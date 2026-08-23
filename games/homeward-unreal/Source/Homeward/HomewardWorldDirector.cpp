#include "HomewardWorldDirector.h"
#include "HomewardCharacter.h"
#include "Components/LightComponent.h"
#include "Components/SkyLightComponent.h"
#include "Components/StaticMeshComponent.h"
#include "Engine/DirectionalLight.h"
#include "Engine/Engine.h"
#include "Engine/SkyLight.h"
#include "Engine/StaticMesh.h"
#include "Engine/StaticMeshActor.h"
#include "Engine/World.h"
#include "EngineUtils.h"
#include "GameFramework/Pawn.h"
#include "GameFramework/PlayerController.h"
#include "Materials/MaterialInstanceDynamic.h"
#include "Materials/MaterialInterface.h"
#include "UObject/ConstructorHelpers.h"

AHomewardWorldDirector::AHomewardWorldDirector()
{
    PrimaryActorTick.bCanEverTick = true;

    static ConstructorHelpers::FObjectFinder<UStaticMesh> Cube(TEXT("/Engine/BasicShapes/Cube.Cube"));
    static ConstructorHelpers::FObjectFinder<UStaticMesh> Sphere(TEXT("/Engine/BasicShapes/Sphere.Sphere"));
    static ConstructorHelpers::FObjectFinder<UStaticMesh> Cylinder(TEXT("/Engine/BasicShapes/Cylinder.Cylinder"));
    static ConstructorHelpers::FObjectFinder<UStaticMesh> Cone(TEXT("/Engine/BasicShapes/Cone.Cone"));
    static ConstructorHelpers::FObjectFinder<UMaterialInterface> Material(TEXT("/Engine/BasicShapes/BasicShapeMaterial.BasicShapeMaterial"));

    CubeMesh = Cube.Object;
    SphereMesh = Sphere.Object;
    CylinderMesh = Cylinder.Object;
    ConeMesh = Cone.Object;
    BasicMaterial = Material.Object;
}

void AHomewardWorldDirector::BeginPlay()
{
    Super::BeginPlay();
    Inventory.Init(0, 7);
    Brewed.Init(false, 4);
    Wizards.Init(false, 5);
    Helpers.Init(false, 4);
    Gates.Init(nullptr, 4);
    BuildWorld();
    Say(TEXT("HOMEWARD | WASD move | E interact | Q brew | no combat | get home to the tribe"), FColor::Silver, 9.f);
}

void AHomewardWorldDirector::Tick(float DeltaSeconds)
{
    Super::Tick(DeltaSeconds);
    if (GEngine)
    {
        GEngine->AddOnScreenDebugMessage(5058, .08f, FColor(166, 255, 235), Objective());
    }

    if (bHome || Wizards.Num() < 5 || !Wizards[4] || !GetWorld()) return;
    APlayerController* PC = GetWorld()->GetFirstPlayerController();
    APawn* Pawn = PC ? PC->GetPawn() : nullptr;
    if (Pawn && Pawn->GetActorLocation().X >= 6550.f)
    {
        bHome = true;
        Say(TEXT("YOU'RE HOME. The road became a garden. Your tribe was waiting in Eden Commons."), FColor(255, 218, 118), 30.f);
    }
}

AActor* AHomewardWorldDirector::SpawnShape(const FVector& Location, const FVector& Scale, UStaticMesh* Mesh,
                                           const FLinearColor& Color, FName Tag, bool bCollision)
{
    if (!GetWorld() || !Mesh) return nullptr;

    FActorSpawnParameters Params;
    Params.SpawnCollisionHandlingOverride = ESpawnActorCollisionHandlingMethod::AlwaysSpawn;
    AStaticMeshActor* Actor = GetWorld()->SpawnActor<AStaticMeshActor>(AStaticMeshActor::StaticClass(), Location, FRotator::ZeroRotator, Params);
    if (!Actor) return nullptr;

    UStaticMeshComponent* Comp = Actor->GetStaticMeshComponent();
    Comp->SetStaticMesh(Mesh);
    Comp->SetMobility(EComponentMobility::Movable);
    Comp->SetCollisionEnabled(bCollision ? ECollisionEnabled::QueryAndPhysics : ECollisionEnabled::NoCollision);
    if (bCollision) Comp->SetCollisionResponseToAllChannels(ECR_Block);
    Actor->SetActorScale3D(Scale);
    if (!Tag.IsNone()) Actor->Tags.Add(Tag);

    if (BasicMaterial)
    {
        UMaterialInstanceDynamic* Dyn = UMaterialInstanceDynamic::Create(BasicMaterial, Actor);
        if (Dyn)
        {
            Dyn->SetVectorParameterValue(TEXT("Color"), Color);
            Comp->SetMaterial(0, Dyn);
        }
    }
    return Actor;
}

