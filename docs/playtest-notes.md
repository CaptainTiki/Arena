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
