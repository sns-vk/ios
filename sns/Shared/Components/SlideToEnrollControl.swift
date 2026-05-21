import SwiftUI

struct SlideToEnrollControl: View {
    let isEnrolledInBatch: Bool
    var isEnabled: Bool = true
    let resetTrigger: Int
    var shimmerTrigger: Int = 0
    var disabledText = "Add availability to enroll"
    let onCompleted: () -> Void

    @State private var knobOffset: CGFloat = 0
    @State private var shimmerPhase: CGFloat = -1

    var body: some View {
        GeometryReader { geometry in
            let trackHeight: CGFloat = 56
            let knobInset: CGFloat = 4
            let knobSize = trackHeight - (knobInset * 2)
            let maxOffset = geometry.size.width - knobSize - (knobInset * 2)
            let currentOffset = isEnrolledInBatch ? maxOffset : knobOffset
            let knobWidth = isEnrolledInBatch ? knobSize : knobSize + currentOffset
            let knobX = isEnrolledInBatch ? maxOffset + knobInset : knobInset

            ZStack(alignment: .leading) {
                Capsule()
                    .fill(.ultraThinMaterial)
                    .overlay {
                        Capsule()
                            .fill(Color.gray.opacity(isEnabled || isEnrolledInBatch ? 0.12 : 0.08))
                    }
                    .overlay {
                        Capsule()
                            .stroke(Color.white.opacity(0.42), lineWidth: 1)
                    }

                sliderLabel

                ZStack(alignment: .trailing) {
                    Capsule()
                        .fill(isEnabled || isEnrolledInBatch ? Color.accentColor : Color(.systemBackground))
                        .shadow(color: .black.opacity(0.14), radius: 8, y: 3)
                        .overlay {
                            Capsule()
                                .stroke(Color.white.opacity(isEnabled || isEnrolledInBatch ? 0.36 : 0.5), lineWidth: 1)
                        }

                    Image(systemName: knobSystemImage)
                        .font(.headline)
                        .foregroundStyle(knobColor)
                        .frame(width: knobSize, height: knobSize)
                }
                .frame(width: knobWidth, height: knobSize)
                .offset(x: knobX)
                .animation(.interactiveSpring(response: 0.25, dampingFraction: 0.9), value: currentOffset)
                .animation(.interactiveSpring(response: 0.28, dampingFraction: 0.82), value: isEnrolledInBatch)
            }
            .frame(height: trackHeight)
            .contentShape(Rectangle())
            .accessibilityElement(children: .contain)
            .accessibilityLabel(sliderText)
            .accessibilityIdentifier("Weekly Batch Enrollment Slider")
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        guard isEnabled, !isEnrolledInBatch else { return }
                        knobOffset = min(max(0, value.translation.width), maxOffset)
                    }
                    .onEnded { _ in
                        guard isEnabled, !isEnrolledInBatch else { return }

                        if knobOffset >= (maxOffset * 0.85) {
                            withAnimation(.spring(response: 0.25, dampingFraction: 0.9)) {
                                knobOffset = maxOffset
                            }
                            onCompleted()
                        } else {
                            withAnimation(.spring(response: 0.25, dampingFraction: 0.9)) {
                                knobOffset = 0
                            }
                        }
                    }
            )
        }
        .frame(height: 56)
        .opacity(isEnabled || isEnrolledInBatch ? 1 : 0.65)
        .onChange(of: shimmerTrigger) { _, _ in
            playTextShimmer()
        }
        .onChange(of: resetTrigger) { _, _ in
            guard !isEnrolledInBatch else { return }
            withAnimation(.spring(response: 0.25, dampingFraction: 0.9)) {
                knobOffset = 0
            }
        }
        .onChange(of: isEnabled) { _, newValue in
            guard !newValue, !isEnrolledInBatch else { return }
            withAnimation(.spring(response: 0.25, dampingFraction: 0.9)) {
                knobOffset = 0
            }
        }
    }

    private var sliderLabel: some View {
        Text(sliderText)
            .font(.headline)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity)
            .overlay {
                if isEnabled && !isEnrolledInBatch {
                    Text(sliderText)
                        .font(.headline)
                        .foregroundStyle(
                            LinearGradient(
                                stops: [
                                    .init(color: .clear, location: 0),
                                    .init(color: .white.opacity(0.9), location: 0.5),
                                    .init(color: .clear, location: 1)
                                ],
                                startPoint: UnitPoint(x: shimmerPhase, y: 0.5),
                                endPoint: UnitPoint(x: shimmerPhase + 0.55, y: 0.5)
                            )
                        )
                }
            }
    }

    private func playTextShimmer() {
        guard isEnabled, !isEnrolledInBatch else { return }
        shimmerPhase = -0.65
        withAnimation(.easeInOut(duration: 0.9)) {
            shimmerPhase = 1.1
        }
    }

    private var sliderText: String {
        if isEnrolledInBatch {
            return "Enrolled"
        }

        return isEnabled ? "Slide to Enroll" : disabledText
    }

    private var knobSystemImage: String {
        if isEnrolledInBatch {
            return "checkmark"
        }

        return isEnabled ? "chevron.right" : "lock.fill"
    }

    private var knobColor: Color {
        isEnabled || isEnrolledInBatch ? .white : .secondary
    }
}
