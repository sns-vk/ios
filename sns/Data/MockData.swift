import Foundation

enum MockData {
    static let contacts: [AppContact] = [
        AppContact(name: "Ivory Berry"),
        AppContact(name: "Casen Valentine"),
        AppContact(name: "Alianna Mendez"),
        AppContact(name: "Ahmed Ingram"),
        AppContact(name: "Ryleigh Kramer"),
        AppContact(name: "Abraham Combs"),
        AppContact(name: "Braelynn Vu"),
        AppContact(name: "Ethan Jimenez"),
        AppContact(name: "Sara Osborne"),
        AppContact(name: "Carter Houston"),
        AppContact(name: "Dior Mann"),
        AppContact(name: "Jaxson Leach"),
        AppContact(name: "Landry Garcia"),
        AppContact(name: "Brady Woodward"),
        AppContact(name: "Bellamy Juarez"),
        AppContact(name: "Grant Landry"),
        AppContact(name: "Stormi Osborne"),
        AppContact(name: "Manuel Klein"),
        AppContact(name: "Marie Bell"),
        AppContact(name: "Damien Avalos"),
        AppContact(name: "Iris Burke"),
        AppContact(name: "Bryan Burton"),
        AppContact(name: "Bethany Shepard"),
        AppContact(name: "Jaden Spence"),
        AppContact(name: "Faye Arroyo"),
        AppContact(name: "Watson Fisher"),
        AppContact(name: "Ryann Roberts"),
        AppContact(name: "Onyx Valdez"),
        AppContact(name: "Aubriella Sellers"),
        AppContact(name: "Ruben Mendoza"),
        AppContact(name: "Kylee Maxwell"),
        AppContact(name: "Jaden Avalos"),
        AppContact(name: "Rowan Burch"),
        AppContact(name: "Zavier White"),
        AppContact(name: "Esmeralda Galindo"),
        AppContact(name: "Brayan Hensley"),
        AppContact(name: "Rosa Acosta"),
        AppContact(name: "Ivan White"),
        AppContact(name: "Jaelynn Sosa"),
        AppContact(name: "Jedidiah Stein"),
        AppContact(name: "Addison Burch"),
        AppContact(name: "Maverick Person"),
        AppContact(name: "Chloe Simmons"),
        AppContact(name: "Kaiser Bravo"),
        AppContact(name: "Joyce Stokes"),
        AppContact(name: "Mathew Combs"),
        AppContact(name: "London Adams"),
        AppContact(name: "Roman Brandt"),
        AppContact(name: "Maryam Olsen"),
        AppContact(name: "Romeo Hoffman"),
        AppContact(name: "London Pham"),
        AppContact(name: "Alijah Alvarez"),
        AppContact(name: "Joyce Yoder"),
        AppContact(name: "Marcel Ahmed"),
        AppContact(name: "Winter Parsons"),
        AppContact(name: "Lance Buck"),
        AppContact(name: "Etta Sims"),
        AppContact(name: "Eithan Casey"),
        AppContact(name: "Kylee Portillo"),
        AppContact(name: "Ahmed Singh"),
        AppContact(name: "Elliott McCoy"),
        AppContact(name: "Andre Lim"),
        AppContact(name: "Lennox Bell"),
        AppContact(name: "Ambrose Santana")
    ]

    static let groups: [AppGroup] = [
        AppGroup(name: "Study Group", members: [contacts[0], contacts[1], contacts[2]]),
        AppGroup(name: "Weekend Hikes", members: [contacts[3], contacts[4]])
    ]

    static let locationSuggestions: [LocationSuggestion] = [
        LocationSuggestion(
            title: "Hayes Valley",
            subtitle: "San Francisco, CA",
            neighborhoodName: "Hayes Valley",
            latitude: 37.7767,
            longitude: -122.4241,
            keywords: ["94102", "neighborhood", "sf"]
        ),
        LocationSuggestion(
            title: "Mission District",
            subtitle: "San Francisco, CA",
            neighborhoodName: "Mission District",
            latitude: 37.7599,
            longitude: -122.4148,
            keywords: ["94110", "mission", "neighborhood", "sf"]
        ),
        LocationSuggestion(
            title: "SoMa",
            subtitle: "San Francisco, CA",
            neighborhoodName: "SoMa",
            latitude: 37.7785,
            longitude: -122.4056,
            keywords: ["94103", "south of market", "neighborhood", "sf"]
        ),
        LocationSuggestion(
            title: "123 Market St",
            subtitle: "San Francisco, CA",
            neighborhoodName: "Financial District",
            latitude: 37.7936,
            longitude: -122.3965,
            keywords: ["94105", "address", "financial district", "market street", "sf"]
        ),
        LocationSuggestion(
            title: "San Francisco",
            subtitle: "CA",
            neighborhoodName: "SoMa",
            latitude: 37.7785,
            longitude: -122.4056,
            keywords: ["94102", "94103", "94105", "94110", "city", "sf"]
        ),
        LocationSuggestion(
            title: "North Beach",
            subtitle: "San Francisco, CA",
            neighborhoodName: "North Beach",
            latitude: 37.8061,
            longitude: -122.4103,
            keywords: ["94133", "neighborhood", "sf"]
        ),
        LocationSuggestion(
            title: "Marina",
            subtitle: "San Francisco, CA",
            neighborhoodName: "Marina",
            latitude: 37.8037,
            longitude: -122.4368,
            keywords: ["94123", "marina district", "neighborhood", "sf"]
        ),
        LocationSuggestion(
            title: "Inner Sunset",
            subtitle: "San Francisco, CA",
            neighborhoodName: "Inner Sunset",
            latitude: 37.7607,
            longitude: -122.4676,
            keywords: ["94122", "sunset", "neighborhood", "sf"]
        )
    ]

