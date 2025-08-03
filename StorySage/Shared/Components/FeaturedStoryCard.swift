//
//  FeaturedStoryCard.swift
//  StorySage
//
//  Created on 2025-08-03.
//

import SwiftUI

struct FeaturedStoryCard: View {
    let story: Story
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 0) {
                // Featured Story Artwork
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(LinearGradient(
                            colors: [Color.orange.opacity(0.7), Color.red.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(height: 140)
                    
                    VStack(spacing: 8) {
                        Image(systemName: "star.fill")
                            .font(.title)
                            .foregroundColor(.white)
                        
                        Text("FEATURED")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.white.opacity(0.3))
                            .cornerRadius(8)
                    }
                    
                    // Play button overlay
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Button(action: action) {
                                Image(systemName: "play.circle.fill")
                                    .font(.title)
                                    .foregroundColor(.white)
                                    .background(Circle().fill(Color.black.opacity(0.3)))
                            }
                            .padding(.trailing, 16)
                            .padding(.bottom, 16)
                        }
                    }
                }
                
                // Story Details
                VStack(alignment: .leading, spacing: 8) {
                    Text(story.title)
                        .font(.headline)
                        .fontWeight(.bold)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    
                    Text(story.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(3)
                        .multilineTextAlignment(.leading)
                    
                    HStack {
                        Label(story.gradeLevelDisplayName, systemImage: "graduationcap.fill")
                        Spacer()
                        Label(story.formattedDuration, systemImage: "clock.fill")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(Color(.systemBackground))
            .cornerRadius(20)
            .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    FeaturedStoryCard(story: Story.sampleStory) {}
        .padding()
}