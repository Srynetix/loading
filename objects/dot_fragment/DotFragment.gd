extends Area2D

const DEFAULT_MOVEMENT_SPEED = 500

var is_moving = true
var is_collected = false
var is_good = true
var speed = DEFAULT_MOVEMENT_SPEED

onready var sound_good = $PickupGood
onready var sound_bad = $PickupBad
onready var particles = $Particles2D
onready var tween = $Tween
onready var visibility_notifier = $VisibilityNotifier2D
onready var shape = $CollisionShape2D

###################
# Lifecycle methods

func _ready():
    visibility_notifier.connect("screen_exited", self, "_on_screen_exited")

    if not self.is_good:
        particles.process_material.color_ramp.gradient.colors[0] = Color("#aa0000")

func _process(delta):
    if self.is_moving:
        position.x -= delta * self.speed

################
# Public methods

func prepare(is_good, speed):
    self.is_good = is_good
    self.speed = speed

func collect():
    self.is_moving = false
    self.is_collected = true
    particles.emitting = false
    shape.set_deferred("disabled", true)

    if self.is_good:
        sound_good.play()
    else:
        sound_bad.play()
        tween.interpolate_property(self, "modulate", Color(1, 1, 1, 1), Color(1, 1, 1, 0), 0.5, Tween.TRANS_LINEAR, Tween.EASE_IN)
        tween.start()
        yield(tween, "tween_completed")

        queue_free()

#################
# Event callbacks

func _on_screen_exited():
    if not self.is_collected:
        queue_free()
