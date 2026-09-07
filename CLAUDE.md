# FATEBORN — Claude Code Development Rules

These instructions govern all Claude Code work inside this repository.

The goal is to work efficiently on the live FATEBORN Roblox project without
creating conflicts between local source, Roblox Script Sync, Team Create,
Git/GitHub, collaborators, and Roblox Studio MCP.

---

## 1. Current Project

This repository is the current FATEBORN development workspace.

The live Roblox Studio / Team Create place is the authoritative live game state.

The repository contains Roblox Script Sync mirrors of the live Luau source.

Think of the project as:

Local synchronized Luau
    ↕ Roblox Script Sync
Roblox Studio
    ↕ Team Create
Live FATEBORN project

Git/GitHub provides history, review, backup, and collaboration checkpoints.

Roblox MCP provides access to the live Studio DataModel and runtime.

---

## 2. Never Use Old Project Copies as Current Source

Do not use older FATEBORN workspaces, exported places, backups, dumps,
temporary scripts, generated inspection files, or copied source as current
authoritative code.

In particular, files outside this repository must be treated as
legacy/reference unless the user explicitly asks to inspect or recover them.

Never copy old code into the current project merely because it appears more
complete.

Always prefer:

1. current synchronized repository source for Luau
2. current Studio state for Studio-only objects/runtime
3. legacy/reference material only when explicitly needed

---

## 3. Script Sync File Naming

Do not assume that a filename containing `legacy` is obsolete.

Roblox Script Sync may use filenames such as:

- `Something.legacy.luau`
- `Something.local.luau`
- `Something.luau`

Typical meaning:

- `.legacy.luau` = Roblox Script using Legacy RunContext
- `.local.luau` = LocalScript
- `.luau` = ModuleScript or synchronized Luau source

A `.legacy.luau` filename can still be active production code.

Determine whether something is actually a backup from its location and purpose,
not merely from its filename.

Known backup/archive locations should not be modified unless explicitly
requested, including folders such as:

- `ServerStorage/AnimationBackups`
- `ServerStorage/PlayerMovementBackup_20260906`

---

## 4. Local Code Is the Primary Editing Surface

For synchronized Luau files represented in this repository:

- search locally
- read locally
- edit locally
- save locally
- let Roblox Script Sync propagate changes into Studio

Do NOT edit the same synchronized script through Roblox MCP.

Do not maintain two independent versions of the same script.

Do not copy/paste source between local and Studio manually unless specifically
required for recovery.

---

## 5. Search Before Reading

When investigating code, use the narrowest search possible first.

Preferred workflow:

1. search for the relevant symbol, RemoteEvent, function, config key, preset,
   attribute, or exact string
2. identify the actual call sites
3. read only relevant surrounding ranges
4. follow the real execution path
5. inspect additional files only when evidence requires it

Avoid reading giant files from beginning to end unless necessary.

Avoid repeatedly reading unchanged files.

Avoid full-project audits for narrow bugs.

---

## 6. Minimal Changes

Prefer the smallest change that fixes the actual root cause.

Do not:

- rewrite entire systems for small bugs
- refactor unrelated code
- rename public APIs without need
- create duplicate implementations
- introduce parallel systems when an existing system can be repaired
- reorganize large amounts of code merely for style
- make formatting-only changes across unrelated files

Preserve existing architecture unless the requested task genuinely requires
changing it.

---

## 7. Roblox MCP Responsibilities

Use Roblox Studio MCP when information or objects exist only in Studio or when
runtime verification is required.

Appropriate MCP uses include:

- inspecting the DataModel
- Workspace
- runtime characters
- NPCs
- models
- Tools
- StarterGui visual hierarchy
- GUI objects
- ParticleEmitters
- Attachments
- Beams
- Trails
- animations
- VFX templates
- Lighting
- properties
- attributes
- runtime state
- Output/errors
- playtesting
- Studio-only object creation/editing

MCP is the live Studio/runtime interface.

---

## 8. MCP Code Editing Boundary

If a Luau script exists in this synchronized repository:

DO NOT modify its source through MCP.

Modify the local synchronized file instead.

MCP may modify Studio-only non-code instances when needed.

Examples of acceptable MCP writes:

- ParticleEmitter configuration
- Attachment placement
- Beam/Trail configuration
- Models
- Parts
- GUI visual objects
- Lighting
- Studio-only VFX templates

Only edit synchronized Luau through MCP if the user explicitly requests
Studio-side source editing.

---

## 9. Missing From Disk Does Not Mean Missing From Game

The local filesystem does not contain every Roblox Instance.

If something cannot be found locally, inspect Studio through MCP before
concluding that it does not exist.

