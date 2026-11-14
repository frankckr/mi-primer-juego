extends CharacterBody2D

const VELOCIDAD = 220.0
const SALTO = -420.0

var estado = "normal"
var t = 0.0
var mirando = 1
var coyote = 0.0
var buffer = 0.0
var inmune = 0.0
var cd_rodar = 0.0
var cd_impulso = 0.0
var ultima_j = -1000
var golpeados = []
var nodos = []
var ruta = []
var espada: Area2D
var linea: Line2D
var mira: Sprite2D
@onready var anim = get_node_or_null("AnimatedSprite2D")
@onready var camara = get_node_or_null("Camera2D")

func _ready():
	add_to_group("jugador")
	collision_layer = 2
	collision_mask = 1
	espada = Area2D.new()
	espada.collision_layer = 0
	espada.collision_mask = 4
	espada.add_child(Juego.forma(Vector2(28, 18)))
	var hoja = Polygon2D.new()
	hoja.polygon = PackedVector2Array([Vector2(-12, -2), Vector2(16, 0), Vector2(-12, 2)])
	hoja.color = Color(0.4, 0.95, 1)
	espada.add_child(hoja)
	espada.hide()
	add_child(espada)
	linea = Line2D.new()
	linea.top_level = true
	linea.width = 1
	linea.default_color = Color(1, 0.85, 0.3)
	add_child(linea)
	mira = Juego.sprite_de(Juego.NODO)
	mira.top_level = true
	mira.hide()
	add_child(mira)
	if Juego.reaparicion == Vector2.ZERO:
		Juego.reaparicion = global_position
	global_position = Juego.reaparicion
	if Juego.despertar:
		Juego.despertar = false
		cambiar("dormida")

func cambiar(nuevo):
	estado = nuevo
	t = 0.0

func _physics_process(delta):
	t += delta
	inmune -= delta
	cd_rodar -= delta
	cd_impulso -= delta
	coyote -= delta
	buffer -= delta
	if Input.is_action_just_pressed("atacar"):
		ultima_j = Time.get_ticks_msec()
	if estado != "impulso" and not is_on_floor():
		velocity += get_gravity() * delta
	match estado:
		"normal":
			normal(delta)
		"rodar":
			velocity.x = mirando * 320
			if t > 0.35:
				cambiar("normal")
		"atacar":
			velocity.x = move_toward(velocity.x, 0, 2000 * delta)
			if t < 0.15:
				golpear()
			elif t > 0.3:
				espada.hide()
				cambiar("normal")
		"curar":
			velocity.x = 0
			if t > 0.8:
				if Juego.gastar_energia(35):
					Juego.curar(2)
				cambiar("normal")
		"herida":
			if t > 0.25:
				cambiar("normal")
		"muerta":
			velocity.x = 0
			if t > 1.2:
				reaparecer()
		"dormida":
			velocity.x = 0
			if t > 2.0:
				cambiar("normal")
	if estado == "impulso":
		impulso(delta)
	else:
		move_and_slide()
	nodos_y_mira()
	animar()

func normal(delta):
	var dir = Input.get_axis("izquierda", "derecha")
	velocity.x = move_toward(velocity.x, dir * VELOCIDAD, 1800 * delta)
	if dir != 0:
		mirando = sign(dir)
	if is_on_floor():
		coyote = 0.1
	if Input.is_action_just_pressed("saltar"):
		if Input.is_action_pressed("arriba") and not nodos.is_empty():
			empezar_impulso()
			return
		buffer = 0.1
	if buffer > 0 and coyote > 0:
		velocity.y = SALTO
		buffer = 0
		coyote = 0
	if Input.is_action_just_released("saltar") and velocity.y < 0:
		velocity.y *= 0.5
	if Input.is_action_just_pressed("rodar") and is_on_floor() and cd_rodar <= 0:
		cambiar("rodar")
		inmune = 0.2
		cd_rodar = 0.75
	elif Input.is_action_just_pressed("atacar"):
		cambiar("atacar")
		golpeados.clear()
		espada.position.x = 18 * mirando
		espada.scale.x = mirando
		espada.show()
	elif Input.is_action_just_pressed("curar") and Juego.vida < Juego.vida_max:
		if Juego.energia >= 35:
			cambiar("curar")
		else:
			Juego.mensaje.emit("Falta energía")
	elif Input.is_action_just_pressed("carga"):
		Juego.usar_carga()
	elif Input.is_action_just_pressed("pocion"):
		Juego.usar_pocion()

