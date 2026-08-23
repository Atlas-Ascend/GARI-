#include "HomewardWorldDirector.h"
#include "HomewardCharacter.h"
#include "Components/DirectionalLightComponent.h"
#include "Components/SkyLightComponent.h"
#include "Components/StaticMeshComponent.h"
#include "Engine/DirectionalLight.h"
#include "Engine/Engine.h"
#include "Engine/SkyLight.h"
#include "Engine/StaticMesh.h"
#include "Engine/StaticMeshActor.h"
#include "EngineUtils.h"
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
    Say(TEXT("WASD / stick: move | E / A: interact | Q / X: brew at a cauldron | No combat. The objective is HOME."), FColor::Silver, 9.f);
}

void AHomewardWorldDirector::Tick(float DeltaSeconds)
{
    Super::Tick(DeltaSeconds);

    if (GEngine)
    {
        GEngine->AddOnScreenDebugMessage(5058, .08f, FColor(166, 255, 235), Objective());
    }

    if (bHome || Wizards.Num() < 5 || !Wizards[4]) return;
    APawn* Pawn = GetWorld() ? GetWorld()->GetFirstPlayerController()->GetPawn() : nullptr;
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
        SpawnShape(Location + FVector(0, 0, 228), FVector(.34f, .34f, .56f), ConeMesh,
                   FLinearColor(1.f, .72f, .22f), NAME_None, false);
        SpawnShape(Location + FVector(35, 0, 85), FVector(.05f, .05f, 1.1f), CylinderMesh,
                   FLinearColor(.48f, .29f, .16f), NAME_None, false);
        SpawnShape(Location + FVector(35, 0, 150), FVector(.10f), SphereMesh,
                   FLinearColor(.42f, .95f, .85f), NAME_None, false);
    }
}

