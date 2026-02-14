extends CharacterBody2D


signal player_died
signal weapon_reloading(progress: float)

@export var reload_time: float = 0.4
var current_reload_time: float = 0.0

# Leg animation variables
@export var pants_color: Color = Color("#373737") # Gray pants
var leg_animation_time: float = 0.0
# Increased speed and angle to match high movement speed (770)
var leg_swing_speed: float = 12.0 # Was 10.0 - faster swing for running
var max_leg_swing_angle: float = deg_to_rad(25) # Was 25 - wider stride for running


func _ready() -> void:
	add_to_group("Player")
	default_hand_scale = hands_sprite.scale
	current_reload_time = reload_time # Start with cooldown
	
	# Setup sound effects
	jump_sound = AudioStreamPlayer.new()
	jump_sound.stream = load("res://assets/Musik/Event/Motion/Jump/jump.wav")
	add_child(jump_sound)
	jump_sound.volume_db = -20
	
	shoot_sound = AudioStreamPlayer.new()
	shoot_sound.stream = load("res://assets/Musik/Event/Shooting/simple_shoot.wav")
	add_child(shoot_sound)
	shoot_sound.volume_db = -27
	
	# Setup footstep sound with procedural generator
	footstep_sound = AudioStreamPlayer.new()
	var generator = AudioStreamGenerator.new()
	generator.mix_rate = 22050
	generator.buffer_length = 0.13
	footstep_sound.stream = generator
	footstep_sound.volume_db = -10.0
	add_child(footstep_sound)
	footstep_sound.play()


const JUMP_VELOCITY = -1200.0

var bullet_scene = preload("res://Scripts/Environment/Objects/MovableObjects/Bullet/bullet.tscn")
var dust_scene = preload("res://Scripts/Effects/Dust/dust.tscn")

# Sound effects
var jump_sound: AudioStreamPlayer
var shoot_sound: AudioStreamPlayer
var footstep_sound: AudioStreamPlayer
var last_step_phase: float = 0.0

@onready var bullet_marker: Marker2D = $AnimatedSprite2D/Hands/BulletMarker
@onready var muzzle_flash: CPUParticles2D = %MuzzleFlash
@onready var hands_sprite: Sprite2D = $AnimatedSprite2D/Hands
@onready var left_schoulder_marker: Marker2D = $AnimatedSprite2D/LeftSchoulderMarker
@onready var left_hand_marker: Marker2D = $AnimatedSprite2D/Hands/LeftHandMarker

var move_speed := 770.0

const MIN_ANGLE = deg_to_rad(-65) # up
const MAX_ANGLE = deg_to_rad(30) # down

var current_shoot_direction: Vector2 = Vector2.RIGHT

var default_hand_scale: Vector2
var was_on_floor: bool = false


func _physics_process(delta: float) -> void:
	_update_hand_rotation(delta)

	if current_reload_time > 0:
		current_reload_time -= delta
		if current_reload_time <= 0:
			current_reload_time = 0
			weapon_reloading.emit(1.0)
		else:
			weapon_reloading.emit(1.0 - (current_reload_time / reload_time))

	# Horizontal movement
	var direction := Input.get_axis("ui_left", "ui_right")
	if direction != 0:
		velocity.x = direction * move_speed
	else:
		velocity.x = move_toward(velocity.x, 0, move_speed * delta * 5)

	# Update leg animation based on movement
	if abs(velocity.x) > 10 and is_on_floor():
		# Sync animation speed with movement velocity more directly
		var prev_leg_time = leg_animation_time
		leg_animation_time += delta * leg_swing_speed * (abs(velocity.x) / move_speed)
		
		# Play footstep sound on each step (when phase crosses PI)
		var current_step = floor(leg_animation_time / PI)
		var last_step = floor(prev_leg_time / PI)
		if current_step != last_step and footstep_sound:
			_play_footstep()
	else:
		# Reset legs to neutral position smoothly or instantly when stopped
		pass # Keep current phase for blending if needed, or reset? Let's just stop incrementing.
		
	# Jump Animation Blend
	if not is_on_floor():
		jump_blend = move_toward(jump_blend, 1.0, delta * 10)
	else:
		if abs(velocity.x) < 10:
			leg_animation_time = 0 # Reset walk cycle when stopped on floor
		jump_blend = move_toward(jump_blend, 0.0, delta * 10)

	velocity += get_gravity() * delta
	if is_on_floor_only():
		if Input.is_action_pressed("ui_accept"):
			velocity.y = JUMP_VELOCITY
			if jump_sound:
				jump_sound.play()

	move_and_slide()

	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		if collision.get_collider().is_in_group("Obstacle"):
			die()

	if not was_on_floor and is_on_floor():
		spawn_dust()

	was_on_floor = is_on_floor()


