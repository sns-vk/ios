import Foundation
import Observation

protocol ProfileCriteriaOption: CaseIterable, Identifiable, Hashable {
    var label: String { get }
}

enum AgeDisplay {
    static let bounds = 18...85

    static func label(for age: Int) -> String {
        age >= bounds.upperBound ? "\(bounds.upperBound)+" : "\(age)"
    }

    static func rangeLabel(min: Int, max: Int) -> String {
        "\(label(for: min))-\(label(for: max))"
    }
}

extension ProfileCriteriaOption {
    var id: Self { self }
}

enum GenderIdentity: String, ProfileCriteriaOption {
    case male
    case female
    case nonbinary

    var label: String {
        switch self {
        case .male: "Male"
        case .female: "Female"
        case .nonbinary: "Nonbinary"
        }
    }
}

enum PronounOption: String, ProfileCriteriaOption {
    case heHim = "he/him"
    case sheHer = "she/her"
    case theyThem = "they/them"
    case notListed = "not listed"

    var label: String {
        switch self {
        case .heHim, .sheHer, .theyThem: rawValue
        case .notListed: "Not listed"
        }
    }
}

enum SexualityOption: String, ProfileCriteriaOption {
    case straight
    case gay
    case lesbian
    case bisexual
    case notListed

    var label: String {
        switch self {
        case .straight: "Straight"
        case .gay: "Gay"
        case .lesbian: "Lesbian"
        case .bisexual: "Bisexual"
        case .notListed: "Not listed"
        }
    }
}

enum SubstanceUseCategory: String, ProfileCriteriaOption, Sendable {
    case vaping
    case smoking
    case marijuana
    case drinking
    case other

    var label: String {
        switch self {
        case .vaping: "Vaping"
        case .smoking: "Smoking"
        case .marijuana: "Marijuana"
        case .drinking: "Drinking"
        case .other: "Other"
        }
    }
}

enum SubstanceUseAnswer: String, ProfileCriteriaOption {
    case yes
    case sometimes
    case no

    var label: String {
        switch self {
        case .yes: "Yes"
        case .sometimes: "Sometimes"
        case .no: "No"
        }
    }
}

enum ProfileDisclosureField: Hashable, Sendable {
    case photo
    case firstName
    case lastName
    case nickname
    case age
    case gender
    case pronouns
    case sexuality
    case substanceUse(SubstanceUseCategory)
}

struct AvailabilityWindow: Identifiable, Hashable {
    let id: UUID
    var startTime: Date
    var endTime: Date

    init(id: UUID = UUID(), startTime: Date, endTime: Date) {
        self.id = id
        self.startTime = startTime
        self.endTime = endTime
    }

    var isValid: Bool {
        endTime > startTime
    }
}

struct WeeklyAvailabilityDay: Identifiable, Hashable {
    var date: Date
    var windows: [AvailabilityWindow]

    var id: Date { date }

    init(date: Date, windows: [AvailabilityWindow] = []) {
        self.date = date
        self.windows = windows
    }

    var hasValidWindow: Bool {
        windows.contains { $0.isValid }
    }
}

struct MatchCriteriaSnapshot: Hashable {
    var location: String
    var radiusMiles: Int
    var extendRadiusIfNeeded: Bool
    var preferredAgeMin: Int
    var preferredAgeMax: Int
    var preferredGenders: Set<GenderIdentity>
    var preferredSexualities: Set<SexualityOption>
    var acceptedSubstanceUse: [SubstanceUseCategory: SubstanceUseAnswer]
    var matchPolicy: MatchPolicy

    var locationSummary: String {
        location
    }

    var radiusSummary: String {
        extendRadiusIfNeeded ? "Within \(radiusMiles) mi, flexible" : "Within \(radiusMiles) mi"
    }

    var ageRangeSummary: String {
        AgeDisplay.rangeLabel(min: preferredAgeMin, max: preferredAgeMax)
    }

    var preferredGendersSummary: String {
        Self.summary(for: preferredGenders, emptyLabel: "None selected", allLabel: "Open to all")
    }

    var preferredSexualitiesSummary: String {
        Self.summary(for: preferredSexualities, emptyLabel: "None selected", allLabel: "Open to all")
    }

    var acceptedSubstanceUseSummary: String {
        Self.substanceUseSummary(for: acceptedSubstanceUse, emptyLabel: "None selected", allLabel: "Open to all")
    }

