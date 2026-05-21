import SwiftUI
import UIKit

struct SettingsView: View {
    @Bindable var appState: AppState

    var body: some View {
        NavigationStack {
            ProfileTabView(appState: appState)
        }
    }
}

struct ProfileTabView: View {
    @Bindable var appState: AppState

    var body: some View {
        List {
            Section {
                NavigationLink(value: RootDestination.myCard) {
                    HStack(spacing: 14) {
                        MyCardAvatarView(contact: appState.myCard, size: 56)

                        VStack(alignment: .leading, spacing: 3) {
                            Text(appState.myCard.name)
                                .font(.headline)
                                .foregroundStyle(.primary)
                            Text("My Card")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 6)
                }
                .accessibilityIdentifier("My Card Row")
            } footer: {
                Text("Shared when adding a contact.")
            }

            Section("Account") {
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
                substanceUseRows(
                    selection: appState.substanceUse,
                    accessibilityPrefix: "Account"
                )
            }

            Section("Logbook") {
                NavigationLink(value: RootDestination.page(.logbook)) {
                    preferenceValueRow(title: "Logbook", value: "\(MockData.logbookItems.count) events", systemImage: "checklist")
                }
                .accessibilityIdentifier("Logbook Row")
            }
        }
        .listStyle(.insetGrouped)
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

    private func substanceUseRows(
        selection: [SubstanceUseCategory: SubstanceUseAnswer],
        accessibilityPrefix: String
    ) -> some View {
        ForEach(Array(SubstanceUseCategory.allCases), id: \.self) { substance in
            NavigationLink(value: RootDestination.profileSubstanceUse(substance)) {
                preferenceValueRow(
                    title: substance.label,
                    value: selection[substance, default: .no].label,
                    systemImage: substance.systemImage
                )
            }
            .accessibilityIdentifier("\(accessibilityPrefix) \(substance.label) Substance Use Row")
        }
    }
}

struct MyCardDetailView: View {
    @Binding var contact: AppContact
    @State private var isEditing = false

    var body: some View {
        Form {
            if isEditing {
                Section("Name") {
                    TextField("First Name", text: $contact.firstName)
                        .textContentType(.givenName)
                        .accessibilityIdentifier("My Card First Name Field")
                    TextField("Last Name", text: $contact.lastName)
                        .textContentType(.familyName)
                        .accessibilityIdentifier("My Card Last Name Field")
                }

                Section("Notes") {
                    TextEditor(text: $contact.notes)
                        .frame(minHeight: 120)
                        .accessibilityIdentifier("My Card Notes Field")
                }
            } else {
                Section("Name") {
                    detailRow(title: "First Name", value: contact.firstName)
                    detailRow(title: "Last Name", value: contact.lastName)
                }

                Section("Notes") {
                    Text(contact.notes)
                }
            }
        }
        .navigationTitle("My Card")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(isEditing ? "Done" : "Edit") {
                    isEditing.toggle()
                }
            }
        }
    }

    @ViewBuilder
    private func detailRow(title: String, value: String) -> some View {
        if !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            HStack {
                Text(title)
                Spacer()
                Text(value)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.trailing)
            }
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
                Text(contact.initials)
                    .font(.system(size: size * 0.38, weight: .semibold, design: .serif))
                    .foregroundStyle(Color.accentColor)
                    .accessibilityIdentifier("My Card Initials Avatar")
            }
        }
        .frame(width: size, height: size)
        .accessibilityLabel("My Card photo")
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
            Section("Account") {
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
        .navigationTitle("Account")
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
    @Binding var isShared: Bool

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

            ProfileDisclosureSection(isShared: $isShared)
        }
        .navigationTitle("Age")
    }
}

struct AccountSingleSelectView<Option: ProfileCriteriaOption>: View {
    let title: String
    @Binding var selection: Option
    @Binding var isShared: Bool

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
                            if selection == option {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(.tint)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            } header: {
                Text(title)
            }

            ProfileDisclosureSection(isShared: $isShared)
        }
        .navigationTitle(title)
    }
}

struct AccountSubstanceUseView: View {
    let category: SubstanceUseCategory
    @Binding var selection: SubstanceUseAnswer
    @Binding var isShared: Bool

    var body: some View {
        SubstanceUseAnswerView(
            title: category.label,
            selection: $selection,
            isShared: $isShared
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
                VStack(alignment: .leading, spacing: 14) {
                    Text(AgeDisplay.rangeLabel(min: preferredAgeMin, max: preferredAgeMax))
                        .font(.title2.weight(.semibold))

                    AgeRangeSlider(
                        minValue: $preferredAgeMin,
                        maxValue: $preferredAgeMax,
                        bounds: AgeDisplay.bounds
                    )
                    .frame(height: 36)
                    .accessibilityIdentifier("Age Range Slider")

                    HStack {
                        Text("\(AgeDisplay.bounds.lowerBound)")
                        Spacer()
                        Text("\(AgeDisplay.bounds.upperBound)+")
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
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
                            if matchPolicy == policy {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(.tint)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            } footer: {
                Text("Choose how broadly this week's match can be selected.")
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
                    if selection.contains(option) {
                        Image(systemName: "checkmark")
                            .foregroundStyle(.tint)
                    }
                }
            }
            .buttonStyle(.plain)
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
    var isShared: Binding<Bool>?

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

                            if selection == option {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(.tint)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("\(title) \(option.label) Substance Use Option")
                }
            }

            if let isShared {
                ProfileDisclosureSection(isShared: isShared)
            }
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct ProfileDisclosureSection: View {
    @Binding var isShared: Bool

    var body: some View {
        Section {
            Button {
                isShared.toggle()
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: isShared ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(isShared ? Color.accentColor : Color.secondary)

                    Text("Share with matched person")
                        .foregroundStyle(.primary)
                }
            }
            .buttonStyle(.plain)
        }
    }
}
