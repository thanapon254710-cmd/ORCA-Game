# Story flow
Start -> How to Play -> room407cutscene -> Blink -> floor5 (two dialogue pages).
Every floor entry displays its IntroUI dialogue and pauses gameplay until Enter finishes all pages. Edit IntroUI > Passages in the floor Inspector. Floor2 directs the player to the bookshelf at entry.

Ending: parking.gd calls GameState.finish_story() after the red car escapes and the success message finishes. scenes/ui/ending.tscn contains two passages; then scenes/ui/the_end.tscn displays THE END. Enter returns home. The original prologue is no longer in the new-game path.

Floor5 IntroUI > Voice accepts an optional AudioStream for the Orca line. No AI voice asset has been generated. The voice stops when advancing.

How to Play uses the original Start/Exit artwork with red hover: Start begins the classroom scene; Exit returns to the title.
