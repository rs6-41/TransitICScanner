import Foundation
import CoreNFC
import SwiftUI

//MARK: Octopus
let hkOctopus = CardInfo(
    logo:"hkOctopus",
    name:"cardList.hkOctopus",
    sortName:"cardList.hkOctopus.sortName",
    area: .hk,
    countryCode: ["hk"],
    prefectures: nil,
    description:"cardList.hkOctopus.description",
    scand_description: "",
    searchWords: ["badatong","baat3daat6tung1","baatdaattung"],
    scanOption: ScanOption(
        name:"hkOctopus",
        nameShort:"hkOctopus.short",
        scanType: .nfc,
        pollingOption:[.iso18092],
        felicaSystemCodes:["8008"],
        historyCount:0,
        currencyType:.hkd,
        converter:.hkOctopus,
        scrapingView: nil
    ),
    infomation: nil,
    sample:
        ResultSample(
            balance:300.0,
            idm:"012467574734EB05",
            type:"",
            history: []
        )
    
)

@MainActor
extension NFCScannerModel {
    func hkOctopus_scan(_ tag: NFCTag,_ session: NFCTagReaderSession) async{
        guard case let .feliCa(felicaTag)=tag else{
            session.invalidate(errorMessage:"Not FeliCa"); return
        }
        let info = await hkOctopus_info(felicaTag)
        let balance = await hkOctopus_balance(felicaTag) ?? 0.0

        self.result = Result(
            balance: Double(balance),
            isHistory: false,
            history: nil,
            info: info,
            converter:hkOctopus.scanOption.converter,
            isLastHide: false,
            description: hkOctopus.scand_description,
            savedAt: Date.now
        )

        session.alertMessage = String(localized:"scanner.coreNFC.scanning.done")
        session.invalidate()
    }
    func hkOctopus_balance(_ tag:NFCFeliCaTag) async -> Double?{
        await withCheckedContinuation{c in
            tag.readWithoutEncryption(
                serviceCodeList: [Data([0x17, 0x01])],
                blockList: [Data([0x80, 0x00])]
            ) { status1, status2, data, error in

                if let error {
                    print(error)
                }

                guard error == nil,
                      status1 == 0,
                      status2 == 0,
                      let d = data.first
                else {
                    c.resume(returning: nil)
                    return
                }

                print(d.map { String(format: "%02X", $0) }.joined(separator: " "))

                let b = [UInt8](d)

                let raw =
                    Int(UInt32(b[0]) << 24) |
                    Int(UInt32(b[1]) << 16) |
                    Int(UInt32(b[2]) << 8) |
                    Int(UInt32(b[3]))

                // Octopus stores the value in 0.1 HKD units and includes the HK$50 deposit.
                let displayBalance = Double(max(raw - 500, 0)) / 10.0

                c.resume(returning: displayBalance)
            }
        }
    }
    func hkOctopus_info(_ tag: NFCFeliCaTag) async -> ResultCardInfo? {

        let idm = tag.currentIDm
            .map { String(format: "%02X", $0) }
            .joined()

        print("IDm:", idm)

        return ResultCardInfo(
            idm: idm,
            name: hkOctopus.name,
            nameShort: hkOctopus.scanOption.nameShort,
            currencyType: hkOctopus.scanOption.currencyType,
            type: "",
            serial: nil,
            version: nil,
            validDate: nil
        )
    }
}
