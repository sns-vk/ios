import SwiftUI

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
                                Image(systemName: "person.crop.circle.fill")
                                    .font(.title3)
                                    .foregroundStyle(.secondary)

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
    @State private var isEditing = false
    @State private var showAddToGroupSheet = false

    var body: some View {
        Form {
            Section("Recommendations") {
                Toggle("Use for matching", isOn: $contact.useForFoFRecommendations)
            }

            Section("Groups") {
                if memberGroupIndices.isEmpty {
                    Text("Not in any groups")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(memberGroupIndices, id: \.self) { index in
                        HStack(spacing: 12) {
                            if isEditing {
                                Button {
                                    removeContactFromGroup(at: index)
                                } label: {
                                    Image(systemName: "minus.circle.fill")
                                        .foregroundStyle(.red)
                                }
                                .buttonStyle(.plain)
                            }

                            Text(groups[index].name)
                        }
                    }
                }

                if isEditing {
                    Button("Add to Group") {
                        showAddToGroupSheet = true
                    }
                    .disabled(availableGroupIndices.isEmpty)
                }
            }

            if isEditing {
                Section("Name") {
                    TextField("First Name", text: $contact.firstName)
                    TextField("Last Name", text: $contact.lastName)
                }

                Section("Profile") {
                    TextField("Description", text: $contact.bio)
                    TextField("Pronouns", text: $contact.pronouns)
                }

                Section("Contact") {
                    TextField("Phone", text: $contact.phone)
                        .keyboardType(.phonePad)
                    TextField("Email", text: $contact.email)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled(true)
                    TextField("Address", text: $contact.address)
                    TextField("URL", text: $contact.websiteURL)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled(true)
                }

                Section("Dates") {
                    if contact.birthday == nil {
                        Button("Add Birthday") {
                            contact.birthday = Date()
                        }
                    } else {
                        DatePicker("Birthday", selection: birthdayBinding, displayedComponents: .date)
                        Button("Remove Birthday", role: .destructive) {
                            contact.birthday = nil
                        }
                    }
                }

                Section("Notes") {
                    TextEditor(text: $contact.notes)
                        .frame(minHeight: 120)
                }
            } else {
                if hasNameContent {
                    Section("Name") {
                        if !contact.firstName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            detailRow(title: "First Name", value: contact.firstName)
                        }
                        if !contact.lastName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            detailRow(title: "Last Name", value: contact.lastName)
                        }
                    }
                }

                if hasProfileContent {
                    Section("Profile") {
                        detailRow(title: "Description", value: contact.bio)
                        detailRow(title: "Pronouns", value: contact.pronouns)
                    }
                }

                if hasContactContent {
                    Section("Contact") {
                        detailRow(title: "Phone", value: contact.phone)
                        detailRow(title: "Email", value: contact.email)
                        detailRow(title: "Address", value: contact.address)
                        detailRow(title: "URL", value: contact.websiteURL)
                    }
                }

                if contact.birthday != nil {
                    Section("Dates") {
                        if let birthday = contact.birthday {
                            detailRow(title: "Birthday", value: Self.dateFormatter.string(from: birthday))
                        }
                    }
                }

                if !contact.notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Section("Notes") {
                        Text(contact.notes)
                    }
                }
            }
        }
        .overlay {
            if !isEditing && !hasAnyProfileContent {
                ContentUnavailableView("No Profile Info Yet", systemImage: "person.text.rectangle")
            }
        }
        .navigationTitle(contact.name)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showAddToGroupSheet) {
            AddContactToGroupsSheetView(groups: $groups, contact: contact)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(isEditing ? "Done" : "Edit") {
                    isEditing.toggle()
                }
            }
        }
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }()

    private var birthdayBinding: Binding<Date> {
        Binding(
            get: { contact.birthday ?? Date() },
            set: { contact.birthday = $0 }
        )
    }

    private var hasNameContent: Bool {
        !contact.firstName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
        !contact.lastName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var hasProfileContent: Bool {
        !contact.bio.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
        !contact.pronouns.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var hasContactContent: Bool {
        !contact.phone.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
        !contact.email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
        !contact.address.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
        !contact.websiteURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var hasAnyProfileContent: Bool {
        hasNameContent ||
        hasProfileContent ||
        hasContactContent ||
        contact.birthday != nil ||
        !contact.notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var memberGroupIndices: [Int] {
        groups.indices.filter { groupIndex in
            groups[groupIndex].members.contains(where: { $0.id == contact.id })
        }
    }

    private var availableGroupIndices: [Int] {
        groups.indices.filter { groupIndex in
            !groups[groupIndex].members.contains(where: { $0.id == contact.id })
        }
    }

    private func removeContactFromGroup(at groupIndex: Int) {
        groups[groupIndex].members.removeAll { $0.id == contact.id }
    }

    @ViewBuilder
    private func detailRow(title: String, value: String) -> some View {
        if !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            HStack {
                Text(title)
                Spacer()
                Text(value.trimmingCharacters(in: .whitespacesAndNewlines))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.trailing)
            }
        }
    }
}
