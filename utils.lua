--[[
    Utilities Module for AutoJob
    Common utility functions
]]--

local utils = {}

local resources = require('resources')
local res = require('resources')

-------------------------------------------
-- Spell and Ability Lookup
-------------------------------------------

-- Find a spell by name
function utils.find_spell(spell_name)
    if not spell_name then return nil end

    local lower_name = spell_name:lower()

    for id, spell in pairs(res.spells) do
        if spell.en and spell.en:lower() == lower_name then
            return {
                id = id,
                name = spell.en,
                mp_cost = spell.mp_cost or 0,
                cast_time = spell.cast_time or 0,
                recast = spell.recast or 0,
                skill = spell.skill,
                type = spell.type
            }
        end
    end

    return nil
end

-- Find a job ability by name
function utils.find_ability(ability_name)
    if not ability_name then return nil end

    local lower_name = ability_name:lower()

    for id, ability in pairs(res.job_abilities) do
        if ability.en and ability.en:lower() == lower_name then
            return {
                id = id,
                name = ability.en,
                recast = ability.recast or 0,
                mp_cost = ability.mp_cost or 0,
                tp_cost = ability.tp_cost or 0
            }
        end
    end

    return nil
end

-- Find a weapon skill by name
function utils.find_weapon_skill(ws_name)
    if not ws_name then return nil end

    local lower_name = ws_name:lower()

    for id, ws in pairs(res.weapon_skills) do
        if ws.en and ws.en:lower() == lower_name then
            return {
                id = id,
                name = ws.en,
                skill = ws.skill
            }
        end
    end

    return nil
end

-- Find a monster ability by name
function utils.find_monster_ability(ability_name)
    if not ability_name then return nil end

    local lower_name = ability_name:lower()

    for id, ability in pairs(res.monster_abilities) do
        if ability.en and ability.en:lower() == lower_name then
            return {
                id = id,
                name = ability.en
            }
        end
    end

    return nil
end

-------------------------------------------
-- Player State Utilities
-------------------------------------------

-- Get player's current buffs
function utils.get_buffs()
    local player = windower.ffxi.get_player()
    if not player or not player.buffs then
        return {}
    end

    local buff_names = {}
    for _, buff_id in ipairs(player.buffs) do
        if buff_id and buff_id ~= 255 and buff_id ~= 0 then
            local buff = res.buffs[buff_id]
            if buff then
                table.insert(buff_names, buff.en)
            end
        end
    end

    return buff_names
end

-- Check if player has a specific buff
function utils.has_buff(buff_name)
    local buffs = utils.get_buffs()
    local lower_name = buff_name:lower()

    for _, name in ipairs(buffs) do
        if name:lower() == lower_name then
            return true
        end
    end

    return false
end

-- Check if player has any of the specified buffs
function utils.has_any_buff(buff_names)
    local buffs = utils.get_buffs()

    for _, check_name in ipairs(buff_names) do
        local lower_check = check_name:lower()
        for _, buff_name in ipairs(buffs) do
            if buff_name:lower() == lower_check then
                return true
            end
        end
    end

    return false
end

-------------------------------------------
-- Target Utilities
-------------------------------------------

-- Get current target info
function utils.get_target()
    local target = windower.ffxi.get_mob_by_target('t')
    if not target then return nil end

    return {
        id = target.id,
        index = target.index,
        name = target.name,
        hpp = target.hpp,
        distance = target.distance,
        is_npc = target.is_npc,
        claim_id = target.claim_id
    }
end

-- Check if we're in melee range
function utils.in_melee_range(max_distance)
    max_distance = max_distance or 6

    local target = windower.ffxi.get_mob_by_target('t')
    if not target then return false end

    return target.distance and math.sqrt(target.distance) <= max_distance
end

-- Check if we're in spell range
function utils.in_spell_range(max_distance)
    max_distance = max_distance or 21

    local target = windower.ffxi.get_mob_by_target('t')
    if not target then return false end

    return target.distance and math.sqrt(target.distance) <= max_distance
end

-------------------------------------------
-- Job Utilities
-------------------------------------------

-- Get job abbreviation from ID
function utils.get_job_abbrev(job_id)
    local jobs = {
        [1] = 'WAR', [2] = 'MNK', [3] = 'WHM', [4] = 'BLM',
        [5] = 'RDM', [6] = 'THF', [7] = 'PLD', [8] = 'DRK',
        [9] = 'BST', [10] = 'BRD', [11] = 'RNG', [12] = 'SAM',
        [13] = 'NIN', [14] = 'DRG', [15] = 'SMN', [16] = 'BLU',
        [17] = 'COR', [18] = 'PUP', [19] = 'DNC', [20] = 'SCH',
        [21] = 'GEO', [22] = 'RUN'
    }

    return jobs[job_id] or 'NON'
end

-- Get job ID from abbreviation
function utils.get_job_id(job_abbrev)
    local jobs = {
        WAR = 1, MNK = 2, WHM = 3, BLM = 4,
        RDM = 5, THF = 6, PLD = 7, DRK = 8,
        BST = 9, BRD = 10, RNG = 11, SAM = 12,
        NIN = 13, DRG = 14, SMN = 15, BLU = 16,
        COR = 17, PUP = 18, DNC = 19, SCH = 20,
        GEO = 21, RUN = 22
    }

    return jobs[job_abbrev:upper()] or 0
end

-- Check if player can use a spell based on job/level
function utils.can_use_spell(spell_name)
    local spell = utils.find_spell(spell_name)
    if not spell then return false end

    local player = windower.ffxi.get_player()
    if not player then return false end

    -- Check if player has the spell in their list
    local spells = windower.ffxi.get_spells()
    if spells and spells[spell.id] then
        return true
    end

    return false
end

-- Check if player can use an ability
function utils.can_use_ability(ability_name)
    local ability = utils.find_ability(ability_name)
    if not ability then return false end

    local player = windower.ffxi.get_player()
    if not player then return false end

    -- Check if player has the ability
    local abilities = windower.ffxi.get_abilities()
    if abilities and abilities.job_abilities then
        for _, id in ipairs(abilities.job_abilities) do
            if id == ability.id then
                return true
            end
        end
    end

    return false
end

-------------------------------------------
-- String Utilities
-------------------------------------------

-- Parse quoted string from arguments
function utils.parse_quoted_arg(args, start_index)
    if not args[start_index] then return nil, start_index end

    local first = args[start_index]

    -- Check if it starts with a quote
    if first:sub(1, 1) == '"' then
        -- Find the closing quote
        local result = first:sub(2) -- Remove leading quote

        if result:sub(-1) == '"' then
            -- Single-word quoted string
            return result:sub(1, -2), start_index + 1
        end

        -- Multi-word quoted string
        local i = start_index + 1
        while args[i] do
            if args[i]:sub(-1) == '"' then
                result = result .. ' ' .. args[i]:sub(1, -2)
                return result, i + 1
            else
                result = result .. ' ' .. args[i]
            end
            i = i + 1
        end

        return result, i
    else
        -- Unquoted string
        return first, start_index + 1
    end
end

-------------------------------------------
-- Time Utilities
-------------------------------------------

-- Format seconds as mm:ss
function utils.format_time(seconds)
    local mins = math.floor(seconds / 60)
    local secs = math.floor(seconds % 60)
    return string.format('%02d:%02d', mins, secs)
end

-- Get current game time
function utils.get_game_time()
    local info = windower.ffxi.get_info()
    if info then
        return info.time or 0
    end
    return 0
end

return utils
