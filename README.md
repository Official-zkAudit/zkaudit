# zkAudit - Privacy-Preserving Certification Protocol for Aleo

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

zkAudit is a privacy-preserving certification protocol for Aleo programs that enables trusted auditors to issue verifiable security credentials without revealing sensitive audit details, auditor identities, or proprietary implementation specifics.

## Overview

zkAudit leverages Aleo's zero-knowledge execution model and Leo's private records to enable projects to prove "this program has been audited and meets security standard X" to users, integrators, and wallets — all while maintaining full on-chain privacy.

### Key Features

- **🔒 Privacy-First Design**: Audit details, auditor identities, and implementation specifics remain private
- **✅ Verifiable Credentials**: Projects can prove certification without revealing sensitive information
- **🎯 Flexible Standards**: Support for multiple security standard levels (basic, standard, advanced, critical)
- **⏰ Time-Bound Certificates**: Optional expiration dates for time-limited certifications
- **🔄 Certificate Management**: Transfer, verify, and revoke certificates as needed
- **📊 Auditor Reputation**: Privacy-preserving reputation system based on certificate issuance count
- **🛡️ Revocation System**: Auditors can revoke certificates if post-audit issues are discovered

## Privacy Guarantees

### What Remains Private

1. **Audit Details**: The specific findings, vulnerabilities discovered, and remediation steps
2. **Auditor Identity**: Auditors are identified by commitments, not public addresses
3. **Implementation Details**: The actual code and proprietary algorithms remain hidden
4. **Certificate Ownership**: Only the certificate owner knows they possess it
5. **Program Hash**: The specific program being certified is not publicly revealed

### What Is Public

1. **Revocation Status**: Whether a certificate has been revoked (for safety)
2. **Auditor Registration**: Commitments of registered auditors (without revealing identity)
3. **Certificate Count**: Number of certificates issued by each auditor (reputation metric)

## Architecture

### Core Components

#### 1. Certificate Record (Private)

```leo
record Certificate {
    owner: address,              // Certificate holder
    certificate_id: field,       // Unique identifier
    program_hash: field,         // Hash of audited program
    standard_level: u8,          // Security standard (1-4)
    issued_at: u64,             // Issuance timestamp
    expires_at: u64,            // Expiration (0 = no expiry)
    auditor_commitment: field,   // Auditor identifier (privacy-preserving)
}
```

#### 2. Security Standard Levels

- **Level 1 (Basic)**: Code review and basic security checks
- **Level 2 (Standard)**: Comprehensive security audit with automated testing
- **Level 3 (Advanced)**: Formal verification and advanced threat modeling
- **Level 4 (Critical)**: Maximum security for high-value or critical infrastructure

#### 3. Key Transitions

- `register_auditor`: Register as an auditor using a commitment
- `issue_certificate`: Issue a certificate to a project
- `verify_certificate`: Verify certificate validity and standard level
- `revoke_certificate`: Revoke a certificate (auditor only)
- `transfer_certificate`: Transfer ownership of a certificate
- `verify_program_hash`: Prove certificate corresponds to specific program
- `get_auditor_reputation`: Check auditor's certificate issuance count

## Usage Examples

### For Auditors

#### 1. Register as an Auditor

```bash
# Generate auditor commitment (off-chain)
auditor_commitment = hash(auditor_private_key + salt)

# Register on-chain
leo run register_auditor {auditor_commitment}
```

#### 2. Issue a Certificate

```bash
leo run issue_certificate \
    {recipient_address} \
    {certificate_id} \
    {program_hash} \
    2u8 \                    # Standard level
    1234567890u64 \          # Issued at timestamp
    1924567890u64 \          # Expires at timestamp (or 0u64 for no expiry)
    {auditor_commitment}
```

#### 3. Revoke a Certificate

```bash
leo run revoke_certificate \
    {certificate_record} \
    {revocation_timestamp} \
    {reason_hash} \
    {auditor_commitment}
```

### For Projects

#### 1. Verify Your Certificate

```bash
leo run verify_certificate \
    {certificate_record} \
    {current_timestamp} \
    2u8  # Minimum standard level required
```

#### 2. Prove Program Certification

```bash
leo run verify_program_hash \
    {certificate_record} \
    {program_hash}
```

#### 3. Transfer Certificate Ownership

```bash
leo run transfer_certificate \
    {certificate_record} \
    {new_owner_address}
```

### For Verifiers (Users/Integrators/Wallets)

When a project claims to be audited, they can provide their Certificate record. The verifier can:

1. **Check it meets minimum standards**: Use `verify_certificate` transition
2. **Verify it's for the correct program**: Use `verify_program_hash` transition
3. **Check auditor reputation**: Use `get_auditor_reputation` transition
4. **Verify not revoked**: The `verify_certificate` transition checks revocation status

## Integration Guide

### For Wallet Developers

