clc;
clear all;
close all;
%% 

% Definir la carpeta de salida para los archivos .mat
output_folder = 'C:\Users\a9029\Desktop\bnew_datos'; % Cambia esto según tu directorio
mkdir(output_folder); % Crear la carpeta si no existe

filename_txt  = fullfile(output_folder, 'soluciones_quadprog.txt');
filename_txt2 = fullfile(output_folder, 'soluciones_OSQP.txt');
filename_txt3 = fullfile(output_folder, 'tiempo_quadprog.txt');
filename_txt4 = fullfile(output_folder, 'tiempo_OSQP_solve.txt');
filename_txt5 = fullfile(output_folder, 'tiempo_OSQP_run.txt');
filename_txt6 = fullfile(output_folder, 'iteraciones_quadprog.txt');
filename_txt7 = fullfile(output_folder, 'iteraciones_OSQP.txt');
filename_txt8 = fullfile(output_folder, 'actuaciones_quadprog.txt');
filename_txt9 = fullfile(output_folder, 'actuaciones_OSQP.txt');

filename_txt10 = fullfile(output_folder, 'tiempo_OSQP_polish.txt');
filename_txt11 = fullfile(output_folder, 'tiempo_OSQP_setup.txt');
filename_txt12 = fullfile(output_folder, 'tiempo_OSQP_update.txt');

filename_extra = fullfile(output_folder, 'tiempo_osqp.txt');

fileID = fopen(filename_txt, 'w');  
fclose(fileID);
fileID = fopen(filename_txt2, 'w');  
fclose(fileID);
fileID = fopen(filename_txt3, 'w');  
fclose(fileID);
fileID = fopen(filename_txt4, 'w');  
fclose(fileID);
fileID = fopen(filename_txt5, 'w');  
fclose(fileID);
fileID = fopen(filename_txt6, 'w');  
fclose(fileID);
fileID = fopen(filename_txt7, 'w');  
fclose(fileID);
fileID = fopen(filename_txt8, 'w');  
fclose(fileID);
fileID = fopen(filename_txt9, 'w');  
fclose(fileID);

fileID = fopen(filename_extra, 'w');  
fclose(fileID);


% Numero de problemas QP para cada n 
N = 100;

