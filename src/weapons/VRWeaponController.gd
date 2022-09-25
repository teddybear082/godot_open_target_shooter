extends Spatial


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
onready var weapon_pickable = get_parent()
onready var flat_screen_weapon = get_child(0)
signal shooting(spawn_point, bullet_speed, bullet_scene, bullet_damage)
# Called when the node enters the scene tree for the first time.
func _ready():
	weapon_pickable.connect("action_pressed", self, "fire_flat_weapon")# Replace with function body.
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
func fire_flat_weapon(_pickable_weapon_parent):
	flat_screen_weapon.fire()
	emit_signal("shooting", flat_screen_weapon)
