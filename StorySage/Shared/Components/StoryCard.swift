//
//  StoryCard.swift
//  StorySage
//
//  Created on 2025-08-03.
//

import SwiftUI

struct StoryCard: View {
    let story: Story
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                // Story Artwork
                RoundedRectangle(cornerRadius: 12)
                    .fill(LinearGradient(
                        colors: [Color.blue.opacity(0.6), Color.purple.opacity(0.6)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .aspectRatio(1, contentMode: .fit)
                    .overlay(
                        VStack {
                            Image(systemName: "book.fill")
                                .font(.title)
                                .foregroundColor(.white)
                            
                            if story.isDownloaded {
                                Image(systemName: "arrow.down.circle.fill")
                                    .font(.caption)
                                    .foregroundColor(.green)
                                    .padding(.top, 4)
                            }
                        }
                    )
                
                // Story Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(story.title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    
                    Text(story.formattedDuration)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    // Grade level badge
                    Text(story.gradeLevelDisplayName)
                        .font(.caption2)
                        .fontWeight(.medium)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.2))
                        .foregroundColor(.blue)
                        .cornerRadius(4)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    VStack {
        HStack {
            StoryCard(story: Story.sampleStory) {}
                .frame(width: 160)
            
            StoryCard(story: Story.sampleStories[1]) {}
                .frame(width: 160)
        }
    }
    .padding()
}