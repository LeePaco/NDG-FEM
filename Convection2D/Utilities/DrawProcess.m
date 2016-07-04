function DrawProcess
close all;
DrawSurface;

end% func

function DrawSurface
%% Parameters
filename = 'Convection2D_1_20.nc';
varname  = 'var';
time     = ncread(filename, 'time');
x        = ncread(filename, 'x');
y        = ncread(filename, 'y');

[np]     = numel(x);
ntime    = numel(time);

%% Read result and draw pics
figure('Position', [430, 375, 660, 429]);

ist = 1;
var = ncread(filename, varname, [1,ist], [np, 1]);
p   = plot3(x(:), y(:), var(:), '.');

for ist = 1:1:ntime
    var = ncread(filename, varname, [1,ist], [np, 1]);
    set(p, 'ZData', var(:));
    drawnow;
    fprintf('Processing %f...\n', ist/ntime);
end
end% func