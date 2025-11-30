//
//  FeedbackSheet.swift
//  Nestory-Pro
//
//  Created for v1.2 - P4-07
//

// ============================================================================
// FEEDBACK SHEET
// ============================================================================
// Task P4-07: In-app feedback & support
// - Displays feedback category options
// - Shows device info summary
// - Opens email with pre-filled info
//
// SEE: TODO.md P4-07 | FeedbackService.swift
// ============================================================================

import SwiftUI

struct FeedbackSheet: View {
    @Environment(\.dismiss) private var dismiss

    let feedbackService: FeedbackService

    @State private var showingEmailError = false
    @State private var emailErrorMessage = ""
    
    var body: some View {
        NavigationStack {
            List {
                // Feedback categories
                Section {
                    ForEach(FeedbackCategory.allCases, id: \.self) { category in
                        Button {
                            sendFeedback(category: category)
                        } label: {
                            HStack {
                                Label(category.rawValue, systemImage: category.icon)
                                    .foregroundStyle(.primary)
                                Spacer()
                                Image(systemName: "arrow.up.right")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                } header: {
                    Text("What would you like to share?")
                } footer: {
                    Text("This will open your email app with device info pre-filled.")
                }
                
                // Device info summary (simplified - full details included in email)
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        DeviceInfoRow(label: "App Version", value: appVersion)
                        DeviceInfoRow(label: "iOS Version", value: UIDevice.current.systemVersion)
                        DeviceInfoRow(label: "Device", value: UIDevice.current.model)
                    }
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                } header: {
                    Text("Device Information")
                } footer: {
                    Text("This information helps us troubleshoot issues.")
                }
                
                // Help Center link
                Section {
                    Link(destination: URL(string: "https://nestory-support.netlify.app")!) {
                        HStack {
                            Label("Visit Help Center", systemImage: "questionmark.circle")
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                } footer: {
                    Text("Browse FAQs and troubleshooting guides.")
                }
            }
            .navigationTitle("Send Feedback")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Email Not Available", isPresented: $showingEmailError) {
                Button("OK", role: .cancel) { }
                Button("Copy Email Address") {
                    UIPasteboard.general.string = FeedbackService.supportEmail
                }
            } message: {
                Text(emailErrorMessage)
            }
        }
    }
    
    // MARK: - Private
    
    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }
    
    private func sendFeedback(category: FeedbackCategory) {
        feedbackService.openFeedbackEmail(category: category) { success, errorMessage in
            if success {
                dismiss()
            } else if let error = errorMessage {
                emailErrorMessage = error
                showingEmailError = true
            }
        }
    }
}

// MARK: - Supporting Views

private struct DeviceInfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
            Spacer()
            Text(value)
                .foregroundStyle(.tertiary)
        }
    }
}

// MARK: - Preview

#if DEBUG
#Preview {
    FeedbackSheet(feedbackService: FeedbackService())
}
#endif
