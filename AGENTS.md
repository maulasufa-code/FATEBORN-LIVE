# FATEBORN Development Rules

These rules apply to all work performed inside this workspace.

---

## 1. Project Architecture and Source of Truth

The live Roblox Studio / Team Create place is the authoritative game project.

`E:\FATEBORN-LIVE` is the current Roblox Script Sync workspace and contains
the synchronized Luau source for the live project.

For synchronized Luau source:
- read locally
- search locally
- edit locally
- let Roblox Script Sync propagate changes into Studio

For Roblox instances that are not represented on disk:
- inspect and modify them through Roblox Studio / MCP when required

The local filesystem and Roblox Studio are two views of the SAME live project,
not separate project versions.

### Legacy workspace

`E:\roblox-ws` is OLD / LEGACY / REFERENCE ONLY.

NEVER:
- treat `E:\roblox-ws` as current source
- copy old code from it into the live project without explicit instruction
- use its `.rbxl`, `.rbxlx`, dumps, temporary scripts, or generated files as
  authoritative current project state

Only inspect legacy files if the user explicitly asks for historical comparison
or recovery.

---

## 2. Important Script Sync Naming

Do not misinterpret Script Sync filename suffixes.

Examples:

- `*.legacy.luau` may represent a current Roblox Script using Legacy RunContext
- `*.local.luau` represents synchronized LocalScript source
- `*.luau` may represent synchronized ModuleScript source

A `.legacy.luau` suffix does NOT automatically mean the file is an old backup.

Determine whether something is actually a backup from its project location
and purpose, not from the filename suffix alone.

Known backup/archive locations include:

- `ServerStorage/AnimationBackups`
- `ServerStorage/PlayerMovementBackup_20260906`

Do not modify backup/archive content unless explicitly requested.

---

## 3. Code Editing Policy

For any Script Sync managed source file:

1. Search locally first.
2. Read only the relevant file/range.
3. Understand the existing execution path.
4. Make the smallest change that solves the requested problem.
5. Preserve existing public interfaces unless changing them is necessary.
6. Let Script Sync propagate the modification into Studio.
7. Use MCP only afterward if runtime or Studio-side verification is needed.

Do NOT edit the same synchronized script through MCP.

Do NOT maintain separate local and Studio versions of the same script.

Do NOT:
- rewrite an entire system for a small bug
- refactor unrelated code
- rename APIs casually
- duplicate an existing system
- create parallel implementations when an existing implementation can be fixed
- replace working architecture simply because another design is cleaner

Prefer fixing the actual root cause.

---

## 4. Local Search Strategy

Use local filesystem tools for code investigation whenever possible.

Preferred order:

1. `rg` / grep for symbols, remote names, functions, attributes, and call sites
2. inspect relevant surrounding code
3. follow the real call chain
4. inspect dependent files only when required

Avoid:
- opening large scripts from top to bottom without reason
- repeatedly reading unchanged files
- broad whole-project audits for narrow bugs
- searching backup folders unless relevant
- MCP script reads when the synchronized source already exists locally

When debugging a runtime flow, trace the actual path rather than guessing.

Example:

`input -> client action -> RemoteEvent -> server handler -> system -> VFX dispatch`

---

## 5. Roblox MCP Policy

Roblox MCP is primarily the live Studio/runtime interface.

Use MCP for:

- DataModel hierarchy inspection
- Workspace state
- runtime instances
- character/NPC inspection
- StarterGui visual hierarchy
- Tools
- models
- map/build objects
- ParticleEmitters
- Beams
- Trails
- Attachments
- animation objects
- VFX templates
- properties/attributes
- runtime state
- Output/errors
- targeted playtesting
- Studio-only assets and instances

### MCP writes

MCP MAY create/edit/delete NON-CODE Studio instances when the requested task
requires it.

Examples:

- ParticleEmitter properties
- Attachments
- Beam/Trail setup
- VFX templates
- Models
- Parts
- GUI visual objects
- Lighting
- other Studio-only instances

