# Game intro

Flow: Start menu -> How to Play -> Begin -> room407 introduction -> Enter -> blink to black -> floor5 warning -> Enter -> gameplay.

The text is stored in each scene's IntroUI/Control/Panel/Label. Edit it there in Godot. ContinueHint is the Enter prompt. Fade is the black ColorRect animated by a Tween.

Controllers: scripts/ui/room407_intro.gd and scripts/ui/floor5_intro.gd. The original floor and room objects/scripts are preserved.

IntroUI uses Always processing while the SceneTree is paused. This freezes player movement, Orca and ordinary interactions. Enter is consumed by the intro; held keys cannot skip the second message. Floor5 dismisses the warning before unpausing. Failed scene loading keeps the player safe and offers Enter to retry.

GameState remembers both messages for the current run. Begin calls reset_game(), so every new game plays them again. Returning to a floor or respawning does not replay the intro. Running floor5 directly also shows its warning once.

Control and Fade are hidden in the saved scenes so they do not cover the level editor. To edit the dialogue visually, temporarily show IntroUI/Control using its eye icon. Hide it again before saving. The scripts show it automatically during play.

Test the complete flow with F6 on start_menu.tscn or F5 with start_menu.tscn set as the main scene.

## Revised classroom staging
The room407 intro places the player at the editable CutsceneSeat marker, beside a desk, facing up toward the board. Ordinary room visits still use their normal entrance. Dialogue background opacity is 65%; text remains fully readable.

After the classroom fades out, scenes/ui/blink.tscn displays "You Blinked your Eyes" on black, fades the text in, holds it for two seconds, then fades it out and opens floor5 automatically. Change hold_seconds on the Blink root to adjust the duration. The player remains paused throughout.

## Orca prologue
The full flow is Start -> How to Play -> Begin -> five prologue passages -> room407 -> blink -> floor5 warning -> gameplay. Press Enter for each passage; transitions fade the text smoothly and ignore held/repeated presses. Inventory and Home are hidden during the black prologue. Edit the five Passages on the root of scenes/ui/prologue.tscn in the Inspector. Text and Hint are actual Label nodes.
