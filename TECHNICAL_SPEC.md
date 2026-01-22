# zkAudit Technical Specification

## Protocol Overview

zkAudit implements a privacy-preserving certification system using Aleo's zero-knowledge execution model and Leo's private records.

## Privacy Model

### Privacy Guarantees

1. **Audit Details Privacy**
   - Audit findings, vulnerability reports, and remediation details remain off-chain
   - Only a commitment (certificate) exists on-chain
   - Certificate contains no information about specific vulnerabilities

2. **Auditor Identity Privacy**
   - Auditors are identified by commitments, not addresses
   - Commitment: `hash(private_key || salt || domain_separator)`
   - Multiple auditors can operate without revealing real-world identities
   - Prevents correlation between auditor identity and specific audits

3. **Program Implementation Privacy**
   - Program hash is a commitment to the code
   - Actual source code never stored on-chain
   - Proprietary algorithms remain confidential
   - Only certificate owner knows which certificate corresponds to their program

4. **Certificate Ownership Privacy**
   - Certificates are private records
   - Only owner can access and present certificate
   - No public list of who holds which certificates

### Information Flow

```
Off-Chain:
┌─────────────────────────────────────────────────┐
│ Detailed Audit Report                           │
│ - Source code analysis                          │
│ - Vulnerability findings                        │
│ - Remediation recommendations                   │
│ - Test results                                  │
└─────────────────────────────────────────────────┘
                    ↓
            Hash/Commitment
                    ↓
On-Chain:
┌─────────────────────────────────────────────────┐
│ Certificate Record (Private)                    │
│ - program_hash: field                           │
│ - standard_level: u8                            │
│ - auditor_commitment: field                     │
│ - (Other metadata)                              │
└─────────────────────────────────────────────────┘
```

## Cryptographic Primitives

### 1. Auditor Commitments

**Purpose**: Privacy-preserving auditor identification

**Construction**:
```
auditor_commitment = H(auditor_private_key || salt || "zkaudit.auditor.v1")
```

**Properties**:
- Binding: Cannot be changed after registration
- Hiding: Does not reveal auditor identity
- Unique: Each auditor has unique commitment
- Verifiable: Auditor can prove ownership of commitment (off-chain)

### 2. Program Hash

**Purpose**: Commit to specific program version

**Construction**:
```
program_hash = H(
    source_code ||
    dependencies_manifest ||
    compiler_version ||
    build_configuration
)
```

**Properties**:
- Deterministic: Same input produces same hash
- Collision-resistant: Different programs have different hashes
- Preimage-resistant: Cannot derive source from hash

### 3. Certificate ID

**Purpose**: Unique identifier for each certificate

**Construction**:
```
certificate_id = H(
    auditor_commitment ||
    program_hash ||
    timestamp ||
    random_nonce
)
```

**Properties**:
- Globally unique
- Unpredictable (prevents precomputation attacks)
- Non-sequential (prevents enumeration)

### 4. Reason Hash

**Purpose**: Privacy-preserving revocation reason

**Construction**:
```
reason_hash = H(revocation_reason_text)
```

**Properties**:
- Hiding: Reason not revealed publicly
- Verifiable: Original reason can be verified off-chain if shared

## Security Properties

### Threat Model

**Adversary Capabilities**:
- Can observe all on-chain transactions
- Can attempt to register as auditor
- Can request certificates from auditors
- Can analyze certificate patterns
- Cannot forge certificates
- Cannot impersonate auditors

**Security Goals**:
1. **Unforgeability**: Only registered auditors can issue valid certificates
2. **Non-repudiation**: Auditor cannot deny issuing certificate
3. **Revocability**: Auditor can revoke compromised certificates
4. **Privacy**: Sensitive information remains confidential
5. **Verifiability**: Anyone can verify certificate validity

### Attack Vectors and Mitigations

