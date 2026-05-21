import Combine
import SwiftUI

struct RootView: View {
    @State private var appState = AppState.mock()
    @State private var router = AppRouter()
    @State private var homeViewModel = HomeViewModel()
    @State private var showNetworkInfoPopup = false
    @State private var enrollmentShimmerTrigger = 0
    @State private var hasShownMatchTab = false

    var body: some View {
        TabView(selection: Binding(
            get: { router.selectedTab },
            set: { router.select($0) }
        )) {
            Tab(RootTab.match.title, systemImage: RootTab.match.systemImage, value: RootTab.match) {
                NavigationStack(path: $router.matchPath) {
                    List {
                        matchSections
                    }
                    .navigationTitle(RootTab.match.title)
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar(.hidden, for: .navigationBar)
                    .listStyle(.insetGrouped)
                    .alert("Batch Info", isPresented: $homeViewModel.showBatchInfoPopup) {
                        Button("OK", role: .cancel) {}
                    } message: {
                        Text("Sliding to enroll locks availability, criteria, and referral network for next week. Edits afterward apply to later batches. Each batch closes Sunday @ 11:59 PM local time.")
                    }
                    .onDisappear {
                        homeViewModel.cancelMatchSimulation()
                    }
                    .onAppear {
                        triggerEnrollmentShimmerAfterFirstAppearance()
                    }
                    .navigationDestination(for: RootDestination.self) { destination in
                        rootDestination(for: destination)
                            .toolbar(.visible, for: .navigationBar)
                    }
                }
            }

            Tab("Profile", systemImage: RootTab.profile.systemImage, value: RootTab.profile) {
                NavigationStack(path: $router.profilePath) {
                    ProfileTabView(appState: appState)
                        .navigationTitle(RootTab.profile.title)
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar(.hidden, for: .navigationBar)
                        .navigationDestination(for: RootDestination.self) { destination in
                            rootDestination(for: destination)
                                .toolbar(.visible, for: .navigationBar)
                        }
                }
            }

            Tab("Search", systemImage: RootTab.search.systemImage, value: RootTab.search, role: .search) {
                NavigationStack(path: $router.searchPath) {
                    RootSearchView(
                        appState: appState,
                        isSearchPresented: $router.isRootSearchPresented
                    ) {
                        router.dismissSearch()
                    }
                    .navigationTitle(RootTab.search.title)
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar(.hidden, for: .navigationBar)
                    .navigationDestination(for: RootDestination.self) { destination in
                        rootDestination(for: destination)
                            .toolbar(.visible, for: .navigationBar)
                    }
                }
            }
            .accessibilityIdentifier("Search Tab")
        }
        .tabViewSearchActivation(.searchTabSelection)
        .alert("Network Priority", isPresented: $showNetworkInfoPopup) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("To keep the network trustworthy, contacts can only be added in person via Bluetooth. Add contacts to groups, then reorder groups to set match priority.")
        }
        .onChange(of: router.selectedTab) { _, newTab in
            guard newTab == .match else { return }
            triggerEnrollmentShimmerAfterFirstAppearance()
        }
    }

    @ViewBuilder
    private var matchSections: some View {
        Section {
            matchHero
                .listRowSeparator(.hidden)
        }

        Section {
            NavigationLink(value: RootDestination.weeklyBatchAvailability) {
                availabilityRow
            }
            .accessibilityIdentifier("Availability Row")

            NavigationLink(value: RootDestination.matchCriteria) {
                valueRow(
                    title: "Match Criteria",
                    value: appState.matchCriteriaEditedSummary,
                    systemImage: "slider.horizontal.3"
                )
            }
            .accessibilityIdentifier("Match Criteria Row")

            SlideToEnrollControl(
                isEnrolledInBatch: isEnrolledInBatch,
                isEnabled: appState.hasCompleteWeeklyAvailability,
                resetTrigger: homeViewModel.sliderResetTrigger,
                shimmerTrigger: enrollmentShimmerTrigger,
                disabledText: "Add availability"
            ) {
                enrollInWeeklyBatch()
            }
        } header: {
            HStack(spacing: 6) {
                Text("Next Week")
                Button {
                    homeViewModel.showBatchInfoPopup = true
                } label: {
                    Image(systemName: "info.circle")
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("Batch Info")
            }
        }

        networkSection

        historySection
    }

    @ViewBuilder
    private var matchHero: some View {
        if homeViewModel.hasMatchThisWeek {
            NavigationLink(value: RootDestination.matchProfile) {
                anonymousMatchProfile(profile: homeViewModel.matchProfile)
            }
            .accessibilityIdentifier("Weekly Match Row")
        } else {
            HStack(alignment: .center, spacing: 14) {
                ZStack {
                    Circle()
                        .fill(Color.accentColor.opacity(0.16))

                    Image(systemName: "tray.fill")
                        .font(.system(size: 28, weight: .regular))
                        .foregroundStyle(Color.accentColor)
                        .accessibilityLabel("No Match Mailbox Icon")
                        .accessibilityIdentifier("No Match Mailbox Icon")
                }
                .frame(width: 56, height: 56)

                VStack(alignment: .leading, spacing: 3) {
                    Text("No match yet")
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Text("Your weekly match will appear here after release.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.vertical, 6)
            .accessibilityIdentifier("No Match Empty State")
        }
    }

    private func anonymousMatchProfile(profile: AnonymousMatchProfile) -> some View {
        HStack(alignment: .center, spacing: 14) {
            matchAvatar(size: 56)

            VStack(alignment: .leading, spacing: 3) {
                Text("Meet Your Match")
                    .font(.headline)
                    .foregroundStyle(.primary)
                Text("This week's match details and meeting plan")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 6)
        .accessibilityIdentifier("Anonymous Match Profile")
    }

    private func matchAvatar(size: CGFloat) -> some View {
        ZStack {
            Circle()
                .fill(Color.accentColor.opacity(0.16))

            Image(systemName: "person.crop.circle.fill")
                .font(.system(size: size * 0.72, weight: .regular))
                .foregroundStyle(Color.accentColor)
                .accessibilityIdentifier("Anonymous Match Default Avatar")
        }
        .frame(width: size, height: size)
    }

    private var availabilityRow: some View {
        HStack(spacing: 12) {
            Image(systemName: "calendar")
                .foregroundStyle(.secondary)
                .frame(width: 22)

            Text("Availability")

            Spacer()

            Text(availabilityStatusText)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.trailing)
        }
    }

    private var availabilityStatusText: String {
        appState.hasCompleteWeeklyAvailability ? "Set" : "Not set"
    }

    private var isEnrolledInBatch: Bool {
        homeViewModel.isEnrolledInBatch || appState.isEnrolledInWeeklyBatch
    }

    private func adaptiveAvailabilityGridHeight(for containerHeight: CGFloat) -> CGFloat {
        let reservedHeight: CGFloat = 260
        return min(max(containerHeight - reservedHeight, 360), 560)
    }

    private var networkSection: some View {
        Section {
            NavigationLink(value: RootDestination.page(.contacts)) {
                valueRow(title: "Contacts", value: "\(appState.contacts.count)", systemImage: "person.2.fill")
            }
            .accessibilityIdentifier("Contacts Row")

            NavigationLink(value: RootDestination.page(.groups)) {
                valueRow(title: "Groups", value: "\(appState.groups.count)", systemImage: "rectangle.3.group.fill")
            }
            .accessibilityIdentifier("Groups Row")
        } header: {
            HStack(spacing: 6) {
                Text("Network")
                Button {
                    showNetworkInfoPopup = true
                } label: {
                    Image(systemName: "info.circle")
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("Network Info")
            }
        }
    }

    private var historySection: some View {
        Section("History") {
            NavigationLink(value: RootDestination.page(.logbook)) {
                valueRow(title: "Logbook", value: "\(MockData.logbookItems.count) events", systemImage: "checklist")
            }
            .accessibilityIdentifier("Logbook Row")
        }
    }

    private func valueRow(title: String, value: String, systemImage: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .foregroundStyle(.secondary)
                .frame(width: 22)

            Text(title)

            Spacer()

            Text(value)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.trailing)
        }
    }

    @ViewBuilder
    private func rootDestination(for destination: RootDestination) -> some View {
        switch destination {
        case .page(let page):
            rootPageDestination(for: page)
        case .profileField(let field):
            profileFieldDestination(for: field)
        case .profileSubstanceUse(let category):
            AccountSubstanceUseView(
                category: category,
                selection: substanceUseBinding(for: category)
            )
        case .sharingField(let field):
            SharingFieldView(appState: appState, field: field)
        case .matchSubstanceUse(let category):
            MatchSubstanceUsePreferenceView(
                category: category,
                selection: acceptedSubstanceUseBinding(for: category)
            )
        case .contact(let id):
            if let contact = contactBinding(for: id) {
                ContactDetailView(contact: contact, groups: $appState.groups)
            } else {
                Text("Contact unavailable")
            }
        case .myCard:
            SharingCardView(appState: appState)
        case .matchProfile:
            MatchProfileView(profile: homeViewModel.matchProfile)
        case .matchCriteria:
            MatchCriteriaView(appState: appState, isEnrolledInBatch: isEnrolledInBatch)
        case .weeklyBatchAvailability:
            WeeklyBatchAvailabilityView(
                appState: appState,
                isEnrolledInBatch: isEnrolledInBatch
            )
        }
    }

    private func enrollInWeeklyBatch() {
        appState.enrollInWeeklyBatch()
        homeViewModel.confirmEnrollment()
    }

    private func triggerEnrollmentShimmerAfterFirstAppearance() {
        guard appState.hasCompleteWeeklyAvailability, !isEnrolledInBatch else {
            hasShownMatchTab = true
            return
        }

        guard hasShownMatchTab else {
            hasShownMatchTab = true
            return
        }

        enrollmentShimmerTrigger += 1
    }

    @ViewBuilder
    private func rootPageDestination(for page: RootSearchPage) -> some View {
        switch page {
        case .contacts:
            ContactsView(appState: appState)
                .navigationTitle("Contacts")
        case .groups:
            GroupsView(groups: $appState.groups, allContacts: appState.contacts)
                .navigationTitle("Groups")
        case .logbook:
            LogbookView(items: MockData.logbookItems)
        case .location:
            MatchingLocationView(location: $appState.matchingLocation)
        case .radius:
            MatchingRadiusView(
                radiusMiles: $appState.matchingRadiusMiles,
                extendRadiusIfNeeded: $appState.extendRadiusIfNeeded
            )
        case .matchWith:
            MatchGenderPreferenceView(preferredGenders: $appState.preferredGenders)
        case .sexuality:
            MatchSexualityPreferenceView(preferredSexualities: $appState.preferredSexualities)
        case .substanceUse:
            MatchSubstanceUseListView(acceptedSubstanceUse: appState.acceptedSubstanceUse)
        case .ageRange:
            AgeRangePreferenceView(
                preferredAgeMin: $appState.preferredAgeMin,
                preferredAgeMax: $appState.preferredAgeMax
            )
        case .matchPolicy:
            MatchPolicyView(matchPolicy: $appState.matchPolicy)
        case .profile:
            AccountProfileView(
                age: $appState.age,
                gender: $appState.gender,
                pronouns: $appState.pronouns,
                sexuality: $appState.sexuality,
                substanceUse: $appState.substanceUse
            )
        }
    }

    @ViewBuilder
    private func profileFieldDestination(for field: ProfileField) -> some View {
        switch field {
        case .firstName:
            AccountTextFieldView(
                title: field.title,
                text: $appState.myCard.firstName,
                textContentType: .givenName
            )
        case .lastName:
            AccountTextFieldView(
                title: field.title,
                text: $appState.myCard.lastName,
                textContentType: .familyName
            )
        case .nickname:
            AccountTextFieldView(
                title: field.title,
                text: $appState.myCard.nickname,
                textContentType: .nickname
            )
        case .age:
            AccountAgeView(age: $appState.age)
        case .gender:
            AccountSingleSelectView(
                title: field.title,
                selection: $appState.gender
            )
        case .pronouns:
            AccountSingleSelectView(
                title: field.title,
                selection: $appState.pronouns
            )
        case .sexuality:
            AccountSingleSelectView(
                title: field.title,
                selection: $appState.sexuality
            )
        }
    }

    private func contactBinding(for id: AppContact.ID) -> Binding<AppContact>? {
        guard let index = appState.contacts.firstIndex(where: { $0.id == id }) else { return nil }
        return $appState.contacts[index]
    }

    private func substanceUseBinding(for category: SubstanceUseCategory) -> Binding<SubstanceUseAnswer> {
        Binding(
            get: {
                appState.substanceUseAnswer(for: category)
            },
            set: { newValue in
                appState.substanceUse[category] = newValue
            }
        )
    }

    private func sharedProfileFieldBinding(for field: ProfileDisclosureField) -> Binding<Bool> {
        Binding(
            get: {
                appState.sharedProfileFields.contains(field)
            },
            set: { isShared in
                if isShared {
                    appState.sharedProfileFields.insert(field)
                } else {
                    appState.sharedProfileFields.remove(field)
                }
            }
        )
    }

    private func acceptedSubstanceUseBinding(for category: SubstanceUseCategory) -> Binding<SubstanceUseAnswer> {
        Binding(
            get: {
                appState.acceptedSubstanceUseAnswer(for: category)
            },
            set: { newValue in
                appState.acceptedSubstanceUse[category] = newValue
            }
        )
    }
}

private struct MatchProfileView: View {
    let profile: AnonymousMatchProfile

    var body: some View {
        List {
            Section {
                HStack(alignment: .center, spacing: 14) {
                    matchAvatar(size: 56)

                    VStack(alignment: .leading, spacing: 3) {
                        Text(profile.name)
                            .font(.headline)
                            .foregroundStyle(.primary)
                        Text("This week's match details and meeting plan")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 6)
            }

            Section("Meeting") {
                matchDetailRow(title: "Date & Time", value: "Thursday, 3:00-3:30 PM", systemImage: "clock")
                matchDetailRow(title: "Address", value: "Hayes Cafe Mock Spot", systemImage: "mappin.and.ellipse")
            }

            Section("Profile") {
                matchDetailRow(title: "Age", value: "\(profile.age)", systemImage: "number")
                matchDetailRow(title: "Pronouns", value: profile.pronouns, systemImage: "text.bubble")
                matchDetailRow(title: "Neighborhood", value: profile.neighborhood, systemImage: "location")
            }

            Section("About") {
                Text(profile.bio)
                    .foregroundStyle(.secondary)
            }

            Section("Interests") {
                ForEach(profile.interests, id: \.self) { interest in
                    Text(interest)
                }
            }
        }
        .navigationTitle(profile.name)
        .navigationBarTitleDisplayMode(.inline)
        .listStyle(.insetGrouped)
        .accessibilityIdentifier("Weekly Match Detail")
    }

    private func matchDetailRow(title: String, value: String, systemImage: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .foregroundStyle(.secondary)
                .frame(width: 22)

            Text(title)

            Spacer()

            Text(value)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.trailing)
        }
    }

    private func matchAvatar(size: CGFloat) -> some View {
        ZStack {
            Circle()
                .fill(Color.accentColor.opacity(0.16))

            Image(systemName: "person.crop.circle.fill")
                .font(.system(size: size * 0.72, weight: .regular))
                .foregroundStyle(Color.accentColor)
                .accessibilityIdentifier("Weekly Match Default Avatar")
        }
        .frame(width: size, height: size)
    }
}

private struct MatchCriteriaView: View {
    @Bindable var appState: AppState
    let isEnrolledInBatch: Bool

    var body: some View {
        List {
            if isEnrolledInBatch {
                Section {
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "lock.fill")
                            .foregroundStyle(.secondary)
                        Text("This week's criteria are locked. Changes here apply to next week's batch.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .accessibilityIdentifier("Next Week Criteria Notice")
                }
            }

            Section("Location") {
                NavigationLink(value: RootDestination.page(.location)) {
                    valueRow(title: "Location", value: appState.matchingLocation, systemImage: "location.fill")
                }
                .accessibilityIdentifier("Location Row")

                NavigationLink(value: RootDestination.page(.radius)) {
                    valueRow(title: "Radius", value: "Within \(appState.matchingRadiusMiles) mi", systemImage: "scope")
                }
                .accessibilityIdentifier("Radius Row")
            }

            Section("Demographics") {
                NavigationLink(value: RootDestination.page(.ageRange)) {
                    valueRow(title: "Age Range", value: appState.currentMatchCriteriaSnapshot.ageRangeSummary, systemImage: "calendar")
                }
                .accessibilityIdentifier("Age Range Row")

                NavigationLink(value: RootDestination.page(.matchWith)) {
                    valueRow(title: "Gender", value: appState.preferredGendersSummary, systemImage: "person.fill")
                }
                .accessibilityIdentifier("Criteria Gender Row")

                NavigationLink(value: RootDestination.page(.sexuality)) {
                    valueRow(title: "Sexuality", value: appState.preferredSexualitiesSummary, systemImage: "heart.circle")
                }
                .accessibilityIdentifier("Criteria Sexuality Row")

                NavigationLink(value: RootDestination.page(.matchPolicy)) {
                    valueRow(title: "Match Policy", value: appState.matchPolicy.label, systemImage: "checkmark.shield.fill")
                }
                .accessibilityIdentifier("Match Policy Row")
            }

            Section("Substance Use") {
                substanceUseRows(
                    selection: appState.acceptedSubstanceUse,
                    accessibilityPrefix: "Criteria"
                )
            }
        }
        .navigationTitle("Match Criteria")
        .navigationBarTitleDisplayMode(.inline)
        .listStyle(.insetGrouped)
    }

    private func valueRow(title: String, value: String, systemImage: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .foregroundStyle(.secondary)
                .frame(width: 22)

            Text(title)

            Spacer()

            Text(value)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.trailing)
        }
    }

    private func substanceUseRows(
        selection: [SubstanceUseCategory: SubstanceUseAnswer],
        accessibilityPrefix: String
    ) -> some View {
        ForEach(Array(SubstanceUseCategory.allCases), id: \.self) { substance in
            NavigationLink(value: RootDestination.matchSubstanceUse(substance)) {
                valueRow(
                    title: substance.label,
                    value: selection[substance, default: .yes].label,
                    systemImage: substance.systemImage
                )
            }
            .accessibilityIdentifier("\(accessibilityPrefix) \(substance.label) Substance Use Row")
        }
    }
}

