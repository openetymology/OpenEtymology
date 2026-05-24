//
//  SpeechManager.swift
//  wordety
//

import Foundation
import AVFoundation

class SpeechManager {
    static let shared = SpeechManager()
    private let synthesizer = AVSpeechSynthesizer()
    
    private init() {}
    
    func speak(text: String, isUS: Bool = true) {
        // 如果正在说话，先停止
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        
        let utterance = AVSpeechUtterance(string: text)
        
        // 查找特定口音和性别的声音
        let language = isUS ? "en-US" : "en-GB"
        let voices = AVSpeechSynthesisVoice.speechVoices()
        
        // 尝试寻找匹配的声音
        // US 偏向男声 (如 Alex)，UK 偏向女声 (如 Serena/Samantha)
        let preferredVoice = voices.first { voice in
            if isUS {
                return voice.language == "en-US" && voice.gender == .male
            } else {
                return voice.language == "en-GB" && voice.gender == .female
            }
        } ?? AVSpeechSynthesisVoice(language: language)
        
        utterance.voice = preferredVoice
        utterance.rate = 0.55 // 语速调快一点（0.5 是默认，0.55 稍微快一点）
        utterance.pitchMultiplier = 1.0 // 音调
        utterance.volume = 1.0 // 音量
        
        synthesizer.speak(utterance)
    }
}
