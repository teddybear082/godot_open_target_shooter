extends Node


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
enum Buttons {
	VR_BUTTON_BY = 1,
	VR_GRIP = 2,
	VR_BUTTON_3 = 3,
	VR_BUTTON_4 = 4,
	VR_BUTTON_5 = 5,
	VR_BUTTON_6 = 6,
	VR_BUTTON_AX = 7,
	VR_BUTTON_8 = 8,
	VR_BUTTON_9 = 9,
	VR_BUTTON_10 = 10,
	VR_BUTTON_11 = 11,
	VR_BUTTON_12 = 12,
	VR_BUTTON_13 = 13,
	VR_PAD = 14,
	VR_TRIGGER = 15
}

## Button to reload
export (Buttons) var reload_button_id = Buttons.VR_BUTTON_AX


onready var primary_hand_function_pickup = get_parent().get_node("Player/FPController/RightHandController/Function_Pickup")
onready var hand_gun_pickable = get_parent().get_node("PickableHandGun")
onready var flat_screen_hand_gun = hand_gun_pickable.get_node("WeaponPistol")
onready var rifle_pickable = get_parent().get_node("PickableRifle")
onready var flat_screen_rifle = rifle_pickable.get_node("WeaponRifle")
onready var weapon_hud = get_parent().get_node("Player/FPController/LeftHandController/LeftHandHUD").get_scene_instance()
var current_weapon : Weapon


signal shooting(spawn_point, bullet_speed, bullet_scene, bullet_damage)
# Called when the node enters the scene tree for the first time.
func _ready():
	hand_gun_pickable.connect("action_pressed", self, "fire_handgun")# Replace with function body.
	rifle_pickable.connect("action_pressed", self, "fire_rifle")
	
	flat_screen_hand_gun.ammo_loaded = (
			flat_screen_hand_gun.magazine_size
	)
	
	flat_screen_rifle.ammo_loaded = (
			flat_screen_rifle.magazine_size
	)
	#primary_hand_function_pickup._pick_up_object(rifle_pickable)
	#current_weapon = flat_screen_rifle
	
	#weapon_hud.update_weapon_ammo(current_weapon.ammo_loaded)
	#weapon_hud.update_weapon_icon(current_weapon.icon)
	#_reload_current_weapon()
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if primary_hand_function_pickup == null:
		return
		
	if primary_hand_function_pickup.picked_up_object == null:
		return
		
	if primary_hand_function_pickup.get_parent().is_button_pressed(reload_button_id):
		_reload_current_weapon()

func fire_handgun(_pickable_weapon_parent):
	flat_screen_hand_gun.fire()
	emit_signal("shooting", flat_screen_hand_gun)
	weapon_hud.update_weapon_ammo(current_weapon.ammo_loaded)

func fire_rifle(_pickable_weapon_parent):
	flat_screen_rifle.fire()
	emit_signal("shooting", flat_screen_rifle)
	weapon_hud.update_weapon_ammo(current_weapon.ammo_loaded)

func switch_current_weapon(selected_pickable_weapon):
	if selected_pickable_weapon == hand_gun_pickable:
		current_weapon = flat_screen_hand_gun
		weapon_hud.update_weapon_ammo(current_weapon.ammo_loaded)
		weapon_hud.update_weapon_icon(current_weapon.icon)
	
	if selected_pickable_weapon == rifle_pickable:
		current_weapon = flat_screen_rifle
		weapon_hud.update_weapon_ammo(current_weapon.ammo_loaded)
		weapon_hud.update_weapon_icon(current_weapon.icon)
############################
#      Private Methods     #
############################

func _reload_current_weapon() -> void:
	if not current_weapon.is_reloading:
		# Unload mag
		current_weapon.is_reloading = true
		current_weapon.reload_unload()
		weapon_hud.update_weapon_ammo(current_weapon.ammo_loaded)
		yield(current_weapon, "reload_unload_anim_done")
		
		current_weapon.reload_load()
		yield(current_weapon, "reload_load_anim_done")
		current_weapon.is_reloading = false
		weapon_hud.update_weapon_ammo(current_weapon.ammo_loaded)
