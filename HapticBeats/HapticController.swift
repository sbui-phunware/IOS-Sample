//
//  HapticController.swift
//  HapticBeats
//
//  Created by Si Beats on 2017-05-28.
//  Copyright © 2018 Si Beats. All rights reserved.
//

import UIKit
import AudioToolbox

class HapticController {
    static let shared = HapticController()
    private var feedbackGenerator = UIImpactFeedbackGenerator(style: .heavy)
    private var lightFeedbackGenerator = UIImpactFeedbackGenerator(style: .light)
    
    func prepare() {
        feedbackGenerator.prepare()
        lightFeedbackGenerator.prepare()
    }
    
    func playHapticBeat(hard: Bool) {
        let feedbackSupportLevel = UIDevice.current.value(forKey: "_feedbackSupportLevel") as! Int
        switch feedbackSupportLevel {
        case 2:
            // New Haptic Engine (iPhone 7 and up)
            if hard {
                feedbackGenerator.impactOccurred()
            } else {
                lightFeedbackGenerator.impactOccurred()
            }
        case 1:
            // Original Haptic Engine (iPhone 6s)
            AudioServicesPlaySystemSound(hard ? 1520 : 1519)
        default:
            // No Haptic Engine
            AudioServicesPlaySystemSoundWithVibration(4095, nil, generateClassicVibrationDictionary(with: hard ? 2 : 1))
        }
    }
    
    private func generateClassicVibrationDictionary(with intensity: Int) -> [String: Any] {
        return [
            "VibePattern": [true, 30],
            "Intensity": intensity
        ]
    }
}
