import SwiftUI

struct MatchingRadiusView: View {
    @Binding var radiusMiles: Int
    @Binding var extendRadiusIfNeeded: Bool

    var body: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: 0) {
                    SingleValueSlider(
                        value: $radiusMiles,
                        bounds: 1...50,
                        accessibilityLabel: "Radius Slider",
                        valueLabel: { "\($0) mi" }
                    )
                        .frame(height: 62)
                        .accessibilityIdentifier("Radius Slider")
                }
                .padding(.vertical, 6)
            }

            Section {
                Button {
                    extendRadiusIfNeeded.toggle()
                } label: {
                    HStack {
                        Text("Extend if needed")
                            .foregroundStyle(.primary)

                        Spacer()

                        if extendRadiusIfNeeded {
                            Image(systemName: "checkmark")
                                .foregroundStyle(.tint)
                                .accessibilityHidden(true)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .navigationTitle("Maximum Radius")
    }
}
