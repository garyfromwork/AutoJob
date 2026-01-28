--[[
    AutoJob - FFXI Windower Addon
    Automates job-specific actions based on player's job/subjob combination

    Commands:
        //aj help                           - Show help
        //aj on/off                         - Enable/disable automation
        //aj status                         - Show current status and configuration
        //aj ws "Name" <TP>                 - Set weapon skill and TP threshold
        //aj ws off                         - Disable weapon skill automation
        //aj spell "Spell" "Trigger"        - Cast spell when enemy uses trigger ability
        //aj spell "Spell" timer <seconds>  - Cast spell on timer while engaged
        //aj spell "Spell" hp <percent>     - Cast spell when HP below percent
        //aj spell "Spell" off              - Remove spell automation
        //aj ability "Name" [on/off]        - Toggle ability automation
        //aj ja "Name" [on/off]             - Toggle job ability automation
        //aj list                           - List all configured automations
        //aj clear                          - Clear all configurations
        //aj save                           - Save current configuration
        //aj load                           - Load saved configuration
        //aj debug [on/off]                 - Toggle debug mode
]]--

_addon.name = 'AutoJob'
_addon.author = 'Garyfromwork'
_addon.version = '1.0.0'
_addon.commands = {'autojob', 'aj'}

require('tables')
require('strings')
require('logger')
local config = require('config')
local packets = require('packets')
local resources = require('resources')
local res = require('resources')

-- Load sub-modules
local job_abilities = require('job_abilities')
local spell_triggers = require('spell_triggers')
local utils = require('utils')

-- Default settings
local defaults = {
    enabled = true,
    debug = false,
    weapon_skill = {
        enabled = false,
        name = '',
        tp_threshold = 1000
    },
    spells = {},
    abilities = {},
    job_settings = {}
}

local settings = config.load(defaults)

-- State tracking
local state = {
    engaged = false,
    target_id = nil,
    target_index = nil,
    player_job = nil,
    player_subjob = nil,
    player_level = 0,
    player_sublevel = 0,
    last_ws_time = 0,
    last_ability_times = {},
    last_spell_times = {},
    spell_timers = {},
    action_queue = {},
    casting = false,
    busy = false,
    mob_casting = {},
    last_prerender = 0
}

-- Constants
local WS_DELAY = 2.0
local ABILITY_DELAY = 1.5
local SPELL_DELAY = 2.5
local PRERENDER_INTERVAL = 0.1

-- Forward declarations
local check_weapon_skill
local check_abilities
local check_spell_timers
local process_action_queue
local handle_mob_action
local update_player_info
local is_ready
local can_act

-------------------------------------------
-- Utility Functions
-------------------------------------------

local function debug_log(msg)
    if settings.debug then
        log('[DEBUG] ' .. msg)
    end
end

local function get_current_time()
    return os.clock()
end

local function get_recast_time(ability_id, is_spell)
    if is_spell then
        local recasts = windower.ffxi.get_spell_recasts()
        if recasts and recasts[ability_id] then
            return recasts[ability_id] / 60
        end
    else
        local recasts = windower.ffxi.get_ability_recasts()
        if recasts and recasts[ability_id] then
            return recasts[ability_id]
        end
    end
    return 0
end

-------------------------------------------
-- Player State Functions
-------------------------------------------

function update_player_info()
    local player = windower.ffxi.get_player()
    if not player then return false end

    state.player_job = player.main_job
    state.player_subjob = player.sub_job
    state.player_level = player.main_job_level
    state.player_sublevel = player.sub_job_level

    return true
end

function is_ready()
    local player = windower.ffxi.get_player()
    if not player then return false end

    -- Check if player can act
    if player.status == 2 then -- Event/cutscene
        return false
    end

    if state.casting or state.busy then
        return false
    end

    return true
end

function can_act()
    if not is_ready() then return false end
    if not state.engaged then return false end
    return true
end

-------------------------------------------
-- Combat Functions
-------------------------------------------

