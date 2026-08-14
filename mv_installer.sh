#!/usr/bin/env bash
set -e

# ============================================================
# mv_installer.sh - Instalador/Desinstalador del visor Markdown
# Uso:
#   ./mv_installer.sh          # Instalar
#   ./mv_installer.sh -u       # Desinstalar
# ============================================================

# Verificar si se ejecuta como root; si no, re-ejecutar con sudo
if [ "$EUID" -ne 0 ]; then
    exec sudo "$0" "$@"
fi

ACTION="install"
if [ "$1" = "-u" ] || [ "$1" = "--uninstall" ]; then
    ACTION="uninstall"
fi

# Rutas de instalación
COMMAND_PATH="/usr/local/bin/mdv"
PAGER_PATH="/usr/local/lib/mdview_pager.py"
SCREEN_SESSION="mdview"

# Detectar familia de distribución
detect_distro() {
    if [ -f /etc/debian_version ]; then
        PKG_MANAGER="apt"
        INSTALL_CMD="apt-get install -y -qq"
        UPDATE_CMD="apt-get update -qq"
    elif [ -f /etc/redhat-release ]; then
        PKG_MANAGER="yum"
        INSTALL_CMD="yum install -y -q"
        UPDATE_CMD="yum check-update -q"  # no actualiza, solo comprueba
    else
        echo "Distribución no soportada. Solo Debian/Ubuntu y RedHat/CentOS."
        exit 1
    fi
}

# -------------------------------------------------------------------
# Funciones de utilidad
# -------------------------------------------------------------------
check_dependencies() {
    echo "==> Verificando dependencias del sistema..."
    detect_distro

    # screen
    if ! command -v screen &>/dev/null; then
        echo "    Instalando screen..."
        $UPDATE_CMD
        $INSTALL_CMD screen
    else
        echo "    screen ya está instalado."
    fi

    # python3
    if ! command -v python3 &>/dev/null; then
        echo "    Instalando python3..."
        $INSTALL_CMD python3
    else
        echo "    python3 ya está instalado."
    fi

    # pip3
    if ! command -v pip3 &>/dev/null; then
        echo "    Instalando pip3..."
        if [ "$PKG_MANAGER" = "apt" ]; then
            $INSTALL_CMD python3-pip
        elif [ "$PKG_MANAGER" = "yum" ]; then
            $INSTALL_CMD python3-pip
        fi
    else
        echo "    pip3 ya está instalado."
    fi

    # rich
    if ! python3 -c "import rich" &>/dev/null; then
        echo "    Instalando librería 'rich' con pip..."
        pip3 install -q rich
    else
        echo "    rich ya está instalado."
    fi
}

