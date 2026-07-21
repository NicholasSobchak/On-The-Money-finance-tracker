# Security Policy

## Reporting a Vulnerability

If you discover a security vulnerability in On The Money, please report it responsibly.

**Contact:** nicholassobchak@gmail.com

Please include:
- Description of the vulnerability
- Steps to reproduce
- Potential impact
- Any suggested fixes

## Response Timeline

- **Acknowledgment:** Within 48 hours
- **Initial assessment:** Within 1 week
- **Resolution:** Depends on severity, typically within 2 weeks

## Security Measures

- All data is encrypted in transit (TLS 1.2+)
- Plaid access tokens are encrypted at rest using PostgreSQL pgcrypto
- API authentication required for all endpoints
- Multi-factor authentication (TOTP) supported
- Dependencies scanned regularly via Dependabot and OWASP
- No data is shared with third parties except through explicit Plaid linking

## Scope

This policy applies to the On The Money finance tracker application and its API.

## Safe Harbor

We will not take legal action against researchers who discover and report vulnerabilities in good faith, following responsible disclosure practices.
