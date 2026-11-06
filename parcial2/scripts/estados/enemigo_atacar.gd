extends Estado

# ESTADO ATACAR (lo tiene solo el enemigo tonto)
#
# El golpe pasa una sola vez, en el entrar(). Despues se queda quieto un
# ratito antes de volver a perseguir. Esa pausa es lo que te da tiempo a
# escaparte, si no es imposible.
#
# Ojo: la espera larga entre golpe y golpe NO esta aca, esta en la clase
# Enemigo (la variable espera_ataque), porque tiene que seguir bajando
# mientras persigue. Por eso Perseguir pregunta puede_atacar() antes de
# mandarlo a este estado.
#
# De aca puede pasar a: Perseguir y Muerto.

var tiempo_que_queda = 0.0


func entrar():
	tiempo_que_queda = 0.28
	entidad.atacar()


func actualizar(delta):
	entidad.mirar_al_jugador()
	entidad.frenar(delta)

	tiempo_que_queda = tiempo_que_queda - delta
	if tiempo_que_queda <= 0.0:
		cambiar_a("Perseguir")
