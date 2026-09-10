# FATEBORN V2 M1 Contracts & Shadow Core

Date: 2026-09-11

Tracking issue: `#2 [V2 M1] Contracts, Source Capture & Shadow Core`

Implementation status: **PASS**. The source-controlled M1 implementation, source capture, Rojo validations, Studio compilation checks, shadow comparisons, and guarded final-path Studio characterization all pass. Legacy remains authoritative.

## Objective

M1 establishes a typed vocabulary and non-authoritative read/resolve/calculate layer for current behavior. It does not cut over movement, input, combat, abilities, animation playback, stamina, character construction, spawning, respawning, persistence, or lifecycle.

The operating rule is: **observe, describe, and resolve; do not take over**.

## Source-of-truth verification

The full M0 audit was read before any repository edit. Current local source and the connected `FATEBORN` place (`placeId 79776008039106`) were then rechecked.

The important M0 findings still match:

- `Fateborn.legacy.luau` remains the main gameplay/lifecycle/combat authority.
- active movement uses the `PlayerMovement` client/server pair and `StaminaSystem`.
- only Half-Beast has a registered custom model/animation package.
- Human and all non-Half-Beast races retain the generic bone StarterCharacter path.
- generic bone animation IDs remain embedded in `PlayerMovement.local.luau`.
- Half-Beast IDs/tuning remain in `RaceCharacterModels.luau`.
- displayed aggregate Power includes Race Power, while active Basic/ability base damage does not.
- active Basic targeting remains a fixed 12-stud nearest-target scan with dot threshold; most `M1Config` race geometry/damage fields remain unused.
- the duplicate legacy `Action` Sprint/Dash paths and repeated `Block=true` parry refresh remain unchanged for M2.
- `HumanBoxingBones` remains enabled; `HumanBoxingCombo` remains enabled but immediately returns; both `HalfBeastAnimationLoader` instances remain enabled and empty.

No material repository change made the M0 architecture stale for M1.

## Final V2 structure

```text
ReplicatedStorage/
  FatebornV2/
    Shared/
      Contracts/
        ActionIds.luau
        CharacterStateKeys.luau
        CharacterAttributes.luau
      Character/
        CharacterContext.luau
        CharacterState.luau
      Race/
        RaceRegistry.luau
        RaceLoader.luau
        Definitions/
          Human.luau
          HalfBeast.luau
      Animation/
        AnimationCatalog.luau
        AnimationResolver.luau
      Stats/
        StatCalculator.luau
ServerScriptService/
  FatebornV2/
    Tests/
      LegacyContractCharacterization.server.luau
docs/migration/
  studio-source-capture/
    README.md
    StarterPlayer.StarterPlayerScripts.HumanBoxingBones.local.luau
    StarterPlayer.StarterPlayerScripts.HumanBoxingCombo.local.luau
    StarterGui.WheelUI.WheelLocalScript.local.luau
```

The recommended M0 runtime paths were used without deviation. Studio-only source was archived under `docs/`, which is not mapped by `default.project.json`, to prevent duplicate runtime scripts.

## Source capture

Exact source was archived for:

- `StarterPlayer.StarterPlayerScripts.HumanBoxingBones` — enabled LocalScript.
- `StarterPlayer.StarterPlayerScripts.HumanBoxingCombo` — enabled LocalScript, runtime-inert at its immediate return.
- `StarterGui.WheelUI.WheelLocalScript` — disabled LocalScript.

The captures were compared line-for-line against Studio after writing. SHA-256 hashes, unique IDs, original paths, Enabled state, RunContext, and behavioral notes are recorded in `studio-source-capture/README.md`.

The two enabled, empty `HalfBeastAnimationLoader` instances are recorded by unique ID. Their empty source was not duplicated unnecessarily because the synchronized zero-byte source already preserves that fact.

Studio-only StarterCharacter and Half-Beast model facts were revalidated and documented. Large/binary model, animation, enemy, and VFX assets were not exported or duplicated.

No live Studio instance or behavior was changed.

## Canonical action vocabulary

