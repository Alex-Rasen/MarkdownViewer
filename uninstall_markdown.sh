#!/bin/bash
# Desinstalador del comando 'markdown' y su visor paginado
# Ejecutar con: sudo bash uninstall_markdown.sh

set -e

COMMAND_NAME="markdown"
COMMAND_PATH="/usr/local/bin/$COMMAND_NAME"
PAGER_PATH="/usr/local/lib/mdview_pager.py"
SCREEN_SESSION="mdview"

echo "Desinstalando el comando 'markdown'..."

# Eliminar el script de comando
if [ -f "$COMMAND_PATH" ]; then
    rm -f "$COMMAND_PATH"
    echo "  - Eliminado: $COMMAND_PATH"
else
    echo "  - No se encontró: $COMMAND_PATH"
fi

# Eliminar el paginador Python
if [ -f "$PAGER_PATH" ]; then
    rm -f "$PAGER_PATH"
    echo "  - Eliminado: $PAGER_PATH"
else
    echo "  - No se encontró: $PAGER_PATH"
fi

# Cerrar sesión de screen si existe
if screen -list | grep -q "\.${SCREEN_SESSION}\b"; then
    read -p "¿Deseas cerrar la sesión de screen '${SCREEN_SESSION}'? (s/N): " respuesta
    if [[ "$respuesta" =~ ^[sS]$ ]]; then
        screen -S "$SCREEN_SESSION" -X quit
        echo "  - Sesión de screen '${SCREEN_SESSION}' cerrada."
    else
        echo "  - La sesión de screen '${SCREEN_SESSION}' sigue activa. Puedes cerrarla manualmente con: screen -X -S ${SCREEN_SESSION} quit"
    fi
else
    echo "  - No se encontró la sesión de screen '${SCREEN_SESSION}'."
fi

echo ""
echo "Desinstalación completada."
echo "La librería 'rich' (Python) no se ha eliminado, ya que puede ser usada por otros programas."
echo "Si deseas eliminarla manualmente: pip3 uninstall rich"