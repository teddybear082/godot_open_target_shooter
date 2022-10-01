class_name LevelManager
extends Spatial
# Script to keep track of and manage level properties


### Signals ###
signal change_scene_request(target_scene_res_path)


### Private variables ###
var _par_time: float
var _best_time: float = -1.0

var _is_player_on_range: bool = false
var _run_time_raw: float setget _set_run_time_raw
var _run_time: float
var _bonus_value: int = 1000

var _missed_enemy_penalty: float = 1.2
var _hit_friendly_penalty: float = 0.6

#for VR height selection
var _is_taller = false

### Onready variables ###
onready var _primary_light: DirectionalLight = $WorldEnvironment/DirectionalLight
onready var _player = $Player
onready var _hand_gun = $PickableHandGun
onready var _rifle = $PickableRifle
onready var _vr_weapon_controller = $VRWeaponController
onready var _radial_menu = $Weapon_RadialMenu
onready var _level_radial_menu = $Level_RadialMenu
#onready var _camera_system: LevelCameraSystem = $LevelCameraSystem
onready var _level_name := filename.get_file().get_basename()
onready var _level_ui: LevelUI = get_node("LevelUI")
onready var _vr_level_ui = get_node("Player/FPController/RightHandController/RightHandHUD").get_scene_instance()
onready var _pause_menu: MultiPageUIMagager = $PauseMenu/PauseMenu
onready var _run_summary_page: Control = $RunSummaryPage/RunSummaryPage
onready var _run_summary_viewport3D = $RunSummaryViewport3D
onready var _run_summary_page_vr = $RunSummaryViewport3D.get_scene_instance()

onready var _target_manager: TargetManager = $TargetManager
onready var _bullet_manager: BulletManager = $BulletManager
onready var _badge_tracker: BadgeTracker = $BadgeTracker

onready var _audio_player_run_start: AudioStreamPlayer = $AudioStreamRunStart
onready var _audio_player_run_end: AudioStreamPlayer = $AudioStreamRunEnd


############################
# Engine Callback Methods  #
############################
func _ready() -> void:
	MusicManager.transition_to_track(
			MusicManager.Tracks.OFF_RANGE, 3
	)
	
	
	_par_time = SaveLoad.load_level_par_time(_level_name)
	_level_ui.set_label_time_par(_par_time)
	_vr_level_ui.set_label_time_par(_par_time)
	_best_time = SaveLoad.load_level_best_time(_level_name)
	if _best_time != -1.0:
		_level_ui.set_label_time_best(_best_time)
		_vr_level_ui.set_label_time_best(_best_time)
	_run_summary_page.set_level_par_time(_par_time)
	_run_summary_page_vr.set_level_par_time(_par_time)
	
	_connect_signals()
	_init_level_ui()
	
	if UserPreferences.snap_turn_mode == true:
		var right_controller = _player.get_node("FPController/RightHandController")
		right_controller.get_node("Function_Turn_movement").smooth_rotation = false
		

	if UserPreferences.left_handed_mode == true: 
		var left_controller = _player.get_node("FPController/LeftHandController")
		var right_controller = _player.get_node("FPController/RightHandController")
		var left_controller_children = left_controller.get_children()
		var right_controller_children = right_controller.get_children()
		left_controller.get_node("Function_Teleport").enabled = false
		right_controller.get_node("Function_Teleport").enabled = true
		
		#This isn't working right now for whatever reason
		#for child in left_controller_children:
		#	if child.is_in_group("movement_providers"):
		#		left_controller.remove_child(child)
		#		right_controller.add_child(child)
		#for child in right_controller_children:
		#	if child.is_in_group("movement_providers"):
		#		right_controller.remove_child(child)
		#		left_controller.add_child(child)
		_radial_menu.controller = left_controller
		_level_radial_menu.controller = right_controller
		_vr_weapon_controller.primary_hand_function_pickup = left_controller.get_node("Function_Pickup")
		
