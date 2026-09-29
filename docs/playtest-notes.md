# Playtest notes

Findings per build step, kept so the six kickoff questions can be answered honestly at the end.

## Step 1 — arena, movement, dash (2026-09-28)

* **Dash:** good as tuned (28 m/s, 0.18 s, 1.2 s cooldown).
* **Sprint:** fine (11 vs 7 m/s).
* **Camera:** fine for now at 60 Hz physics, no interpolation.
* **Arena:** feels weird; not complex enough to be entertaining. Early signal on question 5 (flat arena gets boring), judged with no enemies present.
  * Wants different vertical levels.
  * Wants hiding spots to run away from things.
  * Pod placement should force the player to engage to collect them.
  * Implications: no-jump rule means ramps; cover and levels mean enemies need navmesh pathfinding rather than running straight at the player.
  * Decision: revisit the arena once enemies exist (after step 3 or 4).

## Step 2 — weapon, ammo, reload (2026-09-28)

* **Gun, shots, reload:** good, work as intended.
* **Fire rate:** fine for a cheap pistol that takes several shots to kill. Later weapons can be meatier.
* **Headshots:** almost too easy, even at range. Gun bounce alone is not enough; the aim itself needs to kick. Added aim recoil (pitch up plus random yaw) in response.
* **Ammo limits:** just annoying while testing feel with nothing dropping ammo. Added a debug infinite-reserve toggle on the Arena node (on by default). Question 2 (shoot to earn shots) can't be judged until pods exist.
* **Arena, sharpened (step 2):** the real problem is scale and exposure. Two dashes cross the arena, so going for a pickup never means giving up a position, and nothing about moving around risks being seen. The rework needs to be bigger and non-rectangular, with sight lines that make crossing open ground a decision.

## Step 3 — enemies, spawner (2026-09-28)

* **Threat:** none. 100+ kills on a first run, gave up rather than died, could have reached 150 to 200. Early signal on question 1: backpedal-and-shoot trivialises a horde that only runs straight at you.
* **Attacks:** never saw a windup or an attack land. The only damage came from backing into enemies behind. Cause: player backpedalled at 7 m/s, grunts chased at 4.5 m/s, so they never got into range.
* **Pressure:** none until about 15 alive, and even then the pack bunched up in front while backpedalling.
* **Recoil:** good direction, not enough. Repeated headshots from across the map were still easy.
* **Requests:** slower backward movement; smaller head; 2 headshots or 4 body shots to kill; 12-round mag (think .380 rather than 9 mm).
* **Changes made in response:**
  * Backpedal at 60% speed, sprint forward only.
  * Grunts 5 m/s with a per-enemy speed spread, and each leads the player by a random amount to cut them off.
  * Melee is now a windup (orange, squash) then a fast straight-line lunge, so standing or backing away gets hit and sidestepping or dashing dodges.
  * Head hitbox radius 0.45 to 0.25 and raised to 1.9 m, above the player's 1.6 m eye line, so level aim hits the body.
  * Health 30 to 40, mag 6 to 12, recoil 2.2 to 3.4 degrees pitch with slower recovery.

## Step 4 — feel pass, plus the step 3 fixes (2026-09-28)

* **Overall:** feels much better.
* **Windup and lunge:** readable. Can watch the windup and dodge with dash or a sidestep.
* **Pressure:** real now. Had to dodge, move, run and gain distance to shoot; health went down constantly. Possibly a bit too harsh, but better on this side. Leave for the tuning pass (step 8).
* **Hitstop:** not noticeable even on headshot kills, and that is fine. Tester dislikes hitstop as a game feel in general, especially when it fires constantly. Do not make it stronger; candidate for removal.
* Early read on question 1 (does first-person horde combat feel good): yes, once enemies can actually threaten a moving player.

## Arena rework, first pass (2026-09-28, not yet playtested)

Built in response to the step 1 and step 2 arena notes. Not one of the kickoff doc's numbered steps.

