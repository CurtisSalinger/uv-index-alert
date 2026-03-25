import WidgetKit
import SwiftUI

struct UVEntry: TimelineEntry {
    let date: Date
    let uvIndex: Double?
    let locationName: String?
}

struct UVProvider: TimelineProvider {
    func placeholder(in context: Context) -> UVEntry {
        UVEntry(date: .now, uvIndex: 4.2, locationName: "Your Location")
    }

    func getSnapshot(in context: Context, completion: @escaping (UVEntry) -> Void) {
        let entry = currentEntry()
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<UVEntry>) -> Void) {
        let defaults = AppConstants.sharedDefaults
        let lat = defaults?.double(forKey: AppConstants.latitudeKey) ?? 0
        let lng = defaults?.double(forKey: AppConstants.longitudeKey) ?? 0

        guard lat != 0, lng != 0 else {
            let entry = UVEntry(date: .now, uvIndex: nil, locationName: nil)
            let timeline = Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(900)))
            completion(timeline)
            return
        }

        let urlString = "https://api.open-meteo.com/v1/forecast"
            + "?latitude=\(lat)&longitude=\(lng)"
            + "&current=uv_index&timezone=auto"

        guard let url = URL(string: urlString) else {
            let timeline = Timeline(entries: [currentEntry()], policy: .after(Date().addingTimeInterval(3600)))
            completion(timeline)
            return
        }

        URLSession.shared.dataTask(with: url) { data, _, error in
            var uvIndex: Double?
            if let data, error == nil,
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let current = json["current"] as? [String: Any],
               let uv = current["uv_index"] as? Double {
                uvIndex = uv
                defaults?.set(uv, forKey: AppConstants.uvIndexKey)
                defaults?.set(Date().timeIntervalSince1970, forKey: AppConstants.lastCheckedKey)
            }

            let entry = UVEntry(date: .now, uvIndex: uvIndex ?? defaults?.double(forKey: AppConstants.uvIndexKey), locationName: nil)
            let nextRefresh = Date().addingTimeInterval(3600)
            let timeline = Timeline(entries: [entry], policy: .after(nextRefresh))
            completion(timeline)
        }.resume()
    }

    private func currentEntry() -> UVEntry {
        let defaults = AppConstants.sharedDefaults
        let uv = defaults?.double(forKey: AppConstants.uvIndexKey)
        return UVEntry(date: .now, uvIndex: uv == 0 ? nil : uv, locationName: nil)
    }
}

// MARK: - Small Widget

struct UVWidgetSmallView: View {
    let entry: UVEntry

    var body: some View {
        ZStack {
            backgroundGradient
            VStack(spacing: 6) {
                Text(uvEmoji)
                    .font(.system(size: 36))

                if let uv = entry.uvIndex {
                    Text(String(format: "%.1f", uv))
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)

                    Text(shortDescription)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.white.opacity(0.9))
                } else {
                    Text("--")
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.5))

                    Text("Open app")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.7))
                }
            }
        }
    }

    private var shortDescription: String {
        guard let uv = entry.uvIndex else { return "" }
        switch uv {
        case ..<3: return "Low"
        case 3..<6: return "Wear Sunscreen"
        case 6..<8: return "High UV"
        case 8..<11: return "Very High"
        default: return "Extreme!"
        }
    }

    private var uvEmoji: String {
        guard let uv = entry.uvIndex else { return "🌤️" }
        switch uv {
        case ..<3: return "😎"
        case 3..<6: return "🧴"
        case 6..<8: return "⚠️"
        case 8..<11: return "🔥"
        default: return "☠️"
        }
    }

    private var backgroundGradient: some View {
        let colors: [Color] = {
            guard let uv = entry.uvIndex else {
                return [.gray.opacity(0.6), .gray.opacity(0.3)]
            }
            switch uv {
            case ..<3: return [.green, .green.opacity(0.6)]
            case 3..<6: return [.yellow, .orange.opacity(0.6)]
            case 6..<8: return [.orange, .red.opacity(0.6)]
            case 8..<11: return [.red, .red.opacity(0.7)]
            default: return [.purple, .red.opacity(0.7)]
            }
        }()
        return LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}

// MARK: - Medium Widget

struct UVWidgetMediumView: View {
    let entry: UVEntry

    var body: some View {
        ZStack {
            backgroundGradient
            HStack(spacing: 20) {
                VStack(spacing: 4) {
                    Text(uvEmoji)
                        .font(.system(size: 44))

                    if let uv = entry.uvIndex {
                        Text(String(format: "%.1f", uv))
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                    } else {
                        Text("--")
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.5))
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("UV Index")
                        .font(.headline)
                        .foregroundStyle(.white.opacity(0.8))

                    if let uv = entry.uvIndex {
                        Text(longDescription)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(.white)

                        Text(entry.date.formatted(date: .omitted, time: .shortened))
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.7))
                    } else {
                        Text("Open the app to start checking UV levels")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.8))
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, 4)
        }
    }

    private var longDescription: String {
        guard let uv = entry.uvIndex else { return "" }
        switch uv {
        case ..<3: return "Low risk.\nNo protection needed."
        case 3..<6: return "Moderate risk.\nWear sunscreen!"
        case 6..<8: return "High risk.\nSunscreen is a must."
        case 8..<11: return "Very high risk.\nAvoid the sun."
        default: return "Extreme risk.\nStay inside!"
        }
    }

    private var uvEmoji: String {
        guard let uv = entry.uvIndex else { return "🌤️" }
        switch uv {
        case ..<3: return "😎"
        case 3..<6: return "🧴"
        case 6..<8: return "⚠️"
        case 8..<11: return "🔥"
        default: return "☠️"
        }
    }

    private var backgroundGradient: some View {
        let colors: [Color] = {
            guard let uv = entry.uvIndex else {
                return [.gray.opacity(0.6), .gray.opacity(0.3)]
            }
            switch uv {
            case ..<3: return [.green, .green.opacity(0.6)]
            case 3..<6: return [.yellow, .orange.opacity(0.6)]
            case 6..<8: return [.orange, .red.opacity(0.6)]
            case 8..<11: return [.red, .red.opacity(0.7)]
            default: return [.purple, .red.opacity(0.7)]
            }
        }()
        return LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}

// MARK: - Widget Definition

struct UVIndexAlertWidget: Widget {
    let kind = "UVIndexAlertWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: UVProvider()) { entry in
            if #available(iOS 17.0, *) {
                WidgetView(entry: entry)
                    .containerBackground(for: .widget) { Color.clear }
            } else {
                WidgetView(entry: entry)
            }
        }
        .configurationDisplayName("UV Index")
        .description("Shows the current UV index for your location.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct WidgetView: View {
    @Environment(\.widgetFamily) var family
    let entry: UVEntry

    var body: some View {
        switch family {
        case .systemMedium:
            UVWidgetMediumView(entry: entry)
        default:
            UVWidgetSmallView(entry: entry)
        }
    }
}

#Preview(as: .systemSmall) {
    UVIndexAlertWidget()
} timeline: {
    UVEntry(date: .now, uvIndex: 4.2, locationName: "San Francisco")
    UVEntry(date: .now, uvIndex: 8.5, locationName: "San Francisco")
}

#Preview(as: .systemMedium) {
    UVIndexAlertWidget()
} timeline: {
    UVEntry(date: .now, uvIndex: 5.7, locationName: "San Francisco")
}
