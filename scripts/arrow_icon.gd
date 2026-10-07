extends Control
## Font-independent arrow icon drawn with a polygon (works the same in web
## exports where Unicode arrow glyphs may be missing from the font).
## angle_deg: 0 = up, 90 = right, 180 = down, 270 = left (clockwise).

@export var angle_deg: float = 0.0
@export var color: Color = Color.WHITE
@export var outline: Color = Color(0, 0, 0, 0.85)
@export var icon_size: float = 28.0


func _ready() -> void:
	custom_minimum_size = Vector2(icon_size, icon_size)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func set_angle(a: float) -> void:
	angle_deg = a
	queue_redraw()


func _draw() -> void:
	var s := icon_size * 0.5
	var base: Array[Vector2] = [
		Vector2(0, -s), Vector2(s * 0.85, -s * 0.05), Vector2(s * 0.32, -s * 0.05), Vector2(s * 0.32, s),
		Vector2(-s * 0.32, s), Vector2(-s * 0.32, -s * 0.05), Vector2(-s * 0.85, -s * 0.05),
	]
	var pts := PackedVector2Array()
	var c := Vector2(icon_size, icon_size) * 0.5
	var r := deg_to_rad(angle_deg)
	for p in base:
		pts.append(c + p.rotated(r))
	draw_colored_polygon(pts, color)
	var closed := pts.duplicate()
	closed.append(pts[0])
	draw_polyline(closed, outline, 2.0)
