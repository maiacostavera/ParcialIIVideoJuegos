extends Area2D

# LA BALA
#
# La usan el jugador y los enemigos, la unica diferencia es el "equipo".
# Asi una bala mia no me puede pegar a mi, y una de ellos no le pega a otro
# enemigo. Al principio no tenia esto y los zombies se mataban entre ellos
# sin que yo hiciera nada.

var direccion = Vector2.RIGHT
var velocidad = 1100.0
var danio = 30
var equipo = "jugador"

var _distancia_recorrida = 0.0
var _ya_pego = false


func _ready():
	body_entered.connect(_cuando_choca)


# Lo llama el que dispara, justo despues de agregarla a la escena.
func disparar_desde(posicion, angulo, cuanto_danio, de_quien):
	global_position = posicion
	rotation = angulo
	direccion = Vector2.RIGHT.rotated(angulo)
	danio = cuanto_danio
	equipo = de_quien


func _physics_process(delta):
	var paso = velocidad * delta
	position = position + direccion * paso

	# Si no las borro, las balas que no le pegan a nada se van para siempre
	# y el juego se va llenando de balas invisibles.
	_distancia_recorrida = _distancia_recorrida + paso
	if _distancia_recorrida > 1600:
		queue_free()


func _cuando_choca(con_quien):
	if _ya_pego:
		return

	# Si es de mi equipo la atraviesa.
	if con_quien.is_in_group(equipo):
		return

	_ya_pego = true

	# has_method() es para chequear que el nodo tenga esa funcion. Las paredes
	# no la tienen, entonces la bala simplemente se borra contra la pared.
	if con_quien.has_method("recibir_danio"):
		con_quien.recibir_danio(danio, direccion)

	queue_free()


# Dibujo la bala con codigo en vez de usar una imagen, porque el pack de
# Kenney no trae ninguna que me gustara. Es una rayita amarilla.
func _draw():
	draw_line(Vector2(-9, 0), Vector2(5, 0), Color(1.0, 0.85, 0.35), 3.0)
	draw_line(Vector2(-3, 0), Vector2(5, 0), Color(1.0, 1.0, 0.9), 1.5)
