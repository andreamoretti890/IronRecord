import Foundation

struct WorkoutSessionTimerState {
    let elapsedText: String
    let restText: String
    let isRestActive: Bool
    let activeRestIdentifier: WorkoutRestIdentifier?

    static func make(for session: WorkoutSession, now: Date) -> WorkoutSessionTimerState {
        WorkoutSessionTimerState(
            elapsedText: formatElapsedTime(session.elapsedDuration(at: now)),
            restText: formatClock(seconds: session.activeRestRemainingSeconds(at: now) ?? 0),
            isRestActive: (session.activeRestRemainingSeconds(at: now) ?? 0) > 0,
            activeRestIdentifier: session.activeRestIdentifier
        )
    }

    static func formatClock(seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        let secondsRemainder = seconds % 60

        if hours > 0 {
            return String(format: "%01d:%02d:%02d", hours, minutes, secondsRemainder)
        }

        return String(format: "%02d:%02d", minutes, secondsRemainder)
    }

    static func formatElapsedTime(_ duration: TimeInterval) -> String {
        formatClock(seconds: max(Int(duration.rounded(.down)), 0))
    }
}

extension WorkoutSession {
    func elapsedDuration(at date: Date) -> TimeInterval {
        let endDate = completedAt ?? pausedAt ?? date
        return max(endDate.timeIntervalSince(startedAt) - accumulatedPausedDuration, 0)
    }
}
