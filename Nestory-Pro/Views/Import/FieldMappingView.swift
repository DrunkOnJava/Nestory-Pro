//
//  FieldMappingView.swift
//  Nestory-Pro
//
//  F6-04: Column to field mapping UI
//

// ============================================================================
// F6-04: FieldMappingView
// ============================================================================
// UI for mapping CSV columns to Item model fields.
// - Shows each column with auto-detected mapping
// - Confidence indicator for auto-mappings
// - Dropdown to change or clear mappings
// - Sample data preview for each column
//
// SEE: TODO.md F6-04 | ColumnMapper.swift | ImportPreviewView.swift
// ============================================================================

import SwiftUI

// MARK: - FieldMappingView

struct FieldMappingView: View {
    let mappingResult: ColumnMapper.MappingResult
    let headers: [String]
    let sampleRow: [String]
    let onMappingChange: (Int, ColumnMapper.TargetField?) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Warnings
            if !mappingResult.warnings.isEmpty {
                WarningsSection(warnings: mappingResult.warnings)
            }

            // Mapping list
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(mappingResult.mappings) { mapping in
                        ColumnMappingRow(
                            mapping: mapping,
                            sampleValue: sampleRow.indices.contains(mapping.columnIndex)
                                ? sampleRow[mapping.columnIndex]
                                : "",
                            onMappingChange: { field in
                                onMappingChange(mapping.columnIndex, field)
                            }
                        )
                    }
                }
                .padding(.horizontal)
            }

            // Summary footer
            MappingSummary(mappingResult: mappingResult)
        }
        .padding(.vertical)
    }
}

// MARK: - WarningsSection

private struct WarningsSection: View {
    let warnings: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(warnings, id: \.self) { warning in
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                    Text(warning)
                        .font(.caption)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.orange.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .padding(.horizontal)
    }
}

// MARK: - ColumnMappingRow

private struct ColumnMappingRow: View {
    let mapping: ColumnMapper.ColumnMapping
    let sampleValue: String
    let onMappingChange: (ColumnMapper.TargetField?) -> Void

    @State private var selectedField: ColumnMapper.TargetField?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Column header and confidence
            HStack {
                Text(mapping.columnHeader)
                    .font(.headline)

                Spacer()

                if mapping.isAutoMapped {
                    ConfidenceBadge(confidence: mapping.confidence)
                }
            }

            // Sample value
            if !sampleValue.isEmpty {
                Text("Sample: \"\(sampleValue.prefix(50))\(sampleValue.count > 50 ? "..." : "")\"")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            // Field selector
            HStack {
                Image(systemName: "arrow.right")
                    .foregroundStyle(.secondary)

                Picker("Map to", selection: $selectedField) {
                    Text("Don't import").tag(nil as ColumnMapper.TargetField?)

                    ForEach(ColumnMapper.TargetField.allCases, id: \.self) { field in
                        HStack {
                            Text(field.displayName)
                            if field.isRequired {
                                Text("*")
                                    .foregroundStyle(.red)
                            }
                        }
                        .tag(field as ColumnMapper.TargetField?)
                    }
                }
                .pickerStyle(.menu)
                .tint(selectedField == nil ? .secondary : .accentColor)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .onAppear {
            selectedField = mapping.targetField
        }
        .onChange(of: selectedField) { _, newValue in
            if newValue != mapping.targetField {
                onMappingChange(newValue)
            }
        }
    }
}

// MARK: - ConfidenceBadge

private struct ConfidenceBadge: View {
    let confidence: Double

    private var color: Color {
        if confidence >= 0.9 { return .green }
        if confidence >= 0.7 { return .orange }
        return .red
    }

    private var text: String {
        if confidence >= 0.9 { return "High" }
        if confidence >= 0.7 { return "Medium" }
        return "Low"
    }

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 6, height: 6)
            Text("\(text) confidence")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.1))
        .clipShape(Capsule())
    }
}

// MARK: - MappingSummary

private struct MappingSummary: View {
    let mappingResult: ColumnMapper.MappingResult

    var body: some View {
        HStack(spacing: 20) {
            SummaryItem(
                icon: "checkmark.circle.fill",
                color: .green,
                count: mappingResult.mappedFieldCount,
                label: "Mapped"
            )

            SummaryItem(
                icon: "minus.circle.fill",
                color: .secondary,
                count: mappingResult.unmappedColumns.count,
                label: "Unmapped"
            )

            if !mappingResult.missingRequiredFields.isEmpty {
                SummaryItem(
                    icon: "exclamationmark.circle.fill",
                    color: .red,
                    count: mappingResult.missingRequiredFields.count,
                    label: "Required"
                )
            }

            Spacer()

            if mappingResult.isValid {
                Label("Ready to import", systemImage: "checkmark.seal.fill")
                    .font(.caption)
                    .foregroundStyle(.green)
            } else {
                Label("Map required fields", systemImage: "exclamationmark.triangle.fill")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }
        }
        .padding()
        .background(Color(.systemGray6))
    }
}

private struct SummaryItem: View {
    let icon: String
    let color: Color
    let count: Int
    let label: String

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .foregroundStyle(color)
            Text("\(count)")
                .fontWeight(.medium)
            Text(label)
                .foregroundStyle(.secondary)
        }
        .font(.caption)
    }
}

// MARK: - Preview

#Preview {
    let mappings: [ColumnMapper.ColumnMapping] = [
        ColumnMapper.ColumnMapping(columnIndex: 0, columnHeader: "Item Name", targetField: .name, confidence: 1.0),
        ColumnMapper.ColumnMapping(columnIndex: 1, columnHeader: "Brand", targetField: .brand, confidence: 0.95),
        ColumnMapper.ColumnMapping(columnIndex: 2, columnHeader: "Price", targetField: .purchasePrice, confidence: 0.8),
        ColumnMapper.ColumnMapping(columnIndex: 3, columnHeader: "Location", targetField: .room, confidence: 0.7),
        ColumnMapper.ColumnMapping(columnIndex: 4, columnHeader: "Notes", targetField: nil, confidence: 0)
    ]

    let mappingResult = ColumnMapper.MappingResult(
        mappings: mappings,
        unmappedColumns: [4],
        missingRequiredFields: [],
        warnings: ["Low confidence mappings (review recommended): \"Location\""]
    )

    return FieldMappingView(
        mappingResult: mappingResult,
        headers: ["Item Name", "Brand", "Price", "Location", "Notes"],
        sampleRow: ["MacBook Pro", "Apple", "$2499.00", "Office", "Work laptop"],
        onMappingChange: { _, _ in }
    )
}