% Orden del problema QP 'n'*'inq' (N*M)
for n = 1:40
     


    r = 1; %por defecto en 1
    
    % Número de restricciones de igualdad
    eqc = 4;
    
    % Número de restricciones de desigualdad
    inq = 2*n*(r+1); 
    fprintf('Generando problemas con n %d\n', n);
    % Restricciones de caja
    delta = 10;

    % Magnitud de los valores en H
    K = 10;
    
    % Restricciones de caja lb<=x<=ub
    lb = -delta * ones(n,1);
    ub = delta * ones(n,1);
    %X0 = zeros(n,1); % Punto inicial
    
    options =  optimset('Algorithm','interior-point-convex','Display','off'); 
 
    %options = optimoptions('quadprog', 'Algorithm', 'interior-point-convex', 'Display', 'off', 'MaxIterations', 2000);


    HH = zeros(n, n, N);                
    hh = zeros(n, N);                   
    AA = zeros(inq + 2*n + 2*eqc, n, N);    
    bb = zeros(inq + 2*n + 2*eqc, N);       
    xx = zeros(n, N);                   
    xo = zeros(n, N);                   
    ll = zeros(inq + 2*n + 2*eqc, N);       
    uu = zeros(inq + 2*n + 2*eqc, N);  

    i = 1;
    while i <= N
        H = zeros(n); nt = 0;
        for j = 1:n-1
            nt = nt + n - j; 
        end
        H(logical(triu(ones(n), 1))) = randi(K, nt, 1);
        H = H + H';
        H = H + diag(sum(H,2) + randi(n,n,1));  
        h = randn(n,r) * randn(r,1) + randn(n,1);

        F = 2 * rand(eqc,n);
        ft = 2 * rand(n,1);
        f = F * ft;

        G = randn(inq,n);
        g = 10 * rand(inq,r) * rand(r,1) + rand(inq,1);
        
     
        
        
        
        
        A = [G; eye(n); -eye(n); F; -F];
        b = [g; ub; -lb; f; -f];
        if i== 1
            [s, fsval, exitflag, output, lambda] = quadprog(H, h, A, b, [], [], [], [], [], options);
          
        end
        for j = 1:10
            tStart=tic;
            xd = rand(1000); % Código que quieres medir
            tElapsed=toc;
        end
       
        
        tStart = tic;
        [s, fsval, exitflag, output, lambda] = quadprog(H, h, A, b, [], [], [], [], [], options);
        %[s, fsval, exitflag, output, lambda] = quadprog(H, h, A, b, [], [], [], [], X0, options);
        tElapsed = toc(tStart);
        
        l_eq = f;
        u_eq = f;
        l = [-inf(size(g)); lb; -ub; l_eq; -inf(size(f))];  % Límites inferiores
        u = [g; ub; -lb; u_eq; -f];  % Límites superiores

        prob = osqp;
        tStartOSQP = tic;
        tElapsedOSQP = toc(tStartOSQP);
        tStartOSQP = tic;
        prob.setup(H, h, A, l, u,'verbose', false);
        %prob.setup(H, h, A, l, u, 'alpha', 1, 'verbose', false, 'check_termination', false, 'max_iter', 2000);
        res = prob.solve();
        tElapsedOSQP = toc(tStartOSQP);
        
        if ~strcmp(res.info.status, 'solved') || exitflag ~= 1
            continue;
        end

          
        xo(:,i) = res.x;
        ll(:,i) = l;
        uu(:,i) = u;
        
        HH(:,:,i) = H;
        hh(:,i) = h;
        AA(:,:,i) = A;
        bb(:,i) = b;
        xx(:,i) = s;


        % Guardar el archivo en la carpeta de salida
        filename = fullfile(output_folder, sprintf('OSQPData_%d.mat', n*inq));
        save(filename, 'HH', 'hh', 'AA', 'bb', 'll', 'uu', 'xo');
        
        i = i + 1;
    
        fileID = fopen(filename_txt, 'a');  
        fprintf(fileID, '%f, ', fsval); 
        fclose(fileID);
        
        fileID = fopen(filename_txt2, 'a');  
        fprintf(fileID, '%f, ', res.info.obj_val); 
        fclose(fileID);
        
        fileID = fopen(filename_txt3, 'a');  
        fprintf(fileID, '%f, ', tElapsed); 
        fclose(fileID);
    
        fileID = fopen(filename_extra, 'a');  
        fprintf(fileID, '%f, ', tElapsedOSQP); 
        fclose(fileID);


        fileID = fopen(filename_txt4, 'a');  
        fprintf(fileID, '%f, ', res.info.solve_time ); 
        fclose(fileID);
        
        fileID = fopen(filename_txt5, 'a');  
        fprintf(fileID, '%f, ', res.info.run_time); 
        fclose(fileID);
        
        fileID = fopen(filename_txt6, 'a');  
        fprintf(fileID, '%d, ', output.iterations ); 
        fclose(fileID);
        
        fileID = fopen(filename_txt7, 'a');  
        fprintf(fileID, '%d, ', res.info.iter); 
        fclose(fileID);

        fileID = fopen(filename_txt8, 'a');  
        fprintf(fileID, '%f, ', xx); 
        fclose(fileID);

        fileID = fopen(filename_txt9, 'a');  
        fprintf(fileID, '%f, ', xo); 
        fclose(fileID);

        fileID = fopen(filename_txt10, 'a');  
        fprintf(fileID, '%f, ', res.info.polish_time); 
        fclose(fileID);

        fileID = fopen(filename_txt11, 'a');  
        fprintf(fileID, '%f, ', res.info.setup_time); 
        fclose(fileID);

        fileID = fopen(filename_txt12, 'a');  
        fprintf(fileID, '%f, ', res.info.update_time); 
        fclose(fileID);
    
    end
end