    static func locationSuggestions(matching query: String) -> [LocationSuggestion] {
        locationSuggestions.filter { $0.matches(query) }
    }

    static func locationSuggestion(forNeighborhood neighborhoodName: String) -> LocationSuggestion? {
        locationSuggestions.first { $0.neighborhoodName == neighborhoodName }
    }

    static let vettedMeetingLocations: [VettedMeetingLocation] = [
        VettedMeetingLocation(name: "Hayes Cafe Mock Spot", neighborhoodName: "Hayes Valley", activityType: .cafe, detail: "Indoor public seating"),
        VettedMeetingLocation(name: "Hayes Green Mock Walk", neighborhoodName: "Hayes Valley", activityType: .walk, detail: "Daytime public route"),
        VettedMeetingLocation(name: "Mission Cafe Mock Spot", neighborhoodName: "Mission District", activityType: .cafe, detail: "Transit-adjacent"),
        VettedMeetingLocation(name: "Mission Plaza Mock Walk", neighborhoodName: "Mission District", activityType: .walk, detail: "Daytime public route"),
        VettedMeetingLocation(name: "SoMa Cafe Mock Spot", neighborhoodName: "SoMa", activityType: .cafe, detail: "Central SF option"),
        VettedMeetingLocation(name: "SoMa Promenade Mock Walk", neighborhoodName: "SoMa", activityType: .walk, detail: "Daytime public route"),
        VettedMeetingLocation(name: "FiDi Cafe Mock Spot", neighborhoodName: "Financial District", activityType: .cafe, detail: "Weekday-friendly"),
        VettedMeetingLocation(name: "FiDi Waterfront Mock Walk", neighborhoodName: "Financial District", activityType: .walk, detail: "Daytime public route")
    ]

    static let logbookItems: [ActivityItem] = [
        ActivityItem(title: "Enrolled in this week's batch", detail: "You're in for Sunday release.", timestamp: "2h ago", symbol: "checkmark.circle.fill"),
        ActivityItem(title: "Added Ivory Berry", detail: "New contact added to your network.", timestamp: "Yesterday", symbol: "person.badge.plus"),
        ActivityItem(title: "Created Weekend Hikes", detail: "Group now has 5 members.", timestamp: "2d ago", symbol: "person.2.fill"),
        ActivityItem(title: "Updated discovery preferences", detail: "Age range updated to 21-27.", timestamp: "3d ago", symbol: "slider.horizontal.3")
    ]

    static let initialMatchMessages: [MatchMessage] = [
        MatchMessage(isFromUser: false, text: "Hey! Nice to match with you this week.", timestamp: "9:41 AM"),
        MatchMessage(isFromUser: true, text: "Likewise, hope your week is going well.", timestamp: "9:42 AM"),
        MatchMessage(isFromUser: false, text: "It is! Want to grab coffee tomorrow?", timestamp: "9:43 AM")
    ]

    static let mailThreads: [MailThread] = [
        MailThread(
            correspondentName: "Ivory Berry",
            subject: "Coffee after the batch?",
            preview: "I might be near Hayes Valley later this week.",
            timestamp: "Today",
            isUnread: true,
            messages: [
                MailMessage(senderName: "Ivory Berry", body: "I might be near Hayes Valley later this week. Want to find a quiet coffee spot?", timestamp: "Today, 9:12 AM", isFromUser: false),
                MailMessage(senderName: "Me", body: "That sounds good. Thursday afternoon is easiest for me.", timestamp: "Today, 9:30 AM", isFromUser: true)
            ]
        ),
        MailThread(
            correspondentName: "Casen Valentine",
            subject: "Intro through Study Group",
            preview: "Mia said we should compare notes before Sunday.",
            timestamp: "Yesterday",
            isUnread: true,
            messages: [
                MailMessage(senderName: "Casen Valentine", body: "Alianna said we should compare notes before Sunday. I can send over a short summary tonight.", timestamp: "Yesterday, 7:44 PM", isFromUser: false)
            ]
        ),
        MailThread(
            correspondentName: "Ahmed Ingram",
            subject: "Weekend Hikes route",
            preview: "The route I mentioned is better early in the morning.",
            timestamp: "Mon",
            isUnread: false,
            messages: [
                MailMessage(senderName: "Ahmed Ingram", body: "The route I mentioned is better early in the morning. It gets crowded after 10.", timestamp: "Mon, 8:18 AM", isFromUser: false),
                MailMessage(senderName: "Me", body: "Good call. I will check the trail map before we pick a time.", timestamp: "Mon, 10:05 AM", isFromUser: true)
            ]
        )
    ]
}