void AHomewardWorldDirector::BuildWorld()
{
    if (!GetWorld()) return;

    ADirectionalLight* Sun = GetWorld()->SpawnActor<ADirectionalLight>(FVector(0, 0, 1000), FRotator(-42.f, -35.f, 0.f));
    if (Sun) Sun->GetLightComponent()->SetIntensity(7.5f);
    ASkyLight* Sky = GetWorld()->SpawnActor<ASkyLight>(FVector::ZeroVector, FRotator::ZeroRotator);
    if (Sky) Sky->GetLightComponent()->SetIntensity(1.25f);

    const FLinearColor ZoneColors[5] = {
        FLinearColor(.05f, .34f, .29f), FLinearColor(.12f, .23f, .38f), FLinearColor(.42f, .23f, .19f),
        FLinearColor(.06f, .31f, .42f), FLinearColor(.31f, .24f, .41f)
    };

    for (int32 i = 0; i < 14; ++i)
    {
        const int32 Zone = FMath::Clamp(i / 3, 0, 4);
        SpawnShape(FVector(250.f + i * 500.f, 0.f, -28.f), FVector(5.f, 12.f, .28f), CubeMesh,
                   ZoneColors[Zone], NAME_None, true);
    }

    // Side walls keep the path honest without turning the game into combat.
    SpawnShape(FVector(3500.f, 650.f, 145.f), FVector(70.f, .25f, 3.f), CubeMesh, FLinearColor(.05f, .16f, .24f), NAME_None, true);
    SpawnShape(FVector(3500.f, -650.f, 145.f), FVector(70.f, .25f, 3.f), CubeMesh, FLinearColor(.05f, .16f, .24f), NAME_None, true);

    // Repeating environmental forms: crystal pylons, trees, lanterns.
    for (int32 i = 0; i < 28; ++i)
    {
        const float X = 220.f + i * 245.f;
        const float Y = (i % 2 == 0) ? 500.f : -500.f;
        const FLinearColor C = (i % 3 == 0) ? FLinearColor(.25f, .86f, .76f) : FLinearColor(.15f, .44f, .50f);
        SpawnShape(FVector(X, Y, 85.f), FVector(.18f, .18f, 1.4f + (i % 4) * .2f), ConeMesh, C, NAME_None, false);
        SpawnShape(FVector(X, Y, 190.f + (i % 4) * 15.f), FVector(.12f), SphereMesh, FLinearColor(.90f, .78f, .34f), NAME_None, false);
    }

    // Resources. Tag number = ingredient index.
    const struct { int32 T; float X; float Y; FLinearColor C; } R[] = {
        {0, 380, 190, FLinearColor(.25f,.85f,.36f)}, {0, 690,-230,FLinearColor(.25f,.85f,.36f)},
        {0, 980,260,FLinearColor(.25f,.85f,.36f)}, {1, 560,-80,FLinearColor(.25f,.82f,.94f)},
        {1,1160,-260,FLinearColor(.25f,.82f,.94f)}, {5,1340,220,FLinearColor(.95f,.88f,.32f)},

        {2,1940,220,FLinearColor(.65f,.42f,.96f)}, {2,2240,-240,FLinearColor(.65f,.42f,.96f)},
        {2,2540,180,FLinearColor(.65f,.42f,.96f)}, {0,2760,-210,FLinearColor(.25f,.85f,.36f)},
        {6,2420,300,FLinearColor(.20f,.86f,.96f)},

        {3,3290,220,FLinearColor(.96f,.30f,.18f)}, {3,3540,-230,FLinearColor(.96f,.30f,.18f)},
        {3,3870,260,FLinearColor(.96f,.30f,.18f)}, {1,4050,-190,FLinearColor(.25f,.82f,.94f)},
        {1,4200,250,FLinearColor(.25f,.82f,.94f)},

        {4,4630,180,FLinearColor(.98f,.72f,.20f)}, {4,5220,-210,FLinearColor(.98f,.72f,.20f)},
        {2,4860,260,FLinearColor(.65f,.42f,.96f)}, {3,5420,200,FLinearColor(.96f,.30f,.18f)},
        {6,5530,-250,FLinearColor(.20f,.86f,.96f)}
    };
    for (const auto& N : R)
    {
        SpawnShape(FVector(N.X, N.Y, 50.f), FVector(.20f, .20f, .34f), SphereMesh, N.C,
                   *FString::Printf(TEXT("Resource%d"), N.T), false);
    }

    // Alchemy stations, one for each required stage.
    const float CauldronX[4] = {1450.f, 2860.f, 4200.f, 5480.f};
    for (int32 i = 0; i < 4; ++i)
    {
        SpawnShape(FVector(CauldronX[i], -40.f, 45.f), FVector(.42f, .42f, .26f), CylinderMesh,
                   FLinearColor(.08f, .12f, .18f), *FString::Printf(TEXT("Cauldron%d"), i), false);
        SpawnShape(FVector(CauldronX[i], -40.f, 76.f), FVector(.26f), SphereMesh,
                   FLinearColor(.18f, .88f, .72f), NAME_None, false);
    }

    // Helpers gift optional ingredients and make the road feel inhabited.
    const float HelperX[4] = {1030.f, 2310.f, 3650.f, 5050.f};
    const FLinearColor HelperColors[4] = {
        FLinearColor(.84f,.50f,.22f), FLinearColor(.22f,.55f,.62f), FLinearColor(.58f,.38f,.72f), FLinearColor(.22f,.67f,.50f)
    };
    for (int32 i = 0; i < 4; ++i)
        SpawnFigure(FVector(HelperX[i], 360.f, 0.f), HelperColors[i], *FString::Printf(TEXT("Helper%d"), i), false);

    // Guardian wizards and gates.
    const float WizardX[5] = {1620.f, 3010.f, 4340.f, 5620.f, 6210.f};
    const FLinearColor WizardColors[5] = {
        FLinearColor(.70f,.48f,.18f), FLinearColor(.15f,.20f,.34f), FLinearColor(.20f,.62f,.45f),
        FLinearColor(.55f,.30f,.72f), FLinearColor(.18f,.52f,.70f)
    };
    for (int32 i = 0; i < 5; ++i)
        SpawnFigure(FVector(WizardX[i], -340.f, 0.f), WizardColors[i], *FString::Printf(TEXT("Wizard%d"), i), true);

    const float GateX[4] = {1760.f, 3140.f, 4460.f, 5740.f};
    for (int32 i = 0; i < 4; ++i)
    {
        Gates[i] = SpawnShape(FVector(GateX[i], 0.f, 145.f), FVector(.22f, 13.f, 3.f), CubeMesh,
                              FLinearColor(.09f, .37f, .46f), *FString::Printf(TEXT("Gate%d"), i), true);
    }

    // Eden Commons and the tribe.
    SpawnShape(FVector(6650.f, 0.f, 145.f), FVector(3.2f, 5.0f, 3.f), CubeMesh,
               FLinearColor(.12f, .32f, .42f), TEXT("Home"), true);
    SpawnShape(FVector(6650.f, 0.f, 385.f), FVector(3.7f, 5.5f, 1.0f), ConeMesh,
               FLinearColor(.95f, .69f, .24f), NAME_None, false);
    for (int32 i = 0; i < 7; ++i)
    {
        const float Y = -360.f + i * 120.f;
        const FLinearColor C = FLinearColor::MakeFromHSV8((uint8)(i * 34), 180, 245);
        SpawnFigure(FVector(6450.f, Y, 0.f), C, NAME_None, false);
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
        if (DistSq < BestSq)
        {
            BestSq = DistSq;
            Best = A;
            OutIndex = Idx;
        }
    }
    return Best;
}

