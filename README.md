# zkAudit 🛡️

**Privacy-Preserving Security Certification Protocol for Aleo Programs**

[![Aleo](https://img.shields.io/badge/Built%20on-Aleo-blue)](https://aleo.org)
[![Leo](https://img.shields.io/badge/Language-Leo-green)](https://docs.leo-lang.org)
[![License](https://img.shields.io/badge/License-MIT-yellow)](LICENSE)

> *"Prove your program is audited without revealing who audited it or what they found."*

## 🎯 Problem Statement

In privacy-focused blockchains like Aleo, there's a fundamental paradox:
- **Users want privacy** for their transactions and interactions
- **Users also want trust** that applications they use are secure
- **Traditional trust mechanisms** (public audits) break the privacy model

**zkAudit solves this** by enabling private, verifiable security certifications.

## ✨ Key Features

| Feature | Description |
|---------|-------------|
| **Private Certifications** | Audit results stored as encrypted records, only visible to the owner |
| **Selective Disclosure** | Prove "level ≥ X" without revealing exact level or auditor |
| **Auditor Anonymity** | Verifications don't reveal which auditor issued the certification |
| **Composable** | Other Aleo programs can verify certifications programmatically |
| **Revocation** | Certifications can be revoked by auditor, owner, or admin |
| **Tiered Auditors** | Different auditor tiers can issue different certification levels |

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           zkAudit Protocol Flow                              │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  ┌──────────────┐     ┌──────────────┐     ┌──────────────┐                │
│  │   Phase 1    │────▶│   Phase 2    │────▶│   Phase 3    │                │
│  │  Off-Chain   │     │  Issuance    │     │ Verification │                │
│  │    Audit     │     │  (Private)   │     │  (ZK Proof)  │                │
│  └──────────────┘     └──────────────┘     └──────────────┘                │
│         │                    │                    │                        │
│         ▼                    ▼                    ▼                        │
│  ┌──────────────┐     ┌──────────────┐     ┌──────────────┐                │
│  │ Auditor      │     │ Private      │     │ Public proof │                │
│  │ reviews code │     │ record       │     │ "level ≥ X"  │                │
│  │ off-chain    │     │ created      │     │ verified     │                │
│  └──────────────┘     └──────────────┘     └──────────────┘                │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

## 📦 Installation

### Prerequisites

1. **Rust & Cargo**
   ```bash
   curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
   ```

2. **Leo Language**
   ```bash
   cargo install leo-lang
   ```

3. **Verify Installation**
   ```bash
   leo --version
   ```

### Setup

```bash
# Clone the repository
git clone https://github.com/trinnode/zkAudit.git
cd zkAudit

# Build the program
leo build

# Run the demo
./run.sh
```

## 🚀 Quick Start

### 1. Initialize the Protocol

```bash
# Set admin private key
echo 'NETWORK=testnet
PRIVATE_KEY=APrivateKey1zkp...' > .env

# Initialize
leo run initialize
```

### 2. Register an Auditor

```bash
# As admin, register a Tier 2 auditor
leo run register_auditor \
    aleo1auditor... \    # auditor address
    2u8 \                # tier (1=Individual, 2=Firm, 3=Elite)
    1737590400u64 \      # timestamp
    12345field           # nonce
```

### 3. Issue a Certification

```bash
# Switch to auditor key, then issue cert
leo run issue_certification \
    aleo1project... \    # recipient (project owner)
    123456789field \     # program_id (hash of audited program)
    2u8 \                # level (1-4)
    1737590400u64 \      # issued_at
    1769126400u64 \      # expires_at (0 = never)
    987654321field \     # scope_hash
    111222333field       # nonce
```

### 4. Verify Certification

```bash
# Switch to project key, verify with the cert record
leo run verify_minimum_level \
    "{ owner: ..., program_id: ..., level: ..., ... }" \
    1u8 \                # minimum level required
    1737676800u64        # current timestamp
```

## 📋 Certification Levels

| Level | Name | Typical Scope | Auditor Tier Required |
|-------|------|---------------|----------------------|
| 1 | Basic | Automated scan | Tier 1+ |
| 2 | Standard | Full manual review | Tier 1+ |
| 3 | Advanced | Comprehensive + formal verification | Tier 2+ |
| 4 | Comprehensive | Multiple auditors, continuous monitoring | Tier 3 |

## 🔐 Privacy Guarantees

### What is Private

- ✅ Exact certification level
- ✅ Auditor identity
- ✅ Issuance/expiration dates
- ✅ Audit scope details
- ✅ Number of certifications held

### What is Public (by design)

- 📊 Protocol statistics (total certs issued)
- 📊 Verification cache (highest verified level per program)
- 📊 Auditor registry (which addresses are trusted)

## 🛠️ Program Structure

```
zkaudit/
├── src/
│   └── main.leo          # Main program (transitions, records, mappings)
├── program.json          # Leo project configuration
├── .env                  # Private key configuration (DO NOT COMMIT)
├── run.sh               # Demo script
├── README.md            # This file
└── zkAudit.md           # Yellow Paper (technical specification)
```

## 📜 Transitions Reference

| Transition | Description | Caller |
|------------|-------------|--------|
| `initialize` | Set up protocol admin | Anyone (once) |
| `transfer_admin` | Change protocol admin | Admin |
| `register_auditor` | Add trusted auditor | Admin |
| `deactivate_auditor` | Disable auditor | Admin |
| `reactivate_auditor` | Re-enable auditor | Admin |
| `issue_certification` | Create new certification | Auditor |
| `verify_minimum_level` | Prove cert meets minimum | Cert Owner |
| `verify_specific_auditor` | Prove cert from specific auditor | Cert Owner |
| `revoke_by_auditor` | Revoke own issued cert | Auditor |
| `self_revoke` | Revoke own held cert | Cert Owner |
| `admin_revoke` | Emergency revocation | Admin |
| `transfer_certification` | Transfer cert ownership | Cert Owner |

## 🧪 Testing

```bash
# Build and check for errors
leo build

# Run individual transitions
leo run initialize
leo run register_auditor <args>
# ... etc

# Run full demo
./run.sh
```

## 🌐 Deployment

### Testnet

```bash
# Ensure you have testnet credits
# Get from: https://faucet.aleo.org/

# Deploy
leo deploy --network testnet
```

### Mainnet (Future)

```bash
# Requires mainnet credits and thorough testing
leo deploy --network mainnet
```

## 🗺️ Roadmap

- [x] **Wave 1**: Core protocol (issue, verify, revoke)
- [ ] **Wave 2**: Multi-auditor support, React frontend
- [ ] **Wave 3**: Certification renewal, expiration handling
- [ ] **Wave 4**: Cross-program SDK
- [ ] **Wave 5**: Wallet badge integration
- [ ] **Wave 6-7**: Multisig admin, staking
- [ ] **Wave 8-9**: DAO governance, mainnet deploy
- [ ] **Wave 10**: Open auditor registration

## 🤝 Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## 📄 License

MIT License - see [LICENSE](LICENSE) for details.

## 📚 Resources

- [Aleo Developer Docs](https://developer.aleo.org/)
- [Leo Language Docs](https://docs.leo-lang.org/)
- [Leo Playground](https://play.leo-lang.org/)
- [Aleo Testnet Faucet](https://faucet.aleo.org/)

## 👤 Author

**Isah Dauda** (@_trinnex)  
Web3bridge Cohort XIII | Smart Contract Security Researcher

## 🏆 Acknowledgments

Built for the [AKINDO Aleo Privacy Buildathon](https://app.akindo.io/wave-hacks/gXdXJvJXxTJKBELvo)

---

*zkAudit - Building trust without breaking privacy.*