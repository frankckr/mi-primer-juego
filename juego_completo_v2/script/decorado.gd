extends Node2D

@export_enum("fondo", "suelo") var capa = "fondo"

var rng = RandomNumberGenerator.new()
var estrellas = []
var motas = []
var luces = []
var t = 0.0


func _ready():
	rng.seed = 7
	for i in 260:
		estrellas.append(Vector3(rng.randf_range(0, 4800), rng.randf_range(-150, 285), rng.randf_range(0, TAU)))
	for i in 90:
		motas.append(Vector3(rng.randf_range(0, 4800), rng.randf_range(140, 295), rng.randf_range(0, TAU)))
	if capa == "fondo":
		buscar_luces.call_deferred()


func buscar_luces():
	var colores = {"descanso": Color(1, 0.6, 0.2), "santuario": Color(0.4, 0.9, 1), "objeto": Color(0.6, 0.9, 1), "luz_final": Color(1, 1, 0.9), "runa": Color(0.4, 0.8, 1), "cofre": Color(1, 0.85, 0.4)}
	for n in get_parent().find_children("*", "Area2D", true, false):
		if "tipo" in n and colores.has(n.tipo):
			luces.append([n, colores[n.tipo]])


func _process(delta):
	t += delta
	queue_redraw()


func _draw():
	rng.seed = 11
	if capa == "suelo":
		dibujar_suelo()
		return
	for e in estrellas:
		draw_rect(Rect2(e.x, e.y, 1, 1), Color(1, 1, 1, 0.25 + 0.6 * abs(sin(t * 1.5 + e.z))))
	draw_circle(Vector2(620, 168), 34, Color(0.9, 0.9, 1, 0.08))
	draw_circle(Vector2(620, 168), 24, Color(0.95, 0.95, 0.82))
	draw_circle(Vector2(631, 162), 20, Color(0.07, 0.08, 0.2))
	colinas(0, 1200, Color(0.1, 0.11, 0.27), 70, 0.011, 0.0)
	colinas(0, 1200, Color(0.13, 0.14, 0.32), 40, 0.023, 2.0)
	colinas(1200, 2200, Color(0.17, 0.13, 0.3), 75, 0.009, 1.0)
	colinas(1200, 2200, Color(0.2, 0.15, 0.34), 38, 0.021, 4.0)
	colinas(2200, 3800, Color(0.08, 0.17, 0.2), 80, 0.008, 3.0)
	colinas(2200, 3800, Color(0.1, 0.2, 0.23), 42, 0.019, 0.5)
	colinas(3800, 4800, Color(0.21, 0.08, 0.15), 90, 0.012, 2.5)
	colinas(3800, 4800, Color(0.25, 0.1, 0.18), 45, 0.025, 1.5)
	observatorio()
	pueblo()
	ruinas()
	arena()
	for i in luces.size():
		var n = luces[i][0]
		if is_instance_valid(n) and n.visible:
			var r = 20 + 3 * sin(t * 5 + i)
			draw_circle(n.global_position, r, Color(luces[i][1], 0.1))
			draw_circle(n.global_position, r * 0.55, Color(luces[i][1], 0.12))
	for m in motas:
		var p = Vector2(m.x + sin(t * 0.5 + m.z) * 10, m.y + cos(t * 0.7 + m.z) * 6)
		draw_rect(Rect2(p, Vector2(1, 1)), Color(0.8, 1, 0.7, 0.6 * abs(sin(t + m.z))))


func colinas(x1, x2, color, alto, frec, fase):
	var puntos = PackedVector2Array([Vector2(x1, 300)])
	var x = x1
	while x <= x2:
		puntos.append(Vector2(x, 300 - alto * (0.6 + 0.4 * sin(x * frec + fase))))
		x += 20
	puntos.append(Vector2(x2, 300))
	draw_colored_polygon(puntos, color)


func columna(x, alto, color, rota = false):
	draw_rect(Rect2(x - 6, 300 - alto, 12, alto), color)
	draw_rect(Rect2(x - 4, 300 - alto, 2, alto), color.lightened(0.12))
	draw_rect(Rect2(x - 9, 296, 18, 4), color.lightened(0.08))
	if rota:
		draw_rect(Rect2(x - 6, 296 - alto, 5, 4), color)
	else:
		draw_rect(Rect2(x - 10, 296 - alto, 20, 5), color.lightened(0.08))


func observatorio():
	var muro = Color(0.17, 0.19, 0.38)
	draw_rect(Rect2(265, 200, 70, 100), muro)
	draw_circle(Vector2(300, 200), 35, muro.lightened(0.08))
	draw_rect(Rect2(265, 200, 70, 4), muro.lightened(0.2))
	draw_line(Vector2(300, 192), Vector2(345, 150), Color(0.5, 0.55, 0.8), 5)
	draw_circle(Vector2(345, 150), 4, Color(0.6, 0.9, 1))
	for y in [220, 250]:
		draw_rect(Rect2(280, y, 8, 12), Color(1, 0.85, 0.4, 0.8 + 0.2 * sin(t * 3 + y)))
		draw_rect(Rect2(312, y, 8, 12), Color(1, 0.85, 0.4, 0.8 + 0.2 * cos(t * 2 + y)))
	draw_rect(Rect2(20, 170, 120, 130), muro.darkened(0.15))
	draw_rect(Rect2(20, 170, 120, 4), muro.lightened(0.15))
	draw_rect(Rect2(60, 200, 40, 34), Color(0.1, 0.12, 0.3))
	draw_line(Vector2(80, 200), Vector2(80, 234), muro, 2)
	draw_line(Vector2(60, 217), Vector2(100, 217), muro, 2)
	for x in [420, 700, 880, 1040, 1160]:
		columna(x, 80 + (x % 50), muro)


