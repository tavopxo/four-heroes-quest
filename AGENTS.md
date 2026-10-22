# Four Heroes Quest agent guide

## Project

- Godot Engine 4.7, 2D platformer, 640x360 viewport.
- Main scene: `scenes/ui/main_menu.tscn`.
- Autoloads: `GameManager` (`scripts/game_manager.gd`) and `AudioManager` (`scripts/audio_manager.gd`).
- Architecture reference: `docs/ARCHITECTURE.md`.
- Gameplay invariants: `docs/GAMEPLAY_CONTRACT.md`.

## Working rules

- Read the relevant scene and script before editing; follow existing patterns.
- Keep hero definitions in `GameManager.heroes_data`; do not duplicate stats in scenes.
- Reuse existing item, trap, signal, audio, and UI conventions.
- Do not edit `.godot/` or generated `.uid` files.
- Preserve `user://game_save.json` compatibility and the fallback `res://game_save.json`.
- Keep changes scoped to the requested behavior. Update the docs when architecture or contracts change.

## Validation

Run the project validation script from the repository root:

```bash
./tools/validate.sh
```

For a manual smoke test, launch the project and verify the main menu, hero selection, level selection, one level transition, checkpoint/respawn, and save behavior.

## Handoff format

Report changed files, behavior implemented, validation performed, and any known limitations. Use `docs/TASK_TEMPLATE.md` when preparing a task for another agent.

