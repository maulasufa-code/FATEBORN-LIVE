return [==[
# Project memory
## Overview
FATEBORN is a Roblox RPG with fate reroll systems. Character identity is generated through the Wheel of Existence: player spins separate wheels per category (Race first, then others after quests). No reroll initially; each spin is permanent.
## Where things live
- Main server script: ServerScriptService.Fateborn
- World building: Workspace.SpawnCandidate (asset 82580521449305), moved so its bottom sits at y=0 near original spawn point (0, 24)
- Active movement client: StarterPlayer.StarterPlayerScripts.PlayerMovement
- Active movement server: ServerScriptService.PlayerMovement
- Stamina module: ServerStorage.ZeroScript.StaminaSystem
- Hit reaction/stagger module: ServerStorage.ZeroScript.HitReactionSystem
- Reusable enemy AI state machine: ServerStorage.ZeroScript.EnemyAISystem
- Stamina HUD: StarterGui.StaminaHUD with LocalScript StaminaClient; uses a very small, thin, continuous-looking vertical curved bar shaped like ")" beside the local character, no numeric text. It is screen-space tracked with a fixed pixel offset to the right of the character, so it stays on the player's right side regardless of facing direction and does not overlap the body. The bar uses many tightly overlapping strips to appear seamless; yellow/orange fill decreases along the curve. The old bottom-screen bar stays hidden.
- Config module: ReplicatedStorage.Shared.Config
- Race spin system: ServerStorage.ZeroScript.SpinSystem
- Race data: ServerStorage.ZeroScript.Data.RaceData
- Client copy of RaceData: ReplicatedStorage.ZeroScript.Data.RaceData
- Race spin server script: ServerScriptService.RaceSpinHandler
- Race spin RemoteEvent: ReplicatedStorage.SpinRaceEvent
- Wheel UI: StarterGui.WheelUI (MainFrame) with LocalScript WheelLocalScript
- Current Wanderer NPC visual: ServerStorage.WandererModel5 (Wanderer Wibs, shares MeshId with Model4)
- FallenKing also uses WandererModel5 visual
- Other wanderer models: WandererModel (mummy), WandererModel2, WandererModel3, WandererModel4 (all private/unavailable mesh/texture assets; do not use)
- FallenKing stats boosted: Level 35, MaxHealth 12000, Damage 75, Gold 650, Exp 1800, Essence 150, Fragments 35
- Lantern tool: StarterPack.Lantern
- Bright moon: Workspace.Moon
## Conventions
- Enemies are generated procedurally in createEnemy; visual mesh models are welded to hidden root parts.
- Use Config.Rarity colors and Config.Enemies stats.
## Key systems
- createWorld builds map; createEnemy spawns enemies from spawnDefinitions.
- Main BGM is created in StarterPlayer.StarterPlayerScripts.Fateborn using SoundService. It stays Looped and keeps playing continuously from intro into gameplay; gameplay volume is 85% of intro volume (15% quieter) via a smooth tween, without stopping or resetting TimePosition.
- Wheel of Existence: spin categories in order (Race -> Potential -> Ability -> Weakness -> Attributes -> Weapon Affinity -> Backstory -> Alignment). Race spin only currently.
- Stamina is server-authoritative via ServerStorage.ZeroScript.StaminaSystem. Player attributes Stamina/MaxStamina replicate to HUD. Current tuning: Max 100, sprint 18/sec while moving, roll cost 25, regen delay 1.5 sec, regen 20/sec. Block now uses BlockDrainPerSecond 12 via SetDrain.
- Block + Parry: active client input and floating indicators are integrated into StarterPlayer.StarterPlayerScripts.Fateborn (hold V) using ReplicatedStorage.CombatDefenseEvent; do not rely on the separate CombatDefenseClient, which did not clone into PlayerScripts during verification. Server logic lives in ServerScriptService.Fateborn. Perfect parry window scales from Fate.FightingMastery Power (~0.16s Novice up to ~0.30s top tier), opens a punish window on the attacking enemy, and Fighting Mastery Master+ (Power >= 1.30) unlocks Advanced Counter. Normal block reduces incoming damage to 28%. Floating BLOCK / PERFECT PARRY / PUNISH / ADVANCED COUNTER / GUARD BREAK indicators appear briefly near combat. Perfect Parry was verified in Studio with a deterministic debug hit through the same resolveIncomingDamage path: player HP stayed 100, block released, and Wanderer received PunishableByUserId/PunishUntil.
- Hit reaction/stagger is server-authoritative via ServerStorage.ZeroScript.HitReactionSystem. Reactions use HitReaction/HitReactionStartedAt/HitReactionUntil/Staggered character-model attributes. Light hits cause short flinch; heavy hits build stagger pressure and stagger only when pressure reaches the target's DurabilityPower, so higher Durability takes more heavy pressure and also shortens reaction duration; finishers apply knockback scaled down by Durability. Reaction locks cancel sprint, reject roll/basic/ability inputs, interrupt enemy ActionToken/ActionEnd, and PlayerMovement/EnemyAnimation render distinct reaction poses. Current Fateborn mapping: Basic = Light, normal damaging abilities = Heavy, Awakening = Finisher; boss finishers downgrade to Heavy instead of knockback.
- Enemy AI is driven by ServerStorage.ZeroScript.EnemyAISystem and called from ServerScriptService.Fateborn. It exposes explicit replicated AIState/AITier attributes and supports Patrol, Aggro, Chase, Attack, Retreat, Stagger, Death, plus hard leash-to-spawn behavior. Tier profiles are Standard, Elite, MiniBoss, Boss; current non-boss enemies default Standard and Boss=true resolves to Boss. Attack/skill execution and boss phase logic remain in Fateborn while EnemyAISystem owns target acquisition, movement/state transitions, patrol points, tactical low-health retreat, stagger/death overrides, and leash reset.
- Target lock client: StarterPlayer.StarterPlayerScripts.TargetLock. Hold MouseButton2 (right click) to soft-lock; releasing RMB unlocks immediately. While held, horizontal mouse movement switches to eligible enemies on the left/right within range. Targets models with Enemy=true, writes Player.TargetLockTarget ObjectValue, sets CombatFacingLock for strafe-facing, follows the target with the camera, auto-reacquires while RMB remains held, and auto-breaks on invalid/dead/out-of-range targets. StarterPlayerScripts.Fateborn cameraDirection() uses TargetLockTarget when valid so existing M1 and abilities aim toward the locked enemy.
- Gameplay/menu state controller: StarterPlayer.StarterPlayerScripts.GameplayMouse. During gameplay MouseBehavior is LockCenter and cursor is hidden; holding LeftAlt or RightAlt temporarily releases/shows it. Menu state has priority for the active Character Select and Fateborn Intro/Wheel/Inspect/Boost panels, which automatically release/show the cursor and hide gameplay-only UI. Legacy StarterGui WheelUI/RaceWheelGui are intentionally NOT used to determine menu state because their frames may remain Visible and falsely keep the cursor unlocked during gameplay. GameplayMouse writes Player.GameplayActive=true only during gameplay. Gameplay-only roots in FATEBORN_UI are named GameplayTitleBar, GameplayStatusHUD, GameplayMenuBar, GameplayNotifications, GameplayActionBar, and GameplayControls; StaminaHUD and FATEBORN_HOTBAR are also hidden in menu state. StaminaClient additionally checks GameplayActive before showing CharacterStaminaArc, so stamina never appears in menu states. Returning to gameplay restores those HUDs and locks/hides the cursor.
## Decisions & gotchas
- StarterPlayerScripts.MovementController and MovementControllerV2 are disabled; active movement uses PlayerMovement + ReplicatedStorage.PlayerMovement RemoteEvent.
- Stamina sprint drain only applies while Humanoid.MoveDirection magnitude > 0.05; holding Shift while stationary does not drain stamina. Sprint auto-stops when stamina reaches zero. Roll is rejected when stamina is insufficient.
- External mesh models from Meshy may have private mesh/texture assets, causing plain or rock-like appearance for other players.
- Meshy animations do NOT animate the custom VioletWarden mesh because the rig has no Motor6D. Currently using procedural bone animation in CustomVisualAnimation instead.
- ScaleTo uses the asset's original size, not current size.
- generate_texture fails for private mesh assets.
- Custom player visual attempts removed; player uses default Roblox body for now.
- Studio-only startup bypass is active for testing: StarterPlayerScripts.Fateborn skips the intro/wheel when RunService:IsStudio(), CharacterSelect returns immediately in Studio, and StarterPlayerScripts.StudioDebugBypass disables FATEBORN_CHARACTER_SELECT / RaceWheelGui / WheelUI if they appear. StudioDebugBypass was verified cloned and set Player.StudioDebugBypass=true. ServerScriptService.Fateborn also auto-selects/creates debug slot 1 in Studio and initializes profiles[player]/activeSlots[player], setting Player.StudioDebugProfile=true; this is required because M1/abilities return early when profiles[player] is nil. Verified M1 damage after this fix: Wanderer HP 85 -> 67.8 (17.2 damage) at ~5 studs.
## User preferences
- Indonesian language; concise replies.
- When editing combat systems, do not start/stop Play test unless the user explicitly asks.
## Open questions / TODO
- None
]==]