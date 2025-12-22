---
name: 1v1 Hero Support Spell Game - DEMO VERSION
overview: Build a minimal demo of the 1v1 battle game to test core mechanics with friends. Simplified scope for quick iteration and easy sharing.
todos:
  - id: setup
    content: Project Setup - Install Godot 4.x, create new 2D project, open in Cursor
    status: pending
  - id: networking
    content: Networking Foundation - Create NetworkManager.gd with host/join, WiFi IP display (BIG TEXT)
    status: pending
  - id: main_menu
    content: Main Menu UI - Host/Join buttons, WiFi IP display (prominent), connection status
    status: pending
  - id: hero_movement
    content: Hero Movement - WASD controls, mouse aim, network sync, colored circles (3 heroes)
    status: pending
  - id: combat_system
    content: Combat System - Auto-attack, health bars, damage numbers, projectiles (circles)
    status: pending
  - id: abilities
    content: Hero Abilities - Q/E hotkeys, 2 abilities per hero (Fighter/Shooter/Mage), cooldowns
    status: pending
  - id: supports
    content: Support System - 3 supports (Tank/Damage/Buffer), hotkeys 1/2/3, AI, colored rectangles
    status: pending
  - id: big_spell
    content: Big Spell System - 2 spells (Area Blast/Massive Buff), R hotkey, one-time use, choose 1
    status: pending
  - id: hero_switching
    content: Hero Switching - Death detection, selection UI (1/2/3 keys), respawn, win condition
    status: pending
  - id: selection_screen
    content: Pre-Battle Selection - Auto-select 3 heroes + 3 supports, choose 1 of 2 spells, Quick Start
    status: pending
  - id: arena_map
    content: Arena Map - Simple rectangular arena, 2-3 obstacle blocks, spawn points
    status: pending
  - id: visual_polish
    content: Visual Polish - Blocks/circles only (NO animations), health bars, UI elements, victory screen
    status: pending
  - id: export_test
    content: Export & Testing - Export .exe/.app, test on 2 computers (same WiFi), verify IP display works
    status: pending
---

# 1v1 Hero Support Spell Game - DEMO Development Plan

## Demo Summary

**Goal**: Create a playable demo to test core game mechanics with friends at home.**Content**:

- **3 Heroes** total (Fighter, Shooter, Mage) - players get all 3
- **3 Supports** total (Tank, Damage Dealer, Buffer) - players get all 3  
- **2 Big Spells** total (Area Blast, Massive Buff) - players choose 1

**CRITICAL REQUIREMENT - WiFi IP Display**:

- When player clicks "Host Game", the game MUST display the WiFi IP address in **LARGE, PROMINENT TEXT**
- Format: "Your WiFi IP: 192.168.1.100" (or similar, large font, center screen)
- This IP address is what the second player needs to connect
- Both players must be on the same WiFi network (same home router)
- No port forwarding or external servers needed - just WiFi IP connection

**Visual Style**:

- **NO ANIMATIONS** - Static shapes only
- Heroes = Colored circles
- Supports = Colored rectangles/squares
- Obstacles = Gray rectangular blocks
- Projectiles = Small colored circles
- Everything appears/disappears instantly (no movement animations)

**Multiplayer**:

- **2 separate computers** (one for each player)
- Both computers on same WiFi network (same home network)
- One player hosts, other connects via WiFi IP address
- Easy setup - no port forwarding or external servers needed
- Each player has full screen on their own computer

## Demo Scope (Simplified for Testing)

A playable demo to validate core game mechanics. Simplified from full game to focus on essential features.

### Demo Features

**Simplified Pre-Battle**:

- **3 Heroes** total in pool - each player chooses all 3 (no selection needed, just confirmation)
- **3 Supports** total in pool - each player chooses all 3 (no selection needed, just confirmation)
- **2 Big Spells** total in pool - each player chooses 1 from 2 available
- **Quick Start Option**: Pre-selected loadouts for instant testing (skip selection entirely)

**Simplified Battle**:

- **Simple Arena**: Open rectangular arena (colored background, no lanes yet)
- **Basic Obstacles**: 2-3 simple rectangular walls/obstacles for cover (colored blocks)
- **Core Combat**: Hero movement, auto-attack, 2 abilities per hero (no ultimates in demo)
- **Support AI**: Basic AI (follow, attack, simple behaviors)
- **Hero Switching**: When hero dies, quick selection of remaining hero
- **Win Condition**: All heroes eliminated

**Visual Style - Blocks & Circles Only**:

- **NO ANIMATIONS** - Static shapes only
- **Heroes**: Colored circles (different colors for each hero type)
- **Supports**: Colored squares/rectangles (different sizes for different support types)
- **Obstacles**: Gray/colored rectangular blocks
- **Projectiles**: Small colored circles that move
- **Abilities**: Colored circles/rectangles for area effects
- **UI**: Simple text and colored rectangles for buttons/bars

**Controls** (Each player on their own computer):

- **Player 1**: WASD (movement), Mouse (aim/attack), Q/E (abilities), 1/2/3 (summon supports), R (big spell)
- **Player 2**: WASD (movement), Mouse (aim/attack), Q/E (abilities), 1/2/3 (summon supports), R (big spell)
- Both players use same controls (WASD movement + mouse aim) on their own computers

## Technical Stack

**Development Environment:**

- **Cursor AI**: AI-powered code editor for rapid development
- **Godot Engine 4.x**: Game engine (Best for quick demo and easy export)

**Game Technology:**

- **Language**: GDScript
- **Export**: Single executable file (Windows/Mac/Linux)
- **Sharing**: Just send the .exe/.app file to friends
- **Networking**: Godot's built-in ENetMultiplayerPeer (perfect for local network)
- **Port**: Default 7777 (configurable, auto-handled by Godot)

**Why Cursor AI + Godot:**

