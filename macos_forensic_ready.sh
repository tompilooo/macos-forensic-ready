#!/usr/bin/env bash
set -euo pipefail

echo "[*] macOS Forensic Logging Setup (auditd + Unified Logs)"

# ---------------------------
# 0) Pre-check
# ---------------------------
if [[ $EUID -ne 0 ]]; then
  echo "[!] Jalankan sebagai root (sudo)."
  exit 1
fi

# ---------------------------
# 1) Ensure audit directory
# ---------------------------
echo "[*] Ensuring /var/audit"
mkdir -p /var/audit
chmod 700 /var/audit
chown root:wheel /var/audit

# ---------------------------
# 2) Backup & configure audit_control
# ---------------------------
AUDIT_CTL="/etc/security/audit_control"
TS="$(date +%Y%m%d%H%M%S)"

echo "[*] Backup $AUDIT_CTL"
cp "$AUDIT_CTL" "${AUDIT_CTL}.bak.${TS}" || true

echo "[*] Writing forensic-friendly audit policy"
cat > "$AUDIT_CTL" << 'EOF'
dir:/var/audit
flags:lo,aa,pc,ex,fw
minfree:5
naflags:lo,aa
policy:cnt,argv
filesz:50M
expire-after:7d
EOF

# Keterangan singkat:
# pc,ex  -> process creation & execution (WAJIB)
# argv   -> capture command line
# fw     -> file write (berguna untuk perubahan file)
# filesz -> rotasi file (hindari disk penuh)
# expire-after -> retensi

# ---------------------------
# 3) Enable & (re)start auditd (modern launchctl)
# ---------------------------
echo "[*] Enabling auditd"
launchctl enable system/com.apple.auditd || true

echo "[*] Bootstrapping auditd (ignore if already loaded)"
launchctl bootstrap system /System/Library/LaunchDaemons/com.apple.auditd.plist 2>/dev/null || true

echo "[*] Restarting auditd"
launchctl kickstart -k system/com.apple.auditd

echo "[*] Reload audit subsystem"
audit -s

# ---------------------------
# 4) Increase Unified Logging verbosity
# ---------------------------
echo "[*] Configuring Unified Logging verbosity"
# buka private data (berguna untuk DFIR)
log config --mode "private_data:on" || true
# naikkan level untuk subsystem Apple (lab only)
log config --subsystem com.apple --mode level:debug || true

# ---------------------------
# 5) Quick validation (generate minimal events)
# ---------------------------
echo "[*] Generating test events"
# jalankan sebagai user pemanggil (kalau ada)
if [[ -n "${SUDO_USER:-}" ]]; then
  su - "$SUDO_USER" -c 'osascript -e "display dialog \"forensic logging test\""' || true
  su - "$SUDO_USER" -c 'whoami >/dev/null' || true
else
  osascript -e 'display dialog "forensic logging test"' || true
  whoami >/dev/null || true
fi

# ---------------------------
# 6) Validation outputs
# ---------------------------
echo "[*] Audit files:"
ls -lah /var/audit || true

echo "[*] auditd status (short):"
launchctl print system/com.apple.auditd | head -20 || true

echo "[*] Sample audit parse (exec events):"
praudit /var/audit/current 2>/dev/null | grep exec | head -20 || true

echo "[*] Sample Unified Logs (osascript, last 5m):"
log show --predicate 'process == "osascript"' --last 5m --info --debug | head -20 || true

echo "[✓] Forensic logging baseline applied"
