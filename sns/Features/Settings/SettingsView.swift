import SwiftUI
import UIKit
import PhotosUI

struct ProfileTabView: View {
    @Bindable var appState: AppState

    var body: some View {
        List {
            Section {
                NavigationLink(value: RootDestination.myCard) {
                    HStack(spacing: 14) {
                        MyCardAvatarView(contact: appState.myCard, size: 56)

                        VStack(alignment: .leading, spacing: 3) {
                            Text("Sharing Card")
                                .font(.headline)
                                .foregroundStyle(.primary)
                            Text("What is shared to your match and when.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 6)
                }
                .accessibilityIdentifier("Sharing Card Row")
            }

            Section("Name") {
                NavigationLink(value: RootDestination.profileField(.firstName)) {
                    preferenceValueRow(title: "First Name", value: profileValue(appState.myCard.firstName), systemImage: "person.text.rectangle")
                }
                .accessibilityIdentifier("Account First Name Row")

                NavigationLink(value: RootDestination.profileField(.lastName)) {
                    preferenceValueRow(title: "Last Name", value: profileValue(appState.myCard.lastName), systemImage: "person.text.rectangle")
                }
                .accessibilityIdentifier("Account Last Name Row")

                NavigationLink(value: RootDestination.profileField(.nickname)) {
                    preferenceValueRow(title: "Nickname", value: profileValue(appState.myCard.nickname), systemImage: "quote.bubble")
                }
                .accessibilityIdentifier("Account Nickname Row")
            }

            Section("Demographics") {
                NavigationLink(value: RootDestination.profileField(.age)) {
                    preferenceValueRow(title: "Age", value: "\(appState.age)", systemImage: "number")
                }
                .accessibilityIdentifier("Account Age Row")

                NavigationLink(value: RootDestination.profileField(.gender)) {
                    preferenceValueRow(title: "Gender", value: appState.gender.label, systemImage: "person.fill")
                }
                .accessibilityIdentifier("Account Gender Row")

                NavigationLink(value: RootDestination.profileField(.pronouns)) {
                    preferenceValueRow(title: "Pronouns", value: appState.pronouns.label, systemImage: "text.bubble")
                }
                .accessibilityIdentifier("Account Pronouns Row")

                NavigationLink(value: RootDestination.profileField(.sexuality)) {
                    preferenceValueRow(title: "Sexuality", value: appState.sexuality.label, systemImage: "heart.circle")
                }
                .accessibilityIdentifier("Account Sexuality Row")
            }

            Section("Substance Use") {
                ForEach(Array(SubstanceUseCategory.allCases), id: \.self) { substance in
                    NavigationLink(value: RootDestination.profileSubstanceUse(substance)) {
                        preferenceValueRow(
                            title: substance.label,
                            value: appState.substanceUse[substance, default: .no].label,
                            systemImage: substance.systemImage
                        )
                    }
                    .accessibilityIdentifier("Account \(substance.label) Substance Use Row")
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    private func profileValue(_ value: String) -> String {
        let trimmedValue = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedValue.isEmpty ? "Not set" : trimmedValue
    }

    private func preferenceValueRow(title: String, value: String, systemImage: String) -> some View {
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

}

struct SharingCardView: View {
    @Bindable var appState: AppState
    @State private var selectedPhoto: PhotosPickerItem?

    var body: some View {
        List {
            photoEditor
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)

            Section("Photo") {
                sharingCardRow(
                    title: "Photo",
                    systemImage: "camera",
                    sharedField: .photo,
                    valueOverride: hasMyCardPhoto ? nil : "No photo",
                    isMuted: !hasMyCardPhoto,
                    accessibilityIdentifier: "Sharing Card Photo Row"
                )
            }

            Section("Name") {
                sharingCardRow(
                    title: "First Name",
                    systemImage: "person.text.rectangle",
                    sharedField: .firstName,
                    accessibilityIdentifier: "Sharing Card First Name Row"
                )

                sharingCardRow(
                    title: "Last Name",
                    systemImage: "person.text.rectangle",
                    sharedField: .lastName,
                    accessibilityIdentifier: "Sharing Card Last Name Row"
                )

                sharingCardRow(
                    title: "Nickname",
                    systemImage: "quote.bubble",
                    sharedField: .nickname,
                    accessibilityIdentifier: "Sharing Card Nickname Row"
                )
            }

            Section("Demographics") {
                sharingCardRow(
                    title: "Age",
                    systemImage: "number",
                    sharedField: .age,
                    accessibilityIdentifier: "Sharing Card Age Row"
                )

                sharingCardRow(
                    title: "Gender",
                    systemImage: "person.fill",
                    sharedField: .gender,
                    accessibilityIdentifier: "Sharing Card Gender Row"
                )

                sharingCardRow(
                    title: "Pronouns",
                    systemImage: "text.bubble",
                    sharedField: .pronouns,
                    accessibilityIdentifier: "Sharing Card Pronouns Row"
                )

                sharingCardRow(
                    title: "Sexuality",
                    systemImage: "heart.circle",
                    sharedField: .sexuality,
                    accessibilityIdentifier: "Sharing Card Sexuality Row"
                )
            }

            Section {
                ForEach(Array(SubstanceUseCategory.allCases), id: \.self) { substance in
                    sharingCardRow(
                        title: substance.label,
                        systemImage: substance.systemImage,
                        sharedField: .substanceUse(substance),
                        accessibilityIdentifier: "Sharing Card \(substance.label) Substance Use Row"
                    )
                }
            } header: {
                Text("Substance Use")
            }
        }
        .navigationTitle("Sharing Card")
        .navigationBarTitleDisplayMode(.inline)
        .listStyle(.insetGrouped)
        .onChange(of: selectedPhoto) { _, newPhoto in
            Task {
                appState.myCard.photoData = try? await newPhoto?.loadTransferable(type: Data.self)
            }
        }
    }

    private var photoEditor: some View {
        VStack(spacing: 12) {
            ZStack(alignment: .topTrailing) {
                MyCardAvatarView(contact: appState.myCard, size: 160)

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
                .buttonStyle(NoPressFeedbackButtonStyle())
                .offset(x: 2, y: -2)
                .accessibilityIdentifier("Choose Account Photo")
            }

        }
        .frame(maxWidth: .infinity)
        .padding(.top, 18)
        .padding(.bottom, 6)
        .accessibilityIdentifier("Sharing Card Photo Editor")
    }

    private var hasMyCardPhoto: Bool {
        guard let photoData = appState.myCard.photoData else { return false }
        return UIImage(data: photoData) != nil
    }

    private func sharingCardRow(
        title: String,
        systemImage: String,
        sharedField: ProfileDisclosureField,
        valueOverride: String? = nil,
        isMuted: Bool = false,
        accessibilityIdentifier: String
    ) -> some View {
        NavigationLink(value: RootDestination.sharingField(sharedField)) {
            HStack(spacing: 12) {
                Image(systemName: systemImage)
                    .foregroundStyle(.secondary)
                    .frame(width: 22)

                Text(title)
                    .foregroundStyle(isMuted ? Color.secondary : Color.primary)

                Spacer()

                Text(valueOverride ?? disclosureState(for: sharedField).summary)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.trailing)
            }
        }
        .disabled(isMuted)
        .accessibilityIdentifier(accessibilityIdentifier)
    }

    private func disclosureState(for field: ProfileDisclosureField) -> SharingDisclosureState {
        SharingDisclosureState(
            isSharedWhenMatched: appState.sharedProfileFields.contains(field),
            isSharedWhenAddingContact: appState.sharedContactFields.contains(field)
        )
    }
}

struct SharingFieldView: View {
    @Bindable var appState: AppState
    let field: ProfileDisclosureField

    var body: some View {
        List {
            Section {
                sharingOptionRow(
                    title: "Not shared",
                    state: .notShared,
                    accessibilityIdentifier: "Sharing \(field.title) Not Shared Row"
                )
                sharingOptionRow(
                    title: "Shared when exchanging contacts",
                    state: .contact,
                    accessibilityIdentifier: "Sharing \(field.title) Contact Row"
                )
                sharingOptionRow(
                    title: "Shared when releasing matches",
                    state: .matched,
                    accessibilityIdentifier: "Sharing \(field.title) Matched Row"
                )
            } header: {
                Text(field.title)
            }
        }
        .navigationTitle(field.title)
        .navigationBarTitleDisplayMode(.inline)
        .listStyle(.insetGrouped)
    }

    private func sharingOptionRow(
        title: String,
        state: SharingDisclosureState,
        accessibilityIdentifier: String
    ) -> some View {
        Button {
            setDisclosureState(state)
        } label: {
            HStack {
                Text(title)
                    .foregroundStyle(.primary)

                Spacer()

                RadioSelectionIndicator(isSelected: currentState == state)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(StaticSelectionRowButtonStyle())
        .accessibilityIdentifier(accessibilityIdentifier)
    }

    private var currentState: SharingDisclosureState {
        SharingDisclosureState(
            isSharedWhenMatched: appState.sharedProfileFields.contains(field),
            isSharedWhenAddingContact: appState.sharedContactFields.contains(field)
        )
    }

    private func setDisclosureState(_ state: SharingDisclosureState) {
        appState.sharedProfileFields.remove(field)
        appState.sharedContactFields.remove(field)

        switch state {
        case .notShared:
            break
        case .matched:
            appState.sharedProfileFields.insert(field)
            appState.sharedContactFields.insert(field)
        case .contact:
            appState.sharedContactFields.insert(field)
        }
    }
}

enum SharingDisclosureState: Equatable {
    case notShared
    case matched
    case contact

    init(isSharedWhenMatched: Bool, isSharedWhenAddingContact: Bool) {
        if isSharedWhenMatched {
            self = .matched
        } else if isSharedWhenAddingContact {
            self = .contact
        } else {
            self = .notShared
        }
    }

    var summary: String {
        switch self {
        case .notShared: "Not shared"
        case .matched: "Match + contact"
        case .contact: "Contact only"
        }
    }
}

extension ProfileDisclosureField {
    var title: String {
        switch self {
        case .photo: "Photo"
        case .firstName: "First Name"
        case .lastName: "Last Name"
        case .nickname: "Nickname"
        case .age: "Age"
        case .gender: "Gender"
        case .pronouns: "Pronouns"
        case .sexuality: "Sexuality"
        case .substanceUse(let category): category.label
        }
    }
}

struct MyCardAvatarView: View {
    let contact: AppContact
    let size: CGFloat

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.accentColor.opacity(0.16))

            if let photoData = contact.photoData, let image = UIImage(data: photoData) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: size, height: size)
                    .clipShape(Circle())
            } else {
                Image(systemName: "person.crop.circle.fill")
                    .font(.system(size: size * 0.72, weight: .regular))
                    .foregroundStyle(Color.accentColor)
                    .accessibilityIdentifier("My Card Default Avatar")
            }
        }
        .frame(width: size, height: size)
        .accessibilityLabel("My Card photo")
    }
}

private struct NoPressFeedbackButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
    }
}

extension SubstanceUseCategory {
    var systemImage: String {
        switch self {
        case .vaping: "wind"
        case .smoking: "flame"
        case .marijuana: "leaf"
        case .drinking: "wineglass"
        case .other: "ellipsis.circle"
        }
    }
}

struct AccountProfileView: View {
    @Binding var age: Int
    @Binding var gender: GenderIdentity
    @Binding var pronouns: PronounOption
    @Binding var sexuality: SexualityOption
    @Binding var substanceUse: [SubstanceUseCategory: SubstanceUseAnswer]

