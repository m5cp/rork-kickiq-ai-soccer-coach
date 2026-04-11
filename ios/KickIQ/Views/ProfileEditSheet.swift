import SwiftUI
import PhotosUI

struct ProfileEditSheet: View {
    let storage: StorageService
    @Environment(\.dismiss) private var dismiss
    @State private var name: String = ""
    @State private var position: PlayerPosition = .midfielder
    @State private var skillLevel: SkillLevel = .beginner
    @State private var weakness: WeaknessArea = .firstTouch
    @State private var selectedAvatarType: AvatarType = .symbol
    @State private var selectedSymbol: String = "figure.soccer"
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var profileImageData: Data?

    enum AvatarType: String, CaseIterable {
        case photo = "Photo"
        case symbol = "Symbol"
    }

    private let availableSymbols = [
        "figure.soccer", "soccerball", "sportscourt.fill",
        "bolt.fill", "flame.fill", "star.fill",
        "trophy.fill", "medal.fill", "crown.fill",
        "shield.fill", "target", "scope",
        "figure.run", "figure.walk", "heart.fill",
        "lightning.bolt.fill"
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: KickIQTheme.Spacing.lg) {
                    avatarSection
                    nameSection
                    positionSection
                    skillLevelSection
                    weaknessSection
                }
                .padding(KickIQTheme.Spacing.md + 4)
            }
            .scrollIndicators(.hidden)
            .scrollDismissesKeyboard(.interactively)
            .background(KickIQTheme.background.ignoresSafeArea())
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(KickIQTheme.textSecondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveProfile()
                        dismiss()
                    }
                    .foregroundStyle(KickIQTheme.accent)
                    .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .presentationBackground(KickIQTheme.background)
        .onChange(of: selectedPhotoItem) { _, newItem in
            guard let newItem else { return }
            Task {
                if let data = try? await newItem.loadTransferable(type: Data.self) {
                    if let uiImage = UIImage(data: data),
                       let compressed = uiImage.jpegData(compressionQuality: 0.7) {
                        profileImageData = compressed
                        selectedAvatarType = .photo
                    }
                }
            }
        }
        .onAppear {
            if let profile = storage.profile {
                name = profile.name
                position = profile.position
                skillLevel = profile.skillLevel
                weakness = profile.weakness
                if let avatar = profile.avatar {
                    switch avatar {
                    case .symbol(let sym):
                        selectedAvatarType = .symbol
                        selectedSymbol = sym
                    case .imageData(let data):
                        selectedAvatarType = .photo
                        profileImageData = data
                    }
                }
            }
        }
    }

    private var avatarSection: some View {
        VStack(spacing: KickIQTheme.Spacing.md) {
            Text("AVATAR")
                .font(.caption.weight(.bold))
                .tracking(1)
                .foregroundStyle(KickIQTheme.accent)
                .frame(maxWidth: .infinity, alignment: .leading)

            currentAvatarPreview

            HStack(spacing: KickIQTheme.Spacing.sm) {
                ForEach(AvatarType.allCases, id: \.rawValue) { type in
                    Button {
                        selectedAvatarType = type
                    } label: {
                        Text(type.rawValue)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(selectedAvatarType == type ? .black : KickIQTheme.textSecondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, KickIQTheme.Spacing.sm)
                            .background(selectedAvatarType == type ? KickIQTheme.accent : KickIQTheme.surface, in: .rect(cornerRadius: KickIQTheme.Radius.sm))
                    }
                }
            }

            if selectedAvatarType == .photo {
                PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                    HStack(spacing: KickIQTheme.Spacing.sm) {
                        Image(systemName: "photo.on.rectangle.angled")
                        Text("Choose Photo")
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(KickIQTheme.accent)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(KickIQTheme.accent.opacity(0.15), in: .rect(cornerRadius: KickIQTheme.Radius.md))
                }
            } else {
                symbolGrid
            }
        }
    }

    @ViewBuilder
    private var currentAvatarPreview: some View {
        ZStack {
            if selectedAvatarType == .photo, let data = profileImageData, let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 80, height: 80)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(KickIQTheme.accent.opacity(0.3), lineWidth: 2))
            } else {
                ZStack {
                    Circle()
                        .fill(KickIQTheme.accent.opacity(0.15))
                        .frame(width: 80, height: 80)
                    Image(systemName: selectedSymbol)
                        .font(.system(size: 32))
                        .foregroundStyle(KickIQTheme.accent)
                }
                .overlay(Circle().stroke(KickIQTheme.accent.opacity(0.3), lineWidth: 2))
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var symbolGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 4), spacing: 10) {
            ForEach(availableSymbols, id: \.self) { symbol in
                Button {
                    selectedSymbol = symbol
                } label: {
                    ZStack {
                        RoundedRectangle(cornerRadius: KickIQTheme.Radius.sm)
                            .fill(selectedSymbol == symbol ? KickIQTheme.accent.opacity(0.2) : KickIQTheme.surface)
                            .frame(height: 56)
                            .overlay(
                                RoundedRectangle(cornerRadius: KickIQTheme.Radius.sm)
                                    .stroke(selectedSymbol == symbol ? KickIQTheme.accent : Color.clear, lineWidth: 1.5)
                            )
                        Image(systemName: symbol)
                            .font(.title3)
                            .foregroundStyle(selectedSymbol == symbol ? KickIQTheme.accent : KickIQTheme.textSecondary)
                    }
                }
            }
        }
    }

    private var nameSection: some View {
        VStack(alignment: .leading, spacing: KickIQTheme.Spacing.sm) {
            Text("NAME")
                .font(.caption.weight(.bold))
                .tracking(1)
                .foregroundStyle(KickIQTheme.accent)

            TextField("Your name", text: $name)
                .font(.body)
                .padding(KickIQTheme.Spacing.md)
                .background(KickIQTheme.card, in: .rect(cornerRadius: KickIQTheme.Radius.md))
                .foregroundStyle(KickIQTheme.textPrimary)
        }
    }

    private var positionSection: some View {
        VStack(alignment: .leading, spacing: KickIQTheme.Spacing.sm) {
            Text("POSITION")
                .font(.caption.weight(.bold))
                .tracking(1)
                .foregroundStyle(KickIQTheme.accent)

            ForEach(PlayerPosition.allCases) { pos in
                Button {
                    position = pos
                } label: {
                    HStack {
                        Image(systemName: pos.icon)
                            .foregroundStyle(position == pos ? KickIQTheme.accent : KickIQTheme.textSecondary)
                            .frame(width: 24)
                        Text(pos.rawValue)
                            .foregroundStyle(position == pos ? KickIQTheme.textPrimary : KickIQTheme.textSecondary)
                        Spacer()
                        if position == pos {
                            Image(systemName: "checkmark")
                                .foregroundStyle(KickIQTheme.accent)
                        }
                    }
                    .font(.subheadline.weight(.medium))
                    .padding(KickIQTheme.Spacing.sm + 2)
                    .background(position == pos ? KickIQTheme.accent.opacity(0.1) : KickIQTheme.card, in: .rect(cornerRadius: KickIQTheme.Radius.sm))
                }
            }
        }
    }

    private var skillLevelSection: some View {
        VStack(alignment: .leading, spacing: KickIQTheme.Spacing.sm) {
            Text("SKILL LEVEL")
                .font(.caption.weight(.bold))
                .tracking(1)
                .foregroundStyle(KickIQTheme.accent)

            ForEach(SkillLevel.allCases) { level in
                Button {
                    skillLevel = level
                } label: {
                    HStack {
                        Text(level.rawValue)
                            .foregroundStyle(skillLevel == level ? KickIQTheme.textPrimary : KickIQTheme.textSecondary)
                        Spacer()
                        if skillLevel == level {
                            Image(systemName: "checkmark")
                                .foregroundStyle(KickIQTheme.accent)
                        }
                    }
                    .font(.subheadline.weight(.medium))
                    .padding(KickIQTheme.Spacing.sm + 2)
                    .background(skillLevel == level ? KickIQTheme.accent.opacity(0.1) : KickIQTheme.card, in: .rect(cornerRadius: KickIQTheme.Radius.sm))
                }
            }
        }
    }

    private var weaknessSection: some View {
        VStack(alignment: .leading, spacing: KickIQTheme.Spacing.sm) {
            Text("WEAKNESS")
                .font(.caption.weight(.bold))
                .tracking(1)
                .foregroundStyle(KickIQTheme.accent)

            ForEach(WeaknessArea.allCases) { area in
                Button {
                    weakness = area
                } label: {
                    HStack {
                        Image(systemName: area.icon)
                            .foregroundStyle(weakness == area ? KickIQTheme.accent : KickIQTheme.textSecondary)
                            .frame(width: 24)
                        Text(area.rawValue)
                            .foregroundStyle(weakness == area ? KickIQTheme.textPrimary : KickIQTheme.textSecondary)
                        Spacer()
                        if weakness == area {
                            Image(systemName: "checkmark")
                                .foregroundStyle(KickIQTheme.accent)
                        }
                    }
                    .font(.subheadline.weight(.medium))
                    .padding(KickIQTheme.Spacing.sm + 2)
                    .background(weakness == area ? KickIQTheme.accent.opacity(0.1) : KickIQTheme.card, in: .rect(cornerRadius: KickIQTheme.Radius.sm))
                }
            }
        }
    }

    private func saveProfile() {
        let avatar: ProfileAvatar?
        if selectedAvatarType == .photo, let data = profileImageData {
            avatar = .imageData(data)
        } else {
            avatar = .symbol(selectedSymbol)
        }

        let profile = PlayerProfile(
            name: name.trimmingCharacters(in: .whitespaces),
            position: position,
            ageRange: storage.profile?.ageRange ?? .sixteen18,
            skillLevel: skillLevel,
            weakness: weakness,
            avatar: avatar
        )
        storage.saveProfile(profile)
    }
}