    private static func summary<Option: ProfileCriteriaOption>(
        for values: Set<Option>,
        emptyLabel: String,
        allLabel: String
    ) -> String {
        if values.isEmpty {
            return emptyLabel
        }

        let allOptions = Array(Option.allCases)
        if values.count == allOptions.count && allOptions.allSatisfy(values.contains) {
            return allLabel
        }

        return allOptions
            .filter(values.contains)
            .map(\.label)
            .joined(separator: ", ")
    }

    private static func substanceUseSummary(
        for values: [SubstanceUseCategory: SubstanceUseAnswer],
        emptyLabel: String,
        allLabel: String
    ) -> String {
        let allOptions = Array(SubstanceUseCategory.allCases)
        let answeredOptions = allOptions.filter { values[$0] != nil }
        guard !answeredOptions.isEmpty else { return emptyLabel }

        if allOptions.allSatisfy({ values[$0] == .yes }) {
            return allLabel
        }

        return answeredOptions
            .map { "\($0.label): \(values[$0, default: .no].label)" }
            .joined(separator: ", ")
    }
}

struct WeeklyBatchEnrollment: Identifiable, Hashable {
    let id: UUID
    var enrolledAt: Date
    var matchCriteria: MatchCriteriaSnapshot
    var availability: [WeeklyAvailabilityDay]

    init(
        id: UUID = UUID(),
        enrolledAt: Date,
        matchCriteria: MatchCriteriaSnapshot,
        availability: [WeeklyAvailabilityDay]
    ) {
        self.id = id
        self.enrolledAt = enrolledAt
        self.matchCriteria = matchCriteria
        self.availability = availability
    }
}

struct AvailabilityMinuteWindow: Identifiable, Hashable {
    let id: UUID
    var startMinute: Int
    var endMinute: Int
}

enum WeeklyAvailabilityGridRules {
    static let startMinute = 0
    static let endMinute = 24 * 60
    static let snapIntervalMinutes = 15
    static let minimumDurationMinutes = 30

    static func snap(_ minute: Int) -> Int {
        let snapped = Int((Double(minute) / Double(snapIntervalMinutes)).rounded()) * snapIntervalMinutes
        return min(max(snapped, startMinute), endMinute)
    }

    static func createWindowMinutes(
        anchorMinute: Int,
        currentMinute: Int,
        existingWindows: [AvailabilityMinuteWindow]
    ) -> AvailabilityMinuteWindow? {
        let anchor = snap(anchorMinute)
        let current = snap(currentMinute)
        let sortedWindows = existingWindows.sorted { $0.startMinute < $1.startMinute }

        if current >= anchor {
            let nextStart = sortedWindows
                .filter { $0.startMinute >= anchor }
                .map(\.startMinute)
                .min() ?? endMinute
            let end = min(max(current, anchor + minimumDurationMinutes), nextStart)
            guard end - anchor >= minimumDurationMinutes else { return nil }
            return AvailabilityMinuteWindow(id: UUID(), startMinute: anchor, endMinute: end)
        }

        let previousEnd = sortedWindows
            .filter { $0.endMinute <= anchor }
            .map(\.endMinute)
            .max() ?? startMinute
        let start = max(min(current, anchor - minimumDurationMinutes), previousEnd)
        guard anchor - start >= minimumDurationMinutes else { return nil }
        return AvailabilityMinuteWindow(id: UUID(), startMinute: start, endMinute: anchor)
    }

    static func resizeStartMinutes(
        currentMinute: Int,
        originalWindow: AvailabilityMinuteWindow,
        existingWindows: [AvailabilityMinuteWindow]
    ) -> AvailabilityMinuteWindow {
        let lowerBound = existingWindows
            .filter { $0.id != originalWindow.id && $0.endMinute <= originalWindow.endMinute }
            .map(\.endMinute)
            .max() ?? startMinute
        let upperBound = originalWindow.endMinute - minimumDurationMinutes
        let start = min(max(snap(currentMinute), lowerBound), upperBound)

        return AvailabilityMinuteWindow(
            id: originalWindow.id,
            startMinute: start,
            endMinute: originalWindow.endMinute
        )
    }

