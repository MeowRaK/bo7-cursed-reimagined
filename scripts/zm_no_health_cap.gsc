// No Zombie Health Cap v2 - Made by Kazuto

#using scripts\common\callbacks;
#using scripts\common\system;
#using scripts\common\utility;
#using scripts\common\values;
#using scripts\mp\common\perks\zombie\zombie_perks;
#using scripts\mp\common\utility\game_utility;
#using scripts\mp\currency;
#using scripts\mp\interaction;
#using scripts\mp\health_scaling_round;
#using scripts\mp\zm\zm_utility;

#namespace zm_no_health_cap;

function autoexec zm_no_health_cap_autoexec()
{
    level thread zhc_start();
}

// -------------------- SETTINGS --------------------
function private zhc_debug_enabled()
{
    return false;
}

function private zhc_supported_mode()
{
    mode = game_utility::getgametype();
    if ( !isdefined( mode ) || !isstartstr( mode, "zm_" ) )
    {
        return false;
    }
    if ( issubstr( mode, "ztron" ) )
    {
        return false;
    }
    return true;
}

function private zhc_safe_max()
{
    return 2147483647;
}

// Enemies with NO health cap (names from the game's health tables).
function private zhc_uncapped_list()
{
    names = [];
    names[ names.size ] = "health_zombie_base";                 // Zombie
    names[ names.size ] = "health_zombie_base_armored_light";   // Armored zombie
    names[ names.size ] = "health_zombie_base_armored_heavy";   // Heavy (armored) zombie
    names[ names.size ] = "health_zombie_base_armored_agni";    // Fire zombie (armored)
    names[ names.size ] = "health_zombie_shade";                // Ravager
    names[ names.size ] = "health_zombie_base_toxic";           // Toxic zombie
    names[ names.size ] = "health_zombie_base_luna";            // Frost zombie
    names[ names.size ] = "health_zombie_methone";              // Rad-Hound
    names[ names.size ] = "health_zombie_hellhound";            // Hellhound
    names[ names.size ] = "health_zombie_loom_minion";          // Deathspinner (Rex Infernus spider)
    return names;
}

// Every other enemy stops at its health on this round, using the Mister Peeks
// Mayhem health table and cap (same in every mode).
function private zhc_capped_round()
{
    return 85;
}

// Enemies that have their own Mister Peeks Mayhem (_r_mod) health table.
function private zhc_mpm_list()
{
    names = [];
    names[ names.size ] = "health_zombie_ghoul";
    names[ names.size ] = "health_zombie_loom";
    names[ names.size ] = "health_zombie_galileo";
    names[ names.size ] = "health_zombie_mimic";
    names[ names.size ] = "health_zombie_viper";
    names[ names.size ] = "health_zombie_viper_mini";
    names[ names.size ] = "health_zombie_callisto";
    names[ names.size ] = "health_zombie_orion";
    names[ names.size ] = "health_zombie_karkinos";
    return names;
}