void AHomewardWorldDirector::SpawnFigure(const FVector& Location, const FLinearColor& RobeColor, FName Tag, bool bWizard)
{
    SpawnShape(Location + FVector(0, 0, 90), FVector(.42f, .42f, 1.05f), CylinderMesh, RobeColor, Tag, false);
    SpawnShape(Location + FVector(0, 0, 178), FVector(.25f), SphereMesh, FLinearColor(.72f, .47f, .32f), NAME_None, false);
    if (bWizard)
    {
        SpawnShape(Location + FVector(0, 0, 228), FVector(.34f, .34f, .56f), ConeMesh, FLinearColor(1.f, .72f, .22f), NAME_None, false);
        SpawnShape(Location + FVector(35, 0, 95), FVector(.05f, .05f, 1.0f), CylinderMesh, FLinearColor(.48f, .29f, .16f), NAME_None, false);
        SpawnShape(Location + FVector(35, 0, 155), FVector(.10f), SphereMesh, FLinearColor(.42f, .95f, .85f), NAME_None, false);
    }
}

void AHomewardWorldDirector::BuildWorld()
{
    if (!GetWorld()) return;

    FActorSpawnParameters Params;
    Params.SpawnCollisionHandlingOverride = ESpawnActorCollisionHandlingMethod::AlwaysSpawn;
    ADirectionalLight* Sun = GetWorld()->SpawnActor<ADirectionalLight>(ADirectionalLight::StaticClass(), FVector(0, 0, 1000), FRotator(-42.f, -35.f, 0.f), Params);
    if (Sun && Sun->GetLightComponent()) Sun->GetLightComponent()->SetIntensity(7.5f);
    ASkyLight* Sky = GetWorld()->SpawnActor<ASkyLight>(ASkyLight::StaticClass(), FVector::ZeroVector, FRotator::ZeroRotator, Params);
    if (Sky && Sky->GetLightComponent()) Sky->GetLightComponent()->SetIntensity(1.25f);

    const FLinearColor ZoneColors[5] = {
        FLinearColor(.05f,.34f,.29f), FLinearColor(.12f,.23f,.38f), FLinearColor(.42f,.23f,.19f),
        FLinearColor(.06f,.31f,.42f), FLinearColor(.31f,.24f,.41f)
    };
    for (int32 i = 0; i < 14; ++i)
    {
        SpawnShape(FVector(250.f + i * 500.f, 0.f, -28.f), FVector(5.f, 12.f, .28f), CubeMesh,
                   ZoneColors[FMath::Clamp(i / 3, 0, 4)], NAME_None, true);
    }
    SpawnShape(FVector(3500.f, 650.f, 145.f), FVector(70.f, .25f, 3.f), CubeMesh, FLinearColor(.05f,.16f,.24f), NAME_None, true);
    SpawnShape(FVector(3500.f,-650.f, 145.f), FVector(70.f, .25f, 3.f), CubeMesh, FLinearColor(.05f,.16f,.24f), NAME_None, true);

    for (int32 i = 0; i < 28; ++i)
    {
        const float X = 220.f + i * 245.f;
        const float Y = i % 2 == 0 ? 500.f : -500.f;
        SpawnShape(FVector(X,Y,85.f), FVector(.18f,.18f,1.4f + (i % 4) * .2f), ConeMesh,
                   i % 3 == 0 ? FLinearColor(.25f,.86f,.76f) : FLinearColor(.15f,.44f,.50f), NAME_None, false);
    }

    struct FResourceDef { int32 Type; float X; float Y; FLinearColor Color; };
    const FResourceDef Resources[] = {
        {0,380,190,{.25f,.85f,.36f}}, {0,690,-230,{.25f,.85f,.36f}}, {0,980,260,{.25f,.85f,.36f}},
        {1,560,-80,{.25f,.82f,.94f}}, {1,1160,-260,{.25f,.82f,.94f}}, {5,1340,220,{.95f,.88f,.32f}},
        {2,1940,220,{.65f,.42f,.96f}}, {2,2240,-240,{.65f,.42f,.96f}}, {2,2540,180,{.65f,.42f,.96f}},
        {0,2760,-210,{.25f,.85f,.36f}}, {6,2420,300,{.20f,.86f,.96f}},
        {3,3290,220,{.96f,.30f,.18f}}, {3,3540,-230,{.96f,.30f,.18f}}, {3,3870,260,{.96f,.30f,.18f}},
        {1,4050,-190,{.25f,.82f,.94f}}, {1,4200,250,{.25f,.82f,.94f}},
        {4,4630,180,{.98f,.72f,.20f}}, {4,5220,-210,{.98f,.72f,.20f}}, {2,4860,260,{.65f,.42f,.96f}},
        {3,5420,200,{.96f,.30f,.18f}}, {6,5530,-250,{.20f,.86f,.96f}}
    };
    for (const FResourceDef& R : Resources)
    {
        SpawnShape(FVector(R.X,R.Y,50.f), FVector(.20f,.20f,.34f), SphereMesh, R.Color,
                   *FString::Printf(TEXT("Resource%d"), R.Type), false);
    }

    const float Cauldrons[4] = {1450.f,2860.f,4200.f,5480.f};
    const float HelpersX[4] = {1030.f,2310.f,3650.f,5050.f};
    const float WizardsX[5] = {1620.f,3010.f,4340.f,5620.f,6210.f};
    const float GatesX[4] = {1760.f,3140.f,4460.f,5740.f};
    const FLinearColor HelperColors[4] = {{.84f,.50f,.22f},{.22f,.55f,.62f},{.58f,.38f,.72f},{.22f,.67f,.50f}};
    const FLinearColor WizardColors[5] = {{.70f,.48f,.18f},{.15f,.20f,.34f},{.20f,.62f,.45f},{.55f,.30f,.72f},{.18f,.52f,.70f}};

    for (int32 i = 0; i < 4; ++i)
    {
        SpawnShape(FVector(Cauldrons[i],-40.f,45.f), FVector(.42f,.42f,.26f), CylinderMesh, FLinearColor(.08f,.12f,.18f), *FString::Printf(TEXT("Cauldron%d"), i), false);
        SpawnShape(FVector(Cauldrons[i],-40.f,76.f), FVector(.26f), SphereMesh, FLinearColor(.18f,.88f,.72f), NAME_None, false);
        SpawnFigure(FVector(HelpersX[i],360.f,0.f), HelperColors[i], *FString::Printf(TEXT("Helper%d"), i), false);
        Gates[i] = SpawnShape(FVector(GatesX[i],0.f,145.f), FVector(.22f,13.f,3.f), CubeMesh, FLinearColor(.09f,.37f,.46f), *FString::Printf(TEXT("Gate%d"), i), true);
    }
    for (int32 i = 0; i < 5; ++i)
    {
        SpawnFigure(FVector(WizardsX[i],-340.f,0.f), WizardColors[i], *FString::Printf(TEXT("Wizard%d"), i), true);
    }

    SpawnShape(FVector(6650.f,0.f,145.f), FVector(3.2f,5.0f,3.f), CubeMesh, FLinearColor(.12f,.32f,.42f), TEXT("Home"), true);
    SpawnShape(FVector(6650.f,0.f,385.f), FVector(3.7f,5.5f,1.0f), ConeMesh, FLinearColor(.95f,.69f,.24f), NAME_None, false);
    for (int32 i = 0; i < 7; ++i)
    {
        SpawnFigure(FVector(6450.f,-360.f + i * 120.f,0.f), FLinearColor::MakeFromHSV8((uint8)(i * 34),180,245), NAME_None, false);
    }
}

