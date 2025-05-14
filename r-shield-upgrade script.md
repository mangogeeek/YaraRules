Here’s a **summary of what the r-shield update script does**, step-by-step:

* * *

### 🔧 **Purpose**

To safely update the `r-shield` binary running as a systemd service, ensuring version tracking, backup, integrity checks, and cleanup.

* * *

### 📜 **Script Flow Overview**

1.  **🧾 Input Validation**
    
    1.  Expects one argument: the path to a `.tar.gz` file.
        
    2.  Exits with usage instructions if no argument is given.
        
2.  **🛠 Setup and Logging**
    
    1.  Defines paths, service name, binary/config names, and log file.
        
    2.  Logs all output to `/var/log/r-shield-update.log`.
        
3.  **📌 Version Logging (Before Update)**
    
    1.  Extracts and prints the current version from journal logs:  
        `Starting hycu r-shield scanner...`
4.  **🛑 Stop the Service**
    
    1.  Stops `r-shield.service`.
        
    2.  Waits 25 seconds for full shutdown.
        
5.  **✅ Check Service Status**
    
    1.  Accepts `inactive` or `failed` as valid states.
        
    2.  Aborts if the service is still `active`.
        
6.  **📦 Extract the Update Package**
    
    1.  Cleans and recreates `/tmp/r-shield_update`.
        
    2.  Extracts the `.tar.gz` file there.
        
7.  **📂 Backup Current Binary**
    
    1.  Saves the existing `/r-shield/r-shield` to a dated backup file in `/r-shield/.r-shield_build/`.
8.  **🚀 Deploy New Binary**
    
    1.  Copies the new binary to `/r-shield/`.
        
    2.  Ensures it is executable.
        
9.  **🔐 Binary Verification**
    
    1.  Compares the deployed and extracted binaries byte-by-byte and via SHA256.
        
    2.  Fails if mismatched or non-executable.
        
10. **▶️ Start the Service**
    
    1.  Starts the `r-shield.service`.
11. **🔍 Verify Service and Logs**
    
    1.  Shows `systemctl status`.
        
    2.  Prints the last 10 journal lines for the service.
        
12. **🆕 Log New Version**
    
    1.  Prints the version line again post-restart to confirm the update.
13. **🧹 Clean Up**
    
    1.  Deletes `/tmp/r-shield_update`.
14. **✅ Final Confirmation**
    
    1.  Prints a successful completion message with timestamp.

* * *

## HYCU R-Shield Scanner update script

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
TMP_SUBDIR="/tmp/r-shield_update"
SERVICE_NAME="r-shield.service"
INSTALL_DIR="/r-shield"
BACKUP_DIR="$INSTALL_DIR/.r-shield_build"
BINARY_NAME="r-shield"
CONFIG_NAME="r-shield-config"
DATE_SUFFIX=$(date +%F)
LOG_FILE="/var/log/r-shield-update.log"

# === Start Logging ===
exec > >(tee -a "$LOG_FILE") 2>&1
echo "==== r-shield Binary Update Started: $(date) ===="
echo ">>> Starting r-shield binary update process..."

# === Version Check Before Update ===
echo "[Pre-Update] Retrieving current r-shield scanner version..."
CURRENT_VERSION=$(sudo journalctl -u "$SERVICE_NAME" | egrep "Starting hycu r-shield scanner" | tail -n 1)

if [ -z "$CURRENT_VERSION" ]; then
    echo "⚠️  No version info found in logs. The service may not have started previously or log data is missing."
else
    echo "Current Service Version: $CURRENT_VERSION"
fi

# === 1. Stop the r-shield service ===
echo "[1/7] Stopping $SERVICE_NAME..."
sudo systemctl stop "$SERVICE_NAME"

echo "Waiting 25 seconds for the service to stop..."
sleep 25

# === 2. Verify the service has stopped ===
SERVICE_STATE=$(sudo systemctl is-active "$SERVICE_NAME" || true)

if [[ "$SERVICE_STATE" == "inactive" || "$SERVICE_STATE" == "failed" ]]; then
    echo "✅ Service is not running (state: $SERVICE_STATE) — continuing with update."
