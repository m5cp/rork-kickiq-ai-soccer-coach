import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            WatchTodayView()
                .tag(0)
            WatchTimerView()
                .tag(1)
            WatchHistoryView()
                .tag(2)
        }
        .tabViewStyle(.verticalPage)
    }
}
