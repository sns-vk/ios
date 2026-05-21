//
//  snsTests.swift
//  snsTests
//
//  Created by Kevin Jin on 3/27/26.
//

import Foundation
import Testing
@testable import sns

struct snsTests {

    @Test func contactNameParsesFirstAndLastName() {
        let contact = AppContact(name: "Ava Thompson")

        #expect(contact.firstName == "Ava")
        #expect(contact.lastName == "Thompson")
        #expect(contact.name == "Ava Thompson")
    }

    @Test func blankContactUsesFallbackName() {
        let contact = AppContact(name: "   ")

        #expect(contact.firstName.isEmpty)
        #expect(contact.lastName.isEmpty)
        #expect(contact.name == "Unnamed Contact")
    }

    @Test func contactInitialsUseNameOrDefaultFallback() {
        #expect(AppContact(name: "Ava Thompson").initials == "AT")
        #expect(AppContact(name: "Ava").initials == "A")
        #expect(AppContact(name: "   ").initials == "FL")
    }

    @Test func preferredContactSummaryUsesSelectedMethodValue() {
        var contact = AppContact(name: "Ava Thompson")

        #expect(contact.preferredContactSummary == "Email")

        contact.email = "ava@example.com"
        #expect(contact.preferredContactSummary == "ava@example.com")

        contact.preferredContactMethod = .phone
        contact.phone = "555-0100"
        #expect(contact.preferredContactSummary == "555-0100")

        contact.preferredContactMethod = .sns
        contact.preferredContactDetail = "@ava"
        #expect(contact.preferredContactSummary == "@ava")

        contact.preferredContactMethod = .other
        contact.preferredContactDetail = ""
        #expect(contact.preferredContactSummary == "Other")
    }

    @Test func appStateCountsEligibleContacts() {
        var enabledContact = AppContact(name: "Ava Thompson")
        var disabledContact = AppContact(name: "Noah Kim")
        disabledContact.useForFoFRecommendations = false

        let state = AppState(
            myCard: AppContact(name: "My Name"),
            contacts: [enabledContact, disabledContact],
            groups: [],
            sharedProfileFields: []
        )

        #expect(state.fofSourceCount == 1)

        enabledContact.useForFoFRecommendations = false
        state.contacts = [enabledContact, disabledContact]

        #expect(state.fofSourceCount == 0)
    }

    @Test func appStateAddsAndRemovesGroupMembership() {
        let contact = AppContact(name: "Ava Thompson")
        let state = AppState(
            myCard: AppContact(name: "My Name"),
            contacts: [contact],
            groups: [AppGroup(name: "Study Group", members: [])],
            sharedProfileFields: []
        )

        state.add(contact, toGroupAt: 0)

        #expect(state.groups[0].members.map(\.id) == [contact.id])

        state.add(contact, toGroupAt: 0)

        #expect(state.groups[0].members.count == 1)

        state.removeContact(contact.id, fromGroupAt: 0)

        #expect(state.groups[0].members.isEmpty)
    }

    @Test func appStateUsesDefaultMatchingCriteria() {
        let state = AppState.mock()

        #expect(state.matchingLocation == "SoMa")
        #expect(state.matchingRadiusMiles == 10)
        #expect(state.extendRadiusIfNeeded == false)
        #expect(state.matchPolicy == .mutualsOnly)
    }

    @Test func appStateUsesDefaultProfileCriteria() {
        let state = AppState.mock()

        #expect(state.gender == .female)
        #expect(state.pronouns == .sheHer)
        #expect(state.sexuality == .notListed)
        #expect(state.substanceUse.isEmpty)
        #expect(state.profileSummary == "24, Female")
        #expect(state.substanceUseSummary == "None listed")
    }

    @Test func appStateDefaultsMatchCriteriaToOpenToAll() {
        let state = AppState.mock()

        #expect(state.preferredGenders == Set(GenderIdentity.allCases))
        #expect(state.preferredSexualities == Set(SexualityOption.allCases))
        #expect(SubstanceUseCategory.allCases.allSatisfy { state.acceptedSubstanceUse[$0] == .yes })
        #expect(state.preferredGendersSummary == "Open to all")
        #expect(state.preferredSexualitiesSummary == "Open to all")
        #expect(state.acceptedSubstanceUseSummary == "Open to all")
    }

