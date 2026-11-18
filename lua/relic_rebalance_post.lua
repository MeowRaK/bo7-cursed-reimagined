-- Relic Rebalance - relic menu text (companion to zm_relic_rebalance.gsc)  v3
-- Install: Assets/Lua/relic_rebalance_post.lua (same pack as the .gsc).
--
-- The game's relic widgets (relic select menu, the pause menu's relic box)
-- turn each description into text with Engine.localize, then show it. This
-- file wraps Engine.localize: when the finished text is a reworked relic's
-- stock description, the new description is returned instead.
--
-- v3: built to stay light. Every lookup is cached, nothing is created per
-- call, and loading the file again (new match / UI reload) replaces the old
-- hook instead of stacking another one on top.

-- -------------------- SETTINGS --------------------
-- 1 = small status line in the bottom-left of the main menu.
local BADGE = 0
-- 1 = with the Rocket relic, Totenreich's Glocke and Wunderbarrage still show
-- at the crafting table (once unlocked) while other scorestreaks are hidden.
local ROCKET_SHOW_TOTENREICH = 1
local ROCKET_KEEP = { "zm_bernard_primary", "zm_bernard_secondary" }
-- 1 = swap relic descriptions where menus read them from data models.
-- 0 = off (use this to rule it out if a menu crashes).
local MODEL_HOOK = 1
-- 1 = change the relic descriptions in the relic item data, but only when
-- the stored value is plain text (anything else crashed the relic menu).
-- 0 = never touch the relic item data.
local RELIC_PATCH = 1
-- 1 = recognise relic text codes by asking the game what text they stand for
-- (only for values of the game's "xhash" text-code type, once per value).
-- 0 = off (if a menu crashes with it on).
local LOCALIZE_CODES = 1
-- 1 = re-apply the new text every frame on elements showing a reworked relic
-- (the relic select menu's info box sets the stock text again on its own).
local REAPPLY = 1
-- 1 = also swap relic text in a match (pause menu relic box).
-- 0 = menus only (safer: a match passes far more values through the hooks).
local MATCH_TEXT = 1
-- 1 = in a match, show the .gsc's crash diagnostics (dvar rr_diag) in the
-- top-left corner. Record your screen: the last frame before a crash shows
-- what the mod was doing.
local DIAG_HUD = 0

-- short = the one-line description shown everywhere. text = longer notes
-- (not shown). stock = the game's English text (used to recognise it).
local RELICS = {
    { id = "spork", short = "Zombies and armored zombies deal 50% more damage, 100 base health, and more changes", name = "Golden Spork",
      key = "zm_sat_r_mod/golden_spork_modifier", stock = "Enemies deal double damage",
      text = "Zombies deal 50% more damage (bosses, elites and specials deal normal damage). "
          .. "Max health is 100 without Juggernog. "
          .. "Armored zombies hit you as hard as normal zombies, but wear your armor down faster. "
          .. "Armor blocks less damage; other enemies wear it down at its normal rate." },
    { id = "pen", short = "Mimics appear every other round and vanish at round end", name = "Lawyer's Pen",
      key = "zm_sat_r_mod/lawyers_pen_modifier", stock = "Mimic props have infiltrated the map",
      text = "Every other round, killed zombies can leave Mimics disguised as items behind. "
          .. "Any Mimic props left when the round ends disappear." },
    { id = "wings", short = "Max one power-up per round, in the classic drop cycle", name = "Dragon Wings",
      key = "zm_sat_r_mod/dragon_wings_modifier", stock = "Normal Power-Up spawns are disabled",
      text = "At most one power-up can drop each round (none is guaranteed). On max ammo rounds nothing drops except "
          .. "the max ammo at the end. Power-ups follow the classic shuffled drop cycle. Boss fights drop power-ups like normal." },
    { id = "rocket", short = "Crafting universal scorestreaks is disabled", name = "Rocket",
      key = "zm_sat_r_mod/rocket_modifier", stock = "No Scorestreaks",
      text = "Scorestreaks can't be crafted, but still show up as loot: drops, T.E.D.D. task rewards "
          .. "and O.S.C.A.R.'s Golden Death Machine. Totenreich's Glocke and Wunderbarrage can still be "
          .. "crafted, and Kowakujo's Remote Robot can still be bought." },
    { id = "pswitch", short = "Equipment switches each round to one of the same rarity", name = "Power Switch",
      key = "zm_sat_r_mod/power_switch_modifier", stock = "Tactical and lethal equipment randomizes each round",
      text = "At the end of each round your lethal and tactical switch to a different one of the same rarity. "
          .. "Kazimirs, Monkey Bombs and Psych Grenades only switch between each other." },
    { id = "gramo", short = "Every shot costs 2 ammo, but all weapons deal double damage", name = "Gramophone",
      key = "zm_sat_r_mod/gramophone_modifier", stock = "Bullets deal increased damage but each shot consumes 2 bullets.",
      text = "Every shot from any weapon costs an extra round of ammo, but all your weapons deal double damage." },
    { id = "vrill", short = "Only 4 machine-bought Perk-a-Colas; other perks stack on top", name = "Vrill Sphere",
      key = "zm_sat_r_mod/wardens_key_modifier", stock = "Players can only carry 4 Perk-a-Colas",
      text = "You can only carry 4 Perk-a-Colas bought from perk machines. "
          .. "Perk cans and Free Perk power-ups don't count toward the limit and stack on top." },
    { id = "elephant", short = "Health regen delay is increased to 3 seconds", name = "Stuffed Elephant",
      key = "zm_sat_r_mod/stu_ele_modifier", stock = "Health regen delay is increased",
      text = "Health regen delay is increased to 3 seconds." },
    { id = "valk", short = "Only 1 electric field can spawn per round where you stay", name = "Valkyrie Helmet",
      key = "zm_sat_r_mod/valkhelmet", stock = "Areas you stay in start to spawn electric fields that damage you.",
      text = "Areas you stay in spawn electric fields that damage you, but only 1 can spawn per round." },
    { id = "film", short = "Only one weapon can be at max Pack-a-Punch", name = "Film Reel",
      key = "zm_sat_r_mod/film_reel_modifier", stock = "Player can only carry one Pack-a-Punch weapon",
      text = "Only one weapon can be at the max Pack-a-Punch level; every other weapon tops out one level below "
          .. "(PaP 3 for the rest when PaP 4 is unlocked, otherwise PaP 2)." },
    { id = "vials", short = "Augments are randomized each match", name = "Blood Vials",
      key = "zm_sat_r_mod/blood_vials_modifier", stock = "All Augments are turned off",
      text = "Your augments are randomized when you load into the match. "
          .. "Your saved augment setup is not changed." },
    { id = "cph", short = "Perk decay - every 350 kills, you lose a perk", name = "Civil Protector Head",
      key = "zm_sat_r_mod/civil_protector_head_modifier", stock = "Perk decay - every 100 kills, you lose a perk",
      text = "Perk decay - every 350 kills, you lose a perk" },
    { id = "mangler", short = "No Arsenal; Ultra Aether Tools and PaP 4 crystals can drop", name = "Mangler Helmet",
      key = "zm_sat_r_mod/manglerhelment_modifier", stock = "No Arsenal",
      text = "No Arsenal. Ultra Aether Tools and PaP 4 Aether Crystals can drop; from round 40 they replace "
          .. "Legendary Aether Tools and PaP 3 Aether Crystals." },
    { id = "agarthan", short = "Every other round zombies become a random element", name = "Agarthan Device",
      key = "zm_sat_r_mod/agarthan_device_modifier", stock = "Each round, the type of zombies will be randomized",
      text = "Every other round the zombies change to a random elemental type. They never super sprint, "
          .. "and armored zombies don't spawn during those rounds." },
    { id = "mubox", short = "Only critical hits do damage (wonder weapons exempt); critical kills give 200 points", name = "Music Box",
      key = "zm_sat_r_mod/mu_box_modifier", stock = "Enemies only take critical damage",
      text = "Enemies only take critical damage. Wonder weapons ignore this and deal full damage. "
          .. "Critical kills give double points." },
    { id = "arnie", short = "Hard armor: less front armor protection; bosses, specials and elites hit armor as normal", name = "Dancing Arnie",
      key = "zm_sat_r_mod/dancing_arnie_modifier", stock = "All Perk-a-Cola machines have been cursed and now give out random Perk-a-Colas",
      text = "Perk machines work normally. Against normal zombies, Turtle Shell blocks half its normal armor share from the front "
          .. "and other Juggernog major augments block nothing from the front; back hits are unchanged. "
          .. "Specials, elites and boss attacks use normal armor. Needs Cursed Reimagined." },
}


-- -------------------- SETUP --------------------
pcall(function()
local C = rawget(_G, "CLUA")
local H = rawget(_G, "xhash") or rawget(_G, "PushXHash") or (type(C) == "table" and C.PushXHash)

-- Turn off an older copy of this file (its timer stops, its hooks pass through).
local old = rawget(_G, "RelicRebalanceText")
if type(old) == "table" then old.enabled = false end
local S = { enabled = true, version = 3, locHooks = 0, swaps = 0, ticks = 0 }
rawset(_G, "RelicRebalanceText", S)

-- Survives reloads: wrapper -> the game's original function.
local REG = rawget(_G, "RelicRebalanceReg")
if type(REG) ~= "table" then
    REG = { orig = setmetatable({}, { __mode = "k" }) }
    rawset(_G, "RelicRebalanceReg", REG)
end
local function unwrap(f)
    local guard = 0
    while REG.orig[f] ~= nil and guard < 50 do f = REG.orig[f]; guard = guard + 1 end
    return f
end

local function hx(name)
    if type(H) ~= "function" then return nil end
    local ok, v = pcall(H, name)
    if ok then return v end
end
local function engine() return rawget(_G, "Engine") end
local function get(object, key)
    if object == nil then return nil end
    local ok, v = pcall(function() return object[key] end)
    if ok and v ~= nil then return v end
    local k = hx(key)
    if k == nil then return nil end
    ok, v = pcall(function() return object[k] end)
    if ok then return v end
end

-- -------------------- LOOKUP (cached) --------------------
-- Texts are compared on letters and digits only (case, spaces, punctuation,
-- colour codes and hidden characters ignored): the game's returned text can
-- carry invisible characters the plain stock string doesn't have.
local function squash(t)
    t = string.lower(t):gsub("%^%d", "")
    return (t:gsub("[^%a%d]", ""))
end
local byStock = {}
for _, r in ipairs(RELICS) do byStock[squash(r.stock)] = r end

local cache = {}          -- finished text -> relic or false
local cacheSize = 0
local function short(t, n)
    t = tostring(t):gsub("%s+", " ")
    if #t > n then t = t:sub(1, n) .. "..." end
    return t
end
local function relicForText(out)
    local hit = cache[out]
    if hit ~= nil then return hit end
    local r = false
    if #out < 200 then
        r = byStock[squash(out)] or false
    end
    if cacheSize > 2000 then cache = {}; cacheSize = 0 end
    cache[out] = r
    cacheSize = cacheSize + 1
    return r
end

-- In a match the short text is used (one line per relic in the pause box).
local inMatch = false
local function newText(r)
    -- One short line everywhere (menus, lobby list, pause menu).
    return r.short or r.text
end

-- -------------------- HOOK: Engine.localize --------------------
local function hookLocalize()
    local E = engine()
    if E == nil then return end
    local keys = { "localize", "Localize" }
    for _, n in ipairs({ "localize", "Localize", "0xaed84c33ec5f01ea" }) do
        local h = hx(n)
        if h ~= nil then keys[#keys + 1] = h end
    end
    local count = 0
    for _, key in ipairs(keys) do
        local ok, cur = pcall(function() return E[key] end)
        if ok and type(cur) == "function" then
            if REG.orig[cur] ~= nil and REG.owner == S then
                count = count + 1          -- already ours (this copy)
            else
                local original = unwrap(cur)
                S.origLoc = S.origLoc or original
                local wrapped = function(ref, ...)
                    local out = original(ref, ...)
                    if S.enabled and type(out) == "string" and (not inMatch or MATCH_TEXT >= 1) then
                        local r = relicForText(out)
                        if r then
                            S.swaps = S.swaps + 1
                            return newText(r)
                        end
                    end
                    return out
                end
                REG.orig[wrapped] = original
                if not pcall(rawset, E, key, wrapped) then
                    pcall(function() E[key] = wrapped end)
                end
                local okV, now = pcall(function() return E[key] end)
                if okV and now == wrapped then count = count + 1 end
            end
        end
    end
    REG.owner = S
    S.locHooks = count
end

local function markLocalized(text)
    local fn = get(engine(), "MarkLocalized")
    if type(fn) == "function" then
        local ok, v = pcall(fn, text)
        if ok and v ~= nil then return v end
    end
    return text
end

-- -------------------- ROCKET: Totenreich crafting items --------------------
-- The Rocket relic hides scorestreaks in the crafting menu. The menu reads
-- each item's bundle (Engine.getscriptbundle) and, it seems, hides items
-- whose loot type is a scorestreak. For the two Totenreich items it gets a
-- copy whose loot type is "INVALID" (what self revive / armor use), so the
-- scorestreak hide skips them. Crafting itself is decided by the game script.
S.rocketOn = false
S.bundleSwaps = 0
local KEY_ITEMREF = hx("itemref")
local KEY_LOOTTYPE = hx("lootitemtype")
local keepRef = {}
for _, r in ipairs(ROCKET_KEEP) do
    keepRef[r] = true
    local h = hx(r)
    if h ~= nil then pcall(function() keepRef[h] = true end) end
end

local function field(t, plain, hashed)
    local v = nil
    pcall(function() v = rawget(t, plain) end)
    if v == nil and hashed ~= nil then pcall(function() v = rawget(t, hashed) end) end
    return v
end

local KEY_MOD = hx("modifier")
local byIdLookup = {}
for _, r in ipairs(RELICS) do byIdLookup[r.id] = r end
local byKey = {}
for _, r in ipairs(RELICS) do byKey[string.lower(r.key)] = r end
S.relicBundles = 0

-- Rocket: the two Totenreich items get their loot type changed in place
-- while the relic is on (and put back when it's off). No copies are handed
-- to the menu, so it always gets the game's own item data.
local patched = {}   -- bundle -> { key = original value, ... }
local function setType(b, repl)
    local saved = patched[b] or {}
    for _, k in ipairs({ "lootitemtype", KEY_LOOTTYPE }) do
        if k ~= nil then
            local okR, cur = pcall(rawget, b, k)
            if okR and cur ~= nil and saved[k] == nil then
                saved[k] = cur
                pcall(rawset, b, k, repl)
            end
        end
    end
    patched[b] = saved
    S.bundleSwaps = S.bundleSwaps + 1
end
local function restoreTypes()
    for b, saved in pairs(patched) do
        for k, v in pairs(saved) do pcall(rawset, b, k, v) end
    end
    patched = {}
end
S.restoreTypes = restoreTypes

local checked = setmetatable({}, { __mode = "k" })   -- bundles that aren't the two items
local function adjustBundle(b)
    if not S.rocketOn or ROCKET_SHOW_TOTENREICH < 1 or type(b) ~= "table" then return b end
    if patched[b] ~= nil or checked[b] then return b end
    local ref = field(b, "itemref", KEY_ITEMREF)
    if type(ref) ~= "string" or not keepRef[ref] then
        checked[b] = true   -- not one of the two: never look at it again
        return b
    end
    local cur = field(b, "lootitemtype", KEY_LOOTTYPE)
    if type(cur) ~= "string" then return b end   -- only a plain text type is changed
    setType(b, "INVALID")
    return b
end

local function hookBundles()
    local E = engine()
    if E == nil then return end
    local keys = { "getscriptbundle", "GetScriptBundle" }
    for _, n in ipairs({ "getscriptbundle", "0xf06093d047200548" }) do
        local h = hx(n)
        if h ~= nil then keys[#keys + 1] = h end
    end
    local count = 0
    for _, key in ipairs(keys) do
        local ok, cur = pcall(function() return E[key] end)
        if ok and type(cur) == "function" then
            if REG.orig[cur] ~= nil and REG.bundleOwner == S then
                count = count + 1
            else
                local original = unwrap(cur)
                local wrapped = function(...)
                    local b = original(...)
                    if S.enabled and S.rocketOn and type(b) == "table" and not checked[b] then
                        local okA, r = pcall(adjustBundle, b)
                        if okA then return r end
                    end
                    return b
                end
                REG.orig[wrapped] = original
                if not pcall(rawset, E, key, wrapped) then
                    pcall(function() E[key] = wrapped end)
                end
                local okV, now = pcall(function() return E[key] end)
                if okV and now == wrapped then count = count + 1 end
            end
        end
    end
    REG.bundleOwner = S
    S.bundleHooks = count
end

-- -------------------- RELIC DATA (patched in place) --------------------
-- What the game's menu code does (read from the compiled relic widgets):
-- the relic's item data (script bundle) is kept in a data model, a relic
-- utility returns its "modifier" field, and the widget passes that straight
-- to setText. The menu grabbed its functions before this file loaded, so
-- hooks never see it. Instead each reworked relic's item data is fetched
-- here (the game caches them, so it's the same object the menu holds) and
-- its "modifier" field is set to the new text. Matched by loot id.
local RELIC_ASSETS = {
    vials = { 102253, "sat_zm_firefly_beta_relic" },
    wings = { 102250, "sat_zm_firefly_epsilon_relic" },
    pen = { 102256, "sat_zm_firefly_iota_relic" },
    vrill = { 102252, "sat_zm_firefly_xi_relic" },
    gramo = { 132623, "sat_zm_hornet_theta_cr" },
    valk = { 132625, "sat_zm_hornet_virgo_cr" },
    film = { 132621, "sat_zm_hornet_zeta_cr" },
    agarthan = { 132213, "sat_zm_locust_alpha_cr" },
    mubox = { 132217, "sat_zm_locust_cancer_cr" },
    pswitch = { 132207, "sat_zm_locust_lambda_cr" },
    elephant = { 132211, "sat_zm_locust_taurus_cr" },
    spork = { 123185, "sat_zm_ruby_phi_relic" },
    cph = { 123187, "sat_zm_ruby_upsilon_relic" },
    rocket = { 129756, "zm_sat_mantis_heta_relic" },
    mangler = { 129757, "zm_sat_mantis_sampi_relic" },
    arnie = { 132206, "sat_zm_locust_gamma_cr" },
}
local AH = rawget(_G, "xhashasset") or (type(C) == "table" and C.PushXHashAsset)
local KEY_LOOTID = hx("lootid")
S.relicFound = 0
S.relicPatched = 0
S.codeList = {}       -- { code = text code, relic = relic }
if type(REG.relicOrig) ~= "table" then REG.relicOrig = setmetatable({}, { __mode = "k" }) end

local function bundleLoader()
    local E = engine()
    for _, n in ipairs({ "getscriptbundle", "0xf06093d047200548" }) do
        local h = hx(n)
        if h ~= nil then
            local ok, f = pcall(function() return E[h] end)
            if ok and type(f) == "function" then return unwrap(f) end
        end
    end
    local f = get(E, "GetScriptBundle")
    if type(f) == "function" then return unwrap(f) end
    return nil
end

local function lootidOf(b)
    local v = field(b, "lootid", KEY_LOOTID)
    return tonumber(v)
end

local function findRelicBundle(loader, lootid, asset)
    if type(AH) ~= "function" then return nil end
    for _, name in ipairs({ "relic:" .. asset, asset }) do
        local okH, h = pcall(AH, name)
        if okH and h ~= nil then
            local okB, b = pcall(loader, h)
            if okB and type(b) == "table" and lootidOf(b) == lootid then return b end
        end
    end
    return nil
end

local function patchRelics()
    if RELIC_PATCH < 1 then S.relicLookup = "off"; return end
    S.codeList = {}
    local loader = bundleLoader()
    if loader == nil then S.relicLookup = "no loader"; return end
    if type(AH) ~= "function" then S.relicLookup = "no asset hash"; return end
    local found, patched = 0, 0
    for id, a in pairs(RELIC_ASSETS) do
        local r = byIdLookup[id]
        local b = r and findRelicBundle(loader, a[1], a[2])
        if b then
            found = found + 1
            -- Remember this relic's text code (the value the menu shows).
            local codeKey = KEY_MOD ~= nil and rawget(b, KEY_MOD) or nil
            if codeKey == nil then codeKey = rawget(b, "modifier") end
            if REG.relicOrig[b] and REG.relicOrig[b][KEY_MOD] ~= nil then codeKey = REG.relicOrig[b][KEY_MOD] end
            if codeKey ~= nil then
                S.codeList[#S.codeList + 1] = { code = codeKey, relic = r }
            end
            local keys = {}
            if rawget(b, "modifier") ~= nil then keys[#keys + 1] = "modifier" end
            if KEY_MOD ~= nil and rawget(b, KEY_MOD) ~= nil then keys[#keys + 1] = KEY_MOD end
            if REG.relicOrig[b] == nil then
                local saved = {}
                for _, k in ipairs(keys) do saved[k] = rawget(b, k) end
                REG.relicOrig[b] = saved
            end
            local text = newText(r)
            for _, k in ipairs(keys) do
                local orig = REG.relicOrig[b] and REG.relicOrig[b][k]
                S.relicModType = type(orig)
                -- Only a plain text value is replaced, and with plain text:
                -- the value keeps the type the menu expects.
                if type(orig) == "string" then
                    if pcall(rawset, b, k, text) and rawget(b, k) == text then patched = patched + 1 end
                end
            end
        end
    end
    S.relicFound = found
    S.relicPatched = patched
    -- Safety: each relic's code must give a different key, or the swap is off.
    -- (codes compared with ==, which other Kronos mods use for hashes)
    local same = false
    for i = 1, #S.codeList do
        for j = i + 1, #S.codeList do
            local ok, eq = pcall(function() return S.codeList[i].code == S.codeList[j].code end)
            if not ok or eq then same = true end
        end
    end
    S.codesOk = #S.codeList > 0 and not same
    -- Self test: look up the Golden Spork's own code (a real text code).
    S.selfTest = "not run"
    if LOCALIZE_CODES >= 1 and type(S.origLoc) == "function" then
        for _, e in ipairs(S.codeList) do
            if e.relic.id == "spork" then
                S.codeType = type(e.code)
                local okL, out = pcall(S.origLoc, e.code)
                if not okL then
                    S.selfTest = "lookup error: " .. short(out, 50)
                elseif type(out) ~= "string" then
                    S.selfTest = "lookup gave " .. type(out)
                else
                    S.selfTest = "'" .. short(out, 40) .. "' -> " .. (relicForText(out) and "MATCH" or "no match")
                        .. " (len " .. #out .. ")"
                end
            end
        end
    elseif type(S.origLoc) ~= "function" then
        S.selfTest = "no localize function"
    end
    S.relicLookup = "ok"
end

local function unpatchRelics()
    for b, saved in pairs(REG.relicOrig) do
        for k, v in pairs(saved) do pcall(rawset, b, k, v) end
    end
end
S.unpatchRelics = unpatchRelics

-- -------------------- HOOK: data source subscribers --------------------
-- The relic widgets do element:AddDataSourceSubscriber(element, getter,
-- setter) and the setter calls element:setText(value), where value is the
-- relic's text code. The setter is wrapped: when the value is one of the
-- reworked relics' codes, it gets the new text instead. Only that setText
-- call sees it; the relic data itself is never changed.
S.subHooks = 0
S.subSwaps = 0
S.watch = setmetatable({}, { __mode = "k" })   -- element -> relic it should show
S.reapplied = 0
local PLAIN = { ["nil"] = true, boolean = true, number = true, string = true, table = true, ["function"] = true }
local codeSeen = setmetatable({}, { __mode = "k" })   -- xhash object -> relic or false
S.locLookups = 0
S.eqHits = 0; S.textHits = 0; S.lookFail = 0; S.lookNonString = 0; S.lookCached = 0
S.recentLooks = {}      -- last few lookup results (short)
S.hintLook = nil        -- last lookup result that looks like a relic description
local HINT_WORDS = { "damage", "critical", "perk", "power-up", "powerup", "scorestreak", "augment", "arsenal",
    "mimic", "regen", "electric", "pack-a-punch", "equipment", "zombies", "ammo crate", "bullet" }
local function noteLook(out)
    local r = S.recentLooks
    if r[#r] ~= out then
        r[#r + 1] = out
        if #r > 3 then table.remove(r, 1) end
    end
    local low = string.lower(out)
    for _, w in ipairs(HINT_WORDS) do
        if low:find(w, 1, true) then S.hintLook = out; break end
    end
end
local function swapCode(v)
    local tv = type(v)
    if PLAIN[tv] then return nil end
    if S.codesOk then
        for i = 1, #S.codeList do
            local e = S.codeList[i]
            local ok, eq = pcall(function() return v == e.code end)
            if ok and eq then S.eqHits = S.eqHits + 1; S.lastHow = "same object"; return e.relic end
        end
    end
    -- Same code, different object: ask the game what text it stands for.
    if LOCALIZE_CODES < 1 or tv ~= "xhash" or type(S.origLoc) ~= "function" then return nil end
    local okC, hit = pcall(function() return codeSeen[v] end)
    if okC and hit ~= nil then
        S.lookCached = S.lookCached + 1
        if hit then S.lastHow = "text (cached)" end
        return hit or nil
    end
    hit = false
    local ok, out = pcall(S.origLoc, v)
    S.locLookups = S.locLookups + 1
    if not ok then
        S.lookFail = S.lookFail + 1
        S.lastLookErr = short(out, 60)
    elseif type(out) ~= "string" then
        S.lookNonString = S.lookNonString + 1
    else
        noteLook(out)
        hit = relicForText(out) or false
        if hit then S.textHits = S.textHits + 1; S.lastHow = "text" end
    end
    pcall(function() codeSeen[v] = hit end)
    return hit or nil
end

local function wrapSubscribe(holder, key)
    local okC, cur = pcall(rawget, holder, key)
    if not okC or type(cur) ~= "function" then return false end
    if REG.orig[cur] ~= nil and REG.subOwner == S then return true end
    local original = unwrap(cur)
    local wrapped = function(self, elem, getter, setter, ...)
        S.subCalls = (S.subCalls or 0) + 1
        if S.enabled and type(setter) == "function" then
            local inner = setter
            setter = function(v, ...)
                if inMatch and MATCH_TEXT < 1 then return inner(v, ...) end
                local el = ...
                S.setterCalls = (S.setterCalls or 0) + 1
                local tv = type(v)
                S.setterTypes = S.setterTypes or {}
                S.setterTypes[tv] = (S.setterTypes[tv] or 0) + 1
                local r
                if tv == "string" then
                    r = relicForText(v)
                    if r then S.plainStock = (S.plainStock or 0) + 1; S.lastHow = "plain text" end
                else
                    r = swapCode(v)
                end
                -- Remember which element shows a reworked relic (or forget it
                -- when it's given anything else), for the per-frame re-apply.
                if el ~= nil then
                    pcall(function() S.watch[el] = r or nil end)
                end
                if r then
                    S.subSwaps = S.subSwaps + 1
                    S.lastSwap = r.name .. " via " .. tostring(S.lastHow) .. (inMatch and " (match)" or " (menu)")
                    local okI, res = pcall(inner, markLocalized(newText(r)), ...)
                    if not okI then
                        S.innerErr = (S.innerErr or 0) + 1
                        S.lastInnerErr = short(res, 60)
                        return inner(v, ...)
                    end
                    return res
                end
                return inner(v, ...)
            end
        end
        return original(self, elem, getter, setter, ...)
    end
    REG.orig[wrapped] = original
    if pcall(rawset, holder, key, wrapped) then return true end
    return false
end

local function hookSubscribers()
    local L = rawget(_G, "LUI")
    if L == nil then return end
    local holders = {}
    local function add(t) if type(t) == "table" then holders[#holders + 1] = t end end
    for _, n in ipairs({ "UIElement", "UIText", "UIStyledText", "UIImage" }) do add(get(L, n)) end
    -- The shared method table behind element objects.
    for _, n in ipairs({ "UIElement", "UIStyledText" }) do
        local okN, el = pcall(function() return get(get(L, n), "new")() end)
        if okN and el ~= nil then
            local okM, mt = pcall(getmetatable, el)
            if okM and type(mt) == "table" then
                add(mt)
                add(rawget(mt, "__index"))
            end
            pcall(function() el:closeTree() end)
        end
    end
    local count, seen = 0, {}
    for _, h in ipairs(holders) do
        if not seen[h] then
            seen[h] = true
            for _, key in ipairs({ "AddDataSourceSubscriber", hx("AddDataSourceSubscriber") }) do
                if key ~= nil and wrapSubscribe(h, key) then count = count + 1 end
            end
        end
    end
    REG.subOwner = S
    S.subHooks = count
end

-- -------------------- HOOK: data models --------------------
-- The relic menu keeps each relic's description in a data model and the
-- widgets read it back with model:GetValue(). Wrapping GetValue (and
-- SetValue) on the shared model type swaps the description wherever it's
-- read, even when the widget turns it into text on its own.
S.modelHooks = 0
S.modelSwaps = 0
local strCache = {}
local strCacheSize = 0

local function swapValue(v)
    local t = type(v)
    if t == "string" then
        local hit = strCache[v]
        if hit == nil then
            hit = false
            if #v < 140 then
                local k = string.lower(v):gsub("^&#", ""):gsub("^&", ""):gsub("^#", "")
                hit = byKey[k] or relicForText(v) or false
            end
            if strCacheSize > 2000 then strCache = {}; strCacheSize = 0 end
            strCache[v] = hit
            strCacheSize = strCacheSize + 1
        end
        return hit
    end
    -- Anything that isn't text (icons, ids, numbers, hashes) is left alone:
    -- never handed to localize, which can crash the game on the wrong type.
    return false
end

local function wrapModelMethod(holder, name, isGet)
    local keys = { name }
    local h = hx(name)
    if h ~= nil then keys[#keys + 1] = h end
    for _, key in ipairs(keys) do
        local okC, cur = pcall(function() return rawget(holder, key) end)
        if okC and type(cur) == "function" and REG.orig[cur] == nil then
            local original = cur
            local wrapped
            if isGet then
                wrapped = function(self, ...)
                    local v = original(self, ...)
                    if S.enabled then
                        local r = swapValue(v)
                        if r then
                            S.modelSwaps = S.modelSwaps + 1
                            return markLocalized(newText(r))
                        end
                    end
                    return v
                end
            else
                wrapped = function(self, a, b, ...)
                    if S.enabled then
                        -- SetValue(controller, value) or SetValue(value)
                        if b ~= nil then
                            local r = swapValue(b)
                            if r then S.modelSwaps = S.modelSwaps + 1; return original(self, a, markLocalized(newText(r)), ...) end
                        else
                            local r = swapValue(a)
                            if r then S.modelSwaps = S.modelSwaps + 1; return original(self, markLocalized(newText(r)), b, ...) end
                        end
                    end
                    return original(self, a, b, ...)
                end
            end
            REG.orig[wrapped] = original
            if pcall(rawset, holder, key, wrapped) then S.modelHooks = S.modelHooks + 1 end
        elseif okC and type(cur) == "function" and REG.orig[cur] ~= nil then
            -- already wrapped by an older copy of this file: rewrap the original
            local original = unwrap(cur)
            pcall(rawset, holder, key, original)
            return wrapModelMethod(holder, name, isGet)
        end
    end
end

-- Find the shared method table of data models: take any model the game
-- hands out and look at its metatable.
local function methodTableOf(model)
    if model == nil then return nil end
    local okM, mt = pcall(getmetatable, model)
    if not okM or type(mt) ~= "table" then return nil end
    local idx = rawget(mt, "__index")
    if type(idx) == "table" then
        local g = rawget(idx, "GetValue")
        if g == nil and hx("GetValue") ~= nil then g = rawget(idx, hx("GetValue")) end
        if type(g) == "function" then return idx end
    end
    local g = rawget(mt, "GetValue")
    if type(g) == "function" then return mt end
    return nil
end

local function findModel()
    local DS = rawget(_G, "DataSources")
    if type(DS) == "table" then
        local tries = 0
        for _, ds in pairs(DS) do
            tries = tries + 1
            if tries > 400 then break end
            if type(ds) == "table" then
                local gm = rawget(ds, "GetModel")
                if gm == nil and hx("GetModel") ~= nil then gm = rawget(ds, hx("GetModel")) end
                if type(gm) == "function" then
                    local ok, m = pcall(gm, 0)
                    if ok and methodTableOf(m) then return m end
                    ok, m = pcall(gm, ds, 0)
                    if ok and methodTableOf(m) then return m end
                end
            end
        end
    end
    local E = engine()
    for _, n in ipairs({ "GetGlobalModel", "getglobalmodel", "GetModelForController", "getmodelforcontroller" }) do
        local f = get(E, n)
        if type(f) == "function" then
            local ok, m = pcall(f, 0)
            if ok and methodTableOf(m) then return m end
            ok, m = pcall(f)
            if ok and methodTableOf(m) then return m end
        end
    end
    return nil
end

local function hookModels()
    if MODEL_HOOK < 1 then S.modelLookup = "off"; return end
    if S.modelHooks > 0 then return end
    local m = findModel()
    local holder = methodTableOf(m)
    if holder == nil then S.modelLookup = "no model found"; return end
    wrapModelMethod(holder, "GetValue", true)
    wrapModelMethod(holder, "SetValue", false)
    S.modelLookup = "ok"
end

local HD = rawget(_G, "xhashdvar") or rawget(_G, "PushXHashDvar") or (type(C) == "table" and C.PushXHashDvar)
local function readDvarString(name)
    local D = rawget(_G, "Dvar")
    local fn = get(D, "GetDvarString")
    if type(fn) ~= "function" then return "" end
    if type(HD) == "function" then
        local okH, key = pcall(HD, name)
        if okH then
            local ok, v = pcall(fn, key)
            if ok and v ~= nil then return tostring(v) end
        end
    end
    local ok, v = pcall(fn, name)
    if ok and v ~= nil then return tostring(v) end
    return ""
end

local function readRelics()
    local D = rawget(_G, "Dvar")
    local fn = get(D, "GetDvarString")
    if type(fn) ~= "function" then return "" end
    if type(HD) == "function" then
        local okH, key = pcall(HD, "rr_relics")
        if okH then
            local ok, v = pcall(fn, key)
            if ok and v ~= nil then return tostring(v) end
        end
    end
    local ok, v = pcall(fn, "rr_relics")
    if ok and v ~= nil then return tostring(v) end
    return ""
end

-- -------------------- STATUS LINE + TIMER --------------------
local function newElement(kind)
    local f = get(get(rawget(_G, "LUI"), kind), "new")
    if type(f) ~= "function" then error("no " .. kind, 0) end
    return f()
end
local function call(object, key, ...)
    local f = get(object, key)
    if type(f) == "function" then return f(object, ...) end
end
local function pc(object, key, ...) return pcall(call, object, key, ...) end
local function displayParent()
    local L = rawget(_G, "LUI")
    local okR, root = pcall(function() return call(get(L, "UIRoot"), "GetRootForControllerIndex", 0) end)
    if not okR or type(get(root, "addElement")) ~= "function" then return nil end
    for _ = 1, 16 do
        local okP, parent = pcall(call, root, "getParent")
        if not okP or not parent or parent == root then break end
        root = parent
    end
    return root
end

local function clearBadge()
    if S.badge then pc(S.badge, "closeTree") end
    S.badge = nil; S.badgeText = nil; S.badgeTexts = nil; S.badgeLast = nil; S.badgeParent = nil
end

local function badgeLines()
    local L = {}
    local types = {}
    for k, v in pairs(S.setterTypes or {}) do types[#types + 1] = k .. " " .. v end
    L[#L + 1] = "RELIC REBALANCE LUA v3h  |  in match: " .. tostring(inMatch) .. "  |  rocket on: " .. tostring(S.rocketOn)
        .. "  |  Glocke/Wunderbarrage type swaps: " .. (S.bundleSwaps or 0)
    L[#L + 1] = "1 relic codes: found " .. S.relicFound .. "/15 (" .. tostring(S.relicLookup) .. "), code type " .. tostring(S.codeType)
        .. ", unique " .. tostring(S.codesOk) .. "  |  self test (Golden Spork code): " .. tostring(S.selfTest)
    L[#L + 1] = "2 subscriber hook: " .. S.subHooks .. " installed, called " .. (S.subCalls or 0) .. "x, setters ran " .. (S.setterCalls or 0)
        .. "x  [" .. table.concat(types, ", ") .. "]"
    L[#L + 1] = "3 matching: same-object " .. (S.eqHits or 0) .. ", by text " .. (S.textHits or 0) .. ", plain stock text " .. (S.plainStock or 0)
        .. "  |  lookups " .. (S.locLookups or 0) .. " (cached " .. (S.lookCached or 0) .. ", errors " .. (S.lookFail or 0)
        .. ", not text " .. (S.lookNonString or 0) .. ")" .. (S.lastLookErr and ("  last error: " .. S.lastLookErr) or "")
    local watching = 0
    for _ in pairs(S.watch) do watching = watching + 1 end
    L[#L + 1] = "4 swaps: " .. S.subSwaps .. "  |  watching " .. watching .. " elements, re-applied " .. S.reapplied .. "x" .. "  |  last: " .. tostring(S.lastSwap or "none") .. "  |  setter errors after swap: "
        .. (S.innerErr or 0) .. (S.lastInnerErr and (" (" .. S.lastInnerErr .. ")") or "")
    local fw = 0
    for _ in pairs(S.focusWidgets) do fw = fw + 1 end
    L[#L + 1] = "7 info box: builder hook " .. tostring(S.builderHooked == true) .. ", built " .. S.focusBuilt .. ", live " .. fw
        .. ", data " .. tostring(S.focusValType) .. " -> " .. tostring(S.focusInnerType) .. ", swaps " .. S.focusSwaps
        .. ", last " .. tostring(S.lastFocus or "none") .. (S.focusNoEl and "  (no 'modifier' element found)" or "")
    local recent = {}
    for _, t in ipairs(S.recentLooks or {}) do recent[#recent + 1] = "'" .. short(t, 28) .. "'" end
    L[#L + 1] = "5 last lookups: " .. (#recent > 0 and table.concat(recent, "  ") or "none")
        .. "  |  last relic-like text: " .. (S.hintLook and ("'" .. short(S.hintLook, 45) .. "'") or "none")
    L[#L + 1] = "6 other hooks: localize " .. S.locHooks .. ", bundle " .. (S.bundleHooks or 0) .. ", model " .. S.modelHooks
        .. " (" .. tostring(S.modelLookup) .. ")  |  settings: RELIC_PATCH " .. RELIC_PATCH .. ", LOCALIZE_CODES " .. LOCALIZE_CODES
        .. ", ROCKET_SHOW_TOTENREICH " .. ROCKET_SHOW_TOTENREICH .. ", MODEL_HOOK " .. MODEL_HOOK
    return L
end

local LINE_H = 20
local function updateBadge()
    if BADGE < 1 or inMatch then
        if S.badge then clearBadge() end
        return
    end
    local parent = displayParent()
    if not parent then return end
    local lines = badgeLines()
    if not S.badge or S.badgeParent ~= parent or #(S.badgeTexts or {}) ~= #lines then
        clearBadge()
        local frame = newElement("UIElement")
        pc(frame, "setPriority", 1000)
        pc(frame, "SetHandleMouse", false)
        call(parent, "addElement", frame)
        local h = #lines * LINE_H + 6
        pc(frame, "SetAnchorsAndPosition", 0, 1, 1, 0, 20, 1900, -(h + 40), -40)
        local fonts = rawget(_G, "FONT_HANDLE")
        local font = get(fonts, "SecondaryRegular") or get(fonts, "PrimaryRegular")
        S.badgeTexts = {}
        for i = 1, #lines do
            local t = newElement("UIStyledText")
            pc(t, "SetAnchorsAndPosition", 0, 1, 0, 1, 0, 1880, (i - 1) * LINE_H, (i - 1) * LINE_H + 18)
            if font then pc(t, "SetFont", font) end
            pc(t, "SetFontSize", 15 * (tonumber(rawget(_G, "_PT")) or 1))
            pc(t, "SetRGB", i == 1 and 0xffc94a or 0x6fd3ff)
            pc(t, "SetAlignment", 0)
            call(frame, "addElement", t)
            S.badgeTexts[i] = t
        end
        S.badge = frame; S.badgeParent = parent; S.badgeLast = {}
    end
    for i, line in ipairs(lines) do
        if S.badgeLast[i] ~= line then
            pc(S.badgeTexts[i], "setText", markLocalized(line))
            S.badgeLast[i] = line
        end
    end
end

-- -------------------- RELIC INFO BOX (relic select menu) --------------------
-- FocusedRelicInformation keeps its description text element in the field
-- "modifier" and reads the relic from its own data source. The widget is
-- caught when the menu builds it; every frame the relic it shows is read and
-- the new text set straight on that element.
S.focusWidgets = setmetatable({}, { __mode = "k" })
S.focusBuilt = 0
S.focusSwaps = 0
local FOCUS_KINDS = {}
for _, n in ipairs({ "FocusedRelicInformation", "focusedrelicinformation" }) do
    FOCUS_KINDS[n] = true
    local h = hx(n)
    if h ~= nil then FOCUS_KINDS[h] = true end
end
local function isFocusKind(kind)
    if FOCUS_KINDS[kind] then return true end
    for k in pairs(FOCUS_KINDS) do
        local ok, eq = pcall(function() return k == kind end)
        if ok and eq then return true end
    end
    return false
end

local function hookBuilder()
    local B = rawget(_G, "MenuBuilder")
    if type(B) ~= "table" then return end
    local cur = rawget(B, "BuildRegisteredType")
    if type(cur) ~= "function" then return end
    if REG.orig[cur] ~= nil and REG.builderOwner == S then return end
    local original = unwrap(cur)
    local unpackf = rawget(_G, "unpack") or table.unpack
    local wrapped = function(kind, ...)
        local r = { original(kind, ...) }
        if S.enabled and r[1] ~= nil then
            local okK, yes = pcall(isFocusKind, kind)
            if okK and yes then
                pcall(function() S.focusWidgets[r[1]] = true end)
                S.focusBuilt = S.focusBuilt + 1
            end
        end
        return unpackf(r)
    end
    REG.orig[wrapped] = original
    if pcall(rawset, B, "BuildRegisteredType", wrapped) then
        REG.builderOwner = S
        S.builderHooked = true
    end
end

local function fieldAny(t, plain, hashed)
    local v
    pcall(function() v = t[plain] end)
    if v == nil and hashed ~= nil then pcall(function() v = t[hashed] end) end
    return v
end

local function focusValue(w)
    local ok, ds = pcall(function() return w:GetDataSource() end)
    if not ok or ds == nil then return nil end
    local v = fieldAny(ds, "modifier", KEY_MOD)
    S.focusValType = type(v)
    -- A data model: read its value; a table: its "modifier" field.
    local tv = type(v)
    if tv == "table" or tv == "userdata" then
        local okG, g = pcall(function() return v.GetValue end)
        if okG and type(g) == "function" then
            local okV, val = pcall(g, v, 0)
            if okV then v = val end
        end
    end
    if type(v) == "table" then v = fieldAny(v, "modifier", KEY_MOD) end
    S.focusInnerType = type(v)
    return v
end

local function updateFocus()
    for w in pairs(S.focusWidgets) do
        local el = fieldAny(w, "modifier", KEY_MOD)
        if el ~= nil then
            local v = focusValue(w)
            local r = nil
            if type(v) == "string" then r = relicForText(v) else r = swapCode(v) end
            if r then
                local ok = pcall(function() el:setText(markLocalized(newText(r))) end)
                if ok then S.focusSwaps = S.focusSwaps + 1; S.lastFocus = r.name end
            end
        else
            S.focusNoEl = true
        end
    end
end

-- -------------------- CRASH DIAGNOSTICS HUD (in a match) --------------------
local function clearDiag()
    if S.diag then pc(S.diag, "closeTree") end
    S.diag = nil; S.diagTexts = nil; S.diagLast = nil; S.diagParent = nil
end
S.clearDiag = clearDiag

local function updateDiag()
    if DIAG_HUD < 1 or not inMatch then
        if S.diag then clearDiag() end
        return
    end
    local raw = readDvarString("rr_diag")
    if raw == "" then raw = "waiting for the .gsc diagnostics (dvar rr_diag empty)" end
    local lines = {}
    for part in (raw .. "|"):gmatch("([^|]*)|") do lines[#lines + 1] = part end
    local parent = displayParent()
    if not parent then return end
    if not S.diag or S.diagParent ~= parent then
        clearDiag()
        local frame = newElement("UIElement")
        pc(frame, "setPriority", 1000)
        pc(frame, "SetHandleMouse", false)
        call(parent, "addElement", frame)
        pc(frame, "SetAnchorsAndPosition", 0, 1, 0, 1, 20, 1900, 60, 180)
        local fonts = rawget(_G, "FONT_HANDLE")
        local font = get(fonts, "SecondaryRegular") or get(fonts, "PrimaryRegular")
        S.diagTexts = {}
        for i = 1, 5 do
            local t = newElement("UIStyledText")
            pc(t, "SetAnchorsAndPosition", 0, 1, 0, 1, 0, 1880, (i - 1) * 19, (i - 1) * 19 + 17)
            if font then pc(t, "SetFont", font) end
            pc(t, "SetFontSize", 14 * (tonumber(rawget(_G, "_PT")) or 1))
            pc(t, "SetRGB", (i == 1 or i == 5) and 0xffc94a or 0x9fe8ff)
            pc(t, "SetAlignment", 0)
            call(frame, "addElement", t)
            S.diagTexts[i] = t
        end
        S.diag = frame; S.diagParent = parent; S.diagLast = {}
    end
    for i = 1, 5 do
        local line = lines[i] or ""
        if S.diagLast[i] ~= line then
            pc(S.diagTexts[i], "setText", markLocalized(line))
            S.diagLast[i] = line
        end
    end
end

local function reapply()
    for el, r in pairs(S.watch) do
        local ok = pcall(function() el:setText(markLocalized(newText(r))) end)
        if ok then S.reapplied = S.reapplied + 1 else S.watch[el] = nil end
    end
end

local function tick()
    S.ticks = S.ticks + 1
    -- Every frame: are we in a match? (cheap; the text hooks go quiet in a
    -- match right away instead of up to half a second later)
    local fe = S.feFn
    if fe == nil and S.ticks % 60 == 1 then
        fe = get(engine(), "InFrontend")
        if type(fe) == "function" then S.feFn = fe end
    end
    if fe ~= nil then
        local okF, front = pcall(fe)
        local wasMatch = inMatch
        inMatch = okF and front == false
        if wasMatch ~= inMatch then S.matchChanged = true end
    end
    -- Every frame: put the new text back on elements showing a reworked
    -- relic (the info box's own binding sets the stock text again).
    if REAPPLY >= 1 and (not inMatch or MATCH_TEXT >= 1) then pcall(reapply) end
    if inMatch and MATCH_TEXT < 1 then
        for el in pairs(S.watch) do S.watch[el] = nil end
    end
    if not inMatch then pcall(updateFocus) end
    -- About twice a second is plenty.
    if S.ticks % 30 ~= 0 then return end
    -- Relic codes: at start, when going in/out of a match, and every ~10 s.
    if S.ticks == 30 or S.matchChanged or S.ticks % 600 == 0 then pcall(patchRelics) end
    S.matchChanged = false
    if S.locHooks == 0 or S.ticks % 600 == 0 then pcall(hookLocalize) end
    if S.subHooks == 0 then pcall(hookSubscribers) end
    if not S.builderHooked then pcall(hookBuilder) end
    if (S.bundleHooks or 0) == 0 or S.ticks % 600 == 0 then pcall(hookBundles) end
    if S.modelHooks == 0 then pcall(hookModels) end
    local wasOn = S.rocketOn
    S.rocketOn = inMatch and (readRelics():find("rocket", 1, true) ~= nil)
    if wasOn and not S.rocketOn then restoreTypes() end
    pcall(updateBadge)
    pcall(updateDiag)
end

local function timerRoot()
    local L = rawget(_G, "LUI")
    local ok, cur = pcall(function() return get(L, "GetRoot")() end)
    if ok and cur then return cur end
    return get(L, "primaryRoot")
end
local function ensureTimer()
    if not S.enabled then return end
    local root = timerRoot()
    if not root then return end
    local okP, parent = pcall(call, S.timer, "getParent")
    if okP and parent == root then return end
    if S.timer then pc(S.timer, "closeTree") end
    S.timer = nil
    pcall(function()
        local host = newElement("UIElement")
        pc(host, "SetHandleMouse", false)
        call(root, "addElement", host)
        S.timer = host
        local function schedule()
            if not S.enabled or S.timer ~= host then return end
            local anim = call(host, "Wait", 16)
            if not anim then S.timer = nil; return end
            anim.onComplete = function()
                if not S.enabled or S.timer ~= host then return end
                if not pcall(tick) then clearBadge() end
                pcall(schedule)
            end
        end
        schedule()
    end)
end

-- Restart the timer if the UI root is rebuilt (only once per root object).
local seenInput = setmetatable({}, { __mode = "k" })
local function installInput()
    local input = get(rawget(_G, "LUI"), "UIRoot")
    if input == nil or seenInput[input] then return end
    local cur = get(input, "QueueInput")
    if type(cur) ~= "function" then return end
    local original = unwrap(cur)
    local wrapped = function(...)
        if S.enabled then pcall(ensureTimer) end
        return original(...)
    end
    REG.orig[wrapped] = original
    seenInput[input] = true
    pcall(function() input.QueueInput = wrapped end)
    local k = hx("QueueInput")
    if k ~= nil then pcall(function() input[k] = wrapped end) end
end

do
    local okF, front = pcall(function() return get(engine(), "InFrontend")() end)
    inMatch = okF and front == false
end
if old and old.clear then pcall(old.clear) end
if old and old.restoreTypes then pcall(old.restoreTypes) end
S.clear = clearBadge
pcall(hookLocalize)
pcall(hookBundles)
pcall(hookModels)
pcall(patchRelics)
pcall(hookSubscribers)
pcall(hookBuilder)
pcall(ensureTimer)
pcall(installInput)
end)
