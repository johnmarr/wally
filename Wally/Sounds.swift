//
//  Sounds.swift
//  Wally
//
//  Created by John Marr on 1/14/21.
//

import Foundation
import AVFoundation
import UIKit

struct Sounds {
    
    enum SoundFile: String {
        case shutter = "shutter"
        case success = "success"
        case reset = "reset"
    }
    
    var soundEffect: AVAudioPlayer?
    
    mutating func playSound(file: SoundFile) {
        
        guard let path = Bundle.main.path(forResource: file.rawValue, ofType:"wav") else {
            print ("No \(file.rawValue) sound.")
            return
        }
        
        let url = URL(fileURLWithPath: path)

        do {
            soundEffect = try AVAudioPlayer(contentsOf: url)
            soundEffect?.play()
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
        } catch {
            print ("Error playing camera sound: \(error)")
        }
    }
}
