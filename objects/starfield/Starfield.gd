extends Control
tool

onready var particles = $Particles2D

###################
# Lifecycle methods

func _ready():
    var game_size = get_viewport().get_size()
    particles.position.x = game_size.x / 2.0
    particles.position.y = game_size.y / 2.0
    particles.process_material.emission_box_extents.x = game_size.x / 2.0
    particles.process_material.emission_box_extents.y = game_size.y / 2.0
    particles.process_material.radial_accel = 0

################
# Public methods

func start():
    particles.emitting = true

func set_radial_accel(accel):
    particles.process_material.radial_accel = accel

func set_hue(hue):
    particles.process_material.hue_variation = hue

func stop():
    particles.emitting = false
