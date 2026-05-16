# W

## Script Naming & Domain Standard

Top-level scripts are organized by feature-domain directories, and every runnable Roblox script follows:

- `PascalCase` or `snake_case` descriptive names with clear functional intent.
- Execution-context suffixes: `.client.lua` for LocalScripts and `.server.lua` for server scripts.
- Explicit version labels when multiple scripts intentionally overlap in feature scope.

## Domain Layout

- `ai/`
- `animation/`
- `combat/`
- `fishing/`
- `ui/`
- `experimental/`

## Legacy Name → Canonical Name Map

| Legacy Root Script | Canonical Script Path | Domain Rationale |
|---|---|---|
| `Maj` | `ai/AIFriendCompanion.client.lua` | AI companion behavior |
| `De` | `ai/MitralAIPlayerController.client.lua` | AI player-control experimentation |
| `Emo` | `animation/EmoteAnimationOverride.client.lua` | Character animation override |
| `Rezy` | `animation/EmoteAnimationRuntimeOverride.client.lua` | Runtime animation override UI |
| `U` | `combat/VenomMovesetController.client.lua` | Combat moveset system |
| `Weapon editor` | `fishing/OverengineeredFishingSystem.client.lua` | File content is fishing gameplay despite legacy name |
| `Just a guy fishing` | `ui/WeaponEditorExperimental.client.lua` | File content is an experimental weapon editor UI |
| `Edit` | `ui/WeaponEditorV2.client.lua` | Main supported weapon editor |
| `Nah` | `experimental/NexusMindController.client.lua` | Quarantined high-autonomy prototype |

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

Deprecation note: if functionality converges, deprecate `WeaponEditorExperimental` in favor of `WeaponEditorV2`, add migration notes here, then remove only after one full release cycle.
