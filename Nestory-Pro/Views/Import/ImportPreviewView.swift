//
//  ImportPreviewView.swift
//  Nestory-Pro
//
//  F6-03: CSV import preview and workflow sheet
//

// ============================================================================
// F6-03: ImportPreviewView
// ============================================================================
// Full-screen sheet for CSV import workflow:
// - Step 1: File parsing and preview
// - Step 2: Column mapping configuration
// - Step 3: Validation and error review
// - Step 4: Import execution and progress
// - Step 5: Results summary
//
// SEE: TODO.md F6-03 | CSVImportService.swift | FieldMappingView.swift
// ============================================================================

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

// MARK: - ImportPreviewView

struct ImportPreviewView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var importService = CSVImportService()
    @State private var showFilePicker = true
    @State private var currentStep: ImportStep = .selectFile

    enum ImportStep {
        case selectFile
        case preview
        case mapping
        case validating
        case importing
        case completed
        case error
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Progress indicator
                ImportProgressBar(currentStep: currentStep)
                    .padding(.horizontal)
                    .padding(.top, 8)

                // Content based on step
                Group {
                    switch currentStep {
                    case .selectFile:
                        SelectFileView(showFilePicker: $showFilePicker)

                    case .preview:
                        if let result = importService.parseResult {
                            CSVPreviewView(parseResult: result)
                        }

                    case .mapping:
                        if let mapping = importService.mappingResult,
                           let parse = importService.parseResult {
                            FieldMappingView(
                                mappingResult: mapping,
                                headers: parse.headers,
                                sampleRow: parse.rows.first ?? [],
                                onMappingChange: { columnIndex, field in
                                    Task {
                                        await importService.updateColumnMapping(
                                            columnIndex: columnIndex,
                                            field: field
                                        )
                                    }
                                }
                            )
                        }

                    case .validating:
                        ValidationProgressView(
                            validatedCount: importService.validatedRows.count,
                            errorCount: importService.validationErrors.count
                        )

                    case .importing:
                        if case .importing(let progress) = importService.state {
                            ImportProgressView(progress: progress)
                        }

                    case .completed:
                        if case .completed(let summary) = importService.state {
                            ImportCompletedView(summary: summary)
                        }

                    case .error:
                        if case .failed(let message) = importService.state {
                            ImportErrorView(message: message)
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                // Bottom action bar
                actionBar
            }
            .navigationTitle(navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .fileImporter(
                isPresented: $showFilePicker,
                allowedContentTypes: [.commaSeparatedText, .tabSeparatedText, .plainText],
                onCompletion: handleFileSelection
            )
            .onChange(of: importService.state) { _, newState in
                updateStep(for: newState)
            }
        }
    }

    // MARK: - Subviews

    private var navigationTitle: String {
        switch currentStep {
        case .selectFile: return "Import from CSV"
        case .preview: return "Preview Data"
        case .mapping: return "Map Columns"
        case .validating: return "Validating..."
        case .importing: return "Importing..."
        case .completed: return "Import Complete"
        case .error: return "Import Error"
        }
    }

    @ViewBuilder
    private var actionBar: some View {
        VStack(spacing: 12) {
            Divider()

            HStack(spacing: 16) {
                // Secondary action
                if currentStep == .preview || currentStep == .mapping {
                    Button("Back") {
                        goBack()
                    }
                    .buttonStyle(.bordered)
                }

                Spacer()

                // Primary action
                primaryActionButton
            }
            .padding(.horizontal)
            .padding(.bottom, 8)
        }
        .background(.background)
    }

    @ViewBuilder
    private var primaryActionButton: some View {
        switch currentStep {
        case .selectFile:
            Button("Select File") {
                showFilePicker = true
            }
            .buttonStyle(.borderedProminent)

        case .preview:
            Button("Configure Mapping") {
                currentStep = .mapping
            }
            .buttonStyle(.borderedProminent)

        case .mapping:
            Button("Validate & Import") {
                startValidation()
            }
            .buttonStyle(.borderedProminent)
            .disabled(importService.mappingResult?.isValid != true)

        case .validating, .importing:
            Button("Please wait...") {}
                .buttonStyle(.borderedProminent)
                .disabled(true)

        case .completed:
            Button("Done") {
                dismiss()
            }
            .buttonStyle(.borderedProminent)

        case .error:
            Button("Try Again") {
                importService.reset()
                currentStep = .selectFile
                showFilePicker = true
            }
            .buttonStyle(.borderedProminent)
        }
    }

    // MARK: - Actions

    private func handleFileSelection(_ result: Result<URL, Error>) {
        switch result {
        case .success(let url):
            guard url.startAccessingSecurityScopedResource() else {
                importService.setError("Unable to access the selected file")
                return
            }

            defer { url.stopAccessingSecurityScopedResource() }

            Task {
                await importService.parseFile(url: url)
            }

        case .failure(let error):
            importService.setError(error.localizedDescription)
        }
    }

    private func updateStep(for state: CSVImportService.ImportState) {
        switch state {
        case .idle:
            currentStep = .selectFile
        case .parsing:
            currentStep = .selectFile
        case .mapping:
            currentStep = .preview
        case .validating:
            currentStep = .validating
        case .importing:
            currentStep = .importing
        case .completed:
            currentStep = .completed
        case .failed:
            currentStep = .error
        }
    }

    private func goBack() {
        switch currentStep {
        case .mapping:
            currentStep = .preview
        case .preview:
            importService.reset()
            currentStep = .selectFile
            showFilePicker = true
        default:
            break
        }
    }

    private func startValidation() {
        Task {
            await importService.validateRows()

            // If validation passed, start import
            if importService.validatedRows.isEmpty && !importService.validationErrors.isEmpty {
                // All rows had errors - show error state
                importService.setError("All rows have validation errors. Please check column mappings.")
            } else {
                await importService.executeImport(modelContext: modelContext)
            }
        }
    }
}

// MARK: - ImportProgressBar

private struct ImportProgressBar: View {
    let currentStep: ImportPreviewView.ImportStep

    private var stepIndex: Int {
        switch currentStep {
        case .selectFile: return 0
        case .preview: return 1
        case .mapping: return 2
        case .validating, .importing: return 3
        case .completed, .error: return 4
        }
    }

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<5, id: \.self) { index in
                Capsule()
                    .fill(index <= stepIndex ? Color.accentColor : Color.secondary.opacity(0.3))
                    .frame(height: 4)
            }
        }
    }
}

