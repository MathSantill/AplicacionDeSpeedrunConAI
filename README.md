# AplicacionDeSpeedrunConAI

Infraestructura del proyecto

Motor del videojuego
Utiliza Godot Engine 4.x, preferiblemente la versión 4.2 o superior.

Lenguaje de programación recomendado:
GDScript, aunque también puedes usar C# si deseas integraciones más complejas. GDScript es más directo y nativo en el entorno Godot.

Aprendizaje por refuerzo (RL)
Lenguaje de implementación: Python 3.10 o superior.

Frameworks sugeridos para RL
Stable-Baselines3 para implementar algoritmos como PPO (Proximal Policy Optimization) y DQN (Deep Q-Network).

Comunicación entre Godot y Python (IA)
Implementa una API REST en Python utilizando Flask o FastAPI.

Desde Godot, puedes usar la clase HTTPRequest para enviar datos del estado del juego (posición, velocidad, colisiones, eventos) al servidor Python.

El servidor responderá con la acción que el agente debe realizar.

Se recomienda estructurar los datos en formato JSON para facilidad de parsing y flexibilidad.


GitHub + GitHub Actions: para control de versiones, integración continua y automatización del despliegue.

Configuración del entorno local
Herramientas obligatorias a instalar en tu máquina local

Godot Engine 4.x
Python 3.10 o superior
Git
Cuenta en GitHub y Git configurado en tu máquina
Editor de código recomendado: Visual Studio Code o PyCharm
Extensiones recomendadas para Visual Studio Code

Python: para soporte de sintaxis, ejecución de scripts y depuración.

GitLens: para gestión avanzada de control de versiones dentro del editor.

REST Client: para probar manualmente los endpoints de la API REST entre Godot y Python.