install_files() {
    echo "==> Instalando archivos del visor Markdown (comando 'mdv')..."

    mkdir -p "$(dirname "$PAGER_PATH")"

    # Escribir el script del comando 'mdv'
    cat > "$COMMAND_PATH" << 'COMMAND_EOF'
#!/bin/bash
# Comando mdv - visualizador de Markdown con paginación y screen
PAGER_SCRIPT="/usr/local/lib/mdview_pager.py"
SCREEN_SESSION="mdview"

mostrar_ayuda() {
    cat << EOF
Uso: mdv [OPCIONES] [archivo.md]
       mdv -h | --help
       mdv -r | --reconnect

Visualiza un archivo Markdown en la terminal con formato enriquecido y paginación.
Utiliza una sesión de screen llamada 'mdview'. Si la sesión existe,
se reengancha a ella (ignorando el archivo proporcionado).

Opciones:
  -h, --help     Muestra esta ayuda.
  -r, --reconnect  Reengancha a la sesión de screen existente (sin archivo).

Controles dentro del visor:
  Av Pág, Re Pág : Página siguiente / anterior
  Inicio, Fin    : Ir al principio / final del documento
  d              : Despegar (suspender) la sesión; luego recuperar con 'mdv -r'
  q              : Salir del visor y cerrar la sesión

Ejemplos:
  mdv README.md
  mdv -r
  mdv -h
EOF
}

# Procesar opciones
if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    mostrar_ayuda
    exit 0
fi

if [ "$1" = "-r" ] || [ "$1" = "--reconnect" ]; then
    if screen -list | grep -q "\.${SCREEN_SESSION}\b"; then
        exec screen -r "$SCREEN_SESSION"
    else
        echo "No hay sesión de screen '${SCREEN_SESSION}' para reenganchar." >&2
        exit 1
    fi
fi

# Si se proporciona un archivo
if [ $# -ne 1 ]; then
    echo "Error: Se requiere exactamente un archivo o usar -r para reenganchar." >&2
    echo "Uso: mdv <archivo.md> o mdv -r" >&2
    exit 1
fi

archivo="$1"
if [ ! -f "$archivo" ]; then
    echo "Error: El archivo '$archivo' no existe." >&2
    exit 1
fi

if [ ! -f "$PAGER_SCRIPT" ]; then
    echo "Error: No se encuentra el script paginador en $PAGER_SCRIPT" >&2
    echo "Asegúrate de haber instalado correctamente el comando." >&2
    exit 1
fi

# Si la sesión de screen ya existe, reenganchar
if screen -list | grep -q "\.${SCREEN_SESSION}\b"; then
    exec screen -r "$SCREEN_SESSION"
else
    exec screen -S "$SCREEN_SESSION" python3 "$PAGER_SCRIPT" "$archivo"
fi
COMMAND_EOF

    chmod +x "$COMMAND_PATH"

    # Escribir el paginador Python (sin cambios)
    cat > "$PAGER_PATH" << 'PAGER_EOF'
#!/usr/bin/env python3
"""
Visor de Markdown paginado para usar dentro de screen.
Uso: mdview_pager.py archivo.md
"""

import sys
import os
import tty
import termios
import shutil
import signal
from pathlib import Path
from io import StringIO

try:
    from rich.console import Console
    from rich.markdown import Markdown
except ImportError:
    sys.exit("Error: La librería 'rich' no está instalada. Instálala con: pip install rich")

terminal_resized = False

def handle_resize(signum, frame):
    global terminal_resized
    terminal_resized = True

def read_key():
    fd = sys.stdin.fileno()
    old_settings = termios.tcgetattr(fd)
    try:
        tty.setraw(fd)
        ch = sys.stdin.read(1)
        if ch == '\x1b':
            seq = ch
            ch2 = sys.stdin.read(1)
            if not ch2:
                return seq
            seq += ch2
            if ch2 == '[':
                while True:
                    ch3 = sys.stdin.read(1)
                    if not ch3:
                        break
                    seq += ch3
                    if ch3.isalpha() or ch3 == '~':
                        break
            return seq
        else:
            return ch
    finally:
        termios.tcsetattr(fd, termios.TCSADRAIN, old_settings)

def render_markdown(md_content, width):
    console = Console(file=StringIO(), force_terminal=True, width=width, color_system="standard")
    md = Markdown(md_content)
    console.print(md)
    rendered = console.file.getvalue()
    if rendered.endswith("\n"):
        rendered = rendered[:-1]
    return rendered.splitlines()

def main():
    if len(sys.argv) != 2:
        print("Uso interno: mdview_pager.py <archivo.md>", file=sys.stderr)
        sys.exit(1)

    file_path = Path(sys.argv[1])
    if not file_path.is_file():
        print(f"Error: El archivo '{file_path}' no existe.", file=sys.stderr)
        sys.exit(1)

    try:
        md_content = file_path.read_text(encoding="utf-8")
    except Exception as e:
        print(f"Error al leer el archivo: {e}", file=sys.stderr)
        sys.exit(1)

    signal.signal(signal.SIGWINCH, handle_resize)

    term_size = shutil.get_terminal_size((80, 24))
    term_cols, term_rows = term_size.columns, term_size.lines

    lines = render_markdown(md_content, term_cols)
    total_lines = len(lines)
    display_rows = term_rows - 1 if term_rows > 1 else 1

    start_line = 0

    sys.stdout.write("\033[2J\033[H")
    sys.stdout.flush()

    while True:
        global terminal_resized

        if terminal_resized:
            term_size = shutil.get_terminal_size((80, 24))
            term_cols, term_rows = term_size.columns, term_size.lines
            lines = render_markdown(md_content, term_cols)
            total_lines = len(lines)
            display_rows = term_rows - 1 if term_rows > 1 else 1
            start_line = max(0, min(start_line, total_lines - display_rows))
            terminal_resized = False

        end_line = min(start_line + display_rows, total_lines)
        sys.stdout.write("\033[H")
        for i in range(start_line, end_line):
            line = lines[i]
            sys.stdout.write(line + "\033[K\n")
        for _ in range(end_line - start_line, display_rows):
            sys.stdout.write("\033[K\n")

        status = f" Línea {start_line+1}-{end_line} de {total_lines} | [AvPág/RePág/Inicio/Fin] [d]espegar [q]uit "
        sys.stdout.write(f"\033[{term_rows};1H\033[7m{status[:term_cols]}\033[0m\033[K")
        sys.stdout.flush()

        key = read_key()

        if key == 'q' or key == 'Q':
            sys.stdout.write("\033[2J\033[H")
            sys.stdout.flush()
            break
        elif key == 'd' or key == 'D':
            sty = os.environ.get('STY')
            if sty:
                os.system(f'screen -S {sty} -X detach')
            continue
        elif key == '\x1b[5~':   # Re Pág
            start_line = max(0, start_line - display_rows)
        elif key == '\x1b[6~':   # Av Pág
            start_line = min(max(0, total_lines - display_rows), start_line + display_rows)
        elif key == '\x1b[H' or key == '\x1b[1~':  # Inicio
            start_line = 0
        elif key == '\x1b[F' or key == '\x1b[4~':  # Fin
            start_line = max(0, total_lines - display_rows)
        elif key == '\x1b[A':    # Flecha arriba
            start_line = max(0, start_line - 1)
        elif key == '\x1b[B':    # Flecha abajo
            start_line = min(max(0, total_lines - display_rows), start_line + 1)

if __name__ == "__main__":
    main()
PAGER_EOF

    chmod +x "$PAGER_PATH"
    echo "    - $COMMAND_PATH"
    echo "    - $PAGER_PATH"
}

uninstall_files() {
    echo "==> Desinstalando visor Markdown (mdv)..."
    if [ -f "$COMMAND_PATH" ]; then
        rm -f "$COMMAND_PATH"
        echo "    Eliminado: $COMMAND_PATH"
    else
        echo "    No se encontró $COMMAND_PATH"
    fi

    if [ -f "$PAGER_PATH" ]; then
        rm -f "$PAGER_PATH"
        echo "    Eliminado: $PAGER_PATH"
    else
        echo "    No se encontró $PAGER_PATH"
    fi

    if screen -list 2>/dev/null | grep -q "\.${SCREEN_SESSION}\b"; then
        read -p "¿Deseas cerrar la sesión de screen '${SCREEN_SESSION}'? (s/N): " respuesta
        if [[ "$respuesta" =~ ^[sS]$ ]]; then
            screen -S "$SCREEN_SESSION" -X quit
            echo "    Sesión de screen cerrada."
        else
            echo "    La sesión de screen sigue activa. Puedes cerrarla con: screen -X -S ${SCREEN_SESSION} quit"
        fi
    fi
    echo "    Los paquetes del sistema (screen, python3, pip) no se han desinstalado."
}

# -------------------------------------------------------------------
# Ejecución principal
# -------------------------------------------------------------------
if [ "$ACTION" = "install" ]; then
    echo "Instalando visor Markdown (mdv)..."
    check_dependencies
    install_files
    echo ""
    echo "¡Instalación completada!"
    echo "Uso: mdv archivo.md  o  mdv -r"
elif [ "$ACTION" = "uninstall" ]; then
    echo "Desinstalando visor Markdown (mdv)..."
    uninstall_files
    echo ""
    echo "Desinstalación completada."
else
    echo "Opción no reconocida. Use -u para desinstalar."
    exit 1
fi
