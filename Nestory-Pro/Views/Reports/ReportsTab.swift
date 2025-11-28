//
//  ReportsTab.swift
//  Nestory-Pro
//
//  Created by Griffin on 11/28/25.
//

import SwiftUI

struct ReportsTab: View {
    var body: some View {
        NavigationStack {
            EmptyStateView(
                iconName: "doc.text.fill",
                title: "Reports",
                message: "Generate insurance-ready PDFs and loss lists."
            )
            .navigationTitle("Reports")
        }
    }
}

#Preview {
    ReportsTab()
}
