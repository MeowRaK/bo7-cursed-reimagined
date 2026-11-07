// ============================================================
// zm_enhanced_full_power - Full Power also gives a score streak
// (weapon AND item streaks)
//
// Normal Full Power power-ups still give Full Power as usual, and
// on top of that the player who picks it up is given a random score
// streak straight into their streak slot, replacing any streak they
// already hold:
//   - weapon streaks come with the crafting bench's ammo
//   - item streaks (RC-XD, DAWG...): the held streak is removed
//     first with the game's own "removecurrent", then the new one
//     goes in the way the crafting bench does it
//
// Works with every Full Power: natural zombie drops and ones spawned
// by mod menus. Watches the stock #"powerup_dropped" / #"powerup_grabbed"
// notifies, so the streak goes to the exact player who grabs it.
//
// Notes what it did to cod25\kronos\enhanced_full_power\info.json.
//
// Does not touch the crafting table.
// ============================================================

#using script_4c770a9a4ad7659c;
#using scripts\common\utility;
#using scripts\common\callbacks;
#using scripts\mp\loot\common_item;

autoexec zfpa_init()
{
    // ---------- which streaks Full Power can give ----------
    //   1 = all weapon streaks
    //   2 = just the Death Machine
    //   3 = all weapon streaks and item streaks
    //   4 = all weapon streaks + Disciple Injection
    level.zfpa_pool = 4;

    // ---------- if you're already holding a streak ----------
    //   1 = the new streak replaces it (the old one is gone)
    //   2 = the new streak replaces it, and your old one is dropped on
    //       the floor at your feet (weapon streaks keep their ammo)
    level.zfpa_when_held = 2;

    // ---------- other settings ----------
    level.zfpa_remove_wait = 0.1; // item streaks: seconds between removing the old streak and giving the new one
    level.zfpa_cleanup_wait = 0.5;  // item streaks: seconds before removing the floor copy the game leaves behind
    level.zfpa_hide_depth = 40;   // item streaks: how far under the floor that copy is placed so you
                                  // don't see it (0 = at your feet, visible for a moment)

    // weapon streaks and the ammo each comes with
    level.zfpa_ammo = [];
    level.zfpa_ammo[ "death_machine_gun" ]    = 300; // Death Machine
    level.zfpa_ammo[ "war_machine_launcher" ] = 30;  // War Machine
    level.zfpa_ammo[ "hand_cannon" ]          = 10;  // Hand Cannon
    level.zfpa_ammo[ "mangler_cannon" ]       = 3;   // Mangler Cannon
    level.zfpa_ammo[ "m202_launcher" ]        = 12;  // M202 launcher
    level.zfpa_ammo[ "combat_bow" ]           = 12;  // Combat Bow
    level.zfpa_ammo[ "smart_gun" ]            = 16;  // Smart Gun

    // weapon streaks (remove a name to stop it being given)
    level.zfpa_weapons = [ "death_machine_gun", "war_machine_launcher", "hand_cannon", "mangler_cannon",
        "m202_launcher", "combat_bow", "smart_gun" ];

    // item streaks (remove a name to stop it being given)
    level.zfpa_items = [ "rcxd", "toma_strike", "remote_turret", "dawg", "zm_dinj", "ground_drone_unit",
        "radiation_blast" ];

    level.zfpa_is_item = [];

    foreach ( ref in level.zfpa_items )
    {
        level.zfpa_is_item[ ref ] = 1;
    }

    nengine_store_clear( "enhanced_full_power" );
    level thread zfpa_hook();
}

function zfpa_info( key, value )
{
    nengine_store_set( "enhanced_full_power", key, value );
    nengine_store_save( "enhanced_full_power", "info" );
}

