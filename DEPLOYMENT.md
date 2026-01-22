# zkAudit Deployment Guide

This guide walks you through deploying the zkAudit protocol to the Aleo network.

## Prerequisites

### Install Leo

```bash
# Install Leo programming language
curl -L https://raw.githubusercontent.com/AleoHQ/leo/testnet/install.sh | sh

# Verify installation
leo --version
```

### Install Aleo SDK (Optional)

```bash
# For advanced testing and development
npm install -g @aleohq/sdk
```

### Setup Wallet

You'll need an Aleo wallet with credits for deployment.

```bash
# Generate new account (or use existing)
leo account new

# Output:
# Private Key: APrivateKey1...
# View Key: AViewKey1...
# Address: aleo1...
```

⚠️ **IMPORTANT**: Securely store your private key! Never commit it to version control.

## Local Testing

### 1. Build the Program

```bash
cd zkaudit
leo build
```

Expected output:
```
Compiling zkaudit.aleo...
✅ Compiled 'zkaudit.aleo'
```

### 2. Run Local Tests

Test individual transitions:

```bash
# Test auditor registration
leo run register_auditor 12345678901234567890field

# Test certificate issuance
leo run issue_certificate \
    aleo1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqq3ljyzc \
    11111111111111111111field \
    99999999999999999999field \
    2u8 \
    1700000000u64 \
    1731536000u64 \
    12345678901234567890field
```

### 3. Test with Input File

```bash
# Run with pre-defined inputs
leo run --input inputs/zkaudit.in register_auditor
leo run --input inputs/zkaudit.in issue_certificate
```

## Testnet Deployment

### 1. Configure Network

Set up testnet configuration:

```bash
# Set network to testnet
export NETWORK=testnet

# Or add to program.json:
{
  "program": "zkaudit.aleo",
  "version": "0.1.0",
  "network": "testnet",
  "description": "Privacy-preserving certification protocol for Aleo programs",
  "license": "MIT"
}
```

### 2. Fund Your Account

Get testnet credits:

```bash
# Visit Aleo faucet
# https://faucet.aleo.org/

# Enter your address: aleo1...
# Request credits
```

Verify balance:

```bash
# Check credits balance
leo account balance --address aleo1...
```

### 3. Deploy to Testnet

```bash
# Deploy program
leo deploy --network testnet

# You'll be prompted for:
# - Private key
# - Program name (zkaudit.aleo)
# - Fee amount
```

Expected output:
```
Deploying zkaudit.aleo to testnet...
✅ Successfully deployed zkaudit.aleo
Program ID: zkaudit.aleo
Transaction: at1...
```

### 4. Verify Deployment

```bash
# Verify program is deployed
aleo program info zkaudit.aleo --network testnet

# Check transaction
aleo transaction info at1... --network testnet
```

## Mainnet Deployment

⚠️ **WARNING**: Mainnet deployment is permanent and costs real credits. Test thoroughly on testnet first!

### Pre-Deployment Checklist

- [ ] Thoroughly tested on testnet
- [ ] Security audit completed
- [ ] Code review passed
- [ ] Documentation complete
- [ ] Sufficient mainnet credits (~1,000,000+ for deployment)
- [ ] Backup of private keys
- [ ] Emergency response plan

### Deploy to Mainnet

```bash
# Set network to mainnet
export NETWORK=mainnet

# Deploy (requires confirmation)
leo deploy --network mainnet --private-key APrivateKey1...

# Confirm deployment details
# Program: zkaudit.aleo
# Network: mainnet
# Fee: ~1,000,000 credits
```

### Post-Deployment

1. **Verify Deployment**
   ```bash
   aleo program info zkaudit.aleo --network mainnet
   ```

2. **Test Critical Functions**
   ```bash
   # Test registration
   leo execute register_auditor 12345678901234567890field \
       --network mainnet \
       --private-key APrivateKey1...
   ```

3. **Announce Deployment**
   - Update documentation with program ID
   - Announce on social media
   - Add to Aleo ecosystem directory

## Upgrading

⚠️ **NOTE**: Aleo programs are immutable once deployed. Upgrades require deploying a new version.

### Migration Strategy

1. **Deploy New Version**
   ```bash
   # Update program name
   # e.g., zkaudit_v2.aleo
   leo deploy --network mainnet
   ```

2. **Announce Deprecation**
   - Document migration path
   - Set deprecation timeline
   - Notify users and auditors

3. **Data Migration**
   - Export necessary state
   - Provide migration tools
   - Support both versions temporarily

## Monitoring

### Track Program Usage

```bash
# View recent transactions
aleo program transactions zkaudit.aleo --network mainnet --limit 10

# Monitor certificate issuance
aleo mapping get registered_auditors --network mainnet

# Check auditor counts
aleo mapping get auditor_certificate_count --network mainnet
```

