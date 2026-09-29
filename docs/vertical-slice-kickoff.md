# ARENA — Vertical Slice Kickoff

**Goal:** twenty minutes of the whole game, at greybox quality, so we can judge whether the *loop* is fun and not just the fight.

The six kickoff questions are answered (see `playtest-notes.md`). This document is the next stage. It replaces "build one experiment, play it, build the next" with one continuous push toward a complete run-through. It is still a prototype: no art, no audio files, no polish beyond feel. But nothing in the loop may be missing or stubbed. If a system exists in the loop, it exists in this build.

**The one question this slice answers:** after losing a hard contract, does the player want to go back to the base and try again, or quit?

---

## The twenty minutes we are building for

This is the arc a tester should be able to play, start to finish, in one sitting:

1. Start in the base with a pistol and nothing else.
2. Book an easy contract. Win it. Earn a little cash, a little favour.
3. Book another easy one, or the mid tier. Win. Earn more.
4. Buy armour and the shotgun. Maybe a health stim for the pocket.
5. Book a hard contract with a sponsor request on it for double favour.
6. Fight it properly: shotgun for the crowd, pistol for weak points, stim when it goes wrong.
7. Win or lose. Either way, look at the sponsor board and see how far the .357 is.
8. Decide whether to go again.

If any step is impossible because a system is missing, the slice is not done.

---

## What to build, in order

Order is **AI → economy and loadout → contracts ladder → base**. AI first because the loop is not worth testing against enemies that walk in a line, and it is the biggest piece.

### 1. Enemy perception and behaviour

Not production AI. Enough that *finding* a fight and *being found* are both real, and holding a Warden zone has a cost.

**All enemies on the floor from the start** for extermination contracts (rosters spawn into the arena spread out, not at the player). Survival and scavenger still spawn over time, but spawned enemies start unaware.

**Three states per enemy, driven by `EnemyData`:**

- **Idle / patrol.** Wanders between navmesh points. Does not know where the player is.
- **Alerted.** Has a last-known position and moves to it. Gets there and finds nothing → searches nearby for a few seconds → back to idle.
- **Engaged.** Can see the player. Existing chase / windup / attack behaviour.

**Senses, all tunable in `EnemyData`:**

- Sight: range and cone, blocked by geometry (raycast). Seeing the player → engaged.
- Hearing: gunfire within a radius gives the *shooter's position* as last-known and alerts. Every shot is a noise event on `Arena`, which tells nearby enemies. Shotgun is louder than pistol (`WeaponData.noise_radius`).
- A held Warden zone is a continuous noise at the zone's position while the player is inside it.
- Engaged enemies that lose sight for N seconds drop to alerted with the last seen position.

**Type-specific behaviour, kept small:**

- Grunts: when three or more are engaged on the same target, they pick offset approach points around the player instead of the same one, so they arrive from more than one side. No formation logic; just a random angle offset per grunt when it picks its path target.
- Shooters: hold at their preferred range, and if the player closes inside half that range, back off along the navmesh to reopen it. If they cannot see the player for a few seconds, reposition to a spot with line of sight to last-known.
- Heavies: unchanged. They are fine.

**Feedback:** an enemy's state must be readable at a glance. Idle, alerted and engaged each get a distinct colour tint or a small marker above the body. Testers need to know they were heard.

**Log:** `enemy_alert` (with cause: sight, gunfire, zone), `enemy_lost`, `enemy_search`. Crumbs already list enemy state; make sure the new states appear.

### 2. Economy, loadout and consumables

Everything is persisted in `ProfileStore`. Items are Resources.

**`ItemData`** (new): name, description, price in cash, price in favour (0 if not purchasable with favour), which sponsor's favour if any, category (weapon, armour, consumable, mod), and what it does. Keep effects to a small enum, the same way `PodData` works.

**Loadout:** two weapon slots, one armour slot, one consumable slot. Set in the base, locked during the fight. A fresh profile owns the pistol only. The shotgun is no longer free.

**Starting purchases, placeholder numbers, all in `.tres`:**

| Item | Category | Costs | Does |
|-|-|-|-|
| Shotgun | weapon | cash | the existing shotgun |
| Light armour | armour | cash | flat damage reduction, no movement penalty |
| Heavy armour | armour | more cash | bigger reduction, sprint slower |
| Health stim | consumable | cash, one use | carried in the pocket; press a key mid-fight to heal over 3 s |
| Extended mag | mod | cash | permanent +mag for the pistol |
| **.357** | weapon | **favour, one sponsor, high tier** | huge damage, small mag, slow fire, weak-point one-taps everything including heavies from the front |

