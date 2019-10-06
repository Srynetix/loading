extends Control

var DotFragment = preload("res://objects/dot_fragment/DotFragment.tscn")

onready var dot = $LoadingDot
onready var prompt = $Prompt
onready var timer = $Timer
onready var game_timer = $GameTimer
onready var wall = $Wall
onready var flash = $Flash
onready var starfield = $Starfield
onready var music = $MusicLoop
onready var background_message = $BackgroundMessage

var LEVELS = {
    1: {
        "name": "Tutorial",
        "frag_freq": 1,
        "frag_min_speed": 400,
        "frag_max_speed": 500,
        "frag_chance": 50,
        "wall_size": 10,
        "starfield_accel": 0,
        "starfield_hue": 0,
    },
    2: {
        "name": "Level 2",
        "frag_freq": 0.8,
        "frag_min_speed": 500,
        "frag_max_speed": 600,
        "frag_chance": 50,
        "wall_size": 30,
        "starfield_accel": -10,
        "starfield_hue": -0.9
    },
    3: {
        "name": "Level 3",
        "frag_freq": 0.5,
        "frag_min_speed": 600,
        "frag_max_speed": 800,
        "frag_chance": 40,
        "wall_size": 50,
        "starfield_accel": -30,
        "starfield_hue": -0.5
    },
    4: {
        "name": "LAST LEVEL",
        "frag_freq": 0.2,
        "frag_min_speed": 300,
        "frag_max_speed": 1200,
        "frag_chance": 60,
        "wall_size": 100,
        "starfield_accel": -250,
        "starfield_hue": -0.15
    }
}

var bad_fragment_hit = false
var good_fragment_hit = false
var first_time_timer = true
var timer_freq = 1
var fragment_min_speed = 400
var fragment_max_speed = 500
var good_chance = 50
var current_wall_size = 10
var current_level = 1

###################
# Lifecycle methods

func _ready():
    randomize()

    timer.connect("timeout", self, "_on_timer_timeout")
    dot.connect("hit_good_fragment", self, "_on_good_fragment_hit")
    dot.connect("hit_bad_fragment", self, "_on_bad_fragment_hit")
    dot.connect("exploded", self, "_on_dot_exploded")
    game_timer.connect("half_time_elapsed", self, "_on_half_time_elapsed")
    game_timer.connect("time_elapsed", self, "_on_time_elapsed")
    wall.connect("exploded", self, "_on_wall_exploded")

    wall.prepare_wall(self.current_wall_size)

    self._start_at_level(self.current_level)

#################
# Private methods

func _start_at_level(lvl):
    if lvl == 1:
        self._start_tutorial()
    elif lvl < 4:
        dot.prepare()
        yield(dot, "prepared")
        self._start_new_level(lvl)
    elif lvl == 4:
        dot.prepare()
        yield(dot, "prepared")
        self._start_hardmode()
    else:
        dot.prepare()
        yield(dot, "prepared")
        self._start_end_game()

func _start_tutorial():
    # Wait a little
    yield(get_tree().create_timer(3), "timeout")

    # Introduction prompt
    prompt.show_message("LOADING...")
    yield(prompt, "message_shown")
    prompt.show_message("LOADING...")
    yield(prompt, "message_shown")
    prompt.show_message("LOA... Hello, you.")
    yield(prompt, "message_shown")
    prompt.show_message("Wanna play a little?")
    yield(prompt, "message_shown")
    prompt.show_message("Let's move.")
    yield(prompt, "message_shown")

    # Show background message
    background_message.show_message("Tutorial")
    # Start music
    music.start()

    # Prepare loading dot
    flash.flash()
    dot.prepare()
    yield(dot, "prepared")
    # Prepare wall
    wall.prepare_wall(current_wall_size)
    # Start game timer
    game_timer.start()
    # Start the fragment spawning
    self._update_timer(1)
    self._spawn_fragment()
    timer.start()

    # Wait for 1 sec
    yield(get_tree().create_timer(1), "timeout")

    # Message
    prompt.show_message("Okay, flying dots.")
    yield(prompt, "message_shown")
    prompt.show_message("Catch them.")
    yield(prompt, "message_shown")
    prompt.show_message("Using the ARROW KEYS or MOUSE WITH BUTTON PRESSED.")
    dot.set_controlled(true)
    yield(prompt, "message_shown")

func _update_timer(value):
    self.timer_freq = value
    timer.wait_time = timer_freq

func _revive_dot():
    dot.revive()
    yield(dot, "revived")

    prompt.show_message("Here you go.")
    yield(prompt, "message_shown")

    # Restart
    self._start_new_level(self.current_level)

