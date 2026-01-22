# zkAudit FAQ

Frequently asked questions about the zkAudit protocol.

## General Questions

### What is zkAudit?

zkAudit is a privacy-preserving certification protocol for Aleo programs. It allows auditors to issue verifiable security credentials to projects without revealing sensitive audit details, auditor identities, or proprietary implementation specifics.

### Why use zkAudit instead of traditional audit reports?

Traditional audit reports:
- Reveal sensitive vulnerability details publicly
- Expose auditor identities
- May leak proprietary implementation details
- Cannot be verified on-chain

zkAudit provides:
- ✅ On-chain verification without revealing details
- ✅ Privacy-preserving auditor identification
- ✅ Verifiable credentials using zero-knowledge proofs
- ✅ Protection of proprietary information

### How does zkAudit maintain privacy?

zkAudit uses:
1. **Private Records**: Certificates are Leo records, visible only to owner
2. **Commitments**: Auditors identified by cryptographic commitments, not addresses
3. **Hashes**: Program and reason details stored as hashes, not plaintext
4. **Zero-Knowledge**: Aleo's zk-SNARK execution ensures privacy

### Is zkAudit only for Aleo programs?

Yes, zkAudit v0.1.0 is designed specifically for Aleo programs. However, the concepts could be adapted to other zero-knowledge platforms in the future.

## For Auditors

### How do I become a registered auditor?

1. Generate an auditor commitment (off-chain)
2. Call `register_auditor` with your commitment
3. Pay transaction fee (~10,000 credits)