For synchronized Luau source, edit LOCAL files instead.

Only edit synchronized code through MCP if the user explicitly requests
Studio-side code editing.

---

## 6. Missing Objects

If an object cannot be found locally, do NOT conclude that it does not exist.

The local workspace does not contain every Roblox instance.

Check the live Studio DataModel through MCP for:

- UI objects
- Tools
- models
- ParticleEmitters
- Attachments
- Beams
- Trails
- map objects
- NPC instances
- animation objects
- other non-script instances

Likewise, do not recreate something simply because it is absent from disk.

Inspect Studio first.

---

## 7. Script Sync Conflict Safety

Other developers may edit the live Team Create project.

Never blindly resolve a Script Sync conflict.

Never automatically prefer disk over Studio.

If a synchronized source file differs unexpectedly:

1. stop modifying that file
2. inspect the current synchronized local state
3. determine whether Studio contains newer collaborator work
4. preserve collaborator changes
5. merge only the required modification

Do not overwrite recent Team Create changes with cached or legacy source.

Avoid simultaneous modification of the same script by multiple developers.

---

## 8. Git Safety

Git is used for:

- history
- diff inspection
- rollback safety
- review of Codex changes

Before substantial work, inspect repository state when relevant.

After modifications, inspect the diff and ensure only intended files changed.

Useful checks:

- `git status`
- `git diff`
- `git diff --check`

Do NOT perform destructive Git operations unless explicitly requested.

Never automatically run:

- `git reset --hard`
- `git clean -fd`
- destructive checkout/revert of unrelated files
- history rewriting
- force push

Do not discard modifications that may belong to the user or collaborators.

Do not create commits unless requested or the current task explicitly includes
committing changes.

---

## 9. Collaboration Rules

Assume another Team Create collaborator may be working at the same time.

Therefore:

- minimize the number of files touched
- do not make formatting-only changes across unrelated files
- do not reorder large tables unless necessary
- do not rename large sets of instances without need
- preserve changes that are unrelated to the task
- never revert code merely because it was not authored in the current session

One script should ideally have one active editor at a time.

If unexpected changes appear during a task, treat them as potentially valid
collaborator changes.

---

## 10. Runtime Testing Policy

Testing must be hypothesis-driven.

Do not repeatedly start and stop Play mode merely to "see what happens."

Before starting Play:

1. identify what is being tested
2. identify the expected result
3. identify the signal that proves success/failure

Then perform the smallest useful runtime test.

Preferred workflow:

1. search local source
2. identify likely root cause
3. make targeted edit
4. allow Script Sync to propagate
5. enter Play mode
6. execute the exact relevant action
7. inspect visual/runtime result and Output
8. stop Play
9. make another change only if new evidence justifies it

Avoid repeated Play sessions with no code change or new hypothesis.

---

## 11. Character Select / Studio Testing

FATEBORN may require character selection before normal gameplay becomes
available.

Do not waste repeated Play sessions interacting blindly with the character
selection screen.

If a runtime test is blocked by Studio character-selection/debug behavior:

- stop the test
- inspect the relevant Studio-only/debug path
- investigate `StudioDebugBypass` if relevant
- keep any bypass strictly Studio-only
- do not alter production character selection merely to make testing easier
- do not modify production DataStore behavior just to bypass Studio testing

Resolve the test blocker once, then continue the targeted test.

---

## 12. Gameplay Safety

When fixing presentation, VFX, UI, animation, or feedback bugs:

Do not modify gameplay mechanics unless the task requires it.

Preserve unless explicitly requested:

- damage
- cooldowns
- hitboxes
- stamina costs
- movement values
- race bonuses
- passive bonuses
- ability behavior
- inventory behavior
- equipment stats
- save data
- progression logic

A visual bug should not silently become a gameplay rewrite.

---

## 13. Networking and Remote Contracts

Reuse existing networking architecture.

Before creating a new:

- RemoteEvent
- RemoteFunction
- BindableEvent
- shared state channel

