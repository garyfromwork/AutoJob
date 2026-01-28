--[[
    Spell Triggers Module for AutoJob
    Handles spell trigger logic and common spell configurations
]]--

local spell_triggers = {}

local resources = require('resources')

-- Common interrupt spells by job
local interrupt_spells = {
    -- Dark Knight / Sub Dark Knight
    DRK = {
        { name = 'Stun', level = 37, mp = 25 }
    },
    -- Blue Mage
    BLU = {
        { name = 'Head Butt', level = 12, mp = 12 },
        { name = 'Sudden Lunge', level = 56, mp = 46 }
    },
    -- Red Mage (if they could stun, which they can't by default)
    -- Scholar (uses Dark Arts + Stun)
    SCH = {
        { name = 'Stun', level = 45, mp = 25 } -- Requires Dark Arts
    },
    -- White Mage
    WHM = {
        { name = 'Repose', level = 85, mp = 40 } -- Sleep not interrupt
    }
}

-- Common buff spells by job
local buff_spells = {
    WHM = {
        { name = 'Protect', level = 7, mp = 9, duration = 1800 },
        { name = 'Shell', level = 17, mp = 18, duration = 1800 },
        { name = 'Haste', level = 40, mp = 40, duration = 180 },
        { name = 'Regen', level = 21, mp = 15, duration = 60 }
    },
    RDM = {
        { name = 'Protect', level = 7, mp = 9, duration = 1800 },
        { name = 'Shell', level = 17, mp = 18, duration = 1800 },
        { name = 'Haste', level = 48, mp = 40, duration = 180 },
        { name = 'Refresh', level = 41, mp = 40, duration = 150 },
        { name = 'Phalanx', level = 33, mp = 21, duration = 180 }
    },
    BLU = {
        { name = 'Cocoon', level = 8, mp = 14, duration = 90 },
        { name = 'Refueling', level = 48, mp = 29, duration = 300 }
    },
    SCH = {
        { name = 'Protect', level = 7, mp = 9, duration = 1800 },
        { name = 'Shell', level = 17, mp = 18, duration = 1800 },
        { name = 'Regen', level = 18, mp = 15, duration = 60 }
    },
    DNC = {
        { name = 'Haste Samba', level = 5, tp = 350, duration = 120 }
    }
}

-- Common nuke spells for skillchains
local nuke_spells = {
    BLM = {
        fire = { 'Fire', 'Fire II', 'Fire III', 'Fire IV', 'Fire V', 'Fire VI' },
        ice = { 'Blizzard', 'Blizzard II', 'Blizzard III', 'Blizzard IV', 'Blizzard V', 'Blizzard VI' },
        wind = { 'Aero', 'Aero II', 'Aero III', 'Aero IV', 'Aero V', 'Aero VI' },
        earth = { 'Stone', 'Stone II', 'Stone III', 'Stone IV', 'Stone V', 'Stone VI' },
        lightning = { 'Thunder', 'Thunder II', 'Thunder III', 'Thunder IV', 'Thunder V', 'Thunder VI' },
        water = { 'Water', 'Water II', 'Water III', 'Water IV', 'Water V', 'Water VI' }
    },
    RDM = {
        fire = { 'Fire', 'Fire II', 'Fire III', 'Fire IV' },
        ice = { 'Blizzard', 'Blizzard II', 'Blizzard III', 'Blizzard IV' },
        wind = { 'Aero', 'Aero II', 'Aero III', 'Aero IV' },
        earth = { 'Stone', 'Stone II', 'Stone III', 'Stone IV' },
        lightning = { 'Thunder', 'Thunder II', 'Thunder III', 'Thunder IV' },
        water = { 'Water', 'Water II', 'Water III', 'Water IV' }
    },
    SCH = {
        fire = { 'Fire', 'Fire II', 'Fire III', 'Fire IV', 'Fire V' },
        ice = { 'Blizzard', 'Blizzard II', 'Blizzard III', 'Blizzard IV', 'Blizzard V' },
        wind = { 'Aero', 'Aero II', 'Aero III', 'Aero IV', 'Aero V' },
        earth = { 'Stone', 'Stone II', 'Stone III', 'Stone IV', 'Stone V' },
        lightning = { 'Thunder', 'Thunder II', 'Thunder III', 'Thunder IV', 'Thunder V' },
        water = { 'Water', 'Water II', 'Water III', 'Water IV', 'Water V' }
    },
    GEO = {
        fire = { 'Fire', 'Fire II', 'Fire III', 'Fire IV', 'Fire V' },
        ice = { 'Blizzard', 'Blizzard II', 'Blizzard III', 'Blizzard IV', 'Blizzard V' },
        wind = { 'Aero', 'Aero II', 'Aero III', 'Aero IV', 'Aero V' },
        earth = { 'Stone', 'Stone II', 'Stone III', 'Stone IV', 'Stone V' },
        lightning = { 'Thunder', 'Thunder II', 'Thunder III', 'Thunder IV', 'Thunder V' },
        water = { 'Water', 'Water II', 'Water III', 'Water IV', 'Water V' }
    }
}

-- Heal spells by job
local heal_spells = {
    WHM = {
        { name = 'Cure', level = 1, mp = 8 },
        { name = 'Cure II', level = 11, mp = 24 },
        { name = 'Cure III', level = 21, mp = 46 },
        { name = 'Cure IV', level = 41, mp = 88 },
        { name = 'Cure V', level = 61, mp = 135 },
        { name = 'Cure VI', level = 80, mp = 227 }
    },
    RDM = {
        { name = 'Cure', level = 1, mp = 8 },
        { name = 'Cure II', level = 14, mp = 24 },
        { name = 'Cure III', level = 26, mp = 46 },
        { name = 'Cure IV', level = 48, mp = 88 }
    },
    PLD = {
        { name = 'Cure', level = 5, mp = 8 },
        { name = 'Cure II', level = 17, mp = 24 },
        { name = 'Cure III', level = 30, mp = 46 },
        { name = 'Cure IV', level = 55, mp = 88 }
    },
    SCH = {
        { name = 'Cure', level = 3, mp = 8 },
        { name = 'Cure II', level = 14, mp = 24 },
        { name = 'Cure III', level = 26, mp = 46 },
        { name = 'Cure IV', level = 48, mp = 88 }
    },
    RUN = {
        { name = 'Cure', level = 5, mp = 8 },
        { name = 'Cure II', level = 17, mp = 24 },
        { name = 'Cure III', level = 30, mp = 46 },
        { name = 'Cure IV', level = 59, mp = 88 }
    }
}

-- Dangerous enemy actions that should be interrupted (examples)
local dangerous_actions = {
    -- Generic dangerous actions
    'Death Ray',
    'Astral Flow',
    'Chainspell',
    'Hundred Fists',
    'Mighty Strikes',
    'Invincible',
    'Perfect Dodge',
    'Blood Weapon',
    'Meikyo Shisui',
    'Benediction',
    'Manafont',
    'Soul Voice',
    'Eagle Eye Shot',
    'Doom',
    'Death',
    'Sleepga',
    'Sleepga II',
    'Breakga',
    'Petro Eyes',
    -- Add more as needed
}

-------------------------------------------
-- Public Functions
-------------------------------------------

function spell_triggers.get_interrupt_spells(job, level)
    local spells = {}
    if interrupt_spells[job] then
        for _, spell in ipairs(interrupt_spells[job]) do
            if level >= spell.level then
                table.insert(spells, spell)
            end
        end
    end
    return spells
end

function spell_triggers.get_buff_spells(job, level)
    local spells = {}
    if buff_spells[job] then
        for _, spell in ipairs(buff_spells[job]) do
            if level >= spell.level then
                table.insert(spells, spell)
            end
        end
    end
    return spells
end

function spell_triggers.get_heal_spells(job, level)
    local spells = {}
    if heal_spells[job] then
        for _, spell in ipairs(heal_spells[job]) do
            if level >= spell.level then
                table.insert(spells, spell)
            end
        end
    end
    return spells
end

function spell_triggers.get_best_heal(job, level, current_mp)
    local spells = spell_triggers.get_heal_spells(job, level)
    local best = nil

    for _, spell in ipairs(spells) do
        if current_mp >= spell.mp then
            best = spell
        end
    end

    return best
end

function spell_triggers.is_dangerous_action(action_name)
    for _, dangerous in ipairs(dangerous_actions) do
        if dangerous:lower() == action_name:lower() then
            return true
        end
    end
    return false
end

function spell_triggers.get_dangerous_actions()
    return dangerous_actions
end

function spell_triggers.add_dangerous_action(action_name)
    table.insert(dangerous_actions, action_name)
end

function spell_triggers.remove_dangerous_action(action_name)
    for i, action in ipairs(dangerous_actions) do
        if action:lower() == action_name:lower() then
            table.remove(dangerous_actions, i)
            return true
        end
    end
    return false
end

return spell_triggers
