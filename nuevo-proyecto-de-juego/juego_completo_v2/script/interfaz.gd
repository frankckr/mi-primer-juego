extends CanvasLayer

const TITULO = "NOMBRE DEL JUEGO"
const MENU_AL_INICIO = true

var vida: ProgressBar
var energia: ProgressBar
var barra_jefe: ProgressBar
var info: Label
var aviso: Label
var caja: PanelContainer
var texto: Label
var ventana: Control
var actual = ""
var lineas = []
var quien = ""
var jefe
var volver_a: Callable
var tw: Tween

func _ready():
	layer = 10
	process_mode = PROCESS_MODE_ALWAYS
	vida = barra(Vector2(12, 12), Color(0.9, 0.3, 0.4))
	energia = barra(Vector2(12, 30), Color(0.3, 0.8, 1))
	energia.max_value = 100
	info = etiqueta(self, Vector2(12, 44))
	aviso = etiqueta(self, Vector2(12, 70))
	barra_jefe = barra(Vector2.ZERO, Color(0.7, 0.4, 1))
	barra_jefe.size.x = 300
	barra_jefe.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM, Control.PRESET_MODE_KEEP_SIZE, 40)
	etiqueta(barra_jefe, Vector2(0, -26), "Guardián Astral")
	barra_jefe.hide()
	caja = PanelContainer.new()
	caja.custom_minimum_size.y = 64
	caja.grow_vertical = Control.GROW_DIRECTION_BEGIN
	add_child(caja)
	caja.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE, Control.PRESET_MODE_MINSIZE, 16)
	texto = etiqueta(caja, Vector2.ZERO)
	texto.autowrap_mode = TextServer.AUTOWRAP_WORD
	caja.hide()
	Juego.cambio.connect(actualizar)
	Juego.mensaje.connect(avisar)
	Juego.jefe_aparece.connect(ver_jefe)
	Juego.jefe_derrotado.connect(barra_jefe.hide)
	actualizar()
	if MENU_AL_INICIO:
		menu_principal.call_deferred()

func _process(_delta):
	if is_instance_valid(jefe):
		barra_jefe.value = jefe.vida

func _input(e):
	if caja.visible and e.is_action_pressed("usar"):
		get_viewport().set_input_as_handled()
		siguiente()

func _unhandled_input(e):
	if caja.visible or actual == "menu" or actual == "fin":
		return
	if e.is_action_pressed("pausa"):
		alternar(pausa)
	elif e.is_action_pressed("inventario"):
		alternar(inventario)
	elif e.is_action_pressed("mapa"):
		alternar(mapa)

func alternar(abrir_ventana):
	if actual:
		cerrar()
	else:
		abrir_ventana.call()

func actualizar():
	vida.max_value = Juego.vida_max
	vida.value = Juego.vida
	energia.value = Juego.energia
	info.text = "Cargas %d   Cristales %d   Pociones %d   Nivel %d" % [Juego.cargas, Juego.inventario.get("cristal", 0), Juego.inventario.get("pocion", 0), Juego.nivel]

func avisar(t):
	aviso.text = t
	aviso.modulate.a = 1
	if tw:
		tw.kill()
	tw = create_tween()
	tw.tween_interval(1.5)
	tw.tween_property(aviso, "modulate:a", 0.0, 0.5)

func ver_jefe(j):
	jefe = j
	barra_jefe.max_value = j.vida
	barra_jefe.show()

func dialogo(nombre, t):
	quien = nombre
	lineas = Array(t.split("\n", false))
	caja.show()
	get_tree().paused = true
	siguiente()

func siguiente():
	if lineas.is_empty():
		caja.hide()
		get_tree().paused = false
		return
	texto.text = (quien + ": " if quien else "") + lineas.pop_front() + "   [E]"

func abrir(nombre, titulo, cuerpo, botones):
	cerrar()
	actual = nombre
	get_tree().paused = true
	ventana = CenterContainer.new()
	add_child(ventana)
	ventana.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var panel = PanelContainer.new()
	ventana.add_child(panel)
	var lista = VBoxContainer.new()
	panel.add_child(lista)
	var t = etiqueta(lista, Vector2.ZERO, titulo + ("\n\n" + cuerpo if cuerpo else ""))
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	for b in botones:
		var boton = Button.new()
		boton.text = b[0]
		boton.pressed.connect(b[1])
		lista.add_child(boton)
	lista.get_child(1).grab_focus()

func cerrar():
	if ventana:
		ventana.queue_free()
	ventana = null
	actual = ""
	get_tree().paused = false

func menu_principal():
	var b = [["Nueva partida", nueva]]
	if Juego.hay_guardado():
		b.append(["Continuar", continuar])
	b.append(["Configuración", configuracion])
	b.append(["Salir", get_tree().quit])
	abrir("menu", TITULO, "", b)

func pausa():
	abrir("pausa", "PAUSA", "", [["Continuar", cerrar], ["Inventario", inventario], ["Mapa", mapa], ["Configuración", configuracion], ["Menú principal", menu_principal]])

func inventario():
	var t = "Nivel %d   XP %d/%d\n" % [Juego.nivel, Juego.xp, Juego.nivel * 10]
	for k in Juego.inventario:
		t += "\n%s x%d" % [k.capitalize(), Juego.inventario[k]]
	var b = [["Cerrar", cerrar]]
	if Juego.inventario.get("amuleto", 0) > 0:
		t += "\n\nAmuleto del Eco: el parry deja un nodo."
		b.push_front(["Quitar amuleto" if Juego.amuleto else "Equipar amuleto", equipar])
	abrir("inventario", "INVENTARIO", t, b)

func equipar():
	Juego.amuleto = not Juego.amuleto
	inventario()

func mapa():
	var partes = []
	for z in ["observatorio", "pueblo", "ruinas", "arena"]:
		partes.append(z.capitalize() if z in Juego.zonas else "???")
	abrir("mapa", "MAPA", " — ".join(partes), [["Cerrar", cerrar]])

func configuracion():
	if actual != "config":
		volver_a = menu_principal if actual == "menu" else pausa
	var v = db_to_linear(AudioServer.get_bus_volume_db(0))
	abrir("config", "CONFIGURACIÓN", "Volumen %d%%" % round(v * 100), [["Volumen +", volumen.bind(0.1)], ["Volumen -", volumen.bind(-0.1)], ["Pantalla completa", pantalla], ["Volver", volver_a]])

func volumen(paso):
	var v = clamp(db_to_linear(AudioServer.get_bus_volume_db(0)) + paso, 0.0, 1.0)
	AudioServer.set_bus_volume_db(0, linear_to_db(v))
	configuracion()

func pantalla():
	var completa = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED if completa else DisplayServer.WINDOW_MODE_FULLSCREEN)

func fin():
	abrir("fin", "FIN DE LA DEMO", "Gracias por jugar.", [["Menú principal", menu_principal], ["Salir", get_tree().quit]])

func nueva():
	Juego.nueva_partida()
	reiniciar()

func continuar():
	Juego.cargar()
	reiniciar()

func reiniciar():
	cerrar()
	barra_jefe.hide()
	get_tree().reload_current_scene()

func etiqueta(padre, pos, t = ""):
	var l = Label.new()
	l.position = pos
	l.text = t
	padre.add_child(l)
	return l

func barra(pos, color):
	var b = ProgressBar.new()
	b.position = pos
	b.size = Vector2(160, 12)
	b.show_percentage = false
	var relleno = StyleBoxFlat.new()
	relleno.bg_color = color
	b.add_theme_stylebox_override("fill", relleno)
	add_child(b)
	return b
