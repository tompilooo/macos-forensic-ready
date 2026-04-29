# macOS Forensic Logging Setup

## Overview

This script configures a macOS system to be **forensic-ready** by enabling and optimizing native logging mechanisms. It focuses exclusively on **logging and audit configuration**, without installing third-party tools.

The goal is to provide **high-quality forensic artifacts** for:

* Incident response
* Threat hunting
* Timeline reconstruction
* Behavioral analysis

It leverages:

* auditd for low-level system auditing
* Unified Logging System for high-level system and application logs

---

## Features

### 1. Audit Logging (Low-Level Visibility)

* Enables and configures `auditd`
* Captures:

  * Process creation (`pc`)
  * Process execution (`ex`)
  * Command-line arguments (`argv`)
  * File write activity (`fw`)
* Ensures audit logs are stored in:

  ```
  /var/audit
  ```

### 2. Log Rotation & Retention

* Prevents disk exhaustion with:

  * `filesz:50M` (log rotation size)
  * `expire-after:7d` (log retention policy)

### 3. Unified Logging Optimization

* Increases verbosity for Apple subsystems
* Improves visibility into:

  * Process behavior
  * System activity
  * Application-level events

### 4. Automatic Validation

* Generates test events (e.g., `osascript`)
* Verifies:

  * Audit logs are being written
  * Logging pipeline is functional

---

## Requirements

* macOS (tested on modern versions)
* Root privileges (`sudo`)
* Terminal access

---

## Usage

### 1. Make the script executable

```bash
chmod +x macos_forensic_ready.sh
```

### 2. Run the script

```bash
sudo ./macos_forensic_ready.sh
```

---

## What the Script Does

### Step 1 — Prepare Audit Directory

* Ensures `/var/audit` exists
* Applies secure permissions

### Step 2 — Configure Audit Policy

Updates:

```
/etc/security/audit_control
```

With forensic-friendly settings:

```
flags:lo,aa,pc,ex,fw
policy:cnt,argv
```

### Step 3 — Enable and Restart auditd

Uses modern `launchctl` commands:

* `enable`
* `bootstrap`
* `kickstart`

### Step 4 — Reload Audit Subsystem

Applies new configuration immediately:

```bash
audit -s
```

### Step 5 — Increase Logging Verbosity

Adjusts Unified Logging for better visibility

### Step 6 — Generate Test Events

Triggers:

* AppleScript execution
* Basic command execution

### Step 7 — Validate Logging

Displays:

* Audit log files
* Sample parsed audit entries
* Sample Unified Logs output

---

## Validation (Manual)

After running the script, you can verify logging with:

### Audit Logs

```bash
sudo praudit /var/audit/current | grep exec
```

### Search for Specific Execution (e.g., osascript)

```bash
sudo praudit /var/audit/current | grep -i osascript
```

### Unified Logs

```bash
log show --predicate 'process == "osascript"' --last 10m --info --debug
```

---

## Example Forensic Insight

Audit log entry:

```
exec arg,su,-,macos,-c,whoami >/dev/null
```

This indicates:

* User: `macos`
* Command executed: `whoami`
* Execution context: via `su`

This level of detail enables:

* Command tracing
* User attribution
* Attack chain reconstruction

---

## Important Notes

* Increased logging verbosity may generate large volumes of data
* Suitable for:

  * Lab environments
  * Forensic research
* Use caution in production environments due to:

  * Storage impact
  * Potential exposure of sensitive data in logs

---

## Limitations

* Does not include:

  * EDR tools
  * Log forwarding
  * SIEM integration
* Focused only on **local forensic readiness**

---

## Recommended Next Steps

* Perform attack simulation (e.g., Atomic Red Team)
* Collect and compare:

  * Pre-attack baseline
  * Post-attack artifacts
* Build a timeline using:

  * Audit logs
  * Unified logs

---

## License

Use at your own risk. Intended for educational and research purposes.