See [EXAMPLES.md](EXAMPLES.md#auditor-workflows) for details.

### What's an auditor commitment?

An auditor commitment is a cryptographic hash that identifies you without revealing your identity:

```
commitment = hash(private_key || salt || domain_separator)
```

It allows you to:
- Issue certificates under pseudonym
- Build reputation without revealing identity
- Prove ownership of commitment privately

### Can I have multiple auditor commitments?

Yes, you can register multiple commitments. However:
- Each commitment builds separate reputation
- Consider using one commitment to consolidate reputation
- Multiple commitments may be useful for different audit types

### How do I issue a certificate?

After registration:

```bash
leo run issue_certificate \
    {recipient_address} \
    {unique_certificate_id} \
    {program_hash} \
    {standard_level} \
    {issued_timestamp} \
    {expiration_timestamp} \
    {your_auditor_commitment}
```

The certificate is automatically sent to the recipient as a private record.

### What if I discover a vulnerability after issuing a certificate?

Use the revocation mechanism:

```bash
leo run revoke_certificate \
    {certificate_record} \
    {revocation_timestamp} \
    {reason_hash} \
    {your_commitment}
```

This immediately invalidates the certificate. All future verification attempts will fail.

### How is my reputation calculated?

Reputation = Total number of certificates issued

This is tracked in the `auditor_certificate_count` mapping. Anyone can query:

```bash
leo run get_auditor_reputation {your_commitment}
```

### Can revocations damage my reputation?

Currently, revocations don't directly decrease your certificate count. However:
- Frequent revocations may indicate poor initial audits
- Community may track revocation rates off-chain
- Future versions may include revocation metrics

## For Projects

### How do I get a certificate?

1. Hire a registered auditor
2. Auditor performs security audit
3. Auditor issues certificate to your address
4. You receive Certificate record in your wallet

### What do the standard levels mean?

- **Level 1 (Basic)**: Code review, basic security checks
- **Level 2 (Standard)**: Comprehensive audit, automated testing
- **Level 3 (Advanced)**: Formal verification, advanced threat modeling
- **Level 4 (Critical)**: Maximum security for high-value systems

Choose based on your project's risk profile and user requirements.

### How do I prove my project is certified?

To users/integrators:
1. Share your Certificate record (privately)
2. They verify using `verify_certificate` transition
3. They can check program hash matches using `verify_program_hash`

You can also:
- Display certification badge in UI
- Link to on-chain verification
- Share auditor reputation metrics

### What if I update my program after certification?

Certificates are bound to specific program hashes. If you update your code:
1. Program hash changes
2. Old certificate no longer matches
3. You need a new audit and certificate

This ensures certificates always correspond to audited code version.

### Can I transfer my certificate?

Yes! Use the `transfer_certificate` transition:

```bash
leo run transfer_certificate \
    {your_certificate} \
    {new_owner_address}
```

Useful for:
- Project sales
- Ownership changes
- Organizational restructuring

### What happens if my certificate expires?

Expired certificates fail verification. You need to:
1. Get a new audit (if code changed)
2. Request certificate renewal (if code unchanged)
3. Receive new certificate with updated expiration

### Can I have multiple certificates?

Yes! You can have:
- Multiple certificates from different auditors
- Certificates for different program versions
- Certificates at different standard levels

Each certificate is independent.

## For Verifiers (Users/Integrators/Wallets)

### How do I verify a certificate?

1. Project provides Certificate record
2. Call `verify_certificate` with:
   - Certificate
   - Current timestamp
   - Minimum standard level required

3. Call `verify_program_hash` to ensure certificate matches program

If both succeed, the certificate is valid!

### What should I check before trusting a certificate?

Verification checklist:
- ✅ Certificate not expired (`verify_certificate`)
- ✅ Certificate not revoked (automatic in `verify_certificate`)
- ✅ Certificate meets minimum standard level
- ✅ Certificate matches deployed program (`verify_program_hash`)
- ✅ Auditor has reasonable reputation (`get_auditor_reputation`)

### How do I check auditor reputation?

```bash
leo run get_auditor_reputation {auditor_commitment_from_certificate}
```

Or query the `auditor_certificate_count` mapping directly.

Higher count generally indicates:
- More experience
- Longer track record
- Higher trust (though not guaranteed)

### What if a project shows an expired certificate?

Expired certificates should not be trusted. The project needs:
- Re-audit if code changed significantly
- Certificate renewal if code unchanged

Your application should:
- Display warning for expired certificates
- Require valid certificates for sensitive operations
- Encourage projects to maintain current certifications

### Can I verify certificates without revealing my identity?

Yes! Verification uses Aleo's zero-knowledge execution:
- Your verification queries are private
- No one knows which certificates you're checking
- No on-chain record of your verification attempts

### What if no certificate is provided?

This is a policy decision for your application:

**Conservative approach**:
- Require certificates for all interactions
- Show warnings for uncertified programs
- Limit functionality for uncertified programs

**Permissive approach**:
- Allow uncertified programs with disclaimer
- Display certification status clearly
- Let users decide risk tolerance

## Technical Questions

### What's the on-chain storage cost?

Per certificate:
- Certificate record: ~248 bytes (private, off-chain in user wallet)
- Revocation mapping entry: ~9 bytes (on-chain)
- Auditor count entry: ~16 bytes (on-chain)

Total on-chain storage per certificate: ~25 bytes

### What are the transaction costs?

Approximate costs in credits:
- Register auditor: ~10,000
- Issue certificate: ~15,000
- Verify certificate: ~5,000
- Revoke certificate: ~12,000
- Transfer certificate: ~3,000
- Verify program hash: ~2,000

### Can the protocol be upgraded?

Aleo programs are immutable once deployed. Upgrades require:
1. Deploy new version (e.g., zkaudit_v2.aleo)
2. Migrate users and auditors
3. Maintain both versions during transition
4. Eventually deprecate old version

### How scalable is zkAudit?

Very scalable:
- Certificate storage: Linear in number of certificates
- Verification time: O(1) constant time
- No quadratic complexity factors
- Can handle millions of certificates

### Is the protocol audited?

zkAudit v0.1.0 has not yet been professionally audited. 

Planned: Professional security audit in Q2 2026.

We welcome security researchers to review the code.

## Privacy Questions

### What information is public?

Public information:
- Auditor commitments (not identities)
- Certificate revocation status
- Certificate issuance counts per auditor

Private information:
- Certificate details (owner, program hash, standard level)
- Audit findings and vulnerability details
- Actual auditor identities
- Program source code

### Can someone link my certificate to my identity?

Not through the protocol itself. However:
- If you publicly announce your certificate
- If auditor reveals certificate details
- If you use same address for other public activities

Best practices:
- Use dedicated addresses for certificates
- Don't publicly link certificates to identity
- Be careful with off-chain communication

### Can auditors see each other's certificates?

No. Certificates are private records only visible to:
- Certificate owner
- Anyone the owner explicitly shares with

Auditors cannot see:
- Other auditors' certificates
- Which programs have been certified
- Certificate details (unless publicly shared)

### How are program hashes kept private?

Program hashes are:
- Stored in private Certificate records
- Not revealed in public mappings
- Only known to certificate owner and auditor

When verifying, the hash comparison happens in zero-knowledge.

## Integration Questions

### How do I integrate zkAudit into my wallet?

See [EXAMPLES.md](EXAMPLES.md#wallet-integration-javascript) for detailed example.

Key steps:
1. Detect certificates in user's wallet
2. Verify certificate validity
3. Display certification badge
4. Check auditor reputation
5. Warn about expired/invalid certificates

### Can I build a marketplace using zkAudit?

Yes! You can:
- Filter programs by certification status
- Display certification badges
- Sort by standard level or auditor reputation
- Require certifications for featured listings

### How do I display a certification badge?

Example badge:

```html
<div class="certification-badge">
    <span class="icon">🛡️</span>
    <span class="text">Security Audited</span>
    <span class="level">Level 2 - Standard</span>
    <span class="auditor">Auditor Reputation: 42 audits</span>
</div>
```

Customize based on your application's design.

### Can I use zkAudit with non-Aleo programs?

Not directly. zkAudit v0.1.0 is designed for Aleo programs using Leo and Aleo's execution model.

However, concepts could be adapted for other platforms.

## Economic Questions

### How much does it cost to get certified?

Certificate issuance cost: ~15,000 credits (~$0.15-$1.50 depending on market)

Plus auditor fees (off-protocol):
- Basic audit: Varies widely based on complexity
- Standard audit: $5,000 - $50,000+
- Advanced audit: $50,000 - $200,000+
- Critical audit: $200,000+

### How do auditors get paid?

Auditor payment happens off-chain:
- Direct payment from project to auditor
- Payment in Aleo credits, stablecoins, or fiat
- Negotiated based on scope and complexity

zkAudit protocol only tracks certification, not payment.

### Is there a fee for verification?

Yes, verification costs ~5,000 credits per check.

However:
- One-time verification often sufficient
- Can cache verification results
- Cost is low compared to security benefit

### Can I offer free certifications?

Yes! As an auditor, you can:
- Issue certificates to projects for free
- Absorb transaction costs
- Build reputation and portfolio

Some reasons for free certificates:
- Open source projects
- Educational purposes
- Portfolio building
- Community contribution

## Support and Community

### Where can I get help?

- **GitHub Issues**: Bug reports and questions
- **GitHub Discussions**: Feature requests and ideas
- **Discord**: Join Aleo Discord #zkaudit channel
- **Email**: support@zkaudit.org

### How can I contribute?

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

Ways to contribute:
- Code improvements
- Documentation updates
- Bug reports
- Feature suggestions
- Community support
- Integrations and tools

### Where can I find examples?

See [EXAMPLES.md](EXAMPLES.md) for comprehensive examples covering:
- Auditor workflows
- Project owner workflows
- Verifier workflows
- Integration examples

### Is there a roadmap?

See [README.md](README.md#roadmap) for the roadmap.

Highlights:
- v0.2.0: Multi-signature auditor support
- v0.3.0: Governance and tiered auditors
- v1.0.0: Cross-chain verification, insurance integration

---

## Still have questions?

- Open an issue: [GitHub Issues](https://github.com/Official-zkAudit/zkaudit/issues)
- Join the discussion: [GitHub Discussions](https://github.com/Official-zkAudit/zkaudit/discussions)
- Email us: support@zkaudit.org
