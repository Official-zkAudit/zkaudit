# Contributing to zkAudit

Thank you for your interest in contributing to zkAudit! This document provides guidelines and instructions for contributing.

## Code of Conduct

Be respectful, inclusive, and professional. We're building this for the entire Aleo ecosystem.

## How to Contribute

### Reporting Bugs

If you find a bug, please create an issue with:
- Clear description of the bug
- Steps to reproduce
- Expected vs actual behavior
- Leo version and environment details

### Suggesting Enhancements

Enhancement suggestions are welcome! Please include:
- Clear description of the enhancement
- Use case and motivation
- Potential implementation approach (if known)

### Pull Requests

1. **Fork the repository**
   ```bash
   git clone https://github.com/Official-zkAudit/zkaudit.git
   cd zkaudit
   ```

2. **Create a feature branch**
   ```bash
   git checkout -b feature/your-feature-name
   ```

3. **Make your changes**
   - Follow the existing code style
   - Add comments for complex logic
   - Update documentation as needed

4. **Test your changes**
   ```bash
   leo build
   leo test
   ```

5. **Commit your changes**
   ```bash
   git add .
   git commit -m "feat: add your feature description"
   ```

   Use conventional commits:
   - `feat:` for new features
   - `fix:` for bug fixes
   - `docs:` for documentation changes
   - `test:` for test additions/changes
   - `refactor:` for code refactoring

6. **Push and create PR**
   ```bash
   git push origin feature/your-feature-name
   ```
   Then create a pull request on GitHub.

## Development Guidelines

### Leo Code Style

- Use clear, descriptive variable names
- Add comments for complex transitions
- Follow Aleo's Leo best practices
- Ensure all transitions have proper error handling

### Documentation

- Update README.md for new features
- Add examples to EXAMPLES.md
- Include inline code documentation
- Keep documentation in sync with code

### Testing

- Test all new transitions
- Include edge cases
- Test error conditions
- Verify privacy properties

### Security

- Never commit private keys or secrets
- Review cryptographic operations carefully
- Consider attack vectors
- Document security assumptions

## Project Structure

```
zkaudit/
├── src/
│   └── main.leo          # Main program code
├── inputs/
│   └── zkaudit.in        # Example inputs
├── build/                 # Build artifacts (gitignored)
├── program.json          # Program metadata
├── README.md             # Main documentation
├── EXAMPLES.md           # Usage examples
├── CONTRIBUTING.md       # This file
└── LICENSE               # MIT License
```

## Review Process

1. All PRs require review before merging
2. CI checks must pass
3. Documentation must be updated
4. Tests must be included for new features

## Questions?

- Open an issue for questions
- Tag with `question` label
- Maintainers will respond

## License

By contributing, you agree that your contributions will be licensed under the MIT License.
