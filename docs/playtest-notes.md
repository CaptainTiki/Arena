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
