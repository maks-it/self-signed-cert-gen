# Self-Signed Certificates & PSK Generator for Home Lab

Generate self-signed root certificates, device certificates, and Pre-Shared Keys (PSK) for your home lab environment. Supports both **Linux (Bash)** and **Windows (PowerShell)**.

## Features

| Feature | Linux (Bash) | Windows (PowerShell) |
|---------|--------------|----------------------|
| Root CA generation | `create_self_signed_root_cert.sh` | `New-SelfSignedRootCert.ps1` |
| Device certificates | `create_self_signed_cert.sh` | `New-SelfSignedCert.ps1` |
| PSK generation | `create_psk.sh` | `New-PskCert.ps1` |
| Install Root CA | Manual | `Install-RootCA.ps1` |

---

## Quick Start

### Linux (Bash)

```bash
cd src/bash

# 1. Generate Root CA
./create_self_signed_root_cert.sh

# 2. Generate device certificate
./create_self_signed_cert.sh

# 3. Generate PSK (for TLS-PSK)
./create_psk.sh
```

### Windows (PowerShell)

```powershell
cd src\Powershell

# 1. Generate Root CA
.\New-SelfSignedRootCert.ps1

# 2. Generate device certificate
.\New-SelfSignedCert.ps1

# 3. Generate PSK (for TLS-PSK)
.\New-PskCert.ps1

# 4. Install Root CA to Windows trust store (run as Administrator)
.\Install-RootCA.bat
```

> **Note:** On Windows, the scripts include bundled OpenSSL. Run `Install-OpenSSL.bat` if needed.

---

## Root CA Generation

Generate a self-signed Root Certificate Authority:

**Prompts:**
- CommonName (e.g., `Maks-IT Root CA`)
- Organization (e.g., `Maks-IT LLC`)
- OrganizationalUnit (e.g., `IT Security Department`)

**Output files** (in `rootCert/`):
- `ca.crt` - CA certificate (distribute to clients)
- `ca.key` - CA private key (**keep secret!**)
- `ca.pem` - CA certificate in PEM format

> Keep `rootCert/` in place to sign device certificates.

---

## Device Certificate Generation

Generate certificates signed by your Root CA:

**Prompts:**
- Certificate Type: Server, Client, or Both
- Organization
- OrganizationalUnit
- CommonName (device FQDN, e.g., `server01.corp.maks-it.com`)
- Additional SANs (optional IP addresses or DNS names)

**Output files** (in `certs/<CommonName>/`):
- `<CommonName>.crt` - Signed certificate
- `<CommonName>.key` - Private key
- `ca.crt` - CA certificate (for verification)

---

## PSK Generation

Generate Pre-Shared Keys for TLS-PSK authentication (e.g., Zabbix):

**Prompts:**
- PSK Identity (e.g., `server01.corp.maks-it.com`)
- PSK length in bytes (default: 32 = 256-bit)

**Output files** (in `pskCerts/<Identity>/`):
- `<Identity>.psk` - Hex-encoded PSK (**keep secret!**)
- `identity.txt` - Identity string

---

## Install Root CA

### Windows (Automated)

Run as Administrator:
```powershell
.\Install-RootCA.bat
```

Or manually:
1. Double-click `ca.crt`
2. Click "Install Certificate..."
3. Select "Local Machine"
4. Choose "Place all certificates in the following store"
5. Select "Trusted Root Certification Authorities"
6. Finish

### Linux (Fedora/RHEL)

```bash
sudo cp rootCert/ca.pem /etc/pki/ca-trust/source/anchors/
sudo update-ca-trust
```

### Linux (Debian/Ubuntu)

```bash
sudo cp rootCert/ca.crt /usr/local/share/ca-certificates/
sudo update-ca-certificates
```

---

## File Extensions Reference

| Extension | Description |
|-----------|-------------|
| `.key` | Private key (keep secret!) |
| `.crt` / `.cert` | Signed certificate |
| `.pem` | PEM-encoded certificate or key |
| `.csr` | Certificate Signing Request |
| `.psk` | Pre-Shared Key (hex-encoded) |
| `.p12` | PKCS#12 bundle (certificate + private key) |

---

## Directory Structure

```
src/
├── bash/                    # Linux scripts
│   ├── create_self_signed_root_cert.sh
│   ├── create_self_signed_cert.sh
│   ├── create_psk.sh
│   ├── rootCert/           # Generated Root CA
│   ├── certs/              # Generated certificates
│   └── pskCerts/           # Generated PSKs
│
└── Powershell/             # Windows scripts
    ├── New-SelfSignedRootCert.ps1
    ├── New-SelfSignedCert.ps1
    ├── New-PskCert.ps1
    ├── Install-RootCA.ps1
    ├── rootCert/           # Generated Root CA
    ├── certs/              # Generated certificates
    └── pskCerts/           # Generated PSKs
```

---

## License

See [LICENSE](LICENSE) for details.