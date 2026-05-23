import SwiftUI

struct GroupsView: View {
    @Binding var groups: [AppGroup]
    let allContacts: [AppContact]
    @State private var selectedGroupID: AppGroup.ID?
    @State private var isShowingCreateGroup = false
    @State private var activeDragID: AppGroup.ID?
    @State private var activeDragOffset: CGSize = .zero
    @State private var activeDragStartFrame: CGRect?
    @State private var activeDragFrameSnapshot: [AppGroup.ID: CGRect] = [:]
    @State private var pendingDropIndex: Int?
    @State private var isSettlingDrag = false
    @State private var groupRowFrames: [AppGroup.ID: CGRect] = [:]
    @State private var groupPlaceholderFrame: CGRect?
    @Namespace private var groupReorderNamespace

    private let groupSpacing: CGFloat = 14
    private let reorderAnimation = Animation.spring(response: 0.42, dampingFraction: 0.9)
    private let dragActivationAnimation = Animation.spring(response: 0.18, dampingFraction: 0.82)
    private let releaseAnimation = Animation.easeOut(duration: 0.22)
    private let releaseAnimationDuration: UInt64 = 220_000_000

    var body: some View {
        ZStack(alignment: .topLeading) {
            ScrollView {
                LazyVStack(spacing: groupSpacing) {
                    ForEach(groupListElements) { element in
                        switch element {
                        case .placeholder:
                            GroupPlaceholderCard()
                                .background {
                                    GeometryReader { proxy in
                                        Color.clear.preference(
                                            key: GroupPlaceholderFramePreferenceKey.self,
                                            value: proxy.frame(in: .named("groups-list"))
                                        )
                                    }
                                }
                                .zIndex(0)
                                .transition(.identity)

                        case .group(let group):
                            GroupCard(group: group)
                                .matchedGeometryEffect(id: group.id, in: groupReorderNamespace)
                                .contentShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                                .background {
                                    GeometryReader { proxy in
                                        Color.clear.preference(
                                            key: GroupRowFramePreferenceKey.self,
                                            value: [group.id: proxy.frame(in: .named("groups-list"))]
                                        )
                                    }
                                }
                                .onTapGesture {
                                    guard activeDragID == nil else { return }
                                    selectedGroupID = group.id
                                }
                                .highPriorityGesture(reorderGesture(for: group.id))
                                .animation(reorderAnimation, value: activeDragID)
                                .animation(reorderAnimation, value: pendingDropIndex)
                                .zIndex(1)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 20)
            }

            if let activeDragID,
               let activeGroup = groups.first(where: { $0.id == activeDragID }),
               let activeDragStartFrame {
                GroupCard(group: activeGroup)
                    .frame(width: activeDragStartFrame.width)
                    .matchedGeometryEffect(id: activeDragID, in: groupReorderNamespace)
                    .scaleEffect(1.025)
                    .shadow(color: Color.black.opacity(0.18), radius: 16, x: 0, y: 8)
                    .offset(
                        x: activeDragStartFrame.minX + activeDragOffset.width,
                        y: activeDragStartFrame.minY + activeDragOffset.height
                    )
                    .zIndex(2)
                    .allowsHitTesting(false)
                    .transition(.identity)
            }
        }
        .coordinateSpace(name: "groups-list")
        .scrollDisabled(activeDragID != nil)
        .background(Color(.systemGroupedBackground))
        .onPreferenceChange(GroupRowFramePreferenceKey.self) { frames in
            groupRowFrames = frames
        }
        .onPreferenceChange(GroupPlaceholderFramePreferenceKey.self) { frame in
            groupPlaceholderFrame = frame
        }
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
            get: { selectedGroupID != nil },
            set: { isPresented in
                if !isPresented {
                    selectedGroupID = nil
                }
            }
        )) {
            if let selectedGroupID, let group = groupBinding(for: selectedGroupID) {
                GroupMembersSheetView(group: group, allContacts: allContacts)
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
            }
        }
    }

    private var groupListElements: [GroupListElement] {
        let visibleGroups = groups.filter { $0.id != activeDragID }
        var elements = visibleGroups.map(GroupListElement.group)

        if activeDragID != nil {
            elements.insert(.placeholder, at: clampedPendingDropIndex(for: visibleGroups))
        }

        return elements
    }

    private func reorderGesture(for groupID: AppGroup.ID) -> some Gesture {
        LongPressGesture(minimumDuration: 0.28)
            .sequenced(before: DragGesture(minimumDistance: 0, coordinateSpace: .named("groups-list")))
            .onChanged { value in
                guard !isSettlingDrag else { return }

                switch value {
                case .first(true):
                    activateDrag(for: groupID)
                case .second(true, let drag):
                    activateDrag(for: groupID)
                    activeDragOffset = drag?.translation ?? .zero
                    if let drag {
                        updateDropIndex(for: groupID, translation: drag.translation)
                    }
                default:
                    break
                }
            }
            .onEnded { value in
                guard activeDragID == groupID else {
                    resetDrag()
                    return
                }

                settleDrag()
            }
    }

    private func activateDrag(for groupID: AppGroup.ID) {
        guard activeDragID != groupID else { return }
        activeDragFrameSnapshot = groupRowFrames
        activeDragStartFrame = groupRowFrames[groupID]
        pendingDropIndex = groups.firstIndex(where: { $0.id == groupID })
        withAnimation(dragActivationAnimation) {
            activeDragID = groupID
            activeDragOffset = .zero
        }
    }

