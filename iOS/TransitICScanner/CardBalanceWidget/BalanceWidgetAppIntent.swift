import WidgetKit
import AppIntents
import SwiftUI

final class CardBalanceModel {
    let name: String
    let idm: String

    init(name: String, idm: String) {
        self.name = name
        self.idm = idm
    }
}

extension CardBalanceModel: AppEntity {
    typealias ID = String
    
    var id: String {
        idm
    }
    
    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(stringLiteral: name)
    }

    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        "widget.balance.setting.card.none"
    }

    static var defaultQuery = CardBalanceQuery()
}

struct CardBalanceQuery: EntityQuery {

    func suggestedEntities() async throws -> [CardBalanceModel] {
        let savedWidgetData = getSavedWidgetData()

        return savedWidgetData.map {
            CardBalanceModel(
                name: $0.DisplayName ?? "unknown",
                idm: $0.idm
            )
        }
    }

    func entities(for ids: [CardBalanceModel.ID]) async throws -> [CardBalanceModel] {
        let savedWidgetData = getSavedWidgetData()

        return savedWidgetData
            .filter { ids.contains($0.idm) }
            .map {
                CardBalanceModel(
                    name: $0.DisplayName ?? "unknown",
                    idm: $0.idm
                )
            }
    }
}
