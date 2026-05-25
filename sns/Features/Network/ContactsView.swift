import SwiftUI
import PhotosUI

struct ContactsView: View {
    @Bindable var appState: AppState
    @State private var showAddContactSheet = false

    private var filteredContacts: [AppContact] {
        appState.contacts.sorted { $0.name < $1.name }
    }

    private var groupedContacts: [(key: String, value: [AppContact])] {
        let grouped = Dictionary(grouping: filteredContacts) { contact in
            String(contact.name.prefix(1)).uppercased()
        }

        return grouped
            .map { key, value in
                (key: key, value: value.sorted { $0.name < $1.name })
            }
            .sorted { $0.key < $1.key }
    }

    var body: some View {
        List {
            ForEach(groupedContacts, id: \.key) { section in
                Section {
                    ForEach(section.value) { contact in
                        NavigationLink {
                            if let contactIndex = appState.contacts.firstIndex(where: { $0.id == contact.id }) {
                                ContactDetailView(contact: $appState.contacts[contactIndex], groups: $appState.groups)
                            } else {
                                Text("Contact unavailable")
                            }
                        } label: {
                            HStack(spacing: 12) {
                                ContactListAvatar(contact: contact)

                                Text(contact.name)
                            }
                            .padding(.vertical, 2)
                        }
                    }
                } header: {
                    Text(section.key)
                }
                .listSectionSeparator(.hidden, edges: .top)
            }
        }
        .listStyle(.insetGrouped)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showAddContactSheet = true
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("Add Contact via Tap")
            }
        }
        .sheet(isPresented: $showAddContactSheet) {
            AddContactTapSheetView()
                .presentationDetents([.fraction(0.4)])
                .presentationDragIndicator(.visible)
        }
    }
}

private struct ContactListAvatar: View {
    let contact: AppContact
    var size: CGFloat = 24

    var body: some View {
        if let photoData = contact.photoData, let image = UIImage(data: photoData) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: size, height: size)
                .clipShape(Circle())
        } else {
            Image(systemName: "person.crop.circle.fill")
                .font(.title3)
                .foregroundStyle(.secondary)
        }
    }
}

private enum AddContactStatus {
    case connecting
    case sharing
    case completed

    var title: String {
        switch self {
        case .connecting:
            return "Connecting devices..."
        case .sharing:
            return "Sharing contact card..."
        case .completed:
            return "Contact shared"
        }
    }

    var subtitle: String {
        switch self {
        case .connecting:
            return "Bring phones together using Bluetooth + NFC."
        case .sharing:
            return "Hold steady while the contact card transfers."
        case .completed:
            return "Transfer complete."
        }
    }

    var icon: String {
        switch self {
        case .connecting:
            return "wave.3.right.circle.fill"
        case .sharing:
            return "person.crop.rectangle.badge.plus"
        case .completed:
            return "checkmark.circle.fill"
        }
    }
}

struct AddContactTapSheetView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var status: AddContactStatus = .connecting
    @State private var simulationTask: Task<Void, Never>?

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: status.icon)
                .font(.system(size: 42))
                .foregroundStyle(status == .completed ? .green : .blue)

            Text(status.title)
                .font(.headline)

            Text(status.subtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            if status != .completed {
                ProgressView()
                    .padding(.top, 2)
            }

            Button(status == .completed ? "Done" : "Cancel") {
                dismiss()
            }
            .padding(.top, 6)
        }
        .padding()
        .onAppear {
            startSimulation()
        }
        .onDisappear {
            simulationTask?.cancel()
            simulationTask = nil
        }
    }

    private func startSimulation() {
        simulationTask?.cancel()
        status = .connecting

        simulationTask = Task {
            try? await Task.sleep(for: .seconds(1.5))
            guard !Task.isCancelled else { return }
            await MainActor.run {
                status = .sharing
            }

            try? await Task.sleep(for: .seconds(1.8))
            guard !Task.isCancelled else { return }
            await MainActor.run {
                status = .completed
            }
        }
    }
}

struct ContactDetailView: View {
    @Binding var contact: AppContact
    @Binding var groups: [AppGroup]
    @State private var selectedPhoto: PhotosPickerItem?

