#!/usr/bin/env python3
"""
Extract story data from existing StorySage system for iOS app
This creates a self-contained data package with all stories and audio files
"""

import json
import os
import shutil
from pathlib import Path

# Paths
BASE_DIR = Path("/Users/efmbpm2/repos/StorySage")
AUDIO_DIR = BASE_DIR / "audio_files"
OUTPUT_DIR = Path("/Users/efmbpm2/repos/StorySage/iOS/Resources")
OUTPUT_AUDIO_DIR = OUTPUT_DIR / "Audio"
OUTPUT_DATA_DIR = OUTPUT_DIR / "Data"

# Story data (extracted from existing system)
STORIES_DATA = {
    "stories": [
        # Pre-K Stories
        {
            "id": "1b1aa466-389e-48ca-bee3-143b8a128c6c",
            "title": "Benny's Big Feeling Day",
            "description": "Benny the Bear learns to identify and express his feelings with help from Spark the Firefly.",
            "category": "firefly-forest",
            "gradeLevel": "grade_prek",
            "duration": 420,
            "audioFile": "benny-big-feeling-day.mp3",
            "keyLessons": [
                "It's okay to feel different emotions",
                "Talking about feelings helps us feel better",
                "Everyone has big feelings sometimes",
                "Friends can help us understand our emotions",
                "There are healthy ways to express feelings"
            ],
            "tags": ["emotions", "feelings", "friendship", "self-awareness"]
        },
        {
            "id": "b6d8f66e-44e8-43d2-9cbc-e06896a8b072",
            "title": "Luna's Worried Night",
            "description": "Luna the Owl learns that sharing worries with friends makes them feel smaller.",
            "category": "firefly-forest",
            "gradeLevel": "grade_prek", 
            "duration": 420,
            "audioFile": "luna-worried-night.mp3",
            "keyLessons": [
                "It's normal to feel worried sometimes",
                "Sharing worries helps them feel smaller",
                "Friends want to help when we're scared",
                "Nighttime can feel less scary with support",
                "Talking about fears makes us braver"
            ],
            "tags": ["worry", "friendship", "nighttime", "courage"]
        },
        {
            "id": "1e579d53-26dd-4eb4-8444-94cfad047114",
            "title": "The Little Helpers",
            "description": "A group of young animals discover the joy of working together to help their community.",
            "category": "rainbow-rapids",
            "gradeLevel": "grade_prek",
            "duration": 420,
            "audioFile": "the-little-helpers.mp3",
            "keyLessons": [
                "Helping others feels good",
                "Even small acts of kindness matter",
                "Working together makes tasks easier",
                "Everyone can be a helper",
                "Kindness creates happiness"
            ],
            "tags": ["helping", "teamwork", "kindness", "community"]
        },
        {
            "id": "6cfb738d-a915-471b-9c2e-8c8507874202",
            "title": "Pip's First Friend",
            "description": "Pip the Penguin learns how to make friends by being kind and sharing.",
            "category": "rainbow-rapids",
            "gradeLevel": "grade_prek",
            "duration": 420,
            "audioFile": "pips-first-friend.mp3",
            "keyLessons": [
                "Making friends takes courage",
                "Sharing helps build friendships",
                "Being kind attracts friends",
                "Friends can be different from us",
                "Friendship makes us happy"
            ],
            "tags": ["friendship", "sharing", "kindness", "social-skills"]
        },
        {
            "id": "cfea38dc-5baa-4455-98ea-8b47224f48a3",
            "title": "Zoe's Brave Voice",
            "description": "Zoe the Zebra finds her courage to speak up when she needs help.",
            "category": "thunder-mountain",
            "gradeLevel": "grade_prek",
            "duration": 420,
            "audioFile": "zoes-brave-voice.mp3",
            "keyLessons": [
                "It's brave to ask for help",
                "Speaking up keeps us safe",
                "Adults want to help children",
                "Using our voice is powerful",
                "Being brave means trying"
            ],
            "tags": ["courage", "communication", "safety", "self-advocacy"]
        },
        {
            "id": "ed779ffa-a750-4844-be2e-8026f23d3789",
            "title": "The Tiny Climber",
            "description": "A small mountain goat proves that size doesn't determine what you can achieve.",
            "category": "thunder-mountain",
            "gradeLevel": "grade_prek",
            "duration": 420,
            "audioFile": "the-tiny-climber.mp3",
            "keyLessons": [
                "Size doesn't limit our abilities",
                "Trying hard leads to success",
                "Practice makes us better",
                "Believing in ourselves is important",
                "Small steps lead to big achievements"
            ],
            "tags": ["perseverance", "self-belief", "determination", "growth"]
        },
        {
            "id": "61cfdc9a-31e5-422b-a0c2-bcc6307ac4c1",
            "title": "Daisy's Sharing Day",
            "description": "Daisy the Deer discovers that sharing her toys makes playtime more fun.",
            "category": "starlight-meadow",
            "gradeLevel": "grade_prek",
            "duration": 420,
            "audioFile": "daisys-sharing-day.mp3",
            "keyLessons": [
                "Sharing makes play more fun",
                "Taking turns is fair",
                "Friends like to share too",
                "Sharing shows we care",
                "Playing together is better"
            ],
            "tags": ["sharing", "friendship", "play", "cooperation"]
        },
        {
            "id": "39cea39e-43e7-477c-949c-6167d9652bd3",
            "title": "Max's Helping Hands",
            "description": "Max the Mouse learns that his small hands can do big helpful things.",
            "category": "starlight-meadow",
            "gradeLevel": "grade_prek",
            "duration": 420,
            "audioFile": "maxs-helping-hands.mp3",
            "keyLessons": [
                "Small hands can help too",
                "Helping makes others smile",
                "There are many ways to help",
                "Being helpful feels good",
                "Everyone can contribute"
            ],
            "tags": ["helping", "kindness", "self-worth", "community"]
        },
        {
            "id": "730d8a07-cbc3-46d7-a410-43179dca1c6c",
            "title": "Rosie's Pet Rock",
            "description": "Rosie the Rabbit learns about responsibility by taking care of her pet rock.",
            "category": "compass-cliff",
            "gradeLevel": "grade_prek",
            "duration": 420,
            "audioFile": "rosies-pet-rock.mp3",
            "keyLessons": [
                "Pets need our care every day",
                "Being responsible means remembering",
                "Taking care of things is important",
                "Practice helps us learn",
                "Even pretend pets teach us"
            ],
            "tags": ["responsibility", "caring", "routine", "learning"]
        },
        {
            "id": "f52b7e28-941e-457f-9a7a-933f569c26c8",
            "title": "Sam's Morning Jobs",
            "description": "Sam the Squirrel creates a morning routine that helps him start each day right.",
            "category": "compass-cliff",
            "gradeLevel": "grade_prek",
            "duration": 420,
            "audioFile": "sams-morning-jobs.mp3",
            "keyLessons": [
                "Routines help us remember",
                "Morning jobs prepare our day",
                "Being organized feels good",
                "Small tasks are important",
                "We can do things ourselves"
            ],
            "tags": ["routine", "independence", "organization", "self-care"]
        },
        {
            "id": "9f96f7d0-30d7-459e-89d5-e757ec88998e",
            "title": "Echo's First Big Jump",
            "description": "Echo the Eagle learns that trying new things can be scary but rewarding.",
            "category": "compass-cliff",
            "gradeLevel": "grade_prek",
            "duration": 420,
            "audioFile": "echos-first-big-jump.mp3",
            "keyLessons": [
                "Trying new things is brave",
                "It's okay to feel scared",
                "Practice builds confidence",
                "Adults help us stay safe",
                "Success feels amazing"
            ],
            "tags": ["courage", "growth", "trying", "confidence"]
        },
        # 2nd Grade Stories
        {
            "id": "2beecb7b-51a6-4428-8a22-6c3cc050cbea",
            "title": "The Glowing Map Mystery",
            "description": "Alex and friends solve the mystery of a magical map that appears in Firefly Forest.",
            "category": "firefly-forest",
            "gradeLevel": "grade_2",
            "duration": 600,
            "audioFile": "the-glowing-map-mystery.mp3",
            "keyLessons": [
                "Teamwork helps solve problems",
                "Observation skills are important",
                "Maps help us find our way",
                "Mystery solving requires patience",
                "Friends have different strengths"
            ],
            "tags": ["mystery", "teamwork", "problem-solving", "adventure"]
        },
        {
            "id": "bf3dd02e-ca4d-403d-822e-bdafb98a15d1",
            "title": "Emotions in the Mist",
            "description": "Journey through the forest learning about complex emotions and empathy.",
            "category": "firefly-forest",
            "gradeLevel": "grade_2",
            "duration": 600,
            "audioFile": "emotions-in-the-mist.mp3",
            "keyLessons": [
                "Emotions can be complex",
                "Empathy means understanding others",
                "It's okay to have mixed feelings",
                "Talking helps process emotions",
                "Everyone experiences emotions differently"
            ],
            "tags": ["emotions", "empathy", "self-awareness", "understanding"]
        },
        {
            "id": "82ee68c4-98e5-4704-bf3d-2305e1fb8b3e",
            "title": "The Lost Firefly Prince",
            "description": "Help reunite a lost firefly prince with his family through kindness and clever thinking.",
            "category": "firefly-forest",
            "gradeLevel": "grade_2",
            "duration": 600,
            "audioFile": "the-lost-firefly-prince.mp3",
            "keyLessons": [
                "Helping others is rewarding",
                "Creative thinking solves problems",
                "Persistence leads to success",
                "Small creatures need gentleness",
                "Family connections are precious"
            ],
            "tags": ["helping", "problem-solving", "family", "kindness"]
        },
        {
            "id": "8b593160-6e12-47f0-8d05-0c77b80ae6f3",
            "title": "Building Bridges Together",
            "description": "Learn about cooperation as forest friends work together to build a bridge.",
            "category": "rainbow-rapids",
            "gradeLevel": "grade_2",
            "duration": 600,
            "audioFile": "building-bridges-together.mp3",
            "keyLessons": [
                "Cooperation achieves big goals",
                "Planning before building is smart",
                "Everyone's ideas have value",
                "Working together is efficient",
                "Celebrating success together"
            ],
            "tags": ["cooperation", "planning", "teamwork", "achievement"]
        },
        {
            "id": "8985951e-1311-4794-9b39-3e7b32847d88",
            "title": "The Great Raft Race",
            "description": "Teams compete in a raft race while learning about fairness and good sportsmanship.",
            "category": "rainbow-rapids",
            "gradeLevel": "grade_2",
            "duration": 600,
            "audioFile": "the-great-raft-race.mp3",
            "keyLessons": [
                "Fair play makes games fun",
                "Winning isn't everything",
                "Good sportsmanship matters",
                "Teamwork beats competition",
                "Celebrating others' success"
            ],
            "tags": ["sportsmanship", "fairness", "competition", "teamwork"]
        },
        {
            "id": "9d44887b-9d0c-4716-a440-e1379a3d7e10",
            "title": "Rainbow Fish School",
            "description": "Attend an underwater school where fish learn about colors, patterns, and diversity.",
            "category": "rainbow-rapids",
            "gradeLevel": "grade_2",
            "duration": 600,
            "audioFile": "rainbow-fish-school.mp3",
            "keyLessons": [
                "Diversity makes life colorful",
                "Everyone learns differently",
                "School is for discovering",
                "Questions help us learn",
                "Differences are beautiful"
            ],
            "tags": ["diversity", "learning", "school", "acceptance"]
        },
        {
            "id": "3d7d7975-790a-460a-a08b-87365fc57420",
            "title": "Peak Performance Challenge",
            "description": "Join young climbers learning about goal-setting and perseverance on Thunder Mountain.",
            "category": "thunder-mountain",
            "gradeLevel": "grade_2",
            "duration": 600,
            "audioFile": "peak-performance-challenge.mp3",
            "keyLessons": [
                "Goals guide our efforts",
                "Breaking big tasks helps",
                "Perseverance conquers challenges",
                "Progress takes time",
                "Celebrating milestones matters"
            ],
            "tags": ["goals", "perseverance", "achievement", "planning"]
        },
        {
            "id": "9469d3f8-9871-4064-b433-a318a2cea71e",
            "title": "Courage Under Pressure",
            "description": "Learn how mountain animals stay brave during a surprise storm.",
            "category": "thunder-mountain",
            "gradeLevel": "grade_2",
            "duration": 600,
            "audioFile": "courage-under-pressure.mp3",
            "keyLessons": [
                "Courage means acting despite fear",
                "Helping others shows bravery",
                "Staying calm helps thinking",
                "Preparation prevents panic",
                "Community provides strength"
            ],
            "tags": ["courage", "emergency", "helping", "community"]
        },
        {
            "id": "b5e283a5-cac6-426b-8333-37c9e3570643",
            "title": "The Determination Games",
            "description": "Annual games teach young animals about trying hard and not giving up.",
            "category": "thunder-mountain",
            "gradeLevel": "grade_2",
            "duration": 600,
            "audioFile": "the-determination-games.mp3",
            "keyLessons": [
                "Determination drives success",
                "Effort matters more than winning",
                "Learning from failure helps",
                "Supporting others builds character",
                "Personal best is the goal"
            ],
            "tags": ["determination", "effort", "sportsmanship", "growth"]
        },
        {
            "id": "730c85c9-5419-4c4f-a4bb-cbb3c7e9c234",
            "title": "Star Catchers Club",
            "description": "Join a club that teaches patience and wonder while stargazing in the meadow.",
            "category": "starlight-meadow",
            "gradeLevel": "grade_2",
            "duration": 600,
            "audioFile": "star-catchers-club.mp3",
            "keyLessons": [
                "Patience reveals beauty",
                "Wonder fuels curiosity",
                "Science explains nature",
                "Quiet observation teaches",
                "Sharing discoveries doubles joy"
            ],
            "tags": ["patience", "science", "wonder", "observation"]
        },
        {
            "id": "92e0d470-39ae-48cf-aede-c87277fa3c63",
            "title": "The Gratitude Garden",
            "description": "Learn how expressing gratitude helps friendships grow like flowers in a garden.",
            "category": "starlight-meadow",
            "gradeLevel": "grade_2",
            "duration": 600,
            "audioFile": "the-gratitude-garden.mp3",
            "keyLessons": [
                "Gratitude strengthens friendships",
                "Saying thanks shows appreciation",
                "Small gestures mean a lot",
                "Gratitude creates happiness",
                "Kindness grows when shared"
            ],
            "tags": ["gratitude", "friendship", "kindness", "appreciation"]
        },
        {
            "id": "a1c3a456-2e2f-4b9e-b234-456def789abc",
            "title": "Moonlight Wishes",
            "description": "Discover how working toward wishes teaches the difference between needs and wants.",
            "category": "starlight-meadow",
            "gradeLevel": "grade_2",
            "duration": 600,
            "audioFile": "moonlight-wishes.mp3",
            "keyLessons": [
                "Wishes require work",
                "Needs differ from wants",
                "Planning helps achieve goals",
                "Patience brings rewards",
                "Helping others' wishes matters"
            ],
            "tags": ["wishes", "goals", "patience", "helping"]
        },
        {
            "id": "b2d4b567-3f3f-5c9f-c345-567ef890bcd",
            "title": "Direction Detective Academy",
            "description": "Train to become a direction detective, learning navigation and problem-solving skills.",
            "category": "compass-cliff",
            "gradeLevel": "grade_2",
            "duration": 600,
            "audioFile": "direction-detective-academy.mp3",
            "keyLessons": [
                "Directions help us navigate",
                "Clues lead to solutions",
                "Maps are helpful tools",
                "Observation skills matter",
                "Teaching others reinforces learning"
            ],
            "tags": ["navigation", "problem-solving", "learning", "teaching"]
        },
        {
            "id": "c3e5c678-4f4f-6d9f-d456-678f901cde",
            "title": "Responsibility Rangers",
            "description": "Join the rangers learning about environmental responsibility and caring for nature.",
            "category": "compass-cliff",
            "gradeLevel": "grade_2",
            "duration": 600,
            "audioFile": "responsibility-rangers.mp3",
            "keyLessons": [
                "Nature needs our protection",
                "Small actions have big impacts",
                "Responsibility means caring",
                "Working together multiplies effort",
                "Future generations depend on us"
            ],
            "tags": ["responsibility", "environment", "caring", "teamwork"]
        },
        {
            "id": "d4f6d789-5f5f-7e9f-e567-789012def",
            "title": "Focus Finding Mission",
            "description": "Learn concentration techniques while helping solve the mystery of the missing compass.",
            "category": "compass-cliff",
            "gradeLevel": "grade_2",
            "duration": 600,
            "audioFile": "focus-finding-mission.mp3",
            "keyLessons": [
                "Focus helps solve problems",
                "Distractions can be managed",
                "Breaking tasks helps concentration",
                "Deep breathing aids focus",
                "Practice improves attention"
            ],
            "tags": ["focus", "concentration", "problem-solving", "mindfulness"]
        },
        {
            "id": "e5f7e890-6f6f-8f9f-f678-890123ef0",
            "title": "Future Leaders Camp",
            "description": "Experience leadership lessons through fun camp activities and challenges.",
            "category": "compass-cliff",
            "gradeLevel": "grade_2",
            "duration": 600,
            "audioFile": "future-leaders-camp.mp3",
            "keyLessons": [
                "Leaders serve others",
                "Good leaders listen first",
                "Leadership means responsibility",
                "Everyone can lead sometimes",
                "Leaders learn from mistakes"
            ],
            "tags": ["leadership", "responsibility", "service", "growth"]
        }
    ]
}

