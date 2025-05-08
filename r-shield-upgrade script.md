### ✅ Summary of What This Script Does:

1.  **Stops** the `r-shield` service and waits 20 seconds.
    
2.  **Verifies** that the service has stopped.
    
3.  **Extracts** the specified `.tar.gz` to `/tmp/r-shield_update`.
    
4.  **Backs up** the current binary to `.r-shield_build/` with a date-based `.bak` name.
    
5.  **Copies** the new binary into `/r-shield/`.
    
6.  **Verifies**:
    
    - That the deployed binary matches the extracted one (via `cmp` and SHA256).
        
    - That it is executable.
        
7.  **Restarts** the `r-shield` service.
    
8.  **Displays** service status and last 10 log entries.
    

* * *

📜 Script: `update_rshield.sh`

```
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

# === 1. Stop the r-shield service ===
echo "[1/7] Stopping $SERVICE_NAME..."
sudo systemctl stop "$SERVICE_NAME"

echo "Waiting 20 seconds for the service to stop..."
sleep 20

# === 2. Verify the service has stopped ===
echo "Verifying service has stopped..."
SERVICE_STATE=$(sudo systemctl is-active "$SERVICE_NAME" || true)
if [ "$SERVICE_STATE" = "inactive" ]; then
    echo "✅ Service is inactive as expected."
else
    echo "❌ Service is still running (status: $SERVICE_STATE). Aborting update."
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

# (Optional) Backup config - currently disabled
# if [ -f "$INSTALL_DIR/$CONFIG_NAME" ]; then
#     CONFIG_BAK_PATH=$(generate_unique_name "$BACKUP_DIR/${CONFIG_NAME}.${DATE_SUFFIX}" ".bak")
#     sudo cp "$INSTALL_DIR/$CONFIG_NAME" "$CONFIG_BAK_PATH"
#     echo "Backed up config to: $CONFIG_BAK_PATH"
# fi

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

echo "✅ r-shield binary update completed successfully."
echo "==== Update Finished: $(date) ===="
```

### 🔐 **Permissions Note:**

Ensure the script has write access to the log file:

```
sudo touch /var/log/r-shield-upgrade.log  
sudo chmod 664 /var/log/r-shield-upgrade.log  
sudo chown root:$(whoami) /var/log/r-shield-upgrade.log
```

## 🟨 Usage Reminder

You should run the script itself with `sudo:`

```
sudo chmod +x upgrade_rshield.sh  
sudo ./upgrade_rshield.sh /path/to/r-shield.tar.gz
```

## 💡Output

```
hycu@hycu-AHV:/r-shield$ sudo ./upgrade_r-shield.sh /mnt/download/dist/r-shield.tar.gz
==== r-shield Binary Update Started: čet 08 maj 2025 09:47:46 CEST ====
>>> Starting r-shield binary update process...
[1/7] Stopping r-shield.service...
Waiting 20 seconds for the service to stop...
Verifying service has stopped...
✅ Service is inactive as expected.
[2/7] Preparing extraction directory...
Extracting /mnt/download/dist/r-shield.tar.gz to /tmp/r-shield_update...
[3/7] Backing up existing binary...
Backed up binary to: /r-shield/.r-shield_build/r-shield.2025-05-08.2.bak
[4/7] Deploying new binary to /r-shield...
[Verification] Checking deployed binary integrity...
✅ Binary integrity verified: Deployed matches extracted file.
✅ Deployed binary is executable
[5/7] Starting r-shield.service...
[6/7] Verifying service status...
● r-shield.service - R-Shield Scanner Service
     Loaded: loaded (/etc/systemd/system/r-shield.service; disabled; vendor preset: enabled)
     Active: active (running) since Thu 2025-05-08 09:48:07 CEST; 36ms ago
   Main PID: 31189 (r-shield)
      Tasks: 1 (limit: 18984)
     Memory: 3.5M
        CPU: 24ms
     CGroup: /system.slice/r-shield.service
             └─31189 /r-shield/r-shield

maj 08 09:48:07 hycu-AHV systemd[1]: Started R-Shield Scanner Service.
[7/7] Displaying last 10 log entries...
maj 08 09:47:46 hycu-AHV r-shield[31061]: Shutdown signal received. Finishing current tasks and exiting...
maj 08 09:47:46 hycu-AHV r-shield[31061]: Attempting to cancel running tasks...
maj 08 09:47:46 hycu-AHV r-shield[31061]: Initiating non-blocking executor shutdown...
maj 08 09:47:47 hycu-AHV r-shield[31061]: Shutting down. Attempting to clean up resources...
maj 08 09:47:47 hycu-AHV r-shield[31061]: Shutting down thread pool...
maj 08 09:47:47 hycu-AHV r-shield[31061]: All cleanup completed. Exiting.
maj 08 09:47:47 hycu-AHV systemd[1]: r-shield.service: Deactivated successfully.
maj 08 09:47:47 hycu-AHV systemd[1]: Stopped R-Shield Scanner Service.
maj 08 09:47:47 hycu-AHV systemd[1]: r-shield.service: Consumed 1.099s CPU time.
maj 08 09:48:07 hycu-AHV systemd[1]: Started R-Shield Scanner Service.
✅ r-shield binary update completed successfully.
==== Update Finished: čet 08 maj 2025 09:48:08 CEST ====
```
