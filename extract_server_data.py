#!/usr/bin/env python3
"""
Extract story data from StorySage server for iOS app embedding.
This script fetches all stories and categories from the API and saves them as JSON files.
"""

import json
import requests
import os
import shutil
from pathlib import Path

# Configuration
API_BASE_URL = "http://localhost:5010"
OUTPUT_DIR = Path("extracted_data")
AUDIO_SOURCE_DIR = Path("../audio_files")
IOS_PROJECT_DIR = Path("StorySage/Resources")

def fetch_api_data(endpoint):
    """Fetch data from API endpoint"""
    try:
        response = requests.get(f"{API_BASE_URL}{endpoint}")
        response.raise_for_status()
        data = response.json()
        return data.get('data', []) if 'data' in data else data
    except Exception as e:
        print(f"Error fetching {endpoint}: {e}")
        return None

def extract_categories():
    """Extract all categories"""
    print("Extracting categories...")
    categories = fetch_api_data("/api/categories")
    if categories:
        output_file = OUTPUT_DIR / "categories.json"
        with open(output_file, 'w') as f:
            json.dump(categories, f, indent=2)
        print(f"Saved {len(categories)} categories to {output_file}")
    return categories

def extract_stories():
    """Extract all stories"""
    print("Extracting stories...")
    stories = fetch_api_data("/api/stories")
    if stories:
        # Create audio mapping
        audio_mapping = {}
        
        # Update story audio URLs to local references
        for story in stories:
            if story.get('audio_url'):
                # Extract filename from URL
                audio_filename = story['audio_url'].split('/')[-1]
                # Map to actual file if it exists
                if 'audio_files' in story['audio_url']:
                    # This is already pointing to a file
                    parts = story['audio_url'].split('/')
                    if len(parts) > 1:
                        audio_filename = parts[-1]
                
                # Update to local reference
                story['local_audio_file'] = audio_filename
                audio_mapping[story['id']] = audio_filename
                
                # Keep original URL for reference
                story['original_audio_url'] = story['audio_url']
                story['audio_url'] = audio_filename  # Update to just filename
        
        output_file = OUTPUT_DIR / "stories.json"
        with open(output_file, 'w') as f:
            json.dump(stories, f, indent=2)
        print(f"Saved {len(stories)} stories to {output_file}")
        
        # Save audio mapping
        mapping_file = OUTPUT_DIR / "audio_mapping.json"
        with open(mapping_file, 'w') as f:
            json.dump(audio_mapping, f, indent=2)
        print(f"Saved audio mapping to {mapping_file}")
        
    return stories

def copy_audio_files():
    """Copy audio files to iOS project structure"""
    print("\nCopying audio files...")
    
    audio_dir = IOS_PROJECT_DIR / "Audio"
    audio_dir.mkdir(parents=True, exist_ok=True)
    
    if AUDIO_SOURCE_DIR.exists():
        mp3_files = list(AUDIO_SOURCE_DIR.glob("*.mp3"))
        print(f"Found {len(mp3_files)} MP3 files")
        
        for mp3_file in mp3_files:
            dest_file = audio_dir / mp3_file.name
            shutil.copy2(mp3_file, dest_file)
            print(f"Copied {mp3_file.name}")
        
        print(f"\nAll audio files copied to {audio_dir}")
    else:
        print(f"Warning: Audio source directory {AUDIO_SOURCE_DIR} not found")

def generate_metadata():
    """Generate metadata file with summary information"""
    print("\nGenerating metadata...")
    
    metadata = {
        "version": "1.0",
        "extraction_date": str(Path.cwd()),
        "categories_count": 0,
        "stories_count": 0,
        "total_audio_files": 0,
        "grade_levels": ["grade_prek", "grade_k", "grade_1", "grade_2"]
    }
    
    # Count categories
    categories_file = OUTPUT_DIR / "categories.json"
    if categories_file.exists():
        with open(categories_file) as f:
            categories = json.load(f)
            metadata["categories_count"] = len(categories)
    
    # Count stories
    stories_file = OUTPUT_DIR / "stories.json"
    if stories_file.exists():
        with open(stories_file) as f:
            stories = json.load(f)
            metadata["stories_count"] = len(stories)
            
            # Group by grade level
            grade_counts = {}
            for story in stories:
                grade = story.get('grade_level', 'unknown')
                grade_counts[grade] = grade_counts.get(grade, 0) + 1
            metadata["stories_by_grade"] = grade_counts
    
    # Count audio files
    audio_dir = IOS_PROJECT_DIR / "Audio"
    if audio_dir.exists():
        metadata["total_audio_files"] = len(list(audio_dir.glob("*.mp3")))
    
    metadata_file = OUTPUT_DIR / "metadata.json"
    with open(metadata_file, 'w') as f:
        json.dump(metadata, f, indent=2)
    print(f"Saved metadata to {metadata_file}")
    
    return metadata

def main():
    """Main extraction process"""
    print("StorySage Data Extraction Tool")
    print("=" * 50)
    
    # Create output directory
    OUTPUT_DIR.mkdir(exist_ok=True)
    IOS_PROJECT_DIR.mkdir(parents=True, exist_ok=True)
    
    # Extract data
    categories = extract_categories()
    stories = extract_stories()
    
    # Copy audio files
    copy_audio_files()
    
    # Generate metadata
    metadata = generate_metadata()
    
    # Copy JSON files to iOS project
    data_dir = IOS_PROJECT_DIR / "Data"
    data_dir.mkdir(exist_ok=True)
    
    for json_file in OUTPUT_DIR.glob("*.json"):
        dest_file = data_dir / json_file.name
        shutil.copy2(json_file, dest_file)
        print(f"Copied {json_file.name} to iOS project")
    
    print("\n" + "=" * 50)
    print("Extraction complete!")
    print(f"Categories: {metadata.get('categories_count', 0)}")
    print(f"Stories: {metadata.get('stories_count', 0)}")
    print(f"Audio files: {metadata.get('total_audio_files', 0)}")
    print(f"\nData saved to: {IOS_PROJECT_DIR}")

if __name__ == "__main__":
    main()