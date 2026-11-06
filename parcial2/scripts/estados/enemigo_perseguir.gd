extends Estado

# ESTADO PERSEGUIR
#
# Lo usan los DOS tipos de enemigo, y es el ejemplo mas claro de para que me
# sirvio hacer la clase comun.
#
# Fijate que aca no pregunto en ningun momento de que tipo de enemigo se
# trata. Le pido que camine y cada zombie decide por su cuenta para donde:
#
#   hacia_donde_persigo()   el tonto va derecho y se traba en las paredes,
#                           el inteligente sigue el camino que esquiva todo
#
#   velocidad_de_ahora()    el tonto va siempre igual,
#                           el inteligente acelera cuando te tiene a la vista
#
# Antes este mismo archivo tenia un "if entidad.tipo == CUERPO ... else ..."
# y cada vez que agregaba algo tenia que acordarme de tocar las dos ramas.
# Ahora el estado no sabe ni le importa con cual de los dos esta hablando.
#
# De aca puede pasar a: Quieto, Atacar y Muerto.


func actualizar(delta):
	if not entidad.hay_jugador():
		cambiar_a("Quieto")
		return

	entidad.mirar_al_jugador()
	entidad.mover(entidad.hacia_donde_persigo(), delta)

	# puede_atacar() es la espera entre mordiscon y mordiscon, y
	# puedo_atacar_al_jugador() es si lo tengo lo bastante cerca. Las dos
	# estan en la clase comun porque los dos zombies muerden igual.
	if entidad.puede_atacar() and entidad.puedo_atacar_al_jugador():
		cambiar_a("Atacar")
