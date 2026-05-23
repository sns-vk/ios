import Combine
import SwiftUI
import UIKit

struct RootView: View {
    @State private var appState = AppState.mock()
    @State private var router = AppRouter()
    @State private var homeViewModel = HomeViewModel()
    @State private var showNetworkInfoPopup = false
    @State private var enrollmentShimmerTrigger = 0
    @State private var matchCardShimmerTrigger = 0
    @State private var hasShownMatchTab = false
    @State private var availabilityVisibleStartIndex = 5
    @State private var availabilityTopMinute = (16 * 60) + 30

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
                        triggerMatchCardShimmerIfNeeded()
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
            triggerMatchCardShimmerIfNeeded()
        }
        .onChange(of: homeViewModel.hasMatchThisWeek) { _, hasMatch in
            guard hasMatch else { return }
            triggerMatchCardShimmerIfNeeded()
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
            .listRowBackground(MatchCardShimmerBackground(trigger: matchCardShimmerTrigger))
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
                isEnrolledInBatch: isEnrolledInBatch,
                visibleStartIndex: $availabilityVisibleStartIndex,
                topVisibleMinute: $availabilityTopMinute
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

    private func triggerMatchCardShimmerIfNeeded() {
        guard homeViewModel.hasMatchThisWeek else { return }
        matchCardShimmerTrigger += 1
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

private struct MatchCardShimmerBackground: View {
    let trigger: Int
    @State private var shimmerPhase: CGFloat = 1.2

    var body: some View {
        RoundedRectangle(cornerRadius: 24, style: .continuous)
            .fill(Color(.secondarySystemGroupedBackground))
            .overlay {
                GeometryReader { proxy in
                    let width = proxy.size.width

                    Rectangle()
                        .fill(
                            LinearGradient(
                                stops: [
                                    .init(color: .clear, location: 0),
                                    .init(color: Color.accentColor.opacity(0.2), location: 0.5),
                                    .init(color: .clear, location: 1)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: width * 0.7)
                        .offset(x: shimmerPhase * width)
                }
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            }
            .onAppear {
                playShimmer()
            }
            .onChange(of: trigger) { _, _ in
                playShimmer()
            }
    }

    private func playShimmer() {
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            shimmerPhase = -0.75
        }

        DispatchQueue.main.async {
            withAnimation(.easeInOut(duration: 1.1)) {
                shimmerPhase = 1.2
            }
        }
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
    @Binding var visibleStartIndex: Int
    @Binding var topVisibleMinute: Int
    @State private var viewMode: AvailabilityViewMode = .multiDay
    @State private var activeWindowID: AvailabilityWindow.ID?
    @State private var editingWindowContext: AvailabilityWindowEditContext?

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .topLeading) {
                Color(.systemGroupedBackground)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        activeWindowID = nil
                    }

                VStack(alignment: .leading, spacing: 16) {
                    switch viewMode {
                    case .multiDay:
                        WeeklyAvailabilityEditor(
                            appState: appState,
                            isLocked: isEnrolledInBatch,
                            gridHeight: gridHeight(
                                for: proxy.size.height,
                                bottomSafeArea: proxy.safeAreaInsets.bottom
                            ),
                            activeWindowID: $activeWindowID,
                            visibleStartIndex: $visibleStartIndex,
                            topVisibleMinute: $topVisibleMinute,
                            onEditWindow: editWindow
                        )
                    case .list:
                        WeeklyAvailabilityListView(
                            appState: appState,
                            isLocked: isEnrolledInBatch,
                            activeWindowID: $activeWindowID
                        )
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Availability")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Availability")
                    .font(.headline)
                    .frame(minWidth: 180, minHeight: 44)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        activeWindowID = nil
                    }
            }
            ToolbarItem(placement: .topBarTrailing) {
                HStack(spacing: 8) {
                    Menu {
                        Picker("View", selection: $viewMode) {
                            ForEach(AvailabilityViewMode.allCases) { mode in
                                Label(mode.label, systemImage: mode.systemImage)
                                    .tag(mode)
                            }
                        }
                    } label: {
                        Image(systemName: viewMode.systemImage)
                            .frame(width: 44, height: 44)
                    }
                    .accessibilityLabel("Availability View")

                    Button {
                        addSlot()
                    } label: {
                        Image(systemName: "plus")
                            .frame(width: 44, height: 44)
                    }
                    .disabled(isEnrolledInBatch)
                    .accessibilityLabel("Add Slot")
                }
                .buttonStyle(.plain)
                .foregroundStyle(.primary)
            }
        }
        .sheet(item: $editingWindowContext) { context in
            AvailabilityWindowEditSheet(
                appState: appState,
                context: context,
                activeWindowID: $activeWindowID
            )
            .presentationDetents([.height(320)])
            .presentationDragIndicator(.visible)
        }
        .onDisappear {
            activeWindowID = nil
        }
    }

    private var activeWindowEditContext: AvailabilityWindowEditContext? {
        guard let activeWindowID else { return nil }

        let calendar = WeeklyAvailabilityCalendar.configuredCalendar()
        for availabilityDay in appState.weeklyAvailability {
            if let window = availabilityDay.windows.first(where: { $0.id == activeWindowID }) {
                return AvailabilityWindowEditContext(
                    date: calendar.startOfDay(for: availabilityDay.date),
                    window: window
                )
            }
        }

        return nil
    }

    private func editWindow(_ window: AvailabilityWindow, on date: Date) {
        let calendar = WeeklyAvailabilityCalendar.configuredCalendar()
        editingWindowContext = AvailabilityWindowEditContext(
            date: calendar.startOfDay(for: date),
            window: window
        )
    }

    private func addSlot() {
        let calendar = WeeklyAvailabilityCalendar.configuredCalendar()
        guard let date = activeWindowEditContext?.date ?? WeeklyAvailabilityCalendar.nextWeekDates(calendar: calendar).first else {
            return
        }

        let existingWindows = appState.availabilityMinuteWindows(on: date, calendar: calendar)
        guard let minuteWindow = defaultNewSlot(existingWindows: existingWindows) else {
            return
        }

        let savedWindow = appState.upsertAvailabilityWindow(minuteWindow, on: date, calendar: calendar)
        activeWindowID = savedWindow.id
        editingWindowContext = AvailabilityWindowEditContext(
            date: calendar.startOfDay(for: date),
            window: savedWindow
        )
    }

    private func defaultNewSlot(existingWindows: [AvailabilityMinuteWindow]) -> AvailabilityMinuteWindow? {
        let duration = 60
        let preferredStartMinute = (17 * 60)
        let latestStartMinute = WeeklyAvailabilityGridRules.endMinute - duration
        let candidateStarts = Array(stride(from: preferredStartMinute, through: latestStartMinute, by: 30))
            + Array(stride(from: WeeklyAvailabilityGridRules.startMinute, to: preferredStartMinute, by: 30))

        guard let startMinute = candidateStarts.first(where: { startMinute in
            let endMinute = startMinute + duration
            return !existingWindows.contains { startMinute < $0.endMinute && endMinute > $0.startMinute }
        }) else {
            return nil
        }

        return AvailabilityMinuteWindow(
            id: UUID(),
            startMinute: startMinute,
            endMinute: startMinute + duration
        )
    }

    private func gridHeight(for containerHeight: CGFloat, bottomSafeArea: CGFloat) -> CGFloat {
        let tabBarClearance: CGFloat = 96
        let reservedHeight = 130 + max(bottomSafeArea, tabBarClearance)
        return min(max(containerHeight - reservedHeight, 360), 620)
    }
}

private enum AvailabilityViewMode: String, CaseIterable, Identifiable {
    case multiDay
    case list

    var id: Self {
        self
    }

