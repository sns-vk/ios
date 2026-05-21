import SwiftUI

struct GroupsView: View {
    @Binding var groups: [AppGroup]
    let allContacts: [AppContact]
    @State private var selectedGroupIndex: Int?
    @State private var isShowingCreateGroup = false

    private var filteredGroupIndices: [Int] {
        Array(groups.indices)
    }

    var body: some View {
        List {
            ForEach(filteredGroupIndices, id: \.self) { index in
                Section {
                    Button {
                        selectedGroupIndex = index
                    } label: {
                        GroupRow(group: groups[index])
                    }
                    .buttonStyle(.plain)
                    .listRowInsets(EdgeInsets(top: 14, leading: 18, bottom: 14, trailing: 18))
                }
                .listSectionSeparator(.hidden, edges: .top)
            }
        }
        .listStyle(.insetGrouped)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    isShowingCreateGroup = true
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("Create Group")
            }
        }
        .fullScreenCover(isPresented: $isShowingCreateGroup) {
            CreateGroupView { name in
                groups.insert(AppGroup(name: name, members: []), at: 0)
            }
        }
        .sheet(isPresented: Binding(
            get: { selectedGroupIndex != nil },
            set: { isPresented in
                if !isPresented {
                    selectedGroupIndex = nil
                }
            }
        )) {
            if let selectedGroupIndex {
                GroupMembersSheetView(group: $groups[selectedGroupIndex], allContacts: allContacts)
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
            }
        }
    }
}

private struct GroupRow: View {
    let group: AppGroup

    private var memberSummary: String {
        guard !group.members.isEmpty else { return "No contacts yet" }

        return group.members
            .map(\.name)
            .joined(separator: ", ")
    }

    var body: some View {
        HStack(spacing: 14) {
            GroupAvatar(name: group.name)

            VStack(alignment: .leading, spacing: 3) {
                Text(group.name)
                    .font(.headline)
                    .foregroundStyle(.primary)

                Text(memberSummary)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }

            Spacer(minLength: 12)

            Image(systemName: "chevron.right")
                .font(.headline.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct GroupAvatar: View {
    let name: String

    private var initials: String {
        let initials = name
            .split(separator: " ")
            .prefix(2)
            .compactMap(\.first)

        let value = String(initials).uppercased()
        return value.isEmpty ? "G" : value
    }

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.accentColor.opacity(0.16))

            Text(initials)
                .font(.system(size: 20, weight: .semibold, design: .serif))
                .foregroundStyle(Color.accentColor)
        }
        .frame(width: 56, height: 56)
    }
}

private struct CreateGroupView: View {
    let onCreate: (String) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var groupName = ""

    private var trimmedGroupName: String {
        groupName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Group") {
                    TextField("Group name", text: $groupName)
                        .textInputAutocapitalization(.words)
                        .submitLabel(.done)
                        .onSubmit(createGroup)
                }
            }
            .navigationTitle("New Group")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Create", action: createGroup)
                        .disabled(trimmedGroupName.isEmpty)
                }
            }
        }
    }

    private func createGroup() {
        let name = trimmedGroupName
        guard !name.isEmpty else { return }

        onCreate(name)
        dismiss()
    }
}

struct AddContactToGroupsSheetView: View {
    @Binding var groups: [AppGroup]
    let contact: AppContact

    @Environment(\.dismiss) private var dismiss

    private var availableGroupIndices: [Int] {
        groups.indices.filter { groupIndex in
            !groups[groupIndex].members.contains(where: { $0.id == contact.id })
        }
    }

    var body: some View {
        NavigationStack {
            List {
                if availableGroupIndices.isEmpty {
                    Text("This contact is already in all groups.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(availableGroupIndices, id: \.self) { groupIndex in
                        Button {
                            groups[groupIndex].members.append(contact)
                            dismiss()
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "person.2.fill")
                                    .foregroundStyle(.secondary)
                                Text(groups[groupIndex].name)
                                Spacer()
                                Image(systemName: "plus.circle.fill")
                                    .foregroundStyle(.green)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .navigationTitle("Add to Group")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct GroupMembersSheetView: View {
    @Binding var group: AppGroup
    let allContacts: [AppContact]

    @State private var isEditingMembers = false
    @State private var showAddMembersSheet = false

    var body: some View {
        NavigationStack {
            List {
                ForEach(group.members) { member in
                    HStack(spacing: 12) {
                        if isEditingMembers {
                            Button {
                                removeMember(member.id)
                            } label: {
                                Image(systemName: "minus.circle.fill")
                                    .foregroundStyle(.red)
                            }
                            .buttonStyle(.plain)
                        }

                        Image(systemName: "person.crop.circle.fill")
                            .font(.title3)
                            .foregroundStyle(.secondary)

                        Text(member.name)
                    }
                    .padding(.vertical, 2)
                }
            }
            .listStyle(.plain)
            .navigationTitle(group.name)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(isEditingMembers ? "Done" : "Edit") {
                        withAnimation {
                            isEditingMembers.toggle()
                        }
                    }
                }

                if isEditingMembers {
                    ToolbarItem(placement: .confirmationAction) {
                        Button {
                            showAddMembersSheet = true
                        } label: {
                            Image(systemName: "plus")
                        }
                        .accessibilityLabel("Add Members")
                    }
                }
            }
            .sheet(isPresented: $showAddMembersSheet) {
                AddMembersToGroupSheetView(
                    availableContacts: allContacts.filter { contact in
                        !group.members.contains(where: { $0.id == contact.id })
                    }
                ) { selectedMembers in
                    group.members.append(contentsOf: selectedMembers)
                }
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
            }
        }
    }

    private func removeMember(_ id: AppContact.ID) {
        group.members.removeAll { $0.id == id }
    }
}

struct AddMembersToGroupSheetView: View {
    let availableContacts: [AppContact]
    let onAddMembers: ([AppContact]) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var selectedContactIDs: Set<AppContact.ID> = []

    var body: some View {
        NavigationStack {
            List(availableContacts) { contact in
                Button {
                    toggleSelection(for: contact.id)
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: selectedContactIDs.contains(contact.id) ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(selectedContactIDs.contains(contact.id) ? .green : .secondary)

                        Text(contact.name)
                            .foregroundStyle(.primary)
                    }
                }
                .buttonStyle(.plain)
            }
            .navigationTitle("Add Members")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        let selectedMembers = availableContacts.filter { selectedContactIDs.contains($0.id) }
                        onAddMembers(selectedMembers)
                        dismiss()
                    }
                    .disabled(selectedContactIDs.isEmpty)
                }
            }
        }
    }

    private func toggleSelection(for id: AppContact.ID) {
        if selectedContactIDs.contains(id) {
            selectedContactIDs.remove(id)
        } else {
            selectedContactIDs.insert(id)
        }
    }
}