    static func resizeEndMinutes(
        currentMinute: Int,
        originalWindow: AvailabilityMinuteWindow,
        existingWindows: [AvailabilityMinuteWindow]
    ) -> AvailabilityMinuteWindow {
        let lowerBound = originalWindow.startMinute + minimumDurationMinutes
        let upperBound = existingWindows
            .filter { $0.id != originalWindow.id && $0.startMinute >= originalWindow.startMinute }
            .map(\.startMinute)
            .min() ?? endMinute
        let end = max(min(snap(currentMinute), upperBound), lowerBound)

        return AvailabilityMinuteWindow(
            id: originalWindow.id,
            startMinute: originalWindow.startMinute,
            endMinute: end
        )
    }

    static func moveWindowMinutes(
        proposedStartMinute: Int,
        originalWindow: AvailabilityMinuteWindow,
        existingWindows: [AvailabilityMinuteWindow]
    ) -> AvailabilityMinuteWindow {
        let duration = originalWindow.endMinute - originalWindow.startMinute
        let previousEnd = existingWindows
            .filter { $0.id != originalWindow.id && $0.endMinute <= originalWindow.startMinute }
            .map(\.endMinute)
            .max() ?? startMinute
        let nextStart = existingWindows
            .filter { $0.id != originalWindow.id && $0.startMinute >= originalWindow.endMinute }
            .map(\.startMinute)
            .min() ?? endMinute

        let lowerBound = previousEnd
        let upperBound = nextStart - duration
        let start = min(max(snap(proposedStartMinute), lowerBound), upperBound)

        return AvailabilityMinuteWindow(
            id: originalWindow.id,
            startMinute: start,
            endMinute: start + duration
        )
    }
}

enum WeeklyAvailabilityCalendar {
    static func configuredCalendar(from calendar: Calendar = .current) -> Calendar {
        var configuredCalendar = calendar
        configuredCalendar.firstWeekday = 2
        return configuredCalendar
    }

    static func currentWeekDates(containing date: Date = Date(), calendar: Calendar = .current) -> [Date] {
        let configuredCalendar = configuredCalendar(from: calendar)
        guard let weekInterval = configuredCalendar.dateInterval(of: .weekOfYear, for: date) else {
            return []
        }

        return (0..<7).compactMap {
            configuredCalendar.date(byAdding: .day, value: $0, to: weekInterval.start)
        }
    }

    static func currentWeekDateRange(containing date: Date = Date(), calendar: Calendar = .current) -> Range<Date>? {
        let dates = currentWeekDates(containing: date, calendar: calendar)
        guard let start = dates.first else { return nil }

        let configuredCalendar = configuredCalendar(from: calendar)
        let end = configuredCalendar.date(byAdding: .day, value: 7, to: start) ?? start
        return start..<end
    }

    static func nextWeekDates(containing date: Date = Date(), calendar: Calendar = .current) -> [Date] {
        let configuredCalendar = configuredCalendar(from: calendar)
        guard let weekStart = currentWeekDates(containing: date, calendar: configuredCalendar).first,
              let nextWeekStart = configuredCalendar.date(byAdding: .day, value: 7, to: weekStart) else {
            return []
        }

        return (0..<7).compactMap {
            configuredCalendar.date(byAdding: .day, value: $0, to: nextWeekStart)
        }
    }

    static func nextWeekDateRange(containing date: Date = Date(), calendar: Calendar = .current) -> Range<Date>? {
        let dates = nextWeekDates(containing: date, calendar: calendar)
        guard let start = dates.first else { return nil }

        let configuredCalendar = configuredCalendar(from: calendar)
        let end = configuredCalendar.date(byAdding: .day, value: 7, to: start) ?? start
        return start..<end
    }

    static func minuteOfDay(for date: Date, calendar: Calendar = .current) -> Int {
        let configuredCalendar = configuredCalendar(from: calendar)
        let components = configuredCalendar.dateComponents([.hour, .minute], from: date)
        return ((components.hour ?? 0) * 60) + (components.minute ?? 0)
    }

    static func minuteOffset(from day: Date, to date: Date, calendar: Calendar = .current) -> Int {
        let configuredCalendar = configuredCalendar(from: calendar)
        let startOfDay = configuredCalendar.startOfDay(for: day)
        let rawMinute = Int((date.timeIntervalSince(startOfDay) / 60).rounded())
        return min(max(rawMinute, WeeklyAvailabilityGridRules.startMinute), WeeklyAvailabilityGridRules.endMinute)
    }

