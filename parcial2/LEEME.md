# ZONA CERO — Segundo parcial de Videojuegos

Juego de disparos cenital (vista desde arriba) estilo Hotline Miami, hecho en
**Godot 4.4** con los graficos del pack de Kenney.

Es la continuacion del ejercicio del 16/10, con el menu, los dos niveles, la
meta y los enemigos pasados a herencia.

---

## Como correrlo

1. Abrir Godot 4.4.
2. **Importar** → elegir la carpeta del proyecto (la que tiene el
   `project.godot`).
3. La primera vez Godot importa las imagenes y los sonidos, tarda unos
   segundos.
4. F5 para jugar. Arranca en el menu principal.

---

## Controles

| Tecla | Que hace |
|---|---|
| W A S D (o flechas) | Moverse |
| Mouse | Apuntar |
| Click izquierdo | Disparar |
| R | Recargar |
| Espacio | Esquivar (mientras dura no te pueden pegar) |
| 1 / 2 / 3 | Cambiar de arma |
| **F3** | Ver el estado de cada personaje **y el camino del zombie inteligente** |
| Esc | Pausa |
| Enter | Reintentar el nivel cuando perdiste |

> **F3 es el que conviene mostrar en la entrega.** Prende dos cosas: los
> carteles que dicen en que estado esta cada uno (`Zombie tonto: Perseguir`,
> `Zombie listo: Atacar`...) y, en el zombie inteligente, **la linea que
> dibuja el camino que esta siguiendo**. Con eso se ve de un vistazo que la
> maquina de estados anda y que el zombie inteligente esta esquivando las
> paredes de verdad, no de casualidad.

---

## Donde esta cada cosa que pedia el parcial

| Lo que pedia | Donde esta |
|---|---|
| Menu inicial (Nivel 1, Nivel 2 y Salir) | `escenas/menu_principal.tscn` + `scripts/menu_principal.gd` |
| Nivel 1 y Nivel 2 | los dos botones del menu → `MAPA_1` y `MAPA_2` en `scripts/nivel.gd` |
| Boton para salir | `_apretaron_salir()` en `scripts/menu_principal.gd` |
| Personaje principal con pistola | `escenas/jugador.tscn` + `scripts/jugador.gd` (la pistola es el arma 1) |
| Dos tipos de enemigo (tonto e inteligente) | `scripts/enemigo_tonto.gd` y `scripts/enemigo_inteligente.gd` |
| **Que hereden de una clase comun con `class_name`** | `scripts/enemigo.gd` → `class_name Enemigo` |
| Condicion de victoria: llegar de un punto A a un punto B | la letra `P` y la letra `M` del mapa → `scripts/meta.gd` |
| Pasar al nivel siguiente | boton "Siguiente nivel" → `Game.siguiente_nivel()` en `scripts/game.gd` |
| Carpetas ordenadas | `escenas/`, `scripts/`, `scripts/estados/`, `assets/` |
| Nombres como corresponde | ver la seccion de convenciones mas abajo |

---

## La herencia de los enemigos (el punto principal)

Antes los dos tipos de enemigo eran **un solo script** con una variable
`tipo` que valia 0 o 1, y en todos lados habia que preguntar
`if tipo == 0 ... else ...`.

Ahora hay una clase comun y dos clases que heredan de ella:

```
Enemigo                  scripts/enemigo.gd        class_name Enemigo
  ├── EnemigoTonto       scripts/enemigo_tonto.gd         extends Enemigo
  └── EnemigoInteligente scripts/enemigo_inteligente.gd   extends Enemigo
```

Los dos son zombies: **muerden igual, se mueven igual, tienen vida y se
mueren igual**. Todo eso esta escrito UNA sola vez, en la clase comun.

**Lo unico que los hace tonto o inteligente es como deciden hacia donde
caminar.** Esas son las tres funciones que cada hijo vuelve a escribir:

| Funcion | EnemigoTonto | EnemigoInteligente |
|---|---|---|
| `como_me_llamo()` | `"Zombie tonto"` | `"Zombie listo"` |
| `hacia_donde_persigo()` | derecho al jugador, siempre | le pide un camino al nivel y lo sigue esquivando las paredes |
| `velocidad_de_ahora()` | siempre la misma | acelera cuando te tiene a la vista |

