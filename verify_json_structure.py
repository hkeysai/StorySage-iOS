#!/usr/bin/env python3
"""
Verify JSON structure matches what the iOS app expects
"""

import json
import os

def check_json_files():
    """Check if JSON files have the correct structure"""
    
    base_path = "/Users/efmbpm2/repos/StorySage/iOS/StorySage"
    
    # Check categories.json
    print("Checking categories.json...")
    categories_path = os.path.join(base_path, "categories.json")
    if os.path.exists(categories_path):
        with open(categories_path, 'r') as f:
            data = json.load(f)
            if "categories" in data:
                print(f"✅ categories.json has correct structure with {len(data['categories'])} categories")
                for cat in data['categories']:
                    print(f"  - {cat['name']} (id: {cat['id']})")
            else:
                print("❌ categories.json missing 'categories' key")
    else:
        print("❌ categories.json not found")
    
    # Check stories.json
    print("\nChecking stories.json...")
    stories_path = os.path.join(base_path, "stories.json")
    if os.path.exists(stories_path):
        with open(stories_path, 'r') as f:
            data = json.load(f)
            if "stories" in data:
                print(f"✅ stories.json has correct structure with {len(data['stories'])} stories")
                # Group by category
                by_category = {}
                for story in data['stories']:
                    cat = story.get('category', 'unknown')
                    if cat not in by_category:
                        by_category[cat] = []
                    by_category[cat].append(story['title'])
                
                print("\nStories by category:")
                for cat, titles in by_category.items():
                    print(f"  {cat}: {len(titles)} stories")
            else:
                print("❌ stories.json missing 'stories' key")
    else:
        print("❌ stories.json not found")
    
    # Check if files exist in multiple locations
    print("\nChecking file locations:")
    locations = [
        base_path,
        os.path.join(base_path, "Data"),
        os.path.join(base_path, "Resources/Data")
    ]
    
    for loc in locations:
        cat_exists = os.path.exists(os.path.join(loc, "categories.json"))
        stories_exists = os.path.exists(os.path.join(loc, "stories.json"))
        if cat_exists or stories_exists:
            print(f"  {loc}: categories={cat_exists}, stories={stories_exists}")

if __name__ == "__main__":
    check_json_files()