* 100 x 100 m cross shape instead of a 40 x 60 m rectangle; the four corners are solid masses.
* Centre: open ground with four pillars and four low crates (can shoot over, cannot walk through).
* North: terrace 3 m up, two ramps.
* East: two tall staggered walls making an S-shaped alley with broken sight lines.
* South: bridge 3 m up with a ramp at each end; walkable underneath.
* West: walled bunker room with two doorways.
* Enemies now path with a navigation mesh, baked on load, instead of running in a straight line.
* Open questions for the playtest: is it big enough that crossing is a decision; do the terrace and bridge feel like positions worth holding; is the bunker a hiding spot or a death trap.

## Arena rework, playtest (2026-09-28)

* **Overall:** feels good. Likes the levels, the movement and the blockers. Where to move is now a real decision. Update on question 5: a flat arena was boring, this one is not.
* **Crossing:** still relatively easy to get anywhere. The missing pressure should come from enemies rather than more geometry.
* **Enemy variety wanted** (kickoff doc lists this as out of scope; tester now wants it):
  * Small units that stop you standing still (the current grunt).
  * Heavy: slow, meaty, area denial, big damage if you stay close too long.
  * Shooter: ranged, so leaving cover hurts and crossing has to be quick.
* **Terrace and bridge:** not worth holding, just places to pass through. Idea: hold-the-zone mechanic, stay within range of something for X seconds and it drops Y. Could be a future route to ammo or health. Fits as a fourth sponsor trigger.
* **Bunker:** not found during the playtest (west arm). Concern: a room without two exits is a death trap. It has two doorways, east and south.
* **Pathing:** no enemies seen getting stuck.

## Steps 5 and 6 — sponsors and pods (2026-09-28)

* **Pods:** liked. Actively tried to earn more ammo, and chained kills on purpose for the bigger mag and fire rate. Answer to question 4 (does courting sponsors change play): yes.
* **Readability:** knew why points were being scored, because the meter lists what each sponsor wants. Answer to question 3: readable, but only thanks to the on-screen text. Future: the player needs somewhere to read about their sponsors between missions.
* **Ammo economy:** likes it so far (question 2), but accuracy should not be the only route to ammo.
* **Crossing:** still not hard. "Dash, dash, pick up stuff." Needs more dynamics to make it a choice.
* **Changes made in response:** heavy and shooter enemies; a fourth sponsor that pays ammo for holding a marked zone, which moves after each payout.

## Enemy variety and hold zones (2026-09-28)

* **Overall:** tough, but a lot more fun than where it started.
* **Heavy:** never gets close; easy to walk around. Needs more base speed and a way to close distance, such as an occasional charge when the player is beyond some range.
* **Heavy health:** too much for the pistol alone. Too many shots for one kill.
* **Changes made in response:** heavy speed 2.6 to 3.4 m/s, health 300 to 140, and a telegraphed straight-line charge when the player is 10 to 30 m away and visible, on a cooldown.

## Step 7 — run summary, reputation stub, heavy rework (2026-09-28)

* **Summary screen:** a lot of text, but readable for now. Trim when it gets a real design.
* **Progression stub:** liked. Answer to question 6 (is meta-progression worth building): yes, the hook lands.
* **Dash:** should be a dodge, not travel. Halve its velocity so it moves you less far. Changed dash speed 28 to 14 m/s (about 2.5 m per dash instead of 5).
* No complaints recorded about the heavy's charge or its 140 health this round.

## The six questions, as of 2026-09-28

1. **Does first-person horde combat feel good?** Yes, but only once enemies could threaten a moving player. Straight-line chasers were trivially kited by backpedalling.
2. **Does "shoot to earn shots" create tension?** Yes, liked. But accuracy cannot be the only source of ammo; the hold-zone sponsor was added as a second route.
3. **Is the sponsor system readable?** Yes, because each meter states what the sponsor wants and shows reactions. It leans on text; the real game needs a place to read about sponsors between runs.
4. **Does courting sponsors change how people play?** Yes. Chased ammo through accuracy and chained kills on purpose for the mag and fire-rate pods.
5. **Does a flat arena get boring?** Yes, immediately. Levels, cover and a non-rectangular shape fixed the boredom; enemy variety (shooter, heavy) is what makes crossing it a decision. The real project needs designed or generated arenas, not a box.
6. **Is meta-progression worth building?** Yes, the stub was liked.

