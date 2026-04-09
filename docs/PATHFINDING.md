# Click-to-Move Pathfinding System

This document describes the click-to-move pathfinding functionality added to the tile-based dungeon game.

## Features

✅ **Click-to-Move**: Click any walkable tile to automatically navigate there  
✅ **A* Pathfinding**: Intelligent pathfinding that finds the optimal route  
✅ **Smooth Animation**: Reuses existing movement animations for seamless tile-by-tile movement  
✅ **WASD Override**: WASD keys interrupt pathfinding and take immediate control  
✅ **Visual Feedback**: Destination and path highlights show your planned route  
✅ **Multiple Map Types**: Works with dungeons, caverns, outdoor areas, and cities  

## How It Works

### 1. Click a Destination
- Click any **walkable tile** (floor, road, corridor) visible on the map
- The system calculates the shortest path using A* algorithm
- **Green pulsing border** appears around your destination
- **Blue dots** mark the path you'll take

### 2. Automatic Movement
- Character moves **one tile at a time** using existing smooth animations
- Movement respects game rules (can't walk through walls, locked doors, etc.)
- **Queue system** processes moves sequentially for smooth gameplay

### 3. WASD Override
- Press **W/A/S/D** at any time to interrupt pathfinding
- Takes immediate control for manual movement
- Pathfinding highlights disappear

### 4. Walkable Tiles
**✅ Walkable:**
- Floor, road, corridor tiles
- Open doors, stairs, waypoints
- Tiles with items, monsters, or features

**❌ Not Walkable:**
- Walls, shrubs, pillars
- Locked doors
- Out-of-bounds areas

## Technical Implementation

### JavaScript Components
- **PathfindingHook**: Main LiveView hook handling click events and pathfinding
- **A* Algorithm**: Efficient pathfinding with 4-directional movement
- **Movement Queue**: Processes path moves sequentially
- **Visual Highlights**: CSS animations for destination and path markers

### Elixir Integration
- **Walkability Grid**: 2D boolean array generated from dungeon tiles
- **Movement Events**: Integrates with existing `move_player` event system
- **Real-time Updates**: Pathfinding data updates when map or player changes

### CSS Styling
- `.pathfinding-destination`: Green pulsing border for destination
- `.pathfinding-path`: Blue dots marking the path
- Smooth animations with proper z-indexing

## Usage Tips

1. **Click Planning**: Click to see your path before committing to movement
2. **Quick Navigation**: Great for moving across large open areas
3. **Combat Ready**: WASD still works instantly for tactical movement
4. **Visual Feedback**: Watch the highlights to understand your planned route

## Compatibility

- Works with all existing game features (combat, dialogs, interactions)
- Respects fog of war and revealed tile restrictions
- Compatible with mobile touch controls and desktop clicks
- Maintains all existing WASD keyboard functionality 