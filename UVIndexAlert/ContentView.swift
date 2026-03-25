import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Label("UV Index", systemImage: "sun.max.fill")
                }
                .tag(0)

            UVMapView()
                .tabItem {
                    Label("World Map", systemImage: "map.fill")
                }
                .tag(1)

            LocationDetailView()
                .tabItem {
                    Label("Details", systemImage: "info.circle.fill")
                }
                .tag(2)
        }
    }
}

// MARK: - Home View (original UV display)

struct HomeView: View {
    @StateObject private var locationManager = LocationManager()
    @StateObject private var uvManager = UVManager()
    @StateObject private var settings = UserSettings.shared
    @State private var lastChecked: Date?
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                Spacer()

                uvDisplay

                if let lastChecked {
                    Text("Last checked \(lastChecked.formatted(.relative(presentation: .named)))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if let errorMessage {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                Spacer()

                thresholdSetting

                refreshButton
            }
            .padding()
            .navigationTitle("UV Index Alert")
            .task {
                await setup()
            }
        }
    }

    private var uvDisplay: some View {
        VStack(spacing: 12) {
            Text(uvEmoji)
                .font(.system(size: 80))

            if let uv = uvManager.currentUV {
                Text(String(format: "%.1f", uv))
                    .font(.system(size: 64, weight: .bold, design: .rounded))
                    .foregroundStyle(uvColor(for: uv))

                Text(uvDescription(for: uv))
                    .font(.title3)
                    .foregroundStyle(.secondary)
            } else {
                Text("--")
                    .font(.system(size: 64, weight: .bold, design: .rounded))
                    .foregroundStyle(.secondary)

                Text("Checking UV index...")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var thresholdSetting: some View {
        VStack(spacing: 8) {
            Text("Alert when UV is above \(Int(settings.threshold))")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Slider(value: $settings.threshold, in: 1...11, step: 1)
                .tint(uvColor(for: settings.threshold))
                .padding(.horizontal, 32)
        }
    }

    private var refreshButton: some View {
        Button {
            Task { await checkUV() }
        } label: {
            Label("Check Now", systemImage: "arrow.clockwise")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(.blue)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .padding(.horizontal)
        .padding(.bottom)
    }

    private func setup() async {
        NotificationManager.shared.requestPermission()
        locationManager.requestPermission()

        // Schedule background refresh
        (UIApplication.shared.delegate as? AppDelegate)?.scheduleBackgroundRefresh()

        // Small delay for location to populate
        try? await Task.sleep(for: .seconds(1))
        await checkUV()
    }

    private func checkUV() async {
        errorMessage = nil
        guard let location = locationManager.lastLocation else {
            errorMessage = "Waiting for location access..."
            return
        }

        do {
            let uv = try await uvManager.fetchUVIndex(
                latitude: location.coordinate.latitude,
                longitude: location.coordinate.longitude
            )
            lastChecked = Date()
            if uv > settings.threshold {
                await NotificationManager.shared.sendUVAlert(uvIndex: uv)
            }
        } catch {
            errorMessage = "Could not fetch UV index. Check your connection."
        }
    }

    private var uvEmoji: String {
        guard let uv = uvManager.currentUV else { return "🌤️" }
        switch uv {
        case ..<3: return "😎"
        case 3..<6: return "🧴"
        case 6..<8: return "⚠️"
        case 8..<11: return "🔥"
        default: return "☠️"
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

    private func uvDescription(for uv: Double) -> String {
        switch uv {
        case ..<3: return "Low — No protection needed"
        case 3..<6: return "Moderate — Wear sunscreen"
        case 6..<8: return "High — Sunscreen is a must"
        case 8..<11: return "Very High — Avoid the sun"
        default: return "Extreme — Stay inside"
        }
    }
}

#Preview {
    ContentView()
}
