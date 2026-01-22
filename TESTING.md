# zkAudit Test Scenarios

This document outlines test scenarios for the zkAudit protocol to ensure correctness and security.

## Test Categories

1. Auditor Registration Tests
2. Certificate Issuance Tests
3. Certificate Verification Tests
4. Certificate Revocation Tests
5. Certificate Transfer Tests
6. Program Hash Verification Tests
7. Edge Cases and Security Tests

---

## 1. Auditor Registration Tests

### Test 1.1: Valid Auditor Registration

**Setup**: New auditor with unique commitment

**Action**:
```bash
leo run register_auditor 12345678901234567890field
```

**Expected**: 
- Transaction succeeds
- `registered_auditors[12345678901234567890field] = 1`
- `auditor_certificate_count[12345678901234567890field] = 0`

### Test 1.2: Duplicate Auditor Registration

**Setup**: Auditor already registered

**Action**:
```bash
leo run register_auditor 12345678901234567890field  # Second time
```

**Expected**: 
- Transaction succeeds (overwrites with same value)
- No error (idempotent operation)

---

## 2. Certificate Issuance Tests

### Test 2.1: Valid Certificate Issuance

**Setup**: Registered auditor issues certificate

**Action**:
```bash
leo run issue_certificate \
    aleo1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqq3ljyzc \
    11111111111111111111field \
    99999999999999999999field \
    2u8 \
    1700000000u64 \
    1731536000u64 \
    12345678901234567890field
```

**Expected**:
- Certificate record created
- `auditor_certificate_count[12345678901234567890field] += 1`
- `revoked_certificates[11111111111111111111field] = 0`

### Test 2.2: Unregistered Auditor Issues Certificate

**Setup**: Auditor not registered

**Action**:
```bash
leo run issue_certificate \
    aleo1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqq3ljyzc \
    22222222222222222222field \
    99999999999999999999field \
    2u8 \
    1700000000u64 \
    1731536000u64 \
    99999999999999999999field  # Unregistered commitment
```

**Expected**:
- Transaction fails in finalize
- Error: Auditor not registered (assert_eq fails)

### Test 2.3: Certificate with No Expiration

**Setup**: Registered auditor issues certificate with 0u64 expiration

**Action**:
```bash
leo run issue_certificate \
    aleo1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqq3ljyzc \
    33333333333333333333field \
    99999999999999999999field \
    3u8 \
    1700000000u64 \
    0u64 \  # No expiration
    12345678901234567890field
```

**Expected**:
- Certificate created with expires_at = 0u64
- Certificate never expires

### Test 2.4: Multiple Certificates from Same Auditor

**Setup**: Registered auditor issues multiple certificates

**Action**:
```bash
leo run issue_certificate {...} 11111field  # First
leo run issue_certificate {...} 22222field  # Second
leo run issue_certificate {...} 33333field  # Third
```

**Expected**:
- All certificates issued successfully
- `auditor_certificate_count` increments to 3

---

## 3. Certificate Verification Tests

### Test 3.1: Verify Valid Certificate

**Setup**: Valid certificate, not expired, not revoked

**Action**:
```bash
leo run verify_certificate \
    {certificate_record} \
    1705000000u64 \  # Current time < expiration
    1u8              # Minimum standard
```

**Expected**:
- Returns (Certificate, true)
- Finalize succeeds (not revoked)

### Test 3.2: Verify Expired Certificate

**Setup**: Certificate with expiration in past

**Action**:
```bash
leo run verify_certificate \
    {certificate_record} \
    1800000000u64 \  # Current time > expiration
    1u8
```

**Expected**:
- Returns (Certificate, false)
- Certificate marked as invalid due to expiration

### Test 3.3: Verify Certificate Below Minimum Standard

**Setup**: Certificate with standard_level = 1

**Action**:
```bash
leo run verify_certificate \
    {certificate_record} \
    1705000000u64 \
    3u8  # Require level 3, but certificate is level 1
```

**Expected**:
- Returns (Certificate, false)
- Does not meet minimum standard

