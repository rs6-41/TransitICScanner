import Foundation
#if !os(watchOS)
import WidgetKit
#endif
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

@MainActor
enum SavedDataModelContainer {
    #if !os(watchOS)
    static func deleteStore() throws {
        let fileManager = FileManager.default

        guard
            let containerURL = fileManager.containerURL(
                forSecurityApplicationGroupIdentifier: StorageConfig.appGroup
            )
        else {
            Log.debug("App GroupのURLを取得できません")
            return
        }

        let applicationSupportURL =
            containerURL
            .appendingPathComponent("Library")
            .appendingPathComponent("Application Support")

        let storeURL =
            applicationSupportURL
            .appendingPathComponent("default.store")

        let storeFiles = [
            storeURL,
            storeURL.appendingPathExtension("shm"),
            storeURL.appendingPathExtension("wal"),
        ]

        for url in storeFiles {
            if fileManager.fileExists(atPath: url.path) {
                Log.debug("SwiftDataストア削除:", url.path)
                try fileManager.removeItem(at: url)
            }
        }
    }
    #endif

    /// 起動時に使った保存先の状態
    enum StartupState: Equatable {
        /// 設定どおり（iCloud 同期の設定に従う）
        case normal
        /// iCloud 同期付きで開けなかったため、この端末のみに保存している
        case localOnly
        /// 保存データを開けなかったため、一時的なメモリ上の保存先を使っている（終了すると消える）
        case inMemory
    }

    private(set) static var startupState: StartupState = .normal

    private static var schema: Schema {
        Schema([
            SavedCard.self,
            SavedHistory.self,
        ])
    }

    static func makeContainer() throws -> ModelContainer {
        try makeContainer(cloudSync: CloudSyncSettings.isEnabled)
    }

    /// 起動用の ModelContainer を作る。失敗してもアプリが起動できるよう、
    /// iCloud 同期なし → メモリ上の一時保存の順に切り替える。
    static func makeContainerWithFallback() -> ModelContainer {
        do {
            let container = try makeContainer()
            startupState = .normal
            return container
        } catch {
            Log.error("ModelContainerを作成できません: \(error)")
        }

        if CloudSyncSettings.isEnabled {
            do {
                let container = try makeContainer(cloudSync: false)
                startupState = .localOnly
                return container
            } catch {
                Log.error("ローカルのModelContainerも作成できません: \(error)")
            }
        }

        do {
            let configuration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: true
            )
            let container = try ModelContainer(for: schema, configurations: [configuration])
            startupState = .inMemory
            return container
        } catch {
            fatalError("メモリ上のModelContainerも作成できません: \(error)")
        }
    }

    private static func makeContainer(cloudSync: Bool) throws -> ModelContainer {
        let configuration = ModelConfiguration(
            schema: schema,
            groupContainer: .identifier(StorageConfig.appGroup),
            cloudKitDatabase: cloudSync
                ? .private(StorageConfig.cloudKitContainerIdentifier)
                : .none
        )

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

    var issueInfo: IssueInfo?

    @Relationship(
        deleteRule: .cascade,
        inverse: \SavedHistory.card
    )
    var histories: [SavedHistory]? = []

    var parsedCurrencyType: CurrencyType? {
        CurrencyType(rawValue: currency.lowercased())
    }

    // 保存スキーマを変えず、旧カード名・画像名を現行の表示キーへ解決する。
    var nameKey: String { CardIdentity.localizationKey(name) }
    var nameShortKey: String { CardIdentity.localizationKey(nameShort) }
    var iconAssetName: String? { iconName.map(CardIdentity.assetName) }

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
        converterTypeRaw: String? = nil,
        savedAt: Date,
        fullLog: String? = nil,
        issueInfo: IssueInfo? = nil
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
        self.converterTypeRaw = converterTypeRaw
        self.histories = []
        self.savedAt = savedAt
        self.fullLog = fullLog
        self.issueInfo = issueInfo
    }

    #if !os(watchOS)
    var converterType: ConverterType {
        guard let converterTypeRaw else {
            return .jpIC
        }

        return ConverterType(rawValue: CardIdentity.savedConverterID(converterTypeRaw, cardNumber: idm)) ?? .jpIC
    }
    #endif
}