private struct RootSearchView: View {
    @Bindable var appState: AppState
    @Binding var isSearchPresented: Bool
    let onDismissSearch: () -> Void

    @State private var searchText = ""
    @State private var selectedGroupID: AppGroup.ID?

    private var rootSearchResults: RootSearchResults {
        RootSearchIndex.results(for: searchText, in: appState)
    }

    var body: some View {
        List {
            searchResults
        }
        .listStyle(.insetGrouped)
        .searchable(text: $searchText, isPresented: $isSearchPresented, prompt: "Quick Search")
        .onAppear {
            isSearchPresented = true
        }
        .onChange(of: isSearchPresented) { oldValue, newValue in
            if oldValue && !newValue {
                dismissSearch()
            }
        }
        .sheet(isPresented: Binding(
            get: { selectedGroupID != nil },
            set: { isPresented in
                if !isPresented {
                    selectedGroupID = nil
                }
            }
        )) {
            if let selectedGroupID, let group = groupBinding(for: selectedGroupID) {
                GroupMembersSheetView(group: group, allContacts: appState.contacts)
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
            }
        }
    }

    @ViewBuilder
    private var searchResults: some View {
        if !rootSearchResults.isSearching {
            Section {
                Text("Search pages, contacts, or groups")
                    .foregroundStyle(.secondary)
            }
        } else if rootSearchResults.isEmpty {
            Section {
                Text("No results")
                    .foregroundStyle(.secondary)
            }
        }

        if !rootSearchResults.pages.isEmpty {
            Section("Pages") {
                ForEach(rootSearchResults.pages) { page in
                    NavigationLink(value: RootDestination.page(page)) {
                        valueRow(title: page.title, value: "", systemImage: page.systemImage)
                    }
                    .accessibilityIdentifier("Quick Search Page \(page.title)")
                }
            }
        }

        if !rootSearchResults.contactIDs.isEmpty {
            Section("Contacts") {
                ForEach(rootSearchResults.contactIDs, id: \.self) { id in
                    if let contact = contactBinding(for: id) {
                        NavigationLink(value: RootDestination.contact(id)) {
                            valueRow(title: contact.wrappedValue.name, value: "", systemImage: "person.crop.circle.fill")
                        }
                    }
                }
            }
        }

        if !rootSearchResults.groupIDs.isEmpty {
            Section("Groups") {
                ForEach(rootSearchResults.groupIDs, id: \.self) { id in
                    if let group = groupBinding(for: id) {
                        Button {
                            selectedGroupID = id
                        } label: {
                            valueRow(title: group.wrappedValue.name, value: "\(group.wrappedValue.members.count) members", systemImage: "person.2.fill")
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private func valueRow(title: String, value: String, systemImage: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .foregroundStyle(.secondary)
                .frame(width: 22)

            Text(title)

            Spacer()

            Text(value)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.trailing)
        }
    }

    private func contactBinding(for id: AppContact.ID) -> Binding<AppContact>? {
        guard let index = appState.contacts.firstIndex(where: { $0.id == id }) else { return nil }
        return $appState.contacts[index]
    }

    private func groupBinding(for id: AppGroup.ID) -> Binding<AppGroup>? {
        guard let index = appState.groups.firstIndex(where: { $0.id == id }) else { return nil }
        return $appState.groups[index]
    }

    private func dismissSearch() {
        searchText = ""
        onDismissSearch()
    }
}

private struct WeeklyBatchAvailabilityView: View {
    @Bindable var appState: AppState
    let isEnrolledInBatch: Bool

    var body: some View {
        GeometryReader { proxy in
            VStack(alignment: .leading, spacing: 16) {
                WeeklyAvailabilityEditor(
                    appState: appState,
                    isLocked: isEnrolledInBatch,
                    gridHeight: gridHeight(
                        for: proxy.size.height,
                        bottomSafeArea: proxy.safeAreaInsets.bottom
                    )
                )
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Availability")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func gridHeight(for containerHeight: CGFloat, bottomSafeArea: CGFloat) -> CGFloat {
        let tabBarClearance: CGFloat = 96
        let reservedHeight = 130 + max(bottomSafeArea, tabBarClearance)
        return min(max(containerHeight - reservedHeight, 360), 620)
    }
}

private struct WeeklyAvailabilityEditor: View {
    @Bindable var appState: AppState
    let isLocked: Bool
    let gridHeight: CGFloat
    @State private var activeWindowID: AvailabilityWindow.ID?
    @State private var visibleStartIndex = 0

    private let visibleDayCount = 2

    private var calendar: Calendar {
        WeeklyAvailabilityCalendar.configuredCalendar()
    }

    private var weekDates: [Date] {
        WeeklyAvailabilityCalendar.nextWeekDates(calendar: calendar)
    }

    private var visibleDates: [Date] {
        let endIndex = min(visibleStartIndex + visibleDayCount, weekDates.count)
        guard visibleStartIndex < endIndex else {
            return []
        }

        return Array(weekDates[visibleStartIndex..<endIndex])
    }

    private var visibleMonthTitle: String {
        guard let first = visibleDates.first else {
            return "Next Week"
        }

        guard let last = visibleDates.last,
              calendar.component(.month, from: first) != calendar.component(.month, from: last) else {
            return first.formatted(.dateTime.month(.wide))
        }

        return "\(first.formatted(.dateTime.month(.wide))) / \(last.formatted(.dateTime.month(.wide)))"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(visibleMonthTitle)
                .font(.headline)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 4)

            WeeklyAvailabilityGrid(
                appState: appState,
                isLocked: isLocked,
                visibleStartIndex: visibleStartIndex,
                visibleDayCount: visibleDayCount,
                visibleDates: visibleDates,
                visibleGridHeight: gridHeight,
                activeWindowID: $activeWindowID,
                onShiftVisibleDates: shiftVisibleDates,
                onSelectVisibleStartIndex: selectVisibleStartIndex
            )
            .padding(12)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        }
        .accessibilityIdentifier("Weekly Availability Editor")
        .onChange(of: isLocked) { _, newValue in
            if newValue {
                activeWindowID = nil
            }
        }
    }

    private func shiftVisibleDates(by offset: Int) {
        selectVisibleStartIndex(visibleStartIndex + offset)
    }

    private func selectVisibleStartIndex(_ index: Int) {
        let maxStartIndex = max(0, weekDates.count - visibleDayCount)
        let nextIndex = min(max(index, 0), maxStartIndex)
        guard nextIndex != visibleStartIndex else { return }

        activeWindowID = nil
        withAnimation(.easeInOut(duration: 0.2)) {
            visibleStartIndex = nextIndex
        }
    }
}

private struct WeeklyAvailabilityGrid: View {
    @Bindable var appState: AppState
    let isLocked: Bool
    let visibleStartIndex: Int
    let visibleDayCount: Int
    let visibleDates: [Date]
    let visibleGridHeight: CGFloat
    @Binding var activeWindowID: AvailabilityWindow.ID?
    let onShiftVisibleDates: (Int) -> Void
    let onSelectVisibleStartIndex: (Int) -> Void

    @State private var creatingWindowID: AvailabilityWindow.ID?
    @State private var movingOriginalWindow: AvailabilityMinuteWindow?
    @State private var resizingStartOriginalWindow: AvailabilityMinuteWindow?
    @State private var resizingEndOriginalWindow: AvailabilityMinuteWindow?
    @State private var scrollOffsetY: CGFloat = 0

    private let timeLabelWidth: CGFloat = 50
    private let hourHeight: CGFloat = 56
    private let headerHeight: CGFloat = 38
    private let weekSelectorHeight: CGFloat = 76
    private let topScrollInset: CGFloat = 28
    private let initialTopMinute = (16 * 60) + 30
    private let slotHorizontalInset: CGFloat = 5
    private let bottomDragSlop: CGFloat = 28
    private let activeColor = Color.accentColor
    private let scrollViewCoordinateSpace = "AvailabilityGridScrollView"
    private let contentCoordinateSpace = "AvailabilityGridContent"

    private var calendar: Calendar {
        WeeklyAvailabilityCalendar.configuredCalendar()
    }

    private var weekDates: [Date] {
        WeeklyAvailabilityCalendar.nextWeekDates(calendar: calendar)
    }

    private var contentHeight: CGFloat {
        CGFloat(WeeklyAvailabilityGridRules.endMinute - WeeklyAvailabilityGridRules.startMinute) / 60 * hourHeight
    }

    private var bottomScrollInset: CGFloat {
        max(visibleGridHeight - (contentHeight - minuteY(initialTopMinute)), 0)
    }

    private var interactiveContentHeight: CGFloat {
        contentHeight + bottomDragSlop
    }

    var body: some View {
        GeometryReader { geometry in
            let dayCount = max(visibleDates.count, 1)
            let dayWidth = max((geometry.size.width - timeLabelWidth) / CGFloat(dayCount), 96)

            VStack(spacing: 0) {
                weekSelector
                VStack(spacing: 0) {
                    dayHeader(dayWidth: dayWidth)

                    ScrollViewReader { proxy in
                        ScrollView(.vertical, showsIndicators: false) {
                            VStack(spacing: 0) {
                                Color.clear
                                    .frame(height: topScrollInset)

                                ZStack(alignment: .topLeading) {
                                    scrollOffsetReader()
                                    scrollAnchors()
                                    gridLines(totalWidth: geometry.size.width, dayWidth: dayWidth)
                                    creationColumns(dayWidth: dayWidth)
                                    availabilityWindows(dayWidth: dayWidth)
                                }
                                .frame(width: geometry.size.width, height: interactiveContentHeight, alignment: .topLeading)
                                .coordinateSpace(name: contentCoordinateSpace)

                                Color.clear
                                    .frame(height: bottomScrollInset)
                            }
                        }
                        .coordinateSpace(name: scrollViewCoordinateSpace)
                        .frame(height: visibleGridHeight)
                        .background(alignment: .topLeading) {
                            columnSeparators(dayWidth: dayWidth, height: visibleGridHeight)
                        }
                        .clipped()
                        .contentMargins(.all, 0, for: .scrollContent)
                        .scrollIndicators(.hidden)
                        .onPreferenceChange(AvailabilityScrollOffsetKey.self) { value in
                            scrollOffsetY = max(0, -value)
                        }
                        .onAppear {
                            scrollOffsetY = minuteY(initialTopMinute)
                            DispatchQueue.main.async {
                                proxy.scrollTo(scrollAnchorID(for: initialTopMinute), anchor: .top)
                            }
                        }
                    }
                }
                .id(visibleStartIndex)
                .transition(.opacity)
            }
        }
        .frame(height: weekSelectorHeight + headerHeight + visibleGridHeight)
        .contentShape(Rectangle())
        .simultaneousGesture(intervalSwipeGesture)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Weekly Availability Grid")
        .accessibilityIdentifier("Weekly Availability Grid")
    }

    private var weekSelector: some View {
        GeometryReader { proxy in
            let dayCount = max(weekDates.count, 1)
            let dayWidth = proxy.size.width / CGFloat(dayCount)
            let pillInset: CGFloat = 5
            let pillHeight: CGFloat = 42
            let pillY: CGFloat = 28
            let circleSize: CGFloat = 32
            let circleX = (dayWidth * CGFloat(visibleStartIndex)) + ((dayWidth - circleSize) / 2)
            let pillX = circleX - pillInset
            let pillWidth = (dayWidth * CGFloat(visibleDayCount)) - (dayWidth - circleSize) + (pillInset * 2)

            ZStack(alignment: .topLeading) {
                if !weekDates.isEmpty {
                    Capsule()
                        .fill(Color(.tertiarySystemFill))
                        .frame(
                            width: pillWidth,
                            height: pillHeight
                        )
                        .offset(x: pillX, y: pillY)

                    Circle()
                        .fill(Color.accentColor)
                        .frame(width: circleSize, height: circleSize)
                        .offset(
                            x: circleX,
                            y: pillY + ((pillHeight - circleSize) / 2)
                        )
                }

                HStack(spacing: 0) {
                    ForEach(Array(weekDates.enumerated()), id: \.element) { index, date in
                        Button {
                            onSelectVisibleStartIndex(index)
                        } label: {
                            VStack(spacing: 6) {
                                Text(date.formatted(.dateTime.weekday(.abbreviated)))
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.secondary)

                                Text(date.formatted(.dateTime.day()))
                                    .font(.title3.weight(.medium))
                                    .foregroundStyle(dateForegroundStyle(for: index))
                                    .frame(height: circleSize + 2)
                            }
                            .frame(maxWidth: .infinity, minHeight: weekSelectorHeight)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("Availability Week Selector \(weekdayName(for: date))")
                    }
                }
            }
        }
        .frame(height: weekSelectorHeight)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Color(.separator).opacity(0.35))
                .frame(height: 1)
        }
    }

    private func isDateVisible(at index: Int) -> Bool {
        index >= visibleStartIndex && index < visibleStartIndex + visibleDayCount
    }

    private func dateForegroundStyle(for index: Int) -> Color {
        if index == visibleStartIndex {
            return .white
        }

        return .primary
    }

    private func dayHeader(dayWidth: CGFloat) -> some View {
        HStack(spacing: 0) {
            Color.clear
                .frame(width: timeLabelWidth)

            ForEach(visibleDates, id: \.self) { date in
                Text(dayHeaderLabel(for: date))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
                .frame(width: dayWidth, height: headerHeight)
                .accessibilityIdentifier("Availability Day Header \(weekdayName(for: date))")
            }
        }
        .background(Color(.secondarySystemGroupedBackground))
        .overlay(alignment: .topLeading) {
            columnSeparators(dayWidth: dayWidth, height: headerHeight)
        }
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Color(.separator).opacity(0.35))
                .frame(height: 1)
        }
    }