function check_weapon_skill()
    if not settings.weapon_skill.enabled then return end
    if not can_act() then return end

    local player = windower.ffxi.get_player()
    if not player then return end

    local current_time = get_current_time()
    if current_time - state.last_ws_time < WS_DELAY then return end

    local tp = player.vitals.tp
    if tp >= settings.weapon_skill.tp_threshold then
        local ws_name = settings.weapon_skill.name
        debug_log('Attempting WS: ' .. ws_name .. ' at TP: ' .. tp)

        windower.chat.input('/ws "' .. ws_name .. '" <t>')
        state.last_ws_time = current_time
    end
end

function check_abilities()
    if not can_act() then return end

    local current_time = get_current_time()
    local player = windower.ffxi.get_player()
    if not player then return end

    -- Check job-specific abilities
    local job_config = job_abilities.get_job_config(state.player_job, state.player_subjob,
                                                     state.player_level, state.player_sublevel)

    if job_config and job_config.abilities then
        for _, ability in ipairs(job_config.abilities) do
            if settings.abilities[ability.name] ~= false then
                local last_use = state.last_ability_times[ability.name] or 0

                if current_time - last_use >= (ability.delay or ABILITY_DELAY) then
                    local recast = get_recast_time(ability.id, false)

                    if recast == 0 then
                        -- Check conditions
                        local should_use = true

                        if ability.condition then
                            should_use = ability.condition(player, state)
                        end

                        if should_use then
                            debug_log('Using ability: ' .. ability.name)
                            windower.chat.input('/' .. ability.command .. ' "' .. ability.name .. '"' ..
                                              (ability.target or ' <t>'))
                            state.last_ability_times[ability.name] = current_time
                        end
                    end
                end
            end
        end
    end

    -- Check user-configured abilities
    for ability_name, ability_config in pairs(settings.abilities) do
        if type(ability_config) == 'table' and ability_config.enabled then
            local last_use = state.last_ability_times[ability_name] or 0

            if current_time - last_use >= ABILITY_DELAY then
                local ability_res = utils.find_ability(ability_name)
                if ability_res then
                    local recast = get_recast_time(ability_res.id, false)

                    if recast == 0 then
                        debug_log('Using configured ability: ' .. ability_name)
                        windower.chat.input('/ja "' .. ability_name .. '" <t>')
                        state.last_ability_times[ability_name] = current_time
                    end
                end
            end
        end
    end
end

function check_spell_timers()
    if not can_act() then return end

    local current_time = get_current_time()
    local player = windower.ffxi.get_player()
    if not player then return end

    for spell_name, spell_config in pairs(settings.spells) do
        if spell_config.enabled then
            -- Timer-based spells
            if spell_config.trigger_type == 'timer' then
                local last_cast = state.last_spell_times[spell_name] or 0
                local interval = spell_config.timer_interval or 30

                if current_time - last_cast >= interval then
                    local spell_res = utils.find_spell(spell_name)
                    if spell_res then
                        local recast = get_recast_time(spell_res.id, true)

                        if recast == 0 and player.vitals.mp >= (spell_res.mp_cost or 0) then
                            debug_log('Casting timed spell: ' .. spell_name)
                            windower.chat.input('/ma "' .. spell_name .. '" <t>')
                            state.last_spell_times[spell_name] = current_time
                        end
                    end
                end

            -- HP threshold spells
            elseif spell_config.trigger_type == 'hp' then
                local hp_percent = (player.vitals.hp / player.vitals.max_hp) * 100

                if hp_percent <= spell_config.hp_threshold then
                    local last_cast = state.last_spell_times[spell_name] or 0

                    if current_time - last_cast >= SPELL_DELAY then
                        local spell_res = utils.find_spell(spell_name)
                        if spell_res then
                            local recast = get_recast_time(spell_res.id, true)

                            if recast == 0 and player.vitals.mp >= (spell_res.mp_cost or 0) then
                                debug_log('Casting HP threshold spell: ' .. spell_name)
                                windower.chat.input('/ma "' .. spell_name .. '" <me>')
                                state.last_spell_times[spell_name] = current_time
                            end
                        end
                    end
                end
            end
        end
    end
