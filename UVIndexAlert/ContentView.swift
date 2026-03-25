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

                if uv > 0 {
                    maxTimeCard(uv: uv)
                }
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

    private func maxTimeCard(uv: Double) -> some View {
        let fairMax = maxSafeMinutes(uv: uv, skinFactor: 1.0)
        let medMax = maxSafeMinutes(uv: uv, skinFactor: 1.7)

        return VStack(spacing: 8) {
            Divider().padding(.horizontal, 40)

            HStack(spacing: 24) {
                VStack(spacing: 2) {
                    Text("🧑🏻")
                    Text(formatMinutes(fairMax))
                        .font(.system(.callout, design: .rounded, weight: .bold))
                        .foregroundStyle(.orange)
                    Text("fair skin")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                VStack(spacing: 2) {
                    Text("🧑🏽")
                    Text(formatMinutes(medMax))
                        .font(.system(.callout, design: .rounded, weight: .bold))
                        .foregroundStyle(.orange)
                    Text("medium skin")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                VStack(spacing: 2) {
                    Image(systemName: "cross.vial.fill")
                        .foregroundStyle(.blue)
                        .font(.callout)
                    Text(quickSPF(uv: uv))
                        .font(.system(.callout, design: .rounded, weight: .bold))
                        .foregroundStyle(.blue)
                    Text("rec. SPF")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            if uv >= 3 {
                Text("Reapply sunscreen every 2 hours")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.top, 4)
    }

    private func maxSafeMinutes(uv: Double, skinFactor: Double) -> Double {
        guard uv > 0 else { return 999 }
        return (67.0 * skinFactor / uv) * 0.6
    }

    private func formatMinutes(_ min: Double) -> String {
        if min > 120 { return "2h+" }
        if min < 5 { return "<5m" }
        return String(format: "%.0fm", min)
    }

    private func quickSPF(uv: Double) -> String {
        switch uv {
        case ..<3: return "15"
        case 3..<6: return "30"
        case 6..<8: return "50"
        default: return "50+"
        }
    }
}

#Preview {
    ContentView()
}