    private func dayHeaderLabel(for date: Date) -> String {
        let month = calendar.component(.month, from: date)
        let day = calendar.component(.day, from: date)
        return "\(date.formatted(.dateTime.weekday(.wide))) - \(month)/\(day)"
    }

    private func gridLines(totalWidth: CGFloat, dayWidth: CGFloat) -> some View {
        ZStack(alignment: .topLeading) {
            Path { path in
                for hour in 0...24 {
                    let y = minuteY(hour * 60)
                    path.move(to: CGPoint(x: timeLabelWidth, y: y))
                    path.addLine(to: CGPoint(x: totalWidth, y: y))
                }
            }
            .stroke(Color(.separator).opacity(0.55), lineWidth: 1)

            ForEach(Array(stride(from: 0, through: 24, by: 1)), id: \.self) { hour in
                Text(timeLabel(for: hour))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(width: timeLabelWidth - 6, alignment: .trailing)
                    .offset(x: 0, y: minuteY(hour * 60) - 8)
            }
        }
    }

    private func columnSeparators(dayWidth: CGFloat, height: CGFloat) -> some View {
        Path { path in
            for dayIndex in 0...visibleDates.count {
                let x = timeLabelWidth + (CGFloat(dayIndex) * dayWidth)
                path.move(to: CGPoint(x: x, y: 0))
                path.addLine(to: CGPoint(x: x, y: height))
            }
        }
        .stroke(Color(.separator).opacity(0.55), lineWidth: 1)
        .allowsHitTesting(false)
    }

