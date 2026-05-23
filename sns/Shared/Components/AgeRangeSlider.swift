import SwiftUI

struct AgeRangeSlider: View {
    @Binding var minValue: Int
    @Binding var maxValue: Int
    @State private var activeMinDragFraction: CGFloat?
    @State private var activeMaxDragFraction: CGFloat?
    @State private var minDragResetTask: Task<Void, Never>?
    @State private var maxDragResetTask: Task<Void, Never>?

    let bounds: ClosedRange<Int>
    let valueLabel: ((Int) -> String)?

    init(
        minValue: Binding<Int>,
        maxValue: Binding<Int>,
        bounds: ClosedRange<Int>,
        valueLabel: ((Int) -> String)? = nil
    ) {
        self._minValue = minValue
        self._maxValue = maxValue
        self.bounds = bounds
        self.valueLabel = valueLabel
    }

    private let thumbSize: CGFloat = 32
    private let trackHeight: CGFloat = 6
    private let valueLabelWidth: CGFloat = 56
    private let minimumGap = 1
    private let snapAnimation = Animation.easeOut(duration: 0.18)

    var body: some View {
        GeometryReader { geometry in
            let travelWidth = max(1, geometry.size.width - (thumbSize * 2))
            let minDisplayFraction = activeMinDragFraction ?? minFraction(for: minValue)
            let maxDisplayFraction = activeMaxDragFraction ?? maxFraction(for: maxValue)
            let minCenterX = minXPosition(forFraction: minDisplayFraction, travelWidth: travelWidth)
            let maxCenterX = maxXPosition(forFraction: maxDisplayFraction, travelWidth: travelWidth)
            let hasValueLabel = valueLabel != nil
            let sliderCenterY = hasValueLabel ? max(thumbSize / 2, geometry.size.height - 20) : geometry.size.height / 2

            ZStack(alignment: .topLeading) {
                Capsule()
                    .fill(Color.gray.opacity(0.25))
                    .frame(height: trackHeight)
                    .offset(y: sliderCenterY - (trackHeight / 2))

                Capsule()
                    .fill(Color.accentColor)
                    .frame(width: max(0, maxCenterX - minCenterX), height: trackHeight)
                    .offset(x: minCenterX, y: sliderCenterY - (trackHeight / 2))

                Circle()
                    .fill(Color.white)
                    .overlay(Circle().stroke(Color.accentColor, lineWidth: 2))
                    .frame(width: thumbSize, height: thumbSize)
                    .offset(x: minCenterX - (thumbSize / 2), y: sliderCenterY - (thumbSize / 2))
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { gestureValue in
                                minDragResetTask?.cancel()
                                let fraction = min(
                                    minFraction(forLocationX: gestureValue.location.x, travelWidth: travelWidth),
                                    maxDisplayFraction
                                )
                                activeMinDragFraction = fraction
                                minValue = min(minValue(for: fraction), maxValue - minimumGap)
                            }
                            .onEnded { gestureValue in
                                let fraction = min(
                                    minFraction(forLocationX: gestureValue.location.x, travelWidth: travelWidth),
                                    maxFraction(for: maxValue)
                                )
                                let snappedValue = min(minValue(for: fraction), maxValue - minimumGap)
                                minValue = snappedValue

                                withAnimation(snapAnimation) {
                                    activeMinDragFraction = self.minFraction(for: snappedValue)
                                }

                                minDragResetTask = Task { @MainActor in
                                    try? await Task.sleep(nanoseconds: 180_000_000)
                                    activeMinDragFraction = nil
                                    minDragResetTask = nil
                                }
                            }
                    )

                Circle()
                    .fill(Color.white)
                    .overlay(Circle().stroke(Color.accentColor, lineWidth: 2))
                    .frame(width: thumbSize, height: thumbSize)
                    .offset(x: maxCenterX - (thumbSize / 2), y: sliderCenterY - (thumbSize / 2))
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { gestureValue in
                                maxDragResetTask?.cancel()
                                let fraction = max(
                                    maxFraction(forLocationX: gestureValue.location.x, travelWidth: travelWidth),
                                    minDisplayFraction
                                )
                                activeMaxDragFraction = fraction
                                maxValue = max(maxValue(for: fraction), minValue + minimumGap)
                            }
                            .onEnded { gestureValue in
                                let fraction = max(
                                    maxFraction(forLocationX: gestureValue.location.x, travelWidth: travelWidth),
                                    minFraction(for: minValue)
                                )
                                let snappedValue = max(maxValue(for: fraction), minValue + minimumGap)
                                maxValue = snappedValue

                                withAnimation(snapAnimation) {
                                    activeMaxDragFraction = self.maxFraction(for: snappedValue)
                                }

                                maxDragResetTask = Task { @MainActor in
                                    try? await Task.sleep(nanoseconds: 180_000_000)
                                    activeMaxDragFraction = nil
                                    maxDragResetTask = nil
                                }
                            }
                    )

                if let valueLabel {
                    Text(valueLabel(minValue))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                        .frame(width: valueLabelWidth, alignment: .center)
                        .offset(x: minCenterX - (valueLabelWidth / 2))

                    Text(valueLabel(maxValue))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                        .frame(width: valueLabelWidth, alignment: .center)
                        .offset(x: maxCenterX - (valueLabelWidth / 2))
                }
            }
        }
        .onDisappear {
            minDragResetTask?.cancel()
            maxDragResetTask?.cancel()
            minDragResetTask = nil
            maxDragResetTask = nil
        }
        .onAppear(perform: enforceMinimumGap)
        .onChange(of: minValue) { _, _ in
            enforceMinimumGap()
        }
        .onChange(of: maxValue) { _, _ in
            enforceMinimumGap()
        }
    }

    private var draggableStepSpan: Int {
        max(1, (bounds.upperBound - bounds.lowerBound) - minimumGap)
    }

    private func minFraction(for value: Int) -> CGFloat {
        let clampedValue = min(max(value, bounds.lowerBound), bounds.upperBound - minimumGap)
        return CGFloat(clampedValue - bounds.lowerBound) / CGFloat(draggableStepSpan)
    }

    private func maxFraction(for value: Int) -> CGFloat {
        let clampedValue = min(max(value, bounds.lowerBound + minimumGap), bounds.upperBound)
        return CGFloat(clampedValue - bounds.lowerBound - minimumGap) / CGFloat(draggableStepSpan)
    }

    private func minXPosition(forFraction fraction: CGFloat, travelWidth: CGFloat) -> CGFloat {
        (thumbSize / 2) + (min(max(fraction, 0), 1) * travelWidth)
    }

    private func maxXPosition(forFraction fraction: CGFloat, travelWidth: CGFloat) -> CGFloat {
        (thumbSize * 1.5) + (min(max(fraction, 0), 1) * travelWidth)
    }

    private func minFraction(forLocationX locationX: CGFloat, travelWidth: CGFloat) -> CGFloat {
        let minX = thumbSize / 2
        let maxX = minX + travelWidth
        let clampedX = min(max(locationX, minX), maxX)
        return (clampedX - minX) / travelWidth
    }

    private func maxFraction(forLocationX locationX: CGFloat, travelWidth: CGFloat) -> CGFloat {
        let minX = thumbSize * 1.5
        let maxX = minX + travelWidth
        let clampedX = min(max(locationX, minX), maxX)
        return (clampedX - minX) / travelWidth
    }

    private func minValue(for fraction: CGFloat) -> Int {
        let rawValue = CGFloat(bounds.lowerBound) + (min(max(fraction, 0), 1) * CGFloat(draggableStepSpan))
        return min(max(Int(round(rawValue)), bounds.lowerBound), bounds.upperBound - minimumGap)
    }

    private func maxValue(for fraction: CGFloat) -> Int {
        let rawValue = CGFloat(bounds.lowerBound + minimumGap) + (min(max(fraction, 0), 1) * CGFloat(draggableStepSpan))
        return min(max(Int(round(rawValue)), bounds.lowerBound + minimumGap), bounds.upperBound)
    }

    private func enforceMinimumGap() {
        guard maxValue - minValue < minimumGap else { return }

        if minValue <= bounds.upperBound - minimumGap {
            maxValue = minValue + minimumGap
        } else {
            minValue = max(bounds.lowerBound, maxValue - minimumGap)
        }
    }
}
