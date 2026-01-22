# zkAudit Quick Reference

Quick reference guide for common operations with the zkAudit protocol.

## Installation

```bash
# Install Leo
curl -L https://raw.githubusercontent.com/AleoHQ/leo/testnet/install.sh | sh

# Clone zkAudit
git clone https://github.com/Official-zkAudit/zkaudit.git
cd zkaudit

# Build
leo build
```

## Common Commands

### Auditor Operations

```bash
# Register as auditor
leo run register_auditor {auditor_commitment}

# Issue certificate
leo run issue_certificate \
    {recipient_address} \
    {certificate_id} \
    {program_hash} \
    {standard_level}u8 \
    {issued_at}u64 \
    {expires_at}u64 \
    {auditor_commitment}

# Revoke certificate
leo run revoke_certificate \
    {certificate_record} \
    {revoked_at}u64 \
    {reason_hash} \
    {auditor_commitment}
```

### Project Operations

```bash
# Verify your certificate
leo run verify_certificate \
    {certificate_record} \
    {current_time}u64 \
    {min_standard}u8

# Transfer certificate
leo run transfer_certificate \
    {certificate_record} \
    {new_owner_address}

# Verify program hash
leo run verify_program_hash \
    {certificate_record} \
    {expected_program_hash}
```

### Verifier Operations

```bash
# Check auditor reputation
leo run get_auditor_reputation {auditor_commitment}

# Verify certificate validity
leo run verify_certificate {certificate} {time} {min_standard}

# Verify program match
leo run verify_program_hash {certificate} {program_hash}
```

## Standard Levels

| Level | Name | Description |
|-------|------|-------------|
| 1 | Basic | Code review, basic security checks |
| 2 | Standard | Comprehensive audit, automated testing |
| 3 | Advanced | Formal verification, advanced threat modeling |
| 4 | Critical | Maximum security for high-value systems |

## Data Types

### Certificate Record
```leo
record Certificate {
    owner: address,
    certificate_id: field,
    program_hash: field,
    standard_level: u8,      // 1-4
    issued_at: u64,
    expires_at: u64,         // 0 = no expiration
    auditor_commitment: field,
}
```

### RevocationProof Record
```leo
record RevocationProof {
    owner: address,
    certificate_id: field,
    revoked_at: u64,
    reason_hash: field,
}
```

## Transitions

| Transition | Description | Inputs | Outputs |
|------------|-------------|--------|---------|
| `register_auditor` | Register as auditor | commitment | Future |
| `issue_certificate` | Issue certificate | 7 params | Certificate + Future |
| `verify_certificate` | Verify validity | cert + time + standard | Certificate + bool + Future |
| `revoke_certificate` | Revoke certificate | cert + time + reason + commitment | RevocationProof + Future |
| `transfer_certificate` | Transfer ownership | cert + new_owner | Certificate |
| `verify_program_hash` | Verify program match | cert + hash | Certificate + bool |
| `get_auditor_reputation` | Check reputation | commitment | Future |

## Mappings

| Mapping | Key | Value | Purpose |
|---------|-----|-------|---------|
| `revoked_certificates` | certificate_id (field) | status (u8) | Track revocations |
| `registered_auditors` | auditor_commitment (field) | status (u8) | Track registrations |
| `auditor_certificate_count` | auditor_commitment (field) | count (u64) | Track reputation |

## Error Messages

| Error | Cause | Solution |
|-------|-------|----------|
| "Auditor not registered" | Unregistered auditor issuing cert | Call `register_auditor` first |
| "Certificate revoked" | Verifying revoked certificate | Certificate is no longer valid |
| "Auditor mismatch" | Wrong auditor revoking | Only issuing auditor can revoke |

## Best Practices

### For Auditors
- ✅ Use strong, unique commitments
- ✅ Set appropriate expiration dates (6-12 months)
- ✅ Revoke promptly if issues found
- ✅ Keep audit reports secure off-chain
- ❌ Don't reuse commitments
- ❌ Don't issue without thorough audit

