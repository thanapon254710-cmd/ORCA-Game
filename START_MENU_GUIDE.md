# Start menu

Press F5 to launch the menu. Start begins a fresh game on floor 5; Exit closes the game.
The menu uses the original PNG files without modifying them. AtlasTexture regions separate
the Start and Exit images into individual real TextureButton nodes.
Only the hovered button turns blood red; keyboard Tab focus also highlights a button.
The inventory and its shortcut hint are hidden on the menu, and restored when gameplay begins.

Edit scenes/ui/start_menu.tscn in the 2D editor:
- Artwork/Background: original title illustration.
- Artwork/StartButton and ExitButton: clickable objects.
- StartBlood / ExitBlood: the red hover artwork.
- StartGlow / ExitGlow: a soft red glow behind the hovered button.
- Select StartMenu to change First Scene in the Inspector.

The design uses 1152 x 648 coordinates and fits the window without distortion, with black
bars if necessary. The existing game window/fullscreen settings are preserved.

Files: scenes/ui/start_menu.tscn, scripts/ui/start_menu.gd, assets/ui/start_menu/,
and project.godot (main scene setting).
