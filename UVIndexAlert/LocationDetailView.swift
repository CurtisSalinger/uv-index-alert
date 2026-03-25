import SwiftUI
import CoreLocation

struct LocationDetailView: View {
    @StateObject private var locationManager = LocationManager()
    @State private var placemark: CLPlacemark?
    @State private var elevation: Double?
    @State private var uvIndex: Double?
    @State private var humidity: Int?
    @State private var temperature: Double?
    @State private var cloudCover: Int?
    @State private var sunrise: String?
    @State private var sunset: String?
    @State private var solarNoon: String?
    @State private var daylightDuration: Double?
    @State private var isLoading = true

    var body: some View {
        NavigationStack {
            List {
                if isLoading {
                    Section {
                        HStack {
                            Spacer()
                            ProgressView("Loading location details...")
                            Spacer()
                        }
                    }
                } else {
                    locationSection
                    coordinatesSection
                    weatherSection
                    sunExposureSection
                    sunTimesSection
                    protectionSection
                }
            }
            .navigationTitle("Location Details")
            .navigationBarTitleDisplayMode(.inline)
            .task {
                await loadDetails()
            }
            .refreshable {
                await loadDetails()
            }
        }
    }

    private var locationSection: some View {
        Section("Location") {
            if let placemark {
                detailRow(icon: "mappin.circle.fill", label: "City", value: placemark.locality ?? "Unknown")
                detailRow(icon: "map.fill", label: "State/Region", value: placemark.administrativeArea ?? "Unknown")
                detailRow(icon: "flag.fill", label: "Country", value: placemark.country ?? "Unknown")
                if let tz = placemark.timeZone {
                    detailRow(icon: "clock.fill", label: "Timezone", value: tz.identifier)
                }
            } else {
                detailRow(icon: "mappin.circle.fill", label: "City", value: "Unavailable")
            }
        }
    }

    private var coordinatesSection: some View {
        Section("Coordinates") {
            if let location = locationManager.lastLocation {
                detailRow(
                    icon: "location.fill",
                    label: "Latitude",
                    value: String(format: "%.4f°", location.coordinate.latitude)
                )
                detailRow(
                    icon: "location.fill",
                    label: "Longitude",
                    value: String(format: "%.4f°", location.coordinate.longitude)
                )
            }
            if let elevation {
                detailRow(
                    icon: "mountain.2.fill",
                    label: "Elevation",
                    value: String(format: "%.0f m (%.0f ft)", elevation, elevation * 3.28084)
                )
            }
        }
    }

    private var weatherSection: some View {
        Section("Current Conditions") {
            if let uvIndex {
                HStack {
                    Label {
                        Text("UV Index")
                    } icon: {
                        Image(systemName: "sun.max.fill")
                            .foregroundStyle(uvColor(for: uvIndex))
                    }
                    Spacer()
                    Text(String(format: "%.1f — %@", uvIndex, uvDescription(for: uvIndex)))
                        .fontWeight(.medium)
                        .foregroundStyle(uvColor(for: uvIndex))
                }
            }
            if let temperature {
                detailRow(
                    icon: "thermometer.medium",
                    label: "Temperature",
                    value: String(format: "%.1f°C (%.1f°F)", temperature, temperature * 9/5 + 32)
                )
            }
            if let humidity {
                detailRow(icon: "humidity.fill", label: "Humidity", value: "\(humidity)%")
            }
            if let cloudCover {
                detailRow(icon: "cloud.fill", label: "Cloud Cover", value: "\(cloudCover)%")
            }
        }
    }