`ActionIds` records the exact current strings and the channels on which they occur:

| Semantic concept | Current string | Current channel(s) |
|---|---|---|
| Basic / M1 | `Basic` | `FatebornRemotes.Action` |
| Ability / Skill | `Ability` | `FatebornRemotes.Action` |
| Sprint | `Sprint` | both `FatebornRemotes.Action` and `PlayerMovement` |
| Roll | `Roll` | `PlayerMovement` |
| Block | `Block` | `CombatDefenseEvent` |
| Dash | `Dash` | legacy `FatebornRemotes.Action` |
| IntroSeen | `IntroSeen` | `FatebornRemotes.Action` |
| Studio debug hit | `DebugHit` | `CombatDefenseEvent`, Studio-only handler |

Duplicated Sprint and distinct Dash/Roll paths remain visible. Nothing is normalized or rerouted in M1.

## Canonical state vocabulary

`CharacterStateKeys` defines:

- Locomotion: `Idle`, `Walk`, `Run`, `Jump`, `Fall`, `Climb`, `Swim`, `SwimIdle`.
- Action: `None`, `Basic`/M1, `Roll`, `Block`, `Parry`, `AbilityCast`/Skill, `Dash`.
- Condition: `None`, `HitReaction`, `Flinch`, `Stagger`, `Finisher`, `Death`.

These names are vocabulary, not a state machine or mutual-exclusion policy.

## Canonical attribute mapping

`CharacterAttributes` centralizes exact current strings without renaming live data:

- Player resource/UI: `Stamina`, `MaxStamina`, `GameplayActive`.
- active/legacy identity: `Race`, `RaceName`, `FateRace`, `RaceTier`, `RaceDescription`, `RaceCharacterProfile`, `RaceCharacterAssetId`, `PlayerModelAssetId`, `FatebornBoneCharacter`.
- public profile/stat facts: `FatebornPlayerId`, `Ability`, `Power`, `StrengthPower`, `SpeedPower`, `DurabilityPower`, `FightingMasteryPower`, and legacy stat aliases.
- action/state: `BaseWalkSpeed`, `Sprinting`, `Dashing`, `RollStartedAt`, `Blocking`, `BasicAttackStartedAt`, `BasicAttackComboIndex`, `SkillCastStartedAt`, `HitReaction`, `HitReactionStartedAt`, `HitReactionUntil`, `Staggered`.
- current optional modifiers/diagnostics: M1 multipliers, `DamageTakenMultiplier`, `CombatFacingLock`, `LocalAnimationState`, and `LocalAnimationSource`.

Race/stat read-order arrays document the legacy fallback names used by `M1Config`.

## CharacterContext

`CharacterContext.Create(player?, character)` validates and returns a frozen facade containing:

- Player (optional), Character, Humanoid, optional existing Animator, and HumanoidRootPart.
- current race and race-character-profile identity.
- frozen snapshots of current Character and Player attributes.

The module also exposes read-only live attribute accessors. Construction creates no Animator, instance, connection, attribute, remote, spawn, or lifecycle mutation.

It does not own `LoadCharacter`, `Player.Character`, persistence, race assembly, combat, animation, or stamina.

## CharacterState shadow semantics

`CharacterState.GatherSignals(context)` reads current Humanoid state, velocity, FloorMaterial, health, and existing attributes.

`CharacterState.ResolveSignals(signals, now)` is a pure resolver. `CharacterState.Read(context, now?)` combines both.

The shadow channels behave as follows:

- Locomotion mirrors the legacy client selection inputs: Swimming/Climbing/Jumping/Freefall/Air, horizontal speed threshold `0.7`, and `Sprinting`.
- Condition reports Death or an active replicated reaction window, including Flinch/Stagger/Finisher.
- Action reports replicated, time-bounded Roll (`0.60` seconds) or Block when no reaction/death suppresses presentation.
- Basic/skill timestamps are retained as `LastActionCue`, with `Active=false`, because the server replicates no authoritative action end time.
- Parry is explicitly documented as unrepresentable from Player/Character attributes; it exists as a derived server outcome/client event.