    private func resetDrag() {
        let draggedGroupID = activeDragID
        let dropIndex = pendingDropIndex
        withAnimation(reorderAnimation) {
            if let draggedGroupID, let dropIndex {
                moveGroup(draggedGroupID, to: dropIndex)
            }
            activeDragID = nil
            activeDragOffset = .zero
            activeDragStartFrame = nil
            activeDragFrameSnapshot = [:]
            pendingDropIndex = nil
            isSettlingDrag = false
            groupPlaceholderFrame = nil
        }
    }

    private func settleDrag() {
        guard
            let draggedGroupID = activeDragID,
            let dropIndex = pendingDropIndex,
            let settleOffset = settleOffset(for: draggedGroupID, dropIndex: dropIndex)
        else {
            resetDrag()
            return
        }

        isSettlingDrag = true
        withAnimation(releaseAnimation) {
            activeDragOffset = settleOffset
        }

        Task { @MainActor in
            try? await Task.sleep(nanoseconds: releaseAnimationDuration)
            guard activeDragID == draggedGroupID else { return }

            var transaction = Transaction()
            transaction.disablesAnimations = true
            withTransaction(transaction) {
                moveGroup(draggedGroupID, to: dropIndex)
                activeDragID = nil
                activeDragOffset = .zero
                activeDragStartFrame = nil
                activeDragFrameSnapshot = [:]
                pendingDropIndex = nil
                isSettlingDrag = false
                groupPlaceholderFrame = nil
            }
        }
    }

    private func updateDropIndex(for groupID: AppGroup.ID, translation: CGSize) {
        let targetIndex = targetIndex(for: groupID, translation: translation)
        guard pendingDropIndex != targetIndex else { return }

        withAnimation(reorderAnimation) {
            pendingDropIndex = targetIndex
        }
    }

    private func targetIndex(for groupID: AppGroup.ID, translation: CGSize) -> Int {
        let frames = activeDragFrameSnapshot.isEmpty ? groupRowFrames : activeDragFrameSnapshot
        guard let startFrame = activeDragStartFrame ?? frames[groupID] else {
            return groups.firstIndex(where: { $0.id == groupID }) ?? 0
        }

        let draggedMidY = startFrame.midY + translation.height
        let nonDraggedGroups = groups.filter { $0.id != groupID }
        let insertionIndex = nonDraggedGroups.reduce(0) { count, group in
            guard let frame = frames[group.id], draggedMidY > frame.midY else {
                return count
            }

            return count + 1
        }

        return min(max(insertionIndex, 0), max(groups.count - 1, 0))
    }

    private func moveGroup(_ groupID: AppGroup.ID, to targetIndex: Int) {
        guard
            let sourceIndex = groups.firstIndex(where: { $0.id == groupID }),
            sourceIndex != targetIndex
        else {
            return
        }

        let group = groups.remove(at: sourceIndex)
        groups.insert(group, at: min(max(targetIndex, 0), groups.count))
    }

    private func settleOffset(for groupID: AppGroup.ID, dropIndex: Int) -> CGSize? {
        guard let startFrame = activeDragStartFrame ?? activeDragFrameSnapshot[groupID] ?? groupRowFrames[groupID] else {
            return nil
        }

        if let groupPlaceholderFrame {
            return CGSize(width: 0, height: groupPlaceholderFrame.minY - startFrame.minY)
        }

        let visibleGroups = groups.filter { $0.id != groupID }
        let targetMinY: CGFloat

        if visibleGroups.isEmpty {
            targetMinY = startFrame.minY
        } else if dropIndex <= 0, let firstGroup = visibleGroups.first, let firstFrame = groupRowFrames[firstGroup.id] {
            targetMinY = firstFrame.minY
        } else if dropIndex >= visibleGroups.count, let lastGroup = visibleGroups.last, let lastFrame = groupRowFrames[lastGroup.id] {
            targetMinY = lastFrame.maxY + groupSpacing
        } else if let nextFrame = groupRowFrames[visibleGroups[dropIndex].id] {
            targetMinY = nextFrame.minY
        } else {
            return nil
        }

        return CGSize(width: 0, height: targetMinY - startFrame.minY)
    }

    private func clampedPendingDropIndex(for visibleGroups: [AppGroup]) -> Int {
        min(max(pendingDropIndex ?? visibleGroups.count, 0), visibleGroups.count)
    }

    private func groupBinding(for id: AppGroup.ID) -> Binding<AppGroup>? {
        guard let index = groups.firstIndex(where: { $0.id == id }) else { return nil }
        return $groups[index]
    }
}

private enum GroupListElement: Identifiable {
    case placeholder
    case group(AppGroup)

    var id: String {
        switch self {
        case .placeholder:
            return "placeholder"
        case .group(let group):
            return group.id.uuidString
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

private struct GroupCard: View {
    let group: AppGroup

    var body: some View {
        GroupRow(group: group)
            .padding(.horizontal, 18)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }
}

private struct GroupPlaceholderCard: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 24, style: .continuous)
            .strokeBorder(
                Color.secondary,
                style: StrokeStyle(lineWidth: 2, lineCap: .round, dash: [7, 7])
            )
            .frame(height: 84)
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
                .fill(Color.secondary)

            Text(initials)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(Color(.systemBackground))
        }
        .frame(width: 56, height: 56)
    }
}

private struct GroupRowFramePreferenceKey: PreferenceKey {
    static var defaultValue: [AppGroup.ID: CGRect] = [:]

    static func reduce(value: inout [AppGroup.ID: CGRect], nextValue: () -> [AppGroup.ID: CGRect]) {
        value.merge(nextValue()) { _, newValue in newValue }
    }
}

private struct GroupPlaceholderFramePreferenceKey: PreferenceKey {
    static var defaultValue: CGRect?

    static func reduce(value: inout CGRect?, nextValue: () -> CGRect?) {
        value = nextValue() ?? value
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
