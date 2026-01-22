// The 'zkaudit' program - Privacy-preserving certification protocol for Aleo programs
program zkaudit.aleo {
    
    // A Certificate is a private record that proves a program has been audited
    // and meets a specific security standard without revealing audit details
    record Certificate {
        // The owner of this certificate (typically the project/program owner)
        owner: address,
        // Unique identifier for this certificate
        certificate_id: field,
        // Hash of the audited program (commitment to what was audited)
        program_hash: field,
        // Security standard level (e.g., 1=basic, 2=standard, 3=advanced, 4=critical)
        standard_level: u8,
        // Timestamp when certificate was issued (block height or timestamp)
        issued_at: u64,
        // Expiration timestamp (0 means no expiration)
        expires_at: u64,
        // Hash of auditor's public key (privacy-preserving auditor identification)
        auditor_commitment: field,
    }

    // RevocationProof is a record that proves a certificate has been revoked
    record RevocationProof {
        owner: address,
        certificate_id: field,
        revoked_at: u64,
        reason_hash: field,
    }

    // Mapping to track revoked certificates (public state for verification)
    // Maps certificate_id -> revocation status (0=valid, 1=revoked)
    mapping revoked_certificates: field => u8;

    // Mapping to track registered auditors (privacy-preserving)
    // Maps auditor_commitment -> registration status (0=not registered, 1=registered)
    mapping registered_auditors: field => u8;

    // Mapping to track certificate issuance count per auditor (for reputation)
    mapping auditor_certificate_count: field => u64;

    
    // Transition: Register an auditor
    // Only the auditor can register themselves by providing a commitment
    // This allows tracking auditor reputation without revealing identity
    async transition register_auditor(
        public auditor_commitment: field
    ) -> Future {
        return finalize_register_auditor(auditor_commitment);
    }

    async function finalize_register_auditor(auditor_commitment: field) {
        // Register the auditor by setting their commitment to 1
        Mapping::set(registered_auditors, auditor_commitment, 1u8);
    }


    // Transition: Issue a certificate
    // An auditor issues a certificate to a project after successful audit
    // This creates a private record that the project can use to prove certification
    async transition issue_certificate(
        recipient: address,
        certificate_id: field,
        program_hash: field,
        standard_level: u8,
        issued_at: u64,
        expires_at: u64,
        auditor_commitment: field
    ) -> (Certificate, Future) {
        
        // Create the certificate record (private to recipient)
        let certificate: Certificate = Certificate {
            owner: recipient,
            certificate_id: certificate_id,
            program_hash: program_hash,
            standard_level: standard_level,
            issued_at: issued_at,
            expires_at: expires_at,
            auditor_commitment: auditor_commitment,
        };

        return (certificate, finalize_issue_certificate(auditor_commitment, certificate_id));
    }

    async function finalize_issue_certificate(
        auditor_commitment: field,
        certificate_id: field
    ) {
        // Verify auditor is registered
        let is_registered: u8 = Mapping::get(registered_auditors, auditor_commitment);
        assert_eq(is_registered, 1u8);
        
        // Increment the auditor's certificate count
        let current_count: u64 = Mapping::get_or_use(auditor_certificate_count, auditor_commitment, 0u64);
        Mapping::set(auditor_certificate_count, auditor_commitment, current_count + 1u64);
        
        // Ensure certificate is not already revoked (initialize as valid)
        Mapping::set(revoked_certificates, certificate_id, 0u8);
    }


    // Transition: Verify certificate validity
    // Anyone can verify a certificate meets requirements without revealing details
    // Returns true if certificate is valid and meets the minimum standard level
    async transition verify_certificate(
        certificate: Certificate,
        current_time: u64,
        minimum_standard: u8
    ) -> (Certificate, bool, Future) {
        
        // Check if certificate meets minimum standard
        let meets_standard: bool = certificate.standard_level >= minimum_standard;
        
        // Check if certificate is expired (0 means no expiration)
        let is_expired: bool = certificate.expires_at != 0u64 && current_time > certificate.expires_at;
        let not_expired: bool = !is_expired;
        
        // Certificate is valid if it meets standard and is not expired
        let is_valid: bool = meets_standard && not_expired;
        
        return (certificate, is_valid, finalize_verify_certificate(certificate.certificate_id));
    }

    async function finalize_verify_certificate(certificate_id: field) {
        // Check if certificate has been revoked
        let revocation_status: u8 = Mapping::get_or_use(revoked_certificates, certificate_id, 0u8);
        assert_eq(revocation_status, 0u8); // Must not be revoked
    }


    // Transition: Revoke a certificate
    // Auditor can revoke a certificate if issues are found post-audit
    async transition revoke_certificate(
        certificate: Certificate,
        revoked_at: u64,
        reason_hash: field,
        auditor_commitment: field
    ) -> (RevocationProof, Future) {
        
        // Verify the auditor is the one who issued this certificate
        assert_eq(certificate.auditor_commitment, auditor_commitment);
        
        // Create revocation proof
        let revocation: RevocationProof = RevocationProof {
            owner: certificate.owner,
            certificate_id: certificate.certificate_id,
            revoked_at: revoked_at,
            reason_hash: reason_hash,
        };
        
        return (revocation, finalize_revoke_certificate(certificate.certificate_id, auditor_commitment));
    }

    async function finalize_revoke_certificate(
        certificate_id: field,
        auditor_commitment: field
    ) {
        // Verify auditor is registered
        let is_registered: u8 = Mapping::get(registered_auditors, auditor_commitment);
        assert_eq(is_registered, 1u8);
        
        // Mark certificate as revoked
        Mapping::set(revoked_certificates, certificate_id, 1u8);
    }


    // Transition: Transfer certificate ownership
    // Allows transferring a certificate to a new owner (e.g., after project sale)
    transition transfer_certificate(
        certificate: Certificate,
        new_owner: address
    ) -> Certificate {
        
        // Create new certificate with updated owner
        let transferred: Certificate = Certificate {
            owner: new_owner,
            certificate_id: certificate.certificate_id,
            program_hash: certificate.program_hash,
            standard_level: certificate.standard_level,
            issued_at: certificate.issued_at,
            expires_at: certificate.expires_at,
            auditor_commitment: certificate.auditor_commitment,
        };
        
        return transferred;
    }


    // Transition: Verify program hash
    // Proves that a certificate corresponds to a specific program without revealing other details
    transition verify_program_hash(
        certificate: Certificate,
        expected_program_hash: field
    ) -> (Certificate, bool) {
        
        let matches: bool = certificate.program_hash == expected_program_hash;
        return (certificate, matches);
    }


    // Transition: Get auditor reputation
    // Returns the number of certificates issued by an auditor (public metric)
    async transition get_auditor_reputation(
        public auditor_commitment: field
    ) -> Future {
        return finalize_get_auditor_reputation(auditor_commitment);
    }

    async function finalize_get_auditor_reputation(auditor_commitment: field) {
        // This is primarily for on-chain verification
        // The count can be read from the mapping
        let _count: u64 = Mapping::get_or_use(auditor_certificate_count, auditor_commitment, 0u64);
    }
}