The adapter writes nothing and does not establish a competing state machine.

## Race registry and pilots

`RaceRegistry` contains only Human and Half-Beast pilot definitions.

Human records:

- active Config rarity/power facts;
- legacy RaceData weight/description facts;
- Human `M1Config` profile facts and their unused-by-active-Basic status;
- generic bone StarterCharacter fallback;
- the enabled-but-uncued Studio Human boxing source.

Half-Beast records:

- active Config rarity/power facts;
- legacy RaceData facts;
- Half-Beast `M1Config` facts and their unused-by-active-Basic status;
- the registered custom grafted package and exact template/asset metadata;
- the custom animation profile.

`RaceRegistry.CompareLegacySources` accepts current source tables explicitly and reports roster/schema differences. It does not require legacy modules as a hidden dependency.

`RaceLoader.Resolve` returns a lookup descriptor only. Unknown/non-pilot races retain an identity-preserving generic StarterCharacter resolution; they are not silently relabeled Human. It never clones, reparents, grafts, calls `LoadCharacter`, or sets `Player.Character`.

### Remaining source divergence

- active Config and legacy RaceData have the same 35 displayed names but different schemas, descriptions, and probability models.
- `M1Config` has a divergent roster. Characterization confirms active `Elementalborn` is absent from M1 and M1 `Seraph` is absent from active Config.
- `M1Config` still silently falls back to Human for missing names in its own helpers.
- product-authoritative resolution of the full roster remains intentionally undecided.

## Animation catalog and resolver

`AnimationCatalog` captures:

- generic Walk `92954261547077`, Run `85618915186426`, and Roll `137733801815535` IDs from active `PlayerMovement`.
- all current Half-Beast animation IDs, source names, combo-slot mapping, and tuning from `RaceCharacterModels`.
- `Guard`, `Backstep`, and `Drink` as unused today.
- `UnclassifiedClip0` as intentionally not loaded.
- Human Basic as `PresentButUncued`, pointing to the captured Studio procedural source.

`AnimationResolver.Resolve(raceName, animationName)` returns a frozen descriptor and supports current semantic aliases. Missing assets produce `Available=false` with a reason. It never creates/loads/plays/stops tracks, writes bones, changes priorities, or owns animation arbitration.

## StatCalculator formulas

`StatCalculator` is pure and reproduces current behavior:

```text
displayedPower = floor((110 + Level*82 + Mastery*3.5)
  * product over current Fate categories of (1 + (Power - 1)*0.16))

baseDamage = (14 + Level*3.2 + Mastery*0.22)
  * StrengthPower * AbilityPower

MaxHealth = floor((100 + Level*7) * DurabilityPower)
MaxStamina = floor(100 * StaminaPower)
WalkSpeed = clamp(14 * SpeedPower, 12, 24)
JumpPower = clamp(50 * (0.94 + SpeedPower*0.08), 45, 65)

BasicDamage = baseDamage
  * current mastery multiplier
  * current combo-curve multiplier

AbilityDamage = baseDamage * move.Damage
```

It also reproduces current stat normalization, speed interval/hit-delay, durability damage-taken, mastery combo-cap/multiplier, and combo curves.

Race Power intentionally affects displayed aggregate Power but is absent from active Basic/ability damage. `M1Config` race Damage/Tempo/geometry and modifiers used only by dormant helpers are not introduced into the active formula.

No calculation writes Humanoid, Player, Character, stamina, or damage state.

## Characterization and shadow validation

The guarded Studio-only test Script covers:

1. exact action/attribute/state constants;
2. no communication instances created by requiring V2 modules;
3. Human generic fallback;
4. Half-Beast package parity;
5. race roster/schema divergence;
6. Half-Beast animation ID/tuning parity;
7. generic animation fallback IDs;
8. explicit missing, uncued, and unclassified animation states;
9. read-only CharacterContext construction;
10. representative CharacterState resolution and ambiguity preservation;
11. current stat formulas and Race Power/display-versus-damage distinction.

