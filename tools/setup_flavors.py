import os
import re

pbxproj_path = "apps/admin/ios/Runner.xcodeproj/project.pbxproj"

# 1. Read pbxproj
with open(pbxproj_path, "r", encoding="utf-8") as f:
    content = f.read()

# Check if already processed
if "Debug-development" in content:
    print("Already configured with flavors. Skipping pbxproj modification.")
else:
    # 2. Add PBXFileReference entries
    file_references_to_add = """\
\t\tF1D000010000000000000001 /* Debug-development.xcconfig */ = {isa = PBXFileReference; lastKnownFileType = text.xcconfig; name = "Debug-development.xcconfig"; path = "Flutter/Debug-development.xcconfig"; sourceTree = "<group>"; };
\t\tF1D000020000000000000001 /* Release-development.xcconfig */ = {isa = PBXFileReference; lastKnownFileType = text.xcconfig; name = "Release-development.xcconfig"; path = "Flutter/Release-development.xcconfig"; sourceTree = "<group>"; };
\t\tF1D000030000000000000001 /* Profile-development.xcconfig */ = {isa = PBXFileReference; lastKnownFileType = text.xcconfig; name = "Profile-development.xcconfig"; path = "Flutter/Profile-development.xcconfig"; sourceTree = "<group>"; };
\t\tF1D000040000000000000001 /* Debug-staging.xcconfig */ = {isa = PBXFileReference; lastKnownFileType = text.xcconfig; name = "Debug-staging.xcconfig"; path = "Flutter/Debug-staging.xcconfig"; sourceTree = "<group>"; };
\t\tF1D000050000000000000001 /* Release-staging.xcconfig */ = {isa = PBXFileReference; lastKnownFileType = text.xcconfig; name = "Release-staging.xcconfig"; path = "Flutter/Release-staging.xcconfig"; sourceTree = "<group>"; };
\t\tF1D000060000000000000001 /* Profile-staging.xcconfig */ = {isa = PBXFileReference; lastKnownFileType = text.xcconfig; name = "Profile-staging.xcconfig"; path = "Flutter/Profile-staging.xcconfig"; sourceTree = "<group>"; };
\t\tF1D000070000000000000001 /* Debug-production.xcconfig */ = {isa = PBXFileReference; lastKnownFileType = text.xcconfig; name = "Debug-production.xcconfig"; path = "Flutter/Debug-production.xcconfig"; sourceTree = "<group>"; };
\t\tF1D000080000000000000001 /* Release-production.xcconfig */ = {isa = PBXFileReference; lastKnownFileType = text.xcconfig; name = "Release-production.xcconfig"; path = "Flutter/Release-production.xcconfig"; sourceTree = "<group>"; };
\t\tF1D000090000000000000001 /* Profile-production.xcconfig */ = {isa = PBXFileReference; lastKnownFileType = text.xcconfig; name = "Profile-production.xcconfig"; path = "Flutter/Profile-production.xcconfig"; sourceTree = "<group>"; };\n"""
    
    content = content.replace(
        "/* Begin PBXFileReference section */\n",
        "/* Begin PBXFileReference section */\n" + file_references_to_add
    )

    # 3. Add to Flutter PBXGroup children
    group_children_to_add = """\
\t\t\t\tF1D000010000000000000001 /* Debug-development.xcconfig */,
\t\t\t\tF1D000020000000000000001 /* Release-development.xcconfig */,
\t\t\t\tF1D000030000000000000001 /* Profile-development.xcconfig */,
\t\t\t\tF1D000040000000000000001 /* Debug-staging.xcconfig */,
\t\t\t\tF1D000050000000000000001 /* Release-staging.xcconfig */,
\t\t\t\tF1D000060000000000000001 /* Profile-staging.xcconfig */,
\t\t\t\tF1D000070000000000000001 /* Debug-production.xcconfig */,
\t\t\t\tF1D000080000000000000001 /* Release-production.xcconfig */,
\t\t\t\tF1D000090000000000000001 /* Profile-production.xcconfig */,\n"""
    
    group_match = re.search(r"(\t*9740EEB11CF90186004384FC /\* Flutter \*/ = \{\s*isa = PBXGroup;\s*children = \(\n)", content)
    if group_match:
        content = content.replace(group_match.group(1), group_match.group(1) + group_children_to_add)

    # 4. Duplicate build configurations in XCBuildConfiguration section
    configs_section_match = re.search(r"(/\* Begin XCBuildConfiguration section \*/\n)([\s\S]*?)(\n/\* End XCBuildConfiguration section \*/)", content)
    if configs_section_match:
        configs_block = configs_section_match.group(2)
        configs = re.findall(r"(\t\t([0-9A-F]{24}) /\* ([^*]+) \*/ = \{\s*isa = XCBuildConfiguration;[\s\S]*?\n\t\t\};)", configs_block)
        
        env_uuids = {
            # Project level
            "97C147031CF9000F007C117D": {
                "development": "F1D000110000000000000001",
                "staging": "F1D000120000000000000001",
                "production": "F1D000130000000000000001",
            },
            "97C147041CF9000F007C117D": {
                "development": "F1D000140000000000000001",
                "staging": "F1D000150000000000000001",
                "production": "F1D000160000000000000001",
            },
            "249021D3217E4FDB00AE95B9": {
                "development": "F1D000170000000000000001",
                "staging": "F1D000180000000000000001",
                "production": "F1D000190000000000000001",
            },
            # Runner target level
            "97C147061CF9000F007C117D": {
                "development": "F1D000210000000000000001",
                "staging": "F1D000220000000000000001",
                "production": "F1D000230000000000000001",
            },
            "97C147071CF9000F007C117D": {
                "development": "F1D000240000000000000001",
                "staging": "F1D000250000000000000001",
                "production": "F1D000260000000000000001",
            },
            "249021D4217E4FDB00AE95B9": {
                "development": "F1D000270000000000000001",
                "staging": "F1D000280000000000000001",
                "production": "F1D000290000000000000001",
            },
            # RunnerTests target level
            "331C8088294A63A400263BE5": {
                "development": "F1D000310000000000000001",
                "staging": "F1D000320000000000000001",
                "production": "F1D000330000000000000001",
            },
            "331C8089294A63A400263BE5": {
                "development": "F1D000340000000000000001",
                "staging": "F1D000350000000000000001",
                "production": "F1D000360000000000000001",
            },
            "331C808A294A63A400263BE5": {
                "development": "F1D000370000000000000001",
                "staging": "F1D000380000000000000001",
                "production": "F1D000390000000000000001",
            }
        }
        
        xcconfig_refs = {
            "development": {
                "Debug": "F1D000010000000000000001 /* Debug-development.xcconfig */",
                "Release": "F1D000020000000000000001 /* Release-development.xcconfig */",
                "Profile": "F1D000030000000000000001 /* Profile-development.xcconfig */",
            },
            "staging": {
                "Debug": "F1D000040000000000000001 /* Debug-staging.xcconfig */",
                "Release": "F1D000050000000000000001 /* Release-staging.xcconfig */",
                "Profile": "F1D000060000000000000001 /* Profile-staging.xcconfig */",
            },
            "production": {
                "Debug": "F1D000070000000000000001 /* Debug-production.xcconfig */",
                "Release": "F1D000080000000000000001 /* Release-production.xcconfig */",
                "Profile": "F1D000090000000000000001 /* Profile-production.xcconfig */",
            }
        }
        
        duplicated_configs = ""
        for full_match, uuid, name in configs:
            if uuid in env_uuids:
                for env in ["development", "staging", "production"]:
                    new_uuid = env_uuids[uuid][env]
                    new_name = f"{name}-{env}"
                    
                    new_block = full_match
                    new_block = new_block.replace(f"{uuid} /* {name} */", f"{new_uuid} /* {new_name} */")
                    new_block = new_block.replace(f"name = {name};", f"name = \"{new_name}\";")
                    
                    if "baseConfigurationReference =" in new_block:
                        current_ref_match = re.search(r"baseConfigurationReference = ([^;]+);", new_block)
                        if current_ref_match:
                            new_ref = xcconfig_refs[env][name]
                            new_block = new_block.replace(f"baseConfigurationReference = {current_ref_match.group(1)};", f"baseConfigurationReference = {new_ref};")
                            
                    duplicated_configs += "\n" + new_block
                    
        content = content.replace(configs_block, configs_block + duplicated_configs)
        
    # 5. Update XCConfigurationList buildConfigurations list
    lists_to_update = {
        "331C8087294A63A400263BE5": [
            "F1D000310000000000000001 /* Debug-development */",
            "F1D000340000000000000001 /* Release-development */",
            "F1D000370000000000000001 /* Profile-development */",
            "F1D000320000000000000001 /* Debug-staging */",
            "F1D000350000000000000001 /* Release-staging */",
            "F1D000380000000000000001 /* Profile-staging */",
            "F1D000330000000000000001 /* Debug-production */",
            "F1D000360000000000000001 /* Release-production */",
            "F1D000390000000000000001 /* Profile-production */"
        ],
        "97C146E91CF9000F007C117D": [
            "F1D000110000000000000001 /* Debug-development */",
            "F1D000140000000000000001 /* Release-development */",
            "F1D000170000000000000001 /* Profile-development */",
            "F1D000120000000000000001 /* Debug-staging */",
            "F1D000150000000000000001 /* Release-staging */",
            "F1D000180000000000000001 /* Profile-staging */",
            "F1D000130000000000000001 /* Debug-production */",
            "F1D000160000000000000001 /* Release-production */",
            "F1D000190000000000000001 /* Profile-production */"
        ],
        "97C147051CF9000F007C117D": [
            "F1D000210000000000000001 /* Debug-development */",
            "F1D000240000000000000001 /* Release-development */",
            "F1D000270000000000000001 /* Profile-development */",
            "F1D000220000000000000001 /* Debug-staging */",
            "F1D000250000000000000001 /* Release-staging */",
            "F1D000280000000000000001 /* Profile-staging */",
            "F1D000230000000000000001 /* Debug-production */",
            "F1D000260000000000000001 /* Release-production */",
            "F1D000290000000000000001 /* Profile-production */"
        ]
    }
    
    for list_id, configs_to_add in lists_to_update.items():
        pattern = r"(\t*" + list_id + r" /\* [^*]+ \*/ = \{\s*isa = XCConfigurationList;\s*buildConfigurations = \(\n)"
        match = re.search(pattern, content)
        if match:
            added_text = ""
            for cfg in configs_to_add:
                added_text += f"\t\t\t\t{cfg},\n"
            content = content.replace(match.group(1), match.group(1) + added_text)
            
    with open(pbxproj_path, "w", encoding="utf-8") as f:
        f.write(content)
    print("Successfully modified pbxproj with build configurations and file references.")

