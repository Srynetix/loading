extends Control

onready var anim_player = $AnimationPlayer

func flash():
    anim_player.play("flash")