// -------------------- START --------------------
function private zhc_start()
{
    level endon( #"game_ended" );

    level.zhc_stages = [];
    if ( zhc_debug_enabled() )
    {
        level thread zhc_debug_stages();
    }
    zhc_stage( "1 script started" );

    for ( i = 0; i < 6000 && !utility::issharedfuncdefined( #"zombie", #"health_scaling_get_starting_health" ); i++ )
    {
        waitframe();
    }
    if ( !utility::issharedfuncdefined( #"zombie", #"health_scaling_get_starting_health" ) )
    {
        zhc_stage( "STOP: game health system not found" );
        return;
    }
    zhc_stage( "2 game health system found" );

    mode = game_utility::getgametype();
    if ( !isdefined( mode ) )
    {
        mode = "undefined";
    }
    if ( !zhc_supported_mode() )
    {
        zhc_stage( "STOP: mode not supported: " + mode );
        return;
    }
    zhc_stage( "3 mode ok: " + mode );

    level.zhc_cache = [];
    waitframe();
    zhc_register();
    logstring( "[No Zombie Health Cap] Initialized - Made by Kazuto" );
    zhc_stage( "4 health cap removed" );

    level thread zhc_keep_registered();
    if ( zhc_debug_enabled() )
    {
        level thread zhc_debug_rounds();
        level callback::add( "on_zombie_ai_damaged", &zhc_debug_on_damaged );
    }
}

function private zhc_stage( stage_msg )
{
    level.zhc_stages[ level.zhc_stages.size ] = stage_msg;
    level notify( #"zhc_stage" );
    if ( zhc_debug_enabled() )
    {
        nengine_store_set( "zhcmod", "stage_" + level.zhc_stages.size, stage_msg );
        nengine_store_save( "zhcmod", "stages" );
    }
}

function private zhc_debug_stages()
{
    level endon( #"game_ended" );

    while ( !isdefined( level.players ) || level.players.size == 0 || !isalive( level.players[ 0 ] ) )
    {
        wait 1;
    }
    wait 5;

    for ( pass = 0; pass < 6; pass++ )
    {
        foreach ( player in level.players )
        {
            player iprintln( "^3[No Health Cap] ^7--- startup check " + ( pass + 1 ) + "/6 ---" );
            foreach ( stage_msg in level.zhc_stages )
            {
                player iprintln( "^3[No Health Cap] ^7" + stage_msg );
            }
        }
        wait 20;
    }
}

function private zhc_register()
{
    utility::registersharedfunc( #"zombie", #"health_scaling_get_starting_health", &zhc_get_starting_health );
}

function private zhc_keep_registered()
{
    level endon( #"game_ended" );

    for ( i = 0; i < 60; i++ )
    {
        wait 1;
        zhc_register();
    }
}

// -------------------- BUNDLE REMAP --------------------
function private zhc_remap( scriptbundle_name )
{
    remapped = scriptbundle_name;
    if ( !isdefined( level.gametypebundle ) || !isdefined( level.gametypebundle.healthreplacementmapping ) )
    {
        return remapped;
    }
    foreach ( entry in level.gametypebundle.healthreplacementmapping )
    {
        if ( entry.originalhealth === hashcat( %"healthscalinground:", scriptbundle_name ) )
        {
            remapped = entry.newhealth;
        }
    }
    return remapped;
}

// -------------------- ENEMY LIST --------------------
function private zhc_is_uncapped( scriptbundle_name, bundle_name )
{
    if ( !isdefined( level.zhc_uncapped_keys ) )
    {
        level.zhc_uncapped_keys = [];
        foreach ( entry_name in zhc_uncapped_list() )
        {
            level.zhc_uncapped_keys[ level.zhc_uncapped_keys.size ] = hashcat( %"healthscalinground:", entry_name );
            level.zhc_uncapped_keys[ level.zhc_uncapped_keys.size ] = hashcat( %"healthscalinground:", entry_name + "_r_mod" );
        }
    }
    key_a = hashcat( %"healthscalinground:", scriptbundle_name );
    key_b = hashcat( %"healthscalinground:", bundle_name );
    foreach ( key in level.zhc_uncapped_keys )
    {
        if ( key === key_a || key === key_b )
        {
            return true;
        }
    }
    return false;
}

function private zhc_mpm_bundle( scriptbundle_name, bundle_name )
{
    if ( !isdefined( level.zhc_mpm_keys ) )
    {
        level.zhc_mpm_keys = [];
        level.zhc_mpm_bundles = [];
        foreach ( entry_name in zhc_mpm_list() )
        {
            mpm_bundle = getscriptbundle( "healthscalinground:" + entry_name + "_r_mod" );
            if ( !isdefined( mpm_bundle ) )
            {
                continue;
            }
            level.zhc_mpm_keys[ level.zhc_mpm_keys.size ] = hashcat( %"healthscalinground:", entry_name );
            level.zhc_mpm_bundles[ level.zhc_mpm_bundles.size ] = mpm_bundle;
            level.zhc_mpm_keys[ level.zhc_mpm_keys.size ] = hashcat( %"healthscalinground:", entry_name + "_r_mod" );
            level.zhc_mpm_bundles[ level.zhc_mpm_bundles.size ] = mpm_bundle;
        }
    }
    key_a = hashcat( %"healthscalinground:", scriptbundle_name );
    key_b = hashcat( %"healthscalinground:", bundle_name );
    for ( i = 0; i < level.zhc_mpm_keys.size; i++ )
    {
        if ( level.zhc_mpm_keys[ i ] === key_a || level.zhc_mpm_keys[ i ] === key_b )
        {
            return level.zhc_mpm_bundles[ i ];
        }
    }
    return undefined;
}

function private zhc_progression_health( progression, base, health_round )
{
    result_health = base;
    if ( health_round > 1 && isdefined( progression ) )
    {
        for ( i = 0; i < progression.size; i++ )
        {
            if ( health_round < progression[ i ].startround )
            {
                break;
            }
            health_per_round = 0;
            if ( isdefined( progression[ i ].healthadded ) )
            {
                health_per_round = progression[ i ].healthadded;
            }
            if ( isdefined( progression[ i + 1 ] ) && health_round >= progression[ i + 1 ].startround )
            {
                health_rounds = progression[ i + 1 ].startround - progression[ i ].startround;
            }
            else
            {
                health_rounds = health_round - progression[ i ].startround;
            }
            result_health += health_per_round * health_rounds;
        }
    }
    return result_health;
}

// -------------------- HEALTH --------------------
function zhc_get_starting_health( scriptbundle_name, current_round, b_ignore_per_player_increase )
{
    if ( !isdefined( scriptbundle_name ) || !isdefined( level.starting_health ) )
    {
        return 100;
    }
    if ( !isdefined( current_round ) )
    {
        current_round = 1;
    }
    ignore_players = 0;
    if ( isdefined( b_ignore_per_player_increase ) && b_ignore_per_player_increase )
    {
        ignore_players = 1;
    }

    bundle_name = zhc_remap( scriptbundle_name );

    num_players = 1;
    if ( !ignore_players )
    {
        if ( isdefined( level.var_b29bf68fec4ea398 ) )
        {
            num_players = level.var_b29bf68fec4ea398;
        }
        else
        {
            num_players = level.players.size;
        }
    }

    if ( !isdefined( level.zhc_cache ) )
    {
        level.zhc_cache = [];
    }
    if ( !isdefined( level.zhc_cache[ bundle_name ] ) )
    {
        level.zhc_cache[ bundle_name ] = [];
    }

    if ( !isdefined( level.zhc_cache[ bundle_name ][ current_round ][ num_players ] ) )
    {
        health_bundle = getscriptbundle( "healthscalinground:" + bundle_name );
        if ( !isdefined( health_bundle ) )
        {
            return self health_scaling_round::get_starting_health( scriptbundle_name, current_round, ignore_players );
        }

        if ( isdefined( health_bundle.overridebasehealth ) && isdefined( self ) )
        {
            self.basehealth = health_bundle.overridebasehealth;
        }

        base = 100;
        if ( isdefined( health_bundle.overridebasehealth ) )
        {
            base = health_bundle.overridebasehealth;
        }
        else if ( isdefined( self ) && isdefined( self.basehealth ) )
        {
            base = self.basehealth;
        }

        progression = health_bundle.healthprogressionlist;
        result_health = zhc_progression_health( progression, base, current_round );

        if ( !zhc_is_uncapped( scriptbundle_name, bundle_name ) )
        {
            cap_bundle = zhc_mpm_bundle( scriptbundle_name, bundle_name );
            if ( !isdefined( cap_bundle ) )
            {
                cap_bundle = health_bundle;
            }
            cap_base = base;
            if ( isdefined( cap_bundle.overridebasehealth ) )
            {
                cap_base = cap_bundle.overridebasehealth;
            }
            // Cap = round-85 health. The bundle's maxhealth is not applied: most
            // tables set it near their round-55 health, which would stop
            // health at ~55 instead of 85. zhc_safe_max() still applies below.
            cap = zhc_progression_health( cap_bundle.healthprogressionlist, cap_base, zhc_capped_round() );
            if ( result_health > cap )
            {
                result_health = cap;
            }
        }

        per_player_increase = health_bundle.numplayerhealthscale;
        if ( isdefined( per_player_increase ) && num_players > 1 )
        {
            result_health += result_health * ( num_players - 1 ) * per_player_increase;
        }

        if ( result_health > zhc_safe_max() )
        {
            result_health = zhc_safe_max();
        }

        if ( level.zhc_cache[ bundle_name ].size >= 10 )
        {
            level.zhc_cache[ bundle_name ] = [];
        }
        if ( !isdefined( level.zhc_cache[ bundle_name ][ current_round ] ) )
        {
            level.zhc_cache[ bundle_name ][ current_round ] = [];
        }
        level.zhc_cache[ bundle_name ][ current_round ][ num_players ] = int( result_health );
    }

    result = level.zhc_cache[ bundle_name ][ current_round ][ num_players ];

    default_scale = 1;
    if ( isdefined( level.gametypebundle ) && isdefined( level.gametypebundle.agenthealthscale ) )
    {
        default_scale = level.gametypebundle.agenthealthscale;
    }
    result *= getdvarfloat( @"scr_agent_health_scale", default_scale );

    if ( result > zhc_safe_max() )
    {
        result = zhc_safe_max();
    }
    return result;
}

// -------------------- DEBUG --------------------
function private zhc_debug_rounds()
{
    level endon( #"game_ended" );

    while ( !isdefined( level.players ) || level.players.size == 0 || !isalive( level.players[ 0 ] ) )
    {
        wait 1;
    }
    wait 3;
    foreach ( player in level.players )
    {
        player iprintlnbold( "^3No Zombie Health Cap ^7is active" );
    }

    last_round = -1;
    while ( true )
    {
        wait 1;
        round_number = zm_utility::get_round_number();
        if ( round_number == last_round )
        {
            continue;
        }

        seen = undefined;
        seen_round = "?";
        foreach ( ai in getaiarray() )
        {
            if ( isdefined( ai ) && isalive( ai ) && isdefined( ai.subclass ) && ai.subclass == "zombie_base" && isdefined( ai.maxhealth ) )
            {
                seen = ai.maxhealth;
                if ( isdefined( ai._blackboard ) && isdefined( ai._blackboard.difficultyround ) )
                {
                    seen_round = ai._blackboard.difficultyround;
                }
                break;
            }
        }
        if ( !isdefined( seen ) )
        {
            continue;
        }
        last_round = round_number;

        msg = "Round " + round_number + " - zombie health " + seen + " (spawned as round " + seen_round + ")";
        logstring( "[No Zombie Health Cap] " + msg );
        nengine_store_set( "zhcmod", "round_" + round_number, msg );
        nengine_store_save( "zhcmod", "stages" );
        if ( isdefined( level.players ) )
        {
            foreach ( player in level.players )
            {
                player iprintln( "^3[No Health Cap] ^7" + msg );
            }
        }
    }
}

function private zhc_debug_on_damaged( dmg_struct )
{
    if ( !isdefined( dmg_struct ) || !isdefined( self ) || !isdefined( self.maxhealth ) || !isdefined( self.health ) )
    {
        return;
    }
    attacker = dmg_struct.eattacker;
    if ( !isdefined( attacker ) || !isplayer( attacker ) )
    {
        return;
    }
    now = gettime();
    if ( isdefined( attacker.zhc_last_hp_msg ) && now - attacker.zhc_last_hp_msg < 250 )
    {
        return;
    }
    attacker.zhc_last_hp_msg = now;

    hit = 0;
    if ( isdefined( dmg_struct.idamage ) )
    {
        hit = int( dmg_struct.idamage );
    }
    left = self.health - hit;
    if ( left < 0 )
    {
        left = 0;
    }
    attacker iprintln( "^3Zombie HP: ^7" + left + " / " + self.maxhealth + "  ^3(hit " + hit + ")" );
}
