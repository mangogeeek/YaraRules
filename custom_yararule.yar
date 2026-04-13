rule Linux_Ransomware_GwisinLocker
{
    meta:
        author = "Piyush"
        description = "GwisinLocker test rule aligned with injected sample"
        date = "2025-04-29"
        family = "GwisinLocker"
        testable = true

    strings:
        $s1 = "GwisinLocker" nocase
        $s2 = "Www.Gwisin.Co.Kr" nocase
        $r  = "ransom" nocase
        $h  = { 47 77 69 73 69 6E 00 6C 6F 63 6B }

    condition:
        all of them
}

rule Linux_Ransomware_Helldown
{
    meta:
        author = "Piyush"
        description = "Helldown test rule aligned with injected sample"
        date = "2025-04-29"
        family = "Helldown"
        testable = true

    strings:
        $s1 = "hell_down" nocase
        $s2 = "korea_ransomware_team" nocase
        $r  = "ransom" nocase
        $h  = { 48 65 6C 6C 44 6F 77 6E 00 6C 6F 63 6B }

    condition:
        all of them
}
