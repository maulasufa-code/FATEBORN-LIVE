# FATEBORN Development Rules

## Project source

The live Roblox Studio / Team Create place is the authoritative game project.

This local workspace contains Roblox Script Sync mirrors of the live code.

Do NOT use E:\roblox-ws as current source.
It is legacy/reference only.

## Code workflow

For scripts represented in this workspace:

- Search and read them locally.
- Edit them locally.
- Let Roblox Script Sync propagate changes to Studio.
- Do NOT edit the same synced script through Roblox MCP.
- Make minimal targeted edits.
- Do not refactor unrelated systems.

## Roblox MCP

Use Roblox Studio MCP for:

- inspecting the DataModel
- objects that do not exist on disk
- Workspace
- StarterGui visual hierarchy
- Tools/models
- ParticleEmitters
- Beams
- Trails
- Attachments
- animations
- VFX templates
- runtime state
- Output/errors
- playtesting

If something is not found locally, check Roblox Studio through MCP
before concluding that it does not exist.

## Studio objects

Non-code Roblox instances remain managed in Studio.

Code may reference Studio-only objects normally.

## Collaboration

Other developers may edit the live Team Create project.

Never blindly overwrite a Script Sync conflict.

Before editing a file that may have changed:
- use the latest synchronized local contents
- do not work from cached/copied/legacy files

Avoid simultaneous edits to the same script.

## Testing

Use this workflow:

1. Search locally.
2. Identify the actual root cause.
3. Make the smallest local code change.
4. Wait for Script Sync.
5. Use MCP for one focused runtime test.
6. Inspect Output/result.
7. Stop Play.

Do not repeatedly Play test without a new hypothesis or code change.

## Efficiency

- grep/search before opening large scripts
- read only relevant ranges
- avoid broad project audits unless requested
- avoid unnecessary MCP reads when the source is available locally
- do not repeatedly inspect unchanged files