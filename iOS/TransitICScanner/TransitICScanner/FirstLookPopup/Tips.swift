import SwiftUI
import TipKit

// TipView(WidgetTip())
struct WidgetTip: Tip {
    var title: Text {
        Text("tip.widget.title")
    }

    var message: Text? {
        Text("tip.widget.message")
    }

    var image: Image? {
        Image(systemName: "widget.large.badge.plus")
    }
}
