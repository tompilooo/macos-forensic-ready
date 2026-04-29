#!/usr/bin/env bash
set -euo pipefail

echo "[*] macOS Forensic Logging Setup (PRODUCTION-SAFE)"

# ---------------------------
# 0) Pre-check
# ---------------------------
if [[ $EUID -ne 0 ]]; then
  echo "[!] Run as root (sudo)."
  exit 1
fi

AUDIT_CTL="/etc/security/audit_control"
TS="$(date +%Y%m%d%H%M%S)"

# ---------------------------
# 1) Ensure audit directory
# ---------------------------
echo "[*] Ensuring /var/audit"
mkdir -p /var/audit
chmod 700 /var/audit
chown root:wheel /var/audit

# ---------------------------
# 2) Configure audit_control (minimal & stable)
# ---------------------------
echo "[*] Backing up audit_control"
cp "$AUDIT_CTL" "${AUDIT_CTL}.bak.${TS}" 2>/dev/null || true

echo "[*] Applying production-safe audit policy"

cat > "$AUDIT_CTL" << 'EOF'
dir:/var/audit
flags:lo,aa,pc,ex
naflags:lo,aa
policy:cnt,argv
minfree:10
filesz:25M
expire-after:3d
host:localhost
EOF

# Explanation:
# pc,ex  -> essential execution tracking
# argv   -> command-line visibility
# NO fw  -> reduce noise & disk usage
# smaller filesz -> better rotation
# shorter retention -> prevent disk growth

# ---------------------------
# 3) Ensure auditd running (NO aggressive restart)
# ---------------------------
echo "[*] Checking auditd status"

if launchctl print system/com.apple.auditd 2>/dev/null | grep -q "state = running"; then
  echo "[*] auditd already running"
else
  echo "[*] Starting auditd"
  launchctl enable system/com.apple.auditd 2>/dev/null || true
  launchctl bootstrap system /System/Library/LaunchDaemons/com.apple.auditd.plist 2>/dev/null || true
  launchctl kickstart -k system/com.apple.auditd 2>/dev/null || true
fi

# Apply config once (safe)
echo "[*] Reloading audit subsystem"
audit -s

# ---------------------------
# 4) Unified Logging (NO debug mode)
# ---------------------------
echo "[*] Keeping default Unified Logging (production-safe)"

# DO NOT enable:
# - private_data:on
# - debug level
# Reason: may expose sensitive data & increase noise

# ---------------------------
# 5) Lightweight validation
# ---------------------------
echo "[*] Validating logging (light check)"

if ls /var/audit/* 1>/dev/null 2>&1; then
  echo "[PASS] Audit logs present"
else
  echo "[WARN] No audit logs detected"
fi

if sudo praudit /var/audit/current 2>/dev/null | grep -q exec; then
  echo "[PASS] Execution events detected"
else
  echo "[WARN] No execution events found yet"
fi

echo "[*] auditd state:"
launchctl print system/com.apple.auditd | grep state || true

echo "[✓] Production-safe forensic logging applied"
