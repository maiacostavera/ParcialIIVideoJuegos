extends Estado

# ESTADO ESQUIVAR
#
# Una corrida rapida y corta. Mientras dura no me pueden pegar y no puedo
# disparar.
#
# La direccion la guardo al entrar y no la cambio mas. Lo hice asi a
# proposito: si pudieras corregir el rumbo en el medio, esquivar seria
# simplemente "correr mas rapido" y perderia la gracia.
#
# De aca puede pasar a: Quieto, Caminar y Muerto.

var tiempo_que_queda = 0.0
var direccion = Vector2.ZERO


func entrar():
	direccion = entidad.direccion_del_esquive()
	tiempo_que_queda = entidad.duracion_esquive
	entidad.empezar_espera_del_esquive()
	entidad.poner_transparente(true)


func salir():
	# Esto es lo bueno de tener el salir(): no importa como me vaya de este
	# estado, el sprite siempre vuelve a la normalidad. Antes lo hacia con una
	# variable "esquivando" y me olvidaba de apagarla en algun lado, entonces
	# el personaje quedaba transparente para siempre.
	entidad.poner_transparente(false)


func actualizar(delta):
	entidad.mirar_al_mouse()
	entidad.moverse_esquivando(direccion)

	tiempo_que_queda = tiempo_que_queda - delta
	if tiempo_que_queda <= 0.0:
		if entidad.teclas_de_movimiento() != Vector2.ZERO:
			cambiar_a("Caminar")
		else:
			cambiar_a("Quieto")
