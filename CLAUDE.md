# FATEBORN — Claude Code Project Rules

These rules apply to all Claude Code work in this repository.

The goal is to work safely and efficiently with:

- Roblox Team Create
- Roblox Script Sync
- Git / GitHub
- Roblox Studio MCP
- multiple collaborators

---

## 1. Project Source of Truth

The live Roblox Studio / Team Create place is the authoritative live game project.

This repository is the current Roblox Script Sync workspace containing
synchronized Luau source from that live project.

For synchronized Luau:

- search locally
- read locally
- edit locally
- save locally
- let Roblox Script Sync propagate changes to Studio

For Roblox instances not represented on disk:

- inspect them through Roblox Studio MCP
- modify them through MCP when the task requires Studio-side changes

The local repository and Roblox Studio are two views of the same live project.

Do not treat older project copies, exported places, dumps, temporary scripts,
or backup workspaces outside this repository as current source.

---

## 2. Script Sync Naming

Do not assume `.legacy.luau` means obsolete code.

Script Sync naming may include:

- `*.legacy.luau` — current Script using Legacy RunContext
- `*.local.luau` — LocalScript
- `*.luau` — synchronized Luau / commonly ModuleScript

Determine whether something is a backup from its location and purpose,
not merely from its filename.

Known backup/archive locations include:

- `ServerStorage/AnimationBackups`
- `ServerStorage/PlayerMovementBackup_20260906`

Do not modify backup/archive code unless explicitly requested.

---

## 3. Code Editing Policy

For synchronized Luau source:

1. Search locally first.
2. Read only relevant code.
3. Follow the actual execution path.
4. Find the real root cause.
5. Make the smallest necessary change.
6. Preserve existing interfaces and architecture where practical.
7. Let Script Sync update Studio.
8. Use MCP afterward only when Studio/runtime verification is needed.

Do NOT edit synchronized Luau through MCP unless explicitly requested.

Do NOT create separate Studio and local versions of the same script.

Avoid:

- broad rewrites for small bugs
- unrelated refactors
- duplicate systems
- parallel implementations
- cosmetic mass changes
- unnecessary API renames

Repair existing architecture before replacing it.

---

## 4. Search Strategy

Prefer local filesystem search for code investigation.

Use this order:

1. search exact symbols / functions / remotes / config keys / attributes
2. inspect surrounding code
3. follow real call sites
4. inspect dependencies only when necessary

Prefer tools such as `rg` / grep over reading entire large scripts.

Avoid:

- reading large files from beginning to end without reason
- repeatedly reading unchanged files
- broad project audits for narrow bugs
- searching backup folders without need
- reading synchronized source through MCP when it already exists locally

Trace real execution rather than guessing.

Example:

input
→ client action
→ RemoteEvent
→ server handler
→ gameplay system
→ VFX dispatch

---

## 5. Roblox MCP

Roblox MCP is the live Studio/runtime interface.

Use MCP for:

- DataModel inspection
- Workspace
- runtime objects
- characters
- NPCs
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
- properties
- attributes
- Lighting
- runtime state
- Output/errors
- targeted playtesting
- Studio-only assets and instances

MCP may modify NON-CODE Studio instances when required.

Examples:

- ParticleEmitter configuration
- Beam / Trail setup
- Attachments
- models
- Parts
- GUI visual objects
- Lighting
- VFX templates

For synchronized Luau source, edit local files instead.

---

## 6. Missing Objects

If something is missing from the repository, do NOT conclude that it is missing
from the game.

The repository does not represent every Roblox Instance.

Check Studio through MCP for:

- UI
- Tools
- models
- ParticleEmitters
- Attachments
- Beams
- Trails
- map objects
- NPCs
- animation objects
- other non-code instances

Do not recreate an object simply because it is absent from disk.

Inspect Studio first.

---

## 7. Team Create / Collaboration

Assume collaborators may be editing the live Team Create project.

