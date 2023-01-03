//
//  ContentViewModal.swift
//  audio-processing
//
//  Created by Ibrahim Berat Kaya on 1/2/23.
//

import Foundation
import SwiftUI

class ContentViewModel: ObservableObject, AudioProcessorDelegate {
    @Published var sourceFilePath: String? {
        didSet {
            if let sourceFilePath {
                fileSampleRate = audioProcessor.getFileSampleRate(sourceFilePath)
            }
        }
    }
    @Published var outputFilePath: String?
    @Published var showDocumentPicker = false
    
    @Published var reverb = 0.0
    
    @Published var delay = 0.0
    @Published var delayTimeInMS = 0.0
    @Published var delayLowPassCutoff = 15000.0
    @Published var delayFeedback = 50.0
    
    @Published var distortionAmount = 0.0
    @Published var distortionGain = -6.0
    
    @Published var pitchAmount = 0.0
    @Published var pitchOverlap = 8.0
    @Published var pitchRate = 1.0
    
    @Published var playRate = 1.0
    
    @Published var fileSampleRate: Double?
    
    @Published var processingStatus = ProcessingStatus.idle
    @Published var isPlaying = false
    
    
    init() {
        audioProcessor.delegate = self
    }
    
    private let audioProcessor = AudioProcessor()
    
    func resetReverb() {
        reverb = 0
    }
    
    func resetDelay() {
        delay = 0.0
        delayTimeInMS = 0.0
        delayLowPassCutoff = 15000.0
        delayFeedback = 50.0
    }
    
    func resetDistortion() {
        distortionAmount = 0.0
        distortionGain = -6.0
    }
    
    func resetPitch() {
        pitchAmount = 0.0
        pitchOverlap = 8.0
        pitchRate = 1.0
    }
    
    func resetPlayRate() {
        playRate = 1
    }
    
    func didFinishPlaying() {
        isPlaying = false
    }
    
    func stopPlayer() {
        audioProcessor.stopPlayer()
        isPlaying = false
    }
    
    func playFile(_ filePath: String) {
        try? audioProcessor.playFile(filePath)
        isPlaying = true
    }
    
    func processFile() {
        guard let sourceFilePath else {
            return
        }
        stopPlayer()
        processingStatus = .processing
        DispatchQueue.global(qos: .userInitiated).async { [self] in
            let settings = ProcessingSettings(
                reverb: Int(reverb),
                delay: Int(delay),
                delayTimeInMS: Int(delayTimeInMS),
                delayFeedback: Int(delayFeedback),
                delayLowPassCutoff: Int(delayLowPassCutoff),
                distortionAmount: Int(distortionAmount),
                distortionGain: Int(distortionGain),
                pitchAmount: Int(pitchAmount),
                pitchOverlap: Float(pitchOverlap),
                pitchRate: Float(pitchRate),
                playRate: Float(playRate)
            )
            let outputFile = try? audioProcessor.processFile(sourceFilePath, settings: settings)
            DispatchQueue.main.async {
                self.outputFilePath = outputFile?.path
                self.processingStatus = .done
            }
        }
    }
}