### Test 3.4: Verify Revoked Certificate

**Setup**: Certificate that has been revoked

**Action**:
```bash
leo run verify_certificate \
    {revoked_certificate_record} \
    1705000000u64 \
    1u8
```

**Expected**:
- Transaction fails in finalize
- Error: Certificate revoked (assert_eq fails)

### Test 3.5: Verify Certificate with No Expiration

**Setup**: Certificate with expires_at = 0u64

**Action**:
```bash
leo run verify_certificate \
    {certificate_record} \
    9999999999u64 \  # Far future time
    1u8
```

**Expected**:
- Returns (Certificate, true)
- Certificate never expires

---

## 4. Certificate Revocation Tests

### Test 4.1: Valid Certificate Revocation

**Setup**: Auditor revokes their own certificate

**Action**:
```bash
leo run revoke_certificate \
    {certificate_record} \
    1710000000u64 \
    55555555555555555555field \
    12345678901234567890field  # Matching auditor commitment
```

**Expected**:
- RevocationProof record created
- `revoked_certificates[certificate_id] = 1`
- Future verifications fail

### Test 4.2: Revoke Certificate with Wrong Auditor

**Setup**: Different auditor tries to revoke certificate

**Action**:
```bash
leo run revoke_certificate \
    {certificate_record} \
    1710000000u64 \
    55555555555555555555field \
    99999999999999999999field  # Wrong auditor commitment
```

**Expected**:
- Transaction fails
- Error: Auditor commitment mismatch (assert_eq fails)

### Test 4.3: Revoke Already Revoked Certificate

**Setup**: Certificate already revoked

**Action**:
```bash
leo run revoke_certificate \
    {revoked_certificate_record} \
    1715000000u64 \
    66666666666666666666field \
    12345678901234567890field
```

**Expected**:
- Transaction succeeds (overwrites revocation status with 1)
- New RevocationProof created

---

## 5. Certificate Transfer Tests

### Test 5.1: Valid Certificate Transfer

**Setup**: Certificate owner transfers to new owner

**Action**:
```bash
leo run transfer_certificate \
    {certificate_record} \
    aleo1newowner...
```

**Expected**:
- New Certificate record created
- New owner = aleo1newowner...
- All other fields unchanged
- Original certificate consumed

### Test 5.2: Transfer to Same Owner

**Setup**: Transfer certificate to self

**Action**:
```bash
leo run transfer_certificate \
    {certificate_record} \
    aleo1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqq3ljyzc  # Same as current owner
```

**Expected**:
- New Certificate record created
- Owner unchanged
- All fields unchanged

---

## 6. Program Hash Verification Tests

### Test 6.1: Verify Matching Program Hash

**Setup**: Certificate with specific program hash

**Action**:
```bash
leo run verify_program_hash \
    {certificate_record} \
    99999999999999999999field  # Matches certificate.program_hash
```

**Expected**:
- Returns (Certificate, true)

### Test 6.2: Verify Non-Matching Program Hash

**Setup**: Certificate with different program hash

**Action**:
```bash
leo run verify_program_hash \
    {certificate_record} \
    88888888888888888888field  # Does not match
```

**Expected**:
- Returns (Certificate, false)

---

## 7. Auditor Reputation Tests

### Test 7.1: Get Reputation for Registered Auditor

**Setup**: Auditor with issued certificates

**Action**:
```bash
leo run get_auditor_reputation 12345678901234567890field
```

**Expected**:
- Finalize succeeds
- Can query `auditor_certificate_count` mapping
- Returns count of certificates issued

### Test 7.2: Get Reputation for Unregistered Auditor

**Setup**: Auditor never registered

**Action**:
```bash
leo run get_auditor_reputation 99999999999999999999field
```

**Expected**:
- Finalize succeeds
- Returns 0u64 (get_or_use default)

---

## 8. Edge Cases and Security Tests

### Test 8.1: Certificate with Maximum Standard Level

**Setup**: Certificate with level 4 (critical)

