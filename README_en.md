[日本語](README.md)

# Worldwide Transit IC Balance Checker

An application that scans transit IC cards worldwide and retrieves their balances and transaction history.

- [Development Environment & Guidelines](./doc/dev/README.md)

## LLM development skills

Reusable instructions, templates, and validation tools for generative AI agents are available in the top-level [skills/ directory](./skills/README.md).

| Skill | Scope |
| -- | -- |
| [Card development and issues](./skills/transit-card-workflow/SKILL.md) | Research/iOS issues, research-to-specification, specification-to-iOS implementation, and documentation/skill maintenance issues |
| [Localization completion](./skills/transit-localization/SKILL.md) | Complete missing translations from one supplied language and record context in the xcstrings JSON `comment` field |

Ask the agent to read the [root AGENTS.md](./AGENTS.md) and the relevant `SKILL.md`, then specify the target and requested stage. For example: “Use `skills/transit-card-workflow/SKILL.md` to create a card specification from the supplied research” or “Use `skills/transit-localization/SKILL.md` to complete the other languages from the Japanese text for these keys.”

These skills follow this project's models, structure, and rules. If you also want issue submission, code changes, commits, or a PR, specify that scope and the target branch. Issues and PRs written by an LLM must carry the `Agent` label while retaining existing labels.

## Platforms

| OS | Link | Requirements | External Reader |
| -- | -- | -- | -- |
| iOS | [App Store](https://apps.apple.com/us/app/世界ic残高確認/id6812794719) | iOS 26.4+ | Supported |
| macOS | [App Store](https://apps.apple.com/us/app/世界ic残高確認/id6812794719) | macOS 26.4+ | Required |
| watchOS | Unreleased | watchOS 26.4+ | - |
| Android | Not implemented | TBD | TBD |
| HarmonyOS | Not implemented | HarmonyOS NEXT | TBD |
| Windows | Not implemented | TBD | Required |

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

### North America

| Region | Name | Implementation ID | NFC | Standard | Status | Notes |
| -- | -- | -- | -- | -- | -- | -- |
| United States (San Francisco) | Clipper | usClipper | Type-A | [Clipper](./doc/cards/usClipper.md) | ✅ | |