CATEGORIES_DATA = {
    "categories": [
        {
            "id": "firefly-forest",
            "name": "Firefly Forest",
            "description": "Magical forest adventures with glowing friends",
            "color": "#4CAF50",
            "icon": "✨",
            "gradeLevels": ["grade_prek", "grade_2"]
        },
        {
            "id": "rainbow-rapids", 
            "name": "Rainbow Rapids",
            "description": "Colorful water adventures and teamwork",
            "color": "#2196F3",
            "icon": "🌈",
            "gradeLevels": ["grade_prek", "grade_2"]
        },
        {
            "id": "thunder-mountain",
            "name": "Thunder Mountain",
            "description": "Brave mountain climbing and courage tales",
            "color": "#FF5722",
            "icon": "⛰️",
            "gradeLevels": ["grade_prek", "grade_2"]
        },
        {
            "id": "starlight-meadow",
            "name": "Starlight Meadow",
            "description": "Peaceful meadow stories about kindness",
            "color": "#9C27B0",
            "icon": "⭐",
            "gradeLevels": ["grade_prek", "grade_2"]
        },
        {
            "id": "compass-cliff",
            "name": "Compass Cliff",
            "description": "Navigation adventures and responsibility",
            "color": "#607D8B",
            "icon": "🧭",
            "gradeLevels": ["grade_prek", "grade_2"]
        }
    ]
}

