# Architecture

## Runtime flow

`project.godot` starts `scenes/ui/main_menu.tscn`. The main menu routes to hero selection, level selection, settings, the four authored levels, or endless mode.

`GameManager` and `AudioManager` are autoload singletons. `GameManager` owns selected-hero data, health, fruit counts, timing, checkpoints, level records, unlocks, endless records, scene transitions, and persistence. `AudioManager` owns the pooled sound-effect players and looping background music.

Authored level flow:

```text
MainMenu
  -> GameManager.start_level(index)
  -> scenes/levels/level_<index>.tscn
  -> BaseLevel + Player + HUD + items/traps
  -> checkpoint/respawn or GameManager.complete_level()
  -> LevelCompleteMenu -> next level, retry, or level select
```

Endless flow uses `GameManager.start_endless_mode()` and `scenes/levels/level_endless.tscn`. `EndlessLevel` generates and removes chunks around the player, updates distance records, and reuses the same item/trap scenes.

## Responsibilities

| Area | Location | Responsibility |
| --- | --- | --- |
| Global state | `scripts/game_manager.gd` | Hero data, run state, signals, scene transitions, save/load |
| Audio | `scripts/audio_manager.gd` | SFX pool, BGM loop, volume settings |
| Player | `scripts/player.gd`, `scenes/characters/player.tscn` | Movement, jumps, wall movement, hero abilities, damage/respawn |
| Levels | `scenes/levels/`, `scripts/levels/` | Layout, camera, abyss handling, authored/endless generation |
| Items | `scenes/items/`, `scripts/items/` | Fruit, breakable boxes, checkpoints |
| Traps | `scenes/traps/`, `scripts/traps/` | Hazard behavior and player damage |
| UI | `scenes/ui/`, `scripts/ui/` | Menus, HUD, navigation, records, completion screens |
| Assets | `resources/`, `Background/`, `Items/`, `Main Characters/`, `Traps/`, `Menu/`, `audio/` | Imported sprites, animations, tiles, and audio |

## Hero data

Hero IDs are `ninja_frog`, `pink_man`, `virtual_guy`, and `mask_dude`. Their dictionaries in `GameManager.heroes_data` are the source of truth for movement values, health, abilities, and sprite-frame resources. `Player.load_hero_stats()` applies that dictionary at runtime.

Abilities are data-gated:

- Ninja Frog: wall mobility and high speed.
- Pink Man: reduced glide gravity.
- Virtual Guy: `special_action` cyber dash.
- Mask Dude: extra health and airborne `move_down` ground pound.

## Signals and persistence

`GameManager` emits `health_changed`, `fruits_changed`, `checkpoint_reached`, `player_died`, `player_respawned`, and `level_completed`. Level and HUD scripts connect to these signals rather than maintaining duplicate global state.

Progress is serialized as JSON with `max_unlocked_level`, `selected_hero_id`, `records`, `endless_best_distance`, and `endless_best_fruits`. The preferred path is `user://game_save.json`; `res://game_save.json` is the local fallback used when the user path is unavailable.

## Conventions

- Add reusable gameplay objects as a scene/script pair under the matching `scenes/` and `scripts/` folders.
- Use `res://` paths and existing resource files rather than embedding duplicate assets.
- Add input actions through `GameManager._setup_input_actions()` unless the project moves to an explicit Input Map configuration.
- Play gameplay feedback through `AudioManager.play_sfx()`.
- Use `BaseLevel` for authored levels and `EndlessLevel` for procedural generation.

