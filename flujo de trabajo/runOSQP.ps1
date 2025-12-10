# Definir la carpeta donde están los archivos .c
$Carpeta = "C:/Users/a9029/Desktop/datos/only"  # Cambia esto por la ruta deseada

# Verificar si la carpeta existe
if (!(Test-Path $Carpeta)) {
    Write-Error "La carpeta especificada no existe: $Carpeta"
    exit 1
}

# Buscar archivos C en la carpeta especificada
$archivos = Get-ChildItem -Path $Carpeta -Filter "orden_*.c"

# Crear una lista con los archivos y sus valores numéricos extraídos
$archivosProcesados = @()

foreach ($archivo in $archivos) {
    if ($archivo.Name -match "orden_(\d+)_problema_(\d+)\.c") {
        $archivosProcesados += [PSCustomObject]@{
            Archivo  = $archivo
            Orden    = [int]$matches[1]
            Problema = [int]$matches[2]
        }
    }
}

# Ordenar primero por Orden, luego por Problema en orden ascendente
$archivosOrdenados = $archivosProcesados | Sort-Object Orden, Problema

foreach ($item in $archivosOrdenados) {
    $archivo = $item.Archivo
    $orden = $item.Orden
    $problema = $item.Problema
    $ejecutable = "$Carpeta\orden_${orden}_problema_${problema}_output.exe"

    Write-Output "Procesando: Orden $orden - Problema $problema"

    # Verificar que los directorios existen
    $include1 = "C:/Users/a9029/Desktop/osqp/include/public"
    $include2 = "C:/Users/a9029/Desktop/osqp/build/include/public"
    $libPath = "C:/Users/a9029/Desktop/osqp/build/out"

    if (!(Test-Path $include1) -or !(Test-Path $include2) -or !(Test-Path $libPath)) {
        Write-Error "Uno o más directorios de inclusión o bibliotecas no existen."
        exit 1
    }

    # Compilar el archivo
    $sourceFile = $archivo.FullName
    $compilacion = & gcc "`"$sourceFile`"" -I "$include1" -I "$include2" `
                     -L "$libPath" -losqpstatic -lm -lpthread -o "`"$ejecutable`"" 2>&1

    if ($?) {
        
        & "$ejecutable"  # Ejecuta el binario generado

        # Eliminar el ejecutable después de su ejecución
        Remove-Item "$ejecutable" -Force
        
    } else {
        Write-Error "Error al compilar $archivo"
        Write-Output "Detalles: $compilacion"
    }
}