def create_directories():
    """Create output directory structure"""
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    OUTPUT_AUDIO_DIR.mkdir(parents=True, exist_ok=True)
    OUTPUT_DATA_DIR.mkdir(parents=True, exist_ok=True)
    print(f"✅ Created directory structure at {OUTPUT_DIR}")

def copy_audio_files():
    """Copy and rename audio files"""
    audio_map = {story['id']: story['audioFile'] for story in STORIES_DATA['stories']}
    
    copied = 0
    missing = []
    
    for old_id, new_name in audio_map.items():
        old_path = AUDIO_DIR / f"{old_id}.mp3"
        new_path = OUTPUT_AUDIO_DIR / new_name
        
        if old_path.exists():
            shutil.copy2(old_path, new_path)
            copied += 1
            print(f"✅ Copied: {new_name}")
        else:
            missing.append((old_id, new_name))
            print(f"❌ Missing: {old_path}")
    
    print(f"\n📊 Audio Summary: {copied} copied, {len(missing)} missing")
    return copied, missing

def create_json_files():
    """Create JSON data files"""
    # Save stories
    stories_path = OUTPUT_DATA_DIR / "stories.json"
    with open(stories_path, 'w') as f:
        json.dump(STORIES_DATA, f, indent=2)
    print(f"✅ Created: {stories_path}")
    
    # Save categories
    categories_path = OUTPUT_DATA_DIR / "categories.json"
    with open(categories_path, 'w') as f:
        json.dump(CATEGORIES_DATA, f, indent=2)
    print(f"✅ Created: {categories_path}")
    
    # Create metadata file
    metadata = {
        "version": "1.0",
        "totalStories": len(STORIES_DATA['stories']),
        "totalCategories": len(CATEGORIES_DATA['categories']),
        "gradeLevels": ["grade_prek", "grade_2"],
        "totalDuration": sum(s['duration'] for s in STORIES_DATA['stories']),
        "lastUpdated": "2025-08-03"
    }
    
    metadata_path = OUTPUT_DATA_DIR / "metadata.json"
    with open(metadata_path, 'w') as f:
        json.dump(metadata, f, indent=2)
    print(f"✅ Created: {metadata_path}")

