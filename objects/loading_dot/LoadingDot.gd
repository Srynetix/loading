extends Area2D

signal prepared
signal hit_good_fragment
signal hit_bad_fragment
signal exploded
signal revived

const MOVEMENT_SPEED = 450
const DAMPING = 0.95
const MAX_FRAGMENT_COUNT = 150

var is_spinning = false
var is_controlled = false
var velocity = Vector2(0, 0)
var angular_velocity = 1
var is_touching = false
var last_touch_position = Vector2()
var touch_distance = 0

onready var sprite = $Sprite
onready var anim_player = $AnimationPlayer
onready var particles = $Particles2D
onready var tween = $Tween
onready var fragments = $Fragments
onready var collision_shape = $CollisionShape2D
onready var explode_sound = $ExplodeSound
onready var explosion_particles = $ExplosionParticles

###################
# Lifecycle methods

func _ready():
    # Connect signals
    connect("area_entered", self, "_on_area_entered")

    var game_size = get_viewport().get_size()
    var start_pos = Vector2(game_size.x - 4, 4)
    self.position = start_pos
    particles.emitting = false

func _process(delta):
    var game_size = get_viewport().get_size()

    if is_spinning:
        sprite.rotation += 0.1 * angular_velocity
        fragments.rotation += 0.1 * angular_velocity

    if is_controlled:
        self._handle_movement(delta)

    position += velocity * delta
    velocity *= Vector2(DAMPING, DAMPING)

    # Clamp position
    position.x = clamp(position.x, 0, game_size.x)
    position.y = clamp(position.y, 0, game_size.y)

func _input(event):
    if event is InputEventScreenTouch:
        self.last_touch_position = event.position
        self.is_touching = event.pressed
        self.touch_distance = self.position - event.position

        # Screen released
        if not event.pressed:
            self.velocity = Vector2()

    elif event is InputEventScreenDrag:
        self.last_touch_position = event.position

################
# Public methods

func set_controlled(value):
    self.is_controlled = value

