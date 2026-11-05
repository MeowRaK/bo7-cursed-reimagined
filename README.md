![Cursed Reimagined Preview](previewmod.png)

# BO7 Zombies | Cursed Reimagined

A classic-inspired gameplay overhaul for **Call of Duty: Black Ops 7 Zombies**, designed for the **Kronos offline client**.

Cursed Reimagined brings back elements of classic Zombies while preserving BO7's modern gameplay systems. It reworks weapon progression, Pack-a-Punch, armor, perks, melee combat, Wonder Weapons, and Field Upgrades to deliver a more traditional Zombies experience.

## Supported Game Modes

- **Cursed**
- **Cursed Survival**
- **Mister Peeks Mayhem**

The mod is designed specifically for these three modes and does not intentionally modify Standard Zombies or Directed Mode.

---

## Features

### 1. Combined Pack-a-Punch & Weapon Rarity

Weapon rarity increases automatically when using Pack-a-Punch, removing the need to upgrade rarity separately through the Arsenal.

| Weapon State | Rarity | Pack-a-Punch Cost |
| --- | --- | --- |
| Starting 1911 | White / Common | — |
| Wall-Buy & Mystery Box Weapons | Green / Uncommon | — |
| Pack-a-Punch I | Blue / Rare | 5,000 |
| Pack-a-Punch II | Purple / Epic | 20,000 |
| Pack-a-Punch III | Gold / Legendary | 35,000 |
| Pack-a-Punch IV | Red / Ultra | 50,000 |

Rarity upgrades are included with each Pack-a-Punch purchase at no additional Salvage cost.

### 2. Mystery Box Overhaul

The Mystery Box has been adjusted to provide more consistent weapon progression.

- Regular weapons always appear at **Green / Uncommon rarity**, regardless of the round.
- Blue, Purple, and Gold regular weapon rolls are disabled.
- Aether Tools are removed from the loot pool.
- Ultra Legacy Weapons remain available through their separate loot system.
- **Mystery Box Zombie Builds:** Meleeing the Mystery Box allows the weapon to retain the saved Zombie Build attachments of the player who meleed it, even if another player purchases the weapon.

### 3. Wall-Buy Changes

- All regular wall-buy weapons remain **Green / Uncommon rarity**.
- Weapon rarity no longer increases as rounds progress.
- **Classic White Chalk Outlines:** Wall-buy weapon outlines remain white regardless of weapon rarity, recreating the classic Zombies appearance.
- Purchased weapons can still be upgraded through Pack-a-Punch.

### 4. Arsenal Rework

The Arsenal has been repurposed to provide Ammo Mods instead of weapon rarity upgrades.

- **Random Ammo Mod:** 250 Salvage.
- Each successful purchase applies a randomly selected compatible Ammo Mod.
- Existing Ammo Mods can be replaced through another purchase.
- Manual weapon rarity upgrades are disabled.
- Custom Arsenal interaction prompts are provided through the included Lua script.
- Wonder Weapons are excluded from the custom Ammo Mod purchase system.

### 5. Classic Armor Progression

Players begin each match **without armor** and must purchase armor upgrades from wall-buy locations.

| Armor Tier | Cost |
| --- | --- |
| Tier I | 2,500 |
| Tier II | 4,000 |
| Tier III | 10,000 |
| Golden Armor | 25,000 |

Armor upgrades must be purchased progressively.

### 6. Classic Perks & Wunderfizz

The package includes a separately maintained Classic Perks script that restores BO3-inspired perk pricing, with adjustments for newer perks.

| Perk | Cost |
| --- | --- |
| Juggernog | 2,500 |
| Quick Revive | 1,500 |
| Speed Cola | 3,000 |
| Stamin-Up | 2,000 |
| Deadshot Daiquiri | 1,500 |
| Death Perception | 1,500 |
| PHD Flopper | 2,000 |
| Vulture Aid | 3,000 |
| Elemental Pop | 2,500 |
| Melee Macchiato | 1,500 |
| Wisp Tea | 2,000 |

Additional perks use the prices defined in the included Classic Perks script.

**Wunderfizz:**

- Random perk for **2,500 Essence**.
- After obtaining all available perks, players can purchase **Eternal Perks for 7,500 Essence**.