```javascript
// Example integration pseudo-code
async function verifyProjectCertification(certificate, programHash, minStandard) {
    // 1. Verify certificate matches the program
    const programMatches = await executeTransition(
        'verify_program_hash',
        [certificate, programHash]
    );
    
    if (!programMatches) {
        return { certified: false, reason: 'Program hash mismatch' };
    }
    
    // 2. Verify certificate meets minimum standard and is not expired
    const currentTime = Date.now() / 1000;
    const isValid = await executeTransition(
        'verify_certificate',
        [certificate, currentTime, minStandard]
    );
    
    if (!isValid) {
        return { certified: false, reason: 'Certificate invalid or expired' };
    }
    
    // 3. Check auditor reputation (optional)
    const auditorCommitment = certificate.auditor_commitment;
    const reputation = await getAuditorReputation(auditorCommitment);
    
    return {
        certified: true,
        standardLevel: certificate.standard_level,
        auditorReputation: reputation,
        expiresAt: certificate.expires_at
    };
}
```

### For DApp Developers

```javascript
// Display certification badge in UI
function renderCertificationBadge(certificate) {
    const standardLabels = {
        1: 'Basic Security Audit',
        2: 'Standard Security Audit',
        3: 'Advanced Security Audit',
        4: 'Critical Infrastructure Audit'
    };
    
    return `
        <div class="certification-badge">
            <span class="badge-icon">🛡️</span>
            <span class="badge-text">
                ${standardLabels[certificate.standard_level]}
            </span>
            ${certificate.expires_at > 0 ? 
                `<span class="expiry">Expires: ${new Date(certificate.expires_at * 1000).toLocaleDateString()}</span>` 
                : ''}
        </div>
    `;
}
```

## Building and Testing

### Prerequisites

- [Leo](https://developer.aleo.org/leo/) - Install the Leo programming language
- [Aleo SDK](https://developer.aleo.org/sdk/) - For local testing

### Build

```bash
# Build the program
leo build

# Clean build artifacts
leo clean
```

### Test

```bash
# Run all tests
leo test

# Run specific test
leo test test_issue_certificate
```

### Deploy

```bash
# Deploy to Aleo testnet
leo deploy --network testnet

# Deploy to Aleo mainnet
leo deploy --network mainnet
```

## Security Considerations

### Auditor Commitments

Auditors should use strong, unique commitments:
```
auditor_commitment = hash(auditor_private_key || random_salt || domain_separator)
```

Never reuse commitments across different contexts to prevent correlation attacks.

### Certificate IDs

Certificate IDs should be:
- Globally unique
- Unpredictable (use cryptographic randomness)
- Not derivable from public information

Example: `certificate_id = hash(program_hash || timestamp || random_nonce)`

### Program Hashes

The program hash should be a commitment to:
- Source code
- Compiler version
- Build configuration
- Dependencies

This ensures the certificate is bound to a specific program version.

### Expiration Policy

Consider setting expiration dates for certificates to:
- Encourage regular re-audits
- Account for new vulnerability discoveries
- Reflect evolving security standards

Recommended: 12 months for most applications, 6 months for critical infrastructure.

## Threat Model

### Protected Against

- ✅ Unauthorized certificate issuance (auditor registration required)
- ✅ Certificate forgery (cryptographic binding)
- ✅ Privacy breaches (zero-knowledge proofs)
- ✅ Replay attacks (unique certificate IDs)
- ✅ Post-audit issues (revocation mechanism)

### Out of Scope

- ❌ Auditor collusion or malicious auditors (requires off-chain reputation/governance)
- ❌ Social engineering attacks on certificate holders
- ❌ Bugs in the audited program itself (certificate proves audit, not correctness)
- ❌ Compromise of auditor's private keys (requires key management best practices)

## Roadmap

- [x] Core protocol implementation
- [x] Basic certification and verification
- [x] Revocation mechanism
- [x] Auditor reputation system
- [ ] Multi-signature auditor support
- [ ] Automated audit tool integration
- [ ] Standard templates for different audit types
- [ ] Governance framework for auditor registration
- [ ] Integration with popular Aleo wallets
- [ ] Developer dashboard and analytics

## Contributing

Contributions are welcome! Please follow these guidelines:

1. Fork the repository
2. Create a feature branch
3. Write tests for new functionality
4. Ensure all tests pass
5. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- Built on [Aleo](https://aleo.org/) and the [Leo programming language](https://developer.aleo.org/leo/)
- Inspired by existing smart contract audit certification systems
- Thanks to the zero-knowledge cryptography community

## Contact

- GitHub Issues: [zkAudit Issues](https://github.com/Official-zkAudit/zkaudit/issues)
- Documentation: [zkAudit Docs](https://docs.zkaudit.org) (coming soon)

## Citation

If you use zkAudit in your research or project, please cite:

```bibtex
@software{zkaudit2026,
  title = {zkAudit: Privacy-Preserving Certification Protocol for Aleo},
  author = {zkAudit Contributors},
  year = {2026},
  url = {https://github.com/Official-zkAudit/zkaudit}
}
```