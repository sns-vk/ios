import Foundation
import Observation

struct AnonymousMatchProfile: Hashable {
    var firstName: String
    var lastName: String
    var pronouns: PronounOption
    var gender: GenderIdentity
    var sexuality: SexualityOption

    var name: String {
        "\(firstName) \(lastName)"
    }

    static let mock = AnonymousMatchProfile(
        firstName: "Hannah",
        lastName: "Miller",
        pronouns: .theyThem,
        gender: .female,
        sexuality: .straight
    )
}

@MainActor
@Observable
final class HomeViewModel {
    var isEnrolledInBatch = false
    var hasMatchThisWeek = false
    var showBatchInfoPopup = false
    var showEnrollConfirmation = false
    var showMatchInfoSheet = false
    var sliderResetTrigger = 0
    var secondsUntilMatchRelease = 5

    let matchProfile = AnonymousMatchProfile.mock

    private var matchTimerTask: Task<Void, Never>?

    init() {
        if ProcessInfo.processInfo.arguments.contains("-snsUITestHasMatch") {
            isEnrolledInBatch = true
            hasMatchThisWeek = true
        }
    }

    func cancelEnrollment() {
        sliderResetTrigger += 1
    }

    func confirmEnrollment() {
        isEnrolledInBatch = true
        hasMatchThisWeek = false
        beginMatchSimulation()
    }

    func advanceToNextBatchAfterMatch() {
        isEnrolledInBatch = false
        sliderResetTrigger += 1
    }

    func cancelMatchSimulation() {
        matchTimerTask?.cancel()
        matchTimerTask = nil
    }

    private func beginMatchSimulation() {
        cancelMatchSimulation()
        secondsUntilMatchRelease = 5

        matchTimerTask = Task { [weak self] in
            guard let self else { return }

            while self.secondsUntilMatchRelease > 0 {
                try? await Task.sleep(for: .seconds(1))
                guard !Task.isCancelled else { return }
                await MainActor.run {
                    self.secondsUntilMatchRelease -= 1
                }
            }

            guard !Task.isCancelled else { return }
            await MainActor.run {
                self.hasMatchThisWeek = true
            }
        }
    }
}