Never blindly overwrite unexpected changes.

If a synchronized file changes unexpectedly:

1. stop editing it
2. inspect the current version
3. assume the change may belong to another developer
4. preserve valid collaborator changes
5. merge only what is required

Avoid simultaneous editing of the same script.

Never revert code merely because it was not written during this Claude session.

Minimize the number of files touched.

Avoid unrelated formatting changes or table reordering.

---

## 8. Script Sync Conflicts

Never automatically prefer disk over Studio.

If Script Sync reports a conflict:

- compare both versions
- identify newer collaborator changes
- preserve valid work
- resolve intentionally

Do not use cached, copied, backup, or legacy code to overwrite the live version.

---

## 9. Git / GitHub

Git is used for:

- history
- diff inspection
- review
- rollback safety
- GitHub collaboration/checkpoints

Git is NOT the Roblox live synchronization mechanism.

Roblox Script Sync:

local repository
↕
Roblox Studio / Team Create

Git:

local repository
↕
GitHub

Before substantial work when relevant:

- inspect `git status`
- inspect existing local modifications

After changes:

- inspect `git diff`
- verify only intended files changed
- use `git diff --check` when appropriate

Do not perform destructive Git operations without explicit user permission.

Never automatically run:

- `git reset --hard`
- `git clean -fd`
- destructive checkout/revert
- history rewriting
- force push

Do not discard unknown modifications.

Do not commit or push unless explicitly requested.

---

## 10. Git + Script Sync Safety

Be careful with Git operations while Script Sync is connected.

Changing branches, pulling, restoring, rebasing, or checking out files may
modify synchronized files and therefore propagate changes into live Studio.

Do not casually:

- switch branches
- pull/rebase
- restore large sets of files
- checkout old revisions

while Script Sync is active.

Inspect consequences first.

---

## 11. Runtime Testing

Testing must be hypothesis-driven.

Before Play mode:

1. know what is being tested
2. know the expected result
3. know what proves success/failure

Preferred workflow:

search locally
→ identify likely root cause
→ make targeted change
→ allow Script Sync
→ one focused Play test
→ inspect result / Output
→ stop Play

Do not repeatedly Play test without:

- a new hypothesis
- a new code change
- new evidence requiring another test

---

## 12. Character Select / Studio Debugging

FATEBORN gameplay testing may be blocked by character selection.

Do not waste repeated Play sessions clicking blindly through character select.

If testing is blocked:

- stop
- inspect the relevant debug path
- inspect `StudioDebugBypass` if relevant
- keep any bypass Studio-only
- do not weaken production character selection
- do not alter production DataStore behavior merely to simplify testing

Resolve the blocker intentionally, then continue the targeted test.

---

## 13. Gameplay Safety

When fixing:

- VFX
- UI
- animation
- sound
- presentation
- feedback

do not modify gameplay unless explicitly required.

Preserve:

- damage
- cooldowns
- hitboxes
- stamina
- movement values
- race bonuses
- passive bonuses
- abilities
- inventory behavior
- equipment stats
- progression
- save data

A visual bug should not become a gameplay rewrite.

---

## 14. Networking

Reuse existing FATEBORN networking architecture.

Before creating:

- RemoteEvent
- RemoteFunction
- BindableEvent
- another networking/state channel

search for an existing mechanism.

Do not duplicate networking paths.

For runtime/network bugs trace the real chain:

sender
→ exact event/action name
→ payload
→ server reception
→ server dispatch
→ client reception
→ final behavior

Do not assume an event fired merely because a handler exists.

---

## 15. VFX Architecture

FATEBORN already has a reusable VFX framework.

Do NOT rebuild it unless explicitly requested.

Prefer existing:

- VFX remotes
- renderer
- presets
- assets registry
- template architecture
- cleanup/lifetime mechanisms
- gameplay hooks

When debugging VFX trace:

