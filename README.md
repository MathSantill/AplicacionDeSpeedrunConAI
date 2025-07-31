# 🚀 AplicacionDeSpeedrunConAI

Proyecto de speedrun automatizado con IA integrada en Godot Engine usando aprendizaje por refuerzo (RL).

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
