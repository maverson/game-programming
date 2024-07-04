extends CharacterBody2D


@export var movement_speed = 20.0
@export var hp = 10
@export var knockback_recovery = 3.5
@export var experience = 1
@export var enemy_damage = 1
var knockback = Vector2.ZERO

var initial_mov_speed

@onready var player = get_tree().get_first_node_in_group("player")
@onready var loot_base = get_tree().get_first_node_in_group("loot")
@onready var sprite = $Sprite2D
@onready var anim = $AnimationPlayer
@onready var snd_hit = $snd_hit
@onready var hitBox = $HitBox
@onready var freezeTimer = $globalFreezeTimer
@onready var confusion_timer = $globalConfusionTimer

var death_anim = preload("res://Enemy/explosion.tscn")
var exp_gem = preload("res://Objects/experience_gem.tscn")

var global_strength = 0

signal remove_from_array(object)

func take_damage(amount):
	hp -= amount

func _ready():
	anim.play("walk")
	hitBox.damage = enemy_damage
	initial_mov_speed = movement_speed

func _physics_process(_delta):
	knockback = knockback.move_toward(Vector2.ZERO, knockback_recovery)
	var direction = global_position.direction_to(player.global_position)
	velocity = direction*movement_speed
	velocity += knockback
	move_and_slide()
	
	if direction.x > 0.1:
		sprite.flip_h = true
	elif direction.x < -0.1:
		sprite.flip_h = false

func death():
	emit_signal("remove_from_array",self)
	var enemy_death = death_anim.instantiate()
	enemy_death.scale = sprite.scale
	enemy_death.global_position = global_position
	get_parent().call_deferred("add_child",enemy_death)
	var new_gem = exp_gem.instantiate()
	new_gem.global_position = global_position
	new_gem.experience = experience
	loot_base.call_deferred("add_child",new_gem)
	queue_free()

func _on_hurt_box_hurt(damage, angle, knockback_amount):
	hp -= damage
	knockback = angle * knockback_amount
	if hp <= 0:
		death()
	else:
		snd_hit.play()
		
		
func global_attack(type, strength):
	global_strength = strength
	if type == 0:
		movement_speed *= clampf(0.5 / global_strength, 0.0, 1.0);
		freezeTimer.start();
	if type == 1:
		movement_speed *= clampf(-global_strength, -100000.0, -1.0)
		confusion_timer.start();
	if type == 2:
		hp -= global_strength * 2
		if hp <= 0.0:
			death()
		

func _on_global_freeze_timer_timeout():
	movement_speed = movement_speed / (0.5 / global_strength);

func _on_global_confusion_timer_timeout():
	movement_speed = initial_mov_speed