func _process(delta: float) -> void:
	if _is_player_on_range:
		_set_run_time_raw(_run_time_raw + delta)

#	if _run_summary_viewport3D.visible == true:
#		var vrCamera = _player.get_node("FPController/ARVRCamera")
#		var viewDir = -vrCamera.global_transform.basis.z
#		var camPos = vrCamera.global_transform.origin
#		var distance = 2.0
#		var currentPosition = camPos + viewDir * distance
#		_run_summary_viewport3D.global_transform.origin = currentPosition



func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		#_pause_menu.popup()
		get_tree().quit()

############################
# Signal Connected Methods #
############################
func _on_player_passed_through_range_entrance() -> void:
	_start_run()


func _on_player_passed_through_range_exit() -> void:
	_finish_run()


func _on_player_shooting(player_weapon: Weapon) -> void:
	if player_weapon.ammo_loaded <= 0:
		return
	_bullet_manager.spawn_bullet(player_weapon, _player)
	if _is_player_on_range:
		_bullet_manager.update_run_accuracy(_target_manager.target_count_enemy_down())


func _on_enemy_target_hit() -> void:
	if _is_player_on_range:
		_level_ui.set_label_enemy_hits(
				_target_manager.target_count_enemy_down(), _target_manager.target_count_enemy()
		)
		_vr_level_ui.set_label_enemy_hits(
				_target_manager.target_count_enemy_down(), _target_manager.target_count_enemy()
		)
		_bullet_manager.update_run_accuracy(_target_manager.target_count_enemy_down())


func _on_friendly_target_hit() -> void:
	if _is_player_on_range:
		_level_ui.set_label_friendly_hits(
				_target_manager.target_count_friendly_down()
		)
		_vr_level_ui.set_label_friendly_hits(
				_target_manager.target_count_friendly_down()
		)

func _on_quit_level() -> void:
	emit_signal("change_scene_request", "res://src/ui/main_menu/main_menu_vr.tscn")

func _on_radial_level_entry_selected(entry):
	if entry == "home":
		#get_tree().quit()
		_on_quit_level()
	if entry == "level1":
		emit_signal("change_scene_request", "res://src/levels/level_1.tscn")
		#get_tree().change_scene("res://src/levels/level_1.tscn")
	if entry == "level2":
		emit_signal("change_scene_request", "res://src/levels/level_2.tscn")
		#get_tree().change_scene("res://src/levels/level_2.tscn")
	if entry == "level3":
		emit_signal("change_scene_request", "res://src/levels/level_3.tscn")
		#get_tree().change_scene("res://src/levels/level_3.tscn")
	if entry == "level4":
		emit_signal("change_scene_request", "res://src/levels/level_4.tscn")
		#get_tree().change_scene("res://src/levels/level_4.tscn")
	if entry == "level5":
		emit_signal("change_scene_request", "res://src/levels/level_5.tscn")
		#get_tree().change_scene("res://src/levels/level_5.tscn")

func _on_radial_entry_selected(entry):
	var radial_controller = _radial_menu.controller
	var vr_func_pickup = radial_controller.get_node_or_null("Function_Pickup")
	
	if vr_func_pickup == null:
		return
		
	if entry == "pistol":
		if vr_func_pickup.picked_up_object == _hand_gun:
			return
			
		if vr_func_pickup.picked_up_object == null:
			vr_func_pickup._pick_up_object(_hand_gun)
			_vr_weapon_controller.switch_current_weapon(_hand_gun)
			return
		
		else:
			vr_func_pickup.drop_object()
			vr_func_pickup._pick_up_object(_hand_gun)
			_hand_gun.visible = true
			_rifle.visible = false
			_vr_weapon_controller.switch_current_weapon(_hand_gun)
			return			
	
	if entry == "rifle":
		if vr_func_pickup.picked_up_object == _rifle:
			return
			
		if vr_func_pickup.picked_up_object == null:
			vr_func_pickup._pick_up_object(_rifle)
			_vr_weapon_controller.switch_current_weapon(_rifle)
			return
			
		else:
			vr_func_pickup.drop_object()
			vr_func_pickup._pick_up_object(_rifle)
			_rifle.visible = true
			_hand_gun.visible = false
			_vr_weapon_controller.switch_current_weapon(_rifle)
			return
			
	if entry == "height":
		if _is_taller == true:
			_player.get_node("FPController/PlayerBody").player_height_offset -= .20
			_is_taller = false
		else:
			_player.get_node("FPController/PlayerBody").player_height_offset += .20
			_is_taller = true