    @Test func appStateSummarizesPartialCriteriaSelections() {
        let state = AppState.mock()

        state.substanceUse = [.drinking: .yes, .marijuana: .sometimes]
        state.preferredGenders = [.female, .nonbinary]
        state.preferredSexualities = []
        state.acceptedSubstanceUse = [.drinking: .yes]

        #expect(state.substanceUseSummary == "Marijuana: Sometimes, Drinking: Yes")
        #expect(state.preferredGendersSummary == "Female, Nonbinary")
        #expect(state.preferredSexualitiesSummary == "None selected")
        #expect(state.acceptedSubstanceUseSummary == "Drinking: Yes")
    }

    @Test func matchCriteriaEditedSummaryUsesRelativeLabels() {
        let calendar = testCalendar()
        let now = testDate(year: 2026, month: 5, day: 31, hour: 12, calendar: calendar)

        #expect(AppState.matchCriteriaEditedSummary(
            updatedAt: testDate(year: 2026, month: 5, day: 31, hour: 9, calendar: calendar),
            now: now,
            calendar: calendar
        ) == "Edited today")
        #expect(AppState.matchCriteriaEditedSummary(
            updatedAt: testDate(year: 2026, month: 5, day: 30, hour: 9, calendar: calendar),
            now: now,
            calendar: calendar
        ) == "Edited yesterday")
        #expect(AppState.matchCriteriaEditedSummary(
            updatedAt: testDate(year: 2026, month: 5, day: 29, hour: 9, calendar: calendar),
            now: now,
            calendar: calendar
        ) == "Edited 2 days ago")
        #expect(AppState.matchCriteriaEditedSummary(
            updatedAt: testDate(year: 2026, month: 5, day: 24, hour: 9, calendar: calendar),
            now: now,
            calendar: calendar
        ) == "Edited last week")
        #expect(AppState.matchCriteriaEditedSummary(
            updatedAt: testDate(year: 2026, month: 5, day: 17, hour: 9, calendar: calendar),
            now: now,
            calendar: calendar
        ) == "Edited 2 weeks ago")
        #expect(AppState.matchCriteriaEditedSummary(
            updatedAt: testDate(year: 2026, month: 4, day: 30, hour: 9, calendar: calendar),
            now: now,
            calendar: calendar
        ) == "Edited last month")
        #expect(AppState.matchCriteriaEditedSummary(
            updatedAt: testDate(year: 2026, month: 3, day: 31, hour: 9, calendar: calendar),
            now: now,
            calendar: calendar
        ) == "Edited 2 months ago")
        #expect(AppState.matchCriteriaEditedSummary(
            updatedAt: testDate(year: 2025, month: 5, day: 31, hour: 9, calendar: calendar),
            now: now,
            calendar: calendar
        ) == "Edited last year")
        #expect(AppState.matchCriteriaEditedSummary(
            updatedAt: testDate(year: 2024, month: 5, day: 31, hour: 9, calendar: calendar),
            now: now,
            calendar: calendar
        ) == "Edited 2 years ago")
    }

    @Test func matchCriteriaEditsRefreshTimestamp() {
        let calendar = testCalendar()
        let staleDate = testDate(year: 2020, month: 1, day: 1, hour: 9, calendar: calendar)
        let state = AppState(
            myCard: AppContact(name: "My Name"),
            contacts: [],
            groups: [],
            sharedProfileFields: [],
            matchCriteriaUpdatedAt: staleDate
        )

        func expectRefresh(_ edit: () -> Void) {
            state.matchCriteriaUpdatedAt = staleDate
            edit()
            #expect(state.matchCriteriaUpdatedAt > staleDate)
        }

        expectRefresh { state.matchingLocation = "Mission" }
        expectRefresh { state.matchingRadiusMiles = 20 }
        expectRefresh { state.extendRadiusIfNeeded = true }
        expectRefresh { state.preferredAgeMin = 22 }
        expectRefresh { state.preferredAgeMax = 31 }
        expectRefresh { state.preferredGenders = [.female] }
        expectRefresh { state.preferredSexualities = [.bisexual] }
        expectRefresh { state.acceptedSubstanceUse = [.drinking: .yes] }
        expectRefresh { state.matchPolicy = .anyEligibleMatch }
    }

    @Test func appStateUpdatesMatchingRadius() {
        let state = AppState.mock()

        state.matchingRadiusMiles = 25

        #expect(state.matchingRadiusMiles == 25)
    }

    @Test func appStateUpdatesRadiusFlexibility() {
        let state = AppState.mock()

        state.extendRadiusIfNeeded = true

        #expect(state.extendRadiusIfNeeded == true)
    }

    @Test func weeklyAvailabilityDefaultsToIncomplete() {
        let state = AppState.mock()

        #expect(state.weeklyAvailability.isEmpty)
        #expect(!state.hasCompleteWeeklyAvailability)
        #expect(state.weeklyAvailabilitySummary == "No availability")
    }

    @Test func weeklyAvailabilitySelectedDayWithoutWindowDoesNotUnlockEnrollment() {
        let state = AppState.mock()
        let calendar = testCalendar()
        let date = testDate(year: 2026, month: 4, day: 30, hour: 12, calendar: calendar)
        let components = calendar.dateComponents([.calendar, .era, .year, .month, .day], from: date)

        state.setWeeklyAvailabilityDates([components], calendar: calendar)

        #expect(state.weeklyAvailability.count == 1)
        #expect(state.weeklyAvailability[0].windows.isEmpty)
        #expect(!state.hasCompleteWeeklyAvailability)
    }

    @Test func weeklyAvailabilityInvalidWindowDoesNotUnlockEnrollment() {
        let state = AppState.mock()
        let calendar = testCalendar()
        let startTime = testDate(year: 2026, month: 4, day: 30, hour: 18, calendar: calendar)
        let endTime = testDate(year: 2026, month: 4, day: 30, hour: 18, calendar: calendar)

        state.weeklyAvailability = [
            WeeklyAvailabilityDay(date: startTime, windows: [
                AvailabilityWindow(startTime: startTime, endTime: endTime)
            ])
        ]

        #expect(!state.hasCompleteWeeklyAvailability)
        #expect(state.weeklyAvailabilitySummary == "No availability")
    }

    @Test func weeklyAvailabilityValidWindowUnlocksEnrollment() {
        let state = AppState.mock()
        let calendar = testCalendar()
        let day = testDate(year: 2026, month: 4, day: 30, hour: 12, calendar: calendar)

        state.weeklyAvailability = [WeeklyAvailabilityDay(date: day)]
        state.addAvailabilityWindow(on: day, calendar: calendar)

        #expect(state.hasCompleteWeeklyAvailability)
        #expect(state.weeklyAvailabilitySummary == "1 time window")
    }

    @Test func weeklyBatchEnrollmentCapturesCriteriaAndAvailabilitySnapshot() {
        let state = AppState.mock()
        let calendar = testCalendar()
        let day = testDate(year: 2026, month: 4, day: 30, hour: 12, calendar: calendar)
        let enrolledAt = testDate(year: 2026, month: 5, day: 1, hour: 9, calendar: calendar)

        state.matchingLocation = "Hayes Valley"
        state.matchingRadiusMiles = 20
        state.extendRadiusIfNeeded = true
        state.preferredAgeMin = 23
        state.preferredAgeMax = 31
        state.preferredGenders = [.female, .nonbinary]
        state.preferredSexualities = [.bisexual]
        state.acceptedSubstanceUse = [.drinking: .yes]
        state.matchPolicy = .anyEligibleMatchIfNoMutuals
        state.weeklyAvailability = [WeeklyAvailabilityDay(date: day)]
        state.addAvailabilityWindow(on: day, calendar: calendar)

        state.enrollInWeeklyBatch(now: enrolledAt)

        #expect(state.isEnrolledInWeeklyBatch)
        #expect(state.weeklyBatchEnrollment?.enrolledAt == enrolledAt)
        #expect(state.weeklyBatchEnrollment?.availability == state.weeklyAvailability)
        #expect(state.weeklyBatchEnrollment?.matchCriteria.location == "Hayes Valley")
        #expect(state.weeklyBatchEnrollment?.matchCriteria.radiusMiles == 20)
        #expect(state.weeklyBatchEnrollment?.matchCriteria.extendRadiusIfNeeded == true)
        #expect(state.weeklyBatchEnrollment?.matchCriteria.preferredAgeMin == 23)
        #expect(state.weeklyBatchEnrollment?.matchCriteria.preferredAgeMax == 31)
        #expect(state.weeklyBatchEnrollment?.matchCriteria.preferredGenders == Set([.female, .nonbinary]))
        #expect(state.weeklyBatchEnrollment?.matchCriteria.preferredSexualities == Set([.bisexual]))
        #expect(state.weeklyBatchEnrollment?.matchCriteria.acceptedSubstanceUse == [.drinking: .yes])
        #expect(state.weeklyBatchEnrollment?.matchCriteria.matchPolicy == .anyEligibleMatchIfNoMutuals)
        #expect(state.displayedWeeklyAvailabilitySummary == "1 time window")
    }

    @Test func weeklyBatchEnrollmentSnapshotDoesNotChangeWithNextWeekCriteriaEdits() {
        let state = AppState.mock()
        let calendar = testCalendar()
        let day = testDate(year: 2026, month: 4, day: 30, hour: 12, calendar: calendar)

        state.weeklyAvailability = [WeeklyAvailabilityDay(date: day)]
        state.addAvailabilityWindow(on: day, calendar: calendar)
        state.enrollInWeeklyBatch()

        state.matchingLocation = "Mission"
        state.matchingRadiusMiles = 30
        state.acceptedSubstanceUse = [.drinking: .yes]
        state.matchPolicy = .anyEligibleMatch
        state.weeklyAvailability.removeAll()

        #expect(state.currentMatchCriteriaSnapshot.location == "Mission")
        #expect(state.currentMatchCriteriaSnapshot.radiusMiles == 30)
        #expect(state.currentMatchCriteriaSnapshot.acceptedSubstanceUse == [.drinking: .yes])
        #expect(state.weeklyBatchEnrollment?.matchCriteria.location == "SoMa")
        #expect(state.weeklyBatchEnrollment?.matchCriteria.radiusMiles == 10)
        #expect(SubstanceUseCategory.allCases.allSatisfy { state.weeklyBatchEnrollment?.matchCriteria.acceptedSubstanceUse[$0] == .yes })
        #expect(state.displayedWeeklyBatchCriteria == state.weeklyBatchEnrollment!.matchCriteria)
        #expect(state.weeklyAvailabilitySummary == "No availability")
        #expect(state.displayedWeeklyAvailabilitySummary == "1 time window")
    }

    @Test func weeklyAvailabilitySupportsMultipleWindowsPerDay() {
        let state = AppState.mock()
        let calendar = testCalendar()
        let day = testDate(year: 2026, month: 4, day: 30, hour: 12, calendar: calendar)

        state.weeklyAvailability = [WeeklyAvailabilityDay(date: day)]
        state.addAvailabilityWindow(on: day, calendar: calendar)
        state.addAvailabilityWindow(on: day, calendar: calendar)

        #expect(state.weeklyAvailability[0].windows.count == 2)
        #expect(state.hasCompleteWeeklyAvailability)
        #expect(state.weeklyAvailabilitySummary == "2 time windows")
    }

    @Test func weeklyAvailabilityCalendarReturnsMondayThroughSunday() {
        let calendar = testCalendar()
        let thursday = testDate(year: 2026, month: 4, day: 30, hour: 12, calendar: calendar)
        let weekDates = WeeklyAvailabilityCalendar.currentWeekDates(containing: thursday, calendar: calendar)
        let weekdays = weekDates.map { WeeklyAvailabilityCalendar.configuredCalendar(from: calendar).component(.weekday, from: $0) }

        #expect(weekDates.count == 7)
        #expect(weekdays == [2, 3, 4, 5, 6, 7, 1])
    }

    @Test func weeklyAvailabilityCalendarReturnsNextMondayThroughSunday() {
        let calendar = testCalendar()
        let thursday = testDate(year: 2026, month: 4, day: 30, hour: 12, calendar: calendar)
        let weekDates = WeeklyAvailabilityCalendar.nextWeekDates(containing: thursday, calendar: calendar)
        let days = weekDates.map { calendar.component(.day, from: $0) }
        let weekdays = weekDates.map { WeeklyAvailabilityCalendar.configuredCalendar(from: calendar).component(.weekday, from: $0) }

        #expect(weekDates.count == 7)
        #expect(days == [4, 5, 6, 7, 8, 9, 10])
        #expect(weekdays == [2, 3, 4, 5, 6, 7, 1])
    }

    @Test func weeklyAvailabilityGridSnapsToFifteenMinutes() {
        #expect(WeeklyAvailabilityGridRules.snap(7 * 60 + 7) == 7 * 60)
        #expect(WeeklyAvailabilityGridRules.snap(7 * 60 + 8) == 7 * 60 + 15)
        #expect(WeeklyAvailabilityGridRules.snap(-15) == WeeklyAvailabilityGridRules.startMinute)
        #expect(WeeklyAvailabilityGridRules.snap(25 * 60) == WeeklyAvailabilityGridRules.endMinute)
    }

    @Test func weeklyAvailabilityGridCreatesWindowWithMinimumDuration() {
        let window = WeeklyAvailabilityGridRules.createWindowMinutes(
            anchorMinute: 7 * 60,
            currentMinute: 7 * 60 + 5,
            existingWindows: []
        )

        #expect(window?.startMinute == 7 * 60)
        #expect(window?.endMinute == 7 * 60 + 15)
    }

    @Test func weeklyAvailabilityGridClampsToFullDay() {
        let startWindow = WeeklyAvailabilityGridRules.createWindowMinutes(
            anchorMinute: -30,
            currentMinute: 5,
            existingWindows: []
        )
        let endWindow = WeeklyAvailabilityGridRules.createWindowMinutes(
            anchorMinute: 24 * 60 - 10,
            currentMinute: 25 * 60,
            existingWindows: []
        )

        #expect(startWindow?.startMinute == 0)
        #expect(startWindow?.endMinute == 15)
        #expect(endWindow?.startMinute == 23 * 60 + 45)
        #expect(endWindow?.endMinute == 24 * 60)
    }

    @Test func weeklyAvailabilityGridCreateClampsBeforeOverlap() {
        let existing = AvailabilityMinuteWindow(
            id: UUID(),
            startMinute: 8 * 60,
            endMinute: 9 * 60
        )
        let window = WeeklyAvailabilityGridRules.createWindowMinutes(
            anchorMinute: 7 * 60,
            currentMinute: 8 * 60 + 30,
            existingWindows: [existing]
        )

        #expect(window?.startMinute == 7 * 60)
        #expect(window?.endMinute == 8 * 60)
    }

    @Test func weeklyAvailabilityGridResizeClampsAroundNeighbors() {
        let activeID = UUID()
        let previous = AvailabilityMinuteWindow(id: UUID(), startMinute: 6 * 60, endMinute: 7 * 60)
        let active = AvailabilityMinuteWindow(id: activeID, startMinute: 8 * 60, endMinute: 9 * 60)
        let next = AvailabilityMinuteWindow(id: UUID(), startMinute: 10 * 60, endMinute: 11 * 60)

        let resizedStart = WeeklyAvailabilityGridRules.resizeStartMinutes(
            currentMinute: 6 * 60 + 30,
            originalWindow: active,
            existingWindows: [previous, active, next]
        )
        let resizedEnd = WeeklyAvailabilityGridRules.resizeEndMinutes(
            currentMinute: 10 * 60 + 30,
            originalWindow: active,
            existingWindows: [previous, active, next]
        )

        #expect(resizedStart.startMinute == 7 * 60)
        #expect(resizedStart.endMinute == 9 * 60)
        #expect(resizedEnd.startMinute == 8 * 60)
        #expect(resizedEnd.endMinute == 10 * 60)
    }

    @Test func weeklyAvailabilityGridMovePreservesDurationAndStopsAtOverlap() {
        let activeID = UUID()
        let active = AvailabilityMinuteWindow(id: activeID, startMinute: 8 * 60, endMinute: 9 * 60)
        let next = AvailabilityMinuteWindow(id: UUID(), startMinute: 9 * 60 + 30, endMinute: 10 * 60)

        let moved = WeeklyAvailabilityGridRules.moveWindowMinutes(
            proposedStartMinute: 9 * 60,
            originalWindow: active,
            existingWindows: [active, next]
        )

        #expect(moved.startMinute == 8 * 60 + 30)
        #expect(moved.endMinute == 9 * 60 + 30)
    }

    @Test func weeklyAvailabilityUpsertStoresSortedNonOverlappingWindows() {
        let state = AppState.mock()
        let calendar = testCalendar()
        let day = testDate(year: 2026, month: 5, day: 4, hour: 12, calendar: calendar)
        let laterWindow = AvailabilityMinuteWindow(id: UUID(), startMinute: 12 * 60, endMinute: 13 * 60)
        let earlierWindow = AvailabilityMinuteWindow(id: UUID(), startMinute: 8 * 60, endMinute: 9 * 60)

        state.upsertAvailabilityWindow(laterWindow, on: day, calendar: calendar)
        state.upsertAvailabilityWindow(earlierWindow, on: day, calendar: calendar)

        let windows = state.availabilityMinuteWindows(on: day, calendar: calendar)
        #expect(windows.map(\.startMinute) == [8 * 60, 12 * 60])
        #expect(state.hasCompleteWeeklyAvailability)
    }

    @Test func locationSuggestionFormatsDisplayName() {
        let neighborhood = LocationSuggestion(title: "Hayes Valley", subtitle: "San Francisco, CA")
        let city = LocationSuggestion(title: "San Francisco")

        #expect(neighborhood.displayName == "Hayes Valley, San Francisco, CA")
        #expect(city.displayName == "San Francisco")
    }

    @Test func locationSuggestionCarriesNeighborhoodMapping() {
        let marketStreet = MockData.locationSuggestions(matching: "123 Market").first { $0.title == "123 Market St" }
        let city = MockData.locationSuggestions(matching: "San Francisco").first { $0.title == "San Francisco" }

        #expect(marketStreet?.neighborhoodName == "Financial District")
        #expect(marketStreet?.neighborhoodMappingDescription == "Maps to Financial District")
        #expect(city?.neighborhoodName == "SoMa")
    }

    @Test func locationSuggestionSearchMatchesMultipleLocationInputs() {
        #expect(MockData.locationSuggestions(matching: "hayes").contains { $0.title == "Hayes Valley" })
        #expect(MockData.locationSuggestions(matching: "sf").contains { $0.title == "San Francisco" })
        #expect(MockData.locationSuggestions(matching: "123 Market").contains { $0.title == "123 Market St" })
        #expect(MockData.locationSuggestions(matching: "94102").contains { $0.title == "Hayes Valley" })
    }

    @Test func locationSuggestionSearchIsSanFranciscoOnly() {
        #expect(MockData.locationSuggestions(matching: "Brooklyn").isEmpty)
        #expect(MockData.locationSuggestions(matching: "Santa Monica").isEmpty)
        #expect(MockData.locationSuggestions(matching: "Seattle").isEmpty)
    }

    @Test func locationSuggestionSearchIgnoresEmptyQuery() {
        #expect(MockData.locationSuggestions(matching: "").isEmpty)
        #expect(MockData.locationSuggestions(matching: "   ").isEmpty)
    }

    @Test func rootSearchFindsContactsByName() {
        let state = AppState.mock()
        let results = RootSearchIndex.results(for: "Ava", in: state)

        #expect(results.pages.isEmpty)
        #expect(results.contactIDs == [state.contacts[0].id])
        #expect(results.groupIDs.isEmpty)
        #expect(results.isSearching)
        #expect(!results.isEmpty)
    }

    @Test func rootSearchFindsGroupsByName() {
        let state = AppState.mock()
        let results = RootSearchIndex.results(for: "Study", in: state)

        #expect(results.pages.isEmpty)
        #expect(results.contactIDs.isEmpty)
        #expect(results.groupIDs == [state.groups[0].id])
    }

    @Test func rootSearchFindsPagesByTitleAndKeyword() {
        let state = AppState.mock()
        let radiusResults = RootSearchIndex.results(for: "radius", in: state)
        let contactsResults = RootSearchIndex.results(for: "network", in: state)

        #expect(radiusResults.pages == [.radius])
        #expect(contactsResults.pages == [.contacts])
    }

    @Test func rootSearchTrimsWhitespace() {
        let state = AppState.mock()
        let results = RootSearchIndex.results(for: "  Ava  ", in: state)

        #expect(results.query == "Ava")
        #expect(results.contactIDs == [state.contacts[0].id])
    }

    @Test func rootSearchHandlesEmptyAndNoResultQueries() {
        let state = AppState.mock()
        let emptyResults = RootSearchIndex.results(for: "   ", in: state)
        let noResults = RootSearchIndex.results(for: "zzzzzz", in: state)

        #expect(!emptyResults.isSearching)
        #expect(emptyResults.isEmpty)
        #expect(noResults.isSearching)
        #expect(noResults.isEmpty)
    }

    @Test func appRouterDefaultsToMatchWithEmptyPaths() {
        let router = AppRouter()

        #expect(router.selectedTab == .match)
        #expect(router.lastContentTab == .match)
        #expect(router.matchPath.isEmpty)
        #expect(router.profilePath.isEmpty)
        #expect(router.searchPath.isEmpty)
        #expect(router.isRootSearchPresented == false)
    }

    @Test func appRouterTracksLastContentTab() {
        let router = AppRouter()

        router.select(.profile)

        #expect(router.selectedTab == .profile)
        #expect(router.lastContentTab == .profile)

        router.select(.search)

        #expect(router.selectedTab == .search)
        #expect(router.lastContentTab == .profile)
    }

    @Test func appRouterDismissesSearchToLastContentTab() {
        let router = AppRouter()
        router.select(.profile)
        router.select(.search)
        router.isRootSearchPresented = true

        router.dismissSearch()

        #expect(router.selectedTab == .profile)
        #expect(router.lastContentTab == .profile)
        #expect(router.isRootSearchPresented == false)
    }

    @Test func appRouterOpensDestinationsOnExpectedPaths() {
        let router = AppRouter()
        let contactID = AppContact(name: "Ava Thompson").id

        router.openPage(.radius)
        router.openContact(contactID, from: .match)
        router.openPage(.sexuality, from: .profile)
        router.openMyCard(from: .search)
        router.openMatchCriteria(from: .match)

        #expect(router.matchPath == [.page(.radius), .contact(contactID), .matchCriteria])
        #expect(router.profilePath == [.page(.sexuality)])
        #expect(router.searchPath == [.myCard])
    }

    @Test func appRouterFutureFlowHooksAreNoOps() {
        let router = AppRouter()

        router.startOnboarding()
        router.openMatchRelease()

        #expect(router.selectedTab == .match)
        #expect(router.lastContentTab == .match)
        #expect(router.matchPath.isEmpty)
        #expect(router.profilePath.isEmpty)
        #expect(router.searchPath.isEmpty)
    }

    private func testCalendar() -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        calendar.firstWeekday = 2
        return calendar
    }

    private func testDate(year: Int, month: Int, day: Int, hour: Int, calendar: Calendar) -> Date {
        calendar.date(from: DateComponents(
            calendar: calendar,
            timeZone: calendar.timeZone,
            year: year,
            month: month,
            day: day,
            hour: hour
        ))!
    }
}
