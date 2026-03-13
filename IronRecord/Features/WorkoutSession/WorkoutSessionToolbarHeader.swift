import SwiftUI

struct WorkoutSessionToolbarHeader: View {
    let title: String
    let session: WorkoutSession

    var body: some View {
        VStack(spacing: 3) {
            TimelineView(.periodic(from: .now, by: 1)) { context in
                Text(
                    WorkoutSessionTimerState.formatElapsedTime(
                        session.elapsedDuration(at: context.date)
                    )
                )
                .font(.headline)
                .monospacedDigit()
                .foregroundStyle(.primary)
            }

            Text(title)
                .font(.subheadline)
                .bold()
                .lineLimit(1)
                .truncationMode(.tail)
        }
    }
}
