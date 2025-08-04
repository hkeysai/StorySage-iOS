#!/usr/bin/env python3
"""
Add JSON files to Xcode project
"""

import re

def add_json_files_to_project(project_file):
    """Add JSON files to the Xcode project"""
    
    # Read the project file
    with open(project_file, 'r') as f:
        content = f.read()
    
    # JSON files to add
    json_files = ["categories.json", "metadata.json", "stories.json"]
    
    # Find where to insert new build file entries (after the last mp3 entry)
    last_mp3_pattern = r'(FB73DAAA2E40352300E48998 /\* benny-big-feeling-day\.mp3 in Resources \*/ = \{[^}]+\};\n)'
    match = re.search(last_mp3_pattern, content)
    if not match:
        print("Could not find insertion point")
        return
    
    insert_point = match.end()
    
    # Generate build file entries
    build_entries = []
    file_entries = []
    resource_entries = []
    
    # Generate IDs (simple increment from last known ID)
    base_id = "FB73DAAB2E40352300E48998"
    file_base_id = "FB73DA9B2E40352300E48998"
    
    for i, json_file in enumerate(json_files):
        # Increment IDs
        build_id = base_id[:-1] + str(int(base_id[-1]) + i)
        file_id = file_base_id[:-1] + str(int(file_base_id[-1]) + i + 20)
        
        # Build file entry
        build_entry = f'\t\t{build_id} /* {json_file} in Resources */ = {{isa = PBXBuildFile; fileRef = {file_id} /* {json_file} */; }};'
        build_entries.append(build_entry)
        
        # File reference entry
        file_entry = f'\t\t{file_id} /* {json_file} */ = {{isa = PBXFileReference; lastKnownFileType = text.json; path = {json_file}; sourceTree = "<group>"; }};'
        file_entries.append(file_entry)
        
        # Resource entry for Copy Bundle Resources
        resource_entry = f'\t\t\t\t{build_id} /* {json_file} in Resources */,'
        resource_entries.append(resource_entry)
    
    # Insert build file entries
    new_content = content[:insert_point] + '\n'.join(build_entries) + '\n' + content[insert_point:]
    
    # Insert file reference entries (find where mp3 file refs end)
    file_ref_pattern = r'(FB73DA962E40352300E48998 /\* zoes-brave-voice\.mp3 \*/ = \{[^}]+\};\n)'
    match = re.search(file_ref_pattern, new_content)
    if match:
        insert_point = match.end()
        new_content = new_content[:insert_point] + '\n'.join(file_entries) + '\n' + new_content[insert_point:]
    
    # Add to Resources build phase
    resources_pattern = r'(FB73DAAA2E40352300E48998 /\* benny-big-feeling-day\.mp3 in Resources \*/,)'
    match = re.search(resources_pattern, new_content)
    if match:
        insert_point = match.end()
        new_content = new_content[:insert_point] + '\n' + '\n'.join(resource_entries) + new_content[insert_point:]
    
    # Add files to the group (where mp3 files are listed)
    group_pattern = r'(FB73DA962E40352300E48998 /\* zoes-brave-voice\.mp3 \*/,)'
    match = re.search(group_pattern, new_content)
    if match:
        insert_point = match.end()
        group_entries = [f'\t\t\t\t{file_base_id[:-1] + str(int(file_base_id[-1]) + i + 20)} /* {json_file} */,' for i, json_file in enumerate(json_files)]
        new_content = new_content[:insert_point] + '\n' + '\n'.join(group_entries) + new_content[insert_point:]
    
    # Write back
    with open(project_file, 'w') as f:
        f.write(new_content)
    
    print("✅ Added JSON files to project")
    print("\nNext steps:")
    print("1. Open Xcode")
    print("2. Clean build folder (Shift+Cmd+K)")
    print("3. Build and run (Cmd+R)")

if __name__ == "__main__":
    project_file = "/Users/efmbpm2/repos/StorySage/iOS/StorySage.xcodeproj/project.pbxproj"
    add_json_files_to_project(project_file)