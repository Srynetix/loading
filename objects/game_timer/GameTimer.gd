extends Control

signal half_time_elapsed
signal time_elapsed

const BASE_TIME = 60

var time_left = BASE_TIME

onready var timer = $Timer
onready var label = $Label
onready var anim_player = $AnimationPlayer

func _ready():
    timer.connect("timeout", self, "_on_timer_timeout")

func start():
    timer.start()

func reset():
    time_left = BASE_TIME
    timer.stop()

func show():
    anim_player.play("slidein")

func hide():
    anim_player.play("slideout")

func _update_timer():
    label.set_text(str(time_left))

func _on_timer_timeout():
    time_left -= 1
    if time_left > 0:
        timer.start()

    if time_left == BASE_TIME / 2:
        emit_signal("half_time_elapsed")

    if time_left == 0:
        emit_signal("time_elapsed")

    _update_timer()
