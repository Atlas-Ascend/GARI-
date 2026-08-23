# Ghost Atlas: New Atlantis — HOMEWARD

**Engine:** Unreal Engine 5.8  
**Runtime:** native UE C++  
**Browser delivery:** Pixel Streaming 2 / WebRTC  
**Combat:** none  
**Primary loop:** explore → forage → brew → meet helper/wizard → open passage → reach Eden Commons

## What is in this repo

This project is intentionally code-first. The first playable world is generated at runtime from Unreal Engine primitives so the repository does not depend on opaque binary `.uasset` files merely to boot.

The vertical slice includes:

- third-person wizard player with camera and gamepad/keyboard controls
- five connected New Atlantis regions
- 3D environment forms, lights, roads, gates, cauldrons, resources, helpers, wizards, Eden Commons, and tribe figures
- resource gathering
- four required alchemy recipes: Horizon Tea, Passage Tonic, Blessing Oil, Rainbow Elixir
- four guardian gates plus Thoth at the Eden Approach
- no combat or health loop
- explicit win condition: reach the tribe in Eden Commons after completing the homeward route
- Pixel Streaming 2 enabled in `Homeward.uproject`
- GitHub source-contract CI plus a self-hosted UE5.8 GPU package/smoke-run lane

## Engine installation

Unreal Engine source is governed by Epic's EULA and its GitHub repository requires an Epic-linked GitHub account. The engine is therefore installed into the working checkout but excluded from Git.

From PowerShell:

```powershell
cd games/homeward-unreal
./Scripts/Setup-Unreal58.ps1
```

Or set `UE_ROOT` to an existing UE 5.8 installation.

## Package and run as a browser-streamed Unreal game

```powershell
cd games/homeward-unreal
$env:UE_ROOT='C:\path\to\UnrealEngine-5.8'
./Scripts/Package-And-PixelStream.ps1
```

The launcher packages the Win64 Shipping build, checks that `Homeward.exe` exists, downloads Epic's matching `UE5.8` Pixel Streaming Infrastructure, starts the signalling/web server, launches the packaged game with `-RenderOffScreen` and Pixel Streaming, and fails if the game process exits during the launch smoke test.

Default local player address: `http://127.0.0.1`

## Public hosting

A public Pixel Streaming deployment requires a GPU host that keeps `Homeward.exe` running and exposes the signalling/web ports. GitHub and static/serverless web hosting are not the renderer. Use a Windows/Linux GPU VM or a physical GPU machine, then put TLS/reverse-proxying in front of the Pixel Streaming web endpoint.

## Controls

- `WASD` / gamepad: move
- mouse: camera
- `E` / gamepad bottom face button: forage, talk, interact
- `Q` / gamepad left face button: brew at a cauldron

The objective is deliberately simple: **get home to the tribe.**