The Script is guarded by `RunService:IsStudio()` and has no production path. Its only created instances are unparented fixture Model/Humanoid/Part objects, destroyed at test completion.

Before Script Sync finished applying the new tree, equivalent in-memory Studio checks loaded the exact local module sources without creating persistent instances. Both data/stat/animation/race and character/state harnesses passed. All 13 new Luau files also compiled through Studio `loadstring`. After synchronization completed, the guarded final-path Script ran in Play and reported `FATEBORN V2 M1 characterization PASS (12 checks)`.

## Play validation

A bounded Studio Play session was run with the following hypothesis: unchanged legacy startup should create its existing remotes and report no startup error.

Result:

- `FATEBORN server ready — Prototype 0.1` and `FATEBORN client ready` were observed.
- runtime `FatebornRemotes`, `PlayerMovement`, `VFXEvent`, and `VFXLocal` existed.
- the synchronized V2 tree was present in both ReplicatedStorage and ServerScriptService.
- `FATEBORN V2 M1 characterization PASS (12 checks)` was observed from the guarded final-path test Script.
- no new startup error appeared in Output.
- Play was stopped after the bounded check.

Limitation: the session did not force live Human and Half-Beast character selection. Their registry/package/animation facts were compared against current legacy sources, and no legacy path was changed. Character selection was not bypassed, and production lifecycle/DataStore behavior was not changed solely to force race-path testing.

## Legacy systems that remain authoritative

- character slots, persistence, spawning, replacement, death, and respawn: `Fateborn.legacy.luau` and current CharacterSelect flow;
- input, locomotion physics, jump, animation selection/playback, and procedural posing: current client scripts, primarily `PlayerMovement.local.luau`;
- sprint/roll acceptance and stamina: current PlayerMovement server and `StaminaSystem`;
- M1, abilities, targeting, damage, cooldowns, block/parry/punish, rewards, and enemy/world bootstrap: `Fateborn.legacy.luau` plus current helper modules;
- hit reactions: `HitReactionSystem`;
- VFX dispatch/rendering: current server dispatch and `VFXClient`;
- character model construction: StarterCharacter plus current Half-Beast replacement/graft path.

No legacy script, module, remote, bindable, asset, instance, or runtime path was removed, renamed, disabled, or replaced.

## Out-of-scope confirmation

No ActionRouter, InputController takeover, AnimationController, CombatService, AbilityService, Resource/Stamina service extraction, StatusEffectSystem, ModifierSystem, PassiveSystem gameplay, CharacterFactory, or CharacterLifecycleService was implemented or activated.

The Sprint/Dash bypass, parry refresh, observer animation parity, M1 prediction, roll rotation, gameplay balance, race passives, and full race roster are unchanged.

## Validation performed

| Validation | Result |
|---|---|
| full M0 audit read before edits | PASS |
| current local source revalidation | PASS |
| Studio-only source/instance state revalidation | PASS |
| archived source line-for-line comparison | PASS |
| Studio syntax compilation of 13 new Luau files | PASS |
| in-memory Studio contract/race/animation/stat characterization | PASS |
| in-memory Studio CharacterContext/CharacterState characterization | PASS |
| `rojo sourcemap default.project.json --output <temporary>` | PASS |
| `rojo build default.project.json --output <temporary>` | PASS |
| bounded Studio Play legacy startup | PASS |
| final-path synchronized V2 Play characterization | PASS — 12 checks |

No Luau analyzer, Selene, or StyLua executable was installed in the current toolchain; Studio compilation and Rojo validation were used instead.

## Deviations from M0 recommendation

Runtime module paths match the M0 recommendation. The only implementation decision was to archive Studio-only source under the non-runtime `docs/migration/studio-source-capture/` location instead of mapping it into StarterPlayer, preventing duplicate active scripts.

## Unresolved decisions

