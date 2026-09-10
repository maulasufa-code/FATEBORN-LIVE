# Studio-only source capture

Capture date: 2026-09-11 (Asia/Jakarta)

Purpose: preserve Studio-only source identified by the M0 audit before later animation or character migration. This directory is outside every service `$path` in `default.project.json`, so these files are archival and do not create duplicate runtime scripts.

No Studio instance, Enabled state, source, asset, or runtime behavior was changed during capture.

## Captured scripts

| Original Studio path | Class / state | Archive | SHA-256 | Observed behavior |
|---|---|---|---|---|
| `StarterPlayer.StarterPlayerScripts.HumanBoxingBones` | LocalScript; Enabled; Legacy RunContext; unique ID `0b2d0e26-2d67-d857-0ab3-534200004d74` | `StarterPlayer.StarterPlayerScripts.HumanBoxingBones.local.luau` | `B64C9DFA959F7248CFDA8EF079B71F2E12BF08128BA7E95198EE4A8525CA9C9D` | Active procedural Human bone boxing source. It listens for Basic cue attributes, but current server code emits those cues only for Half-Beast. |
| `StarterPlayer.StarterPlayerScripts.HumanBoxingCombo` | LocalScript; Enabled; Legacy RunContext; unique ID `0b2d0e26-2d67-d857-0ab3-53420000415b` | `StarterPlayer.StarterPlayerScripts.HumanBoxingCombo.local.luau` | `1C19EA1AE7DA96ACF3CB3D29F7EEDBD78967FE488CCE978149761EFE1ABC9F1C` | Runtime-inert because line 14 is `do return end`. |
| `StarterGui.WheelUI.WheelLocalScript` | LocalScript; Disabled; Legacy RunContext; unique ID `1917099e-c5b3-c612-0aae-184a00001464` | `StarterGui.WheelUI.WheelLocalScript.local.luau` | `36B0B9AE3AA8755FDA4A45C98999DF293FDE41BEAAA843CAEB78BF26522C1D2A` | Disabled legacy race-spin UI. |

Each archived source was compared line-for-line with the connected Studio source after capture.

## Empty duplicate instances

Two enabled, zero-byte LocalScripts remain at `StarterPlayer.StarterPlayerScripts.HalfBeastAnimationLoader`:

- unique ID `25687624-821f-0ccf-0ab3-31e10001097a`
- unique ID `3014e850-3887-25ac-0ab3-31c100002a7f`

Their source is empty, and the synchronized zero-byte file at `StarterPlayer/StarterPlayerScripts/HalfBeastAnimationLoader.local.luau` already preserves that fact. Neither duplicate was activated, disabled, renamed, or removed.

## Studio-only non-code dependencies revalidated

- `StarterPlayer.StarterCharacter`: custom bone host; `FatebornBoneCharacter=true`; `PlayerModelAssetId=125661800403596`; 30 descendants when inspected.
- `ServerStorage.PlayerAssetSources.HalfBeastCharacter.Char half beast`: custom package; `FatebornBoneCharacter=true`; `PlayerModelAssetId=92882444915511`; 86 descendants when inspected.
- Imported character/enemy models, animation objects, and VFX source instances remain Studio-owned and were not duplicated as large/binary exports.

The connected place was `FATEBORN` (`placeId 79776008039106`) in Edit mode.
