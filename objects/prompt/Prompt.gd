extends Control

signal message_shown(msg)
signal message_hidden

var current_idx = 0
var target_message = ""
var play_sound = true
var writing_message = false
var message_queue = []

onready var letter_timer = $LetterTimer
onready var message_timer = $MessageTimer
onready var label = $Label
onready var sound = $AudioStreamPlayer
onready var anim_player = $AnimationPlayer

func _ready():
    letter_timer.connect("timeout", self, "_on_letter_timer_timeout")
    message_timer.connect("timeout", self, "_on_message_timer_timeout")

func _process(delta):
    if not self.writing_message and len(self.message_queue) > 0:
        self.writing_message = true
        self.target_message = self.message_queue.pop_front()
        self.current_idx = 0
        letter_timer.start()

func push_message(msg):
    self.message_queue.push_back(msg)

func show_message(msg):
    self.push_message(msg)

func show_priority_message(msg):
    self.message_queue = []
    self.writing_message = false
    self.push_message(msg)

func _update_text(text):
    label.set_text(text)

    if play_sound:
        sound.play()
        play_sound = false

    else:
        play_sound = true

func _on_letter_timer_timeout():
    if self.current_idx <= len(self.target_message):
        var message = self.target_message.substr(0, self.current_idx)
        self._update_text(message)

        self.current_idx += 1
        letter_timer.start()

    else:
        message_timer.start()

func _on_message_timer_timeout():
    # Text is written
    anim_player.play("fadeout")
    yield(anim_player, "animation_finished")
    anim_player.play("idle")
    label.set_text("")
    self.writing_message = false

    emit_signal("message_shown", self.target_message)
