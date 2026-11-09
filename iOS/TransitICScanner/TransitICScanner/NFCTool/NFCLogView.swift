import SwiftUI
import SwiftData

struct NFCLogView: View {
    @Query
    private var cards: [SavedCard]

    private var logCards: [SavedCard] {
        let cardsWithLog = cards.filter { card in
            guard let fullLog = card.fullLog else {
                return false
            }

            return !fullLog.isEmpty
        }

        let grouped = Dictionary(
            grouping: cardsWithLog,
            by: { $0.name }
        )

        return grouped.compactMap { _, cards in
            cards.max {
                ($0.savedAt ?? .distantPast) < ($1.savedAt ?? .distantPast)
            }
        }
        .sorted {
            let lhsDate = $0.savedAt ?? .distantPast
            let rhsDate = $1.savedAt ?? .distantPast

            return lhsDate > rhsDate
        }
    }

    var body: some View {
        NavigationStack {
            List {
                if logCards.isEmpty {
                    ContentUnavailableView(
                        LocalizedStringKey("nfc.log.empty"),
                        systemImage: "doc.text"
                    )
                } else {
                    ForEach(logCards) { card in
                        NavigationLink {
                            NFCLogDetailView(card: card)
                        } label: {
                            HStack {
                                Image(systemName: "doc.text")
                                    .font(.title2)
                                    .frame(
                                        width: 40,
                                        height: 40
                                    )

                                VStack(
                                    alignment: .leading,
                                    spacing: 3
                                ) {
                                    if let displayName = card.displayName,
                                        !displayName.isEmpty
                                    {
                                        Text(
                                            LocalizedStringKey(displayName)
                                        )
                                        .font(.headline)

                                        Text(
                                            LocalizedStringKey(card.name)
                                        )
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                    } else {
                                        Text(
                                            LocalizedStringKey(card.nameShort)
                                        )
                                        .font(.headline)

                                        Text(
                                            LocalizedStringKey(card.name)
                                        )
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                    }

                                    if let savedAt = card.savedAt {
                                        Text(
                                            savedAt,
                                            format: Date.FormatStyle(
                                                date: .numeric,
                                                time: .shortened
                                            )
                                        )
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    }
                                }

                                Spacer()
                            }
                        }
                    }
                }
            }
            .navigationTitle("tool.fullLog")
        }
    }
}

struct NFCLogDetailView: View {
    let card: SavedCard

    private var result: ScanResult {
        card.result()
    }

    private var exportText: String {
        var lines: [String] = []

        func append(_ name: String, _ value: String?) {
            guard let value, !value.isEmpty else {
                return
            }

            lines.append("\(name): \(value)")
        }

        append("Scanning at ", Localize("appName"))
        lines.append("")
        append("IDm", result.info?.idm)
        append("Name", Localize(result.info?.name ?? ""))
        append("Serial", result.info?.serial)
        append("Version", result.info?.version)
        append("Valid Date", result.info?.validDate)
        append("Balance", String(result.balance ?? 0))
        append("Is History", String(result.isHistory))
        append("History Count", String(result.history?.count ?? 0))

        if let savedAt = result.savedAt {
            append(
                "Saved At",
                savedAt.formatted(
                    date: .numeric,
                    time: .standard
                )
            )
        }
        lines.append("")

        if let fullLog = result.fullLog {
            lines.append(fullLog)
        }

        return lines.joined(separator: "\n")
    }

    private var fileName: String {
        let sanitizedName =
            card.name
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "\\", with: "_")
            .replacingOccurrences(of: ":", with: "_")
            + "_" + String(card.idm)

        return "\(sanitizedName)_NFCLog.txt"
    }

    var body: some View {
        ScrollView {
            VStack(
                alignment: .leading,
                spacing: 3
            ) {
                Group {
                    informationRow(
                        name: "Scanning at ",
                        value: Localize("appName")
                    )
                    informationRow(
                        name: "IDm",
                        value: result.info?.idm
                    )

                    informationRow(
                        name: "Name",
                        value: Localize(result.info?.name ?? "")
                    )

                    informationRow(
                        name: "Serial",
                        value: result.info?.serial
                    )

                    informationRow(
                        name: "Version",
                        value: result.info?.version
                    )

                    informationRow(
                        name: "Valid Date",
                        value: result.info?.validDate
                    )

                    informationRow(
                        name: "Balance",
                        value: String(result.balance ?? 0)
                    )

                    informationRow(
                        name: "Is History",
                        value: String(result.isHistory)
                    )

                    if let savedAt = result.savedAt {
                        informationRow(
                            name: "Saved At",
                            value: savedAt.formatted(
                                date: .numeric,
                                time: .standard
                            )
                        )
                    }
                }
                Text(result.fullLog ?? "")
                    .font(.system(.body, design: .monospaced))
                    .textSelection(.enabled)
                    .frame(
                        maxWidth: .infinity,
                        alignment: .leading
                    )
            }
            .padding()
        }
        .navigationTitle(LocalizedStringKey(card.name))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                ShareLink(
                    item: exportText,
                    preview: SharePreview(
                        fileName,
                        image: Image(systemName: "doc.text")
                    )
                ) {
                    Image(systemName: "square.and.arrow.up")
                }
            }
        }
    }

    @ViewBuilder
    private func informationRow(
        name: String,
        value: String?
    ) -> some View {
        if let value, !value.isEmpty {
            HStack(
                alignment: .top,
                spacing: 8
            ) {
                Text(name)
                    .fontWeight(.semibold)
                    .frame(
                        minWidth: 110,
                        alignment: .leading
                    )

                Text(value)
                    .textSelection(.enabled)
                    .frame(
                        maxWidth: .infinity,
                        alignment: .leading
                    )
            }
        }
    }
}
