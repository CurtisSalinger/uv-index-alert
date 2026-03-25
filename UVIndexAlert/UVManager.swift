import Foundation
import WidgetKit

class UVManager: ObservableObject {
    @Published var currentUV: Double?

    struct OpenMeteoResponse: Codable {
        let current: CurrentWeather

        struct CurrentWeather: Codable {
            let uv_index: Double
        }
    }

    @MainActor
    func fetchUVIndex(latitude: Double, longitude: Double) async throws -> Double {
        let urlString = "https://api.open-meteo.com/v1/forecast"
            + "?latitude=\(latitude)"
            + "&longitude=\(longitude)"
            + "&current=uv_index"
            + "&timezone=auto"

        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }

        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode(OpenMeteoResponse.self, from: data)
        let uv = response.current.uv_index
        currentUV = uv

        // Share with widget
        if let defaults = AppConstants.sharedDefaults {
            defaults.set(uv, forKey: AppConstants.uvIndexKey)
            defaults.set(Date().timeIntervalSince1970, forKey: AppConstants.lastCheckedKey)
        }
        WidgetCenter.shared.reloadAllTimelines()

        return uv
    }
}
