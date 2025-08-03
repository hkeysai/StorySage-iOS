#!/usr/bin/env swift

//
//  test_local_data.swift
//  StorySage
//
//  Created on 2025-08-03.
//
//  Test script to verify local data loading works correctly.
//

import Foundation

// Simple test to verify JSON files can be loaded

struct Category: Codable {
    let id: String
    let name: String
    let description: String
}

struct Story: Codable {
    let id: String
    let title: String
    let description: String
    let category: String
    let gradeLevel: String
    let audioUrl: String?
    
    enum CodingKeys: String, CodingKey {
        case id, title, description, category
        case gradeLevel = "grade_level"
        case audioUrl = "audio_url"
    }
}

func testLocalDataLoading() {
    print("Testing Local Data Loading")
    print("=" * 50)
    
    // Test categories loading
    if let categoriesURL = Bundle.main.url(forResource: "categories", withExtension: "json", subdirectory: "Data") {
        print("✅ Found categories.json")
        
        if let data = try? Data(contentsOf: categoriesURL),
           let categories = try? JSONDecoder().decode([Category].self, from: data) {
            print("✅ Loaded \(categories.count) categories")
            for category in categories.prefix(3) {
                print("  - \(category.name): \(category.id)")
            }
        } else {
            print("❌ Failed to decode categories")
        }
    } else {
        print("❌ categories.json not found")
    }
    
    print()
    
    // Test stories loading
    if let storiesURL = Bundle.main.url(forResource: "stories", withExtension: "json", subdirectory: "Data") {
        print("✅ Found stories.json")
        
        if let data = try? Data(contentsOf: storiesURL),
           let stories = try? JSONDecoder().decode([Story].self, from: data) {
            print("✅ Loaded \(stories.count) stories")
            
            // Group by grade level
            let gradeGroups = Dictionary(grouping: stories) { $0.gradeLevel }
            for (grade, storyList) in gradeGroups {
                print("  - \(grade): \(storyList.count) stories")
            }
            
            // Check audio files
            print("\nChecking audio files:")
            var foundCount = 0
            for story in stories.prefix(5) {
                if let audioFile = story.audioUrl {
                    let fileName = audioFile.replacingOccurrences(of: ".mp3", with: "")
                    if Bundle.main.url(forResource: fileName, withExtension: "mp3", subdirectory: "Audio") != nil {
                        print("  ✅ Found audio for: \(story.title)")
                        foundCount += 1
                    } else if Bundle.main.url(forResource: story.id, withExtension: "mp3", subdirectory: "Audio") != nil {
                        print("  ✅ Found audio by ID for: \(story.title)")
                        foundCount += 1
                    } else {
                        print("  ❌ Missing audio for: \(story.title)")
                    }
                }
            }
            print("\nFound \(foundCount) audio files out of \(min(5, stories.count)) checked")
            
        } else {
            print("❌ Failed to decode stories")
        }
    } else {
        print("❌ stories.json not found")
    }
    
    print()
    
    // List all MP3 files in bundle
    if let audioURLs = Bundle.main.urls(forResourcesWithExtension: "mp3", subdirectory: "Audio") {
        print("Found \(audioURLs.count) MP3 files in bundle:")
        for url in audioURLs.prefix(5) {
            print("  - \(url.lastPathComponent)")
        }
        if audioURLs.count > 5 {
            print("  ... and \(audioURLs.count - 5) more")
        }
    } else {
        print("❌ No MP3 files found in Audio directory")
    }
}

// Run the test
testLocalDataLoading()