// MARK: - SelectFileView

private struct SelectFileView: View {
    @Binding var showFilePicker: Bool

    var body: some View {
        ContentUnavailableView {
            Label("Select a CSV File", systemImage: "doc.text")
        } description: {
            Text("Choose a CSV or spreadsheet file to import items from.")
        } actions: {
            Button("Browse Files") {
                showFilePicker = true
            }
            .buttonStyle(.borderedProminent)
        }
    }
}

// MARK: - CSVPreviewView

private struct CSVPreviewView: View {
    let parseResult: CSVParser.ParseResult

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Summary
            HStack(spacing: 20) {
                StatView(title: "Rows", value: "\(parseResult.rowCount)")
                StatView(title: "Columns", value: "\(parseResult.columnCount)")
                StatView(title: "Delimiter", value: parseResult.detectedDelimiter.displayName)
            }
            .padding(.horizontal)

            // Preview table
            ScrollView([.horizontal, .vertical]) {
                LazyVStack(alignment: .leading, spacing: 0) {
                    // Headers
                    HStack(spacing: 0) {
                        ForEach(Array(parseResult.headers.enumerated()), id: \.offset) { _, header in
                            Text(header)
                                .font(.caption.bold())
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                                .frame(width: 120, alignment: .leading)
                                .padding(8)
                                .background(Color(.systemGray5))
                        }
                    }

                    Divider()

                    // Data rows (first 10)
                    ForEach(Array(parseResult.rows.prefix(10).enumerated()), id: \.offset) { rowIndex, row in
                        HStack(spacing: 0) {
                            ForEach(Array(row.enumerated()), id: \.offset) { _, cell in
                                Text(cell)
                                    .font(.caption)
                                    .lineLimit(2)
                                    .frame(width: 120, alignment: .leading)
                                    .padding(8)
                            }
                        }
                        .background(rowIndex % 2 == 0 ? Color.clear : Color(.systemGray6))
                    }

                    if parseResult.rowCount > 10 {
                        Text("... and \(parseResult.rowCount - 10) more rows")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding()
                    }
                }
            }
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(.separator), lineWidth: 0.5)
            )
            .padding(.horizontal)
        }
        .padding(.vertical)
    }
}

private struct StatView: View {
    let title: String
    let value: String

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2.bold())
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - ValidationProgressView

private struct ValidationProgressView: View {
    let validatedCount: Int
    let errorCount: Int

    var body: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)

            Text("Validating rows...")
                .font(.headline)

            HStack(spacing: 30) {
                Label("\(validatedCount) valid", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                Label("\(errorCount) errors", systemImage: "exclamationmark.circle.fill")
                    .foregroundStyle(.red)
            }
            .font(.subheadline)
        }
    }
}

// MARK: - ImportProgressView

private struct ImportProgressView: View {
    let progress: Double

    var body: some View {
        VStack(spacing: 20) {
            ProgressView(value: progress)
                .progressViewStyle(.linear)
                .frame(width: 200)

            Text("\(Int(progress * 100))% complete")
                .font(.headline)

            Text("Importing items...")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - ImportCompletedView

private struct ImportCompletedView: View {
    let summary: CSVImportService.ImportSummary

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundStyle(.green)

            Text("Import Completed!")
                .font(.title2.bold())

            VStack(spacing: 12) {
                SummaryRow(label: "Items imported", value: "\(summary.importedCount)")
                if summary.skippedCount > 0 {
                    SummaryRow(label: "Rows skipped", value: "\(summary.skippedCount)")
                }
                if summary.errorCount > 0 {
                    SummaryRow(label: "Errors", value: "\(summary.errorCount)")
                }
                SummaryRow(label: "Time", value: String(format: "%.1fs", summary.duration))
            }
            .padding()
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 12))

            if !summary.errors.isEmpty {
                DisclosureGroup("View Errors (\(summary.errors.count))") {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(summary.errors.prefix(10)) { error in
                            Text("Row \(error.rowNumber): \(error.message)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        if summary.errors.count > 10 {
                            Text("... and \(summary.errors.count - 10) more")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding()
            }
        }
        .padding()
    }
}

private struct SummaryRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
    }
}

// MARK: - ImportErrorView

private struct ImportErrorView: View {
    let message: String

    var body: some View {
        ContentUnavailableView {
            Label("Import Failed", systemImage: "exclamationmark.triangle.fill")
                .foregroundStyle(.red)
        } description: {
            Text(message)
        }
    }
}

// MARK: - Preview

#Preview {
    ImportPreviewView()
}
