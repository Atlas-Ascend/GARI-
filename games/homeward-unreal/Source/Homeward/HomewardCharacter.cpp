#include "HomewardCharacter.h"
#include "HomewardWorldDirector.h"
#include "Camera/CameraComponent.h"
#include "Components/CapsuleComponent.h"
#include "Components/InputComponent.h"
#include "Components/StaticMeshComponent.h"
#include "Engine/StaticMesh.h"
#include "EngineUtils.h"
#include "GameFramework/CharacterMovementComponent.h"
#include "GameFramework/Controller.h"
#include "GameFramework/SpringArmComponent.h"
#include "UObject/ConstructorHelpers.h"

AHomewardCharacter::AHomewardCharacter()
{
    PrimaryActorTick.bCanEverTick = false;
    GetCapsuleComponent()->InitCapsuleSize(42.f, 88.f);
    GetCharacterMovement()->MaxWalkSpeed = 520.f;
    GetCharacterMovement()->bOrientRotationToMovement = true;
    bUseControllerRotationYaw = false;

    SpringArm = CreateDefaultSubobject<USpringArmComponent>(TEXT("SpringArm"));
    SpringArm->SetupAttachment(GetCapsuleComponent());
    SpringArm->TargetArmLength = 520.f;
    SpringArm->SetRelativeLocation(FVector(0.f, 0.f, 85.f));
    SpringArm->bUsePawnControlRotation = true;

    Camera = CreateDefaultSubobject<UCameraComponent>(TEXT("Camera"));
    Camera->SetupAttachment(SpringArm, USpringArmComponent::SocketName);
    Camera->bUsePawnControlRotation = false;

    static ConstructorHelpers::FObjectFinder<UStaticMesh> Cylinder(TEXT("/Engine/BasicShapes/Cylinder.Cylinder"));
    static ConstructorHelpers::FObjectFinder<UStaticMesh> Sphere(TEXT("/Engine/BasicShapes/Sphere.Sphere"));
    static ConstructorHelpers::FObjectFinder<UStaticMesh> Cone(TEXT("/Engine/BasicShapes/Cone.Cone"));

    Robe = CreateDefaultSubobject<UStaticMeshComponent>(TEXT("Robe"));
    Robe->SetupAttachment(GetCapsuleComponent());
    if (Cylinder.Succeeded()) Robe->SetStaticMesh(Cylinder.Object);
    Robe->SetRelativeLocation(FVector(0.f, 0.f, -20.f));
    Robe->SetRelativeScale3D(FVector(.48f, .48f, 1.15f));
    Robe->SetCollisionEnabled(ECollisionEnabled::NoCollision);
    Robe->SetVectorParameterValueOnMaterials(TEXT("Color"), FVector(0.04f, 0.22f, 0.38f));

    Head = CreateDefaultSubobject<UStaticMeshComponent>(TEXT("Head"));
    Head->SetupAttachment(GetCapsuleComponent());
    if (Sphere.Succeeded()) Head->SetStaticMesh(Sphere.Object);
    Head->SetRelativeLocation(FVector(0.f, 0.f, 63.f));
    Head->SetRelativeScale3D(FVector(.25f));
    Head->SetCollisionEnabled(ECollisionEnabled::NoCollision);
    Head->SetVectorParameterValueOnMaterials(TEXT("Color"), FVector(.70f, .44f, .29f));

    Hood = CreateDefaultSubobject<UStaticMeshComponent>(TEXT("Hood"));
    Hood->SetupAttachment(GetCapsuleComponent());
    if (Cone.Succeeded()) Hood->SetStaticMesh(Cone.Object);
    Hood->SetRelativeLocation(FVector(0.f, 0.f, 92.f));
    Hood->SetRelativeScale3D(FVector(.34f, .34f, .52f));
    Hood->SetCollisionEnabled(ECollisionEnabled::NoCollision);
    Hood->SetVectorParameterValueOnMaterials(TEXT("Color"), FVector(.95f, .68f, .18f));
}

void AHomewardCharacter::SetupPlayerInputComponent(UInputComponent* PlayerInputComponent)
{
    Super::SetupPlayerInputComponent(PlayerInputComponent);
    PlayerInputComponent->BindAxis(TEXT("MoveForward"), this, &AHomewardCharacter::MoveForward);
    PlayerInputComponent->BindAxis(TEXT("MoveRight"), this, &AHomewardCharacter::MoveRight);
    PlayerInputComponent->BindAxis(TEXT("Turn"), this, &AHomewardCharacter::Turn);
    PlayerInputComponent->BindAxis(TEXT("LookUp"), this, &AHomewardCharacter::LookUp);
    PlayerInputComponent->BindAction(TEXT("Interact"), IE_Pressed, this, &AHomewardCharacter::Interact);
    PlayerInputComponent->BindAction(TEXT("Brew"), IE_Pressed, this, &AHomewardCharacter::Brew);
}

void AHomewardCharacter::MoveForward(float Value)
{
    if (!Controller || FMath::IsNearlyZero(Value)) return;
    const FRotator YawRot(0.f, Controller->GetControlRotation().Yaw, 0.f);
    AddMovementInput(FRotationMatrix(YawRot).GetUnitAxis(EAxis::X), Value);
}

void AHomewardCharacter::MoveRight(float Value)
{
    if (!Controller || FMath::IsNearlyZero(Value)) return;
    const FRotator YawRot(0.f, Controller->GetControlRotation().Yaw, 0.f);
    AddMovementInput(FRotationMatrix(YawRot).GetUnitAxis(EAxis::Y), Value);
}

void AHomewardCharacter::Turn(float Value) { AddControllerYawInput(Value); }
void AHomewardCharacter::LookUp(float Value) { AddControllerPitchInput(Value); }

void AHomewardCharacter::Interact()
{
    for (TActorIterator<AHomewardWorldDirector> It(GetWorld()); It; ++It)
    {
        It->TryInteract(this);
        return;
    }
}

void AHomewardCharacter::Brew()
{
    for (TActorIterator<AHomewardWorldDirector> It(GetWorld()); It; ++It)
    {
        It->TryBrew(this);
        return;
    }
}