search for an existing mechanism first.

Do not create duplicate networking paths for a system that already has one.

When changing an event contract, inspect both sender and receiver.

For runtime bugs involving remotes, trace:

- who fires it
- exact event/action name
- payload
- server reception
- server dispatch
- client reception
- final lookup/render/action

Do not assume an event was sent merely because a handler exists.

---

## 14. VFX Architecture

FATEBORN already has an existing reusable VFX framework.

Do NOT rebuild the VFX framework unless explicitly requested.

Prefer:

- existing VFX remotes
- existing renderer
- existing presets
- existing template architecture
- existing cleanup/lifetime mechanisms

When implementing or fixing VFX:

1. identify the gameplay dispatch
2. verify the exact preset/effect name
3. verify payload
4. verify client reception
5. verify preset/template lookup
6. verify rendering
7. verify cleanup

Do not spawn random direct ParticleEmitters from gameplay code as a workaround
when the existing VFX system should handle the effect.

Do not create duplicate VFX systems.

Do not leave persistent temporary VFX instances attached to characters.

When cleaning VFX instances, remove only instances proven to belong to the VFX
system. Never blindly delete all Attachments, Trails, Beams, or
ParticleEmitters from a character.

---

## 15. Imported Assets / Models

Treat imported models and third-party assets as untrusted project content.

Before relying on an imported asset:

- inspect its hierarchy
- inspect scripts if present
- do not execute unknown scripts merely to inspect the asset
- preserve only the parts required by the project

Do not delete imported source packs or reference assets unless explicitly
requested.

Do not change asset IDs, animation IDs, or external references without need.

---

## 16. Renaming Instances

Before renaming a Roblox instance that may be referenced by code:

search for exact-name access such as:

- `WaitForChild("Name")`
- `FindFirstChild("Name")`
- `FindFirstAncestor("Name")`
- indexed child access
- attributes/config entries containing the name

If references exist, update the complete proven dependency chain.

Do not perform cosmetic instance renames during unrelated tasks.

---

## 17. Data and Production Safety

Do not perform destructive operations against live player data.

Do not alter:

- DataStore schemas
- save migrations
- production persistence
- monetization data
- live progression data

unless explicitly required by the task.

Studio testing changes must remain safe for development.

Do not publish/release the game or perform irreversible production actions
unless explicitly requested.

---

## 18. Performance and Scope

Optimize for both correctness and tool efficiency.

Prefer:

- targeted search
- small diffs
- existing architecture
- one focused test
- direct evidence

Avoid:

- unnecessary full-project scanning
- repeated MCP calls
- repeated screenshots
- repeated Play sessions
- reading giant files multiple times
- speculative rewrites
- creating unnecessary abstractions
- solving unrelated technical debt during a focused task

When a problem is localized, keep the solution localized.

---

## 19. Root-Cause Standard

Do not declare a bug fixed based only on code inspection.

For bugs where runtime verification is possible, distinguish between:

- suspected cause
- proven cause
- applied fix
- verified result

If evidence disproves a hypothesis, abandon it instead of repeatedly testing the
same assumption.

For cross-system bugs, find the first point where expected behavior diverges
from actual behavior.

---

## 20. Completion Standard

Before considering a task complete:

- requested behavior is implemented
- unrelated gameplay is preserved
- no unintended files were changed
- no obvious runtime errors were introduced
- temporary debug instrumentation is removed unless useful permanently
- temporary VFX/test objects are cleaned up
- relevant runtime behavior is verified when practical

Final report should be concise and contain:

1. root cause, if applicable
2. files/instances changed
3. what was changed
4. test performed
5. result
6. any remaining limitation or unverified item

Do not provide a long narrative unless requested.

---

## 21. Priority Rule

When instructions conflict, use this priority:

1. the user's explicit current request
2. safety of live project and collaborator work
3. current synchronized local source for code
4. current live Studio state for non-code/runtime
5. these project rules
6. legacy/reference material

Never choose a legacy snapshot over current synchronized/live project state.