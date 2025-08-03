//
//  ContinueListeningCard.swift
//  StorySage
//
//  Created on 2025-08-03.
//

import SwiftUI

struct ContinueListeningCard: View {
    let story: Story
    let action: () -> Void
    
    // Mock progress for demo - in real app this would come from user data
    private let progress: Double = 0.65
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Story Artwork
                RoundedRectangle(cornerRadius: 12)
                    .fill(LinearGradient(
                        colors: [Color.green.opacity(0.6), Color.blue.opacity(0.6)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 80, height: 80)
                    .overlay(
                        Image(systemName: "book.fill")
                            .font(.title2)
                            .foregroundColor(.white)
                    )
                
                // Story Info
                VStack(alignment: .leading, spacing: 8) {
                    Text(story.title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    
                    Text("\(Int(progress * 100))% complete")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    // Progress Bar
                    ProgressView(value: progress)
                        .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                        .frame(height: 4)
                    
                    HStack {
                        Text(story.gradeLevelDisplayName)
                            .font(.caption2)
                            .fontWeight(.medium)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.2))
                            .foregroundColor(.blue)
                            .cornerRadius(4)
                        
                        Spacer()
                        
                        Text(story.formattedDuration)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // Continue Button
                Image(systemName: "play.circle.fill")
                    .font(.title)
                    .foregroundColor(.blue)
            }
            .padding(16)
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    ContinueListeningCard(story: Story.sampleStory) {}
        .padding()
}