import Foundation

struct RootSearchResults {
    let query: String
    let pages: [RootSearchPage]
    let shortcuts: [RootSearchShortcut]
    let contactIDs: [AppContact.ID]
    let groupIDs: [AppGroup.ID]

    var isSearching: Bool {
        !query.isEmpty
    }

    var isEmpty: Bool {
        pages.isEmpty && shortcuts.isEmpty && contactIDs.isEmpty && groupIDs.isEmpty
    }
}

enum RootSearchShortcut: CaseIterable, Identifiable {
    case sharingCard
    case firstName
    case lastName
    case nickname

    var id: Self { self }

    var title: String {
        switch self {
        case .sharingCard: "Sharing Card"
        case .firstName: ProfileField.firstName.title
        case .lastName: ProfileField.lastName.title
        case .nickname: ProfileField.nickname.title
        }
    }

    var systemImage: String {
        switch self {
        case .sharingCard: "person.text.rectangle"
        case .firstName, .lastName: "person.text.rectangle"
        case .nickname: "quote.bubble"
        }
    }

    var destination: RootDestination {
        switch self {
        case .sharingCard: .myCard
        case .firstName: .profileField(.firstName)
        case .lastName: .profileField(.lastName)
        case .nickname: .profileField(.nickname)
        }
    }

    private var keywords: [String] {
        switch self {
        case .sharingCard: ["card", "contact card", "sharing", "shared", "profile"]
        case .firstName: ["name", "given name"]
        case .lastName: ["name", "family name", "surname"]
        case .nickname: ["name", "handle", "username"]
        }
    }

    func matches(_ query: String) -> Bool {
        let normalizedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedQuery.isEmpty else { return false }
        return title.localizedCaseInsensitiveContains(normalizedQuery)
            || keywords.contains { $0.localizedCaseInsensitiveContains(normalizedQuery) }
    }
}

enum RootSearchIndex {
    static func results(
        for query: String,
        contacts: [AppContact],
        groups: [AppGroup]
    ) -> RootSearchResults {
        let normalizedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !normalizedQuery.isEmpty else {
            return RootSearchResults(query: "", pages: [], shortcuts: [], contactIDs: [], groupIDs: [])
        }

        let pages = RootSearchPage.allCases.filter { $0.matches(normalizedQuery) }
        let shortcuts = RootSearchShortcut.allCases.filter { $0.matches(normalizedQuery) }
        let contactIDs = contacts
            .filter { $0.name.localizedCaseInsensitiveContains(normalizedQuery) }
            .map(\.id)
        let groupIDs = groups
            .filter { $0.name.localizedCaseInsensitiveContains(normalizedQuery) }
            .map(\.id)

        return RootSearchResults(
            query: normalizedQuery,
            pages: pages,
            shortcuts: shortcuts,
            contactIDs: contactIDs,
            groupIDs: groupIDs
        )
    }

    static func results(for query: String, in appState: AppState) -> RootSearchResults {
        results(for: query, contacts: appState.contacts, groups: appState.groups)
    }
}
