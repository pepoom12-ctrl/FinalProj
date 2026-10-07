extends Node
## Autoload singleton: run-wide state that survives scene changes.

# Matches Player.Staff enum: 0 = Inferno (fire), 1 = Glacier (ice), 2 = Tempest (lightning)
var selected_staff: int = 0
