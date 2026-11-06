extends Area2D

# BOTIQUIN / CAJON DE MUNICION
#
# Uso un Area2D en vez de un CharacterBody2D porque no quiero que choque,
# solo quiero saber cuando el jugador lo toca.

@export_enum("vida", "municion") var clase = "vida"
@export var cuanta_vida = 35
@export var cuanta_municion = 45
@export var tarda_en_volver = 14.0

@onready var imagen = $Sprite

var esta_disponible = true
var tiempo_para_volver = 0.0


func _ready():
	body_entered.connect(_cuando_lo_tocan)

	if clase == "vida":
		imagen.texture = preload("res://assets/tile_318.png")
		imagen.modulate = Color(0.42, 1.0, 0.55)
	else:
		imagen.texture = preload("res://assets/tile_316.png")
		imagen.modulate = Color(1.0, 0.86, 0.35)

	_hacerlo_latir()


# Para que se note que es algo que se puede agarrar y no decoracion.
# set_loops() hace que la animacion se repita para siempre.
func _hacerlo_latir():
	var tween = create_tween().set_loops()
	tween.tween_property(imagen, "scale", Vector2(0.92, 0.92), 0.7)
	tween.tween_property(imagen, "scale", Vector2(1.06, 1.06), 0.7)


func _process(delta):
	if esta_disponible:
		return

	tiempo_para_volver = tiempo_para_volver - delta
	if tiempo_para_volver <= 0.0:
		esta_disponible = true
		imagen.visible = true


func _cuando_lo_tocan(quien):
	if not esta_disponible:
		return
	if not quien.is_in_group("jugador"):
		return

	var me_sirvio = false

	if clase == "vida":
		# Si ya tengo la vida llena no lo gasto, lo dejo para despues.
		if quien.vida < quien.vida_maxima:
			quien.curar(cuanta_vida)
			me_sirvio = true
	else:
		me_sirvio = quien.dar_municion(cuanta_municion)

	if not me_sirvio:
		return

	Game.sonar("item")
	esta_disponible = false
	tiempo_para_volver = tarda_en_volver
	imagen.visible = false
