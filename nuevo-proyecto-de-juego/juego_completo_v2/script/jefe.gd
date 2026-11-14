extends CharacterBody2D

const COLOR_MANO = Color(0.2, 0.18, 0.3)

@export var vida = 20

var estado = "espera"
var t = 0.0
var escudo = true
var sprite: Sprite2D
var manos = []
var mano = 0
var fase = 0
var t_mano = 0.0
var destino: Vector2
var golpeo = false
var jugador

func _ready():
	if Juego.jefe_vencido:
		queue_free()
		return
	add_to_group("jefe")
	collision_layer = 4
	collision_mask = 0
	sprite = get_node_or_null("Sprite2D")
	if sprite == null:
		sprite = Juego.sprite_de(Juego.JEFE)
		sprite.scale = Vector2(4, 4)
		add_child(sprite)
	sprite.show_behind_parent = true
	if get_node_or_null("CollisionShape2D") == null:
		add_child(Juego.forma(Vector2(70, 110)))
	for lado in [-1, 1]:
		var m = Polygon2D.new()
		m.polygon = PackedVector2Array([Vector2(-10, -8), Vector2(10, -8), Vector2(10, 8), Vector2(-10, 8)])
		m.color = COLOR_MANO
		m.position = Vector2(85 * lado, 20)
		add_child(m)
		manos.append(m)

func _physics_process(delta):
	queue_redraw()
	jugador = get_tree().get_first_node_in_group("jugador")
	if estado == "muerto" or jugador == null:
		return
	t += delta
	sprite.position.y = sin(Time.get_ticks_msec() / 500.0) * 3
	match estado:
		"espera":
			if global_position.distance_to(jugador.global_position) < 260:
				estado = "escudo"
				Juego.jefe_aparece.emit(self)
		"escudo":
			manotazos(delta)
		"aturdido":
			if t > 1.2:
				estado = "vulnerable"
		"vulnerable":
			if t > 3.0:
				estado = "recuperando"
				t = 0.0
				cuadro(Juego.JEFE)
		"recuperando":
			manotazos(delta)
			if t > 4.0:
				escudo = true
				estado = "escudo"

func manotazos(delta):
	t_mano += delta
	var m = manos[mano]
	match fase:
		0:
			if t_mano > 2.0:
				mano = 0 if jugador.global_position.x < global_position.x else 1
				destino = to_local(jugador.global_position)
				golpeo = false
				siguiente_fase()
		1:
			m.position = m.position.lerp(destino + Vector2(0, -80), 0.15)
			m.color = Color(1, 0.3, 0.7) if int(t_mano * 12) % 2 == 0 else COLOR_MANO
			if t_mano > 0.8:
				siguiente_fase()
		2:
			m.position = m.position.move_toward(destino, 1200 * delta)
			if not golpeo and m.global_position.distance_to(jugador.global_position) < 26:
				golpeo = true
				jugador.recibir_golpe(2, m)
			if t_mano > 0.2:
				jugador.sacudir(5)
				siguiente_fase()
		3:
			m.position = m.position.lerp(Vector2(170 * mano - 85, 20), 0.15)
			m.color = COLOR_MANO
			if t_mano > 0.5:
				siguiente_fase()

func siguiente_fase():
	fase = (fase + 1) % 4
	t_mano = 0.0

func romper_escudo():
	if estado != "escudo":
		return
	escudo = false
	estado = "aturdido"
	t = 0.0
	fase = 3
	t_mano = 0.0
	cuadro(Juego.JEFE_ATURDIDO)
	Juego.mensaje.emit("¡Escudo roto!")
	jugador.sacudir(8)

func herir(n, _desde):
	var expuesto = estado == "aturdido" or estado == "vulnerable"
	sprite.modulate = Color(3, 3, 3) if expuesto else Color(0.5, 0.7, 1)
	create_tween().tween_property(sprite, "modulate", Color.WHITE, 0.15)
	if not expuesto:
		Juego.mensaje.emit("El escudo lo protege")
		return
	vida -= n
	if vida <= 0:
		estado = "muerto"
		escudo = false
		collision_layer = 0
		Juego.jefe_vencido = true
		Juego.sumar_xp(20)
		Juego.jefe_derrotado.emit()
		var tw = create_tween()
		tw.tween_property(self, "modulate:a", 0.0, 1.5)
		tw.tween_callback(queue_free)

func cuadro(n):
	if sprite.hframes > n:
		sprite.frame = n

func _draw():
	if escudo and estado != "espera":
		draw_circle(Vector2.ZERO, 72, Color(0.35, 0.55, 1, 0.22))
		draw_arc(Vector2.ZERO, 72, 0, TAU, 48, Color(0.55, 0.75, 1), 2)
