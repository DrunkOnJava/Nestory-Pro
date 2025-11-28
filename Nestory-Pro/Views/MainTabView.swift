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
            
            CaptureTab()
                .tabItem {
                    Label(AppTab.capture.rawValue, systemImage: AppTab.capture.iconName)
                }
                .tag(AppTab.capture)
            
            ReportsTab()
                .tabItem {
                    Label(AppTab.reports.rawValue, systemImage: AppTab.reports.iconName)
                }
                .tag(AppTab.reports)
            
            SettingsTab()
                .tabItem {
                    Label(AppTab.settings.rawValue, systemImage: AppTab.settings.iconName)
                }
                .tag(AppTab.settings)
        }
        .tint(.accentColor)
    }
}

#Preview {
    MainTabView()
        .modelContainer(for: [Item.self, Category.self, Room.self], inMemory: true)
}
