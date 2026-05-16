# W

## Script Naming & Domain Standard

Top-level scripts are organized by feature domain directories, and every runnable Roblox script follows:

- `PascalCase` or `snake_case` descriptive names with functional intent.
- Execution-context suffixes: `.client.lua` for LocalScripts and `.server.lua` for server scripts.
- Versioned naming for functionally overlapping scripts.

## Script Manifest

| Script Path | Responsibility | Roblox Service Target |
|---|---|---|
| `ai/AIFriendCompanion.client.lua` | Autonomous AI companion with movement/chat/world awareness | `StarterPlayerScripts` |
| `ai/MitralAIPlayerController.client.lua` | Experimental AI avatar controller and environment scanning | `StarterPlayerScripts` |
| `combat/VenomMovesetController.client.lua` | Venom combat moveset and ability input handling | `StarterPlayerScripts` |
| `animation/EmoteAnimationOverride.client.lua` | Emote-to-animation slot reassignment (character scoped) | `StarterCharacterScripts` |
| `animation/EmoteAnimationRuntimeOverride.client.lua` | Runtime emote scanning/override UI (player scoped) | `StarterPlayerScripts` |
| `ui/WeaponEditorV2.client.lua` | Weapon editor v2 main UI and effects controls | `StarterPlayerScripts` |
| `ui/WeaponEditorExperimental.client.lua` | Weapon editor experimental variant with alternate UX/effects | `StarterPlayerScripts` |
| `fishing/OverengineeredFishingSystem.client.lua` | Fishing gameplay system (casting, fish AI, bucket, line simulation) | `StarterPlayerScripts` |
| `experimental/NexusMindController.client.lua` | High-autonomy Nexus Mind controller; quarantined for non-production | `StarterPlayerScripts` *(quarantine / experimental only)* |

## Weapon Editor Overlap Policy

Two weapon editor scripts are retained intentionally with explicit versioning:

- `ui/WeaponEditorV2.client.lua`: **primary** supported editor.
- `ui/WeaponEditorExperimental.client.lua`: **experimental** branch for feature trials.

Deprecation note: if functionality converges, deprecate `WeaponEditorExperimental` in favor of `WeaponEditorV2` and keep compatibility notes in this README before removal.