bool AHomewardWorldDirector::CanBrew(int32 Stage) const
{
    if (Inventory.Num() < 7) return false;
    switch (Stage)
    {
        case 0: return Inventory[0] >= 2 && Inventory[1] >= 1; // Horizon Tea
        case 1: return Inventory[2] >= 2 && Inventory[0] >= 1; // Passage Tonic
        case 2: return Inventory[3] >= 2 && Inventory[1] >= 1; // Blessing Oil
        case 3: return Inventory[4] >= 1 && Inventory[2] >= 1 && Inventory[3] >= 1; // Rainbow Elixir
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
    AActor* Cauldron = FindNearestTagged(Player->GetActorLocation(), TEXT("Cauldron"), 300.f, Stage);
    if (!Cauldron || Stage < 0 || Stage >= 4)
    {
        Say(TEXT("Find an alchemy cauldron first."), FColor::Silver, 2.5f);
        return;
    }
    if (Brewed[Stage])
    {
        Say(TEXT("That medicine is already in your kit."), FColor::Green, 2.5f);
        return;
    }
    if (!CanBrew(Stage))
    {
        const FString Need[4] = {
            TEXT("HORIZON TEA needs 2 Moonleaf + 1 Crystal Reed."),
            TEXT("PASSAGE TONIC needs 2 Starshroom + 1 Moonleaf."),
            TEXT("BLESSING OIL needs 2 Emberberry + 1 Crystal Reed."),
            TEXT("RAINBOW ELIXIR needs 1 Prism Seed + 1 Starshroom + 1 Emberberry.")
        };
        Say(Need[Stage], FColor::Yellow, 4.f);
        return;
    }

    BrewStage(Stage);
    const FString Names[4] = {TEXT("HORIZON TEA"), TEXT("PASSAGE TONIC"), TEXT("BLESSING OIL"), TEXT("RAINBOW ELIXIR")};
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
            Inventory[Index] += 1;
            const FString Names[7] = {TEXT("Moonleaf"),TEXT("Crystal Reed"),TEXT("Starshroom"),TEXT("Emberberry"),TEXT("Prism Seed"),TEXT("Sunmint"),TEXT("Tideglass")};
            Say(FString::Printf(TEXT("FORAGED: %s | count %d"), *Names[Index], Inventory[Index]), FColor::Emerald, 2.5f);
            Resource->Destroy();
            return;
        }
    }

    if (AActor* Helper = FindNearestTagged(P, TEXT("Helper"), 270.f, Index))
    {
        if (Helpers.IsValidIndex(Index) && !Helpers[Index])
        {
            Helpers[Index] = true;
            if (Index == 0) Inventory[5] += 1;
            if (Index == 1) Inventory[6] += 1;
            if (Index == 2) Inventory[3] += 1;
            if (Index == 3) Inventory[4] += 1;
            const FString Lines[4] = {
                TEXT("Mara: Notice what grows between destinations. Gift: Sunmint."),
                TEXT("Ione: Every shore remembers the way home. Gift: Tideglass."),
                TEXT("Sol: Good alchemy feeds somebody. Gift: Emberberry."),
                TEXT("Navi: Keep wonder alive while you navigate. Gift: Prism Seed.")
            };
            Say(Lines[Index], FColor(180,255,235), 6.f);
            Helper->SetActorScale3D(Helper->GetActorScale3D() * 1.08f);
        }
        else
        {
            Say(TEXT("Your friend nods. Keep going."), FColor::Silver, 2.f);
        }
        return;
    }

    if (AActor* Wizard = FindNearestTagged(P, TEXT("Wizard"), 300.f, Index))
    {
        if (Index >= 0 && Index < 4)
        {
            if (Wizards[Index])
            {
                Say(TEXT("The guardian has already opened this passage."), FColor::Green, 2.f);
                return;
            }
            if (!Brewed[Index])
            {
                const FString Names[4] = {TEXT("Horizon Tea"), TEXT("Passage Tonic"), TEXT("Blessing Oil"), TEXT("Rainbow Elixir")};
                Say(FString::Printf(TEXT("Guardian: Bring me %s. The gate stays closed until the medicine is made."), *Names[Index]), FColor::Yellow, 4.f);
                return;
            }
            Wizards[Index] = true;
            OpenGate(Index);
            const FString Lines[4] = {
                TEXT("SPHINX: Taste the horizon. The first passage opens."),
                TEXT("ANUBIS: Carry yourself whole through thresholds. The second passage opens."),
                TEXT("HAMSA: An open hand can protect and receive. The third passage opens."),
                TEXT("RAINBOW ORACLE: Many realities can bloom without losing your center. Eden opens ahead.")
            };
            Say(Lines[Index], FColor(255,218,118), 7.f);
            return;
        }

        if (Index == 4)
        {
            const bool Four = Wizards[0] && Wizards[1] && Wizards[2] && Wizards[3];
            if (!Four)
            {
                Say(TEXT("THOTH: Bring the four guardian lessons. Nothing useful is lost."), FColor::Yellow, 5.f);
                return;
            }
            Wizards[4] = true;
            Say(TEXT("THOTH: You gathered the road into memory. Walk the last light into Eden Commons."), FColor(255,218,118), 8.f);
            return;
        }
    }

    if (FindNearestTagged(P, TEXT("Cauldron"), 300.f, Index))
    {
        TryBrew(Player);
        return;
    }

    Say(TEXT("NAVI: Explore the luminous road. Forage what catches your eye."), FColor::Silver, 2.5f);
}

