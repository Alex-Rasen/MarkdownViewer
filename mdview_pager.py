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
from pathlib import Path
from io import StringIO

try:
    from rich.console import Console
    from rich.markdown import Markdown
except ImportError:
    sys.exit("Error: La librería 'rich' no está instalada. Instálala con: pip install rich")

def read_key():
    """Lee una tecla sin necesidad de Enter (modo raw)."""
    fd = sys.stdin.fileno()
    old_settings = termios.tcgetattr(fd)
    try:
        tty.setraw(fd)
        ch = sys.stdin.read(1)
        # Manejar secuencias de escape (flechas, página, etc.)
        if ch == '\x1b':
            extra = sys.stdin.read(2)  # leer los siguientes dos caracteres
            ch += extra
    finally:
        termios.tcsetattr(fd, termios.TCSADRAIN, old_settings)
    return ch

def render_markdown(md_content, width):
    """Renderiza el contenido Markdown a líneas coloreadas (ANSI) usando Rich."""
    console = Console(file=StringIO(), force_terminal=True, width=width, color_system="standard")
    md = Markdown(md_content)
    console.print(md)
    rendered = console.file.getvalue()
    # Eliminar posible salto de línea final extra
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

    # Obtener tamaño de terminal actual
    term_size = shutil.get_terminal_size((80, 24))
    term_cols, term_rows = term_size.columns, term_size.lines

    # Renderizar a líneas (con colores ANSI)
    lines = render_markdown(md_content, term_cols)
    total_lines = len(lines)
    # La última línea se reserva para la barra de estado
    display_rows = term_rows - 1 if term_rows > 1 else 1

    start_line = 0

    # Limpiar pantalla inicial
    sys.stdout.write("\033[2J\033[H")
    sys.stdout.flush()

    while True:
        # Calcular las líneas a mostrar
        end_line = min(start_line + display_rows, total_lines)
        # Mover cursor al inicio
        sys.stdout.write("\033[H")
        # Mostrar líneas
        for i in range(start_line, end_line):
            # Asegurar que no excedamos el ancho (aunque Rich ya ajusta, podríamos truncar)
            line = lines[i]
            sys.stdout.write(line[:term_cols] + "\033[K\n")  # \033[K limpia el resto de línea
        # Rellenar líneas vacías hasta display_rows
        for _ in range(end_line - start_line, display_rows):
            sys.stdout.write("\033[K\n")

        # Barra de estado
        status = f" Línea {start_line+1}-{min(end_line, total_lines)} de {total_lines} | [AvPág/RePág/Inicio/Fin] [d]espegar [q]uit "
        # Limpiar línea de estado y escribir
        sys.stdout.write(f"\033[{term_rows};1H\033[7m{status[:term_cols]}\033[0m\033[K")
        sys.stdout.flush()

        # Leer tecla
        key = read_key()

        # Procesar tecla
        if key == 'q' or key == 'Q':
            sys.stdout.write("\033[2J\033[H")  # limpiar pantalla
            sys.stdout.flush()
            break
        elif key == 'd' or key == 'D':
            # Enviar secuencia de desconexión de screen: Ctrl-a d
            sys.stdout.write("\x01d")
            sys.stdout.flush()
            # El programa sigue esperando entrada, cuando se reconecte continuará
            continue
        elif key == '\x1b[5~':  # Re Pág (Page Up) // Asegúrate de que la vista se desplace exactamente la cantidad de líneas que se muestran en la pantalla
            start_line = max(0, start_line - display_rows)
        elif key == '\x1b[6~':  # Av Pág (Page Down) // Asegúrate de que la vista se desplace exactamente la cantidad de líneas que se muestran en la pantalla
            start_line = min(max(0, total_lines - display_rows), start_line + display_rows)
        elif key == '\x1b[H' or key == '\x1b[1~':  # Inicio (Home) // Asegúrate de que la vista se desplace al inicio de la pagina
            start_line = 0
        elif key == '\x1b[F' or key == '\x1b[4~':  # Fin (End) // Asegúrate de que la vista se desplace al final de la pagina
            start_line = max(0, total_lines - display_rows)
        elif key == '\x1b[A':  # Flecha arriba // Asegúrate de que la vista se desplace una linea hacia arriba
            start_line = max(0, start_line - 1)
        elif key == '\x1b[B':  # Flecha abajo // Asegúrate de que la vista se desplace una linea hacia abajo
            start_line = min(max(0, total_lines - display_rows), start_line + 1)
        # Si se redimensiona la terminal (SIGWINCH), volver a renderizar y ajustar
        # Podríamos añadir detección de cambio de tamaño, pero por simplicidad lo dejamos así.

if __name__ == "__main__":
    main()
