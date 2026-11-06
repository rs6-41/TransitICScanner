import SwiftUI

struct ContentView: View {

    var body: some View {
        NavigationStack {
            SavedListView()
                .navigationTitle(LocalizedStringKey("appName.short"))
                .toolbarForegroundStyle(.blue, for: .navigationBar)
        }
    }
}

#Preview {
    ContentView()
}
