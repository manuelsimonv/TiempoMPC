1.-se generan los problemas en Matlab con el archivo gen_qp_problems.m
2.-estos problemas se traducen a lenguaje C con el archivo conversor.py
3.-estos problemas se pueden ejecutar automáticamente con los scripts runOSQP.ps1 en windows y runOSQP.sh en linux
4.-las metricas de interes se guardan en archivos .txt una vez ejecutados los problemas

**en la parte final del codigo de conversor.py se puede ver que metricas se estan almacenando, ademas aqui se pueden modificar los parametros del solver
