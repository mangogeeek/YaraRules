rule Linux_Ransomware_GwisinLocker_Helldown
{
    meta:
        author = "Piyush"
        description = "Combined GwisinLocker and Helldown detection rule"
        date = "2025-04-29"
        families = "GwisinLocker, Helldown"
        testable = true

    strings:
        // GwisinLocker indicators
        $gwisin_str1 = "GwisinLocker" nocase
        $gwisin_str2 = "Www.Gwisin.Co.Kr" nocase
        $gwisin_hex  = { 47 77 69 73 69 6E 00 6C 6F 63 6B }

        // Helldown indicators
        $helldown_str1 = "hell_down" nocase
        $helldown_str2 = "korea_ransomware_team" nocase
        $helldown_hex  = { 48 65 6C 6C 44 6F 77 6E 00 6C 6F 63 6B }

        // Shared indicator
        $common_str = "ransom" nocase

    condition:
        (
            (any of ($gwisin_str*) and $common_str and $gwisin_hex)
        )
        or
        (
            (2 of ($helldown_str*) and $common_str and $helldown_hex)
        )
}