# 6. Generate scheme files
xcschemes_dir = "apps/admin/ios/Runner.xcodeproj/xcshareddata/xcschemes"
os.makedirs(xcschemes_dir, exist_ok=True)

def generate_scheme(env_name, app_name_suffix):
    scheme_content = f"""<?xml version="1.0" encoding="UTF-8"?>
<Scheme
   LastUpgradeVersion = "1510"
   version = "1.7">
   <BuildAction
      parallelizeBuildables = "YES"
      buildImplicitDependencies = "YES">
      <PreActions>
         <ExecutionAction
            ActionType = "Xcode.IDEStandardExecutionActionsCore.ExecutionActionType.ShellScriptAction">
            <ActionContent
               title = "Run Prepare Flutter Framework Script"
               scriptText = "/bin/sh &quot;$FLUTTER_ROOT/packages/flutter_tools/bin/xcode_backend.sh&quot; prepare&#10;">
               <EnvironmentBuildable>
                  <BuildableReference
                     BuildableIdentifier = "primary"
                     BlueprintIdentifier = "97C146ED1CF9000F007C117D"
                     BuildableName = "Runner.app"
                     BlueprintName = "Runner"
                     ReferencedContainer = "container:Runner.xcodeproj">
                  </BuildableReference>
               </EnvironmentBuildable>
            </ActionContent>
         </ExecutionAction>
      </PreActions>
      <BuildActionEntries>
         <BuildActionEntry
            buildForTesting = "YES"
            buildForRunning = "YES"
            buildForProfiling = "YES"
            buildForArchiving = "YES"
            buildForAnalyzing = "YES">
            <BuildableReference
               BuildableIdentifier = "primary"
               BlueprintIdentifier = "97C146ED1CF9000F007C117D"
               BuildableName = "Runner.app"
               BlueprintName = "Runner"
               ReferencedContainer = "container:Runner.xcodeproj">
            </BuildableReference>
         </BuildActionEntry>
      </BuildActionEntries>
   </BuildAction>
   <TestAction
      buildConfiguration = "Debug-{env_name}"
      selectedDebuggerIdentifier = "Xcode.DebuggerFoundation.Debugger.LLDB"
      selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB"
      customLLDBInitFile = "$(SRCROOT)/Flutter/ephemeral/flutter_lldbinit"
      shouldUseLaunchSchemeArgsEnv = "YES">
      <Testables>
         <TestableReference
            skipped = "NO"
            parallelizable = "YES">
            <BuildableReference
               BuildableIdentifier = "primary"
               BlueprintIdentifier = "331C8080294A63A400263BE5"
               BuildableName = "RunnerTests.xctest"
               BlueprintName = "RunnerTests"
               ReferencedContainer = "container:Runner.xcodeproj">
            </BuildableReference>
         </TestableReference>
      </Testables>
   </TestAction>
   <LaunchAction
      buildConfiguration = "Debug-{env_name}"
      selectedDebuggerIdentifier = "Xcode.DebuggerFoundation.Debugger.LLDB"
      selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB"
      customLLDBInitFile = "$(SRCROOT)/Flutter/ephemeral/flutter_lldbinit"
      launchStyle = "0"
      useCustomWorkingDirectory = "NO"
      ignoresPersistentStateOnLaunch = "NO"
      debugDocumentVersioning = "YES"
      debugServiceExtension = "internal"
      allowLocationSimulation = "YES">
      <BuildableProductRunnable
         runnableDebuggingMode = "0">
         <BuildableReference
            BuildableIdentifier = "primary"
            BlueprintIdentifier = "97C146ED1CF9000F007C117D"
            BuildableName = "Runner.app"
            BlueprintName = "Runner"
            ReferencedContainer = "container:Runner.xcodeproj">
         </BuildableReference>
      </BuildableProductRunnable>
   </LaunchAction>
   <ProfileAction
      buildConfiguration = "Profile-{env_name}"
      shouldUseLaunchSchemeArgsEnv = "YES"
      savedToolIdentifier = ""
      useCustomWorkingDirectory = "NO"
      debugDocumentVersioning = "YES">
      <BuildableProductRunnable
         runnableDebuggingMode = "0">
         <BuildableReference
            BuildableIdentifier = "primary"
            BlueprintIdentifier = "97C146ED1CF9000F007C117D"
            BuildableName = "Runner.app"
            BlueprintName = "Runner"
            ReferencedContainer = "container:Runner.xcodeproj">
         </BuildableReference>
      </BuildableProductRunnable>
   </ProfileAction>
   <AnalyzeAction
      buildConfiguration = "Debug-{env_name}">
   </AnalyzeAction>
   <ArchiveAction
      buildConfiguration = "Release-{env_name}"
      revealArchiveInOrganizer = "YES">
   </ArchiveAction>
</Scheme>
"""
    with open(f"{xcschemes_dir}/{env_name}.xcscheme", "w", encoding="utf-8") as f:
        f.write(scheme_content)
    print(f"Generated scheme {env_name}.xcscheme")

generate_scheme("development", " DEV")
generate_scheme("staging", " STAGING")
generate_scheme("production", "")
