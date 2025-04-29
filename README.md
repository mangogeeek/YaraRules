# YaraRules
I want to create a manual YARA rule similar to the rules available at https://github.com/reversinglabs/reversinglabs-yara-rules/blob/develop/yara/ransomware/Linux.Ransomware.GwisinLocker.yara and https://github.com/reversinglabs/reversinglabs-yara-rules/blob/develop/yara/ransomware/Linux.Ransomware.Helldown.yara.

The problem with the **[ReversingLabs](https://github.com/reversinglabs/reversinglabs-yara-rules)** rules is that they are difficult to replicate for testing by simply manipulating strings.

My objective is to create a custom YARA rule that replicates the above two rules and also to understand how to inject these signatures into files so that the rule can detect them.

## Command to inject the errors
### Using tee for Elevated Write Access

`echo -n "This is a fake GwisinLocker ransomware payload ransom Www.Gwisin.Co.Kr" | sudo tee test_gwisin > /dev/null`

`echo -ne '\x47\x77\x69\x73\x69\x6E\x00\x6C\x6F\x63\x6B' | sudo tee -a test_gwisin > /dev/null`

### Verify the output using Hexdump

```
:~$ hexdump -C test_gwisin
00000000  54 68 69 73 20 69 73 20  61 20 66 61 6b 65 20 47  |This is a fake G|
00000010  77 69 73 69 6e 4c 6f 63  6b 65 72 20 72 61 6e 73  |wisinLocker rans|
00000020  6f 6d 77 61 72 65 20 70  61 79 6c 6f 61 64 20 72  |omware payload r|
00000030  61 6e 73 6f 6d 20 57 77  77 2e 47 77 69 73 69 6e  |ansom Www.Gwisin|
00000040  2e 43 6f 2e 4b 72 47 77  69 73 69 6e 00 6c 6f 63  |.Co.KrGwisin.loc|
00000050  6b                                                |k|
00000051
```