@Model
final class SavedHistory {
    var processType: Int = 0
    var processType4: Int = 0

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
        processType4: Int,
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
        self.processType4 = processType4
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
    func result() -> ScanResult {
        let info = ResultCardInfo(
            idm: idm,
            name: nameKey,
            nameShort: nameShortKey,
            displayName: displayName,
            iconName: iconAssetName,
            currencyType: parsedCurrencyType,
            type: CardIdentity.localizationKey(type),
            serial: serial,
            version: version,
            validDate: validDate,
            issueInfo: issueInfo
        )

        let history = (histories ?? []).map { item in
            ResultHistory(
                processType: UInt8(clamping: item.processType),
                processType4: UInt32(clamping: item.processType4),
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

        #if os(watchOS)
        return ScanResult(
            balance: balance,
            isHistory: !history.isEmpty,
            history: history.isEmpty ? nil : history,
            info: info,
            isLastHide: isLastHide,
            description: CardIdentity.localizationKey(cardDescription),
            savedAt: savedAt,
            fullLog: fullLog,
            converterTypeRaw: converterTypeRaw.map { CardIdentity.savedConverterID($0, cardNumber: idm) }
        )
        #else
        return ScanResult(
            balance: balance,
            isHistory: !history.isEmpty,
            history: history.isEmpty ? nil : history,
            info: info,
            converter: converterType,
            isLastHide: isLastHide,
            description: CardIdentity.localizationKey(cardDescription),
            savedAt: savedAt,
            fullLog: fullLog,
            converterTypeRaw: converterTypeRaw.map { CardIdentity.savedConverterID($0, cardNumber: idm) }
        )
        #endif
    }
}

enum ResultSave {

    static func loadResults(
        from modelContext: ModelContext
    ) throws -> [ScanResult] {
        let descriptor = FetchDescriptor<SavedCard>(
            sortBy: [SortDescriptor(\.name)]
        )

        return try modelContext.fetch(descriptor).map { $0.result() }
    }

    #if !os(watchOS)
    static func save(
        _ result: ScanResult,
        in modelContext: ModelContext
    ) throws {
        guard let info = result.info else {
            return
        }

        let idm = info.idm
        let descriptor = FetchDescriptor<SavedCard>(
            predicate: #Predicate {
                $0.idm == idm
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
                currency: info.currencyType?.rawValue ?? "",
                type: info.type,
                serial: info.serial,
                version: info.version,
                validDate: info.validDate,
                balance: result.balance,
                isLastHide: result.isLastHide,
                cardDescription: result.description,
                converterTypeRaw: result.converter.rawValue,
                savedAt: result.savedAt ?? Date.now,
                fullLog: result.fullLog,
                issueInfo: info.issueInfo ?? nil
            )

            modelContext.insert(card)

            Log.debug("insert直後:", card)
            Log.debug("insert直後 hasChanges:", modelContext.hasChanges)

            Log.debug(
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
        card.currency = info.currencyType?.rawValue ?? ""
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
        card.issueInfo = info.issueInfo ?? nil

        if let histories = result.history {
            var existingTransactionIDs = Set(
                (card.histories ?? []).map(\.transactionId)
            )

            var cepasHistoriesByID: [Int: SavedHistory] = [:]
            if result.converter == .spEZLink {
                for savedHistory in card.histories ?? [] {
                    cepasHistoriesByID[savedHistory.transactionId] = savedHistory
                }
            }

            for history in histories {
                if let savedHistory = cepasHistoriesByID[history.transactionId],
                    history.mappingID == SPEZLinkHistory.balanceMappingID
                {
                    savedHistory.balance = history.balance
                    savedHistory.mappingID = history.mappingID
                }
                guard
                    !existingTransactionIDs.contains(
                        history.transactionId
                    )
                else {
                    continue
                }

                let savedHistory = SavedHistory(
                    processType: Int(history.processType ?? 0),
                    processType4: Int(history.processType4 ?? 0),
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

        let saveData = BalanceWidgetModel(
            displayName: info.displayName
                ?? {
                    #if os(watchOS)
                    info.name
                    #else
                    localizedString(info.name)
                    #endif
                }(),
            balance: result.balance,
            currencyType: result.info?.currencyType,
            idm: info.idm,
            icon: info.iconName,
            savedAt: result.savedAt
        )

        WidgetDataStore.update { models in
            models.removeAll { $0.idm == info.idm }
            models.append(saveData)
        }
    }

    /// 保存済みカードの表示名・券面だけを更新する。
    /// 残高や履歴は書き換えないため、他の端末で同期された新しい読取結果を上書きしない。
    static func updateUserData(
        idm: String,
        displayName: String?,
        iconName: String?,
        in modelContext: ModelContext
    ) throws {
        guard let card = try loadCard(idm: idm, from: modelContext) else {
            return
        }

        card.displayName = displayName
        card.iconName = iconName
        try modelContext.save()

        WidgetDataStore.update { models in
            guard let index = models.firstIndex(where: { $0.idm == idm }) else {
                return
            }
            if let displayName, !displayName.isEmpty {
                models[index].displayName = displayName
            }
            models[index].icon = iconName
        }
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
        guard
            let card = try loadCard(
                idm: idm,
                from: modelContext
            )
        else {
            return
        }

        modelContext.delete(card)
        try modelContext.save()

        WidgetDataStore.update { models in
            models.removeAll { $0.idm == idm }
        }
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

        WidgetDataStore.update { models in
            models.removeAll()
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

            Log.debug("保存データをリセットしました")
        } catch {
            Log.debug(
                "保存データのリセットに失敗しました: \(error)"
            )
        }
    }
    #endif
}
