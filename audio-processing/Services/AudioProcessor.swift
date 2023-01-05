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
    init(reverb: Int = 0, delay: Int = 0, delayTimeInMS: Int = 0, delayFeedback: Int = 50, delayLowPassCutoff: Int = 15000, distortionAmount: Int = 0, distortionGain: Int = -6, pitchAmount: Int = 0, pitchOverlap: Float = 8.0, pitchRate: Float =  1.0, playRate: Float = 1.0) {
        self.reverb = reverb
        self.delay = delay
        self.delayTimeInMS = delayTimeInMS
        self.delayFeedback = delayFeedback
        self.delayLowPassCutoff = delayLowPassCutoff
        self.distortionGain = distortionGain
        self.distortionAmount = distortionAmount
        self.pitchRate = pitchRate
        self.pitchAmount = pitchAmount
        self.pitchOverlap = pitchOverlap
        self.playRate = playRate
    }
    
    /// You specify the blend as a percentage. The range is 0% through 100%, where 0% represents all dry.
    let reverb: Int
    
    /// You specify the blend as a percentage. The default value is 100%. The valid range of values is 0% through 100%, where 0% represents all dry.
    let delay: Int
    
    /// The amount of the output signal that feeds back into the delay line. You specify the feedback as a percentage. The default value is 50%. The valid range of values is -100% to 100%.
    let delayFeedback: Int
    
    /// You specify the delay in seconds. The default value is 1. The valid range of values is 0 to 2 seconds.
    let delayTimeInMS: Int
    
    /// The cutoff frequency above which high frequency content rolls off, in hertz.
    /// The default value is 15000 Hz. The valid range of values is 10 Hz through (sampleRate/2).
    let delayLowPassCutoff: Int
    
    /// You specify the blend as a percentage. The default value is 50%. The valid range is 0% through 100%, where 0 represents all dry.
    let distortionAmount: Int
    
    /// The gain that the audio unit applies to the signal before distortion, in decibels.
    /// The default value is -6 dB. The valid range of values is -80 dB to 20 dB.
    let distortionGain: Int
    
    /// The audio unit measures the pitch in cents, a logarithmic value you use for measuring musical intervals. One octave is equal to 1200 cents. One musical semitone is equal to 100 cents.
    /// The default value is 0.0. The range of values is -2400 to 2400.
    let pitchAmount: Int

    /// A higher value results in fewer artifacts in the output signal. The default value is 8.0. The range of values is 3.0 to 32.0.
    let pitchOverlap: Float
    
    /// The default value is 1.0. The range of supported values is 1/32 to 32.0.
    let pitchRate: Float
    
    /// The audio playback rate. The default value is 1.0. The range of values is 0.25 to 4.0.
    let playRate: Float
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
    
    func getFileSampleRate(_ pathStr: String) -> Double {
        let path = URL(filePath: pathStr)
        let sourceFile: AVAudioFile
        do {
            _ = path.startAccessingSecurityScopedResource()
            sourceFile = try AVAudioFile(forReading: path)
            
            return sourceFile.fileFormat.sampleRate
        } catch {
            print(error.localizedDescription)
            fatalError(error.localizedDescription)
        }
    }
    
    func processFile(_ pathStr: String, settings: ProcessingSettings) throws -> URL {
        print(settings)
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
        let pitchNode = AVAudioUnitTimePitch()
        let playRateNode = AVAudioUnitVarispeed()

        engine.attach(playerNode)
        
        engine.attach(reverbNode)
        reverbNode.loadFactoryPreset(.mediumHall)
        reverbNode.wetDryMix = Float(settings.reverb)
        
        engine.attach(delayNode)
        delayNode.delayTime = TimeInterval(Float(settings.delayTimeInMS) / 1000)
        delayNode.wetDryMix = Float(settings.delay)
        delayNode.feedback = Float(settings.delayFeedback) / 100
        delayNode.lowPassCutoff = Float(settings.delayLowPassCutoff)
        
        engine.attach(distortionNode)
        distortionNode.wetDryMix = Float(settings.distortionAmount)
        distortionNode.preGain = Float(settings.distortionGain)
        
        engine.attach(pitchNode)
        pitchNode.overlap = settings.pitchOverlap
        pitchNode.rate = settings.pitchRate
        pitchNode.pitch = Float(settings.pitchAmount)
        
        engine.attach(playRateNode)
        playRateNode.rate = settings.playRate
        
        engine.connect(playerNode, to: reverbNode, format: format)
        engine.connect(reverbNode, to: delayNode, format: format)
        engine.connect(delayNode, to: distortionNode, format: format)
        engine.connect(distortionNode, to: pitchNode, format: format)
        engine.connect(pitchNode, to: playRateNode, format: format)
        engine.connect(playRateNode, to: engine.mainMixerNode, format: format)
        

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
