import SwiftUI
import MapKit

struct MatchingLocationView: View {
    @Binding var location: String
    @State private var query = ""

    private var suggestions: [LocationSuggestion] {
        MockData.locationSuggestions(matching: query)
    }

    private var isSearching: Bool {
        !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var selectedSuggestion: LocationSuggestion? {
        MockData.locationSuggestion(forNeighborhood: location)
    }

    var body: some View {
        Form {
            Section {
                HStack {
                    Text("Current")
                    Spacer()
                    Text(location)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.trailing)
                        .accessibilityIdentifier("Current Matching Location")
                }
            } header: {
                Text("Matching Location")
            } footer: {
                Text("Matching uses neighborhood-level location.")
            }

            if let selectedSuggestion {
                Section {
                    NeighborhoodMapPreview(suggestion: selectedSuggestion)
                        .frame(height: 160)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .accessibilityIdentifier("Neighborhood Map Preview")
                } header: {
                    Text("Neighborhood Preview")
                } footer: {
                    Text("The map is a non-interactive preview.")
                }
            }

            Section {
                TextField("Address, neighborhood, or zip", text: $query)
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled()
                    .accessibilityIdentifier("Location Search Field")
            } header: {
                Text("Search")
            } footer: {
                if !isSearching {
                    Text("Choose a suggestion to update your matching location.")
                }
            }

            if isSearching {
                Section {
                    if suggestions.isEmpty {
                        Text("No locations found")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(suggestions) { suggestion in
                            Button {
                                location = suggestion.neighborhoodName
                                query = ""
                            } label: {
                                HStack(spacing: 12) {
                                    Image(systemName: "location.magnifyingglass")
                                        .foregroundStyle(.secondary)
                                        .frame(width: 24)

                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(suggestion.title)
                                            .foregroundStyle(.primary)
                                        if !suggestion.subtitle.isEmpty {
                                            Text(suggestion.subtitle)
                                                .font(.subheadline)
                                                .foregroundStyle(.secondary)
                                        }
                                        Text(suggestion.neighborhoodMappingDescription)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }

                                    Spacer()
                                }
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .accessibilityIdentifier("Location Suggestion \(suggestion.displayName)")
                        }
                    }
                } header: {
                    Text("Suggestions")
                }
            }
        }
        .navigationTitle("Location")
    }
}

private struct NeighborhoodMapPreview: View {
    let suggestion: LocationSuggestion

    private var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: suggestion.latitude, longitude: suggestion.longitude)
    }

    private var region: MKCoordinateRegion {
        MKCoordinateRegion(
            center: coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.025, longitudeDelta: 0.025)
        )
    }

    var body: some View {
        Map(
            position: .constant(.region(region)),
            interactionModes: []
        ) {
            Marker(suggestion.neighborhoodName, coordinate: coordinate)
        }
        .mapControlVisibility(.hidden)
        .allowsHitTesting(false)
    }
}