    private var sunExposureSection: some View {
        Section {
            if let uvIndex {
                // Max recommended time by skin type
                let (fairBurn, fairMax) = burnAndMaxTime(uv: uvIndex, skinFactor: 1.0)
                let (medBurn, medMax) = burnAndMaxTime(uv: uvIndex, skinFactor: 1.7)
                let (darkBurn, darkMax) = burnAndMaxTime(uv: uvIndex, skinFactor: 3.0)

                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "clock.badge.exclamationmark")
                            .foregroundStyle(.orange)
                        Text("Max Recommended Sun Exposure")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }

                    skinTypeRow(
                        label: "Fair / Light",
                        emoji: "🧑🏻",
                        burnTime: fairBurn,
                        maxSafe: fairMax
                    )
                    skinTypeRow(
                        label: "Medium / Olive",
                        emoji: "🧑🏽",
                        burnTime: medBurn,
                        maxSafe: medMax
                    )
                    skinTypeRow(
                        label: "Dark / Deep",
                        emoji: "🧑🏿",
                        burnTime: darkBurn,
                        maxSafe: darkMax
                    )
                }
                .padding(.vertical, 4)

                // SPF recommendation
                HStack {
                    Label {
                        Text("Recommended SPF")
                    } icon: {
                        Image(systemName: "cross.vial.fill")
                            .foregroundStyle(.blue)
                    }
                    Spacer()
                    Text(recommendedSPF(uv: uvIndex))
                        .fontWeight(.semibold)
                        .foregroundStyle(.blue)
                }

                // Reapply reminder
                HStack {
                    Label {
                        Text("Reapply Sunscreen")
                    } icon: {
                        Image(systemName: "arrow.clockwise.circle.fill")
                            .foregroundStyle(.orange)
                    }
                    Spacer()
                    Text(uvIndex >= 3 ? "Every 2 hours" : "Not needed")
                        .foregroundStyle(.secondary)
                }

