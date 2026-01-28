--[[
    Job Abilities Module for AutoJob
    Defines job-specific abilities and their automation rules
]]--

local job_abilities = {}

local resources = require('resources')

-- Ability definitions by job
-- Each ability has:
--   name: Display name
--   id: Ability ID for recast checking
--   command: ja, pet, etc.
--   target: <t>, <me>, <st>, etc. (default <t>)
--   level: Required level to use
--   delay: Minimum delay between uses (seconds)
--   condition: Optional function(player, state) returning boolean

local job_configs = {
    -- Dragoon
    DRG = {
        abilities = {
            {
                name = 'Jump',
                id = 158,
                command = 'ja',
                target = ' <t>',
                level = 10,
                delay = 90,
                condition = function(player, state)
                    return state.engaged
                end
            },
            {
                name = 'High Jump',
                id = 159,
                command = 'ja',
                target = ' <t>',
                level = 35,
                delay = 180,
                condition = function(player, state)
                    return state.engaged
                end
            },
            {
                name = 'Super Jump',
                id = 160,
                command = 'ja',
                target = ' <t>',
                level = 50,
                delay = 300,
                condition = function(player, state)
                    -- Only use when player has hate (simplified)
                    return state.engaged
                end
            },
            {
                name = 'Spirit Jump',
                id = 167,
                command = 'ja',
                target = ' <t>',
                level = 77,
                delay = 60,
                condition = function(player, state)
                    return state.engaged
                end
            },
            {
                name = 'Soul Jump',
                id = 168,
                command = 'ja',
                target = ' <t>',
                level = 85,
                delay = 120,
                condition = function(player, state)
                    return state.engaged
                end
            }
        }
    },

    -- Warrior
    WAR = {
        abilities = {
            {
                name = 'Provoke',
                id = 5,
                command = 'ja',
                target = ' <t>',
                level = 5,
                delay = 30,
                condition = function(player, state)
                    return state.engaged
                end
            },
            {
                name = 'Berserk',
                id = 1,
                command = 'ja',
                target = ' <me>',
                level = 15,
                delay = 300,
                condition = function(player, state)
                    return state.engaged
                end
            },
            {
                name = 'Defender',
                id = 3,
                command = 'ja',
                target = ' <me>',
                level = 25,
                delay = 300,
                condition = function(player, state)
                    local hp_pct = (player.vitals.hp / player.vitals.max_hp) * 100
                    return state.engaged and hp_pct < 50
                end
            },
            {
                name = 'Warcry',
                id = 2,
                command = 'ja',
                target = ' <me>',
                level = 35,
                delay = 300,
                condition = function(player, state)
                    return state.engaged
                end
            },
            {
                name = 'Aggressor',
                id = 4,
                command = 'ja',
                target = ' <me>',
                level = 45,
                delay = 300,
                condition = function(player, state)
                    return state.engaged
                end
            }
        }
    },

    -- Monk
    MNK = {
        abilities = {
            {
                name = 'Boost',
                id = 15,
                command = 'ja',
                target = ' <me>',
                level = 5,
                delay = 15,
                condition = function(player, state)
                    return state.engaged
                end
            },
            {
                name = 'Dodge',
                id = 16,
                command = 'ja',
                target = ' <me>',
                level = 15,
                delay = 300,
                condition = function(player, state)
                    return state.engaged
                end
            },
            {
                name = 'Focus',
                id = 13,
                command = 'ja',
                target = ' <me>',
                level = 25,
                delay = 300,
                condition = function(player, state)
                    return state.engaged
                end
            },
            {
                name = 'Chi Blast',
                id = 18,
                command = 'ja',
                target = ' <t>',
                level = 41,
                delay = 180,
                condition = function(player, state)
                    return state.engaged
                end
            },
            {
                name = 'Chakra',
                id = 14,
                command = 'ja',
                target = ' <me>',
                level = 35,
                delay = 300,
                condition = function(player, state)
                    local hp_pct = (player.vitals.hp / player.vitals.max_hp) * 100
                    return hp_pct < 75
                end
            }
        }
    },

    -- Thief
    THF = {
        abilities = {
            {
                name = 'Sneak Attack',
                id = 35,
                command = 'ja',
                target = ' <me>',
                level = 15,
                delay = 60,
                condition = function(player, state)
                    return state.engaged and player.vitals.tp >= 1000
                end
            },
            {
                name = 'Trick Attack',
                id = 37,
                command = 'ja',
                target = ' <me>',
                level = 30,
                delay = 60,
                condition = function(player, state)
                    return state.engaged and player.vitals.tp >= 1000
                end
            },
            {
                name = 'Flee',
                id = 36,
                command = 'ja',
                target = ' <me>',
                level = 25,
                delay = 300,
                condition = function(player, state)
                    local hp_pct = (player.vitals.hp / player.vitals.max_hp) * 100
                    return hp_pct < 25 -- Emergency flee
                end
            }
        }
    },

    -- Dark Knight
    DRK = {
        abilities = {
            {
                name = 'Last Resort',
                id = 51,
                command = 'ja',
                target = ' <me>',
                level = 15,
                delay = 300,
                condition = function(player, state)
                    return state.engaged
                end
            },
            {
                name = 'Souleater',
                id = 53,
                command = 'ja',
                target = ' <me>',
                level = 30,
                delay = 360,
                condition = function(player, state)
                    local hp_pct = (player.vitals.hp / player.vitals.max_hp) * 100
                    return state.engaged and hp_pct > 50
                end
            },
            {
                name = 'Weapon Bash',
                id = 54,
                command = 'ja',
                target = ' <t>',
                level = 20,
                delay = 180,
                condition = function(player, state)
                    return state.engaged
                end
            }
        }
    },

    -- Paladin
    PLD = {
        abilities = {
            {
                name = 'Shield Bash',
                id = 46,
                command = 'ja',
                target = ' <t>',
                level = 15,
                delay = 180,
                condition = function(player, state)
                    return state.engaged
                end
            },
            {
                name = 'Sentinel',
                id = 47,
                command = 'ja',
                target = ' <me>',
                level = 30,
                delay = 300,
                condition = function(player, state)
                    local hp_pct = (player.vitals.hp / player.vitals.max_hp) * 100
                    return state.engaged and hp_pct < 50
                end
            },
            {
                name = 'Holy Circle',
                id = 43,
                command = 'ja',
                target = ' <me>',
                level = 5,
                delay = 600,
                condition = function(player, state)
                    return state.engaged
                end
            },
            {
                name = 'Rampart',
                id = 48,
                command = 'ja',
                target = ' <me>',
                level = 62,
                delay = 300,
                condition = function(player, state)
                    return state.engaged
                end
            }
        }
    },

    -- Samurai
    SAM = {
        abilities = {
            {
                name = 'Meditate',
                id = 134,
                command = 'ja',
                target = ' <me>',
                level = 30,
                delay = 180,
                condition = function(player, state)
                    return state.engaged and player.vitals.tp < 2000
                end
            },
            {
                name = 'Third Eye',
                id = 133,
                command = 'ja',
                target = ' <me>',
                level = 15,
                delay = 60,
                condition = function(player, state)
                    return state.engaged
                end
            },
            {
                name = 'Hasso',
                id = 138,
                command = 'ja',
                target = ' <me>',
                level = 25,
                delay = 60,
                condition = function(player, state)
                    return state.engaged
                end
            },
            {
                name = 'Sekkanoki',
                id = 140,
                command = 'ja',
                target = ' <me>',
                level = 60,
                delay = 300,
                condition = function(player, state)
                    return state.engaged and player.vitals.tp >= 1000
                end
            }
        }
    },

    -- Ninja
    NIN = {
        abilities = {
            {
                name = 'Yonin',
                id = 146,
                command = 'ja',
                target = ' <me>',
                level = 40,
                delay = 60,
                condition = function(player, state)
                    return state.engaged
                end
            },
            {
                name = 'Innin',
                id = 147,
                command = 'ja',
                target = ' <me>',
                level = 40,
                delay = 60,
                condition = function(player, state)
                    return state.engaged
                end
            }
        }
    },

    -- Ranger
    RNG = {
        abilities = {
            {
                name = 'Sharpshot',
                id = 106,
                command = 'ja',
                target = ' <me>',
                level = 1,
                delay = 300,
                condition = function(player, state)
                    return state.engaged
                end
            },
            {
                name = 'Barrage',
                id = 107,
                command = 'ja',
                target = ' <me>',
                level = 30,
                delay = 300,
                condition = function(player, state)
                    return state.engaged
                end
            },
            {
                name = 'Shadowbind',
                id = 108,
                command = 'ja',
                target = ' <t>',
                level = 40,
                delay = 300,
                condition = function(player, state)
                    return state.engaged
                end
            }
        }
    },

    -- Blue Mage
    BLU = {
        abilities = {
            {
                name = 'Chain Affinity',
                id = 181,
                command = 'ja',
                target = ' <me>',
                level = 40,
                delay = 120,
                condition = function(player, state)
                    return state.engaged and player.vitals.tp >= 1000
                end
            },
            {
                name = 'Burst Affinity',
                id = 182,
                command = 'ja',
                target = ' <me>',
                level = 25,
                delay = 120,
                condition = function(player, state)
                    return state.engaged and player.vitals.tp >= 1000
                end
            },
            {
                name = 'Diffusion',
                id = 184,
                command = 'ja',
                target = ' <me>',
                level = 75,
                delay = 60,
                condition = function(player, state)
                    return false -- User should control this
                end
            }
        }
    },

    -- Corsair
    COR = {
        abilities = {
            {
                name = 'Quick Draw',
                id = 195,
                command = 'ja',
                target = ' <t>',
                level = 40,
                delay = 60,
                condition = function(player, state)
                    return state.engaged
                end
            },
            {
                name = 'Random Deal',
                id = 196,
                command = 'ja',
                target = ' <me>',
                level = 50,
                delay = 1200,
                condition = function(player, state)
                    return true
                end
            }
        }
    },

    -- Dancer
    DNC = {
        abilities = {
            {
                name = 'Violent Flourish',
                id = 212,
                command = 'ja',
                target = ' <t>',
                level = 45,
                delay = 10,
                condition = function(player, state)
                    return state.engaged and player.vitals.tp >= 100
                end
            },
            {
                name = 'Animated Flourish',
                id = 213,
                command = 'ja',
                target = ' <t>',
                level = 20,
                delay = 30,
                condition = function(player, state)
                    return state.engaged and player.vitals.tp >= 100
                end
            },
            {
                name = 'Curing Waltz',
                id = 190,
                command = 'ja',
                target = ' <me>',
                level = 15,
                delay = 8,
                condition = function(player, state)
                    local hp_pct = (player.vitals.hp / player.vitals.max_hp) * 100
                    return hp_pct < 75 and player.vitals.tp >= 200
                end
            },
            {
                name = 'Curing Waltz II',
                id = 191,
                command = 'ja',
                target = ' <me>',
                level = 30,
                delay = 8,
                condition = function(player, state)
                    local hp_pct = (player.vitals.hp / player.vitals.max_hp) * 100
                    return hp_pct < 60 and player.vitals.tp >= 350
                end
            }
        }
    },

    -- Scholar
    SCH = {
        abilities = {
            {
                name = 'Light Arts',
                id = 228,
                command = 'ja',
                target = ' <me>',
                level = 10,
                delay = 60,
                condition = function(player, state)
                    return false -- User controls this
                end
            },
            {
                name = 'Dark Arts',
                id = 232,
                command = 'ja',
                target = ' <me>',
                level = 10,
                delay = 60,
                condition = function(player, state)
                    return false -- User controls this
                end
            }
        }
    },

    -- Rune Fencer
    RUN = {
        abilities = {
            {
                name = 'Vallation',
                id = 23,
                command = 'ja',
                target = ' <me>',
                level = 10,
                delay = 120,
                condition = function(player, state)
                    return state.engaged
                end
            },
            {
                name = 'Pflug',
                id = 59,
                command = 'ja',
                target = ' <me>',
                level = 40,
                delay = 120,
                condition = function(player, state)
                    return state.engaged
                end
            },
            {
                name = 'Swordplay',
                id = 24,
                command = 'ja',
                target = ' <me>',
                level = 20,
                delay = 300,
                condition = function(player, state)
                    return state.engaged
                end
            }
        }
    },

    -- Geomancer
    GEO = {
        abilities = {
            {
                name = 'Theurgic Focus',
                id = 246,
                command = 'ja',
                target = ' <me>',
                level = 50,
                delay = 60,
                condition = function(player, state)
                    return state.engaged
                end
            }
        }
    }
}

