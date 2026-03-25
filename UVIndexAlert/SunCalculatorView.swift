import SwiftUI

struct SunCalculatorView: View {
    @StateObject private var locationManager = LocationManager()
    @StateObject private var uvManager = UVManager()
    @State private var desiredMinutes: Double = 60
    @State private var selectedSkinType: SkinType = .medium
    @State private var hasLoaded = false

    enum SkinType: String, CaseIterable, Identifiable {
        case fair = "Fair / Light"
        case medium = "Medium / Olive"
        case dark = "Dark / Deep"

        var id: String { rawValue }

        var emoji: String {
            switch self {
            case .fair: return "🧑🏻"
            case .medium: return "🧑🏽"
            case .dark: return "🧑🏿"
            }
        }

        /// Multiplier relative to skin type I base burn time
        var factor: Double {
            switch self {
            case .fair: return 1.0
            case .medium: return 1.7
            case .dark: return 3.0
            }
        }
    }

    private var currentUV: Double {
        uvManager.currentUV ?? 0
    }

    /// Unprotected burn time in minutes for the selected skin type
    private var baseBurnTime: Double {
        guard currentUV > 0 else { return 999 }
        return 67.0 * selectedSkinType.factor / currentUV
    }

    /// How many "burn cycles" the desired time covers
    private var protectionMultiple: Double {
        guard baseBurnTime > 0 else { return 1 }
        return desiredMinutes / baseBurnTime
    }

    /// Minimum SPF needed (SPF = how many times longer you can stay out)
    private var requiredSPF: Int {
        let raw = Int(ceil(protectionMultiple))
        // Round up to nearest standard SPF
        if raw <= 1 { return 0 } // no sunscreen needed
        if raw <= 15 { return 15 }
        if raw <= 30 { return 30 }
        if raw <= 50 { return 50 }
        return 50
    }

    /// Practical SPF recommendation (accounts for real-world application)
    /// People typically apply 25-50% of tested amount, so recommend 2x the calculated need
    private var recommendedSPF: Int {
        let practical = Int(ceil(protectionMultiple * 2))
        if practical <= 1 { return 0 }
        if practical <= 15 { return 15 }
        if practical <= 30 { return 30 }
        if practical <= 50 { return 50 }
        return 50
    }

    /// Reapply interval in minutes
    private var reapplyInterval: Int {
        if recommendedSPF == 0 { return 0 } // no sunscreen needed
        // Sunscreen degrades: reapply every 2 hours or sooner if sweating/swimming
        // For very high UV, recommend more frequent
        if currentUV >= 8 { return 60 }
        if currentUV >= 6 { return 80 }
        return 120
    }

    /// Number of times you need to reapply
    private var reapplyCount: Int {
        guard reapplyInterval > 0 else { return 0 }
        return max(0, Int(ceil(desiredMinutes / Double(reapplyInterval))) - 1)
    }

    var body: some View {
        NavigationStack {
            List {
                currentUVSection
                timeInputSection
                skinTypeSection

                if hasLoaded && currentUV > 0 {
                    resultSection
                    timelineSection
                    tipsSection
                }
            }
            .navigationTitle("Sun Calculator")
            .navigationBarTitleDisplayMode(.inline)
            .task {
                locationManager.requestPermission()
                try? await Task.sleep(for: .seconds(1))
                if let loc = locationManager.lastLocation {
                    _ = try? await uvManager.fetchUVIndex(
                        latitude: loc.coordinate.latitude,
                        longitude: loc.coordinate.longitude
                    )
                }
                hasLoaded = true
            }
        }
    }

