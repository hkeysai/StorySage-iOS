#!/usr/bin/env python3
"""
Fix Resources in Xcode project - Add all audio files to Copy Bundle Resources
"""

import os
import re
import uuid

def generate_uuid():
    """Generate a 24-character uppercase hex UUID for Xcode"""
    return uuid.uuid4().hex[:24].upper()

def find_copy_bundle_resources_section(content):
    """Find the Copy Bundle Resources section"""
    match = re.search(r'/\* Resources \*/ = \{\s*isa = PBXResourcesBuildPhase;\s*buildActionMask = [^;]+;\s*files = \(\s*([^)]*)\s*\);', content, re.DOTALL)
    if match:
        return match
    return None

def add_audio_files_to_project(project_file):
    """Add audio files to the Xcode project"""
    
    # Read the project file
    with open(project_file, 'r') as f:
        content = f.read()
    
    # Find all MP3 files in Resources/Audio
    audio_dir = "/Users/efmbpm2/repos/StorySage/iOS/StorySage/Resources/Audio"
    mp3_files = [f for f in os.listdir(audio_dir) if f.endswith('.mp3')]
    
    print(f"Found {len(mp3_files)} MP3 files to add")
    
    # Find the PBXBuildFile section
    build_file_section = content.find("/* End PBXBuildFile section */")
    
    # Find the PBXFileReference section  
    file_ref_section = content.find("/* End PBXFileReference section */")
    
    # Find the Resources group
    resources_match = re.search(r'/\* Resources \*/ = \{[^}]+files = \(([^)]*)\);', content, re.DOTALL)
    if not resources_match:
        print("ERROR: Could not find Resources build phase")
        return
    
    resources_files = resources_match.group(1).strip()
    
    # Generate entries for each MP3 file
    new_build_files = []
    new_file_refs = []
    new_resource_refs = []
    
    for mp3_file in mp3_files:
        # Generate UUIDs
        build_uuid = generate_uuid()
        file_uuid = generate_uuid()
        
        # Create build file entry
        build_entry = f"\t\t{build_uuid} /* {mp3_file} in Resources */ = {{isa = PBXBuildFile; fileRef = {file_uuid} /* {mp3_file} */; }};"
        new_build_files.append(build_entry)
        
        # Create file reference entry
        file_entry = f'\t\t{file_uuid} /* {mp3_file} */ = {{isa = PBXFileReference; lastKnownFileType = audio.mp3; path = "{mp3_file}"; sourceTree = "<group>"; }};'
        new_file_refs.append(file_entry)
        
        # Add to resources list
        resource_ref = f"\t\t\t\t{build_uuid} /* {mp3_file} in Resources */,"
        new_resource_refs.append(resource_ref)
    
    # Insert build files
    content = content[:build_file_section] + '\n'.join(new_build_files) + '\n' + content[build_file_section:]
    
    # Update file reference section
    file_ref_section = content.find("/* End PBXFileReference section */")
    content = content[:file_ref_section] + '\n'.join(new_file_refs) + '\n' + content[file_ref_section:]
    
    # Update resources list
    if resources_files:
        # Add comma after existing entries if needed
        if not resources_files.rstrip().endswith(','):
            resources_files += ','
        new_resources = resources_files + '\n' + '\n'.join(new_resource_refs)
    else:
        new_resources = '\n'.join(new_resource_refs)
    
    content = re.sub(
        r'(/\* Resources \*/ = \{[^}]+files = \()[^)]*(\);)', 
        rf'\1{new_resources}\n\t\t\t\2',
        content,
        flags=re.DOTALL
    )
    
    # Write back
    with open(project_file, 'w') as f:
        f.write(content)
    
    print(f"✅ Added {len(mp3_files)} MP3 files to project")
    print("\nNext steps:")
    print("1. Close Xcode")
    print("2. Open Xcode again") 
    print("3. Clean build folder (Shift+Cmd+K)")
    print("4. Build and run (Cmd+R)")

if __name__ == "__main__":
    project_file = "/Users/efmbpm2/repos/StorySage/iOS/StorySage.xcodeproj/project.pbxproj"
    add_audio_files_to_project(project_file)