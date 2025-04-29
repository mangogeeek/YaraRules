rule Linux_Ransomware_GwisinLocker
{
    meta:
        author = "Piyush"
        description = "Custom GwisinLocker rule with string and binary hex patterns for test use"
        date = "2025-04-29"
        family = "GwisinLocker"
        testable = true

    strings:
        $gwisin_str1 = "GwisinLocker" nocase
        $gwisin_str2 = "Www.Gwisin.Co.Kr" nocase
        $common_str  = "ransom" nocase
        $fake_hex    = { 47 77 69 73 69 6E 00 6C 6F 63 6B }  // "Gwisin\0lock"

    condition:
        (any of ($gwisin_str*) and $common_str) and $fake_hex
}
rule Linux_Ransomware_Helldown
{
    meta:
        author = "Piyush"
        description = "Custom Helldown rule with string and binary hex patterns for test use"
        date = "2025-04-29"
        family = "Helldown"
        testable = true

    strings:
        $helldown_str1 = "hell_down" nocase
        $helldown_str2 = "korea_ransomware_team" nocase
        $common_str    = "ransom" nocase
        $fake_hex      = { 48 65 6C 6C 44 6F 77 6E 00 6C 6F 63 6B }  // "HellDown\0lock"

    condition:
        (2 of ($helldown_str*) and $common_str) and $fake_hex
}