def create_resource_list():
    """Create a list of all resources for Xcode"""
    resources = []
    
    # Add audio files
    for story in STORIES_DATA['stories']:
        resources.append(f"Audio/{story['audioFile']}")
    
    # Add data files
    resources.extend([
        "Data/stories.json",
        "Data/categories.json", 
        "Data/metadata.json"
    ])
    
    # Save resource list
    resource_list_path = OUTPUT_DIR / "resources.txt"
    with open(resource_list_path, 'w') as f:
        f.write("\n".join(resources))
    print(f"✅ Created resource list: {resource_list_path}")

def main():
    print("🚀 Starting StorySage iOS Data Extraction\n")
    
    # Create directories
    create_directories()
    
    # Copy audio files
    print("\n📁 Copying audio files...")
    copied, missing = copy_audio_files()
    
    # Create JSON files
    print("\n📝 Creating data files...")
    create_json_files()
    
    # Create resource list
    print("\n📋 Creating resource list...")
    create_resource_list()
    
    # Summary
    print("\n✨ Extraction Complete!")
    print(f"📁 Output directory: {OUTPUT_DIR}")
    print(f"🎵 Audio files: {copied}")
    print(f"📊 Total size: ~{copied * 5}MB")
    
    if missing:
        print(f"\n⚠️  Missing {len(missing)} audio files - you may need to generate these")

if __name__ == "__main__":
    main()