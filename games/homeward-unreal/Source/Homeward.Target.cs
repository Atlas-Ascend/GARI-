using UnrealBuildTool;
using System.Collections.Generic;

public class HomewardTarget : TargetRules
{
    public HomewardTarget(TargetInfo Target) : base(Target)
    {
        Type = TargetType.Game;
        DefaultBuildSettings = BuildSettingsVersion.V6;
        IncludeOrderVersion = EngineIncludeOrderVersion.Latest;
        ExtraModuleNames.Add("Homeward");
    }
}
