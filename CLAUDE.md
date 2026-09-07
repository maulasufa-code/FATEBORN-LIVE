# FATEBORN — Claude Code Project Rules

These rules apply to all Claude Code work in this repository.

Goal: solve tasks correctly with the **smallest necessary context, tool usage, file changes, and runtime testing**, while protecting Roblox Team Create, Script Sync, collaborators, Git history, gameplay, and production data.

---

## 1. Source of Truth

FATEBORN has two synchronized views:

```text
Local repository
      ↕
Roblox Script Sync
      ↕
Roblox Studio / Team Create
```

The live Roblox Studio / Team Create place is authoritative for the live game.

The local repository is authoritative for synchronized Luau source.

For synchronized Luau:

* search locally
* read locally
* edit locally
* save locally
* let Script Sync propagate changes to Studio

For Studio-only instances or runtime state:

* inspect through Roblox Studio MCP
* modify through MCP when required

Never treat old copies, exports, dumps, temporary scripts, or backup workspaces as current source.

---

## 2. Fast Decision Rule

Before investigating, classify the task:

```text
Synchronized Luau source
→ local repository

Studio-only instance
→ Roblox Studio MCP

Runtime state / Output / Playtest
→ Roblox Studio MCP

Git history / diff / status
→ Git

Live collaborator changes
→ preserve and merge carefully
```

Do not use MCP for Luau code that already exists locally.

Do not recreate a Studio object merely because it is absent from disk.

---

## 3. Investigation Strategy

Use the smallest investigation that can establish the root cause.

Preferred order:

1. Search exact symbols, functions, errors, remotes, attributes, names, or config keys.
2. Read only the relevant code around the match.
3. Follow the actual execution path.
4. Inspect dependencies only when required by evidence.
5. Stop investigating once the root cause is sufficiently established.
6. Make the smallest safe fix.
7. Validate the changed behavior.

Prefer `rg` / grep and targeted reads over large file reads.

For cross-system bugs, trace:

```text
input
→ client action
→ remote/event
→ server handler
→ gameplay system
→ client/VFX/UI result
```

Find the **first point where expected behavior diverges from actual behavior**.

Do not guess when direct evidence is available.

---

## 4. Context Efficiency

Optimize for low context and low tool usage.

Do NOT:

* scan the entire repository for a narrow task
* read large files from beginning to end without reason
* repeatedly read unchanged files
* repeat searches that already produced sufficient evidence
* inspect unrelated systems
* inspect backup folders without a reason
* dump large Studio hierarchies
* take repeated screenshots of unchanged state
* repeatedly run Play mode without new evidence
* perform broad audits for narrow bugs
* investigate facts already established during the current task

Reuse information already established in the current task.

Re-check something only if:

* relevant code changed
* Studio state changed
* a collaborator changed the relevant file
* new runtime evidence contradicts the previous conclusion

When the evidence is sufficient, **stop investigating and implement**.

---

## 5. Code Editing

For synchronized Luau:

1. Search locally first.
2. Read only relevant code.
3. Confirm the execution path.
4. Identify the root cause.
5. Make the smallest necessary change.
6. Preserve existing interfaces and architecture.
7. Let Script Sync update Studio.
8. Use MCP only for Studio/runtime verification.

Prefer repairing existing architecture over replacing it.

Do NOT:

* broad-rewrite a small bug
* refactor unrelated code
* rename APIs unnecessarily
* create duplicate systems
* create parallel implementations
* perform cosmetic mass changes
* reformat unrelated code
* introduce abstractions without need

Minimize files touched.

---

## 6. Script Sync Naming

Do not assume `.legacy.luau` means obsolete.

Script Sync may use:

* `*.legacy.luau` — current Script using Legacy RunContext
* `*.local.luau` — LocalScript
* `*.luau` — synchronized Luau / commonly ModuleScript

Determine whether code is current or archived from its location and purpose, not its filename alone.

Known backup/archive locations include:

```text
ServerStorage/AnimationBackups
ServerStorage/PlayerMovementBackup_20260906
```

Do not modify backup/archive code unless explicitly requested.

---

## 7. Roblox Studio MCP

Use MCP for:

