# 05 - Frontend Master 🎨

Objetivo de evaluación (traducción):

> Frontend master - Desarrollador frontend
- La página web es interactiva, reacciona al usuario y es "extraordinariamente bonita".

Resumen breve

- La interfaz del proyecto `ft_onion` es interactiva, responde a acciones del usuario (hover, animaciones, indicadores) y presenta un diseño visual cuidado con efectos y animaciones modernas.
- Archivos clave: [index.html](index.html#L1) (marca la UI completa), además la configuración de Nginx sirve el contenido estático.

Cómo se cumple (punto por punto)

1) Interactividad visual y diseño atractivo

- Fondo animado (rejilla en movimiento) y efectos visuales: [index.html](index.html#L46) y animación `grid-move` en [index.html](index.html#L52).
- Orbes y capas borrosas que aportan profundidad: [index.html](index.html#L69).
- Tipografía, glow y animaciones en título y cabecera: `h1` y `terminal-header` en [index.html](index.html#L120) y [index.html](index.html#L390).

2) Reactividad a la interacción del usuario

- Componentes tipo tarjeta con hover y transiciones (`.status-box`, `.feature-card`): estilos en [index.html](index.html#L206) y [index.html](index.html#L243), y la cuadrícula HTML en [index.html](index.html#L411) y [index.html](index.html#L433).
- Indicadores animados (dots, pulsos) que muestran estado y animación al pasar el ratón: vea [index.html](index.html#L411).

3) Interactividad programática (JavaScript)

- Script que aplica animaciones al cargar y simula refresco de estado periódico (extensible a llamadas reales a API): inicio del script en [index.html](index.html#L516) y `setInterval` en [index.html](index.html#L527).

4) Calidad visual y profesionalidad

- Colores, degradados, sombras, blur y transiciones están diseñados para una apariencia moderna y coherente; estilos principales desde el head en [index.html](index.html#L1-L120) y componentes en las secciones referidas arriba.
- Estructura responsive y adaptativa (`@media`), accesibilidad básica y adaptación móvil integradas en los estilos — referencias: [index.html](index.html#L345-L356) (`@media (max-width: 768px)`), [index.html](index.html#L368-L372) (`@media print`), variables de tema en [index.html](index.html#L17) (`:root`).

Qué demostrar en la defensa (sugerido)

- Abrir `index.html` y mostrar la animación de fondo y las orbes (explicar cómo funciona el CSS en [index.html](index.html#L46-L69)).
- Pasar el cursor por las tarjetas para mostrar hover/transform (`.status-box` / `.feature-card`) y mencionar la regla CSS responsable ([index.html](index.html#L206-L243)).
- Mostrar la carga de la página y explicar el script que añade animaciones y refresco simulado (`[index.html](index.html#L516-L527)`) y cómo podría enlazarse con endpoints reales para estados dinámicos.
- Argumentar brevemente por qué el diseño es “remarkably beautiful”: paleta de colores, capas, animaciones suaves y coherencia visual (referir a `:root` variables y `h1` glow en la cabecera).

Comandos útiles para comprobar rápidamente (desde `03_ft_onion_Web`):

```bash
# Ver dónde están los estilos de fondo animado
grep -n "background-image" index.html

# Mostrar las reglas de las tarjetas y el header
grep -n "\.status-box" index.html
grep -n "\.feature-card" index.html
grep -n "\.terminal-header" index.html

# Localizar el script de interactividad
grep -n "<script>" index.html
grep -n "setInterval" index.html
```

Notas finales

- Este documento resume cómo el frontend cumple el requisito de ser interactivo, reactivo y visualmente destacado.
