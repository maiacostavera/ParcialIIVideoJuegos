class_name EnemigoTonto
extends Enemigo

# EL ZOMBIE TONTO
#
# Hereda de Enemigo, asi que ya tiene la vida, el movimiento, el mordiscon,
# los balazos y la muerte de la clase comun. Aca abajo esta TODO lo que
# tiene de propio, que es muy poco a proposito.
#
# Es tonto porque camina siempre derecho hacia el jugador y no se fija si
# hay algo en el medio: si tiene una pared adelante se queda ahi apretado
# empujandola hasta que el jugador se corre de lugar.
#
# Que se trabe no es un error mio, es la gracia: al lado del zombie
# inteligente (que da la vuelta y te encuentra) la diferencia se ve
# enseguida.
#
# Fijate que este archivo casi no tiene codigo. Eso es justamente lo bueno
# de haberlo hecho con herencia: todo lo que comparte con el otro zombie
# esta escrito una sola vez en enemigo.gd.


func como_me_llamo():
	return "Zombie tonto"


# Derecho hacia el jugador, sin pensar.
#
# Esta funcion hace exactamente lo mismo que la de la clase comun, asi que
# en realidad podria borrarla y andaria igual. La dejo escrita a proposito
# para que se pueda leer al lado de la del zombie inteligente y se entienda
# de una cual es la diferencia entre los dos.
func hacia_donde_persigo():
	return direccion_al_jugador()