- Cursor AI can generate GDScript code quickly
- AI helps with game logic, networking, and UI implementation
- Faster iteration with AI assistance
- Cursor understands game development patterns

## Multiplayer Networking Implementation

### Network Architecture (Local Network Only)

**Godot Multiplayer Setup:**

- **Type**: Client-Server (one player hosts, other connects)
- **Protocol**: ENet (reliable UDP, built into Godot)
- **Port**: 7777 (default, can be changed)
- **Network**: Local WiFi only (same home network)
- **No Internet Required**: Works offline on local network
- **Synchronization**: RPC calls for player actions, state sync for game objects

**Why This Works for 2 Computers at Home:**

- Both computers connect to same WiFi router
- Host's computer acts as server
- Client computer connects directly to host's WiFi IP address
- No external servers, no port forwarding needed
- Works instantly - just need WiFi IP address
- Each player has their own computer and full screen

### Key Network Scripts

**NetworkManager.gd** (Main networking controller):

```gdscript
# Handles connection, hosting, joining
# Manages multiplayer peer lifecycle
# Handles connection/disconnection events
# CRITICAL: Gets WiFi IP address and displays it prominently
# Function: get_local_ip() - gets WiFi IP address (192.168.x.x or 10.x.x.x)
# Function: display_ip_address() - shows IP in UI (large, visible text)
# When hosting: Display IP address in large font, center screen
# Example: "Your WiFi IP: 192.168.1.100" (big, bold text)
```

**Synchronized Objects**:

- Heroes (position, health, state)
- Supports (position, health, AI state)
- Projectiles/Abilities (spawn, movement, impact)
- Big Spell effects (cast, area, damage)

**RPC Functions** (Remote Procedure Calls):

- `move_hero()` - Player movement
- `use_ability()` - Ability activation
- `summon_support()` - Support spawning
- `cast_big_spell()` - Big spell activation
- `switch_hero()` - Hero selection on death

### Connection Flow (2 Computers on Same WiFi)

1. **Host (Computer 1)**: 

- Creates multiplayer peer → Starts server → **DISPLAYS WiFi IP ADDRESS IN BIG TEXT** (e.g., "192.168.1.100")
- Shows "Waiting for player..." status
- Waits for client to connect

2. **Client (Computer 2)**: 

- Creates multiplayer peer → Enters host's WiFi IP address (from host's screen) → Connects to host → Joins game
- Shows "Connecting..." then "Connected!" when successful

3. **Both**: 

- Synchronize game state → Both see "Ready to start" → Click "Start Battle" → Play on separate computers!

**IMPORTANT**: WiFi IP address MUST be displayed prominently on host's screen so they can easily tell their friend what IP to connect to.

### WiFi IP Address Implementation (CRITICAL)

**How to Get WiFi IP Address in Godot**:

```gdscript
# In NetworkManager.gd
func get_wifi_ip() -> String:
    # Method 1: Get all local IPs and filter for WiFi
    var interfaces = IP.get_local_addresses()
    for ip in interfaces:
        # Filter for local network IPs (192.168.x.x or 10.x.x.x)
        if ip.begins_with("192.168.") or ip.begins_with("10."):
            return ip
    
    # Method 2: Alternative approach
    # Use OS.get_environment() or IP.resolve_hostname()
    return "127.0.0.1"  # Fallback (localhost)
```

**How to Display WiFi IP in UI**:

```gdscript
# In MainMenu.gd or NetworkManager.gd
func display_ip_address(ip: String):
    # Get the label node
    var ip_label = $IPAddressLabel  # Large Label node in scene
    
    # Set text with large font
    ip_label.text = "Your WiFi IP: " + ip
    ip_label.add_theme_font_size_override("font_size", 48)  # Large font
    ip_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    ip_label.visible = true  # Make sure it's visible!
```

**UI Layout Requirements**:

- **IP Address Label**: Large Label node, center of screen, font size 48+
- **Position**: Center of screen or top-center, highly visible
- **Text Format**: "Your WiFi IP: 192.168.1.100" or "IP: 192.168.1.100"
- **Visibility**: Show immediately when "Host Game" is clicked
- **Optional**: Add "Copy to Clipboard" button next to IP address

**Cursor AI Prompt to Use**:

- "Create NetworkManager.gd that gets WiFi IP address (192.168.x.x) and displays it in large text when hosting"
- "Add a Label node to MainMenu that shows WiFi IP address in font size 48, centered on screen"
- "When Host Game button is clicked, get local WiFi IP and display it prominently"

### UI Requirements - CRITICAL: WiFi IP Display

**Main Menu**:

- **"Host Game" button** (creates server, displays WiFi IP address in BIG, PROMINENT text)
- **IP Address Display**: Large, bold text showing WiFi IP (e.g., "192.168.1.100")
- **Copy to Clipboard** button (optional but helpful)
- **Connection Status**: "Waiting for player..." displayed clearly
- **"Join Game" button** (opens WiFi IP address input field, connects to host)
- **IP Input Field**: Text field to enter host's WiFi IP address
- **Connect Button**: Click to connect
- **Connection Status**: "Connecting..." / "Connected!" / "Failed to connect"
- **WiFi IP address display** (MUST be visible and easy to read for host to share)
- Display format: "Your IP: 192.168.1.100" (large font, center screen)
- Show port if needed: "Port: 7777"
- **Connection status indicator** ("Waiting for player..." / "Connected!" / "Ready to start")
- **"Quick Start" button** (single-player test mode for development)

## Demo File Structure

**Note**: Open this project folder in Cursor AI to edit code files (.gd scripts)