                // Vitamin D note
                HStack {
                    Label {
                        Text("Vitamin D Exposure")
                    } icon: {
                        Image(systemName: "pill.fill")
                            .foregroundStyle(.yellow)
                    }
                    Spacer()
                    Text(vitaminDTime(uv: uvIndex))
                        .foregroundStyle(.secondary)
                }
            }
        } header: {
            Text("Sun Exposure Guide")
        } footer: {
            Text("Burn times are estimates based on UV index and skin type. Individual sensitivity varies. Always err on the side of caution.")
        }
    }

    private var sunTimesSection: some View {
        Section("Sun Times") {
            if let sunrise {
                detailRow(icon: "sunrise.fill", label: "Sunrise", value: sunrise)
            }
            if let solarNoon {
                detailRow(icon: "sun.max.fill", label: "Solar Noon", value: solarNoon)
            }
            if let sunset {
                detailRow(icon: "sunset.fill", label: "Sunset", value: sunset)
            }
            if let daylightDuration {
                let hours = Int(daylightDuration) / 3600
                let minutes = (Int(daylightDuration) % 3600) / 60
                detailRow(icon: "hourglass", label: "Daylight", value: "\(hours)h \(minutes)m")
            }
            if let uvIndex {
                detailRow(
                    icon: "exclamationmark.triangle.fill",
                    label: "Peak UV Hours",
                    value: uvIndex > 0 ? "10 AM – 4 PM" : "None (nighttime)"
                )
            }
        }
    }

    private var protectionSection: some View {
        Section {
            if let uvIndex {
                ForEach(protectionTips(uv: uvIndex), id: \.self) { tip in
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: tip.icon)
                            .foregroundStyle(tip.color)
                            .frame(width: 24)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(tip.title)
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Text(tip.detail)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 2)
                }
            }

            if let elevation {
                let elevRisk = elevation > 1500 ? "Higher UV at altitude" : "Normal altitude"
                detailRow(icon: "arrow.up.forward", label: "Altitude Effect", value: elevRisk)
            }
            if let cloudCover {
                let cloudRisk: String
                switch cloudCover {
                case 0..<25: cloudRisk = "Minimal cloud protection"
                case 25..<50: cloudRisk = "Some cloud filtering"
                case 50..<75: cloudRisk = "Moderate cloud cover"
                default: cloudRisk = "Heavy cloud cover"
                }
                detailRow(icon: "cloud.sun.fill", label: "Cloud Effect", value: cloudRisk)
            }
        } header: {
            Text("Protection Tips")
        } footer: {
            if let uvIndex, uvIndex >= 8 {
                Text("UV is very high. Limit outdoor activities between 10 AM and 4 PM.")
            }
        }
    }

    // MARK: - Sun Exposure Helpers

    private func burnAndMaxTime(uv: Double, skinFactor: Double) -> (String, String) {
        guard uv > 0 else { return ("N/A", "No limit") }
        // Approximate MED (Minimal Erythemal Dose) based burn time
        // Base burn time for skin type I at UV 1 ≈ 67 minutes
        let baseBurn = 67.0 * skinFactor
        let burnMinutes = baseBurn / uv
        let maxSafe = burnMinutes * 0.6 // 60% of burn time as safe margin

        let burnStr: String
        if burnMinutes > 120 { burnStr = "2+ hours" }
        else if burnMinutes > 60 { burnStr = String(format: "~%.0f min", burnMinutes) }
        else { burnStr = String(format: "~%.0f min", burnMinutes) }

        let maxStr: String
        if maxSafe > 120 { maxStr = "2+ hours" }
        else if maxSafe < 5 { maxStr = "< 5 min" }
        else { maxStr = String(format: "%.0f min", maxSafe) }

        return (burnStr, maxStr)
    }

    private func skinTypeRow(label: String, emoji: String, burnTime: String, maxSafe: String) -> some View {
        HStack {
            Text(emoji)
            VStack(alignment: .leading, spacing: 1) {
                Text(label)
                    .font(.caption)
                    .fontWeight(.medium)
                Text("Burns in \(burnTime)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 1) {
                Text(maxSafe)
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(.orange)
                Text("max safe")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
    }

    private func recommendedSPF(uv: Double) -> String {
        switch uv {
        case ..<3: return "SPF 15 (optional)"
        case 3..<6: return "SPF 30"
        case 6..<8: return "SPF 50"
        case 8..<11: return "SPF 50+"
        default: return "SPF 50+ (stay inside if possible)"
        }
    }

    private func vitaminDTime(uv: Double) -> String {
        switch uv {
        case ..<1: return "UV too low for vitamin D"
        case 1..<3: return "~20-30 min (arms & face)"
        case 3..<6: return "~10-15 min (arms & face)"
        case 6..<8: return "~5-10 min (arms & face)"
        default: return "~5 min (arms & face)"
        }
    }

    struct ProtectionTip: Hashable {
        let icon: String
        let color: Color
        let title: String
        let detail: String
    }

    private func protectionTips(uv: Double) -> [ProtectionTip] {
        var tips: [ProtectionTip] = []

        if uv >= 3 {
            tips.append(ProtectionTip(
                icon: "tube.and.syringe",
                color: .blue,
                title: "Apply sunscreen",
                detail: "SPF 30+ on all exposed skin, 15 min before going out"
            ))
        }
        if uv >= 3 {
            tips.append(ProtectionTip(
                icon: "eyeglasses",
                color: .brown,
                title: "Wear sunglasses",
                detail: "UV400 or 100% UV protection lenses"
            ))
        }
        if uv >= 6 {
            tips.append(ProtectionTip(
                icon: "tshirt.fill",
                color: .indigo,
                title: "Cover up",
                detail: "Long sleeves, pants, and a wide-brimmed hat"
            ))
        }
        if uv >= 6 {
            tips.append(ProtectionTip(
                icon: "house.fill",
                color: .green,
                title: "Seek shade",
                detail: "Stay under cover during peak hours (10 AM – 4 PM)"
            ))
        }
        if uv >= 8 {
            tips.append(ProtectionTip(
                icon: "xmark.octagon.fill",
                color: .red,
                title: "Avoid outdoor activities",
                detail: "Reschedule outdoor exercise to early morning or evening"
            ))
        }
        if uv >= 11 {
            tips.append(ProtectionTip(
                icon: "exclamationmark.triangle.fill",
                color: .purple,
                title: "Extreme danger",
                detail: "Unprotected skin can burn in minutes. Stay inside."
            ))
        }
        if uv < 3 {
            tips.append(ProtectionTip(
                icon: "checkmark.circle.fill",
                color: .green,
                title: "Low risk",
                detail: "Enjoy the outdoors! Sunscreen optional for most skin types."
            ))
        }

        return tips
    }

    private func detailRow(icon: String, label: String, value: String) -> some View {
        HStack {
            Label(label, systemImage: icon)
            Spacer()
            Text(value)
                .foregroundStyle(.secondary)
        }
    }

    private func loadDetails() async {
        isLoading = true
        defer { isLoading = false }

        locationManager.requestPermission()
        try? await Task.sleep(for: .seconds(1))

        guard let location = locationManager.lastLocation else { return }

        // Reverse geocode
        let geocoder = CLGeocoder()
        placemark = try? await geocoder.reverseGeocodeLocation(location).first

        // Fetch detailed weather
        let lat = location.coordinate.latitude
        let lng = location.coordinate.longitude
        let urlString = "https://api.open-meteo.com/v1/forecast"
            + "?latitude=\(lat)&longitude=\(lng)"
            + "&current=uv_index,temperature_2m,relative_humidity_2m,cloud_cover"
            + "&daily=sunrise,sunset,daylight_duration,uv_index_max"
            + "&timezone=auto"

        guard let url = URL(string: urlString) else { return }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                elevation = json["elevation"] as? Double
                if let current = json["current"] as? [String: Any] {
                    uvIndex = current["uv_index"] as? Double
                    temperature = current["temperature_2m"] as? Double
                    humidity = current["relative_humidity_2m"] as? Int
                    cloudCover = current["cloud_cover"] as? Int
                }
                if let daily = json["daily"] as? [String: Any] {
                    if let sunrises = daily["sunrise"] as? [String], let first = sunrises.first {
                        sunrise = formatTimeFromISO(first)
                    }
                    if let sunsets = daily["sunset"] as? [String], let first = sunsets.first {
                        sunset = formatTimeFromISO(first)
                    }
                    if let durations = daily["daylight_duration"] as? [Double], let first = durations.first {
                        daylightDuration = first
                    }
                }
                // Calculate solar noon from sunrise/sunset
                if let daily = json["daily"] as? [String: Any],
                   let sunrises = daily["sunrise"] as? [String], let sr = sunrises.first,
                   let sunsets = daily["sunset"] as? [String], let ss = sunsets.first {
                    solarNoon = calculateSolarNoon(sunrise: sr, sunset: ss)
                }
            }
        } catch {
            print("Failed to fetch weather details: \(error)")
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
        case ..<3: return "Low"
        case 3..<6: return "Moderate"
        case 6..<8: return "High"
        case 8..<11: return "Very High"
        default: return "Extreme"
        }
    }

    private func formatTimeFromISO(_ iso: String) -> String {
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withFullDate, .withTime, .withColonSeparatorInTime]
        guard let date = isoFormatter.date(from: iso) else {
            // Try without T separator
            let df = DateFormatter()
            df.dateFormat = "yyyy-MM-dd'T'HH:mm"
            guard let d = df.date(from: iso) else { return iso }
            let tf = DateFormatter()
            tf.timeStyle = .short
            return tf.string(from: d)
        }
        let tf = DateFormatter()
        tf.timeStyle = .short
        return tf.string(from: date)
    }

    private func calculateSolarNoon(sunrise: String, sunset: String) -> String {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd'T'HH:mm"
        guard let sr = df.date(from: sunrise), let ss = df.date(from: sunset) else { return "--" }
        let noon = sr.addingTimeInterval(ss.timeIntervalSince(sr) / 2)
        let tf = DateFormatter()
        tf.timeStyle = .short
        return tf.string(from: noon)
    }
}

#Preview {
    LocationDetailView()
}
