function ParabolicBowlVerify
% Compare the results with exact solution on section x=0;

% Parameters
g     = 9.81;
alpha = 1.6*1e-7;
w     = sqrt(8*g*alpha);
T     = 2*pi/w;
rmin  = -4000; 
rmax  =  4000;
ne    = 1000;   % number of exact solution
np    = 100;    % number of interpolated solutions


% Get position points
xe    = zeros(ne, 1);
ye    = linspace(rmin, rmax, ne)';
re    = (xe.^2 + ye.^2);
be    = alpha*re;

xp    = zeros(np, 1);  
yp    = linspace(rmin, rmax, np)';
rp    = (xp.^2 + yp.^2);
bp    = alpha*rp;
% Draw pic
time     = (0:1/6:1)*T;
timeStr  = {'t=0', 't=T/6', 't=2T/6', 't=3T/6',...
    't=4T/6', 't=5T/6', 't=T'};
filename = 'SWE2D.nc';
for ist = 1:numel(time)
    [He, Qxe, Qye] = ParabolicBowlExtSol(xe, ye, be, time(ist));
    [hs, qxs, qys] = GetResult(filename, xp, yp, time(ist));
    % draw water height
    figure('Color', 'w');
    plot(ye, He+be, 'k--'); hold on
    plot(yp, hs+bp, 'r+');
    plot(ye, be, 'k');
    ylabel('Elvation (m)', 'Interpreter', 'Latex');
    xlabel('y (m)', 'Interpreter', 'Latex');
    title(timeStr{ist}, 'Interpreter', 'Latex');
    t = legend('Exact', 'RKDG');
    set(t, 'box', 'off');
    
    % draw flux
    figure('Color', 'w');
    plot(ye, Qxe, 'k--'); hold on
    plot(yp, qxs, 'r+');
    ylim([-1.25, 1.25]);
    ylabel('Discharge (m)', 'Interpreter', 'Latex');
    xlabel('y (m)', 'Interpreter', 'Latex');
    title(timeStr{ist}, 'Interpreter', 'Latex');
    t = legend('Exact', 'RKDG');
    set(t, 'box', 'off');
    
    % draw flux
    figure('Color', 'w');
    plot(ye, Qye, 'k--'); hold on
    plot(yp, qys, 'r+');
    ylabel('Discharge (m)', 'Interpreter', 'Latex');
    xlabel('y (m)', 'Interpreter', 'Latex');
    title(timeStr{ist}, 'Interpreter', 'Latex');
    t = legend('Exact', 'RKDG');
    set(t, 'box', 'off');
end% for

end% func

%% GetResult
% Get solutions at spicific position and time.
function [hs, qxs, qys] = GetResult(filename, xe, ye, stime)
x        = ncread(filename, 'x');
y        = ncread(filename, 'y');
time     = ncread(filename, 'time');
[~, ist] = min( abs(time - stime) );
terr     = abs(time(ist) - stime);
fprintf('Time Deviation: %f\n', terr);
[np, ne] = size(x);
% get result
h        = ncread(filename, 'h',  [1,1,ist], [np, ne, 1]);
qx       = ncread(filename, 'qx', [1,1,ist], [np, ne, 1]);
qy       = ncread(filename, 'qy', [1,1,ist], [np, ne, 1]);
% interpolation
Interp = scatteredInterpolant(x(:),y(:),h(:));
hs     = Interp(xe, ye);
Interp = scatteredInterpolant(x(:),y(:),qx(:));
qxs    = Interp(xe, ye);
Interp = scatteredInterpolant(x(:),y(:),qy(:));
qys    = Interp(xe, ye);
end% func