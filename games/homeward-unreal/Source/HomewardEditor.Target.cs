using UnrealBuildTool;
using System.Collections.Generic;

public class HomewardEditorTarget : TargetRules
{
    public HomewardEditorTarget(TargetInfo Target) : base(Target)
    {
        Type = TargetType.Editor;
        DefaultBuildSettings = BuildSettingsVersion.V6;
        IncludeOrderVersion = EngineIncludeOrderVersion.Latest;
        ExtraModuleNames.Add("Homeward");
    }
}
