# Inventory

Open scenes/inventory/inventory_demo.tscn and press F6 to test.
Walk near an item and press E. I shows/hides the inventory bar.
The seven slots show counts; collected items survive floor changes during this run.
Inventory is not saved when the game closes. GameState.reset_game() starts a fresh inventory.

## Place real objects in your floors
Drag a scene from scenes/inventory/items/ into the floor's Scene tree.
Move it in the 2D editor. Each scene has Visual (Sprite2D), CollisionShape2D,
and Prompt (Label). Existing players detect it through InteractArea.
Use a unique node name for every pickup. The default persistence ID is floor path + node path.
If you need to move/rename objects while retaining IDs, set Pickup Id to a globally unique value.
Do not give two pickups the same Pickup Id.

The seven included SVG icons are simple replaceable icons, not cutouts of the supplied screenshots.
Replace Visual > Texture to use your final art, and update the corresponding HUD Icon texture.
Edit the inventory's visible nodes in scenes/inventory/inventory.tscn.
Inventory is an Autoload, so do not also instance it manually in a floor.

## Item IDs
key_yellow, key_blue, key_purple, key_gold, book_blue, book_white, book_orange.

## Use in a door or puzzle script
```gdscript
if Inventory.has_item("key_yellow"):
	# Open your door here. This only checks possession.
	pass

# To consume an item after a successful action:
Inventory.remove_item("key_yellow")

# To check a book:
if Inventory.has_item("book_blue"):
	pass
```

Consumed pickups do not reappear when returning to a floor.
No existing doors/puzzles consume items automatically; connect those rules explicitly.
The demo does not change the project's main scene or the team's floor layouts.
