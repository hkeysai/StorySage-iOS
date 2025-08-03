//
//  CategoryCard.swift
//  StorySage
//
//  Created on 2025-08-03.
//

import SwiftUI

struct CategoryCard: View {
    let category: Category
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 16) {
                // Category Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(LinearGradient(
                            colors: [category.themeColor.opacity(0.6), category.themeColor.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(height: 100)
                    
                    VStack(spacing: 8) {
                        Image(systemName: category.systemImageName)
                            .font(.title)
                            .foregroundColor(.white)
                        
                        Text("\(category.storyCount)")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text("stories")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.9))
                    }
                }
                
                // Category Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(category.name)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .lineLimit(1)
                    
                    Text(category.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    
                    // Grade level badge
                    Text(category.gradeLevelDisplayName)
                        .font(.caption2)
                        .fontWeight(.medium)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(category.themeColor.opacity(0.2))
                        .foregroundColor(category.themeColor)
                        .cornerRadius(4)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(16)
            .background(Color(.systemBackground))
            .cornerRadius(20)
            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    LazyVGrid(columns: [
        GridItem(.flexible()),
        GridItem(.flexible())
    ], spacing: 16) {
        ForEach(Category.sampleCategories.prefix(4)) { category in
            CategoryCard(category: category) {}
        }
    }
    .padding()
}