void AHomewardWorldDirector::OpenGate(int32 Stage)
{
    if (Gates.IsValidIndex(Stage) && Gates[Stage])
    {
        Gates[Stage]->Destroy();
        Gates[Stage] = nullptr;
    }
}

FString AHomewardWorldDirector::Objective() const
{
    if (bHome) return TEXT("HOMEWARD COMPLETE | EDEN COMMONS");
    if (!Wizards[0]) return Brewed[0] ? TEXT("OBJECTIVE: Bring Horizon Tea to the Sphinx wizard") : TEXT("OBJECTIVE: Forage Moonleaf + Crystal Reed | Brew Horizon Tea");
    if (!Wizards[1]) return Brewed[1] ? TEXT("OBJECTIVE: Bring Passage Tonic to Anubis") : TEXT("OBJECTIVE: Forage Starshroom + Moonleaf | Brew Passage Tonic");
    if (!Wizards[2]) return Brewed[2] ? TEXT("OBJECTIVE: Bring Blessing Oil to Hamsa") : TEXT("OBJECTIVE: Forage Emberberry + Crystal Reed | Brew Blessing Oil");
    if (!Wizards[3]) return Brewed[3] ? TEXT("OBJECTIVE: Bring Rainbow Elixir to the Oracle") : TEXT("OBJECTIVE: Forage Prism Seed + Starshroom + Emberberry | Brew Rainbow Elixir");
    if (!Wizards[4]) return TEXT("OBJECTIVE: Find Thoth on the Eden Approach");
    return TEXT("OBJECTIVE: Walk into Eden Commons. Your tribe is waiting.");
}

void AHomewardWorldDirector::Say(const FString& Text, const FColor& Color, float Seconds) const
{
    if (GEngine) GEngine->AddOnScreenDebugMessage(-1, Seconds, Color, Text);
}