    var body: some View {
        Form {
            photoEditor
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)

            Section("Profile") {
                NavigationLink {
                    AccountAgeView(age: $contact.age)
                } label: {
                    contactValueRow(title: "Age", value: AgeDisplay.label(for: contact.age), systemImage: "number")
                }

                NavigationLink {
                    AccountSingleSelectView(title: "Gender", selection: $contact.gender)
                } label: {
                    contactValueRow(title: "Gender", value: contact.gender.label, systemImage: "person.fill")
                }

                NavigationLink {
                    AccountSingleSelectView(title: "Pronouns", selection: $contact.pronouns)
                } label: {
                    contactValueRow(title: "Pronouns", value: contact.pronouns.label, systemImage: "text.bubble")
                }

                NavigationLink {
                    AccountSingleSelectView(title: "Sexuality", selection: $contact.sexuality)
                } label: {
                    contactValueRow(title: "Sexuality", value: contact.sexuality.label, systemImage: "heart.circle")
                }
            }

            Section("Groups") {
                NavigationLink {
                    ContactGroupsView(contact: $contact, groups: $groups)
                } label: {
                    contactValueRow(title: "Membership", value: groupsSummary, systemImage: "circle.grid.2x1.left.filled")
                }
            }

            Section("Substance Use") {
                ForEach(SubstanceUseCategory.allCases) { category in
                    NavigationLink {
                        AccountSubstanceUseView(
                            category: category,
                            selection: substanceUseBinding(for: category)
                        )
                    } label: {
                        contactValueRow(
                            title: category.label,
                            value: contact.substanceUse[category, default: .no].label,
                            systemImage: category.systemImage
                        )
                    }
                }
            }

            Section("Notes") {
                NavigationLink {
                    ContactNotesView(notes: $contact.notes)
                } label: {
                    contactValueRow(title: "Notes", value: notesSummary, systemImage: "note.text")
                }
            }
        }
        .navigationTitle(contact.name)
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: selectedPhoto) { _, newPhoto in
            Task {
                contact.photoData = try? await newPhoto?.loadTransferable(type: Data.self)
            }
        }
    }

    private var photoEditor: some View {
        VStack(spacing: 12) {
            ZStack(alignment: .topTrailing) {
                MyCardAvatarView(contact: contact, size: 160)

                PhotosPicker(selection: $selectedPhoto, matching: .images) {
                    Image(systemName: "pencil")
                        .font(.headline)
                        .foregroundStyle(Color.accentColor)
                        .frame(width: 44, height: 44)
                        .background(Color(.systemBackground), in: Circle())
                        .overlay {
                            Circle()
                                .stroke(Color(.separator).opacity(0.45), lineWidth: 1)
                        }
                        .shadow(color: .black.opacity(0.12), radius: 8, y: 3)
                }
                .buttonStyle(ContactNoPressFeedbackButtonStyle())
                .offset(x: 2, y: -2)
                .accessibilityIdentifier("Choose Contact Photo")
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 18)
        .padding(.bottom, 6)
        .accessibilityIdentifier("Contact Photo Editor")
    }

    private func substanceUseBinding(for category: SubstanceUseCategory) -> Binding<SubstanceUseAnswer> {
        Binding(
            get: { contact.substanceUse[category, default: .no] },
            set: { contact.substanceUse[category] = $0 }
        )
    }

    private var memberGroupIndices: [Int] {
        groups.indices.filter { groupIndex in
            groups[groupIndex].members.contains(where: { $0.id == contact.id })
        }
    }

    private var groupsSummary: String {
        guard !memberGroupIndices.isEmpty else { return "Not in any groups" }

        if memberGroupIndices.count == 1, let index = memberGroupIndices.first {
            return groups[index].displayTitle
        }

        return "\(memberGroupIndices.count) groups"
    }

    private var notesSummary: String {
        let trimmed = contact.notes.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "Not set" : trimmed
    }

    @ViewBuilder
    private func contactValueRow(title: String, value: String, systemImage: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.title3)
                .foregroundStyle(.secondary)
                .frame(width: 28)

            Text(title)

            Spacer()

            Text(value.trimmingCharacters(in: .whitespacesAndNewlines))
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .multilineTextAlignment(.trailing)
        }
    }
}

