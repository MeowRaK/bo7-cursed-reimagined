// =====================================================================
// zm_relic_rebalance.gsc  v8.3  -  BO7 Zombies (Kronos)
// (formerly zm_golden_spork_rework.gsc - delete the old file)
// =====================================================================
//
// Relic Rebalance.
//
// GOLDEN SPORK: points 1-4 below only happen while the Golden Spork is
// active; without it they are untouched.
//
// ROUND DAMAGE SCALING (point 5): applies in every match, relic or not.
//
//  1. ENEMY DAMAGE: +50% instead of +100% (x1.5 instead of x2).
//     Only normal zombies, armored zombies, hellhounds and the other common
//     zombie types get the +50%. Specials, elites, HVTs and every boss
//     (Veytharion, Caltheris, The Dark Heart, Dravakar, the Warden, Nyxara,
//     the Guardian, Z-Rex) hit you for normal damage.
//
//  2. HEALTH: without Juggernog your max health is 100 (stock 150).
//     Juggernog stays at 250, and 300 with the Probiotic augment
//     (stock values: the game sets those from the match base, not from
//     your current health, so the 100 does not lower them).
//
//  3. ARMORED ZOMBIES (v2.5): they spawn as normal again and hit your
//     health exactly as hard as a normal zombie (50 -> 75 with the relic for
//     both). Stock armored zombies hit harder than normal ones (base melee
//     35 vs 30, steeper round tables), so their health damage is brought
//     down to what a normal zombie deals at the same round. Their damage to
//     your ARMOR stays stock armored (harder than normal zombies) and is
//     +50% on top (level.gsr_armored_armor_wear_mult).
//     Covers light, heavy and agni armored zombies, Nyxara's included.
//     (The v2.0 spawn block is still in the file, switched off:
//     level.gsr_block_armored_spawns = 1 turns it back on.)
//
//  4. ARMOR:
//     - Durability: your armor wears down as if the relic were not there
//       (except armored zombies' hits, point 3)
//       (the +50% does not chew through plates faster, and the mitigation
//       nerf below does not either).
//     - Mitigation nerf: armor blocks less of each hit. Tuned to your
//       example: a 50 damage hit becomes 75 with the Golden Spork, and with
//       full armor + Hardened Plates + Durable Plates you take 35.
//       (Stock with the relic would be about 26.)
//
//  5. ROUND DAMAGE SCALING: zombie damage keeps its stock round steps up to
//     round 51. After that the steps come half as often: the step the game
//     gives at round 61 comes at 71, round 71's at 91, and so on (every 20
//     rounds instead of every 10). Only damage changes; how many zombies can
//     attack you at once still follows the real round.
//     With Cursed Reimagined running, CR's own damage tiers are kept for
//     everything EXCEPT bosses: bosses always get this mod's scaling
//     (level.rr_scaling_cr_priority).
//
// LAWYER'S PEN (v2.7, level.rr_lawyers_pen):
//  - Killed zombies only leave Mimic props behind every other round (odd
//    rounds by default: 1, 3, 5...). On the other rounds none drop.
//  - When a round ends, every Mimic prop the relic left on the map
//    disappears (a Mimic that already jumped out keeps fighting).
//  How the game does it (zombie_mode_modifiers.gsc): with the relic on,
//  each zombie kill has a 10% chance (mimic_spawn_chance) to spawn a
//  disguised Mimic prop, max 5 at once, each cleaned up after 20 s. The
//  props are tagged from_zmmodifier_prop and listed in
//  level.mimic_trap_props / level.spawned_mimic_props
//  (zombie_mimic_prop_spawn.gsc), and removed with its clean_up_prop.
//
// DRAGON WINGS (v2.8, level.rr_dragon_wings):
//  Stock Dragon Wings turns power-ups off. Reworked:
//  - Exactly 1 power-up per round. It can drop from a kill as usual; if
//    none has dropped by the time the round's last zombie dies, it drops
//    there instead.
//  - Max ammo rounds (rounds that end with the max ammo reward): only that
//    max ammo at the end, no other power-up that round.
//  - Cycle: a power-up cannot drop again until every power-up has dropped
//    once. The end-of-round max ammo does not count; max ammo still has
//    to come up in the cycle on its own turn. A power-up that cannot drop
//    right now (e.g. Fire Sale while the box is not usable) keeps its place
//    and comes up later in the same cycle instead of being skipped.
//  How the game does it (zm_powerups.gsc, powerups.gsc): the relic sets
//  zmmodedisablepowerups, which blocks kill drops and the round-end reward.
//  Kill drops are capped by powerup var "powerup_drop_max_per_round" and
//  picked by get_next_powerup(), which takes level.var_1972d2e9730827d4
//  first if set. Rounds with a round-end power-up reward turn kill drops off
//  until that reward drops.
//
// ROCKET (v2.9, level.rr_rocket) - the "no scorestreaks" relic:
//  - Scorestreaks are back in the loot pool: zombie drops, T.E.D.D. task
//    reward chests, O.S.C.A.R.'s Golden Death Machine on Astra Malorum, any
//    other drop list. The scorestreak HUD is shown again.
//  - The crafting table still refuses scorestreaks, EXCEPT Totenreich's own
//    two: the Glocke (zm_bernard_primary) and the Wunderbarrage
//    (zm_bernard_secondary). They still need whatever the map normally
//    needs before they show up there.
//  - Kowakujo's Remote Robot ("Rhino", 1750 salvage at its interact) is
//    given straight to the player, not through the loot pool or the
//    crafting table, so the relic never blocked buying it; it only hid the
//    scorestreak HUD, which is back on.
//  How the game does it (zombie_mode_modifiers.gsc, relic on):
//    ui_show_killstreaks = 0; item type "killstreak" banned (checked by the
//    crafting table through level.var_71b6079fc23545cd); an item-spawn
//    callback (hash_8e2728470d1fa87a) rejects scorestreaks from drop lists;
//    and an item-spawned callback deletes any scorestreak that appears in the
//    world unless it is a quest item or a player dropped it.
//
// POWER SWITCH (v3.0, level.rr_power_switch):
//  At the end of every round your lethal and tactical still switch, but only
//  to a DIFFERENT item of the SAME rarity:
//    Tactical rarity 3: Kazimir <-> Monkey Bomb <-> Psych (gas) Grenade
//    Tactical rarity 2: Concussion, Stim, Decoy, Shock Charge
//    Lethal (all rarity 2): Frag, Semtex, C4, Molotov, Combat Axe, Cluster,
//                           Thermobaric, Impact, Mini Sentry
//  Items the relic never touched (Grapple Hook, Europa remote, trinkets...)
//  are still left alone, an empty slot stays empty, and ammo carries over
//  capped at the new item's max, like stock.
//  How the game does it (zombie_mode_modifiers.gsc): with the relic on
//  (var_d3644cfcd25048c2), every round end gives each player a random item
//  from a lethal list and a tactical list (any rarity). Rarities from the
//  item spawn entries (itemspawnentry #rarity).
//
// GRAMOPHONE (v3.1, level.rr_gramophone) - the "extra bullet cost" relic:
//  - Every weapon you fire costs the extra ammo, not just bullet guns:
//    launchers, projectile guns, wonder weapons (the Astra Malorum wonder
//    weapon included, which stock skipped), scorestreak guns.
//  - All damage you deal is doubled (stock +25%), every weapon type.
//  How the game does it (zombie_mode_modifiers.gsc): set_extra_bullet_cost
//  takes 1 extra round per "player_fired_shot" (add_extra_bullet) and adds a
//  player damage modifier "extra_bullet_cost" (+extradamage, 0.25), both
//  skipping sat_ww_ruby_zm. This mod charges on "weapon_fired" instead
//  (every weapon) and replaces the damage modifier with x2.
//
// VRILL SPHERE (v3.2, level.rr_vrill_sphere) - the "4 Perk-a-Colas" relic:
//  - Only perks BOUGHT at a perk machine count toward the 4-perk limit.
//  - Perk cans (loot item perks) and the Free Perk power-up (and any other
//    perk you get without buying it) never count: they stack on top, so
//    you can go past 4, and they are never the perk that gets taken.
//  - Buying a 5th machine perk still drops your oldest machine perk.
//  How the game does it (zombie_mode_modifiers.gsc function_de2be231627b8af,
//  shared func zm_mode_modifiers/hash_6843c64da905f4f8, called from
//  zombie_perks::give_perk): every perk goes into a list; past the limit the
//  oldest one in that list is taken. Perk cans counted; free perks only
//  skipped the list once you were already at 4.
//
// STUFFED ELEPHANT (v3.3, level.rr_stuffed_elephant) - longer regen delay:
//  - Health regen now starts 3 seconds after damage instead of ~6.
//  How the game does it (zombie_mode_modifiers.gsc set_delay_health_regen,
//  playerhealth.gsc): the relic adds a regen-delay modifier of -3.333
//  ("regen_delay_relics"); the delay is base x (1 - modifiers), so about
//  4.3x the match's base delay. This mod swaps that modifier for one that
//  gives level.rr_elephant_delay_seconds total, worked out from the match's
//  own base delay. Other regen buffs / debuffs still stack on top as usual.
//
// VALKYRIE HELMET (v3.4, level.rr_valkyrie_helmet) - electric fields:
//  - At most 2 electric fields spawn per round (all players together).
//    Once a round's 2 have spawned, staying still is safe until the next
//    round. Fields already on the ground keep working as normal.
//  How the game does it (zombie_mode_modifiers.gsc thread_electric_fields):
//  every 20 s, each player still within 300 units of where they were 20 s
//  earlier (player.prev_electric_field_loc) gets a field; a 5 s warning
//  (electric_field_warning + screen fx) runs before each check. No cap.
//  This mod lets only as many players qualify as there are slots left
//  this round; the others count as having moved (no field, no warning fx).
//
// FILM REEL (v3.5, level.rr_film_reel) - "only one Pack-a-Punch weapon":
//  - You can Pack-a-Punch every weapon again, but only ONE can be at the
//    max PaP level; every other weapon tops out one level below.
//      PaP 4 unlocked (Mr. Peeks mayhem or relic Tier 3): one weapon PaP 4,
//        the rest up to PaP 3.
//      Otherwise: one weapon PaP 3, the rest up to PaP 2.
//  - If a second weapon reaches the max (packed, picked up...), your OTHER
//    max weapon is knocked down one level (it is not dropped).
//  How the game does it (zombie_mode_modifiers.gsc, relic flag
//  var_63da2ef147f344a4): any second weapon with ANY PaP level gets
//  dropped. Max level = level.max_pack_a_punch_level (3, or 4 from relic
//  Tier 3 in zm_relics.gsc / the PaP-level increase in pack_a_punch.gsc).
//  This mod switches the stock rule off (its own disable function) and
//  re-packs the extra max weapon one level lower with pack_a_punch's
//  pap_weapon (target level override).
//
// BLOOD VIALS (v3.6, level.rr_blood_vials) - stock: "All Augments off":
//  - Instead of turning augments off, each player's augments are shuffled
//    once when they load into the match: every perk / ammo mod / field
//    upgrade gets a random major and a random minor augment (a different
//    one from your loadout when there is a choice).
//  - Only the in-match augments change. The augment setup saved in your
//    menu / loadout is never touched; next match you start from it again.
//  - Bonus augment slots are left as they are.
//  How the game does it (zombie_mode_modifiers.gsc set_no_augments,
//  zombie_augments.gsc): the relic flag zmmodenoaugments makes every spawn
//  wipe the in-match augment slots (take_all_player_augments), plus a 30 s
//  loop that keeps wiping them. Slots live in player.zombie_augments[type]
//  (majorname / minorname), filled from the loadout on connect; augments
//  are given with give_player_augment.
//
// CIVIL PROTECTOR HEAD (v3.7, level.rr_civil_protector) - perk decay:
//  - You lose a perk every 350 kills instead of every 100 (still your
//    oldest perk, Quick Revive skipped when it is first, like stock).
//  How the game does it (zombie_mode_modifiers.gsc): each kill adds 1 to a
//  per-player counter and compares it with the relic setting
//  level.zm_relic_modifiers[ hash_3385fa4802fa103e ].var_c7936ba2a928b771
//  (bundle value 100), read fresh on every kill. This mod sets it to 350.
//
// MANGLER HELMET (v3.8, level.rr_mangler_helmet) - "No Arsenal":
//  - The Arsenal stays off (stock). Added to the loot pool:
//      Ultra aether tool  (sat_aethertool5,    zmloot_aether_tool_5)
//      PaP 4 aether crystal (sat_aethercrystal4, zmloot_aether_crystal_4)
//    Before round 40 every Legendary (gold) aether tool that spawns has a
//    level.rr_mh_upgrade_chance % chance to be the Ultra one instead, and
//    every PaP 3 crystal the same chance to be the PaP 4 one.
//  - From round 40 they fully replace them: no more Legendary tools or
//    PaP 3 crystals, always Ultra tools / PaP 4 crystals.
//  - Cursed Reimagined: if its "no Aether Tools" rule is running, this mod
//    never creates an aether tool (and CR blocks every tool tier anyway,
//    the Ultra one included). Crystals still get the PaP 4 upgrade.
//  Notes from the dump (common_item_upgrade.gsc): the Ultra tool works on
//  any weapon below Ultra. The PaP 4 crystal works on any weapon below
//  PaP 3 (it jumps it straight to PaP 4); a PaP 3 weapon can only take it
//  once PaP 4 is unlocked (can_pap checks the max PaP level).
//
// AGARTHAN DEVICE (v3.9, level.rr_agarthan) - elemental zombie rounds:
//  - Odd rounds (1, 3, 5...) have normal zombies. Even rounds (2, 4, 6...)
//    swap the normal zombies for one random elemental type (Luna or Toxic;
//    the armored Agni type is left out, see below).
//  - Those elemental zombies never super sprint: when the round would make
//    them super sprint they sprint instead (they can still walk / run /
//    sprint as the round decides).
//  - On the elemental rounds armored zombies do not spawn: light, heavy and
//    Agni armored zombies from the spawn lists become that round's
//    elemental type instead. Bosses' own summons are not touched.
//  How the game does it (zombie_mode_modifiers.gsc): every round start the
//  relic picks one of [default, Luna, Toxic, armored Agni] at random and
//  swaps "zombie_base" for it (zm_round_spawning aitypeoverridemap). Speed
//  is a priority list per zombie (zombie_utils function_a8ce00e0448cb6f0);
//  the highest priority request wins.
//
// MUSIC BOX (v4.0, level.rr_music_box) - "Enemies only take critical damage":
//  - Every wonder weapon ignores the relic (full damage, any hit). Stock only
//    let map wonder weapons and two named ones through.
//  - Critical kills give double points (100 -> 200; the Double Points
//    power-up still doubles on top).
//  How the game does it (zombie_mode_modifiers.gsc set_only_critical_damage):
//  a player damage modifier "only_critical_dmg" zeroes any non-critical hit
//  unless the weapon is a map wonder weapon / listed. Points go through
//  points.gsc zm_modify_points, which calls shared func
//  zombie/hash_f2c6034e2393f380( eventinfo, points ) if one is registered.
//
//  MENU TEXT: the Golden Spork's description in the relic menu is changed by
//  the companion file relic_rebalance_post.lua (install it with this one).
//
// Standalone. Works in vanilla Cursed and alongside Cursed Reimagined.
//
// HOW THE GAME DOES IT (verified in the BO7 script dump)
//  - Relic effect sets val "zombie_damage_to_player_multiplier" = 2, stored
//    in level.var_3f27e31a208b760f; zm_player_damage.gsc multiplies AI hits
//    by it, then calls attacker.ai_attack_damage_override.
//  - perk_juggernaut.gsc: Jug health = matchrules maxHealth (150) + 100;
//    Probiotic (juggernog_juggernaut) adds +50.
//  - zm_armor.gsc: mitigation 0.45 / 0.58 / 0.65 by armor level, Hardened
//    Plates (juggernog_thicker_plates) +0.05; Durable Plates
//    (juggernog_well_constructed) -20% armor wear. Per-player hooks
//    self.callback_armor_damage_override and
//    self.callback_armor_post_damage_override are used by this mod.
//  - zm_round_spawning.gsc: aitypeoverridemap swaps a spawn-list subclass
//    for another one in normal rounds.
//
// v1.1: Veytharion lasers / missiles verified.
// v1.2: Nyxara verified (fan fire, tornado, projectile; her beam was never
//       doubled because the game credits it to the player).
// v2.0: x1.5, 100 health without Jug, no armored zombies outside boss
//       fights, armor wear as without the relic, armor mitigation nerf.
// v2.1: renamed to Relic Rebalance; round damage scaling slowed after 51;
//       relic menu description (Lua add-on).
// v2.2: scaling hook installs once (no loop with Cursed Reimagined's own
//       wrapper of the same function); skipped when CR is running.
// v2.3: bosses get this mod's round scaling even with CR running.
// v2.4: armored zombies spawn again; no health bonus, +50% armor wear.
// v2.5: armored zombies get the +50% like normal zombies and their health
//       damage matches a normal zombie's; armor damage stays higher.
// v5.0: Crash diagnostics: every part counts its runs; summary in dvar
//       rr_diag each second (shown by the Lua file in a match).
// v4.9: On/off switches for the Golden Spork rework and the round damage
//       scaling change (crash hunt).
// v4.8: Compile fix: removed the hash-named engine call added in v4.7;
//       Agarthan uses the type the stock relic picked each round.
// v4.7: Agarthan Device: elemental types taken from the relic's own list for
//       the map (no hard-coded types).
// v4.6: Dragon Wings: max ammo rounds drop nothing from kills (only the
//       round's max ammo), bonus drops respect the 1-per-round cap, drops
//       from other things don't change the cycle order, final encounters
//       (a boss alive) drop power-ups like normal. Power Switch: new item's
//       count capped by its real max. Mr Peeks test now off by default.
// v4.5: Music Box: critical-kill bonus paid through the game's own kill
//       points function (shows a +100 popup, Double Points applies).
// v4.4: Rocket: scorestreaks hidden in the crafting table again (the HUD
//       switch also controls that list; it's now off near crafting tables).
// v4.3: Music Box: critical-kill bonus now given on the zombie's death
//       (the old points hook was never called for kills).
// v4.2: Load fix: replaced the !== operator, which this game's compiler
//       likely rejects (it would make the whole file get skipped).
// v4.1: Menu text fix (Lua now hooks the text elements themselves) and a
//       pause-menu list of the reworked relics that are active (dvar
//       rr_relics). TEST setting: Mr Peeks spawns every round.
// v4.0: Music Box: all wonder weapons ignore it, critical kills x2 points.
// v3.9: Agarthan Device: elemental zombies every other round, no super
//       sprint for them, no armored zombies on those rounds.
// v3.8: Mangler Helmet: Ultra tools / PaP 4 crystals in the loot pool,
//       replacing Legendary tools / PaP 3 crystals from round 40.
// v3.7: Civil Protector Head: lose a perk every 350 kills (stock 100).
// v3.6: Blood Vials: augments shuffled once in-match instead of removed.
// v3.5: Film Reel: one max-PaP weapon, the rest one level below.
// v3.4: Valkyrie Helmet: max electric fields per round (v6.1: 1).
// v3.3: Stuffed Elephant: regen delay 3 s instead of ~6.
// v3.2: Vrill Sphere: perk cans and Free Perks stack past the 4 limit.
// v3.1: Gramophone: extra ammo cost on every weapon, double damage.
// v3.0: Power Switch: equipment only switches within its own rarity.
// v2.9: Rocket: scorestreaks back in the loot pool, crafting only for
//       Totenreich's Glocke / Wunderbarrage, Rhino HUD back.
// v2.8: Dragon Wings: 1 power-up per round, max ammo rounds only give the
//       end max ammo, every power-up once before any repeats.
// v2.7: Lawyer's Pen: Mimic props every other round, cleared at round end.
// v2.6: 100 max health without Jug fixed (no longer needs the max health to
//       equal the match-rules value); health debug line.
//  - damage_scaling_round.gsc: shared func zombie/hash_e27e55920dabe660
//    sets each zombie's melee/ranged/leap/armor damage multipliers from
//    step tables (startround -> multiplier). This mod wraps it and feeds
//    it a slower round number past 51.
//
// DEBUG: level.gsr_debug = 1 prints, once per enemy type, whether it gets
// the +50% or not, plus a line when armored spawns are blocked / allowed.
// =====================================================================

#using scripts\common\callbacks;
#using scripts\common\system;
#using scripts\common\utility;
#using scripts\mp\zm\zm_utility;
#using scripts\mp\loot\common_item;
#using scripts\mp\equipment;
#using scripts\common\values;
#using scripts\mp\playerhealth;
#using scripts\mp\armor;
#using scripts\mp\zm\systems\zm_armor;
#using scripts\common\ai\aitypes\shared\zombie\zombie_utils;
#using scripts\common\weapon;
#using scripts\mp\zm\points;
#using scripts\mp\zm\systems\zombie_mode_modifiers;

#namespace zm_relic_rebalance;

