## 📝 **Summary of What This Script Does**

1.  **Stops the `r-shield` service** using `systemctl stop`.
2.  **Waits for 20 seconds** to allow graceful termination.
3.  **Verifies** the service is **truly stopped** using `systemctl is-active`. If it's still running, the script exits with an error.
4.  **Extracts the provided `.tar.gz`** to `/tmp/r-shield_upgrade/`.
5.  **Backs up the current binary and config** (if present) into `/r-shield/.r-shield_build/` with a `.bak.YYYY-MM-DD` filename.
6.  **Deploys the new binary and config** from the extracted directory into `/r-shield/`.
    - **Restarts the `r-shield` service** and prints its status.
    - **Displays the last 10 logs** using `journalctl` for verification.

* * *

```bash
#!/bin/bash

set -e

# === INPUT VALIDATION ===
if [ $# -ne 1 ]; then
    echo "Usage: sudo $0 /path/to/r-shield.tar.gz"
    exit 1
fi

# === CONFIGURATION ===
TAR_FILE="$1"
TMP_SUBDIR="/tmp/r-shield_upgrade"
SERVICE_NAME="r-shield.service"
INSTALL_DIR="/r-shield"
BACKUP_DIR="$INSTALL_DIR/.r-shield_build"
BINARY_NAME="r-shield"
CONFIG_NAME="r-shield-config"
DATE_SUFFIX=$(date +%F)  # e.g., 2025-05-07

echo ">>> Starting r-shield upgrade process..."

# === 1. Stop the r-shield service ===
echo "[1/7] Stopping $SERVICE_NAME..."
sudo systemctl stop "$SERVICE_NAME"

echo "Waiting 20 seconds for the service to stop..."
sleep 20

echo "Verifying service has stopped..."
SERVICE_STATE=$(sudo systemctl is-active "$SERVICE_NAME")
if [ "$SERVICE_STATE" = "inactive" ]; then
    echo "✅ Service is inactive as expected."
else
    echo "❌ Service is still running (status: $SERVICE_STATE). Aborting upgrade."
    exit 1
fi

# === 2. Extract the .tar.gz into /tmp/r-shield_upgrade ===
echo "[2/7] Preparing extraction directory..."
sudo rm -rf "$TMP_SUBDIR"
sudo mkdir -p "$TMP_SUBDIR"

echo "Extracting $TAR_FILE to $TMP_SUBDIR..."
sudo tar -xzf "$TAR_FILE" -C "$TMP_SUBDIR"

# === 3. Backup current binary and config ===
echo "[3/7] Backing up existing binary and config..."
sudo mkdir -p "$BACKUP_DIR"

if [ -f "$INSTALL_DIR/$BINARY_NAME" ]; then
    sudo mv "$INSTALL_DIR/$BINARY_NAME" "$BACKUP_DIR/${BINARY_NAME}.${DATE_SUFFIX}.bak"
fi

if [ -f "$INSTALL_DIR/$CONFIG_NAME" ]; then
    sudo cp "$INSTALL_DIR/$CONFIG_NAME" "$BACKUP_DIR/${CONFIG_NAME}.${DATE_SUFFIX}.bak"
fi

# === 4. Deploy new binary and config ===
echo "[4/7] Deploying new files to $INSTALL_DIR..."
sudo cp "$TMP_SUBDIR/$BINARY_NAME" "$INSTALL_DIR/$BINARY_NAME"
sudo chmod +x "$INSTALL_DIR/$BINARY_NAME"

if [ -f "$TMP_SUBDIR/$CONFIG_NAME" ]; then
    sudo cp "$TMP_SUBDIR/$CONFIG_NAME" "$INSTALL_DIR/$CONFIG_NAME"
fi

# === 5. Start the r-shield service ===
echo "[5/7] Starting $SERVICE_NAME..."
sudo systemctl start "$SERVICE_NAME"

# === 6. Final service check ===
echo "[6/7] Verifying service status..."
sudo systemctl status "$SERVICE_NAME"

# === 7. Show last 10 journal entries ===
echo "[7/7] Displaying last 10 log entries..."
sudo journalctl -u "$SERVICE_NAME" -n 10

echo "✅ r-shield upgrade completed successfully."

```
