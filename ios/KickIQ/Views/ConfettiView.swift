import SwiftUI

struct ConfettiPiece: Identifiable {
    let id = UUID()
    let color: Color
    let x: CGFloat
    let rotation: Double
    let delay: Double
    let size: CGFloat
    let shape: Int
}

struct ConfettiView: View {
    @State private var animate = false
    let pieces: [ConfettiPiece]

    init(count: Int = 50) {
        let colors: [Color] = [
            KickIQTheme.accent,
            .orange,
            .yellow,
            .green,
            .blue,
            .pink,
            .purple,
            .white
        ]
        pieces = (0..<count).map { _ in
            ConfettiPiece(
                color: colors.randomElement()!,
                x: CGFloat.random(in: -200...200),
                rotation: Double.random(in: 0...720),
                delay: Double.random(in: 0...0.3),
                size: CGFloat.random(in: 4...10),
                shape: Int.random(in: 0...2)
            )
        }
    }

    var body: some View {
        ZStack {
            ForEach(pieces) { piece in
                confettiShape(piece)
                    .foregroundStyle(piece.color)
                    .frame(width: piece.size, height: piece.size * (piece.shape == 1 ? 2.5 : 1))
                    .offset(
                        x: animate ? piece.x : 0,
                        y: animate ? CGFloat.random(in: 400...800) : -50
                    )
                    .rotationEffect(.degrees(animate ? piece.rotation : 0))
                    .opacity(animate ? 0 : 1)
                    .animation(
                        .easeOut(duration: Double.random(in: 1.5...2.5))
                        .delay(piece.delay),
                        value: animate
                    )
            }
        }
        .allowsHitTesting(false)
        .onAppear {
            animate = true
        }
    }

    @ViewBuilder
    private func confettiShape(_ piece: ConfettiPiece) -> some View {
        switch piece.shape {
        case 0:
            Circle().fill(piece.color)
        case 1:
            RoundedRectangle(cornerRadius: 1).fill(piece.color)
        default:
            Rectangle().fill(piece.color).rotationEffect(.degrees(45))
        }
    }
}

struct ConfettiModifier: ViewModifier {
    @Binding var isActive: Bool

    func body(content: Content) -> some View {
        content
            .overlay {
                if isActive {
                    ConfettiView()
                        .ignoresSafeArea()
                        .task {
                            try? await Task.sleep(for: .seconds(2.5))
                            isActive = false
                        }
                }
            }
    }
}

extension View {
    func confetti(isActive: Binding<Bool>) -> some View {
        modifier(ConfettiModifier(isActive: isActive))
    }
}
