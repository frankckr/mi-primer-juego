extends Node

signal cambio
signal mensaje(texto)
signal jefe_aparece(jefe)
signal jefe_derrotado

const HOJA_OBJETOS = "res://personajes/5_personajes_y_objetos_32x32.png"
const RUTA = "user://partida.json"
const GUARDAR = ["vida_max", "cargas_max", "inventario", "tiene_nodos", "amuleto", "abiertos", "zonas", "jefe_vencido", "nivel", "xp"]
const TECLAS = {
	"izquierda": [KEY_A, KEY_LEFT], "derecha": [KEY_D, KEY_RIGHT], "arriba": [KEY_W, KEY_UP],
	"saltar": [KEY_SPACE], "atacar": [KEY_J], "rodar": [KEY_K], "nodo": [KEY_L], "curar": [KEY_Q],
	"carga": [KEY_C], "pocion": [KEY_1], "usar": [KEY_E], "inventario": [KEY_I], "mapa": [KEY_M], "pausa": [KEY_ESCAPE],
}

enum { ESCARABAJO, AVISO, POLILLA, POLILLA2, ESPADA, JEFE_ESCUDO, NODO, CARACOL, HONGO, ORACULO, PROTA, CAMA, COFRE_ABIERTO, COFRE, CRISTAL, HOGUERA, JEFE_ATURDIDO, JEFE, LUZ, RUNA, SANTUARIO }

var vida = 5
var vida_max = 5
var energia = 0
var cargas = 2
var cargas_max = 2
var inventario = {}
var tiene_nodos = false
var amuleto = false
var abiertos = {}
var zonas = []
var jefe_vencido = false
var nivel = 1
var xp = 0
var reaparicion = Vector2.ZERO
var despertar = true
var inicial = ""

func _ready():
	for accion in TECLAS:
		if not InputMap.has_action(accion):
			InputMap.add_action(accion)
		for tecla in TECLAS[accion]:
			var e = InputEventKey.new()
			e.physical_keycode = tecla
			InputMap.action_add_event(accion, e)
	inicial = JSON.stringify(datos())

func sprite_de(cuadro):
	var s = Sprite2D.new()
	s.texture = load(HOJA_OBJETOS)
	s.hframes = 21
	s.frame = cuadro
	return s

func forma(tam):
	var c = CollisionShape2D.new()
	c.shape = RectangleShape2D.new()
	c.shape.size = tam
	return c

func danar(n):
	vida = max(vida - n, 0)
	cambio.emit()
	return vida == 0

func curar(n):
	vida = min(vida + n, vida_max)
	cambio.emit()

func llenar():
	vida = vida_max
	cargas = cargas_max
	cambio.emit()

func sumar_energia(n):
	energia = clamp(energia + n, 0, 100)
	cambio.emit()

func gastar_energia(n):
	if energia < n:
		mensaje.emit("Falta energía")
		return false
	sumar_energia(-n)
	return true

func usar_carga():
	if cargas > 0 and vida < vida_max:
		cargas -= 1
		curar(2)

func usar_pocion():
	if vida < vida_max and quitar("pocion"):
		curar(vida_max)

func agregar(cosa, n = 1):
	inventario[cosa] = inventario.get(cosa, 0) + n
	mensaje.emit("+%d %s" % [n, cosa])
	cambio.emit()

func quitar(cosa, n = 1):
	if inventario.get(cosa, 0) < n:
		return false
	inventario[cosa] -= n
	cambio.emit()
	return true

func sumar_xp(n):
	xp += n
	if xp >= nivel * 10:
		xp -= nivel * 10
		nivel += 1
		vida_max += 1
		mensaje.emit("¡Nivel %d!" % nivel)
		llenar()
	cambio.emit()

func visitar(zona):
	if zona not in zonas:
		zonas.append(zona)
		mensaje.emit(zona.capitalize())

func descansar(pos):
	reaparicion = pos
	llenar()
	guardar()

func congelar(segundos):
	Engine.time_scale = 0.05
	await get_tree().create_timer(segundos, true, false, true).timeout
	Engine.time_scale = 1.0

func datos():
	var d = {"x": reaparicion.x, "y": reaparicion.y}
	for k in GUARDAR:
		d[k] = get(k)
	return d

func aplicar(d):
	for k in GUARDAR:
		set(k, int(d[k]) if d[k] is float else d[k])
	reaparicion = Vector2(d["x"], d["y"])
	energia = 0
	llenar()

func nueva_partida():
	aplicar(JSON.parse_string(inicial))
	despertar = true

func hay_guardado():
	return FileAccess.file_exists(RUTA)

func guardar():
	FileAccess.open(RUTA, FileAccess.WRITE).store_string(JSON.stringify(datos()))

func cargar():
	aplicar(JSON.parse_string(FileAccess.get_file_as_string(RUTA)))
	despertar = false
