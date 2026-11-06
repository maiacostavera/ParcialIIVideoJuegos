class_name Estado
extends Node

# Clase base de todos los estados de la maquina de estados.
#
# Cada estado es un nodo hijo del nodo MaquinaDeEstados. Este script no hace
# nada por si solo: define los metodos que despues cada estado sobreescribe
# con lo que tenga que hacer.
#
# La idea (asi me la explicaron) es que el personaje solo puede estar en UN
# estado a la vez. Entonces en vez de tener mil variables tipo
# "esta_recargando" o "esta_esquivando" y preguntar por todas en cada if,
# tengo un solo estado activo y listo.

# La maquina escucha esta señal. Cuando un estado quiere pasarle el control a
# otro, la emite con el nombre del nodo del otro estado.
signal pedir_cambio(nombre_del_estado)

# El personaje duenio de la maquina (el jugador o el enemigo).
# Se la pasa la MaquinaDeEstados cuando arranca, asi no tengo que andar
# buscandolo con get_parent().get_parent() que queda horrible.
var entidad = null


# Se ejecuta una sola vez cuando entro al estado.
func entrar():
	pass


# Se ejecuta una sola vez cuando salgo del estado.
# Sirve para dejar las cosas como estaban (por ejemplo volver el sprite
# normal).
func salir():
	pass


# Se ejecuta en cada frame de fisica mientras el estado esta activo.
func actualizar(_delta):
	pass


# Atajo para no escribir la señal a mano en todos lados.
func cambiar_a(nombre_del_estado):
	pedir_cambio.emit(nombre_del_estado)
