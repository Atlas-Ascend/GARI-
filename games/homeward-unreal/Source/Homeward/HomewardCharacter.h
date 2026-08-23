#pragma once

#include "CoreMinimal.h"
#include "GameFramework/Character.h"
#include "HomewardCharacter.generated.h"

class USpringArmComponent;
class UCameraComponent;
class UStaticMeshComponent;

UCLASS()
class HOMEWARD_API AHomewardCharacter : public ACharacter
{
    GENERATED_BODY()
public:
    AHomewardCharacter();
    virtual void SetupPlayerInputComponent(UInputComponent* PlayerInputComponent) override;

private:
    UPROPERTY() USpringArmComponent* SpringArm;
    UPROPERTY() UCameraComponent* Camera;
    UPROPERTY() UStaticMeshComponent* Robe;
    UPROPERTY() UStaticMeshComponent* Head;
    UPROPERTY() UStaticMeshComponent* Hood;

    void MoveForward(float Value);
    void MoveRight(float Value);
    void Turn(float Value);
    void LookUp(float Value);
    void Interact();
    void Brew();
};
