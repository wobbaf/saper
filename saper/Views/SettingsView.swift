import SwiftUI

/// Settings screen.
struct SettingsView: View {
    @ObservedObject var gameState: GameState
    @Environment(\.dismiss) private var dismiss
    @State private var showResetSaveConfirmation = false

    // Developer mode
    @AppStorage("devModeEnabled") private var devModeEnabled = false
    @State private var devTapCount = 0
    @State private var devTapResetTask: Task<Void, Never>? = nil

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
                if GamePersistence.hasSave() {
                    Section("Game") {
                        Button(role: .destructive) {
                            showResetSaveConfirmation = true
                        } label: {
                            Label("Reset Saved Game", systemImage: "trash")
                        }
                    }
                }

                Section {
                    HStack {
                        Text("Version")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("1.0")
                            .font(.system(.body, design: .monospaced))
                            .foregroundColor(.secondary)
                            .onTapGesture {
                                devTapResetTask?.cancel()
                                devTapCount += 1
                                if devTapCount >= 7 {
                                    devTapCount = 0
                                    devModeEnabled.toggle()
                                } else {
                                    devTapResetTask = Task {
                                        try? await Task.sleep(nanoseconds: 2_000_000_000)
                                        devTapCount = 0
                                    }
                                }
                            }
                    }
                }

                if devModeEnabled {
                    Section {
                        HStack {
                            Image(systemName: "hammer.fill")
                                .foregroundColor(.orange)
                            Text("Developer Mode")
                                .foregroundColor(.orange)
                                .font(.system(size: 13, weight: .semibold))
                            Spacer()
                            Toggle("", isOn: $devModeEnabled)
                                .labelsHidden()
                        }
                        Button {
                            gameState.profile.gems += 100
                        } label: {
                            Label("+100 gems", systemImage: "diamond.fill")
                        }
                        Button {
                            gameState.profile.gems += 1000
                        } label: {
                            Label("+1000 gems", systemImage: "diamond.fill")
                        }
                        Button {
                            gameState.profile.xp += gameState.profile.xpForNextLevel - gameState.profile.xp
                        } label: {
                            Label("Force level up", systemImage: "arrow.up.circle.fill")
                        }
                    } header: {
                        Text("Developer")
                    } footer: {
                        Text("Tap version number 7 times to toggle this section.")
                    }
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .alert("Reset Saved Game?", isPresented: $showResetSaveConfirmation) {
                Button("Reset", role: .destructive) { GamePersistence.clearSave() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Your saved board will be permanently deleted.")
            }
        }
    }
}
