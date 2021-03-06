%{
--------------------------------------------------------------------------------------
    Name: Light field reconstruction with back propagation approach.
    
    Author:   Ni Chen (ni_chen@163.com)
    Date:     Aug. 2015
    Modified:

    Reference:
    - J.-H. Park, "Light ray field capture using focal plane sweeping and its
     optical reconstruction using 3D displays", OE, 2014.
    - N. Chen, "Analysis of the noise in back-projection light field acquisition and 
     its optimization", AO 56(13):F20-F26, 2017. 
--------------------------------------------------------------------------------------
%}

close all;
clear;
clc;

%% paramters
expName = 'OFC';    % expName = 'NA/OSA/OFC/IU/wenzi';
 
% File directory
inDir = ['./data/', expName, '/'];
outDir = ['./output/', expName, '/'];

% If out floder isn't exist, make it
if ~exist(outDir,'dir')==1
   mkdir(outDir);
end

% Load the parameters of the defocus images
run([inDir, 'PARAM.m']);

% number of parallax
Nttx = 100;
Ntty = 1;

% For reducing computer load
if Nttx > 3 || Ntty > 3
    isOutImg = 0;
else
    isOutImg = 1;
end

% interval of tan(theta)
% pttx = tan(2*asin(NA)/Nttx);
% ptty = tan(2*asin(NA)/Ntty);
ptx = (2*asin(NA)/Nttx);
pty = (2*asin(NA)/Ntty);

%% Calculate LF
isOutParaImg = 0;   % whether output all parallex images
% save([outDir, 'parameters.mat'], 'NI', 'type','NA','f', 'pps', 'dz', 'z_scope', 'z1', 'z2', 'Nttx', 'Ntty', 'ptx', 'pty');
save([outDir, 'parameters.mat'], 'NI', 'NA', 'pps', 'dz', 'z_scope', 'z1', 'z2', 'Nttx', 'Ntty', 'ptx', 'pty');
% save([outDir, 'parameters.mat'], 'NI', 'NA', 'pps', 'dz', 'Nttx', 'Ntty', 'ptx', 'pty');

isDeblur = 1;   % If deblur the reconstruction, Ni Chen, Applied Optics, 56(13):F20-F26, 2017.
LF = lf_bp(inDir, outDir, pps, [pty ptx], [Ntty Nttx], isOutParaImg, isDeblur);

% Propagate to focused plane
% LF = lf_prop(LF, pps, [pty ptx], z1, 2);
    
%% Extract and display horizontal LF(x, tan(theta_x))
if ~isOutParaImg
    [Ny, Nx, N_ThetaY, N_ThetaX, Nc] = size(LF);
        
    % EPS image along x axis
    LF_x_ttx = zeros(Nx, N_ThetaX, Nc);
    for ix_prime = 1:Nx     
        for itx = 1:N_ThetaX
            LF_x_ttx(ix_prime, itx, :) = LF(round(1*Ny/2), ix_prime, round(N_ThetaY/2), itx, :);
%              LF_x_ttx(ix_prime, itx, :) = LF(round(2*Ny/5), ix_prime, round(N_ThetaY/2), itx, :);
%              LF_x_ttx(ix_prime, itx, :) = LF(round(5*Ny/6), ix_prime, round(N_ThetaY/2), itx, :);
        end
    end

%     % EPS image along y axis
%     LF_y_ttx = zeros(Ny, N_ThetaY, Nc);    
%     for iy_prime = 1:Ny
%         for ity = 1:N_ThetaY
%             LF_y_ttx(iy_prime, ity, :) = LF(iy_prime, 150, ity, round(N_ThetaX/2), :);
%         end
%     end
    
    %% output
    if isOutImg == 0   % Output depth reconstruction
        %% Display LF
        temp = imrotate(LF_x_ttx, 90);
        figure;
        imshow(mat2gray(temp), []);
%         imagesc(x, atan(ttx)/pi*180, uint8(temp));
%         set(gca,'YDir','normal');
             
        set(gcf, 'paperpositionmode', 'auto');
        if isDeblur
%             print('-depsc', [outDir, 'exp_x_ttx_NI', num2str(NI), '_p1_deblur.eps']);
            imwrite(mat2gray(temp), [outDir, 'x_ttx_NI', num2str(NI), '_p1_deblur.jpg'], 'jpg');  
        else
%             print('-depsc', [outDir, 'exp_x_ttx_NI', num2str(NI), '_p1.eps']);
            imwrite(mat2gray(temp), [outDir, 'x_ttx_NI', num2str(NI), '_p1.jpg'], 'jpg');  
        end
        
        % Output EPS images at focused planes
        LF_prime = lf_prop(LF_x_ttx, pps, ptx, z1, 2);
        temp = imrotate(LF_prime, 90);
        imwrite(mat2gray(temp), [outDir, 'x-ttx_z1.jpg'],'jpg');
        
        LF_prime = lf_prop(LF_x_ttx, pps, ptx, z2, 2);
        temp = imrotate(LF_prime, 90);
        imwrite(mat2gray(temp), [outDir, 'x-ttx_z2.jpg'],'jpg');
        
        %% Refocuse intensity images at different depth
        n = 0;
        for zn = z_scope    % z position of the photo
            n = n + 1;
            Iz = lf_proj2Img(LF, pps, NA, zn, 1);
            imwrite(mat2gray(Iz), [outDir, num2str(NI), '_',num2str(isDeblur),'_',num2str(zn*1000),'.jpg'],'jpg');
            disp([num2str(n/7*100), '% is finished~~']);
            
%             figure;
%             imshow(uint8(temp), []);
%             set(gcf,'paperpositionmode','auto');
%             print('-depsc', [outDir, 'deblur_', num2str(zn*1000), '.eps']);
        end
    else
        %% Display parallax view images
        viewImg = zeros(Ny, Nx, Nc);
        for ittx = 1:Nttx
            for itty = 1:Ntty
                viewImg(1:Ny, 1:Nx, :) = LF(:, :, itty, ittx, :);
                temp = viewImg;
                imwrite(mat2gray(temp), [outDir, 'ParaImg(', num2str(ittx), ',', num2str(itty), ').jpg'], 'jpg');
            end
        end
    end    
    
end