    var body: some View {
        Form {
            Section("Demographics") {
                Stepper(value: $age, in: AgeDisplay.bounds) {
                    valueRow(title: "Age", value: AgeDisplay.label(for: age))
                }

                Picker("Gender", selection: $gender) {
                    ForEach(GenderIdentity.allCases) { option in
                        Text(option.label).tag(option)
                    }
                }

                Picker("Pronouns", selection: $pronouns) {
                    ForEach(PronounOption.allCases) { option in
                        Text(option.label).tag(option)
                    }
                }

                Picker("Sexuality", selection: $sexuality) {
                    ForEach(SexualityOption.allCases) { option in
                        Text(option.label).tag(option)
                    }
                }
            }

            Section("Substance Use") {
                ForEach(Array(SubstanceUseCategory.allCases), id: \.self) { substance in
                    NavigationLink(value: RootDestination.profileSubstanceUse(substance)) {
                        valueRow(
                            title: substance.label,
                            value: substanceUse[substance, default: .no].label
                        )
                    }
                }
            }
        }
        .navigationTitle("Demographics")
    }

    private func valueRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(value)
                .foregroundStyle(.secondary)
        }
    }
}

struct AccountAgeView: View {
    @Binding var age: Int

    var body: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: 14) {
                    Text(AgeDisplay.label(for: age))
                        .font(.title2.weight(.semibold))

                    SingleValueSlider(
                        value: $age,
                        bounds: AgeDisplay.bounds,
                        accessibilityLabel: "Age Slider"
                    )
                    .frame(height: 36)
                    .accessibilityIdentifier("Age Slider")

                    HStack {
                        Text("\(AgeDisplay.bounds.lowerBound)")
                        Spacer()
                        Text("\(AgeDisplay.bounds.upperBound)+")
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
                .padding(.vertical, 6)
            }
        }
        .navigationTitle("Age")
    }
}

