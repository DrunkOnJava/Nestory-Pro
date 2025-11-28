//
//  MainTabView.swift
//  Nestory-Pro
//
//  Created by Griffin on 11/28/25.
//

import SwiftUI
import SwiftData

enum AppTab: String, CaseIterable {
    case inventory = "Inventory"
    case capture = "Capture"
    case reports = "Reports"
    case settings = "Settings"
    
    var iconName: String {
        switch self {
        case .inventory: return "archivebox.fill"
        case .capture: return "camera.fill"
        case .reports: return "doc.text.fill"
        case .settings: return "gearshape.fill"
        }
    }
}

struct MainTabView: View {
    @State private var selectedTab: AppTab = .inventory
    
    var body: some View {
        TabView(selection: $selectedTab) {
            InventoryTab()
                .tabItem {
                    Label(AppTab.inventory.rawValue, systemImage: AppTab.inventory.iconName)
                }
                .tag(AppTab.inventory)
                .accessibilityIdentifier("mainTab.inventory")
            
            CaptureTab()
                .tabItem {
                    Label(AppTab.capture.rawValue, systemImage: AppTab.capture.iconName)
                }
                .tag(AppTab.capture)
                .accessibilityIdentifier("mainTab.capture")
            
            ReportsTab()
                .tabItem {
                    Label(AppTab.reports.rawValue, systemImage: AppTab.reports.iconName)
                }
                .tag(AppTab.reports)
                .accessibilityIdentifier("mainTab.reports")
            
            SettingsTab()
                .tabItem {
                    Label(AppTab.settings.rawValue, systemImage: AppTab.settings.iconName)
                }
                .tag(AppTab.settings)
                .accessibilityIdentifier("mainTab.settings")
        }
        .tint(.accentColor)
    }
}

#Preview("Default - Light") {
    MainTabView()
        .modelContainer(PreviewContainer.withSampleData())
}

#Preview("Default - Dark") {
    MainTabView()
        .modelContainer(PreviewContainer.withSampleData())
        .preferredColorScheme(.dark)
}

#Preview("Empty Inventory") {
    MainTabView()
        .modelContainer(PreviewContainer.emptyInventory())
}

#Preview("Many Items") {
    MainTabView()
        .modelContainer(PreviewContainer.withManyItems(count: 50))
}

#Preview("Large Text") {
    MainTabView()
        .modelContainer(PreviewContainer.withSampleData())
        .environment(\.dynamicTypeSize, .xxxLarge)
}

#Preview("Small Text") {
    MainTabView()
        .modelContainer(PreviewContainer.withSampleData())
        .environment(\.dynamicTypeSize, .xSmall)
}
