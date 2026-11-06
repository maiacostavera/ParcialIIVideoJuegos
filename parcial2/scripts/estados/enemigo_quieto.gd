extends Estado

# ESTADO QUIETO (enemigo)
#
# Es el estado con el que arrancan los dos enemigos. Se queda frenado hasta
# que el jugador se le acerca o hasta que lo ve.
#
# Si lo despertara de entrada, los enemigos me venian todos juntos desde la
# otra punta del mapa. Asi el nivel se va abriendo de a poco.
#
# De aca puede pasar a: Perseguir y Muerto.
#
# Este estado lo usan los DOS tipos de enemigo sin cambiarle nada, porque
# quedarse quieto es igual para los dos.


func actualizar(delta):
	entidad.frenar(delta)

	if not entidad.hay_jugador():
		return

	# Me despierto si lo tengo cerca, o si lo veo y no esta tan lejos.
	# El segundo caso le da un poco mas de alcance cuando no hay paredes en
	# el medio, pero con un limite: si no, en el nivel 1 que es bastante
	# abierto se despertaba medio mapa de una sola vez.
	var cerca = entidad.distancia_para_despertar
	var distancia = entidad.distancia_al_jugador

	if distancia <= cerca or (entidad.lo_veo and distancia <= cerca * 1.6):
		cambiar_a("Perseguir")
