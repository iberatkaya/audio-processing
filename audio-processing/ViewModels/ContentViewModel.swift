//
//  ContentViewModal.swift
//  audio-processing
//
//  Created by Ibrahim Berat Kaya on 1/2/23.
//

import Foundation
import SwiftUI

class ContentViewModel: ObservableObject, AudioProcessorDelegate {
    @Published var sourceFilePath: String?
    @Published var outputFilePath: String?
    @Published var showDocumentPicker = false
    @Published var reverb = 0.0
    @Published var delay = 0.0
    @Published var delayTimeInMS = 0.0
    @Published var distortionAmount = 0.0
    @Published var distortionGain = -6.0
    @Published var processingStatus = ProcessingStatus.idle
    @Published var isPlaying = false
    
    
    init() {
        audioProcessor.delegate = self
    }
    
    private let audioProcessor = AudioProcessor()
    
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
        isPlaying = false
        processingStatus = .processing
        DispatchQueue.global(qos: .userInitiated).async {
            let outputFile = try? self.audioProcessor.processFile(sourceFilePath, settings: ProcessingSettings(reverb: Int(self.reverb), delay: Int(self.delay), delayTimeInMS: Int(self.delayTimeInMS), distortionAmount: Int(self.distortionAmount), distortionGain: Int(self.distortionGain)))
            DispatchQueue.main.async {
                self.outputFilePath = outputFile?.path
                self.processingStatus = .done
            }
        }
    }
}
