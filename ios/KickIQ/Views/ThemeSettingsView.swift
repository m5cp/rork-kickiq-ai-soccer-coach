import SwiftUI

struct ThemeSettingsView: View {
    @State private var themeManager = ThemeManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var showCustomPicker = false
    @State private var customPrimaryColor: Color = .blue
    @State private var customAccentColor: Color = .blue

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: KickIQTheme.Spacing.lg) {
                    appearanceModeSection
                    previewCard
                    presetsSection
                    customColorsSection
                }
                .padding(.horizontal, KickIQTheme.Spacing.md)
                .padding(.bottom, KickIQTheme.Spacing.xl)
            }
            .scrollIndicators(.hidden)
            .background(KickIQTheme.background.ignoresSafeArea())
            .navigationTitle("Appearance")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(KickIQTheme.accent)
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .presentationBackground(KickIQTheme.background)
        .onAppear {
            customPrimaryColor = Color(hex: themeManager.customPrimaryHex)
            customAccentColor = Color(hex: themeManager.customAccentHex)
        }
    }

    private var appearanceModeSection: some View {
        VStack(alignment: .leading, spacing: KickIQTheme.Spacing.sm) {
            Text("APPEARANCE")
                .font(.caption.weight(.bold))
                .tracking(1)
                .foregroundStyle(KickIQTheme.textSecondary.opacity(0.5))

            HStack(spacing: 0) {
                ForEach(AppearanceMode.allCases, id: \.rawValue) { mode in
                    Button {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            themeManager.appearanceMode = mode
                        }
                    } label: {
                        VStack(spacing: 6) {
                            Image(systemName: mode.icon)
                                .font(.title3)
                            Text(mode.rawValue)
                                .font(.caption.weight(.semibold))
                        }
                        .foregroundStyle(themeManager.appearanceMode == mode ? KickIQTheme.buttonLabel : KickIQTheme.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background {
                            if themeManager.appearanceMode == mode {
                                RoundedRectangle(cornerRadius: KickIQTheme.Radius.md)
                                    .fill(KickIQTheme.accent)
                            }
                        }
                    }
                }
            }
            .padding(4)
            .background(KickIQTheme.card, in: .rect(cornerRadius: KickIQTheme.Radius.lg))
        }
        .padding(.top, KickIQTheme.Spacing.sm)
    }

    private var previewCard: some View {
        VStack(spacing: KickIQTheme.Spacing.md) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("PREVIEW")
                        .font(.caption.weight(.bold))
                        .tracking(1)
                        .foregroundStyle(KickIQTheme.accent)
                    Text("KickIQ Theme")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(KickIQTheme.textPrimary)
                }
                Spacer()
                ZStack {
                    Circle()
                        .fill(KickIQTheme.accent.opacity(0.15))
                        .frame(width: 44, height: 44)
                    Image(systemName: "figure.soccer")
                        .font(.title3)
                        .foregroundStyle(KickIQTheme.accent)
                }
            }

            HStack(spacing: KickIQTheme.Spacing.sm) {
                previewStat("85", label: "Score", icon: "chart.line.uptrend.xyaxis")
                previewStat("7", label: "Streak", icon: "flame.fill")
                previewStat("12", label: "Sessions", icon: "video.fill")
            }

            HStack(spacing: KickIQTheme.Spacing.sm) {
                Text("Analyze Clip")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(KickIQTheme.buttonLabel)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(KickIQTheme.accent, in: .rect(cornerRadius: KickIQTheme.Radius.sm))

                Text("View Drills")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(KickIQTheme.accent)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(KickIQTheme.accent.opacity(0.15), in: .rect(cornerRadius: KickIQTheme.Radius.sm))
            }
        }
        .padding(KickIQTheme.Spacing.md)
        .background(KickIQTheme.card, in: .rect(cornerRadius: KickIQTheme.Radius.xl))
        .overlay(
            RoundedRectangle(cornerRadius: KickIQTheme.Radius.xl)
                .stroke(KickIQTheme.accent.opacity(0.2), lineWidth: 1)
        )
    }

    private func previewStat(_ value: String, label: String, icon: String) -> some View {
        VStack(spacing: 6) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 10))
                    .foregroundStyle(KickIQTheme.accent)
                Text(value)
                    .font(.title3.weight(.black))
                    .foregroundStyle(KickIQTheme.textPrimary)
            }
            Text(label)
                .font(.caption2.weight(.medium))
                .foregroundStyle(KickIQTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(KickIQTheme.surface, in: .rect(cornerRadius: KickIQTheme.Radius.sm))
    }

    private var presetsSection: some View {
        VStack(alignment: .leading, spacing: KickIQTheme.Spacing.sm) {
            HStack {
                Text("COLOR THEMES")
                    .font(.caption.weight(.bold))
                    .tracking(1)
                    .foregroundStyle(KickIQTheme.textSecondary.opacity(0.5))
                Spacer()
                Button {
                    withAnimation(.spring(response: 0.35)) {
                        if themeManager.isUsingCustomColors {
                            themeManager.isUsingCustomColors = false
                            themeManager.selectedPresetID = "sky"
                        } else {
                            themeManager.isUsingCustomColors = true
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: themeManager.isUsingCustomColors ? "paintpalette.fill" : "paintpalette")
                            .font(.caption)
                        Text(themeManager.isUsingCustomColors ? "Using Custom" : "Custom")
                            .font(.caption.weight(.semibold))
                    }
                    .foregroundStyle(themeManager.isUsingCustomColors ? KickIQTheme.accent : KickIQTheme.textSecondary)
                }
            }

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: 10)], spacing: 10) {
                ForEach(ThemePreset.allPresets) { preset in
                    presetCell(preset)
                }
            }
        }
    }

    private func presetCell(_ preset: ThemePreset) -> some View {
        let isSelected = !themeManager.isUsingCustomColors && themeManager.selectedPresetID == preset.id

        return Button {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                themeManager.selectPreset(preset)
            }
        } label: {
            VStack(spacing: 8) {
                HStack(spacing: 0) {
                    Color(hex: preset.primaryHex)
                    Color(hex: preset.accentHex)
                }
                .frame(height: 32)
                .clipShape(.rect(cornerRadius: 6))

                HStack(spacing: 4) {
                    Image(systemName: preset.icon)
                        .font(.system(size: 9))
                    Text(preset.name)
                        .font(.caption2.weight(.semibold))
                        .lineLimit(1)
                }
                .foregroundStyle(isSelected ? KickIQTheme.accent : KickIQTheme.textSecondary)
            }
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: KickIQTheme.Radius.md)
                    .fill(isSelected ? KickIQTheme.accent.opacity(0.1) : KickIQTheme.card)
                    .overlay(
                        RoundedRectangle(cornerRadius: KickIQTheme.Radius.md)
                            .stroke(isSelected ? KickIQTheme.accent : Color.clear, lineWidth: 1.5)
                    )
            )
        }
        .sensoryFeedback(.selection, trigger: isSelected)
    }

    private var customColorsSection: some View {
        VStack(alignment: .leading, spacing: KickIQTheme.Spacing.sm) {
            Text("CUSTOM COLORS")
                .font(.caption.weight(.bold))
                .tracking(1)
                .foregroundStyle(KickIQTheme.textSecondary.opacity(0.5))

            VStack(spacing: KickIQTheme.Spacing.sm) {
                colorPickerRow("Primary Color", color: $customPrimaryColor) {
                    themeManager.customPrimaryHex = customPrimaryColor.hexUInt
                    themeManager.isUsingCustomColors = true
                }

                colorPickerRow("Accent Color", color: $customAccentColor) {
                    themeManager.customAccentHex = customAccentColor.hexUInt
                    themeManager.isUsingCustomColors = true
                }
            }
            .padding(KickIQTheme.Spacing.md)
            .background(KickIQTheme.card, in: .rect(cornerRadius: KickIQTheme.Radius.lg))
        }
    }

    private func colorPickerRow(_ title: String, color: Binding<Color>, onChange: @escaping () -> Void) -> some View {
        HStack {
            Text(title)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(KickIQTheme.textPrimary)
            Spacer()
            ColorPicker("", selection: color, supportsOpacity: false)
                .labelsHidden()
                .onChange(of: color.wrappedValue) { _, _ in
                    onChange()
                }
        }
    }
}
