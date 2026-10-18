# Security Policy

## Reporting a vulnerability

If you discover a security issue in Earbar, please report it
privately rather than opening a public issue:

- Use GitHub's private vulnerability reporting:
  [Report a vulnerability](https://github.com/diovaniomota/earbar/security/advisories/new)

Please include steps to reproduce and the affected version. You'll get an
acknowledgement as soon as possible, and a fix will be prioritized.

## Scope

This app runs locally and talks only to your earbuds over Bluetooth. It makes no
network connections and collects no data, so the attack surface is limited to:

- The local Bluetooth/SPP message parsing.
- The app bundle and its distribution (`.dmg`).

## Supported versions

The latest release receives security fixes. Older versions are not maintained —
please update to the newest version.

## Verifying downloads

Each release `.dmg` has a SHA-256 published in the GitHub release notes. Verify it before installing:

```bash
shasum -a 256 Earbar-<version>.dmg
```
