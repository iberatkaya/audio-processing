//
//  EffectSliders.swift
//  audio-processing
//
//  Created by Ibrahim Berat Kaya on 1/2/23.
//

import SwiftUI

struct EffectSliders: View {
    @ObservedObject var viewModel: ContentViewModel
    @State private var currentEffect = 0

    var body: some View {
        Picker("Audio Effects", selection: $currentEffect) {
            Text("Reverb").tag(0)
            Text("Delay").tag(1)
            Text("Distortion").tag(2)
            Text("Pitch").tag(3)
            Text("Play Rate").tag(4)
        }
        .onChange(of: currentEffect, perform: { newValue in
            
        })
        .padding([.horizontal, .top], 16)
        .pickerStyle(.segmented)
        TabView(selection: $currentEffect) {
            VStack {
                Slider(
                    value: $viewModel.reverb,
                    in: 0...100,
                    step: 1,
                    label: {
                        Text("Reverb")
                    }, minimumValueLabel: {
                        Text("0")
                    }, maximumValueLabel: {
                        Text("100%")
                    })
                .padding(.horizontal, 24)
                .padding(.bottom, 8)
                Text("Reverb: \(Int(viewModel.reverb))%")
                    .padding(.bottom, 8)
                Button("Reset") {
                    viewModel.resetReverb()
                }
            }.tag(0)
            
            VStack {
                Slider(
                    value: $viewModel.delay,
                    in: 0...100,
                    step: 1,
                    label: {
                        Text("Delay")
                    }, minimumValueLabel: {
                        Text("0")
                    }, maximumValueLabel: {
                        Text("100%")
                    })
                .padding(.horizontal, 24)
                .padding(.bottom, 8)
                Text("Delay amount: \(Int(viewModel.delay))%")
                    .padding(.bottom, 8)
                
                Slider(
                    value: $viewModel.delayTimeInMS,
                    in: 0...2000,
                    step: 10,
                    label: {
                        Text("Delay time in ms")
                    }, minimumValueLabel: {
                        Text("0")
                    }, maximumValueLabel: {
                        Text("2000ms")
                    })
                .padding(.horizontal, 24)
                .padding(.bottom, 8)
                Text("Delay amount: \(Int(viewModel.delayTimeInMS))ms")
                    .padding(.bottom, 8)
                
                Slider(
                    value: $viewModel.delayFeedback,
                    in: -100...100,
                    step: 1,
                    label: {
                        Text("Delay feedback")
                    }, minimumValueLabel: {
                        Text("-100%")
                    }, maximumValueLabel: {
                        Text("100%")
                    })
                .padding(.horizontal, 24)
                .padding(.bottom, 8)
                Text("Delay feedback: \(Int(viewModel.delayFeedback))%")
                    .padding(.bottom, 8)
                
                if let fileSampleRate = viewModel.fileSampleRate, let maxLimit = fileSampleRate / 2 {
                    Slider(
                        value: $viewModel.delayLowPassCutoff,
                        in: 10...maxLimit,
                        step: 10,
                        label: {
                            Text("Delay low pass cutoff")
                        }, minimumValueLabel: {
                            Text("10 Hz")
                        }, maximumValueLabel: {
                            Text("\(Int(maxLimit)) Hz")
                        })
                    .padding(.horizontal, 24)
                    .padding(.bottom, 8)
                    Text("Delay low pass cutoff: \(Int(viewModel.delayLowPassCutoff)) Hz")
                        .padding(.bottom, 8)
                }
                Button("Reset") {
                    viewModel.resetDelay()
                }
            }.tag(1)
            
            VStack {
                Slider(
                    value: $viewModel.distortionAmount,
                    in: 0...100,
                    step: 1,
                    label: {
                        Text("Distortion amount")
                    }, minimumValueLabel: {
                        Text("0")
                    }, maximumValueLabel: {
                        Text("100%")
                    })
                .padding(.horizontal, 24)
                .padding(.bottom, 8)
                Text("Distortion: \(Int(viewModel.distortionAmount))%")
                    .padding(.bottom, 8)
                
                Slider(
                    value: $viewModel.distortionGain,
                    in: -80...20,
                    step: 1,
                    label: {
                        Text("Pre gain in dB")
                    }, minimumValueLabel: {
                        Text("-6")
                    }, maximumValueLabel: {
                        Text("80 dB")
                    })
                .padding(.horizontal, 24)
                .padding(.bottom, 8)
                Text("Pre gain: \(Int(viewModel.distortionGain)) dB")
                    .padding(.bottom, 8)
                Button("Reset") {
                    viewModel.resetDistortion()
                }
            }.tag(2)
            
            VStack {
                Slider(
                    value: $viewModel.pitchAmount,
                    in: -2400...2400,
                    step: 100,
                    label: {
                        Text("Pitch amount")
                    }, minimumValueLabel: {
                        Text("-2400")
                    }, maximumValueLabel: {
                        Text("2400 cents")
                    })
                .padding(.horizontal, 24)
                .padding(.bottom, 8)
                Text("Pitch amount: \(Int(viewModel.pitchAmount)) cents")
                    .padding(.bottom, 8)
                
                Slider(
                    value: $viewModel.pitchRate,
                    in: (1/32)...32,
                    step: 1/32,
                    label: {
                        Text("Pitch rate")
                    }, minimumValueLabel: {
                        Text("1/32")
                    }, maximumValueLabel: {
                        Text("32")
                    })
                .padding(.horizontal, 24)
                .padding(.bottom, 8)
                Text(String(format: "Pitch rate: %.2f", viewModel.pitchRate))
                    .padding(.bottom, 8)
                
                Slider(
                    value: $viewModel.pitchOverlap,
                    in: 3...32,
                    step: 0.25,
                    label: {
                        Text("Pitch overlap")
                    }, minimumValueLabel: {
                        Text("3")
                    }, maximumValueLabel: {
                        Text("32")
                    })
                .padding(.horizontal, 24)
                .padding(.bottom, 8)
                Text(String(format: "Pitch overlap: %.2f", viewModel.pitchOverlap))
                    .padding(.bottom, 8)
                Button("Reset") {
                    viewModel.resetPitch()
                }
            }.tag(3)
            
            
            VStack {
                Slider(
                    value: $viewModel.playRate,
                    in: 0.25...4,
                    step: 0.05,
                    label: {
                        Text("Play rate")
                    }, minimumValueLabel: {
                        Text("0.25")
                    }, maximumValueLabel: {
                        Text("4")
                    })
                .padding(.horizontal, 24)
                .padding(.bottom, 8)
                Text(String(format: "Play rate: %.2fx", viewModel.playRate))
                    .padding(.bottom, 8)
                Button("Reset") {
                    viewModel.resetPlayRate()
                }
            }.tag(4)
        }.tabViewStyle(.page)
    }
}

struct EffectSliders_Previews: PreviewProvider {
    @State static var viewModel = ContentViewModel()
    
    static var previews: some View {
        EffectSliders(viewModel: viewModel)
    }
}
