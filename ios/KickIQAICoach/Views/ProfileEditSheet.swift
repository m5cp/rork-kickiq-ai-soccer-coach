import SwiftUI
import PhotosUI

struct ProfileEditSheet: View {
    let storage: StorageService
    @Environment(\.dismiss) private var dismiss
    @State private var name: String = ""
    @State private var position: PlayerPosition = .midfielder
    @State private var skillLevel: SkillLevel = .beginner
    @State private var weakness: WeaknessArea = .firstTouch
    @State private var gender: PlayerGender = .male
    @State private var usesFootball: Bool = false
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
                VStack(spacing: KickIQAICoachTheme.Spacing.lg) {
                    avatarSection
                    nameSection
                    genderSection
                    terminologySection
                    positionSection
                    skillLevelSection
                    weaknessSection
                }
                .padding(KickIQAICoachTheme.Spacing.md + 4)
            }
            .scrollIndicators(.hidden)
            .scrollDismissesKeyboard(.interactively)
            .background(KickIQAICoachTheme.background.ignoresSafeArea())
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(KickIQAICoachTheme.textSecondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveProfile()
                        dismiss()
                    }
                    .foregroundStyle(KickIQAICoachTheme.accent)
                    .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .presentationBackground(.background)
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
                gender = profile.gender
                usesFootball = profile.usesFootballTerminology
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
        VStack(spacing: KickIQAICoachTheme.Spacing.md) {
            Text("AVATAR")
                .font(.caption.weight(.bold))
                .tracking(1)
                .foregroundStyle(KickIQAICoachTheme.accent)
                .frame(maxWidth: .infinity, alignment: .leading)

            currentAvatarPreview

            HStack(spacing: KickIQAICoachTheme.Spacing.sm) {
                ForEach(AvatarType.allCases, id: \.rawValue) { type in
                    Button {
                        selectedAvatarType = type
                    } label: {
                        Text(type.rawValue)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(selectedAvatarType == type ? KickIQAICoachTheme.onAccent : KickIQAICoachTheme.textSecondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, KickIQAICoachTheme.Spacing.sm)
                            .background(selectedAvatarType == type ? KickIQAICoachTheme.accent : KickIQAICoachTheme.surface, in: .rect(cornerRadius: KickIQAICoachTheme.Radius.sm))
                    }
                }
            }

            if selectedAvatarType == .photo {
                PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                    HStack(spacing: KickIQAICoachTheme.Spacing.sm) {
                        Image(systemName: "photo.on.rectangle.angled")
                        Text("Choose Photo")
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(KickIQAICoachTheme.accent)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(KickIQAICoachTheme.accent.opacity(0.15), in: .rect(cornerRadius: KickIQAICoachTheme.Radius.md))
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
                    .overlay(Circle().stroke(KickIQAICoachTheme.accent.opacity(0.3), lineWidth: 2))
            } else {
                ZStack {
                    Circle()
                        .fill(KickIQAICoachTheme.accent.opacity(0.15))
                        .frame(width: 80, height: 80)
                    Image(systemName: selectedSymbol)
                        .font(.system(size: 32))
                        .foregroundStyle(KickIQAICoachTheme.accent)
                }
                .overlay(Circle().stroke(KickIQAICoachTheme.accent.opacity(0.3), lineWidth: 2))
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
                        RoundedRectangle(cornerRadius: KickIQAICoachTheme.Radius.sm)
                            .fill(selectedSymbol == symbol ? KickIQAICoachTheme.accent.opacity(0.2) : KickIQAICoachTheme.surface)
                            .frame(height: 56)
                            .overlay(
                                RoundedRectangle(cornerRadius: KickIQAICoachTheme.Radius.sm)
                                    .stroke(selectedSymbol == symbol ? KickIQAICoachTheme.accent : Color.clear, lineWidth: 1.5)
                            )
                        Image(systemName: symbol)
                            .font(.title3)
                            .foregroundStyle(selectedSymbol == symbol ? KickIQAICoachTheme.accent : KickIQAICoachTheme.textSecondary)
                    }
                }
            }
        }
    }

    private var nameSection: some View {
        VStack(alignment: .leading, spacing: KickIQAICoachTheme.Spacing.sm) {
            Text("NAME")
                .font(.caption.weight(.bold))
                .tracking(1)
                .foregroundStyle(KickIQAICoachTheme.accent)

            TextField("Your name", text: $name)
                .font(.body)
                .padding(KickIQAICoachTheme.Spacing.md)
                .background(KickIQAICoachTheme.card, in: .rect(cornerRadius: KickIQAICoachTheme.Radius.md))
                .foregroundStyle(KickIQAICoachTheme.textPrimary)
        }
    }

    private var genderSection: some View {
        VStack(alignment: .leading, spacing: KickIQAICoachTheme.Spacing.sm) {
            Text("GENDER")
                .font(.caption.weight(.bold))
                .tracking(1)
                .foregroundStyle(KickIQAICoachTheme.accent)

            ForEach(PlayerGender.allCases) { g in
                Button {
                    gender = g
                } label: {
                    HStack {
                        Image(systemName: g.icon)
                            .foregroundStyle(gender == g ? KickIQAICoachTheme.accent : KickIQAICoachTheme.textSecondary)
                            .frame(width: 24)
                        VStack(alignment: .leading, spacing: 1) {
                            Text(g.rawValue)
                                .foregroundStyle(gender == g ? KickIQAICoachTheme.textPrimary : KickIQAICoachTheme.textSecondary)
                            if g == .nonBinary {
                                Text("Benchmarks use male standards")
                                    .font(.caption2.weight(.medium))
                                    .foregroundStyle(KickIQAICoachTheme.textSecondary.opacity(0.6))
                            }
                        }
                        Spacer()
                        if gender == g {
                            Image(systemName: "checkmark")
                                .foregroundStyle(KickIQAICoachTheme.accent)
                        }
                    }
                    .font(.subheadline.weight(.medium))
                    .padding(KickIQAICoachTheme.Spacing.sm + 2)
                    .background(gender == g ? KickIQAICoachTheme.accent.opacity(0.1) : KickIQAICoachTheme.card, in: .rect(cornerRadius: KickIQAICoachTheme.Radius.sm))
                }
            }
        }
    }

    private var terminologySection: some View {
        VStack(alignment: .leading, spacing: KickIQAICoachTheme.Spacing.sm) {
            Text("SPORT NAME")
                .font(.caption.weight(.bold))
                .tracking(1)
                .foregroundStyle(KickIQAICoachTheme.accent)

            HStack(spacing: KickIQAICoachTheme.Spacing.sm) {
                Button {
                    usesFootball = false
                } label: {
                    HStack {
                        Image(systemName: "flag.fill")
                            .foregroundStyle(!usesFootball ? KickIQAICoachTheme.accent : KickIQAICoachTheme.textSecondary)
                        Text("Soccer")
                            .foregroundStyle(!usesFootball ? KickIQAICoachTheme.textPrimary : KickIQAICoachTheme.textSecondary)
                    }
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, KickIQAICoachTheme.Spacing.sm + 2)
                    .background(!usesFootball ? KickIQAICoachTheme.accent.opacity(0.15) : KickIQAICoachTheme.card, in: .rect(cornerRadius: KickIQAICoachTheme.Radius.sm))
                    .overlay(
                        RoundedRectangle(cornerRadius: KickIQAICoachTheme.Radius.sm)
                            .stroke(!usesFootball ? KickIQAICoachTheme.accent : Color.clear, lineWidth: 1.5)
                    )
                }

                Button {
                    usesFootball = true
                } label: {
                    HStack {
                        Image(systemName: "globe")
                            .foregroundStyle(usesFootball ? KickIQAICoachTheme.accent : KickIQAICoachTheme.textSecondary)
                        Text("Football")
                            .foregroundStyle(usesFootball ? KickIQAICoachTheme.textPrimary : KickIQAICoachTheme.textSecondary)
                    }
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, KickIQAICoachTheme.Spacing.sm + 2)
                    .background(usesFootball ? KickIQAICoachTheme.accent.opacity(0.15) : KickIQAICoachTheme.card, in: .rect(cornerRadius: KickIQAICoachTheme.Radius.sm))
                    .overlay(
                        RoundedRectangle(cornerRadius: KickIQAICoachTheme.Radius.sm)
                            .stroke(usesFootball ? KickIQAICoachTheme.accent : Color.clear, lineWidth: 1.5)
                    )
                }
            }
        }
    }

    private var positionSection: some View {
        VStack(alignment: .leading, spacing: KickIQAICoachTheme.Spacing.sm) {
            Text("POSITION")
                .font(.caption.weight(.bold))
                .tracking(1)
                .foregroundStyle(KickIQAICoachTheme.accent)

            ForEach(PlayerPosition.allCases) { pos in
                Button {
                    position = pos
                } label: {
                    HStack {
                        Image(systemName: pos.icon)
                            .foregroundStyle(position == pos ? KickIQAICoachTheme.accent : KickIQAICoachTheme.textSecondary)
                            .frame(width: 24)
                        Text(pos.rawValue)
                            .foregroundStyle(position == pos ? KickIQAICoachTheme.textPrimary : KickIQAICoachTheme.textSecondary)
                        Spacer()
                        if position == pos {
                            Image(systemName: "checkmark")
                                .foregroundStyle(KickIQAICoachTheme.accent)
                        }
                    }
                    .font(.subheadline.weight(.medium))
                    .padding(KickIQAICoachTheme.Spacing.sm + 2)
                    .background(position == pos ? KickIQAICoachTheme.accent.opacity(0.1) : KickIQAICoachTheme.card, in: .rect(cornerRadius: KickIQAICoachTheme.Radius.sm))
                }
            }
        }
    }

    private var skillLevelSection: some View {
        VStack(alignment: .leading, spacing: KickIQAICoachTheme.Spacing.sm) {
            Text("SKILL LEVEL")
                .font(.caption.weight(.bold))
                .tracking(1)
                .foregroundStyle(KickIQAICoachTheme.accent)

            ForEach(SkillLevel.allCases) { level in
                Button {
                    skillLevel = level
                } label: {
                    HStack {
                        Text(level.rawValue)
                            .foregroundStyle(skillLevel == level ? KickIQAICoachTheme.textPrimary : KickIQAICoachTheme.textSecondary)
                        Spacer()
                        if skillLevel == level {
                            Image(systemName: "checkmark")
                                .foregroundStyle(KickIQAICoachTheme.accent)
                        }
                    }
                    .font(.subheadline.weight(.medium))
                    .padding(KickIQAICoachTheme.Spacing.sm + 2)
                    .background(skillLevel == level ? KickIQAICoachTheme.accent.opacity(0.1) : KickIQAICoachTheme.card, in: .rect(cornerRadius: KickIQAICoachTheme.Radius.sm))
                }
            }
        }
    }

    private var weaknessSection: some View {
        VStack(alignment: .leading, spacing: KickIQAICoachTheme.Spacing.sm) {
            Text("WEAKNESS")
                .font(.caption.weight(.bold))
                .tracking(1)
                .foregroundStyle(KickIQAICoachTheme.accent)

            ForEach(WeaknessArea.allCases) { area in
                Button {
                    weakness = area
                } label: {
                    HStack {
                        Image(systemName: area.icon)
                            .foregroundStyle(weakness == area ? KickIQAICoachTheme.accent : KickIQAICoachTheme.textSecondary)
                            .frame(width: 24)
                        Text(area.rawValue)
                            .foregroundStyle(weakness == area ? KickIQAICoachTheme.textPrimary : KickIQAICoachTheme.textSecondary)
                        Spacer()
                        if weakness == area {
                            Image(systemName: "checkmark")
                                .foregroundStyle(KickIQAICoachTheme.accent)
                        }
                    }
                    .font(.subheadline.weight(.medium))
                    .padding(KickIQAICoachTheme.Spacing.sm + 2)
                    .background(weakness == area ? KickIQAICoachTheme.accent.opacity(0.1) : KickIQAICoachTheme.card, in: .rect(cornerRadius: KickIQAICoachTheme.Radius.sm))
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
            ageRange: storage.profile?.ageRange ?? .fifteen18,
            skillLevel: skillLevel,
            weakness: weakness,
            gender: gender,
            usesFootballTerminology: usesFootball,
            avatar: avatar
        )
        storage.saveProfile(profile)
    }
}
