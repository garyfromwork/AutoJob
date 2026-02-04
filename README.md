# AutoJob - FFXI Windower Addon

**Author:** Garyfromwork
**Version:** 1.0.0
**Commands:** `//autojob` or `//aj`

## Overview

AutoJob is an intelligent combat automation addon for Final Fantasy XI (Windower). It detects your current job/subjob combination and automatically uses appropriate abilities based on your level. Additionally, it provides a flexible system for automating weapon skills, spells, and responses to enemy actions.

Whether you want to automate DRG jumps while engaged, cast Stun when an enemy uses a dangerous ability, or simply fire off weapon skills at a certain TP threshold, AutoJob handles it all.

## Features

- **Job Detection** - Automatically detects your main job, subjob, and levels
- **Smart Ability Usage** - Uses job abilities when they're off cooldown and conditions are met
- **Weapon Skill Automation** - Execute weapon skills at configurable TP thresholds
- **Spell Triggers** - Cast spells in response to enemy actions (interrupt with Stun, etc.)
- **Timer-Based Spells** - Automatically recast spells on a set interval
- **HP-Threshold Spells** - Auto-heal when HP drops below a percentage
- **Persistent Settings** - Configuration saves between sessions
- **Per-Job Configurations** - Different settings for different job combinations

## Installation

1. Download the AutoJob addon
2. Extract to your `Windower/addons/AutoJob/` folder
3. In-game, load with `//lua load autojob`
4. (Optional) Add to your `Windower/scripts/init.txt` for auto-loading

### File Structure

```
Windower/addons/AutoJob/
├── AutoJob.lua       # Main addon file
├── job_abilities.lua # Job-specific ability definitions
├── spell_triggers.lua# Spell trigger configurations
├── utils.lua         # Utility functions
└── data/
    └── settings.xml  # Saved configuration (auto-generated)
```

## Commands

### Core Commands

| Command | Description |
|---------|-------------|
| `//aj on` | Enable automation |
| `//aj off` | Disable automation |
| `//aj status` | Show current job, settings, and state |
| `//aj list` | List all configured automations |
| `//aj clear` | Clear all user configurations |
| `//aj save` | Save current configuration |
| `//aj load` | Load saved configuration |
| `//aj help` | Display command help |
| `//aj debug [on/off]` | Toggle debug mode |

### Weapon Skill Commands

| Command | Description |
|---------|-------------|
| `//aj ws "Name" <TP>` | Set weapon skill and TP threshold |
| `//aj ws off` | Disable weapon skill automation |

### Spell Commands

| Command | Description |
|---------|-------------|
| `//aj spell "Spell" "Trigger"` | Cast spell when enemy uses trigger action |
| `//aj spell "Spell" "*"` | Cast spell on ANY enemy action |
| `//aj spell "Spell" timer <seconds>` | Cast spell on interval while engaged |
| `//aj spell "Spell" hp <percent>` | Cast spell when HP below threshold |
| `//aj spell "Spell" off` | Remove spell automation |

### Ability Commands

| Command | Description |
|---------|-------------|
| `//aj ability "Name" on` | Enable ability automation |
| `//aj ability "Name" off` | Disable ability automation |
| `//aj ability "Name"` | Toggle ability automation |
| `//aj ja "Name" [on/off]` | Alias for ability command |

## Usage Examples

### Weapon Skill at TP Threshold

Automatically use Asuran Fists when TP reaches 2000:

```
//aj ws "Asuran Fists" 2000
```

Use Savage Blade at 1000 TP:

```
//aj ws "Savage Blade" 1000
```

Disable weapon skill automation:

```
//aj ws off
```

### Interrupt Enemy Actions

Cast Stun when an enemy uses "Death Ray":

```
//aj spell "Stun" "Death Ray"
```

Cast Stun on ANY enemy action (spell or TP move):

```
//aj spell "Stun" "*"
```

Multiple interrupt triggers:

```
//aj spell "Stun" "Astral Flow"
//aj spell "Head Butt" "Sleepga"
```

### Timer-Based Spells

Recast Dia II every 60 seconds:

```
//aj spell "Dia II" timer 60
```

Keep Bio II up with 90-second refresh:

```
//aj spell "Bio II" timer 90
```

### HP-Threshold Healing

Cast Cure IV when HP drops below 50%:

```
//aj spell "Cure IV" hp 50
```

Emergency Cure V at 25% HP:

```
//aj spell "Cure V" hp 25
```

### Managing Job Abilities

Disable automatic Jump usage:

```
//aj ability "Jump" off
```

Re-enable High Jump:

```
//aj ability "High Jump" on
```

### Viewing Configuration

Check current status:

```
//aj status
```

Output:
```
=== AutoJob Status ===
Enabled: true
Job: DRG99/SAM49
Engaged: true
Weapon Skill: Stardiver @ 2000 TP
Configured Spells: 2
Configured Abilities: 1
```

List all configurations:

```
//aj list
```

Output:
```
=== AutoJob Configuration ===
Weapon Skill: Stardiver @ 2000 TP
--- Spells ---
  Stun: on "Death Ray"
  Dia II: every 60s
--- Abilities ---
  Jump: Enabled
  High Jump: Disabled
```

