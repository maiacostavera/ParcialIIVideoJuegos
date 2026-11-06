extends Estado

# ESTADO CAMINAR
#
# Es igual que Quieto pero moviendose. Lo deje separado aunque casi no cambia
# porque es el lugar donde despues le quiero poner el sonido de los pasos y
# una animacion, y asi no tengo que ensuciar el otro estado con un if.
#
# De aca puede pasar a: Quieto, Esquivar, Recargar y Muerto.


func entrar():
	entidad.poner_sprite_del_arma()


func actualizar(delta):
	entidad.mirar_al_mouse()
	entidad.revisar_cambio_de_arma()

	var teclas = entidad.teclas_de_movimiento()
	entidad.mover(teclas, delta)

	if teclas == Vector2.ZERO:
		cambiar_a("Quieto")
		return

	if Input.is_action_just_pressed("esquivar") and entidad.puede_esquivar():
		cambiar_a("Esquivar")
		return

	if entidad.puede_recargar():
		if entidad.quiere_recargar() or (entidad.quiere_disparar() and entidad.cargador_vacio()):
			cambiar_a("Recargar")
			return

	if entidad.quiere_disparar():
		entidad.disparar()