    static func date(on day: Date, minuteOfDay: Int, calendar: Calendar = .current) -> Date {
        let configuredCalendar = configuredCalendar(from: calendar)
        let startOfDay = configuredCalendar.startOfDay(for: day)
        return configuredCalendar.date(byAdding: .minute, value: minuteOfDay, to: startOfDay) ?? startOfDay
    }
}

@Observable
final class AppState {
    var myCard: AppContact
    var contacts: [AppContact]
    var groups: [AppGroup]
    var age: Int
    var gender: GenderIdentity
    var pronouns: PronounOption
    var sexuality: SexualityOption
    var substanceUse: [SubstanceUseCategory: SubstanceUseAnswer]
    var sharedContactFields: Set<ProfileDisclosureField>
    var sharedProfileFields: Set<ProfileDisclosureField>
    var preferredGenders: Set<GenderIdentity> {
        didSet { markMatchCriteriaEditedIfChanged(from: oldValue, to: preferredGenders) }
    }
    var preferredSexualities: Set<SexualityOption> {
        didSet { markMatchCriteriaEditedIfChanged(from: oldValue, to: preferredSexualities) }
    }
    var acceptedSubstanceUse: [SubstanceUseCategory: SubstanceUseAnswer] {
        didSet { markMatchCriteriaEditedIfChanged(from: oldValue, to: acceptedSubstanceUse) }
    }
    var preferredAgeMin: Int {
        didSet { markMatchCriteriaEditedIfChanged(from: oldValue, to: preferredAgeMin) }
    }
    var preferredAgeMax: Int {
        didSet { markMatchCriteriaEditedIfChanged(from: oldValue, to: preferredAgeMax) }
    }
    var matchPolicy: MatchPolicy {
        didSet { markMatchCriteriaEditedIfChanged(from: oldValue, to: matchPolicy) }
    }
    var matchingLocation: String {
        didSet { markMatchCriteriaEditedIfChanged(from: oldValue, to: matchingLocation) }
    }
    var matchingRadiusMiles: Int {
        didSet { markMatchCriteriaEditedIfChanged(from: oldValue, to: matchingRadiusMiles) }
    }
    var extendRadiusIfNeeded: Bool {
        didSet { markMatchCriteriaEditedIfChanged(from: oldValue, to: extendRadiusIfNeeded) }
    }
    var matchCriteriaUpdatedAt: Date
    var weeklyAvailability: [WeeklyAvailabilityDay]
    var weeklyBatchEnrollment: WeeklyBatchEnrollment?

    var fofSourceCount: Int {
        contacts.filter(\.useForFoFRecommendations).count
    }

    init(
        myCard: AppContact,
        contacts: [AppContact],
        groups: [AppGroup],
        age: Int = 24,
        gender: GenderIdentity = .female,
        pronouns: PronounOption = .sheHer,
        sexuality: SexualityOption = .notListed,
        substanceUse: [SubstanceUseCategory: SubstanceUseAnswer] = [:],
        sharedContactFields: Set<ProfileDisclosureField>,
        sharedProfileFields: Set<ProfileDisclosureField>,
        preferredGenders: Set<GenderIdentity> = Set(GenderIdentity.allCases),
        preferredSexualities: Set<SexualityOption> = Set(SexualityOption.allCases),
        acceptedSubstanceUse: [SubstanceUseCategory: SubstanceUseAnswer] = Dictionary(
            uniqueKeysWithValues: SubstanceUseCategory.allCases.map { ($0, .yes) }
        ),
        preferredAgeMin: Int = 21,
        preferredAgeMax: Int = 27,
        matchPolicy: MatchPolicy = .mutualsOnly,
        matchingLocation: String = "SoMa",
        matchingRadiusMiles: Int = 10,
        extendRadiusIfNeeded: Bool = false,
        matchCriteriaUpdatedAt: Date = Date(),
        weeklyAvailability: [WeeklyAvailabilityDay] = [],
        weeklyBatchEnrollment: WeeklyBatchEnrollment? = nil
    ) {
        self.myCard = myCard
        self.contacts = contacts
        self.groups = groups
        self.age = age
        self.gender = gender
        self.pronouns = pronouns
        self.sexuality = sexuality
        self.substanceUse = substanceUse
        self.sharedContactFields = sharedContactFields
        self.sharedProfileFields = sharedProfileFields
        self.preferredGenders = preferredGenders
        self.preferredSexualities = preferredSexualities
        self.acceptedSubstanceUse = acceptedSubstanceUse
        self.preferredAgeMin = preferredAgeMin
        self.preferredAgeMax = preferredAgeMax
        self.matchPolicy = matchPolicy
        self.matchingLocation = matchingLocation
        self.matchingRadiusMiles = matchingRadiusMiles
        self.extendRadiusIfNeeded = extendRadiusIfNeeded
        self.matchCriteriaUpdatedAt = matchCriteriaUpdatedAt
        self.weeklyAvailability = weeklyAvailability
        self.weeklyBatchEnrollment = weeklyBatchEnrollment
    }

