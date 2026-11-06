extends Estado

# ESTADO RECARGAR
#
# Mientras recargo me puedo seguir moviendo y apuntando, pero no disparar.
# Si cambio de arma en el medio, la recarga se cancela.
#
# De aca puede pasar a: Quieto, Esquivar y Muerto.

var tiempo_que_queda = 0.0


func entrar():
	tiempo_que_queda = entidad.tiempo_de_recarga()
	entidad.poner_sprite_de_recarga()
	Game.sonar("recarga")


func salir():
	# Termine o me hayan cancelado, el sprite vuelve al del arma.
	entidad.poner_sprite_del_arma()


func actualizar(delta):
	entidad.mirar_al_mouse()
	var cambio_de_arma = entidad.revisar_cambio_de_arma()
	entidad.mover(entidad.teclas_de_movimiento(), delta)

	if cambio_de_arma:
		cambiar_a("Quieto")
		return

	if Input.is_action_just_pressed("esquivar") and entidad.puede_esquivar():
		cambiar_a("Esquivar")
		return

	tiempo_que_queda = tiempo_que_queda - delta
	if tiempo_que_queda <= 0.0:
		entidad.terminar_recarga()
		cambiar_a("Quieto")