// ---------- get told who picks up each power-up ----------
// Stock powerups::powerup_drop() does
//   level notify( #"powerup_dropped", e_powerup );
// and powerups::powerup_wait_for_pickup() does
//   self notify( #"powerup_grabbed", player );
// on the grabbed power-up, so the streak goes to the exact player.
function zfpa_hook()
{
    level endon( #"game_ended" );
    zfpa_info( "watching power-up drops", 1 );

    while ( true )
    {
        level waittill( #"powerup_dropped", e_powerup );

        if ( isdefined( e_powerup ) && e_powerup.str_powerup === "full_power" )
        {
            e_powerup thread zfpa_watch_grab();
        }
    }
}

// self = dropped Full Power
function zfpa_watch_grab()
{
    self endon( #"death" );
    level endon( #"game_ended" );

    self waittill( #"powerup_grabbed", player );

    if ( isplayer( player ) )
    {
        zfpa_info( "full power grabbed", gettime() );
        player thread zfpa_reward();
    }
}

// ---------- picking the streak ----------
function zfpa_pool()
{
    if ( level.zfpa_pool == 2 )
    {
        return [ "death_machine_gun" ];
    }

    if ( level.zfpa_pool == 1 )
    {
        return level.zfpa_weapons;
    }

    if ( level.zfpa_pool == 4 )
    {
        list = [];

        foreach ( ref in level.zfpa_weapons )
        {
            list[ list.size ] = ref;
        }

        list[ list.size ] = "zm_dinj";
        return list;
    }

    list = [];

    foreach ( ref in level.zfpa_weapons )
    {
        list[ list.size ] = ref;
    }

    foreach ( ref in level.zfpa_items )
    {
        list[ list.size ] = ref;
    }

    return list;
}

function zfpa_reward()
{
    list = zfpa_pool();
    ref = list[ randomint( list.size ) ];
    self zfpa_give( ref );
}

// ---------- giving the streak ----------
function zfpa_give( ref )
{
    zfpa_info( "gave " + ref, gettime() );

    if ( !isdefined( level.commonitem ) || !isdefined( level.commonitem.itemcallbacks ) || !isdefined( level.commonitem.itemcallbacks[ "killstreak" ] ) )
    {
        return;
    }

    use = level.commonitem.itemcallbacks[ "killstreak" ].funcs[ #"use" ];
    bundle = common_item::function_cf68ad18114498b2( ref );

    if ( !isdefined( use ) || !isdefined( bundle ) )
    {
        return;
    }

    // set to keep the old streak: note which one you have (and its
    // ammo), give the new one, then drop the old one at your feet
    // (dropping it first could let the game pick it straight back up)
    old_ref = undefined;
    old_count = undefined;

    if ( level.zfpa_when_held == 2 )
    {
        self zfpa_read_current();
        old_ref = self.zfpa_cur_ref;
        old_count = self.zfpa_cur_count;
    }

    self zfpa_give_new( ref, bundle, use );

    if ( isdefined( old_ref ) )
    {
        self zfpa_drop_at_feet( old_ref, old_count );
    }
}

function zfpa_give_new( ref, bundle, use )
{
    if ( isdefined( level.zfpa_is_item[ ref ] ) )
    {
        self zfpa_give_item( ref, bundle, use );
        return;
    }

    // weapon streaks: the crafting bench passes the item with its ammo
    // in .count; 0 = taken on purpose, so it replaces a held streak
    if ( isdefined( level.zfpa_ammo[ ref ] ) )
    {
        item = spawnstruct();
        item.count = level.zfpa_ammo[ ref ];
        self.zfpa_ok = 0;
        self thread zfpa_use_with_ammo( use, bundle, item );

        for ( i = 0; i < 20 && !istrue( self.zfpa_ok ); i++ )
        {
            wait 0.05;
        }

        if ( istrue( self.zfpa_ok ) )
        {
            return;
        }

        zfpa_info( "ammo item refused, gave without " + ref, 1 );
    }

    self [[ use ]]( bundle, undefined, 0, undefined );
}

// what streak the player is holding and how much ammo it has left
// (the game's own "getcurrent"); sets self.zfpa_cur_ref / _count
function zfpa_read_current()
{
    self.zfpa_cur_ref = undefined;
    self.zfpa_cur_count = undefined;
    gc = level.commonitem.itemcallbacks[ "killstreak" ].funcs[ #"getcurrent" ];

    if ( isdefined( gc ) )
    {
        self thread zfpa_getcurrent_call( gc );
    }
}

function zfpa_getcurrent_call( gc )
{
    cur = self [[ gc ]]();

    if ( !isdefined( cur ) )
    {
        return;
    }

    if ( isstring( cur ) )
    {
        self.zfpa_cur_ref = cur;
        return;
    }

    if ( isdefined( cur.ref ) && isstring( cur.ref ) )
    {
        self.zfpa_cur_ref = cur.ref;
    }

    if ( isdefined( cur.count ) )
    {
        self.zfpa_cur_count = cur.count;
    }
}

// drop a streak on the floor at your feet. Weapon streaks get the
// ammo they had (if the game reports it), otherwise the full amount
// from the list at the top.
function zfpa_drop_at_feet( ref, count )
{
    if ( !isdefined( count ) || count < 1 )
    {
        count = 1;

        if ( isdefined( level.zfpa_ammo[ ref ] ) )
        {
            count = level.zfpa_ammo[ ref ];
        }
    }

    spawnoptions = common_item::items_initspawnoptions_spawnfromentity( self );
    spawnoptions.originalowner = self;
    common_item::function_325e28c0fb65c36a( ref, count, spawnoptions );
    zfpa_info( "dropped old " + ref, count );
}

function zfpa_use_with_ammo( use, bundle, item )
{
    self [[ use ]]( bundle, item, 0, undefined );
    self.zfpa_ok = 1;
}

// Item streaks: the game won't swap one into a full streak slot, so
// first remove the held streak with the game's own "removecurrent",
// then place a real streak item where you stand and hand it over
// like the crafting bench does. The game leaves a floor copy behind,
// which is removed after a moment.
function zfpa_give_item( ref, bundle, use )
{
    // 1. place the new item first: hidden under the floor, or if the
    //    game won't place it there, right at your feet
    spawnoptions = undefined;
    item = undefined;

    if ( level.zfpa_hide_depth > 0 )
    {
        spawnoptions = common_item::function_bc5ff2958b71a708( self.origin - ( 0, 0, level.zfpa_hide_depth ), self.angles );
        item = self zfpa_try_place( ref, spawnoptions );
    }

    if ( !isdefined( item ) )
    {
        spawnoptions = common_item::function_bc5ff2958b71a708( self.origin, self.angles );
        item = self zfpa_try_place( ref, spawnoptions );
    }

    // couldn't place one at all: keep your streak, give a weapon streak instead
    if ( !isdefined( item ) )
    {
        weapon = level.zfpa_weapons[ randomint( level.zfpa_weapons.size ) ];
        zfpa_info( "couldn't place " + ref + ", gave " + weapon + " instead", gettime() );
        wbundle = common_item::function_cf68ad18114498b2( weapon );

        if ( isdefined( wbundle ) )
        {
            self zfpa_give_new( weapon, wbundle, use );
        }

        return;
    }

    // 2. only now remove the streak you're holding
    rc = level.commonitem.itemcallbacks[ "killstreak" ].funcs[ #"removecurrent" ];

    if ( isdefined( rc ) )
    {
        self.zfpa_rc_ok = 0;
        self thread zfpa_remove_call( rc );

        if ( !istrue( self.zfpa_rc_ok ) )
        {
            zfpa_info( "removecurrent errored " + ref, gettime() );
        }

        wait level.zfpa_remove_wait;
    }
    else
    {
        zfpa_info( "removecurrent missing", 1 );
    }

    // 3. hand the new item over (if the game already picked it up
    //    while your slot was empty, there's nothing left to do)
    if ( !isdefined( item ) )
    {
        return;
    }

    self [[ use ]]( bundle, item, 0, spawnoptions );

    // 4. give the game a moment to finish, then remove the floor copy
    //    (removing it straight away cancels the pick-up)
    for ( i = 0; i < level.zfpa_cleanup_wait * 20 && isdefined( item ); i++ )
    {
        wait 0.05;
    }

    if ( isdefined( item ) )
    {
        common_item::function_869d7676e359a627( item, 0 );
    }
}

function zfpa_try_place( ref, spawnoptions )
{
    self.zfpa_item = undefined;
    self.zfpa_place_ok = 0;
    self thread zfpa_place( ref, spawnoptions );

    for ( i = 0; i < 20 && !istrue( self.zfpa_place_ok ); i++ )
    {
        wait 0.05;
    }

    return self.zfpa_item;
}

function zfpa_remove_call( rc )
{
    self [[ rc ]]();
    self.zfpa_rc_ok = 1;
}

function zfpa_place( ref, spawnoptions )
{
    item = common_item::function_325e28c0fb65c36a( ref, 1, spawnoptions );

    if ( isdefined( item ) && isarray( item ) )
    {
        item = item[ 0 ];
    }

    self.zfpa_item = item;
    self.zfpa_place_ok = 1;
}
