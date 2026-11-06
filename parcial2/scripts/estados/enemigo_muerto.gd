extends Estado

# ESTADO MUERTO (enemigo)
#
# Deja la mancha de sangre, suma los puntos y se borra con queue_free().
# No sale para ningun lado.
#
# A este estado no se llega con una transicion normal: lo fuerza
# recibir_danio() de la clase Enemigo cuando la vida llega a cero, porque
# morirse no es algo que el estado actual pueda decidir.


func entrar():
	entidad.morir()
