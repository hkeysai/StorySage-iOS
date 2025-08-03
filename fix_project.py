#!/usr/bin/env python3
"""
Fix StorySage iOS project file by:
1. Removing references to deleted files
2. Adding references to new local implementation files
3. Creating proper group structure
"""

import re
import uuid

def generate_pbx_id():
    """Generate a 24-character hex ID for PBX objects"""
    return uuid.uuid4().hex[:24].upper()

def fix_project_file():
    with open('StorySage.xcodeproj/project.pbxproj', 'r') as f:
        content = f.read()
    
    # Files to remove
    files_to_remove = [
        'NetworkManager.swift',
        'AudioPlayer.swift',
        'AudioCacheManager.swift',
        'APIEndpoint.swift',
        'APIError.swift'
    ]
    
    # Extract IDs for files to remove
    file_ids_to_remove = {}
    for filename in files_to_remove:
        # Find file reference ID
        match = re.search(rf'(\w{{24}}) /\* {re.escape(filename)} \*/', content)
        if match:
            file_ids_to_remove[filename] = match.group(1)
            print(f"Found {filename} with ID: {match.group(1)}")
    
    # Remove from PBXBuildFile section
    for filename, file_id in file_ids_to_remove.items():
        # Remove build file entries
        pattern = rf'\s*\w{{24}} /\* {re.escape(filename)} in Sources \*/ = {{isa = PBXBuildFile; fileRef = {file_id} /\* {re.escape(filename)} \*/; }};'
        content = re.sub(pattern, '', content)
        print(f"Removed build file entry for {filename}")
    
    # Remove from PBXFileReference section
    for filename, file_id in file_ids_to_remove.items():
        pattern = rf'\s*{file_id} /\* {re.escape(filename)} \*/ = {{isa = PBXFileReference; [^}}]+}};'
        content = re.sub(pattern, '', content)
        print(f"Removed file reference for {filename}")
    
    # Remove from Sources build phase
    for filename, file_id in file_ids_to_remove.items():
        pattern = rf'\s*\w{{24}} /\* {re.escape(filename)} in Sources \*/,'
        content = re.sub(pattern, '', content)
        print(f"Removed from Sources build phase: {filename}")
    
    # Remove from group listings
    for filename, file_id in file_ids_to_remove.items():
        pattern = rf'\s*{file_id} /\* {re.escape(filename)} \*/,'
        content = re.sub(pattern, '', content)
        print(f"Removed from groups: {filename}")
    
    # Now add new files
    new_files = [
        ('LocalAudioPlayer.swift', 'Core/Audio'),
        ('LocalDataProvider.swift', 'Core/Data'),
        ('LocalDataManager.swift', 'Core/Data'),
        ('CoreDataManager.swift', 'Core/Data'),
        ('LocalHomeViewModel.swift', 'Features/Home'),
        ('CategoryCard.swift', 'Shared/Components'),
        ('ContinueListeningCard.swift', 'Shared/Components'),
        ('FeaturedStoryCard.swift', 'Shared/Components'),
        ('MiniPlayerView.swift', 'Shared/Components'),
        ('StoryCard.swift', 'Shared/Components'),
    ]
    
    # Generate IDs for new files
    new_file_ids = {}
    build_file_ids = {}
    for filename, path in new_files:
        file_id = generate_pbx_id()
        build_id = generate_pbx_id()
        new_file_ids[filename] = file_id
        build_file_ids[filename] = build_id
        print(f"Generated IDs for {filename}: file={file_id}, build={build_id}")
    
    # Add to PBXBuildFile section
    build_file_section = re.search(r'(/\* Begin PBXBuildFile section \*/\n)(.*?)(/\* End PBXBuildFile section \*/)', content, re.DOTALL)
    if build_file_section:
        new_build_entries = ""
        for filename, path in new_files:
            new_build_entries += f"\t\t{build_file_ids[filename]} /* {filename} in Sources */ = {{isa = PBXBuildFile; fileRef = {new_file_ids[filename]} /* {filename} */; }};\n"
        
        # Insert at the end of the section
        content = content.replace(build_file_section.group(0), 
                                build_file_section.group(1) + build_file_section.group(2) + new_build_entries + build_file_section.group(3))
    
    # Add to PBXFileReference section
    file_ref_section = re.search(r'(/\* Begin PBXFileReference section \*/\n)(.*?)(/\* End PBXFileReference section \*/)', content, re.DOTALL)
    if file_ref_section:
        new_file_entries = ""
        for filename, path in new_files:
            new_file_entries += f"\t\t{new_file_ids[filename]} /* {filename} */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = {filename}; sourceTree = \"<group>\"; }};\n"
        
        content = content.replace(file_ref_section.group(0),
                                file_ref_section.group(1) + file_ref_section.group(2) + new_file_entries + file_ref_section.group(3))
    
    # Add to Sources build phase
    sources_section = re.search(r'(3D0A3F182B5F1234000A1B2C /\* Sources \*/ = \{[^}]+files = \(\n)(.*?)(\s*\);\s*runOnlyForDeploymentPostprocessing)', content, re.DOTALL)
    if sources_section:
        new_source_entries = ""
        for filename, path in new_files:
            new_source_entries += f"\t\t\t\t{build_file_ids[filename]} /* {filename} in Sources */,\n"
        
        content = content.replace(sources_section.group(0),
                                sources_section.group(1) + sources_section.group(2) + new_source_entries + sources_section.group(3))
    
    # Create Data group if it doesn't exist
    data_group_id = generate_pbx_id()
    
    # Find Core group and add Data subgroup
    core_group_match = re.search(r'(3D0A3F5A2B5F1350000A1B2C /\* Core \*/ = \{[^}]+children = \(\n)(.*?)(\s*\);)', content, re.DOTALL)
    if core_group_match:
        # Add Data group reference to Core's children
        new_children = core_group_match.group(2).rstrip()
        if not re.search(r'/\* Data \*/', new_children):
            new_children += f",\n\t\t\t\t{data_group_id} /* Data */"
        content = content.replace(core_group_match.group(0),
                                core_group_match.group(1) + new_children + core_group_match.group(3))
        
        # Add Data group definition after Core group
        data_group_def = f"""
\t\t{data_group_id} /* Data */ = {{
\t\t\tisa = PBXGroup;
\t\t\tchildren = (
\t\t\t\t{new_file_ids['LocalDataProvider.swift']} /* LocalDataProvider.swift */,
\t\t\t\t{new_file_ids['LocalDataManager.swift']} /* LocalDataManager.swift */,
\t\t\t\t{new_file_ids['CoreDataManager.swift']} /* CoreDataManager.swift */,
\t\t\t);
\t\t\tpath = Data;
\t\t\tsourceTree = "<group>";
\t\t}};"""
        
        # Insert after Navigation group
        nav_group_match = re.search(r'(3D0A3F602B5F1380000A1B2C /\* Navigation \*/ = \{[^}]+\};)', content)
        if nav_group_match:
            content = content.replace(nav_group_match.group(0),
                                    nav_group_match.group(0) + data_group_def)
    
    # Add LocalAudioPlayer to Audio group
    audio_group_match = re.search(r'(3D0A3F5E2B5F1370000A1B2C /\* Audio \*/ = \{[^}]+children = \(\n)(.*?)(\s*\);)', content, re.DOTALL)
    if audio_group_match:
        new_children = f"\t\t\t\t{new_file_ids['LocalAudioPlayer.swift']} /* LocalAudioPlayer.swift */,\n"
        content = content.replace(audio_group_match.group(0),
                                audio_group_match.group(1) + new_children + audio_group_match.group(3))
    
    # Add LocalHomeViewModel to Home group
    home_group_match = re.search(r'(3D0A3F612B5F1385000A1B2C /\* Home \*/ = \{[^}]+children = \(\n)(.*?)(\s*\);)', content, re.DOTALL)
    if home_group_match:
        new_children = home_group_match.group(2).rstrip()
        new_children += f",\n\t\t\t\t{new_file_ids['LocalHomeViewModel.swift']} /* LocalHomeViewModel.swift */"
        content = content.replace(home_group_match.group(0),
                                home_group_match.group(1) + new_children + home_group_match.group(3))
    
    # Add new components to Components group
    components_group_match = re.search(r'(3D0A3F642B5F1400000A1B2C /\* Components \*/ = \{[^}]+children = \(\n)(.*?)(\s*\);)', content, re.DOTALL)
    if components_group_match:
        new_children = components_group_match.group(2).rstrip()
        for filename in ['CategoryCard.swift', 'ContinueListeningCard.swift', 'FeaturedStoryCard.swift', 'MiniPlayerView.swift', 'StoryCard.swift']:
            new_children += f",\n\t\t\t\t{new_file_ids[filename]} /* {filename} */"
        content = content.replace(components_group_match.group(0),
                                components_group_match.group(1) + new_children + components_group_match.group(3))
    
    # Write the fixed content
    with open('StorySage.xcodeproj/project.pbxproj', 'w') as f:
        f.write(content)
    
    print("\nProject file fixed successfully!")
    print("Next steps:")
    print("1. Open StorySage.xcodeproj in Xcode")
    print("2. Clean Build Folder (Cmd+Shift+K)")
    print("3. Build the project (Cmd+B)")

if __name__ == "__main__":
    fix_project_file()