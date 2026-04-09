import CoreHaptics

/// Predefined haptic patterns for game events.
enum HapticPattern {
    case tileReveal(number: Int)
    case floodFillTap
    case flagPlaced
    case flagRemoved
    case mineHit
    case sectorSolved
    case gemCollected
    case levelUp
    case boosterRevealOne
    case boosterSolveSector
    case chordReveal
    case lockedSectorTap

    func buildPattern() throws -> CHHapticPattern {
        switch self {
        case .tileReveal(let number):
            // Intensity scales with tile number
            let intensity = Float(max(0.2, min(0.3 + Double(number) * 0.08, 0.9)))
            return try CHHapticPattern(events: [
                CHHapticEvent(
                    eventType: .hapticTransient,
                    parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.8)
                    ],
                    relativeTime: 0
                )
            ], parameters: [])

        case .floodFillTap:
            return try CHHapticPattern(events: [
                CHHapticEvent(
                    eventType: .hapticTransient,
                    parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.15),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.5)
                    ],
                    relativeTime: 0
                )
            ], parameters: [])

        case .flagPlaced:
            // Double-tap pattern
            return try CHHapticPattern(events: [
                CHHapticEvent(
                    eventType: .hapticTransient,
                    parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.6),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.5)
                    ],
                    relativeTime: 0
                ),
                CHHapticEvent(
                    eventType: .hapticTransient,
                    parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.7),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.5)
                    ],
                    relativeTime: 0.08
                )
            ], parameters: [])

        case .flagRemoved:
            return try CHHapticPattern(events: [
                CHHapticEvent(
                    eventType: .hapticTransient,
                    parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.3),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.4)
                    ],
                    relativeTime: 0
                )
            ], parameters: [])

        case .mineHit:
            // Strong thud followed by low rumble
            return try CHHapticPattern(events: [
                CHHapticEvent(
                    eventType: .hapticTransient,
                    parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.3)
                    ],
                    relativeTime: 0
                ),
                CHHapticEvent(
                    eventType: .hapticContinuous,
                    parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.7),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.1)
                    ],
                    relativeTime: 0.05,
                    duration: 0.8
                )
            ], parameterCurves: [
                CHHapticParameterCurve(
                    parameterID: .hapticIntensityControl,
                    controlPoints: [
                        CHHapticParameterCurve.ControlPoint(relativeTime: 0.05, value: 0.7),
                        CHHapticParameterCurve.ControlPoint(relativeTime: 0.85, value: 0.0)
                    ],
                    relativeTime: 0
                )
            ])

        case .sectorSolved:
            // Ascending rhythm: 3 taps getting stronger, then final pulse
            return try CHHapticPattern(events: [
                CHHapticEvent(
                    eventType: .hapticTransient,
                    parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.4),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.5)
                    ],
                    relativeTime: 0
                ),
                CHHapticEvent(
                    eventType: .hapticTransient,
                    parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.6),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.6)
                    ],
                    relativeTime: 0.1
                ),
                CHHapticEvent(
                    eventType: .hapticTransient,
                    parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.8),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.7)
                    ],
                    relativeTime: 0.2
                ),
                CHHapticEvent(
                    eventType: .hapticContinuous,
                    parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.8)
                    ],
                    relativeTime: 0.35,
                    duration: 0.25
                )
            ], parameters: [])

        case .gemCollected:
            // Two quick light taps
            return try CHHapticPattern(events: [
                CHHapticEvent(
                    eventType: .hapticTransient,
                    parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.5),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 1.0)
                    ],
                    relativeTime: 0
                ),
                CHHapticEvent(
                    eventType: .hapticTransient,
                    parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.6),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 1.0)
                    ],
                    relativeTime: 0.06
                )
            ], parameters: [])

        case .levelUp:
            // Build-up of 4 rapid taps then long strong vibration
            return try CHHapticPattern(events: [
                CHHapticEvent(eventType: .hapticTransient,
                    parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.3),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.5)
                    ], relativeTime: 0),
                CHHapticEvent(eventType: .hapticTransient,
                    parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.5),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.6)
                    ], relativeTime: 0.08),
                CHHapticEvent(eventType: .hapticTransient,
                    parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.7),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.7)
                    ], relativeTime: 0.16),
                CHHapticEvent(eventType: .hapticTransient,
                    parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.9),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.8)
                    ], relativeTime: 0.24),
                CHHapticEvent(eventType: .hapticContinuous,
                    parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.7)
                    ], relativeTime: 0.35, duration: 0.5)
            ], parameters: [])

        case .boosterRevealOne:
            return try CHHapticPattern(events: [
                CHHapticEvent(eventType: .hapticContinuous,
                    parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.5),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.6)
                    ], relativeTime: 0, duration: 0.3)
            ], parameterCurves: [
                CHHapticParameterCurve(
                    parameterID: .hapticIntensityControl,
                    controlPoints: [
                        CHHapticParameterCurve.ControlPoint(relativeTime: 0, value: 0.5),
                        CHHapticParameterCurve.ControlPoint(relativeTime: 0.3, value: 0.0)
                    ],
                    relativeTime: 0
                )
            ])

        case .boosterSolveSector:
            // Sweeping pattern: 6 taps increasing in intensity
            var events: [CHHapticEvent] = []
            for i in 0..<6 {
                events.append(CHHapticEvent(
                    eventType: .hapticTransient,
                    parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: Float(0.3 + Double(i) * 0.12)),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: Float(0.4 + Double(i) * 0.1))
                    ],
                    relativeTime: Double(i) * 0.08
                ))
            }
            return try CHHapticPattern(events: events, parameters: [])

        case .chordReveal:
            return try CHHapticPattern(events: [
                CHHapticEvent(eventType: .hapticTransient,
                    parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.3),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.6)
                    ], relativeTime: 0),
                CHHapticEvent(eventType: .hapticTransient,
                    parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.2),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.5)
                    ], relativeTime: 0.04),
                CHHapticEvent(eventType: .hapticTransient,
                    parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.15),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.4)
                    ], relativeTime: 0.08)
            ], parameters: [])

        case .lockedSectorTap:
            // Short sharp "blocked" double buzz
            return try CHHapticPattern(events: [
                CHHapticEvent(eventType: .hapticTransient,
                    parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.7),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.9)
                    ], relativeTime: 0),
                CHHapticEvent(eventType: .hapticTransient,
                    parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.8),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.9)
                    ], relativeTime: 0.06)
            ], parameters: [])
        }
    }
}