func pueblo():
	var tonos = [Color(0.7, 0.25, 0.4), Color(0.3, 0.5, 0.7), Color(0.75, 0.5, 0.25), Color(0.45, 0.3, 0.7)]
	var i = 0
	for x in [1380, 1560, 1760, 1960]:
		draw_rect(Rect2(x - 20, 245, 40, 55), Color(0.5, 0.45, 0.55))
		draw_rect(Rect2(x - 20, 245, 6, 55), Color(0.42, 0.38, 0.48))
		var techo = PackedVector2Array()
		for k in 13:
			var a = PI * k / 12.0
			techo.append(Vector2(x + cos(a) * 46, 250 - sin(a) * 34))
		draw_colored_polygon(techo, tonos[i])
		draw_circle(Vector2(x - 18, 236), 5, tonos[i].lightened(0.5))
		draw_circle(Vector2(x + 14, 228), 7, tonos[i].lightened(0.5))
		draw_circle(Vector2(x + 26, 243), 3, tonos[i].lightened(0.5))
		draw_rect(Rect2(x - 14, 276, 11, 24), Color(0.22, 0.15, 0.2))
		draw_circle(Vector2(x + 9, 268), 11, Color(1, 0.85, 0.4, 0.12))
		draw_rect(Rect2(x + 4, 263, 9, 9), Color(1, 0.85, 0.4, 0.85 + 0.15 * sin(t * 2 + x)))
		i += 1
	for x in [1290, 1500, 1700, 1900, 2130]:
		draw_line(Vector2(x, 300), Vector2(x, 248), Color(0.25, 0.2, 0.3), 2)
		draw_circle(Vector2(x, 244), 14 + sin(t * 3 + x), Color(1, 0.8, 0.4, 0.13))
		draw_circle(Vector2(x, 244), 4, Color(1, 0.9, 0.55))


func ruinas():
	var piedra = Color(0.15, 0.27, 0.3)
	var x = 2270
	while x < 3780:
		columna(x, rng.randi_range(40, 130), piedra, rng.randf() < 0.6)
		x += rng.randi_range(80, 140)
	draw_arc(Vector2(3650, 236), 48, PI, TAU, 16, piedra.lightened(0.15), 8)
	draw_rect(Rect2(3598, 236, 8, 64), piedra.lightened(0.15))
	draw_rect(Rect2(3694, 236, 8, 64), piedra.lightened(0.15))
	for k in 12:
		var c = Vector2(rng.randf_range(2250, 3750), 300)
		var alto = rng.randf_range(8, 20)
		draw_colored_polygon(PackedVector2Array([c + Vector2(-4, 0), c + Vector2(0, -alto), c + Vector2(4, 0)]), Color(0.4, 0.85, 0.9, 0.5 + 0.2 * sin(t * 2 + k)))


func arena():
	var piedra = Color(0.3, 0.11, 0.2)
	for x in [3870, 4040, 4200, 4640, 4780]:
		draw_rect(Rect2(x - 10, 120, 20, 180), piedra)
		draw_rect(Rect2(x - 7, 120, 3, 180), piedra.lightened(0.12))
		draw_rect(Rect2(x - 14, 290, 28, 10), piedra.lightened(0.1))
		draw_rect(Rect2(x - 14, 150, 28, 6), piedra.lightened(0.1))
		draw_colored_polygon(PackedVector2Array([Vector2(x + 10, 160), Vector2(x + 32, 160), Vector2(x + 32, 215), Vector2(x + 21, 205), Vector2(x + 10, 215)]), Color(0.7, 0.15, 0.3))
		draw_circle(Vector2(x + 21, 180), 5, Color(1, 0.8, 0.4))
	if not Juego.jefe_vencido:
		var c = Vector2(4420, 220)
		draw_arc(c, 95, 0, TAU, 48, Color(1, 0.4, 0.7, 0.2), 2)
		for k in 8:
			var a = t * 0.3 + k * TAU / 8
			draw_arc(c, 112, a, a + 0.5, 8, Color(1, 0.5, 0.8, 0.35), 2)
			draw_arc(c, 80, -a, -a + 0.3, 6, Color(0.6, 0.6, 1, 0.3), 2)


func dibujar_suelo():
	for c in get_node("../Suelo").get_children():
		var tam = c.shape.size
		var r = Rect2(c.position - tam / 2, tam)
		var color = c.get_node("Color").color
		var junta = color.darkened(0.3)
		var fila = 0
		var y = r.position.y + 10
		while y < r.end.y:
			draw_rect(Rect2(r.position.x, y, tam.x, 1), junta)
			var x = r.position.x + (12 if fila % 2 == 0 else 0)
			while x < r.end.x:
				draw_rect(Rect2(x, y - 6, 1, 6), junta)
				x += 24
			fila += 1
			y += 10
		draw_rect(Rect2(r.position, Vector2(tam.x, 3)), color.lightened(0.35))
		draw_rect(Rect2(r.position + Vector2(0, 3), Vector2(tam.x, 1)), junta)
		if tam.y > 100:
			continue
		var x2 = r.position.x + 4
		while x2 < r.end.x - 4:
			var alto = rng.randi_range(2, 5)
			draw_rect(Rect2(x2, r.position.y - alto, 1, alto), color.lightened(0.5))
			x2 += rng.randi_range(5, 16)
		if tam.y < 20:
			var x3 = r.position.x + 6
			while x3 < r.end.x - 4:
				draw_rect(Rect2(x3, r.end.y, 1, rng.randi_range(4, 14)), Color(0.3, 0.65, 0.45))
				x3 += rng.randi_range(8, 20)