    private func scrollOffsetReader() -> some View {
        GeometryReader { proxy in
            Color.clear
                .preference(
                    key: AvailabilityScrollOffsetKey.self,
                    value: proxy.frame(in: .named(scrollViewCoordinateSpace)).minY
                )
        }
        .frame(height: 0)
    }

    private func scrollAnchors() -> some View {
        VStack(spacing: 0) {
            ForEach(Array(stride(
                from: WeeklyAvailabilityGridRules.startMinute,
                to: WeeklyAvailabilityGridRules.endMinute,
                by: WeeklyAvailabilityGridRules.snapIntervalMinutes
            )), id: \.self) { minute in
                Color.clear
                    .frame(width: 1, height: minuteHeight(WeeklyAvailabilityGridRules.snapIntervalMinutes))
                    .id(scrollAnchorID(for: minute))
            }
        }
        .frame(width: 1, height: contentHeight, alignment: .topLeading)
        .allowsHitTesting(false)
    }

    private func scrollAnchorMinute(for minute: Int) -> Int {
        let maxAnchorMinute = WeeklyAvailabilityGridRules.endMinute - WeeklyAvailabilityGridRules.snapIntervalMinutes
        return min(max(minute, WeeklyAvailabilityGridRules.startMinute), maxAnchorMinute)
    }

