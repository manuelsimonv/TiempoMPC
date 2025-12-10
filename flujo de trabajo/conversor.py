import scipy.io
import math
import os
import re
import shutil  


directorio_salida = "C:/Users/a9029/Desktop/datos/costo_iter_check1"  # Ruta de la carpeta a crear
if not os.path.exists(directorio_salida):
    os.makedirs(directorio_salida)


# Ruta del directorio donde están los archivos .mat
directorio_archivos = 'C:/Users/a9029/Desktop/datos/matlab_out'  # Cambia esta ruta según sea necesario

# Obtener todos los archivos .mat con el patrón OSQPData_x.mat
archivos = [f for f in os.listdir(directorio_archivos) if f.startswith('OSQPData') and f.endswith('.mat')]

for archivo in archivos:
    archivo_path = os.path.join(directorio_archivos, archivo)
    mat_contents = scipy.io.loadmat(archivo_path)

    numero = re.search(r'_(\d+)\.mat', archivo)
    numero=numero.group(1)


    # Claves deseadas
    keys_to_extract = ['AA', 'HH', 'bb', 'hh', 'll', 'uu', 'xx']
        
    # Filtrar las claves disponibles
    data_dict = {key: mat_contents[key] for key in keys_to_extract if key in mat_contents}
    #print("Keys in the .mat file:", mat_contents.keys())

        
    #print("Datos extraídos:")
    #for key, value in data_dict.items():
    #    print(f"{key}: {value}")



    AA = mat_contents['AA']
    HH = mat_contents['HH']
    hh = mat_contents['hh']
    ll = mat_contents['ll']
    uu = mat_contents['uu']

    #variables auxiliares
    AA_aux = mat_contents['AA']
    HH_aux = mat_contents['HH']
    hh_aux = mat_contents['hh']
    ll_aux = mat_contents['ll']
    uu_aux = mat_contents['uu']


    dimensiones = AA.shape
    dimensiones = dimensiones[2]


    for iter in range(dimensiones):
        #print("Archivo", iter+1)
        AA = AA[:, :, iter]  
        HH = HH[:, :, iter]
        hh = hh[:, iter]
        ll = ll[:, iter]
        uu = uu[:, iter]

        # Inicializar listas para almacenar los resultados
        array_pos_AA = [[] for _ in range(AA.shape[1])]
        array_AA = [[] for _ in range(AA.shape[1])]

        # Iterar sobre cada columna de la matriz
        for col_idx in range(AA.shape[1]):  # Desde la primera hasta la última columna
            columna = AA[:, col_idx]
            for row_idx, valor in enumerate(columna):
                if valor != 0:
                    array_pos_AA[col_idx].append(row_idx)  # Agregar posición del valor no cero
                    array_AA[col_idx].append(valor)       # Agregar el valor no cero

        # Imprimir los resultados para cada columna
        
        #for i in range(len(array_AA)):
        #    print(f"Columna {i + 1} filtrada:", array_AA[i])
        #    print(f"Largo de la columna {i + 1}:", len(array_AA[i]))
        #    print(f"Posiciones de la columna {i + 1}:", array_pos_AA[i])
        

        # Concatenar todas las columnas filtradas
        A_x = []
        for col_idx in range(len(array_AA)):
            columna = array_AA[col_idx]

            for valor in columna:
                if valor != 0:
                    A_x.append(valor)   # Añadir el valor no cero
        A_nnz = len(A_x)

        # Concatenar todas las posiciones filtradas
        A_i = [pos for columna in array_pos_AA for pos in columna]

        # Generar A_p dinámicamente
        A_p = [0]
        acumulador = 0
        for columna in array_AA:
            acumulador += len(columna)
            A_p.append(acumulador)
        
        q = []
        for elemento in hh:
            q.append(elemento.item())
        #print(q) 

        
        l = []
        for elemento in ll:
            valor = elemento.item()
            #print('elemento', valor)
            if math.isinf(valor):
                l.append('-1e6')
            else:
                l.append(valor)
        #print(l)    

        
        u = []
        for elemento in uu:
            valor = elemento.item()
            #print('elemento', valor)
            if math.isinf(valor):
                u.append('1e6')
            else:
                u.append(valor)
        #print(u)    

        n = len(q)
        m = len(u) 
        #print ("nm", n, m)

        HH_shape = HH.shape
        #print("HH.shape", HH.shape)
        #print(f"Tamaño de la matriz HH: {HH_shape}")
        P_nnz = int(HH_shape[0] * (HH_shape[0]-1) / 2 + HH_shape[0]) #cantidad de elementos no 0 en la matriz triangular: n(n-1)/2 + n
        #print ("h", P_nnz )

        # Inicializar lista P_x
        P_x = []
        # Iterar sobre las columnas de la matriz 'HH'
        for j in range(HH_shape[1]):  # Usamos HH_shape[1] para obtener el número de columnas
            # Aplanar los primeros j+1 elementos de la columna j y convertirlos a enteros
            P_x.extend(HH[:j+1, j].astype(int))  # Tomamos los primeros j+1 elementos de la columna j
        #print("P_x:", P_x)

        dim = HH_shape[0]
        P_i = []
        for i in range(1, dim + 1):
            P_i.extend(range(i))
        #print('P_i', P_i)


        P_p = []
        for i in range(dim):  
            P_p.append(int(i*(i-1)/2 + i))
        P_p.append(int(dim*(dim+1)/2))
        #print('P_p', P_p)


        AA = AA_aux 
        HH = HH_aux 
        hh = hh_aux 
        ll = ll_aux 
        uu = uu_aux 
        
        # Escribir archivo.txt con la conversion a C realizada
        nombre_archivo = f'orden_{numero}_problema_{iter+1}.txt'
        with open(nombre_archivo, 'w') as archivo:
            # P
            archivo.write(f'OSQPFloat P_x[{len(P_x)}] = {{ {", ".join(map(str, P_x))} }};\n')
            archivo.write(f'OSQPInt P_nnz = {P_nnz};\n')
            archivo.write(f'OSQPInt P_i[{len(P_i)}] = {{ {", ".join(map(str, P_i))} }};\n')
            archivo.write(f'OSQPInt P_p[{len(P_p)}] = {{ {", ".join(map(str, P_p))} }};\n\n')

            # q
            archivo.write(f'OSQPFloat q[{len(q)}] = {{ {", ".join(map(str, q))} }};\n\n')

            # A
            archivo.write(f'OSQPFloat A_x[{len(A_x)}] = {{ {", ".join(map(str, A_x))} }};\n')
            archivo.write(f'OSQPInt A_nnz = {A_nnz};\n')
            archivo.write(f'OSQPInt A_i[{len(A_i)}] = {{ {", ".join(map(str, A_i))} }};\n')
            archivo.write(f'OSQPInt A_p[{len(A_p)}] = {{ {", ".join(map(str, A_p))} }};\n\n')

            # l
            archivo.write(f'OSQPFloat l[{len(l)}] = {{ {", ".join(map(str, l))} }};\n\n')

            # u
            archivo.write(f'OSQPFloat u[{len(u)}] = {{ {", ".join(map(str, u))} }};\n\n')

            # n
            archivo.write(f'OSQPInt n = {n};\n')

            # m
            archivo.write(f'OSQPInt m = {m};\n')

        
