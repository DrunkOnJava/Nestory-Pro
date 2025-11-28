//
//  LossListPDFView.swift
//  Nestory-Pro
//
//  Created by Griffin on 11/28/25.
//

// ============================================================================
// CLAUDE CODE AGENT: LOSS LIST PDF PREVIEW VIEW
// ============================================================================
// Task 3.3.3: SwiftUI view for previewing generated loss list PDFs
//
// PURPOSE:
// - Display generated loss list PDF with native PDF viewer
// - Allow pinch-to-zoom and scrolling of PDF content
// - Share button for exporting via native iOS share sheet
// - Dismiss/close functionality
//
// ARCHITECTURE:
// - UIViewRepresentable wrapper around PDFKit's PDFView
// - Accepts URL to pre-generated PDF file
// - Uses ShareLink for native sharing
// - Error handling for PDF loading failures
//
// FEATURES:
// - Navigation bar with "Loss List Report" title
// - Share button in toolbar (exports PDF file)
// - Close/Done button for dismissal
// - Pinch-to-zoom support (native PDFView behavior)
// - Scroll/pan support (native PDFView behavior)
// - Auto-scales to fit page initially
//
// ERROR HANDLING:
// - Invalid PDF URL
// - PDF document loading failures
// - Missing file at URL
//
// NAVIGATION:
// - Presented as sheet or navigation destination from LossListSelectionView
// - Dismisses after user closes or shares
//
// SEE: TODO.md Task 3.3.3 | ReportGeneratorService.swift | LossListSelectionView.swift
// ============================================================================

import SwiftUI
import PDFKit

struct LossListPDFView: View {
    // MARK: - Environment

    @Environment(\.dismiss) private var dismiss

    // MARK: - Properties

    let pdfURL: URL

    // MARK: - State

    @State private var loadError: Bool = false
    @State private var errorMessage: String?

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Group {
                if loadError {
                    errorView
                } else {
                    PDFKitView(url: pdfURL, onError: handleLoadError)
                        .ignoresSafeArea(edges: .bottom)
                }
            }
            .navigationTitle("Loss List Report")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .primaryAction) {
                    if !loadError {
                        ShareLink(item: pdfURL) {
                            Label("Share", systemImage: "square.and.arrow.up")
                        }
                    }
                }
            }
        }
    }

    // MARK: - View Components

    private var errorView: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 60))
                .foregroundStyle(.orange)

            Text("Failed to Load PDF")
                .font(.title2)
                .fontWeight(.semibold)

            Text(errorMessage ?? "The PDF file could not be loaded. Please try generating the report again.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Button {
                dismiss()
            } label: {
                Text("Close")
                    .fontWeight(.semibold)
                    .frame(maxWidth: 200)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Actions

    private func handleLoadError(_ error: String) {
        errorMessage = error
        loadError = true
    }
}

// MARK: - PDFKit UIViewRepresentable

struct PDFKitView: UIViewRepresentable {
    let url: URL
    let onError: (String) -> Void

    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()

        // Configure PDF view for optimal viewing
        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous
        pdfView.displayDirection = .vertical

        // Enable user interactions
        pdfView.isUserInteractionEnabled = true
        pdfView.minScaleFactor = pdfView.scaleFactorForSizeToFit
        pdfView.maxScaleFactor = 4.0

        // Load the PDF document
        loadPDF(into: pdfView)

        return pdfView
    }

    func updateUIView(_ pdfView: PDFView, context: Context) {
        // Only reload if the URL has changed
        if pdfView.document?.documentURL != url {
            loadPDF(into: pdfView)
        }
    }

    private func loadPDF(into pdfView: PDFView) {
        guard let document = PDFDocument(url: url) else {
            onError("Unable to load PDF document from file.")
            return
        }

        // Verify the document has at least one page
        if document.pageCount == 0 {
            onError("The PDF document is empty or corrupted.")
            return
        }

        pdfView.document = document
    }
}

// MARK: - Previews

#Preview("Loss List PDF View - Valid PDF") {
    // Create a sample PDF for preview
    let samplePDFURL = createSamplePDF()
    LossListPDFView(pdfURL: samplePDFURL)
}

#Preview("Loss List PDF View - Invalid PDF") {
    // Use invalid URL to test error state
    let invalidURL = URL(fileURLWithPath: "/nonexistent/file.pdf")
    LossListPDFView(pdfURL: invalidURL)
}

// MARK: - Preview Helpers

private func createSamplePDF() -> URL {
    let pdfData = NSMutableData()
    let pageSize = CGSize(width: 612, height: 792) // US Letter
    var mediaBox = CGRect(origin: .zero, size: pageSize)

    guard let consumer = CGDataConsumer(data: pdfData),
          let context = CGContext(consumer: consumer, mediaBox: &mediaBox, nil) else {
        fatalError("Failed to create PDF context for preview")
    }

    context.beginPage(mediaBox: &mediaBox)

    // Draw sample content
    let titleAttributes: [NSAttributedString.Key: Any] = [
        .font: UIFont.systemFont(ofSize: 24, weight: .bold),
        .foregroundColor: UIColor.label
    ]

    let bodyAttributes: [NSAttributedString.Key: Any] = [
        .font: UIFont.systemFont(ofSize: 14, weight: .regular),
        .foregroundColor: UIColor.label
    ]

    let title = NSAttributedString(string: "Sample Loss List Report", attributes: titleAttributes)
    let body = NSAttributedString(string: "This is a preview of a loss list PDF.\n\nIn the actual app, this will display the generated insurance loss list with incident details and item information.", attributes: bodyAttributes)

    title.draw(at: CGPoint(x: 54, y: 54))
    body.draw(in: CGRect(x: 54, y: 100, width: pageSize.width - 108, height: 200))

    context.endPage()
    context.closePDF()

    // Save to temp file
    let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("SampleLossList.pdf")
    try? pdfData.write(to: tempURL)

    return tempURL
}