struct AccountTextFieldView: View {
    let title: String
    @Binding var text: String
    let textContentType: UITextContentType

    var body: some View {
        Form {
            Section {
                TextField(title, text: $text)
                    .textContentType(textContentType)
                    .accessibilityIdentifier("Account \(title) Field")
            }
        }
        .navigationTitle(title)
    }
}

struct AccountSingleSelectView<Option: ProfileCriteriaOption>: View {
    let title: String
    @Binding var selection: Option

    var body: some View {
        Form {
            Section {
                ForEach(Array(Option.allCases), id: \.self) { option in
                    Button {
                        selection = option
                    } label: {
                        HStack {
                            Text(option.label)
                                .foregroundStyle(.primary)
                            Spacer()
                            RadioSelectionIndicator(isSelected: selection == option)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(StaticSelectionRowButtonStyle())
                }
            } header: {
                Text(title)
            }
        }
        .navigationTitle(title)
    }
}

struct AccountSubstanceUseView: View {
    let category: SubstanceUseCategory
    @Binding var selection: SubstanceUseAnswer

    var body: some View {
        SubstanceUseAnswerView(
            title: category.label,
            selection: $selection,
            indicatorStyle: .radio
        )
    }
}

struct MatchGenderPreferenceView: View {
    @Binding var preferredGenders: Set<GenderIdentity>

    var body: some View {
        MatchCriteriaMultiSelectView(
            title: "Gender",
            footer: "Select the genders you are open to matching with.",
            selection: $preferredGenders
        )
    }
}

struct MatchSexualityPreferenceView: View {
    @Binding var preferredSexualities: Set<SexualityOption>

    var body: some View {
        MatchCriteriaMultiSelectView(
            title: "Sexuality",
            footer: "Select the sexualities you are open to matching with.",
            selection: $preferredSexualities
        )
    }
}

struct MatchSubstanceUsePreferenceView: View {
    let category: SubstanceUseCategory
    @Binding var selection: SubstanceUseAnswer

    var body: some View {
        SubstanceUseAnswerView(
            title: category.label,
            selection: $selection
        )
    }
}

struct MatchSubstanceUseListView: View {
    let acceptedSubstanceUse: [SubstanceUseCategory: SubstanceUseAnswer]

    var body: some View {
        Form {
            Section {
                ForEach(Array(SubstanceUseCategory.allCases), id: \.self) { substance in
                    NavigationLink(value: RootDestination.matchSubstanceUse(substance)) {
                        HStack {
                            Image(systemName: substance.systemImage)
                                .foregroundStyle(.secondary)
                                .frame(width: 22)

                            Text(substance.label)

                            Spacer()

                            Text(acceptedSubstanceUse[substance, default: .yes].label)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .accessibilityIdentifier("Criteria \(substance.label) Substance Use Row")
                }
            } footer: {
                Text("Choose the answer you are open to for each substance-use category.")
            }
        }
        .navigationTitle("Substance Use")
    }
}

struct AgeRangePreferenceView: View {
    @Binding var preferredAgeMin: Int
    @Binding var preferredAgeMax: Int

    var body: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: 0) {
                    AgeRangeSlider(
                        minValue: $preferredAgeMin,
                        maxValue: $preferredAgeMax,
                        bounds: AgeDisplay.bounds,
                        valueLabel: { AgeDisplay.label(for: $0) }
                    )
                    .frame(height: 62)
                    .accessibilityIdentifier("Age Range Slider")
                }
                .padding(.vertical, 6)
            } footer: {
                Text("Only people in this age range are eligible for matching.")
            }
        }
        .navigationTitle("Age Range")
    }
}