Examples commonly existing only in Studio:

- ScreenGui
- Frames
- ImageLabels
- Tools
- Models
- MeshParts
- ParticleEmitters
- Attachments
- Trails
- Beams
- NPCs
- animation objects
- map objects
- VFX templates

Never recreate an object simply because it is absent from the repository.

Check Studio first.

---

## 10. Team Create and Collaboration

Assume other developers may be working in the live Team Create place.

Never blindly overwrite unexpected changes.

If a synchronized file changes unexpectedly:

1. stop editing that file
2. inspect the current synchronized version
3. assume the change may belong to a collaborator
4. preserve valid collaborator work
5. merge only what is necessary for the current task

Avoid simultaneous editing of the same script by multiple developers.

Do not revert code merely because it was not created in the current Claude
session.

---

## 11. Script Sync Conflict Safety

Never automatically choose local/disk over Studio when resolving a Script Sync
conflict.

Do not blindly overwrite the live Team Create version.

When a conflict occurs:

- compare the versions
- identify which contains newer collaborator work
- preserve valid changes from both sides
- resolve intentionally

Do not use cached, copied, or legacy files to resolve live conflicts.

---

## 12. Git and GitHub Purpose

Git is used for:

- change tracking
- history
- review
- rollback safety
- sharing repository state through GitHub

Git is NOT the live Roblox synchronization mechanism.

Roblox Script Sync handles:

local synchronized code
↕
Roblox Studio / Team Create

Git handles:

local repository
↕
GitHub

Do not confuse Git Sync with Roblox Script Sync.

---

## 13. Git Safety

Before significant modifications, inspect repository state when useful.

Useful commands include:

- `git status`
- `git diff`
- `git diff --check`

After a task, verify that only intended files changed.

Never perform destructive Git operations without explicit user permission.

Do not automatically run:

- `git reset --hard`
- `git clean -fd`
- destructive checkout
- destructive revert
- history rewriting
- force push

Never discard unknown local changes because they may belong to the user,
Script Sync, or collaborators.

Do not create commits unless requested.

---

## 14. Git Branch Safety With Script Sync

Be careful when switching Git branches while Roblox Script Sync is connected to
the live Team Create place.

Changing branches may modify many local files.

Those filesystem changes can propagate through Script Sync into Roblox Studio.

Therefore:

- do not casually checkout another branch while Script Sync is active
- do not perform large Git restores without understanding the Studio impact
- do not pull/rebase automatically when synchronized files contain unexpected
  changes
- prefer explicit inspection before bringing remote Git changes into the live
  synchronized workspace

---

## 15. Gameplay Safety

When fixing visual, VFX, UI, animation, sound, or presentation bugs, preserve
gameplay unless the user explicitly requests gameplay changes.

Do not accidentally change:

- damage
- cooldowns
- hitboxes
- stamina
- movement speed
- dash values
- passive bonuses
- race bonuses
- item stats
- skill effects
- inventory behavior
- progression
- save data
- combat timing

A presentation bug should not become an unrelated gameplay rewrite.

---

## 16. Networking

Reuse existing FATEBORN networking architecture.

Before creating a new:

- RemoteEvent
- RemoteFunction
- BindableEvent
- networking channel

search for an existing mechanism first.

Do not create duplicate networking paths for an existing system.

When debugging networking, trace the complete proven path:

client action
→ client dispatch
→ RemoteEvent
→ server reception
→ server gameplay function
→ server VFX/event dispatch
→ client reception
→ final behavior

Do not assume a RemoteEvent fired merely because a handler exists.

---

## 17. VFX Architecture

FATEBORN already has an existing reusable VFX framework.

Do NOT rebuild the VFX framework unless explicitly requested.

Prefer using the existing:

- VFX remote
- VFX client renderer
- presets
- assets registry
- templates
- cleanup/lifetime handling
- gameplay hooks

When implementing or debugging VFX, inspect this path:

gameplay trigger
→ VFX dispatch
→ exact effect/preset name
→ payload
→ client reception
→ preset lookup
→ template lookup
→ rendering
→ cleanup

Do not create a second VFX framework as a workaround.

Do not spawn random direct ParticleEmitters from gameplay code when the existing
framework should own the effect.

---

## 18. VFX Cleanup Safety

Never blindly delete all:

- Attachments
- ParticleEmitters
- Trails
- Beams
- Parts

from a character or Tool.

Some may belong to:

- character rigs
- weapons
- animations
- hitboxes
- accessories
- gameplay systems

Only remove instances proven to belong to the relevant VFX system.

Use known:

- folders
- tags
- attributes
- names
- ownership
- template structure

