import SwiftUI

struct PhotoEditorView: View {
    let originalImage: UIImage
    let onSave: (UIImage) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var selectedFilter: PhotoFilter = .none
    @State private var adjustments = PhotoAdjustments.default
    @State private var processedImage: UIImage?
    @State private var filterPreviews: [String: UIImage] = [:]
    @State private var activeTab: EditorTab = .filters
    @State private var isProcessing = false
    @State private var compareMode = false

    private enum EditorTab: String, CaseIterable {
        case filters = "Filters"
        case adjust = "Adjust"
    }

    private var displayImage: UIImage {
        if compareMode { return originalImage }
        return processedImage ?? originalImage
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                VStack(spacing: 0) {
                    imagePreview
                    editorControls
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(.white)
                }
                ToolbarItem(placement: .principal) {
                    Text("Edit")
                        .font(.headline)
                        .foregroundStyle(.white)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        onSave(displayImage)
                        dismiss()
                    } label: {
                        Text("Done")
                            .fontWeight(.bold)
                            .foregroundStyle(KickIQTheme.accent)
                    }
                    .disabled(isProcessing)
                }
            }
            .toolbarBackground(.hidden, for: .navigationBar)
        }
        .task {
            await generateFilterPreviews()
        }
        .onChange(of: selectedFilter) { _, _ in applyEdits() }
        .onChange(of: adjustments) { _, _ in applyEdits() }
    }

    private var imagePreview: some View {
        GeometryReader { geo in
            Image(uiImage: displayImage)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxWidth: geo.size.width, maxHeight: geo.size.height)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .gesture(
                    LongPressGesture(minimumDuration: 0.2)
                        .onChanged { _ in compareMode = true }
                        .onEnded { _ in compareMode = false }
                )
                .overlay(alignment: .topLeading) {
                    if compareMode {
                        Text("ORIGINAL")
                            .font(.system(size: 11, weight: .black))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(.black.opacity(0.6), in: Capsule())
                            .padding(12)
                    }
                }
        }
        .frame(maxHeight: .infinity)
    }

    private var editorControls: some View {
        VStack(spacing: 0) {
            Picker("", selection: $activeTab) {
                ForEach(EditorTab.allCases, id: \.self) { tab in
                    Text(tab.rawValue).tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, KickIQTheme.Spacing.md)
            .padding(.top, 12)

            Group {
                switch activeTab {
                case .filters:
                    filtersStrip
                case .adjust:
                    adjustmentControls
                }
            }
            .frame(height: 160)
            .transition(.opacity)
            .animation(.easeInOut(duration: 0.2), value: activeTab)
        }
        .background(.black)
    }

    private var filtersStrip: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 12) {
                ForEach(PhotoFilter.allFilters) { filter in
                    filterThumbnail(filter)
                }
            }
            .padding(.vertical, 12)
        }
        .contentMargins(.horizontal, 16)
        .scrollIndicators(.hidden)
    }

    private func filterThumbnail(_ filter: PhotoFilter) -> some View {
        let isSelected = selectedFilter == filter

        return Button {
            withAnimation(.spring(response: 0.25)) {
                selectedFilter = filter
            }
        } label: {
            VStack(spacing: 6) {
                if let preview = filterPreviews[filter.id] {
                    Image(uiImage: preview)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 72, height: 72)
                        .clipShape(.rect(cornerRadius: 10))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(isSelected ? KickIQTheme.accent : Color.clear, lineWidth: 2.5)
                        )
                } else {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(white: 0.15))
                        .frame(width: 72, height: 72)
                        .overlay {
                            Image(systemName: filter.icon)
                                .font(.title3)
                                .foregroundStyle(.white.opacity(0.4))
                        }
                }

                Text(filter.name)
                    .font(.system(size: 10, weight: isSelected ? .bold : .medium))
                    .foregroundStyle(isSelected ? KickIQTheme.accent : .white.opacity(0.6))
            }
        }
        .sensoryFeedback(.selection, trigger: isSelected)
    }

    private var adjustmentControls: some View {
        ScrollView {
            VStack(spacing: 14) {
                adjustSlider(label: "Exposure", icon: "sun.max.fill", value: $adjustments.exposure, range: -1...1)
                adjustSlider(label: "Brightness", icon: "sun.min.fill", value: $adjustments.brightness, range: -0.3...0.3)
                adjustSlider(label: "Contrast", icon: "circle.lefthalf.filled", value: $adjustments.contrast, range: 0.5...1.5)
                adjustSlider(label: "Saturation", icon: "drop.fill", value: $adjustments.saturation, range: 0...2)
                adjustSlider(label: "Warmth", icon: "thermometer.medium", value: $adjustments.warmth, range: 3000...10000)
                adjustSlider(label: "Vibrance", icon: "wand.and.stars", value: $adjustments.vibrance, range: -1...1)
                adjustSlider(label: "Sharpen", icon: "triangle", value: $adjustments.sharpen, range: 0...2)
                adjustSlider(label: "Vignette", icon: "circle.dashed", value: $adjustments.vignette, range: 0...3)
                adjustSlider(label: "Highlights", icon: "sun.max.trianglebadge.exclamationmark.fill", value: $adjustments.highlights, range: 0...2)
                adjustSlider(label: "Shadows", icon: "shadow", value: $adjustments.shadows, range: -1...1)
            }
            .padding(.horizontal, KickIQTheme.Spacing.md)
            .padding(.vertical, 10)
        }
        .scrollIndicators(.hidden)
    }

    private func adjustSlider(label: String, icon: String, value: Binding<Float>, range: ClosedRange<Float>) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundStyle(.white.opacity(0.5))
                .frame(width: 20)

            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.white.opacity(0.7))
                .frame(width: 70, alignment: .leading)

            Slider(value: value, in: range)
                .tint(KickIQTheme.accent)
        }
    }

    private func applyEdits() {
        isProcessing = true
        let filter = selectedFilter
        let adj = adjustments
        let source = originalImage

        Task.detached {
            let result = PhotoFilterService.applyFilterAndAdjustments(filter: filter, adjustments: adj, to: source)
            await MainActor.run {
                processedImage = result
                isProcessing = false
            }
        }
    }

    private func generateFilterPreviews() async {
        let thumbSize = CGSize(width: 150, height: 150)
        let renderer = UIGraphicsImageRenderer(size: thumbSize)
        let thumb = renderer.image { ctx in
            originalImage.draw(in: CGRect(origin: .zero, size: thumbSize))
        }

        for filter in PhotoFilter.allFilters {
            let preview = await Task.detached {
                PhotoFilterService.applyFilter(filter, to: thumb)
            }.value
            filterPreviews[filter.id] = preview
        }
    }
}