func _update_hand_rotation(delta: float) -> void:
	var mouse_pos = get_viewport().get_camera_2d().get_global_mouse_position()
	var dir = (mouse_pos - hands_sprite.global_position).normalized()

	var target_angle = dir.angle()
	target_angle = clamp(target_angle, MIN_ANGLE, MAX_ANGLE)

	hands_sprite.rotation = lerp_angle(hands_sprite.rotation, target_angle, delta * 12)
	hands_sprite.scale = hands_sprite.scale.lerp(default_hand_scale, delta * 3)

	current_shoot_direction = Vector2.from_angle(target_angle)

	queue_redraw()


# Shoot
func _input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		shoot()


func shoot():
	if bullet_scene == null or current_reload_time > 0:
		return

	current_reload_time = reload_time
	weapon_reloading.emit(0.0)

	var bullet = bullet_scene.instantiate()

	bullet.direction = current_shoot_direction.normalized()
	bullet.global_position = bullet_marker.global_position + (bullet.direction * 40)

	bullet.velocity_offset.x = self.velocity.x
	bullet.z_index = -1

	hands_sprite.rotation -= 0.2
	hands_sprite.scale.x = 0.87

	get_tree().current_scene.add_child(bullet)
	
	# Play shoot sound
	if shoot_sound:
		shoot_sound.play()

	# Add muzzle flash effect with a tiny delay
	await get_tree().create_timer(0.03).timeout
	if !Global.is_game_over:
		# Dynamically adjust velocity based on player speed to make it "hit hard" but keep it modest
		var speed_boost = abs(velocity.x) * 0.16
		muzzle_flash.initial_velocity_min = 200.0 + speed_boost
		muzzle_flash.initial_velocity_max = 400.0 + speed_boost
		muzzle_flash.restart()


var death_spread: float = 0.0:
	set(value):
		death_spread = value
		queue_redraw()

var jump_blend: float = 0.0
var is_dead: bool = false


