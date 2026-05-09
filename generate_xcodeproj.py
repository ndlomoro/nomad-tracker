#!/usr/bin/env python3
"""
Generate a complete, buildable .xcodeproj for NomadTracker.
Creates proper targets, build phases, file references, and dependencies.
"""

import os
import json
from datetime import datetime

BASE = "/Users/ndlomoro/Documents/Develop/nomad-tracker"
PROJECT_DIR = os.path.join(BASE, "NomadTracker.xcodeproj")
PBXPROJ = os.path.join(PROJECT_DIR, "project.pbxproj")

# Clean up
import shutil
if os.path.exists(PROJECT_DIR):
    shutil.rmtree(PROJECT_DIR)
os.makedirs(PROJECT_DIR, exist_ok=True)

# Collect all files
def collect_files(base, patterns, exclude_dirs=None):
    exclude_dirs = exclude_dirs or ['.git', '.xcodeproj', 'node_modules']
    files = {}
    for root, dirs, fnames in os.walk(base):
        dirs[:] = [d for d in dirs if d not in exclude_dirs]
        for f in fnames:
            if any(f.endswith(p) for p in patterns):
                full = os.path.join(root, f)
                rel = os.path.relpath(full, base)
                files[rel] = full
    return files

swift_files = collect_files(BASE, ['.swift'])
plist_files = collect_files(BASE, ['.plist'])
entitlements_files = collect_files(BASE, ['.entitlements'])
json_files = collect_files(BASE, ['.json'])
xcdatamodel_files = collect_files(BASE, ['.xcdatamodel'])

print(f"Found: {len(swift_files)} swift, {len(plist_files)} plist, {len(entitlements_files)} entitlements, {len(json_files)} json, {len(xcdatamodel_files)} xcdatamodel")

# Generate UUIDs
import hashlib
uuid_counter = [0]
def uid():
    uuid_counter[0] += 1
    # Generate valid-looking UUIDs
    return f"{uuid_counter[0]:08X}{'0' * 24}"

# File type mapping
def file_type(path):
    if path.endswith('.swift'): return 'sourcecode.swift'
    if path.endswith('.plist'): return 'text.plist.xml'
    if path.endswith('.json'): return 'text.json'
    if path.endswith('.entitlements'): return 'text.plist.xml'
    if path.endswith('.xcdatamodel'): return 'wrapper.xcdatamodel'
    return 'text'

# Create file references
file_refs = {}
for rel in sorted(swift_files.keys()):
    file_refs[rel] = uid()
for rel in sorted(plist_files.keys()):
    file_refs[rel] = uid()
for rel in sorted(entitlements_files.keys()):
    file_refs[rel] = uid()
for rel in sorted(json_files.keys()):
    file_refs[rel] = uid()
for rel in sorted(xcdatamodel_files.keys()):
    file_refs[rel] = uid()

# Create groups
groups = {}
group_uids = {}
def ensure_group(path):
    if path not in group_uids:
        group_uids[path] = uid()
    return group_uids[path]

# Root group
root_group = uid()

# Top-level groups
nomad_group = ensure_group("NomadTracker")
widget_group = ensure_group("NomadTrackerWidget")
intents_group = ensure_group("NomadTrackerIntents")
shared_group = ensure_group("Shared")

# Sub-groups for NomadTracker
app_group = ensure_group("NomadTracker/App")
data_group = ensure_group("NomadTracker/Data")
models_group = ensure_group("NomadTracker/Models")
viewmodel_group = ensure_group("NomadTracker/ViewModel")
views_group = ensure_group("NomadTracker/Views")
dashboard_group = ensure_group("NomadTracker/Views/Dashboard")
resources_group = ensure_group("NomadTracker/Resources")
assets_group = ensure_group("NomadTracker/Resources/Assets.xcassets")
appicon_group = ensure_group("NomadTracker/Resources/Assets.xcassets/AppIcon.appiconset")
datamodel_group = ensure_group("NomadTracker/Resources/NomadTracker.xcdatamodeld")

# Assign files to groups
def assign_file(rel, group_key):
    """Assign a file to a group"""
    pass

