import Foundation

struct LocationSuggestion: Identifiable, Hashable {
    let id: String
    let title: String
    let subtitle: String
    let neighborhoodName: String
    let latitude: Double
    let longitude: Double
    let keywords: [String]

    init(
        title: String,
        subtitle: String = "",
        neighborhoodName: String? = nil,
        latitude: Double = 37.7749,
        longitude: Double = -122.4194,
        keywords: [String] = []
    ) {
        self.id = [title, subtitle, neighborhoodName].compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: "|")
        self.title = title
        self.subtitle = subtitle
        self.neighborhoodName = neighborhoodName ?? title
        self.latitude = latitude
        self.longitude = longitude
        self.keywords = keywords
    }

    var displayName: String {
        guard !subtitle.isEmpty else { return title }
        return "\(title), \(subtitle)"
    }

    var neighborhoodMappingDescription: String {
        "Neighborhood: \(neighborhoodName)"
    }

    func matches(_ query: String) -> Bool {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else { return false }

        let searchableText = ([title, subtitle, displayName, neighborhoodName] + keywords)
            .joined(separator: " ")

        return searchableText.localizedCaseInsensitiveContains(trimmedQuery)
    }
}

enum MeetingActivityType: String, Hashable {
    case cafe = "Cafe"
    case walk = "Walk"
}

struct VettedMeetingLocation: Identifiable, Hashable {
    let id: String
    let name: String
    let neighborhoodName: String
    let activityType: MeetingActivityType
    let detail: String

    init(name: String, neighborhoodName: String, activityType: MeetingActivityType, detail: String = "") {
        self.id = "\(neighborhoodName)|\(activityType.rawValue)|\(name)"
        self.name = name
        self.neighborhoodName = neighborhoodName
        self.activityType = activityType
        self.detail = detail
    }
}