    static func mock() -> AppState {
        AppState(
            myCard: {
                var card = AppContact(name: "Kevin Jin")
                card.nickname = "KEVWJIN"
                return card
            }(),
            contacts: MockData.contacts,
            groups: MockData.groups,
            gender: .male,
            pronouns: .heHim,
            sexuality: .straight,
            sharedContactFields: [],
            sharedProfileFields: []
        )
    }

    func add(_ contact: AppContact, toGroupAt groupIndex: Int) {
        guard groups.indices.contains(groupIndex), !groups[groupIndex].members.contains(where: { $0.id == contact.id }) else { return }
        groups[groupIndex].members.append(contact)
    }

    func removeContact(_ contactID: AppContact.ID, fromGroupAt groupIndex: Int) {
        guard groups.indices.contains(groupIndex) else { return }
        groups[groupIndex].members.removeAll { $0.id == contactID }
    }

    private func markMatchCriteriaEditedIfChanged<Value: Equatable>(from oldValue: Value, to newValue: Value) {
        guard oldValue != newValue else { return }
        matchCriteriaUpdatedAt = Date()
    }
}

extension AppState {
    var hasCompleteWeeklyAvailability: Bool {
        weeklyAvailability.contains { $0.hasValidWindow }
    }

    var isEnrolledInWeeklyBatch: Bool {
        weeklyBatchEnrollment != nil
    }

    var currentMatchCriteriaSnapshot: MatchCriteriaSnapshot {
        MatchCriteriaSnapshot(
            location: matchingLocation,
            radiusMiles: matchingRadiusMiles,
            extendRadiusIfNeeded: extendRadiusIfNeeded,
            preferredAgeMin: preferredAgeMin,
            preferredAgeMax: preferredAgeMax,
            preferredGenders: preferredGenders,
            preferredSexualities: preferredSexualities,
            acceptedSubstanceUse: acceptedSubstanceUse,
            matchPolicy: matchPolicy
        )
    }

    var displayedWeeklyBatchCriteria: MatchCriteriaSnapshot {
        weeklyBatchEnrollment?.matchCriteria ?? currentMatchCriteriaSnapshot
    }

    var displayedWeeklyAvailabilitySummary: String {
        guard let enrollment = weeklyBatchEnrollment else {
            return weeklyAvailabilitySummary
        }

        return Self.weeklyAvailabilitySummary(for: enrollment.availability)
    }

    var matchCriteriaEditedSummary: String {
        Self.matchCriteriaEditedSummary(updatedAt: matchCriteriaUpdatedAt)
    }

