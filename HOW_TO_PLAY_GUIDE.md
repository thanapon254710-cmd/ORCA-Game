# How to Play

F5 launches Start Menu -> Start -> How to Play -> Begin -> Floor 5.
Back (or Escape) returns to the menu. Begin resets inventory and question progress.
The inventory and Home HUD are hidden while reading; they return during gameplay.

Edit scenes/ui/how_to_play.tscn: every instruction, button and background is a saved node.
Select HowToPlay and change Gameplay Scene in the Inspector to choose the starting floor.
The background uses slow lighting changes; the instruction text remains steady.

Files: scenes/ui/how_to_play.tscn, scripts/ui/how_to_play.gd,
assets/ui/how_to_play/. scripts/ui/start_menu.gd routes Start here;
project.godot launches the start menu.

Artwork generated with the built-in image tool. Prompt: dark school corridor at midnight,
charcoal horror illustration, empty nearly black chalkboard on the left for readable text,
sinister orca mascot watching from a doorway on the right, blood-red light and dusty haze,
no text or UI in the image. Full prompt was supplied in the generation tool call.
