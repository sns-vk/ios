import SwiftUI

struct MatchingRadiusView: View {
    @Binding var radiusMiles: Int
    @Binding var extendRadiusIfNeeded: Bool

    var body: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: 14) {
                    Text("Within \(radiusMiles) mi")
                        .font(.title2.weight(.semibold))

                    SingleValueSlider(
                        value: $radiusMiles,
                        bounds: 1...50,
                        accessibilityLabel: "Radius Slider"
                    )
                        .frame(height: 36)
                        .accessibilityIdentifier("Radius Slider")

                    HStack {
                        Text("1 mi")
                        Spacer()
                        Text("50 mi")
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
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

                        Image(systemName: extendRadiusIfNeeded ? "checkmark.circle.fill" : "circle")
                            .font(.title3)
                            .foregroundStyle(extendRadiusIfNeeded ? Color.accentColor : Color.secondary)
                            .accessibilityHidden(true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .navigationTitle("Radius")
    }
}
