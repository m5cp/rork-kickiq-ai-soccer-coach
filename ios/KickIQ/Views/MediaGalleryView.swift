import SwiftUI

struct MediaGalleryView: View {
    let storage: StorageService
    @State private var mediaStorage = MediaStorageService()
    @State private var selectedTag: MediaTag?
    @State private var showCamera = false
    @State private var showEditor = false
    @State private var selectedItem: MediaItem?
    @State private var selectedImage: UIImage?
    @State private var showDetail = false
    @State private var isSelecting = false
    @State private var selectedIDs: Set<String> = []
    @State private var showDeleteConfirm = false
    @State private var showProfile = false

    private let columns = [
        GridItem(.flexible(), spacing: 2),
        GridItem(.flexible(), spacing: 2),
        GridItem(.flexible(), spacing: 2)
    ]

    private var filteredItems: [MediaItem] {
        mediaStorage.items(for: selectedTag)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                KickIQTheme.background.ignoresSafeArea()

                if mediaStorage.items.isEmpty {
                    emptyState
                } else {
                    galleryContent
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if isSelecting {
                        Button("Cancel") {
                            isSelecting = false
                            selectedIDs.removeAll()
                        }
                        .foregroundStyle(KickIQTheme.textSecondary)
                    } else {
                        Text("MEDIA")
                            .font(.system(.headline, design: .default, weight: .black).width(.compressed))
                            .tracking(1.5)
                            .foregroundStyle(KickIQTheme.textPrimary)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 12) {
                        if isSelecting {
                            if !selectedIDs.isEmpty {
                                Button {
                                    showDeleteConfirm = true
                                } label: {
                                    Image(systemName: "trash")
                                        .foregroundStyle(.red)
                                }
                            }
                        } else {
                            Button {
                                isSelecting = true
                            } label: {
                                Image(systemName: "checkmark.circle")
                                    .foregroundStyle(KickIQTheme.textSecondary)
                            }

                            Button {
                                showCamera = true
                            } label: {
                                Image(systemName: "camera.fill")
                                    .foregroundStyle(KickIQTheme.accent)
                            }
                        }
                    }
                }
            }
            .fullScreenCover(isPresented: $showCamera) {
                CameraRecordView(
                    onPhotoCaptured: { image in
                        let _ = mediaStorage.savePhoto(
                            image,
                            playerName: storage.profile?.name
                        )
                    },
                    initialMode: .photo
                )
            }
            .sheet(isPresented: $showDetail) {
                if let item = selectedItem, let image = selectedImage {
                    MediaDetailSheet(
                        item: item,
                        image: image,
                        mediaStorage: mediaStorage,
                        onEdit: {
                            showDetail = false
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                                showEditor = true
                            }
                        }
                    )
                }
            }
            .fullScreenCover(isPresented: $showEditor) {
                if let image = selectedImage {
                    PhotoEditorView(originalImage: image) { editedImage in
                        if let item = selectedItem {
                            let _ = mediaStorage.saveEditedPhoto(editedImage, originalItem: item)
                        }
                    }
                }
            }
            .alert("Delete \(selectedIDs.count) item\(selectedIDs.count == 1 ? "" : "s")?", isPresented: $showDeleteConfirm) {
                Button("Delete", role: .destructive) {
                    mediaStorage.deleteItems(selectedIDs)
                    selectedIDs.removeAll()
                    isSelecting = false
                }
                Button("Cancel", role: .cancel) {}
            }
        }
    }

    private var galleryContent: some View {
        VStack(spacing: 0) {
            tagFilterBar

            ScrollView {
                statsBar

                LazyVGrid(columns: columns, spacing: 2) {
                    ForEach(filteredItems) { item in
                        gridCell(item)
                    }
                }
                .padding(.horizontal, 2)
                .padding(.bottom, KickIQTheme.Spacing.xl)
            }
            .scrollIndicators(.hidden)
        }
    }

    private var tagFilterBar: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 8) {
                tagChip(nil, label: "All")
                ForEach(MediaTag.allCases) { tag in
                    tagChip(tag, label: tag.rawValue)
                }
            }
            .padding(.vertical, 10)
        }
        .contentMargins(.horizontal, 16)
        .scrollIndicators(.hidden)
    }

    private func tagChip(_ tag: MediaTag?, label: String) -> some View {
        let isActive = selectedTag == tag

        return Button {
            withAnimation(.spring(response: 0.25)) {
                selectedTag = tag
            }
        } label: {
            Text(label)
                .font(.system(size: 13, weight: isActive ? .bold : .medium))
                .foregroundStyle(isActive ? .black : KickIQTheme.textSecondary)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(
                    isActive ? KickIQTheme.accent : KickIQTheme.card,
                    in: Capsule()
                )
        }
        .sensoryFeedback(.selection, trigger: isActive)
    }

    private var statsBar: some View {
        HStack(spacing: KickIQTheme.Spacing.lg) {
            statPill(value: "\(mediaStorage.photoCount)", label: "Photos")
            statPill(value: String(format: "%.1f MB", mediaStorage.storageUsedMB), label: "Storage")
        }
        .padding(.horizontal, KickIQTheme.Spacing.md)
        .padding(.vertical, 8)
    }

    private func statPill(value: String, label: String) -> some View {
        HStack(spacing: 6) {
            Text(value)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(KickIQTheme.textPrimary)
            Text(label)
                .font(.caption)
                .foregroundStyle(KickIQTheme.textSecondary)
        }
    }

    private func gridCell(_ item: MediaItem) -> some View {
        let isSelected = selectedIDs.contains(item.id)

        return Button {
            if isSelecting {
                if isSelected {
                    selectedIDs.remove(item.id)
                } else {
                    selectedIDs.insert(item.id)
                }
            } else {
                selectedItem = item
                selectedImage = mediaStorage.loadImage(for: item)
                showDetail = true
            }
        } label: {
            Color(.secondarySystemBackground)
                .aspectRatio(1, contentMode: .fit)
                .overlay {
                    if let image = mediaStorage.loadImage(for: item) {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .allowsHitTesting(false)
                    }
                }
                .clipShape(.rect)
                .overlay(alignment: .topTrailing) {
                    if isSelecting {
                        ZStack {
                            Circle()
                                .fill(isSelected ? KickIQTheme.accent : .black.opacity(0.4))
                                .frame(width: 24, height: 24)
                            if isSelected {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundStyle(.black)
                            } else {
                                Circle()
                                    .stroke(.white.opacity(0.7), lineWidth: 1.5)
                                    .frame(width: 24, height: 24)
                            }
                        }
                        .padding(6)
                    }
                }
                .overlay(alignment: .bottomLeading) {
                    if item.isEdited {
                        Image(systemName: "wand.and.stars")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(4)
                            .background(.black.opacity(0.5), in: Circle())
                            .padding(4)
                    }
                }
        }
        .sensoryFeedback(.selection, trigger: isSelected)
    }

    private var emptyState: some View {
        VStack(spacing: KickIQTheme.Spacing.lg) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 56))
                .foregroundStyle(KickIQTheme.accent.opacity(0.5))

            VStack(spacing: KickIQTheme.Spacing.sm) {
                Text("No Photos Yet")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(KickIQTheme.textPrimary)

                Text("Take photos of your training sessions,\ntechnique work, or team moments")
                    .font(.subheadline)
                    .foregroundStyle(KickIQTheme.textSecondary)
                    .multilineTextAlignment(.center)
            }

            Button {
                showCamera = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "camera.fill")
                    Text("Take a Photo")
                }
                .font(.headline)
                .foregroundStyle(.black)
                .padding(.horizontal, KickIQTheme.Spacing.xl)
                .padding(.vertical, KickIQTheme.Spacing.md)
                .background(KickIQTheme.accent, in: .rect(cornerRadius: KickIQTheme.Radius.lg))
            }
        }
    }
}

