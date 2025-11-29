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
    @Environment(AppEnvironment.self) private var env
    @Environment(\.scenePhase) private var scenePhase
    
    // Direct AppStorage observation for theme changes (fixes theme toggle)
    @AppStorage("themePreference") private var themePreference: ThemePreference = .system
    
    @State private var selectedTab: AppTab = .inventory
    @State private var isLocked = false
    @State private var lastBackgroundTime: Date?
    
    var body: some View {
        ZStack {
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
            
            // App Lock Overlay (Task 6.2.2)
            if isLocked && env.settings.requiresBiometrics {
                LockScreenView(isLocked: $isLocked)
                    .transition(.opacity)
            }
        }
        .preferredColorScheme(themePreference.colorScheme)
        .onChange(of: scenePhase) { oldPhase, newPhase in
            handleScenePhaseChange(oldPhase: oldPhase, newPhase: newPhase)
        }
        .task {
            // Check if app lock is enabled on initial launch
            if env.settings.requiresBiometrics {
                isLocked = true
            }
        }
    }
    
    // MARK: - Scene Phase Handling
    
    private func handleScenePhaseChange(oldPhase: ScenePhase, newPhase: ScenePhase) {
        switch newPhase {
        case .background:
            // Record when app went to background
            lastBackgroundTime = Date()
            
        case .active:
            // Check if we should lock the app
            guard env.settings.requiresBiometrics else { return }
            
            if env.settings.lockAfterInactivity {
                // Lock if app was in background for more than 1 minute
                if let lastTime = lastBackgroundTime {
                    let elapsed = Date().timeIntervalSince(lastTime)
                    if elapsed > 60 { // 1 minute
                        isLocked = true
                    }
                }
            } else {
                // Always lock when returning from background
                if oldPhase == .background || oldPhase == .inactive {
                    isLocked = true
                }
            }
            
        case .inactive:
            // Don't do anything special for inactive state
            break
            
        @unknown default:
            break
        }
    }
}

#Preview("Default - Light") {
    MainTabView()
        .modelContainer(PreviewContainer.withSampleData())
        .environment(AppEnvironment())
}

#Preview("Default - Dark") {
    MainTabView()
        .modelContainer(PreviewContainer.withSampleData())
        .environment(AppEnvironment())
        .preferredColorScheme(.dark)
}

#Preview("Empty Inventory") {
    MainTabView()
        .modelContainer(PreviewContainer.emptyInventory())
        .environment(AppEnvironment())
}

#Preview("Many Items") {
    MainTabView()
        .modelContainer(PreviewContainer.withManyItems(count: 50))
        .environment(AppEnvironment())
}

#Preview("Large Text") {
    MainTabView()
        .modelContainer(PreviewContainer.withSampleData())
        .environment(AppEnvironment())
        .environment(\.dynamicTypeSize, .xxxLarge)
}

#Preview("Small Text") {
    MainTabView()
        .modelContainer(PreviewContainer.withSampleData())
        .environment(AppEnvironment())
        .environment(\.dynamicTypeSize, .xSmall)
}
