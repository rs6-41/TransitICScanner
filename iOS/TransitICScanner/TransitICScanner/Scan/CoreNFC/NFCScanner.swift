import SwiftUI
public import Combine
@preconcurrency import CoreNFC

/// 読み取りが途中で終了した理由（ユーザーに表示する）
struct ScanError: Equatable {
    var code: NFCReaderError.Code?
    /// ユーザーに表示するメッセージ
    var message: String
}

/// 1枚のカードの読み取りを管理する
///
/// 内蔵リーダー(CoreNFC)の流れ
/// 1. `readerSetup()` で読取セッションを開始（システムの読取画面が表示される）
/// 2. カードを検出したら `tagReaderSession(_:didDetect:)` で接続し、`switchCard(id:_:_:)` へ渡す
/// 3. 各カードの読取処理が `completeScan(_:session:)` を呼ぶと、`result` が更新されてセッションが終わる
/// 4. タイムアウトなどで終了した場合は `scanError` が更新される
///
/// 外部リーダーは `scanWithExternalReader(using:)`（ScannerBranch.swift）から同じ `result` に結果を返す。
/// 各カードの読取処理は CardDefine/ 配下で、この型の extension として実装している。
final class NFCScannerModel: NSObject, ObservableObject, NFCTagReaderSessionDelegate {
    @Published var result: ScanResult?
    @Published var scanError: ScanError?
    @Published var scanOption: ScanOption

    /// 実行中の読取セッション（終了すると nil）
    var session: NFCTagReaderSession?

    init(scanOption: ScanOption) {
        self.scanOption = scanOption
        super.init()
    }

    // MARK: - セッションの開始

    func readerSetup() {
        scanError = nil

        let configuration: NFCTagReaderSession.Configuration
        if let systemCodes = scanOption.felicaSystemCodes {
            configuration = NFCTagReaderSession.Configuration(
                pollingOption: scanOption.pollingOption,
                feliCaSystemCodes: systemCodes
            )
        } else {
            configuration = NFCTagReaderSession.Configuration(
                pollingOption: scanOption.pollingOption
            )
        }

        let session = NFCTagReaderSession(configuration: configuration, delegate: self)
        session.alertMessage = String(
            format: String(localized: "scanner.coreNFC.scan.message"),
            Localize(scanOption.nameShort)
        )
        self.session = session
        session.begin()
    }

    // MARK: - NFCTagReaderSessionDelegate

    func tagReaderSessionDidBecomeActive(_ session: NFCTagReaderSession) {}

    func tagReaderSession(_ session: NFCTagReaderSession, didInvalidateWithError error: Error) {
        Task { @MainActor in
            self.session = nil

            guard let readerError = error as? NFCReaderError else {
                Log.debug("Unknown Error \(error.localizedDescription)")
                self.scanError = ScanError(
                    code: .readerSessionInvalidationErrorSessionTerminatedUnexpectedly,
                    message: error.localizedDescription
                )
                return
            }

            // ユーザーによるキャンセル・アプリ自身による終了（エラー文言は読取画面に表示済み）は通知しない
            guard readerError.code != .readerSessionInvalidationErrorUserCanceled else {
                return
            }

            Log.debug("NFCReaderError code: \(readerError.code.rawValue) \(readerError.localizedDescription)")
            self.scanError = ScanError(
                code: readerError.code,
                message: readerError.localizedDescription
            )
        }
    }

    func tagReaderSession(_ session: NFCTagReaderSession, didDetect tags: [NFCTag]) {
        guard let tag = tags.first else {
            session.invalidate(errorMessage: String(localized: "scanner.coreNFC.error.noTag"))
            return
        }

        Self.logDetectedTag(tag)

        session.connect(to: tag) { [weak self] error in
            guard let self else { return }

            if let error {
                Log.debug("Connect error:", error)
                session.invalidate(errorMessage: error.localizedDescription)
                return
            }

            Task { @MainActor in
                session.alertMessage = String(localized: "scanner.coreNFC.scanning.message")
                await self.switchCard(id: self.scanOption.id, tag, session)
            }
        }
    }

    // MARK: - 読取の完了

    /// CoreNFC での読取成功時の共通処理。結果を公開し、完了メッセージを表示してセッションを終える。
    @MainActor
    func completeScan(_ result: ScanResult, session: NFCTagReaderSession) {
        self.result = result
        session.alertMessage = String(localized: "scanner.coreNFC.scanning.done")
        session.invalidate()
    }

    // MARK: - デバッグ出力

    /// 検出したタグの種類と識別情報を出力する（新しいカードの調査用）
    private static func logDetectedTag(_ tag: NFCTag) {
        func hex(_ data: Data, separator: String = "") -> String {
            data.map { String(format: "%02X", $0) }.joined(separator: separator)
        }

        switch tag {
        case .miFare(let miFareTag):
            Log.debug("Detected MiFare family:", miFareTag.mifareFamily.rawValue, "identifier:", hex(miFareTag.identifier))
            if let historical = miFareTag.historicalBytes {
                Log.debug("historicalBytes:", hex(historical, separator: " "))
            }
        case .iso7816(let isoTag):
            Log.debug("Detected ISO7816 AID:", isoTag.initialSelectedAID, "identifier:", hex(isoTag.identifier))
            if let historical = isoTag.historicalBytes {
                Log.debug("historicalBytes:", hex(historical, separator: " "))
            }
            if let applicationData = isoTag.applicationData {
                Log.debug("applicationData:", hex(applicationData, separator: " "))
            }
        case .feliCa(let felicaTag):
            Log.debug("Detected FeliCa IDm:", hex(felicaTag.currentIDm))
        case .iso15693:
            Log.debug("Detected ISO15693")
        @unknown default:
            Log.debug("Detected unknown tag")
        }
    }
}
