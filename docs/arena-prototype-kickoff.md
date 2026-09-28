# ARENA — Greybox Prototype Kickoff

**Working title:** Arena (rename later)
**Engine:** Godot 4.x, GDScript
**Repo:** fresh. No code, scenes, or assumptions carried over from any other project.
**Goal:** a playable greybox in the shortest path possible, so we can feel the core loop and decide what survives into the real project.

This is a prototype. It exists to answer questions, not to be good. Read the "Questions this prototype answers" section before writing any code — if a task doesn't serve one of those questions, it's out of scope.

\---

## The pitch (one paragraph)

First-person arena shooter roguelike. You're a gladiator. The arena is ringed by **sponsors** who watch you fight and reward the kind of fighting they like. Kills and style earn drops — ammo, health, weapons, upgrades — which land as pods somewhere on the arena floor, and you have to go get them under pressure. Your build emerges from how you play, not from a menu. Between runs, sponsor reputation persists and grows: number-go-up is literally how much you get to pull the trigger.

Reference points: Smash TV / Robotron (arena, crowd, pickups under pressure), Doom Eternal (resource loop driven by aggression), Vampire Survivors (run structure, ramping density), Risk of Rain (build emergence).

\---

## Questions this prototype answers

1. **Does first-person horde combat feel good?** Or is the camera fighting the genre?
2. **Does "shoot to earn shots" create tension?** Does a good player feel rich and a scared player feel starved?
3. **Is the sponsor system readable?** Can the player tell *why* a pod dropped? If it feels random, the concept is dead.
4. **Does courting sponsors change how people play?** Do testers actually chase headshots because the headshot sponsor is watching?
5. **Does a flat arena get boring?** This decides whether the real project needs level generation.
6. **Is meta-progression worth building?** Does a fake unlock screen make testers want to run again?

\---

## Hard rules

* **Greybox only.** Capsules, cubes, cylinders, CSG. No meshes, no textures, no materials beyond flat color. No audio. No menus beyond a run-summary screen.
* **If it can't be tested with a cube and a `print()`, it's out of scope.**
* **Everything tunable lives in Resources.** Weapon stats, sponsor rules, spawn curves, pod contents. Tuning should never require touching a script.
* **Loud feedback.** Every reward event gets a big on-screen text pop and a distinct flat-color pod. Readability is a test subject, so over-communicate.
* **No polish that isn't feel.** Hitstop, screenshake, knockback, damage numbers, kill pops: yes, these are the test. Post-processing, particles, UI styling: no.

\---

## Architecture conventions

Follow these; they are house style, not suggestions.

* Scenes-first composition. Node-first authoring. No runtime node generation — everything is instanced from scenes; use object pools for anything spawned in volume (enemies, projectiles, pods).
* `class\_name` on every script, explicit static typing everywhere.
* Content is Resources: `WeaponData`, `SponsorData`, `PodData`, `SpawnWave`, `EnemyData`.
* Tight coupling with a clear ownership spine over a global signal bus. `Arena` owns `Spawner`, `SponsorDirector`, `PodDropper`, and `Player`. Children talk up to their owner; the owner routes. Avoid autoload event buses.
* Damage goes through a single `take\_hit(hit: HitInfo)` chokepoint on anything damageable.
* Input isolation: the player reads an intent component; nothing else reads input directly.
* Horde enemies are LOD'd: `CharacterBody3D` when active/near, cheaper `Node3D` shells when distant. Collision shape count is the primary perf lever — keep it minimal.

\---

## Scope

### Player

* `CharacterBody3D`, first-person camera, mouse look.
* Move, sprint, **dash** (short i-frame burst with cooldown). No jump.
* Health bar (flat rect on HUD). Death ends the run.
* Intent component wraps all input.

### Weapon (exactly one)

* Manual trigger. Semi-auto. Hitscan (raycast) for the prototype — projectiles can come later.
* **Magazine + reserve.** Starts small (e.g. mag 6, reserve 12 — tune in `WeaponData`).
* Reload with a real duration.
* Headshot detection: separate hitbox on enemies, 2x damage, flagged in `HitInfo`.
* Miss detection: a fired shot that hits nothing counts as a miss for sponsor scoring.

