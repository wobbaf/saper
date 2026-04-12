import SwiftUI

/// Settings screen.
struct SettingsView: View {
    @ObservedObject var gameState: GameState
    @Environment(\.dismiss) private var dismiss
    @State private var showResetSaveConfirmation = false
    @State private var showSkinPicker = false

    private var theme: SkinUITheme { gameState.profile.currentSkin.uiTheme }

    // Developer mode — only available in Debug and TestFlight builds
    @AppStorage("devModeEnabled") private var devModeEnabled = false
    @State private var devTapCount = 0
    @State private var devTapResetTask: Task<Void, Never>? = nil

    private var isDevBuild: Bool {
        #if DEBUG
        return true
        #else
        return Bundle.main.appStoreReceiptURL?.lastPathComponent == "sandboxReceipt"
        #endif
    }

    var body: some View {
        NavigationView {
            List {
                Section("Appearance") {
                    Button {
                        showSkinPicker = true
                    } label: {
                        HStack {
                            Label("Skins", systemImage: "paintbrush.fill")
                            Spacer()
                            Text(gameState.profile.currentSkin.displayName)
                                .foregroundColor(.secondary)
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }
                    }
                    .foregroundColor(.primary)
                }

                Section("Audio") {
                    HStack(spacing: 12) {
                        Label("Sound Effects", systemImage: "speaker.wave.2.fill")
                            .frame(width: 140, alignment: .leading)
                        Slider(value: $gameState.profile.sfxVolume, in: 0...1)
                            .onChange(of: gameState.profile.sfxVolume) { vol in
                                AudioManager.shared.sfxVolume = vol
                            }
                    }
                    HStack(spacing: 12) {
                        Label("Music", systemImage: "music.note")
                            .frame(width: 140, alignment: .leading)
                        Slider(value: $gameState.profile.ambienceVolume, in: 0...1)
                            .onChange(of: gameState.profile.ambienceVolume) { vol in
                                AudioManager.shared.ambienceVolume = vol
                                MusicEngine.shared.outputVolume = vol * 0.35
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

                Section("Legal") {
                    Link(destination: URL(string: "https://polar-cylinder-6aa.notion.site/Privacy-policy-2568f5d0356f80579df9fe35977c2792")!) {
                        Label("Privacy Policy", systemImage: "hand.raised.fill")
                    }
                    Link(destination: URL(string: "https://polar-cylinder-6aa.notion.site/Terms-and-conditions-2568f5d0356f80459de9ecaf33c081fe")!) {
                        Label("Terms of Service", systemImage: "doc.text.fill")
                    }
                }

                Section {
                    HStack {
                        Text("Version")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(isDevBuild && devModeEnabled ? "1.0 🔧" : (isDevBuild && devTapCount > 0 ? "1.0 (\(devTapCount))" : "1.0"))
                            .font(.system(.body, design: .monospaced))
                            .foregroundColor(.secondary)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        guard isDevBuild else { return }
                        devTapResetTask?.cancel()
                        devTapCount += 1
                        if devTapCount >= 7 {
                            devTapCount = 0
                            devModeEnabled.toggle()
                        } else {
                            devTapResetTask = Task {
                                do {
                                    try await Task.sleep(nanoseconds: 3_000_000_000)
                                    await MainActor.run { devTapCount = 0 }
                                } catch is CancellationError {
                                    // cancelled by next tap — do nothing
                                } catch {}
                            }
                        }
                    }
                }

                if isDevBuild && devModeEnabled {
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
            .navigationBarColorScheme(theme.isDark ? .dark : .light)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(theme.accentColor)
                }
            }
            .alert("Reset Saved Game?", isPresented: $showResetSaveConfirmation) {
                Button("Reset", role: .destructive) { GamePersistence.clearSave() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Your saved board will be permanently deleted.")
            }
            .sheet(isPresented: $showSkinPicker) {
                SkinPickerView(gameState: gameState)
            }
        }
    }
}