### 7. Personalized Starting Weapons

Players spawn with their own saved Zombie Builds for:

- **1911 Pistol**
- **Starting Knife**

Configured blueprints, attachments where supported, and cosmetics are preserved.

For example, players can equip the **"The Classic" 1911 blueprint** by assigning it as their saved 1911 Zombie Build.

### 8. Classic 1911 Damage

The unupgraded White/Common 1911 has been adjusted to recreate the classic BO1 starting pistol strategy.

On round 1, players can use **8 leg shots followed by a knife kill** to maximize points.

This adjustment applies only to the starting 1911 and does not affect other weapons.

### 9. Classic Starting Knife Damage

The unupgraded **White/Common Knife** has been adjusted to recreate classic BO1–BO3 Zombies melee damage progression.

- **Round 1:** 1 hit to kill.
- **Round 2:** 2 hits to kill.
- **Rounds 3–4:** 3 hits to kill.
- **Round 5 onward:** Damage follows the classic Zombies knife progression.
- **No Headshot Bonus:** Knife attacks deal equal damage regardless of hit location.
- **Equal Attack Damage:** Primary (left-click) and alternative (right-click) attacks deal identical damage.
- Changes apply exclusively to the **White/Common Knife**. Upgraded rarities and Pack-a-Punched knives retain their normal damage.

### 10. Infinite Wonder Weapon Damage

Map-specific Wonder Weapons deal **effectively infinite damage against normal zombies when upgraded to Pack-a-Punch III**.

- **Pack-a-Punch III is required** to activate infinite damage.
- Normal zombies can be eliminated in a single successful damaging hit, regardless of the round.
- The effect remains active at extremely high rounds.
- Original weapon effects, animations, and ammunition consumption are preserved.
- Bosses, Elite enemies, and Special enemies retain their normal damage interactions.
- **Ray Gun and Ray Gun Mark II are excluded** and retain their original damage behavior.

This ensures fully upgraded map-specific Wonder Weapons remain effective throughout high-round gameplay.

### 11. No Starting GobbleGums

Players begin with **0 preloaded GobbleGums** instead of the usual 3.

GobbleGums can still be acquired and used normally during the match.

### 12. Classic Knife System

The classic knife system is enabled through Melee Macchiato's **Mocha Maul** functionality.

- The dedicated melee weapon can be used through the melee button.
- Mocha Maul behavior is enabled automatically.
- Players can select other Melee Macchiato augments without giving up the classic knife functionality.
- The system works independently of whether Melee Macchiato has been purchased, subject to the game's weapon exclusions.

### 13. Field Upgrade Recharging

Field Upgrades use a fixed recharge requirement instead of becoming more expensive after repeated activations.

- **40 kills** are required for the standard recharge.
- The required kill count does not increase after each use.

### 14. Zombie Damage Scaling

Custom zombie attack damage scaling has been disabled.

- The standard version no longer applies custom zombie attack damage values.
- The BO3 Health-compatible version leaves damage handling to BO3 Health.
- Zombie health progression, movement speed, and spawning remain unchanged by this adjustment.

---

## BO3 Health Compatibility

A separate version of Cursed Reimagined is available for players using the **BO3 Health mod**.

This version includes the same core gameplay features as the standard mod, with adjustments to armor and other systems to ensure compatibility with BO3 Health.

- Adjusted armor functionality to prevent conflicts.
- Compatible with BO3 Health's player health and Juggernog systems.
- Custom zombie damage scaling is disabled to preserve BO3 Health's damage mechanics.
- Retains the classic gameplay modifications wherever compatible.

**Download:**

[BO7 Cursed Reimagined — BO3 Health Version](https://github.com/MeowRaK/bo7-cursed-reimagined-bo3-health)

**Installation:** Use `zm_cursed_reimagined_bo3c.gsc` alongside `bo3_health.gsc` instead of the standard `zm_cursed_reimagined.gsc`.

---

## Credits

- **MeowRaK** — Cursed Reimagined mod development and gameplay modifications.
- **Classic Perks Mod:** Created by **aspect.of.autumn** (Discord: `@aspect.of.autumn`), including classic perk pricing and Wunderfizz functionality.
