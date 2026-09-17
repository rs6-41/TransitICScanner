import SwiftUI

struct SquareIcon: View {
    @State var text: LocalizedStringKey
    @State var systemImage: String
    @State var color:Color
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
            Text(text)
        }
    }
}

#Preview {
    SquareIcon(text: "Text",systemImage: "ladybug.fill",color: Color.red)
}
