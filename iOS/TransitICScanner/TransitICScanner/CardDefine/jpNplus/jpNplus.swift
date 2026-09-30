import SwiftUI
import Foundation
import CoreNFC

//MARK: エヌタスカード
let jpNplus = CardInfo(
    logo:"jpNplus",
    name:"cardList.jpNplus",
    sortName:"cardList.jpNplus.sortName",
    area: .jp,
    countryCode: ["jp"],
    prefectures: ["Nagasaki"],
    regionOption: nil,
    description:"cardList.jpNplus.description",
    scand_description: "jpIC.scand.description",
    searchWords: ["locate.prefecture.Nagasaki","ながさき","ナガサキ","nagasaki","Tカード","県営バス"],
    scanOption:ScanOption(
        name:"jpNplus",
        nameShort:"jpNplus.short",
        scanType: .nfc,
        pollingOption:[.iso18092],
        felicaSystemCodes:["93EC"],
        historyCount:20,
        currencyType:.jpy,
        converter:.jpNplus,
        scrapingView: nil
    ),
    infomation: nil,
    sample:
        ResultSample(
            balance:2300.0,
            idm:"01100A9183740114",
            type:"",
            history: [
            //TODO: 駅コード例を調べる（暫定的に全て1111）
            // 1: 新規発行 残高1500円 2025/19/23 19:21
            ResultHistory(processType: 0x50,date: sampleDay2,balance: 1500,amount: nil,lineIn: 0x11,stationIn: 0x11,lineOut: 0x11,stationOut: 0x11,transactionId: 151),
            // 2: チャージ 残高2500円 2025/19/23 19:21
            ResultHistory(processType: 0x50,date: sampleDay2,balance: 2500,amount: nil,lineIn: 0x11,stationIn: 0x11,lineOut: 0x11,stationOut: 0x11,transactionId: 152),
            // 3: バス 残高2300円 2026/1/3 12:58
            ResultHistory(processType: 0x40,date: sampleDay3,balance: 2300,amount: nil,lineIn: 0x11,stationIn: 0x11,lineOut: 0x11,stationOut: 0x11,transactionId: 153),
            ]
        )
)

//カードの読み取り処理
extension NFCScannerModel {
    
    func jpNplus_scan(_ tag: NFCTag, _ session: NFCTagReaderSession) {
        guard case let .feliCa(felicaTag) = tag else {
            session.invalidate(errorMessage: String(localized:"scanner.coreNFC.error.notfeliCa"))
            return
        }

        Task {
            guard let balance = await jpNplus_balance(felicaTag) else { return }

            let history = await jpNplus_history(
                felicaTag,
                count: self.scanOption.historyCount
            )

            let info = await jpNplus_info(felicaTag)

            await MainActor.run {
                self.result = Result(
                    balance: Double(balance),
                    isHistory: true,
                    history: history,
                    info: info,
                    converter: jpNplus.scanOption.converter,
                    isLastHide:true,
                    description: jpNplus.scand_description,
                    savedAt: Date.now
                )

                self.session?.alertMessage =
                String(localized:"scanner.coreNFC.scanning.done")

                session.invalidate()
            }
        }
    }
    
    //MARK: 残高を取得する
    func jpNplus_balance(_ felicaTag: NFCFeliCaTag) async -> Int? {
        await withCheckedContinuation { continuation in
            let serviceCode = Data([0x40, 0x8B].reversed())
            let blockList = [Data([0x80, 0x01])]

            felicaTag.readWithoutEncryption(serviceCodeList: [serviceCode], blockList: blockList) { [weak self] status1, status2, blockData, error in
                if let error = error {
                    print("Read error: \(error)")
                    self?.session?.invalidate(errorMessage: error.localizedDescription)
                    continuation.resume(returning: nil)
                    return
                }

                guard status1 == 0x00, status2 == 0x00 else {
                    self?.session?.invalidate(errorMessage: String(localized:"scanner.coreNFC.scanning.error.statusFlag,s1:\(status1), s2:\(status2)"))
                    continuation.resume(returning: nil)
                    return
                }
                

                guard let data = blockData.first else {
                    continuation.resume(returning: nil)
                    return
                }
                
                print("エヌタス：\(data)")
                
                let balance = data.toIntReversed(5, 6)
                continuation.resume(returning: Int(balance))
            }
        }
    }
    