int32 AHomewardWorldDirector::FindTagIndex(AActor* Actor, const FString& Prefix, int32 MaxIndex) const
{
    if (!Actor) return INDEX_NONE;
    for (int32 i = 0; i < MaxIndex; ++i)
    {
        if (Actor->ActorHasTag(*FString::Printf(TEXT("%s%d"), *Prefix, i))) return i;
    }
    return INDEX_NONE;
}

AActor* AHomewardWorldDirector::FindNearestTagged(const FVector& From, const FString& Prefix, float Radius, int32& OutIndex) const
{
    OutIndex = INDEX_NONE;
    AActor* Best = nullptr;
    float BestSq = Radius * Radius;
    if (!GetWorld()) return nullptr;

    for (TActorIterator<AActor> It(GetWorld()); It; ++It)
    {
        AActor* A = *It;
        const int32 Idx = FindTagIndex(A, Prefix, 8);
        if (Idx == INDEX_NONE) continue;
        const float DistSq = FVector::DistSquared(From, A->GetActorLocation());
        if (DistSq < BestSq) { BestSq = DistSq; Best = A; OutIndex = Idx; }
    }
    return Best;
}

bool AHomewardWorldDirector::CanBrew(int32 Stage) const
{
    if (Inventory.Num() < 7) return false;
    switch (Stage)
    {
        case 0: return Inventory[0] >= 2 && Inventory[1] >= 1;
        case 1: return Inventory[2] >= 2 && Inventory[0] >= 1;
        case 2: return Inventory[3] >= 2 && Inventory[1] >= 1;
        case 3: return Inventory[4] >= 1 && Inventory[2] >= 1 && Inventory[3] >= 1;
        default: return false;
    }
}