############################
#      Private Methods     #
############################
func _set_run_time_raw(seconds: float) -> void:
	_run_time_raw = seconds
	_level_ui.set_label_time(_run_time_raw)
	_vr_level_ui.set_label_time(_run_time_raw)


func _init_level_ui() -> void:
	_level_ui.set_label_enemy_hits(
			0, _target_manager.target_count_enemy()
	)
	_level_ui.set_label_friendly_hits(0)
	_vr_level_ui.set_label_enemy_hits(
			0, _target_manager.target_count_enemy()
	)
	_vr_level_ui.set_label_friendly_hits(0)
	
	

func _connect_signals() -> void:
	# Player
	GenUtils.connect_signal_assert_ok(
			_vr_weapon_controller, "shooting", 
			self, "_on_player_shooting"
	)
	
	# Target Manager
	GenUtils.connect_signal_assert_ok(
			_target_manager, "enemy_target_hit",
			self, "_on_enemy_target_hit"
	)
	GenUtils.connect_signal_assert_ok(
			_target_manager, "friendly_target_hit",
			self, "_on_friendly_target_hit"
	)
	GenUtils.connect_signal_assert_ok(
			_target_manager, "enemy_target_hit",
			_badge_tracker, "_on_enemy_target_hit"
	)
	GenUtils.connect_signal_assert_ok(
			_target_manager, "friendly_target_hit",
			_badge_tracker, "_on_friendly_target_hit"
	)
	
	# Pause menu
	GenUtils.connect_signal_assert_ok(
			_pause_menu, "quit_level", 
			self, "_on_quit_level"
	)
	
	# Bullet Manager
	GenUtils.connect_signal_assert_ok(
			_bullet_manager, "longshot_bullet",
			_badge_tracker, "_on_longshot_bullet"
	)
	
	# Badge Tracker
	GenUtils.connect_signal_assert_ok(
			_badge_tracker, "badge_earned",
			_level_ui, "_on_badge_earned"
	)
	GenUtils.connect_signal_assert_ok(
			_badge_tracker, "badge_earned",
			_vr_level_ui, "_on_badge_earned"
	)
	
	# VR Radial Gun Menu
	GenUtils.connect_signal_assert_ok(
			_radial_menu, "entry_selected", 
			self, "_on_radial_entry_selected"
	)
	
	# VR Level Selection Menu
	GenUtils.connect_signal_assert_ok(
			_level_radial_menu, "entry_selected", 
			self, "_on_radial_level_entry_selected"
	)
func _start_run() -> void:
	MusicManager.transition_to_track(
			MusicManager.Tracks.ON_RANGE, 1
	)
	_audio_player_run_start.play()
	_is_player_on_range = true
	_run_time_raw = 0
	_run_time = 0
	
	_target_manager.reset_targets()
	_bullet_manager.reset_run_stats()
	_badge_tracker.reset_badges()
	
	_level_ui.set_label_enemy_hits(0, _target_manager.target_count_enemy())
	_level_ui.set_label_friendly_hits(0)

	_vr_level_ui.set_label_enemy_hits(0, _target_manager.target_count_enemy())
	_vr_level_ui.set_label_friendly_hits(0)

	_run_summary_viewport3D.visible = false
	_run_summary_viewport3D.global_transform.origin.y = 4
	_run_summary_page_vr.reset_badges_icons()
	