else
    echo "❌ Service is still running or in an unexpected state (status: $SERVICE_STATE)."
    echo "Aborting update to prevent inconsistent state."
    exit 1
fi

# === 3. Extract the .tar.gz into /tmp/r-shield_update ===
echo "[2/7] Preparing extraction directory..."
sudo rm -rf "$TMP_SUBDIR"
sudo mkdir -p "$TMP_SUBDIR"

echo "Extracting $TAR_FILE to $TMP_SUBDIR..."
sudo tar -xzf "$TAR_FILE" -C "$TMP_SUBDIR"

# === 4. Backup current binary ===
echo "[3/7] Backing up existing binary..."
sudo mkdir -p "$BACKUP_DIR"

generate_unique_name() {
    local base_name="$1"
    local ext="$2"
    local counter=1
    local new_name="${base_name}${ext}"

    while [ -e "$new_name" ]; do
        new_name="${base_name}.${counter}${ext}"
        ((counter++))
    done

    echo "$new_name"
}

if [ -f "$INSTALL_DIR/$BINARY_NAME" ]; then
    BINARY_BAK_PATH=$(generate_unique_name "$BACKUP_DIR/${BINARY_NAME}.${DATE_SUFFIX}" ".bak")
    sudo mv "$INSTALL_DIR/$BINARY_NAME" "$BINARY_BAK_PATH"
    echo "Backed up binary to: $BINARY_BAK_PATH"
fi

# === 5. Deploy new binary ===
echo "[4/7] Deploying new binary to $INSTALL_DIR..."
sudo cp "$TMP_SUBDIR/$BINARY_NAME" "$INSTALL_DIR/$BINARY_NAME"
sudo chmod +x "$INSTALL_DIR/$BINARY_NAME"

# === 5b. Verify deployed binary ===
echo "[Verification] Checking deployed binary integrity..."

DEPLOYED="$INSTALL_DIR/$BINARY_NAME"
EXTRACTED="$TMP_SUBDIR/$BINARY_NAME"

if [ ! -f "$DEPLOYED" ]; then
    echo "❌ ERROR: Deployed binary not found at $DEPLOYED"
    exit 1
fi

if ! cmp -s "$DEPLOYED" "$EXTRACTED"; then
    echo "❌ ERROR: Deployed binary does not match extracted version!"
    echo "Extracted SHA256: $(sha256sum "$EXTRACTED")"
    echo "Deployed  SHA256: $(sha256sum "$DEPLOYED")"
    exit 1
else
    echo "✅ Binary integrity verified: Deployed matches extracted file."
fi

if [ ! -x "$DEPLOYED" ]; then
    echo "❌ ERROR: Deployed binary is not executable"
    exit 1
else
    echo "✅ Deployed binary is executable"
fi

# === 6. Start the r-shield service ===
echo "[5/7] Starting $SERVICE_NAME..."
sudo systemctl start "$SERVICE_NAME"

# === 7. Final service check ===
echo "[6/7] Verifying service status..."
sudo systemctl status "$SERVICE_NAME"

# === 8. Show last 10 journal entries ===
echo "[7/7] Displaying last 10 log entries..."
sudo journalctl -u "$SERVICE_NAME" -n 10

# === 9. Post-Update Version Check ===
echo "[8/7] Retrieving updated r-shield scanner version..."
NEW_VERSION=$(sudo journalctl -u "$SERVICE_NAME" | egrep "Starting hycu r-shield scanner" | tail -n 1)

if [ -z "$NEW_VERSION" ]; then
    echo "⚠️  No startup version info found in logs after restart. Please verify manually."
else
    echo "Updated Service Version: $NEW_VERSION"
fi

# === 10. Cleanup temp folder ===
echo "[9/7] Cleaning up temporary directory..."
sudo rm -rf "$TMP_SUBDIR"
echo "✅ Temporary directory $TMP_SUBDIR deleted."

echo "✅ r-shield binary update completed successfully."
echo "==== Update Finished: $(date) ===="

```
