# Informe de Diferencias: dotSloth vs CodelyTV/dotly

**Fecha:** 2026-07-03  
**Autor:** Hermes Agent  
**Repositorio upstream:** https://github.com/CodelyTV/dotly

---

## Resumen Ejecutivo

dotSloth es un fork de CodelyTV/dotly con **significativas divergencias**. El upstream tiene una estructura más simplificada, mientras que dotSloth ha acumulado muchas features adicionales (home automation, PV systems, etc.) que hacen la sincronización directa imposible para la mayoría de los cambios.

### Diferencias Clave

| Área | dotSloth | dotly upstream |
|------|----------|----------------|
| **Estructura** | scripts/core/src/ | scripts/core/ |
| **bin/dot** | 196 líneas, multi-path | 79 líneas, simple |
| **restorer** | 527 líneas, completo | 365 líneas, básico |
| **package managers** | 12+ managers | 6-8 managers |
| **home automation** | Sí | No |
| **PV systems** | Sí | No |
| **Tests** | No | No |

---

## Cambios Upstream que Merecen Incorporarse

### 1. **Corrección de bugs upstream** (Prioridad Alta)
- Verificar si upstream tiene fixes que no están en dotSloth
- Especialmente en scripts core y package managers

### 2. **Simplificación de bin/dot** (Prioridad Media)
- Upstream tiene un `bin/dot` más simple (79 líneas)
- Menos complejidad en detección de paths
- **Posible solución:** Mantener dotSloth bin/dot pero incorporar lógica upstream de fzf_prompt

### 3. **Mejoras de performance** (Prioridad Media)
- Upstream puede tener optimizaciones que no están en dotSloth
- Revisar scripts core para oportunidades de mejora

### 4. **Documentación** (Prioridad Baja)
- Upstream puede tener mejoras en docs
- Incorporar si son relevantes

---

## Cambios que NO se Pueden Incorporar

### 1. **Estructura de directorios**
- dotSloth usa `scripts/core/src/`, upstream usa `scripts/core/`
- Cambiar esto rompería compatibilidad existente

### 2. **Features únicas de dotSloth**
- Home automation (Home Assistant, Zigbee, Shelly)
- PV systems integration
- Tesla/EV integrations
- Estas features no existen en upstream

### 3. **Configuración de paths**
- dotSloth tiene lógica compleja para SLOTH_PATH/DOTLY_PATH
- Upstream es más simple pero menos flexible

---

## Análisis de Herramientas y Migración

### docpars/docopts - Estado Actual

| Tool | Estrellas | Último update | Issues | Estado |
|------|-----------|---------------|--------|--------|
| **docpars** | 25 | 2022 | 2 | ⚠️ Abandonado |
| **docopts** | 523 | 2024 | 30 | ⚠️ Python, lento |
| **docopt.rs** | 749 | 2021 | 49 | ❌ Archivado |
| **clap-rs** | 16,537 | 2026 | 442 | ✅ Excelente |
| **go-flags** | 2,698 | 2024 | 68 | ✅ Bueno |

### Recomendación: Migrar a Rust con clap-rs

**Por qué Rust:**
1. **Velocidad:** 10-100x más rápido que Bash/Python
2. **Confiabilidad:** Type safety, manejo de errores robusto
3. **Distribución:** Binarios estáticos, fácil install
4. **Ecosistema:** clap-rs es el estándar para CLI tools en Rust

**Herramientas a crear:**
1. `dot-cli` - Reemplazo del comando `dot` (entry point)
2. `up-cli` - Reemplazo del comando `up` (package updates)
3. `docparser` - Reemplazo de docpars/docopts

---

## Issues Creados

### Bugs
1. **#233** - [Bug] Auto-updater no funciona correctamente
2. **#234** - [Bug] Restorer no funciona correctamente
3. **#235** - [Bug] Comando 'up' falla al parsear actualizaciones

### Features
4. **#236** - [Feature] Migrar docpars/docopts a tooling propio en Rust
5. **#237** - [Feature] Migrar comando 'dot' a Rust con clap-rs
6. **#238** - [Feature] Migrar comando 'up' a Rust con manejo robusto
7. **#239** - [Feature] Sincronizar mejoras upstream de CodelyTV/dotly
8. **#240** - [Feature] Implementar sistema de testing completo
9. **#241** - [Feature] Mejorar sistema de package managers con timeouts
10. **#242** - [Feature] Mejorar restorer con validación y rollback

---

## Plan de Acción Recomendado

### Fase 1: Estabilización (Corto plazo)
1. Fix #233, #234, #235 - Bugs críticos
2. #241 - Timeouts en package managers
3. #240 - Sistema de testing básico

### Fase 2: Mejoras (Mediano plazo)
1. #239 - Sincronizar cambios upstream compatibles
2. #242 - Mejorar restorer

### Fase 3: Migración (Largo plazo)
1. #236 - Tooling propio en Rust
2. #237 - Migrar `dot` a Rust
3. #238 - Migrar `up` a Rust

---

## Conclusión

dotSloth ha divergido significativamente de dotly upstream. La sincronización directa es imposible para la mayoría de los cambios, pero hay correcciones upstream que vale la pena incorporar. La migración a Rust para los comandos críticos (`dot`, `up`) es la inversión más impactante a largo plazo, resolviendo los problemas de performance y confiabilidad actuales.

**Próximo paso inmediato:** Implementar timeouts en package managers (#241) y sistema de testing básico (#240) para estabilizar antes de cualquier migración mayor.
