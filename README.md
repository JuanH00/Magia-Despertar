# Magia: Despertar

Prototipo 3D low poly jugable de Sam Heart en Godot 4.7.2.

## Incluye

- Sam Heart procedural: cabello castaño, ojos verdes, túnica lila, botas, libro y varita.
- Movimiento en tercera persona, salto, carrera, cámara orbital y animación procedural.
- Seis elementos: fuego, agua, aire, tierra, luz y oscuridad.
- Variantes avanzadas: hielo y Explosión de Fuego: Entei.
- Arena de entrenamiento con objetivos, vida, maná, HUD y efectos.

## Controles

- WASD: mover
- Shift: correr
- Espacio: saltar
- Ratón: cámara
- Clic izquierdo o Q: lanzar magia
- Clic derecho: hielo con Agua o Entei con Fuego
- Teclas 1 a 6 o rueda: elegir elemento
- Escape: liberar el ratón

## Archivos principales

- scenes/main.tscn: escena activa.
- scripts/main.gd: arena, HUD y coordinación de hechizos.
- scripts/sam_heart.gd: personaje, modelo, cámara y controles.
- scripts/spell_projectile.gd: proyectiles elementales.
- scripts/training_target.gd: objetivos de práctica.
- tests/smoke_test.gd: prueba de carga y rutas de magia.

La escena vieja main.tscn y el controlador anterior sam.gd se conservan para referencia. La escena activa es scenes/main.tscn.
