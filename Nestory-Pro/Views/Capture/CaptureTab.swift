//
//  CaptureTab.swift
//  Nestory-Pro
//
//  Created by Griffin on 11/28/25.
//

import SwiftUI

struct CaptureTab: View {
    var body: some View {
        NavigationStack {
            EmptyStateView(
                iconName: "camera.fill",
                title: "Capture",
                message: "Photo, receipt, and barcode capture coming soon."
            )
            .navigationTitle("Capture")
        }
    }
}

#Preview {
    CaptureTab()
}
