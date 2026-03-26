import SwiftUI
import MapKit

struct UVMapView: View {
    @StateObject private var worldUV = WorldUVManager()
    @State private var camera: MapCameraPosition = .automatic

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                extremesBar

                Map(position: $camera) {
                    ForEach(worldUV.locations) { loc in
                        if let uv = loc.uvIndex {
                            Annotation(loc.name, coordinate: loc.coordinate) {
                                uvPin(uv: uv, name: loc.name)
                            }
                        }
                    }
                }
                .mapStyle(.standard(elevation: .realistic))
            }
            .navigationTitle("World UV Map")
            .navigationBarTitleDisplayMode(.inline)
            .task {
                await worldUV.fetchAllUV()
            }
            .refreshable {
                await worldUV.fetchAllUV()
            }
        }
    }

    private var extremesBar: some View {
        HStack(spacing: 0) {
            if worldUV.isLoading {
                HStack {
                    ProgressView()
                    Text("Loading global UV data...")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            } else if let maxLoc = worldUV.maxUVLocation, let minLoc = worldUV.minUVLocation {
                extremeCard(
                    label: "HIGHEST",
                    city: maxLoc.name,
                    uv: maxLoc.uvIndex ?? 0,
                    icon: "arrow.up.circle.fill",
                    color: uvColor(for: maxLoc.uvIndex ?? 0)
                )

                Divider()
                    .frame(height: 40)

                extremeCard(
                    label: "LOWEST",
                    city: minLoc.name,
                    uv: minLoc.uvIndex ?? 0,
                    icon: "arrow.down.circle.fill",
                    color: uvColor(for: minLoc.uvIndex ?? 0)
                )
            }
        }
        .padding(.vertical, 8)
        .background(.ultraThinMaterial)
    }

    private func extremeCard(label: String, city: String, uv: Double, icon: String, color: Color) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                Text(city)
                    .font(.caption)
                    .fontWeight(.medium)
                Text(String(format: "UV %.1f", uv))
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundStyle(color)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func uvPin(uv: Double, name: String) -> some View {
        VStack(spacing: 2) {
            ZStack {
                Circle()
                    .fill(uvColor(for: uv))
                    .frame(width: 36, height: 36)
                    .shadow(color: uvColor(for: uv).opacity(0.5), radius: 4)

                Text(String(format: "%.0f", uv))
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
            }

            // Pointer triangle
            Triangle()
                .fill(uvColor(for: uv))
                .frame(width: 10, height: 6)
        }
    }

    private func uvColor(for uv: Double) -> Color {
        switch uv {
        case ..<3: return .green
        case 3..<6: return .yellow
        case 6..<8: return .orange
        case 8..<11: return .red
        default: return .purple
        }
    }
}

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.closeSubpath()
        return path
    }
}

#Preview {
    UVMapView()
}
