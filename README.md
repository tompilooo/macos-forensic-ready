# macOS Forensic Logging Setup (Production Mode)

## Overview

`macos_forensic_ready.sh` is a **production-safe configuration script** designed to prepare a macOS endpoint for forensic investigations while maintaining system stability and minimal performance impact.

It enables essential logging using:

* auditd for low-level auditing
* Unified Logging System (default configuration, no verbosity increase)

---

## Purpose

This script ensures that a macOS system:

* Generates reliable forensic artifacts
* Maintains stable performance in production environments
* Avoids excessive logging noise and disk consumption

It is intended for:

* Enterprise endpoints
* Long-term monitoring
* Incident response readiness

---

## Features

* ✅ Enables and configures `auditd` safely
* ✅ Captures process execution (`pc`, `ex`)
* ✅ Captures command-line arguments (`argv`)
* ✅ Applies log rotation and retention policy
* ✅ Avoids noisy logging (no file write tracking, no debug logs)
* ✅ Prevents unnecessary service restarts
* ✅ Performs lightweight validation

---

## Requirements

* macOS (modern versions recommended)
* Root privileges (`sudo`)
* Terminal access

---

## Usage

### 1. Make the script executable

```bash
chmod +x macos_forensic_ready_prod.sh
```

### 2. Run the script

```bash
sudo ./macos_forensic_ready_prod.sh
```

---

## Configuration Details

The script modifies:

```
/etc/security/audit_control
```

### Applied Policy

```
dir:/var/audit
flags:lo,aa,pc,ex
naflags:lo,aa
policy:cnt,argv
minfree:10
filesz:25M
expire-after:3d
host:localhost
```

### Explanation

* `pc`, `ex` → Track process creation and execution
* `argv` → Capture command-line arguments
* `filesz:25M` → Rotate logs to prevent large files
* `expire-after:3d` → Retain logs for 3 days
* `minfree:10` → Maintain disk safety margin
* `host:localhost` → Prevent audit warnings and instability

---

## What the Script Does

1. Ensures `/var/audit` exists with secure permissions
2. Backs up existing audit configuration
3. Applies a **minimal and stable audit policy**
4. Ensures `auditd` is running (without aggressive restarts)
5. Reloads audit configuration safely
6. Performs a basic validation of logging

---

## Validation

After execution, the script verifies:

* Audit logs exist in `/var/audit`
* `auditd` service is running

You can manually validate:

```bash
sudo praudit /var/audit/current | grep exec
```

```bash
launchctl print system/com.apple.auditd
```

---

## Example Output

```
[PASS] Audit logs exist
[*] auditd state: running
[✓] PRODUCTION forensic logging ready
```

---

## Design Principles

### Stability First

* No repeated service restarts
* No aggressive logging configuration

### Minimal Footprint

* Avoids high-volume logging (e.g., file write tracking)
* Uses conservative retention settings

### Forensic Sufficiency

* Captures essential execution and command-line data
* Provides enough visibility for incident response

---

## Limitations

* Does not enable verbose/debug logging
* Does not include:

  * EDR tools
  * Log forwarding
  * SIEM integration
* Limited retention (3 days by default)

---

## Recommended Enhancements

For enterprise environments, consider adding:

* Centralized log forwarding
* Endpoint Detection & Response (EDR) tools
* Monitoring/alerting for `auditd` service status

---

## Disclaimer

This script is intended for **production environments requiring stable forensic readiness**.
Always test in a staging environment before deploying at scale.
