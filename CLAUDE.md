# FATEBORN Claude Code Instructions

@AGENTS.md

The imported AGENTS.md contains the authoritative shared development rules
for this repository.

Follow all rules in AGENTS.md for:
- Roblox Script Sync
- Team Create collaboration
- local-vs-MCP editing boundaries
- Git safety
- runtime testing
- VFX architecture
- project scope and efficiency

## Claude Code specific rules

- Treat the repository root containing this CLAUDE.md as the current
  FATEBORN local Script Sync workspace.
- Do not assume any absolute filesystem path because each developer may
  clone the repository to a different location.
- Use local filesystem tools for synchronized Luau source.
- Use the connected Roblox MCP server for Studio-only instances and runtime
  inspection/testing.
- Do not edit synchronized Luau through MCP unless explicitly requested.
- If something is absent from disk, inspect Roblox Studio through MCP before
  concluding that it does not exist.
- Never use legacy/backup project copies as current source.