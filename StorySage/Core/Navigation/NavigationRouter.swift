//
//  NavigationRouter.swift
//  StorySage
//
//  Created on 2025-08-03.
//

import SwiftUI

// MARK: - Navigation Destination

enum NavigationDestination: Hashable {
    case home
    case categoryStories(Category)
    case storyDetail(Story)
    case profile
    case settings
    case achievements
    case favorites
}

// MARK: - Navigation Router

@MainActor
class NavigationRouter: ObservableObject {
    @Published var path = NavigationPath()
    
    func navigate(to destination: NavigationDestination) {
        path.append(destination)
    }
    
    func navigateBack() {
        if !path.isEmpty {
            path.removeLast()
        }
    }
    
    func navigateToRoot() {
        path = NavigationPath()
    }
    
    func replace(with destination: NavigationDestination) {
        path.removeLast()
        path.append(destination)
    }
}

// MARK: - Navigation View Modifier

struct NavigationDestinationModifier: ViewModifier {
    @EnvironmentObject var router: NavigationRouter
    
    func body(content: Content) -> some View {
        content
            .navigationDestination(for: NavigationDestination.self) { destination in
                switch destination {
                case .home:
                    HomeView()
                    
                case .categoryStories(let category):
                    StoryListView(category: category)
                    
                case .storyDetail(let story):
                    StoryDetailView(story: story)
                    
                case .profile:
                    Text("Profile View - Coming Soon")
                        .navigationTitle("Profile")
                    
                case .settings:
                    Text("Settings View - Coming Soon")
                        .navigationTitle("Settings")
                    
                case .achievements:
                    Text("Achievements View - Coming Soon")
                        .navigationTitle("Achievements")
                    
                case .favorites:
                    Text("Favorites View - Coming Soon")
                        .navigationTitle("Favorites")
                }
            }
    }
}

extension View {
    func withNavigationDestinations() -> some View {
        modifier(NavigationDestinationModifier())
    }
}