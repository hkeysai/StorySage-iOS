#!/usr/bin/env swift

import Foundation

// Define the structures
struct CategoriesFile: Codable {
    let categories: [LocalCategory]
}

struct LocalCategory: Codable {
    let id: String
    let name: String
    let description: String
    let color: String
    let icon: String
    let gradeLevels: [String]
}

// Load and test
let jsonPath = "/Users/efmbpm2/repos/StorySage/iOS/StorySage/categories.json"
do {
    let data = try Data(contentsOf: URL(fileURLWithPath: jsonPath))
    let decoder = JSONDecoder()
    let categoriesFile = try decoder.decode(CategoriesFile.self, from: data)
    
    print("✅ Successfully decoded \(categoriesFile.categories.count) categories")
    
    for cat in categoriesFile.categories {
        print("\n\(cat.name) (id: \(cat.id))")
        print("  Grade levels: \(cat.gradeLevels.joined(separator: ", "))")
        print("  Description: \(cat.description)")
    }
    
    // Show expanded categories (one per grade level)
    print("\n📚 Expanded categories by grade level:")
    var expandedCount = 0
    for cat in categoriesFile.categories {
        for grade in cat.gradeLevels {
            expandedCount += 1
            print("  - \(cat.name) for \(grade)")
        }
    }
    print("\nTotal expanded categories: \(expandedCount)")
    
} catch {
    print("❌ Error: \(error)")
}