extends Node2D

const LOW_VOLUME = -40
const HIGH_VOLUME = 0

onready var tween = $Tween
onready var stream = $AudioStreamPlayer

################
# Public methods

func start():
    # Play
    stream.volume_db = LOW_VOLUME
    stream.play()

    # Interpolate volume
    tween.interpolate_property(stream, "volume_db", LOW_VOLUME, HIGH_VOLUME, 2, Tween.TRANS_LINEAR, Tween.EASE_IN)
    tween.start()
    yield(tween, "tween_completed")

func stop():
    # Interpolate volume
    tween.interpolate_property(stream, "volume_db", HIGH_VOLUME, LOW_VOLUME, 2, Tween.TRANS_LINEAR, Tween.EASE_IN)
    tween.start()
    yield(tween, "tween_completed")
    stream.stop()
