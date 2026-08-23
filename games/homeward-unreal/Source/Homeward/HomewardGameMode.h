#pragma once

#include "CoreMinimal.h"
#include "GameFramework/GameModeBase.h"
#include "HomewardGameMode.generated.h"

UCLASS()
class HOMEWARD_API AHomewardGameMode : public AGameModeBase
{
    GENERATED_BODY()
public:
    AHomewardGameMode();
    virtual void StartPlay() override;
};
