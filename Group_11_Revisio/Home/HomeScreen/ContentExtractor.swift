//
//  ContentExtractor.swift
//  Group_11_Revisio
//
//  Created by Mithil on 11/02/26.
//


import UIKit
import PDFKit
import Vision

class ContentExtractor {
    static let shared = ContentExtractor()
    
    /// Main function to determine file type and extract text accordingly
    func extractContent(from item: Any) async -> String {
        // 1. If it's a Topic object, return its notes
        if let topic = item as? Topic {
            let notes = topic.notesContent ?? ""
            let body = topic.largeContentBody ?? ""
            let combined = "\(notes)\n\(body)".trimmingCharacters(in: .whitespacesAndNewlines)
            return combined.isEmpty ? topic.name : combined
        }
        
        // 2. If it's a URL (File), extract based on extension
        if let url = item as? URL {
            let fileExtension = url.pathExtension.lowercased()
            
            if fileExtension == "pdf" {
                return extractTextFromPDF(url: url)
            } else if ["jpg", "jpeg", "png", "heic"].contains(fileExtension) {
                return await extractTextFromImage(url: url)
            } else if ["txt", "md", "json"].contains(fileExtension) {
                return (try? String(contentsOf: url, encoding: .utf8)) ?? ""
            }
        }
        
        // 3. If it's just a String, return it
        if let str = item as? String {
            return str
        }
        
        return ""
    }
    
    // MARK: - PDF Extraction
    private func extractTextFromPDF(url: URL) -> String {
        guard let pdfDocument = PDFDocument(url: url) else { return "" }
        var fullText = ""
        
        // Loop through all pages and append text
        for i in 0..<pdfDocument.pageCount {
            if let page = pdfDocument.page(at: i), let pageText = page.string {
                fullText += pageText + "\n"
            }
        }
        
        return fullText.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    // MARK: - Image OCR (Vision)
    private func extractTextFromImage(url: URL) async -> String {
        guard let image = UIImage(contentsOfFile: url.path),
              let cgImage = image.cgImage else { return "" }
        
        return await withCheckedContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                guard let observations = request.results as? [VNRecognizedTextObservation], error == nil else {
                    continuation.resume(returning: "")
                    return
                }
                
                let recognizedStrings = observations.compactMap { $0.topCandidates(1).first?.string }
                let finalText = recognizedStrings.joined(separator: "\n")
                continuation.resume(returning: finalText)
            }
            
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            try? handler.perform([request])
        }
    }
}