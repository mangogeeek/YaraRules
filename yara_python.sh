#!/usr/bin/env python3
import subprocess
from datetime import datetime

def run_command(command, description):
    """
    Runs a shell command using subprocess and returns its output.

    Args:
        command (list): A list representing the command and its arguments.
        description (str): A description of the command being run.

    Returns:
        str: The combined standard output and standard error of the command.
             Returns an empty string if the command fails but the error is handled.
    """
    try:
        result = subprocess.run(command, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True, check=True)
        return result.stdout + result.stderr
    except subprocess.CalledProcessError as e:
        output = (e.stdout or "") + (e.stderr or "")
        print(f"Error during {description}: {output.strip()}")
        return output

def run_yara_scan():
    """
    Runs a YARA scan on the mounted image directory.
    """
    yara_rules_path = "malware_check.yar"
    mount_point = "/mnt/image"

    start_time = datetime.now()
    print(f"🕒 Scan started at: {start_time.strftime('%Y-%m-%d %H:%M:%S')}")

    print("Running YARA scan...")
    yara_cmd = ["sudo", "yara", "-r", yara_rules_path, mount_point]
    output = run_command(yara_cmd, "Full YARA scan")

    end_time = datetime.now()
    print(f"✅ Scan ended at: {end_time.strftime('%Y-%m-%d %H:%M:%S')}")
    print(f"⏱ Duration: {str(end_time - start_time)}")

    if output:
        print(f"\nScan output:\n{output.strip()}")
    else:
        print("No output from YARA scan.")

if __name__ == "__main__":
    run_yara_scan()