end

-------------------------------------------
-- Mob Action Handling
-------------------------------------------

function handle_mob_action(act)
    if not settings.enabled then return end
    if not state.engaged then return end

    -- Check if this is our target
    if act.actor_id ~= state.target_id then return end

    local category = act.category

    -- Category 7 = Weapon Skill / TP move starting
    -- Category 8 = Spell starting
    if category == 7 or category == 8 then
        local action_id = act.param
        local action_name = ''

        if category == 7 then
            -- Monster ability
            local mob_ability = res.monster_abilities[action_id]
            if mob_ability then
                action_name = mob_ability.en
            end
        elseif category == 8 then
            -- Spell
            local spell = res.spells[action_id]
            if spell then
                action_name = spell.en
            end
        end

        if action_name ~= '' then
            debug_log('Enemy action detected: ' .. action_name)

            -- Check spell triggers
            for spell_name, spell_config in pairs(settings.spells) do
                if spell_config.enabled and spell_config.trigger_type == 'action' then
                    if spell_config.trigger_action and
                       (spell_config.trigger_action:lower() == action_name:lower() or
                        spell_config.trigger_action == '*') then

                        local player = windower.ffxi.get_player()
                        if player then
                            local spell_res = utils.find_spell(spell_name)
                            if spell_res then
                                local recast = get_recast_time(spell_res.id, true)

                                if recast == 0 and player.vitals.mp >= (spell_res.mp_cost or 0) then
                                    debug_log('Triggering spell: ' .. spell_name .. ' in response to: ' .. action_name)
                                    windower.chat.input('/ma "' .. spell_name .. '" <t>')
                                    state.last_spell_times[spell_name] = get_current_time()
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end

-------------------------------------------
-- Event Handlers
-------------------------------------------

windower.register_event('prerender', function()
    local current_time = get_current_time()

    if current_time - state.last_prerender < PRERENDER_INTERVAL then
        return
    end
    state.last_prerender = current_time

    if not settings.enabled then return end

    -- Update player info
    if not update_player_info() then return end

    -- Check engagement status
    local player = windower.ffxi.get_player()
    if player then
        state.engaged = (player.status == 1) -- 1 = Engaged

        if state.engaged then
            local target = windower.ffxi.get_mob_by_target('t')
            if target then
                state.target_id = target.id
                state.target_index = target.index
            end
        else
            state.target_id = nil
            state.target_index = nil
        end
    end

    -- Run automation checks
    check_weapon_skill()
    check_abilities()
    check_spell_timers()
end)

windower.register_event('action', function(act)
    handle_mob_action(act)
end)

-- Track casting state
windower.register_event('outgoing chunk', function(id, data)
    if id == 0x028 then -- Action packet
        state.busy = true
        coroutine.schedule(function() state.busy = false end, 2)
    end
end)

windower.register_event('incoming chunk', function(id, data)
    if id == 0x028 then -- Action result
        state.casting = false
    end
end)

windower.register_event('action message', function(actor_id, target_id, actor_index, target_index, message_id)
    -- Spell interrupted, finished, etc
    local player = windower.ffxi.get_player()
    if player and actor_id == player.id then
        state.casting = false
        state.busy = false
    end
end)

-------------------------------------------
-- Command Handling
-------------------------------------------

