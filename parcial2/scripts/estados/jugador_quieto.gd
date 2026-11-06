extends Estado

# ESTADO QUIETO
#
# El jugador esta parado. Igual puede apuntar, disparar y cambiar de arma,
# lo unico que no hace es moverse.
#
# De aca puede pasar a: Caminar, Esquivar, Recargar y Muerto.


func entrar():
	entidad.poner_sprite_del_arma()


func actualizar(delta):
	entidad.mirar_al_mouse()
	entidad.revisar_cambio_de_arma()
	entidad.frenar(delta)

	# Primero reviso las salidas y despues disparo, porque si no disparo un
	# tiro de mas justo cuando estoy cambiando de estado.
	if entidad.teclas_de_movimiento() != Vector2.ZERO:
		cambiar_a("Caminar")
		return

	if Input.is_action_just_pressed("esquivar") and entidad.puede_esquivar():
		cambiar_a("Esquivar")
		return

	# Recargo si apreto R, o si trato de disparar sin balas.
	if entidad.puede_recargar():
		if entidad.quiere_recargar() or (entidad.quiere_disparar() and entidad.cargador_vacio()):
			cambiar_a("Recargar")
			return

	if entidad.quiere_disparar():
		entidad.disparar()
