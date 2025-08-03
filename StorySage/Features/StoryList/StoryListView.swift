//
//  StoryListView.swift
//  StorySage
//
//  Created on 2025-08-03.
//

import SwiftUI

struct StoryListView: View {
    let category: Category
    
    @StateObject private var viewModel: StoryListViewModel
    @EnvironmentObject var router: NavigationRouter
    @EnvironmentObject var audioPlayer: LocalAudioPlayer
    
    init(category: Category) {
        self.category = category
        self._viewModel = StateObject(wrappedValue: StoryListViewModel(category: category))
    }
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                // Category Header
                categoryHeader
                
                // Story Grid
                storyGrid
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 100) // Space for mini player
        }
        .background(
            LinearGradient(
                colors: [category.themeColor.opacity(0.1), category.themeColor.opacity(0.05)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        )
        .navigationTitle(category.name)
        .navigationBarTitleDisplayMode(.large)
        .refreshable {
            await viewModel.refreshStories()
        }
        .task {
            await viewModel.loadStories()
        }
        .overlay(alignment: .bottom) {
            if audioPlayer.currentStory != nil {
                MiniPlayerView()
                    .padding(.horizontal, 16)
                    .padding(.bottom, 34)
            }
        }
        .searchable(text: $viewModel.searchText, prompt: "Search stories...")
    }
    
    // MARK: - Category Header
    
    private var categoryHeader: some View {
        VStack(spacing: 16) {
            // Category Info
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: category.systemImageName)
                            .font(.title2)
                            .foregroundColor(category.themeColor)
                        
                        Text(category.name)
                            .font(.title)
                            .fontWeight(.bold)
                    }
                    
                    Text(category.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                    
                    HStack {
                        Text(category.gradeLevelDisplayName)
                            .font(.caption)
                            .fontWeight(.medium)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(category.themeColor.opacity(0.2))
                            .cornerRadius(6)
                        
                        Text("\(viewModel.stories.count) stories")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                    }
                }
                
                Spacer()
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 16)
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
            
            // Filter Options
            if !viewModel.stories.isEmpty {
                filterOptions
            }
        }
    }
    
    // MARK: - Filter Options
    
    private var filterOptions: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                FilterChip(
                    title: "All",
                    isSelected: viewModel.selectedFilter == .all
                ) {
                    viewModel.setFilter(.all)
                }
                
                FilterChip(
                    title: "New",
                    isSelected: viewModel.selectedFilter == .new
                ) {
                    viewModel.setFilter(.new)
                }
                
                FilterChip(
                    title: "Favorites",
                    isSelected: viewModel.selectedFilter == .favorites
                ) {
                    viewModel.setFilter(.favorites)
                }
                
                FilterChip(
                    title: "Downloaded",
                    isSelected: viewModel.selectedFilter == .downloaded
                ) {
                    viewModel.setFilter(.downloaded)
                }
                
                FilterChip(
                    title: "Short (< 5 min)",
                    isSelected: viewModel.selectedFilter == .shortStories
                ) {
                    viewModel.setFilter(.shortStories)
                }
                
                FilterChip(
                    title: "Long (> 10 min)",
                    isSelected: viewModel.selectedFilter == .longStories
                ) {
                    viewModel.setFilter(.longStories)
                }
            }
            .padding(.horizontal, 20)
        }
        .padding(.horizontal, -20)
    }
    
    // MARK: - Story Grid
    
    private var storyGrid: some View {
        Group {
            if viewModel.isLoading {
                loadingView
            } else if viewModel.filteredStories.isEmpty {
                emptyStateView
            } else {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 16) {
                    ForEach(viewModel.filteredStories) { story in
                        StoryCard(story: story) {
                            router.navigate(to: .storyDetail(story))
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Loading View
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            
            Text("Loading stories...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 200)
    }
    
    // MARK: - Empty State View
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "book.closed")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text("No Stories Found")
                .font(.headline)
                .fontWeight(.semibold)
            
            Text("Try adjusting your filters or check back later for new stories.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            Button("Reset Filters") {
                viewModel.resetFilters()
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, minHeight: 200)
    }
}

// MARK: - Filter Chip

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.blue : Color(.systemGray6))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(16)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    NavigationStack {
        StoryListView(category: Category.sampleCategories[0])
            .environmentObject(NavigationRouter())
            .environmentObject(LocalAudioPlayer())
    }
}