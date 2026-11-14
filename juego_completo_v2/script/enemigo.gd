extends CharacterBody2D

@export var volador = false
@export var vida = 3

var estado = "patrulla"
var t = 0.0
var dir = -1
var casa: Vector2
var objetivo: Vector2
var golpeo = false
var jugador
var sprite: Sprite2D
var golpe: Area2D

func _ready():
	collision_layer = 4
	collision_mask = 1
	casa = global_position
	if volador:
		motion_mode = MOTION_MODE_FLOATING
	sprite = get_node_or_null("Sprite2D")
	if sprite == null:
		sprite = Juego.sprite_de(Juego.POLILLA if volador else Juego.ESCARABAJO)
		add_child(sprite)
	if get_node_or_null("CollisionShape2D") == null:
		add_child(Juego.forma(Vector2(22, 16)))
	golpe = Area2D.new()
	golpe.collision_layer = 0
	golpe.collision_mask = 2
	golpe.add_child(Juego.forma(Vector2(28, 22)))
	add_child(golpe)

func cambiar(nuevo):
	estado = nuevo
	t = 0.0
	sprite.modulate = Color(0.5, 0.5, 1) if nuevo == "aturdido" else Color.WHITE
	cuadro(Juego.POLILLA if volador else Juego.ESCARABAJO)

func cuadro(n):
	if sprite.hframes > n:
		sprite.frame = n

func _physics_process(delta):
	jugador = get_tree().get_first_node_in_group("jugador")
	if estado == "muerto" or jugador == null:
		return
	t += delta
	if not volador and not is_on_floor():
		velocity += get_gravity() * delta
	var cerca = jugador.estado != "muerta" and global_position.distance_to(jugador.global_position) < 140
	match estado:
		"patrulla":
			velocity.x = dir * 45
			if volador:
				velocity.y = cos(t * 3) * 30
				cuadro(Juego.POLILLA + int(t * 7) % 2)
			if abs(global_position.x - casa.x) > 64:
				dir = 1 if global_position.x < casa.x else -1
			elif is_on_wall():
				dir = -dir
			if cerca:
				cambiar("aviso")
		"aviso":
			velocity.x = 0
			if volador:
				velocity.y = 0
			else:
				cuadro(Juego.AVISO)
			dir = 1 if jugador.global_position.x > global_position.x else -1
			sprite.modulate = Color(3, 3, 3) if int(t * 12) % 2 == 0 else Color.WHITE
			if t > 0.5:
				objetivo = jugador.global_position
				golpeo = false
				cambiar("ataque")
		"ataque":
			if volador:
				velocity = global_position.direction_to(objetivo) * 220
			else:
				velocity.x = dir * 260
			for cuerpo in golpe.get_overlapping_bodies():
				if not golpeo and cuerpo.has_method("recibir_golpe"):
					golpeo = true
					cuerpo.recibir_golpe(1, self)
			if t > 0.5 or is_on_wall() or (volador and global_position.distance_to(objetivo) < 8):
				cambiar("descanso")
		"descanso", "aturdido":
			velocity.x = move_toward(velocity.x, 0, 800 * delta)
			if volador:
				velocity = global_position.direction_to(casa) * 60
			if t > 1.0:
				cambiar("patrulla")
	sprite.flip_h = dir < 0
	move_and_slide()

func herir(n, desde):
	if estado == "muerto":
		return
	vida -= n
	velocity.x = 120 * sign(global_position.x - desde.global_position.x)
	sprite.modulate = Color(3, 3, 3)
	create_tween().tween_property(sprite, "modulate", Color.WHITE, 0.15)
	if vida <= 0:
		estado = "muerto"
		collision_layer = 0
		Juego.sumar_xp(3)
		Juego.sumar_energia(10)
		Juego.agregar("cristal")
		var tw = create_tween()
		tw.tween_property(sprite, "modulate:a", 0.0, 0.4)
		tw.tween_callback(queue_free)

func aturdir():
	if estado != "muerto":
		cambiar("aturdido")