* DataModel inspection
* Workspace objects
* runtime objects
* characters
* NPCs
* StarterGui hierarchy
* Tools
* models
* map/build objects
* ParticleEmitters
* Beams
* Trails
* Attachments
* animation objects
* VFX templates
* properties
* attributes
* Lighting
* Output/errors
* targeted Play testing
* Studio-only assets and instances

MCP may modify non-code Studio instances when required.

For MCP investigation:

1. inspect only the relevant hierarchy
2. query only required properties
3. avoid large hierarchy dumps
4. avoid repeated inspection of unchanged state
5. reuse previously observed information

---

## 8. Missing Studio Objects

The repository does not represent every Roblox Instance.

If an object is absent locally, check Studio before assuming it does not exist.

This especially applies to:

* UI
* Tools
* models
* ParticleEmitters
* Attachments
* Beams
* Trails
* map objects
* NPCs
* animation objects
* VFX templates
* other non-code instances

Do not recreate an object solely because it is missing from disk.

---

## 9. Team Create / Collaboration

Assume collaborators may edit the live Team Create project.

Never blindly overwrite unexpected changes.

If a synchronized file changes unexpectedly:

1. stop editing
2. inspect the current version
3. assume the change may belong to another developer
4. preserve valid changes
5. merge only what is required

Do not revert code merely because it was not created during this Claude session.

Avoid simultaneous editing of the same script.

Minimize touched files and avoid unrelated formatting/table reordering.

---

## 10. Script Sync Conflicts

Never automatically prefer disk over Studio.

If Script Sync reports a conflict:

1. compare both versions
2. identify current/collaborator changes
3. preserve valid work
4. resolve intentionally

Never use cached, copied, backup, legacy, or historical code to overwrite current live work.

---

## 11. Git / GitHub Safety

Git is for:

* history
* diff inspection
* review
* rollback safety
* GitHub collaboration
* checkpoints

Git is NOT the Roblox live synchronization mechanism.

Before substantial work when relevant:

```bash
git status
```

After changes:

```bash
git diff
git diff --check
```

Verify that only intended files changed.

Never automatically run:

```text
git reset --hard
git clean -fd
destructive checkout/revert
history rewriting
force push
```

Do not discard unknown modifications.

Do not commit or push unless explicitly requested.

---

## 12. Git + Script Sync

Git operations can affect Script Sync and therefore the live Studio project.

While Script Sync is active, do not casually:

* switch branches
* pull
* rebase
* restore large file sets
* checkout old revisions
* revert synchronized files

Inspect consequences before performing such operations.

Treat synchronized Git changes as potentially live Studio changes.

---

## 13. Runtime Testing

Testing must be hypothesis-driven.

Before Play mode, know:

* what is being tested
* expected behavior
* what evidence proves success/failure

Preferred workflow:

```text
search
→ targeted read
→ root cause
→ minimal fix
→ Script Sync
→ one focused Play test
→ inspect Output/result
→ stop Play
```

Do not repeatedly Play test without:

* a new hypothesis
* a new code change
* new evidence requiring another test

Prefer the smallest relevant test rather than the entire test suite.

If an unrelated pre-existing test fails, do not fix unrelated code unless requested.

---

## 14. Character Select / Studio Debugging

FATEBORN gameplay testing may be blocked by character selection.

Do not waste repeated Play sessions clicking blindly.

If blocked:

1. stop
2. inspect the relevant debug path
3. inspect `StudioDebugBypass` if relevant
4. keep any bypass Studio-only
5. do not weaken production character selection
6. do not alter production DataStore behavior for testing convenience

Resolve the blocker intentionally, then continue the focused test.

---

## 15. Gameplay Safety

For tasks involving:

* VFX
* UI
* animation
* sound
* presentation
* feedback

do not modify gameplay unless explicitly required.

Preserve:

* damage
* cooldowns
* hitboxes
* stamina
* movement values
* race bonuses
* passive bonuses
* abilities
* inventory behavior
* equipment stats
* progression
* save data

A visual bug must not become a gameplay rewrite.

---

## 16. Networking

Reuse existing FATEBORN networking architecture.

Before creating a:

* RemoteEvent
* RemoteFunction
* BindableEvent
* networking/state channel

search for an existing mechanism.