```javascript
game_demo/
├── scenes/
│   ├── MainMenu.tscn (simple start screen)
│   ├── QuickBattle.tscn (skip selection, use defaults)
│   └── BattleScene.tscn (main battle)
├── scripts/
│   ├── core/
│   │   ├── Hero.gd (simplified hero class - edit in Cursor)
│   │   ├── Support.gd (basic support class - edit in Cursor)
│   │   └── BigSpell.gd (spell system - edit in Cursor)
│   ├── controllers/
│   │   ├── PlayerController.gd (input handling - edit in Cursor)
│   │   └── SimpleSupportAI.gd (basic AI - edit in Cursor)
│   └── managers/
│       ├── GameManager.gd (battle state - edit in Cursor)
│       ├── BattleManager.gd (hero switching, win conditions - edit in Cursor)
│       └── NetworkManager.gd (multiplayer - edit in Cursor)
├── resources/
│   ├── demo_heroes.json (3 heroes: Fighter, Shooter, Mage)
│   ├── demo_supports.json (3 supports: Tank, Damage Dealer, Buffer)
│   └── demo_spells.json (2 spells: Area Damage, Massive Buff)
└── assets/
    ├── sprites/ (NO custom sprites needed - use Godot's built-in shapes)
    │   ├── Use CircleShape2D for heroes/projectiles
    │   ├── Use RectangleShape2D for supports/obstacles
    │   └── Use ColorRect nodes for UI elements
    └── fonts/ (default Godot font is fine)
```

**Cursor AI Workflow:**

- Edit `.gd` script files in Cursor AI
- Create scenes (`.tscn` files) in Godot editor
- Use Cursor to generate code, then attach scripts to nodes in Godot

## Implementation Checklist (Priority Order)

### Phase 1: Foundation & Networking (MUST DO FIRST)

- [ ] Install Godot 4.x and create new 2D project
- [ ] Open project folder in Cursor AI
- [ ] **Create NetworkManager.gd** with WiFi IP detection and display
- [ ] Function to get local WiFi IP (192.168.x.x or 10.x.x.x)
- [ ] Function to display IP address in large, visible text
- [ ] Host game functionality (start server, show IP)
- [ ] Join game functionality (connect to IP address)
- [ ] Connection status handling
- [ ] **Create MainMenu scene** with UI
- [ ] "Host Game" button (shows WiFi IP in BIG TEXT when clicked)
- [ ] "Join Game" button (opens IP input field)
- [ ] IP address display label (large font, center screen)
- [ ] Connection status label
- [ ] "Quick Start" button (single-player test)

### Phase 2: Core Gameplay

- [ ] Create Hero.gd base class (3 heroes: Fighter, Shooter, Mage)
- [ ] Create BattleScene with simple arena (colored background)
- [ ] Implement hero movement (WASD) with network sync
- [ ] Add hero visuals (colored circles - blue/green/red)
- [ ] Add health bars above heroes
- [ ] Implement auto-attack system
- [ ] Create projectile system (small colored circles)
- [ ] Add damage numbers (text popups)

### Phase 3: Abilities & Supports

- [ ] Implement ability system (Q/E hotkeys, cooldowns)
- [ ] Fighter: Dash, Shield Bash
- [ ] Shooter: Rapid Fire, Piercing Shot
- [ ] Mage: Fireball, Teleport
- [ ] Create Support.gd base class
- [ ] Implement 3 supports (Tank, Damage Dealer, Buffer)
- [ ] Visual: Colored rectangles (gray/red/yellow)
- [ ] AI: Follow player, attack enemies
- [ ] Summoning: Hotkeys 1/2/3, one-time use
- [ ] Add support AI behavior

### Phase 4: Big Spells & Hero Switching

- [ ] Create BigSpell.gd system
- [ ] Implement 2 spells (Area Blast, Massive Buff)
- [ ] Visual: Large colored circles (red/green)
- [ ] R hotkey activation
- [ ] Cast at mouse location (instant cast)
- [ ] Area Blast: Cast at mouse location, instant damage
- [ ] Massive Buff: Cast at mouse location, affects player and supports in area
- [ ] One-time use restriction
- [ ] Cooldown UI display
- [ ] Implement hero death detection
- [ ] Create hero switching system (no switching before death, only on death)
- [ ] Create hero switching overlay UI (press 1/2/3 to select, appears on death)
- [ ] Add 5-second respawn delay (player can only select hero during this time)
- [ ] Add hero respawn system (respawn at original spawn position)
- [ ] Add 3-second spawn protection (invincibility after respawn)
- [ ] Implement win condition (all 3 heroes dead)
- [ ] Add match timer (10 minutes)
- [ ] Add sudden death system (3.0x damage multiplier after 10 minutes)

### Phase 5: Pre-Battle & Polish

- [ ] Create selection screen UI
- [ ] Auto-select all 3 heroes (just confirm)
- [ ] Auto-select all 3 supports (just confirm)
- [ ] Choose 1 of 2 big spells (click button)
- [ ] Quick Start option (skip selection)
- [ ] Add obstacles to arena (2-3 rectangular blocks with collision)
- [ ] Add obstacle collision system (heroes, projectiles, abilities all blocked by obstacles) - ask Cursor: "Add collision detection so nothing can pass through obstacles"
- [ ] Visual polish (ensure all blocks/circles, NO animations)
- [ ] Victory/defeat screen
- [ ] Add restart functionality

### Phase 6: Testing & Export

- [ ] Test single-player (Quick Start mode)
- [ ] Test multiplayer locally (2 instances, localhost)
- [ ] **Test WiFi connection** (2 computers, same WiFi)
- [ ] Verify IP address displays correctly
- [ ] Verify connection works
- [ ] Test full gameplay loop
- [ ] Export for Windows (.exe)
- [ ] Export for Mac (.app)
- [ ] Test exported versions
- [ ] Create README with controls

## Demo Implementation Plan

### Week 1: Core Demo (Playable Prototype)

#### Day 1-2: Setup & Basic Movement

**Cursor AI Prompts to Use:**

- "Create a new Godot 4 project structure with basic 2D scene setup"
- "Create a Hero.gd script that moves with WASD keys using CharacterBody2D"
- "Add a simple arena scene with a colored rectangle background"
- "Create hero sprites as colored circles (blue, green, red) using Godot's built-in shapes"