    private func scrollAnchorID(for minute: Int) -> String {
        "availability-minute-\(scrollAnchorMinute(for: minute))"
    }

    private func creationColumns(dayWidth: CGFloat) -> some View {
        HStack(spacing: 0) {
            ForEach(visibleDates, id: \.self) { date in
                Rectangle()
                    .fill(Color(.systemBackground).opacity(0.001))
                    .contentShape(Rectangle())
                    .frame(width: dayWidth, height: interactiveContentHeight)
                    .gesture(createGesture(for: date), including: isLocked ? .subviews : .gesture)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("Availability Day \(weekdayName(for: date))")
                    .accessibilityIdentifier("Availability Day \(weekdayName(for: date))")
            }
        }
        .offset(x: timeLabelWidth)
    }

    private func availabilityWindows(dayWidth: CGFloat) -> some View {
        ForEach(Array(visibleDates.enumerated()), id: \.element) { dayIndex, date in
            ForEach(appState.availabilityWindows(on: date, calendar: calendar)) { window in
                let minuteWindow = minuteWindow(for: window, on: date)
                let isActive = !isLocked && activeWindowID == window.id
                let windowHeight = max(minuteHeight(minuteWindow.endMinute - minuteWindow.startMinute), 28)

                AvailabilityWindowBlock(
                    window: window,
                    isActive: isActive,
                    isLocked: isLocked,
                    activeColor: activeColor,
                    onDelete: {
                        appState.removeAvailabilityWindow(window.id, on: date, calendar: calendar)
                        activeWindowID = nil
                    },
                    moveGesture: moveGesture(for: minuteWindow, on: date),
                    resizeStartGesture: resizeStartGesture(for: minuteWindow, on: date),
                    resizeEndGesture: resizeEndGesture(for: minuteWindow, on: date)
                )
                .frame(width: max(dayWidth - (slotHorizontalInset * 2), 26), height: windowHeight)
                .position(
                    x: timeLabelWidth + (CGFloat(dayIndex) * dayWidth) + (dayWidth / 2),
                    y: minuteY(minuteWindow.startMinute) + (windowHeight / 2)
                )
                .onTapGesture {
                    guard !isLocked else { return }
                    activeWindowID = window.id
                }
                .zIndex(isActive ? 2 : 1)
            }
        }
    }