func _spawn_fragment():
    var game_size = get_viewport().get_size()
    var is_good = rand_range(1, 100) > (100 - good_chance)
    var spwn = DotFragment.instance()
    spwn.prepare(is_good, rand_range(self.fragment_min_speed, self.fragment_max_speed))
    spwn.position = Vector2(game_size.x + 4, rand_range(4, game_size.y - 4))
    add_child(spwn)

func _start_new_level(lvl):
    self.current_level = lvl

    var level_data = LEVELS[lvl]
    background_message.show_message(level_data["name"])
    self._update_timer(level_data["frag_freq"])
    self.fragment_min_speed = level_data["frag_min_speed"]
    self.fragment_max_speed = level_data["frag_max_speed"]
    self.good_chance = level_data["frag_chance"]
    self.current_wall_size = level_data["wall_size"]
    starfield.set_radial_accel(level_data["starfield_accel"])
    starfield.set_hue(level_data["starfield_hue"])

    if lvl > 1:
        starfield.start()

    music.start()
    wall.reset()
    wall.prepare_wall(self.current_wall_size)
    game_timer.start()
    _spawn_fragment()
    timer.start()
    dot.start_spin()
    dot.set_controlled(true)

func _start_hardmode():
    background_message.show_message("Too easy heh ?")
    yield(background_message, "message_shown")
    prompt.show_message("Uh...")
    yield(prompt, "message_shown")
    prompt.show_message("Okay?")

    self._start_new_level(4)

func _start_end_game():
    starfield.set_radial_accel(0)
    starfield.set_hue(0)
    starfield.start()

    dot.prepare_for_endgame()
    yield(dot, "prepared")

    background_message.show_message("Okay...")
    yield(background_message, "message_shown")
    background_message.show_message("You won the game.")
    yield(background_message, "message_shown")
    background_message.show_message("You can go out now.")
    yield(background_message, "message_shown")

    starfield.stop()
    prompt.show_message("Well, it's over.")
    yield(prompt, "message_shown")
    prompt.show_message("Time for another player.")
    yield(prompt, "message_shown")

    yield(get_tree().create_timer(3), "timeout")
    get_tree().reload_current_scene()

func _player_lose():
    flash.flash()
    starfield.set_radial_accel(0)
    dot.reset_spin()

    game_timer.reset()
    game_timer.hide()

    prompt.show_message("You died.")
    yield(prompt, "message_shown")
    prompt.show_message("You are too small.")
    yield(prompt, "message_shown")
    prompt.show_message("I will give you another chance.")
    yield(prompt, "message_shown")

    self._revive_dot()

func _player_win():
    flash.flash()
    starfield.set_radial_accel(0)
    starfield.start()
    dot.reset_spin()

    game_timer.reset()
    game_timer.hide()

    prompt.show_message("Wow. You made it.")
    yield(prompt, "message_shown")

    if self.current_level < 3:
        prompt.show_message("What's next?")
        yield(prompt, "message_shown")
        self._start_new_level(self.current_level + 1)

    elif self.current_level == 3:
        self._start_hardmode()

    elif self.current_level == 4:
        self._start_end_game()


#################
# Event callbacks

func _on_timer_timeout():
    _spawn_fragment()
    timer.start()

func _on_good_fragment_hit():
    if good_fragment_hit or self.current_level > 1:
        return

    good_fragment_hit = true

    prompt.show_message("Get the white dots.")
    yield(prompt, "message_shown")

func _on_bad_fragment_hit():
    if bad_fragment_hit or self.current_level > 1:
        return

    bad_fragment_hit = true

    prompt.show_message("You should dodge these red dots.")
    yield(prompt, "message_shown")

func _on_half_time_elapsed():
    game_timer.show()

    if self.first_time_timer and self.current_level == 1:
        first_time_timer = false
        prompt.show_message("Uh... A wild timer appeared.")
        yield(prompt, "message_shown")
        prompt.show_message("Hurry up.")
        yield(prompt, "message_shown")
    else:
        prompt.show_message("Hurry up.")
        yield(prompt, "message_shown")

func _on_time_elapsed():
    timer.stop()
    music.stop()

    prompt.show_priority_message("Time is up.")
    yield(prompt, "message_shown")
    dot.prepare_for_wall()
    prompt.show_priority_message("WATCH OUT!")
    wall.start()

func _on_dot_exploded():
    self._player_lose()

func _on_wall_exploded():
    self._player_win()