**Tasks:**

- [ ] Install Godot 4.x
- [ ] Create new project
- [ ] Open project folder in Cursor AI
- [ ] Set up basic scene structure (ask Cursor to create initial scene files)
- [ ] **Set up networking early** - ask Cursor: "Create NetworkManager.gd with host/join functionality and WiFi IP display"
- **CRITICAL**: WiFi IP address must be displayed in large, visible text when hosting
- Use `IP.get_local_addresses()` or `IP.resolve_hostname(OS.get_environment("COMPUTERNAME"), IP.TYPE_IPV4)` to get WiFi IP
- Filter for local network IPs (192.168.x.x or 10.x.x.x)
- Display IP address prominently in UI (large font, center of screen, bold)
- Example display: "Your WiFi IP: 192.168.1.100" (font size 48+, center screen)
- [ ] Create simple arena (colored rectangle background - gray or beige)
- [ ] Implement hero movement (WASD for both players) - ask Cursor: "Create PlayerController.gd for WASD movement with network sync"
- [ ] Add hero visuals: Colored circles (use Godot's CircleShape2D or simple sprite)
- Fighter: Blue circle (larger)
- Shooter: Green circle (medium)
- Mage: Red circle (smaller)
- [ ] Add player indicators (P1 = blue outline, P2 = red outline)
- [ ] Test: Both players can move independently (test with 2 computers on WiFi)

#### Day 3-4: Combat System

**Cursor AI Prompts to Use:**

- "Create a health bar UI system using ColorRect nodes above units"
- "Implement auto-attack system that finds nearest enemy and attacks"
- "Create a projectile system with small colored circles that move toward targets"
- "Add damage numbers that appear above units (text labels, no animations)"
- "Create an ability system with Q and E hotkeys and cooldowns"

**Tasks:**

- [ ] Add hero health bars (colored rectangles above heroes) - ask Cursor: "Create HealthBar.gd script"
- [ ] Implement auto-attack (heroes attack nearest enemy in range, stops when out of range) - ask Cursor: "Add auto-attack to Hero.gd that targets nearest enemy and stops when out of range"
- [ ] Add projectiles: Small colored circles that move in straight lines toward target - ask Cursor: "Create Projectile.gd script with straight-line movement"
- [ ] Add collision system: Projectiles blocked by obstacles - ask Cursor: "Add obstacle collision to Projectile.gd"
- [ ] Add damage system: Text numbers appear above damaged units (no animations, just instant text) - ask Cursor: "Create damage number popup system"
- [ ] Create 2 abilities per hero (Q and E keys) - ask Cursor: "Add ability system to Hero.gd with Q/E hotkeys":
- Fighter: Dash (instant movement), Shield Bash (damage circle)
- Shooter: Rapid Fire (buff), Piercing Shot (line projectile)
- Mage: Fireball (area circle), Teleport (instant movement)
- [ ] Ability visuals: Colored circles/rectangles for area effects (no animations)
- [ ] Add ability cooldowns (text countdown or colored bar) - ask Cursor: "Add cooldown UI system"
- [ ] Test: Players can fight and use abilities

#### Day 5-6: Support System

**Cursor AI Prompts to Use:**

- "Create a base Support.gd class that extends CharacterBody2D"
- "Implement AI that makes supports follow the player and attack nearest enemy"
- "Create support summoning system with hotkeys 1, 2, 3"
- "Add one-time use restriction for supports (can only be summoned once)"

**Tasks:**

- [ ] Create base Support class - ask Cursor: "Create Support.gd with health, movement, and attack"
- [ ] Implement 3 support types with visual blocks - ask Cursor: "Create Tank, DamageDealer, and Buffer support classes":
- **Tank Support**: Large gray/blue rectangle, high HP, high melee damage, slow movement, follows player within close range, walks to nearest enemy
- **Damage Support**: Small red square, low HP, high damage, fast movement, follows player within medium range, attacks nearest enemy with projectiles
- **Buffer Support**: Small yellow square with glow effect (colored outline), low HP, very low damage, medium movement, follows player within medium range, provides buffs via fixed-radius aura around player
- [ ] Add support summoning (hotkeys 1, 2, 3) - spawns at player location - ask Cursor: "Add support summoning to PlayerController.gd"
- [ ] Basic AI: Follow player within range, attack nearest enemy - ask Cursor: "Create SimpleSupportAI.gd with follow-within-range and attack-nearest-enemy behavior"
- [ ] One-time use restriction (each support can only be summoned once, button grays out) - ask Cursor: "Add support usage tracking"
- [ ] Support death handling (supports die = gone for match, no respawn) - ask Cursor: "Add support death handling that removes support permanently"
- [ ] Buffer aura system (fixed radius around player) - ask Cursor: "Add buffer aura system with fixed radius around player"
- [ ] Support projectiles: Small colored circles (same as hero projectiles, blocked by obstacles)
- [ ] Test: Players can summon supports, supports fight and provide buffs

#### Day 7: Pre-Battle Selection & Big Spell

**Cursor AI Prompts to Use:**

- "Create a selection screen UI with buttons for hero/support/spell selection"
- "Create BigSpell.gd class with Area Blast and Massive Buff spells"
- "Add R hotkey for big spell activation with one-time use restriction"

**Tasks:**

- [ ] Create selection screen UI (simple buttons and text, no fancy graphics) - ask Cursor: "Create SelectionUI.gd with button layout"
- [ ] Implement hero selection (all 3 heroes auto-selected, just confirm) - ask Cursor: "Add hero selection logic"
- [ ] Implement support selection (all 3 supports auto-selected, just confirm) - ask Cursor: "Add support selection logic"
- [ ] Implement spell selection (choose 1 from 2 available - click button) - ask Cursor: "Add spell selection with 2 options"
- [ ] Add "Quick Start" option (auto-selects all, skips selection entirely) - ask Cursor: "Add quick start button"
- [ ] Implement 2 big spells - ask Cursor: "Create BigSpell.gd with Area Blast and Massive Buff":
- **Area Blast**: Cast at mouse location, instant cast, large red circle appears, deals damage instantly, circle disappears after 0.5 seconds
- **Massive Buff**: Cast at mouse location, instant cast, large green circle appears, provides buffs to player and supports in area, circle stays visible for 3 seconds then disappears
- [ ] Big spell visuals: Colored circles (red for damage, green for buff) - instant appearance, no animation
- [ ] Add big spell hotkey (R) - cast at mouse location, instant cast, one-time use, button grays out after use - ask Cursor: "Add R hotkey to PlayerController.gd that casts big spell at mouse location"
- [ ] Add big spell cooldown UI - ask Cursor: "Add cooldown UI display for big spell"
- [ ] Test: Selection works, spells work in battle

#### Day 8: Hero Switching & Win Conditions

**Cursor AI Prompts to Use:**

- "Add hero death detection to Hero.gd"
- "Create hero switching UI that appears when hero dies"
- "Implement win condition checking when all heroes are dead"

**Tasks:**

- [ ] Hero death detection - ask Cursor: "Add death detection to Hero.gd when health reaches 0"
- [ ] Hero switching system (no switching before death) - ask Cursor: "Prevent hero switching before death"
- [ ] Hero switching overlay UI (appears on death, press 1, 2, or 3 to select) - ask Cursor: "Create HeroSwitchingUI.gd overlay with number key selection that appears on hero death"
- [ ] 5-second respawn delay (player can only select hero during this time) - ask Cursor: "Add 5-second respawn delay where player can only select hero"
- [ ] Hero respawn system (respawn at original spawn position) - ask Cursor: "Add hero respawn at original spawn point"
- [ ] 3-second spawn protection (invincibility after respawn) - ask Cursor: "Add 3-second invincibility after hero respawn"
- [ ] Win condition (all 3 heroes dead) - ask Cursor: "Add win condition check to BattleManager.gd when all 3 heroes are dead"
- [ ] Match timer (10 minutes) - ask Cursor: "Add 10-minute match timer"
- [ ] Sudden death system (3.0x damage multiplier after 10 minutes) - ask Cursor: "Add sudden death system that applies 3.0x damage multiplier to all heroes after 10 minutes"
- [ ] Victory/defeat screen - ask Cursor: "Create victory/defeat screen UI"
- [ ] Test: Full gameplay loop works

### Week 2: Polish & Testing Prep

#### Day 8-9: Visual Polish (Blocks & Circles Only)

- [ ] Add damage numbers (text appears above units, fades out - simple text, no animation)
- [ ] Ensure all visuals are blocks/circles:
- Heroes: Colored circles (blue/green/red)
- Supports: Colored rectangles/squares (gray/red/yellow)
- Obstacles: Gray rectangular blocks
- Projectiles: Small colored circles
- Abilities: Colored circles/rectangles for areas
- [ ] Add health bars above units (colored rectangles, green/red)
- [ ] Add simple UI (ability cooldowns as text/numbers, support buttons as colored rectangles)
- [ ] Add victory/defeat screen (simple text on colored background)
- [ ] Add visual indicators: Player names, team colors, etc.
- [ ] NO ANIMATIONS - everything is static shapes that appear/disappear instantly

#### Day 10-11: Testing Features

- [ ] Add "Quick Start" button (skip selection, use defaults)
- [ ] Add simple instructions screen
- [ ] Add restart button
- [ ] Balance testing (adjust damage, health, cooldowns)
- [ ] Bug fixes

#### Day 12-14: Export & Distribution

- [ ] Export for Windows (.exe)
- [ ] Export for Mac (.app)
- [ ] Export for Linux (optional)
- [ ] Create simple README with controls
- [ ] Test exported versions
- [ ] Package for sharing (zip file)

## Demo Content

### 3 Heroes (All Available - Players Get All 3)

**Hero 1: Fighter**

- Visual: Large blue circle
- High HP, melee attack (short range)
- Ability 1 (Q): Dash (instant movement to clicked location)
- Ability 2 (E): Shield Bash (damage circle around hero, stuns enemies)
- Projectiles: None (melee only)
- Ultimate: Not in demo

**Hero 2: Shooter**

- Visual: Medium green circle
- Medium HP, ranged attack (long range)
- Ability 1 (Q): Rapid Fire (temporary attack speed buff - visual: green outline)
- Ability 2 (E): Piercing Shot (line projectile that hits multiple enemies)
- Projectiles: Small green circles
- Ultimate: Not in demo

**Hero 3: Mage**

- Visual: Small red circle
- Low HP, ranged magic attack (medium range)
- Ability 1 (Q): Fireball (area damage circle at target location)
- Ability 2 (E): Teleport (instant movement to nearby location)
- Projectiles: Small red circles
- Ultimate: Not in demo

### 3 Supports (All Available - Players Get All 3)

**Support 1: Tank**

- Visual: Large gray/blue rectangle (bigger than heroes)
- High HP, high melee damage, slow movement
- Behavior: Follows player within close range, walks to nearest enemy and attacks (no taunt, just high damage and slow speed)
- Projectiles: Small gray circles (weak) or melee attacks
- Role: Protects player, soaks damage, high melee damage
- Summon: Press 1
- Death: Gone for match when killed

**Support 2: Damage Dealer**

- Visual: Small red square (smaller than heroes)
- Low HP, high damage, fast movement
- Behavior: Follows player within medium range, attacks nearest enemy with projectiles
- Projectiles: Small red circles (strong, travel straight, blocked by obstacles)
- Role: High DPS, needs player protection
- Summon: Press 2
- Death: Gone for match when killed

**Support 3: Buffer**

- Visual: Small yellow square with yellow outline/glow (same size as damage dealer)
- Low HP, very low damage, medium movement
- Behavior: Follows player within medium range, provides attack speed/damage buffs via fixed-radius aura around player (not around buffer)
- Projectiles: None or very weak
- Role: Provides buffs, very fragile, needs protection
- Summon: Press 3
- Death: Gone for match when killed
- Aura: Fixed radius around player (colored circle visual indicator)

### 2 Big Spells (Choose 1)

**Spell 1: Area Blast**

- Visual: Large red circle appears instantly at cast location, disappears after 0.5 seconds
- Effect: Deals heavy damage to all enemies in large circle
- One-time use (button grays out after use)
- Activation: Press R key
- Use: Clear supports instantly or finish off low-health heroes
- No animation - circle appears, damage applies, circle disappears
- **Casting**: Cast at mouse location (instant cast)
- **Cooldown UI**: Shows cooldown status when available/used

**Spell 2: Massive Buff**

- Visual: Large green circle appears instantly at cast location, stays visible for 3 seconds, then disappears
- Effect: Provides huge damage/attack speed buff to player and supports in circle
- One-time use (button grays out after use)
- Activation: Press R key
- Use: Turn the tide of battle, make hero temporarily overpowered
- No animation - circle appears, buff applies, circle fades out
- **Casting**: Cast at mouse location (instant cast)
- **Affects**: Player and supports within the circle (supports that enter later also get buff)
- **Cooldown UI**: Shows cooldown status when available/used

## Game Design Details & Mechanics

### Match Rules & Timing

- **Hero Respawn Delay**: 5 seconds after hero death
- **Match Time Limit**: 10 minutes
- **Sudden Death**: After 10 minutes, all heroes receive a 3.0x damage multiplier
- **Win Condition**: All 3 heroes of one player must be eliminated (all heroes dead)

### Combat & Auto-Attack System

**Auto-Attack Behavior**:

- **Target Selection**: Always targets nearest enemy within attack range
- **Range Behavior**: Auto-attack stops when target moves out of range
- **Projectile Movement**: Projectiles travel in straight lines toward target
- **Collision**: Nothing can pass through obstacles (heroes, projectiles, abilities all blocked by obstacles)

**Combat Flow**:

- Heroes automatically attack nearest enemy when in range
- Attack stops if enemy moves out of range
- Projectiles are blocked by obstacles (walls/obstacles)
- Heroes cannot walk through obstacles

### Support AI Behavior

**Follow Behavior**:

- **Follow Distance**: Supports stay within a specific range of the player (different ranges for different support types)
- Tank: Closer follow range (stays near player)
- Damage Dealer: Medium follow range
- Buffer: Medium follow range

**Attack Behavior**:

- **Target Priority**: Always targets nearest enemy
- **Tank Support**: High melee damage, slow movement speed, walks directly to nearest enemy (no taunt mechanic, just high damage and slow speed)
- **Damage Dealer**: Attacks nearest enemy with ranged projectiles
- **Buffer**: Provides buffs, attacks rarely or with very weak projectiles

**Buffer Aura**:

- **Aura Radius**: Fixed radius around the player (not around the buffer itself)
- **Effect**: Provides attack speed/damage buffs to player within aura radius
- **Visual**: Colored circle around player indicates aura effect

**Support Death**:

- **Permanent**: When a support dies, it is gone for the rest of the match
- **No Respawn**: Supports cannot be resummoned once dead
- **One-Time Use**: Each support can only be summoned once per match

### Hero Switching & Respawn System

**Hero Switching Rules**:

- **No Pre-Death Switching**: Players cannot switch heroes before death
- **Death Required**: Hero switching only occurs when current hero dies

**Death & Respawn Flow**:

1. Hero dies (health reaches 0)
2. **5 Second Respawn Delay**: Player cannot do anything except select next hero
3. **Selection Overlay**: Hero selection UI appears as overlay (press 1, 2, or 3 to select)
4. **Respawn Location**: Hero respawns at original spawn position (not where they died)
5. **Spawn Protection**: 3 seconds of invincibility after respawn (cannot take damage)

**Selection UI**:

- **Overlay Display**: Hero selection UI appears as overlay during gameplay (does not pause game)
- **Input**: Press 1, 2, or 3 to select next hero
- **Time Limit**: Must select within 5 seconds (respawn delay)
- **Visual**: Shows available heroes with numbers 1, 2, 3

### Big Spell Mechanics

**Area Blast**:

- **Casting**: Cast at mouse location (click where you want the spell)
- **Cast Type**: Instant cast (no channel time)
- **Effect**: Large red circle appears instantly, deals damage to all enemies in area
- **Visual Duration**: Circle disappears after 0.5 seconds
- **Cooldown UI**: Shows spell status (available/used/cooldown)

**Massive Buff**:

- **Casting**: Cast at mouse location (click where you want the buff area)
- **Cast Type**: Instant cast (no channel time)
- **Effect**: Large green circle appears, provides damage/attack speed buff
- **Affects**: Player and all supports within the circle (supports that enter later also receive buff)
- **Visual Duration**: Circle stays visible for 3 seconds, then disappears
- **Cooldown UI**: Shows spell status (available/used/cooldown)

### Hero Abilities (Demo Design)

**Note**: For demo purposes, ability mechanics can be designed flexibly. Below are suggested implementations:**Fighter Abilities**:

- **Q - Dash**: Instant movement ability (can be click-to-dash or dash toward mouse)
- **E - Shield Bash**: Area damage around hero or at target location

**Shooter Abilities**:

- **Q - Rapid Fire**: Temporary attack speed buff (self-buff, visual indicator)
- **E - Piercing Shot**: Line projectile that hits multiple enemies

**Mage Abilities**:

- **Q - Fireball**: Area damage at target location
- **E - Teleport**: Instant movement to nearby location

**Ability Design Flexibility**: Since this is a demo, ability mechanics can be adjusted during development for best gameplay feel.

### Obstacle & Collision System

**Obstacles**:

- **Type**: Rectangular blocks (gray/colored)
- **Collision**: Solid - nothing can pass through
- **Blocked Entities**: Heroes, projectiles, abilities all blocked by obstacles
- **Placement**: 2-3 obstacles placed strategically in arena

**Arena Boundaries**:

- **Walls**: Invisible or visible boundaries prevent heroes from leaving arena
- **Collision**: Heroes cannot walk outside arena bounds

### Visual Feedback & UI

**Damage Numbers**:

- **Display**: Text numbers appear above damaged units
- **Behavior**: Can fade out or disappear instantly (no animation requirement)

**Health Bars**:

- **Display**: Always visible above units (or only when damaged - flexible for demo)
- **Visual**: Colored rectangles (green/red) showing health percentage

**Ability Cooldowns**:

- **Display**: Cooldown UI shows ability status
- **Format**: Numbers, progress bars, or both (flexible for demo)

**Support Indicators**:

- **Display**: Visual indicator showing which supports are available/used
- **Format**: Colored rectangles or icons for each support (1, 2, 3)

**Big Spell Cooldown**:

- **Display**: Cooldown UI shows big spell status (available/used)
- **Visual**: Button or indicator shows when spell is ready

## Easy Testing Setup (2 Separate Computers on Same WiFi)

### Setup: Two Computers - WiFi IP Connection

**Requirements:**

- **2 separate computers** (one for each player)
- Both computers connected to **same WiFi network** (your home WiFi)
- Each computer runs the game independently
- Each player has their own full screen

**Connection Steps:**

1. **Both players connect to same WiFi network** (your home WiFi)
2. **Player 1 (Host - Your Computer)**:

- Launch game on your computer
- Click "Host Game" button
- Game displays your WiFi IP address in big text (e.g., "192.168.1.100")
- Tell Player 2 your IP address (or show them the screen)

3. **Player 2 (Client - Friend's Computer)**:

- Launch game on friend's computer
- Click "Join Game" button
- Enter WiFi IP address from Player 1 (type it in the text field)
- Click "Connect" button
- Wait for "Connected!" message

4. **Both Players**:

- Once both see "Ready" or "Connected" status
- Click "Start Battle" button
- Game begins - each player controls their hero on their own computer screen!

**Why This Works:**

- Godot's built-in networking handles everything automatically
- Uses WiFi IP address for direct connection
- No port forwarding needed (local network only)
- No external servers needed
- Works instantly on same WiFi
- Each player has full screen on their own computer

**Troubleshooting:**

- **Can't connect?** Make sure both computers are on same WiFi network
- **Firewall blocking?** Windows/Mac may ask to allow game - click "Allow"
- **Wrong IP?** WiFi IP should start with `192.168.x.x` or `10.x.x.x` (local network)
- **Still stuck?** Check WiFi connection on both computers - both must be connected to same router

## Easy Running & Testing Guide

### For Quick Testing (Development)

1. **Open in Godot**:

- Launch Godot 4.x
- Open project folder
- Press F5 to run (or click Play button)
- Game runs in editor - quick iteration

2. **Test Single-Player**:

- Use "Quick Start" mode
- Test all mechanics yourself
- Check for bugs before multiplayer testing

3. **Test Multiplayer Locally**:

- Run game twice (two instances)
- First instance: Click "Host Game"
- Second instance: Click "Join Game", enter `localhost` or `127.0.0.1`
- Both windows show the same game
- Test connection and gameplay

### For Testing with Friends (Same Home/Network)

**Step-by-Step Guide:**

1. **Export the Game** (One Time Setup):

- In Godot: Project → Export
- Select platform (Windows/Mac/Linux)
- Click "Export Project"
- Choose location (creates single .exe/.app file)
- No installation needed - just one file!

2. **Share with Friends**:

- Copy exported file to USB drive
- Or upload to Google Drive/Dropbox and share link
- Friends download/copy the file
- **No installation** - just double-click to run

3. **Connect and Play** (2 Computers on Same WiFi):

**Setup: Each player uses their own computer**a. **Player 1 (Host - Your Computer)**:

    - Launch game on your computer
    - Click "Host Game" button
    - Game shows WiFi IP address in big text (e.g., "192.168.1.100")
    - Tell Player 2 the IP address (or show them the screen)

b. **Player 2 (Client - Friend's Computer)**:

    - Launch game on friend's computer (separate computer)
    - Click "Join Game" button
    - Enter WiFi IP address from Player 1 (type it in)
    - Click "Connect" button
    - Wait for "Connected!" message

c. **Both Players**:

    - Once both see "Ready" status
    - Click "Start Battle" button
    - Game begins! Each player controls their hero on their own computer

4. **Quick Troubleshooting**:

- **Can't connect?** Make sure both computers are on same WiFi network (same router)
- **Firewall blocking?** Windows/Mac may ask to allow game - click "Allow"
- **Wrong IP?** WiFi IP should start with `192.168.x.x` or `10.x.x.x` (local network)
- **Still stuck?** Verify both computers show they're connected to WiFi in system settings

**Pro Tip:** Write down your computer's IP address before friends arrive - you can find it in:

- Windows: Open Command Prompt, type `ipconfig`, look for "IPv4 Address"
- Mac: System Preferences → Network → WiFi → Advanced → TCP/IP

## Export & Sharing Instructions

### Exporting the Demo

1. **In Godot**:

- Project → Export
- Select platform (Windows/Mac/Linux)
- Click "Export Project"
- Choose export location
- Creates single executable file

2. **For Windows**:

- Export as `.exe`
- Friends just double-click to run
- No installation needed

3. **For Mac**:

- Export as `.app`
- Friends double-click to run
- May need to allow in Security settings

4. **Sharing**:

- Zip the exported file
- Upload to Google Drive/Dropbox
- Share link with friends
- Include README with controls

### Testing Checklist

**Connection Testing:**

- [ ] Host can start game and see IP address
- [ ] Client can connect using IP address
- [ ] Connection status shows correctly
- [ ] Both players can see each other in game
- [ ] Disconnection handled gracefully

**Gameplay Testing:**

- [ ] Both players can move (synchronized)
- [ ] Combat works (damage, health bars sync)
- [ ] Abilities work (cooldowns visible, sync properly)
- [ ] Supports can be summoned (both players see them)
- [ ] Supports fight enemies (AI works for both)
- [ ] Big spell works (visual effects sync)
- [ ] Hero switching works (both players see hero change)
- [ ] Win condition triggers (both players see victory/defeat)
- [ ] Game can restart
- [ ] No crashes during gameplay
- [ ] No lag or desync issues

## Demo Controls Reference

**Player 1 (WASD Controls)**:

- **Move**: WASD keys
- **Aim/Attack**: Mouse (auto-attacks nearest enemy in range)
- **Ability 1**: Q
- **Ability 2**: E
- **Summon Support 1**: 1
- **Summon Support 2**: 2
- **Summon Support 3**: 3
- **Big Spell**: R

**Player 2 (WASD Controls)**:

- **Move**: WASD keys
- **Aim/Attack**: Mouse (auto-attacks nearest enemy in range)
- **Ability 1**: Q
- **Ability 2**: E
- **Summon Support 1**: 1
- **Summon Support 2**: 2
- **Summon Support 3**: 3
- **Big Spell**: R

**Hero Switching** (when hero dies):

- **Select Hero 1**: Press 1
- **Select Hero 2**: Press 2
- **Select Hero 3**: Press 3

## Success Criteria for Demo

✅ **Playable**: Two players can complete a full match✅ **Core Mechanics Work**: Movement, combat, supports, spells, hero switching✅ **No Critical Bugs**: Game doesn't crash, win condition works✅ **Easy to Share**: Single file, friends can run without setup✅ **Fun to Test**: Core gameplay loop is engaging

## Post-Demo: What to Test & Gather Feedback

1. **Gameplay Feel**:

- Is combat satisfying?
- Are supports useful?
- Is hero switching interesting?
- Is big spell impactful?

2. **Balance**:

- Are heroes balanced?
- Are supports too strong/weak?
- Is big spell too powerful?

3. **Controls**:

- Are controls intuitive?
- Any input issues?

4. **Fun Factor**:

- Is it fun to play?
- What would make it more fun?

## Next Steps After Demo

Based on feedback, decide:

- Expand to full game (3 heroes, 3 supports, lanes, etc.)
- Adjust mechanics
- Add more content
- Improve visuals
- Add online multiplayer

## Development Workflow with Cursor AI

### Setup

1. **Install Godot 4.x**: https://godotengine.org/download
2. **Open Cursor AI**: Use Cursor as your code editor
3. **Create New Godot Project**: 

- Open Godot, create new 2D project
- Save project in a folder
- Open that folder in Cursor AI

4. **Configure Cursor for GDScript**:

- Cursor will recognize .gd files automatically
- Use Cursor's AI chat to ask for GDScript code

### Working with Cursor AI

**Best Practices:**

- **Ask Cursor to create scripts**: "Create a Hero.gd script with movement and health"
- **Use Cursor for networking**: "Help me set up multiplayer with WiFi IP connection"
- **Iterate with AI**: Ask Cursor to modify existing code
- **Test in Godot**: Write code in Cursor, test in Godot editor
- **Use Cursor's codebase search**: Ask Cursor to find related code

**Example Cursor Prompts:**

- "Create a hero controller script that moves with WASD keys"
- "Implement support AI that follows the player and attacks enemies"
- "Create NetworkManager.gd for local WiFi multiplayer with host/join functionality"
- "Add WiFi IP address display and connection UI"
- "Create a simple UI for hero selection"
- "Help me debug why the multiplayer connection isn't working"
- "Synchronize hero positions between two players over network"
- "Add RPC functions for player actions (movement, abilities, supports)"

### Development Process

1. **Plan Feature**: Review plan section (Day 1-2, Day 3-4, etc.)
2. **Ask Cursor**: Request code implementation in Cursor AI chat
3. **Review Code**: Check Cursor's generated code
4. **Test in Godot**: Run game in Godot editor (F5)
5. **Iterate**: Ask Cursor to fix bugs or improve code
6. **Commit Progress**: Save working versions frequently

### Quick Start Guide for Developers

1. **Install Godot 4.x**: https://godotengine.org/download
2. **Open Cursor AI**: Use Cursor for code editing
3. **Create New Project**: 2D project in Godot, open folder in Cursor
4. **Follow Demo Plan**: Use Cursor AI to implement Day 1-2, then Day 3-4, etc.
5. **Test Frequently**: After each feature, test in Godot (F5)
6. **Export Early**: Test export process early to catch issues
7. **Get Feedback**: Share with friends as soon as playable

## Resources for Demo

**Development Tools:**

- **Cursor AI**: https://cursor.sh/ (AI-powered code editor)
- **Godot Engine**: https://godotengine.org/download

**Documentation:**

- **Godot Docs**: https://docs.godotengine.org/
- **GDScript Basics**: https://docs.godotengine.org/en/stable/getting_started/scripting/gdscript/
- **Godot Multiplayer**: https://docs.godotengine.org/en/stable/tutorials/networking/
- **2D Movement**: Godot's CharacterBody2D tutorial
- **Export Guide**: Godot's export documentation

**Using Cursor AI:**

- Ask Cursor to explain GDScript syntax if needed
- Use Cursor's codebase search to find related code
- Ask Cursor to debug errors: "Why is this code not working?"