Still open: overall difficulty was called tough and possibly too harsh; tuning pass pending. Only one tester so far.

## Dash at half speed, and full-run pacing (2026-09-28)

* **Dash:** much better at 14 m/s. "Awesome as it is." Leave it alone.
* **Tuning values:** fine as they are. The problem is pacing, not numbers per enemy.
* **Pacing:** the game plays too quickly. The arena fills too fast with too many big enemies. Wants real progression: start slow, ramp over time, and be almost too much at 12 to 15 minutes, by which point the player should have picked up health, fire rate and so on.
* **Ammo:** running out a lot. Sponsors should not be the only source. Wants fixed ammo stations around the map ("vending machines"): several of them, restocking on a timer of a minute or two, with lights showing state (flashing when about to restock, green when stocked). Possibly hold nearby for a few seconds to collect.
* **Pods:** should not slam straight down. Wants them to float down on a parachute over 15 to 20 seconds, drifting one way then another before settling.
* **Heavy:** likes it as it is now, including the area size, but dislikes the disc on the ground. The reach should not be advertised. Think big arms that it swings down.

## Direction decisions (2026-09-28)

Decided by the tester:

* **Pods:** parachute descent, 15 to 20 s, drifting. The landing spot is NOT shown in advance; that is the point. The pod is announced, you look up, guess and commit, and risk another look. The beacon only lights once the pod is down and collectable. Wanted an alarm on the announcement (no audio in the greybox, so visual only for now).
* **Ammo stations:** walk-up grab, no holding.
* **Warden:** swaps from plain ammo to a bigger bonus (damage up, large ammo crate).
* **Pity drop:** keep. May carry cash or coin later.
* **Heavy:** no floor disc; arms that swing down.

Proposed by the tester for the next prototype stage, still greybox:

* **A home base** between fights, with things to walk up to: a weapon rack, a wardrobe for loadout, a computer to book the next fight, and somewhere to read up on sponsors, arenas and enemies.
* **Fights as contracts:** each one states its time limit, its enemies and a cash reward.
* **Less swarm, more danger:** roughly double the damage enemies take, and far fewer of them, so a roster like "4 grunts, 3 rifles, 2 shotguns and a heavy" tells you what you are up against.
* **Money** buys weapons, armour and mods that change the loadout.

This replaces the 15-minute ramp as the main structure, so the pacing-ramp rework was not built.

## More direction decisions (2026-09-28)

* **Contract types:** extermination, survival and scavenger ("collect the Warden 4 times").
* **Extermination ends** when everything is dead: kill everything and win. The timer acts as the difficulty curve, possibly.
* **Build order agreed:** contracts and combat pivot, then new enemy types, then the base, then the economy.
* **The kickoff doc is not binding.** "We find the game. We find the fun." Nothing in it is chiselled in stone, including the no-audio rule. Sound is in.
* **Home base vision:** display trophies, build the loadout, pick a mission and get paid, talk to an agent who is finding the next fight, research enemies and the next arena, learn the sponsors.

