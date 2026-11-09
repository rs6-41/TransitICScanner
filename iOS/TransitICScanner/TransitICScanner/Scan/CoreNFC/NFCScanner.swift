import UIKit
import SwiftUI
@preconcurrency import CoreNFC
public import Combine

struct ScanError: Equatable {
    var code: NFCReaderError.Code?
    /// ユーザーに表示するメッセージ
    var message: String
}

final class NFCScannerModel: NSObject, ObservableObject, NFCTagReaderSessionDelegate {
    @Published var scanError: ScanError? = nil
    @Published var scanOption: ScanOption
    @Published var sessionActive: Bool = false
    @Published var result: ScanResult? = nil

    var session: NFCTagReaderSession?
    var currentTag: NFCTag?

    init(scanOption: ScanOption) {
        self.scanOption = scanOption
        super.init()
    }

    func readerSetup() {
        self.scanError = nil

        let configuration: NFCTagReaderSession.Configuration

        if scanOption.felicaSystemCodes != nil {
            configuration = NFCTagReaderSession.Configuration(
                pollingOption: scanOption.pollingOption,
                feliCaSystemCodes: scanOption.felicaSystemCodes ?? []
            )
        } else {
            configuration = NFCTagReaderSession.Configuration(
                pollingOption: scanOption.pollingOption
            )
        }

        self.session = NFCTagReaderSession(configuration: configuration, delegate: self)
        let cardName = scanOption.nameShort
        self.session?.alertMessage = String(
            format: String(localized: "scanner.coreNFC.scan.message"),
            Localize(cardName)
        )
        self.session?.begin()
    }

    func tagReaderSessionDidBecomeActive(_ session: NFCTagReaderSession) {
        Task { @MainActor in
            self.sessionActive = true
        }
    }

    func tagReaderSession(_ session: NFCTagReaderSession, didInvalidateWithError error: Error) {
        Task { @MainActor in
            self.sessionActive = false
            self.session = nil

            if let readerError = error as? NFCReaderError {
                // ユーザーによるキャンセル・アプリ自身による終了(エラー文言は読取画面に表示済み)は通知しない
                guard readerError.code != .readerSessionInvalidationErrorUserCanceled else {
                    return
                }
                Log.debug("NFCReaderError code: \(readerError.code.rawValue) \(readerError.localizedDescription)")
                self.scanError = ScanError(
                    code: readerError.code,
                    message: readerError.localizedDescription
                )
            } else {
                Log.debug("Unknown Error \(error.localizedDescription)")
                self.scanError = ScanError(
                    code: .readerSessionInvalidationErrorSessionTerminatedUnexpectedly,
                    message: error.localizedDescription
                )
            }
        }
    }

    func tagReaderSession(_ session: NFCTagReaderSession, didDetect tags: [NFCTag]) {
        Log.debug("tagReaderSession(_:didDetect:)")
        Log.debug("Detected tags: \(tags)")

        self.currentTag = tags.first
        guard let tag = tags.first else {
            session.invalidate(errorMessage: String(localized: "scanner.coreNFC.error.noTag"))
            return
        }

        switch tag {
        case .miFare(let miFareTag):
            Log.debug("Detected NFCMiFareTag")
            Log.debug("Identifier: \(miFareTag.identifier.map { String(format: "%02X", $0) }.joined())")
            Log.debug("Family: \(miFareTag.mifareFamily.rawValue)")
            if let historical = miFareTag.historicalBytes {
                Log.debug("Historical: \(historical.map { String(format: "%02X", $0) }.joined(separator: " "))")
            }
        case .iso7816(let tag):
            Log.debug("Detected ISO7816")
            Log.debug("initialSelectedAID:", tag.initialSelectedAID)
            Log.debug(
                "identifier:",
                tag.identifier
                    .map { String(format: "%02X", $0) }
                    .joined()
            )

            if let historicalBytes = tag.historicalBytes {
                Log.debug(
                    "historicalBytes:",
                    historicalBytes
                        .map { String(format: "%02X", $0) }
                        .joined(separator: " ")
                )
            }

            if let applicationData = tag.applicationData {
                Log.debug(
                    "applicationData:",
                    applicationData
                        .map { String(format: "%02X", $0) }
                        .joined(separator: " ")
                )
            }

            Log.debug(
                "proprietaryApplicationDataCoding:",
                tag.proprietaryApplicationDataCoding
            )
        case .feliCa:
            Log.debug("Detected FeliCa")
        case .iso15693:
            Log.debug("Detected ISO15693")
        @unknown default:
            Log.debug("Detected unknown tag")
        }

        session.connect(to: tag) { [weak self] error in
            guard let self else { return }
            Log.debug("connect callback")

            if let error {
                Log.debug("Connect error:", error)
                session.invalidate(errorMessage: error.localizedDescription)
                return
            }

            Log.debug("connect success")

            Task { @MainActor in
                session.alertMessage = String(localized: "scanner.coreNFC.scanning.message")
                await self.switchCard(id: self.scanOption.id, tag, session)
            }
        }
    }
}

extension NFCScannerModel {
    /// CoreNFC での読取成功時の共通処理。結果を公開し、完了メッセージを表示してセッションを終える。
    @MainActor
    func completeScan(_ result: ScanResult, session: NFCTagReaderSession) {
        self.result = result
        session.alertMessage = String(localized: "scanner.coreNFC.scanning.done")
        session.invalidate()
    }
}
