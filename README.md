I want to create a manual YARA rule similar to the rules available at https://github.com/reversinglabs/reversinglabs-yara-rules/blob/develop/yara/ransomware/Linux.Ransomware.GwisinLocker.yara and https://github.com/reversinglabs/reversinglabs-yara-rules/blob/develop/yara/ransomware/Linux.Ransomware.Helldown.yara.

The problem with the **[ReversingLabs](https://github.com/reversinglabs/reversinglabs-yara-rules)** rules is that they are difficult to replicate for testing by simply manipulating strings.

My objective is to create a custom YARA rule that replicates the above two rules and also to understand how to inject these signatures into files so that the rule can detect them.

## Install YARA from Ubuntu Repositories
`sudo apt update`
`sudo apt install yara`
`yara --version`

## Command to inject the errors
### Using tee for Elevated Write Access
#### For GwisinLocker (Korean threat actor, Linux-based ransomware)
```
echo -n "GwisinLocker ransom Www.Gwisin.Co.Kr" | sudo tee vm_agent.bin > /dev/null
echo -ne '\x47\x77\x69\x73\x69\x6E\x00\x6C\x6F\x63\x6B' | sudo tee -a vm_agent.bin > /dev/null
```

**Verify the output using Hexdump**
```
$ hexdump -C vm_agent.bin
00000000  47 77 69 73 69 6e 4c 6f  63 6b 65 72 20 72 61 6e  |GwisinLocker ran|
00000010  73 6f 6d 20 57 77 77 2e  47 77 69 73 69 6e 2e 43  |som Www.Gwisin.C|
00000020  6f 2e 4b 72 47 77 69 73  69 6e 00 6c 6f 63 6b     |o.KrGwisin.lock|
0000002f
```


#### For Helldown (also Korean-themed ransomware)

```
echo -n "hell_down korea_ransomware_team ransom" | sudo tee init_exec_lockdown.sh > /dev/null
echo -ne '\x48\x65\x6C\x6C\x44\x6F\x77\x6E\x00\x6C\x6F\x63\x6B' | sudo tee -a init_exec_lockdown.sh > /dev/null
```

**Verify the output using Hexdump**
```
$ hexdump -C init_exec_lockdown.sh
00000000  68 65 6c 6c 5f 64 6f 77  6e 20 6b 6f 72 65 61 5f  |hell_down korea_|
00000010  72 61 6e 73 6f 6d 77 61  72 65 5f 74 65 61 6d 20  |ransomware_team |
00000020  72 61 6e 73 6f 6d 48 65  6c 6c 44 6f 77 6e 00 6c  |ransomHellDown.l|
00000030  6f 63 6b                                          |ock|
00000033
```
***
## Update `.env` file
```bash
sudo sed -i.bak 's@^#API-KEY=.*@API-KEY=aTY0YW1lZDZkdXI4c3ZrYmpnY2M2dXV0ajNrYg==@' /r-shield/.env
```

## Update `r-shield-config` file

```bash
# R-Shield Configuration
# Format: KEY=VALUE
#
# [Required] HYCU endpoint (https://<ip>:<port>)
HYCU_URL=https://10.169.28.55:8443
#
# [Optional] Notification webhook URL
WEBHOOK=https://hycuinc.webhook.office.com/webhookb2/97ec80b4-ca0b-4c4d-a138-365bddaa4f46@a2bad164-be70-4a5f-9b9b-cd882b76486c/IncomingWebhook/2ac4217871a4409b91be6a148e932a39/0c58bb82-5185-4260-835d-003e3f0bfe93/V26kL49By0wAVGylZSRivBDI_UBq67gSnHvPSUf8Vr8gQ1
#
# [Optional] Text file with VM names (one per line)
# File must be located within the "/r-shield/" directory
VM_LIST=vm_list
#
# [Optional] Custom YARA rules directory
# Folder must be located within the "/r-shield/" directory
#RULES=manual_rules/
#
# [Optional] Parallel scans (default=4)
#CONCURRENCY=4
#
# [Optional] Uncomment for full scans (ignores incremental optimizations)
FORCE_FULL_SCAN=True
#
# [Optional] Uncomment to exclude Open File errors from webhook notifications
#SUPPRESS_COULD_NOT_OPEN_FILE_ERROR=True
```