func die():
	if is_dead:
		return
	is_dead = true
	
	player_died.emit()
	muzzle_flash.emitting = false
	muzzle_flash.visible = false
	set_physics_process(false) # Stop player movement
	set_process_input(false) # Stop shooting
	
	# Animate legs to spread out / \
	var tween = create_tween()
	tween.tween_property(self, "death_spread", 1.0, 0.1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	# Force redraw on each frame since physics process is stopped
	tween.tween_method(func(_v): queue_redraw(), 0.0, 1.0, 0.1)


func _draw() -> void:
	# Advanced Procedural Legs (Thigh + Calf + Foot)
	var body_bottom_y = -55
	var leg_separation = 43.0
	
	# Leg dimensions
	var thigh_length = 17.0 # Was 22.0 - shortened drastically per feedback
	var calf_length = 17.0 # Was 22.0
	var foot_length = 22.0
	var foot_height = 12.0
	var leg_thickness = 44.0 # Standard width from variables
	
	# Running Cycle Calculation
	# We use sin/cos to determine phase of each leg
	# Left leg phase
	var left_phase = leg_animation_time
	# Right leg phase (offset by PI for opposite movement)
	var right_phase = leg_animation_time + PI
	
	# Jump Pose Targets
	# Right Leg (Back): Slightly trailing
	var jump_right_thigh = deg_to_rad(20)
	var jump_right_knee = 0.3
	
	# Left Leg (Front): High knee tuck
	var jump_left_thigh = deg_to_rad(-60)
	var jump_left_knee = 1.2
	
	# Draw Right Leg (Back) first so it appears behind
	# Target angle: Negative (Left/Front) e.g. -14 degrees per user request
	_draw_segment_leg(Vector2(leg_separation / 2, body_bottom_y), right_phase, thigh_length, calf_length, leg_thickness, foot_length, foot_height, pants_color.darkened(0.1), deg_to_rad(-14), jump_right_thigh, jump_right_knee)
	
	# Draw Left Leg (Front)
	# Target angle: Positive (Right/Back) e.g. 14 degrees per user request
	_draw_segment_leg(Vector2(-leg_separation / 2, body_bottom_y), left_phase, thigh_length, calf_length, leg_thickness, foot_length, foot_height, pants_color, deg_to_rad(14), jump_left_thigh, jump_left_knee)

	
	# Draw arm (existing code)
	if left_schoulder_marker and left_hand_marker:
		var start = to_local(left_schoulder_marker.global_position)
		var end = to_local(left_hand_marker.global_position)
		var color = Color("#533838")
		var width = 20.0
		var radius = width / 2.0

		draw_line(start, end, color, width)
		draw_circle(start, radius, color)
		draw_circle(end, radius, color)


# Helper function to get point on quadratic bezier curve
func _get_bezier_point(t: float, p0: Vector2, p1: Vector2, p2: Vector2) -> Vector2:
	var u = 1.0 - t
	var tt = t * t
	var uu = u * u
	return (uu * p0) + (2 * u * t * p1) + (tt * p2)


# Helper function to draw rotated rectangle
# Rotates from the top center (hip pivot point)
func _draw_segment_leg(hip_pos: Vector2, phase: float, thigh_len: float, calf_len: float, width: float, _foot_len: float, _foot_h: float, color: Color, target_death_angle: float = 0.0, target_jump_thigh: float = 0.0, target_jump_knee: float = 0.0) -> void:
	var swing_angle = sin(phase) * max_leg_swing_angle
	
	# Knee Logic:
	# When leg moves forward (swing phase), bend knee significantly
	# When leg moves back (push phase), leg is mostly straight
	var knee_bend_angle = 0.0
	
	# Complex knee math for "cool" running look
	# cos(phase) < 0 means leg is swinging forward (reversing logic per request)
	if cos(phase) < 0:
		# Bringing leg forward -> Bend knee to lift foot
		# Reduced bend multiplier to 0.8 to avoid sharp L-shape (was 1.25)
		knee_bend_angle = 0.8 * abs(cos(phase))
	else:
		# Pushing back -> Slight bend or straight
		knee_bend_angle = 0.2
		
	# Apply animation
	# Interpolate to death pose if dying
	if death_spread > 0.0:
		swing_angle = lerp_angle(swing_angle, target_death_angle, death_spread)
		knee_bend_angle = lerp(knee_bend_angle, 0.1, death_spread * 1.5) # Straighten legs on death
		knee_bend_angle = max(0.0, knee_bend_angle) # Ensure non-negative
	elif jump_blend > 0.0:
		# Interpolate to jump pose if airborne
		swing_angle = lerp_angle(swing_angle, target_jump_thigh, jump_blend)
		knee_bend_angle = lerp(knee_bend_angle, target_jump_knee, jump_blend)
	
	var thigh_angle = swing_angle
	var calf_angle = thigh_angle + knee_bend_angle # Calf adds rotation relative to thigh
	
	# Calculate Key Positions
	var knee_pos = hip_pos + Vector2(0, thigh_len).rotated(thigh_angle)
	var ankle_pos = knee_pos + Vector2(0, calf_len).rotated(calf_angle)
	
	# Calculate Control Point for Bezier Curve
	# We want the curve to pass through the knee at t=0.5
	# Formula: Control = 2 * Knee - 0.5 * (Hip + Ankle)
	var control_point = 2 * knee_pos - 0.5 * (hip_pos + ankle_pos)
	
	# Create stylebox for rounded joints
	var joint_style = StyleBoxFlat.new()
	joint_style.bg_color = color
	joint_style.set_corner_radius_all(8) # Fixed radius for rounded rect look
	joint_style.set_corner_detail(4)
	
	# Draw Intermediate Rectangles along the curve
	var num_segments = 8
	var prev_pos = hip_pos
	
	# Draw hip joint using stylebox (centered)
	draw_style_box(joint_style, Rect2(prev_pos - Vector2(width / 2, width / 2), Vector2(width, width)))
	
	for i in range(1, num_segments + 1):
		var t = float(i) / float(num_segments)
		var next_pos = _get_bezier_point(t, hip_pos, control_point, ankle_pos)
		
		# Calculate segment properties
		var segment_vector = next_pos - prev_pos
		var seg_length = segment_vector.length()
		var seg_angle = segment_vector.angle()
		var center = (prev_pos + next_pos) / 2.0
		
		# Draw rotated rectangle (segment)
		# Adding slight overlap (+2) and width to merge with joint
		draw_set_transform(center, seg_angle, Vector2.ONE)
		draw_rect(Rect2(-seg_length / 2.0 - 1.0, -width / 2.0, seg_length + 2.0, width), color)
		
		# Reset transform for joint drawing
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		
		# Draw joint rounded rect to fill gaps at "elbows"
		draw_style_box(joint_style, Rect2(next_pos - Vector2(width / 2, width / 2), Vector2(width, width)))
		
		prev_pos = next_pos
		
	# Reset transform
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _play_footstep():
	# Generate a short low-frequency pulse for footstep
	if footstep_sound and footstep_sound.stream is AudioStreamGenerator:
		var playback = footstep_sound.get_stream_playback() as AudioStreamGeneratorPlayback
		if playback:
			var frequency = 80.0 # Low frequency for footstep
			var duration = 0.05 # Very short pulse
			var sample_rate = 22050.0
			var samples = int(duration * sample_rate)
			
			for i in range(samples):
				var t = float(i) / sample_rate
				var envelope = 1.0 - (float(i) / float(samples)) # Fade out
				var value = sin(t * frequency * TAU) * envelope * 0.3 # Low amplitude
				playback.push_frame(Vector2(value, value))


func spawn_dust():
	if dust_scene:
		var dust = dust_scene.instantiate()
		dust.global_position = global_position + Vector2(0, 100)
		dust.global_position = global_position
		get_parent().add_child(dust)