-- Subjob-specific abilities (reduced effectiveness/level requirements)
local sub_job_configs = {
    DRK = {
        abilities = {
            -- Stun via magic, not an ability
        }
    },
    WAR = {
        abilities = {
            {
                name = 'Provoke',
                id = 5,
                command = 'ja',
                target = ' <t>',
                level = 5,
                delay = 30,
                condition = function(player, state)
                    return state.engaged
                end
            },
            {
                name = 'Berserk',
                id = 1,
                command = 'ja',
                target = ' <me>',
                level = 15,
                delay = 300,
                condition = function(player, state)
                    return state.engaged
                end
            },
            {
                name = 'Warcry',
                id = 2,
                command = 'ja',
                target = ' <me>',
                level = 35,
                delay = 300,
                condition = function(player, state)
                    return state.engaged
                end
            }
        }
    },
    SAM = {
        abilities = {
            {
                name = 'Meditate',
                id = 134,
                command = 'ja',
                target = ' <me>',
                level = 30,
                delay = 180,
                condition = function(player, state)
                    return state.engaged and player.vitals.tp < 2000
                end
            },
            {
                name = 'Third Eye',
                id = 133,
                command = 'ja',
                target = ' <me>',
                level = 15,
                delay = 60,
                condition = function(player, state)
                    return state.engaged
                end
            },
            {
                name = 'Hasso',
                id = 138,
                command = 'ja',
                target = ' <me>',
                level = 25,
                delay = 60,
                condition = function(player, state)
                    return state.engaged
                end
            }
        }
    },
    NIN = {
        abilities = {}
    },
    DNC = {
        abilities = {
            {
                name = 'Curing Waltz',
                id = 190,
                command = 'ja',
                target = ' <me>',
                level = 15,
                delay = 8,
                condition = function(player, state)
                    local hp_pct = (player.vitals.hp / player.vitals.max_hp) * 100
                    return hp_pct < 75 and player.vitals.tp >= 200
                end
            }
        }
    }
}

