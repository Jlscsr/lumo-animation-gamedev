extends CharacterBody2D
# ─────────── CONFIG ───────────
const SPEED           : float = 300.0
const JUMP_VELOCITY   : float = -500.0
const GRAVITY         : float = 980.0     # px / s²

@onready var anim : AnimatedSprite2D = $AnimatedSprite2D
enum Palette { WHITE, RED }

var palette      : int  = Palette.WHITE
var facing_right : bool = true
var is_shifting  : bool = false
# ─────────── PHYSICS ───────────
func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += GRAVITY * delta

	if Input.is_action_just_pressed("ui_accept") and is_on_floor() and not is_shifting:
		velocity.y = JUMP_VELOCITY
		_play(_jump_anim())

	var dir := Input.get_axis("ui_left","ui_right")
	if dir != 0.0 and not is_shifting:
		velocity.x = dir * SPEED
		facing_right = dir > 0
	elif not is_shifting:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()
# ─────────── FRAME / INPUT ───────────
func _process(_d: float) -> void:
	if Input.is_action_just_pressed("color_shift") and not is_shifting:
		_shift_to_red()

	if is_shifting:
		return

	if is_on_floor():
		_play(_idle_anim() if abs(velocity.x) < 1.0 else _walk_anim())
	else:
		_play(_jump_anim())
# ─────────── ANIM HELPERS ───────────
func _idle_anim() -> String:
	return _name("idle_right") if facing_right else _name("idle_left")

func _walk_anim() -> String:
	return _name("right_walk") if facing_right else _name("left_walk")

func _jump_anim() -> String:
	return _name("jump_right") if facing_right else _name("jump_left")

func _name(base:String) -> String:
	# If palette is RED and a *_red clip exists, use it; otherwise fallback to base
	var red_name := base + "_red"
	return red_name if palette == Palette.RED and anim.sprite_frames.has_animation(red_name) else base

func _play(name:String) -> void:
	if name == "":                 # just in case
		return
	if anim.sprite_frames.has_animation(name):
		if anim.animation != name:
			anim.play(name)
	# else silently ignore – avoids spam in Output
# ─────────── COLOUR SHIFT ───────────
func _shift_to_red() -> void:
	if palette == Palette.RED:
		return                     # already red

	is_shifting = true
	anim.play("color_shift")       # one-shot (loop OFF)
	await anim.animation_finished
	palette = Palette.RED
	is_shifting = false
