#!/bin/bash
# Comando markdown - visualizador de Markdown con paginación y screen

PAGER_SCRIPT="/usr/local/lib/mdview_pager.py"  # Ruta donde se instalará el paginador
SCREEN_SESSION="mdview"

mostrar_ayuda() {
    cat << EOF
Uso: markdown [OPCIONES] <archivo.md>
       markdown -h | --help

Visualiza un archivo Markdown en la terminal con formato enriquecido y paginación.
Utiliza una sesión de screen llamada 'mdview'. Si la sesión existe,
se reengancha a ella. Si no, se crea una nueva sesión.

Opciones:
  -h, --help   Muestra esta ayuda.

Controles dentro del visor:
  Av Pág, Re Pág : Página siguiente / anterior
  Inicio, Fin    : Ir al principio / final del documento
  d              : Despegar (suspender) la sesión; luego recuperar con 'markdown <archivo>'
  q              : Salir del visor y cerrar la sesión

Ejemplos:
  markdown README.md
  markdown -h
EOF
}

# Procesar opciones
if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    mostrar_ayuda
    exit 0
fi

# Validar argumentos
if [ $# -ne 1 ]; then
    echo "Error: Se requiere exactamente un archivo." >&2
    echo "Uso: markdown <archivo.md>" >&2
    exit 1
fi

archivo="$1"
if [ ! -f "$archivo" ]; then
    echo "Error: El archivo '$archivo' no existe." >&2
    exit 1
fi

# Verificar que el paginador Python existe
if [ ! -f "$PAGER_SCRIPT" ]; then
    echo "Error: No se encuentra el script paginador en $PAGER_SCRIPT" >&2
    echo "Asegúrate de haber instalado correctamente el comando." >&2
    exit 1
fi

# Si la sesión de screen ya existe, reenganchar
if screen -list | grep -q "\.${SCREEN_SESSION}\b"; then
    exec screen -r "$SCREEN_SESSION"
else
    # Crear nueva sesión con el paginador y el archivo como argumento
    exec screen -S "$SCREEN_SESSION" python3 "$PAGER_SCRIPT" "$archivo"
fi
