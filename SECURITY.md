# Security Policy

## Overview

zkAudit is a privacy-preserving certification protocol built on Aleo. Security is our top priority, and we take all security concerns seriously.

## Supported Versions

| Version | Supported          |
| ------- | ------------------ |
| 0.1.x   | :white_check_mark: |

## Reporting a Vulnerability

**Please do not report security vulnerabilities through public GitHub issues.**

Instead, please report them via email to: security@zkaudit.org (or create a GitHub Security Advisory)

Include the following information:
- Type of vulnerability
- Full paths of affected source files
- Location of affected code (tag/branch/commit or direct URL)
- Step-by-step instructions to reproduce
- Proof-of-concept or exploit code (if possible)
- Impact of the issue

We will respond within 48 hours and provide regular updates on progress toward a fix.

## Security Considerations

### Threat Model

zkAudit protects against:
- ✅ Unauthorized certificate issuance
- ✅ Certificate forgery
- ✅ Privacy breaches (audit details, auditor identity, program details)
- ✅ Replay attacks
- ✅ Post-audit vulnerabilities (via revocation)

zkAudit does NOT protect against:
- ❌ Malicious or colluding auditors
- ❌ Compromise of auditor private keys
- ❌ Social engineering attacks
- ❌ Bugs in audited programs themselves
- ❌ Off-chain audit report breaches

### Privacy Guarantees

**Private Information:**
- Audit findings and details
- Auditor identity (only commitment is public)
- Program implementation details
- Certificate ownership (record-based)

**Public Information:**
- Certificate revocation status
- Auditor commitments (not identities)
- Certificate issuance counts per auditor

### Best Practices for Auditors

1. **Key Management**
   - Use hardware wallets for auditor keys
   - Never reuse commitments
   - Store audit commitments securely
   - Implement key rotation policies

2. **Commitment Generation**
   ```
   commitment = hash(private_key || salt || domain_separator)
   ```
   - Use cryptographically secure randomness
   - Never derive commitments from predictable sources
   - Keep salt and private key secret

3. **Certificate Issuance**
   - Verify program thoroughly before issuance
   - Use unique certificate IDs (cryptographically random)
   - Set appropriate expiration dates
   - Document audit scope off-chain

4. **Revocation**
   - Revoke immediately if vulnerabilities found
   - Document reason securely off-chain
   - Notify affected parties through secure channels

### Best Practices for Projects

1. **Certificate Storage**
   - Store certificates in secure wallet
   - Back up certificate records
   - Never share private certificate details publicly
   - Implement access controls

2. **Program Hash Generation**
   ```
   program_hash = hash(source_code || dependencies || build_config || compiler_version)
   ```
   - Include all relevant code
   - Document hash generation process
   - Use consistent hashing across versions

3. **Verification**
   - Always verify certificate before displaying
   - Check expiration dates
   - Verify program hash matches
   - Re-verify periodically

### Best Practices for Verifiers

1. **Certificate Validation**
   - Always call `verify_certificate` transition
   - Check revocation status (automatic in verify)
   - Verify program hash matches deployed program
   - Check auditor reputation

2. **Trust Decisions**
   - Require appropriate standard levels for use case
   - Consider auditor reputation
   - Check certificate expiration
   - Implement fallback for unaudited programs

### Known Limitations

1. **Auditor Trust**
   - System relies on auditor honesty and competence
   - No on-chain governance for auditor registration (yet)
   - Reputation system is simple count-based

2. **Certificate Binding**
   - Program hash is provided by auditor
   - No on-chain verification of hash correctness
   - Projects could present wrong hash

3. **Revocation**
   - Revocation is auditor-initiated only
   - No community-based revocation mechanism
   - Requires auditor to discover post-audit issues

## Security Updates

We will release security updates through:
- GitHub Security Advisories
- Release notes with security fixes tagged
- Security mailing list (coming soon)

Critical security updates will be expedited.

## Audit Status

zkAudit itself has not yet been professionally audited. We welcome security researchers to review the code and report issues.

Planned: Professional security audit in Q2 2026.

## Responsible Disclosure

We follow a 90-day disclosure timeline:
1. Report received
2. Vulnerability confirmed (48 hours)
3. Fix developed and tested (30 days)
4. Patch released (60 days)
5. Public disclosure (90 days)

Critical vulnerabilities may be expedited.

## Bug Bounty

Coming soon: Bug bounty program for responsibly disclosed vulnerabilities.

## Contact

- Security issues: security@zkaudit.org
- General questions: GitHub Issues
- Private inquiries: maintainers@zkaudit.org

## Acknowledgments

We thank the security research community for helping keep zkAudit and the Aleo ecosystem secure.

## Security Checklist for Contributors

Before submitting code:
- [ ] No hardcoded secrets or keys
- [ ] All inputs validated
- [ ] Error conditions handled
- [ ] Privacy properties maintained
- [ ] Cryptographic operations reviewed
- [ ] Attack vectors considered
- [ ] Documentation updated
- [ ] Security tests added

---

Last updated: January 2026
