import SwiftUI

struct TrainingCalendarView: View {
    let storage: StorageService
    @State private var selectedDate: Date?
    @State private var displayedMonth: Date = .now
    @State private var showDayDetail = false
    @Environment(\.dismiss) private var dismiss

    private let calendar = Calendar.current
    private let daysOfWeek = ["S", "M", "T", "W", "T", "F", "S"]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: KickIQAICoachTheme.Spacing.lg) {
                    monthNavigator
                    calendarGrid
                    legendRow
                    if let date = selectedDate {
                        dayDetailInline(for: date)
                    }
                }
                .padding(.horizontal, KickIQAICoachTheme.Spacing.md)
                .padding(.bottom, KickIQAICoachTheme.Spacing.xl)
            }
            .scrollIndicators(.hidden)
            .background(KickIQAICoachTheme.background.ignoresSafeArea())
            .navigationTitle("Training Calendar")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                        .font(.body.weight(.bold))
                        .foregroundStyle(KickIQAICoachTheme.accent)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        withAnimation(.spring(response: 0.3)) {
                            displayedMonth = .now
                            selectedDate = .now
                        }
                    } label: {
                        Text("Today")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(KickIQAICoachTheme.accent)
                    }
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .presentationBackground(.background)
    }

    private var monthNavigator: some View {
        HStack {
            Button {
                withAnimation(.spring(response: 0.3)) {
                    displayedMonth = calendar.date(byAdding: .month, value: -1, to: displayedMonth)!
                }
            } label: {
                Image(systemName: "chevron.left")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(KickIQAICoachTheme.accent)
                    .frame(width: 44, height: 44)
            }

            Spacer()

            Text(displayedMonth, format: .dateTime.month(.wide).year())
                .font(.title3.weight(.bold))
                .foregroundStyle(KickIQAICoachTheme.textPrimary)

            Spacer()

            Button {
                withAnimation(.spring(response: 0.3)) {
                    displayedMonth = calendar.date(byAdding: .month, value: 1, to: displayedMonth)!
                }
            } label: {
                Image(systemName: "chevron.right")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(KickIQAICoachTheme.accent)
                    .frame(width: 44, height: 44)
            }
        }
    }

    private var calendarGrid: some View {
        let days = daysInMonth()
        let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)

        return VStack(spacing: KickIQAICoachTheme.Spacing.sm) {
            LazyVGrid(columns: columns, spacing: 4) {
                ForEach(daysOfWeek, id: \.self) { day in
                    Text(day)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(KickIQAICoachTheme.textSecondary)
                        .frame(maxWidth: .infinity)
                }
            }

            LazyVGrid(columns: columns, spacing: 6) {
                ForEach(days, id: \.self) { date in
                    if let date {
                        calendarDayCell(date)
                    } else {
                        Color.clear.frame(height: 44)
                    }
                }
            }
        }
        .padding(KickIQAICoachTheme.Spacing.md)
        .background(KickIQAICoachTheme.card, in: .rect(cornerRadius: KickIQAICoachTheme.Radius.xl))
    }

    private func calendarDayCell(_ date: Date) -> some View {
        let isToday = calendar.isDateInToday(date)
        let isSelected = selectedDate.map { calendar.isDate($0, inSameDayAs: date) } ?? false
        let hasTraining = storage.hasSessionOnDate(date) || !storage.drillCompletionsForDate(date).isEmpty
        let isFuture = date > .now && !isToday
        let hasAnnotation = storage.annotationForDate(date) != nil

        return Button {
            withAnimation(.spring(response: 0.25)) {
                selectedDate = date
            }
        } label: {
            VStack(spacing: 2) {
                Text("\(calendar.component(.day, from: date))")
                    .font(.system(size: 14, weight: isToday ? .black : isSelected ? .bold : .medium))
                    .foregroundStyle(
                        isSelected ? KickIQAICoachTheme.onAccent :
                        isToday ? KickIQAICoachTheme.accent :
                        isFuture ? KickIQAICoachTheme.textSecondary.opacity(0.4) :
                        KickIQAICoachTheme.textPrimary
                    )

                HStack(spacing: 2) {
                    if hasTraining {
                        Circle()
                            .fill(KickIQAICoachTheme.accent)
                            .frame(width: 5, height: 5)
                    }
                    if hasAnnotation {
                        Circle()
                            .fill(.orange)
                            .frame(width: 5, height: 5)
                    }
                }
                .frame(height: 5)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .background(
                isSelected ? KickIQAICoachTheme.accent :
                isToday ? KickIQAICoachTheme.accent.opacity(0.12) :
                Color.clear,
                in: .rect(cornerRadius: 10)
            )
        }
        .sensoryFeedback(.selection, trigger: selectedDate)
    }

    private var legendRow: some View {
        HStack(spacing: KickIQAICoachTheme.Spacing.md) {
            legendItem(color: KickIQAICoachTheme.accent, label: "Training Day")
            legendItem(color: .orange, label: "Has Notes")
            Spacer()
        }
        .padding(.horizontal, KickIQAICoachTheme.Spacing.sm)
    }

    private func legendItem(color: Color, label: String) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 6, height: 6)
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(KickIQAICoachTheme.textSecondary)
        }
    }

    @ViewBuilder
    private func dayDetailInline(for date: Date) -> some View {
        let completions = storage.drillCompletionsForDate(date)
        let annotation = storage.annotationForDate(date)
        let isToday = calendar.isDateInToday(date)

        VStack(alignment: .leading, spacing: KickIQAICoachTheme.Spacing.md) {
            HStack {
                Text(date, format: .dateTime.weekday(.wide).month(.abbreviated).day())
                    .font(.headline.weight(.bold))
                    .foregroundStyle(KickIQAICoachTheme.textPrimary)
                Spacer()
                if isToday {
                    Text("Today")
                        .font(.caption.weight(.black))
                        .foregroundStyle(KickIQAICoachTheme.accent)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(KickIQAICoachTheme.accent.opacity(0.12), in: Capsule())
                }
            }

            if completions.isEmpty && annotation == nil {
                VStack(spacing: KickIQAICoachTheme.Spacing.sm) {
                    Image(systemName: date > .now ? "calendar.badge.clock" : "moon.zzz.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(KickIQAICoachTheme.textSecondary.opacity(0.4))
                    Text(date > .now ? "No training scheduled" : "No training recorded")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(KickIQAICoachTheme.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, KickIQAICoachTheme.Spacing.md)
            } else {
                if !completions.isEmpty {
                    VStack(alignment: .leading, spacing: KickIQAICoachTheme.Spacing.xs) {
                        Text("COMPLETED")
                            .font(.system(size: 10, weight: .bold))
                            .tracking(1)
                            .foregroundStyle(KickIQAICoachTheme.accent)

                        ForEach(completions) { completion in
                            HStack(spacing: KickIQAICoachTheme.Spacing.sm) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 12))
                                    .foregroundStyle(.green)
                                Text(completion.drillName)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(KickIQAICoachTheme.textPrimary)
                                    .lineLimit(1)
                                Spacer()
                                Text("\(completion.durationSeconds / 60)m")
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(KickIQAICoachTheme.textSecondary)
                            }
                        }
                    }
                }

                if let annotation {
                    if !annotation.notes.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("NOTES")
                                .font(.system(size: 10, weight: .bold))
                                .tracking(1)
                                .foregroundStyle(.orange)
                            Text(annotation.notes)
                                .font(.subheadline)
                                .foregroundStyle(KickIQAICoachTheme.textPrimary.opacity(0.85))
                                .lineSpacing(3)
                        }
                    }

                    HStack(spacing: KickIQAICoachTheme.Spacing.md) {
                        if let duration = annotation.duration {
                            miniStat(icon: "clock.fill", value: "\(duration)m", label: "Duration")
                        }
                        if let effort = annotation.effort {
                            miniStat(icon: "flame.fill", value: "\(effort)/10", label: "Effort")
                        }
                    }
                }
            }

            Button {
                selectedDate = date
                showDayDetail = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "square.and.pencil")
                        .font(.system(size: 12))
                    Text(annotation != nil ? "Edit Notes" : "Add Notes")
                        .font(.caption.weight(.bold))
                }
                .foregroundStyle(KickIQAICoachTheme.accent)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(KickIQAICoachTheme.accent.opacity(0.1), in: .rect(cornerRadius: KickIQAICoachTheme.Radius.sm))
            }
        }
        .padding(KickIQAICoachTheme.Spacing.md)
        .background(KickIQAICoachTheme.card, in: .rect(cornerRadius: KickIQAICoachTheme.Radius.xl))
        .sheet(isPresented: $showDayDetail) {
            if let date = selectedDate {
                DayAnnotationSheet(storage: storage, date: date)
            }
        }
    }

    private func miniStat(icon: String, value: String, label: String) -> some View {
        VStack(spacing: 2) {
            HStack(spacing: 3) {
                Image(systemName: icon)
                    .font(.system(size: 10))
                    .foregroundStyle(KickIQAICoachTheme.accent)
                Text(value)
                    .font(.caption.weight(.black))
                    .foregroundStyle(KickIQAICoachTheme.textPrimary)
            }
            Text(label)
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(KickIQAICoachTheme.textSecondary)
        }
    }

    private func daysInMonth() -> [Date?] {
        let components = calendar.dateComponents([.year, .month], from: displayedMonth)
        guard let firstDay = calendar.date(from: components),
              let range = calendar.range(of: .day, in: .month, for: firstDay) else {
            return []
        }

        let firstWeekday = calendar.component(.weekday, from: firstDay)
        let leadingEmpty = firstWeekday - 1

        var days: [Date?] = Array(repeating: nil, count: leadingEmpty)

        for day in range {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: firstDay) {
                days.append(date)
            }
        }

        return days
    }
}