# Build file assignments
file_assignments = {}
for rel in file_refs:
    if rel.startswith("NomadTracker/App/"):
        file_assignments[rel] = app_group
    elif rel.startswith("NomadTracker/Data/"):
        file_assignments[rel] = data_group
    elif rel.startswith("NomadTracker/Models/"):
        file_assignments[rel] = models_group
    elif rel.startswith("NomadTracker/ViewModel/"):
        file_assignments[rel] = viewmodel_group
    elif rel.startswith("NomadTracker/Views/Dashboard/"):
        file_assignments[rel] = dashboard_group
    elif rel.startswith("NomadTracker/Views/"):
        file_assignments[rel] = views_group
    elif rel.startswith("NomadTracker/Resources/Assets.xcassets/AppIcon.appiconset/"):
        file_assignments[rel] = appicon_group
    elif rel.startswith("NomadTracker/Resources/Assets.xcassets/"):
        file_assignments[rel] = assets_group
    elif rel.startswith("NomadTracker/Resources/NomadTracker.xcdatamodeld/"):
        file_assignments[rel] = datamodel_group
    elif rel.startswith("NomadTracker/Resources/"):
        file_assignments[rel] = resources_group
    elif rel.startswith("NomadTracker/"):
        file_assignments[rel] = nomad_group
    elif rel.startswith("NomadTrackerWidget/"):
        file_assignments[rel] = widget_group
    elif rel.startswith("NomadTrackerIntents/"):
        file_assignments[rel] = intents_group
    elif rel.startswith("Shared/"):
        file_assignments[rel] = shared_group
    else:
        file_assignments[rel] = root_group

# Target definitions
targets = {
    "NomadTracker": {
        "type": "application",
        "bundle_id": "com.andeslabs.nomadtracker",
        "sources": [r for r in file_refs if r.startswith("NomadTracker/") or r.startswith("Shared/")],
        "resources": [r for r in file_refs if r.startswith("NomadTracker/Resources/")],
        "entitlements": "NomadTracker/NomadTracker.entitlements",
    },
    "NomadTrackerWidget": {
        "type": "app-extension",
        "bundle_id": "com.andeslabs.nomadtracker.NomadTrackerWidget",
        "sources": [r for r in file_refs if r.startswith("NomadTrackerWidget/") or r.startswith("Shared/")],
        "resources": [r for r in file_refs if r.startswith("NomadTrackerWidget/Assets.xcassets/")],
        "entitlements": "NomadTrackerWidget/NomadTrackerWidget.entitlements",
        "dependencies": ["NomadTracker"],
    },
    "NomadTrackerIntents": {
        "type": "app-extension",
        "bundle_id": "com.andeslabs.nomadtracker.NomadTrackerIntents",
        "sources": [r for r in file_refs if r.startswith("NomadTrackerIntents/")],
        "entitlements": "NomadTrackerIntents/NomadTrackerIntents.entitlements",
        "dependencies": ["NomadTracker"],
    },
}

# Generate target UUIDs
target_uids = {}
for tname in targets:
    target_uids[tname] = uid()

# Product UUIDs
product_uids = {}
for tname in targets:
    product_uids[tname] = uid()

# Build configuration list UUIDs
bcl_uids = {}
for tname in targets:
    bcl_uids[tname] = uid()

# Project build configuration list
project_bcl = uid()

# Project object
project_obj = uid()