### Set Up Alerts

```javascript
// Example: Monitor for revocations
const monitorRevocations = async () => {
    const mapping = await aleo.getMapping(
        'zkaudit.aleo',
        'revoked_certificates',
        'mainnet'
    );
    
    // Check for new revocations
    // Alert if any high-profile certificates revoked
};
```

## Cost Analysis

### Deployment Costs

| Action | Testnet | Mainnet |
|--------|---------|---------|
| Deploy Program | ~100,000 credits | ~1,000,000 credits |
| Register Auditor | ~10,000 credits | ~10,000 credits |
| Issue Certificate | ~15,000 credits | ~15,000 credits |
| Verify Certificate | ~5,000 credits | ~5,000 credits |
| Revoke Certificate | ~12,000 credits | ~12,000 credits |

*Costs are estimates and may vary based on network conditions*

### Fee Optimization

- Batch operations when possible
- Use off-chain verification when appropriate
- Cache mapping reads
- Minimize state transitions

## Troubleshooting

### Common Issues

#### 1. Deployment Fails - Insufficient Credits

```
Error: Insufficient credits for deployment
```

**Solution**: Fund account with more credits
```bash
# Check balance
leo account balance --address aleo1...

# Get more credits from faucet (testnet)
# Or purchase credits (mainnet)
```

#### 2. Program Name Conflict

```
Error: Program zkaudit.aleo already exists
```

**Solution**: Use different program name or version
```json
{
  "program": "zkaudit_v2.aleo"
}
```

#### 3. Transaction Timeout

```
Error: Transaction timeout after 300s
```

**Solution**: 
- Increase timeout: `--timeout 600`
- Check network status
- Retry with higher fee

#### 4. Invalid Inputs

```
Error: Invalid input format
```

**Solution**: Check input file format
```bash
# Verify inputs match expected types
leo run register_auditor 12345field  # Must be field type
```

## Security Considerations

### Deployment Security

1. **Private Key Management**
   - Use hardware wallet for mainnet
   - Never expose private key
   - Rotate keys periodically (for new deployments)

2. **Code Verification**
   - Review code before deployment
   - Check dependencies
   - Verify build reproducibility

3. **Access Control**
   - Limit who can deploy
   - Use multi-sig for critical operations
   - Document deployment procedures

### Operational Security

1. **Monitoring**
   - Set up transaction monitoring
   - Alert on suspicious activity
   - Regular security audits

2. **Incident Response**
   - Define incident response plan
   - Contact information for team
   - Communication channels

3. **Backup and Recovery**
   - Backup all keys and credentials
   - Document recovery procedures
   - Test recovery process

## Integration After Deployment

### For Auditors

```bash
# 1. Register as auditor
leo execute register_auditor {your_commitment} \
    --network mainnet \
    --private-key {your_private_key}

# 2. Issue certificates
leo execute issue_certificate \
    {params...} \
    --network mainnet \
    --private-key {your_private_key}
```

### For Projects

```javascript
// Verify your certificate
const result = await aleo.execute(
    'zkaudit.aleo',
    'verify_certificate',
    [certificate, currentTime, minStandard],
    'mainnet'
);
```

### For Wallets/DApps

```javascript
// Integrate verification
import { AleoSDK } from '@aleohq/sdk';

const sdk = new AleoSDK('mainnet');
const program = await sdk.getProgram('zkaudit.aleo');

// Verify certificate before interaction
const isValid = await program.verify_certificate(...);
```

## Support

### Get Help

- **GitHub Issues**: Report bugs or ask questions
- **Discord**: Join Aleo Discord for community support
- **Documentation**: https://docs.zkaudit.org (coming soon)

### Report Issues

- Security issues: security@zkaudit.org
- Bug reports: GitHub Issues
- Feature requests: GitHub Discussions

## Checklist

### Pre-Deployment
- [ ] Code reviewed and tested
- [ ] Documentation complete
- [ ] Testnet deployment successful
- [ ] Security audit completed
- [ ] Sufficient credits available

### Deployment
- [ ] Program deployed successfully
- [ ] Deployment verified on explorer
- [ ] Transaction ID recorded
- [ ] Program ID documented

### Post-Deployment
- [ ] Critical functions tested
- [ ] Monitoring set up
- [ ] Documentation updated
- [ ] Community notified
- [ ] Support channels active

---

For more information, see:
- [README.md](README.md) - Protocol overview
- [TECHNICAL_SPEC.md](TECHNICAL_SPEC.md) - Technical details
- [EXAMPLES.md](EXAMPLES.md) - Usage examples
