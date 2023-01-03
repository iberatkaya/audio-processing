//
//  ContentView.swift
//  audio-processing
//
//  Created by Ibrahim Berat Kaya on 12/23/22.
//

import SwiftUI
import Foundation
import UIKit
import MobileCoreServices
import UniformTypeIdentifiers

enum ProcessingStatus {
    case idle
    case processing
    case done
}

struct ContentView: View {
    @State private var filePath: String?
    @State private var outputFilePath: String?
    @State private var showDocumentPicker = false
    @ObservedObject private var audioProcessor = AudioProcessor()
    @State private var reverb = 0.0
    @State private var delay = 0.0
    @State private var delayTimeInMS = 0.0
    @State private var processingStatus = ProcessingStatus.idle
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(alignment: .center) {
                    if audioProcessor.isPlaying {
                        Button("Stop playing") {
                            audioProcessor.stopPlayer()
                        }.padding(.bottom, 16)
                    }
                    if let filePath {
                        if !audioProcessor.isPlaying {
                            Button("Play source") {
                                try? audioProcessor.playFile(filePath)
                            }.padding(.bottom, 16)
                        }
                    } else {
                        Text("Select a file").padding(.bottom, 16)
                    }
                    if let filePath {
                        Slider(
                            value: $reverb,
                            in: 0...100,
                            step: 1,
                            label: {
                                Text("Reverb")
                            }, minimumValueLabel: {
                                Text("0")
                            }, maximumValueLabel: {
                                Text("100%")
                            })
                        .padding([.horizontal, .bottom], 16)
                        Text("Reverb: \(Int(reverb))%")
                        Slider(
                            value: $delay,
                            in: 0...100,
                            step: 1,
                            label: {
                                Text("Delay")
                            }, minimumValueLabel: {
                                Text("0")
                            }, maximumValueLabel: {
                                Text("100%")
                            })
                        .padding([.horizontal, .bottom], 16)
                        Text("Delay amount: \(Int(delay))%")
                        Slider(
                            value: $delayTimeInMS,
                            in: 0...2000,
                            step: 10,
                            label: {
                                Text("Delay time in ms")
                            }, minimumValueLabel: {
                                Text("0")
                            }, maximumValueLabel: {
                                Text("2000ms")
                            })
                        .padding([.horizontal, .bottom], 16)
                        Text("Delay amount: \(Int(delayTimeInMS))ms")
                            .padding(.bottom, 16)
                        if processingStatus != .processing {
                            Button("Process source file") {
                                self.processingStatus = .processing
                                print(processingStatus)
                                print(processingStatus != .processing)
                                DispatchQueue.global(qos: .userInitiated).async {
                                    let outputFile = try? audioProcessor.processFile(filePath, settings: ProcessingSettings(reverb: Int(reverb), delay: Int(delay), delayTimeInMS: Int(delayTimeInMS)))
                                    DispatchQueue.main.async {
                                        self.outputFilePath = outputFile?.path
                                        self.processingStatus = .done
                                    }
                                    print(self.processingStatus != .processing)
                                }
                            }
                            .padding(.bottom, 16)
                        }
                        if processingStatus == .processing {
                            ProgressView().padding(.bottom, 16)
                        }
                    }
                    if processingStatus == .done, let outputFilePath {
                        Button("Play processed file") {
                            try? audioProcessor.playFile(outputFilePath)
                        }
                        .disabled(processingStatus == .processing)
                        .padding(.bottom, 16)
                    }
                    Button("Pick\(filePath == nil ? "" : " new") file") {
                        showDocumentPicker = true
                    }
                    .padding(.bottom, 16)
                }
                .frame(width: geometry.size.width)
                .frame(height: geometry.size.height)
                .sheet(isPresented: $showDocumentPicker, content: {
                    DocumentPicker(filePath: $filePath)
                })
            }
            .frame(width: geometry.size.width)
            .frame(minHeight: geometry.size.height)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