    private var intervalSwipeGesture: some Gesture {
        DragGesture(minimumDistance: 28)
            .onEnded { value in
                guard abs(value.translation.width) > abs(value.translation.height),
                      abs(value.translation.width) > 48 else {
                    return
                }

                onShiftVisibleDates(value.translation.width < 0 ? 1 : -1)
            }
    }

    private func createGesture(for date: Date) -> some Gesture {
        LongPressGesture(minimumDuration: 0.25)
            .sequenced(before: DragGesture(minimumDistance: 0, coordinateSpace: .named(contentCoordinateSpace)))
            .onChanged { value in
                guard !isLocked else { return }

                switch value {
                case .first:
                    break
                case .second(true, let dragValue):
                    let windowID = creatingWindowID ?? UUID()
                    creatingWindowID = windowID
                    if let dragValue {
                        let anchorContentY = boundedContentY(dragValue.startLocation.y)
                        let currentContentY = boundedContentY(dragValue.location.y)
                        updateCreatingWindow(
                            id: windowID,
                            on: date,
                            anchorContentY: anchorContentY,
                            currentContentY: currentContentY
                        )
                    }
                default:
                    break
                }
            }
            .onEnded { value in
                if case .second(true, nil) = value, !isLocked {
                    let windowID = creatingWindowID ?? UUID()
                    let contentY = contentY(forVisibleY: visibleGridHeight / 2)
                    updateCreatingWindow(
                        id: windowID,
                        on: date,
                        anchorContentY: contentY,
                        currentContentY: contentY
                    )
                }
                creatingWindowID = nil
            }
    }

