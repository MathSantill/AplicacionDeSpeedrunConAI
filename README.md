# 🚀 AplicacionDeSpeedrunConAI

<img width="950" height="537" alt="Screenshot 2025-07-26 194201" src="https://github.com/user-attachments/assets/d5b357c9-9f42-4135-92ad-3ee9729bc896" />

[![Demo del proyecto](https://img.youtube.com/vi/BMqF3_rKCw8/0.jpg)](https://www.youtube.com/watch?v=BMqF3_rKCw8)


Proyecto de speedrun automatizado con IA integrada en Godot Engine usando aprendizaje por refuerzo (RL).

INTRODUCCIÓN
PLANTEAMIENTO DEL PROBLEMA

Los speedruns en videojuegos del género plataformero requieren dominar mecánicas complejas como saltos precisos, sincronización de movimientos y adaptación a obstáculos dinámicos mediante estrategias optimizadas que minimicen el tiempo de completado. Sin embargo, la ejecución manual de estas estrategias por jugadores humanos enfrenta limitaciones significativas:
Curva de aprendizaje empinada: La maestría en speedruns demanda horas de práctica para internalizar patrones y reducir errores.
Incapacidad de adaptación en entornos dinámicos: Los obstáculos con comportamientos no deterministas, como enemigos con trayectorias aleatorias, dificultan la optimización manual de rutas.
Falta de herramientas educativas integradas: Existe una brecha en recursos pedagógicos que combinen el desarrollo de videojuegos con inteligencia artificial (IA) para enseñar aprendizaje por refuerzo (RL) de manera práctica y motivadora.
Por otro lado, los algoritmos clásicos de aprendizaje por refuerzo (RL) presentan desafíos cuando se aplican a entornos de videojuegos:
Espacios de acción continuos: Mecánicas como la intensidad variable de los saltos requieren políticas adaptativas.
Retraso en las recompensas: Las funciones mal diseñadas pueden incentivar soluciones miopes o ineficientes. 
Falta de generalización: Los agentes entrenados en niveles específicos tienden a sobreajustarse, fallando ante cambios mínimos en las condiciones del entorno.
Ante estos problemas, el presente proyecto propone desarrollar un sistema integral que combine:
Un entorno personalizado en Godot Engine, diseñado para desafiar y medir el progreso del agente.
Un sistema de recompensas densas y penalizaciones que guíen al agente hacia estrategias óptimas.
Un pipeline de entrenamiento eficiente en tiempo real que permita la adaptabilidad y el aprendizaje autónomo.

JUSTIFICACIÓN
La inteligencia artificial, y particularmente el aprendizaje por refuerzo, ha demostrado un enorme potencial en la simulación de comportamientos complejos dentro de entornos controlados. No obstante, la mayoría de estos desarrollos se mantienen en entornos cerrados o de difícil acceso educativo.
Este proyecto busca fomentar el aprendizaje práctico de la IA aplicada a los videojuegos, diseñando un entorno accesible donde una IA aprenda a completar un videojuego plataformero.
Con ello se pretende:
Demostrar el potencial educativo del RL para enseñar conceptos de programación y optimización.
Promover la innovación en entornos interactivos que combinen entretenimiento y ciencia de datos.
Reducir la brecha digital, acercando herramientas de inteligencia artificial a comunidades estudiantiles y desarrolladores emergentes.

OBJETIVOS
Objetivo General
Desarrollar un sistema autónomo que, mediante la integración de un entorno de videojuego en Godot Engine y un agente basado en aprendizaje por refuerzo (PPO), optimice estrategias de speedrun y demuestre capacidades de generalización ante entornos no vistos.
Objetivos Específicos
Diseñar un entorno plataformero 2D con mecánicas reproducibles para el entrenamiento del agente.
Implementar una comunicación bidireccional entre Godot y Python mediante sockets TCP/IP.
Entrenar un agente PPO con Stable Baselines3 para optimizar la velocidad de completado de los niveles.
Evaluar el rendimiento del agente frente a jugadores humanos y agentes aleatorios.
Documentar el proceso técnico y metodológico para su replicación en entornos educativos.

METODOLOGIA
La metodología combina investigación teórica y desarrollo técnico experimental, dividida en fases.
Fase teórica
Revisión bibliográfica de RL aplicado a videojuegos (DQN en Atari, PPO en Unity ML-Agents).
Estudio de técnicas de speedrun en juegos clásicos (Super Mario Bros, Celeste) para identificar mecánicas clave (saltos en pared, cadenas de dash).
Análisis de funciones de recompensa utilizadas en optimización temporal (reward shaping, discount factors).
Fase técnica
Selección de herramientas:
Motor de juego: Godot Engine 4.2 por su sistema modular, físicas personalizables y soporte para GDScript.
Framework de RL: Stable Baselines3 (PPO), equilibrando facilidad de integración y rendimiento.
Protocolo de comunicación: Socket TCP/IP, con intercambio de variables (posición, velocidad, estado del dash, datos de plataformas móviles).
Métricas de evaluación:
Tiempo promedio por nivel.
Eficiencia de movimientos (acciones redundantes penalizadas).
Tasa de generalización (% de éxito en niveles no vistos).

## 🔧 Instalación y Configuración

### Prerrequisitos
| Herramienta | Versión mínima | Enlace de descarga |
|-------------|----------------|-------------------|
| Godot Engine | 4.2 | [Descargar](https://godotengine.org/download) |
| Python | 3.10 | [Instalador](https://www.python.org/downloads/) |
| Git | 2.30+ | [Instalador](https://git-scm.com/downloads) |
| VSCode (Opcional) | 1.75+ | [Descargar](https://code.visualstudio.com/) |


### Arquitectura Implementada
Visión General
Estamos implementando una arquitectura cliente-servidor con separación estricta de responsabilidades, diseñada para:

Aislar el motor del juego (Godot) de la lógica de IA (Python)

Permitir entrenamiento offline de modelos RL

Facilitar la integración continua y despliegue

Mantener alta performance en tiempo real

Capas de la Arquitectura (en orden de implementación)
1. Capa de Presentación (Godot Engine)
Aspecto	Detalle
Responsabilidad	Renderizado gráfico, interfaz de usuario y física del juego
Tecnologías	Godot Engine 4.2+, GDScript (81.3%), C# (9.9%)
Ubicación	Sprites/, Levels/, Scripts/Player/
Estado:	 Completado (100%)

2. Capa de Control de Juego
Aspecto	Detalle
Responsabilidad	Gestión de estados del juego, mecánicas y reglas
Tecnologías	GDScript, sistema de nodos de Godot
Ubicación	Scripts/Game/
Componentes clave	game_manager.gd, level_loader.gd
Estado: Completado (100%)

3. Capa de Comunicación
Aspecto	Detalle
Responsabilidad	Intercambio de datos entre juego y servidor de IA
Tecnologías	API REST (FastAPI), JSON over HTTP
Implementación	Godot: Scripts/AIController/agent.gd, Python: api.py
Protocolo	HTTP POST con estado del juego → Respuesta JSON con acción
Estado: En desarrollo (85%)

4. Capa de Lógica de IA
Aspecto	Detalle
Responsabilidad	Procesamiento de estados y generación de acciones óptimas
Tecnologías	Python 3.10+, Stable-Baselines3 (PPO/DQN), PyTorch
Ubicación	api.py, stable_baselines3_example.py
Estado: En desarrollo (70%)

5. Capa de Persistencia
Aspecto	Detalle
Responsabilidad	Almacenamiento de modelos entrenados y datos de sesiones
Tecnologías	Sistema de archivos local, formato .zip para modelos
Implementación	Directorio models/, training_logs/
Estado: Pendiente (0%)

6. Capa de Entrenamiento (Offline)
Aspecto	Detalle
Responsabilidad	Entrenamiento y optimización de modelos RL
Tecnologías	Python scripts, GitHub Actions (CI/CD)
Ubicación	.github/workflows/train.yml
Estado: Pendiente (30%)
Flujo Completo de Datos

Ciclo de Vida de una Acción
Captura: Godot recolecta estado del juego (60 FPS)
Preparación: Datos se estructuran en JSON
Transmisión: HTTP POST a localhost:5000/action

Procesamiento:
Servidor recibe estado
Modelo RL calcula mejor acción

Respuesta:
Acción serializada en JSON
Enviada de vuelta a Godot
Ejecución: Godot aplica acción en próximo frame
Retroalimentación: Resultado usado para próximo ciclo
Evolución de la Implementación
Fase Inicial (Completada)
Configuración de Godot Engine
Diseño básico de niveles
Movimiento básico del personaje
Sistema de colisiones
Fase Actual (Implementando)
Integración API REST
Comunicación Godot-Python
Modelo RL básico (PPO)
Sistema de acciones parametrizadas
Gestión de estados del juego
Próxima Fase
Entrenamiento avanzado con recompensas
Optimización de comunicación
Sistema de persistencia para modelos
Integración CI/CD con GitHub Actions
Sistema de logging y métricas
Desarrollo paralelo de componentes
Actualizaciones independientes
Escalabilidad para nuevos algoritmos RL
Portabilidad entre proyectos
Monitoreo granular del rendimiento

### 🔄 Configuración del entorno virtual de Python
```bash
# Clonar repositorio
git clone https://github.com/MathSantill/AplicacionDeSpeedrunConAI.git
cd AplicacionDeSpeedrunConAI

# Crear y activar entorno virtual (Windows)
python -m venv .venv
.venv\Scripts\activate

# Crear y activar entorno virtual (Linux/macOS)
python -m venv .venv
source .venv/bin/activate

Se recomienda estructurar los datos en formato JSON para facilidad de parsing y flexibilidad.

GitHub + GitHub Actions: para control de versiones, integración continua y automatización del despliegue.
