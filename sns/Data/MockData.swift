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
        AppGroup(name: "DnD", members: [contacts[0], contacts[1], contacts[2], contacts[3], contacts[4]]),
        AppGroup(name: "Hikes", members: [contacts[5], contacts[6], contacts[7]]),
        AppGroup(name: "College", members: [contacts[8], contacts[9], contacts[10], contacts[11]]),
        AppGroup(name: "High School", members: [contacts[12], contacts[13], contacts[14]]),
        AppGroup(name: "Running", members: [contacts[15], contacts[16], contacts[17]])
    ]

    static let locationSuggestions: [LocationSuggestion] = [
        LocationSuggestion(title: "Bayview / Hunters Point", subtitle: "San Francisco, CA", latitude: 37.7294, longitude: -122.3892, keywords: ["bayview", "hunters point", "94124", "neighborhood", "sf"]),
        LocationSuggestion(title: "Bernal Heights", subtitle: "San Francisco, CA", latitude: 37.7394, longitude: -122.4161, keywords: ["94110", "neighborhood", "sf"]),
        LocationSuggestion(title: "Castro / Upper Market", subtitle: "San Francisco, CA", latitude: 37.7621, longitude: -122.435, keywords: ["castro", "upper market", "94114", "neighborhood", "sf"]),
        LocationSuggestion(title: "Chinatown", subtitle: "San Francisco, CA", latitude: 37.7941, longitude: -122.4078, keywords: ["94108", "neighborhood", "sf"]),
        LocationSuggestion(title: "Crocker Amazon", subtitle: "San Francisco, CA", latitude: 37.7094, longitude: -122.4383, keywords: ["crocker-amazon", "94112", "neighborhood", "sf"]),
        LocationSuggestion(title: "Diamond Heights", subtitle: "San Francisco, CA", latitude: 37.7444, longitude: -122.4419, keywords: ["94131", "neighborhood", "sf"]),
        LocationSuggestion(title: "Downtown / Civic Center", subtitle: "San Francisco, CA", latitude: 37.7793, longitude: -122.4192, keywords: ["downtown", "civic center", "94102", "neighborhood", "sf"]),
        LocationSuggestion(title: "Excelsior", subtitle: "San Francisco, CA", latitude: 37.7216, longitude: -122.435, keywords: ["94112", "neighborhood", "sf"]),
        LocationSuggestion(title: "Financial District", subtitle: "San Francisco, CA", latitude: 37.7946, longitude: -122.3999, keywords: ["fidi", "94104", "94105", "neighborhood", "sf"]),
        LocationSuggestion(title: "Glen Park", subtitle: "San Francisco, CA", latitude: 37.7331, longitude: -122.4338, keywords: ["94131", "neighborhood", "sf"]),
        LocationSuggestion(title: "Golden Gate Park", subtitle: "San Francisco, CA", latitude: 37.7694, longitude: -122.4862, keywords: ["ggp", "94122", "94121", "neighborhood", "sf"]),
        LocationSuggestion(title: "Haight Ashbury", subtitle: "San Francisco, CA", latitude: 37.7692, longitude: -122.4481, keywords: ["haight-ashbury", "haight", "94117", "neighborhood", "sf"]),
        LocationSuggestion(title: "Hayes Valley", subtitle: "San Francisco, CA", latitude: 37.7767, longitude: -122.4241, keywords: ["94102", "neighborhood", "sf"]),
        LocationSuggestion(title: "Inner Richmond", subtitle: "San Francisco, CA", latitude: 37.7806, longitude: -122.4674, keywords: ["94118", "neighborhood", "sf"]),
        LocationSuggestion(title: "Inner Sunset", subtitle: "San Francisco, CA", latitude: 37.7607, longitude: -122.4676, keywords: ["94122", "sunset", "neighborhood", "sf"]),
        LocationSuggestion(title: "Lakeshore", subtitle: "San Francisco, CA", latitude: 37.7282, longitude: -122.4941, keywords: ["lake shore", "lake merced", "94132", "neighborhood", "sf"]),
        LocationSuggestion(title: "Marina", subtitle: "San Francisco, CA", latitude: 37.8037, longitude: -122.4368, keywords: ["marina district", "94123", "neighborhood", "sf"]),
        LocationSuggestion(title: "Mission", subtitle: "San Francisco, CA", neighborhoodName: "Mission", latitude: 37.7599, longitude: -122.4148, keywords: ["mission district", "94110", "neighborhood", "sf"]),
        LocationSuggestion(title: "Nob Hill", subtitle: "San Francisco, CA", latitude: 37.793, longitude: -122.4161, keywords: ["94109", "neighborhood", "sf"]),
        LocationSuggestion(title: "Noe Valley", subtitle: "San Francisco, CA", latitude: 37.7502, longitude: -122.4337, keywords: ["94114", "neighborhood", "sf"]),
        LocationSuggestion(title: "North Beach", subtitle: "San Francisco, CA", latitude: 37.8061, longitude: -122.4103, keywords: ["94133", "neighborhood", "sf"]),
        LocationSuggestion(title: "Ocean View", subtitle: "San Francisco, CA", latitude: 37.7136, longitude: -122.4575, keywords: ["oceanview", "omi", "94112", "neighborhood", "sf"]),
        LocationSuggestion(title: "Outer Mission", subtitle: "San Francisco, CA", latitude: 37.7175, longitude: -122.4411, keywords: ["94112", "neighborhood", "sf"]),
        LocationSuggestion(title: "Outer Richmond", subtitle: "San Francisco, CA", latitude: 37.7799, longitude: -122.502, keywords: ["richmond", "94121", "neighborhood", "sf"]),
        LocationSuggestion(title: "Outer Sunset", subtitle: "San Francisco, CA", latitude: 37.7535, longitude: -122.4942, keywords: ["sunset", "94122", "neighborhood", "sf"]),
        LocationSuggestion(title: "Pacific Heights", subtitle: "San Francisco, CA", latitude: 37.7925, longitude: -122.4382, keywords: ["pac heights", "94115", "94123", "neighborhood", "sf"]),
        LocationSuggestion(title: "Parkside", subtitle: "San Francisco, CA", latitude: 37.7389, longitude: -122.4794, keywords: ["94116", "neighborhood", "sf"]),
        LocationSuggestion(title: "Potrero Hill", subtitle: "San Francisco, CA", latitude: 37.7605, longitude: -122.4009, keywords: ["94107", "neighborhood", "sf"]),
        LocationSuggestion(title: "Presidio", subtitle: "San Francisco, CA", latitude: 37.7989, longitude: -122.4662, keywords: ["94129", "neighborhood", "sf"]),
        LocationSuggestion(title: "Presidio Heights", subtitle: "San Francisco, CA", latitude: 37.7888, longitude: -122.453, keywords: ["94118", "neighborhood", "sf"]),
        LocationSuggestion(title: "Russian Hill", subtitle: "San Francisco, CA", latitude: 37.8014, longitude: -122.4185, keywords: ["94109", "neighborhood", "sf"]),
        LocationSuggestion(title: "Seacliff", subtitle: "San Francisco, CA", latitude: 37.787, longitude: -122.4862, keywords: ["sea cliff", "94121", "neighborhood", "sf"]),
        LocationSuggestion(title: "South Beach", subtitle: "San Francisco, CA", latitude: 37.7819, longitude: -122.3925, keywords: ["94105", "94107", "embarcadero", "neighborhood", "sf"]),
        LocationSuggestion(title: "South of Market (SoMa)", subtitle: "San Francisco, CA", neighborhoodName: "SoMa", latitude: 37.7785, longitude: -122.4056, keywords: ["soma", "south of market", "94103", "neighborhood", "sf"]),
        LocationSuggestion(title: "Treasure Island / Yerba Buena Island", subtitle: "San Francisco, CA", latitude: 37.8249, longitude: -122.3718, keywords: ["treasure island", "yerba buena island", "94130", "neighborhood", "sf"]),
        LocationSuggestion(title: "Twin Peaks", subtitle: "San Francisco, CA", latitude: 37.7544, longitude: -122.4477, keywords: ["94131", "neighborhood", "sf"]),
        LocationSuggestion(title: "Visitacion Valley", subtitle: "San Francisco, CA", latitude: 37.7121, longitude: -122.4094, keywords: ["94134", "neighborhood", "sf"]),
        LocationSuggestion(title: "West of Twin Peaks", subtitle: "San Francisco, CA", latitude: 37.741, longitude: -122.4592, keywords: ["west portal", "forest hill", "94127", "94131", "neighborhood", "sf"]),
        LocationSuggestion(title: "Western Addition", subtitle: "San Francisco, CA", latitude: 37.7825, longitude: -122.4342, keywords: ["94115", "neighborhood", "sf"]),
        LocationSuggestion(title: "123 Market St", subtitle: "San Francisco, CA", neighborhoodName: "Financial District", latitude: 37.7936, longitude: -122.3965, keywords: ["94105", "address", "financial district", "market street", "sf"]),
        LocationSuggestion(title: "San Francisco", subtitle: "CA", neighborhoodName: "South Beach", latitude: 37.7819, longitude: -122.3925, keywords: ["94102", "94103", "94105", "94107", "94110", "city", "sf"])
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