void AHomewardWorldDirector::BrewStage(int32 Stage)
{
    switch (Stage)
    {
        case 0: Inventory[0]-=2; Inventory[1]-=1; break;
        case 1: Inventory[2]-=2; Inventory[0]-=1; break;
        case 2: Inventory[3]-=2; Inventory[1]-=1; break;
        case 3: Inventory[4]-=1; Inventory[2]-=1; Inventory[3]-=1; break;
        default: return;
    }
    Brewed[Stage] = true;
}

void AHomewardWorldDirector::TryBrew(AHomewardCharacter* Player)
{
    if (!Player) return;
    int32 Stage = INDEX_NONE;
    if (!FindNearestTagged(Player->GetActorLocation(), TEXT("Cauldron"), 300.f, Stage) || Stage < 0 || Stage >= 4)
    {
        Say(TEXT("Find an alchemy cauldron first."), FColor::Silver, 2.5f); return;
    }
    if (Brewed[Stage]) { Say(TEXT("That medicine is already in your kit."), FColor::Green, 2.5f); return; }
    if (!CanBrew(Stage))
    {
        const FString Need[4] = {
            TEXT("HORIZON TEA: 2 Moonleaf + 1 Crystal Reed"), TEXT("PASSAGE TONIC: 2 Starshroom + 1 Moonleaf"),
            TEXT("BLESSING OIL: 2 Emberberry + 1 Crystal Reed"), TEXT("RAINBOW ELIXIR: 1 Prism Seed + 1 Starshroom + 1 Emberberry")
        };
        Say(Need[Stage], FColor::Yellow, 4.f); return;
    }
    BrewStage(Stage);
    const FString Names[4] = {TEXT("HORIZON TEA"),TEXT("PASSAGE TONIC"),TEXT("BLESSING OIL"),TEXT("RAINBOW ELIXIR")};
    Say(FString::Printf(TEXT("ALCHEMY COMPLETE: %s. Take it to the guardian wizard."), *Names[Stage]), FColor::Green, 5.f);
}

