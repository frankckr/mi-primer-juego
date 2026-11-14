# Demo Metroidvania

Demo jugable de un metroidvania 2D con toques de RPG, hecha en **Godot 4.7** con GDScript. Se juega de principio a fin en unos 5 a 10 minutos.

## De qué trata

El Guardián Astral selló el cielo y robó las estrellas. Una viajera despierta en un viejo observatorio sin recordar cómo llegó ahí. El Oráculo lunar del pueblo le cuenta lo ocurrido y le señala el camino: en las ruinas hay un santuario cuyo poder, los Nodos de Relámpago, es lo único capaz de atravesar el escudo del Guardián.

La demo cubre ese primer tramo de la historia: despertar, aprender a moverse y pelear, conocer a los habitantes del pueblo, explorar las ruinas para conseguir la habilidad y enfrentar al jefe.

## Cómo es el juego

El nivel es un solo mapa que se recorre de izquierda a derecha en cuatro zonas:

| Zona | Qué pasa |
| --- | --- |
| Observatorio | La protagonista despierta. Runas flotantes enseñan los controles y hay un primer enemigo para practicar. |
| Pueblo | Tres personajes: el Oráculo lunar (historia), el Caracol mercader (tienda) y el Hongo farolillo (consejos y una poción). Hay una hoguera para guardar. |
| Ruinas | Zona de exploración con plataformas, enemigos, cristales, un cofre con un amuleto y el santuario que da los Nodos de Relámpago. |
| Arena | Hoguera, pelea contra el Guardián Astral y la luz final que termina la demo. |

### Mecánicas

- **Combate cuerpo a cuerpo** con una espada de energía. Cada golpe carga la barra de energía.
- **Parry**: atacar justo antes de recibir un golpe lo anula, aturde al enemigo y da energía extra.
- **Rodar** para esquivar, con un instante de invulnerabilidad.
- **Curación** de tres formas: gastando energía, con cargas (se recargan al descansar) o con pociones.
- **Nodos de Relámpago**: se colocan hasta 3 nodos en el aire con el ratón; el Impulso Relámpago lanza a la protagonista de nodo en nodo. Sirve para alcanzar lugares altos y es la única forma de romper el escudo del jefe.
- **Progresión**: los enemigos dan experiencia y cristales. Al subir de nivel aumenta la vida máxima. Los cristales se gastan en la tienda.
- **Amuleto del Eco**: equipable desde el inventario; cada parry deja un nodo donde estaba el enemigo.
- **Hogueras**: recuperan vida y cargas, guardan la partida y marcan el punto de reaparición.

### Enemigos

- **Escarabajo**: patrulla el suelo y embiste. Avisa con un destello antes de atacar.
- **Polilla**: vuela y se lanza en picada hacia donde estaba la jugadora.
- **Guardián Astral (jefe)**: protegido por un escudo, ataca con manotazos que caen desde arriba. Hay que romperle el escudo con el Impulso Relámpago y golpearlo mientras está aturdido, antes de que el escudo regrese.

## Controles

| Tecla | Acción |
| --- | --- |
| A / D o flechas | Moverse |
| Espacio | Saltar (mantener para saltar más alto) |
| J | Atacar / parry |
| K | Rodar |
| Q | Curar con energía |
| C | Usar una carga de curación |
| 1 | Usar una poción |
| L (mantener) + ratón | Apuntar y colocar un nodo |
| W + Espacio | Impulso Relámpago |
| E | Hablar, usar y avanzar diálogos |
| I | Inventario |
| M | Mapa |
| Esc | Pausa |

## Cómo abrirlo

1. Instalar [Godot 4.7](https://godotengine.org/download).
2. En Godot: **Importar** y elegir el archivo `project.godot` de la carpeta del juego.
3. Pulsar **F5** para jugar.

## Estructura del proyecto

```
project.godot        configuración (autoloads y escena principal)
escenas/mundo.tscn   el nivel completo con las 4 zonas
personajes/          hojas de sprites en pixel art de 32x32
script/
  juego.gd           datos de la partida, teclas y guardado (autoload)
  interfaz.gd        HUD, diálogos y menús (autoload)
  jugador.gd         la protagonista
  enemigo.gd         escarabajo y polilla
  jefe.gd            Guardián Astral
  cosa.gd            NPCs, tienda, hogueras, cofre, objetos, runas y zonas
  decorado.gd        fondos y detalles dibujados por código
```

## Equipo

Proyecto hecho por un equipo de tres personas, divididas en programación, diseño e historia.
