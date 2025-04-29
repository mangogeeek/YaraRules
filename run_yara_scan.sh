#!/bin/bash

# Script to execute a recursive YARA scan with accurate file counting
# Logs start/end times, duration, and scan results

TARGET_DIR="/mnt/image"
YARA_RULES_FILE="manual_rules/manual_rules.yara"
LOG_FILE="yara_scan_manual.log"

# Check if YARA is installed
if ! command -v yara &> /dev/null; then
  echo "Error: YARA is not installed. Please install it before running this script."
  exit 1
fi

# Check if the YARA rule file exists
if [ ! -f "$YARA_RULES_FILE" ]; then
  echo "Error: YARA rules file '$YARA_RULES_FILE' not found."
  echo "Please check the path or filename."
  exit 1
fi

# Initialize log file
echo "=== YARA Scan Log ===" > "$LOG_FILE"
echo "Scan target: $TARGET_DIR" >> "$LOG_FILE"
echo "Rules file: $YARA_RULES_FILE" >> "$LOG_FILE"

# Get the start time
start_time=$(date +"%Y-%m-%d %H:%M:%S")
start_seconds=$(date -d "$start_time" +%s)
echo -e "\nScan started at: $start_time" | tee -a "$LOG_FILE"

# Find total files and log
total_files=$(sudo find "$TARGET_DIR" -type f | wc -l)
echo "Total files to scan: $total_files" | tee -a "$LOG_FILE"

# Execute scan with proper counting
scanned_files=0
detected_threats=0

while IFS= read -r -d $'\0' file; do
    echo -ne "Scanning... $scanned_files/$total_files files\r"

    # Scan the file with the rule file
    scan_result=$(sudo yara "$YARA_RULES_FILE" "$file" 2>&1)

    if [[ -n "$scan_result" ]]; then
        echo -e "\n[$(date +'%Y-%m-%d %H:%M:%S')] DETECTED in file: $file" | tee -a "$LOG_FILE"
        echo "$scan_result" | tee -a "$LOG_FILE"
        ((detected_threats++))
    fi

    ((scanned_files++))
done < <(sudo find "$TARGET_DIR" -type f -print0)

# Get end time and calculate duration
end_time=$(date +"%Y-%m-%d %H:%M:%S")
end_seconds=$(date -d "$end_time" +%s)
duration_seconds=$((end_seconds - start_seconds))
duration=$(printf "%dh %dm %ds" $((duration_seconds/3600)) $(((duration_seconds%3600)/60)) $((duration_seconds%60)))

# Final report
echo -e "\nScan finished at: $end_time" | tee -a "$LOG_FILE"
echo "Total files scanned: $scanned_files" | tee -a "$LOG_FILE"
echo "Detected threats: $detected_threats" | tee -a "$LOG_FILE"
echo "Total time taken: $duration" | tee -a "$LOG_FILE"

# Summary
echo -e "\n=== Scan Summary ===" | tee -a "$LOG_FILE"
echo "Start: $start_time" | tee -a "$LOG_FILE"
echo "End: $end_time" | tee -a "$LOG_FILE"
echo "Duration: $duration" | tee -a "$LOG_FILE"
echo "Files scanned: $scanned_files/$total_files" | tee -a "$LOG_FILE"
echo "Threats detected: $detected_threats" | tee -a "$LOG_FILE"
echo "Log file: $LOG_FILE" | tee -a "$LOG_FILE"
