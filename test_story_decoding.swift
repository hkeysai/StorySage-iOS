#!/usr/bin/env swift

import Foundation

// Story structures
struct StoriesFile: Codable {
    let stories: [LocalStory]
}

struct LocalStory: Codable {
    let id: String
    let title: String
    let description: String
    let category: String
    let gradeLevel: String
    let duration: Int
    let audioFile: String
    let keyLessons: [String]
    let tags: [String]
}

// Test decoding
let jsonPath = "/Users/efmbpm2/repos/StorySage/iOS/StorySage/stories.json"
do {
    let data = try Data(contentsOf: URL(fileURLWithPath: jsonPath))
    let decoder = JSONDecoder()
    let storiesFile = try decoder.decode(StoriesFile.self, from: data)
    
    print("✅ Successfully decoded \(storiesFile.stories.count) stories")
    
    // Show first few stories
    for (index, story) in storiesFile.stories.prefix(3).enumerated() {
        print("\n\(index + 1). \(story.title)")
        print("   Category: \(story.category)")
        print("   Grade: \(story.gradeLevel)")
        print("   Audio: \(story.audioFile)")
    }
    
} catch {
    print("❌ Decoding error: \(error)")
    
    // Try to decode as raw JSON to see structure
    if let data = try? Data(contentsOf: URL(fileURLWithPath: jsonPath)),
       let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
       let stories = json["stories"] as? [[String: Any]],
       let firstStory = stories.first {
        print("\nFirst story structure:")
        for (key, value) in firstStory {
            print("  \(key): \(type(of: value))")
        }
    }
}