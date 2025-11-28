//
//  IncidentDetailsSheet.swift
//  Nestory-Pro
//
//  Created by Griffin on 11/28/25.
//

// ============================================================================
// CLAUDE CODE AGENT: INCIDENT DETAILS SHEET
// ============================================================================
// Task 3.3.2: Implements loss list incident details capture sheet
// - Date picker for incident date (defaults to today)
// - Picker for incident type (Fire, Theft, Flood, Water Damage, Other)
// - Optional description text field
// - Generates loss list PDF using ReportGeneratorService
// - Shows PDF preview/share sheet on completion
//
// SEE: TODO.md Phase 3 | ReportGeneratorService.swift | LossListSelectionView.swift
// ============================================================================

import SwiftUI
import SwiftData
import PDFKit

struct IncidentDetailsSheet: View {
    // MARK: - Properties

    /// Items selected for the loss list
    let selectedItems: [Item]

    /// Dismisses the sheet
    @Environment(\.dismiss) private var dismiss

    // MARK: - State

    @State private var incidentDate = Date()
    @State private var incidentType: IncidentType = .fire
    @State private var description = ""

    @State private var isGenerating = false
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var generatedPDFURL: URL?
    @State private var showingPDFPreview = false

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Form {
                // Incident Details Section
                Section {
                    DatePicker(
                        "Incident Date",
                        selection: $incidentDate,
                        displayedComponents: .date
                    )

                    Picker("Incident Type", selection: $incidentType) {
                        ForEach(IncidentType.allCases, id: \.self) { type in
                            Text(type.displayName)
                                .tag(type)
                        }
                    }
                } header: {
                    Text("Incident Information")
                } footer: {
                    Text("Provide details about the incident for your insurance claim.")
                }

                // Optional Description Section
                Section {
                    TextField(
                        "Description (optional)",
                        text: $description,
                        axis: .vertical
                    )
                    .lineLimit(3...6)
                } header: {
                    Text("Additional Details")
                } footer: {
                    Text("Describe the incident for your insurance documentation.")
                }

                // Summary Section
                Section {
                    HStack {
                        Text("Items Selected")
                        Spacer()
                        Text("\(selectedItems.count)")
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Text("Total Value")
                        Spacer()
                        Text(totalValue, format: .currency(code: "USD"))
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("Loss Summary")
                }
            }
            .navigationTitle("Loss List Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .disabled(isGenerating)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Generate Report") {
                        generateLossListPDF()
                    }
                    .disabled(isGenerating || selectedItems.isEmpty)
                }
            }
            .overlay {
                if isGenerating {
                    ProgressView("Generating PDF...")
                        .padding()
                        .background(.regularMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .alert("Error Generating Report", isPresented: $showingError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
            .sheet(isPresented: $showingPDFPreview) {
                if let pdfURL = generatedPDFURL {
                    PDFPreviewView(pdfURL: pdfURL)
                }
            }
        }
    }

    // MARK: - Computed Properties

    private var totalValue: Decimal {
        selectedItems.reduce(Decimal(0)) { total, item in
            total + (item.purchasePrice ?? 0)
        }
    }

    // MARK: - Methods

    @MainActor
    private func generateLossListPDF() {
        guard !selectedItems.isEmpty else { return }

        isGenerating = true

        let incident = IncidentDetails(
            incidentDate: incidentDate,
            incidentType: incidentType,
            description: description.isEmpty ? nil : description
        )

        Task {
            do {
                let pdfURL = try await ReportGeneratorService.shared.generateLossListPDF(
                    items: selectedItems,
                    incident: incident
                )

                generatedPDFURL = pdfURL
                showingPDFPreview = true
                isGenerating = false

            } catch {
                errorMessage = error.localizedDescription
                showingError = true
                isGenerating = false
            }
        }
    }
}

// MARK: - PDF Preview View

private struct PDFPreviewView: View {
    let pdfURL: URL

    @Environment(\.dismiss) private var dismiss
    @State private var showingShareSheet = false

    var body: some View {
        NavigationStack {
            IncidentPDFKitView(url: pdfURL)
                .navigationTitle("Loss List Report")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Done") {
                            dismiss()
                        }
                    }

                    ToolbarItem(placement: .primaryAction) {
                        Button {
                            showingShareSheet = true
                        } label: {
                            Label("Share", systemImage: "square.and.arrow.up")
                        }
                    }
                }
                .sheet(isPresented: $showingShareSheet) {
                    ShareSheet(items: [pdfURL])
                }
        }
    }
}

// MARK: - PDFKit View Wrapper

private struct IncidentPDFKitView: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous
        pdfView.displayDirection = .vertical

        if let document = PDFDocument(url: url) {
            pdfView.document = document
        }

        return pdfView
    }

    func updateUIView(_ uiView: PDFView, context: Context) {
        // No updates needed
    }
}

// MARK: - Share Sheet

private struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiView: UIActivityViewController, context: Context) {
        // No updates needed
    }
}

// MARK: - Preview

#Preview("Empty State") {
    IncidentDetailsSheet(selectedItems: [])
        .modelContainer(PreviewContainer.withSampleData())
}

#Preview("With Items") {
    @Previewable @State var container = makePreviewContainerWithItems()
    let context = container.mainContext
    let items = try! context.fetch(FetchDescriptor<Item>())

    IncidentDetailsSheet(selectedItems: Array(items.prefix(5)))
        .modelContainer(container)
}

// MARK: - Preview Helpers

private func makePreviewContainerWithItems() -> ModelContainer {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: Item.self, Room.self, Category.self,
        configurations: config
    )

    let context = container.mainContext

    // Seed sample data
    let categories = PreviewFixtures.sampleCategories()
    let rooms = PreviewFixtures.sampleRooms()

    categories.forEach { context.insert($0) }
    rooms.forEach { context.insert($0) }

    let items = PreviewFixtures.sampleItemCollection(categories: categories, rooms: rooms)
    items.forEach { context.insert($0) }

    return container
}
