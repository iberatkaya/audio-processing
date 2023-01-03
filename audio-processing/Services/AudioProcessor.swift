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
    init(reverb: Int = 0, delay: Int = 0, delayTimeInMS: Int = 500, distortionAmount: Int = 0, distortionGain: Int = 0) {
        self.reverb = reverb
        self.delay = delay
        self.delayTimeInMS = delayTimeInMS
        self.distortionGain = distortionGain
        self.distortionAmount = distortionAmount
    }
    
    let reverb: Int
    let delay: Int
    let delayTimeInMS: Int
    let distortionAmount: Int
    let distortionGain: Int
}

protocol AudioProcessorDelegate {
    func didFinishPlaying()
}

class AudioProcessor: NSObject, AVAudioPlayerDelegate {
    var player: AVAudioPlayer?
    var delegate: AudioProcessorDelegate?
    
    func playFile(_ pathStr: String) throws {
        let path = URL(filePath: pathStr)
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
    }
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        delegate?.didFinishPlaying()
    }
    
    func stopPlayer() {
        if let player, player.isPlaying {
            print("already playing, stop")
            player.stop()
        }
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
        let distortionNode = AVAudioUnitDistortion()

        engine.attach(playerNode)
        
        engine.attach(reverbNode)
        reverbNode.loadFactoryPreset(.mediumHall)
        reverbNode.wetDryMix = Float(settings.reverb)
        
        engine.attach(delayNode)
        delayNode.delayTime = TimeInterval(Float(settings.delayTimeInMS) / 1000)
        delayNode.wetDryMix = Float(settings.delay)
        
        engine.attach(distortionNode)
        distortionNode.wetDryMix = Float(settings.distortionAmount)
        distortionNode.preGain = Float(settings.distortionGain)
        
        engine.connect(playerNode, to: reverbNode, format: format)
        engine.connect(reverbNode, to: delayNode, format: format)
        engine.connect(delayNode, to: distortionNode, format: format)
        engine.connect(distortionNode, to: engine.mainMixerNode, format: format)

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