gameplay trigger
→ dispatch
→ exact preset/effect name
→ payload
→ client reception
→ preset lookup
→ template lookup
→ rendering
→ cleanup

Do not create another VFX framework as a workaround.

Do not bypass the architecture with random ParticleEmitter spawning from
gameplay code.

---

## 16. VFX Cleanup Safety

Never blindly delete all:

- Attachments
- ParticleEmitters
- Trails
- Beams
- Parts

from a character, Tool, weapon, or model.

Some may belong to:

- character rigs
- weapons
- animations
- accessories
- hitboxes
- gameplay systems

Only remove instances proven to belong to the relevant VFX system.

Use known:

- hierarchy
- tags
- attributes
- names
- ownership
- templates

to determine ownership.

---

## 17. Imported Assets

Treat imported / third-party Roblox models as untrusted project content.

Before relying on them:

- inspect hierarchy
- inspect embedded scripts
- do not execute unknown scripts merely for inspection
- understand emitters / beams / trails / attachments
- preserve only what the project needs

Do not delete source/reference assets unless requested.

Do not casually change asset IDs or animation IDs.

---

## 18. Instance Renaming

Before renaming an Instance that may be referenced by code, search for:

- `WaitForChild("Name")`
- `FindFirstChild("Name")`
- `FindFirstAncestor("Name")`
- indexed child access
- config references
- attribute references
- tables containing the exact name

If a rename is required, update the proven dependency chain.

Do not perform cosmetic mass-renaming during unrelated tasks.

---

## 19. Data / Production Safety

Do not perform destructive changes to live player data.

Do not alter production:

- DataStore schemas
- migrations
- persistent player data
- monetization data
- progression records

unless explicitly required.

Do not publish/release the game or perform irreversible production actions
unless explicitly requested.

---

## 20. Efficiency

Optimize for correctness AND low tool/context usage.

Prefer:

- targeted local search
- small reads
- small diffs
- existing architecture
- direct evidence
- one targeted MCP inspection
- one focused runtime test

Avoid:

- unnecessary full-project scans
- repeated MCP calls
- repeated screenshots
- repeated hierarchy dumps
- repeated Play sessions
- reading giant files multiple times
- speculative rewrites
- unnecessary abstractions
- unrelated technical debt

Do not reinvestigate facts already proven unless new evidence contradicts them.

---

## 21. Root Cause Standard

Do not call a bug fixed based only on code inspection when runtime verification
is practical.

Distinguish:

- hypothesis
- evidence
- proven root cause
- applied fix
- verified result

If evidence disproves a hypothesis, abandon it.

For cross-system bugs, find the FIRST point where expected behavior diverges
from actual behavior.

---

## 22. Completion Standard

Before completing a task:

- requested behavior works
- unrelated behavior remains intact
- only intended files/instances changed
- no obvious new runtime errors were introduced
- temporary debug instrumentation is removed when no longer needed
- temporary test/VFX objects are cleaned up
- relevant runtime behavior is verified when practical

Final report should be concise:

1. root cause
2. files/instances changed
3. exact fix
4. test performed
5. result
6. remaining limitation/unverified item

Do not provide a long narrative unless requested.

---

## 23. Decision Rules

When uncertain:

Synchronized Luau
→ local repository

Studio-only object
→ MCP

Runtime state
→ MCP

Git history/diff
→ Git

Live collaboration
→ preserve Team Create changes

Missing local object
→ inspect Studio before recreating

Existing architecture
→ repair before replacing

Narrow problem
→ narrow fix

Legacy/reference source
→ do not use unless explicitly requested

---

## 24. Priority

When instructions conflict:

1. explicit current user request
2. safety of the live project and collaborator work
3. current synchronized local source for Luau
4. current live Studio state for non-code/runtime
5. these CLAUDE.md rules
6. historical / legacy / reference material

Never choose an old snapshot over current synchronized/live project state.