Fijate que **`enemigo_tonto.gd` casi no tiene codigo**: son treinta lineas y
la mayoria son comentarios. Eso es justamente lo que se gana con la herencia.

### Como esquiva el zombie inteligente

Uso **`AStarGrid2D`**, que ya viene con Godot y sirve justo para esto: le
decis de que tamanio es la grilla y cuales celdas estan tapadas, y te
devuelve la lista de puntos por los que hay que pasar. **No programe el
algoritmo de A\*, solo lo use.**

Como el mapa ya es una grilla de letras, armarlo fue directo
(`_preparar_el_buscador_de_caminos()` en `scripts/nivel.gd`): una celda de
la grilla por cada letra del mapa, y marco como tapadas las paredes (`#`) y
los muebles (`c`, `m`, `f`).

> **El error que me costo encontrar:** `update()` **borra** las celdas que
> marcaste como tapadas. Si marcas las paredes y despues llamas a
> `update()`, se pierden todas y el zombie atraviesa el mapa como si nada.
> Hay que llamar a `update()` PRIMERO y marcar las paredes despues.

Despues, el zombie le pide el camino al nivel y lo va siguiendo punto por
punto (`_pedir_un_camino_nuevo()` y `hacia_donde_persigo()` en
`scripts/enemigo_inteligente.gd`). Dos detalles:

- **Si te tiene a la vista no usa el camino, va derecho.** Es lo que haria
  cualquiera, y ademas seguir los puntos de la grilla cuando te tiene al
  lado lo hacia caminar en zigzag.
- **Recalcula el camino cada 0,35 segundos**, no todos los frames. Es la
  cuenta mas cara que hace y total el jugador tampoco se teletransporta.

### Por que conviene la herencia

El mejor ejemplo esta en **`scripts/estados/enemigo_perseguir.gd`**: ese
archivo lo usan los dos zombies y **no pregunta en ningun momento de que
tipo es**:

```gdscript
entidad.mirar_al_jugador()
entidad.mover(entidad.hacia_donde_persigo(), delta)

if entidad.puede_atacar() and entidad.puedo_atacar_al_jugador():
    cambiar_a("Atacar")
```

Y en `scripts/estados/maquina_de_estados.gd` el `class_name` se usa asi:

```gdscript
if duenio is Enemigo:
    texto = duenio.como_me_llamo() + ": " + texto
```

Con un solo `is Enemigo` agarro a los dos tipos de una vez. Si manianna
agrego un tercer enemigo, no toco ninguno de estos dos archivos: creo un
archivo nuevo con `extends Enemigo` y listo.

### Como se distinguen mirando la pantalla

- El **tonto** es el zombie verde de siempre.
- El **inteligente** es el mismo sprite pero **rojizo y un poco mas grande**
  (el color se lo pongo con `color_del_sprite` desde la escena), tiene mas
  vida y muerde mas fuerte.

Jugando la diferencia se nota enseguida: ponete atras de una pared. El tonto
se queda ahi apretado empujandola; el inteligente da la vuelta y aparece por
el otro lado.

---

## La maquina de estados

Cada personaje tiene un nodo `MaquinaDeEstados` y cada estado es un nodo
hijo. El primer hijo es el estado con el que arranca.

```
Jugador                        EnemigoTonto           EnemigoInteligente
└── MaquinaDeEstados           └── MaquinaDeEstados   └── MaquinaDeEstados
    ├── Quieto                     ├── Quieto             ├── Quieto
    ├── Caminar                    ├── Perseguir          ├── Perseguir
    ├── Esquivar                   ├── Atacar             ├── Atacar
    ├── Recargar                   └── Muerto             └── Muerto
    └── Muerto
```

Todos los estados heredan de `Estado` (`scripts/estados/estado.gd`, tambien
con `class_name`) y sobreescriben `entrar()`, `salir()` y
`actualizar(delta)`.

Los **cuatro estados de los enemigos son exactamente los mismos archivos**
para los dos zombies. No tuve que duplicar ninguno.