void AHomewardWorldDirector::TryInteract(AHomewardCharacter* Player)
{
    if (!Player) return;
    const FVector P = Player->GetActorLocation();
    int32 Index = INDEX_NONE;

    if (AActor* Resource = FindNearestTagged(P, TEXT("Resource"), 220.f, Index))
    {
        if (Inventory.IsValidIndex(Index))
        {
            Inventory[Index]++;
            const FString Names[7] = {TEXT("Moonleaf"),TEXT("Crystal Reed"),TEXT("Starshroom"),TEXT("Emberberry"),TEXT("Prism Seed"),TEXT("Sunmint"),TEXT("Tideglass")};
            Say(FString::Printf(TEXT("FORAGED: %s | count %d"), *Names[Index], Inventory[Index]), FColor(80,220,140), 2.5f);
            Resource->Destroy(); return;
        }
    }

    if (AActor* Helper = FindNearestTagged(P, TEXT("Helper"), 270.f, Index))
    {
        if (Helpers.IsValidIndex(Index) && !Helpers[Index])
        {
            Helpers[Index] = true;
            if (Index == 0) Inventory[5]++;
            if (Index == 1) Inventory[6]++;
            if (Index == 2) Inventory[3]++;
            if (Index == 3) Inventory[4]++;
            const FString Lines[4] = {
                TEXT("Mara: Notice what grows between destinations. Gift: Sunmint."),
                TEXT("Ione: Every shore remembers the way home. Gift: Tideglass."),
                TEXT("Sol: Good alchemy feeds somebody. Gift: Emberberry."),
                TEXT("Navi: Keep wonder alive while you navigate. Gift: Prism Seed.")
            };
            Say(Lines[Index], FColor(180,255,235), 6.f);
            Helper->SetActorScale3D(Helper->GetActorScale3D() * 1.08f);
        }
        else Say(TEXT("Your friend nods. Keep going."), FColor::Silver, 2.f);
        return;
    }

    if (AActor* Wizard = FindNearestTagged(P, TEXT("Wizard"), 300.f, Index))
    {
        if (Index >= 0 && Index < 4)
        {
            if (Wizards[Index]) { Say(TEXT("This passage is already open."), FColor::Green, 2.f); return; }
            if (!Brewed[Index])
            {
                const FString Names[4] = {TEXT("Horizon Tea"),TEXT("Passage Tonic"),TEXT("Blessing Oil"),TEXT("Rainbow Elixir")};
                Say(FString::Printf(TEXT("Guardian: Bring %s first."), *Names[Index]), FColor::Yellow, 4.f); return;
            }
            Wizards[Index] = true;
            OpenGate(Index);
            const FString Lines[4] = {
                TEXT("SPHINX: Taste the horizon. The first passage opens."),
                TEXT("ANUBIS: Carry yourself whole through thresholds. The second passage opens."),
                TEXT("HAMSA: An open hand can protect and receive. The third passage opens."),
                TEXT("RAINBOW ORACLE: Many realities can bloom without losing your center. Eden opens ahead.")
            };
            Say(Lines[Index], FColor(255,218,118), 7.f); return;
        }
        if (Index == 4)
        {
            const bool Four = Wizards[0] && Wizards[1] && Wizards[2] && Wizards[3];
            if (!Four) { Say(TEXT("THOTH: Bring the four guardian lessons."), FColor::Yellow, 5.f); return; }
            Wizards[4] = true;
            Say(TEXT("THOTH: You gathered the road into memory. Walk the last light into Eden Commons."), FColor(255,218,118), 8.f); return;
        }
        (void)Wizard;
    }

    if (FindNearestTagged(P, TEXT("Cauldron"), 300.f, Index)) { TryBrew(Player); return; }
    Say(TEXT("NAVI: Explore the luminous road. Forage what catches your eye."), FColor::Silver, 2.5f);
}

void AHomewardWorldDirector::OpenGate(int32 Stage)
{
    if (Gates.IsValidIndex(Stage) && Gates[Stage]) { Gates[Stage]->Destroy(); Gates[Stage] = nullptr; }
}

FString AHomewardWorldDirector::Objective() const
{
    if (bHome) return TEXT("HOMEWARD COMPLETE | EDEN COMMONS");
    if (!Wizards[0]) return Brewed[0] ? TEXT("Bring Horizon Tea to the Sphinx") : TEXT("Forage Moonleaf + Crystal Reed | Brew Horizon Tea");
    if (!Wizards[1]) return Brewed[1] ? TEXT("Bring Passage Tonic to Anubis") : TEXT("Forage Starshroom + Moonleaf | Brew Passage Tonic");
    if (!Wizards[2]) return Brewed[2] ? TEXT("Bring Blessing Oil to Hamsa") : TEXT("Forage Emberberry + Crystal Reed | Brew Blessing Oil");
    if (!Wizards[3]) return Brewed[3] ? TEXT("Bring Rainbow Elixir to the Oracle") : TEXT("Forage Prism Seed + Starshroom + Emberberry | Brew Rainbow Elixir");
    if (!Wizards[4]) return TEXT("Find Thoth on the Eden Approach");
    return TEXT("Walk into Eden Commons. Your tribe is waiting.");
}

void AHomewardWorldDirector::Say(const FString& Text, const FColor& Color, float Seconds) const
{
    if (GEngine) GEngine->AddOnScreenDebugMessage(-1, Seconds, Color, Text);
}
