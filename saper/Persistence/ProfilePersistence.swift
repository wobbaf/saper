import Foundation

/// Manages saving and loading player profile and settings via UserDefaults.
struct ProfilePersistence {
    private static let profileKey = "playerProfile"
    private static let seedKey = "worldSeed"

    static func loadProfile() -> PlayerProfile {
        guard let data = UserDefaults.standard.data(forKey: profileKey),
              let profile = try? JSONDecoder().decode(PlayerProfile.self, from: data) else {
            return PlayerProfile()
        }
        return profile
    }

    static func saveProfile(_ profile: PlayerProfile) {
        if let data = try? JSONEncoder().encode(profile) {
            UserDefaults.standard.set(data, forKey: profileKey)
        }
    }

    static func loadOrCreateSeed() -> UInt64 {
        if let seedValue = UserDefaults.standard.object(forKey: seedKey) as? UInt64 {
            return seedValue
        }
        // UserDefaults doesn't directly support UInt64, use Int64 bit pattern
        if UserDefaults.standard.object(forKey: seedKey) != nil {
            let stored = UserDefaults.standard.integer(forKey: seedKey)
            return UInt64(bitPattern: Int64(stored))
        }
        let newSeed = SeededRandom.newGlobalSeed()
        saveSeed(newSeed)
        return newSeed
    }

    static func saveSeed(_ seed: UInt64) {
        UserDefaults.standard.set(Int64(bitPattern: seed), forKey: seedKey)
    }
}
