import Foundation
import WidgetKit
import SwiftData

enum CloudSyncSettings {
    private static let key = "cloudSyncEnabled"

    static var isEnabled: Bool {
        if UserDefaults.standard.object(forKey: key) == nil {
            return true
        }

        return UserDefaults.standard.bool(forKey: key)
    }

    static func setEnabled(_ enabled: Bool) {
        UserDefaults.standard.set(
            enabled,
            forKey: key
        )
    }
}

enum SavedDataModelContainer {
    static func deleteStore() throws {
        let fileManager = FileManager.default

        guard let containerURL = fileManager.containerURL(
            forSecurityApplicationGroupIdentifier: AppGroup
        ) else {
            print("App GroupのURLを取得できません")
            return
        }

        let applicationSupportURL = containerURL
            .appendingPathComponent("Library")
            .appendingPathComponent("Application Support")

        let storeURL = applicationSupportURL
            .appendingPathComponent("default.store")

        let storeFiles = [
            storeURL,
            storeURL.appendingPathExtension("shm"),
            storeURL.appendingPathExtension("wal")
        ]

        for url in storeFiles {
            if fileManager.fileExists(atPath: url.path) {
                print("SwiftDataストア削除:", url.path)
                try fileManager.removeItem(at: url)
            }
        }
    }

    static func makeContainer() throws -> ModelContainer {
        let schema = Schema([
            SavedCard.self,
            SavedHistory.self
        ])

        let configuration: ModelConfiguration

        if CloudSyncSettings.isEnabled {
            print("CloudKit ON")

            configuration = ModelConfiguration(
                schema: schema,
                cloudKitDatabase: .private(
                    cloudKitContainerIdentifier
                )
            )
        } else {
            print("CloudKit OFF")

            configuration = ModelConfiguration(
                schema: schema
            )
        }

        return try ModelContainer(
            for: schema,
            configurations: [configuration]
        )
    }
}

@Model
final class SavedCard {
    var idm: String = ""

    var name: String = ""
    var nameShort: String = ""
    var displayName: String?
    var iconName: String?
    var currency: String = ""
    var type: String = ""
    var serial: String?
    var version: String?
    var validDate: String?

    var balance: Double?
    var isLastHide: Bool = false
    var cardDescription: String = ""

    var converterTypeRaw: String?

    var savedAt: Date? = Date.now

    var fullLog: String?

    @Relationship(
        deleteRule: .cascade,
        inverse: \SavedHistory.card
    )
    var histories: [SavedHistory]? = []

    var currencyType: currencyType? {
        TransitICScanner.currencyType(
            rawValue: currency.lowercased()
        )
    }

    init(
        idm: String,
        name: String,
        nameShort: String,
        displayName: String,
        iconName: String,
        currency: String,
        type: String,
        serial: String? = nil,
        version: String? = nil,
        validDate: String? = nil,
        balance: Double? = nil,
        isLastHide: Bool = false,
        cardDescription: String = "",
        converterType: ConverterType,
        savedAt: Date,
        fullLog: String? = nil
    ) {
        self.idm = idm
        self.name = name
        self.nameShort = nameShort
        self.displayName = displayName
        self.iconName = iconName
        self.currency = currency
        self.type = type
        self.serial = serial
        self.version = version
        self.validDate = validDate
        self.balance = balance
        self.isLastHide = isLastHide
        self.cardDescription = cardDescription
        self.converterTypeRaw = converterType.rawValue
        self.histories = []
        self.savedAt = savedAt
        self.fullLog = fullLog
    }

    var converterType: ConverterType {
        guard let converterTypeRaw else {
            return .jpIC
        }

        return ConverterType(rawValue: converterTypeRaw) ?? .jpIC
    }
}

@Model
final class SavedHistory {
    var processType: Int = 0

    var dateYear: Int?
    var dateMonth: Int?
    var dateDay: Int?
    var dateHour: Int?
    var dateMinute: Int?
    var dateSecond: Int?

    var balance: Double = 0
    var amount: Double?

    var lineIn: Int = 0
    var stationIn: Int = 0
    var lineOut: Int = 0
    var stationOut: Int = 0

    var transactionId: Int = 0
    var mappingID: String = ""

    var card: SavedCard?