**Action**:
```bash
leo run issue_certificate \
    {...} \
    4u8 \  # Maximum standard level
    {...}
```

**Expected**:
- Certificate created successfully
- Verifies with any minimum standard (1-4)

### Test 8.2: Certificate with Standard Level 0

**Setup**: Attempt to issue certificate with level 0

**Action**:
```bash
leo run issue_certificate \
    {...} \
    0u8 \  # Invalid standard level
    {...}
```

**Expected**:
- Certificate created (no validation in transition)
- May not meet any reasonable standard requirements
- Consider adding validation in future version

### Test 8.3: Verify with Zero Current Time

**Setup**: Verify certificate with current_time = 0

**Action**:
```bash
leo run verify_certificate \
    {certificate_record} \
    0u64 \  # Zero timestamp
    1u8
```

**Expected**:
- If expires_at > 0: Returns false (expired)
- If expires_at = 0: Returns true (not expired)

### Test 8.4: Certificate ID Collision

**Setup**: Two certificates with same ID from different auditors

**Action**:
```bash
# First certificate
leo run issue_certificate {...} 11111field {...}
# Second certificate with same ID
leo run issue_certificate {...} 11111field {...}
```

**Expected**:
- Both certificates created
- Second overwrites revocation status in mapping
- Potential issue: Should use unique IDs in practice

### Test 8.5: Maximum Auditor Certificate Count

**Setup**: Auditor issues many certificates

**Action**:
```bash
# Issue certificates until count approaches u64::MAX
for i in {1..1000}; do
    leo run issue_certificate {...}
done
```

**Expected**:
- All certificates issued
- Count increments correctly
- No overflow (u64 is very large)

---

## Integration Tests

### Integration Test 1: Full Certification Workflow

1. Register auditor
2. Issue certificate to project
3. Project verifies certificate
4. Verifier checks certificate
5. Verifier checks program hash
6. Verifier checks auditor reputation

**Expected**: All steps succeed

### Integration Test 2: Certification and Revocation

1. Register auditor
2. Issue certificate
3. Verify certificate (should succeed)
4. Discover vulnerability
5. Revoke certificate
6. Verify certificate (should fail)

**Expected**: Verification fails after revocation

### Integration Test 3: Multi-Auditor Scenario

1. Register auditor A
2. Register auditor B
3. Auditor A issues certificate to project X
4. Auditor B issues certificate to project Y
5. Verify both certificates
6. Check reputation for both auditors

**Expected**: Both auditors independent, both certificates valid

---

## Performance Tests

### Performance Test 1: Bulk Certificate Issuance

Issue 100 certificates sequentially

**Metrics**:
- Average transaction time
- Gas costs per certificate
- Mapping update performance

### Performance Test 2: Concurrent Verifications

Verify 50 certificates in parallel

**Metrics**:
- Verification throughput
- Read contention on mappings

---

## Security Tests

### Security Test 1: Attempt to Forge Certificate

Try to create certificate without calling issue_certificate

**Expected**: Not possible (records can only be created by transitions)

### Security Test 2: Attempt to Modify Certificate Fields

Try to modify certificate after creation

**Expected**: Not possible (records are immutable)

### Security Test 3: Replay Certificate to Different Program

Try to use certificate for different program

**Expected**: verify_program_hash returns false

---

## Test Execution Checklist

- [ ] All auditor registration tests pass
- [ ] All certificate issuance tests pass
- [ ] All certificate verification tests pass
- [ ] All certificate revocation tests pass
- [ ] All certificate transfer tests pass
- [ ] All program hash verification tests pass
- [ ] All edge case tests pass
- [ ] All integration tests pass
- [ ] All performance metrics acceptable
- [ ] All security tests pass

---

## Notes for Testers

1. Use unique values for certificate IDs in each test
2. Keep track of auditor commitments used
3. Document any unexpected behavior
4. Test on both testnet and local environment
5. Monitor gas costs for each operation
6. Verify privacy properties are maintained

---

For actual test execution, see the inputs/zkaudit.in file for example parameters.