Do not duplicate networking paths.

For networking bugs trace:

```text
sender
→ exact event/action name
→ payload
→ server reception
→ server dispatch
→ client reception
→ final behavior
```

Do not assume an event fired merely because a handler exists.

---

## 17. VFX Architecture

FATEBORN already has a reusable VFX framework.

Do not rebuild it unless explicitly requested.

Prefer existing:

* VFX remotes
* renderer
* presets
* asset registry
* template architecture
* cleanup/lifetime mechanisms
* gameplay hooks

Trace VFX problems through:

```text
gameplay trigger
→ dispatch
→ preset/effect name
→ payload
→ client reception
→ preset lookup
→ template lookup
→ rendering
→ cleanup
```

Do not create another VFX framework as a workaround.

Do not bypass the architecture with random ParticleEmitter spawning from gameplay code.

---

## 18. VFX Cleanup

Never blindly delete all:

* Attachments
* ParticleEmitters
* Trails
* Beams
* Parts

from characters, Tools, weapons, or models.

Instances may belong to:

* character rigs
* weapons
* animations
* accessories
* hitboxes
* gameplay systems

Only remove instances proven to belong to the relevant VFX system.

Use hierarchy, tags, attributes, names, ownership, and templates to establish ownership.

---

## 19. Imported Assets

Treat imported/third-party Roblox models as untrusted project content.

Before relying on them:

* inspect hierarchy
* inspect embedded scripts
* do not execute unknown scripts merely for inspection
* understand emitters/beams/trails/attachments
* preserve only what the project needs

Do not delete source/reference assets unless requested.

Do not casually change asset IDs or animation IDs.

---

## 20. Instance Renaming

Before renaming an Instance that may be referenced by code, search for:

```text
WaitForChild("Name")
FindFirstChild("Name")
FindFirstAncestor("Name")
indexed child access
config references
attribute references
tables containing the exact name
```

If renaming is required, update the proven dependency chain.

Do not mass-rename for cosmetic reasons.

---

## 21. Production / Data Safety

Never perform destructive changes to live player data.

Do not alter production:

* DataStore schemas
* migrations
* persistent player data
* monetization data
* progression records

unless explicitly required.

Do not publish/release the game or perform irreversible production actions unless explicitly requested.

Do not weaken production systems merely to simplify Studio testing.

---

## 22. Scope Discipline

Treat each user request as a focused task.

Do not expand scope into:

* unrelated bug fixes
* technical debt cleanup
* broad refactoring
* architecture redesign
* unrelated optimization
* unrelated UI polish
* opportunistic renaming

If an unrelated issue is discovered, mention it briefly rather than fixing it automatically.

If the requested task can be safely completed without clarification, proceed.

Ask for clarification only when proceeding could:

* modify the wrong system
* overwrite collaborator work
* affect live player data
* unexpectedly change gameplay
* perform destructive/irreversible actions
* violate an explicit constraint

---

## 23. Completion Standard

Before finishing:

* requested behavior is implemented
* root cause is understood
* unrelated behavior is preserved
* only intended files/instances changed
* no obvious new runtime errors were introduced
* temporary debug code is removed
* temporary test/VFX objects are cleaned up
* relevant behavior is verified when practical

For code tasks, inspect the final diff.

For runtime tasks, verify the relevant Studio state.

Final response must be concise:

```text
Root cause:
[short explanation]

Changed:
[files/instances]

Fix:
[short explanation]

Validation:
[test performed + result]

Remaining:
[only if something remains unverified]
```

Do not provide a long narrative unless requested.

---

## 24. Priority Rules

When instructions conflict:

1. explicit current user request
2. live project and collaborator safety
3. current synchronized local Luau source
4. current live Studio state for non-code/runtime
5. these project rules
6. historical/legacy/reference material

Never choose an old snapshot over current synchronized/live project state.

---

## 25. Core Operating Principle

**Evidence over guessing.
Targeted search over broad scanning.
Small reads over large reads.
Existing architecture over new architecture.
Minimal changes over rewrites.
One focused test over repeated testing.
Current live state over historical copies.
Correctness and safety over speed.**

When the root cause is proven and the required change is clear:

**stop investigating, make the minimal fix, validate it, and finish.**