    init(
        processType: Int,
        date: DateComponents,
        balance: Double,
        amount: Double?,
        lineIn: Int,
        stationIn: Int,
        lineOut: Int,
        stationOut: Int,
        transactionId: Int,
        mappingID: String
    ) {
        self.processType = processType
        self.dateYear = date.year
        self.dateMonth = date.month
        self.dateDay = date.day
        self.dateHour = date.hour
        self.dateMinute = date.minute
        self.dateSecond = date.second
        self.balance = balance
        self.amount = amount
        self.lineIn = lineIn
        self.stationIn = stationIn
        self.lineOut = lineOut
        self.stationOut = stationOut
        self.transactionId = transactionId
        self.mappingID = mappingID
    }

    var date: DateComponents {
        DateComponents(
            calendar: Calendar(identifier: .gregorian),
            timeZone: TimeZone.current,
            year: dateYear,
            month: dateMonth,
            day: dateDay,
            hour: dateHour,
            minute: dateMinute,
            second: dateSecond
        )
    }
}

extension SavedCard {
    func result() -> Result {
        let info = ResultCardInfo(
            idm: idm,
            name: name,
            nameShort: nameShort,
            displayName: displayName,
            iconName: iconName,
            currency: currency,
            currencyType: currencyType,
            type: type,
            serial: serial,
            version: version,
            validDate: validDate
        )

        let history = (histories ?? []).map { item in
            ResultHistory(
                processType: UInt8(clamping: item.processType),
                date: item.date,
                balance: item.balance,
                amount: item.amount,
                lineIn: UInt8(clamping: item.lineIn),
                stationIn: UInt8(clamping: item.stationIn),
                lineOut: UInt8(clamping: item.lineOut),
                stationOut: UInt8(clamping: item.stationOut),
                transactionId: item.transactionId,
                mappingID: item.mappingID
            )
        }

        return Result(
            balance: balance,
            isHistory: !history.isEmpty,
            history: history.isEmpty ? nil : history,
            info: info,
            converter: converterType,
            isLastHide: isLastHide,
            description: cardDescription,
            savedAt: savedAt,
            fullLog: fullLog
        )
    }
}

enum ResultSave {

    static func save(
        _ result: Result,
        in modelContext: ModelContext
    ) throws {
        guard let info = result.info else {
            return
        }

        let descriptor = FetchDescriptor<SavedCard>(
            predicate: #Predicate {
                $0.idm == info.idm
            }
        )

        let card: SavedCard

        if let existingCard = try modelContext.fetch(descriptor).first {
            card = existingCard
        } else {
            card = SavedCard(
                idm: info.idm,
                name: info.name,
                nameShort: info.nameShort,
                displayName: info.displayName ?? "",
                iconName: info.iconName ?? "",
                currency: info.currency ?? info.currencyType?.rawValue ?? "",
                type: info.type,
                serial: info.serial,
                version: info.version,
                validDate: info.validDate,
                balance: result.balance,
                isLastHide: result.isLastHide,
                cardDescription: result.description,
                converterType: result.converter,
                savedAt: result.savedAt ?? Date.now,
                fullLog: result.fullLog
            )

            modelContext.insert(card)

            print("insert直後:", card)
            print("insert直後 hasChanges:", modelContext.hasChanges)

            print(
                "insert直後の件数:",
                try modelContext.fetch(
                    FetchDescriptor<SavedCard>()
                ).count
            )
        }

        card.name = info.name
        card.nameShort = info.nameShort
        card.displayName = info.displayName
        card.iconName = info.iconName
        card.currency = info.currency ?? info.currencyType?.rawValue ?? ""
        card.type = info.type
        card.serial = info.serial
        card.version = info.version
        card.validDate = info.validDate
        card.balance = result.balance
        card.isLastHide = result.isLastHide
        card.cardDescription = result.description
        card.converterTypeRaw = result.converter.rawValue
        card.savedAt = result.savedAt
        card.fullLog = result.fullLog

        if let histories = result.history {
            var existingTransactionIDs = Set(
                (card.histories ?? []).map(\.transactionId)
            )

            for history in histories {
                guard !existingTransactionIDs.contains(
                    history.transactionId
                ) else {
                    continue
                }

                let savedHistory = SavedHistory(
                    processType: Int(history.processType),
                    date: history.date,
                    balance: history.balance,
                    amount: history.amount,
                    lineIn: Int(history.lineIn),
                    stationIn: Int(history.stationIn),
                    lineOut: Int(history.lineOut),
                    stationOut: Int(history.stationOut),
                    transactionId: history.transactionId,
                    mappingID: history.mappingID
                )

                savedHistory.card = card

                if card.histories == nil {
                    card.histories = []
                }

                card.histories?.append(savedHistory)

                modelContext.insert(savedHistory)

                existingTransactionIDs.insert(
                    history.transactionId
                )
            }
        }

