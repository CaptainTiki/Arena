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
* Money, favour, mail, what is owned and what is carried all go through `Locker`, which saves on every change.
* All damage goes through `take_hit(hit: HitInfo)`.
* Only `PlayerIntent` reads input. Everything else asks it. Keyboard, mouse and controller all arrive as the same intents; buttons come as events, sticks and the trigger are asked about each frame.
* Greybox visuals: boxes, capsules, flat colours. Sound is allowed; tones are generated from `ToneData`, no audio files.
* Level geometry is built from `arena/block.tscn` (set `size`, don't scale). The navigation mesh bakes itself on load.

## Layout

| Folder | Holds |
|-|-|
| `game/` | `Game` (the spine): swaps the base and the fight |
| `base/` | `Base` (the room between fights), `Kiosk` (locker, shop, terminal, and the door to the arena), `KioskPanel` (the menu), `MenuRow`, `MenuEntry` |
| `mail/` | `MailData` and the messages sponsors and the agent send |
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
* Through `game.tscn` the base opens its log in `_ready`, before a test can redirect it, so one file always lands in `.logs/`. Only the newest 10 are kept, so that file can push out one of the tester's. List `.logs/` before the run and delete only what the run added. This has already cost two of the tester's logs.
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

As of the end of 2026-09-30, on the laptop; moving back to the desktop. The plan is `docs/vertical-slice-kickoff.md`: twenty minutes of the whole loop, greybox. For the slice, batches can be bigger and design choices inside the slice doc are made without asking; stop when a decision truly needs the tester, then discuss, commit, go again.

Played and liked today: the kiosk menus, the door, the shop, mail, cash-only stations with falling prices, the debug kiosk, and the scoped rifle with the .357. **Nothing is built but unplayed except controller support.** Sponsors, pods and rewards are due a full overhaul (brands, agents, personalities, quests, discounts; see the notes from 2026-09-30), so their numbers are being ignored on purpose until then.

The loop as built: start in the base with a pistol and $100. Read the mail and book a contract at the agent's terminal, shop, set the loadout at the locker, then go through the door, which only opens once a contract is booked. Fight, get paid on a win, come back. Favour with each sponsor comes from what they scored in the fight, times the contract's multiplier, doubled for the sponsor who asked for that contract. Favour is standing and is never spent: at 35 the Warden mails an offer and the shotgun appears in the shop, the Marksman's rifle at 90, the Butcher's .357 at 160. Cash buys everything: those weapons, vests, stims, a pistol mod, and ammo or health at stations mid-fight, where the price is shown in yellow and falls to half while the shelf sits untouched. Losing a contract a sponsor asked for costs favour with them. The debug kiosk in the base adds cash or favour, opens the ladder, or resets the save.

Keys: `E` interact and pay, right mouse aims the rifle, `F` stim, `1` `2` `Q` wheel for weapons, `~` debug HUD. In a menu: `W` `S` move, `A` `D` change, `E` or a click chooses, `Esc` goes back. The controller layout is in the notes under "Controller support".

Every number in the economy is a placeholder. Nothing has been balanced; the twenty-minute arc has not been played end to end.

### Start here next session

1. Different machine again (the desktop). Find its Godot 4.7 binary, run `--headless --import`. The save and `.logs/` do not travel; the desktop's save is from before the shop and mail, and will get its mail on first load.
2. Next build: **the agent's read** at the terminal. A letter from the agent assembled from pre-written sentences picked by the numbers: an opener from overall mood, a line per sponsor whose favour moved in the last fight, a nudge about owned gear left unused, a line for anything new in the shop, a sign-off. No numbers shown. Placeholder lines for the current four sponsors; the tester's example is in the notes under "The agent's read". Needs the last fight's favour changes and which weapons were fired kept in the save.
3. Then the sponsor overhaul, from the 2026-09-30 notes, once the read has been played.

Open findings:

* The dash has dodged one hit in every logged run put together. Parked until people other than the tester have played; the fallback is a jump and a crouch.
* Every sponsor offer arrives within three wins; the Warden pays 180 or so for a fight with zones held. Too fast, known, and waits for the overhaul.
* The shotgun is bracketed high on purpose (16 pellets at 18, scarce shells) to find out what overpowered feels like. It has not been played since it went behind a price.
* Rifle and .357 have each been played once and liked. The rifle is helpless up close; whether the other slot should cover that is a slot question. Running `arena.tscn` on its own carries all four weapons.
* Controller: built with no controller plugged in. No aim assist, and the prompts still name keys.
* The player starts 2 m from the `EastSouth` spawn booth. Robots do not use a booth within 20 m of the player, but they can once the player has moved off.
* The .357 kills anything through its weak point. The slice doc wanted heavies killed from the front; a heavy's weak point is on its back, so that is not true yet.
* The navigation mesh covers the roofs and insides of the corner masses. Harmless so far.
* A quiet player on a survival or scavenger contract may never be found; untested by a person since perception went in.

After the arc plays through, per the slice doc: get two people who are not the developer through it, then answer its two questions.