# Write project.pbxproj
with open(PBXPROJ, 'w') as f:
    f.write('// !$*UTF8*$!\n')
    f.write('{\n')
    f.write('\tarchiveVersion = 1;\n')
    f.write('\tclasses = {\n\t};\n')
    f.write('\tobjectVersion = 56;\n')
    f.write(f'\tobjects = {{\n\n')
    
    # Write file references
    f.write('\t/* Begin PBXFileReference */\n')
    for rel, frel_uid in sorted(file_refs.items()):
        basename = os.path.basename(rel)
        ftype = file_type(rel)
        f.write(f'\t\t{frel_uid} /* {basename} */ = {{isa = PBXFileReference; lastKnownFileType = {ftype}; name = "{basename}"; path = "{rel}"; sourceTree = "<group>";}};\n')
    
    # Write product references
    f.write('\n\t/* Begin PBXNativeTarget (products) */\n')
    for tname in targets:
        f.write(f'\t\t{product_uids[tname]} /* {tname} */ = {{isa = PBXNativeTarget; name = "{tname}"; productName = "{tname}"; productReference = {product_uids[tname]}; productType = "com.apple.product-type.application";}};\n')
    
    # Write groups
    f.write('\n\t/* Begin PBXGroup */\n')
    
    # Root group
    f.write(f'\t\t{root_group} = {{\n')
    f.write(f'\t\t\tisa = PBXGroup;\n')
    f.write(f'\t\t\tchildren = (\n')
    for gname, guid in sorted(group_uids.items()):
        f.write(f'\t\t\t\t{guid} /* {gname} */,\n')
    f.write(f'\t\t\t);\n')
    f.write(f'\t\t\tsourceTree = "<group>";\n')
    f.write(f'\t\t}};\n')
    
    # Write all groups with their children
    for gname, guid in sorted(group_uids.items()):
        children = [rel for rel, cg in file_assignments.items() if cg == guid]
        if children:
            f.write(f'\t\t{guid} /* {gname} */ = {{\n')
            f.write(f'\t\t\tisa = PBXGroup;\n')
            f.write(f'\t\t\tchildren = (\n')
            for child in children:
                child_uid = file_refs[child]
                child_name = os.path.basename(child)
                f.write(f'\t\t\t\t{child_uid} /* {child_name} */,\n')
            f.write(f'\t\t\t);\n')
            f.write(f'\t\t\tname = "{gname}";\n')
            f.write(f'\t\t\tsourceTree = "<group>";\n')
            f.write(f'\t\t}};\n')
    
    # Write XCBuildConfiguration entries
    f.write('\n\t/* Begin XCBuildConfiguration */\n')
    
    # Debug config
    debug_config = uid()
    f.write(f'\t\t{debug_config} /* Debug */ = {{\n')
    f.write(f'\t\t\tisa = XCBuildConfiguration;\n')
    f.write(f'\t\t\tbuildSettings = {{\n')
    f.write(f'\t\t\t\tALWAYS_SEARCH_USER_PATHS = NO;\n')
    f.write(f'\t\t\t\tCLANG_ANALYZER_NONNULL = YES;\n')
    f.write(f'\t\t\t\tCLANG_CXX_LANGUAGE_STANDARD = "gnu++20";\n')
    f.write(f'\t\t\t\tCLANG_ENABLE_MODULES = YES;\n')
    f.write(f'\t\t\t\tCLANG_ENABLE_OBJC_ARC = YES;\n')
    f.write(f'\t\t\t\tCLANG_ENABLE_OBJC_WEAK = YES;\n')
    f.write(f'\t\t\t\tCOPY_PHASE_STRIP = NO;\n')
    f.write(f'\t\t\t\tDEBUG_INFORMATION_FORMAT = dwarf;\n')
    f.write(f'\t\t\t\tENABLE_STRICT_OBJC_MSGSEND = YES;\n')
    f.write(f'\t\t\t\tGCC_DYNAMIC_NO_PIC = NO;\n')
    f.write(f'\t\t\t\tGCC_OPTIMIZATION_LEVEL = 0;\n')
    f.write(f'\t\t\t\tGCC_PREPROCESSOR_DEFINITIONS = ("DEBUG=1",);\n')
    f.write(f'\t\t\t\tGCC_WARN_64BIT_COMPATIBILITY = YES;\n')
    f.write(f'\t\t\t\tGCC_WARN_ABOUT_RETURN_TYPE = YES;\n')
    f.write(f'\t\t\t\tGCC_WARN_UNINITIALIZED_AUTOS = YES;\n')
    f.write(f'\t\t\t\tIPHONEOS_DEPLOYMENT_TARGET = "17.0";\n')
    f.write(f'\t\t\t\tMTL_ENABLE_DEBUG_INFO = INCLUDE_SOURCE;\n')
    f.write(f'\t\t\t\tONLY_ACTIVE_ARCH = YES;\n')
    f.write(f'\t\t\t\tSDKROOT = iphoneos;\n')
    f.write(f'\t\t\t\tSWIFT_ACTIVE_COMPILATION_CONDITIONS = "DEBUG";\n')
    f.write(f'\t\t\t\tSWIFT_OPTIMIZATION_LEVEL = "-Onone";\n')
    f.write(f'\t\t\t\tVALIDATE_PRODUCT = YES;\n')
    f.write(f'\t\t\t}};\n')
    f.write(f'\t\t\tname = Debug;\n')
    f.write(f'\t\t}};\n')
    
    # Release config
    release_config = uid()
    f.write(f'\t\t{release_config} /* Release */ = {{\n')
    f.write(f'\t\t\tisa = XCBuildConfiguration;\n')
    f.write(f'\t\t\tbuildSettings = {{\n')
    f.write(f'\t\t\t\tALWAYS_SEARCH_USER_PATHS = NO;\n')
    f.write(f'\t\t\t\tCLANG_ANALYZER_NONNULL = YES;\n')
    f.write(f'\t\t\t\tCLANG_CXX_LANGUAGE_STANDARD = "gnu++20";\n')
    f.write(f'\t\t\t\tCLANG_ENABLE_MODULES = YES;\n')
    f.write(f'\t\t\t\tCLANG_ENABLE_OBJC_ARC = YES;\n')
    f.write(f'\t\t\t\tCLANG_ENABLE_OBJC_WEAK = YES;\n')
    f.write(f'\t\t\t\tCOPY_PHASE_STRIP = NO;\n')
    f.write(f'\t\t\t\tDEBUG_INFORMATION_FORMAT = "dwarf-with-dsym";\n')
    f.write(f'\t\t\t\tENABLE_NS_ASSERTIONS = NO;\n')
    f.write(f'\t\t\t\tENABLE_STRICT_OBJC_MSGSEND = YES;\n')
    f.write(f'\t\t\t\tGCC_OPTIMIZATION_LEVEL = s;\n')
    f.write(f'\t\t\t\tGCC_WARN_64BIT_COMPATIBILITY = YES;\n')
    f.write(f'\t\t\t\tGCC_WARN_ABOUT_RETURN_TYPE = YES;\n')
    f.write(f'\t\t\t\tGCC_WARN_UNINITIALIZED_AUTOS = YES;\n')
    f.write(f'\t\t\t\tIPHONEOS_DEPLOYMENT_TARGET = "17.0";\n')
    f.write(f'\t\t\t\tMTL_ENABLE_DEBUG_INFO = NO;\n')
    f.write(f'\t\t\t\tSDKROOT = iphoneos;\n')
    f.write(f'\t\t\t\tSWIFT_COMPILATION_MODE = wholemodule;\n')
    f.write(f'\t\t\t\tVALIDATE_PRODUCT = YES;\n')
    f.write(f'\t\t\t}};\n')
    f.write(f'\t\t\tname = Release;\n')
    f.write(f'\t\t}};\n')
    
    # Write XCConfigurationList entries
    f.write('\n\t/* Begin XCConfigurationList */\n')
    
    # Project config list
    f.write(f'\t\t{project_bcl} = {{\n')
    f.write(f'\t\t\tisa = XCConfigurationList;\n')
    f.write(f'\t\t\tbuildConfigurations = (\n')
    f.write(f'\t\t\t\t{debug_config} /* Debug */,\n')
    f.write(f'\t\t\t\t{release_config} /* Release */,\n')
    f.write(f'\t\t\t);\n')
    f.write(f'\t\t\tdefaultConfigurationIsVisible = 0;\n')
    f.write(f'\t\t}};\n')
    
    # Target config lists
    for tname in targets:
        t_debug = uid()
        t_release = uid()
        f.write(f'\t\t{bcl_uids[tname]} /* {tname} */ = {{\n')
        f.write(f'\t\t\tisa = XCConfigurationList;\n')
        f.write(f'\t\t\tbuildConfigurations = (\n')
        f.write(f'\t\t\t\t{t_debug} /* Debug */,\n')
        f.write(f'\t\t\t\t{t_release} /* Release */,\n')
        f.write(f'\t\t\t);\n')
        f.write(f'\t\t\tdefaultConfigurationIsVisible = 0;\n')
        f.write(f'\t\t}};\n')
    
    # Write PBXNativeTarget entries
    f.write('\n\t/* Begin PBXNativeTarget */\n')
    for tname, tinfo in targets.items():
        f.write(f'\t\t{target_uids[tname]} /* {tname} */ = {{\n')
        f.write(f'\t\t\tisa = PBXNativeTarget;\n')
        f.write(f'\t\t\tbuildConfigurationList = {bcl_uids[tname]} /* {tname} */;\n')
        f.write(f'\t\t\tbuildPhases = (\n')
        # Sources build phase
        src_bp = uid()
        f.write(f'\t\t\t\t{src_bp} /* Sources */,\n')
        # Resources build phase
        res_bp = uid()
        f.write(f'\t\t\t\t{res_bp} /* Resources */,\n')
        f.write(f'\t\t\t);\n')
        f.write(f'\t\t\tbuildRules = (\n')
        f.write(f'\t\t\t);\n')
        f.write(f'\t\t\tdependencies = (\n')
        for dep in tinfo.get('dependencies', []):
            dep_target_uid = target_uids[dep]
            f.write(f'\t\t\t\t{dep_target_uid} /* {dep} */,\n')
        f.write(f'\t\t\t);\n')
        f.write(f'\t\t\tname = "{tname}";\n')
        f.write(f'\t\t\tproductName = "{tname}";\n')
        f.write(f'\t\t\tproductReference = {product_uids[tname]} /* {tname} */;\n')
        product_type = "com.apple.product-type.application" if tinfo['type'] == 'application' else "com.apple.product-type.app-extension"
        f.write(f'\t\t\tproductType = "{product_type}";\n')
        f.write(f'\t\t}};\n')
    
    # Write PBXSourcesBuildPhase entries
    f.write('\n\t/* Begin PBXSourcesBuildPhase */\n')
    for tname, tinfo in targets.items():
        src_bp = uid()
        f.write(f'\t\t{src_bp} /* {tname} Sources */ = {{\n')
        f.write(f'\t\t\tisa = PBXSourcesBuildPhase;\n')
        f.write(f'\t\t\tfiles = (\n')
        for src in tinfo['sources']:
            if src in file_refs:
                file_ref_uid = file_refs[src]
                f.write(f'\t\t\t\t{file_ref_uid} /* {os.path.basename(src)} */,\n')
        f.write(f'\t\t\t);\n')
        f.write(f'\t\t}};\n')
    
    # Write PBXResourcesBuildPhase entries
    f.write('\n\t/* Begin PBXResourcesBuildPhase */\n')
    for tname, tinfo in targets.items():
        res_bp = uid()
        f.write(f'\t\t{res_bp} /* {tname} Resources */ = {{\n')
        f.write(f'\t\t\tisa = PBXResourcesBuildPhase;\n')
        f.write(f'\t\t\tfiles = (\n')
        for res in tinfo.get('resources', []):
            if res in file_refs:
                file_ref_uid = file_refs[res]
                f.write(f'\t\t\t\t{file_ref_uid} /* {os.path.basename(res)} */,\n')
        f.write(f'\t\t\t);\n')
        f.write(f'\t\t}};\n')
    
    # Write project object
    f.write('\n\t/* Begin PBXProject */\n')
    f.write(f'\t\t{project_obj} /* Project object */ = {{\n')
    f.write(f'\t\t\tisa = PBXProject;\n')
    f.write(f'\t\t\tattributes = {{\n')
    f.write(f'\t\t\t\tBuildIndependentTargetsInParallel = 1;\n')
    f.write(f'\t\t\t\tLastSwiftUpdateCheck = 1540;\n')
    f.write(f'\t\t\t\tLastUpgradeCheck = 1540;\n')
    f.write(f'\t\t\t\tTargetAttributes = {{\n')
    for tname in targets:
        f.write(f'\t\t\t\t\t{target_uids[tname]} = {{\n')
        f.write(f'\t\t\t\t\t\tCreatedOnToolsVersion = 15.4;\n')
        f.write(f'\t\t\t\t\t}};\n')
    f.write(f'\t\t\t\t}};\n')
    f.write(f'\t\t\t}};\n')
    f.write(f'\t\t\tbuildConfigurationList = {project_bcl};\n')
    f.write(f'\t\t\tcompatibilityVersion = "Xcode 14.0";\n')
    f.write(f'\t\t\tdevelopmentRegion = en;\n')
    f.write(f'\t\t\thasScannedForEncodings = 0;\n')
    f.write(f'\t\t\tknownRegions = (\n')
    f.write(f'\t\t\t\ten,\n')
    f.write(f'\t\t\t\tBase,\n')
    f.write(f'\t\t\t);\n')
    f.write(f'\t\t\tmainGroup = {root_group};\n')
    f.write(f'\t\t\tpackageProducts = (\n')
    f.write(f'\t\t\t);\n')
    f.write(f'\t\t\tprojectDirPath = "";\n')
    f.write(f'\t\t\tprojectRoot = "";\n')
    f.write(f'\t\t\ttargets = (\n')
    for tname in targets:
        f.write(f'\t\t\t\t{target_uids[tname]} /* {tname} */,\n')
    f.write(f'\t\t\t);\n')
    f.write(f'\t\t}};\n')
    
    f.write('\t};\n')
    f.write(f'\trootObject = {project_obj} /* Project object */;\n')
    f.write('}\n')

print(f"✅ Generated {PBXPROJ}")
print(f"   Targets: {len(targets)}")
print(f"   File refs: {len(file_refs)}")
print(f"   Groups: {len(group_uids)}")