function private autoexec __init__system__()
{
    system::register( #"zm_relic_rebalance", undefined, &init, undefined );
}

function init()
{
    // ---------------- SETTINGS ----------------
    // Enemy categories that do NOT get the Golden Spork's damage bonus.
    level.gsr_exempt_categories = [];
    level.gsr_exempt_categories[ "special" ] = 1;
    level.gsr_exempt_categories[ "elite" ] = 1;
    level.gsr_exempt_categories[ "hvt" ] = 1;
    level.gsr_exempt_categories[ "boss" ] = 1;

    // Lower-case name parts that ALWAYS get the damage bonus, whatever
    // their category (hellhounds may be tagged "special" by the game).
    level.gsr_always_doubled = [];
    level.gsr_always_doubled[ level.gsr_always_doubled.size ] = "hellhound";
    level.gsr_always_doubled[ level.gsr_always_doubled.size ] = "dog";

    // Lower-case name parts that NEVER get the damage bonus, whatever their
    // category (add an enemy here if debug shows it as "normal").
    // v1.1: every boss by its internal name (from the dump's boss health bar
    // and AI type files), as a backup to the "boss" category check.
    level.gsr_never_doubled = [];
    level.gsr_never_doubled[ level.gsr_never_doubled.size ] = "caltheris";
    level.gsr_never_doubled[ level.gsr_never_doubled.size ] = "hermes";    // Veytharion
    level.gsr_never_doubled[ level.gsr_never_doubled.size ] = "neptune";   // Caltheris / Ascendant / the Needle
    level.gsr_never_doubled[ level.gsr_never_doubled.size ] = "uranus";    // Caltheris
    level.gsr_never_doubled[ level.gsr_never_doubled.size ] = "aeon";      // The Dark Heart
    level.gsr_never_doubled[ level.gsr_never_doubled.size ] = "virgil";    // Dravakar
    level.gsr_never_doubled[ level.gsr_never_doubled.size ] = "weyward";   // Warden (and its stingers)
    level.gsr_never_doubled[ level.gsr_never_doubled.size ] = "diana";     // Nyxara (hornet boss)
    level.gsr_never_doubled[ level.gsr_never_doubled.size ] = "triton";    // The Guardian
    level.gsr_never_doubled[ level.gsr_never_doubled.size ] = "phobos";    // Z-Rex

    // 1 = zombies summoned by a boss (Nyxara's armored agni zombies) keep the
    // +50% like normal armored zombies. 0 = they deal normal damage.
    level.gsr_boss_summons_doubled = 1;

    // v2.0 ------------------------------------
    // Enemy damage multiplier with the Golden Spork (stock 2 = +100%).
    level.gsr_enemy_damage_mult = 1.5;

    // Max health without Juggernog while the Golden Spork is on (stock 150).
    level.gsr_base_health_no_jug = 100;

    // 1 = no armored zombies in normal rounds (they can spawn while a boss
    // is alive). 0 = stock spawning. v2.4: off.
    level.gsr_block_armored_spawns = 0;

    // v2.4: armored zombies deal normal damage to your health, and wear
    // your armor down this much faster (1.5 = +50%, 1 = stock).
    level.gsr_armored_armor_wear_mult = 1.5;
    level.gsr_armored_names = [];
    level.gsr_armored_names[ level.gsr_armored_names.size ] = "armored";
    // v2.5: 1 = armored zombies hit your health exactly as hard as a normal
    // zombie of the same round. 0 = their stock (harder) hits.
    level.gsr_armored_match_normal = 1;
    // Subclass used as the "normal zombie" reference.
    level.gsr_normal_ref_subclass = "zombie_base";
    level.gsr_armored_subclasses = [];
    level.gsr_armored_subclasses[ level.gsr_armored_subclasses.size ] = "zombie_base_armored_light";
    level.gsr_armored_subclasses[ level.gsr_armored_subclasses.size ] = "zombie_base_armored_heavy";
    level.gsr_armored_subclasses[ level.gsr_armored_subclasses.size ] = "zombie_base_armored_agni";
    level.gsr_armored_replacement = "zombie_base";

    // Armor mitigation is multiplied by this (1 = stock). 0.762 gives your
    // example: 50 -> 75 with the relic -> 35 taken with top armor level +
    // Hardened Plates (0.65 + 0.05 = 0.70 stock -> 0.533).
    level.gsr_armor_mitigation_scale = 0.762;

    // 1 = armor wears as if the relic were not there (no extra wear from
    // the +50% or from the mitigation nerf). 0 = no change to wear.
    level.gsr_armor_wear_as_no_relic = 1;

    // v2.1 ------------------------------------
    // Round damage scaling: stock up to this round, slower after it.
    level.rr_scaling_slow_from_round = 51;
    // 2 = steps come every 20 rounds instead of 10. 1 = stock.
    level.rr_scaling_slowdown = 2;
    // 1 = only slow the scaling while the Golden Spork is on. 0 = always.
    level.rr_scaling_spork_only = 0;
    // 1 = when Cursed Reimagined is running, do not touch round scaling at
    // all (its own damage tiers stay exactly as it made them). 0 = slow down
    // whatever scaling Cursed Reimagined leaves on (specials / elites /
    // bosses after 51, and normal zombies' armor damage up to its round-61
    // cap, which would then be reached at round 71).
    level.rr_scaling_skip_cursed_reimagined = 1;
    // v2.3: enemy categories that ALWAYS get this mod's round scaling, even
    // with Cursed Reimagined running (the mod's change wins over CR's for
    // them). Add "elite" / "special" here to include those too.
    level.rr_scaling_cr_priority = [];
    level.rr_scaling_cr_priority[ level.rr_scaling_cr_priority.size ] = "boss";

    // v2.7 LAWYER'S PEN ----------------------
    // 1 = rework on. 0 = stock Lawyer's Pen.
    level.rr_lawyers_pen = 1;
    // 1 = Mimic props drop on odd rounds (1, 3, 5...). 0 = even rounds.
    level.rr_pen_odd_rounds = 1;
    // 1 = clear the relic's Mimic props when a round ends.
    level.rr_pen_clear_on_round_end = 1;

    // v2.8 DRAGON WINGS ----------------------
    // 1 = rework on. 0 = stock Dragon Wings (no power-ups).
    level.rr_dragon_wings = 1;
    // 1 = if no power-up dropped during the round, the round's last zombie
    // drops one. 0 = at most 1 per round, but a round can have none.
    level.rr_wings_guarantee = 0;   // v7.4: no guaranteed last-zombie drop

    // v2.9 ROCKET (no scorestreaks relic) -----
    // 1 = rework on. 0 = stock Rocket.
    level.rr_rocket = 1;
    // Scorestreaks the crafting table may still make with the relic on.
    level.rr_rocket_craft_ok = [];
    level.rr_rocket_craft_ok[ level.rr_rocket_craft_ok.size ] = "zm_bernard_primary";     // Totenreich: Glocke
    level.rr_rocket_craft_ok[ level.rr_rocket_craft_ok.size ] = "zm_bernard_secondary";   // Totenreich: Wunderbarrage
    // The scorestreak HUD is hidden while a player is this close to a
    // crafting table (that same switch hides scorestreaks in its list).
    level.rr_rocket_craft_radius = 250;

    // v3.0 POWER SWITCH ----------------------
    // 1 = rework on. 0 = stock Power Switch.
    level.rr_power_switch = 1;
    // Pools: ref, rarity. Rarities from the game's item spawn entries.
    level.rr_ps_lethals = [];
    level.rr_ps_lethals[ level.rr_ps_lethals.size ] = rr_ps_item( "equip_frag", 2 );
    level.rr_ps_lethals[ level.rr_ps_lethals.size ] = rr_ps_item( "equip_semtex", 2 );
    level.rr_ps_lethals[ level.rr_ps_lethals.size ] = rr_ps_item( "equip_c4", 2 );
    level.rr_ps_lethals[ level.rr_ps_lethals.size ] = rr_ps_item( "equip_molotov", 2 );
    level.rr_ps_lethals[ level.rr_ps_lethals.size ] = rr_ps_item( "equip_combataxe", 2 );
    level.rr_ps_lethals[ level.rr_ps_lethals.size ] = rr_ps_item( "equip_cluster_grenade", 2 );
    level.rr_ps_lethals[ level.rr_ps_lethals.size ] = rr_ps_item( "equip_thermobaric_grenade", 2 );
    level.rr_ps_lethals[ level.rr_ps_lethals.size ] = rr_ps_item( "equip_impact_grenade", 2 );
    level.rr_ps_lethals[ level.rr_ps_lethals.size ] = rr_ps_item( "equip_mini_sentry", 2 );
    level.rr_ps_tacticals = [];
    level.rr_ps_tacticals[ level.rr_ps_tacticals.size ] = rr_ps_item( "equip_concussion", 2 );
    level.rr_ps_tacticals[ level.rr_ps_tacticals.size ] = rr_ps_item( "equip_adrenaline", 2 );
    level.rr_ps_tacticals[ level.rr_ps_tacticals.size ] = rr_ps_item( "equip_decoy", 2 );
    level.rr_ps_tacticals[ level.rr_ps_tacticals.size ] = rr_ps_item( "equip_shockstick", 2 );
    level.rr_ps_tacticals[ level.rr_ps_tacticals.size ] = rr_ps_item( "equip_blackhole_bomb", 3 );   // Kazimir
    level.rr_ps_tacticals[ level.rr_ps_tacticals.size ] = rr_ps_item( "equip_monkey_bomb", 3 );
    level.rr_ps_tacticals[ level.rr_ps_tacticals.size ] = rr_ps_item( "equip_gas_grenade", 3 );      // Psych grenade
    // Rarity of items that are not in the pools above (only used to find
    // which pool to switch into).
    level.rr_ps_other_rarity = [];
    level.rr_ps_other_rarity[ "equip_smart_seeker" ] = 2;
    level.rr_ps_other_rarity[ "equip_smoke" ] = 2;

    // v3.1 GRAMOPHONE ------------------------
    // 1 = rework on. 0 = stock Gramophone.
    level.rr_gramophone = 1;
    // Damage multiplier for everything you deal with the relic on (stock 1.25).
    level.rr_gramo_damage_mult = 2;

    // v3.2 VRILL SPHERE ----------------------
    // 1 = rework on. 0 = stock Vrill Sphere.
    level.rr_vrill_sphere = 1;

    // v3.3 STUFFED ELEPHANT ------------------
    // 1 = rework on. 0 = stock Stuffed Elephant.
    level.rr_stuffed_elephant = 1;
    // Regen delay with the relic, in seconds (stock is about 6).
    level.rr_elephant_delay_seconds = 3;

    // v3.4 VALKYRIE HELMET -------------------
    // 1 = rework on. 0 = stock Valkyrie Helmet.
    level.rr_valkyrie_helmet = 1;
    // Max electric fields per round, all players together.
    level.rr_valk_max_per_round = 1;
    // Must match the relic's spawn radius (bundle: 300).
    level.rr_valk_radius = 300;
    // v5.3: 1 = the mod spawns the fields itself (same effect, same damage
    // as stock) and logs each step. 0 = the game spawns them (v5.2 and older).
    level.rr_valk_own_spawn = 0;

    // v3.5 FILM REEL -------------------------
    // 1 = rework on. 0 = stock Film Reel.
    level.rr_film_reel = 1;

    // v3.6 BLOOD VIALS -----------------------
    // 1 = rework on. 0 = stock Blood Vials (augments off).
    level.rr_blood_vials = 1;

    // v3.7 CIVIL PROTECTOR HEAD --------------
    // 1 = rework on. 0 = stock (every 100 kills).
    level.rr_civil_protector = 1;
    // Kills per lost perk.
    level.rr_cph_kills = 350;

    // v3.8 MANGLER HELMET --------------------
    // 1 = rework on. 0 = stock Mangler Helmet.
    level.rr_mangler_helmet = 1;
    // Chance (%) before the swap round that a Legendary tool / PaP 3
    // crystal spawns as an Ultra tool / PaP 4 crystal instead.
    level.rr_mh_upgrade_chance = 25;
    // From this round on it is always swapped.
    level.rr_mh_full_swap_round = 40;

    // v3.9 AGARTHAN DEVICE -------------------
    // 1 = rework on. 0 = stock Agarthan Device.
    level.rr_agarthan = 1;
    // Elemental types used on the changed rounds (armored Agni left out).
    level.rr_ag_types = [];
    level.rr_ag_types[ level.rr_ag_types.size ] = "zombie_base_luna";
    level.rr_ag_types[ level.rr_ag_types.size ] = "zombie_base_toxic";

    // v4.0 MUSIC BOX -------------------------
    // 1 = rework on. 0 = stock Music Box.
    level.rr_music_box = 1;
    // Extra points for a critical kill with the relic on (stock critical
    // kill is 100, so 100 extra = 200). Double Points doubles the bonus too.
    level.rr_mb_crit_kill_bonus = 100;

    // v7.2 MANNEQUIN TURRET (No Armor) -----
    // 1 = the relic works with Cursed Reimagined (CR switches the game's
    // no-armor flag off because it also blocks armor purchases): no normal
    // armor, and CR's armor wall sells Golden Armor directly at CR's price.
    level.rr_mannequin = 1;

    // v6.7 WRESTLING BELT ------------------
    // 1 = rework on: weapon wall-buys randomize every round even with
    // Cursed Reimagined's Green lock (the stock relic skips locked walls).
    level.rr_wrestling_belt = 1;

    // v4.1 MENU / PAUSE MENU TEXT -----------
    // 1 = tell the Lua file which reworked relics are active (dvar
    // rr_relics), so the pause menu can show their new descriptions.
    level.rr_ui_relic_list = 1;

    // v8.4 DANCING ARNIE (level.rr_dancing_arnie) -----
    // 1 = Dancing Arnie no longer makes perk machines give random perks.
    // Instead it turns on Cursed Reimagined's hard armor (needs CR running):
    // vs normal zombies Turtle Shell blocks half its normal front share and
    // other majors block nothing from the front (back hits unchanged);
    // specials / elites and the boss's own attacks use stock BO7 armor.
    level.rr_dancing_arnie = 1;

    // 1 = show "Relic Rebalance v5.0 loaded" on screen when you spawn, so you
    // can tell the file is running.
    level.rr_show_loaded = 0;

    // v6.2 TEST: 1 = print what the reworks do on screen as it happens
    // (only on events, never on a timer). 0 = off.
    level.rr_test_print = 0;
    // v6.9 TEST: 1 = one Power Switch line per swap (what you had, what you
    // got). Set to 0 once the counts are right.
    level.rr_ps_print = 0;   // 1 = Power Switch / Mannequin Turret test lines


    // 1 = on-screen list of which enemy types keep / lose the +50%.
    level.gsr_debug = 0;

    // v5.0 CRASH DIAGNOSTICS -----------------
    // 1 = count what every part of the mod does and send a summary to the Lua
    // file each second (shown on screen in a match when its DIAG_HUD = 1).
    level.rr_diag = 0;   // v5.7: debug line off (it builds text every second). 1 = on

    // v4.9 TESTING SWITCHES (crash hunt) -----
    // 1 = Golden Spork rework on (armor / health / zombie damage hooks; these
    //     run in every match, with or without the relic). 0 = all of it off.
    level.rr_spork_rework = 1;
    // 1 = round damage scaling change on (every 20 rounds after 51).
    level.rr_round_scaling = 1;
    // CRASH TEST: 0 = everything as set above.
    //   1 = only GROUP A on:  Golden Spork, round scaling, Rocket, Music Box
    //   2 = only GROUP B on:  Film Reel, Power Switch, Stuffed Elephant,
    //       Dragon Wings, Vrill Sphere, Agarthan, menu relic list
    level.rr_test_half = 0;
    // ------------------------------------------

    if ( level.rr_test_half == 1 )
    {
        level.rr_film_reel = 0;
        level.rr_power_switch = 0;
        level.rr_stuffed_elephant = 0;
        level.rr_dragon_wings = 0;
        level.rr_vrill_sphere = 0;
        level.rr_agarthan = 0;
        level.rr_ui_relic_list = 0;
        level.rr_lawyers_pen = 0;
        level.rr_gramophone = 0;
        level.rr_valkyrie_helmet = 0;
        level.rr_blood_vials = 0;
        level.rr_civil_protector = 0;
        level.rr_mangler_helmet = 0;
    }
    else if ( level.rr_test_half == 2 )
    {
        level.rr_spork_rework = 0;
        level.rr_round_scaling = 0;
        level.rr_rocket = 0;
        level.rr_music_box = 0;
    }

    level.gsr_debug_seen = [];
    level.gsr_spork_on = 0;
    level.rr_dc = [];
    level.rr_dlast = "init";
    level thread rr_diag_watch();
    if ( level.rr_spork_rework >= 1 )
    {
        callback::add( "on_agent_spawned", &gsr_on_agent_spawned );
        callback::add( #"player_spawned", &gsr_on_player_spawned );
        level thread gsr_existing_ai();
        level thread gsr_relic_watch();
        level thread gsr_existing_players();
        level thread gsr_armored_spawn_watch();
    }
    if ( level.rr_round_scaling >= 1 )
    {
        level thread rr_scaling_hook_watch();
    }
    level thread rr_pen_watch();
    level thread rr_wings_watch();
    level thread rr_rocket_watch();
    level thread rr_ps_watch();
    level thread rr_gramo_watch();
    level thread rr_vrill_watch();
    level thread rr_elephant_watch();
    level thread rr_valk_watch();
    level thread rr_film_watch();
    level thread rr_bv_watch();
    level thread rr_cph_watch();
    level thread rr_mh_watch();
    level thread rr_mb_watch();
    level thread rr_wcb_watch();
    level thread rr_mq_watch();
    level callback::add( #"player_used_item", &rr_egg_used );
    level thread rr_mq_latch_watch();
    level thread rr_mq_status();
    callback::add( "on_round_end", &rr_wb_on_round_end );
    callback::add( "on_zombie_ai_killed", &rr_mb_on_zombie_killed );
    level thread rr_ui_watch();
    level thread rr_arnie_watch();
    callback::add( #"player_spawned", &rr_loaded_message );
    callback::add( "on_round_start", &rr_ag_on_round_start );
    callback::add( "on_agent_spawned", &rr_ag_on_agent_spawned );
    callback::add( "on_round_end", &rr_ps_on_round_end );
    callback::add( "on_round_ai_spawn_started", &rr_wings_on_round_start );
    callback::add( "on_agent_spawned", &rr_wings_on_agent_spawned );
    callback::add( "on_round_last_ai_killed", &rr_wings_on_last_ai_killed );
    callback::add( "on_round_end", &rr_pen_on_round_end );
    logstring( "[Relic Rebalance v8.3] loaded" );
}

// -------------------- WHO GETS THE +50% --------------------

function private gsr_names( ai )
{
    names = [];
    names[ 0 ] = tolower( "" + ( ai.subclass ?? "" ) );
    names[ 1 ] = tolower( "" + ( ai.archetype ?? "" ) );
    names[ 2 ] = tolower( "" + ( ai.aitype ?? "" ) );
    return names;
}

function private gsr_name_in( ai, list )
{
    names = gsr_names( ai );
    foreach ( key in list )
    {
        foreach ( n in names )
        {
            if ( n != "" && issubstr( n, key ) )
            {
                return true;
            }
        }
    }
    return false;
}

function private gsr_category( ai )
{
    category = ai.aicategory;
    if ( !isdefined( category ) && isdefined( ai.zombieaisettings ) )
    {
        category = ai.zombieaisettings.aicategory;
    }
    return category;
}

// v2.4: armored zombie (zombie_base_armored_light / _heavy / _agni ...).
function private gsr_is_armored( ai )
{
    return isdefined( ai ) && gsr_name_in( ai, level.gsr_armored_names );
}

// True = this enemy should NOT get the Golden Spork's damage bonus.
function private gsr_is_exempt( ai )
{
    if ( !isdefined( ai ) )
    {
        return false;
    }
    if ( gsr_name_in( ai, level.gsr_never_doubled ) )
    {
        return true;
    }
    if ( level.gsr_boss_summons_doubled < 1 && isdefined( ai.spawn_source ) && issubstr( tolower( "" + ai.spawn_source ), "diana" ) )
    {
        return true;   // Nyxara's summoned zombies (spawn_source "diana_summon_zombies_spawn")
    }
    if ( gsr_name_in( ai, level.gsr_always_doubled ) )
    {
        return false;
    }
    category = gsr_category( ai );
    return isdefined( category ) && isdefined( level.gsr_exempt_categories[ category ] );
}

// -------------------- SETUP PER ENEMY --------------------

function private gsr_on_agent_spawned( params )
{
    ent = params.agent;
    if ( isdefined( ent ) )
    {
        ent thread gsr_setup();
    }
}

function private gsr_existing_ai()
{
    wait 1;
    foreach ( ai in getaiarray() )
    {
        if ( isdefined( ai ) && isalive( ai ) )
        {
            ai thread gsr_setup();
        }
    }
}

// Waits for the enemy's own setup (category, stock override), then wraps.
// Re-checks now and then in case the game sets a new override later.
function private gsr_setup()
{
    rr_d( "zombie_setup" );
    self endon( #"death" );
    if ( istrue( self.gsr_watching ) )
    {
        return;
    }
    self.gsr_watching = 1;

    wait 0.5;
    exempt = gsr_is_exempt( self );
    self gsr_debug_report( exempt );
    self gsr_record_normal_ref();
    if ( !exempt && !gsr_is_armored( self ) )
    {
        return;   // normal / hellhound: keeps the +50%, untouched
    }

    while ( true )
    {
        if ( !istrue( self.gsr_wrapped ) || !( self.ai_attack_damage_override === &gsr_override ) )
        {
            // Keep whatever the game put there (if anything) and call it first.
            if ( isdefined( self.ai_attack_damage_override ) && !( self.ai_attack_damage_override === &gsr_override ) )
            {
                self.gsr_orig_override = self.ai_attack_damage_override;
            }
            self.ai_attack_damage_override = &gsr_override;
            self.gsr_wrapped = 1;
        }
        // v1.1: bosses set their own override during the fight (Veytharion's
        // missiles: zombie_hermes_missile.gsc), so re-check quickly.
        wait 0.25;
    }
}

// v2.5: remember what a normal zombie hits for (it changes with the round,
// and Cursed Reimagined pins it), from the latest normal zombie to spawn.
function private gsr_record_normal_ref()
{
    if ( tolower( "" + ( self.subclass ?? "" ) ) != level.gsr_normal_ref_subclass )
    {
        return;
    }
    if ( isdefined( self.melee_damage ) && self.melee_damage > 0 )
    {
        level.gsr_ref_melee = self.melee_damage;
    }
}

// v2.5: multiplier that turns this armored zombie's hit into a normal
// zombie's hit. Fallback before any normal zombie spawned: base 30 / 35.
function private gsr_armored_ratio( attacker )
{
    if ( level.gsr_armored_match_normal < 1 )
    {
        return 1;
    }
    if ( isdefined( level.gsr_ref_melee ) && isdefined( attacker.melee_damage ) && attacker.melee_damage > 0 )
    {
        ratio = level.gsr_ref_melee / attacker.melee_damage;
    }
    else
    {
        ratio = 30 / 35;
    }
    if ( ratio > 1 )
    {
        ratio = 1;   // never make an armored zombie hit harder than stock
    }
    return ratio;
}

// Called by zm_player_damage.gsc right after the relic multiplier:
// [[ override ]]( idamage, attacker, objweapon, smeansofdeath, vpoint )
function gsr_override( idamage, attacker, objweapon, smeansofdeath, vpoint )
{
    rr_d( "spork_hit" );
    if ( isdefined( attacker ) && isdefined( attacker.gsr_orig_override ) )
    {
        // self = the player who was hit (stock overrides such as Veytharion's
        // missile scaling read self.origin / self.vehicle).
        idamage = self [[ attacker.gsr_orig_override ]]( idamage, attacker, objweapon, smeansofdeath, vpoint );
    }

    mult = level.var_3f27e31a208b760f;
    if ( !isdefined( idamage ) || !isdefined( mult ) || mult <= 1 )
    {
        return idamage;   // no Golden Spork: unchanged
    }

    // v2.5: armored zombie -> same health damage as a normal zombie. The
    // ratio is remembered so the armor code can keep their armor damage.
    if ( isdefined( attacker ) && gsr_is_armored( attacker ) )
    {
        ratio = gsr_armored_ratio( attacker );
        self.gsr_eq_ratio = ratio;
        self.gsr_eq_attacker = attacker;
        self.gsr_eq_time = gettime();
        if ( ratio != 1 )
        {
            scaled = int( idamage * ratio );
            if ( idamage > 0 && scaled < 1 )
            {
                scaled = 1;
            }
            idamage = scaled;
        }
        return idamage;   // keeps the relic's +50%
    }

    if ( !isdefined( attacker ) || !gsr_is_exempt( attacker ) )
    {
        return idamage;
    }

    undone = int( idamage / mult );
    if ( idamage > 0 && undone < 1 )
    {
        undone = 1;
    }
    return undone;
}

// -------------------- DEBUG --------------------

function private gsr_debug_report( exempt )
{
    if ( level.gsr_debug < 1 )
    {
        return;
    }
    key = "" + ( self.subclass ?? "?" );
    if ( isdefined( level.gsr_debug_seen[ key ] ) )
    {
        return;
    }
    level.gsr_debug_seen[ key ] = 1;

    msg = "^2gets +50%";
    if ( gsr_is_armored( self ) )
    {
        msg = "^6+50% (normal zombie damage), more armor wear";
    }
    else if ( exempt )
    {
        msg = "^3normal damage";
    }
    cat = gsr_category( self );
    if ( !isdefined( cat ) )
    {
        cat = "?";
    }
    text = "^5[Relic Rebalance] ^7" + key + " (" + cat + ") -> " + msg;
    if ( isdefined( level.players ) )
    {
        foreach ( p in level.players )
        {
            if ( isdefined( p ) )
            {
                p iprintln( text );
            }
        }
    }
}

// =====================================================================
// v2.0: RELIC WATCH  (x2 -> x1.5, and "is the Golden Spork on?")
// =====================================================================

function private gsr_relic_watch()
{
    level endon( #"game_ended" );
    while ( true )
    {
        val = level.var_3f27e31a208b760f;
        if ( isdefined( val ) && val == 2 )
        {
            // The relic just switched on (or the game re-applied it).
            level.var_3f27e31a208b760f = level.gsr_enemy_damage_mult;
            level.gsr_spork_on = 1;
        }
        else if ( istrue( level.gsr_spork_on ) && isdefined( val ) && val == level.gsr_enemy_damage_mult )
        {
            // still on, already ours
        }
        else
        {
            level.gsr_spork_on = isdefined( val ) && val > 1;
        }
        wait 0.1;
    }
}

// =====================================================================
// v2.0: PLAYERS  (100 health without Jug, armor hooks)
// =====================================================================

function private gsr_existing_players()
{
    level endon( #"game_ended" );
    // v2.6: keeps checking, so a player whose spawn callback was missed
    // (joined during load, hot join) still gets the health / armor loop.
    while ( true )
    {
        if ( isdefined( level.players ) )
        {
            foreach ( p in level.players )
            {
                if ( isdefined( p ) && !istrue( p.gsr_loop_running ) )
                {
                    p thread gsr_player_loop();
                }
            }
        }
        wait 2;
    }
}

function private gsr_on_player_spawned( params )
{
    self thread gsr_player_loop();
}

function private gsr_has_jug()
{
    if ( !utility::issharedfuncdefined( #"zombie_perks", #"has_zombie_perk" ) )
    {
        return undefined;   // perks not ready yet
    }
    return istrue( self utility::callsharedfunc( #"zombie_perks", #"has_zombie_perk", "specialty_juggernog" ) );
}

function private gsr_has_augment( name )
{
    if ( !utility::issharedfuncdefined( #"zombie", #"player_has_augment" ) )
    {
        return false;
    }
    return istrue( self utility::callsharedfunc( #"zombie", #"player_has_augment", name ) );
}

function private gsr_player_loop()
{
    self endon( #"disconnect" );
    self notify( #"gsr_player_loop" );
    self endon( #"gsr_player_loop" );
    self.gsr_loop_running = 1;

    while ( true )
    {
        if ( isalive( self ) )
        {
            self gsr_health_tick();
            self gsr_armor_hook_tick();
        }
        wait 0.25;
    }
}

function private gsr_set_max_health( n )
{
    self.maxhealth = n;
    if ( self.health > n )
    {
        self.health = n;
    }
    self callback::callback( "on_player_max_health_change", { #new_max_health:n } );
}

function private gsr_health_tick()
{
    rr_d( "health_tick" );
    has_jug = self gsr_has_jug();
    if ( !isdefined( has_jug ) )
    {
        self gsr_health_debug( "perks not ready" );
        return;
    }
    target = level.gsr_base_health_no_jug;

    if ( istrue( level.gsr_spork_on ) && !has_jug )
    {
        // v2.6: no longer needs the max health to equal the match-rules
        // value. Anything above 100 is cut, unless an overheal (health
        // overcharge) is running right now - that one cleans itself up and
        // the next tick cuts it then.
        overcharged = isdefined( self.health_overcharge_data ) && isnumber( self.health_overcharge_data.overcharged_max_health );
        if ( !overcharged && isdefined( self.maxhealth ) && self.maxhealth > target )
        {
            self gsr_set_max_health( target );
            self.gsr_health_cut = 1;
            self gsr_health_debug( "cut to " + target );
        }
    }
    else if ( istrue( self.gsr_health_cut ) )
    {
        // Relic switched off: give the stock base back (Jug sets its own).
        if ( !has_jug && self.maxhealth == target )
        {
            stock_base = int( getmatchrulesdata( "commonOption", "maxHealth" ) );
            if ( !isdefined( stock_base ) || stock_base <= target )
            {
                stock_base = 150;
            }
            self gsr_set_max_health( stock_base );
        }
        self.gsr_health_cut = undefined;
    }
    self gsr_health_debug( "" );
}

// v2.6: level.gsr_debug = 1 shows what the health check sees (when it
// changes), so a wrong max health can be traced.
function private gsr_health_debug( note )
{
    if ( level.gsr_debug < 1 )
    {
        return;
    }
    jug = self gsr_has_jug();
    text = "^5[Relic Rebalance] ^7health: spork " + ( istrue( level.gsr_spork_on ) ? "^2on" : "^1off" )
        + "^7 (mult " + ( level.var_3f27e31a208b760f ?? "none" ) + ") jug " + ( isdefined( jug ) ? ( jug ? "yes" : "no" ) : "?" )
        + " max " + ( self.maxhealth ?? "?" );
    if ( note != "" )
    {
        text += " -> " + note;
    }
    if ( self.gsr_last_health_debug === text )
    {
        return;
    }
    self.gsr_last_health_debug = text;
    self iprintln( text );
}

// Keeps our armor hooks installed, wrapping anything the game put there.
function private gsr_armor_hook_tick()
{
    rr_d( "armor_hook_tick" );
    if ( !( self.callback_armor_damage_override === &gsr_armor_absorb ) )
    {
        if ( isdefined( self.callback_armor_damage_override ) )
        {
            self.gsr_orig_armor_absorb = self.callback_armor_damage_override;
        }
        self.callback_armor_damage_override = &gsr_armor_absorb;
    }
    if ( !( self.callback_armor_post_damage_override === &gsr_armor_post ) )
    {
        if ( isdefined( self.callback_armor_post_damage_override ) )
        {
            self.gsr_orig_armor_post = self.callback_armor_post_damage_override;
        }
        self.callback_armor_post_damage_override = &gsr_armor_post;
    }
}

// =====================================================================
// v2.0: ARMOR
// =====================================================================

// Stock zm_armor.gsc armor_damage_absorbed() mitigation, recomputed.
function private gsr_stock_mitigation( eattacker )
{
    b = level.armormetadatabundle;
    lv1 = 0.45;
    lv2 = 0.58;
    lv3 = 0.65;
    if ( isdefined( b ) )
    {
        lv1 = b.var_6e36edafe33fcbbd ?? 0.45;
        lv2 = b.var_e1ccf0a99db550c ?? 0.58;
        lv3 = b.var_28630d21f2687b7b ?? 0.65;
    }
    mit = lv1;
    if ( self.platecarrierlevel === 2 )
    {
        mit = lv2;
    }
    else if ( self.platecarrierlevel === 3 )
    {
        mit = lv3;
    }
    if ( istrue( self gsr_has_jug() ) && self gsr_has_augment( #"juggernog_thicker_plates" ) )
    {
        mit += level.zombie_augments[ #"juggernog_thicker_plates" ].var_fcd4c396ce615ccc ?? 0;
    }
    if ( isdefined( eattacker ) && isdefined( eattacker.armormitigationmultiplier ) )
    {
        mit *= eattacker.armormitigationmultiplier;
    }
    return mit;
}

// Did the game multiply this hit by the relic (and leave it multiplied)?
function private gsr_hit_mult( eattacker )
{
    if ( !isdefined( eattacker ) || !isai( eattacker ) || isplayer( eattacker ) )
    {
        return 1;
    }
    mult = level.var_3f27e31a208b760f;
    if ( !isdefined( mult ) || mult <= 1 )
    {
        return 1;
    }
    attacker = eattacker.gunner ?? eattacker;
    if ( gsr_is_exempt( attacker ) )
    {
        return 1;   // our override already took the bonus back off
    }
    return mult;
}

// Same test zm_armor.gsc uses for Turtle Shell (hit from behind = full block).
function private gsr_turtle_shell_hit( eattacker, einflictor, smeansofdeath )
{
    if ( !isdefined( eattacker ) || eattacker == self )
    {
        return false;
    }
    if ( smeansofdeath === "MOD_BLEEDOUT" && istrue( eattacker.var_f968344e6801d0c1 ) )
    {
        return false;
    }
    if ( istrue( eattacker.ignore_turtle_shell ) || ( isdefined( einflictor ) && istrue( einflictor.ignore_turtle_shell ) ) )
    {
        return false;
    }
    if ( !istrue( self gsr_has_jug() ) || !self gsr_has_augment( #"juggernog_turtle_shell" ) )
    {
        return false;
    }
    org = eattacker.turtle_shell_attack_origin ?? eattacker.origin;
    if ( !isdefined( org ) || org == self.origin )
    {
        return false;
    }
    dir = vectornormalize( org - self.origin );
    fwd = vectornormalize( anglestoforward( self.angles ) );
    return vectordot( fwd, dir ) <= 0;
}

// self = player. Returns how much of the hit the armor absorbs.
// zm_armor.gsc: damagepassed = damage - absorbed.
function gsr_armor_absorb( damage, eattacker, einflictor, smeansofdeath )
{
    rr_d( "armor_absorb" );
    if ( isdefined( eattacker ) && eattacker == self )
    {
        rr_ev( "armor: self hit " + ( smeansofdeath ?? "?" ) + " " + ( isdefined( damage ) ? int( damage ) : -1 ) );
    }
    self.gsr_wear_scale = undefined;

    if ( isdefined( self.gsr_orig_armor_absorb ) )
    {
        absorbed = self [[ self.gsr_orig_armor_absorb ]]( damage, eattacker, einflictor, smeansofdeath );
    }
    else
    {
        absorbed = damage * self gsr_stock_mitigation( eattacker );
    }

    if ( !istrue( level.gsr_spork_on ) || !isdefined( absorbed ) || !isdefined( damage ) || damage <= 0 )
    {
        return absorbed;
    }

    hit_mult = gsr_hit_mult( eattacker );
    new_absorbed = absorbed * level.gsr_armor_mitigation_scale;

    // v2.4: armored zombies wear armor faster than stock.
    // v2.5: and their armor damage is based on their stock (pre-match) hit.
    wear_bonus = 1;
    real_attacker = undefined;
    if ( isdefined( eattacker ) )
    {
        real_attacker = eattacker.gunner ?? eattacker;
    }
    if ( isdefined( real_attacker ) && gsr_is_armored( real_attacker ) )
    {
        wear_bonus = level.gsr_armored_armor_wear_mult;
        if ( isdefined( self.gsr_eq_ratio ) && self.gsr_eq_ratio > 0 && self.gsr_eq_attacker === real_attacker && self.gsr_eq_time === gettime() )
        {
            wear_bonus /= self.gsr_eq_ratio;
        }
    }
    self.gsr_eq_ratio = undefined;
    self.gsr_eq_attacker = undefined;

    if ( level.gsr_armor_wear_as_no_relic >= 1 )
    {
        if ( self gsr_turtle_shell_hit( eattacker, einflictor, smeansofdeath ) )
        {
            // Turtle Shell blocks the whole hit; only undo the relic bonus.
            self.gsr_wear_scale = wear_bonus / hit_mult;
        }
        else if ( new_absorbed > 0 )
        {
            // Wear = what this hit would have worn without the relic.
            self.gsr_wear_scale = ( absorbed * wear_bonus / hit_mult ) / new_absorbed;
        }
    }
    return new_absorbed;
}

// self = player. Returns how much armor health the hit removes. Runs after
// the game's own adjustments (Durable Plates, Turtle Shell halving, ...).
function gsr_armor_post( damageabsorbed, attacker, smeansofdeath )
{
    rr_d( "armor_post" );
    if ( isdefined( self.gsr_orig_armor_post ) )
    {
        damageabsorbed = self [[ self.gsr_orig_armor_post ]]( damageabsorbed, attacker, smeansofdeath );
    }
    if ( isdefined( self.gsr_wear_scale ) && isdefined( damageabsorbed ) )
    {
        damageabsorbed *= self.gsr_wear_scale;
    }
    self.gsr_wear_scale = undefined;
    return damageabsorbed;
}

// =====================================================================
// v2.0: NO ARMORED ZOMBIES OUTSIDE BOSS FIGHTS
// =====================================================================

function private gsr_boss_alive()
{
    foreach ( ai in getaiarray() )
    {
        if ( !isdefined( ai ) || !isalive( ai ) )
        {
            continue;
        }
        if ( gsr_category( ai ) === "boss" )
        {
            return true;
        }
        // Boss names as a backup ("weyward" also matches the Warden's
        // stingers, which only exist during its fight).
        if ( gsr_name_in( ai, level.gsr_never_doubled ) )
        {
            return true;
        }
    }
    return false;
}

function private gsr_armored_spawn_watch()
{
    level endon( #"game_ended" );
    level.gsr_armored_blocked = 0;
    level.gsr_saved_overrides = [];

    while ( !isdefined( level.var_a009ab14ee0d3223 ) )
    {
        wait 0.5;
    }

    while ( true )
    {
        want = level.gsr_block_armored_spawns >= 1 && istrue( level.gsr_spork_on ) && !gsr_boss_alive();
        if ( want && !level.gsr_armored_blocked )
        {
            gsr_block_armored( 1 );
        }
        else if ( !want && level.gsr_armored_blocked )
        {
            gsr_block_armored( 0 );
        }
        wait 0.5;
    }
}

function private gsr_block_armored( on )
{
    rs = level.var_a009ab14ee0d3223;
    if ( !isdefined( rs.aitypeoverridemap ) )
    {
        rs.aitypeoverridemap = [];
    }

    foreach ( sub in level.gsr_armored_subclasses )
    {
        if ( on )
        {
            // Keep whatever the game had there so it can be put back.
            level.gsr_saved_overrides[ sub ] = rs.aitypeoverridemap[ sub ];
            rs.aitypeoverridemap[ sub ] = [ level.gsr_armored_replacement ];
        }
        else
        {
            rs.aitypeoverridemap[ sub ] = level.gsr_saved_overrides[ sub ];
        }
    }
    gsr_fog_armored( on );
    level.gsr_armored_blocked = on;

    if ( level.gsr_debug >= 1 && isdefined( level.players ) )
    {
        text = "^5[Relic Rebalance] ^7armored zombie spawns " + ( on ? "^3blocked" : "^2allowed" );
        foreach ( p in level.players )
        {
            if ( isdefined( p ) )
            {
                p iprintln( text );
            }
        }
    }
}

// Fog spawning (zm_fog_spawning.gsc) rolls its own armored chance.
function private gsr_fog_armored( on )
{
    fog = level.var_33df283475cc8d48;
    if ( !isdefined( fog ) )
    {
        return;
    }
    if ( on )
    {
        if ( !isdefined( level.gsr_fog_saved ) )
        {
            level.gsr_fog_saved = [ fog.var_796d2c1d76f03505, fog.var_323e6700f1834c22, fog.lategamearmoredzombiechance ];
        }
        fog.var_796d2c1d76f03505 = 0;
        fog.var_323e6700f1834c22 = 0;
        fog.lategamearmoredzombiechance = 0;
    }
    else if ( isdefined( level.gsr_fog_saved ) )
    {
        fog.var_796d2c1d76f03505 = level.gsr_fog_saved[ 0 ];
        fog.var_323e6700f1834c22 = level.gsr_fog_saved[ 1 ];
        fog.lategamearmoredzombiechance = level.gsr_fog_saved[ 2 ];
        level.gsr_fog_saved = undefined;
    }
}

// =====================================================================
// v2.1: ROUND DAMAGE SCALING  (every 20 rounds instead of 10 after 51)
// =====================================================================

// v2.3: true = this enemy always gets this mod's round scaling, even with
// Cursed Reimagined running. self = the enemy being scaled.
function rr_scaling_has_priority()
{
    category = gsr_category( self );
    if ( isdefined( category ) && arraycontains( level.rr_scaling_cr_priority, category ) )
    {
        return true;
    }
    // Boss names as a backup, in case the category is not readable yet.
    return arraycontains( level.rr_scaling_cr_priority, "boss" ) && gsr_name_in( self, level.gsr_never_doubled );
}

// The round number the game's step tables should see. self = the enemy.
function rr_scaled_round( real_round )
{
    start = level.rr_scaling_slow_from_round;
    slow = level.rr_scaling_slowdown;
    if ( !isdefined( real_round ) || real_round <= start || slow <= 1 )
    {
        return real_round;
    }
    if ( level.rr_scaling_spork_only >= 1 && !istrue( level.gsr_spork_on ) )
    {
        return real_round;
    }
    // v2.2: Cursed Reimagined runs its own damage tiers; leave them alone...
    // v2.3: ...except for bosses (and any category listed in
    // level.rr_scaling_cr_priority), which always get this mod's scaling.
    if ( level.rr_scaling_skip_cursed_reimagined >= 1 && istrue( level.cursed_damage_tier_hooked ) && !( self rr_scaling_has_priority() ) )
    {
        return real_round;
    }
    return start + int( ( real_round - start ) / slow );
}

// Installs our wrapper on the game's damage scaling function ONCE, keeping
// whatever was there (stock, or Cursed Reimagined's wrapper) and calling it.
// v2.2: never re-wraps. Cursed Reimagined also wraps this function; if it
// installs after us it wraps OUR wrapper, and re-wrapping it again would make
// the two call each other forever. Installing once avoids that.
function private rr_scaling_hook_watch()
{
    level endon( #"game_ended" );
    if ( istrue( level.rr_scaling_hooked ) )
    {
        return;
    }
    for ( i = 0; i < 600 && !utility::issharedfuncdefined( #"zombie", #"hash_e27e55920dabe660" ); i++ )
    {
        waitframe();
    }
    if ( !utility::issharedfuncdefined( #"zombie", #"hash_e27e55920dabe660" ) )
    {
        logstring( "[Relic Rebalance] damage scaling func not found; round scaling change off" );
        return;
    }
    current = utility::getsharedfunc( #"zombie", #"hash_e27e55920dabe660" );
    if ( !isdefined( current ) || current === &rr_damage_scaling )
    {
        return;
    }
    level.rr_orig_scaling = current;
    utility::registersharedfunc( #"zombie", #"hash_e27e55920dabe660", &rr_damage_scaling );
    level.rr_scaling_hooked = 1;
}

// self = the zombie. Same signature as damage_scaling_round.gsc.
function rr_damage_scaling( fixed_round_number )
{
    rr_d( "round_scaling" );
    if ( !isdefined( level.rr_orig_scaling ) )
    {
        return;
    }
    scaled = self rr_scaled_round( fixed_round_number );
    if ( !isdefined( scaled ) || scaled === fixed_round_number )
    {
        return self [[ level.rr_orig_scaling ]]( fixed_round_number );
    }

    // Real round first, to keep the non-damage values (max attackers and
    // the round-55 flag) exactly stock...
    self [[ level.rr_orig_scaling ]]( fixed_round_number );
    keep_attackers = self.var_577dec43cf1caedf;
    keep_flag = self.var_f1cb4f6133640cfe;

    // ...then the damage multipliers from the slower round.
    result = self [[ level.rr_orig_scaling ]]( scaled );
    self.var_577dec43cf1caedf = keep_attackers;
    self.var_f1cb4f6133640cfe = keep_flag;
    return result;
}

// =====================================================================
// v2.7: LAWYER'S PEN  (Mimic props every other round, cleared at round end)
// =====================================================================

// The relic's Mimic settings struct, if the Lawyer's Pen is active.
function private rr_pen_params()
{
    mm = level.zm_mode_modifiers;
    if ( !isdefined( mm ) || !istrue( mm.var_17778bfafdc97691 ) )
    {
        return undefined;
    }
    return mm.var_893592d56948086f;
}

function private rr_pen_round_allows( round )
{
    odd = ( round % 2 ) == 1;
    if ( level.rr_pen_odd_rounds >= 1 )
    {
        return odd;
    }
    return !odd;
}

// Turns the relic's drop chance off on the rounds without Mimics and puts
// the stock chance back on the rounds with them.
function private rr_pen_watch()
{
    level endon( #"game_ended" );
    while ( true )
    {
        params = rr_pen_params();
        if ( isdefined( params ) && !istrue( level.rr_pen_seen ) )
        {
            level.rr_pen_seen = 1;
            rr_ev( "Pen: relic active, chance " + ( params.mimic_spawn_chance ?? "?" ) + " limit " + ( params.mimic_spawn_limit ?? "?" ) + " on map " + ( level.var_7376e4ac664af8e0 ?? "undef" ) + " prop system " + utility::issharedfuncdefined( #"mimic_prop", #"hash_652981ac6cb6e8c9" ) );
        }
        if ( isdefined( params ) )
        {
            // Remember the relic's own chance once (stock 10).
            if ( !isdefined( level.rr_pen_stock_chance ) && isdefined( params.mimic_spawn_chance ) && params.mimic_spawn_chance > 0 )
            {
                level.rr_pen_stock_chance = params.mimic_spawn_chance;
            }
            stock = level.rr_pen_stock_chance ?? 10;

            want = stock;
            if ( level.rr_lawyers_pen >= 1 && !rr_pen_round_allows( zm_utility::get_round_number() ) )
            {
                want = 0;
            }
            if ( !( params.mimic_spawn_chance === want ) )
            {
                params.mimic_spawn_chance = want;
                rr_pen_debug( "round " + zm_utility::get_round_number() + ": mimic drops " + ( want > 0 ? "^2on" : "^1off" ) );
            }
        }
        wait 0.5;
    }
}

function private rr_pen_on_round_end( params )
{
    if ( level.rr_lawyers_pen < 1 || level.rr_pen_clear_on_round_end < 1 )
    {
        return;
    }
    if ( !isdefined( rr_pen_params() ) )
    {
        return;
    }
    level thread rr_pen_clear_props();
}

// Removes every Mimic prop the relic left on the map.
function rr_pen_clear_props()
{
    rr_d( "pen_clear" );
    if ( !utility::issharedfuncdefined( #"mimic_prop", #"clean_up_prop" ) )
    {
        return;
    }
    props = [];
    if ( isdefined( level.mimic_trap_props ) )
    {
        props = arraycombine( props, level.mimic_trap_props );
    }
    if ( isdefined( level.spawned_mimic_props ) )
    {
        props = arraycombine( props, level.spawned_mimic_props );
    }

    cleared = 0;
    seen = [];
    foreach ( prop in props )
    {
        if ( !isdefined( prop ) || !istrue( prop.from_zmmodifier_prop ) || isdefined( seen[ prop getentitynumber() ] ) )
        {
            continue;
        }
        seen[ prop getentitynumber() ] = 1;
        // Same bookkeeping the game does before its own cleanup.
        if ( isdefined( level.var_7376e4ac664af8e0 ) )
        {
            level.var_7376e4ac664af8e0 = maxint( 0, level.var_7376e4ac664af8e0 - 1 );
        }
        level thread utility::callsharedfunc( #"mimic_prop", #"clean_up_prop", prop, 1 );
        cleared++;
    }
    if ( cleared > 0 )
    {
        rr_pen_debug( "round end: cleared " + cleared + " mimic prop(s)" );
    }
}

function private rr_pen_debug( text )
{
    rr_ev( "Pen: " + text );
    if ( level.gsr_debug < 1 || !isdefined( level.players ) )
    {
        return;
    }
    foreach ( p in level.players )
    {
        if ( isdefined( p ) )
        {
            p iprintln( "^5[Relic Rebalance] ^7Lawyer's Pen: " + text );
        }
    }
}

// =====================================================================
// v2.8: DRAGON WINGS  (1 power-up per round, full cycle before repeats)
// =====================================================================

function private rr_wings_on()
{
    return level.rr_dragon_wings >= 1 && istrue( level.rr_wings_active );
}

// Watches for the relic, takes over from its "no power-ups" switch, keeps
// the per-round cap at 1 and keeps the next pick queued from the cycle.
function private rr_wings_watch()
{
    level endon( #"game_ended" );
    level.rr_wings_round_drops = 0;
    level thread rr_wings_drop_listener();

    while ( true )
    {
        mm = level.zm_mode_modifiers;
        root = level.powerups_root;
        if ( isdefined( mm ) && istrue( mm.zmmodedisablepowerups ) && level.rr_dragon_wings >= 1 )
        {
            // The relic just switched power-ups off: power-ups back on,
            // this mod limits them instead.
            level.rr_wings_active = 1;
            mm.zmmodedisablepowerups = 0;
            rr_wings_debug( "active" );
        }

        if ( rr_wings_on() && isdefined( root ) && isdefined( root.powerup_vars ) )
        {
            if ( !isdefined( level.rr_wings_stock_max ) )
            {
                level.rr_wings_stock_max = root.powerup_vars[ "powerup_drop_max_per_round" ];
            }
            // v7.1: the ORDER is the game's own classic cycle (WaW / BO1 /
            // BO3: the list is shuffled, dropped in order, reshuffled when it
            // runs out, never starting with the one that just dropped). This
            // only sets how many can drop.
            if ( rr_wings_boss_active() )
            {
                // v4.6: final encounters drop power-ups like normal.
                root.powerup_vars[ "powerup_drop_max_per_round" ] = level.rr_wings_stock_max;
            }
            else if ( istrue( level.rr_wings_reward_round ) )
            {
                // v4.6: max ammo round: nothing drops from kills, only the
                // round's max ammo at the end.
                root.powerup_vars[ "powerup_drop_max_per_round" ] = 0;
            }
            else
            {
                root.powerup_vars[ "powerup_drop_max_per_round" ] = 1;
            }
            rr_wings_hook_bonus_drops();
        }
        wait 0.25;
    }
}

// v4.6: true while a final encounter (boss fight) is on: a boss is alive.
function private rr_wings_boss_active()
{
    if ( !isdefined( level.rr_wings_bosses ) )
    {
        return false;
    }
    level.rr_wings_bosses = arrayremoveundefined( level.rr_wings_bosses );
    foreach ( b in level.rr_wings_bosses )
    {
        if ( isdefined( b ) && isalive( b ) )
        {
            return true;
        }
    }
    return false;
}

function private rr_wings_on_agent_spawned( params )
{
    rr_d( "wings_agent" );
    agent = undefined;
    if ( isdefined( params ) && isdefined( params.agent ) )
    {
        agent = params.agent;
    }
    else
    {
        agent = self;
    }
    if ( !isdefined( agent ) || !( agent.aicategory === "boss" ) )
    {
        return;
    }
    if ( !isdefined( level.rr_wings_bosses ) )
    {
        level.rr_wings_bosses = [];
    }
    level.rr_wings_bosses[ level.rr_wings_bosses.size ] = agent;
}

// v4.6: special "bonus" drops (elites etc.) ignore the per-round cap. With
// the relic they only happen when no power-up has dropped yet this round
// (they use the cycle's pick, so the order holds), never on max ammo rounds;
// in final encounters they work like normal.
function private rr_wings_hook_bonus_drops()
{
    rr_d( "wings_hookcheck" );
    list = level.var_1db3142b2dbcd1a9;
    if ( !isdefined( list ) || !isarray( list ) )
    {
        return;
    }
    if ( list.size == 1 && list[ 0 ] === &rr_wings_bonus_check )
    {
        return;
    }
    if ( !isdefined( level.rr_wings_bonus_funcs ) )
    {
        level.rr_wings_bonus_funcs = [];
    }
    foreach ( f in list )
    {
        if ( isdefined( f ) && !( f === &rr_wings_bonus_check ) && !arraycontains( level.rr_wings_bonus_funcs, f ) )
        {
            level.rr_wings_bonus_funcs[ level.rr_wings_bonus_funcs.size ] = f;
        }
    }
    level.var_1db3142b2dbcd1a9 = [ &rr_wings_bonus_check ];
}

function rr_wings_bonus_check( params )
{
    rr_d( "wings_bonus" );
    result = undefined;
    if ( isdefined( level.rr_wings_bonus_funcs ) )
    {
        foreach ( f in level.rr_wings_bonus_funcs )
        {
            result = [[ f ]]( params );
            if ( istrue( result ) )
            {
                break;
            }
        }
    }
    if ( !istrue( result ) || !rr_wings_on() || rr_wings_boss_active() )
    {
        return result;
    }
    if ( istrue( level.rr_wings_reward_round ) || level.rr_wings_round_drops > 0 )
    {
        return false;
    }
    return result;
}

// Every power-up the map can drop as a regular kill drop.
function private rr_wings_all_powerups()
{
    root = level.powerups_root;
    all = [];
    if ( !isdefined( root ) || !isdefined( root.powerup_drop_array ) )
    {
        return all;
    }
    foreach ( ref in root.powerup_drop_array )
    {
        if ( isdefined( ref ) && !arraycontains( all, ref ) )
        {
            all[ all.size ] = ref;
        }
    }
    return all;
}

function private rr_wings_can_drop_now( ref )
{
    root = level.powerups_root;
    if ( !isdefined( root.powerups ) || !isdefined( root.powerups[ ref ] ) )
    {
        return false;
    }
    info = root.powerups[ ref ];
    if ( !isdefined( info.func_should_drop_with_regular_powerups ) )
    {
        return true;
    }
    ok = [[ info.func_should_drop_with_regular_powerups ]]();
    return istrue( ok );
}

// v7.1: next power-up from the game's own cycle (same as the game's
// get_available_next_powerup: step through the shuffled list, reshuffle at
// the end so the new order never starts with the last one, skip any that
// can't drop right now).
function private rr_wings_cycle_next()
{
    root = level.powerups_root;
    if ( !isdefined( root ) || !isdefined( root.powerup_drop_array ) || root.powerup_drop_array.size == 0 )
    {
        return undefined;
    }
    if ( !isdefined( root.powerup_index ) )
    {
        root.powerup_index = 0;
    }
    for ( n = root.powerup_drop_array.size * 2; n > 0; n-- )
    {
        ref = root.powerup_drop_array[ root.powerup_index ];
        root.powerup_index++;
        if ( root.powerup_index >= root.powerup_drop_array.size )
        {
            root.powerup_index = 0;
            root.powerup_drop_array = arrayrandomize( root.powerup_drop_array );
            last = root.powerup_drop_array.size - 1;
            if ( last > 0 && root.powerup_drop_array[ 0 ] === ref )
            {
                first = root.powerup_drop_array[ 0 ];
                root.powerup_drop_array[ 0 ] = root.powerup_drop_array[ last ];
                root.powerup_drop_array[ last ] = first;
            }
        }
        if ( isdefined( ref ) && rr_wings_can_drop_now( ref ) )
        {
            return ref;
        }
    }
    return undefined;
}

// Power-ups still waiting for their turn this cycle (refills when empty).
function private rr_wings_pending()
{
    if ( !isdefined( level.rr_wings_pending ) || level.rr_wings_pending.size == 0 )
    {
        level.rr_wings_pending = rr_wings_all_powerups();
        // A new cycle never starts with the one that just ended the old one.
        if ( isdefined( level.rr_wings_last ) && level.rr_wings_pending.size > 1 )
        {
            level.rr_wings_block_first = level.rr_wings_last;
        }
        if ( level.rr_wings_pending.size > 0 )
        {
            rr_wings_debug( "new cycle (" + level.rr_wings_pending.size + " power-ups)" );
        }
    }
    return level.rr_wings_pending;
}


// Counts drops and ticks power-ups off the cycle as they appear.
function private rr_wings_drop_listener()
{
    level endon( #"game_ended" );
    while ( true )
    {
        level waittill( #"powerup_dropped" );
        if ( !rr_wings_on() )
        {
            continue;
        }
        // v7.1: the order is the game's own cycle, so this only counts the
        // round's drop (used to allow the last-zombie drop / bonus drops).
        if ( istrue( level.rr_wings_reward_round ) && istrue( level.rr_wings_reward_dropping ) )
        {
            continue;   // the end-of-round max ammo is not the round's power-up
        }
        level.rr_wings_forcing = undefined;
        level.rr_wings_round_drops++;
        rr_wings_debug( "power-up dropped (" + level.rr_wings_round_drops + " this round)" );
    }
}

function private rr_wings_on_round_start( params )
{
    rr_ev( "ROUND " + zm_utility::get_round_number() + " spawning" );
    rr_d( "wings_round" );
    level.rr_wings_round_drops = 0;
    level.rr_wings_reward_round = 0;
    level.rr_wings_reward_dropping = 0;
    if ( isdefined( params ) && isdefined( params.roundendrewardlist ) )
    {
        foreach ( rer in params.roundendrewardlist )
        {
            if ( isdefined( rer ) && rer.rewardtype === #"hash_f2ed8a54cbe19f9b" )
            {
                level.rr_wings_reward_round = 1;   // ends with a power-up reward (max ammo)
            }
        }
    }
    if ( rr_wings_on() && level.rr_wings_reward_round )
    {
        rr_wings_debug( "max ammo round: only the end-of-round max ammo" );
    }
}

function private rr_wings_on_last_ai_killed( params )
{
    if ( !rr_wings_on() || rr_wings_boss_active() )
    {
        return;
    }
    if ( level.rr_wings_reward_round )
    {
        // The game drops the max ammo right after this; mark it so the
        // listener leaves it out of the cycle.
        level.rr_wings_reward_dropping = 1;
        return;
    }
    if ( level.rr_wings_guarantee < 1 || level.rr_wings_round_drops > 0 )
    {
        return;
    }
    level thread rr_wings_guaranteed_drop( params );
}

// No power-up this round yet: the last zombie drops the next one in the cycle.
function private rr_wings_guaranteed_drop( params )
{
    rr_d( "wings_lastzombie" );
    level endon( #"game_ended" );
    pos = undefined;
    if ( isdefined( params ) && isdefined( params.ai ) )
    {
        pos = params.ai.nonfloatingorigin ?? params.ai.origin;
    }
    if ( !isdefined( pos ) && isdefined( params ) && isdefined( params.attacker ) && isplayer( params.attacker ) )
    {
        pos = params.attacker.origin + anglestoforward( params.attacker.angles ) * 100;
    }
    if ( !isdefined( pos ) && isdefined( level.players ) && isdefined( level.players[ 0 ] ) )
    {
        pos = level.players[ 0 ].origin + anglestoforward( level.players[ 0 ].angles ) * 100;
    }
    if ( !isdefined( pos ) )
    {
        return;
    }
    nav = getclosestpointonnavmesh( pos );
    if ( isdefined( nav ) )
    {
        pos = nav;
    }

    // v7.1: the next power-up in the game's own cycle.
    ref = rr_wings_cycle_next();
    if ( !isdefined( ref ) )
    {
        return;
    }

    height = 0;
    if ( isdefined( level.powerups_root ) && isdefined( level.powerups_root.powerup_vars ) )
    {
        height = level.powerups_root.powerup_vars[ "drop_height_offset" ] ?? 0;
    }
    if ( utility::issharedfuncdefined( #"powerups", #"droppowerup" ) )
    {
        rr_wings_debug( "no drop this round: last zombie drops " + ref );
        level.rr_wings_forcing = ref;
        level utility::callsharedfunc( #"powerups", #"droppowerup", ref, pos + ( 0, 0, height ) );
    }
}

function private rr_wings_debug( text )
{
    rr_ev( "Wings: " + text );
    if ( level.gsr_debug < 1 || !isdefined( level.players ) )
    {
        return;
    }
    foreach ( p in level.players )
    {
        if ( isdefined( p ) )
        {
            p iprintln( "^5[Relic Rebalance] ^7Dragon Wings: " + text );
        }
    }
}

// =====================================================================
// v2.9: ROCKET  (scorestreaks from loot; crafting only map exceptions)
// =====================================================================

function private rr_rocket_relic_on()
{
    mm = level.zm_mode_modifiers;
    if ( !isdefined( mm ) || !isdefined( mm.var_1339a4e02399cb52 ) )
    {
        return false;
    }
    return istrue( mm.var_1339a4e02399cb52[ #"killstreak" ] );
}

function private rr_rocket_watch()
{
    level endon( #"game_ended" );
    while ( true )
    {
        if ( level.rr_rocket >= 1 && rr_rocket_relic_on() )
        {
            if ( !istrue( level.rr_rocket_undone ) )
            {
                // Loot pool: stop rejecting scorestreaks from drop lists...
                level callback::remove( #"hash_8e2728470d1fa87a", &zombie_mode_modifiers::function_55d3d1d98d7e61a2 );
                // ...and stop deleting the ones that spawn in the world.
                common_item::function_134b9624f3886a06( "killstreak", &zombie_mode_modifiers::on_item_spawned_killstreak );
                level.rr_rocket_undone = 1;
                rr_rocket_debug( "scorestreaks back in the loot pool" );
            }
            // v4.4: ui_show_killstreaks controls BOTH the scorestreak HUD and
            // the scorestreaks in the crafting table list. Keep it off (stock
            // relic) while anyone is at a crafting table, so the list stays
            // hidden; on everywhere else so the HUD shows streaks you pick up.
            // Items without the scorestreak flag (Totenreich's Glocke and
            // Wunderbarrage) still show in the list, as with the stock relic.
            want = 1;
            if ( rr_rocket_near_crafting() )
            {
                want = 0;
            }
            if ( !isdefined( level.rr_rocket_hud_state ) || level.rr_rocket_hud_state != want )
            {
                rr_ev( "Rocket: scorestreak HUD " + want );
                setomnvar( "ui_show_killstreaks", want );
                level.rr_rocket_hud_state = want;
            }
            // Crafting table: wrap its item filter for the map exceptions.
            if ( isdefined( level.var_71b6079fc23545cd ) && !( level.var_71b6079fc23545cd === &rr_rocket_craft_filter ) )
            {
                level.rr_rocket_orig_filter = level.var_71b6079fc23545cd;
                level.var_71b6079fc23545cd = &rr_rocket_craft_filter;
            }
        }
        wait 0.1;
    }
}

// True while any player is at (or using) a crafting table.
function private rr_rocket_near_crafting()
{
    rr_d( "rocket_near" );
    if ( !isdefined( level.players ) )
    {
        return false;
    }
    foreach ( p in level.players )
    {
        if ( !isdefined( p ) || !isalive( p ) )
        {
            continue;
        }
        if ( isdefined( p.crafting_table_active ) )
        {
            return true;
        }
        if ( isdefined( level.a_s_crafting_tables ) )
        {
            foreach ( t in level.a_s_crafting_tables )
            {
                if ( isdefined( t ) && isdefined( t.model_table ) && distancesquared( p.origin, t.model_table.origin ) < level.rr_rocket_craft_radius * level.rr_rocket_craft_radius )
                {
                    return true;
                }
            }
        }
    }
    return false;
}

function private rr_rocket_is_exception( itemref )
{
    if ( !isdefined( itemref ) )
    {
        return false;
    }
    foreach ( ok in level.rr_rocket_craft_ok )
    {
        if ( isstring( itemref ) )
        {
            if ( tolower( itemref ) == ok )
            {
                return true;
            }
        }
        else if ( itemref == getxhashasset( ok ) || itemref == getxhash( ok ) )
        {
            return true;
        }
    }
    return false;
}

// Same signature as zombie_mode_modifiers::function_a35b515309ed4c69.
// Keeps every stock ban, except that the listed map scorestreaks are let
// through the "no scorestreaks" type ban (never through an item banned by
// name).
function rr_rocket_craft_filter( s_item, current_response )
{
    rr_d( "rocket_craft" );
    allowed = 1;
    if ( isdefined( level.rr_rocket_orig_filter ) )
    {
        allowed = self [[ level.rr_rocket_orig_filter ]]( s_item, current_response );
    }
    if ( istrue( allowed ) || level.rr_rocket < 1 || !rr_rocket_relic_on() || !isdefined( s_item ) )
    {
        return allowed;
    }
    if ( !rr_rocket_is_exception( s_item.itemref ) )
    {
        return allowed;
    }
    mm = level.zm_mode_modifiers;
    if ( isdefined( mm.var_24a8fa99110eda39 ) && istrue( mm.var_24a8fa99110eda39[ getxhashasset( s_item.itemref ) ] ) )
    {
        return allowed;   // banned by name by something else: keep it banned
    }
    return true;
}

function private rr_rocket_debug( text )
{
    rr_ev( "Rocket: " + text );
    if ( level.gsr_debug < 1 || !isdefined( level.players ) )
    {
        return;
    }
    foreach ( p in level.players )
    {
        if ( isdefined( p ) )
        {
            p iprintln( "^5[Relic Rebalance] ^7Rocket: " + text );
        }
    }
}

// =====================================================================
// v3.0: POWER SWITCH  (equipment only switches within its own rarity)
// =====================================================================

function rr_ps_item( ref, rarity )
{
    return { #ref:ref, #rarity:rarity };
}

// Takes over from the relic: its own round-end switch is turned off and
// this mod does the switch instead.
function private rr_ps_watch()
{
    level endon( #"game_ended" );
    while ( true )
    {
        mm = level.zm_mode_modifiers;
        if ( isdefined( mm ) && istrue( mm.var_d3644cfcd25048c2 ) && level.rr_power_switch >= 1 )
        {
            mm.var_d3644cfcd25048c2 = 0;
            level.rr_ps_active = 1;
            rr_ps_debug( "active" );
        }
        wait 0.5;
    }
}

function private rr_ps_on_round_end( params )
{
    rr_ev( "round end" );
    if ( level.rr_power_switch < 1 || !istrue( level.rr_ps_active ) )
    {
        return;
    }
    if ( !isdefined( params ) || !isdefined( params.roundnumber ) || params.roundnumber < 1 || istrue( level.scripted_pause_round_logic ) )
    {
        return;
    }
    if ( isdefined( level.players ) && isdefined( level.players[ 0 ] ) )
    {
        level.players[ 0 ] playsoundtoteam( "evt_plr_oob_impact_laugh", "allies" );   // stock relic cue
    }
    foreach ( player in level.players )
    {
        if ( isdefined( player ) )
        {
            player thread rr_ps_switch_player();
        }
    }
}

function private rr_ps_find( pool, ref )
{
    foreach ( e in pool )
    {
        if ( e.ref == ref )
        {
            return e;
        }
    }
    return undefined;
}

// A different item of the same rarity from the pool (equal chance each).
function private rr_ps_pick( pool, current )
{
    rarity = undefined;
    e = rr_ps_find( pool, current );
    if ( isdefined( e ) )
    {
        rarity = e.rarity;
    }
    else if ( isdefined( level.rr_ps_other_rarity[ current ] ) )
    {
        rarity = level.rr_ps_other_rarity[ current ];
    }
    else
    {
        rarity = 2;
    }

    options = [];
    foreach ( item in pool )
    {
        if ( item.rarity == rarity && item.ref != current )
        {
            options[ options.size ] = item.ref;
        }
    }
    if ( options.size == 0 )
    {
        return undefined;   // nothing else in that rarity: keep it
    }
    return options[ randomint( options.size ) ];
}

function private rr_ps_never_switch( ref )
{
    mm = level.zm_mode_modifiers;
    if ( isdefined( mm ) && isdefined( mm.var_346079b6c9b0a9c6 ) && isdefined( mm.var_346079b6c9b0a9c6.var_783b84ee4ce237e3 ) )
    {
        return arraycontains( mm.var_346079b6c9b0a9c6.var_783b84ee4ce237e3, ref );
    }
    exclusions = [ "equip_europa_remote_control", "equip_decoy_trinket_sat_zm", "equip_attractor", "equip_grappling_hook", "equip_grappling_hook_dreadspinner_ee_sat", "equip_grappling_hook_upgraded_sat" ];
    return arraycontains( exclusions, ref );
}

function private rr_ps_switch_slot( slot, pool )
{
    current = self equipment_mp::getcurrentequipment( slot );
    if ( !isdefined( current ) )
    {
        return;
    }
    never = rr_ps_never_switch( current );
    if ( istrue( never ) )
    {
        return;
    }
    new_ref = rr_ps_pick( pool, current );
    if ( !isdefined( new_ref ) )
    {
        return;
    }

    // v8.0: what you had, if it can be read in this build...
    ammo = self rr_ps_count( current, slot );
    // ...and the new item's max (this read works: equipment_mp's max).
    gamemax = self equipment_mp::getequipmentmaxammo( new_ref, undefined, slot );

    newammo = 1;
    how = "full";
    if ( isdefined( ammo ) && ammo > 0 )
    {
        newammo = ammo;   // you keep exactly this many
        how = "kept";
    }
    else if ( isdefined( gamemax ) && gamemax > 0 )
    {
        newammo = gamemax;   // count not readable: the new item's full amount
    }
    hudmax = newammo;
    if ( isdefined( gamemax ) && gamemax > hudmax )
    {
        hudmax = gamemax;
    }

    self equipment_mp::giveequipment( new_ref, slot );
    waitframe();
    waitframe();
    // The game's own setter, given a real number (the stock relic gave it
    // the failed read, so the item kept its default of 1).
    self equipment_mp::setequipmentammo( new_ref, newammo );
    self rr_ps_hud( slot, newammo, hudmax );

    // Set it again twice so nothing that runs after the swap can undo it.
    delays = [ 0.5, 1.0 ];
    foreach ( d in delays )
    {
        wait d;
        if ( !isdefined( self ) )
        {
            return;
        }
        now_ref = self equipment_mp::getcurrentequipment( slot );
        if ( !( now_ref === new_ref ) )
        {
            return;   // you changed equipment yourself
        }
        self equipment_mp::setequipmentammo( new_ref, newammo );
        self rr_ps_hud( slot, newammo, hudmax );
    }
    had = "?";
    if ( isdefined( ammo ) && ammo > 0 )
    {
        had = ammo;
    }
    self rr_ps_debug( "had " + had + " " + rr_ps_name( current ) + ", gave " + newammo + " " + rr_ps_name( new_ref ) + " (" + how + ")" );
}

// v7.0: readable item names for the Power Switch line.
function private rr_ps_name( ref )
{
    switch ( ref )
    {
        case "equip_frag": return "Frag";
        case "equip_semtex": return "Semtex";
        case "equip_c4": return "C4";
        case "equip_molotov": return "Molotov";
        case "equip_combataxe": return "Combat Axe";
        case "equip_cluster_grenade": return "Cluster Grenade";
        case "equip_thermobaric_grenade": return "Thermobaric";
        case "equip_impact_grenade": return "Impact Grenade";
        case "equip_mini_sentry": return "Mini Sentry";
        case "equip_concussion": return "Stun Grenade";
        case "equip_adrenaline": return "Stim Shot";
        case "equip_decoy": return "Decoy";
        case "equip_shockstick": return "Shock Charge";
        case "equip_blackhole_bomb": return "Kazimir";
        case "equip_monkey_bomb": return "Monkey Bomb";
        case "equip_gas_grenade": return "Psych Grenade";
    }
    return "" + ref;
}

// v7.5: the equipment weapon for ref, found the way the game's own
// setequipmentammo finds it: walk your offhand weapons and match by name.
// Each step is its own small function: if one errors in this build, the
// caller just gets nothing back and tries the next way.
function private rr_ps_weapon( ref, slot )
{
    w = self rr_ps_weapon_offhand( ref );
    if ( isdefined( w ) )
    {
        level.rr_ps_src = "offhand";
        return w;
    }
    w = self rr_ps_weapon_table( ref );
    if ( isdefined( w ) )
    {
        level.rr_ps_src = "table";
        return w;
    }
    w = self rr_ps_weapon_slot( slot );
    if ( isdefined( w ) )
    {
        level.rr_ps_src = "slot";
        return w;
    }
    level.rr_ps_src = "none";
    return undefined;
}

// v7.7: the item's plain table weapon - what the game's own count read
// (equipment_mp::getequipmentammo) is built on, minus its failing step.
function private rr_ps_weapon_table( ref )
{
    info = equipment_mp::getequipmenttableinfo( ref );
    if ( !isdefined( info ) )
    {
        return undefined;
    }
    return info.objweapon;
}

function private rr_ps_weapon_offhand( ref )
{
    list = self getweaponslistoffhands();
    if ( !isdefined( list ) )
    {
        return undefined;
    }
    foreach ( w in list )
    {
        if ( !isdefined( w ) )
        {
            continue;
        }
        if ( self rr_ps_matches( w, ref ) )
        {
            return w;
        }
    }
    return undefined;
}

function private rr_ps_matches( w, ref )
{
    // v7.8: compare names directly (a weapon name can't be turned into
    // text in this build - that made every match fail).
    info = equipment_mp::getequipmenttableinfo( ref );
    if ( isdefined( info ) && isdefined( info.objweapon ) && info.objweapon.basename == w.basename )
    {
        return true;
    }
    r = equipment_mp::getequipmentreffromweaponname( w.basename );
    return isdefined( r ) && r == ref;
}

// v7.6 TEST: every offhand weapon you hold, with its clip and total ammo.
function private rr_ps_offhand_list()
{
    list = self getweaponslistoffhands();
    if ( !isdefined( list ) )
    {
        return "no offhand list";
    }
    out = "";
    idx = 0;
    foreach ( w in list )
    {
        if ( !isdefined( w ) )
        {
            continue;
        }
        c = self rr_ps_clip( w );
        t = self rr_ps_total( w );
        if ( !isdefined( c ) )
        {
            c = "x";
        }
        if ( !isdefined( t ) )
        {
            t = "x";
        }
        idx = idx + 1;
        out = out + "#" + idx + "=" + c + "/" + t + " ";
    }
    if ( out == "" )
    {
        out = "empty";
    }
    return out;
}

function private rr_ps_weapon_slot( slot )
{
    if ( !isdefined( self.equipmentweaponobjs ) )
    {
        return undefined;
    }
    return self.equipmentweaponobjs[ slot ];
}

function private rr_ps_clip( w )
{
    return self getweaponammoclip( w );
}

function private rr_ps_total( w )
{
    return self getammocount( w );
}

// How many of ref you hold (-1 = could not read).
function private rr_ps_count( ref, slot )
{
    w = self rr_ps_weapon( ref, slot );
    if ( !isdefined( w ) )
    {
        return -1;
    }
    // The game reads the total (getammocount), so that first.
    n = self rr_ps_total( w );
    if ( isdefined( n ) && n > 0 )
    {
        return n;
    }
    c = self rr_ps_clip( w );
    if ( isdefined( c ) && c > 0 )
    {
        level.rr_ps_src = level.rr_ps_src + "/clip";
        return c;
    }
    // Same as the game: if that weapon says 0, look for the held copy.
    if ( isdefined( self.offhandinventory ) )
    {
        foreach ( h in self.offhandinventory )
        {
            if ( isdefined( h ) && isdefined( w.basename ) && h.basename == w.basename )
            {
                m = self rr_ps_total( h );
                if ( isdefined( m ) && m > 0 )
                {
                    level.rr_ps_src = level.rr_ps_src + "/held";
                    return m;
                }
            }
        }
    }
    if ( isdefined( n ) )
    {
        return n;
    }
    if ( isdefined( c ) )
    {
        return c;
    }
    return -1;
}

function private rr_ps_hud( slot, count, maxammo )
{
    if ( slot == "primary" )
    {
        self setclientomnvar( "ui_power_num_charges", count );
        if ( self hasclientomnvar( "ui_power_max_charges" ) )
        {
            self setclientomnvar( "ui_power_max_charges", maxammo );
        }
        self setpowerammo( "primary", count, maxammo );
    }
    else if ( slot == "secondary" )
    {
        self setclientomnvar( "ui_power_secondary_num_charges", count );
        if ( self hasclientomnvar( "ui_power_secondary_max_charges" ) )
        {
            self setclientomnvar( "ui_power_secondary_max_charges", maxammo );
        }
        self setpowerammo( "secondary", count, maxammo );
    }
}

// Sets ref's count on its weapon and updates the HUD.
function private rr_ps_set( ref, slot, count )
{
    w = self rr_ps_weapon( ref, slot );
    if ( !isdefined( w ) )
    {
        return;
    }
    self setweaponammoclip( w, count );
    maxammo = self equipment_mp::getequipmentmaxammo( ref, undefined, slot );
    if ( !isdefined( maxammo ) || maxammo < count )
    {
        maxammo = count;
    }
    self rr_ps_hud( slot, count, maxammo );
}

function private rr_ps_switch_player()
{
    rr_d( "pswitch" );
    self endon( #"disconnect" );
    self notify( #"rr_ps_switch" );
    self endon( #"rr_ps_switch" );
    // Same guards the stock relic uses while it swaps.
    self.crafting_table_disabled = 1;
    self.interactions_disabled = 1;
    val::set( "modifier_equipment_carousel", "disallow_loot_but_auto_loot", 1 );

    self rr_ps_switch_slot( "primary", level.rr_ps_lethals );
    self rr_ps_switch_slot( "secondary", level.rr_ps_tacticals );

    self.crafting_table_disabled = 0;
    self.interactions_disabled = 0;
    val::reset( "modifier_equipment_carousel", "disallow_loot_but_auto_loot" );
}

function private rr_ps_debug( text )
{
    rr_ev( "PowerSwitch: " + text );
    if ( level.rr_ps_print >= 1 && !( level.rr_test_print >= 1 ) && isplayer( self ) )
    {
        self iprintln( "^5[Power Switch] ^7" + text );
    }
    if ( level.gsr_debug < 1 || !isdefined( level.players ) )
    {
        return;
    }
    foreach ( p in level.players )
    {
        if ( isdefined( p ) )
        {
            p iprintln( "^5[Relic Rebalance] ^7Power Switch: " + text );
        }
    }
}

// =====================================================================
// v3.1: GRAMOPHONE  (extra ammo cost on every weapon, double damage)
// =====================================================================

function private rr_gramo_relic_on()
{
    mm = level.zm_mode_modifiers;
    return isdefined( mm ) && istrue( mm.var_ac12b3bfd707875b );
}

function private rr_gramo_watch()
{
    level endon( #"game_ended" );
    while ( true )
    {
        if ( level.rr_gramophone >= 1 && rr_gramo_relic_on() )
        {
            if ( !istrue( level.rr_gramo_hooked ) )
            {
                // Stop the stock per-bullet charge; this mod charges every
                // weapon from "weapon_fired" instead (no double charge).
                level callback::remove( #"player_fired_shot", &zombie_mode_modifiers::add_extra_bullet );
                // Replace the stock +25% damage modifier with x2.
                zombie_mode_modifiers::function_9c9da0455f2c2a45( "extra_bullet_cost", &rr_gramo_damage );
                level.rr_gramo_hooked = 1;
                rr_gramo_debug( "active" );
            }
            if ( isdefined( level.players ) )
            {
                foreach ( p in level.players )
                {
                    if ( isdefined( p ) && !istrue( p.rr_gramo_watching ) )
                    {
                        p thread rr_gramo_fire_watch();
                    }
                }
            }
        }
        wait 0.5;
    }
}

// Damage modifier (same signature as the stock one). Every weapon, x2.
function rr_gramo_damage( dmg_struct )
{
    if ( !isdefined( dmg_struct.eattacker ) || !isplayer( dmg_struct.eattacker ) )
    {
        return dmg_struct.idamage;
    }
    return int( dmg_struct.idamage * level.rr_gramo_damage_mult );
}

function private rr_gramo_fire_watch()
{
    self endon( #"disconnect" );
    self.rr_gramo_watching = 1;
    while ( true )
    {
        self waittill( #"weapon_fired", weapon );
        if ( level.rr_gramophone < 1 || !rr_gramo_relic_on() )
        {
            continue;
        }
        if ( !isdefined( weapon ) || isnullweapon( weapon ) )
        {
            weapon = self getcurrentweapon();
        }
        if ( !isdefined( weapon ) || isnullweapon( weapon ) )
        {
            continue;
        }
        if ( weapon.basename == "sat_ww_ruby_zm" )
        {
            // Stock skips this one entirely; charge it here.
            self thread rr_gramo_charge_simple( weapon );
        }
        else
        {
            // Stock charge logic (dual wield, scorestreak guns, stock ammo).
            self thread zombie_mode_modifiers::add_extra_bullet( { #objweapon:weapon } );
        }
    }
}

function private rr_gramo_charge_simple( weapon )
{
    rr_d( "gramo_charge" );
    self endon( #"disconnect" );
    waitframe();
    extra = level.zm_mode_modifiers.extrabullets ?? 1;
    clip = self getweaponammoclip( weapon );
    if ( clip > 0 )
    {
        self addweaponammoclip( weapon, extra * -1 );
        return;
    }
    stock = self getweaponammostock( weapon );
    self setweaponammostock( weapon, int( max( stock - extra, 0 ) ) );
}

function private rr_gramo_debug( text )
{
    rr_ev( "Gramophone: " + text );
    if ( level.gsr_debug < 1 || !isdefined( level.players ) )
    {
        return;
    }
    foreach ( p in level.players )
    {
        if ( isdefined( p ) )
        {
            p iprintln( "^5[Relic Rebalance] ^7Gramophone: " + text );
        }
    }
}

// =====================================================================
// v3.2: VRILL SPHERE  (only machine perks count toward the 4 limit)
// =====================================================================

// Puts this mod's perk-limit tracker in place of the stock one.
function private rr_vrill_watch()
{
    level endon( #"game_ended" );
    while ( true )
    {
        if ( level.rr_vrill_sphere >= 1 )
        {
            current = undefined;
            if ( utility::issharedfuncdefined( #"zm_mode_modifiers", #"hash_6843c64da905f4f8" ) )
            {
                current = utility::getsharedfunc( #"zm_mode_modifiers", #"hash_6843c64da905f4f8" );
            }
            if ( isdefined( current ) && !( current === &rr_vrill_track ) )
            {
                utility::registersharedfunc( #"zm_mode_modifiers", #"hash_6843c64da905f4f8", &rr_vrill_track );
                rr_vrill_debug( "perk cans / free perks no longer count toward the limit" );
            }
        }
        wait 1;
    }
}

// Same signature as the stock tracker. self = player who just got the perk.
function rr_vrill_track( perk, bought, is_item_perk, is_special_returned )
{
    rr_d( "vrill_perk" );
    mm = level.zm_mode_modifiers;
    if ( !isdefined( mm ) || !istrue( mm.var_89fa68db4cdb1044 ) || !isdefined( mm.var_ea2b964809851284 ) )
    {
        return;
    }
    // Perk cans, Free Perk power-ups, any free perk, perks given back after
    // a revive: never counted, never taken.
    if ( istrue( is_item_perk ) || !istrue( bought ) || istrue( is_special_returned ) )
    {
        rr_vrill_debug( self.name + ": " + perk + " stacks (not counted)" );
        return;
    }

    limit = mm.var_ea2b964809851284.perklimitnum ?? 4;
    if ( !isdefined( self.var_9413068bac411438 ) )
    {
        self.var_9413068bac411438 = [];
    }

    // Forget counted perks the player no longer has (lost when downed...).
    kept = [];
    foreach ( p in self.var_9413068bac411438 )
    {
        if ( isdefined( p ) && isdefined( self.perks_active ) && arraycontains( self.perks_active, p ) && p != perk )
        {
            kept[ kept.size ] = p;
        }
    }
    kept[ kept.size ] = perk;

    // Past the limit: the oldest MACHINE perk goes, like stock.
    while ( kept.size > limit )
    {
        oldest = kept[ 0 ];
        new_list = [];
        for ( i = 1; i < kept.size; i++ )
        {
            new_list[ new_list.size ] = kept[ i ];
        }
        kept = new_list;
        rr_vrill_debug( self.name + ": over " + limit + " machine perks, losing " + oldest );
        self utility::callsharedfunc( #"zombie_perks", #"take_perk", oldest );
        waitframe();
    }
    self.var_9413068bac411438 = kept;
}

function private rr_vrill_debug( text )
{
    rr_ev( "Vrill: " + text );
    if ( level.gsr_debug < 1 || !isdefined( level.players ) )
    {
        return;
    }
    foreach ( p in level.players )
    {
        if ( isdefined( p ) )
        {
            p iprintln( "^5[Relic Rebalance] ^7Vrill Sphere: " + text );
        }
    }
}

// =====================================================================
// v3.3: STUFFED ELEPHANT  (regen delay 3 s instead of ~6)
// =====================================================================

// The modifier value that makes the relic's delay come out to the target.
// delay = base x ( 1 - modifier )  ->  modifier = 1 - target / base.
function private rr_elephant_value()
{
    rr_d( "elephant" );
    base = level.healthregendelayms;
    if ( !isdefined( base ) || base <= 0 )
    {
        return -1.1667;   // half of the stock -3.333 effect, if base unknown
    }
    value = 1.0 - ( level.rr_elephant_delay_seconds * 1000.0 ) / base;
    if ( value > 0 )
    {
        value = 0.0;   // never make regen faster than normal
    }
    return float( value );
}

function private rr_elephant_watch()
{
    level endon( #"game_ended" );
    key = getxhash( #"regen_delay_relics" );
    while ( true )
    {
        mm = level.zm_mode_modifiers;
        if ( level.rr_stuffed_elephant >= 1 && isdefined( mm ) && istrue( mm.var_fc36798e78798216 ) && isdefined( mm.regen_delay ) )
        {
            want = rr_elephant_value();
            // Players who spawn later get this value from the relic itself.
            if ( mm.regen_delay != want )
            {
                mm.regen_delay = want;
                rr_elephant_debug( "regen delay set to " + level.rr_elephant_delay_seconds + " s (modifier " + want + ")" );
            }
            if ( isdefined( level.players ) )
            {
                foreach ( p in level.players )
                {
                    if ( !isdefined( p ) || !isdefined( p.regendelaymodifiers ) || !isdefined( p.regendelaymodifiers[ key ] ) )
                    {
                        continue;
                    }
                    if ( p.regendelaymodifiers[ key ] != want )
                    {
                        // v5.6: the right remove (tryremovehealthregendelay clears a
                        // different list, so the add was refused and nothing changed).
                        p playerhealth::function_b1fb4d148779580e( #"regen_delay_relics" );
                        p playerhealth::function_fd91e6d94cab77e7( #"regen_delay_relics", want );
                        rr_elephant_debug( p.name + ": regen delay now " + level.rr_elephant_delay_seconds + " s" );
                    }
                }
            }
        }
        wait 0.5;
    }
}

function private rr_elephant_debug( text )
{
    rr_ev( "Elephant: " + text );
    if ( level.gsr_debug < 1 || !isdefined( level.players ) )
    {
        return;
    }
    foreach ( p in level.players )
    {
        if ( isdefined( p ) )
        {
            p iprintln( "^5[Relic Rebalance] ^7Stuffed Elephant: " + text );
        }
    }
}

// =====================================================================
// v3.4: VALKYRIE HELMET  (max 1 electric field per round since v6.1)
// =====================================================================

function private rr_valk_watch()
{
    level endon( #"game_ended" );
    level.rr_valk_round = -1;
    level.rr_valk_spawned = 0;
    was_warning = 0;
    warn_start = 0;
    far = ( 100000, 100000, 100000 );

    while ( true )
    {
        mm = level.zm_mode_modifiers;
        if ( level.rr_valkyrie_helmet < 1 || !isdefined( mm ) || !istrue( mm.var_d6f68a024fbc3ffe ) || !isdefined( level.players ) )
        {
            was_warning = 0;
            waitframe();
            continue;
        }

        round = zm_utility::get_round_number();
        if ( round != level.rr_valk_round )
        {
            level.rr_valk_round = round;
            level.rr_valk_spawned = 0;
        }

        warning = istrue( mm.electric_field_warning );

        if ( warning && !was_warning )
        {
            // A check is 5 s away: remember everyone's real "20 s ago" spot.
            foreach ( p in level.players )
            {
                if ( isdefined( p ) )
                {
                    p.rr_valk_real_prev = p.prev_electric_field_loc;
                    p.rr_valk_allowed = undefined;
                }
            }
            warn_start = gettime();
            // v5.2 diag (v8.0: only built when debugging is on - no text
            // is made on a timer otherwise)
            if ( level.rr_diag >= 1 || level.rr_test_print >= 1 )
            {
                note = "";
                foreach ( p in level.players )
                {
                    if ( isdefined( p ) && isdefined( p.rr_valk_real_prev ) )
                    {
                        note = " dist " + int( distance2d( p.origin, p.rr_valk_real_prev ) );
                    }
                }
                rr_ev( "Valk warn r" + round + " used " + level.rr_valk_spawned + "/" + level.rr_valk_max_per_round + note );
            }
        }

        if ( warning )
        {
            slots = level.rr_valk_max_per_round - level.rr_valk_spawned;
            allowed = 0;
            foreach ( p in level.players )
            {
                if ( !isdefined( p ) )
                {
                    continue;
                }
                in_range = isdefined( p.rr_valk_real_prev ) && isalive( p ) && distance2dsquared( p.origin, p.rr_valk_real_prev ) < level.rr_valk_radius * level.rr_valk_radius;
                if ( in_range && allowed < slots )
                {
                    allowed++;
                    p.rr_valk_allowed = 1;
                    if ( level.rr_valk_own_spawn >= 1 && gettime() >= warn_start + 4500 )
                    {
                        p.prev_electric_field_loc = far;   // v5.3: the mod spawns this one itself
                    }
                    else
                    {
                        p.prev_electric_field_loc = p.rr_valk_real_prev;   // warning fx (and stock spawn when own_spawn is 0)
                    }
                }
                else
                {
                    p.rr_valk_allowed = undefined;
                    if ( isdefined( p.rr_valk_real_prev ) )
                    {
                        p.prev_electric_field_loc = far;   // counts as moved: no field, no warning fx
                    }
                }
            }
        }
        else if ( was_warning )
        {
            // The game's check ran on this frame or the last one: count the
            // fields it was allowed to spawn.
            n = 0;
            foreach ( p in level.players )
            {
                if ( isdefined( p ) && istrue( p.rr_valk_allowed ) )
                {
                    if ( level.rr_valk_own_spawn >= 1 )
                    {
                        if ( rr_valk_can_spawn( p ) )
                        {
                            n++;
                            level thread rr_valk_field( p.origin );
                        }
                    }
                    else
                    {
                        n++;
                    }
                }
                if ( isdefined( p ) )
                {
                    p.rr_valk_allowed = undefined;
                    p.rr_valk_real_prev = undefined;
                }
            }
            level.rr_valk_spawned += n;
            if ( n > 0 )
            {
                rr_valk_debug( n + " field(s) this check, " + level.rr_valk_spawned + "/" + level.rr_valk_max_per_round + " this round" );
            }
            else
            {
                rr_ev( "Valk check: no field" );
            }
        }

        was_warning = warning;
        waitframe();
    }
}

// v5.3: same tests the game's check uses.
function private rr_valk_can_spawn( p )
{
    b = level.zm_relic_modifiers[ #"electric_fields" ];
    r = level.rr_valk_radius;
    if ( isdefined( b ) && isdefined( b.spawnradius ) )
    {
        r = b.spawnradius;
    }
    if ( !isdefined( p.rr_valk_real_prev ) || !isalive( p ) || istrue( p.electric_field_immune ) || !p val::get( "allow_movement" ) )
    {
        return false;
    }
    return distance2dsquared( p.origin, p.rr_valk_real_prev ) < r * r;
}

// v5.3: copy of the game's spawn_electric_field, with each step logged.
function private rr_valk_field( position )
{
    level endon( #"game_ended" );
    b = level.zm_relic_modifiers[ #"electric_fields" ];
    r = 300;
    first = 50;
    tick = 5;
    rate = 0.5;
    dur = 20;
    if ( isdefined( b ) )
    {
        r = b.damageradius ?? 300;
        first = b.electricfieldinitialdamage ?? 50;
        tick = b.electricfieldtickdamage ?? 5;
        rate = b.tickrate ?? 0.5;
        dur = b.electricfieldduration ?? 20;
    }
    rr_ev( "Valk field 1: effect" );
    field = spawnscriptable( %"zm_sat_hornet_relic_electricity", position );
    rr_ev( "Valk field 2: first hit" );
    rr_valk_field_hit( position, r, first );
    rr_ev( "Valk field 3: hit ok" );
    level thread rr_valk_field_ticks( field, position, r, tick, rate );
    level utility::waittill_notify_or_timeout( "cancel_all_electric_fields", dur );
    if ( isdefined( field ) )
    {
        field setscriptablepartstate( "explosion", "delete" );
        wait 1;
        if ( isdefined( field ) )
        {
            field freescriptable();
        }
    }
    rr_ev( "Valk field 5: removed" );
}

function private rr_valk_field_hit( position, r, dmg )
{
    players = getplayersinradius( position, r );
    foreach ( p in players )
    {
        if ( !isdefined( p ) || !isalive( p ) || istrue( p.electric_field_immune ) || istrue( p.var_d1c4c78b9fb7d153 ) )
        {
            continue;
        }
        if ( abs( position[ 2 ] - p.origin[ 2 ] ) > 100 || !p val::get( "allow_movement" ) )
        {
            continue;
        }
        p dodamage( dmg, p.origin, p, undefined, "MOD_ELEMENTAL_ELEC" );
    }
}

function private rr_valk_field_ticks( field, position, r, dmg, rate )
{
    level endon( #"game_ended" );
    wait rate;
    logged = 0;
    while ( isdefined( field ) )
    {
        mm = level.zm_mode_modifiers;
        if ( !isdefined( mm ) || !istrue( mm.var_d6f68a024fbc3ffe ) )
        {
            return;
        }
        rr_valk_field_hit( position, r, dmg );
        if ( !logged )
        {
            logged = 1;
            rr_ev( "Valk field 4: tick ok" );
        }
        wait rate;
    }
}

function private rr_valk_debug( text )
{
    rr_ev( "Valkyrie: " + text );
    if ( level.gsr_debug < 1 || !isdefined( level.players ) )
    {
        return;
    }
    foreach ( p in level.players )
    {
        if ( isdefined( p ) )
        {
            p iprintln( "^5[Relic Rebalance] ^7Valkyrie Helmet: " + text );
        }
    }
}

// =====================================================================
// v3.5: FILM REEL  (one max-PaP weapon; the rest one level below)
// =====================================================================

function private rr_film_max()
{
    return level.max_pack_a_punch_level ?? 3;
}

function private rr_film_watch()
{
    level endon( #"game_ended" );
    while ( true )
    {
        mm = level.zm_mode_modifiers;
        if ( level.rr_film_reel >= 1 && isdefined( mm ) && istrue( mm.var_63da2ef147f344a4 ) )
        {
            // The relic just switched on: turn the stock "one packed weapon"
            // rule off (its own disable function) and use this one instead.
            zombie_mode_modifiers::function_483ce4653e168eff();
            if ( !istrue( level.rr_film_active ) )
            {
                level.rr_film_active = 1;
                level callback::add( #"item_weapon_picked_up", &rr_film_on_pickup );
                rr_film_debug( "active (max PaP " + rr_film_max() + ")" );
            }
        }

        if ( istrue( level.rr_film_active ) && level.rr_film_reel >= 1 && isdefined( level.players ) )
        {
            foreach ( p in level.players )
            {
                if ( !isdefined( p ) )
                {
                    continue;
                }
                if ( !istrue( p.rr_film_cb ) )
                {
                    p callback::add( "zm_packed_weapon", &rr_film_on_packed );
                    p.rr_film_cb = 1;
                }
                // Safety net (max level changed, weapon given by a script...).
                if ( isalive( p ) && !istrue( p.rr_film_busy ) )
                {
                    p thread rr_film_enforce( undefined );
                }
            }
        }
        wait 1;
    }
}

function private rr_film_on_packed( params )
{
    if ( level.rr_film_reel < 1 || !istrue( level.rr_film_active ) || istrue( self.rr_film_demoting ) )
    {
        return;
    }
    keep = undefined;
    if ( isdefined( params ) && isdefined( params.w_new ) )
    {
        keep = params.w_new;
    }
    self thread rr_film_enforce( keep );
}

function private rr_film_on_pickup( params )
{
    if ( level.rr_film_reel < 1 || !istrue( level.rr_film_active ) || !isplayer( self ) )
    {
        return;
    }
    keep = undefined;
    if ( isdefined( params ) && isdefined( params.newweaponobj ) )
    {
        keep = params.newweaponobj;
    }
    self thread rr_film_enforce( keep );
}

function private rr_film_level( weapon )
{
    lvl = self utility::callsharedfunc( #"pack_a_punch", #"get_pap_level", weapon );
    if ( !isdefined( lvl ) )
    {
        lvl = 0;
    }
    return lvl;
}

// Keeps one weapon at max PaP (the one just packed / picked up, else the
// one in hand, else the first), and re-packs every other max weapon one
// level lower.
function private rr_film_enforce( keep )
{
    rr_d( "film" );
    self endon( #"disconnect" );
    if ( istrue( self.rr_film_busy ) )
    {
        return;
    }
    self.rr_film_busy = 1;
    wait 0.25;   // let the pack / pickup finish

    m = rr_film_max();
    full = [];
    foreach ( w in self getweaponslist( "primary" ) )
    {
        if ( isdefined( w ) && !isnullweapon( w ) && self rr_film_level( w ) >= m )
        {
            full[ full.size ] = w;
        }
    }

    if ( full.size > 1 )
    {
        keeper = undefined;
        if ( isdefined( keep ) )
        {
            foreach ( w in full )
            {
                if ( w.basename == keep.basename )
                {
                    keeper = w;
                    break;
                }
            }
        }
        if ( !isdefined( keeper ) )
        {
            current = self getcurrentweapon();
            foreach ( w in full )
            {
                if ( isdefined( current ) && w.basename == current.basename )
                {
                    keeper = w;
                    break;
                }
            }
        }
        if ( !isdefined( keeper ) )
        {
            keeper = full[ 0 ];
        }

        foreach ( w in full )
        {
            if ( w == keeper )
            {
                continue;
            }
            lvl = self rr_film_level( w );
            rr_film_debug( self.name + ": " + w.basename + " PaP " + lvl + " -> " + ( m - 1 ) + " (only one PaP " + m + ")" );
            self.rr_film_demoting = 1;
            // pap_weapon( weapon, current level, cost, _, currency,
            //             switch to it, packed by augment, target level )
            self utility::callsharedfunc( #"pack_a_punch", #"pap_weapon", w, lvl, 0, undefined, undefined, 0, 1, m - 1 );
            self.rr_film_demoting = undefined;
            waitframe();
        }
        utility::callsharedfunc( #"pack_a_punch", #"update_pap_level_hud" );
    }
    self.rr_film_busy = undefined;
}

function private rr_film_debug( text )
{
    rr_ev( "FilmReel: " + text );
    if ( level.gsr_debug < 1 || !isdefined( level.players ) )
    {
        return;
    }
    foreach ( p in level.players )
    {
        if ( isdefined( p ) )
        {
            p iprintln( "^5[Relic Rebalance] ^7Film Reel: " + text );
        }
    }
}

// =====================================================================
// v3.6: BLOOD VIALS  (augments shuffled once in-match, loadout untouched)
// =====================================================================

function private rr_bv_watch()
{
    level endon( #"game_ended" );
    while ( true )
    {
        mm = level.zm_mode_modifiers;
        if ( level.rr_blood_vials >= 1 && isdefined( mm ) && istrue( mm.zmmodenoaugments ) )
        {
            // Stop the relic from wiping augments: flag off (spawns stop
            // wiping) and its 30 s wipe loop ended (it ends on this notify).
            mm.zmmodenoaugments = 0;
            level notify( #"hash_5f4b5f62807cae10" );
            level.rr_bv_active = 1;
            rr_bv_debug( "active: augments will be shuffled" );
        }
        if ( istrue( level.rr_bv_active ) && level.rr_blood_vials >= 1 && isdefined( level.players ) )
        {
            foreach ( p in level.players )
            {
                if ( isdefined( p ) && !istrue( p.rr_bv_started ) )
                {
                    p.rr_bv_started = 1;
                    p thread rr_bv_shuffle_player();
                }
            }
        }
        wait 0.25;
    }
}

// All usable augments of one type, major or minor (no bonus-slot unlocks).
function private rr_bv_candidates( type, want_major )
{
    list = [];
    if ( !isdefined( level.zombie_augments ) )
    {
        return list;
    }
    foreach ( name, bundle in level.zombie_augments )
    {
        if ( !isdefined( bundle ) || !isdefined( bundle.augmenttype ) || bundle.augmenttype != type )
        {
            continue;
        }
        if ( istrue( bundle.var_2012f7482a2d1b2d ) )
        {
            continue;   // "bonus minor slot" unlock, not a real augment
        }
        if ( istrue( bundle.ismajor ) != want_major )
        {
            continue;
        }
        list[ list.size ] = name;
    }
    return list;
}

function private rr_bv_pick( list, current )
{
    if ( list.size == 0 )
    {
        return undefined;
    }
    options = [];
    foreach ( n in list )
    {
        if ( !( n === current ) )
        {
            options[ options.size ] = n;
        }
    }
    if ( options.size == 0 )
    {
        options = list;
    }
    return options[ randomint( options.size ) ];
}

// Once per player per match, after their loadout augments are in.
function private rr_bv_shuffle_player()
{
    rr_d( "vials" );
    self endon( #"disconnect" );
    level endon( #"game_ended" );

    // Wait for the loadout augments to be given (or up to ~10 s).
    for ( i = 0; i < 40; i++ )
    {
        if ( isdefined( self.zombie_augments ) && self.zombie_augments.size > 0 && !self utility::ent_flag( "loadout_augments_setup_in_progress" ) )
        {
            break;
        }
        wait 0.25;
    }
    wait 0.5;
    if ( !isdefined( self.zombie_augments ) || !utility::issharedfuncdefined( #"zombie", #"give_player_augment" ) )
    {
        return;
    }

    changed = 0;
    picks = [];
    types = getarraykeys( self.zombie_augments );
    foreach ( type in types )
    {
        slot = self.zombie_augments[ type ];
        if ( !isdefined( type ) || !isdefined( slot ) )
        {
            continue;
        }
        // v7.8: always give a fresh slot marked augments_erased. The relic's
        // own wipe loop (2 s, first 30 s of the match) skips slots with that
        // mark, so the new augments are never wiped again. Nothing else in
        // the game reads the mark.
        fresh = spawnstruct();
        fresh.majorname = "none";
        fresh.minorname = "none";
        fresh.bonusmajoraugments = [];
        fresh.bonusminoraugments = [];
        if ( !istrue( slot.augments_erased ) )
        {
            if ( isdefined( slot.majorname ) )
            {
                fresh.majorname = slot.majorname;
            }
            if ( isdefined( slot.minorname ) )
            {
                fresh.minorname = slot.minorname;
            }
            if ( isdefined( slot.bonusmajoraugments ) )
            {
                fresh.bonusmajoraugments = slot.bonusmajoraugments;
            }
            if ( isdefined( slot.bonusminoraugments ) )
            {
                fresh.bonusminoraugments = slot.bonusminoraugments;
            }
        }
        fresh.augments_erased = 1;
        self.zombie_augments[ type ] = fresh;
        slot = fresh;

        major = rr_bv_pick( rr_bv_candidates( type, 1 ), slot.majorname );
        minor = rr_bv_pick( rr_bv_candidates( type, 0 ), slot.minorname );
        if ( isdefined( major ) )
        {
            self utility::callsharedfunc( #"zombie", #"give_player_augment", major, 0, #"rr_blood_vials" );
            picks[ picks.size ] = major;
            changed++;
        }
        if ( isdefined( minor ) )
        {
            self utility::callsharedfunc( #"zombie", #"give_player_augment", minor, 0, #"rr_blood_vials" );
            picks[ picks.size ] = minor;
            changed++;
        }
    }
    rr_bv_debug( self.name + ": " + changed + " augment slot(s) shuffled" );

    // v7.8 backstop: for 40 s, if anything still clears a slot, give the
    // pick back (the stock relic also wipes ~2 s after a spawn).
    for ( t = 0; t < 20; t++ )
    {
        wait 2;
        foreach ( a in picks )
        {
            b = level.zombie_augments[ a ];
            if ( !isdefined( b ) || !isdefined( self.zombie_augments ) )
            {
                continue;
            }
            cur = self.zombie_augments[ b.augmenttype ];
            if ( !isdefined( cur ) )
            {
                continue;
            }
            have = cur.minorname;
            if ( istrue( b.ismajor ) )
            {
                have = cur.majorname;
            }
            if ( !( have === a ) )
            {
                if ( !istrue( cur.augments_erased ) )
                {
                    cur.augments_erased = 1;
                }
                self utility::callsharedfunc( #"zombie", #"give_player_augment", a, 0, #"rr_blood_vials" );
            }
        }
    }
}

function private rr_bv_debug( text )
{
    rr_ev( "BloodVials: " + text );
    if ( level.gsr_debug < 1 || !isdefined( level.players ) )
    {
        return;
    }
    foreach ( p in level.players )
    {
        if ( isdefined( p ) )
        {
            p iprintln( "^5[Relic Rebalance] ^7Blood Vials: " + text );
        }
    }
}

// =====================================================================
// v3.7: CIVIL PROTECTOR HEAD  (lose a perk every 350 kills)
// =====================================================================

function private rr_cph_watch()
{
    level endon( #"game_ended" );
    while ( true )
    {
        if ( level.rr_civil_protector >= 1 && isdefined( level.zm_relic_modifiers ) )
        {
            relic = level.zm_relic_modifiers[ #"hash_3385fa4802fa103e" ];
            if ( isdefined( relic ) && !( relic.var_c7936ba2a928b771 === level.rr_cph_kills ) )
            {
                relic.var_c7936ba2a928b771 = level.rr_cph_kills;
                if ( level.gsr_debug >= 1 && isdefined( level.players ) )
                {
                    foreach ( p in level.players )
                    {
                        if ( isdefined( p ) )
                        {
                            p iprintln( "^5[Relic Rebalance] ^7Civil Protector Head: a perk every " + level.rr_cph_kills + " kills" );
                        }
                    }
                }
            }
        }
        wait 1;
    }
}

// =====================================================================
// v3.8: MANGLER HELMET  (Ultra tools / PaP 4 crystals in the loot pool)
// =====================================================================

function private rr_mh_on()
{
    mm = level.zm_mode_modifiers;
    return level.rr_mangler_helmet >= 1 && isdefined( mm ) && istrue( mm.zmmodenoarsenal );
}

// Cursed Reimagined's "no Aether Tools" rule (and its other rules) set
// these when they install; if any is set, never create an aether tool.
function private rr_mh_cr_blocks_tools()
{
    return istrue( level.cursed_damage_tier_hooked ) || istrue( level.cursed_arsenal_prompt_watch ) || istrue( level.cursed_classic_knife_check_wrapped );
}

function private rr_mh_watch()
{
    level endon( #"game_ended" );
    while ( !rr_mh_on() )
    {
        wait 1;
    }
    // Hook the two items by name as they spawn in the world.
    common_item::function_c7bbbfcefe78f798( "t10_aethertool4", &rr_mh_on_tool4_spawned );
    common_item::function_c7bbbfcefe78f798( "t10_aethercrystal3", &rr_mh_on_crystal3_spawned );
    rr_mh_debug( "active" );
}

function private rr_mh_should_swap()
{
    if ( zm_utility::get_round_number() >= level.rr_mh_full_swap_round )
    {
        return true;
    }
    return randomint( 100 ) < level.rr_mh_upgrade_chance;
}

function rr_mh_on_tool4_spawned( params )
{
    if ( !rr_mh_on() || rr_mh_cr_blocks_tools() )
    {
        return;
    }
    level thread rr_mh_swap( params, %"zmloot_aether_tool_5", "Legendary tool -> Ultra tool" );
}

function rr_mh_on_crystal3_spawned( params )
{
    if ( !rr_mh_on() )
    {
        return;
    }
    level thread rr_mh_swap( params, %"zmloot_aether_crystal_4", "PaP 3 crystal -> PaP 4 crystal" );
}

function private rr_mh_swap( params, new_scriptable, label )
{
    rr_d( "mangler_swap" );
    waittillframeend();
    if ( !isdefined( params ) || !isdefined( params.item ) )
    {
        return;
    }
    item = params.item;
    // Leave items a player dropped and quest items alone.
    if ( istrue( item.quest_item ) )
    {
        return;
    }
    if ( isdefined( params.spawnoptions ) && isdefined( params.spawnoptions.spawningentity ) && isplayer( params.spawnoptions.spawningentity ) )
    {
        return;
    }
    if ( !rr_mh_should_swap() )
    {
        return;
    }
    origin = item.origin;
    angles = item.angles ?? ( 0, 0, 0 );
    if ( !isdefined( origin ) )
    {
        return;
    }
    common_item::items_scriptable_cleanup( item );
    common_item::items_spawnnewitemfromscriptable( new_scriptable, origin, angles );
    rr_mh_debug( label + " (round " + zm_utility::get_round_number() + ")" );
}

function private rr_mh_debug( text )
{
    rr_ev( "Mangler: " + text );
    if ( level.gsr_debug < 1 || !isdefined( level.players ) )
    {
        return;
    }
    foreach ( p in level.players )
    {
        if ( isdefined( p ) )
        {
            p iprintln( "^5[Relic Rebalance] ^7Mangler Helmet: " + text );
        }
    }
}

// =====================================================================
// v3.9: AGARTHAN DEVICE  (elemental every other round, no super sprint,
//                         no armored zombies on those rounds)
// =====================================================================

function private rr_ag_on()
{
    return level.rr_agarthan >= 1 && isdefined( level.zm_relic_modifiers ) && isdefined( level.zm_relic_modifiers[ #"elemental_base_zombies" ] );
}

// v4.8: the elemental type is the one the stock relic itself picked this
// round (its own round-start callback registers it before this runs), so
// it's always a type the map has. Agni / plain picks are swapped for an
// elemental type it picked on an earlier round. No engine lookups needed.
function private rr_ag_pick_type( rs )
{
    if ( !isdefined( level.rr_ag_seen ) )
    {
        level.rr_ag_seen = [];
    }
    pick = undefined;
    list = rs.aitypeoverridemap[ "zombie_base" ];
    if ( isdefined( list ) && isarray( list ) && list.size > 0 )
    {
        pick = list[ list.size - 1 ];
    }
    if ( isdefined( pick ) )
    {
        name = tolower( "" + pick );
        if ( name != "zombie_base" && !issubstr( name, "agni" ) && !issubstr( name, "armored" ) )
        {
            if ( !arraycontains( level.rr_ag_seen, pick ) )
            {
                level.rr_ag_seen[ level.rr_ag_seen.size ] = pick;
            }
            return pick;
        }
    }
    if ( level.rr_ag_seen.size > 0 )
    {
        return level.rr_ag_seen[ randomint( level.rr_ag_seen.size ) ];
    }
    return undefined;
}

function private rr_ag_on_round_start( params )
{
    if ( !rr_ag_on() )
    {
        return;
    }
    level thread rr_ag_apply_round();
}

// Runs right after the relic's own round-start pick and overrides it.
function private rr_ag_apply_round()
{
    rr_d( "agarthan_round" );
    level endon( #"game_ended" );
    waittillframeend();
    waitframe();
    if ( !isdefined( level.var_a009ab14ee0d3223 ) )
    {
        return;
    }
    rs = level.var_a009ab14ee0d3223;
    if ( !isdefined( rs.aitypeoverridemap ) )
    {
        rs.aitypeoverridemap = [];
    }
    round = zm_utility::get_round_number();
    armored = [ "zombie_base_armored_light", "zombie_base_armored_heavy", "zombie_base_armored_agni" ];
    type = undefined;
    if ( ( round % 2 ) == 0 )
    {
        type = rr_ag_pick_type( rs );
    }

    if ( ( round % 2 ) == 1 || !isdefined( type ) )
    {
        // Default round: normal zombies, armored back to normal.
        rs.aitypeoverridemap[ "zombie_base" ] = undefined;
        if ( istrue( level.rr_ag_armored_swapped ) )
        {
            foreach ( sub in armored )
            {
                rs.aitypeoverridemap[ sub ] = level.rr_ag_saved[ sub ];
            }
            level.rr_ag_armored_swapped = undefined;
        }
        level.rr_ag_type = undefined;
        rr_ag_debug( "round " + round + ": normal zombies" );
        return;
    }

    level.rr_ag_type = type;
    rs.aitypeoverridemap[ "zombie_base" ] = [ type ];
    // No armored zombies this round: they become the elemental type.
    if ( !istrue( level.rr_ag_armored_swapped ) )
    {
        level.rr_ag_saved = [];
        foreach ( sub in armored )
        {
            level.rr_ag_saved[ sub ] = rs.aitypeoverridemap[ sub ];
        }
        level.rr_ag_armored_swapped = 1;
    }
    foreach ( sub in armored )
    {
        rs.aitypeoverridemap[ sub ] = [ type ];
    }
    rr_ag_debug( "round " + round + ": " + type + " (no armored, no super sprint)" );
}

function private rr_ag_on_agent_spawned( params )
{
    rr_d( "agarthan_spawn" );
    if ( !rr_ag_on() || !isdefined( level.rr_ag_type ) || !isdefined( params ) || !isdefined( params.agent ) )
    {
        return;
    }
    params.agent thread rr_ag_speed_cap();
}

// Elemental zombies on these rounds: super sprint -> sprint.
function private rr_ag_speed_cap()
{
    rr_d( "agarthan_zombie" );
    self endon( #"death" );
    wait 0.5;   // let the zombie finish its setup
    sub = "" + ( self.subclass ?? "" );
    if ( !isdefined( level.rr_ag_type ) || tolower( sub ) != tolower( "" + level.rr_ag_type ) )
    {
        return;
    }
    capped = 0;
    while ( true )
    {
        structs = self.move_speed_priority_structs;
        top = undefined;
        if ( isarray( structs ) )
        {
            // Highest request that is not this mod's own.
            for ( i = structs.size - 1; i >= 0; i-- )
            {
                if ( isstruct( structs[ i ] ) && !( structs[ i ].id === "rr_agarthan" ) )
                {
                    top = structs[ i ];
                    break;
                }
            }
        }
        wants_super = isdefined( top ) && top.move_speed_value === "super_sprint";
        if ( wants_super && !capped )
        {
            self zombie_utils::function_a8ce00e0448cb6f0( "sprint", "rr_agarthan", 50 );
            capped = 1;
        }
        else if ( !wants_super && capped )
        {
            self zombie_utils::function_a8ce00e0448cb6f0( undefined, "rr_agarthan", 50 );
            capped = 0;
        }
        wait 0.25;
    }
}

function private rr_ag_debug( text )
{
    rr_ev( "Agarthan: " + text );
    if ( level.gsr_debug < 1 || !isdefined( level.players ) )
    {
        return;
    }
    foreach ( p in level.players )
    {
        if ( isdefined( p ) )
        {
            p iprintln( "^5[Relic Rebalance] ^7Agarthan Device: " + text );
        }
    }
}

// =====================================================================
// v7.2: MANNEQUIN TURRET (No Armor) with Cursed Reimagined
// Stock: zmmodenoarmor = 1 strips armor (zombie_mode_modifiers
// function_fc10d319e7a6226f) and only Golden Armor stays. Cursed Reimagined
// sets zmmodenoarmor back to 0 every 0.1 s (the flag also blocks armor
// purchases), so the relic did nothing. This keeps the relic's effect
// without the flag: normal armor is stripped, and the vest level is set to 3
// so CR's armor wall (next tier = level + 1) offers Golden Armor directly at
// CR's own Golden price. Armor plate loot is still removed by the relic's
// own loot callback. Full Armor power-ups still drop (they refill Golden
// Armor; anyone without Golden Armor is stripped again right after).
// Only runs while CR is doing that (flag off with the relic active), so
// without CR the stock relic works as normal.
// =====================================================================

// v8.1: three independent ways to see the relic is on.
function private rr_mq_relic_on()
{
    if ( istrue( level.rr_mq_latched ) )
    {
        return true;   // saw the relic switch the no-armor flag on
    }
    if ( isdefined( level.zm_relic_modifiers ) )
    {
        if ( isdefined( level.zm_relic_modifiers[ #"no_armor" ] ) )
        {
            return true;
        }
    }
    if ( isdefined( level.active_relics ) )
    {
        h = getxhashasset( "relic:sat_zm_hornet_omicron_cr" );
        foreach ( r in level.active_relics )
        {
            if ( r === h )
            {
                return true;
            }
        }
    }
    return false;
}

// v8.1: the stock relic sets zmmodenoarmor = 1 when it turns on; Cursed
// Reimagined clears it within 0.1 s. Watch every frame for 5 minutes and
// remember if it was ever set.
function private rr_mq_latch_watch()
{
    level endon( #"game_ended" );
    for ( i = 0; i < 18000; i++ )
    {
        mm = level.zm_mode_modifiers;
        if ( isdefined( mm ) )
        {
            if ( istrue( mm.zmmodenoarmor ) )
            {
                level.rr_mq_latched = 1;
                return;
            }
        }
        waitframe();
    }
}

// v8.1 TEST: one line 30 s in, active or not.
function private rr_mq_status()
{
    level endon( #"game_ended" );
    wait 30;
    if ( level.rr_ps_print < 1 || !isdefined( level.players ) )
    {
        return;
    }
    on = rr_mq_relic_on();
    act = rr_mq_active();
    text = "^5[Mannequin Turret] ^1NOT detected^7 (relic off, or not seen)";
    if ( istrue( act ) )
    {
        text = "^5[Mannequin Turret] ^2active^7: Golden Armor at the armor wall";
    }
    else if ( istrue( on ) )
    {
        text = "^5[Mannequin Turret] ^3relic seen, Cursed Reimagined not running^7 (stock relic runs)";
    }
    foreach ( p in level.players )
    {
        if ( isdefined( p ) )
        {
            p iprintln( text );
        }
    }
}

// v8.0: step by step (no function calls inside && chains).
function private rr_mq_active()
{
    if ( level.rr_mannequin < 1 )
    {
        return false;
    }
    on = rr_mq_relic_on();
    if ( !istrue( on ) )
    {
        return false;
    }
    // v8.2: only with Cursed Reimagined (its armor wall sells tier =
    // vest level + 1, so it never offers Golden Armor with the relic on).
    // CR sets level.cursed_armor_cap_round in every mode it runs in.
    if ( !isdefined( level.cursed_armor_cap_round ) )
    {
        return false;
    }
    return true;
}

function private rr_mq_watch()
{
    level endon( #"game_ended" );
    hooked = 0;
    while ( true )
    {
        wait 0.25;
        act = rr_mq_active();
        if ( !istrue( act ) )
        {
            continue;
        }
        if ( !isdefined( level.players ) )
        {
            continue;
        }
        if ( !hooked )
        {
            hooked = 1;
            rr_ev( "Mannequin Turret: active with Cursed Reimagined (Golden Armor only)" );
            if ( level.rr_ps_print >= 1 )
            {
                foreach ( p in level.players )
                {
                    if ( isdefined( p ) )
                    {
                        p iprintln( "^5[Mannequin Turret] ^7active: no normal armor, Golden Armor at the armor wall" );
                    }
                }
            }
        }
        foreach ( p in level.players )
        {
            if ( isdefined( p ) && isalive( p ) )
            {
                p rr_mq_strip();
            }
        }
    }
}

// self = player. Same as the relic's own strip, minus the flag.
// v7.9: the vest level is set FIRST (so CR's wall offers Golden Armor even
// if a later step fails), and each armor step is its own small function.
function private rr_mq_strip()
{
    if ( istrue( self.hasgoldenarmorplate ) )
    {
        // Golden Armor is allowed (stock relic keeps it too). CR's Golden
        // purchase expects level-3 armor already on; with the relic you have
        // none, so fill it once (what the stock relic does for Golden).
        maxhp = self.maxarmorhealth;
        if ( !isdefined( maxhp ) || maxhp <= 0 )
        {
            self rr_mq_golden_fill();
        }
        return;
    }
    // CR's wall sells tier ( level + 1 ): level 3 -> Golden Armor next.
    if ( !( self.platecarrierlevel === 3 ) )
    {
        self.platecarrierlevel = 3;
        self rr_mq_hud_off();
    }
    hp = self.armorhealth;
    maxhp = self.maxarmorhealth;
    if ( ( isdefined( hp ) && hp > 0 ) || ( isdefined( maxhp ) && maxhp > 0 ) )
    {
        self rr_mq_zero_armor();
        self rr_mq_hud_off();
    }
    plates = self rr_mq_plates();
    if ( isdefined( plates ) && plates > 0 )
    {
        self rr_mq_zero_plates();
    }
}

// v8.2: level-3 armor for a Golden Armor owner.
function private rr_mq_golden_fill()
{
    self.platecarrierlevel = 3;
    mx = self zm_armor::get_max_armor_health();
    if ( !isdefined( mx ) || mx <= 0 )
    {
        mx = 501;
    }
    self.maxarmorhealth = mx;
    self armor::setarmorhealth( mx, 1, 1 );
    self setclientomnvar( "ui_show_armor_global", 1 );
    self setclientomnvar( "ui_armor_current_level", 3 );
    params = spawnstruct();
    params.player = self;
    params.activate = 1;
    self callback::callback( "toggle_squad_armor", params );
}

function private rr_mq_zero_armor()
{
    self.maxarmorhealth = 0;
    self armor::setarmorhealth( 0, 1, 1 );
}

function private rr_mq_plates()
{
    return self armor::getcurrentplatecount();
}

function private rr_mq_zero_plates()
{
    self armor::external_setarmorplates( 0 );
}

function private rr_mq_hud_off()
{
    self setclientomnvar( "ui_show_armor_global", 0 );
    self setclientomnvar( "ui_armor_current_level", 0 );
    params = spawnstruct();
    params.player = self;
    params.activate = 0;
    self callback::callback( "toggle_squad_armor", params );
}

// =====================================================================
// v8.3: MR PEEKS EGG - MAP WONDER WEAPON
// zm_relic_mrp_events on_item_used: an egg whose reward has
// "map_wonder_weapon" picks from getscriptbundle( level.var_8b6bf63f61fe01f9 ),
// keeping entries flagged ismapwonderweapon. In this mode that lookup comes
// back empty (Cursed box list), so the egg never gave the Wonder Weapon. If
// the game's own lookup finds nothing, this spawns the map's Wonder Weapon at
// the egg instead. Same quest rules as the game; never doubles up.
// =====================================================================

function private rr_egg_ww_item()
{
    switch ( level.mapname )
    {
        case "zm_sat_firefly": return "zm_sat_item_weapon_ww_firefly";
        case "zm_sat_hornet": return "zm_sat_item_weapon_ww_hornet";
        case "zm_sat_locust": return "zm_sat_item_weapon_ww_locust";
        case "zm_sat_mantis": return "zm_sat_item_weapon_ww_mantis";
        case "zm_sat_ruby": return "zm_sat_item_weapon_ww_ruby";
        case "zm_sat_scarab": return "zm_sat_item_weapon_ww_scarab";
    }
    return undefined;
}

// True only if the game's own lookup would find a map Wonder Weapon.
function private rr_egg_stock_ok()
{
    name = level.var_8b6bf63f61fe01f9;
    if ( !isdefined( name ) )
    {
        return false;
    }
    wb = getscriptbundle( name );
    if ( !isdefined( wb ) )
    {
        return false;
    }
    if ( !isdefined( wb.itementries ) )
    {
        return false;
    }
    foreach ( item in wb.itementries )
    {
        if ( !isdefined( item ) || !isdefined( item.itemspawnentry ) )
        {
            continue;
        }
        ib = getscriptbundle( item.itemspawnentry );
        if ( !isdefined( ib ) || !isdefined( ib.ref ) )
        {
            continue;
        }
        wn = getxhashasset( ib.ref );
        md = level.weaponmetadata[ wn ];
        if ( isdefined( md ) )
        {
            if ( istrue( md.ismapwonderweapon ) )
            {
                return true;
            }
        }
    }
    return false;
}

function private rr_egg_used( params )
{
    if ( !isdefined( params ) || !isdefined( params.item ) )
    {
        return;
    }
    tier = params.item.relic_mrp_item_tier;
    if ( !isdefined( tier ) || tier < 1 )
    {
        return;
    }
    origin = params.item.origin;
    b = level.relic_mrp_event_bundle;
    if ( !isdefined( b ) || !isdefined( origin ) )
    {
        return;
    }
    reward = undefined;
    if ( tier == 1 )
    {
        reward = b.rewardstier1;
    }
    else if ( tier == 2 )
    {
        reward = b.rewardstier2;
    }
    else if ( tier == 3 )
    {
        reward = b.rewardstier3;
    }
    if ( !isdefined( reward ) || !isdefined( reward.reliceventscriptreward ) )
    {
        return;
    }
    wants = 0;
    foreach ( r in reward.reliceventscriptreward )
    {
        if ( isdefined( r ) && r.reliceventscriptreward === #"map_wonder_weapon" )
        {
            wants = 1;
        }
    }
    if ( !wants )
    {
        return;
    }
    // Same quest rules as the game.
    if ( level.mapname == "zm_sat_ruby" )
    {
        done = level utility::flag( "ruby_wwq_complete" );
        if ( !istrue( done ) )
        {
            return;
        }
    }
    if ( level.mapname == "zm_sat_locust" )
    {
        done = level utility::flag( "ww_step_08" );
        if ( !istrue( done ) )
        {
            return;
        }
    }
    item = rr_egg_ww_item();
    if ( !isdefined( item ) )
    {
        return;
    }
    ok = rr_egg_stock_ok();
    if ( istrue( ok ) )
    {
        return;   // the game's own reward works here: nothing to add
    }
    spawnoptions = common_item::items_initspawnoptions_spawnfromposition( origin );
    common_item::function_57b88e025e5fb03e( hashcat( %"itemspawnentry:", item ), undefined, spawnoptions );
    rr_ev( "Mr Peeks egg: map Wonder Weapon given" );
}

// =====================================================================
// v6.7: WRESTLING BELT  (weapon wall-buys randomize each round)
// The stock relic (zombie_mode_modifiers on_round_end_randomize_wallbuy)
// skips every wall whose wallbuy_scriptable.disable_upgrade is set, and
// Cursed Reimagined sets it on every weapon wall for its Green lock, so
// nothing changed. This runs the same swap for exactly those walls (the
// ones stock skipped), so it never doubles up with the stock relic.
// =====================================================================

function private rr_wb_on()
{
    mm = level.zm_mode_modifiers;
    return level.rr_wrestling_belt >= 1 && isdefined( mm ) && istrue( mm.var_15a59900eb1cb459 );
}

function private rr_wb_on_round_end( params )
{
    if ( !rr_wb_on() || !isdefined( level.a_s_wallbuy_locations ) )
    {
        return;
    }
    level thread rr_wb_randomize();
}

function private rr_wb_randomize()
{
    level endon( #"game_ended" );
    level notify( #"rr_wb_randomize" );
    level endon( #"rr_wb_randomize" );
    waitframe();   // let the stock randomizer go first (it skips locked walls)

    info = level.zm_mode_modifiers.var_baa2e34a68beadf7;
    if ( !isdefined( info ) )
    {
        return;
    }
    if ( !isdefined( info.excluded_item_weapons ) || info.excluded_item_weapons.size == 0 )
    {
        info.excluded_item_weapons = zombie_mode_modifiers::function_89b2528b4a999090();
    }

    swapped = 0;
    locations = level.a_s_wallbuy_locations;
    foreach ( wallbuy_struct in locations )
    {
        if ( !isdefined( wallbuy_struct ) )
        {
            continue;
        }
        ws = wallbuy_struct.wallbuy_scriptable;
        // Only walls Cursed Reimagined locked (it marks them cursed_white_chalk).
        // Without CR the stock relic randomizes the walls itself, and walls a
        // map locks for its own events stay skipped like stock.
        if ( !isdefined( ws ) || !isdefined( ws.weapon_root_name ) || istrue( ws.b_disable_randomize_wallbuy ) || !isdefined( ws.disable_upgrade ) || !istrue( ws.cursed_white_chalk ) )
        {
            continue;
        }
        new_name = ws zombie_mode_modifiers::choose_random_wallbuy();
        if ( !isdefined( new_name ) || new_name === ws.weapon )
        {
            continue;
        }
        if ( !isdefined( wallbuy_struct.original_script_noteworthy ) )
        {
            wallbuy_struct.original_script_noteworthy = wallbuy_struct.script_noteworthy;
        }
        rarity = ws.rarity;   // keeps the wall's rarity (Green with Cursed Reimagined)
        ws freescriptable();
        if ( isdefined( ws.gunmodel ) )
        {
            ws.gunmodel delete();
        }
        wallbuy_struct.script_noteworthy = new_name;
        wallbuy_struct utility::callsharedfunc( #"wallbuy", #"spawn_wallbuy_internal", wallbuy_struct, rarity );
        nws = wallbuy_struct.wallbuy_scriptable;
        if ( isdefined( nws ) )
        {
            if ( !( wallbuy_struct.script_noteworthy === wallbuy_struct.original_script_noteworthy ) )
            {
                zombie_mode_modifiers::function_8aee443ce950d61d( wallbuy_struct );
            }
            fxdir = anglestoright( nws.angles );
            updir = anglestoup( nws.angles );
            playfx( utility::getfx( "vfx_wallbuy_upgrade" ), nws.origin, fxdir, updir );
            swapped++;
        }
        waitframe();
    }
    level callback::callback( #"hash_6e3acfc32f60c580" );
    rr_ev( "Wrestling Belt: " + swapped + " wall-buy(s) randomized" );
}

// =====================================================================
// v6.4: PER-WEAPON DAMAGE CALLBACKS (Cursed Reimagined's classic 1911)
// zombie_damage runs relic damage modifiers first and per-weapon callbacks
// (zombie_utils::register_zombie_weapon_damage_callback) after them. A
// callback that returns a value SETS the damage, so the Music Box and the
// Gramophone were undone for those weapons (CR's white 1911). Each
// callback is wrapped: it runs first, then the relics are applied to the
// value it set.
// =====================================================================

function private rr_wcb_watch()
{
    level endon( #"game_ended" );
    level.rr_wcb_orig = [];
    while ( true )
    {
        map = level.var_ad4a0c0e90a75e96;
        if ( isdefined( map ) && isarray( map ) )
        {
            todo = [];
            foreach ( name, f in map )
            {
                if ( isdefined( f ) && !( f === &rr_wcb_wrap ) )
                {
                    todo[ todo.size ] = name;
                }
            }
            foreach ( name in todo )
            {
                level.rr_wcb_orig[ name ] = level.var_ad4a0c0e90a75e96[ name ];
                level.var_ad4a0c0e90a75e96[ name ] = &rr_wcb_wrap;
                rr_ev( "weapon damage rule wrapped: " + name );
            }
        }
        wait 2;
    }
}

// self = the zombie. Same signature as the game's weapon callbacks.
function rr_wcb_wrap( dmg_struct )
{
    if ( !isdefined( dmg_struct ) )
    {
        return -1;
    }
    w = dmg_struct.objweapon;
    if ( !isdefined( w ) || !isweapon( w ) )
    {
        w = dmg_struct.sweapon;
    }
    if ( !isdefined( w ) || !isdefined( w.basename ) )
    {
        return -1;
    }
    orig = level.rr_wcb_orig[ w.basename ];
    if ( !isdefined( orig ) )
    {
        return -1;
    }
    result = self [[ orig ]]( dmg_struct );
    if ( !isdefined( result ) || result < 0 )
    {
        return result;   // it left the damage alone: relics already applied
    }

    // Music Box: same filter as every other hit.
    if ( rr_mb_relic_on() )
    {
        dmg_struct.idamage = result;
        if ( level.rr_music_box >= 1 )
        {
            if ( !rr_mb_is_wonder( dmg_struct.sweapon ) )
            {
                result = self rr_mb_filter( dmg_struct );
            }
        }
        else
        {
            result = self zombie_mode_modifiers::function_309ee76ffd6083c2( dmg_struct );
        }
    }
    // Gramophone: same multiplier as every other hit.
    if ( rr_gramo_relic_on() && isdefined( result ) && result > 0 && isdefined( dmg_struct.eattacker ) && isplayer( dmg_struct.eattacker ) )
    {
        if ( level.rr_gramophone >= 1 )
        {
            result = int( result * level.rr_gramo_damage_mult );
        }
        else
        {
            result = int( result * ( 1 + ( level.zm_mode_modifiers.extradamage ?? 0.25 ) ) );
        }
    }
    return result;
}

// =====================================================================
// v4.0: MUSIC BOX  (wonder weapons exempt, critical kills x2 points)
// =====================================================================

function private rr_mb_relic_on()
{
    mm = level.zm_mode_modifiers;
    return isdefined( mm ) && istrue( mm.var_ec86147eb5afdfe );
}

function private rr_mb_watch()
{
    level endon( #"game_ended" );
    while ( true )
    {
        if ( level.rr_music_box >= 1 && rr_mb_relic_on() )
        {
            if ( !istrue( level.rr_mb_hooked ) )
            {
                // Damage: run wonder weapons past the relic's filter.
                zombie_mode_modifiers::function_9c9da0455f2c2a45( "only_critical_dmg", &rr_mb_damage );
                level.rr_mb_hooked = 1;
                rr_mb_debug( "active" );
            }
        }
        wait 1;
    }
}

// v5.8: wonder weapons only. weapon::iswonderweapon also let normal guns
// (the 1911) through, so this checks the weapon name instead: every
// wonder weapon is named "sat_ww_..." (Ray Gun sat_ww_raygun, sat_ww_ruby_zm...).
function private rr_mb_is_wonder( w )
{
    if ( !isdefined( w ) || isnullweapon( w ) || !isdefined( w.basename ) )
    {
        return false;
    }
    // v7.8: the game's own checks (a weapon name can't be turned into text
    // in this build, so the old name test never matched anything).
    if ( weapon::iswonderweapon( w ) )
    {
        return true;
    }
    return istrue( weapon::ismapwonderweapon( w ) );
}

// Same signature as the stock modifier. self = the zombie being hit.
function rr_mb_damage( dmg_struct )
{
    rr_d( "mubox_hit" );
    if ( level.rr_test_print >= 1 && ( level.rr_mb_logged ?? 0 ) < 8 && isdefined( dmg_struct ) && isdefined( self ) )
    {
        level.rr_mb_logged = ( level.rr_mb_logged ?? 0 ) + 1;
        wn = "none";
        if ( isdefined( dmg_struct.sweapon ) && !isnullweapon( dmg_struct.sweapon ) )
        {
            wn = "weapon";
        }
        rr_ev( "MusicBox filter: " + ( self.subclass ?? "?" ) + " crit " + istrue( dmg_struct.biscritical ) + " " + wn + " ai " + isai( self ) + " agent " + isagent( self ) );
    }
    if ( isdefined( dmg_struct ) && rr_mb_is_wonder( dmg_struct.sweapon ) )
    {
        if ( isdefined( self ) && isagent( self ) )
        {
            self zombie_mode_modifiers::disable_zombie_damage_invuln();
        }
        return dmg_struct.idamage;   // wonder weapon: relic ignored
    }
    return self rr_mb_filter( dmg_struct );
}

// v5.9: the game's own critical-only check, but for every zombie AI. The
// stock check skips anything that isn't an "agent", and normal zombies on
// some maps are spawned as actors, so they took full body-shot damage.
function private rr_mb_filter( dmg_struct )
{
    if ( !isdefined( self ) || !isdefined( dmg_struct ) || !( isai( self ) || isagent( self ) ) )
    {
        return dmg_struct.idamage;
    }
    w = dmg_struct.sweapon;
    info = level.zm_mode_modifiers.var_26d1ac1d9963c5ba;

    ignored = 0;
    if ( isdefined( w ) && !isnullweapon( w ) && isdefined( info ) && isdefined( info.var_b3c8a091451e9502 ) && isdefined( w.basenamehash ) )
    {
        ignored = istrue( info.var_b3c8a091451e9502[ w.basenamehash ] );
    }
    map_ww = isdefined( w ) && !isnullweapon( w ) && weapon::ismapwonderweapon( w );

    trap = 0;
    if ( ( isdefined( dmg_struct.einflictor ) && dmg_struct.einflictor.targetname === "trap_attacker" ) || ( isdefined( dmg_struct.eattacker ) && dmg_struct.eattacker.targetname === "trap_attacker" ) )
    {
        trap = 1;
    }

    bad_attacker = 0;
    if ( ( isdefined( dmg_struct.eattacker ) && ( dmg_struct.eattacker.classname === "script_vehicle" || dmg_struct.eattacker.classname === "script_origin" ) )
        || ( isdefined( dmg_struct.einflictor ) && dmg_struct.einflictor.classname === "script_vehicle" ) )
    {
        bad_attacker = !( isdefined( dmg_struct.einflictor ) && istrue( dmg_struct.einflictor.streakinfo ) );
    }

    bad_ai = 0;
    if ( isdefined( self.zombieaisetting ) && isstring( self.zombieaisetting ) && isdefined( info ) && isdefined( info.var_4e4d555d3a43a778 ) )
    {
        bad_ai = istrue( info.var_4e4d555d3a43a778[ self.zombieaisetting ] );
    }

    if ( !istrue( dmg_struct.biscritical ) && !( self.aicategory === "boss" ) && !map_ww && !ignored && !bad_ai && !trap && !bad_attacker )
    {
        if ( isdefined( dmg_struct.metabonename ) )
        {
            // Armor piece hit: the game breaks it for 1 damage (stock).
            self zombie_mode_modifiers::disable_zombie_damage_invuln();
            utility::callsharedfunc( #"zombie", #"damagemetabone", dmg_struct );
            dmg_struct.idamage = 1;
        }
        else
        {
            dmg_struct.idamage = 0;
            self zombie_mode_modifiers::set_zombie_damage_invuln();
        }
    }
    else
    {
        self zombie_mode_modifiers::disable_zombie_damage_invuln();
    }
    return dmg_struct.idamage;
}

// v4.3: kill points are handed out by the game engine, not through the
// script points hook, so instead the killer gets a bonus on top when a
// zombie dies from a critical hit. self = the zombie that died.
function private rr_mb_on_zombie_killed( params )
{
    rr_d( "zombie_died" );
    // v6.3 TEST: the Pen's mimic roll values on the first kills of each round.
    if ( level.rr_test_print >= 1 && isdefined( rr_pen_params() ) )
    {
        r = zm_utility::get_round_number();
        if ( !( level.rr_pen_log_round === r ) )
        {
            level.rr_pen_log_round = r;
            level.rr_pen_log_n = 0;
        }
        if ( level.rr_pen_log_n < 3 )
        {
            level.rr_pen_log_n++;
            pp = rr_pen_params();
            rr_ev( "Pen kill: chance " + ( pp.mimic_spawn_chance ?? "?" ) + " on map " + ( level.var_7376e4ac664af8e0 ?? "undef" ) + "/" + ( pp.mimic_spawn_limit ?? "?" ) + " fog " + istrue( self.b_is_fog_zombie ) + " nodrops " + istrue( self.disable_zombie_drops ) );
        }
    }
    rr_d( "mubox_kill" );
    if ( level.rr_music_box < 1 || !rr_mb_relic_on() || !isdefined( params ) )
    {
        return;
    }
    attacker = params.eattacker;
    if ( !isdefined( attacker ) || !isplayer( attacker ) )
    {
        return;
    }
    crit = istrue( params.biscritical );
    if ( !crit && isdefined( self ) && isdefined( self.last_dmg_struct ) )
    {
        crit = istrue( self.last_dmg_struct.biscritical );
    }
    if ( !crit )
    {
        return;
    }
    if ( level.rr_mb_crit_kill_bonus <= 0 )
    {
        return;
    }
    // v4.5: same path the game's own kill points use in this mode
    // (zombie_mode_modifiers classic points): Double Points applies and a
    // "+100" popup shows next to the stock one.
    if ( utility::issharedfuncdefined( #"points", #"zm_give_points_override" ) )
    {
        utility::callsharedfunc( #"points", #"zm_give_points_override", attacker, level.rr_mb_crit_kill_bonus, #"zombie_kia_r_mod", spawnstruct() );
        if ( level.rr_diag >= 1 || level.rr_test_print >= 1 || level.gsr_debug >= 1 )
        {
            rr_mb_debug( "critical kill bonus +" + level.rr_mb_crit_kill_bonus + " (popup path)" );
        }
        return;
    }
    bonus = int( level.rr_mb_crit_kill_bonus * attacker points::get_point_scalar() );
    attacker points::zm_add_points( bonus );
    if ( utility::issharedfuncdefined( #"points", #"display_points_gained" ) )
    {
        attacker utility::callsharedfunc( #"points", #"display_points_gained", #"zombie_kia_r_mod", bonus, undefined, undefined, 0, 1 );
    }
    if ( level.rr_diag >= 1 || level.rr_test_print >= 1 || level.gsr_debug >= 1 )
    {
        rr_mb_debug( "critical kill bonus +" + bonus + " (direct)" );
    }
}

function private rr_mb_debug( text )
{
    rr_ev( "MusicBox: " + text );
    if ( level.gsr_debug < 1 || !isdefined( level.players ) )
    {
        return;
    }
    foreach ( p in level.players )
    {
        if ( isdefined( p ) )
        {
            p iprintln( "^5[Relic Rebalance] ^7Music Box: " + text );
        }
    }
}

// =====================================================================
// v4.1: RELIC LIST FOR THE MENU TEXT (Lua reads dvar rr_relics)
// =====================================================================

function private rr_ui_on( id )
{
    switch ( id )
    {
        case "spork": return 1;
        case "pen": return level.rr_lawyers_pen;
        case "wings": return level.rr_dragon_wings;
        case "rocket": return level.rr_rocket;
        case "pswitch": return level.rr_power_switch;
        case "gramo": return level.rr_gramophone;
        case "vrill": return level.rr_vrill_sphere;
        case "elephant": return level.rr_stuffed_elephant;
        case "valk": return level.rr_valkyrie_helmet;
        case "film": return level.rr_film_reel;
        case "vials": return level.rr_blood_vials;
        case "cph": return level.rr_civil_protector;
        case "mangler": return level.rr_mangler_helmet;
        case "agarthan": return level.rr_agarthan;
        case "mubox": return level.rr_music_box;
        case "belt": return level.rr_wrestling_belt;
        case "mannequin": return level.rr_mannequin;
        case "arnie": return level.rr_dancing_arnie;
    }
    return 0;
}

function private rr_ui_add( id, modifier )
{
    e = spawnstruct();
    e.id = id;
    e.modifier = modifier;
    level.rr_ui_entries[ level.rr_ui_entries.size ] = e;
}

function private rr_ui_watch()
{
    rr_d( "ui_watch" );
    level endon( #"game_ended" );
    level.rr_ui_entries = [];
    rr_ui_add( "spork", #"hash_811ac96901a51875" );
    rr_ui_add( "pen", #"mimics_infiltrate" );
    rr_ui_add( "wings", #"disable_powerups" );
    rr_ui_add( "rocket", #"no_score_streaks" );
    rr_ui_add( "pswitch", #"equipment_change_carousel" );
    rr_ui_add( "gramo", #"extra_bullet_cost" );
    rr_ui_add( "vrill", #"perk_limit_wrapped" );
    rr_ui_add( "elephant", #"delay_health_regen" );
    rr_ui_add( "valk", #"electric_fields" );
    rr_ui_add( "film", #"hash_45b90ec96daab099" );
    rr_ui_add( "vials", #"no_augments" );
    rr_ui_add( "cph", #"hash_3385fa4802fa103e" );
    rr_ui_add( "mangler", #"no_arsenal" );
    rr_ui_add( "agarthan", #"elemental_base_zombies" );
    rr_ui_add( "mubox", #"only_critical_damage" );
    rr_ui_add( "belt", #"randomize_wallbuys" );
    rr_ui_add( "mannequin", #"no_armor" );
    rr_ui_add( "arnie", #"perk_machines_give_random_perks" );
    // v5.7: no text is built while nothing changes. Each check only makes
    // a number (one bit per active rework); the text is built and sent
    // only when that number changes (normally once per match).
    last = -1;
    while ( true )
    {
        mask = 0;
        bit = 1;
        if ( level.rr_ui_relic_list >= 1 && isdefined( level.zm_relic_modifiers ) )
        {
            foreach ( e in level.rr_ui_entries )
            {
                if ( isdefined( level.zm_relic_modifiers[ e.modifier ] ) && rr_ui_on( e.id ) >= 1 )
                {
                    mask += bit;
                }
                bit *= 2;
            }
        }
        if ( mask != last )
        {
            // v6.0: plain checks again (no bit operators) to build the list.
            text = "";
            if ( level.rr_ui_relic_list >= 1 && isdefined( level.zm_relic_modifiers ) )
            {
                foreach ( e in level.rr_ui_entries )
                {
                    if ( isdefined( level.zm_relic_modifiers[ e.modifier ] ) && rr_ui_on( e.id ) >= 1 )
                    {
                        text = text + e.id + " ";
                    }
                }
            }
            setdvar( "rr_relics", text );
            rr_ev( "relic list for menu/Lua: " + text );
            last = mask;
        }
        wait 5;
    }
}

// =====================================================================
// v8.4: DANCING ARNIE - HARD ARMOR (replaces random perks)
// =====================================================================
// Stock (zm_relic_perk_machines_give_random_perks.gsc -> zombie_mode_
// modifiers set_perk_machines_give_random_perks()): the relic sets
// level.var_3ae3959c37a85611 (read by perk_machines.gsc), registers the
// "override_perk_machine_hint" shared func and puts an fx on every machine
// (stopped by notify hash_57459154b9c4e898). The relic counts as on while
// level.zm_relic_modifiers[ "perk_machines_give_random_perks" ] is set
// (zm_relics is_relic_modifier_active). While it is on, all three are
// undone (machines sell their own perk again) and
// level.rr_arnie_hard_armor tells Cursed Reimagined to use hard armor.
function private rr_arnie_relic_on()
{
    return isdefined( level.zm_relic_modifiers ) && isdefined( level.zm_relic_modifiers[ #"perk_machines_give_random_perks" ] );
}

function private rr_arnie_watch()
{
    level endon( #"game_ended" );
    level.rr_arnie_hard_armor = 0;
    while ( true )
    {
        on = level.rr_dancing_arnie >= 1 && rr_arnie_relic_on();
        if ( on && istrue( level.var_3ae3959c37a85611 ) )
        {
            level.var_3ae3959c37a85611 = undefined;
            utility::clearsharedfunc( #"perk_machine", #"override_perk_machine_hint" );
            level notify( #"hash_57459154b9c4e898" );
            rr_ev( "Dancing Arnie: random perks removed, hard armor on" );
        }
        level.rr_arnie_hard_armor = on;
        wait 0.1;
    }
}

// Shown once per player so you can see the file is running.
function private rr_loaded_message( params )
{
    if ( level.rr_show_loaded < 1 || !isplayer( self ) || istrue( self.rr_loaded_shown ) )
    {
        return;
    }
    self.rr_loaded_shown = 1;
    self iprintlnbold( "^5Relic Rebalance v8.3 ^7loaded" );
}

// =====================================================================
// v5.0: CRASH DIAGNOSTICS
// Every hooked part calls rr_d( name ) when it runs. Once a second a
// summary goes into dvar rr_diag (the Lua file shows it in a match):
// time, round, last part that ran, how often each part ran in the last
// second and in total, and the sizes of everything the mod keeps.
// =====================================================================

function rr_d( name )
{
    if ( !isdefined( level.rr_diag ) || level.rr_diag < 1 )
    {
        return;
    }
    if ( !isdefined( level.rr_dc ) )
    {
        level.rr_dc = [];
    }
    if ( !isdefined( level.rr_dc[ name ] ) )
    {
        level.rr_dc[ name ] = 0;
    }
    level.rr_dc[ name ]++;
    level.rr_dlast = name;
}

function private rr_diag_cut( text, n )
{
    if ( text.size > n )
    {
        return getsubstr( text, 0, n );
    }
    return text;
}

// Last few notable events, with the match time they happened at.
function rr_ev( text )
{
    if ( isdefined( level.rr_test_print ) && level.rr_test_print >= 1 && isdefined( level.players ) )
    {
        foreach ( p in level.players )
        {
            if ( isdefined( p ) )
            {
                p iprintln( "^5[RR] ^7" + text );
            }
        }
    }
    if ( !isdefined( level.rr_diag ) || level.rr_diag < 1 )
    {
        return;
    }
    if ( !isdefined( level.rr_events ) )
    {
        level.rr_events = [];
    }
    secs = int( gettime() / 1000 );
    if ( isdefined( level.rr_diag_start ) )
    {
        secs = int( ( gettime() - level.rr_diag_start ) / 1000 );
    }
    entry = int( secs / 60 ) + "m" + ( secs % 60 ) + "s " + text;
    if ( entry.size > 70 )
    {
        entry = getsubstr( entry, 0, 70 );
    }
    // keep the last 4
    if ( level.rr_events.size >= 4 )
    {
        level.rr_events = [ level.rr_events[ 1 ], level.rr_events[ 2 ], level.rr_events[ 3 ] ];
    }
    level.rr_events[ level.rr_events.size ] = entry;
    rr_diag_write();   // v5.2: show it right away (a freeze can stop the 1 s update)
}

// v5.2: writes the 4 status lines from the last second plus the events now.
function rr_diag_write()
{
    line5 = "events: ";
    if ( isdefined( level.rr_events ) )
    {
        foreach ( ev in level.rr_events )
        {
            line5 += ev + "  ;  ";
        }
    }
    head = level.rr_diag_head ?? "starting|||";
    setdvar( "rr_diag", head + "|" + rr_diag_cut( line5, 300 ) );
}

// v5.4: entity count (total, and the 3 kinds that grew most since the
// first count) - an entity leak runs the game out of entities and crashes it.
function private rr_diag_ents()
{
    ents = getentarray();
    byc = [];
    foreach ( e in ents )
    {
        if ( !isdefined( e ) )
        {
            continue;
        }
        c = "" + ( e.classname ?? "?" );
        if ( !isdefined( byc[ c ] ) )
        {
            byc[ c ] = 0;
        }
        byc[ c ]++;
    }
    if ( !isdefined( level.rr_ent_base ) )
    {
        level.rr_ent_base = byc;
        level.rr_ent_base_total = ents.size;
    }
    used = [];
    top = "";
    for ( k = 0; k < 3; k++ )
    {
        best = undefined;
        bestd = -100000;
        foreach ( c, n in byc )
        {
            if ( isdefined( used[ c ] ) )
            {
                continue;
            }
            d = n - ( level.rr_ent_base[ c ] ?? 0 );
            if ( d > bestd )
            {
                bestd = d;
                best = c;
            }
        }
        if ( !isdefined( best ) )
        {
            break;
        }
        used[ best ] = 1;
        top += " " + best + " " + byc[ best ] + "(" + ( bestd >= 0 ? "+" : "" ) + bestd + ")";
    }
    return "ENTS " + ents.size + " (start " + level.rr_ent_base_total + ") grew:" + top;
}

function private rr_diag_size( a )
{
    if ( isdefined( a ) && isarray( a ) )
    {
        return a.size;
    }
    return -1;
}

function private rr_diag_watch()
{
    level endon( #"game_ended" );
    start = gettime();
    level.rr_diag_start = start;
    prev = [];
    while ( true )
    {
        wait 1;
        if ( level.rr_diag < 1 )
        {
            continue;
        }
        secs = int( ( gettime() - start ) / 1000 );
        line1 = "t " + int( secs / 60 ) + "m" + ( secs % 60 ) + "s  round " + zm_utility::get_round_number() + "  last: " + level.rr_dlast;
        // per second | total, only parts that ran
        line2 = "";
        line3 = "";
        count = 0;
        foreach ( name, total in level.rr_dc )
        {
            before = prev[ name ] ?? 0;
            entry = name + " " + ( total - before ) + "/s (" + total + ")  ";
            if ( count < 8 )
            {
                line2 += entry;
            }
            else
            {
                line3 += entry;
            }
            prev[ name ] = total;
            count++;
        }
        ai = 0;
        if ( isdefined( level.var_a009ab14ee0d3223 ) && isdefined( level.var_a009ab14ee0d3223.aitypeoverridemap ) )
        {
            ai = level.var_a009ab14ee0d3223.aitypeoverridemap.size;
        }
        line4 = rr_diag_ents() + "  |  sizes: bosses " + rr_diag_size( level.rr_wings_bosses ) + "  bonus funcs " + rr_diag_size( level.rr_wings_bonus_funcs )
            + "  bonus list " + rr_diag_size( level.var_1db3142b2dbcd1a9 ) + "  wings pending " + rr_diag_size( level.rr_wings_pending )
            + "  ag seen " + rr_diag_size( level.rr_ag_seen ) + "  type overrides " + ai + "  players " + rr_diag_size( level.players );
        // Keep each line short (dvar strings have a length limit).
        level.rr_diag_head = rr_diag_cut( line1, 200 ) + "|" + rr_diag_cut( line2, 240 ) + "|" + rr_diag_cut( line3, 240 ) + "|" + rr_diag_cut( line4, 240 );
        rr_diag_write();
    }
}