private struct ContactGroupsView: View {
    @Binding var contact: AppContact
    @Binding var groups: [AppGroup]

    private var selectedGroupIndices: [Int] {
        groups.indices.filter { index in
            groups[index].members.contains { $0.id == contact.id }
        }
    }

    var body: some View {
        Form {
            Section("Groups") {
                if selectedGroupIndices.isEmpty {
                    Text("Not in any groups")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(selectedGroupIndices, id: \.self) { index in
                        groupMembershipRow(for: groups[index])
                    }
                }
            }
        }
        .navigationTitle("Groups")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                NavigationLink {
                    ContactGroupSearchView(contact: $contact, groups: $groups)
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("Add Groups")
            }
        }
    }

    @ViewBuilder
    private func groupMembershipRow(for group: AppGroup) -> some View {
        HStack(spacing: 14) {
            GroupAvatar(name: group.displayTitle, photoData: group.photoData, size: 44)

            VStack(alignment: .leading, spacing: 2) {
                Text(group.displayTitle)
                    .font(.headline)
                    .foregroundStyle(.primary)

                Text(group.memberCountSummary)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .lineLimit(1)

            Spacer(minLength: 12)
        }
        .accessibilityIdentifier("Contact Group \(group.displayTitle)")
    }
}

private struct ContactGroupSearchView: View {
    @Binding var contact: AppContact
    @Binding var groups: [AppGroup]
    @State private var searchText = ""

    private var searchResults: [Int] {
        let trimmedQuery = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else { return [] }

        return groups.indices.filter { index in
            groupMatches(groups[index], query: trimmedQuery)
        }
    }

    var body: some View {
        Form {
            Section("Search") {
                TextField("Search groups", text: $searchText)
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled(true)
            }

            if !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Section("Results") {
                    if searchResults.isEmpty {
                        Text("No groups found")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(searchResults, id: \.self) { index in
                            groupToggleRow(for: groups[index])
                        }
                    }
                }
            }
        }
        .navigationTitle("Add Groups")
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private func groupToggleRow(for group: AppGroup) -> some View {
        Button {
            toggleMembership(for: group.id)
        } label: {
            HStack(spacing: 14) {
                GroupAvatar(name: group.displayTitle, photoData: group.photoData, size: 44)

                VStack(alignment: .leading, spacing: 2) {
                    Text(group.displayTitle)
                        .font(.headline)
                        .foregroundStyle(.primary)

                    Text(group.memberCountSummary)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .lineLimit(1)

                Spacer(minLength: 12)

                Image(systemName: "checkmark")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(Color.accentColor)
                    .opacity(isContactMember(of: group) ? 1 : 0)
                    .animation(nil, value: isContactMember(of: group))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("Contact Group \(group.displayTitle)")
    }

    private func groupMatches(_ group: AppGroup, query: String) -> Bool {
        group.displayTitle.localizedCaseInsensitiveContains(query)
            || group.name.localizedCaseInsensitiveContains(query)
            || group.memberSummary.localizedCaseInsensitiveContains(query)
            || group.members.contains { $0.name.localizedCaseInsensitiveContains(query) }
    }

    private func isContactMember(of group: AppGroup) -> Bool {
        group.members.contains { $0.id == contact.id }
    }

    private func toggleMembership(for groupID: AppGroup.ID) {
        guard let index = groups.firstIndex(where: { $0.id == groupID }) else { return }

        if let memberIndex = groups[index].members.firstIndex(where: { $0.id == contact.id }) {
            groups[index].members.remove(at: memberIndex)
        } else {
            groups[index].members.append(contact)
        }
    }
}

private struct ContactNotesView: View {
    @Binding var notes: String

    var body: some View {
        Form {
            Section("Notes") {
                TextEditor(text: $notes)
                    .frame(minHeight: 120)
                    .accessibilityIdentifier("Contact Notes Editor")
            }
        }
        .navigationTitle("Notes")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct ContactNoPressFeedbackButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
    }
}
