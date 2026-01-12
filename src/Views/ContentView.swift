import SwiftUI

/// Main content view with tab-based navigation using Liquid Glass design
struct ContentView: View {
    @Environment(AppState.self) private var appState
    @State private var selectedTab: Tab = .convert

    enum Tab: String, CaseIterable {
        case convert = "Convert"
        case history = "History"
        case settings = "Settings"

        var icon: String {
            switch self {
            case .convert: return "doc.text.magnifyingglass"
            case .history: return "clock.arrow.circlepath"
            case .settings: return "gear"
            }
        }
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            ForEach(Tab.allCases, id: \.self) { tab in
                Group {
                    switch tab {
                    case .convert:
                        ConvertView()
                    case .history:
                        HistoryView()
                    case .settings:
                        SettingsView()
                    }
                }
                .tabItem {
                    Label(tab.rawValue, systemImage: tab.icon)
                }
                .tag(tab)
            }
        }
        .tabBarMinimizeBehavior(.onScrollDown)
    }
}

#Preview {
    ContentView()
        .environment(AppState())
}
