import Foundation

enum PreferredContactMethod: String, CaseIterable, Identifiable, Hashable {
    case email
    case phone
    case sns
    case other

    var id: Self { self }

    var label: String {
        switch self {
        case .email: "Email"
        case .phone: "Phone"
        case .sns: "SNS"
        case .other: "Other"
        }
    }
}

struct AppContact: Identifiable, Hashable {
    let id = UUID()
    var firstName: String
    var lastName: String
    var nickname: String
    var photoData: Data?
    var bio: String
    var phone: String
    var email: String
    var preferredContactMethod: PreferredContactMethod
    var preferredContactDetail: String
    var age: Int
    var gender: GenderIdentity
    var pronouns: PronounOption
    var sexuality: SexualityOption
    var substanceUse: [SubstanceUseCategory: SubstanceUseAnswer]
    var address: String
    var websiteURL: String
    var birthday: Date?
    var notes: String
    var useForFoFRecommendations: Bool

    var name: String {
        let combined = "\(firstName) \(lastName)".trimmingCharacters(in: .whitespaces)
        return combined.isEmpty ? "Unnamed Contact" : combined
    }

    var initials: String {
        let firstInitial = firstName.trimmedInitial
        let lastInitial = lastName.trimmedInitial
        let combined = "\(firstInitial)\(lastInitial)"
        return combined.isEmpty ? "FL" : combined
    }

    var preferredContactSummary: String {
        let value = preferredContactValue.trimmingCharacters(in: .whitespacesAndNewlines)
        return value.isEmpty ? preferredContactMethod.label : value
    }

    var preferredContactValue: String {
        switch preferredContactMethod {
        case .email:
            email
        case .phone:
            phone
        case .sns, .other:
            preferredContactDetail
        }
    }

    init(
        name: String,
        age: Int = 24,
        gender: GenderIdentity = .female,
        pronouns: PronounOption? = nil,
        sexuality: SexualityOption = .notListed,
        substanceUse: [SubstanceUseCategory: SubstanceUseAnswer] = AppContact.defaultSubstanceUse
    ) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let parts = trimmed.split(separator: " ", maxSplits: 1).map(String.init)
        self.firstName = parts.first ?? ""
        self.lastName = parts.count > 1 ? parts[1] : ""
        self.nickname = ""
        self.photoData = nil
        self.bio = ""
        self.phone = ""
        self.email = ""
        self.preferredContactMethod = .email
        self.preferredContactDetail = ""
        self.age = age
        self.gender = gender
        self.pronouns = pronouns ?? gender.defaultPronouns
        self.sexuality = sexuality
        self.substanceUse = substanceUse
        self.address = ""
        self.websiteURL = ""
        self.birthday = nil
        self.notes = ""
        self.useForFoFRecommendations = true
    }

    static let defaultSubstanceUse: [SubstanceUseCategory: SubstanceUseAnswer] = Dictionary(
        uniqueKeysWithValues: SubstanceUseCategory.allCases.map { ($0, .no) }
    )
}

private extension GenderIdentity {
    var defaultPronouns: PronounOption {
        switch self {
        case .male: .heHim
        case .female: .sheHer
        case .nonbinary: .theyThem
        }
    }
}

private extension String {
    var trimmedInitial: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
            .prefix(1)
            .uppercased()
    }
}