func _update_and_show_run_summary(missed_enemy_penalty_time_total: float, hit_friendly_penalty_time_total: float) -> void:
	_run_summary_page.update_time_stats(
			_run_time, _run_time_raw, _badge_tracker.get_run_badge_time(),
			missed_enemy_penalty_time_total, hit_friendly_penalty_time_total
	)
	_run_summary_page_vr.update_time_stats(
			_run_time, _run_time_raw, _badge_tracker.get_run_badge_time(),
			missed_enemy_penalty_time_total, hit_friendly_penalty_time_total
	)
	
	
	_run_summary_page.update_misc_stats(
			_target_manager.target_count_enemy_down(), _target_manager.target_count_enemy(), 
			_target_manager.target_count_friendly_down(), _bullet_manager.run_acc, 
			_bullet_manager.run_bullet_count, _bullet_manager.run_longest_shot
	)
	_run_summary_page_vr.update_misc_stats(
			_target_manager.target_count_enemy_down(), _target_manager.target_count_enemy(), 
			_target_manager.target_count_friendly_down(), _bullet_manager.run_acc, 
			_bullet_manager.run_bullet_count, _bullet_manager.run_longest_shot
	)
	
	_run_summary_page.update_run_badges(_badge_tracker.get_run_badges())
	_run_summary_page_vr.update_run_badges(_badge_tracker.get_run_badges())
	#_run_summary_page.popup()
	_run_summary_page_vr.display_is_new_best()
	
	var vrCamera = _player.get_node("FPController/ARVRCamera")
	var viewDir = -vrCamera.global_transform.basis.z
	var camPos = vrCamera.global_transform.origin
	var distance = 2.0
	var currentPosition = camPos + viewDir * distance;
	var targetPosition = currentPosition;
	var movePosition = currentPosition;
	
	#_run_summary_viewport3D.look_at_from_position(currentPosition, camPos, Vector3(0,1,0))
	#_run_summary_viewport3D.rotation_degrees.y = 180
	_run_summary_viewport3D.global_transform.origin = currentPosition
	_run_summary_viewport3D.visible = true
	
func _finish_run() -> void:
	MusicManager.transition_to_track(
			MusicManager.Tracks.OFF_RANGE, 3
	)
	_audio_player_run_end.play()
	_is_player_on_range = false
	
	_badge_tracker.evaluate_end_of_run_stats(
			_target_manager.are_all_enemy_targets_down(),
			_target_manager.are_all_friendly_targets_up(),
			_bullet_manager.run_acc
	)
	
	var missed_enemy_penalty_time_total: float = (
		_missed_enemy_penalty * _target_manager.target_count_enemy_up()
	)
	var hit_friendly_penalty_time_total: float = (
		_hit_friendly_penalty * _target_manager.target_count_friendly_down()
	)
	
	_run_time = (
			_run_time_raw + _badge_tracker.get_run_badge_time() +
			missed_enemy_penalty_time_total + hit_friendly_penalty_time_total
	)
	 
	_update_level_best()
	
	yield(get_tree().create_timer(3), "timeout")
	_update_and_show_run_summary(
			missed_enemy_penalty_time_total, hit_friendly_penalty_time_total
	)
	

func _update_level_best() -> void:
	if _best_time == -1.0:
		_best_time = _run_time
		_level_ui.set_label_time_best(_best_time)
		_vr_level_ui.set_label_time_best(_best_time)
		SaveLoad.save_level_best_time(_level_name, _run_time)
		_run_summary_page.is_new_best = true
		_run_summary_page_vr.is_new_best = true
		
	elif _run_time < _best_time:
		_run_summary_page.is_new_best = true
		_run_summary_page_vr.is_new_best = true
		_best_time = _run_time
		_level_ui.set_label_time_best(_best_time)
		_vr_level_ui.set_label_time_best(_best_time)
		SaveLoad.save_level_best_time(_level_name, _run_time)
	else:
		_run_summary_page.is_new_best = false
		_run_summary_page_vr.is_new_best = false
