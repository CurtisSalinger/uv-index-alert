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
                    sunSection
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

    private var sunSection: some View {
        Section("UV Risk Factors") {
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
            if let uvIndex {
                let burnTime: String
                switch uvIndex {
                case ..<3: burnTime = "60+ min for fair skin"
                case 3..<6: burnTime = "30-45 min for fair skin"
                case 6..<8: burnTime = "15-25 min for fair skin"
                case 8..<11: burnTime = "10-15 min for fair skin"
                default: burnTime = "< 10 min for fair skin"
                }
                detailRow(icon: "timer", label: "Est. Burn Time", value: burnTime)
            }
        }
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
}

#Preview {
    LocationDetailView()
}
