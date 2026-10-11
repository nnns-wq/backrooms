# BACKROOMS - 3 niveles (Godot 4.3)

Juego 3D en primera persona hecho en Godot (no HTML). Todo se genera por codigo.

## Niveles
- Nivel 0 - El Lobby: pasillos amarillos, alfombra, luces fluorescentes.
- Nivel 1 - Zona Habitable: concreto oscuro, mas grande, ruidos de maquinas.
- Nivel 2 - Tuneles de servicio: calor, luz naranja, la entidad es mas rapida y aparece antes.

## Objetivo
Recoge las botellas de Agua de Almendra y entra a la grieta azul para pasar al siguiente nivel.
La entidad te persigue. La linterna (boton LUZ o tecla F) la ralentiza si la apuntas.
Las pilas amarillas recargan la linterna.

## Controles
- Celular: mitad izquierda = joystick (al maximo corres), mitad derecha = mirar, boton LUZ arriba a la derecha.
- PC: WASD/flechas, raton, Shift correr, F linterna.

## Modelos y texturas propias
- Entidad: models/entity.glb (debe mirar hacia +Z).
- Texturas por nivel en textures/: level0_wall.png, level0_floor.png, level0_ceiling.png (igual para level1, level2).

## APK sin Godot (GitHub Actions)
1. Sube a un repo de GitHub los archivos de la raiz: project.godot, main.tscn, main.gd,
   export_presets.cfg, icon.svg, .gitignore.
2. Crea el archivo .github/workflows/build.yml con el contenido de build.yml.
3. Pestana Actions -> "Build Android APK" -> Run workflow (o se ejecuta solo al subir).
4. Cuando termine (verde), abre la ejecucion y descarga backrooms-apk en Artifacts. Descomprime e instala el APK.
