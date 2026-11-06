extends Node2D

# LAS PARTICULAS DEL DISPARO
#
# Cada vez que el jugador dispara crea una de estas en la punta del arma,
# girada para el mismo lado que la bala. Tiene tres CPUParticles2D:
#
#   Fogonazo   el fuego que sale del canio, dura casi nada
#   Chispas    unos puntitos amarillos que salen para adelante
#   Humo       un poco de humo gris que se queda flotando
#
# Las texturas son del Particle Pack de Kenney (assets/particulas/). Son
# blancas, asi que el color se lo doy en cada CPUParticles2D con "color".
#
# Las hice como escena aparte que se crea en cada tiro (como la bala), y no
# como nodos fijos adentro del jugador, porque la ametralladora tira cada
# 0.08 segundos: si fueran siempre las mismas particulas, cada tiro nuevo
# reiniciaria el humo del anterior antes de que se llegue a ver.
#
# Uso CPUParticles2D y no GPUParticles2D porque el proyecto esta en modo
# Compatibilidad y asi seguro anda en cualquier compu.
#
# El Fogonazo tiene "local_coords" prendido y los otros dos no. Sin
# local_coords la particula no gira con el nodo, y como la textura del fuego
# apunta para arriba, el fogonazo salia de costado en vez de para adelante.
# Al humo y las chispas no les hace falta: igual salen para el lado correcto
# y asi quedan en el lugar del tiro.

@onready var humo = $Humo


func _ready():
	# Las tres tienen one_shot, asi que arrancan solas al entrar a la escena y
	# tiran una sola vez. El humo es el que mas dura, entonces cuando termina
	# ya terminaron todas y me puedo borrar.
	humo.finished.connect(queue_free)
