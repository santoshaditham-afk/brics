import SwiftUI

struct ScoreboardView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AuthManager.self) private var authManager
    @State private var entries: [LeaderboardEntry] = []
    @State private var isLoading = true
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let errorMessage {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                        .padding()
                } else if entries.isEmpty {
                    Text("No scores yet. Play a game!")
                        .foregroundStyle(.secondary)
                        .padding()
                } else {
                    List(entries) { entry in
                        HStack(spacing: 12) {
                            Text("#\(entry.rank)")
                                .font(.headline.monospacedDigit())
                                .foregroundStyle(.secondary)
                                .frame(width: 32, alignment: .leading)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(entry.username)
                                    .font(.headline)
                                Text("Level \(entry.level_reached) · \(Int(entry.duration_secs))s")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            Text("\(entry.score)")
                                .font(.title3.bold().monospacedDigit())
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle("Top Scores")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .task {
            guard let token = authManager.token else { return }
            do {
                entries = try await APIClient().leaderboard(token: token)
            } catch {
                errorMessage = "Could not load scores."
            }
            isLoading = false
        }
    }
}