        try modelContext.save()

        let cards = try modelContext.fetch(
            FetchDescriptor<SavedCard>()
        )

        print("保存直後のSavedCard数:", cards.count)

        for card in cards {
            print(
                "SavedCard:",
                card.idm,
                card.name
            )
        }

        var widgetModels: [BalanceWidgetModel] = []
        let sharedDefaults = UserDefaults(suiteName: AppGroup)

        if let savedData = sharedDefaults?.data(
            forKey: "widgetDatas"
        ),
           let decodedUsers = try? JSONDecoder().decode(
            [BalanceWidgetModel].self,
            from: savedData
           ) {
            widgetModels = decodedUsers
        }

        let saveData = BalanceWidgetModel(
            DisplayName: info.displayName ?? Localize(info.name),
            balance: result.balance,
            currencyType: result.info?.currencyType,
            idm: info.idm,
            icon: info.iconName,
            savedAt: result.savedAt
        )

        widgetModels.removeAll {
            $0.idm == info.idm
        }

        widgetModels.append(saveData)

        if let encodedData = try? JSONEncoder().encode(
            widgetModels
        ) {
            sharedDefaults?.set(
                encodedData,
                forKey: "widgetDatas"
            )

            sharedDefaults?.synchronize()

            print("Widget保存:")
            print("AppGroup:", AppGroup)
            print("件数:", widgetModels.count)
            print("データサイズ:", encodedData.count)
        } else {
            print("WidgetデータのEncodeに失敗")
        }

        print(
            "Widget保存後:",
            sharedDefaults?.data(forKey: "widgetDatas") != nil
        )

        WidgetCenter.shared.reloadAllTimelines()
    }

    static func loadCards(
        from modelContext: ModelContext
    ) throws -> [SavedCard] {
        let descriptor = FetchDescriptor<SavedCard>(
            sortBy: [
                SortDescriptor(\.name)
            ]
        )

        return try modelContext.fetch(descriptor)
    }

    static func loadCard(
        idm: String,
        from modelContext: ModelContext
    ) throws -> SavedCard? {
        let descriptor = FetchDescriptor<SavedCard>(
            predicate: #Predicate {
                $0.idm == idm
            }
        )

        return try modelContext.fetch(descriptor).first
    }

    static func deleteCard(
        idm: String,
        from modelContext: ModelContext
    ) throws {
        guard let card = try loadCard(
            idm: idm,
            from: modelContext
        ) else {
            return
        }

        modelContext.delete(card)
        try modelContext.save()

        var widgetModels: [BalanceWidgetModel] = []
        let sharedDefaults = UserDefaults(suiteName: AppGroup)

        if let savedData = sharedDefaults?.data(
            forKey: "widgetDatas"
        ),
           let decodedUsers = try? JSONDecoder().decode(
            [BalanceWidgetModel].self,
            from: savedData
           ) {
            widgetModels = decodedUsers
        }

        widgetModels.removeAll {
            $0.idm == idm
        }

        if let encodedData = try? JSONEncoder().encode(
            widgetModels
        ) {
            sharedDefaults?.set(
                encodedData,
                forKey: "widgetDatas"
            )
        }

        WidgetCenter.shared.reloadAllTimelines()
    }

    static func deleteAll(
        from modelContext: ModelContext
    ) throws {
        let cards = try loadCards(
            from: modelContext
        )

        for card in cards {
            modelContext.delete(card)
        }

        try modelContext.save()

        var widgetModels: [BalanceWidgetModel] = []
        let sharedDefaults = UserDefaults(suiteName: AppGroup)

        if let encodedData = try? JSONEncoder().encode(
            widgetModels
        ) {
            sharedDefaults?.set(
                encodedData,
                forKey: "widgetDatas"
            )
        }
    }

    static func resetSavedData(
        from modelContext: ModelContext
    ) {
        do {
            try modelContext.delete(
                model: SavedCard.self
            )

            try modelContext.delete(
                model: SavedHistory.self
            )

            try modelContext.save()

            print("保存データをリセットしました")
        } catch {
            print(
                "保存データのリセットに失敗しました: \(error)"
            )
        }
    }
}
