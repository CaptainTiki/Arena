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