    var label: String {
        switch self {
        case .multiDay:
            return "Multi Day"
        case .list:
            return "List"
        }
    }

    var systemImage: String {
        switch self {
        case .multiDay:
            return "calendar.day.timeline.leading"
        case .list:
            return "list.bullet"
        }
    }
}

private struct AvailabilityWindowEditContext: Identifiable {
    let date: Date
    let window: AvailabilityWindow

    var id: AvailabilityWindow.ID {
        window.id
    }
}

private struct AvailabilityWindowEditSheet: View {
    @Bindable var appState: AppState
    let context: AvailabilityWindowEditContext
    @Binding var activeWindowID: AvailabilityWindow.ID?

    @Environment(\.dismiss) private var dismiss
    @State private var startTime: Date
    @State private var endTime: Date

    private var calendar: Calendar {
        WeeklyAvailabilityCalendar.configuredCalendar()
    }

    private var startMinute: Int {
        snappedMinute(from: startTime)
    }

    private var endMinute: Int {
        snappedMinute(from: endTime, treatingMidnightAsEnd: true)
    }

    private var overlapsExistingWindow: Bool {
        appState.availabilityMinuteWindows(on: context.date, calendar: calendar)
            .filter { $0.id != context.id }
            .contains { startMinute < $0.endMinute && endMinute > $0.startMinute }
    }

    private var canSave: Bool {
        endMinute - startMinute >= WeeklyAvailabilityGridRules.minimumDurationMinutes
            && !overlapsExistingWindow
    }

    init(
        appState: AppState,
        context: AvailabilityWindowEditContext,
        activeWindowID: Binding<AvailabilityWindow.ID?>
    ) {
        self.appState = appState
        self.context = context
        self._activeWindowID = activeWindowID
        self._startTime = State(initialValue: context.window.startTime)
        self._endTime = State(initialValue: context.window.endTime)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    DatePicker("Start", selection: $startTime, displayedComponents: .hourAndMinute)
                    DatePicker("End", selection: $endTime, displayedComponents: .hourAndMinute)
                }

                Section {
                    Button(role: .destructive) {
                        deleteWindow()
                    } label: {
                        Text("Delete Slot")
                            .frame(maxWidth: .infinity)
                    }
                }
            }
            .navigationTitle("Edit Slot")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveWindow()
                    }
                    .disabled(!canSave)
                }
            }
        }
    }

    private func saveWindow() {
        let editedWindow = AvailabilityMinuteWindow(
            id: context.id,
            startMinute: startMinute,
            endMinute: endMinute
        )
        let savedWindow = appState.upsertAvailabilityWindow(editedWindow, on: context.date, calendar: calendar)
        activeWindowID = savedWindow.id
        dismiss()
    }

    private func deleteWindow() {
        appState.removeAvailabilityWindow(context.id, on: context.date, calendar: calendar)
        activeWindowID = nil
        dismiss()
    }

    private func snappedMinute(from date: Date, treatingMidnightAsEnd: Bool = false) -> Int {
        let components = calendar.dateComponents([.hour, .minute], from: date)
        let minute = ((components.hour ?? 0) * 60) + (components.minute ?? 0)
        if treatingMidnightAsEnd && minute == WeeklyAvailabilityGridRules.startMinute {
            return WeeklyAvailabilityGridRules.endMinute
        }

        return WeeklyAvailabilityGridRules.snap(minute)
    }
}

private struct WeeklyAvailabilityListView: View {
    @Bindable var appState: AppState
    let isLocked: Bool
    @Binding var activeWindowID: AvailabilityWindow.ID?

    private var calendar: Calendar {
        WeeklyAvailabilityCalendar.configuredCalendar()
    }

    private var weekDates: [Date] {
        WeeklyAvailabilityCalendar.nextWeekDates(calendar: calendar)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                ForEach(weekDates, id: \.self) { date in
                    let windows = appState.availabilityWindows(on: date, calendar: calendar)

                    VStack(alignment: .leading, spacing: 8) {
                        Text(dayTitle(for: date))
                            .font(.headline)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 4)

                        VStack(spacing: 0) {
                            if windows.isEmpty {
                                Text("No slots")
                                    .font(.body)
                                    .foregroundStyle(.secondary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 14)
                            } else {
                                ForEach(windows) { window in
                                    AvailabilitySlotListRow(
                                        window: window,
                                        isActive: activeWindowID == window.id
                                    )
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        guard !isLocked else { return }
                                        activeWindowID = window.id
                                    }

                                    if window.id != windows.last?.id {
                                        Divider()
                                            .padding(.leading, 16)
                                    }
                                }
                            }
                        }
                        .background(Color(.secondarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                    }
                }
            }
            .padding(.bottom, 96)
        }
        .scrollIndicators(.hidden)
        .accessibilityIdentifier("Availability List")
    }

    private func dayTitle(for date: Date) -> String {
        "\(date.formatted(.dateTime.weekday(.wide))) – \(date.formatted(.dateTime.month(.abbreviated).day()))"
    }
}

private struct AvailabilitySlotListRow: View {
    let window: AvailabilityWindow
    let isActive: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "clock")
                .font(.body)
                .foregroundStyle(.secondary)
                .frame(width: 24)

            Text("\(window.startTime.formatted(date: .omitted, time: .shortened))–\(window.endTime.formatted(date: .omitted, time: .shortened))")
                .font(.body)

            Spacer()

            if isActive {
                Image(systemName: "checkmark.circle.fill")
                    .font(.body)
                    .foregroundStyle(.tint)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(isActive ? Color.accentColor.opacity(0.08) : Color.clear)
    }
}

private struct WeeklyAvailabilityEditor: View {
    @Bindable var appState: AppState
    let isLocked: Bool
    let gridHeight: CGFloat
    @Binding var activeWindowID: AvailabilityWindow.ID?
    @Binding var visibleStartIndex: Int
    @Binding var topVisibleMinute: Int
    let onEditWindow: (AvailabilityWindow, Date) -> Void

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
        guard let first = weekDates.first else {
            return "Next Week"
        }

        guard let last = weekDates.last else {
            return first.formatted(.dateTime.month(.wide).day())
        }

        if calendar.component(.month, from: first) == calendar.component(.month, from: last) {
            return "\(first.formatted(.dateTime.month(.wide).day())) – \(last.formatted(.dateTime.day()))"
        }

        return "\(first.formatted(.dateTime.month(.wide).day())) – \(last.formatted(.dateTime.month(.wide).day()))"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(visibleMonthTitle)
                .font(.headline)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 4)
                .contentShape(Rectangle())
                .onTapGesture {
                    clearActiveWindow()
                }

            WeeklyAvailabilityGrid(
                appState: appState,
                isLocked: isLocked,
                visibleStartIndex: visibleStartIndex,
                visibleDayCount: visibleDayCount,
                visibleDates: visibleDates,
                visibleGridHeight: gridHeight,
                activeWindowID: $activeWindowID,
                topVisibleMinute: $topVisibleMinute,
                onShiftVisibleDates: shiftVisibleDates,
                onSelectVisibleStartIndex: selectVisibleStartIndex,
                onEditWindow: onEditWindow
            )
            .padding(12)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        }
        .accessibilityIdentifier("Weekly Availability Editor")
        .onChange(of: isLocked) { _, newValue in
            if newValue {
                clearActiveWindow()
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

        clearActiveWindow()
        visibleStartIndex = nextIndex
    }

    private func clearActiveWindow() {
        activeWindowID = nil
    }
}

private enum AvailabilityCreationDirection {
    case upward
    case downward
}

