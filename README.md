# BACKROOMS - Mundo libre v4 (Godot 4.3)

Mundo infinito en primera persona, generado por trozos mientras caminas. Sin objetivo: sobrevive y explora.

## Zonas
Lobby, Oficinas (escritorios), Banos (cubiculos, lavabos, espejos), Piscinas (inundadas, te ralentizan) y Zona oscura.

## Estadisticas
- Salud y Cordura (arriba a la izquierda). Bateria de la linterna y reloj (arriba a la derecha).
- La cordura baja en la zona oscura, cerca de monstruos y al mirar al Smiler. Con poca cordura hay susurros,
  latidos, luces que fallan y alucinaciones.

## Monstruos
- Acechador: oye tus pasos y te ve. Patrulla, investiga ruidos y te persigue. La linterna lo ralentiza.
- Sabueso: rapido, caza sobre todo por el sonido (aparece tras ~90 s).
- Smiler: sonrisa brillante en la oscuridad. Se queda quieto si no lo miras; si lo miras fijo se acerca y te quita cordura.
- Las bengalas los ralentizan. El hacha los derriba (3 golpes al Acechador, 2 al Sabueso) y vuelven despues.

## Inventario (4 espacios)
1 Hacha, 2 Agua de Almendra (cura salud y cordura), 3 Pilas (recargan linterna), 4 Bengala.

## Controles
- Celular: joystick a la izquierda, mirar a la derecha, botones CORRER / LUZ / USAR / AGACHAR, toca un espacio del inventario para elegirlo.
- PC: WASD, raton, Shift correr, C agachar, F linterna, 1-4 elegir, E/Espacio/clic usar.

## Modelos y texturas propias
- Acechador: models/entity.glb (mirando a +Z). Texturas: textures/zone0_wall.png, zone0_floor.png, zone0_ceiling.png (igual zone1..zone4).

## APK
Cada push a main compila el APK con GitHub Actions (Actions -> Artifacts).
