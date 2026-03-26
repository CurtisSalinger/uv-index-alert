import SwiftUI

/// A programmatic app icon design.
/// To export: run in a preview, screenshot at 1024x1024.
/// Or use this as the app's in-app branding.
struct AppIconView: View {
    var size: CGFloat = 1024

    var body: some View {
        ZStack {
            // Gradient background - warm sun colors
            RoundedRectangle(cornerRadius: size * 0.22)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 1.0, green: 0.6, blue: 0.0),   // warm orange
                            Color(red: 1.0, green: 0.85, blue: 0.1),  // golden yellow
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: size, height: size)

            // Sun rays (subtle radial lines)
            ForEach(0..<12, id: \.self) { i in
                Rectangle()
                    .fill(.white.opacity(0.15))
                    .frame(width: size * 0.03, height: size * 0.35)
                    .offset(y: -size * 0.22)
                    .rotationEffect(.degrees(Double(i) * 30))
            }

            // Sun circle
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            .white,
                            Color(red: 1.0, green: 0.95, blue: 0.6),
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: size * 0.18
                    )
                )
                .frame(width: size * 0.36, height: size * 0.36)
                .offset(y: -size * 0.08)

            // Shield / protection symbol
            VStack(spacing: size * 0.01) {
                Image(systemName: "shield.checkered")
                    .font(.system(size: size * 0.18, weight: .semibold))
                    .foregroundStyle(
                        Color(red: 0.9, green: 0.3, blue: 0.0).opacity(0.85)
                    )
                    .offset(y: size * 0.15)

                Text("UV")
                    .font(.system(size: size * 0.13, weight: .black, design: .rounded))
                    .foregroundStyle(Color(red: 0.8, green: 0.2, blue: 0.0))
                    .offset(y: size * 0.12)
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: size * 0.22))
    }
}

#Preview {
    AppIconView(size: 300)
        .padding()
}
