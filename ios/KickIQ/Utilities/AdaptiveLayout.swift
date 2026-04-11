import SwiftUI

struct AdaptiveLayout {
    static let iPadMaxContentWidth: CGFloat = 700
    static let iPadWideMaxContentWidth: CGFloat = 900
    static let iPadSidebarWidth: CGFloat = 320

    static var iPadGridColumns: [GridItem] {
        [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)]
    }

    static var iPadTripleColumns: [GridItem] {
        [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)]
    }
}

struct AdaptiveContainer<Content: View>: View {
    @Environment(\.horizontalSizeClass) private var sizeClass
    let maxWidth: CGFloat
    @ViewBuilder let content: () -> Content

    init(maxWidth: CGFloat = AdaptiveLayout.iPadMaxContentWidth, @ViewBuilder content: @escaping () -> Content) {
        self.maxWidth = maxWidth
        self.content = content
    }

    var body: some View {
        if sizeClass == .regular {
            content()
                .frame(maxWidth: maxWidth)
                .frame(maxWidth: .infinity)
        } else {
            content()
        }
    }
}

struct AdaptiveTwoColumn<Leading: View, Trailing: View>: View {
    @Environment(\.horizontalSizeClass) private var sizeClass
    @ViewBuilder let leading: () -> Leading
    @ViewBuilder let trailing: () -> Trailing

    var body: some View {
        if sizeClass == .regular {
            HStack(alignment: .top, spacing: 20) {
                leading()
                    .frame(maxWidth: .infinity)
                trailing()
                    .frame(maxWidth: .infinity)
            }
        } else {
            VStack(spacing: KickIQTheme.Spacing.md) {
                leading()
                trailing()
            }
        }
    }
}