-------------------------------------------
-- Public Functions
-------------------------------------------

function job_abilities.get_job_config(main_job, sub_job, main_level, sub_level)
    local result = {
        abilities = {}
    }

    -- Get main job abilities
    if main_job and job_configs[main_job] then
        for _, ability in ipairs(job_configs[main_job].abilities or {}) do
            if main_level >= ability.level then
                table.insert(result.abilities, ability)
            end
        end
    end

    -- Get sub job abilities (level requirement is halved for sub)
    if sub_job and sub_job_configs[sub_job] then
        for _, ability in ipairs(sub_job_configs[sub_job].abilities or {}) do
            if sub_level >= ability.level then
                -- Check if we already have this ability from main job
                local exists = false
                for _, existing in ipairs(result.abilities) do
                    if existing.name == ability.name then
                        exists = true
                        break
                    end
                end

                if not exists then
                    table.insert(result.abilities, ability)
                end
            end
        end
    end

    return result
end

function job_abilities.get_all_jobs()
    local jobs = {}
    for job, _ in pairs(job_configs) do
        table.insert(jobs, job)
    end
    return jobs
end

function job_abilities.get_job_ability_names(job)
    local names = {}
    if job_configs[job] then
        for _, ability in ipairs(job_configs[job].abilities or {}) do
            table.insert(names, ability.name)
        end
    end
    return names
end

return job_abilities