    static func matchCriteriaEditedSummary(
        updatedAt: Date,
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> String {
        let configuredCalendar = WeeklyAvailabilityCalendar.configuredCalendar(from: calendar)
        let updatedDay = configuredCalendar.startOfDay(for: updatedAt)
        let currentDay = configuredCalendar.startOfDay(for: now)
        let dayCount = max(
            0,
            configuredCalendar.dateComponents([.day], from: updatedDay, to: currentDay).day ?? 0
        )

        switch dayCount {
        case 0:
            return "Edited today"
        case 1:
            return "Edited yesterday"
        case 2...6:
            return "Edited \(dayCount) days ago"
        case 7...13:
            return "Edited last week"
        case 14...29:
            return "Edited \(dayCount / 7) weeks ago"
        default:
            let monthCount = max(
                0,
                configuredCalendar.dateComponents([.month], from: updatedDay, to: currentDay).month ?? 0
            )

            switch monthCount {
            case 0:
                return "Edited \(dayCount / 7) weeks ago"
            case 1:
                return "Edited last month"
            case 2...11:
                return "Edited \(monthCount) months ago"
            case 12...23:
                return "Edited last year"
            default:
                return "Edited \(monthCount / 12) years ago"
            }
        }
    }

    func enrollInWeeklyBatch(now: Date = Date()) {
        weeklyBatchEnrollment = WeeklyBatchEnrollment(
            enrolledAt: now,
            matchCriteria: currentMatchCriteriaSnapshot,
            availability: weeklyAvailability
        )
    }

    var weeklyAvailabilitySummary: String {
        Self.weeklyAvailabilitySummary(for: weeklyAvailability)
    }

    private static func weeklyAvailabilitySummary(for availability: [WeeklyAvailabilityDay]) -> String {
        let validWindowCount = availability.reduce(0) { total, day in
            total + day.windows.filter(\.isValid).count
        }

        switch validWindowCount {
        case 0:
            return "No availability"
        case 1:
            return "1 time window"
        default:
            return "\(validWindowCount) time windows"
        }
    }

    func setWeeklyAvailabilityDates(_ dates: Set<DateComponents>, calendar: Calendar = .current) {
        let configuredCalendar = WeeklyAvailabilityCalendar.configuredCalendar(from: calendar)
        let selectedDates = dates.compactMap { components in
            configuredCalendar.date(from: components).map { configuredCalendar.startOfDay(for: $0) }
        }

        weeklyAvailability = selectedDates
            .sorted()
            .map { selectedDate in
                weeklyAvailability.first { configuredCalendar.isDate($0.date, inSameDayAs: selectedDate) }
                    ?? WeeklyAvailabilityDay(date: selectedDate)
            }
    }

    func addAvailabilityWindow(on date: Date, calendar: Calendar = .current) {
        let configuredCalendar = WeeklyAvailabilityCalendar.configuredCalendar(from: calendar)
        let day = configuredCalendar.startOfDay(for: date)
        let startTime = configuredCalendar.date(bySettingHour: 18, minute: 0, second: 0, of: day) ?? day
        let endTime = configuredCalendar.date(bySettingHour: 20, minute: 0, second: 0, of: day) ?? startTime
        let window = AvailabilityWindow(startTime: startTime, endTime: endTime)
        var nextAvailability = weeklyAvailability

        if let index = nextAvailability.firstIndex(where: { configuredCalendar.isDate($0.date, inSameDayAs: day) }) {
            var availabilityDay = nextAvailability[index]
            availabilityDay.windows.append(window)
            availabilityDay.windows.sort { $0.startTime < $1.startTime }
            nextAvailability[index] = availabilityDay
        } else {
            nextAvailability.append(WeeklyAvailabilityDay(date: day, windows: [window]))
        }

        nextAvailability.sort { $0.date < $1.date }
        weeklyAvailability = nextAvailability
    }

    func removeAvailabilityWindow(_ windowID: AvailabilityWindow.ID, on date: Date, calendar: Calendar = .current) {
        let configuredCalendar = WeeklyAvailabilityCalendar.configuredCalendar(from: calendar)
        var nextAvailability = weeklyAvailability
        guard let index = nextAvailability.firstIndex(where: { configuredCalendar.isDate($0.date, inSameDayAs: date) }) else {
            return
        }

        var availabilityDay = nextAvailability[index]
        availabilityDay.windows.removeAll { $0.id == windowID }
        if availabilityDay.windows.isEmpty {
            nextAvailability.remove(at: index)
        } else {
            nextAvailability[index] = availabilityDay
        }
        weeklyAvailability = nextAvailability
    }

    func availabilityWindows(on date: Date, calendar: Calendar = .current) -> [AvailabilityWindow] {
        let configuredCalendar = WeeklyAvailabilityCalendar.configuredCalendar(from: calendar)
        return weeklyAvailability
            .first { configuredCalendar.isDate($0.date, inSameDayAs: date) }?
            .windows
            .sorted { $0.startTime < $1.startTime } ?? []
    }

    func availabilityMinuteWindows(on date: Date, calendar: Calendar = .current) -> [AvailabilityMinuteWindow] {
        let configuredCalendar = WeeklyAvailabilityCalendar.configuredCalendar(from: calendar)
        let day = configuredCalendar.startOfDay(for: date)
        return availabilityWindows(on: date, calendar: calendar).map {
            AvailabilityMinuteWindow(
                id: $0.id,
                startMinute: WeeklyAvailabilityCalendar.minuteOffset(from: day, to: $0.startTime, calendar: configuredCalendar),
                endMinute: WeeklyAvailabilityCalendar.minuteOffset(from: day, to: $0.endTime, calendar: configuredCalendar)
            )
        }
    }

    @discardableResult
    func upsertAvailabilityWindow(
        _ minuteWindow: AvailabilityMinuteWindow,
        on date: Date,
        calendar: Calendar = .current
    ) -> AvailabilityWindow {
        let configuredCalendar = WeeklyAvailabilityCalendar.configuredCalendar(from: calendar)
        let day = configuredCalendar.startOfDay(for: date)
        let window = AvailabilityWindow(
            id: minuteWindow.id,
            startTime: WeeklyAvailabilityCalendar.date(on: day, minuteOfDay: minuteWindow.startMinute, calendar: configuredCalendar),
            endTime: WeeklyAvailabilityCalendar.date(on: day, minuteOfDay: minuteWindow.endMinute, calendar: configuredCalendar)
        )

        var nextAvailability = weeklyAvailability
        if let dayIndex = nextAvailability.firstIndex(where: { configuredCalendar.isDate($0.date, inSameDayAs: day) }) {
            var availabilityDay = nextAvailability[dayIndex]
            if let windowIndex = availabilityDay.windows.firstIndex(where: { $0.id == window.id }) {
                availabilityDay.windows[windowIndex] = window
            } else {
                availabilityDay.windows.append(window)
            }
            availabilityDay.windows.sort { $0.startTime < $1.startTime }
            nextAvailability[dayIndex] = availabilityDay
        } else {
            nextAvailability.append(WeeklyAvailabilityDay(date: day, windows: [window]))
        }

        nextAvailability.sort { $0.date < $1.date }
        weeklyAvailability = nextAvailability

        return window
    }

    var profileSummary: String {
        "\(AgeDisplay.label(for: age)), \(gender.label)"
    }

    var substanceUseSummary: String {
        Self.substanceUseSummary(
            for: substanceUse,
            emptyLabel: "None listed",
            allLabel: "All listed"
        )
    }

    var preferredGendersSummary: String {
        Self.summary(
            for: preferredGenders,
            emptyLabel: "None selected",
            allLabel: "Open to all"
        )
    }

    var preferredSexualitiesSummary: String {
        Self.summary(
            for: preferredSexualities,
            emptyLabel: "None selected",
            allLabel: "Open to all"
        )
    }

    var acceptedSubstanceUseSummary: String {
        Self.substanceUseSummary(
            for: acceptedSubstanceUse,
            emptyLabel: "None selected",
            allLabel: "Open to all"
        )
    }

    func substanceUseAnswer(for category: SubstanceUseCategory) -> SubstanceUseAnswer {
        substanceUse[category, default: .no]
    }

    func acceptedSubstanceUseAnswer(for category: SubstanceUseCategory) -> SubstanceUseAnswer {
        acceptedSubstanceUse[category, default: .yes]
    }

    private static func summary<Option: ProfileCriteriaOption>(
        for values: Set<Option>,
        emptyLabel: String,
        allLabel: String
    ) -> String {
        if values.isEmpty {
            return emptyLabel
        }

        let allOptions = Array(Option.allCases)
        if values.count == allOptions.count && allOptions.allSatisfy(values.contains) {
            return allLabel
        }

        return allOptions
            .filter(values.contains)
            .map(\.label)
            .joined(separator: ", ")
    }

    private static func substanceUseSummary(
        for values: [SubstanceUseCategory: SubstanceUseAnswer],
        emptyLabel: String,
        allLabel: String
    ) -> String {
        let allOptions = Array(SubstanceUseCategory.allCases)
        let answeredOptions = allOptions.filter { values[$0] != nil }
        guard !answeredOptions.isEmpty else { return emptyLabel }

        if allOptions.allSatisfy({ values[$0] == .yes }) {
            return allLabel
        }

        return answeredOptions
            .map { "\($0.label): \(values[$0, default: .no].label)" }
            .joined(separator: ", ")
    }
}