#### 1. Certificate Forgery Attack
**Attack**: Adversary tries to create fake certificate
**Mitigation**: 
- Certificate must be issued through `issue_certificate` transition
- Auditor must be registered in `registered_auditors` mapping
- All certificates tracked in `revoked_certificates` mapping

#### 2. Auditor Impersonation Attack
**Attack**: Adversary tries to issue certificates as different auditor
**Mitigation**:
- Auditor commitment must match in transition
- Commitment ownership cannot be transferred
- Auditor must prove knowledge of preimage (off-chain)

#### 3. Replay Attack
**Attack**: Adversary tries to reuse old certificate
**Mitigation**:
- Unique certificate IDs prevent reuse
- Timestamps allow expiration checking
- Revocation status checked on verification

#### 4. Privacy Leakage Attack
**Attack**: Adversary tries to correlate certificates to programs
**Mitigation**:
- Certificates are private records
- Program hash doesn't reveal program identity
- Auditor commitment doesn't reveal auditor identity

#### 5. Revocation Bypass Attack
**Attack**: Adversary tries to use revoked certificate
**Mitigation**:
- `verify_certificate` checks revocation status
- Revocation status stored in public mapping
- Cannot be bypassed

## Data Structures

### Certificate Record

```leo
record Certificate {
    owner: address,              // Certificate holder (private)
    certificate_id: field,       // Unique ID (private)
    program_hash: field,         // Program commitment (private)
    standard_level: u8,          // 1-4 (private)
    issued_at: u64,             // Timestamp (private)
    expires_at: u64,            // Expiration (private)
    auditor_commitment: field,   // Auditor ID (private)
}
```

**Size**: ~248 bytes
**Privacy**: Fully private (record-based)

### RevocationProof Record

```leo
record RevocationProof {
    owner: address,              // Original certificate owner
    certificate_id: field,       // Revoked certificate ID
    revoked_at: u64,            // Revocation timestamp
    reason_hash: field,          // Privacy-preserving reason
}
```

**Purpose**: Proof that certificate was revoked
**Privacy**: Reason is hashed, not revealed

### Mappings (Public State)

1. **revoked_certificates**: `field => u8`
   - Key: certificate_id
   - Value: 0 (valid) or 1 (revoked)
   - Public for safety (users must know if certificate revoked)

2. **registered_auditors**: `field => u8`
   - Key: auditor_commitment
   - Value: 0 (not registered) or 1 (registered)
   - Public for verification

3. **auditor_certificate_count**: `field => u64`
   - Key: auditor_commitment
   - Value: count of certificates issued
   - Public for reputation system

## State Transitions

### 1. register_auditor

**Input**: `auditor_commitment`
**Output**: Future (finalize sets mapping)
**State Change**: `registered_auditors[commitment] = 1`

**Privacy**: Commitment is public but doesn't reveal identity

### 2. issue_certificate

**Input**: Certificate parameters
**Output**: Certificate record + Future
**State Changes**:
- Creates private Certificate record
- `auditor_certificate_count[commitment] += 1`
- `revoked_certificates[cert_id] = 0`

**Privacy**: Certificate details remain private to recipient

### 3. verify_certificate

**Input**: Certificate + current_time + min_standard
**Output**: Certificate + validity boolean + Future
**State Changes**: None (read-only)
**Checks**:
- Certificate meets minimum standard
- Certificate not expired
- Certificate not revoked (checked in finalize)

**Privacy**: Verification doesn't reveal certificate details

### 4. revoke_certificate

**Input**: Certificate + revocation details
**Output**: RevocationProof + Future
**State Changes**:
- Creates RevocationProof record
- `revoked_certificates[cert_id] = 1`

**Privacy**: Revocation reason hashed

### 5. transfer_certificate

**Input**: Certificate + new_owner
**Output**: New Certificate record
**State Changes**: None (pure function)

**Privacy**: Transfer is private between parties

### 6. verify_program_hash

**Input**: Certificate + expected_hash
**Output**: Certificate + boolean match result
**State Changes**: None (pure function)

**Privacy**: Comparison is private

