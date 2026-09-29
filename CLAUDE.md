# Arena

Greybox prototype of a first-person arena shooter. You are a gladiator; sponsors watch how you fight and drop rewards for the behaviour they like. Godot 4.7, GDScript, Jolt physics.

Read `docs/playtest-notes.md` first. It is the running record of every playtest, every design decision and why it was made. `docs/arena-prototype-kickoff.md` is the original brief and is now history, not a rulebook.

## How we work

* **Small playable batches.** Build, smoke test headless, hand over to play, take feel feedback, carry on. Feel can only be judged by playing, so don't one-shot big plans.
* **We are prototyping to find the fun.** Nothing is chiselled in stone, including anything in the kickoff doc. Design it, test it, improve it or remove it. Give an honest opinion on cost versus payoff.
* **Log findings and decisions** in `docs/playtest-notes.md` as they happen.
* **Commits:** straight to `main`, subject line only. No body, no description, no co-author trailers. Commit a batch once it has been played. Don't push unless asked.
* **Report plainly** what was tested and what was not. Headless tests can't verify anything visual or audible; say so.

## Code conventions

* Scenes first, nodes authored in scenes. No runtime node generation; anything spawned in volume comes from a `ScenePool`.
* `class_name` on every script, explicit static typing everywhere.
* Everything tunable lives in a Resource (`.tres`). Tuning should not need a script change.
* Ownership spine, no autoload event bus. `Arena` owns the spawner, sponsors, pods, player and HUD. Children signal up; the owner routes.
* All damage goes through `take_hit(hit: HitInfo)`.
* Only `PlayerIntent` reads input. Everything else asks it.
* Greybox visuals: boxes, capsules, flat colours. Sound is allowed; tones are generated from `ToneData`, no audio files.
* Level geometry is built from `arena/block.tscn` (set `size`, don't scale). The navigation mesh bakes itself on load.

## Layout

| Folder | Holds |
|-|-|
| `arena/` | `Arena` (the spine), `Level`, blocks, hold zones, ammo stations |
| `player/`, `weapon/` | Player, intent, pistol |
| `enemy/` | One `Enemy` script for all types; `EnemyData` picks the attack style. Grunt, heavy, shooter, projectile |
| `spawn/` | `Spawner` (density ramp or named roster) and ramp waves |
| `contract/` | `ContractData`, `RosterWave`, the three contracts |
| `sponsor/`, `pod/` | Sponsor scoring and the pods they drop |
| `run/` | Run stats, reputation rules, `ProfileStore` (save file) |
| `hud/`, `feel/`, `audio/`, `combat/` | HUD and summary, hitstop and damage numbers, sounds, shared combat types |

## Testing headless

Run Godot 4.7 with `--headless --fixed-fps 60 --path <project> -s <test script>`. Run `--headless --import` first after adding scripts or scenes. Find the 4.7 binary on this machine; an older Godot will not open the project cleanly.

Test scripts extend `SceneTree`. Things that have bitten before:

* Nodes added in `_initialize` are not in the tree yet. Fetch child references on the first `_physics_process`.
* A script error before the test returns `true` hangs the process. Always add a frame-count bailout.
* Mouse capture does not exist headless, so `PlayerIntent.is_active()` is false. Swap the intent's script for a stub that returns `true`.
* Check the test lane for crates and pillars before blaming game code.
* Set `Arena.profile_path` to a test file and delete it afterwards, so the real save is untouched.

## Where things stand

Playable now: three contracts (extermination, scavenger, survival), three enemy types, four sponsors, parachute pods, ammo stations, a cross-shaped arena with levels and cover, run summary with cash and reputation.

Not yet played by the tester: the contract system and the combat pivot (pistol damage doubled, fewer named enemies that hit harder).

Agreed order for what comes next:

1. New enemy types: rifles and shotguns.
2. A walkable home base: booking computer, research terminal for sponsors, enemies and arenas, an agent, trophies.
3. Economy: weapon rack, wardrobe, things to buy with cash (weapons, armour, mods).

Reputation perks shown on the summary are teasers only; none are implemented.
