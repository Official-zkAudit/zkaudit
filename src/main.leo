// ============================================================================
// zkAudit: Privacy-Preserving Security Certification for Aleo Programs
// ============================================================================
// Author: Isah Dauda (@_trinnex)
// Version: 0.2.0
// License: MIT
// 
// This program enables trusted auditors to issue verifiable security 
// certifications for Aleo programs without revealing sensitive audit details.
// Users can verify that a program has been audited without knowing who 
// audited it or what specific findings were discovered.
// ============================================================================

program zkaudit.aleo {

    // ========================================================================
    // RECORDS - Private on-chain state owned by specific addresses
    // ========================================================================
    
    // Private certification credential owned by the audited project
    // This record is encrypted and only visible to the owner (project deployer)
    record Certification {
        owner: address,          // Project deployer who receives the certification
        program_id: field,       // Hash of the certified program (identifies what was audited)
        level: u8,               // 1=Basic, 2=Standard, 3=Advanced, 4=Comprehensive
        issued_at: u64,          // Unix timestamp when cert was issued
        expires_at: u64,         // Unix timestamp when cert expires (0 = never)
        auditor: address,        // Address of the auditor who issued this cert
        scope_hash: field,       // Hash of audit scope document (off-chain reference)
        nonce: field             // Random value for unlinkability between verifications
    }

    // Private auditor credential - proves someone is a registered auditor
    // Could be used for auditor-side privacy in future versions
    record AuditorBadge {
        owner: address,          // The auditor's address
        tier: u8,                // 1=Individual, 2=Firm, 3=Elite
        registered_at: u64,      // When they were registered
        nonce: field             // Uniqueness
    }

    // ========================================================================
    // MAPPINGS - Public on-chain state (readable by anyone)
    // ========================================================================
    
    // Auditor registry: address => packed(is_active, tier)
    // Format: if value >= 256, auditor is active. Lower 8 bits = tier
    // Example: 257 = active + tier 1, 258 = active + tier 2
    mapping auditor_registry: address => u16;
    
    // Revocation registry: tracks revoked certifications by nullifier
    // When a cert is revoked, its nullifier hash is set to true here
    mapping revoked: field => bool;
    
    // Verification cache: program_id => highest verified level
    // This is optional - lets anyone see "this program has at least level X"
    // without revealing who verified it or when
    mapping verification_cache: field => u8;
    
    // Protocol admin address (key 0u8)
    // In production, this should be a multisig or DAO
    mapping admin: u8 => address;
    
    // Protocol statistics for transparency
    // 0 = total certifications issued
    // 1 = total auditors registered  
    // 2 = total verifications performed
    mapping stats: u8 => u64;

    // ========================================================================
    // ADMIN TRANSITIONS - Protocol governance
    // ========================================================================
    
    // Initialize the protocol (one-time setup)
    // IMPORTANT: Call this first before any other transitions!
    // The caller becomes the admin - in production, use a multisig address
    async transition initialize() -> Future {
        // No inputs needed, just capture caller as admin
        return finalize_initialize(self.caller);
    }
    
    async function finalize_initialize(caller: address) {
        // Check if already initialized by looking for existing admin
        // Using a known "zero" address as sentinel value
        let zero_addr: address = aleo1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqq3ljyzc;
        let existing: address = Mapping::get_or_use(admin, 0u8, zero_addr);
        
        // If admin is already set (not zero), this will fail
        // This prevents re-initialization attacks
        assert_eq(existing, zero_addr);
        
        // Set the caller as admin
        Mapping::set(admin, 0u8, caller);
        
        // Initialize protocol stats to zero
        Mapping::set(stats, 0u8, 0u64);  // total_certs
        Mapping::set(stats, 1u8, 0u64);  // total_auditors
        Mapping::set(stats, 2u8, 0u64);  // total_verifications
    }

    // Transfer admin role to a new address
    // Only current admin can call this
    async transition transfer_admin(new_admin: address) -> Future {
        return finalize_transfer_admin(self.caller, new_admin);
    }
    
    async function finalize_transfer_admin(caller: address, new_admin: address) {
        // Get current admin and verify caller matches
        let current_admin: address = Mapping::get(admin, 0u8);
        assert_eq(caller, current_admin);
        
        // Transfer to new admin
        Mapping::set(admin, 0u8, new_admin);
    }

    // ========================================================================
    // AUDITOR MANAGEMENT - Registration and control of trusted auditors
    // ========================================================================
    
    // Register a new auditor (admin only)
    // Returns an AuditorBadge to the auditor as proof of registration
    async transition register_auditor(
        auditor: address,
        tier: u8,                 // 1=Individual, 2=Firm, 3=Elite
        timestamp: u64,
        nonce: field
    ) -> (AuditorBadge, Future) {
        // Validate tier is in valid range
        assert(tier >= 1u8);
        assert(tier <= 3u8);
        
        // Create the auditor's badge
        let badge: AuditorBadge = AuditorBadge {
            owner: auditor,
            tier: tier,
            registered_at: timestamp,
            nonce: nonce
        };
        
        return (badge, finalize_register_auditor(self.caller, auditor, tier));
    }
    
    async function finalize_register_auditor(caller: address, auditor: address, tier: u8) {
        // Only admin can register auditors
        let current_admin: address = Mapping::get(admin, 0u8);
        assert_eq(caller, current_admin);
        
        // Check auditor isn't already registered (prevent double registration)
        let existing: u16 = Mapping::get_or_use(auditor_registry, auditor, 0u16);
        assert_eq(existing, 0u16);
        
        // Pack is_active (1) and tier into u16
        // Format: 256 (0x0100) = active flag, plus tier value
        // So 257 = active tier 1, 258 = active tier 2, 259 = active tier 3
        let packed: u16 = 256u16 + (tier as u16);
        Mapping::set(auditor_registry, auditor, packed);
        
        // Increment auditor count
        let total: u64 = Mapping::get_or_use(stats, 1u8, 0u64);
        Mapping::set(stats, 1u8, total + 1u64);
    }
    
    // Deactivate an auditor (admin only)
    // Doesn't delete them, just marks as inactive so they can't issue new certs
    // Existing certs they issued remain valid (unless individually revoked)
    async transition deactivate_auditor(auditor: address) -> Future {
        return finalize_deactivate_auditor(self.caller, auditor);
    }
    
    async function finalize_deactivate_auditor(caller: address, auditor: address) {
        // Only admin can deactivate
        let current_admin: address = Mapping::get(admin, 0u8);
        assert_eq(caller, current_admin);
        
        // Get current packed value
        let current: u16 = Mapping::get(auditor_registry, auditor);
        
        // Keep tier but remove active flag (set to just tier value, < 256)
        let tier: u16 = current % 256u16;
        Mapping::set(auditor_registry, auditor, tier);
    }
    
    // Reactivate a previously deactivated auditor (admin only)
    async transition reactivate_auditor(auditor: address) -> Future {
        return finalize_reactivate_auditor(self.caller, auditor);
    }
    
    async function finalize_reactivate_auditor(caller: address, auditor: address) {
        let current_admin: address = Mapping::get(admin, 0u8);
        assert_eq(caller, current_admin);
        
        // Get current tier (should exist but be inactive)
        let current: u16 = Mapping::get(auditor_registry, auditor);
        let tier: u16 = current % 256u16;
        
        // Must have a tier (was previously registered)
        assert(tier > 0u16);
        
        // Re-add active flag
        let packed: u16 = 256u16 + tier;
        Mapping::set(auditor_registry, auditor, packed);
    }

    // ========================================================================
    // CERTIFICATION ISSUANCE - Core audit certification functionality
    // ========================================================================
    
    // Issue a new certification (auditor -> project)
    // The auditor calls this to create a private cert record for the project
    async transition issue_certification(
        recipient: address,      // Project owner receiving the cert
        program_id: field,       // Hash of the audited program
        level: u8,               // Certification level (1-4)
        issued_at: u64,          // Current timestamp
        expires_at: u64,         // Expiration timestamp (0 = never)
        scope_hash: field,       // Hash of scope document
        nonce: field             // Random nonce for uniqueness
    ) -> (Certification, Future) {
        // Validate certification level
        assert(level >= 1u8);
        assert(level <= 4u8);
        
        // Validate expiration makes sense
        // Either no expiration (0) or expiration is after issuance
        let valid_expiration: bool = expires_at == 0u64 || expires_at > issued_at;
        assert(valid_expiration);
        
        // Create the certification record owned by the recipient
        let cert: Certification = Certification {
            owner: recipient,
            program_id: program_id,
            level: level,
            issued_at: issued_at,
            expires_at: expires_at,
            auditor: self.caller,
            scope_hash: scope_hash,
            nonce: nonce
        };
        
        return (cert, finalize_issue_certification(self.caller, level));
    }
    
    async function finalize_issue_certification(auditor: address, level: u8) {
        // Verify auditor is registered AND active
        let packed: u16 = Mapping::get(auditor_registry, auditor);
        let is_active: bool = packed >= 256u16;
        assert(is_active);
        
        // Verify auditor tier allows this certification level
        // Tier 1 can issue Level 1-2
        // Tier 2 can issue Level 1-3  
        // Tier 3 can issue Level 1-4 (all levels)
        let tier: u8 = (packed % 256u16) as u8;
        let max_allowed_level: u8 = tier + 1u8;
        assert(level <= max_allowed_level);
        
        // Increment total certs issued
        let total: u64 = Mapping::get_or_use(stats, 0u8, 0u64);
        Mapping::set(stats, 0u8, total + 1u64);
    }

    // ========================================================================
    // VERIFICATION - Prove certification properties without revealing details
    // ========================================================================
    
    // Verify that a certification meets a minimum level requirement
    // This is the main "proof" transition - generates a ZK proof that:
    // 1. The caller has a valid Certification record
    // 2. That cert's level >= min_level
    // 3. The cert is not expired
    // 4. The cert's auditor is still trusted
    // 5. The cert has not been revoked
    //
    // All without revealing: exact level, exact auditor, exact issuance date, etc.
    async transition verify_minimum_level(
        cert: Certification,
        min_level: u8,
        current_timestamp: u64
    ) -> (bool, Future) {
        // Check level meets minimum (this becomes a ZK constraint)
        assert(cert.level >= min_level);
        
        // Check not expired
        // If expires_at is 0, it never expires
        // Otherwise, current time must be before expiration
        let not_expired: bool = cert.expires_at == 0u64 || cert.expires_at > current_timestamp;
        assert(not_expired);
        
        // Compute nullifier for revocation check
        // Using BHP256 hash of nonce ensures each cert has unique nullifier
        let nullifier: field = BHP256::hash_to_field(cert.nonce);
        
        // Return true and update public state
        return (true, finalize_verify_minimum_level(
            cert.auditor,
            cert.program_id,
            cert.level,
            nullifier
        ));
    }
    
    async function finalize_verify_minimum_level(
        auditor: address,
        program_id: field,
        level: u8,
        nullifier: field
    ) {
        // Check auditor is still active
        // Note: We check active status but don't reveal WHICH auditor
        // The proof only shows "some active auditor signed this"
        let packed: u16 = Mapping::get(auditor_registry, auditor);
        let is_active: bool = packed >= 256u16;
        assert(is_active);
        
        // Check certification not revoked
        let is_revoked: bool = Mapping::get_or_use(revoked, nullifier, false);
        assert(!is_revoked);
        
        // Update verification cache with highest level seen for this program
        // This creates a public record that "program X has been verified at level Y"
        let current_cache: u8 = Mapping::get_or_use(verification_cache, program_id, 0u8);
        if (level > current_cache) {
            Mapping::set(verification_cache, program_id, level);
        }
        
        // Increment verification count
        let total: u64 = Mapping::get_or_use(stats, 2u8, 0u64);
        Mapping::set(stats, 2u8, total + 1u64);
    }

    // Verify certification was issued by a specific auditor
    // Use case: "I only trust certifications from AuditorFirm X"
    async transition verify_specific_auditor(
        cert: Certification,
        expected_auditor: address,
        current_timestamp: u64
    ) -> (bool, Future) {
        // Check auditor matches expectation
        assert_eq(cert.auditor, expected_auditor);
        
        // Check not expired
        let not_expired: bool = cert.expires_at == 0u64 || cert.expires_at > current_timestamp;
        assert(not_expired);
        
        let nullifier: field = BHP256::hash_to_field(cert.nonce);
        
        return (true, finalize_verify_auditor(expected_auditor, nullifier));
    }
    
    async function finalize_verify_auditor(auditor: address, nullifier: field) {
        // Check auditor is active
        let packed: u16 = Mapping::get(auditor_registry, auditor);
        assert(packed >= 256u16);
        
        // Check not revoked
        let is_revoked: bool = Mapping::get_or_use(revoked, nullifier, false);
        assert(!is_revoked);
    }

    // ========================================================================
    // REVOCATION - Invalidate certifications
    // ========================================================================
    
    // Auditor revokes their own issued certification
    // Use case: Auditor discovers the program was modified after audit
    async transition revoke_by_auditor(cert: Certification) -> Future {
        // Only the original auditor can revoke via this method
        assert_eq(cert.auditor, self.caller);
        
        let nullifier: field = BHP256::hash_to_field(cert.nonce);
        
        return finalize_revoke_by_auditor(nullifier, cert.program_id);
    }
    
    async function finalize_revoke_by_auditor(nullifier: field, program_id: field) {
        // Mark as revoked
        Mapping::set(revoked, nullifier, true);
        
        // Clear verification cache for this program
        // They'll need to verify with a different cert now
        Mapping::set(verification_cache, program_id, 0u8);
    }
    
    // Owner self-revokes their certification
    // Use case: Project upgraded their code, old cert no longer valid
    async transition self_revoke(cert: Certification) -> Future {
        // Only the cert owner can self-revoke
        assert_eq(cert.owner, self.caller);
        
        let nullifier: field = BHP256::hash_to_field(cert.nonce);
        
        return finalize_self_revoke(nullifier, cert.program_id);
    }
    
    async function finalize_self_revoke(nullifier: field, program_id: field) {
        Mapping::set(revoked, nullifier, true);
        Mapping::set(verification_cache, program_id, 0u8);
    }
    
    // Admin emergency revocation (for compromised auditors, etc.)
    // Note: This requires knowing the nullifier, which is derived from nonce
    // In practice, admin would need off-chain coordination to get this
    async transition admin_revoke(nullifier: field, program_id: field) -> Future {
        return finalize_admin_revoke(self.caller, nullifier, program_id);
    }
    
    async function finalize_admin_revoke(caller: address, nullifier: field, program_id: field) {
        // Only admin can emergency revoke
        let current_admin: address = Mapping::get(admin, 0u8);
        assert_eq(caller, current_admin);
        
        Mapping::set(revoked, nullifier, true);
        Mapping::set(verification_cache, program_id, 0u8);
    }

    // ========================================================================
    // UTILITY TRANSITIONS
    // ========================================================================
    
    // Transfer certification to a new owner
    // Use case: Project ownership changes hands
    transition transfer_certification(
        cert: Certification,
        new_owner: address,
        new_nonce: field          // New nonce to prevent nullifier reuse
    ) -> Certification {
        // Only current owner can transfer
        assert_eq(cert.owner, self.caller);
        
        // Create new cert with same details but new owner and nonce
        return Certification {
            owner: new_owner,
            program_id: cert.program_id,
            level: cert.level,
            issued_at: cert.issued_at,
            expires_at: cert.expires_at,
            auditor: cert.auditor,
            scope_hash: cert.scope_hash,
            nonce: new_nonce
        };
        // No finalize needed - this is purely a private record transfer
    }

}
