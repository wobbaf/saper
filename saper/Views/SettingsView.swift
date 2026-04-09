import SwiftUI

/// Settings screen.
struct SettingsView: View {
    @ObservedObject var gameState: GameState
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            List {
                Section("Audio") {
                    Toggle("Sound Effects", isOn: $gameState.profile.soundEnabled)
                    if gameState.profile.soundEnabled {
                        HStack {
                            Text("SFX Volume")
                            Slider(value: $gameState.profile.sfxVolume, in: 0...1)
                        }
                        HStack {
                            Text("Ambience Volume")
                            Slider(value: $gameState.profile.ambienceVolume, in: 0...1)
                        }
                    }
                }

                Section("Haptics") {
                    Toggle("Haptic Feedback", isOn: $gameState.profile.hapticsEnabled)
                }

                Section("Gameplay") {
                    Toggle("Auto-Flag Remaining Mines", isOn: $gameState.profile.autoFlagEnabled)
                }

                Section("Appearance") {
                    Picker("Theme", selection: $gameState.profile.appearanceMode) {
                        Text("System").tag(0)
                        Text("Light").tag(1)
                        Text("Dark").tag(2)
                    }
                    .pickerStyle(.segmented)
                }

                Section("World Seed") {
                    HStack {
                        Text("Seed")
                        Spacer()
                        Text("\(gameState.boardManager.globalSeed)")
                            .font(.system(.body, design: .monospaced))
                            .foregroundColor(.secondary)
                    }
                }

                Section("High Scores") {
                    HStack {
                        Text("Endless")
                        Spacer()
                        Text("\(gameState.profile.highScoreEndless) sectors")
                            .foregroundColor(.secondary)
                    }
                    HStack {
                        Text("Hardcore")
                        Spacer()
                        Text("\(gameState.profile.highScoreHardcore) sectors")
                            .foregroundColor(.secondary)
                    }
                    HStack {
                        Text("Timed")
                        Spacer()
                        Text("\(gameState.profile.highScoreTimed) sectors")
                            .foregroundColor(.secondary)
                    }
                }

                Section("Stats") {
                    HStack {
                        Text("Total Sectors Solved")
                        Spacer()
                        Text("\(gameState.profile.totalSectorsSolved)")
                            .foregroundColor(.secondary)
                    }
                    HStack {
                        Text("Total Gems Collected")
                        Spacer()
                        Text("\(gameState.profile.totalGemsCollected)")
                            .foregroundColor(.secondary)
                    }
                    HStack {
                        Text("Level")
                        Spacer()
                        Text("\(gameState.profile.level)")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
