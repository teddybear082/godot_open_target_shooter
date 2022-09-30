extends Spatial

signal cooldown_finished

var countdown = 5

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	countdown = countdown - 1
	if countdown == 0:
		visible = false
		$Particles.emitting = false
		$Particles2.emitting = false
		set_process(false)
		emit_signal("cooldown_finished")
