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
                    in: -6...80,
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
            }.tag(2)
        }.tabViewStyle(.page)
    }
}

struct EffectSliders_Previews: PreviewProvider {
    @State static var viewModel = ContentViewModel()
    
    static var previews: some View {
        EffectSliders(viewModel: viewModel)
    }
}
