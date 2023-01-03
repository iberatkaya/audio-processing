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
    @ObservedObject var viewModel = ContentViewModel()
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(alignment: .center) {
                    if viewModel.sourceFilePath != nil {
                        EffectSliders(viewModel: viewModel)
                        
                        if viewModel.processingStatus != .processing {
                            Button("Process source file") {
                                viewModel.processFile()
                            }
                            .padding(.bottom, 16)
                        }
                        if viewModel.processingStatus == .processing {
                            ProgressView().padding(.bottom, 16)
                        }
                    }
                    if viewModel.isPlaying {
                        Button("Stop playing") {
                            viewModel.stopPlayer()
                        }.padding(.bottom, 16)
                    }
                    if viewModel.sourceFilePath != nil {
                        if !viewModel.isPlaying {
                            Button("Play source") {
                                if let sourceFilePath = viewModel.sourceFilePath {
                                    viewModel.playFile(sourceFilePath)
                                }
                            }.padding(.bottom, 16)
                            
                            if viewModel.processingStatus == .done, viewModel.outputFilePath != nil {
                                Button("Play processed file") {
                                    if let outputFilePath = viewModel.outputFilePath {
                                        viewModel.playFile(outputFilePath)
                                    }
                                }
                                .disabled(viewModel.processingStatus == .processing)
                                .padding(.bottom, 16)
                            }
                        }
                    } else {
                        Text("Select a file").padding(.bottom, 16)
                    }
                    Button("Pick\(viewModel.sourceFilePath == nil ? "" : " new") file") {
                        viewModel.showDocumentPicker = true
                    }
                    .padding(.bottom, 16)
                }
                .frame(width: geometry.size.width)
                .frame(height: geometry.size.height)
                .sheet(isPresented: $viewModel.showDocumentPicker, content: {
                    DocumentPicker(filePath: $viewModel.sourceFilePath)
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
