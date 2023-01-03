//
//  DocumentPicker.swift
//  audio-processing
//
//  Created by Ibrahim Berat Kaya on 1/2/23.
//

import Foundation
import SwiftUI

struct DocumentPicker: UIViewControllerRepresentable {
    @Binding var filePath: String?
    
    func makeCoordinator() -> DocumentPickerCoordinator {
        return DocumentPickerCoordinator(filePath: $filePath)
    }
    
    func makeUIViewController(context: UIViewControllerRepresentableContext<DocumentPicker>) -> UIDocumentPickerViewController {
        let controller = UIDocumentPickerViewController(forOpeningContentTypes: [.audio])
        controller.delegate = context.coordinator
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {
    }
}

class DocumentPickerCoordinator: NSObject, UIDocumentPickerDelegate, UINavigationControllerDelegate {
    @Binding var filePath: String?
    
    init(filePath: Binding<String?>) {
        _filePath = filePath
    }
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        filePath = urls[0].path
    }
}
