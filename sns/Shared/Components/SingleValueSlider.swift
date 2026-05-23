import SwiftUI

struct SingleValueSlider: View {
    @Binding var value: Int
    @State private var activeDragFraction: CGFloat?
    @State private var dragResetTask: Task<Void, Never>?

    let bounds: ClosedRange<Int>
    let accessibilityLabel: String
    let valueLabel: ((Int) -> String)?

    init(
        value: Binding<Int>,
        bounds: ClosedRange<Int>,
        accessibilityLabel: String = "Slider",
        valueLabel: ((Int) -> String)? = nil
    ) {
        self._value = value
        self.bounds = bounds
        self.accessibilityLabel = accessibilityLabel
        self.valueLabel = valueLabel
    }

    private let thumbSize: CGFloat = 32
    private let trackHeight: CGFloat = 6
    private let valueLabelWidth: CGFloat = 112
    private let snapAnimation = Animation.easeOut(duration: 0.18)

    var body: some View {
        GeometryReader { geometry in
            let usableWidth = max(1, geometry.size.width - thumbSize)
            let displayFraction = activeDragFraction ?? fraction(for: value)
            let centerX = xPosition(forFraction: displayFraction, usableWidth: usableWidth)
            let hasValueLabel = valueLabel != nil
            let sliderCenterY = hasValueLabel ? max(thumbSize / 2, geometry.size.height - 20) : geometry.size.height / 2
            let labelX = centerX - (valueLabelWidth / 2)

            ZStack(alignment: .topLeading) {
                Capsule()
                    .fill(Color.gray.opacity(0.25))
                    .frame(height: trackHeight)
                    .offset(y: sliderCenterY - (trackHeight / 2))

                Capsule()
                    .fill(Color.accentColor)
                    .frame(width: geometry.size.width * displayFraction, height: trackHeight)
                    .offset(y: sliderCenterY - (trackHeight / 2))

                Circle()
                    .fill(Color.white)
                    .overlay(Circle().stroke(Color.accentColor, lineWidth: 2))
                    .frame(width: thumbSize, height: thumbSize)
                    .offset(x: centerX - (thumbSize / 2), y: sliderCenterY - (thumbSize / 2))
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { gestureValue in
                                dragResetTask?.cancel()
                                let fraction = fraction(forLocationX: gestureValue.location.x, usableWidth: usableWidth)
                                activeDragFraction = fraction
                                value = value(for: fraction)
                            }
                            .onEnded { gestureValue in
                                let fraction = fraction(forLocationX: gestureValue.location.x, usableWidth: usableWidth)
                                let snappedValue = value(for: fraction)
                                value = snappedValue

                                withAnimation(snapAnimation) {
                                    activeDragFraction = self.fraction(for: snappedValue)
                                }

                                dragResetTask = Task { @MainActor in
                                    try? await Task.sleep(nanoseconds: 180_000_000)
                                    activeDragFraction = nil
                                    dragResetTask = nil
                                }
                            }
                    )

                if let valueLabel {
                    Text(valueLabel(value))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                        .frame(width: valueLabelWidth, alignment: .center)
                        .offset(x: labelX)
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityValue("\(value)")
        .onDisappear {
            dragResetTask?.cancel()
            dragResetTask = nil
        }
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment:
                value = min(value + 1, bounds.upperBound)
            case .decrement:
                value = max(value - 1, bounds.lowerBound)
            @unknown default:
                break
            }
        }
    }

    private func fraction(for value: Int) -> CGFloat {
        let range = CGFloat(bounds.upperBound - bounds.lowerBound)
        guard range > 0 else { return 0 }
        return CGFloat(value - bounds.lowerBound) / range
    }

    private func xPosition(forFraction fraction: CGFloat, usableWidth: CGFloat) -> CGFloat {
        (thumbSize / 2) + (min(max(fraction, 0), 1) * usableWidth)
    }

    private func fraction(forLocationX locationX: CGFloat, usableWidth: CGFloat) -> CGFloat {
        let clampedX = min(max(locationX, thumbSize / 2), usableWidth + (thumbSize / 2))
        return (clampedX - (thumbSize / 2)) / usableWidth
    }

    private func value(for fraction: CGFloat) -> Int {
        let rawValue = CGFloat(bounds.lowerBound) + (fraction * CGFloat(bounds.upperBound - bounds.lowerBound))
        return min(max(Int(round(rawValue)), bounds.lowerBound), bounds.upperBound)
    }
}