windower.register_event('addon command', function(...)
    local args = T{...}
    local cmd = args[1] and args[1]:lower() or 'help'

    if cmd == 'help' then
        log('AutoJob Commands:')
        log('  //aj on/off - Enable/disable automation')
        log('  //aj status - Show current status')
        log('  //aj ws "Name" <TP> - Set weapon skill (e.g., //aj ws "Asuran Fists" 2000)')
        log('  //aj ws off - Disable weapon skill')
        log('  //aj spell "Spell" "Trigger" - React to enemy action')
        log('  //aj spell "Spell" timer <sec> - Cast on timer')
        log('  //aj spell "Spell" hp <pct> - Cast when HP below %')
        log('  //aj spell "Spell" off - Remove spell')
        log('  //aj ability "Name" [on/off] - Toggle ability')
        log('  //aj ja "Name" [on/off] - Toggle job ability')
        log('  //aj list - List configurations')
        log('  //aj clear - Clear all configurations')
        log('  //aj save - Save configuration')
        log('  //aj load - Load configuration')
        log('  //aj debug [on/off] - Toggle debug mode')

    elseif cmd == 'on' then
        settings.enabled = true
        log('AutoJob: Enabled')
        settings:save()

    elseif cmd == 'off' then
        settings.enabled = false
        log('AutoJob: Disabled')
        settings:save()

    elseif cmd == 'status' then
        update_player_info()
        log('=== AutoJob Status ===')
        log('Enabled: ' .. tostring(settings.enabled))
        log('Job: ' .. (state.player_job or 'Unknown') .. state.player_level ..
            '/' .. (state.player_subjob or 'Unknown') .. state.player_sublevel)
        log('Engaged: ' .. tostring(state.engaged))
        log('Weapon Skill: ' .. (settings.weapon_skill.enabled and
            (settings.weapon_skill.name .. ' @ ' .. settings.weapon_skill.tp_threshold .. ' TP') or 'Disabled'))

        local spell_count = 0
        for _ in pairs(settings.spells) do spell_count = spell_count + 1 end
        log('Configured Spells: ' .. spell_count)

        local ability_count = 0
        for _ in pairs(settings.abilities) do ability_count = ability_count + 1 end
        log('Configured Abilities: ' .. ability_count)

    elseif cmd == 'ws' then
        if args[2] and args[2]:lower() == 'off' then
            settings.weapon_skill.enabled = false
            log('AutoJob: Weapon skill automation disabled')
        else
            local ws_name = args[2]
            local tp_threshold = tonumber(args[3]) or 1000

            if ws_name then
                -- Remove quotes if present
                ws_name = ws_name:gsub('^"', ''):gsub('"$', '')

                settings.weapon_skill.enabled = true
                settings.weapon_skill.name = ws_name
                settings.weapon_skill.tp_threshold = tp_threshold

                log('AutoJob: Weapon skill set to "' .. ws_name .. '" at ' .. tp_threshold .. ' TP')
            else
                log('Usage: //aj ws "Weapon Skill Name" <TP threshold>')
            end
        end
        settings:save()

    elseif cmd == 'spell' then
        local spell_name = args[2]

        if not spell_name then
            log('Usage: //aj spell "Spell Name" "Trigger"')
            log('       //aj spell "Spell Name" timer <seconds>')
            log('       //aj spell "Spell Name" hp <percent>')
            log('       //aj spell "Spell Name" off')
            return
        end

        spell_name = spell_name:gsub('^"', ''):gsub('"$', '')

        local sub_cmd = args[3] and args[3]:lower() or ''

        if sub_cmd == 'off' then
            settings.spells[spell_name] = nil
            log('AutoJob: Removed spell "' .. spell_name .. '"')

        elseif sub_cmd == 'timer' then
            local interval = tonumber(args[4]) or 30
            settings.spells[spell_name] = {
                enabled = true,
                trigger_type = 'timer',
                timer_interval = interval
            }
            log('AutoJob: Spell "' .. spell_name .. '" set to cast every ' .. interval .. ' seconds')

        elseif sub_cmd == 'hp' then
            local threshold = tonumber(args[4]) or 50
            settings.spells[spell_name] = {
                enabled = true,
                trigger_type = 'hp',
                hp_threshold = threshold
            }
            log('AutoJob: Spell "' .. spell_name .. '" set to cast when HP below ' .. threshold .. '%')

        else
            -- Trigger-based spell
            local trigger = args[3]
            if trigger then
                trigger = trigger:gsub('^"', ''):gsub('"$', '')
                settings.spells[spell_name] = {
                    enabled = true,
                    trigger_type = 'action',
                    trigger_action = trigger
                }
                log('AutoJob: Spell "' .. spell_name .. '" set to cast when enemy uses "' .. trigger .. '"')
            else
                log('Usage: //aj spell "Spell Name" "Trigger Action"')
            end
        end
        settings:save()

    elseif cmd == 'ability' or cmd == 'ja' then
        local ability_name = args[2]

        if not ability_name then
            log('Usage: //aj ability "Ability Name" [on/off]')
            return
        end

        ability_name = ability_name:gsub('^"', ''):gsub('"$', '')
        local toggle = args[3] and args[3]:lower() or 'toggle'

        if toggle == 'off' then
            settings.abilities[ability_name] = { enabled = false }
            log('AutoJob: Ability "' .. ability_name .. '" disabled')
        elseif toggle == 'on' then
            settings.abilities[ability_name] = { enabled = true }
            log('AutoJob: Ability "' .. ability_name .. '" enabled')
        else
            -- Toggle
            local current = settings.abilities[ability_name]
            local new_state = not (current and current.enabled)
            settings.abilities[ability_name] = { enabled = new_state }
            log('AutoJob: Ability "' .. ability_name .. '" ' .. (new_state and 'enabled' or 'disabled'))
        end
        settings:save()

    elseif cmd == 'list' then
        log('=== AutoJob Configuration ===')

        if settings.weapon_skill.enabled then
            log('Weapon Skill: ' .. settings.weapon_skill.name .. ' @ ' .. settings.weapon_skill.tp_threshold .. ' TP')
        else
            log('Weapon Skill: Disabled')
        end

        log('--- Spells ---')
        local has_spells = false
        for spell_name, config in pairs(settings.spells) do
            has_spells = true
            local info = spell_name .. ': '
            if config.trigger_type == 'timer' then
                info = info .. 'every ' .. config.timer_interval .. 's'
            elseif config.trigger_type == 'hp' then
                info = info .. 'HP < ' .. config.hp_threshold .. '%'
            elseif config.trigger_type == 'action' then
                info = info .. 'on "' .. config.trigger_action .. '"'
            end
            log('  ' .. info .. (config.enabled and '' or ' [DISABLED]'))
        end
        if not has_spells then
            log('  (none)')
        end

        log('--- Abilities ---')
        local has_abilities = false
        for ability_name, config in pairs(settings.abilities) do
            has_abilities = true
            log('  ' .. ability_name .. ': ' .. (config.enabled and 'Enabled' or 'Disabled'))
        end
        if not has_abilities then
            log('  (none)')
        end

    elseif cmd == 'clear' then
        settings.weapon_skill = {
            enabled = false,
            name = '',
            tp_threshold = 1000
        }
        settings.spells = {}
        settings.abilities = {}
        log('AutoJob: All configurations cleared')
        settings:save()

    elseif cmd == 'save' then
        settings:save()
        log('AutoJob: Configuration saved')

    elseif cmd == 'load' then
        settings = config.load(defaults)
        log('AutoJob: Configuration loaded')

    elseif cmd == 'debug' then
        if args[2] then
            settings.debug = (args[2]:lower() == 'on')
        else
            settings.debug = not settings.debug
        end
        log('AutoJob: Debug mode ' .. (settings.debug and 'enabled' or 'disabled'))
        settings:save()

    else
        log('Unknown command: ' .. cmd .. '. Use //aj help for commands.')
    end
end)

-------------------------------------------
-- Initialization
-------------------------------------------

windower.register_event('load', function()
    log('AutoJob loaded. Use //aj help for commands.')
    update_player_info()

    if state.player_job then
        log('Detected: ' .. state.player_job .. state.player_level ..
            '/' .. (state.player_subjob or 'NON') .. state.player_sublevel)
    end
end)

windower.register_event('job change', function(main_job_id, main_job_level, sub_job_id, sub_job_level)
    update_player_info()
    log('AutoJob: Job changed to ' .. state.player_job .. state.player_level ..
        '/' .. (state.player_subjob or 'NON') .. state.player_sublevel)
end)

windower.register_event('unload', function()
    settings:save()
end)