private struct WeeklyAvailabilityGrid: View {
    @Bindable var appState: AppState
    let isLocked: Bool
    let visibleStartIndex: Int
    let visibleDayCount: Int
    let visibleDates: [Date]
    let visibleGridHeight: CGFloat
    @Binding var activeWindowID: AvailabilityWindow.ID?
    @Binding var topVisibleMinute: Int
    let onShiftVisibleDates: (Int) -> Void
    let onSelectVisibleStartIndex: (Int) -> Void
    let onEditWindow: (AvailabilityWindow, Date) -> Void

    @State private var movingOriginalWindow: AvailabilityMinuteWindow?
    @State private var movingPreviewWindow: AvailabilityMinuteWindow?
    @State private var resizingStartOriginalWindow: AvailabilityMinuteWindow?
    @State private var resizingEndOriginalWindow: AvailabilityMinuteWindow?
    @State private var resizingPreviewWindow: AvailabilityMinuteWindow?
    @State private var creatingWindowID: AvailabilityWindow.ID?
    @State private var creatingDate: Date?
    @State private var creatingPreviewWindow: AvailabilityMinuteWindow?
    @State private var creatingDirection: AvailabilityCreationDirection?
    @State private var scrollOffsetY: CGFloat = 0
    @State private var horizontalDragOffset: CGFloat = 0
    @State private var selectorVisibleStartIndex: Int
    @State private var pendingHorizontalSnap: DispatchWorkItem?

    private let timeLabelWidth: CGFloat = 50
    private let hourHeight: CGFloat = 56
    private let headerHeight: CGFloat = 38
    private let weekSelectorHeight: CGFloat = 84
    private let weekSelectorLabelOffsetY: CGFloat = -1
    private let weekSelectorDayFont: Font = .system(size: 18, weight: .medium)
    private let topScrollInset: CGFloat = 28
    private let initialTopMinute = (16 * 60) + 30
    private let slotHorizontalInset: CGFloat = 5
    private let bottomDragSlop: CGFloat = 28
    private let gridBottomPadding: CGFloat = 12
    private let trailingScrollHintWidth: CGFloat = 12
    private let slotControlOverflow: CGFloat = 22
    private let horizontalSnapDuration: TimeInterval = 0.22
    private let snapSettleDuration: TimeInterval = 0.18
    private let activeColor = Color.accentColor
    private let gridLineColor = Color(red: 0.88, green: 0.88, blue: 0.9)
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

    private var interactiveContentHeight: CGFloat {
        contentHeight + bottomDragSlop
    }

    private var maxVisibleStartIndex: Int {
        max(0, weekDates.count - visibleDayCount)
    }

    init(
        appState: AppState,
        isLocked: Bool,
        visibleStartIndex: Int,
        visibleDayCount: Int,
        visibleDates: [Date],
        visibleGridHeight: CGFloat,
        activeWindowID: Binding<AvailabilityWindow.ID?>,
        topVisibleMinute: Binding<Int>,
        onShiftVisibleDates: @escaping (Int) -> Void,
        onSelectVisibleStartIndex: @escaping (Int) -> Void,
        onEditWindow: @escaping (AvailabilityWindow, Date) -> Void
    ) {
        self.appState = appState
        self.isLocked = isLocked
        self.visibleStartIndex = visibleStartIndex
        self.visibleDayCount = visibleDayCount
        self.visibleDates = visibleDates
        self.visibleGridHeight = visibleGridHeight
        self._activeWindowID = activeWindowID
        self._topVisibleMinute = topVisibleMinute
        self.onShiftVisibleDates = onShiftVisibleDates
        self.onSelectVisibleStartIndex = onSelectVisibleStartIndex
        self.onEditWindow = onEditWindow
        self._selectorVisibleStartIndex = State(initialValue: visibleStartIndex)
    }

    var body: some View {
        GeometryReader { geometry in
            let dayViewportWidth = geometry.size.width - timeLabelWidth - trailingScrollHintWidth
            let dayWidth = max(dayViewportWidth / CGFloat(visibleDayCount), 96)
            let gridViewportHeight = max(visibleGridHeight - gridBottomPadding, 0)
            let stripOffsetX = horizontalStripOffset(dayWidth: dayWidth)
            let dayStripWidth = dayWidth * CGFloat(max(weekDates.count, 1))

            VStack(spacing: 0) {
                weekSelector
                    .simultaneousGesture(horizontalDateDragGesture(dayWidth: dayWidth))
                    .simultaneousGesture(clearActiveWindowGesture)
                VStack(spacing: 0) {
                    dayHeader(dayWidth: dayWidth, viewportWidth: dayViewportWidth, stripOffsetX: stripOffsetX)
                        .simultaneousGesture(horizontalDateDragGesture(dayWidth: dayWidth))
                        .simultaneousGesture(clearActiveWindowGesture)

                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(spacing: 0) {
                            Color.clear
                                .frame(height: topScrollInset)

                            ZStack(alignment: .topLeading) {
                                gridLines(totalWidth: geometry.size.width, dayWidth: dayWidth)
                                timeGutterSeparator(height: interactiveContentHeight, showsShadow: true)
                                dayStrip(
                                    dayWidth: dayWidth,
                                    dayStripWidth: dayStripWidth,
                                    height: interactiveContentHeight,
                                    stripOffsetX: stripOffsetX
                                )
                                .simultaneousGesture(horizontalDateDragGesture(dayWidth: dayWidth))
                                .frame(width: dayViewportWidth + slotControlOverflow, height: interactiveContentHeight, alignment: .topLeading)
                                .clipped()
                                .background(alignment: .topLeading) {
                                    viewportTrailingSeparator(height: interactiveContentHeight)
                                        .offset(x: dayViewportWidth)
                                }
                                .offset(x: timeLabelWidth)
                            }
                            .frame(width: geometry.size.width, height: interactiveContentHeight, alignment: .topLeading)
                            .coordinateSpace(name: contentCoordinateSpace)

                            Color.clear
                                .frame(height: bottomScrollInset(for: gridViewportHeight))
                        }
                        .background {
                            AvailabilityScrollViewObserver(
                                topInset: topScrollInset,
                                restoreContentOffsetY: minuteY(boundedMinute(topVisibleMinute)),
                                onOffsetChanged: { nextOffset in
                                    scrollOffsetY = nextOffset
                                },
                                onUserScrollEnded: { finalOffset in
                                    saveTopVisibleMinute(fromContentY: finalOffset)
                                }
                            )
                            .frame(width: 0, height: 0)
                        }
                    }
                    .frame(height: gridViewportHeight)
                    .background(alignment: .topLeading) {
                        columnSeparators(dayWidth: dayWidth, height: gridViewportHeight, dayCount: weekDates.count)
                            .frame(width: dayStripWidth, height: gridViewportHeight, alignment: .topLeading)
                            .offset(x: stripOffsetX)
                            .frame(width: dayViewportWidth, height: gridViewportHeight, alignment: .topLeading)
                            .clipped()
                            .offset(x: timeLabelWidth)
                    }
                    .clipped()
                    .contentMargins(.all, 0, for: .scrollContent)
                    .scrollIndicators(.hidden)
                    .onAppear {
                        let minute = boundedMinute(topVisibleMinute)
                        scrollOffsetY = minuteY(minute)
                    }

                    Color.clear
                        .frame(height: gridBottomPadding)
                }
            }
        }
        .frame(height: weekSelectorHeight + headerHeight + visibleGridHeight)
        .contentShape(Rectangle())
        .onAppear {
            selectorVisibleStartIndex = visibleStartIndex
        }
        .onChange(of: visibleStartIndex) { _, newValue in
            guard selectorVisibleStartIndex != newValue else { return }
            animateSelector(to: newValue)
        }
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
            let pillY: CGFloat = 30
            let circleSize: CGFloat = 32
            let circleY = pillY + ((pillHeight - circleSize) / 2)
            let selectedStartIndex = CGFloat(selectorVisibleStartIndex)
            let circleX = (dayWidth * selectedStartIndex) + ((dayWidth - circleSize) / 2)
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
                        .animation(.easeInOut(duration: 0.2), value: selectorVisibleStartIndex)

