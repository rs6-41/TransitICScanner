import Foundation

enum usClipper_Converter {

    static func balance(
        _ value: Int
    ) -> String {

        let usd =
            Double(value) / 100.0

        return String(
            format: "%.2f",
            usd
        )
    }


    static func cardInfo(
        _ info: ResultCardInfo
    ) -> DisplayCardInfo {

        return DisplayCardInfo(
            idm: info.idm,
            name: info.name,
            nameShort: info.nameShort,
            currencyType:
                info.currencyType ?? .usd,
            type: "Clipper",
            typeLocalizeTable: "usClipper_cards"
        )
    }


    static func history(
        _ history: ResultHistory
    ) -> DisplayHistory {

        let processType: String

        switch history.processType {

        case 0x02:
            processType =
                String(
                    localized:
                        "result.history.charge"
                )

        case 0x04:
            processType =
                String(
                    localized:
                        "result.history.fare"
                )

        default:
            processType =
                String(
                    localized:
                        "result.history.other"
                )
        }

        return DisplayHistory(
            date:
                DateFormatter.localizedString(
                    from:
                        Calendar.current.date(
                            from:
                                history.date
                        ) ?? Date(),
                    dateStyle:
                        .short,
                    timeStyle:
                        .short
                ),
            processType:
                processType,
            balance:
                history.balance
        )
    }
}