struct DayAnnotationSheet: View {
    let storage: StorageService
    let date: Date
    @State private var notes: String = ""
    @State private var duration: String = ""
    @State private var effort: Int = 5
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: KickIQAICoachTheme.Spacing.lg) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(date, format: .dateTime.weekday(.wide).month(.abbreviated).day().year())
                            .font(.title3.weight(.bold))
                            .foregroundStyle(KickIQAICoachTheme.textPrimary)
                        Text("Record your training details")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(KickIQAICoachTheme.textSecondary)
                    }

                    VStack(alignment: .leading, spacing: KickIQAICoachTheme.Spacing.sm) {
                        Text("NOTES")
                            .font(.caption.weight(.bold))
                            .tracking(1)
                            .foregroundStyle(KickIQAICoachTheme.accent)

                        TextEditor(text: $notes)
                            .frame(minHeight: 100)
                            .padding(KickIQAICoachTheme.Spacing.sm)
                            .background(Color(.tertiarySystemGroupedBackground), in: .rect(cornerRadius: KickIQAICoachTheme.Radius.md))
                            .font(.body)
                    }

                    VStack(alignment: .leading, spacing: KickIQAICoachTheme.Spacing.sm) {
                        Text("DURATION (MINUTES)")
                            .font(.caption.weight(.bold))
                            .tracking(1)
                            .foregroundStyle(KickIQAICoachTheme.accent)

                        TextField("e.g. 45", text: $duration)
                            .keyboardType(.numberPad)
                            .padding(KickIQAICoachTheme.Spacing.sm + 2)
                            .background(Color(.tertiarySystemGroupedBackground), in: .rect(cornerRadius: KickIQAICoachTheme.Radius.md))
                    }

                    VStack(alignment: .leading, spacing: KickIQAICoachTheme.Spacing.sm) {
                        HStack {
                            Text("PERCEIVED EFFORT")
                                .font(.caption.weight(.bold))
                                .tracking(1)
                                .foregroundStyle(KickIQAICoachTheme.accent)
                            Spacer()
                            Text("\(effort)/10")
                                .font(.subheadline.weight(.black))
                                .foregroundStyle(effortColor)
                        }

                        HStack(spacing: 6) {
                            ForEach(1...10, id: \.self) { level in
                                Button {
                                    effort = level
                                } label: {
                                    Text("\(level)")
                                        .font(.system(size: 12, weight: effort == level ? .black : .medium))
                                        .foregroundStyle(effort == level ? .white : KickIQAICoachTheme.textSecondary)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 36)
                                        .background(
                                            effort == level ? effortColor : Color(.tertiarySystemGroupedBackground),
                                            in: .rect(cornerRadius: 8)
                                        )
                                }
                            }
                        }
                    }

                    Button {
                        saveAnnotation()
                        dismiss()
                    } label: {
                        Text("Save")
                            .font(.headline)
                            .foregroundStyle(KickIQAICoachTheme.onAccent)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, KickIQAICoachTheme.Spacing.md)
                            .background(KickIQAICoachTheme.accent, in: .rect(cornerRadius: KickIQAICoachTheme.Radius.lg))
                    }
                }
                .padding(.horizontal, KickIQAICoachTheme.Spacing.md)
                .padding(.top, KickIQAICoachTheme.Spacing.md)
            }
            .scrollIndicators(.hidden)
            .background(KickIQAICoachTheme.background.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(KickIQAICoachTheme.textSecondary)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .presentationBackground(.background)
        .onAppear {
            if let existing = storage.annotationForDate(date) {
                notes = existing.notes
                duration = existing.duration.map { "\($0)" } ?? ""
                effort = existing.effort ?? 5
            }
        }
    }

    private var effortColor: Color {
        switch effort {
        case 1...3: .green
        case 4...6: .orange
        case 7...8: .red.opacity(0.8)
        default: .red
        }
    }

    private func saveAnnotation() {
        let completions = storage.drillCompletionsForDate(date)
        let drillNames = completions.map(\.drillName)
        let annotation = TrainingAnnotation(
            date: date,
            notes: notes,
            duration: Int(duration),
            effort: effort,
            drillsCompleted: drillNames
        )
        storage.saveAnnotation(annotation)
    }
}
