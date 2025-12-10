#!/bin/bash

# Definimos las rutas de OSQP
OSQP_INCLUDE="/home/pi/Memoria/osqp/include/public"
OSQP_BUILD_INCLUDE="/home/pi/Memoria/osqp/build/include/public"
OSQP_LIB="/home/pi/Memoria/osqp/build/out"

# Obtener lista de archivos y ordenarlos numéricamente por el número después de "orden_"
archivos=$(ls orden_*.c 2>/dev/null | sort -t '_' -k2,2n -k4,4n)

# Recorremos los archivos ordenados
for archivo in $archivos; do
    # Verificamos si el archivo realmente existe
    [ -f "$archivo" ] || continue  

    # Extraemos el número principal (orden) y el número del problema
    if [[ "$archivo" =~ orden_([0-9]+)_problema_([0-9]+)\.c ]]; then
        num_orden="${BASH_REMATCH[1]}"
        num_problema="${BASH_REMATCH[2]}"
    else
        echo "No se pudo extraer los números de $archivo"
        continue
    fi

    # Nombre del ejecutable basado en los números extraídos
    ejecutable="output_orden_${num_orden}_problema_${num_problema}"

    # Compilamos el archivo
    gcc "$archivo" -I "$OSQP_INCLUDE" -I "$OSQP_BUILD_INCLUDE" \
                   -L "$OSQP_LIB" -losqpstatic -lm -lpthread -o "$ejecutable"

    # Verificamos si la compilación fue exitosa
    if [ $? -eq 0 ]; then
        echo "Ejecutando $ejecutable..."
        ./"$ejecutable"
    else
        echo "Error al compilar $archivo"
    fi
done

# Eliminar todos los archivos compilados y los archivos .c después de la ejecución
echo "Eliminando archivos ejecutables y fuentes..."
rm -f output_orden_* orden_*.c

echo "Proceso completado."
