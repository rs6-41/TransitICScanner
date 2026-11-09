import UIKit
import SwiftUI
@preconcurrency import CoreNFC
public import Combine

struct ScanError {
    var code: NFCReaderError.Code?
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
        DispatchQueue.main.async {
            self.sessionActive = true
        }
    }

    func tagReaderSession(_ session: NFCTagReaderSession, didInvalidateWithError error: Error) {
        DispatchQueue.main.async {
            self.sessionActive = false
            self.session = nil

            if let readerError = error as? NFCReaderError {
                if readerError.code.rawValue != 200 {
                    let error = "NFCReaderError\ncode: \(readerError.code.rawValue)\n\(readerError.localizedDescription)"
                    print(error)
                    self.scanError = ScanError(code: readerError.code, message: error)
                }
            } else {
                let error = "Unknown Error\n\(error.localizedDescription)"
                print(error)
                self.scanError = ScanError(
                    code: .readerSessionInvalidationErrorSessionTerminatedUnexpectedly,
                    message: error
                )
            }
        }
    }

    func tagReaderSession(_ session: NFCTagReaderSession, didDetect tags: [NFCTag]) {
        print("tagReaderSession(_:didDetect:)")
        print("Detected tags: \(tags)")

        self.currentTag = tags.first
        guard let tag = tags.first else {
            session.invalidate(errorMessage: "No tag detected")
            return
        }

        switch tag {
        case .miFare(let miFareTag):
            print("Detected NFCMiFareTag")
            print("Identifier: \(miFareTag.identifier.map { String(format: "%02X", $0) }.joined())")
            print("Family: \(miFareTag.mifareFamily.rawValue)")
            if let historical = miFareTag.historicalBytes {
                print("Historical: \(historical.map { String(format: "%02X", $0) }.joined(separator: " "))")
            }
        case .iso7816(let tag):
            print("Detected ISO7816")
            print("initialSelectedAID:", tag.initialSelectedAID)
            print(
                "identifier:",
                tag.identifier
                    .map { String(format: "%02X", $0) }
                    .joined()
            )

            if let historicalBytes = tag.historicalBytes {
                print(
                    "historicalBytes:",
                    historicalBytes
                        .map { String(format: "%02X", $0) }
                        .joined(separator: " ")
                )
            }

            if let applicationData = tag.applicationData {
                print(
                    "applicationData:",
                    applicationData
                        .map { String(format: "%02X", $0) }
                        .joined(separator: " ")
                )
            }

            print(
                "proprietaryApplicationDataCoding:",
                tag.proprietaryApplicationDataCoding
            )
        case .feliCa:
            print("Detected FeliCa")
        case .iso15693:
            print("Detected ISO15693")
        @unknown default:
            print("Detected unknown tag")
        }

        session.connect(to: tag) { [weak self] error in
            guard let self else { return }
            print("connect callback")

            if let error {
                print("Connect error:", error)
                DispatchQueue.main.async {
                    self.session?.invalidate(errorMessage: error.localizedDescription)
                }
                return
            }

            print("connect success")

            DispatchQueue.main.async {
                Task { @MainActor in
                    self.session?.alertMessage = String(localized: "scanner.coreNFC.scanning.message")
                    await self.switchCard(id: self.scanOption.id, tag, session)
                }
            }
        }
    }
}