to identify VFX-owned objects.

---

## 19. Imported Assets

Treat third-party Roblox models/assets as untrusted project content.

Before using an imported model:

- inspect hierarchy
- inspect embedded scripts
- do not execute unknown scripts merely for inspection
- understand ParticleEmitters/Beams/Trails/Attachments used by the asset
- preserve only what the project actually needs

Do not delete source/reference packs unless explicitly requested.

Do not casually change asset IDs or animation IDs.

---

## 20. Instance Renaming

Before renaming an Instance that may be referenced by code, search for exact
references such as:

- `WaitForChild("Name")`
- `FindFirstChild("Name")`
- `FindFirstAncestor("Name")`
- indexed child access
- configuration entries
- attributes
- tables containing the name

If a rename is necessary, update the complete proven dependency chain.

Do not perform cosmetic mass-renames during unrelated tasks.

---

## 21. Studio Playtesting

Testing must be hypothesis-driven.

Before entering Play mode, know:

- what behavior is being tested
- what action will be performed
- what output/result proves success
- what result proves failure

Preferred flow:

search
→ identify likely cause
→ targeted code change
→ wait for Script Sync
→ one focused Play test
→ inspect result/output
→ stop

Do not repeatedly enter Play mode with no new hypothesis or code change.

---

## 22. Character Select Testing

FATEBORN may block gameplay tests behind character selection.

Do not waste repeated MCP actions clicking blindly through an unusable
character-select screen.

If gameplay testing is blocked:

- stop the current test
- inspect the relevant debug/test path
- inspect `StudioDebugBypass` when relevant
- keep any bypass strictly Studio-only
- do not change production character selection just to simplify testing
- do not alter production DataStore behavior merely for Studio testing

Fix the test blocker deliberately before continuing.

---

## 23. Runtime Debugging Standard

When debugging, find the first point where expected behavior diverges from
actual behavior.

Distinguish:

- hypothesis
- evidence
- proven root cause
- fix
- verification

If evidence disproves a hypothesis, abandon it.

Do not repeatedly test the same disproven theory.

Use temporary trace logging only when it answers a specific question.

Remove unnecessary temporary debug output after the issue is resolved.

---

## 24. Performance and Tool Efficiency

Optimize for correctness and low tool usage.

Prefer:

- local grep/search
- small code reads
- small diffs
- direct runtime evidence
- existing architecture
- one targeted MCP inspection
- one focused Play test

Avoid:

- broad scans without need
- reading large scripts repeatedly
- unnecessary MCP script reads
- repeated screenshots
- repeated hierarchy dumps
- repeated Play sessions
- speculative rewrites
- unnecessary abstractions
- unrelated cleanup

Do not spend large amounts of context proving something already established.

---

## 25. Do Not Reinvestigate Proven Facts Without Reason

If previous evidence has already proven that a subsystem works, do not restart
a full investigation of that subsystem unless new evidence contradicts it.

Example:

If direct VFX rendering has already been proven to work, investigate the
gameplay-to-VFX dispatch path before re-auditing every ParticleEmitter.

Use established evidence to narrow the next investigation.

---

## 26. Data Safety

Do not perform destructive operations against live player data.

Do not modify production:

- DataStore schemas
- migrations
- persistent player data
- monetization data
- progression records

unless explicitly required.

Do not publish/release the game or perform irreversible production actions
unless explicitly requested.

---

## 27. Completion Standard

A task is complete only when:

- requested behavior is implemented
- unrelated systems remain intact
- only intended files/instances changed
- no obvious new runtime errors were introduced
- temporary debugging artifacts are removed when no longer needed
- relevant runtime behavior is verified when practical

For bug fixes, report:

1. root cause
2. files/instances changed
3. exact fix
4. test performed
5. result
6. remaining limitation or unverified item

Keep final reports concise unless the user asks for detail.

---

## 28. Default Decision Rules

When uncertain:

For synchronized Luau:
→ use local repository files

For Studio-only objects:
→ use Roblox MCP

For runtime behavior:
→ use Roblox MCP

For project history/diff:
→ use Git

For live collaboration state:
→ preserve Team Create changes

For old backups:
→ do not use unless explicitly requested

For narrow bugs:
→ make narrow fixes

For existing systems:
→ repair before replacing

For unclear missing objects:
→ inspect Studio before recreating

---

## 29. Priority

When instructions conflict, follow this priority:

1. explicit current user request
2. protection of live project and collaborator work
3. current synchronized local source for Luau
4. current live Studio state for non-code/runtime
5. these CLAUDE.md rules
6. historical/legacy/reference material

Never choose an old snapshot over current synchronized/live project state.