### Enemies (exactly one type)

* Capsule. Runs directly at the player. Melee on contact with a short windup.
* Health, knockback on hit, dies with a pop and a kill number.
* Object-pooled. LOD as above.
* `Spawner` ramps count on a curve defined in a `SpawnWave` resource sequence. Target: \~40–60 alive on screen by minute 10 without frame drops.

### Sponsors (exactly three)

Each sponsor is a `SponsorData` resource with:

* `name`, `color`
* `trigger`: the stat it watches (enum: `HEADSHOTS`, `MULTIKILL`, `UNTOUCHED\_STREAK`)
* `threshold`: score needed to trigger a drop, escalating per drop
* `pod`: the `PodData` it drops
* `decay`: does spraying/missing/getting hit reduce standing with this sponsor?

Starting three:

|Sponsor|Watches|Drops|Punishes|
|-|-|-|-|
|**The Marksman**|headshots, hit rate|ammo|misses|
|**The Butcher**|multikills within a window|mag/reserve upgrades, fire rate|nothing|
|**The Purist**|seconds without taking damage|health, dash cooldown|taking damage|

`SponsorDirector` tracks all three, receives `HitInfo` and kill events from `Arena`, and fires `PodDropper.drop(pod, sponsor)` when a threshold is crossed. On every drop: **big text pop "THE MARKSMAN APPROVES"** in the sponsor's color, and a HUD meter per sponsor so the player can see standing rise and fall.

### Pods

* Flat-color cylinder in the sponsor's color, drops from the sky at a random valid point on the arena floor, lands with a thump and a beacon (tall thin cube).
* Walk over to collect. Applies `PodData` effect: ammo, health, `WeaponData` stat modifier.
* Pods despawn after N seconds. Scarcity is part of the pressure.

### Arena

* One flat rectangular floor with walls. Maybe two or three pillars for cover. That's it. If testing says the arena is boring, that's a finding, not a bug.

### Run structure

* Timer counts up. Run ends on death or at 15:00.
* **Run summary screen:** kills, headshot %, hit rate, sponsor standings at end, time survived.
* **Fake meta-progression:** summary shows "Marksman Reputation: 3 → 4" and a stubbed "next run: +1 starting mag" line. Persist a single int per sponsor to `user://`. This is purely to test whether the hook lands.

### Feel (this is half the work)

* Hitstop on kill (a few frames).
* Screenshake scaled by damage dealt and damage taken.
* Enemy knockback on hit, heavier on headshot.
* Floating damage numbers.
* Kill pop: enemy scales up and vanishes, or bursts into a few pooled cubes.
* Reload and empty-mag feedback must be *obvious* — the ammo economy is the test.

\---

## Suggested build order

Work in vertical slices. Each step should be playable and committed before the next.

1. Arena floor + player movement + camera + dash. Playable in 1 hour.
2. Weapon: fire, hit raycast, mag/reserve/reload, HUD ammo counter.
3. One enemy, pooled spawner, kill, ragdoll-free death pop. Ramp curve.
4. Feel pass: hitstop, shake, knockback, damage numbers.
5. `SponsorDirector` + `SponsorData` + the three sponsors + HUD standing meters + approval pops.
6. `PodDropper` + pods + collection + effects.
7. Run timer, death, summary screen, stubbed persistence.
8. Tuning pass on Resources only. Don't touch scripts unless something's broken.

Commit after each step with a message naming the step. If a step balloons past a couple of hours, stop and cut, don't gold-plate.

\---

## Out of scope (do not build)

* Multiple weapons, weapon switching, weapon pickups
* Enemy variety, ranged enemies, bosses
* Level generation, rooms, doors
* Audio of any kind
* Art, materials, palette textures, post-processing
* Main menu, settings, pause menu
* Real meta-progression (only the stub above)
* Story, NPCs, multiplayer
* Mobile/controller input (mouse + keyboard only)

\---

## Definition of done

A tester can launch the project, survive as long as they can, watch sponsors react to how they play, chase pods across the floor, die, see a summary, and want to go again. Then we sit down with the six questions above and answer each one honestly.