Built in response: contract resources with three starting contracts (First Blood, The Warden's Errand, The Long Night), roster spawning with waves that arrive early when the floor is cleared, per-contract enemy health and damage scaling, pistol damage doubled to 20, cash and booking saved to a profile, a contract briefing card and objective line, and generated beep sounds for pod drops and contract results.

## Contracts and combat pivot, playtest (2026-09-29)

* **Enemies:** fall quickly. Not much pressure.
* **Finding enemies:** several times the tester was looking for something to fight.
* **Warden zones:** easy to hold, nothing pushed the tester off them. Idea: holding a zone should alert anything within sight or hearing. Points toward enemies having perception (idle, alerted, searching) rather than always knowing where the player is.
* **HUD:** far too much on screen, feels like 75% of it. Shrink it, and put the verbose data behind a debug key (~). Only two people use this build.
* **Event log wanted:** timestamped log of player actions (dash, shoot, reload, hit taken) with position and rotation, a position breadcrumb every second or so, and enemy events (alert, attacking, hit, killed), so runs can be analysed afterwards.
* **Fact check on the AI as built:** no idle and no perception. Every enemy is handed the player on spawn and paths to them through the navmesh, replanning every 0.25 to 0.5 s, walls or not. So an alert from the Warden zone would change nothing today; the empty stretches come from low counts on a 100 m map, spawns at least 20 m away, and shooters that stop at 24 m and wait.

## Run log (2026-09-29, not yet used on a real playtest)

Built before any AI work, so pressure can be tuned from data rather than impressions.

* One file per session in `.logs/` at the project root (ignored by git, delete freely), named after the project version and the launch time. It stays open across fights and the time between them. One JSON object per line.
* Kept small on request: roughly 300 bytes per second of play, and only the newest 10 files are kept.
* Every line carries session time `t` and event `ev`. Player lines add `pos`, `yaw` and `pitch`.
* Player events: `shot` (sky, world, body or head, with the enemy struck), `dry_fire`, `reload_start`, `reload_done`, `dash`, `damaged`, `dodged` (a hit the dash went through), `zone_enter`, `zone_exit`, `ammo_station`, `pod_collected`.
* Enemy events: `enemy_spawn`, `enemy_windup`, `enemy_attack`, `enemy_killed`, each with id, type, position, distance to the player and health.
* World events: `run_start`, `run_end`, `zone_active`, `pod_drop`, `pod_landed`.
* `crumb` every second: player speed, health, ammo, enemies alive and the nearest one. Every third crumb lists each enemy's position and state.
* Decision: perception AI (sight cone, hearing, search, all enemies on the floor from the start) waits until logs from a playthrough or two have been read.

## What the first logs say (2026-09-29, one run of each contract)

| | First Blood | Warden's Errand | Long Night |
|-|-|-|-|
| Result | won at 1:35 | died at 2:16 | died at 2:11 of 15:00 |
| Kills | 15 | 31 | 25 |
| Hits that were headshots | 75% | 85% | 64% |
| Hits to kill a grunt | 1.2 | 1.1 | 2.4 (health x2) |
| Grunts killed before they ever attacked | 8 of 9 | 23 of 27 | 11 of 20 |
| Seconds with nothing within 25 m | 37 of 96 | 43 of 137 | 6 of 132 |
| Damage taken per minute | 43 | 50 | 46 |
| Hits dodged with the dash | 0 | 0 | 0 |

* **Headshots are the whole story on enemy health.** A headshot does 40, a grunt has 40 and a shooter 20, so nearly every kill is one bullet. The combat pivot doubled pistol damage without touching enemy health.
* **Most grunts never get to attack.** They spawn about 50 m out, walk in a line for ten seconds, and die at about 8 to 10 m.
* **Shooters do half the damage** despite being a seventh of the enemies, because they are the only thing that can hurt from outside pistol-headshot comfort range.
* **Warden zones are safe:** six payout-length holds across the runs, damage taken during four of them was zero.
* **Death is attrition, not pressure.** Damage arrives at 45 a minute in every contract, against 100 health and one health pod collected in three runs. A run lasts about two minutes whatever the contract says.
* **The dash is not used as a dodge.** Three to seven dashes a run, none of them through a hit.
* **Long Night is the only one that feels crowded** (61 of 132 seconds with something inside 8 m), and that is the one with doubled enemy health.

## Direction talk: weak points, healing, favour (2026-09-29, nothing built yet)

* **The combat pivot was meant to double enemy health, not pistol damage.** The earlier note recorded it the other way round and it was built that way. To be corrected: pistol back to 10, enemy health doubled.
* **Headshots feel good and should stay a one-slap kill.** Make them harder to land rather than weaker: shrink the target.
* **Robots, not people.** Hunger Games meets Robotron. Weak points such as eyes or joints instead of a generic head, possibly different per enemy type.
* **Healing will exist.** Idea: ammo stations get buttons to buy a health pack with cash or with sponsor favour. Spending favour competes with saving it for a sponsor's reward (say, level 5 with the Butcher for a cleaver).
* **A losing player drops down a level** and takes easier contracts to earn favour without spending it. Easy contracts pay little favour, hard ones carry a multiplier.
* **Sponsor requests:** a sponsor asks your agent for a specific fight and pays double favour for it.
* **Favour is now logged** per sponsor at the end of every run, with cash, so prices can be set from real earnings.
* **Favour earned in the three logged runs** under the current rule (one per two pods dropped, rounded up, capped at three per sponsor, paid win or lose): First Blood 4, Warden's Errand 8, Long Night 6. About 1 to 3 per sponsor per run.

## More direction decisions (2026-09-29)

* **This is a prototype, not pre-alpha.** Exploring ideas and finding the fun. The proper build (component first, optimised) starts only once the direction is decided and it is fun to play.
* **A loss pays no favour.**
* **Favour is paid at the end of the run.**
* **Pods should be special, not candy at a parade.** Current drop rates are test tuning. A sponsor throws a pod for a specific feat, for example the Butcher drops a health kit for taking 90 damage and staying alive two minutes. The feat's numbers scale with the contract's difficulty multiplier.
* **Everything else comes from vending machines:** spend favour or cash at a station for health or ammo. Stations do not all stock everything, so fighting your way to one can end with no health kit and a run across the map to the next.

## Pivot correction (2026-09-29, not yet playtested)

| | Before | Now |
|-|-|-|
| Pistol damage | 20 | 10 |
| Weak-point multiplier | 2x | 8x |
| Grunt health | 40 | 80 |
| Shooter health | 20 | 40 |
| Heavy health | 140 | 280 |
| Head radius, grunt and shooter | 0.25 m | 0.18 m |
| Head radius, heavy | 0.35 m | 0.25 m |

* A head hit still kills a grunt or shooter in one bullet; the body now takes 8 and 4. The heavy takes 4 head hits or 28 body shots.
* The head was shrunk in the same batch because the tester lands 65 to 85% headshots; without it this change would play the same as before.
* Long Night still doubles health on top, so its grunts take two head hits.
* To watch in the log: share of hits that are headshots, and how many grunts die before attacking.

## Pivot correction, playtest (2026-09-29, one run of Long Night)

* **Feel:** better. Likes the new headshots and health. Hard with only the starter pistol and no way to heal.
* **Log, compared with the Long Night run before the correction:**

| | Before | After |
|-|-|-|
| Died at | 2:11 | 2:12 |
| Kills | 25 | 23 |
| Shots fired | 110 | 86 |
| Shots that missed everything | 34% | 36% |
| Hits that were headshots | 64% | 87% |
| Grunts killed before attacking | 11 of 20 | 16 of 20 |
| Damage taken per minute | 46 | 48 |
| Seconds completely out of ammo | not measured | 9 |

* **The smaller head did not make headshots rarer.** The head sits on top of the body like a lollipop, so a shot aimed at it either hits it or misses everything; it never falls back to a body hit. The tester now aims only at heads, at about 6 m, and lands 94% of hits there inside 8 m.
* **No heavy was killed** (three spawned). In Long Night a heavy has 560 health, seven head hits.
* **Shooters did 60 of the 105 damage taken.**
* **Still no hit dodged with the dash.**
* A second run in the log lasted 11 seconds with no shots or movement; ignored.

## Robots, weak points and station stock (2026-09-29, not yet playtested)

Built because shrinking the head changed nothing: a head on top of a body is hit or missed, never grazed into a body shot.

| Robot | Shape | Weak point | How to reach it |
|-|-|-|-|
| Grunt | Squat red box | Eye on the chest, 0.14 m radius | From the front only. A near miss is a body hit |
| Shooter | Thin teal mast with a turret head | Lens on the turret, 0.16 m radius | Shut behind a dark shutter while it walks; open while it winds up, fires and recovers |
| Heavy | Purple slab with arms | Core on its back, 0.3 m radius | Turns slowly, and stays facing the way it struck until it recovers, so dodge the charge and shoot its back |

* All weak points are yellow and take the same 8x multiplier. In code they are still called heads.
* Heavy turn speed 6 to 2.5.
* **Stations** now stock ammo or health, rolled at each restock (40% health). Blue light for ammo, red for health. Steady is stocked, flashing is arriving within 15 s, no light is empty with nothing on the way. Health heals 30 and stays on the shelf if the player is at full health. Free for now; spending favour or cash comes later.
* The log's `ammo_station` event is now `station`, with what was taken.

## Robots, weak points and station stock, playtest (2026-09-29, one run of Long Night)

* **Feel:** liked a lot. Health was a boon; healed often and felt it kept the run going.
* **Never in control.** Too many small robots to even try for a heavy's back; running the whole time. Wants a crowd-control weapon, a shotgun or a machine gun, or the pistol does less and less as small robots are added.

| | Heads on top | Robots |
|-|-|-|
| Died at | 2:12 | 2:48 |
| Kills | 23 | 18 |
| Hits on a weak point | 87% | 32% |
| Hits to kill a grunt (160 health in this contract) | 2.2 | 4.6 |
| Kills per minute | 10.5 | 6.4 |
| Damage taken per minute | 48 | 59 |
| Seconds with something inside 8 m | 54 of 132 | 93 of 169 |
| Health picked up at stations | none existed | 60 |

* **The chest eye did what the smaller head could not:** weak-point share fell from 87% to 32% and body shots came back (75 of 111 hits).
* **Killing slowed while spawning did not.** The survival ramp keeps raising how many are alive, so the floor went from 5 to 15 and the last minute had one kill. That is the loss of control.
* **Grunts are now the main damage** (90 of 164), where shooters were before.
* **Heavies:** 15 body shots landed on them, none on a core, none killed. They charged 14 times and connected twice.
* **Still no hit dodged with the dash**, in 11 dashes.
* Every logged run since the first three has been Long Night, the hardest contract with doubled health. Nothing is known yet about how the robots play on the other two.
* Decision: build a shotgun as the crowd-control weapon, carried alongside the pistol.

## Shotgun and weapon switching (2026-09-29, not yet playtested)

* Both weapons are carried from the start. `1` pistol, `2` shotgun, `Q` or the mouse wheel swaps. Swapping cancels a reload and takes 0.35 s before the shotgun can fire.
* **Shotgun:** 8 pellets at 10 damage each inside a 5 degree cone, 6 shells, 0.8 s between shots, 2.2 s reload, 40 m range. Weak-point pellets do 2x, not 8x; it is a body weapon. Each pellet shoves.
* A full blast kills a grunt (80 health) outright. In headless tests 7 or 8 pellets landed on a grunt at 4 to 6 m.
* **Ammo is shared out, not chosen:** every ammo pickup feeds both weapons, the shotgun at half the count (AMMO +18 is 18 rounds and 9 shells). Mag, fire rate and damage pods upgrade both.
* The pity drop only triggers when both weapons are empty.
* Sponsors and stats count one shot per trigger pull, judged by the best pellet.
* Log: `shot` lines carry the weapon, pellets landed and total damage; `weapon` marks a swap.

## Shotgun, playtest (2026-09-29, Long Night then First Blood)

* **Shotgun felt really weak.** Nothing died to one shot, even close, even on the weak point. Not sure it helped or hurt.
* **Contracts could not be chosen.** The game offered only "again" or "next", which is why every earlier run was Long Night.
* **Log:** 30 shotgun blasts, 12 kills, average 74 damage per blast that hit, at an average 5.6 m. A full blast was worth exactly 80, a grunt's full health, so one stray pellet meant no kill; and 22 of the 30 blasts were fired in Long Night, where a grunt has 160.
* **The shotgun did kill heavies:** two, the first heavies killed in any logged run. Body damage in bulk gets through where pistol body shots did not.
* **Changes made in response:**
  * Shotgun: 10 pellets at 12 damage (120 a blast, was 80), weak-point pellets 3x (was 2x). A grunt at normal health now dies with 7 of 10 pellets.
  * Contract picker: the first fight of a session waits on a list, and the summary screen offers the same list. Number keys 1 to 3 choose, click repeats the last one.

## Shotgun second pass, playtest (2026-09-29, First Blood then Long Night)

* **Better, still not satisfying.** Rule from the tester: half the pellets should kill a grunt, so a mostly missed blast still kills and the stray pellets chew the crowd behind. The pistol stays as it is.
* **Log, First Blood:** 11 blasts, 7 kills; 5 of 7 blasts at grunts killed. The pistol had 19 shots for 7 kills in the same run. Died at 0:59, 72 of 102 damage from shooters.
* **Log, Long Night:** 30 seconds, pistol only, died to grunts and a heavy slam. First hit ever dodged with the dash.
* **Change made:** shotgun 12 pellets at 14 damage (168 a blast, was 120), cone 5 to 7 degrees. Six pellets is 84, enough for a grunt at normal health.
* Pellets already carry on through a robot that dies mid-blast and strike whatever is behind it.

## Shotgun third pass, playtest (2026-09-29, First Blood twice, desktop)

* **Feel:** OK, still not blown away. The numbers may simply be off against enemy health; talk numbers before chasing feel further. Good enough to move on.
* **Log:** 29 blasts, 19 kills. Against grunts 11 of 14 blasts killed, and every blast inside 5 m did. Two heavies killed, both with the shotgun. Damage taken: heavies 66, grunts 60, shooters 36.
* **Dash:** 8 dashes, nothing dodged. The tester puts this down to not being used to dodging in a shooter. Not to be judged until other people have played. If it does not land with them either, the alternative is a jump and a crouch: hide behind things and hop over them, and drop the dodge.
* **Decision, bracketing:** push the shotgun past the mark on purpose to find out what overpowered feels like, and make its ammo scarce. The pistol is the main weapon; the shotgun comes out to clear fodder and goes away again.

## Direction decisions (2026-09-29, vertical slice)

* `docs/vertical-slice-kickoff.md` is the plan: twenty minutes of the whole loop at greybox quality. Order: AI, economy and loadout, contract ladder, base.
* **Way of working for the slice:** small playable batches are still the default, but batches can be bigger and some play pauses skipped to reach the full loop. The base, its pedestals and their panels go in as one push and get refactored afterwards if needed. When a decision needs the tester: stop, discuss, commit, go again. Numbers get tuned once the whole game is in place.
* **HUD:** health and ammo stay. The dash bar shows only while the dash is recharging. Sponsors come up at the top left when they like something and fade after a second or two. Everything else goes behind the debug key.

## Shotgun bracket, HUD shrink, perception AI (2026-09-29, not yet playtested)

**Shotgun**

| | Before | Now |
|-|-|-|
| Pellets | 12 | 16 |
| Damage per pellet | 14 | 18 |
| Full blast | 168 | 288 |
| Spare shells at the start | 12 | 6 |
| Share of every ammo pickup | half | a quarter (a 12-round station is 3 shells) |

Deliberately too strong. Five pellets kill a grunt at normal health; a full blast is more than a heavy's 280.

**HUD**

* Always on: health bar, ammo, crosshair, a one-line objective at the top.
* Only while they matter: dash bar (recharging), reload bar, status line, pickup and approval text. All text is roughly half the size it was.
* Sponsor rows are hidden. A row comes up when that sponsor likes something or sends a pod, holds a second and fades over a second and a half. Body hits (the Marksman's small change) do not bring the row up, or it would never leave.
* `~` toggles the debug HUD: the time, kills and alive line, and every sponsor row held on screen with what the sponsor wants. The choice carries over between fights.

**Perception**

* Enemies start `IDLE` and wander. `ALERTED` is walking to a last-known position, `SEARCH` is looking around it, and `CHASE` onward is engaged, which is the old behaviour.
* **Sight:** range and cone per type, blocked by walls, checked about seven times a second. Inside 3.5 m they notice whichever way they face.

| | Sight range | Cone |
|-|-|-|
| Grunt | 30 m | 120 degrees |
| Shooter | 45 m | 90 degrees |
| Heavy | 25 m | 100 degrees |

* **Hearing:** every shot is a noise at the player's position: pistol 40 m, shotgun 70 m. Walls do not muffle it. The position they are given is wrong by up to 3 m. Being shot also sends them to where the shot came from.
* **Held Warden zone:** a noise at the zone once a second, 45 m.
* **Losing the player:** engaged and unsighted for 4 s, they go to where they last saw the player, search for 6 s, then go back to wandering.
* **Marks:** nothing over an idle robot, a yellow `?` while it hunts, a red `!` once it has seen you.
* **Grunts** come in from different sides once three are engaged: each heads for its own point 7 m from the player before turning in.
* **Shooters** back off along the floor instead of straight into a wall, now from 12 m (half their 24 m range, was 9 m). Sent to a last-known position, they go to a spot 10 to 22 m from it that can see it.
* **Heavies:** senses only, otherwise unchanged.
* **Extermination:** the whole roster is on the floor from the start, at least 20 m from the player, 8 m from each other, out of sight of where the player starts. The wave clock is off (`roster_on_floor` on the contract turns it back on).
* **Survival and scavenger** still spawn at the edges over time, now unaware.
* **The old behaviour** is `always_aware` on an `EnemyData`. The slice doc asked for a huge sight range to do this, but sight still needs a line and a cone, so a range alone would not bring it back.
* **Log:** `enemy_alert` (with `cause`: sight, gunfire, zone or hit, and the state it went to), `enemy_lost`, `enemy_search`, and `enemy_calm` for giving up. Crumbs list the new states.

**To watch when it is played**

* Whether a quiet player on a survival or scavenger contract is ever found. In a headless run with the player standing silent, most of the crowd stayed idle at the edges.
* Whether 15 robots at once on First Blood is a fight or a pile-on after the first shotgun blast.
* Found on the way: the navigation mesh also covers the roofs of the four corner masses and the floor inside them. Nothing can reach either, and roster placement checks for a way in, but wander and search points near a corner can land there and the robot walks to the wall instead.

## Perception, first play (2026-09-29, one run of First Blood)

* **"Ouch."** Died at 0:21 with 6 kills, starting in the middle of the map.
* **Log:** seen by a robot at 0.02 s, before moving. The first pistol shot at 4.3 s alerted six at once, and 28 alerts were logged in 21 seconds. Damage came from grunts (30), shooters (36) and a heavy (two slams, 34 and the kill).
* **Cause of the instant sighting:** placement was checked for sight and then nudged up to 2 m sideways, which could move a robot out from behind its cover. The check also used one height, not the one the robots look from.
* **Decision:** the player starts in a corner, on a `PlayerSpawn` marker placed by the tester (east arm, south side), with nothing next to them and everything round a corner.
* **Changes made in response:**
  * `Arena` puts the player on `PlayerSpawn`, facing the way the marker faces.
  * A roster on the floor now starts at least 30 m from the player (was 20), with no nudge, and out of sight at both chest and eye height.
* Headless, five starts: nearest robot 30 to 39 m away, nobody aware at the start. Standing still and silent for 30 seconds, the player was found once, at 28.6 s, by a wanderer.

## Perception, corner start, playtest (2026-09-29, one run of First Blood)

* **Liked a lot.** Cautious play is rewarded; moving round the map matters. The furthest the tester has got in a playthrough.
* **Log:** won at 1:29, 15 kills, 32 shots (24 pistol, 8 shotgun), 10 weak-point hits. Hit three times in the whole fight (two shooters, one grunt). 18 alerts by sight, 13 by gunfire, 1 by being shot. Three robots lost the player; one searched.
* **Too short.** A careful player clears the floor in a minute or two. Idea: spawn booths on the sides of the map that let more in from time to time.
* **Pods:** 6 dropped in 89 seconds. Still candy.
* **Decisions for the rest of the slice:**
  * Weapons are sold by sponsors: the Butcher sells the shotgun, the Marksman a rifle, the Warden the .357.
  * Two vests instead of light and heavy armour. The ammo vest starts with more ammo and has bigger pockets. The armour vest cuts damage taken, but starts with less ammo and carries less.
  * The rest of the slice is built as one push.
