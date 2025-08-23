# MageControl Requirements

## Overview
MageControl is a World of Warcraft addon designed specifically for Arcane Mages on the Turtle WoW server. The addon aims to enhance single-target damage output by efficiently managing spell rotations and reducing downtime.

## Core Functionality Requirements

### 1. Spell Rotation Optimization
- Implement an optimal single-target Arcane DPS rotation
- Provide instant Arcane Explosion queuing for AoE situations
- Support specialized rotations for specific encounters (e.g., Incantagos in Karazhan)
- Intelligently manage spell priority based on buffs, debuffs, and cooldowns
- Adapt rotation based on player's haste level

### 2. Buff and Cooldown Tracking
- Track and display key buffs with remaining duration:
  - Arcane Power
  - Mind Quickening
  - Arcane Rupture
  - Wisdom of the Mak'aru
  - Enlightened State
- Provide visual indicators for buff durations with color coding
- Support stack counting for buffs that stack (e.g., Wisdom of the Mak'aru)

### 3. User Interface
- Provide a configuration panel for customizing addon settings
- Allow users to specify action bar slots for key spells
- Support auto-detection of spell slots on action bars
- Enable customizable positioning of buff display frames
- Implement lock/unlock functionality for buff frames

### 4. Mana Management
- Implement safety checks to prevent dangerous mana depletion
- Provide warnings when mana levels are critically low
- Calculate projected mana levels during Arcane Power
- Adjust spell usage based on mana availability

## Technical Requirements

### 1. Performance
- Minimize CPU usage and frame rate impact
- Implement efficient buff checking without using GameTooltips
- Cache buff information to reduce redundant checks
- Use optimized update intervals for different functions

### 2. Compatibility
- Function correctly with World of Warcraft 1.12 client (Vanilla)
- Support the specific spell mechanics of Turtle WoW server
- Integrate with required dependencies (nampower and superwow)
- Avoid conflicts with other common addons

### 3. Usability
- Provide clear slash commands for all functionality
- Implement intuitive UI with appropriate feedback
- Include validation for user inputs
- Support reset functionality for settings
- Provide clear error messages for invalid configurations

## Constraints

### 1. Dependencies
- Requires the nampower addon for instant spell queuing
- Requires the superwow addon for efficient buff fetching
- Must work within the limitations of the WoW 1.12 API

### 2. Server-Specific
- Designed specifically for Turtle WoW server mechanics
- Must account for Turtle WoW-specific spells and talents
- Optimized for the unique Arcane Mage playstyle on Turtle WoW

### 3. Technical Limitations
- Limited by the WoW 1.12 Lua API capabilities
- Must work within the WoW addon framework constraints
- Cannot use features introduced in later WoW expansions