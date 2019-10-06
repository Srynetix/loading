extends Control

signal message_shown(msg)

var current_idx = 0
var target_message = ""
var writing_message = false
var message_queue = []

onready var letter_timer = $LetterTimer
onready var message_timer = $MessageTimer
onready var label = $Label
onready var tween = $Tween

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

func _on_letter_timer_timeout():
    if self.current_idx <= len(self.target_message):
        var message = self.target_message.substr(0, self.current_idx)
        self._update_text(message)

        self.current_idx += 1
        letter_timer.start()

    else:
        message_timer.start()

func _on_message_timer_timeout():
    # Hide label
    tween.interpolate_property(label, "modulate", Color(1, 1, 1, 1), Color(1, 1, 1, 0), 1, Tween.TRANS_LINEAR, Tween.EASE_IN)
    tween.start()
    yield(tween, "tween_completed")

    # Reset label
    label.set_text("")
    label.set_deferred("modulate", Color(1, 1, 1, 1))
    self.writing_message = false

    emit_signal("message_shown", self.target_message)
