import SwiftUI
import UIKit
import PhotosUI

struct GroupsView: View {
    @Binding var groups: [AppGroup]
    let allContacts: [AppContact]
    let onOpenGroup: (AppGroup.ID) -> Void
    @State private var isShowingCreateGroup = false
    @State private var activeDragID: AppGroup.ID?
    @State private var activeDragOffset: CGSize = .zero
    @State private var activeDragStartFrame: CGRect?
    @State private var activeDragFrameSnapshot: [AppGroup.ID: CGRect] = [:]
    @State private var pendingDropIndex: Int?
    @State private var isSettlingDrag = false
    @State private var groupRowFrames: [AppGroup.ID: CGRect] = [:]
    @State private var groupPlaceholderFrame: CGRect?
    @GestureState private var armedDragID: AppGroup.ID?
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
                                .scaleEffect(armedDragID == group.id && activeDragID == nil ? 1.025 : 1)
                                .shadow(
                                    color: Color.black.opacity(armedDragID == group.id && activeDragID == nil ? 0.18 : 0),
                                    radius: armedDragID == group.id && activeDragID == nil ? 16 : 0,
                                    x: 0,
                                    y: armedDragID == group.id && activeDragID == nil ? 8 : 0
                                )
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
                                    onOpenGroup(group.id)
                                }
                                .simultaneousGesture(reorderGesture(for: group.id))
                                .animation(dragActivationAnimation, value: armedDragID == group.id)
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
                    .scaleEffect(isSettlingDrag ? 1 : 1.025)
                    .shadow(
                        color: Color.black.opacity(isSettlingDrag ? 0 : 0.18),
                        radius: isSettlingDrag ? 0 : 16,
                        x: 0,
                        y: isSettlingDrag ? 0 : 8
                    )
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
            GroupFormView(
                navigationTitle: "New Group",
                confirmationTitle: "Create",
                availableContacts: allContacts
            ) { name, members, photoData in
                groups.insert(AppGroup(name: name, members: members, photoData: photoData), at: 0)
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
            .sequenced(before: DragGesture(minimumDistance: 6, coordinateSpace: .named("groups-list")))
            .updating($armedDragID) { value, state, transaction in
                transaction.animation = dragActivationAnimation

                switch value {
                case .second(true, _):
                    if activeDragID == nil {
                        state = groupID
                    }
                default:
                    break
                }
            }
            .onChanged { value in
                guard !isSettlingDrag else { return }

                switch value {
                case .second(true, let drag?):
                    activateDrag(for: groupID)
                    activeDragOffset = drag.translation
                    updateDropIndex(for: groupID, translation: drag.translation)
                default:
                    break
                }
            }
            .onEnded { value in
                guard !isSettlingDrag else { return }

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

        withAnimation(releaseAnimation) {
            isSettlingDrag = true
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

extension AppGroup {
    var hasCustomName: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var displayTitle: String {
        if hasCustomName {
            return name
        }

        return memberSummary
    }

    var memberSummary: String {
        guard !members.isEmpty else { return "No contacts yet" }

        return members
            .map { contact in
                contact.name.split(separator: " ").first.map(String.init) ?? contact.name
            }
            .joined(separator: ", ")
    }

    var memberCountSummary: String {
        "\(members.count) \(members.count == 1 ? "member" : "members")"
    }
}

private func contactsMatching(_ query: String, in contacts: [AppContact]) -> [AppContact] {
    let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmedQuery.isEmpty else { return contacts }

    return contacts.filter { contact in
        contact.name.localizedCaseInsensitiveContains(trimmedQuery)
    }
}

private func memberOptions(
    searchText: String,
    in contacts: [AppContact],
    selectedIDs: Set<AppContact.ID>
) -> [AppContact] {
    let selectedContacts = contacts.filter { selectedIDs.contains($0.id) }
    let trimmedQuery = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmedQuery.isEmpty else { return selectedContacts }

    let matchingContacts = contactsMatching(trimmedQuery, in: contacts)
        .filter { !selectedIDs.contains($0.id) }

    return selectedContacts + matchingContacts
}

private struct GroupRow: View {
    let group: AppGroup

    var body: some View {
        HStack(spacing: 14) {
            GroupAvatar(name: group.displayTitle, photoData: group.photoData)

            VStack(alignment: .leading, spacing: 3) {
                Text(group.displayTitle)
                    .font(.headline)
                    .foregroundStyle(.primary)

                Text(group.memberCountSummary)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .lineLimit(1)
            .truncationMode(.tail)

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
            .fill(Color.gray.opacity(0.12))
            .frame(height: 84)
    }
}

struct GroupAvatar: View {
    let name: String
    var photoData: Data? = nil
    var size: CGFloat = 56

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.accentColor.opacity(0.16))

            if let photoData, let image = UIImage(data: photoData) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: size, height: size)
                    .clipShape(Circle())
            } else {
                VennDiagramIcon(size: size * 0.52, color: Color.accentColor)
            }
        }
        .frame(width: size, height: size)
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

struct GroupFormView: View {
    let navigationTitle: String
    let confirmationTitle: String
    let availableContacts: [AppContact]
    let wrapsInNavigationStack: Bool
    let showsCancelButton: Bool
    let onSave: (String, [AppContact], Data?) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var groupName = ""
    @State private var selectedContactIDs: [AppContact.ID] = []
    @State private var memberSearchText = ""
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var photoData: Data?

    init(
        navigationTitle: String,
        confirmationTitle: String,
        availableContacts: [AppContact],
        initialName: String = "",
        initialMembers: [AppContact] = [],
        initialPhotoData: Data? = nil,
        wrapsInNavigationStack: Bool = true,
        showsCancelButton: Bool = true,
        onSave: @escaping (String, [AppContact], Data?) -> Void
    ) {
        self.navigationTitle = navigationTitle
        self.confirmationTitle = confirmationTitle
        self.availableContacts = availableContacts
        self.wrapsInNavigationStack = wrapsInNavigationStack
        self.showsCancelButton = showsCancelButton
        self.onSave = onSave
        self._groupName = State(initialValue: initialName)
        self._selectedContactIDs = State(initialValue: initialMembers.map(\.id))
        self._photoData = State(initialValue: initialPhotoData)
    }

    private var trimmedGroupName: String {
        groupName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var selectedMembers: [AppContact] {
        selectedContactIDs.compactMap { id in
            availableContacts.first { $0.id == id }
        }
    }

    private var canCreate: Bool {
        !trimmedGroupName.isEmpty || !selectedContactIDs.isEmpty
    }

    private var filteredContacts: [AppContact] {
        guard isSearchingMembers else { return [] }

        return contactsMatching(memberSearchText, in: availableContacts)
    }

    private var isSearchingMembers: Bool {
        !memberSearchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var shouldShowMemberOptions: Bool {
        isSearchingMembers
    }

    var body: some View {
        if wrapsInNavigationStack {
            NavigationStack {
                formContent
            }
        } else {
            formContent
        }
    }

    private var formContent: some View {
        Form {
                groupPhotoEditor
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)

                Section("Group") {
                    TextField("Group name (optional)", text: $groupName)
                        .textInputAutocapitalization(.words)
                        .submitLabel(.done)
                        .onSubmit(saveGroup)
                }

                Section("Members") {
                    MemberComposerSearchRow(
                        selectedMembers: selectedMembers,
                        searchText: $memberSearchText,
                        onRemoveMember: removeSelection
                    )
                }

                if shouldShowMemberOptions {
                    Section {
                        if availableContacts.isEmpty {
                            Text("No contacts available.")
                                .foregroundStyle(.secondary)
                        } else if filteredContacts.isEmpty {
                            Text("No contacts found")
                                .foregroundStyle(.secondary)
                        } else {
                            ForEach(filteredContacts) { contact in
                                Button {
                                    toggleSelection(for: contact.id)
                                } label: {
                                    HStack(spacing: 12) {
                                        Image(systemName: "person.crop.circle.fill")
                                            .font(.title3)
                                            .foregroundStyle(.secondary)

                                        Text(contact.name)
                                            .foregroundStyle(.primary)

                                        Spacer()

                                        Image(systemName: "checkmark")
                                            .font(.headline.weight(.semibold))
                                            .foregroundStyle(Color.accentColor)
                                            .opacity(selectedContactIDs.contains(contact.id) ? 1 : 0)
                                            .animation(nil, value: selectedContactIDs.contains(contact.id))
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    } header: {
                        Text("Members")
                    }
                }
            }
        .navigationTitle(navigationTitle)
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: selectedPhoto) { _, newPhoto in
            Task {
                photoData = try? await newPhoto?.loadTransferable(type: Data.self)
            }
        }
        .toolbar {
            if showsCancelButton {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }

            ToolbarItem(placement: .confirmationAction) {
                Button(confirmationTitle, action: saveGroup)
                    .disabled(!canSave)
            }
        }
    }

    private var groupPhotoEditor: some View {
        VStack(spacing: 12) {
            ZStack(alignment: .topTrailing) {
                GroupAvatar(name: displayNameForPhoto, photoData: photoData, size: 160)

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
                .buttonStyle(GroupNoPressFeedbackButtonStyle())
                .offset(x: 2, y: -2)
                .accessibilityIdentifier("Choose Group Photo")
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 18)
        .padding(.bottom, 6)
        .accessibilityIdentifier("Group Photo Editor")
    }

    private var displayNameForPhoto: String {
        if !trimmedGroupName.isEmpty {
            return trimmedGroupName
        }

        if !selectedMembers.isEmpty {
            return selectedMembers
                .map(\.name)
                .joined(separator: ", ")
        }

        return "Group"
    }

    private var canSave: Bool {
        canCreate
    }

    private func saveGroup() {
        guard canSave else { return }

        onSave(trimmedGroupName, selectedMembers, photoData)
        dismiss()
    }

    private func toggleSelection(for id: AppContact.ID) {
        if let index = selectedContactIDs.firstIndex(of: id) {
            selectedContactIDs.remove(at: index)
        } else {
            selectedContactIDs.append(id)
            memberSearchText = ""
        }
    }

    private func removeSelection(for id: AppContact.ID) {
        selectedContactIDs.removeAll { $0 == id }
    }
}

private struct GroupNoPressFeedbackButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
    }
}

private struct MemberComposerSearchRow: View {
    let selectedMembers: [AppContact]
    @Binding var searchText: String
    let onRemoveMember: (AppContact.ID) -> Void
    @State private var isSearchFocused = false
    @State private var selectedMemberID: AppContact.ID?

    var body: some View {
        WrappingHStack(spacing: -4, rowSpacing: 6) {
            ForEach(Array(selectedMembers.enumerated()), id: \.element.id) { index, member in
                Text(memberDisplayText(for: member, at: index))
                    .fontWeight(.semibold)
                    .foregroundStyle(selectedMemberID == member.id ? Color.white : Color.primary)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2)
                    .background {
                        if selectedMemberID == member.id {
                            RoundedRectangle(cornerRadius: 7, style: .continuous)
                                .fill(Color.accentColor)
                        }
                    }
                    .contentShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
                    .onTapGesture {
                        selectedMemberID = member.id
                        isSearchFocused = true
                    }
            }

            BackspaceAwareTextField(
                placeholder: selectedMembers.isEmpty ? "Search contacts" : "",
                text: $searchText,
                isFocused: $isSearchFocused,
                hidesCaret: selectedMemberID != nil,
                onBackspaceWhenEmpty: handleBackspaceWhenEmpty,
                onTextEntry: clearSelectedMember
            )
                .frame(width: searchFieldWidth)
                .frame(height: 24)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 2)
        .background {
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture {
                    selectedMemberID = nil
                    isSearchFocused = true
                }
        }
        .onChange(of: selectedMembers.map(\.id)) { _, memberIDs in
            guard let selectedMemberID, !memberIDs.contains(selectedMemberID) else { return }
            self.selectedMemberID = nil
        }
    }

    private func memberDisplayText(for member: AppContact, at index: Int) -> String {
        let hasFollowingMember = index < selectedMembers.count - 1
        let isEditingAtEnd = isSearchFocused && selectedMemberID == nil
        let isInputting = !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let shouldShowComma = hasFollowingMember || isInputting || isEditingAtEnd

        return shouldShowComma ? "\(member.name), " : member.name
    }

    private var searchFieldWidth: CGFloat {
        if selectedMembers.isEmpty {
            return 160
        }

        let trimmedSearchText = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedSearchText.isEmpty else {
            return isSearchFocused && selectedMemberID == nil ? 12 : 4
        }

        return max(32, CGFloat(trimmedSearchText.count) * 10 + 18)
    }

    private func handleBackspaceWhenEmpty() {
        if let selectedMemberID {
            onRemoveMember(selectedMemberID)
            self.selectedMemberID = nil
            return
        }

        selectedMemberID = selectedMembers.last?.id
    }

    private func clearSelectedMember() {
        selectedMemberID = nil
    }
}

private struct BackspaceAwareTextField: UIViewRepresentable {
    let placeholder: String
    @Binding var text: String
    @Binding var isFocused: Bool
    let hidesCaret: Bool
    let onBackspaceWhenEmpty: () -> Void
    let onTextEntry: () -> Void

    func makeUIView(context: Context) -> BackspaceTextField {
        let textField = BackspaceTextField()
        textField.delegate = context.coordinator
        textField.onBackspaceWhenEmpty = onBackspaceWhenEmpty
        textField.borderStyle = .none
        textField.backgroundColor = .clear
        textField.font = .preferredFont(forTextStyle: .body)
        textField.adjustsFontForContentSizeCategory = true
        textField.autocorrectionType = .no
        textField.autocapitalizationType = .words
        textField.returnKeyType = .done
        textField.addTarget(context.coordinator, action: #selector(Coordinator.textDidChange(_:)), for: .editingChanged)
        return textField
    }

    func updateUIView(_ uiView: BackspaceTextField, context: Context) {
        context.coordinator.parent = self
        uiView.onBackspaceWhenEmpty = onBackspaceWhenEmpty
        uiView.placeholder = placeholder
        uiView.hidesCaret = hidesCaret

        if uiView.text != text {
            uiView.text = text
        }

        if isFocused, !uiView.isFirstResponder {
            uiView.becomeFirstResponder()
            let endPosition = uiView.endOfDocument
            uiView.selectedTextRange = uiView.textRange(from: endPosition, to: endPosition)
        } else if !isFocused, uiView.isFirstResponder {
            uiView.resignFirstResponder()
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    final class Coordinator: NSObject, UITextFieldDelegate {
        var parent: BackspaceAwareTextField

        init(parent: BackspaceAwareTextField) {
            self.parent = parent
        }

        @objc func textDidChange(_ textField: UITextField) {
            parent.text = textField.text ?? ""
            if !(textField.text ?? "").isEmpty {
                parent.onTextEntry()
            }
        }

        func textFieldDidBeginEditing(_ textField: UITextField) {
            parent.isFocused = true
        }

        func textFieldDidEndEditing(_ textField: UITextField) {
            parent.isFocused = false
        }

        func textFieldShouldReturn(_ textField: UITextField) -> Bool {
            textField.resignFirstResponder()
            return true
        }
    }

    final class BackspaceTextField: UITextField {
        var onBackspaceWhenEmpty: (() -> Void)?
        var hidesCaret = false {
            didSet {
                guard oldValue != hidesCaret else { return }
                setNeedsDisplay()
            }
        }

        override func caretRect(for position: UITextPosition) -> CGRect {
            hidesCaret ? .zero : super.caretRect(for: position)
        }

        override func deleteBackward() {
            if text?.isEmpty ?? true {
                onBackspaceWhenEmpty?()
            } else {
                super.deleteBackward()
            }
        }
    }
}

private struct WrappingHStack: Layout {
    let spacing: CGFloat
    let rowSpacing: CGFloat

    func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) -> CGSize {
        let maxWidth = proposal.width ?? 0
        let rows = rows(for: subviews, maxWidth: maxWidth)
        let height = rows.reduce(CGFloat.zero) { partialResult, row in
            partialResult + row.height
        } + rowSpacing * CGFloat(max(rows.count - 1, 0))

        return CGSize(width: maxWidth, height: height)
    }

    func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) {
        let rows = rows(for: subviews, maxWidth: bounds.width)
        var y = bounds.minY

        for row in rows {
            var x = bounds.minX
            for item in row.items {
                let itemSize = item.size
                subviews[item.index].place(
                    at: CGPoint(x: x, y: y + (row.height - itemSize.height) / 2),
                    proposal: ProposedViewSize(itemSize)
                )
                x += itemSize.width + spacing
            }
            y += row.height + rowSpacing
        }
    }

    private func rows(for subviews: Subviews, maxWidth: CGFloat) -> [Row] {
        guard !subviews.isEmpty else { return [] }

        let wrappingWidth = max(maxWidth, 1)
        var rows: [Row] = []
        var currentRow = Row()

        for index in subviews.indices {
            let size = subviews[index].sizeThatFits(.unspecified)
            let nextWidth = currentRow.items.isEmpty
                ? size.width
                : currentRow.width + spacing + size.width

            if nextWidth > wrappingWidth, !currentRow.items.isEmpty {
                rows.append(currentRow)
                currentRow = Row()
            }

            currentRow.append(index: index, size: size, spacing: spacing)
        }

        if !currentRow.items.isEmpty {
            rows.append(currentRow)
        }

        return rows
    }

    private struct Row {
        var items: [Item] = []
        var width: CGFloat = 0
        var height: CGFloat = 0

        mutating func append(index: Int, size: CGSize, spacing: CGFloat) {
            if !items.isEmpty {
                width += spacing
            }

            items.append(Item(index: index, size: size))
            width += size.width
            height = max(height, size.height)
        }
    }

    private struct Item {
        let index: Int
        let size: CGSize
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
                                VennDiagramIcon()
                                Text(groups[groupIndex].displayTitle)
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
    @State private var memberSearchText = ""

    private var filteredMembers: [AppContact] {
        contactsMatching(memberSearchText, in: group.members)
    }

    var body: some View {
        NavigationStack {
            List {
                if group.members.isEmpty {
                    Text("No contacts yet.")
                        .foregroundStyle(.secondary)
                } else if filteredMembers.isEmpty {
                    Text("No contacts found")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(filteredMembers) { member in
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
            }
            .listStyle(.plain)
            .navigationTitle(group.displayTitle)
            .searchable(text: $memberSearchText, prompt: "Search Members")
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
    @State private var memberSearchText = ""

    private var filteredContacts: [AppContact] {
        memberOptions(searchText: memberSearchText, in: availableContacts, selectedIDs: selectedContactIDs)
    }

    var body: some View {
        NavigationStack {
            List {
                if availableContacts.isEmpty {
                    Text("No contacts available.")
                        .foregroundStyle(.secondary)
                } else if filteredContacts.isEmpty && memberSearchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text("Search contacts to add members.")
                        .foregroundStyle(.secondary)
                } else if filteredContacts.isEmpty {
                    Text("No contacts found")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(filteredContacts) { contact in
                        Button {
                            toggleSelection(for: contact.id)
                        } label: {
                            HStack(spacing: 12) {
                                Text(contact.name)
                                    .foregroundStyle(.primary)

                                Spacer()

                                Image(systemName: "checkmark")
                                    .font(.headline.weight(.semibold))
                                    .foregroundStyle(Color.accentColor)
                                    .opacity(selectedContactIDs.contains(contact.id) ? 1 : 0)
                                    .animation(nil, value: selectedContactIDs.contains(contact.id))
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .navigationTitle("Add Members")
            .searchable(text: $memberSearchText, prompt: "Search Contacts")
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
