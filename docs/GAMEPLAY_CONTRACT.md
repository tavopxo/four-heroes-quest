# Gameplay contract

These behaviors are part of the current game design and must remain stable unless a task explicitly changes them.

## Player and heroes

- All four heroes remain selectable and playable.
- Hero IDs and hero stats remain owned by `GameManager.heroes_data`.
- Ninja Frog supports wall mobility; Pink Man glides while holding Jump during descent; Virtual Guy dashes through `special_action`; Mask Dude has four hearts and ground pounds with `move_down` while airborne.
- Movement uses the existing input actions and preserves coyote time, jump buffering, and double-jump behavior where applicable.

## Run lifecycle

- Starting a level resets the run timer, fruit count, checkpoint state, and health for the selected hero.
- Damage emits the health update and plays the existing hurt feedback.
- A defeated player emits `player_died`; respawn restores full health at the latest checkpoint, or at the level start when no checkpoint exists.
- Checkpoint activation updates the latest respawn position and emits `checkpoint_reached`.
- Completing an authored level records time, fruit count, stars, and unlock progress before showing the completion UI.

## Progress and compatibility

- `user://game_save.json` remains the primary save path.
- The repository fallback `res://game_save.json` remains readable and writable when the user path is unavailable.
- Existing save keys must continue to load: `max_unlocked_level`, `selected_hero_id`, `records`, `endless_best_distance`, and `endless_best_fruits`.
- Level records preserve the best stars, best time, and best fruit count rather than replacing better historical results with worse runs.

## World and feedback

- Existing hazards damage through the established player damage path; they must not silently bypass invulnerability or health signaling.
- New items and hazards should use the existing collision, scene, animation, and `AudioManager.play_sfx()` patterns.
- Player combat uses the `fire` mouse action to aim toward the cursor and launch projectiles at visible enemies.
- Powerups may grant health, temporary speed, or temporary invulnerability; their effects are applied by `Player.apply_powerup()`.
- The four authored levels remain addressable as `res://scenes/levels/level_1.tscn` through `level_4.tscn`.
- Endless mode remains separate from authored-level progression and continues to track distance and fruit records.
- Endless chunks retain a solid ground route; upper platforms and vertical routes are optional challenge and reward paths.

## UI

- Main menu, hero selection, level selection, settings, pause, game-over, and completion flows remain reachable.
- UI must use `GameManager` as the source of global state and must not create a second save or progression model.
