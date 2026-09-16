import SwiftUI

struct CardImage:View {
    @State var name:String
    var body: some View {
        ZStack {
            Image(name)
                .resizable()
                .scaledToFit()
                .frame(width:45,height:45)
                .padding(5)
                .shadow(color: .black.opacity(0.3), radius: 2)
        }
    }
}

struct CardDesigin:Hashable,Identifiable {
    let id = UUID()
    var type:ConverterType
    var name:String
    var imageName:String
    var isDefault:Bool
}

struct CardDesiginResult:Hashable {
    var imageName:String
}

func getCardImageName(type: ConverterType, name: String) -> CardDesiginResult? {
    if let card = cardDesignList.first(where: {
        $0.type == type && $0.name == name
    }) {
        return CardDesiginResult(imageName:card.imageName)
    }
    
    return CardDesiginResult(
        imageName:cardDesignList.first(where: {
        $0.type == type && $0.isDefault
        })?.imageName ?? "")
}
