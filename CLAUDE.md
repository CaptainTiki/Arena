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
* Ownership spine, no autoload event bus. `Game` owns `Base` and `Arena`, one at a time, and swaps them. `Arena` owns the spawner, sponsors, pods, player and HUD. Children signal up; the owner routes.
* Money, favour, what is owned and what is carried all go through `Locker`, which saves on every change.
* All damage goes through `take_hit(hit: HitInfo)`.
* Only `PlayerIntent` reads input. Everything else asks it. Keyboard, mouse and controller all arrive as the same intents; buttons come as events, sticks and the trigger are asked about each frame.
* Greybox visuals: boxes, capsules, flat colours. Sound is allowed; tones are generated from `ToneData`, no audio files.
* Level geometry is built from `arena/block.tscn` (set `size`, don't scale). The navigation mesh bakes itself on load.

## Layout

| Folder | Holds |
|-|-|
| `game/` | `Game` (the spine): swaps the base and the fight |
| `base/` | `Base` (the room between fights), `Kiosk`, `KioskPanel` (the menu), `MenuRow`, `MenuEntry` |
| `arena/` | `Arena` (one fight), `Level`, blocks, hold zones, stations (vending machines), spawn booths |
| `player/`, `weapon/` | Player, intent, pistol, shotgun, rifle, .357 (one `Weapon` script, `WeaponData` sets pellets and spread) |
| `item/` | `ItemData` and everything that can be owned: weapons, vests, the stim, mods |
| `enemy/` | One `Enemy` script for all types; `EnemyData` picks the attack style and sets the senses. Grunt, heavy, shooter, projectile |
| `spawn/` | `Spawner` (density ramp or named roster) and ramp waves |
| `contract/` | `ContractData`, `RosterWave`, the five contracts |
| `sponsor/`, `pod/` | Sponsor scoring and the pods they drop |
| `run/` | `Catalog` (what the game offers), `Locker` and `ProfileStore` (the save), `Loadout`, run stats, `RunLog` (playtest event log) |
| `hud/`, `feel/`, `audio/`, `combat/` | HUD and summary, hitstop and damage numbers, sounds, shared combat types (`Hitbox` is a weak point) |

## Testing headless

Run Godot 4.7 with `--headless --fixed-fps 60 --path <project> -s <test script>`. Run `--headless --import` first after adding scripts or scenes. Find the 4.7 binary on this machine; an older Godot will not open the project cleanly.

Test scripts extend `SceneTree`. Things that have bitten before:

* Nodes added in `_initialize` are not in the tree yet. Fetch child references on the first `_physics_process`.
* A script error before the test returns `true` hangs the process. Always add a frame-count bailout.
* Mouse capture does not exist headless, so `PlayerIntent.is_active()` is false. Swap the intent's script for a stub that returns `true`.
* Check the test lane for crates and pillars before blaming game code.
* Set `profile_path` on `Game` or `Arena` to a test file and delete it afterwards, so the real save is untouched.
* Set `RunLog.directory` to a `user://` folder, or the test writes into the tester's `.logs/`. The base and the arena each have their own `RunLog` node.
* `arena.tscn` on its own fights `default_contract` (or `debug_contract`) carrying all four weapons. Through `game.tscn` it carries the loadout in the save.
* On its own, the arena reloads itself after the summary. A reloaded scene loses exports set on the instance, so it is back on the real profile and log folder.
* Fire with `player.get_weapon()`, not a weapon reference taken at the start; the weapon in hand changes.
* Press keys with `Input.parse_input_event` and an `InputEventAction`, and send the release straight after. A movement action left pressed walks the player away once the menu closes.
* Click a menu row by emitting `pressed` on its `Button`.
* Menu steps are read from what is held, once a frame. Press a direction, wait a frame or two, then release it; pressed and released in the same frame it is never seen.
* A controller is an `InputEventJoypadMotion` or `InputEventJoypadButton` through `Input.parse_input_event`. Set a stick back to 0.0 when done. Both axes pushed right over is a diagonal of length 1, so each turns at 0.7 of full speed.
* Hitstop is timed in real milliseconds. Headless runs faster than real time, so a kill slows many frames of game time; fights take longer on the frame count than on the log's clock.
* The navigation map is empty for the first tick or two. The spawner waits for it; a test that places things itself must too.
* No test scripts are kept in the repo. Write them in a scratch folder.

## Playtest logs

Every session writes one JSON-lines file to `.logs/` at the project root (ignored by git, newest 10 kept). After the tester plays, read the newest file before discussing how it went: what they felt and what the log shows are both evidence, and they have disagreed. The event list is in `docs/playtest-notes.md` under "Run log". Logs do not travel between machines.

## Where things stand

As of the end of 2026-09-29, on the desktop. The plan is `docs/vertical-slice-kickoff.md`: twenty minutes of the whole loop, greybox. For the slice, batches can be bigger and design choices inside the slice doc are made without asking; stop when a decision truly needs the tester, then discuss, commit, go again. Numbers get tuned once the arc has been played.

Every system in the slice doc is built. Played so far: perception AI (liked a lot), and one full loop on The Open Gate with the pistol (won). **Built and committed but not yet played:** the kiosk menus, the shotgun moving to the Warden, and controller support.

The loop as built: start in the base with a pistol and $100. Book a contract at the agent's terminal, fight, get paid on a win, come back. Favour with each sponsor comes from what they scored in the fight, times the contract's multiplier, doubled for the sponsor who asked for that contract. The Warden sells the shotgun, the Marksman the rifle, the Butcher the .357, all for favour. Cash buys vests, stims, a pistol mod, and ammo or health at stations mid-fight.

Keys: `E` interact and pay cash, `T` pay favour, `F` stim, `1` `2` `Q` wheel for weapons, `~` debug HUD. In a menu: `W` `S` move, `A` `D` change, `E` or a click chooses, `Esc` goes back. The controller layout is in the notes under "Controller support".

Every number in the economy is a placeholder. Nothing has been balanced; the twenty-minute arc has not been played end to end.

### Start here next session

1. This is a different machine from the one the work was done on. Find its Godot 4.7 binary, run `--headless --import`, and don't expect any `.logs/` from earlier sessions; logs and the save file do not travel.
2. Ask how the menus and the controller felt, if they have been played. Read the newest log first if there is one.
3. Then play the arc: two easy wins, buy the shotgun from the Warden and a vest, move up the ladder. The favour and price numbers are the first thing to tune, from the log's `favor` and `purchase` lines.

Open findings:

* The dash has dodged one hit in every logged run put together. Parked until people other than the tester have played; the fallback is a jump and a crouch.
* Favour from the one real win (The Open Gate, pistol only, x1): Purist 46, Warden 33, Marksman 22, Butcher 6. The Butcher sells the .357 for 160. Unknown what he pays once the player has the shotgun.
* The Purist pays the most and sells nothing.
* The shotgun is bracketed high on purpose (16 pellets at 18, scarce shells) to find out what overpowered feels like. It has not been played since it went behind a price.
* Rifle and .357 have never been fired by a person. Running `arena.tscn` on its own carries all four weapons.
* Controller: built with no controller plugged in. No aim assist, and the prompts still name keys.
* The player starts 2 m from the `EastSouth` spawn booth. Robots do not use a booth within 20 m of the player, but they can once the player has moved off.
* The .357 kills anything through its weak point. The slice doc wanted heavies killed from the front; a heavy's weak point is on its back, so that is not true yet.
* The navigation mesh covers the roofs and insides of the corner masses. Harmless so far.
* A quiet player on a survival or scavenger contract may never be found; untested by a person since perception went in.

After the arc plays through, per the slice doc: get two people who are not the developer through it, then answer its two questions.