    private var currentUVSection: some View {
        Section {
            if let uv = uvManager.currentUV {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Current UV Index")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text(String(format: "%.1f", uv))
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundStyle(uvColor(for: uv))
                    }
                    Spacer()
                    Text(uvEmoji(for: uv))
                        .font(.system(size: 48))
                }
            } else if hasLoaded {
                HStack {
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundStyle(.orange)
                    Text("Could not fetch UV index. Check location permissions.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            } else {
                HStack {
                    ProgressView()
                    Text("Fetching UV index...")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var timeInputSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 12) {
                Text("How long do you want to stay outside?")
                    .font(.subheadline)
                    .fontWeight(.medium)

                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(formatDuration(desiredMinutes))
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(.blue)
                        .contentTransition(.numericText())
                        .animation(.snappy, value: desiredMinutes)
                }

                Slider(value: $desiredMinutes, in: 15...480, step: 15) {
                    Text("Duration")
                } minimumValueLabel: {
                    Text("15m")
                        .font(.caption2)
                } maximumValueLabel: {
                    Text("8h")
                        .font(.caption2)
                }
                .tint(.blue)

                // Quick-pick buttons
                HStack(spacing: 8) {
                    ForEach([30, 60, 120, 240], id: \.self) { mins in
                        Button {
                            withAnimation { desiredMinutes = Double(mins) }
                        } label: {
                            Text(quickLabel(mins))
                                .font(.caption)
                                .fontWeight(.medium)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(desiredMinutes == Double(mins) ? .blue : Color(.systemGray5))
                                .foregroundStyle(desiredMinutes == Double(mins) ? .white : .primary)
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.vertical, 4)
        }
    }

    private var skinTypeSection: some View {
        Section {
            Picker("Skin Type", selection: $selectedSkinType) {
                ForEach(SkinType.allCases) { type in
                    HStack {
                        Text(type.emoji)
                        Text(type.rawValue)
                    }
                    .tag(type)
                }
            }
            .pickerStyle(.menu)

            HStack {
                Image(systemName: "flame")
                    .foregroundStyle(.orange)
                Text("Unprotected burn time:")
                Spacer()
                Text(baseBurnTime > 120 ? "2+ hours" : String(format: "~%.0f min", baseBurnTime))
                    .fontWeight(.semibold)
                    .foregroundStyle(.orange)
            }
            .font(.subheadline)
        } header: {
            Text("Your Skin")
        } footer: {
            Text("Burn time is an estimate. Fair skin burns fastest, darker skin has more natural protection.")
        }
    }

    private var resultSection: some View {
        Section {
            // SPF Recommendation
            VStack(spacing: 16) {
                if recommendedSPF == 0 {
                    // No sunscreen needed
                    HStack(spacing: 12) {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 40))
                            .foregroundStyle(.green)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("No sunscreen needed!")
                                .font(.headline)
                                .foregroundStyle(.green)
                            Text("Your skin can handle \(formatDuration(desiredMinutes)) at this UV level.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                } else {
                    // SPF card
                    HStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(spfColor.gradient)
                                .frame(width: 72, height: 72)
                            VStack(spacing: 0) {
                                Text("SPF")
                                    .font(.caption2)
                                    .fontWeight(.bold)
                                Text(recommendedSPF == 50 && protectionMultiple * 2 > 50 ? "50+" : "\(recommendedSPF)")
                                    .font(.system(size: 24, weight: .black, design: .rounded))
                            }
                            .foregroundStyle(.white)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Use SPF \(recommendedSPF)\(protectionMultiple * 2 > 50 ? "+" : "")")
                                .font(.headline)

                            if reapplyCount > 0 {
                                Text("Reapply every **\(reapplyInterval) min** (\(reapplyCount)x total)")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            } else {
                                Text("Single application should be enough")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        } header: {
            Text("Your Plan")
        } footer: {
            if recommendedSPF > 0 {
                Text("SPF \(recommendedSPF) means your skin is protected \(recommendedSPF)x longer than without sunscreen. We recommend 2x the theoretical minimum to account for uneven application.")
            }
        }
    }

    private var timelineSection: some View {
        Section("Your Timeline") {
            if recommendedSPF == 0 {
                timelineRow(
                    time: "Now",
                    icon: "figure.walk",
                    color: .green,
                    text: "Head outside — you're good!"
                )
                timelineRow(
                    time: "+\(formatDuration(desiredMinutes))",
                    icon: "checkmark.circle.fill",
                    color: .green,
                    text: "Done! No burn risk."
                )
            } else {
                timelineRow(
                    time: "15 min before",
                    icon: "tube.and.syringe",
                    color: .blue,
                    text: "Apply SPF \(recommendedSPF)\(protectionMultiple * 2 > 50 ? "+" : "") generously"
                )

                timelineRow(
                    time: "Now",
                    icon: "figure.walk",
                    color: .green,
                    text: "Head outside!"
                )

                // Reapply points
                if reapplyCount > 0 {
                    ForEach(1...reapplyCount, id: \.self) { i in
                        let mins = reapplyInterval * i
                        if mins < Int(desiredMinutes) {
                            timelineRow(
                                time: "+\(formatDuration(Double(mins)))",
                                icon: "arrow.clockwise.circle.fill",
                                color: .orange,
                                text: "Reapply sunscreen (#\(i))"
                            )
                        }
                    }
                }

                timelineRow(
                    time: "+\(formatDuration(desiredMinutes))",
                    icon: "checkmark.circle.fill",
                    color: .green,
                    text: "All done — you're protected!"
                )
            }
        }
    }

    private var tipsSection: some View {
        Section("Extra Tips") {
            if currentUV >= 6 {
                tipRow(icon: "drop.fill", color: .cyan, text: "Sweating or swimming? Reapply immediately after, even if it hasn't been \(reapplyInterval) min.")
            }
            if desiredMinutes >= 120 {
                tipRow(icon: "cup.and.saucer.fill", color: .brown, text: "Take shade breaks every hour to reduce cumulative exposure.")
            }
            if currentUV >= 3 {
                tipRow(icon: "eyeglasses", color: .indigo, text: "Don't forget UV-blocking sunglasses and a hat.")
            }
            tipRow(icon: "hand.raised.fill", color: .pink, text: "Apply a shot glass worth (~1 oz) of sunscreen for full body coverage.")
            if desiredMinutes > baseBurnTime && recommendedSPF >= 50 {
                tipRow(icon: "exclamationmark.triangle.fill", color: .red, text: "Long exposure at high UV — consider UPF clothing for extra protection.")
            }
        }
    }

    // MARK: - Helpers

    private func timelineRow(time: String, icon: String, color: Color, text: String) -> some View {
        HStack(spacing: 12) {
            Text(time)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
                .frame(width: 70, alignment: .trailing)

            Image(systemName: icon)
                .foregroundStyle(color)
                .frame(width: 24)

            Text(text)
                .font(.subheadline)
        }
        .padding(.vertical, 2)
    }

    private func tipRow(icon: String, color: Color, text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .frame(width: 24)
            Text(text)
                .font(.caption)
        }
        .padding(.vertical, 2)
    }

    private func formatDuration(_ minutes: Double) -> String {
        let mins = Int(minutes)
        if mins < 60 { return "\(mins) min" }
        let h = mins / 60
        let m = mins % 60
        if m == 0 { return "\(h)h" }
        return "\(h)h \(m)m"
    }

    private func quickLabel(_ mins: Int) -> String {
        if mins < 60 { return "\(mins)m" }
        return "\(mins / 60)h"
    }

    private var spfColor: Color {
        switch recommendedSPF {
        case ..<30: return .green
        case 30: return .yellow
        case 50: return .orange
        default: return .red
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

    private func uvEmoji(for uv: Double) -> String {
        switch uv {
        case ..<3: return "😎"
        case 3..<6: return "🧴"
        case 6..<8: return "⚠️"
        case 8..<11: return "🔥"
        default: return "☠️"
        }
    }
}

#Preview {
    SunCalculatorView()
}
