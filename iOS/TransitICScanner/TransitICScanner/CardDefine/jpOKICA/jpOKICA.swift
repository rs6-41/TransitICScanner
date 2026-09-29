import SwiftUI
import Foundation
import CoreNFC

//MARK: OKICA
let jpOKICA = CardInfo(
    logo:"jpOKICA",
    name:"cardList.jpOKICA",
    sortName:"cardList.jpOKICA.sortName",
    area: .jp,
    countryCode: ["jp"],
    prefectures: ["Okinawa"],
    regionOption: nil,
    description:"cardList.jpOKICA.description",
    scand_description: "jpOKICA.scand.description",
    searchWords: ["locate.prefecture.Okinawa","card.jpOKICA","cardList.area.jp","おきなわ"],
    scanOption:ScanOption(
        name:"jpOKICA",
        nameShort:"jpOKICA.short",
        scanType: .nfc,
        pollingOption:[.iso18092],
        felicaSystemCodes:["8FC1"],
        historyCount:20,
        currencyType:.jpy,
        converter:.jpIC,
        scrapingView: nil
    ),
    infomation: nil,
    sample:
        ResultSample(
            balance:560.0,
            idm:"011203394745678",
            type:"",
            history: [
            // 1: みどりの窓口 新規発行 2025/12/29 10:32
            ResultHistory(processType: 0x19,date: sampleDay1,balance: 1000,amount: nil,lineIn: 0x01,stationIn: 0x00,lineOut: 0x00,stationOut: 0x00,transactionId: 150),
            // 2: 新宿 チャージ 残高1500円 2025/19/23 19:21
            ResultHistory(processType: 0x02,date: sampleDay2,balance: 1500,amount: nil,lineIn: 0x03,stationIn: 0x0D,lineOut: 0x00,stationOut: 0x00,transactionId: 151),
            // 3: 新宿→渋谷 自動改札 残高1099円 2026/1/3 12:58
            ResultHistory(processType: 0x16,date: sampleDay3,balance: 560,amount: nil,lineIn: 0x03,stationIn: 0x0D,lineOut: 0x25,stationOut: 0x07,transactionId: 152),
            ]
        )
)
