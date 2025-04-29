# YaraRules
I want to create a manual YARA rule similar to the rules available at https://github.com/reversinglabs/reversinglabs-yara-rules/blob/develop/yara/ransomware/Linux.Ransomware.GwisinLocker.yara and https://github.com/reversinglabs/reversinglabs-yara-rules/blob/develop/yara/ransomware/Linux.Ransomware.Helldown.yara.

The problem with the **[ReversingLabs](https://github.com/reversinglabs/reversinglabs-yara-rules)** rules is that they are difficult to replicate for testing by simply manipulating strings.

My objective is to create a custom YARA rule that replicates the above two rules and also to understand how to inject these signatures into files so that the rule can detect them.
