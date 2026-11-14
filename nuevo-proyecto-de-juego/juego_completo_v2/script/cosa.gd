extends Area2D

@export_enum("npc", "tienda", "descanso", "santuario", "cofre", "objeto", "runa", "zona", "luz_final") var tipo = "npc"
@export var nombre = ""
@export_multiline var texto = ""
@export var dibujo = 9
@export var regalo = ""

var cerca = false
var oferta = false
var sprite: Sprite2D
var letrero: Label

func _ready():
	collision_layer = 0
	collision_mask = 2
	if get_node_or_null("CollisionShape2D") == null:
		add_child(Juego.forma(Vector2(32, 400) if tipo == "zona" else Vector2(40, 40)))
	sprite = get_node_or_null("Sprite2D")
	if sprite == null and tipo != "zona":
		sprite = Juego.sprite_de(dibujo)
		add_child(sprite)
	letrero = Label.new()
	letrero.text = texto if tipo == "runa" else "E"
	letrero.add_theme_font_size_override("font_size", 8)
	letrero.autowrap_mode = TextServer.AUTOWRAP_WORD
	letrero.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	letrero.custom_minimum_size.x = 120
	letrero.position = Vector2(-60, -48)
	letrero.visible = tipo == "runa"
	add_child(letrero)
	body_entered.connect(entra)
	body_exited.connect(sale)
	if usado() and tipo == "objeto":
		queue_free()
	if usado() and tipo == "cofre":
		cuadro(Juego.COFRE_ABIERTO)
	if tipo == "luz_final":
		visible = Juego.jefe_vencido
		Juego.jefe_derrotado.connect(show)

func _process(_delta):
	if sprite and tipo in ["npc", "objeto", "luz_final"]:
		sprite.position.y = sin(Time.get_ticks_msec() / 400.0) * 2

func _unhandled_input(e):
	if cerca and visible and e.is_action_pressed("usar"):
		get_viewport().set_input_as_handled()
		usar()

func entra(cuerpo):
	if not cuerpo.is_in_group("jugador"):
		return
	if tipo == "objeto":
		marcar()
		Juego.agregar(regalo if regalo else "cristal")
		queue_free()
	elif tipo == "zona":
		Juego.visitar(nombre)
	elif tipo != "runa":
		cerca = true
		letrero.visible = visible

func sale(cuerpo):
	if cuerpo.is_in_group("jugador") and tipo != "runa":
		cerca = false
		oferta = false
		letrero.hide()

func usar():
	match tipo:
		"npc":
			Interfaz.dialogo(nombre, texto)
			if regalo and not usado():
				marcar()
				Juego.agregar(regalo)
		"tienda":
			if not oferta:
				oferta = true
				Interfaz.dialogo(nombre, texto + "\nUna carga extra cuesta 5 cristales. Tienes %d.\nPulsa E otra vez para comprar." % Juego.inventario.get("cristal", 0))
			elif Juego.quitar("cristal", 5):
				Juego.cargas_max += 1
				Juego.llenar()
				Interfaz.dialogo(nombre, "¡Gracias! Ahora tienes una carga más.")
			else:
				Interfaz.dialogo(nombre, "Te faltan cristales.")
		"descanso":
			Juego.descansar(global_position + Vector2(0, -20))
			Interfaz.dialogo("", "Descansas. Vida y cargas llenas.\nPartida guardada.")
		"santuario":
			if not Juego.tiene_nodos:
				Juego.tiene_nodos = true
				Interfaz.dialogo("", texto + "\nMantén L y apunta con el ratón para poner un nodo.\nW + Espacio: Impulso Relámpago.")
		"cofre":
			if not usado():
				marcar()
				cuadro(Juego.COFRE_ABIERTO)
				Juego.agregar(regalo if regalo else "pocion")
		"luz_final":
			Interfaz.fin()

func usado():
	return Juego.abiertos.has(str(get_path()))

func marcar():
	Juego.abiertos[str(get_path())] = true

func cuadro(n):
	if sprite and sprite.hframes > n:
		sprite.frame = n