Los dos arrancan en `Quieto` y se despiertan cuando el jugador se les acerca
o cuando lo ven. Sin eso se venian todos juntos desde la otra punta del mapa
y era imposible.

---

## Los niveles y la condicion de victoria

Los mapas los escribo como texto en `scripts/nivel.gd`. Cada letra es una
celda de 64x64 pixeles:

| Letra | Que es |
|---|---|
| `#` | pared |
| `.` | piso |
| `P` | donde arranca el jugador (**el punto A**) |
| `M` | donde esta la meta (**el punto B**) |
| `Z` | zombie tonto |
| `I` | zombie inteligente |
| `h` | botiquin |
| `a` | cajon de municion |
| `c` `m` `f` | cajon, mesa y sofa (frenan el paso) |

> Ojo con las mayusculas: la **`M`** grande es la meta y la **`m`** chica es
> una mesa.

La misma grilla de letras la uso para dos cosas: para dibujar el nivel y
para armar el buscador de caminos del zombie inteligente.

**La condicion de victoria es llegar a la meta**, no matar a todos. La meta
es una **puerta** en la pared que esta pegada a la `M` (`scripts/meta.gd`);
cuando el jugador la toca se abre, avisa a `Game.ganar_nivel()`, se pausa
el juego y aparece la pantalla de "NIVEL COMPLETADO" con el boton para pasar
al siguiente. Arriba a la derecha el HUD dice a cuantos metros esta, porque
el mapa es mas grande que la pantalla.

### La puerta de salida

Los mapas de texto no los toque: la `M` sigue en el mismo lugar. Lo que hace
`_buscar_donde_va_la_puerta()` en `scripts/nivel.gd` es mirar los cuatro
costados de la `M` y elegir la pared que este en el **borde** del mapa (asi
la puerta da para afuera y no a otra pieza). En esa celda no pongo pared,
pongo piso, y la partida pone la puerta ahi.

- El dibujo es `tile_442.png` del pack de Kenney, una tabla de madera con
  marco, que es lo que usa Kenney de puerta en sus ejemplos.
- La puerta tiene una `Tapa` (un `StaticBody2D` en la capa del mundo) para
  que no se pueda salir del mapa por el agujero ni se escapen las balas.
- En el mapa de texto esa celda sigue siendo `#`, asi que para el buscador
  de caminos sigue tapada y los zombies no intentan salir por ahi.
- Cuando la tocas se abre girando desde la bisagra. Como `ganar_nivel()`
  pausa el juego, el tween de la puerta usa `TWEEN_PAUSE_PROCESS` para
  seguir andando en pausa.
- En los dos niveles la `M` esta pegada a la pared de la derecha, asi que
  las dos puertas quedan ahi.

- **Nivel 1:** bastante abierto, 5 zombies tontos y 2 inteligentes. El
  jugador arranca arriba a la izquierda y la meta esta abajo a la derecha,
  hay que cruzar todo el mapa.
- **Nivel 2:** mas cerrado, con pasillos y piezas, 5 tontos y 3
  inteligentes. Arranca arriba a la izquierda y la meta esta arriba a la
  derecha, pero las paredes obligan a bajar y dar toda la vuelta. Es el
  nivel donde mas se nota la diferencia entre los dos zombies, porque hay
  muchas esquinas.

Cuando terminas el nivel 2 aparece "GANASTE EL JUEGO". El puntaje se va
sumando entre los dos niveles.

---

## Fundido entre escenas

Todos los cambios de escena pasan por `_ir_a()` en `scripts/game.gd` (menu,
partida, siguiente nivel, reintentar), asi que el fundido lo hice una sola
vez ahi:

1. Pongo una cortina negra de a poco (un `ColorRect` adentro de un
   `CanvasLayer` con layer 100, para que tape incluso el HUD).
2. Cuando esta todo negro, despauso y cambio la escena.
3. Saco la cortina de a poco.