struct MatchPolicyView: View {
    @Binding var matchPolicy: MatchPolicy

    var body: some View {
        Form {
            Section {
                ForEach(MatchPolicy.allCases, id: \.self) { policy in
                    Button {
                        matchPolicy = policy
                    } label: {
                        HStack {
                            Text(policy.label)
                                .foregroundStyle(.primary)
                            Spacer()
                            StaticCheckmark(isVisible: matchPolicy == policy)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(StaticSelectionRowButtonStyle())
                }
            } footer: {
                Text("Choose how connected they are to you.")
            }
        }
        .navigationTitle("Match Policy")
    }
}

struct MatchCriteriaMultiSelectView<Option: ProfileCriteriaOption>: View {
    let title: String
    let footer: String
    @Binding var selection: Set<Option>

    var body: some View {
        Form {
            Section {
                MultiSelectOptionsView(selection: $selection)
            } header: {
                Text(title)
            } footer: {
                Text(footer)
            }
        }
        .navigationTitle(title)
    }
}

struct MultiSelectOptionsView<Option: ProfileCriteriaOption>: View {
    @Binding var selection: Set<Option>

    var body: some View {
        ForEach(Array(Option.allCases), id: \.self) { option in
            Button {
                toggle(option)
            } label: {
                HStack {
                    Text(option.label)
                        .foregroundStyle(.primary)
                    Spacer()
                    StaticCheckmark(isVisible: selection.contains(option))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(StaticSelectionRowButtonStyle())
        }
    }

    private func toggle(_ option: Option) {
        var updatedSelection = selection
        if updatedSelection.contains(option) {
            updatedSelection.remove(option)
        } else {
            updatedSelection.insert(option)
        }
        selection = updatedSelection
    }
}

struct SubstanceUseAnswerView: View {
    let title: String
    @Binding var selection: SubstanceUseAnswer
    var indicatorStyle: SingleSelectionIndicatorStyle = .checkmark

    var body: some View {
        Form {
            Section {
                ForEach(Array(SubstanceUseAnswer.allCases), id: \.self) { option in
                    Button {
                        selection = option
                    } label: {
                        HStack {
                            Text(option.label)
                                .foregroundStyle(.primary)

                            Spacer()

                            SingleSelectionIndicator(
                                isSelected: selection == option,
                                style: indicatorStyle
                            )
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(StaticSelectionRowButtonStyle())
                    .accessibilityIdentifier("\(title) \(option.label) Substance Use Option")
                }
            }
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

enum SingleSelectionIndicatorStyle {
    case checkmark
    case radio
}

private struct SingleSelectionIndicator: View {
    let isSelected: Bool
    let style: SingleSelectionIndicatorStyle

    var body: some View {
        switch style {
        case .checkmark:
            StaticCheckmark(isVisible: isSelected)
        case .radio:
            RadioSelectionIndicator(isSelected: isSelected)
        }
    }
}

private struct RadioSelectionIndicator: View {
    let isSelected: Bool

    var body: some View {
        Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
            .font(.title3)
            .foregroundStyle(isSelected ? Color.accentColor : Color.secondary)
            .transaction { transaction in
                transaction.animation = nil
            }
            .accessibilityHidden(true)
    }
}

struct StaticSelectionRowButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .transaction { transaction in
                transaction.animation = nil
            }
    }
}

private struct StaticCheckmark: View {
    let isVisible: Bool

    var body: some View {
        Image(systemName: "checkmark")
            .foregroundStyle(.tint)
            .opacity(isVisible ? 1 : 0)
            .transaction { transaction in
                transaction.animation = nil
            }
    }
}