    //MARK: 履歴を取得する
    func jpNplus_history(_ felicaTag: NFCFeliCaTag, count: Int = 20) async -> [ResultHistory]? {
        await withCheckedContinuation { continuation in
            let serviceCode = Data([0x80, 0xCF].reversed())
            let blockCount = min(max(count, 1), 20)
            let blocksPerRead = 10

            let blockLists = stride(from: 0, to: blockCount, by: blocksPerRead).map { start in
                let end = min(start + blocksPerRead, blockCount)
                return (start..<end).map {
                    Data([0x80, UInt8($0)])
                }
            }

            func readBlocks(_ blockList: [Data], completion: @escaping ([Data]?) -> Void) {
                felicaTag.readWithoutEncryption(
                    serviceCodeList: [serviceCode],
                    blockList: blockList
                ) { status1, status2, blockData, error in
                    print("History status:", status1, status2, "count:", blockData.count)
                    guard error == nil,
                          status1 == 0x00,
                          status2 == 0x00 else {
                        completion(nil)
                        return
                    }

                    completion(blockData)
                }
            }

            func readNext(_ index: Int, result: [Data]) {
                if index >= blockLists.count {
                    for (index, data) in result.enumerated() {
                        let bytes = [UInt8](data)
                        let hex = bytes.map { String(format: "%02X", $0) }.joined(separator: " ")
                        print(String(format: "[%02d] %@", index, hex))
                    }
                    let history = result.compactMap { data -> ResultHistory? in
                        let bytes = [UInt8](data)
                        
                        //異常・空データを弾く
                        guard bytes.count == 16 else {
                            return nil
                        }
                        if bytes.allSatisfy({ $0 == 0 }) {
                            return nil
                        }
                        print("bytes:\(bytes)")

                        //解析
                        let rawDate = UInt16(bytes[0]) << 8 | UInt16(bytes[1])
                        let balance = Double(UInt16(bytes[14]) << 8 | UInt16(bytes[15]))
                        let date = DateComponents(
                            year: Int((rawDate >> 9) & 0x7F) + 2000,
                            month: Int((rawDate >> 5) & 0x0F),
                            day: Int(rawDate & 0x1F),
                            hour: Int(bytes[2]),
                            minute: Int(bytes[3]),
                            second: Int(bytes[4])
                        )

                        return ResultHistory(
                            processType: bytes[13],
                            date: date,
                            balance: balance,
                            amount: nil,
                            lineIn:0,
                            stationIn: 0,
                            lineOut: 0,
                            stationOut: 0,
                            transactionId: 0
                        )
                    }

                    continuation.resume(returning: history)
                    return
                }

                readBlocks(blockLists[index]) { blockData in
                    guard let blockData else {
                        continuation.resume(returning: nil)
                        return
                    }

                    readNext(index + 1, result: result + blockData)
                }
            }

            readNext(0, result: [])
        }
    }

    //MARK: カード情報を取得する
    func jpNplus_info(_ felicaTag: NFCFeliCaTag) async -> ResultCardInfo? {

        let idm = felicaTag.currentIDm
            .map { String(format: "%02X", $0) }
            .joined()

        return ResultCardInfo(
            idm: idm,
            name: jpNplus.name,
            nameShort: jpNplus.scanOption.nameShort,
            currencyType: jpNplus.scanOption.currencyType,
            type: "",
            serial: nil,
            version: nil,
            validDate: nil,
            issueInfo: issueInfo(region:jpDoCard.area.rawValue,area:"locate.prefecture.Nagasaki",issuer:"issue.jp.nagasaki.issuer.ntasu")
        )
    }
    
    func jpNplus_read(
        _ tag:NFCFeliCaTag,
        service:Data,
        blocks:[UInt8]
    ) async -> [Data]? {

        await withCheckedContinuation { continuation in
            let blockList = blocks.map {
                Data([0x80,$0])
            }
            tag.readWithoutEncryption(
                serviceCodeList:[service],
                blockList:blockList
            ){ status1,status2,data,error in


                guard error == nil,
                      status1 == 0,
                      status2 == 0 else {

                    continuation.resume(returning:nil)
                    return
                }


                continuation.resume(
                    returning:data
                )
            }
        }
    }

    func jpNplus_readMultiple(
        _ tag: NFCFeliCaTag,
        service: Data,
        count: Int
    ) async -> [Data]? {

        await withCheckedContinuation { continuation in

            let blockList = (0..<count).map {
                Data([0x80, UInt8($0)])
            }

            tag.readWithoutEncryption(
                serviceCodeList: [service],
                blockList: blockList
            ) { status1, status2, data, error in

                guard error == nil,
                      status1 == 0x00,
                      status2 == 0x00 else {
                    continuation.resume(returning: nil)
                    return
                }

                continuation.resume(returning: data)
            }
        }
    }
}
