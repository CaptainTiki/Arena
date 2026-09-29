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
| `arena/` | `Arena` (the spine), `Level`, blocks, hold zones, stations (ammo or health) |
| `player/`, `weapon/` | Player, intent, pistol and shotgun (one `Weapon` script, `WeaponData` sets pellets and spread) |
| `enemy/` | One `Enemy` script for all types; `EnemyData` picks the attack style and sets the senses. Grunt, heavy, shooter, projectile |
| `spawn/` | `Spawner` (density ramp or named roster) and ramp waves |
| `contract/` | `ContractData`, `RosterWave`, the three contracts |
| `sponsor/`, `pod/` | Sponsor scoring and the pods they drop |
| `run/` | Run stats, reputation rules, `ProfileStore` (save file), `RunLog` (playtest event log) |
| `hud/`, `feel/`, `audio/`, `combat/` | HUD and summary, hitstop and damage numbers, sounds, shared combat types (`Hitbox` is a weak point) |

## Testing headless

Run Godot 4.7 with `--headless --fixed-fps 60 --path <project> -s <test script>`. Run `--headless --import` first after adding scripts or scenes. Find the 4.7 binary on this machine; an older Godot will not open the project cleanly.

Test scripts extend `SceneTree`. Things that have bitten before:

* Nodes added in `_initialize` are not in the tree yet. Fetch child references on the first `_physics_process`.
* A script error before the test returns `true` hangs the process. Always add a frame-count bailout.
* Mouse capture does not exist headless, so `PlayerIntent.is_active()` is false. Swap the intent's script for a stub that returns `true`.
* Check the test lane for crates and pillars before blaming game code.
* Set `Arena.profile_path` to a test file and delete it afterwards, so the real save is untouched.
* Set `RunLog.directory` to a `user://` folder, or the test writes into the tester's `.logs/`.
* Set `Arena.debug_contract`, or `ask_for_contract = false`, or the fight waits on the contract picker forever.
* A reloaded scene loses exports set on the instance, so after `reload_current_scene()` it is back on the real profile and log folder.
* Fire with `player.get_weapon()`, not a weapon reference taken at the start; the weapon in hand changes.
* No test scripts are kept in the repo. Write them in a scratch folder.

## Playtest logs

Every session writes one JSON-lines file to `.logs/` at the project root (ignored by git, newest 10 kept). After the tester plays, read the newest file before discussing how it went: what they felt and what the log shows are both evidence, and they have disagreed. The event list is in `docs/playtest-notes.md` under "Run log". Logs do not travel between machines.

## Where things stand

As of 2026-09-29. The plan is `docs/vertical-slice-kickoff.md`: twenty minutes of the whole loop, greybox. Order: AI, economy and loadout, contract ladder, base. For the slice, batches can be bigger; stop when a decision needs the tester.

Playable now: three contracts chosen from a picker (number keys at launch and on the summary), box robots with weak points (grunt chest eye, shooter lens that opens while it attacks, heavy core on its back), pistol and shotgun carried together (`1`, `2`, `Q` or wheel), stations that stock ammo (blue) or health (red), four sponsors, parachute pods, run summary with cash and reputation.

Last change, built but not yet played or committed (slice section 1, plus two asides):

* **Perception AI.** Enemies idle, get alerted, search and engage; sight cone, hearing of gunfire and of a held Warden zone; `?` and `!` marks; grunts flank, shooters back off along the floor. Extermination rosters start on the floor. `always_aware` on an `EnemyData` brings the old behaviour back.
* **HUD shrunk.** Sponsor rows pop in and fade; `~` is the debug HUD.
* **Shotgun bracketed high** on purpose: 16 pellets at 18, with scarce shells.

Open findings:

* The dash has dodged one hit in every logged run put together. Parked until people other than the tester have played; the fallback is a jump and a crouch.
* Survival contracts keep raising how many are alive whether or not the player is keeping up. The slice doc's fix: cap the alive count and stretch the ramp time.
* The navigation mesh covers the roofs and insides of the corner masses. Harmless so far.

Still to build for the slice:

* **Economy and loadout.** `ItemData`, two weapon slots, armour, a stim, the .357 for favour. The shotgun stops being free.
* **Favour.** Paid on a win only, from sponsor score, scaled by the contract; tens per fight. One contract carries a sponsor request for double.
* **Pods become rare** and **stations become vending machines.**
* **Contract ladder.** Five contracts in four tiers, with an easy one to step down to.
* **The base.** One room, four pedestals with text panels. A `Game` scene owns `Base` and `Arena`.

Reputation perks shown on the summary are teasers only; none are implemented.
