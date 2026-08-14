# 📜 Markdown Terminal Viewer (mdv)

Visor de archivos Markdown en la terminal de Linux con formato enriquecido, paginación y soporte para sesiones de `screen`. Renderiza el contenido como si estuvieras en un navegador, respetando estilos (negritas, cursivas, títulos, código, tablas, listas…).

## ✨ Características

- **Formato enriquecido**: gracias a la librería `rich`, el renderizado incluye colores, estilos y resaltado de sintaxis.
- **Paginación completa**:
  - Av Pág / Re Pág para avanzar y retroceder páginas exactas.
  - Inicio / Fin para ir al principio o final del documento.
  - Flechas ↑/↓ para desplazamiento línea a línea.
- **Sesión con `screen`**: 
  - Al abrir un archivo se crea una sesión de `screen` llamada `mdview` (o se reengancha si ya existe).
  - Puedes **despegar** la sesión con la tecla `d` y recuperarla más tarde con el comando `mdv -r`.
  - Con `q` cierras la sesión y sales del visor.
- **Ajuste automático de texto**: nunca se cortan palabras; el texto se adapta al ancho de la terminal, respetando la estructura de tablas y párrafos.
- **Instalación sencilla** mediante un único script que gestiona dependencias.

## 📋 Requisitos

El script de instalación se encarga de instalar automáticamente lo necesario, pero por claridad:

- `screen` (gestor de sesiones de terminal)
- `python3` 
- Librería Python `rich` (se instala vía apt o pip)

Sistemas basados en Debian/Ubuntu son soportados directamente. Para otras distribuciones, ajusta los comandos del instalador según el gestor de paquetes.

## 🚀 Instalación

1. **Descarga el script `mv_installer.sh`** en tu máquina.
2. Dale permisos de ejecución:
   ```bash
   chmod +x mv_installer.sh
   ```
3. Ejecútalo como root o como usuario normal (se pedirá sudo automáticamente):
   ```bash
   ./mv_installer.sh
   ```
   El script:
   - Eleva privilegios si no eres root.
   - Verifica e instala `screen`, `python3` y `rich` si faltan.
   - Copia el comando `mdv` a `/usr/local/bin/mdv`.
   - Copia el paginador `mdview_pager.py` a `/usr/local/lib/mdview_pager.py`.

Tras la instalación tendrás disponible el comando `mdv`.

## 🖥️ Uso

```bash
mdv archivo.md
```

- Si es la primera vez, se crea una nueva sesión de `screen`.
- Si la sesión `mdview` ya existe (porque estaba suspendida), te reenganchas automáticamente a ella.

### Controles dentro del visor

| Tecla           | Acción                                   |
|-----------------|------------------------------------------|
| **Av Pág**      | Página siguiente (avance exacto)         |
| **Re Pág**      | Página anterior                          |
| **Inicio**      | Ir al principio del documento            |
| **Fin**         | Ir al final del documento                |
| **↑ / ↓**       | Desplazamiento línea a línea             |
| **d**           | Despegar (suspender) la sesión y volver a la terminal |
| **q**           | Salir del visor y cerrar la sesión       |

### Despegar y reconectar

- Pulsa **`d`** para “despegar” la sesión. El visor sigue ejecutándose en segundo plano y puedes usar la terminal normalmente.
- Para retomar la visualización, ejecuta `mdv -r`. Se reenganchará exactamente donde lo dejaste.

### Ayuda

```bash
mdv -h
```

## 🗑️ Desinstalación

Ejecuta el mismo script con el argumento `-u`:

```bash
./mv_installer.sh -u
```

Esto:
- Elimina `/usr/local/bin/mdv` y `/usr/local/lib/mdview_pager.py`.
- Pregunta si quieres cerrar la sesión activa de `screen` (si existe).
- **No desinstala** `screen`, `python3` ni `rich`, ya que pueden ser usados por otros programas.

## ⚠️ Notas

- Si cambias el tamaño de la terminal mientras estás en el visor, el contenido se re‑renderiza automáticamente.
- Si necesitas visualizar un archivo diferente, cierra la sesión actual (tecla `q`) antes de abrir el nuevo, o bien cierra la sesión desde fuera con:
  ```bash
  screen -X -S mdview quit
  ```
- El visor utiliza los colores de tu terminal. Asegúrate de que tu terminal soporte 256 colores o truecolor para la mejor experiencia.

## 📄 Licencia

Este proyecto se distribuye bajo la licencia MIT. Siéntete libre de usarlo y modificarlo.
