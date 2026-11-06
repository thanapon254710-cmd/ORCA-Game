# Home button

Click the house at the top left during gameplay to return to the start menu.
Open question windows close on return. Pressing Start begins a fresh game.
The button belongs to the persistent InventoryHUD, so it is available on all floors,
including when the inventory panel is closed. It is hidden together with the HUD on the menu.
During floor transitions or the paused Game Over sequence it cannot interrupt the transition.

Edit InventoryHUD/Root/HomeButton in scenes/inventory/inventory.tscn to move or resize it.
Icon: assets/ui/home_icon.png. Behavior: scripts/ui/home_button.gd.

The icon was made with the built-in image generation tool.
Prompt: A single transparent PNG Home icon for a hand-drawn horror game: recognizable house,
ivory chalk strokes, black charcoal edging, deep blood-red brush accent and tiny drips;
bold at small sizes, centered, no text, no extra objects, no 3D.
