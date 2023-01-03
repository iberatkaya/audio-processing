//
//  AudioProcesser.swift
//  audio-processing
//
//  Created by Ibrahim Berat Kaya on 1/2/23.
//

import Foundation
import AVKit

enum ProcessingError: Error {
    case fileAccessError
}

struct ProcessingSettings {
    init(reverb: Int = 0, delay: Int = 0, delayTimeInMS: Int = 500) {
        self.reverb = reverb
        self.delay = delay
        self.delayTimeInMS = delayTimeInMS
    }
    
    let reverb: Int
    let delay: Int
    let delayTimeInMS: Int
}

class AudioProcessor: NSObject, ObservableObject, AVAudioPlayerDelegate {
    var player: AVAudioPlayer?
    @Published var isPlaying = false
    
    func playFile(_ pathStr: String) throws {
        print("play file " + pathStr)
        let path = URL(filePath: pathStr)
        print(path.path)
        // File might be secure
        _ = path.startAccessingSecurityScopedResource()
        do {
            stopPlayer()
            try AVAudioSession.sharedInstance().setCategory(.playback)
            player = try AVAudioPlayer(contentsOf: path)
            player?.delegate = self
            player?.prepareToPlay()
            player?.play()
        } catch {
            print(error.localizedDescription)
        }
        isPlaying = player?.isPlaying ?? false
    }
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        isPlaying = false
    }
    
    func stopPlayer() {
        if let player, player.isPlaying {
            print("already playing, stop")
            player.stop()
        }
        isPlaying = player?.isPlaying ?? false
    }
    
    func processFile(_ pathStr: String, settings: ProcessingSettings) throws -> URL {
        let path = URL(filePath: pathStr)
        let sourceFile: AVAudioFile
        let format: AVAudioFormat
        do {
            _ = path.startAccessingSecurityScopedResource()
            sourceFile = try AVAudioFile(forReading: path)
            format = sourceFile.processingFormat
        } catch {
            print(error.localizedDescription)
            fatalError(error.localizedDescription)
        }

        let engine = AVAudioEngine()
        let playerNode = AVAudioPlayerNode()
        let reverbNode = AVAudioUnitReverb()
        let delayNode = AVAudioUnitDelay()

        engine.attach(playerNode)
        if settings.reverb > 0 {
            engine.attach(reverbNode)
        }
        if settings.delay > 0 {
            engine.attach(delayNode)
        }

        if settings.reverb > 0 {
            // Set the desired reverb parameters.
            reverbNode.loadFactoryPreset(.mediumHall)
            reverbNode.wetDryMix = Float(settings.reverb)
        }
        if settings.delay > 0 {
            delayNode.delayTime = TimeInterval(Float(settings.delayTimeInMS) / 1000)
            delayNode.wetDryMix = Float(settings.delay)
        }

        if settings.reverb > 0 {
            // Connect the nodes.
            engine.connect(playerNode, to: reverbNode, format: format)
            if settings.delay > 0 {
                engine.connect(reverbNode, to: delayNode, format: format)
                engine.connect(delayNode, to: engine.mainMixerNode, format: format)
            } else {
                engine.connect(reverbNode, to: engine.mainMixerNode, format: format)
            }
        } else {
            if settings.delay > 0 {
                engine.connect(playerNode, to: delayNode, format: format)
                engine.connect(delayNode, to: engine.mainMixerNode, format: format)
            } else {
                engine.connect(playerNode, to: engine.mainMixerNode, format: format)
            }
        }

        // Schedule the source file.
        playerNode.scheduleFile(sourceFile, at: nil)
        
        do {
            // The maximum number of frames the engine renders in any single render call.
            let maxFrames: AVAudioFrameCount = 4096
            try engine.enableManualRenderingMode(.offline, format: format,
                                                 maximumFrameCount: maxFrames)
        } catch {
            fatalError("Enabling manual rendering mode failed: \(error).")
        }
        
        do {
            try engine.start()
            playerNode.play()
        } catch {
            fatalError("Unable to start audio engine: \(error).")
        }
        
        // The output buffer to which the engine renders the processed data.
        let buffer = AVAudioPCMBuffer(pcmFormat: engine.manualRenderingFormat,
                                      frameCapacity: engine.manualRenderingMaximumFrameCount)!

        var outputFile: AVAudioFile!
        do {
            let documentsURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            let outputURL = documentsURL.appendingPathComponent("audio.m4a")
            outputFile = try AVAudioFile(forWriting: outputURL, settings: sourceFile.fileFormat.settings)
        } catch {
            fatalError("Unable to open output audio file: \(error).")
        }
        
        while engine.manualRenderingSampleTime < sourceFile.length {
            do {
                let frameCount = sourceFile.length - engine.manualRenderingSampleTime
                let framesToRender = min(AVAudioFrameCount(frameCount), buffer.frameCapacity)
                
                let status = try engine.renderOffline(framesToRender, to: buffer)
                switch status {
                    
                case .success:
                    // The data rendered successfully. Write it to the output file.
                    try outputFile.write(from: buffer)
                    
                case .insufficientDataFromInputNode:
                    // Applicable only when using the input node as one of the sources.
                    break
                    
                case .cannotDoInCurrentContext:
                    // The engine couldn't render in the current render call.
                    // Retry in the next iteration.
                    break
                    
                case .error:
                    // An error occurred while rendering the audio.
                    fatalError("The manual rendering failed.")
                }
            } catch {
                fatalError("The manual rendering failed: \(error).")
            }
        }

        // Stop the player node and engine.
        playerNode.stop()
        engine.stop()
        
        return outputFile.url
    }

}
