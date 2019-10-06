extends Area2D

signal exploded

const MOVEMENT_SPEED = 800

onready var sprite = $Sprite
onready var shape = $CollisionShape2D
onready var particles = $Particles2D
onready var explosion_sound = $ExplosionSound
onready var explosion_particles = $ExplosionParticles
onready var tween = $Tween

var is_moving = false
var wall_size = 0

func _process(delta):
    if is_moving:
        position.x -= MOVEMENT_SPEED * delta

func prepare_wall(size):
    var game_size = get_viewport().get_size()

    sprite.scale.x = size / 2
    sprite.scale.y = game_size.y / 16
    shape.shape.extents.x = size * 4
    shape.shape.extents.y = game_size.y / 2

    position.x = game_size.x + sprite.texture.get_size().x * sprite.scale.x * 2
    position.y = game_size.y / 2

    particles.process_material.emission_box_extents.y = game_size.y / 2

    self.wall_size = size
    self.is_moving = false
    self.modulate = Color(1, 1, 1, 1)

func start():
    self.is_moving = true

func reset():
    self.is_moving = false
    self.prepare_wall(self.wall_size)

func explode():
    emit_signal("exploded")

    explosion_sound.play()
    explosion_particles.emitting = true

    tween.interpolate_property(self, "modulate", Color(1, 1, 1, 1), Color(1, 1, 1, 0), 0.25, Tween.TRANS_LINEAR, Tween.EASE_IN)
    tween.start()
    yield(tween, "tween_completed")

    explosion_particles.emitting = false
