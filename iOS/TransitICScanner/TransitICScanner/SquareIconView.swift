import SwiftUI

struct SquareIcon: View {
    var text: LocalizedStringKey?
    var subText: LocalizedStringKey?
    @State var systemImage: String
    @State var color: Color
    var body: some View {
        HStack {
            ZStack {
                Image(systemName: "app.fill")
                    .font(.largeTitle)
                    .foregroundStyle(color)
                Image(systemName: systemImage)
                    .foregroundStyle(.white)
                    .bold()
            }
            VStack(alignment: .leading) {
                if let text {
                    Text(text)
                }
                if let subText {
                    Text(subText)
                        .font(.caption)
                        .foregroundStyle(Color.gray)
                }
            }
        }
    }
}

#Preview {
    SquareIcon(text: "Text", subText: "subText", systemImage: "ladybug.fill", color: Color.red)
}
