# PacMan FPS - Hybrid Game

A unique hybrid game that combines classic Pacman gameplay with third-person shooter mechanics!

## How to Play

### Pacman Mode (2D Top-Down)
- **Movement**: Use WASD or Arrow Keys to move Pacman around the maze
- **Objective**: Collect pellets (white dots) and avoid ghosts
- **Special**: Eat cherries (red dots) to switch to Shooter Mode!

### Shooter Mode (3D Third-Person)
- **Movement**: WASD to move, Mouse to look around
- **Jump**: Spacebar (high jumps to go over walls!)
- **Shoot**: Left Mouse Button to shoot at ghosts
- **Objective**: Defeat all ghosts or survive for 30 seconds
- **Return**: Automatically returns to Pacman mode when objectives are met

## Game Features

- **Seamless Mode Switching**: Cherry pickup triggers instant transition from 2D to 3D
- **Dynamic 3D Maze**: The same maze layout converted to 3D with jumpable walls
- **Smart Ghost AI**: 
  - 2D Mode: Classic Pacman ghost behavior
  - 3D Mode: Shooting enemies with pathfinding
- **High Jumps**: Jump over walls in 3D mode for strategic gameplay
- **Score System**: Points for pellets (10) and cherries (100)

## Controls

### 2D Pacman Mode
- **W/A/S/D** or **Arrow Keys**: Move Pacman

### 3D Shooter Mode
- **W/A/S/D**: Move player
- **Mouse**: Look around (FPS-style camera)
- **Spacebar**: Jump (high jump over walls)
- **Left Mouse Button**: Shoot
- **ESC**: (Godot default) - Return to editor

## Technical Details

- Built with Godot 4.4
- Hybrid 2D/3D gameplay system
- Dynamic scene switching
- Real-time maze conversion from 2D to 3D
- Physics-based bullet system
- Navigation-based AI for 3D ghosts

Enjoy this unique twist on the classic Pacman formula!
