import SwiftUI

// MARK: - 未選択時の表示

/// 分割表示の詳細列などで、何も選ばれていないときに表示する案内
struct EmptyViewSideBar: View {
    var title: String
    var icon: String
    var description: String?

    var body: some View {
        ContentUnavailableView {
            Label {
                Text(LocalizedStringKey(title))
                    .font(.title2)
            } icon: {
                Image(systemName: icon)
                    .imageScale(.large)
            }
        } description: {
            if let description {
                Text(LocalizedStringKey(description))
                    .font(.body)
            }
        }
    }
}

// MARK: - iPhone Duo のヒンジ

/// 折りたたみ端末(iPhone Duo)が開いているかを `value` に反映する
struct IPhoneDuoHingeModifier: ViewModifier {
    @Binding var value: Bool

    func body(content: Content) -> some View {
        if #available(iOS 27.1, *) {
            content
                .onHingeChange { _, duo in
                    guard let hinge = duo.hinge else {
                        value = false
                        return
                    }
                    value = hinge.status == .partiallyOpen || hinge.status == .fullyOpen
                }
        } else {
            content
        }
    }
}

extension View {
    func iPhoneDuoHinge(value: Binding<Bool>) -> some View {
        self.modifier(IPhoneDuoHingeModifier(value: value))
    }
}
