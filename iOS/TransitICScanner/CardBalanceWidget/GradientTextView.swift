import SwiftUI

struct GradientTextView<Content: View>: View {
    let gradient: LinearGradient
    let content: Content

    init(
        gradient: LinearGradient,
        @ViewBuilder content: () -> Content
    ) {
        self.gradient = gradient
        self.content = content()
    }

    var body: some View {
        content
            .foregroundStyle(.clear)
            .overlay {
                gradient
                    .mask {
                        content
                    }
            }
    }
}