texto_nuevo_inicio = '''#include <stdlib.h>
#include "osqp.h"
#include <stdio.h>


int main(int argc, char **argv) {
    /* Load problem data */
'''


texto_nuevo_fin = '''
    /* Exitflag */
    OSQPInt exitflag = 0;

    /* Solver, settings, matrices */
    OSQPSolver   *solver;
    OSQPSettings *settings;
    OSQPCscMatrix* P = malloc(sizeof(OSQPCscMatrix));
    OSQPCscMatrix* A = malloc(sizeof(OSQPCscMatrix));

    /* Populate matrices */
    csc_set_data(A, m, n, A_nnz, A_x, A_i, A_p);
    csc_set_data(P, n, n, P_nnz, P_x, P_i, P_p);

    /* Set default settings */
    settings = (OSQPSettings *)malloc(sizeof(OSQPSettings));
    if (settings) {
        osqp_set_default_settings(settings);
        settings->verbose = 0;
        settings->eps_rel = 1e-20;
        settings->eps_abs = 1e-20;
        settings->max_iter = 100;
        settings->check_termination = 1;
        
    
       
        
    }

    /* Setup solver */
    exitflag = osqp_setup(&solver, P, q, A, l, u, m, n, settings);

    /* Solve problem */
    if (!exitflag) exitflag = osqp_solve(solver);

    char filename_solve[] = "solve_time_costo_iter_check1_R.txt";
    FILE *file_solve = fopen(filename_solve, "a");
    fprintf(file_solve, "%f, ",solver->info->solve_time);
    fclose(file_solve);
    
    char filename_run[] = "run_time_costo_iter_check1_R.txt";
    FILE *file_run = fopen(filename_run, "a");
    fprintf(file_run, "%f, ",solver->info->run_time);
    fclose(file_run);


    char filename_obj_val[] = "obj_val_costo_iter_check1_R.txt";
    FILE *file_obj_val = fopen(filename_obj_val, "a");
    fprintf(file_obj_val, "%f, ",solver->info->obj_val);
    fclose(file_obj_val);

    
    char filename_iter[] = "iter_costo_iter_check1_R.txt";
    FILE *file_iter = fopen(filename_iter, "a");
    fprintf(file_iter, "%d, ", solver->info->iter); 
    fclose(file_iter);


    
    /* Cleanup */
    osqp_cleanup(solver);
    if (A) free(A);
    if (P) free(P);
    if (settings) free(settings);

    return (int)exitflag;
    
    
};
'''

# Directorio donde se encuentran los archivos (usar '.' para el directorio actual)
directorio = '.'

# Patrón para encontrar archivos que coincidan con 'archivo_x.txt'
patron_archivo = re.compile(r'orden_\d+_problema_\d+\.txt')

# Listar todos los archivos en el directorio
archivos = [f for f in os.listdir(directorio) if patron_archivo.match(f)]

# Iterar sobre los archivos encontrados
for nombre_archivo in archivos:
    ruta_archivo = os.path.join(directorio, nombre_archivo)
    
    # Nuevo nombre de archivo con extensión .c
    nuevo_nombre = nombre_archivo.replace('.txt', '.c')
    nueva_ruta = os.path.join(directorio, nuevo_nombre)

    try:
        # Leer el contenido actual del archivo
        with open(ruta_archivo, 'r') as archivo:
            contenido_existente = archivo.read()

        # Escribir el nuevo texto seguido del contenido existente y luego agregar el texto final
        with open(nueva_ruta, 'w') as archivo:
            archivo.write(texto_nuevo_inicio + contenido_existente + texto_nuevo_fin)

        # Eliminar el archivo original .txt
        os.remove(ruta_archivo)

    except FileNotFoundError:
        print(f"El archivo {nombre_archivo} no existe. Se omitirá.")

patron_archivo = re.compile(r'orden_\d+_problema_\d+\.c')
directorio_origen = "."  
for archivo in os.listdir(directorio_origen):
    if patron_archivo.match(archivo):
        ruta_origen = os.path.join(directorio_origen, archivo)
        ruta_destino = os.path.join(directorio_salida, archivo)
        shutil.move(ruta_origen, ruta_destino)