    private func moveGesture(for minuteWindow: AvailabilityMinuteWindow, on date: Date) -> some Gesture {
        DragGesture(minimumDistance: 0, coordinateSpace: .named(contentCoordinateSpace))
            .onChanged { value in
                guard !isLocked else { return }
                activeWindowID = minuteWindow.id

                let originalWindow = movingOriginalWindow ?? minuteWindow
                movingOriginalWindow = originalWindow
                let grabOffsetY = boundedContentY(value.startLocation.y) - minuteY(originalWindow.startMinute)
                let currentContentY = boundedContentY(value.location.y)
                updateMovedWindow(originalWindow, on: date, targetStartContentY: currentContentY - grabOffsetY)
            }
            .onEnded { _ in
                movingOriginalWindow = nil
            }
    }

    private func resizeStartGesture(for minuteWindow: AvailabilityMinuteWindow, on date: Date) -> some Gesture {
        DragGesture(minimumDistance: 0, coordinateSpace: .named(contentCoordinateSpace))
            .onChanged { value in
                guard !isLocked else { return }
                activeWindowID = minuteWindow.id

                let originalWindow = resizingStartOriginalWindow ?? minuteWindow
                resizingStartOriginalWindow = originalWindow
                let grabOffsetY = boundedContentY(value.startLocation.y) - minuteY(originalWindow.startMinute)
                let currentContentY = boundedContentY(value.location.y)
                updateResizedStartWindow(originalWindow, on: date, targetContentY: currentContentY - grabOffsetY)
            }
            .onEnded { _ in
                resizingStartOriginalWindow = nil
            }
    }

    private func resizeEndGesture(for minuteWindow: AvailabilityMinuteWindow, on date: Date) -> some Gesture {
        DragGesture(minimumDistance: 0, coordinateSpace: .named(contentCoordinateSpace))
            .onChanged { value in
                guard !isLocked else { return }
                activeWindowID = minuteWindow.id

                let originalWindow = resizingEndOriginalWindow ?? minuteWindow
                resizingEndOriginalWindow = originalWindow
                let grabOffsetY = boundedContentY(value.startLocation.y) - minuteY(originalWindow.endMinute)
                let currentContentY = boundedContentY(value.location.y)
                updateResizedEndWindow(originalWindow, on: date, targetContentY: currentContentY - grabOffsetY)
            }
            .onEnded { _ in
                resizingEndOriginalWindow = nil
            }
    }

    private func updateCreatingWindow(id: UUID, on date: Date, anchorContentY: CGFloat, currentContentY: CGFloat) {
        let existingWindows = appState
            .availabilityMinuteWindows(on: date, calendar: calendar)
            .filter { $0.id != id }
        guard var minuteWindow = WeeklyAvailabilityGridRules.createWindowMinutes(
            anchorMinute: minute(forContentY: anchorContentY),
            currentMinute: minute(forContentY: currentContentY),
            existingWindows: existingWindows
        ) else {
            return
        }

        minuteWindow = AvailabilityMinuteWindow(
            id: id,
            startMinute: minuteWindow.startMinute,
            endMinute: minuteWindow.endMinute
        )
        activeWindowID = id
        appState.upsertAvailabilityWindow(minuteWindow, on: date, calendar: calendar)
    }