struct MediaDetailSheet: View {
    let item: MediaItem
    let image: UIImage
    let mediaStorage: MediaStorageService
    let onEdit: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var editedItem: MediaItem
    @State private var showShareSheet = false
    @State private var showDeleteConfirm = false

    init(item: MediaItem, image: UIImage, mediaStorage: MediaStorageService, onEdit: @escaping () -> Void) {
        self.item = item
        self.image = image
        self.mediaStorage = mediaStorage
        self.onEdit = onEdit
        _editedItem = State(initialValue: item)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: KickIQTheme.Spacing.lg) {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .clipShape(.rect(cornerRadius: KickIQTheme.Radius.md))
                        .padding(.horizontal, KickIQTheme.Spacing.md)

                    actionButtons

                    detailsSection
                }
                .padding(.top, KickIQTheme.Spacing.md)
                .padding(.bottom, KickIQTheme.Spacing.xl)
            }
            .scrollIndicators(.hidden)
            .background(KickIQTheme.background)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
            .alert("Delete this photo?", isPresented: $showDeleteConfirm) {
                Button("Delete", role: .destructive) {
                    mediaStorage.deleteItem(item)
                    dismiss()
                }
                Button("Cancel", role: .cancel) {}
            }
            .sheet(isPresented: $showShareSheet) {
                ShareSheet(items: [image])
            }
        }
        .presentationDetents([.large])
    }

    private var actionButtons: some View {
        HStack(spacing: KickIQTheme.Spacing.md) {
            actionButton(icon: "wand.and.stars", label: "Edit") {
                onEdit()
            }

            actionButton(icon: "square.and.arrow.up", label: "Share") {
                showShareSheet = true
            }

            actionButton(icon: "trash", label: "Delete", isDestructive: true) {
                showDeleteConfirm = true
            }
        }
        .padding(.horizontal, KickIQTheme.Spacing.md)
    }

    private func actionButton(icon: String, label: String, isDestructive: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.body)
                    .foregroundStyle(isDestructive ? .red : KickIQTheme.accent)
                Text(label)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(isDestructive ? .red.opacity(0.8) : KickIQTheme.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(KickIQTheme.card, in: .rect(cornerRadius: KickIQTheme.Radius.md))
        }
    }

    private var detailsSection: some View {
        VStack(spacing: KickIQTheme.Spacing.md) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Tag")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(KickIQTheme.textSecondary)

                ScrollView(.horizontal) {
                    HStack(spacing: 8) {
                        ForEach(MediaTag.allCases) { tag in
                            Button {
                                editedItem.tag = tag
                                mediaStorage.updateItem(editedItem)
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: tag.icon)
                                        .font(.system(size: 11))
                                    Text(tag.rawValue)
                                        .font(.system(size: 12, weight: .medium))
                                }
                                .foregroundStyle(editedItem.tag == tag ? .black : KickIQTheme.textSecondary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(
                                    editedItem.tag == tag ? KickIQTheme.accent : KickIQTheme.card,
                                    in: Capsule()
                                )
                            }
                        }
                    }
                }
                .contentMargins(.horizontal, 0)
                .scrollIndicators(.hidden)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Caption")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(KickIQTheme.textSecondary)

                TextField("Add a caption...", text: $editedItem.caption)
                    .font(.subheadline)
                    .foregroundStyle(KickIQTheme.textPrimary)
                    .padding(KickIQTheme.Spacing.sm + 4)
                    .background(KickIQTheme.card, in: .rect(cornerRadius: KickIQTheme.Radius.md))
                    .onChange(of: editedItem.caption) { _, _ in
                        mediaStorage.updateItem(editedItem)
                    }
            }

            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Date")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(KickIQTheme.textSecondary)
                    Text(item.createdAt.formatted(date: .abbreviated, time: .shortened))
                        .font(.subheadline)
                        .foregroundStyle(KickIQTheme.textPrimary)
                }
                Spacer()
                if item.isEdited {
                    HStack(spacing: 4) {
                        Image(systemName: "wand.and.stars")
                            .font(.caption)
                        Text("Edited")
                            .font(.caption.weight(.semibold))
                    }
                    .foregroundStyle(KickIQTheme.accent)
                }
            }
        }
        .padding(.horizontal, KickIQTheme.Spacing.md)
    }
}