func prepare():
    var game_size = get_viewport().get_size()
    var start_pos = Vector2(game_size.x - 4, 4)

    anim_player.play("idle")

    tween.interpolate_property(self, "position", start_pos, Vector2(4, 4), 0.5, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
    tween.interpolate_property(sprite, "scale", Vector2(0.5, 0.5), Vector2(64.0, 0.5), 0.25, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
    tween.interpolate_property(sprite, "scale", Vector2(64.0, 0.5), Vector2(0.5, 0.5), 0.25, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT, 0.5)
    tween.interpolate_property(self, "position", Vector2(4, 4), Vector2(4, game_size.y / 2.0 - 4), 0.5, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT, 1)
    tween.interpolate_property(self, "position", Vector2(4, game_size.y / 2.0 - 4), Vector2(24, game_size.y / 2.0 - 4), 0.5, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT, 1.5)
    tween.start()

    yield(tween, "tween_completed")
    yield(tween, "tween_completed")
    yield(tween, "tween_completed")
    yield(tween, "tween_completed")
    yield(tween, "tween_completed")

    self.start_spin()

    emit_signal("prepared")

func start_spin():
    is_spinning = true
    particles.emitting = true

func reset_spin():
    is_spinning = false
    particles.emitting = false

    tween.interpolate_property(sprite, "rotation", null, 0, 0.5, Tween.TRANS_LINEAR, Tween.EASE_IN)
    tween.interpolate_property(fragments, "rotation", null, 0, 0.5, Tween.TRANS_LINEAR, Tween.EASE_IN)
    tween.start()
    yield(tween, "tween_completed")
    yield(tween, "tween_completed")

func prepare_for_wall():
    self.is_controlled = false
    var game_size = get_viewport().get_size()

    tween.interpolate_property(self, "position", null, Vector2(128, game_size.y / 2.0 - 4), 0.5, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
    tween.start()
    yield(tween, "tween_completed")

    emit_signal("prepared")

func prepare_for_endgame():
    self.reset_spin()
    self.is_controlled = false
    var game_size = get_viewport().get_size()

    # Remove fragments
    self._remove_all_fragments()
    yield(get_tree().create_timer(1), "timeout")

    # Move dot
    tween.interpolate_property(self, "position", null, Vector2(game_size.x / 2, game_size.y / 2.0), 1, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
    tween.start()
    yield(tween, "tween_completed")

    tween.interpolate_property(self, "position", null, Vector2(game_size.x - 4, game_size.y / 2 - 4), 1, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
    tween.interpolate_property(self, "position", Vector2(game_size.x - 4, game_size.y / 2 - 4), Vector2(game_size.x - 4, 4), 1, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT, 1)
    tween.start()

    yield(tween, "tween_completed")
    yield(tween, "tween_completed")

    yield(get_tree().create_timer(1), "timeout")
    anim_player.play("blink")

    emit_signal("prepared")

func get_fragment_count():
    return fragments.get_child_count()

func revive():
    tween.interpolate_property(self, "modulate", Color(1, 1, 1, 0), Color(1, 1, 1, 1), 0.5, Tween.TRANS_LINEAR, Tween.EASE_IN)
    tween.start()

    yield(tween, "tween_completed")
    emit_signal("revived")

#################
# Private methods

func _handle_movement(delta):
    if Input.is_action_pressed("ui_up"):
        velocity.y = -MOVEMENT_SPEED
    if Input.is_action_pressed("ui_down"):
        velocity.y = MOVEMENT_SPEED
    if Input.is_action_pressed("ui_left"):
        velocity.x = -MOVEMENT_SPEED
    if Input.is_action_pressed("ui_right"):
        velocity.x = MOVEMENT_SPEED

    if self.is_touching:
        self.velocity = Vector2()
        self.position = self.last_touch_position + self.touch_distance

func _add_fragment(fragment):
    # Remove from parent and add in fragments
    fragment.get_parent().remove_child(fragment)
    fragments.add_child(fragment)

    # Calculate new fragment position
    var offset = fragment.position - position
    fragment.position = offset + Vector2(5, 5)

    self._update_dot_stats()

func _explode():
    emit_signal("exploded")

    explode_sound.play()
    explosion_particles.emitting = true

    tween.interpolate_property(self, "modulate", Color(1, 1, 1, 1), Color(1, 1, 1, 0), 0.5, Tween.TRANS_LINEAR, Tween.EASE_IN)
    tween.start()

    yield(tween, "tween_completed")

func _remove_last_fragment():
    var fragment_count = fragments.get_child_count()
    if fragment_count == 0:
        return

    var last_fragment = fragments.get_child(fragment_count - 1)
    fragments.remove_child(last_fragment)
    last_fragment.queue_free()

    self._update_dot_stats()

func _remove_all_fragments():
    while fragments.get_child_count() > 0:
        self._remove_last_fragment()

func _update_dot_stats():
    # Calculate new size
    var fragment_count = min(fragments.get_child_count(), MAX_FRAGMENT_COUNT)
    var grow_coeff = 0.25 * fragment_count
    var new_scale = Vector2(0.5, 0.5) + Vector2(grow_coeff, grow_coeff)

    # Scale particles
    particles.scale = Vector2(1, 1) + Vector2(grow_coeff, grow_coeff) * 2

    # Enlarge collision shape
    var shape_grow_coeff = 2 * fragment_count
    collision_shape.shape.extents = Vector2(5, 5) + Vector2(shape_grow_coeff, shape_grow_coeff)

    # Angular velocity
    angular_velocity = min(1 + fragment_count * 0.05, 4)

    # Scale sprite
    var current_scale = sprite.scale
    tween.interpolate_property(sprite, "scale", current_scale, new_scale, 0.5, Tween.TRANS_SINE, Tween.EASE_OUT)
    tween.start()
    yield(tween, "tween_completed")

#################
# Event callbacks

func _on_area_entered(other):
    if other.is_in_group("Fragments"):
        if not self.is_controlled:
            return

        if other.is_collected:
            return

        # Collect fragment
        other.collect()

        if other.is_good:
            emit_signal("hit_good_fragment")
            call_deferred("_add_fragment", other)
        else:
            emit_signal("hit_bad_fragment")
            call_deferred("_remove_last_fragment")

    elif other.is_in_group("Walls"):
        if other.wall_size > self.get_fragment_count():
            # Destroy player
            self._explode()
        else:
            # Destroy wall
            other.explode()