La cortina la creo por codigo en `_crear_la_cortina()` porque `Game` es un
Autoload que es solo un script, no tiene escena. Como `Game` tiene
`process_mode` en ALWAYS, el tween anda aunque el juego este pausado (por
ejemplo en la pantalla de "PERDISTE"). Mientras se oscurece la cortina
bloquea el mouse, y si `_ir_a()` se llama dos veces seguidas la segunda se
ignora. El juego tambien arranca con la cortina puesta, asi el menu
aparece de a poco.

---

## Particulas del disparo

Cada vez que el jugador dispara crea `escenas/particulas_disparo.tscn` en la
punta del canio. Tiene tres `CPUParticles2D`:

| Nodo | Que es |
|---|---|
| `Fogonazo` | el fuego de la punta, dura 0,06 segundos |
| `Chispas` | puntitos amarillos que salen para adelante |
| `Humo` | un poco de humo gris que queda flotando |

Las texturas son del **Particle Pack de Kenney** (`assets/particulas/`), son
blancas y el color se lo doy en cada nodo. Se crea una escena nueva por cada
tiro (igual que la bala) porque la ametralladora tira cada 0,08 segundos y
si fueran siempre las mismas particulas cada tiro cortaria el humo del
anterior. Cuando termina el humo, la escena se borra sola.

La mancha de sangre de cuando muere un zombie la deje como estaba.

---

## Tabla de mejores puntajes

Se guardan los **10 mejores puntajes** en un archivo, asi quedan aunque
cierres el juego. Cada uno tiene los puntos, hasta que nivel llegaste (o
"Completo" si ganaste el juego) y la fecha.

- **Cuando se anota:** cuando perdes, o cuando ganas el ultimo nivel. Si
  salis al menu desde la pausa no se anota, porque la partida no termino.
  Las partidas de 0 puntos tampoco.
- **Donde se ve:** al costado del menu principal y al lado del cartel de
  "PERDISTE" o "GANASTE EL JUEGO".
  La partida que recien terminaste aparece en naranja y el cartel te dice en
  que puesto quedaste.
- **Donde se guarda:** `user://puntajes.json`. `user://` es la carpeta que
  Godot le da a cada juego para guardar cosas; en Windows es
  `%APPDATA%\Godot\app_userdata\Zona Cero - Parcial 2\`. Lo guardo como JSON
  porque es texto y se puede abrir con el bloc de notas para ver que se
  guardo bien. Si el archivo esta roto, el juego arranca con la tabla vacia
  en vez de romperse.

El codigo esta en `anotar_puntaje()`, `guardar_puntajes()` y
`cargar_puntajes()` de `scripts/game.gd`. La tabla que se ve en pantalla es
`escenas/tabla_puntajes.tscn`, una sola escena que uso en el menu y en el
HUD.

---

## Estructura de carpetas

```
project.godot
icon.svg
LEEME.md

assets/                      imagenes del pack de Kenney y sonidos
  License.txt                la licencia del pack
  tile_442.png               la puerta de salida
  particulas/                texturas del Particle Pack de Kenney (con su License.txt)
  sonidos/                   los .wav (los genere yo, el pack no trae audio)

escenas/
  menu_principal.tscn        el menu: Nivel 1, Nivel 2 y Salir (escena principal)
  partida.tscn               la escena del juego
  hud.tscn                   los carteles y las pantallas de ganar/perder/pausa
  jugador.tscn
  enemigo_tonto.tscn
  enemigo_inteligente.tscn
  bala.tscn
  item.tscn                  botiquin / municion
  meta.tscn                  la puerta de salida
  particulas_disparo.tscn    fogonazo, chispas y humo de cada tiro
  tabla_puntajes.tscn        la tabla de mejores puntajes (menu y HUD)

scripts/
  game.gd                    AUTOLOAD: nivel, puntaje, sonido, fundido y tabla
  menu_principal.gd
  partida.gd
  hud.gd
  nivel.gd                   los dos mapas, como se arma el nivel y el A*
  jugador.gd
  enemigo.gd                 >>> LA CLASE COMUN (class_name Enemigo)
  enemigo_tonto.gd           >>> extends Enemigo
  enemigo_inteligente.gd     >>> extends Enemigo
  bala.gd
  item.gd
  meta.gd
  particulas_disparo.gd
  tabla_puntajes.gd
  estados/
    estado.gd                clase base de los estados (class_name Estado)
    maquina_de_estados.gd    class_name MaquinaDeEstados
    jugador_quieto.gd        jugador_caminar.gd    jugador_esquivar.gd
    jugador_recargar.gd      jugador_muerto.gd
    enemigo_quieto.gd        enemigo_perseguir.gd
    enemigo_atacar.gd        enemigo_muerto.gd
