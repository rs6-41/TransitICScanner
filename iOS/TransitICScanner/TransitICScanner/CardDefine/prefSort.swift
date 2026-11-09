import SwiftUI

func prefSort(_ prefecture: String) -> Int {
    switch prefecture {
    //日本
    case "Hokkaido": return 0
    case "Aomori": return 1
    case "Iwate": return 2
    case "Miyagi": return 3
    case "Akita": return 4
    case "Yamagata": return 5
    case "Fukushima": return 6
    case "Ibaraki": return 7
    case "Tochigi": return 8
    case "Gunma": return 9
    case "Saitama": return 10
    case "Chiba": return 11
    case "Tokyo": return 12
    case "Kanagawa": return 13
    case "Niigata": return 14
    case "Toyama": return 15
    case "Ishikawa": return 16
    case "Fukui": return 17
    case "Yamanashi": return 18
    case "Nagano": return 19
    case "Gifu": return 20
    case "Shizuoka": return 21
    case "Aichi": return 22
    case "Mie": return 23
    case "Shiga": return 24
    case "Kyoto": return 25
    case "Osaka": return 26
    case "Hyogo": return 27
    case "Nara": return 28
    case "Wakayama": return 29
    case "Tottori": return 30
    case "Shimane": return 31
    case "Okayama": return 32
    case "Hiroshima": return 33
    case "Yamaguchi": return 34
    case "Tokushima": return 35
    case "Kagawa": return 36
    case "Ehime": return 37
    case "Kochi": return 38
    case "Fukuoka": return 39
    case "Saga": return 40
    case "Nagasaki": return 41
    case "Kumamoto": return 42
    case "Oita": return 43
    case "Miyazaki": return 44
    case "Kagoshima": return 45
    case "Okinawa": return 46

    // アメリカ
    case "AL": return 0
    case "AK": return 1
    case "AZ": return 2
    case "AR": return 3
    case "CA": return 4
    case "CO": return 5
    case "CT": return 6
    case "DE": return 7
    case "FL": return 8
    case "GA": return 9
    case "HI": return 10
    case "ID": return 11
    case "IL": return 12
    case "IN": return 13
    case "IA": return 14
    case "KS": return 15
    case "KY": return 16
    case "LA": return 17
    case "ME": return 18
    case "MD": return 19
    case "MA": return 20
    case "MI": return 21
    case "MN": return 22
    case "MS": return 23
    case "MO": return 24
    case "MT": return 25
    case "NE": return 26
    case "NV": return 27
    case "NH": return 28
    case "NJ": return 29
    case "NM": return 30
    case "NY": return 31
    case "NC": return 32
    case "ND": return 33
    case "OH": return 34
    case "OK": return 35
    case "OR": return 36
    case "PA": return 37
    case "RI": return 38
    case "SC": return 39
    case "SD": return 40
    case "TN": return 41
    case "TX": return 42
    case "UT": return 43
    case "VT": return 44
    case "VA": return 45
    case "WA": return 46
    case "WV": return 47
    case "WI": return 48
    case "WY": return 49
    case "DC": return 50

    default: return -1
    }
}
