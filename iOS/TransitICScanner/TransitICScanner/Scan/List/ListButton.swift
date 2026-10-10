import SwiftUI
import CoreNFC

struct CardListRow: View {
    let item: CardInfo
    @State var isFormDisplay = false
    @EnvironmentObject var debug: DebugModel
    @Binding var deleteAds: Bool
    
    var body: some View {
        VStack(alignment: .leading) {
            switch item.scanOption.scanType {
            case .nfc:
                ScanningButton(item: item, deleteAds: $deleteAds)
                
            case .scraping:
                if let view = item.scanOption.scrapingView {
                    Button(action: {
                        isFormDisplay = true
                    }) {
                        ListButtonInner(item: item)
                    }
                    .sheet(isPresented: $isFormDisplay) {
                        view()
                    }
                }
            case .external:
                //TODO: 外部リーダー専用ボタンを実装
                ListButtonInner(item: item)
            }
            
            if debug.isDisplay {
                CardListItemDebugView(item: item)
            }
        }
    }
}

struct ListButtonInner: View {
    let item: CardInfo
    @State var isCardInfoView = false
    
    var body: some View {
        HStack {
            CardImage(name: item.logo)
            
            VStack(alignment: .leading) {
                HStack(spacing: 3) {
                    switch item.scanOption.scanType {
                    case .nfc:
                        Image(systemName: "wave.3.right")
                            .imageScale(.small)
                    case .scraping:
                        Image(systemName: "creditcard.and.numbers")
                            .imageScale(.small)
                    case .external:
                        Image(systemName: "wave.3.right")
                            .imageScale(.small)
                    }
                    Text(LocalizedStringKey(item.name))
                        .fontWeight(.semibold)
                }
                
                VStack(alignment:.leading, spacing: 0) {
                    HStack(spacing: 2) {
                        Text(LocalizedStringKey(item.area.rawValue))
                            .fontWeight(.semibold)
                        if let prefectures = item.prefectures {
                            ForEach(prefectures, id: \.self) { prefecture in
                                Text(LocalizedStringKey("locate.prefecture." + prefecture))
                                if prefecture != prefectures.last {
                                    Text(String(", "))
                                }
                            }
                        }
                    }
                    
                    if let description = item.description {
                        Text(LocalizedStringKey(description))
                    }
                }
                .foregroundStyle(Color.gray)
                .font(.caption)
            }
            
            Spacer()
            
            if item.infomation != nil {
                Button(action: {
                    isCardInfoView.toggle()
                }) {
                    Image(systemName: "questionmark.circle")
                        .imageScale(.large)
                }
                .foregroundStyle(Color.accentColor)
                .sheet(isPresented: $isCardInfoView) {
                    NavigationStack {
                        ScrollView {
                            item.infomation
                        }
                    }
                }
            }
        }
        
        .foregroundStyle(Color.primary)
    }
}

/// NFCスキャンボタン
struct ScanningButton: View {
    let item: CardInfo
    @StateObject private var model: NFCScannerModel
    @State private var path = NavigationPath()
    @State var nfcError = false
    @Binding var deleteAds:Bool

    init(item: CardInfo,deleteAds:Binding<Bool>) {
        self.item = item
        _model = StateObject(wrappedValue: NFCScannerModel(scanOption: item.scanOption))
        self._deleteAds = deleteAds
    }
    var body: some View {
        Button(action: {
            if checkDevice() {
                model.readerSetup()
            } else {
                nfcError = true
            }
        }) {
            ListButtonInner(item: item)
        }
        .navigationDestination(item: $model.result) { result in
            ResultView(result: result, scandata: true, saveListID: .constant(UUID()), deleteAds: $deleteAds)
        }
        .alert(LocalizedStringKey("error"), isPresented: $nfcError) {
            
        } message: {
            Text(LocalizedStringKey("cardList.error.nfc"))
        }
    }
    
    // デバイスのNFC有効性チェック
    func checkDevice() -> Bool {
        return NFCTagReaderSession.readingAvailable
    }
}