## Supported Jobs

AutoJob includes built-in ability configurations for the following jobs:

### Main Jobs

| Job | Auto-Abilities |
|-----|----------------|
| **DRG** | Jump, High Jump, Super Jump, Spirit Jump, Soul Jump |
| **WAR** | Provoke, Berserk, Defender, Warcry, Aggressor |
| **MNK** | Boost, Dodge, Focus, Chi Blast, Chakra |
| **THF** | Sneak Attack, Trick Attack, Flee (emergency) |
| **PLD** | Shield Bash, Sentinel, Holy Circle, Rampart |
| **DRK** | Last Resort, Souleater, Weapon Bash |
| **SAM** | Meditate, Third Eye, Hasso, Sekkanoki |
| **NIN** | Yonin, Innin |
| **RNG** | Sharpshot, Barrage, Shadowbind |
| **BLU** | Chain Affinity, Burst Affinity |
| **COR** | Quick Draw, Random Deal |
| **DNC** | Violent Flourish, Animated Flourish, Curing Waltz |
| **RUN** | Vallation, Pflug, Swordplay |
| **GEO** | Theurgic Focus |

### Subjob Abilities

When subbing these jobs, their abilities are also available (at appropriate level):

- **WAR** - Provoke, Berserk, Warcry
- **SAM** - Meditate, Third Eye, Hasso
- **DNC** - Curing Waltz

## How It Works

### Engagement Detection

AutoJob monitors your player status. When you engage an enemy (status = 1), automation begins. When you disengage or the enemy dies, automation pauses.

### Ability Conditions

Each ability has conditions that must be met:

- **Recast Ready** - Ability must be off cooldown
- **Level Requirement** - Your level must meet the ability's requirement
- **Custom Conditions** - Some abilities have special conditions:
  - Chakra: Only when HP < 75%
  - Defender: Only when HP < 50%
  - Meditate: Only when TP < 2000
  - Sneak/Trick Attack: Only when TP >= 1000

### Spell Triggers

When an enemy begins a TP move or starts casting a spell, AutoJob checks your configured spell triggers. If a match is found and the spell is ready (not on recast, have MP), it's cast immediately.

### Priority System

Actions are processed in this order:

1. Enemy action responses (Stun triggers, etc.)
2. HP-threshold spells (emergency healing)
3. Weapon skills (when TP threshold met)
4. Job abilities (when conditions met)
5. Timer-based spells (buffs/debuffs)

## Configuration Tips

### DRG/SAM Example Setup

```
//aj ws "Stardiver" 2000
//aj ability "Jump" on
//aj ability "High Jump" on
//aj ability "Spirit Jump" on
//aj ability "Meditate" on
```

### RDM/DRK Stunner Setup

```
//aj spell "Stun" "Astral Flow"
//aj spell "Stun" "Benediction"
//aj spell "Stun" "Chainspell"
//aj spell "Stun" "Hundred Fists"
```

### BLU Skillchain Setup

```
//aj ws "Chant du Cygne" 1000
//aj ability "Chain Affinity" on
```

### Self-Healing Setup

```
//aj spell "Cure IV" hp 50
//aj spell "Cure V" hp 30
```

## Advanced Usage

### Wildcard Triggers

Use `*` to trigger on ANY enemy action:

```
//aj spell "Stun" "*"
```

This is useful when fighting enemies with multiple dangerous moves, but be cautious of MP consumption.

### Combining with Gearswap

AutoJob works alongside Gearswap. When AutoJob sends a command like `/ws "Stardiver" <t>`, Gearswap will handle equipment changes as normal.

### Debug Mode

Enable debug mode to see what AutoJob is doing:

```
//aj debug on
```

This will log:
- Ability usage attempts
- Spell trigger activations
- Weapon skill executions
- Condition check results

## Troubleshooting

### Abilities not firing?

1. Check that AutoJob is enabled: `//aj status`
2. Verify you're engaged in combat
3. Check ability recast: may still be on cooldown
4. Verify level requirements are met
5. Enable debug mode to see what's happening: `//aj debug on`

### Spells not triggering on enemy actions?

1. Verify the trigger name matches exactly (case-insensitive)
2. Check that you have enough MP
3. Verify the spell isn't on recast
4. Make sure you're targeting the enemy

### Weapon skills not executing?

1. Check TP threshold: `//aj status`
2. Verify the weapon skill name is spelled correctly
3. Ensure you're engaged and in range
4. Check that you have the weapon skill unlocked

### Settings not saving?

1. Use `//aj save` to force a save
2. Check that the data folder exists
3. Verify file permissions

## Changelog

### Version 1.0.0
- Initial release
- Job detection and auto-abilities for 14 jobs
- Weapon skill automation with TP threshold
- Spell triggers (action-based, timer-based, HP-based)
- Ability toggle system
- Persistent settings
- Debug mode
- On-screen status display

## Future Plans

- Party member buff tracking
- Skillchain automation
- Pet command automation (BST, SMN, PUP)
- Trust coordination
- Gear set integration suggestions
