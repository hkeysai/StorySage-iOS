#!/usr/bin/env python3
"""
Verify story counts per category and grade level
"""

import json

# Load the stories
with open('/Users/efmbpm2/repos/StorySage/iOS/StorySage/stories.json', 'r') as f:
    data = json.load(f)
    stories = data['stories']

# Count stories by category and grade level
counts = {}
for story in stories:
    cat = story['category']
    grade = story['gradeLevel']
    
    if cat not in counts:
        counts[cat] = {}
    
    if grade not in counts[cat]:
        counts[cat][grade] = 0
    
    counts[cat][grade] += 1

# Display results
print("Story counts by category and grade level:")
print("=" * 50)

for category, grades in sorted(counts.items()):
    print(f"\n{category}:")
    for grade, count in sorted(grades.items()):
        print(f"  {grade}: {count} stories")

# Total summary
print("\n" + "=" * 50)
print(f"Total stories: {len(stories)}")
print(f"Categories: {len(counts)}")

# Show Pre-K totals
prek_total = sum(grades.get('grade_prek', 0) for grades in counts.values())
print(f"Pre-K stories: {prek_total}")

# Show 2nd grade totals  
grade2_total = sum(grades.get('grade_2', 0) for grades in counts.values())
print(f"2nd Grade stories: {grade2_total}")