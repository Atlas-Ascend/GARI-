#include "HomewardGameMode.h"
#include "HomewardCharacter.h"
#include "HomewardWorldDirector.h"
#include "Engine/World.h"
#include "GameFramework/PlayerController.h"

AHomewardGameMode::AHomewardGameMode()
{
    DefaultPawnClass = nullptr;
}

void AHomewardGameMode::StartPlay()
{
    Super::StartPlay();

    UWorld* World = GetWorld();
    if (!World) return;

    FActorSpawnParameters Params;
    Params.SpawnCollisionHandlingOverride = ESpawnActorCollisionHandlingMethod::AlwaysSpawn;

    AHomewardWorldDirector* Director = World->SpawnActor<AHomewardWorldDirector>(
        AHomewardWorldDirector::StaticClass(), FVector::ZeroVector, FRotator::ZeroRotator, Params);

    APlayerController* PC = World->GetFirstPlayerController();
    if (PC)
    {
        AHomewardCharacter* Pawn = World->SpawnActor<AHomewardCharacter>(
            AHomewardCharacter::StaticClass(), FVector(150.f, 0.f, 120.f), FRotator::ZeroRotator, Params);
        if (Pawn)
        {
            PC->Possess(Pawn);
            PC->SetShowMouseCursor(false);
        }
    }

    if (GEngine)
    {
        GEngine->AddOnScreenDebugMessage(-1, 8.f, FColor::Cyan,
            TEXT("NEW ATLANTIS: HOMEWARD | Forage. Brew. Meet the wizards. Get home to the tribe."));
    }
}