```

`game.gd` esta puesto como **Autoload** en Proyecto → Configuracion del
proyecto → Autoload, con el nombre `Game`. Lo necesito porque el nivel, el
puntaje y la tabla de puntajes tienen que sobrevivir al cambio de escena: si eso
estuviera en la escena de la partida, al pasar de nivel se perderia todo.

---

## Convenciones de nombres que use

| Cosa | Convencion | Ejemplo |
|---|---|---|
| Archivos (`.gd` y `.tscn`) | `snake_case` | `enemigo_inteligente.gd` |
| Clases (`class_name`) | `PascalCase` | `EnemigoInteligente` |
| Nodos de las escenas | `PascalCase` | `MaquinaDeEstados`, `BarraVida` |
| Variables y funciones | `snake_case` | `vida_maxima`, `hacia_donde_persigo()` |
| Constantes | `MAYUSCULAS` | `TAMANIO_CELDA`, `MAPA_1` |
| Funciones y variables internas | `_` adelante | `_leer_el_mapa()`, `_latido` |

Todo en castellano y sin acentos, para que no se mezcle con el ingles de
Godot (`velocity`, `move_and_slide`) y se note cual es codigo mio.

---

## Capas de colision

Estan con nombre en Proyecto → Configuracion del proyecto → Capas:

| Capa | Nombre | Quien esta |
|---|---|---|
| 1 | mundo | paredes y muebles |
| 2 | jugador | el jugador |
| 3 | enemigos | los dos zombies |
| 4 | balas | las balas |
| 5 | items | botiquines, municion y la meta |

Los enemigos tienen la mascara 1 + 3, o sea que chocan con las paredes **y
entre ellos**. Al principio solo chocaban con las paredes y se amontonaban
todos en el mismo lugar, parecian uno solo.

---

## Que cambie respecto del ejercicio del 16/10

| Antes (16/10) | Ahora |
|---|---|
| Un solo script de enemigo con una variable `tipo` (0 o 1) | Clase comun `Enemigo` con `class_name` + dos hijos |
| Los dos enemigos se diferenciaban en el arma (uno pegaba, otro disparaba) | Los dos son zombies y muerden igual: la diferencia es **como te encuentran** |
| Ningun enemigo esquivaba nada | El inteligente usa `AStarGrid2D` y rodea las paredes y los muebles |
| Oleadas infinitas de enemigos (`generador.gd`) | Enemigos puestos en el mapa, no hay generador |
| Se jugaba hasta morir, no se podia ganar | Condicion de victoria: llegar a la meta |
| Una sola escena (`principal.tscn`) | Menu principal y partida |
| Un solo mapa | Dos niveles, con boton para pasar al siguiente |
| Sin sonido | Nueve efectos de sonido |
| Sin menu | Menu (Nivel 1, Nivel 2 y Salir) y pantalla de pausa |

Lo que **no** cambie porque ya estaba y andaba: la maquina de estados, el
jugador con las tres armas y el esquive, la bala, los botiquines, y los
mapas como texto.

---

## Los sonidos

El pack de Kenney solo trae imagenes, asi que los nueve efectos
(`assets/sonidos/`) los genere con un script aparte: son ruido y ondas
simples con una envolvente que los apaga. Son `.wav` cortos.

Los hago sonar desde `Game.sonar("disparo")`. Al principio ponia un nodo
`AudioStreamPlayer` dentro de cada escena, pero el enemigo hace
`queue_free()` al morir y se borraba junto con el sonido, entonces el
quejido se cortaba enseguida. Haciendolo desde el Autoload el sonido no
depende de quien lo pidio.

El volumen general esta en `Game.volumen` (arranca en 0.8) y
`aplicar_volumen()` lo pone en el bus Master con
`AudioServer.set_bus_volume_db()`.
