#!/bin/bash
# Instalador del comando 'markdown' con paginación y screen
# Ejecutar con: sudo bash install_markdown.sh

set -e

COMMAND_NAME="markdown"
COMMAND_INSTALL_PATH="/usr/local/bin/$COMMAND_NAME"
PAGER_SCRIPT="mdview_pager.py"
PAGER_INSTALL_PATH="/usr/local/lib/mdview_pager.py"

# Verificar archivos fuente
if [ ! -f "$COMMAND_NAME" ] || [ ! -f "$PAGER_SCRIPT" ]; then
    echo "Error: Asegúrate de que '$COMMAND_NAME' y '$PAGER_SCRIPT' existen en el directorio actual." >&2
    exit 1
fi

# Verificar Python 3
if ! command -v python3 &> /dev/null; then
    echo "Error: Python 3 no está instalado." >&2
    exit 1
fi

# Instalar rich si no está presente
if ! python3 -c "import rich" 2>/dev/null; then
    echo "Instalando la librería 'rich'..."
    pip3 install rich || {
        echo "Error: No se pudo instalar 'rich'. Instálala manualmente: pip install rich" >&2
        exit 1
    }
fi

# Verificar screen
if ! command -v screen &> /dev/null; then
    echo "Error: 'screen' no está instalado. Instálalo con: sudo apt install screen (o el gestor de paquetes de tu distribución)" >&2
    exit 1
fi

# Copiar los scripts
cp "$COMMAND_NAME" "$COMMAND_INSTALL_PATH"
chmod +x "$COMMAND_INSTALL_PATH"

mkdir -p "$(dirname "$PAGER_INSTALL_PATH")"
cp "$PAGER_SCRIPT" "$PAGER_INSTALL_PATH"
chmod +x "$PAGER_INSTALL_PATH"

echo "Comando '$COMMAND_NAME' instalado correctamente."
echo "  - Script de comando: $COMMAND_INSTALL_PATH"
echo "  - Paginador Python:  $PAGER_INSTALL_PATH"
echo "Uso: markdown archivo.md"