### For Projects
- ✅ Store certificates securely
- ✅ Re-audit before expiration
- ✅ Display certification badges
- ✅ Verify certificate before presenting
- ❌ Don't lose certificate records
- ❌ Don't modify code after certification

### For Verifiers
- ✅ Always verify certificate validity
- ✅ Check program hash matches
- ✅ Consider auditor reputation
- ✅ Check expiration dates
- ❌ Don't trust expired certificates
- ❌ Don't skip verification steps

## Privacy Properties

**Private:**
- Audit findings and details
- Auditor real-world identity
- Program source code
- Certificate ownership

**Public:**
- Auditor commitments (pseudonyms)
- Certificate revocation status
- Certificate issuance counts

## Cost Estimates

| Operation | Credits | USD (approx) |
|-----------|---------|--------------|
| Register auditor | ~10,000 | $0.10 - $1.00 |
| Issue certificate | ~15,000 | $0.15 - $1.50 |
| Verify certificate | ~5,000 | $0.05 - $0.50 |
| Revoke certificate | ~12,000 | $0.12 - $1.20 |
| Transfer certificate | ~3,000 | $0.03 - $0.30 |
| Verify program hash | ~2,000 | $0.02 - $0.20 |

*Costs vary based on network conditions and credit market price*

## File Structure

```
zkaudit/
├── src/
│   └── main.leo              # Main program
├── inputs/
│   └── zkaudit.in            # Example inputs
├── README.md                  # Overview
├── EXAMPLES.md                # Usage examples
├── TECHNICAL_SPEC.md          # Technical details
├── DEPLOYMENT.md              # Deployment guide
├── TESTING.md                 # Test scenarios
├── FAQ.md                     # FAQ
├── SECURITY.md                # Security policy
├── CONTRIBUTING.md            # Contributing guide
└── program.json               # Program metadata
```

## Example Values

```bash
# Example addresses
recipient="aleo1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqq3ljyzc"

# Example field values
auditor_commitment="12345678901234567890field"
certificate_id="11111111111111111111field"
program_hash="99999999999999999999field"

# Example timestamps
issued_at="1700000000u64"
expires_at="1731536000u64"  # or 0u64 for no expiration

# Example standard levels
basic="1u8"
standard="2u8"
advanced="3u8"
critical="4u8"
```

## Useful Links

- [Main README](README.md) - Protocol overview and features
- [Examples](EXAMPLES.md) - Detailed usage examples
- [Technical Spec](TECHNICAL_SPEC.md) - Architecture and design
- [Deployment Guide](DEPLOYMENT.md) - How to deploy
- [FAQ](FAQ.md) - Common questions
- [Security](SECURITY.md) - Security considerations
- [Aleo Documentation](https://developer.aleo.org/) - Aleo platform docs
- [Leo Documentation](https://developer.aleo.org/leo/) - Leo language docs

## Support

- **Issues**: [GitHub Issues](https://github.com/Official-zkAudit/zkaudit/issues)
- **Discussions**: [GitHub Discussions](https://github.com/Official-zkAudit/zkaudit/discussions)
- **Email**: support@zkaudit.org

## Cheat Sheet

### Generate Commitment
```bash
echo -n "private_key_salt" | sha256sum | cut -d' ' -f1
```

### Generate Program Hash
```bash
cat program.leo | sha256sum | cut -d' ' -f1
```

### Get Current Timestamp
```bash
date +%s
```

### Convert Date to Timestamp
```bash
date -d "2026-12-31" +%s
```

### Check Balance
```bash
leo account balance --address {your_address}
```

### View Transaction
```bash
aleo transaction info {transaction_id} --network {testnet|mainnet}
```

### Query Mapping
```bash
aleo mapping get {mapping_name} {key} \
    --program zkaudit.aleo \
    --network {testnet|mainnet}
```

## License

MIT License - See [LICENSE](LICENSE) file
