# zkAudit Usage Examples

This document provides detailed examples of how to use the zkAudit protocol for different stakeholders.

## Table of Contents

1. [Auditor Workflows](#auditor-workflows)
2. [Project Owner Workflows](#project-owner-workflows)
3. [Verifier Workflows](#verifier-workflows)
4. [Advanced Use Cases](#advanced-use-cases)

---

## Auditor Workflows

### 1. Setting Up as an Auditor

#### Step 1: Generate Auditor Commitment

```bash
# Off-chain: Generate a unique commitment for your auditor identity
# This should be kept secret and never shared publicly
# Example using a hash function:

auditor_private_key="your-secret-auditor-key"
salt="random-salt-12345"
auditor_commitment=$(echo -n "${auditor_private_key}${salt}" | sha256sum | cut -d' ' -f1)

# Convert to field element format for Leo
# Example: 12345678901234567890field
```

#### Step 2: Register on zkAudit

```bash
# Register your auditor commitment
leo run register_auditor 12345678901234567890field

# Expected output:
# • Executing 'zkaudit.aleo/register_auditor'...
# • Executed 'zkaudit.aleo/register_auditor'
```

### 2. Conducting an Audit and Issuing Certificate

#### Step 1: Audit the Project

Perform your security audit of the Aleo program:
- Code review
- Security analysis
- Vulnerability assessment
- Testing

#### Step 2: Generate Program Hash

```bash
# Generate a hash of the audited program
# This should include source code, dependencies, and build config

program_files="program1.leo program2.leo"
program_hash=$(cat $program_files | sha256sum | cut -d' ' -f1)

# Convert to field element
# Example: 99999999999999999999field
```

#### Step 3: Issue the Certificate

```bash
# Issue certificate to the project owner
leo run issue_certificate \
    aleo1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqq3ljyzc \  # Recipient address
    11111111111111111111field \     # Unique certificate ID
    99999999999999999999field \     # Program hash
    2u8 \                           # Standard level (2 = Standard)
    1700000000u64 \                 # Issued at (Unix timestamp)
    1731536000u64 \                 # Expires at (or 0u64 for no expiry)
    12345678901234567890field       # Your auditor commitment

# Expected output:
# Certificate record created and sent to recipient
```

### 3. Revoking a Certificate

If you discover a critical issue post-audit:

```bash
# Create reason hash (off-chain)
revocation_reason="Critical vulnerability found in authentication module"
reason_hash=$(echo -n "$revocation_reason" | sha256sum | cut -d' ' -f1)

# Revoke the certificate
leo run revoke_certificate \
    '{certificate_record}' \
    1710000000u64 \                 # Revocation timestamp
    55555555555555555555field \     # Reason hash
    12345678901234567890field       # Your auditor commitment

# Expected output:
# RevocationProof created
```

---

## Project Owner Workflows

### 1. Receiving a Certificate

After an audit is complete, the auditor will send you a Certificate record:

```leo
Certificate {
    owner: aleo1xyz...,              // Your address
    certificate_id: 11111111...field,
    program_hash: 99999999...field,
    standard_level: 2u8,
    issued_at: 1700000000u64,
    expires_at: 1731536000u64,
    auditor_commitment: 12345678...field
}
```

Store this record securely - it's your proof of certification!

### 2. Verifying Your Certificate

Check that your certificate is valid:

```bash
# Get current timestamp
current_time=$(date +%s)

# Verify certificate
leo run verify_certificate \
    '{your_certificate_record}' \
    ${current_time}u64 \
    1u8  # Minimum standard level you want to check

# Expected output:
# (Certificate, true) if valid
# Assertion failed if revoked
```

### 3. Proving Your Program is Certified

When someone asks for proof:

```bash
# Verify the certificate corresponds to your program
leo run verify_program_hash \
    '{your_certificate_record}' \
    99999999999999999999field  # Your program hash

# Expected output:
# (Certificate, true) if it matches
```

### 4. Transferring Certificate Ownership

If you sell or transfer your project:

```bash
# Transfer certificate to new owner
leo run transfer_certificate \
    '{your_certificate_record}' \
    aleo1newowner...  # New owner's address

# Expected output:
# New Certificate record with updated owner
```

---

## Verifier Workflows

As a user, integrator, or wallet developer, you want to verify that a project is properly audited.

### 1. Basic Certificate Verification

```bash
# Project provides their certificate record
# Verify it meets your requirements

minimum_standard=2u8  # Require at least Standard level
current_time=$(date +%s)

leo run verify_certificate \
    '{provided_certificate}' \
    ${current_time}u64 \
    ${minimum_standard}

# If this succeeds, the certificate is:
# - Not revoked
# - Meets minimum standard
# - Not expired
```

### 2. Verify Program Hash Matches

```bash
# Get the program hash of the deployed program
deployed_program_hash="99999999999999999999field"

# Verify certificate is for this specific program
leo run verify_program_hash \
    '{provided_certificate}' \
    ${deployed_program_hash}

# Output: (Certificate, true) means it matches
```

### 3. Check Auditor Reputation

```bash
# Extract auditor commitment from certificate
auditor_commitment="12345678901234567890field"

# Check how many certificates this auditor has issued
leo run get_auditor_reputation ${auditor_commitment}

# Check the mapping: auditor_certificate_count
# Higher count may indicate more experience
```

---

## Advanced Use Cases

### Use Case 1: Multi-Level Certification

A project gets multiple audits at different levels:

```bash
# Initial basic audit
leo run issue_certificate \
    {recipient} {cert_id_1} {program_hash} 1u8 {time} {expiry} {auditor1}

# Follow-up comprehensive audit
leo run issue_certificate \
    {recipient} {cert_id_2} {program_hash} 3u8 {time} {expiry} {auditor2}

# Project can show either certificate based on requirements
```

### Use Case 2: Time-Limited Certification Campaign

```bash
# Issue certificates that expire after audit campaign
campaign_end=$(date -d "2026-12-31" +%s)

leo run issue_certificate \
    {recipient} {cert_id} {program_hash} 2u8 {time} ${campaign_end}u64 {auditor}

# Certificates automatically become invalid after campaign
```

### Use Case 3: Re-Certification After Update

```bash
# Original program (v1.0) was audited
original_hash="111111field"

# Program updated to v1.1
updated_hash="222222field"

# New audit required for new version
leo run issue_certificate \
    {recipient} {new_cert_id} ${updated_hash} 2u8 {time} {expiry} {auditor}

# Now project has two certificates for different versions
```

### Use Case 4: Emergency Revocation

```bash
# Critical vulnerability discovered
leo run revoke_certificate \
    '{certificate}' \
    $(date +%s)u64 \
    $(echo -n "CVE-2026-XXXXX" | sha256sum | cut -d' ' -f1)field \
    {auditor_commitment}

# Certificate immediately becomes invalid
# verify_certificate will now fail
```

### Use Case 5: Building Auditor Reputation

```bash
# Auditor issues multiple certificates
for i in {1..10}; do
    leo run issue_certificate \
        {recipient_$i} {cert_id_$i} {program_hash_$i} 2u8 {time} {expiry} {auditor}
done

# Check reputation
leo run get_auditor_reputation {auditor_commitment}
# Returns count: 10u64
```

---

## Integration Examples

### Wallet Integration (JavaScript)

```javascript
// Example: Verify a project before allowing interaction

class CertificateVerifier {
    async verifyProject(certificate, programHash, minStandard = 2) {
        try {
            // 1. Check program hash matches
            const hashMatch = await this.executeTransition(
                'verify_program_hash',
                [certificate, programHash]
            );
            
            if (!hashMatch) {
                return { valid: false, reason: 'Program hash mismatch' };
            }
            
            // 2. Check certificate is valid and meets standard
            const currentTime = Math.floor(Date.now() / 1000);
            const isValid = await this.executeTransition(
                'verify_certificate',
                [certificate, currentTime, minStandard]
            );
            
            if (!isValid) {
                return { valid: false, reason: 'Certificate invalid or expired' };
            }
            
            // 3. Check auditor reputation
            const reputation = await this.getAuditorReputation(
                certificate.auditor_commitment
            );
            
            return {
                valid: true,
                standardLevel: certificate.standard_level,
                auditorReputation: reputation,
                expiresAt: certificate.expires_at
            };
            
        } catch (error) {
            return { valid: false, reason: error.message };
        }
    }
    
    async executeTransition(name, inputs) {
        // Implementation depends on Aleo SDK
        // This is pseudo-code
        const program = await aleo.getProgram('zkaudit.aleo');
        const result = await program.execute(name, inputs);
        return result;
    }
    
    async getAuditorReputation(auditorCommitment) {
        const mapping = await aleo.getMappingValue(
            'zkaudit.aleo',
            'auditor_certificate_count',
            auditorCommitment
        );
        return mapping || 0;
    }
}
```

### DApp UI Integration (React)

```jsx
function CertificationBadge({ certificate }) {
    const [verified, setVerified] = useState(false);
    const [reputation, setReputation] = useState(0);
    
    useEffect(() => {
        const verify = async () => {
            const verifier = new CertificateVerifier();
            const result = await verifier.verifyProject(
                certificate,
                programHash,
                2  // Require Standard level
            );
            
            setVerified(result.valid);
            setReputation(result.auditorReputation);
        };
        
        verify();
    }, [certificate]);
    
    const standardLabels = {
        1: 'Basic',
        2: 'Standard',
        3: 'Advanced',
        4: 'Critical'
    };
    
    if (!verified) return null;
    
    return (
        <div className="certification-badge">
            <span className="badge-icon">🛡️</span>
            <div className="badge-content">
                <h4>Security Audited</h4>
                <p>Level: {standardLabels[certificate.standard_level]}</p>
                <p>Auditor Reputation: {reputation} audits</p>
                {certificate.expires_at > 0 && (
                    <p className="expiry">
                        Expires: {new Date(certificate.expires_at * 1000).toLocaleDateString()}
                    </p>
                )}
            </div>
        </div>
    );
}
```

---

## Best Practices

### For Auditors

1. **Use unique commitments** for each audit context
2. **Set reasonable expiration dates** (typically 6-12 months)
3. **Document off-chain** the full audit report securely
4. **Revoke promptly** if issues are discovered
5. **Build reputation** by issuing quality certificates

### For Project Owners

1. **Store certificates securely** - they're valuable assets
2. **Re-audit regularly** before certificates expire
3. **Display badges prominently** in UI/documentation
4. **Update certificates** when code changes significantly
5. **Verify certificate validity** before presenting to users

### For Verifiers

1. **Always verify** both program hash and certificate validity
2. **Check expiration dates** - expired certificates should not be trusted
3. **Consider auditor reputation** as a signal of quality
4. **Require appropriate standard levels** for your use case
5. **Implement fallback behavior** for unaudited programs

---

## Troubleshooting

### Certificate Verification Fails

```bash
# Check if certificate is revoked
# This will fail if revoked:
leo run verify_certificate ...

# Check if expired
# Calculate: current_time > expires_at
```

### Auditor Registration Issues

```bash
# Ensure commitment is unique
# Check if already registered
leo run get_auditor_reputation {commitment}
# If returns > 0, already registered
```

### Program Hash Mismatch

```bash
# Ensure consistent hashing
# Include all relevant files and config
# Use same hash algorithm as auditor
```

---

For more information, see the main [README.md](README.md).
