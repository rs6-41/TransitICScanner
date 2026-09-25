import WidgetKit
import SwiftUI

@main
struct BalanceWidget: WidgetBundle {
    var body: some Widget {
        SmallBalanceWidget()
        ListBalanceWidget()
    }
}
