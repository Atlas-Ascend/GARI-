#pragma once

#include "CoreMinimal.h"
#include "GameFramework/Actor.h"
#include "HomewardWorldDirector.generated.h"

class AHomewardCharacter;
class UStaticMesh;
class UMaterialInterface;

UCLASS()
class HOMEWARD_API AHomewardWorldDirector : public AActor
{
    GENERATED_BODY()
public:
    AHomewardWorldDirector();
    virtual void BeginPlay() override;
    virtual void Tick(float DeltaSeconds) override;

    void TryInteract(AHomewardCharacter* Player);
    void TryBrew(AHomewardCharacter* Player);

private:
    UPROPERTY() UStaticMesh* CubeMesh;
    UPROPERTY() UStaticMesh* SphereMesh;
    UPROPERTY() UStaticMesh* CylinderMesh;
    UPROPERTY() UStaticMesh* ConeMesh;
    UPROPERTY() UMaterialInterface* BasicMaterial;

    TArray<int32> Inventory;
    TArray<bool> Brewed;
    TArray<bool> Wizards;
    TArray<bool> Helpers;
    TArray<TObjectPtr<AActor>> Gates;
    bool bHome = false;

    void BuildWorld();
    AActor* SpawnShape(const FVector& Location, const FVector& Scale, UStaticMesh* Mesh,
                       const FLinearColor& Color, FName Tag, bool bCollision);
    void SpawnFigure(const FVector& Location, const FLinearColor& RobeColor, FName Tag, bool bWizard);
    AActor* FindNearestTagged(const FVector& From, const FString& Prefix, float Radius, int32& OutIndex) const;
    int32 FindTagIndex(AActor* Actor, const FString& Prefix, int32 MaxIndex) const;
    bool CanBrew(int32 Stage) const;
    void BrewStage(int32 Stage);
    FString Objective() const;
    void Say(const FString& Text, const FColor& Color = FColor::Cyan, float Seconds = 4.f) const;
    void OpenGate(int32 Stage);
};
