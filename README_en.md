[日本語](README.md)

# Worldwide Transit IC Balance Checker

[![Swift 6.4.2](https://img.shields.io/badge/Swift-6.4.2-orange?logo=swift&logoColor=white)](./doc/dev/README.md)
[![Xcode 27.2](https://img.shields.io/badge/Xcode-27.2-147EFB?logo=xcode&logoColor=white)](./doc/dev/README.md)
[![iOS 26.4+](https://img.shields.io/badge/iOS-26.4%2B-blue?logo=apple&logoColor=white)](#platforms)
[![macOS 26.4+](https://img.shields.io/badge/macOS-26.4%2B-blue?logo=apple&logoColor=white)](#platforms)
[![App Store](https://img.shields.io/badge/App_Store-Download-0D96F6?logo=appstore&logoColor=white)](https://apps.apple.com/app/id6812794719)
[![CI](https://img.shields.io/github/actions/workflow/status/rs6-41/TransitICScanner/ci.yml?branch=main&label=CI&logo=github)](https://github.com/rs6-41/TransitICScanner/actions/workflows/ci.yml)

An application that scans transit IC cards worldwide and retrieves their balances and transaction history.

## Platforms

| OS | Link | Requirements | External Reader |
| -- | -- | -- | -- |
| iOS | [App Store](https://apps.apple.com/us/app/世界ic残高確認/id6812794719) / [Testflight](https://testflight.apple.com/join/bANTBhFn) | iOS 26.4+ | Supported |
| macOS | [App Store](https://apps.apple.com/us/app/世界ic残高確認/id6812794719) / [Testflight](https://testflight.apple.com/join/bANTBhFn) | macOS 26.4+ | Required |
| watchOS | [Testflight](https://testflight.apple.com/join/bANTBhFn) | watchOS 26.4+ | - |
| Android | Not implemented | TBD | TBD |
| HarmonyOS | Not implemented | HarmonyOS NEXT | TBD |
| Windows | Not implemented | TBD | Required |

- [Development Environment & Guidelines](./doc/dev/README.md)
- [LLM Development Skills](./skills/README.md)

## Supported Cards

**Note:** The built-in NFC reader on iPhone does not support reading MIFARE Classic cards.

### East Asia

| Region | Name | Implementation ID | NFC | Standard | Status | Notes |
| -- | -- | -- | -- | -- | -- | -- |
| Japan | Japanese Transit IC | jpIC | Type-F | [Cybernetics](./doc/cards/jpIC.md) | ✅ | |
| Mainland China | China T-Union | cnTunion | Type-A | [China T-Union](./doc/cards/cnTunion.md) | ✅ | |
| Hong Kong | Octopus | hkOctopus | Type-F | [Octopus](./doc/cards/hkOctopus.md) | ✅ | A China T-Union-compatible version also exists |
| Macau | Macau Pass | | Type-A | MIFARE Classic | | A China T-Union-compatible version also exists |
| Taiwan | EasyCard | twEasyCard_old | Type-A | MIFARE Classic | [Web scraping](./doc/cards/twEasyCard_old.md) | |
| Taiwan | Super EasyCard | | Type-A | | | A next-generation version that supports reading and writing via smartphones |
| Taiwan | iPASS | | Type-A | MIFARE Classic | | |
| Taiwan | iPASS Plus | | Type-A | | | A next-generation version that supports reading and writing via smartphones |
| Taiwan | iCash | twICash | Type-A | [iCash](./doc/cards/twICash.md) | ✅ | |
| South Korea | OneCard AllPass | krOneCard | Type-A | [KS X 6924](./doc/cards/krOneCard.md) | ✅ | |
| North Korea (Pyongyang) | Pyongyang Transit Card (Green) | | Type-A | MIFARE Classic | | |
| North Korea (Pyongyang) | Pyongyang Transit Card (Blue) | | Type-A | MIFARE Classic | | |

#### Japan (Regional Cards)

**Note:** 🈹Partial Cybernetics compatibility indicates that the card is not fully compatible with the Cybernetics standard, but shares its specifications except for the service codes.

| Region | Name | Implementation ID | NFC | Standard | Status | Notes |
| -- | -- | -- | -- | -- | -- | -- |
| Hokkaido (Asahikawa) | DoCard / Asaca | jpDoCard | Type-F | [DoCard / Asaca](./doc/cards/jpDoCard.md) | ✅ | |
| Sapporo | SAPICA | jpIC_SAPICA | Type-F | [🈹Partial Cybernetics](./doc/cards/jpIC.md) | ✅ | |
| Kagawa | IruCa | jpIC_IruCa | Type-F | [🈹Partial Cybernetics](./doc/cards/jpIC.md) | ✅ | |
| Nagasaki | Nagasaki N+ Card | jpNplus | Type-F | [Nagasaki N+ Card](./doc/cards/jpNplus.md) | ✅ | |
| Miyagi | icsca | jpIC_icsca | Type-F | [🈹Partial Cybernetics](./doc/cards/jpIC.md) | ✅ | |
| Okinawa | OKICA | jpOKICA | Type-F | [OKICA](./doc/cards/jpOKICA.md) | ✅ | |
| Kagoshima | Rapica / Iwasaki IC Card | jpRapica | Type-F | [Rapica](./doc/cards/jpRapica.md) | ✅ | |

### Southeast Asia

- Singapore [EZ-Link (CEPAS)](./doc/cards/spEZLink.md) — Balance and transaction scanning in the development card list. EZ-Link balance and history verified with a PaSoRi reader on Mac.

### North America

| Region | Name | Implementation ID | NFC | Standard | Status | Notes |
| -- | -- | -- | -- | -- | -- | -- |
| United States (San Francisco) | Clipper | usClipper | Type-A | [Clipper](./doc/cards/usClipper.md) | ✅ | |