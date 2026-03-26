import Foundation
import CoreLocation

struct WorldLocation: Identifiable {
    let id = UUID()
    let name: String
    let coordinate: CLLocationCoordinate2D
    var uvIndex: Double?
    var elevation: Double?
}

class WorldUVManager: ObservableObject {
    @Published var locations: [WorldLocation] = []
    @Published var isLoading = false

    static let cities: [(String, Double, Double)] = [
        ("Tokyo", 35.6762, 139.6503),
        ("Delhi", 28.7041, 77.1025),
        ("Shanghai", 31.2304, 121.4737),
        ("São Paulo", -23.5505, -46.6333),
        ("Mexico City", 19.4326, -99.1332),
        ("Cairo", 30.0444, 31.2357),
        ("Mumbai", 19.0760, 72.8777),
        ("Beijing", 39.9042, 116.4074),
        ("Lagos", 6.5244, 3.3792),
        ("Los Angeles", 34.0522, -118.2437),
        ("London", 51.5074, -0.1278),
        ("Paris", 48.8566, 2.3522),
        ("Sydney", -33.8688, 151.2093),
        ("Dubai", 25.2048, 55.2708),
        ("Singapore", 1.3521, 103.8198),
        ("Nairobi", -1.2921, 36.8219),
        ("Lima", -12.0464, -77.0428),
        ("Bangkok", 13.7563, 100.5018),
        ("Cape Town", -33.9249, 18.4241),
        ("Reykjavik", 64.1466, -21.9426),
        ("Anchorage", 61.2181, -149.9003),
        ("Miami", 25.7617, -80.1918),
        ("Honolulu", 21.3069, -157.8583),
        ("Santiago", -33.4489, -70.6693),
        ("Moscow", 55.7558, 37.6173),
        ("Johannesburg", -26.2041, 28.0473),
        ("Rio de Janeiro", -22.9068, -43.1729),
        ("Athens", 37.9838, 23.7275),
        ("Marrakech", 31.6295, -7.9811),
        ("Denver", 39.7392, -104.9903),
    ]

    var maxUVLocation: WorldLocation? {
        locations.filter { $0.uvIndex != nil }.max(by: { ($0.uvIndex ?? 0) < ($1.uvIndex ?? 0) })
    }

    var minUVLocation: WorldLocation? {
        locations.filter { $0.uvIndex != nil }.min(by: { ($0.uvIndex ?? 0) < ($1.uvIndex ?? 0) })
    }

    @MainActor
    func fetchAllUV() async {
        isLoading = true
        defer { isLoading = false }

        // Build multi-location query using comma-separated coords
        let lats = Self.cities.map { String($0.1) }.joined(separator: ",")
        let lngs = Self.cities.map { String($0.2) }.joined(separator: ",")

        let urlString = "https://api.open-meteo.com/v1/forecast"
            + "?latitude=\(lats)"
            + "&longitude=\(lngs)"
            + "&current=uv_index"
            + "&timezone=auto"

        guard let url = URL(string: urlString) else { return }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let json = try JSONSerialization.jsonObject(with: data)

            var results: [WorldLocation] = []

            if let array = json as? [[String: Any]] {
                // Multi-location response is an array
                for (i, item) in array.enumerated() where i < Self.cities.count {
                    let city = Self.cities[i]
                    let uv = (item["current"] as? [String: Any])?["uv_index"] as? Double
                    let elev = item["elevation"] as? Double
                    var loc = WorldLocation(
                        name: city.0,
                        coordinate: CLLocationCoordinate2D(latitude: city.1, longitude: city.2)
                    )
                    loc.uvIndex = uv
                    loc.elevation = elev
                    results.append(loc)
                }
            }

            locations = results
        } catch {
            print("Failed to fetch world UV: \(error)")
        }
    }
}