                    Circle()
                        .fill(Color.accentColor)
                        .frame(width: circleSize, height: circleSize)
                        .offset(
                            x: circleX,
                            y: circleY
                        )
                        .animation(.easeInOut(duration: 0.2), value: selectorVisibleStartIndex)
                }

                HStack(spacing: 0) {
                    ForEach(Array(weekDates.enumerated()), id: \.element) { index, date in
                        Button {
                            animateSelector(to: boundedVisibleStartIndex(index))
                            onSelectVisibleStartIndex(index)
                        } label: {
                            VStack(spacing: 6) {
                                Text(date.formatted(.dateTime.weekday(.abbreviated)))
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.secondary)

                                Text(date.formatted(.dateTime.day()))
                                    .font(weekSelectorDayFont)
                                    .foregroundStyle(.primary)
                                    .frame(height: circleSize + 2)
                            }
                            .frame(maxWidth: .infinity, minHeight: weekSelectorHeight)
                            .offset(y: weekSelectorLabelOffsetY)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("Availability Week Selector \(weekdayName(for: date))")
                    }
                }

                selectedDateNumberOverlay(
                    dayWidth: dayWidth,
                    selectorHeight: weekSelectorHeight,
                    labelOffsetY: weekSelectorLabelOffsetY,
                    circleX: circleX,
                    circleY: circleY,
                    circleSize: circleSize
                )
                    .allowsHitTesting(false)
            }
        }
        .frame(height: weekSelectorHeight)
        .overlay(alignment: .bottom) {
            dayDividerLine()
        }
    }

    private func selectedDateNumberOverlay(
        dayWidth: CGFloat,
        selectorHeight: CGFloat,
        labelOffsetY: CGFloat,
        circleX: CGFloat,
        circleY: CGFloat,
        circleSize: CGFloat
    ) -> some View {
        HStack(spacing: 0) {
            ForEach(Array(weekDates.enumerated()), id: \.element) { _, date in
                VStack(spacing: 6) {
                    Text(date.formatted(.dateTime.weekday(.abbreviated)))
                        .font(.caption.weight(.semibold))
                        .hidden()

                    Text(date.formatted(.dateTime.day()))
                        .font(weekSelectorDayFont)
                        .foregroundStyle(.white)
                        .frame(height: circleSize + 2)
                }
                .frame(width: dayWidth, height: selectorHeight)
                .offset(y: labelOffsetY)
            }
        }
        .mask(alignment: .topLeading) {
            Circle()
                .frame(width: circleSize, height: circleSize)
                .offset(
                    x: circleX,
                    y: circleY
                )
        }
        .animation(.easeInOut(duration: 0.2), value: selectorVisibleStartIndex)
    }

    private func animateSelector(to index: Int) {
        withAnimation(.easeInOut(duration: 0.2)) {
            selectorVisibleStartIndex = boundedVisibleStartIndex(index)
        }
    }

    private func dayHeader(dayWidth: CGFloat, viewportWidth: CGFloat, stripOffsetX: CGFloat) -> some View {
        HStack(spacing: 0) {
            Color.clear
                .frame(width: timeLabelWidth)

            HStack(spacing: 0) {
                ForEach(weekDates, id: \.self) { date in
                    Text(dayHeaderLabel(for: date))
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                        .frame(width: dayWidth, height: headerHeight)
                        .accessibilityIdentifier("Availability Day Header \(weekdayName(for: date))")
                }
            }
            .offset(x: stripOffsetX)
            .frame(width: viewportWidth, height: headerHeight, alignment: .leading)
            .clipped()
            .overlay(alignment: .trailing) {
                viewportTrailingSeparator(height: headerHeight)
            }

            Color.clear
                .frame(width: trailingScrollHintWidth)
        }
        .background(Color(.secondarySystemGroupedBackground))
        .overlay(alignment: .topLeading) {
            timeGutterSeparator(height: headerHeight, showsShadow: true)
        }
        .overlay(alignment: .topLeading) {
            columnSeparators(dayWidth: dayWidth, height: headerHeight, dayCount: weekDates.count)
                .offset(x: stripOffsetX)
                .frame(width: viewportWidth, height: headerHeight, alignment: .topLeading)
                .clipped()
                .offset(x: timeLabelWidth)
        }
        .overlay(alignment: .bottom) {
            dayDividerLine()
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
            .stroke(gridLineColor, lineWidth: 1)

            ForEach(Array(stride(from: 0, through: 24, by: 1)), id: \.self) { hour in
                Text(timeLabel(for: hour))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(width: timeLabelWidth - 6, alignment: .trailing)
                    .offset(x: 0, y: minuteY(hour * 60) - 8)
            }
        }
    }

    private func bottomScrollInset(for viewportHeight: CGFloat) -> CGFloat {
        max(viewportHeight - (contentHeight - minuteY(initialTopMinute)), 0)
    }

    private func columnSeparators(dayWidth: CGFloat, height: CGFloat, dayCount: Int) -> some View {
        Path { path in
            for dayIndex in 0...dayCount {
                let x = CGFloat(dayIndex) * dayWidth
                path.move(to: CGPoint(x: x, y: 0))
                path.addLine(to: CGPoint(x: x, y: height))
            }
        }
        .stroke(gridLineColor, lineWidth: 1)
        .allowsHitTesting(false)
    }

    private func timeGutterSeparator(height: CGFloat, showsShadow: Bool) -> some View {
        ZStack(alignment: .topLeading) {
            if showsShadow {
                Rectangle()
                    .fill(.black.opacity(0.08))
                    .frame(width: 1, height: height)
                    .blur(radius: 2)
                    .offset(x: timeLabelWidth + 2)
            }

            Rectangle()
                .fill(gridLineColor)
                .frame(width: 1, height: height)
                .offset(x: timeLabelWidth)
        }
        .allowsHitTesting(false)
    }

    private func viewportTrailingSeparator(height: CGFloat) -> some View {
        Rectangle()
            .fill(gridLineColor)
            .frame(width: 1, height: height)
            .allowsHitTesting(false)
    }

    private func dayDividerLine() -> some View {
        ZStack(alignment: .top) {
            Rectangle()
                .fill(.black.opacity(0.08))
                .frame(height: 1)
                .blur(radius: 2)
                .offset(y: 2)

            Rectangle()
                .fill(gridLineColor)
                .frame(height: 1)
        }
        .allowsHitTesting(false)
    }

    private func dayStrip(dayWidth: CGFloat, dayStripWidth: CGFloat, height: CGFloat, stripOffsetX: CGFloat) -> some View {
        ZStack(alignment: .topLeading) {
            columnSeparators(dayWidth: dayWidth, height: height, dayCount: weekDates.count)
            AvailabilityCreationGestureOverlay(
                dates: weekDates,
                dayWidth: dayWidth,
                isEnabled: !isLocked,
                onTap: {
                    activeWindowID = nil
                },
                onChanged: { date, id, anchorY, currentY in
                    if creatingWindowID != id {
                        activeWindowID = nil
                        creatingDirection = nil
                    }
                    let nextDirection = creationDirection(
                        anchorContentY: anchorY,
                        currentContentY: currentY
                    )
                    let direction = creatingDirection ?? nextDirection ?? .downward

                    creatingWindowID = id
                    creatingDate = date
                    if let nextDirection {
                        creatingDirection = nextDirection
                    }
                    creatingPreviewWindow = previewCreatingWindow(
                        id: id,
                        on: date,
                        anchorContentY: anchorY,
                        currentContentY: currentY,
                        direction: direction
                    )
                },
                onEnded: {
                    if let creatingDate, let creatingPreviewWindow {
                        finishCreatingWindow(creatingPreviewWindow, on: creatingDate)
                    } else {
                        clearCreatingWindow()
                    }
                }
            )
            .frame(width: dayStripWidth, height: height)
            availabilityWindows(dayWidth: dayWidth)
        }
        .frame(width: dayStripWidth, height: height, alignment: .topLeading)
        .offset(x: stripOffsetX)
    }

    private func availabilityWindows(dayWidth: CGFloat) -> some View {
        ForEach(Array(weekDates.enumerated()), id: \.element) { dayIndex, date in
            Group {
                ForEach(appState.availabilityWindows(on: date, calendar: calendar)) { window in
                    if creatingPreviewWindow?.id != window.id {
                        let minuteWindow = minuteWindow(for: window, on: date)
                        availabilityWindowView(
                            window: window,
                            minuteWindow: minuteWindow,
                            date: date,
                            dayIndex: dayIndex,
                            dayWidth: dayWidth,
                            isCreating: false
                        )
                    }
                }

                if let creatingPreviewWindow,
                   let creatingDate,
                   calendar.isDate(creatingDate, inSameDayAs: date) {
                    let window = availabilityWindow(for: creatingPreviewWindow, on: date)
                    availabilityWindowView(
                        window: window,
                        minuteWindow: creatingPreviewWindow,
                        date: date,
                        dayIndex: dayIndex,
                        dayWidth: dayWidth,
                        isCreating: creatingWindowID == creatingPreviewWindow.id
                    )
                }
            }
        }
    }

    private func availabilityWindowView(
        window: AvailabilityWindow,
        minuteWindow: AvailabilityMinuteWindow,
        date: Date,
        dayIndex: Int,
        dayWidth: CGFloat,
        isCreating: Bool
    ) -> some View {
        let displayMinuteWindow: AvailabilityMinuteWindow
        if movingPreviewWindow?.id == minuteWindow.id {
            displayMinuteWindow = movingPreviewWindow ?? minuteWindow
        } else if resizingPreviewWindow?.id == minuteWindow.id {
            displayMinuteWindow = resizingPreviewWindow ?? minuteWindow
        } else {
            displayMinuteWindow = minuteWindow
        }
        let labelWindow = availabilityWindow(for: labelMinuteWindow(for: displayMinuteWindow), on: date)
        let isActive = !isLocked && !isCreating && activeWindowID == window.id
        let windowHeight = max(minuteHeight(displayMinuteWindow.endMinute - displayMinuteWindow.startMinute), 28)

        return AvailabilityWindowBlock(
            window: labelWindow,
            isActive: isActive,
            isLocked: isLocked,
            activeColor: activeColor,
            onEdit: {
                onEditWindow(window, date)
            },
            moveGesture: moveGesture(for: minuteWindow, on: date),
            resizeStartGesture: resizeStartGesture(for: minuteWindow, on: date),
            resizeEndGesture: resizeEndGesture(for: minuteWindow, on: date)
        )
        .frame(width: max(dayWidth - (slotHorizontalInset * 2), 26), height: windowHeight)
        .position(
            x: (CGFloat(dayIndex) * dayWidth) + (dayWidth / 2),
            y: minuteY(displayMinuteWindow.startMinute) + (windowHeight / 2)
        )
        .onTapGesture {
            guard !isLocked else { return }
            activeWindowID = window.id
        }
        .allowsHitTesting(!isCreating)
        .zIndex(isActive ? 2 : isCreating ? 1.5 : 1)
    }

    private func horizontalDateDragGesture(dayWidth: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 28)
            .onChanged { value in
                pendingHorizontalSnap?.cancel()
                pendingHorizontalSnap = nil

                guard isHorizontalDateDrag(value) else {
                    horizontalDragOffset = 0
                    return
                }

                horizontalDragOffset = boundedHorizontalDrag(value.translation.width, dayWidth: dayWidth)
            }
            .onEnded { value in
                guard isHorizontalDateDrag(value) else {
                    horizontalDragOffset = 0
                    return
                }

                let proposedDayOffset = Int(round(-value.translation.width / dayWidth))
                let targetStartIndex = boundedVisibleStartIndex(visibleStartIndex + proposedDayOffset)
                let dayOffset = targetStartIndex - visibleStartIndex
                guard dayOffset != 0 else {
                    withAnimation(.easeOut(duration: horizontalSnapDuration)) {
                        horizontalDragOffset = 0
                    }
                    return
                }

                withAnimation(.easeOut(duration: horizontalSnapDuration)) {
                    horizontalDragOffset = boundedHorizontalDrag(-CGFloat(dayOffset) * dayWidth, dayWidth: dayWidth)
                }

                let snapWorkItem = DispatchWorkItem {
                    var transaction = Transaction()
                    transaction.disablesAnimations = true
                    withTransaction(transaction) {
                        horizontalDragOffset = 0
                        onSelectVisibleStartIndex(targetStartIndex)
                    }
                    animateSelector(to: targetStartIndex)
                    pendingHorizontalSnap = nil
                }
                pendingHorizontalSnap = snapWorkItem
                DispatchQueue.main.asyncAfter(deadline: .now() + horizontalSnapDuration, execute: snapWorkItem)
            }
    }

    private func isHorizontalDateDrag(_ value: DragGesture.Value) -> Bool {
        abs(value.translation.width) > abs(value.translation.height)
            && abs(value.translation.width) > 24
    }

    private func horizontalStripOffset(dayWidth: CGFloat) -> CGFloat {
        let baseOffset = -CGFloat(visibleStartIndex) * dayWidth
        let proposedOffset = baseOffset + horizontalDragOffset
        return min(max(proposedOffset, -CGFloat(maxVisibleStartIndex) * dayWidth), 0)
    }

    private func boundedHorizontalDrag(_ translation: CGFloat, dayWidth: CGFloat) -> CGFloat {
        let baseOffset = -CGFloat(visibleStartIndex) * dayWidth
        let proposedOffset = baseOffset + translation
        let boundedOffset = min(max(proposedOffset, -CGFloat(maxVisibleStartIndex) * dayWidth), 0)
        return boundedOffset - baseOffset
    }

    private func boundedVisibleStartIndex(_ index: Int) -> Int {
        min(max(index, 0), maxVisibleStartIndex)
    }

    private var clearActiveWindowGesture: some Gesture {
        TapGesture()
            .onEnded {
                guard !isLocked else { return }
                activeWindowID = nil
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
                movingPreviewWindow = previewMovedWindow(
                    originalWindow,
                    on: date,
                    targetStartContentY: currentContentY - grabOffsetY
                )
            }
            .onEnded { value in
                guard !isLocked else {
                    movingOriginalWindow = nil
                    movingPreviewWindow = nil
                    return
                }

                let originalWindow = movingOriginalWindow ?? minuteWindow
                let grabOffsetY = boundedContentY(value.startLocation.y) - minuteY(originalWindow.startMinute)
                let currentContentY = boundedContentY(value.location.y)
                withAnimation(.easeOut(duration: snapSettleDuration)) {
                    updateMovedWindow(originalWindow, on: date, targetStartContentY: currentContentY - grabOffsetY)
                    movingPreviewWindow = nil
                }
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
                resizingPreviewWindow = previewResizedStartWindow(
                    originalWindow,
                    on: date,
                    targetContentY: currentContentY - grabOffsetY
                )
            }
            .onEnded { value in
                guard !isLocked else {
                    resizingStartOriginalWindow = nil
                    resizingPreviewWindow = nil
                    return
                }

                let originalWindow = resizingStartOriginalWindow ?? minuteWindow
                let grabOffsetY = boundedContentY(value.startLocation.y) - minuteY(originalWindow.startMinute)
                let currentContentY = boundedContentY(value.location.y)
                withAnimation(.easeOut(duration: snapSettleDuration)) {
                    updateResizedStartWindow(originalWindow, on: date, targetContentY: currentContentY - grabOffsetY)
                    resizingPreviewWindow = nil
                }
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
                resizingPreviewWindow = previewResizedEndWindow(
                    originalWindow,
                    on: date,
                    targetContentY: currentContentY - grabOffsetY
                )
            }
            .onEnded { value in
                guard !isLocked else {
                    resizingEndOriginalWindow = nil
                    resizingPreviewWindow = nil
                    return
                }

                let originalWindow = resizingEndOriginalWindow ?? minuteWindow
                let grabOffsetY = boundedContentY(value.startLocation.y) - minuteY(originalWindow.endMinute)
                let currentContentY = boundedContentY(value.location.y)
                withAnimation(.easeOut(duration: snapSettleDuration)) {
                    updateResizedEndWindow(originalWindow, on: date, targetContentY: currentContentY - grabOffsetY)
                    resizingPreviewWindow = nil
                }
                resizingEndOriginalWindow = nil
            }
    }

    private func previewCreatingWindow(
        id: UUID,
        on date: Date,
        anchorContentY: CGFloat,
        currentContentY: CGFloat,
        direction: AvailabilityCreationDirection
    ) -> AvailabilityMinuteWindow? {
        let existingWindows = appState
            .availabilityMinuteWindows(on: date, calendar: calendar)
            .filter { $0.id != id }

        let anchorRawMinute = rawMinute(forContentY: anchorContentY)
        let anchorStartMinute = floorSnappedMinute(anchorRawMinute)
        let current = rawMinute(forContentY: currentContentY)
        let sortedWindows = existingWindows.sorted { $0.startMinute < $1.startMinute }
        let nextStart = sortedWindows
            .filter { $0.startMinute >= anchorStartMinute }
            .map(\.startMinute)
            .min() ?? WeeklyAvailabilityGridRules.endMinute

        if direction == .downward {
            let end = min(max(current, anchorStartMinute + WeeklyAvailabilityGridRules.minimumDurationMinutes), nextStart)
            guard end - anchorStartMinute >= WeeklyAvailabilityGridRules.minimumDurationMinutes else { return nil }
            return AvailabilityMinuteWindow(id: id, startMinute: anchorStartMinute, endMinute: end)
        }

        let anchoredEndMinute = min(anchorStartMinute + WeeklyAvailabilityGridRules.minimumDurationMinutes, nextStart)
        let previousEnd = sortedWindows
            .filter { $0.endMinute <= anchoredEndMinute }
            .map(\.endMinute)
            .max() ?? WeeklyAvailabilityGridRules.startMinute
        let start = max(min(current, anchoredEndMinute - WeeklyAvailabilityGridRules.minimumDurationMinutes), previousEnd)
        guard anchoredEndMinute - start >= WeeklyAvailabilityGridRules.minimumDurationMinutes else { return nil }
        return AvailabilityMinuteWindow(id: id, startMinute: start, endMinute: anchoredEndMinute)
    }

    private func creationDirection(anchorContentY: CGFloat, currentContentY: CGFloat) -> AvailabilityCreationDirection? {
        let deltaY = currentContentY - anchorContentY
        guard abs(deltaY) >= 1 else { return nil }
        return deltaY < 0 ? .upward : .downward
    }

    private func commitCreatingWindow(_ previewWindow: AvailabilityMinuteWindow, on date: Date) -> AvailabilityWindow? {
        let minuteWindow = AvailabilityMinuteWindow(
            id: previewWindow.id,
            startMinute: snappedMinute(previewWindow.startMinute),
            endMinute: snappedMinute(previewWindow.endMinute)
        )
        guard minuteWindow.endMinute - minuteWindow.startMinute >= WeeklyAvailabilityGridRules.minimumDurationMinutes,
              canCommitCreatedWindow(minuteWindow, on: date) else {
            return nil
        }

        return appState.upsertAvailabilityWindow(minuteWindow, on: date, calendar: calendar)
    }

    private func canCommitCreatedWindow(_ minuteWindow: AvailabilityMinuteWindow, on date: Date) -> Bool {
        appState
            .availabilityMinuteWindows(on: date, calendar: calendar)
            .filter { $0.id != minuteWindow.id }
            .allSatisfy { existingWindow in
                minuteWindow.endMinute <= existingWindow.startMinute
                    || minuteWindow.startMinute >= existingWindow.endMinute
            }
    }

    private func finishCreatingWindow(_ previewWindow: AvailabilityMinuteWindow, on date: Date) {
        guard let savedWindow = commitCreatingWindow(previewWindow, on: date) else {
            clearCreatingWindow()
            return
        }

        let snappedWindow = minuteWindow(for: savedWindow, on: date)
        withAnimation(.easeOut(duration: snapSettleDuration)) {
            activeWindowID = savedWindow.id
            creatingWindowID = nil
            creatingPreviewWindow = snappedWindow
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + snapSettleDuration) {
            guard creatingPreviewWindow?.id == snappedWindow.id else { return }
            clearCreatingWindow()
        }
    }

    private func clearCreatingWindow() {
        creatingWindowID = nil
        creatingDate = nil
        creatingPreviewWindow = nil
        creatingDirection = nil
    }

    private func updateMovedWindow(_ originalWindow: AvailabilityMinuteWindow, on date: Date, targetStartContentY: CGFloat) {
        let movedWindow = WeeklyAvailabilityGridRules.moveWindowMinutes(
            proposedStartMinute: minute(forContentY: targetStartContentY),
            originalWindow: originalWindow,
            existingWindows: appState.availabilityMinuteWindows(on: date, calendar: calendar)
        )

        appState.upsertAvailabilityWindow(movedWindow, on: date, calendar: calendar)
    }

    private func previewMovedWindow(
        _ originalWindow: AvailabilityMinuteWindow,
        on date: Date,
        targetStartContentY: CGFloat
    ) -> AvailabilityMinuteWindow {
        let duration = originalWindow.endMinute - originalWindow.startMinute
        let existingWindows = appState.availabilityMinuteWindows(on: date, calendar: calendar)
        let previousEnd = existingWindows
            .filter { $0.id != originalWindow.id && $0.endMinute <= originalWindow.startMinute }
            .map(\.endMinute)
            .max() ?? WeeklyAvailabilityGridRules.startMinute
        let nextStart = existingWindows
            .filter { $0.id != originalWindow.id && $0.startMinute >= originalWindow.endMinute }
            .map(\.startMinute)
            .min() ?? WeeklyAvailabilityGridRules.endMinute
        let lowerBound = previousEnd
        let upperBound = nextStart - duration
        let startMinute = min(max(rawMinute(forContentY: targetStartContentY), lowerBound), upperBound)

        return AvailabilityMinuteWindow(
            id: originalWindow.id,
            startMinute: startMinute,
            endMinute: startMinute + duration
        )
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

    private func previewResizedStartWindow(
        _ originalWindow: AvailabilityMinuteWindow,
        on date: Date,
        targetContentY: CGFloat
    ) -> AvailabilityMinuteWindow {
        let existingWindows = appState.availabilityMinuteWindows(on: date, calendar: calendar)
        let lowerBound = existingWindows
            .filter { $0.id != originalWindow.id && $0.endMinute <= originalWindow.endMinute }
            .map(\.endMinute)
            .max() ?? WeeklyAvailabilityGridRules.startMinute
        let upperBound = originalWindow.endMinute - WeeklyAvailabilityGridRules.minimumDurationMinutes
        let startMinute = min(max(rawMinute(forContentY: targetContentY), lowerBound), upperBound)

        return AvailabilityMinuteWindow(
            id: originalWindow.id,
            startMinute: startMinute,
            endMinute: originalWindow.endMinute
        )
    }

    private func previewResizedEndWindow(
        _ originalWindow: AvailabilityMinuteWindow,
        on date: Date,
        targetContentY: CGFloat
    ) -> AvailabilityMinuteWindow {
        let existingWindows = appState.availabilityMinuteWindows(on: date, calendar: calendar)
        let lowerBound = originalWindow.startMinute + WeeklyAvailabilityGridRules.minimumDurationMinutes
        let upperBound = existingWindows
            .filter { $0.id != originalWindow.id && $0.startMinute >= originalWindow.startMinute }
            .map(\.startMinute)
            .min() ?? WeeklyAvailabilityGridRules.endMinute
        let endMinute = max(min(rawMinute(forContentY: targetContentY), upperBound), lowerBound)

        return AvailabilityMinuteWindow(
            id: originalWindow.id,
            startMinute: originalWindow.startMinute,
            endMinute: endMinute
        )
    }

    private func minuteWindow(for window: AvailabilityWindow, on date: Date) -> AvailabilityMinuteWindow {
        AvailabilityMinuteWindow(
            id: window.id,
            startMinute: minuteOffset(for: window.startTime, on: date),
            endMinute: minuteOffset(for: window.endTime, on: date)
        )
    }

    private func availabilityWindow(for minuteWindow: AvailabilityMinuteWindow, on date: Date) -> AvailabilityWindow {
        let day = calendar.startOfDay(for: date)
        return AvailabilityWindow(
            id: minuteWindow.id,
            startTime: WeeklyAvailabilityCalendar.date(on: day, minuteOfDay: minuteWindow.startMinute, calendar: calendar),
            endTime: WeeklyAvailabilityCalendar.date(on: day, minuteOfDay: minuteWindow.endMinute, calendar: calendar)
        )
    }

    private func labelMinuteWindow(for minuteWindow: AvailabilityMinuteWindow) -> AvailabilityMinuteWindow {
        AvailabilityMinuteWindow(
            id: minuteWindow.id,
            startMinute: snappedMinute(minuteWindow.startMinute),
            endMinute: snappedMinute(minuteWindow.endMinute)
        )
    }

    private func minuteOffset(for time: Date, on date: Date) -> Int {
        let day = calendar.startOfDay(for: date)
        let rawMinute = Int((time.timeIntervalSince(day) / 60).rounded())
        return min(max(rawMinute, WeeklyAvailabilityGridRules.startMinute), WeeklyAvailabilityGridRules.endMinute)
    }

    private func minute(forContentY y: CGFloat) -> Int {
        WeeklyAvailabilityGridRules.snap(rawMinute(forContentY: y))
    }

    private func snappedMinute(_ minute: Int) -> Int {
        WeeklyAvailabilityGridRules.snap(minute)
    }

    private func floorSnappedMinute(_ minute: Int) -> Int {
        let interval = WeeklyAvailabilityGridRules.snapIntervalMinutes
        let snapped = (minute / interval) * interval
        return min(max(snapped, WeeklyAvailabilityGridRules.startMinute), WeeklyAvailabilityGridRules.endMinute)
    }

    private func ceilingSnappedMinute(_ minute: Int) -> Int {
        let interval = WeeklyAvailabilityGridRules.snapIntervalMinutes
        let snapped = ((minute + interval - 1) / interval) * interval
        return min(max(snapped, WeeklyAvailabilityGridRules.startMinute), WeeklyAvailabilityGridRules.endMinute)
    }

    private func rawMinute(forContentY y: CGFloat) -> Int {
        let rawMinute = WeeklyAvailabilityGridRules.startMinute + Int((boundedContentY(y) / hourHeight) * 60)
        return min(max(rawMinute, WeeklyAvailabilityGridRules.startMinute), WeeklyAvailabilityGridRules.endMinute)
    }

    private func saveTopVisibleMinute(fromContentY y: CGFloat) {
        let minute = rawMinute(forContentY: y)
        if topVisibleMinute != minute {
            topVisibleMinute = minute
        }
    }

    private func boundedMinute(_ minute: Int) -> Int {
        min(max(minute, WeeklyAvailabilityGridRules.startMinute), WeeklyAvailabilityGridRules.endMinute)
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

private struct AvailabilityScrollViewObserver: UIViewRepresentable {
    let topInset: CGFloat
    let restoreContentOffsetY: CGFloat
    let onOffsetChanged: (CGFloat) -> Void
    let onUserScrollEnded: (CGFloat) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        view.backgroundColor = .clear
        view.isUserInteractionEnabled = false
        context.coordinator.attach(from: view)
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        context.coordinator.parent = self
        context.coordinator.attach(from: uiView)
    }

    final class Coordinator: NSObject {
        var parent: AvailabilityScrollViewObserver
        private weak var scrollView: UIScrollView?
        private var contentOffsetObservation: NSKeyValueObservation?
        private var isTrackingUserScroll = false
        private var didRestoreInitialOffset = false

        init(_ parent: AvailabilityScrollViewObserver) {
            self.parent = parent
        }

        deinit {
            if let scrollView {
                scrollView.panGestureRecognizer.removeTarget(self, action: #selector(handlePan(_:)))
            }
            contentOffsetObservation?.invalidate()
        }

        func attach(from view: UIView) {
            DispatchQueue.main.async { [weak self, weak view] in
                guard let self, let view, let scrollView = view.enclosingScrollView else { return }
                guard scrollView !== self.scrollView else { return }

                if let existingScrollView = self.scrollView {
                    existingScrollView.panGestureRecognizer.removeTarget(self, action: #selector(self.handlePan(_:)))
                }

                self.contentOffsetObservation?.invalidate()
                self.scrollView = scrollView
                scrollView.panGestureRecognizer.addTarget(self, action: #selector(self.handlePan(_:)))
                self.contentOffsetObservation = scrollView.observe(\.contentOffset, options: [.new]) { [weak self] scrollView, _ in
                    self?.parent.onOffsetChanged(self?.contentOffsetY(for: scrollView) ?? 0)
                }
                self.restoreInitialOffsetIfNeeded(in: scrollView)
            }
        }

        private func restoreInitialOffsetIfNeeded(in scrollView: UIScrollView) {
            guard !didRestoreInitialOffset else { return }
            didRestoreInitialOffset = true

            DispatchQueue.main.async { [weak self, weak scrollView] in
                guard let self, let scrollView else { return }
                let targetY = self.parent.topInset + self.parent.restoreContentOffsetY
                let maxY = max(0, scrollView.contentSize.height - scrollView.bounds.height)
                let boundedY = min(max(targetY, 0), maxY)
                scrollView.setContentOffset(CGPoint(x: scrollView.contentOffset.x, y: boundedY), animated: false)
                self.parent.onOffsetChanged(self.contentOffsetY(for: scrollView))
            }
        }

        @objc private func handlePan(_ recognizer: UIPanGestureRecognizer) {
            guard let scrollView else { return }

            switch recognizer.state {
            case .began, .changed:
                isTrackingUserScroll = true
            case .ended:
                guard isTrackingUserScroll else { return }
                finishUserScrollWhenSettled(in: scrollView)
            case .cancelled, .failed:
                if isTrackingUserScroll {
                    finishUserScroll(in: scrollView)
                }
            default:
                break
            }
        }

        private func finishUserScrollWhenSettled(in scrollView: UIScrollView) {
            guard scrollView.isDecelerating else {
                finishUserScroll(in: scrollView)
                return
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) { [weak self, weak scrollView] in
                guard let self, let scrollView else { return }
                self.finishUserScrollWhenSettled(in: scrollView)
            }
        }

        private func finishUserScroll(in scrollView: UIScrollView) {
            isTrackingUserScroll = false
            DispatchQueue.main.async { [weak self, weak scrollView] in
                guard let self, let scrollView else { return }
                self.parent.onUserScrollEnded(self.contentOffsetY(for: scrollView))
            }
        }

        private func contentOffsetY(for scrollView: UIScrollView) -> CGFloat {
            max(0, scrollView.contentOffset.y - parent.topInset)
        }
    }
}

private extension UIView {
    var enclosingScrollView: UIScrollView? {
        var view = superview
        while let currentView = view {
            if let scrollView = currentView as? UIScrollView {
                return scrollView
            }

            view = currentView.superview
        }

        return nil
    }
}

private struct AvailabilityCreationGestureOverlay: UIViewRepresentable {
    let dates: [Date]
    let dayWidth: CGFloat
    let isEnabled: Bool
    let onTap: () -> Void
    let onChanged: (Date, UUID, CGFloat, CGFloat) -> Void
    let onEnded: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .clear
        context.coordinator.install(on: view)
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        context.coordinator.parent = self
        uiView.isUserInteractionEnabled = isEnabled
    }

    final class Coordinator: NSObject, UIGestureRecognizerDelegate {
        var parent: AvailabilityCreationGestureOverlay
        private var activeID: UUID?
        private var activeDate: Date?
        private var anchorY: CGFloat?

        init(_ parent: AvailabilityCreationGestureOverlay) {
            self.parent = parent
        }

        func install(on view: UIView) {
            let recognizer = AvailabilityLongPressDragRecognizer(target: self, action: #selector(handleLongPress(_:)))
            recognizer.minimumPressDuration = 0.35
            recognizer.allowablePreRecognitionMovement = 6
            recognizer.cancelsTouchesInView = false
            recognizer.delegate = self
            view.addGestureRecognizer(recognizer)

            let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
            tapRecognizer.cancelsTouchesInView = false
            tapRecognizer.delegate = self
            tapRecognizer.require(toFail: recognizer)
            view.addGestureRecognizer(tapRecognizer)
        }

        @objc private func handleLongPress(_ recognizer: AvailabilityLongPressDragRecognizer) {
            guard parent.isEnabled, let view = recognizer.view else { return }

            let location = recognizer.location(in: view)
            switch recognizer.state {
            case .began:
                let startLocation = recognizer.startLocation(in: view)
                guard let date = parent.date(atX: startLocation.x) else { return }

                let id = UUID()
                activeID = id
                activeDate = date
                anchorY = startLocation.y
                parent.onChanged(date, id, startLocation.y, startLocation.y)
            case .changed:
                guard let id = activeID, let date = activeDate, let anchorY else { return }
                parent.onChanged(date, id, anchorY, location.y)
            case .ended, .cancelled, .failed:
                reset()
                parent.onEnded()
            default:
                break
            }
        }

        @objc private func handleTap(_ recognizer: UITapGestureRecognizer) {
            guard parent.isEnabled, recognizer.state == .ended else { return }
            parent.onTap()
        }

        func gestureRecognizer(
            _ gestureRecognizer: UIGestureRecognizer,
            shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
        ) -> Bool {
            gestureRecognizer.state == .possible
        }

        private func reset() {
            activeID = nil
            activeDate = nil
            anchorY = nil
        }
    }

    private func date(atX x: CGFloat) -> Date? {
        guard dayWidth > 0, !dates.isEmpty else { return nil }

        let index = min(max(Int(floor(x / dayWidth)), 0), dates.count - 1)
        return dates[index]
    }
}

private final class AvailabilityLongPressDragRecognizer: UIGestureRecognizer {
    var minimumPressDuration: TimeInterval = 0.25
    var allowablePreRecognitionMovement: CGFloat = 14

    private var initialLocation: CGPoint?
    private var currentTouch: UITouch?
    private var recognitionWorkItem: DispatchWorkItem?

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        guard currentTouch == nil, let touch = touches.first, let view else {
            state = .failed
            return
        }

        currentTouch = touch
        initialLocation = touch.location(in: view)

        let workItem = DispatchWorkItem { [weak self] in
            guard let self, self.state == .possible else { return }
            self.state = .began
        }
        recognitionWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + minimumPressDuration, execute: workItem)
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
        guard let touch = currentTouch, touches.contains(where: { $0 === touch }), let view, let initialLocation else {
            return
        }

        let location = touch.location(in: view)
        if state == .possible {
            let movement = hypot(location.x - initialLocation.x, location.y - initialLocation.y)
            if movement > allowablePreRecognitionMovement {
                state = .failed
            }
            return
        }

        if state == .began || state == .changed {
            state = .changed
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {
        guard let touch = currentTouch, touches.contains(where: { $0 === touch }) else {
            return
        }

        state = state == .began || state == .changed ? .ended : .failed
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent) {
        state = .cancelled
    }

    override func reset() {
        recognitionWorkItem?.cancel()
        recognitionWorkItem = nil
        initialLocation = nil
        currentTouch = nil
    }

    func startLocation(in view: UIView) -> CGPoint {
        initialLocation ?? location(in: view)
    }
}

private struct AvailabilityWindowBlock<MoveGesture: Gesture, ResizeStartGesture: Gesture, ResizeEndGesture: Gesture>: View {
    let window: AvailabilityWindow
    let isActive: Bool
    let isLocked: Bool
    let activeColor: Color
    let onEdit: () -> Void
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
                .font(.caption.weight(.semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .foregroundStyle(.white)
                .padding(.horizontal, 5)
                .padding(.vertical, 4)

            if isActive {
                GeometryReader { proxy in
                    let handleWidth = max(proxy.size.width / 3, 24)
                    let handleHeight: CGFloat = 10

                    Capsule()
                        .fill(Color(.secondarySystemGroupedBackground))
                        .overlay {
                            Capsule()
                                .stroke(.black.opacity(0.18), lineWidth: 1)
                        }
                        .frame(width: handleWidth, height: handleHeight)
                        .position(x: proxy.size.width / 2, y: 0)
                        .highPriorityGesture(resizeStartGesture)
                        .accessibilityIdentifier("Availability Start Handle")
                        .zIndex(3)

                    Capsule()
                        .fill(Color(.secondarySystemGroupedBackground))
                        .overlay {
                            Capsule()
                                .stroke(.black.opacity(0.18), lineWidth: 1)
                        }
                        .frame(width: handleWidth, height: handleHeight)
                        .position(x: proxy.size.width / 2, y: proxy.size.height)
                        .highPriorityGesture(resizeEndGesture)
                        .accessibilityIdentifier("Availability End Handle")
                        .zIndex(3)

                    Circle()
                        .fill(Color(.secondarySystemGroupedBackground))
                        .overlay {
                            Circle()
                                .stroke(.black.opacity(0.18), lineWidth: 1)
                        }
                        .overlay {
                            Image(systemName: "pencil")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(Color.accentColor)
                        }
                        .frame(width: 32, height: 32)
                        .contentShape(Circle())
                        .highPriorityGesture(
                            TapGesture()
                                .onEnded {
                                    onEdit()
                                }
                        )
                        .position(x: proxy.size.width, y: 0)
                        .accessibilityAddTraits(.isButton)
                        .accessibilityLabel("Edit Selected Slot")
                        .accessibilityIdentifier("Edit Availability Window")
                        .zIndex(4)
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