1. product-authoritative 35-race roster and how/if `M1Config` divergence will be reconciled;
2. whether Race Power should ever affect combat rather than display only;
3. intended passive gameplay versus descriptive copy;
4. intended action mutual-exclusion policy;
5. Human Basic cue ownership and remote-observer animation parity;
6. whether configured M1 geometry/tempo/damage should replace the current scan/formula;
7. whether Half-Beast roll's track plus whole-model rotation is intentional;
8. asset ownership/permission/runtime-length validation;

## Risks carried into M2

- duplicate callable Sprint/Dash remote paths;
- repeated `Block=true` parry-window refresh;
- fragmented action/state validation;
- client-owned ordinary locomotion/jump physics;
- animation cue and observer asymmetry;
- race roster/schema divergence.

M2 must preserve current behavior while deliberately hardening routing; it must not assume `M1Config` is the active combat implementation.

## Files changed

- `ReplicatedStorage/FatebornV2/Shared/Contracts/ActionIds.luau`
- `ReplicatedStorage/FatebornV2/Shared/Contracts/CharacterStateKeys.luau`
- `ReplicatedStorage/FatebornV2/Shared/Contracts/CharacterAttributes.luau`
- `ReplicatedStorage/FatebornV2/Shared/Character/CharacterContext.luau`
- `ReplicatedStorage/FatebornV2/Shared/Character/CharacterState.luau`
- `ReplicatedStorage/FatebornV2/Shared/Race/RaceRegistry.luau`
- `ReplicatedStorage/FatebornV2/Shared/Race/RaceLoader.luau`
- `ReplicatedStorage/FatebornV2/Shared/Race/Definitions/Human.luau`
- `ReplicatedStorage/FatebornV2/Shared/Race/Definitions/HalfBeast.luau`
- `ReplicatedStorage/FatebornV2/Shared/Animation/AnimationCatalog.luau`
- `ReplicatedStorage/FatebornV2/Shared/Animation/AnimationResolver.luau`
- `ReplicatedStorage/FatebornV2/Shared/Stats/StatCalculator.luau`
- `ServerScriptService/FatebornV2/Tests/LegacyContractCharacterization.server.luau`
- `docs/migration/studio-source-capture/README.md`
- `docs/migration/studio-source-capture/StarterPlayer.StarterPlayerScripts.HumanBoxingBones.local.luau`
- `docs/migration/studio-source-capture/StarterPlayer.StarterPlayerScripts.HumanBoxingCombo.local.luau`
- `docs/migration/studio-source-capture/StarterGui.WheelUI.WheelLocalScript.local.luau`
- `docs/migration/V2_M1_CONTRACTS_SHADOW_CORE.md`

The pre-existing untracked `docs/migration/V2_M0_LEGACY_AUDIT.md` was read but not modified.

## M1 exit criteria

| Criterion | Result |
|---|---|
| M0 audit read and used | PASS |
| Studio-only Human animation source safely captured | PASS |
| ActionIds | PASS |
| CharacterStateKeys | PASS |
| CharacterAttributes | PASS |
| non-authoritative CharacterContext | PASS |
| read-only CharacterState | PASS |
| RaceRegistry | PASS |
| Human definition | PASS |
| Half-Beast definition | PASS |
| lookup-only RaceLoader | PASS |
| race-source divergence visible/documented | PASS |
| AnimationCatalog | PASS |
| descriptor-only AnimationResolver | PASS |
| pure current-formula StatCalculator | PASS |
| characterization tests added | PASS |
| characterization tests executed from final synchronized path | PASS |
| legacy gameplay remains authoritative | PASS |
| no gameplay cutover | PASS |
| no legacy runtime removal | PASS |
| no M2+ service activation | PASS |
| Rojo sourcemap | PASS |
| Rojo build | PASS |
| M1 documentation | PASS |

M1 is **PASS** against the requested exit criteria. GitHub issue #2 was not closed.

## Recommended next step

Review the M1 diff and Studio characterization evidence, then begin M2 Action Routing & Network Hardening as a separate approved milestone. Start by specifying one canonical action boundary while preserving current payloads and characterization of the Sprint/Dash and repeated Block-start quirks before changing them.