    private func updateMovedWindow(_ originalWindow: AvailabilityMinuteWindow, on date: Date, targetStartContentY: CGFloat) {
        let movedWindow = WeeklyAvailabilityGridRules.moveWindowMinutes(
            proposedStartMinute: minute(forContentY: targetStartContentY),
            originalWindow: originalWindow,
            existingWindows: appState.availabilityMinuteWindows(on: date, calendar: calendar)
        )

        appState.upsertAvailabilityWindow(movedWindow, on: date, calendar: calendar)
    }

    private func updateResizedStartWindow(_ originalWindow: AvailabilityMinuteWindow, on date: Date, targetContentY: CGFloat) {
        let resizedWindow = WeeklyAvailabilityGridRules.resizeStartMinutes(
            currentMinute: minute(forContentY: targetContentY),
            originalWindow: originalWindow,
            existingWindows: appState.availabilityMinuteWindows(on: date, calendar: calendar)
        )

        appState.upsertAvailabilityWindow(resizedWindow, on: date, calendar: calendar)
    }

    private func updateResizedEndWindow(_ originalWindow: AvailabilityMinuteWindow, on date: Date, targetContentY: CGFloat) {
        let resizedWindow = WeeklyAvailabilityGridRules.resizeEndMinutes(
            currentMinute: minute(forContentY: targetContentY),
            originalWindow: originalWindow,
            existingWindows: appState.availabilityMinuteWindows(on: date, calendar: calendar)
        )

        appState.upsertAvailabilityWindow(resizedWindow, on: date, calendar: calendar)
    }

    private func minuteWindow(for window: AvailabilityWindow, on date: Date) -> AvailabilityMinuteWindow {
        AvailabilityMinuteWindow(
            id: window.id,
            startMinute: minuteOffset(for: window.startTime, on: date),
            endMinute: minuteOffset(for: window.endTime, on: date)
        )
    }

    private func minuteOffset(for time: Date, on date: Date) -> Int {
        let day = calendar.startOfDay(for: date)
        let rawMinute = Int((time.timeIntervalSince(day) / 60).rounded())
        return min(max(rawMinute, WeeklyAvailabilityGridRules.startMinute), WeeklyAvailabilityGridRules.endMinute)
    }

    private func minute(forContentY y: CGFloat) -> Int {
        let rawMinute = WeeklyAvailabilityGridRules.startMinute + Int((y / hourHeight) * 60)
        return WeeklyAvailabilityGridRules.snap(rawMinute)
    }

    private func contentY(forVisibleY y: CGFloat) -> CGFloat {
        boundedContentY(scrollOffsetY + y)
    }

    private func boundedContentY(_ y: CGFloat) -> CGFloat {
        min(max(y, 0), contentHeight)
    }

    private func minuteY(_ minute: Int) -> CGFloat {
        CGFloat(minute - WeeklyAvailabilityGridRules.startMinute) / 60 * hourHeight
    }

    private func minuteHeight(_ minutes: Int) -> CGFloat {
        CGFloat(minutes) / 60 * hourHeight
    }

    private func timeLabel(for hour: Int) -> String {
        switch hour {
        case 0, 24:
            return "12 AM"
        case 1..<12:
            return "\(hour) AM"
        case 12:
            return "12 PM"
        default:
            return "\(hour - 12) PM"
        }
    }

    private func weekdayName(for date: Date) -> String {
        date.formatted(.dateTime.weekday(.wide))
    }
}

private struct AvailabilityScrollOffsetKey: PreferenceKey {
    static var defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

private struct AvailabilityWindowBlock<MoveGesture: Gesture, ResizeStartGesture: Gesture, ResizeEndGesture: Gesture>: View {
    let window: AvailabilityWindow
    let isActive: Bool
    let isLocked: Bool
    let activeColor: Color
    let onDelete: () -> Void
    let moveGesture: MoveGesture
    let resizeStartGesture: ResizeStartGesture
    let resizeEndGesture: ResizeEndGesture

    var body: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 5)
                .fill(activeColor)
                .overlay(
                    RoundedRectangle(cornerRadius: 5)
                        .stroke(activeColor, lineWidth: isActive ? 2 : 0)
                )
                .shadow(color: isActive ? .black.opacity(0.16) : .clear, radius: 3, y: 1)
                .contentShape(Rectangle())
                .gesture(moveGesture)

            Text("\(window.startTime.formatted(date: .omitted, time: .shortened))–\(window.endTime.formatted(date: .omitted, time: .shortened))")
                .font(.caption2.weight(.semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .foregroundStyle(.white)
                .padding(.horizontal, 5)
                .padding(.vertical, 4)

            if isActive {
                Circle()
                    .fill(activeColor)
                    .frame(width: 18, height: 18)
                    .background(Circle().fill(activeColor.opacity(0.16)).frame(width: 32, height: 32))
                    .offset(x: -8, y: -8)
                    .highPriorityGesture(resizeStartGesture)
                    .accessibilityIdentifier("Availability Start Handle")

                GeometryReader { proxy in
                    Circle()
                        .fill(activeColor)
                        .frame(width: 18, height: 18)
                        .background(Circle().fill(activeColor.opacity(0.16)).frame(width: 32, height: 32))
                        .position(x: proxy.size.width + 2, y: proxy.size.height + 2)
                        .highPriorityGesture(resizeEndGesture)
                        .accessibilityIdentifier("Availability End Handle")

                    Button(role: .destructive, action: onDelete) {
                        Image(systemName: "trash")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(activeColor)
                            .padding(5)
                            .background(.thinMaterial, in: Circle())
                    }
                    .buttonStyle(.plain)
                    .position(x: proxy.size.width - 12, y: 12)
                    .accessibilityIdentifier("Delete Availability Window")
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(isActive ? "Active Availability Window" : "Filled Availability Window")
        .accessibilityIdentifier(isActive ? "Active Availability Window" : "Filled Availability Window")
    }
}


#Preview {
    RootView()
}