### 7. get_auditor_reputation

**Input**: auditor_commitment
**Output**: Future (count in mapping)
**State Changes**: None (read-only)

**Privacy**: Count is public metric

## Economic Model

### Auditor Incentives

1. **Reputation Building**: More certificates = higher reputation
2. **Trust Signal**: High reputation attracts more clients
3. **Quality Incentive**: Revocations damage reputation

### Certificate Lifecycle

```
Register Auditor → Issue Certificate → Active Certificate
                          ↓                    ↓
                    [Verification]     [Verification]
                          ↓                    ↓
                     Valid/Invalid        Valid/Invalid
                          ↓
                   [Optional: Revoke]
                          ↓
                   Revoked Certificate
                          ↓
                    Always Invalid
```

### Cost Considerations

- Registration: One-time fee (transaction cost)
- Issuance: Per-certificate fee (transaction cost)
- Verification: Read-only (minimal cost)
- Revocation: Emergency action (transaction cost)

## Integration Patterns

### Pattern 1: Wallet Integration

```
User Action: Interact with DApp
    ↓
Wallet: Check for Certificate
    ↓
If certified:
    - verify_certificate(min_standard=2)
    - verify_program_hash(expected_hash)
    - Display badge if valid
If not certified:
    - Show warning
    - Require user confirmation
```

### Pattern 2: DApp Self-Certification

```
DApp Loads:
    ↓
Load Certificate from storage
    ↓
Display Certification Badge
    ↓
User Clicks Badge:
    - Show standard level
    - Show expiration
    - Show auditor reputation
    - Link to verify on-chain
```

### Pattern 3: Marketplace Filtering

```
Marketplace Query:
    ↓
Filter: certified=true, min_standard=2
    ↓
For each program:
    - Check certificate exists
    - Verify not expired
    - Verify not revoked
    ↓
Display only certified programs
```

## Performance Characteristics

### Transaction Costs (Estimated)

- `register_auditor`: ~10,000 credits
- `issue_certificate`: ~15,000 credits
- `verify_certificate`: ~5,000 credits (read-heavy)
- `revoke_certificate`: ~12,000 credits
- `transfer_certificate`: ~3,000 credits (no finalize)
- `verify_program_hash`: ~2,000 credits (pure)

### Storage Requirements

- Per certificate: ~248 bytes (record)
- Per auditor: 1 mapping entry (commitment)
- Per certificate: 1 mapping entry (revocation status)

### Scalability

- Records scale linearly with certificates issued
- Mappings scale linearly with auditors and certificates
- No quadratic scaling factors
- Verification is O(1) time complexity

## Future Enhancements

### Short-term (v0.2.0)
- [ ] Multi-signature auditor support
- [ ] Certificate renewal mechanism
- [ ] Batch issuance optimization

### Medium-term (v0.3.0)
- [ ] Governance for auditor registration
- [ ] Tiered auditor system
- [ ] Automated audit tool integration

### Long-term (v1.0.0)
- [ ] Cross-chain certificate verification
- [ ] Decentralized auditor network
- [ ] Insurance integration

## Compliance and Standards

### Audit Standards Mapping

- **Level 1 (Basic)**: OWASP Top 10 review
- **Level 2 (Standard)**: OWASP + automated testing
- **Level 3 (Advanced)**: Formal verification + advanced testing
- **Level 4 (Critical)**: Maximum security for DeFi/critical infrastructure

### Best Practices Alignment

- ✅ NIST Cybersecurity Framework
- ✅ ISO/IEC 27001
- ✅ Smart Contract Security Alliance (SCSA)
- ✅ Trail of Bits Audit Methodology

## Conclusion

zkAudit provides a robust, privacy-preserving certification protocol for Aleo programs, balancing transparency (verification) with privacy (audit details, identities). The cryptographic design ensures security while maintaining the zero-knowledge properties of the Aleo platform.

---

Version: 0.1.0  
Last Updated: January 2026  
Authors: zkAudit Contributors