The .357 is the carrot. It goes on the sponsor board from the start with its price visible. The price should be reachable in roughly four fights of decent play.

**Favour rework** (agreed in the notes, now built):

- Paid at the end of a won contract only. Nothing on a loss.
- Amount per sponsor comes from that sponsor's score during the fight, scaled by the contract's `favour_multiplier`.
- Numbers must be large enough to matter: think tens per fight, not 1 to 3. Set the .357 price against what a good run pays.
- One contract on the board at any time carries a **sponsor request**: that sponsor pays double. The request rotates after each fight.
- Spending favour at a vending machine (below) costs the same currency you are saving. That is the tension. Keep it.

**Stations become vending machines:** health and ammo cost a small amount of cash or favour, chosen at the station. Free health is gone. Stock rules unchanged.

**Pods stay** but drop rates come down a lot. A pod is for a feat, not a metronome. Placeholder: roughly one pod per sponsor per fight for a good run.

**Loss rules:** consumables used are gone, cash and favour earned in the fight are gone, purchased gear stays. Cash spent stays spent.

### 3. Contract ladder

Five contracts on the board, in tiers. All `ContractData`, add `tier`, `favour_multiplier`, and `unlocked_by` (a tier the player must have won, or none).

| Tier | Name | Type | Should be winnable with | Pays |
|-|-|-|-|-|
| 1 | new, easy extermination | Extermination | starter pistol, first try | little cash, little favour |
| 1 | First Blood | Extermination | starter pistol | little |
| 2 | Warden's Errand | Scavenger | pistol + some upgrades | mid |
| 3 | Long Night | Survival | shotgun + armour | good, multiplier 2 |
| 4 | new, hard extermination | Extermination | shotgun, armour, stim, and skill | best, multiplier 3, mixed roster with several heavies |

The briefing card shows reward, favour multiplier, roster summary and any sponsor request. Booking is done in the base (below), not on the summary screen. The summary screen sends you back to the base.

Fix from the notes: survival ramps should not keep raising the floor if the kill rate has collapsed. Simplest: cap the alive count at what the tier says and let the ramp *time* stretch instead.

### 4. The base

One greybox room. The player walks in first person. No enemies, no timer, no HUD except a prompt when near a kiosk. `ESC` does nothing special.

Four pedestals, walk up and press `E` to open a plain panel; `E` or `ESC` closes it:

- **Weapon rack** — buy weapons and mods, assign the two slots.
- **Wardrobe** — armour slot, consumable slot, buy stims.
- **Agent's terminal** — the contract board. Shows the five contracts with tier, reward, roster, request flag. Pick one → briefing card → the fight.
- **Sponsor board** — each sponsor: what they want, current favour, the .357 and any tier perks with prices and how far you are. Buying happens here.

Cash and favour totals are shown on every panel. Panels are text. Formatting effort: none.

The base is its own scene. `Arena` no longer owns the flow between fights; a small `Game` scene owns `Base` and `Arena` and swaps between them. This is the one structural change in the slice, and it is worth making now rather than bolting a base into the arena scene.

---

## Hard rules, updated

- Greybox visuals, generated tones only, no menus beyond the panels above. Unchanged.
- Everything tunable in a `.tres`. Prices, favour payouts, sense ranges, ladder. Unchanged.
- Perception AI must be tunable to "everyone knows where you are" by setting sight range huge, so the old behaviour is one resource edit away for comparison.
- The run log keeps working across the base. Add `base_enter`, `purchase`, `contract_booked`, `stim_used`.
- No polish that isn't feel. Kiosk panels are ugly on purpose.
- House code conventions as in `CLAUDE.md`. Ownership spine: `Game` → `Base` / `Arena`.

---

## Out of scope for the slice

- Art, materials, animations, audio files.
- More than five contracts, more than two new items beyond the table.
- An agent NPC to talk to. The terminal is a panel.
- Trophies, research, arena unlocks, a second arena.
- Multiplayer, story, settings, controller.
- Balance beyond "the twenty-minute arc is playable as described." Placeholder numbers are fine; the arc has to be reachable.

---

## Definition of done

A tester starts fresh, plays roughly twenty minutes, buys the shotgun and armour with cash from easy contracts, carries a stim into a hard one, fights enemies that had to find them, wins or loses, and stands in front of the sponsor board looking at the .357's price.

Then answer the one question: did they want to go again?

Second question, for the notes: which half needs work next, the fight or the loop?

Get at least two people who are not the developer through the arc before answering either.
