import SwiftUI

struct WatchHistoryView: View {
    @State private var pedometer = WatchPedometerService.shared

    var body: some View {
        List {
            if pedometer.weekly.isEmpty {
                Text("No data yet")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(pedometer.weekly.reversed()) { day in
                    HStack {
                        Text(label(for: day.date))
                            .font(.footnote.weight(.semibold))
                        Spacer()
                        Text("\(day.steps)")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(.orange)
                    }
                }
            }
        }
        .onAppear {
            pedometer.loadWeekly()
        }
        .navigationTitle("7 Days")
    }

    private func label(for date: Date) -> String {
        if Calendar.current.isDateInToday(date) { return "Today" }
        if Calendar.current.isDateInYesterday(date) { return "Yesterday" }
        let f = DateFormatter()
        f.dateFormat = "EEE"
        return f.string(from: date)
    }
}