func golpear():
	for cuerpo in espada.get_overlapping_bodies():
		if cuerpo.has_method("herir") and cuerpo not in golpeados:
			golpeados.append(cuerpo)
			cuerpo.herir(1, self)
			Juego.sumar_energia(5)
			Juego.congelar(0.05)

func recibir_golpe(dano, quien):
	if estado == "muerta" or estado == "impulso" or inmune > 0:
		return
	if Time.get_ticks_msec() - ultima_j < 180:
		Juego.sumar_energia(15)
		Juego.mensaje.emit("¡Parry!")
		Juego.congelar(0.08)
		if quien.has_method("aturdir"):
			quien.aturdir()
		if Juego.amuleto and Juego.tiene_nodos:
			poner_nodo(quien.global_position)
		return
	espada.hide()
	inmune = 0.8
	velocity = Vector2(160 * sign(global_position.x - quien.global_position.x), -160)
	cambiar("herida")
	sacudir(3)
	if Juego.danar(dano):
		cambiar("muerta")

func reaparecer():
	global_position = Juego.reaparicion
	velocity = Vector2.ZERO
	inmune = 1.0
	Juego.llenar()
	cambiar("normal")

func nodos_y_mira():
	linea.clear_points()
	if not Juego.tiene_nodos or estado == "muerta":
		mira.hide()
		return
	var raton = get_global_mouse_position()
	if Input.is_action_pressed("nodo"):
		mira.show()
		mira.global_position = raton
		mira.modulate = Color.GREEN if valido(raton) else Color.RED
	elif mira.visible:
		mira.hide()
		if valido(raton):
			poner_nodo(raton)
	if not nodos.is_empty():
		linea.add_point(global_position)
		for n in nodos:
			linea.add_point(n.global_position)

func valido(pos):
	var consulta = PhysicsPointQueryParameters2D.new()
	consulta.position = pos
	consulta.collision_mask = 1
	return pos.distance_to(global_position) < 550 and get_world_2d().direct_space_state.intersect_point(consulta).is_empty()

func poner_nodo(pos):
	if nodos.size() >= 3:
		quitar_nodo(nodos[0])
	var n = Juego.sprite_de(Juego.NODO)
	n.top_level = true
	add_child(n)
	n.global_position = pos
	nodos.append(n)
	var tw = n.create_tween()
	tw.tween_property(n, "modulate:a", 0.3, 12.0)
	tw.tween_callback(quitar_nodo.bind(n))

func quitar_nodo(n):
	nodos.erase(n)
	n.queue_free()

func empezar_impulso():
	if cd_impulso > 0 or not Juego.gastar_energia(15):
		return
	ruta.clear()
	for n in nodos:
		ruta.append(n.global_position)
		n.queue_free()
	nodos.clear()
	velocity = Vector2.ZERO
	cambiar("impulso")

func impulso(delta):
	if ruta.is_empty() or t > 1.5 or move_and_collide((ruta[0] - global_position).limit_length(900 * delta)):
		ruta.clear()
		cd_impulso = 1.25
		velocity = Vector2.ZERO
		cambiar("normal")
		return
	if global_position.distance_to(ruta[0]) < 2:
		ruta.pop_front()
	for jefe in get_tree().get_nodes_in_group("jefe"):
		if global_position.distance_to(jefe.global_position) < 80:
			jefe.romper_escudo()

func animar():
	modulate.a = 0.5 if inmune > 0 and int(t * 20) % 2 == 0 else 1.0
	if anim == null:
		return
	anim.flip_h = mirando < 0
	var nombre = estado
	if estado == "normal" or estado == "atacar":
		if not is_on_floor():
			nombre = "saltar" if velocity.y < 0 else "caer"
		elif abs(velocity.x) > 10:
			nombre = "correr"
		else:
			nombre = "quieta"
	elif estado == "muerta":
		nombre = "herida"
	elif estado == "impulso":
		nombre = "saltar"
	if anim.sprite_frames and anim.sprite_frames.has_animation(nombre):
		anim.play(nombre)

func sacudir(fuerza):
	if camara == null:
		return
	var tw = create_tween()
	for _i in 4:
		tw.tween_property(camara, "offset", Vector2(randf_range(-fuerza, fuerza), randf_range(-fuerza, fuerza)), 0.03)
	tw.tween_property(camara, "offset", Vector2.ZERO, 0.03)
