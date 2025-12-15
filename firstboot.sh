#!/bin/bash
# Final hardened firstboot script for virt-sysprep
# - UUID-safe NetworkManager handling (no duplicate profiles)
# - SSH host key regeneration + reliable startup
# - cloud-init race avoidance
# - Fully idempotent, golden-image safe
# - Logs to /var/log/firstboot.log

LOG=/var/log/firstboot.log
mkdir -p "$(dirname "$LOG")"
exec >> "$LOG" 2>&1

set -o pipefail
set -u

echo "=== firstboot start: $(date -u) ==="

run_safe() {
  echo "+ $*"
  "$@" || echo "(non-fatal) command failed: $*"
}

# ------------------------------------------------------------
# Wait for cloud-init (avoid races)
# ------------------------------------------------------------
if command -v cloud-init >/dev/null 2>&1; then
  echo "cloud-init detected — waiting for completion"
  cloud-init status --wait || echo "cloud-init wait returned non-zero"
fi

# ------------------------------------------------------------
# Ensure systemd exists
# ------------------------------------------------------------
if ! command -v systemctl >/dev/null 2>&1; then
  echo "systemctl not present — exiting firstboot"
  echo "=== firstboot finish: $(date -u) ==="
  exit 0
fi

# ------------------------------------------------------------
# Enable NetworkManager
# ------------------------------------------------------------
if command -v nmcli >/dev/null 2>&1; then
  run_safe systemctl enable --now NetworkManager
else
  echo "nmcli not present — skipping network configuration"
fi

# ------------------------------------------------------------
# Wait until NetworkManager is fully running
# ------------------------------------------------------------
if command -v nmcli >/dev/null 2>&1; then
  echo "Waiting for NetworkManager to become ready"
  for _ in {1..10}; do
    nmcli -t -f RUNNING general 2>/dev/null | grep -q running && break
    sleep 1
  done
fi

# ------------------------------------------------------------
# Remove stale Auto-* profiles not bound to any device (UUID-based)
# ------------------------------------------------------------
prune_stale_nm_connections() {
  mapfile -t stale_uuids < <(
    nmcli -t -f NAME,UUID,DEVICE connection show |
    awk -F: '$1 ~ /^Auto-/ && $3=="--" {print $2}'
  )

  for uuid in "${stale_uuids[@]}"; do
    echo "Deleting stale NetworkManager profile UUID=$uuid"
    nmcli connection delete uuid "$uuid" || true
  done
}

# ------------------------------------------------------------
# Ensure exactly one Auto-<iface> per ethernet device (UUID-safe)
# ------------------------------------------------------------
configure_nm_connections() {
  mapfile -t ifaces < <(
    nmcli -t -f DEVICE,TYPE device status |
    awk -F: '$2=="ethernet" {print $1}'
  )

  for iface in "${ifaces[@]}"; do
    # Find UUID of connection bound to this interface
    bound_uuid=$(nmcli -t -f UUID,DEVICE connection show | awk -F: -v dev="$iface" '$2==dev {print $1}')

    if [ -n "$bound_uuid" ]; then
      echo "Using existing connection UUID=$bound_uuid for $iface"
      nmcli connection modify uuid "$bound_uuid" connection.autoconnect yes || true
    else
      echo "No bound connection for $iface — creating Auto-$iface"
      nmcli connection add \
        type ethernet \
        ifname "$iface" \
        con-name "Auto-$iface" \
        connection.autoconnect yes \
        ipv4.method auto \
        ipv6.method auto || true
    fi
  done
}

if command -v nmcli >/dev/null 2>&1; then
  prune_stale_nm_connections
  configure_nm_connections
fi

# ------------------------------------------------------------
# SSH host keys (virt-sysprep removes them)
# ------------------------------------------------------------
if ! ls /etc/ssh/ssh_host_* >/dev/null 2>&1; then
  echo "SSH host keys missing — generating"
  run_safe ssh-keygen -A || run_safe dpkg-reconfigure openssh-server
else
  echo "SSH host keys already present"
fi

# ------------------------------------------------------------
# Ensure /run/sshd exists (Debian/Ubuntu)
# ------------------------------------------------------------
if [ ! -d /run/sshd ]; then
  echo "Creating /run/sshd"
  run_safe mkdir -p /run/sshd
  run_safe chmod 0755 /run/sshd
fi

# ------------------------------------------------------------
# Reload systemd & clear failed state
# ------------------------------------------------------------
run_safe systemctl daemon-reload
run_safe systemctl reset-failed sshd ssh

# ------------------------------------------------------------
# Enable + start SSH reliably
# ------------------------------------------------------------
start_ssh() {
  for attempt in {0..5}; do
    echo "Attempt $attempt to enable/start SSH"

    systemctl enable --now sshd 2>/dev/null && return 0
    systemctl enable --now ssh 2>/dev/null && return 0

    systemctl start sshd 2>/dev/null || systemctl start ssh 2>/dev/null || true

    systemctl is-active --quiet sshd && return 0
    systemctl is-active --quiet ssh && return 0

    sleep 2
  done
  return 1
}

if start_ssh; then
  echo "SSH up and running"
else
  echo "SSH failed — dumping journal"
  journalctl -u sshd -n 200 --no-pager || journalctl -u ssh -n 200 --no-pager
fi

# ------------------------------------------------------------
# Allow SSH via UFW if present
# ------------------------------------------------------------
if command -v ufw >/dev/null 2>&1; then
  run_safe ufw allow ssh
fi

# ------------------------------------------------------------
# Final network state dump
# ------------------------------------------------------------
if command -v nmcli >/dev/null 2>&1; then
  nmcli device show || true
  nmcli connection show || true
fi

echo "=== firstboot finish: $(date -u) ==="
exit 0
