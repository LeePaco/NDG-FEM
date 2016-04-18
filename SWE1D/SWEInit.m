function [h, q, bedElevation] = SWEInit(mesh, physics)
bedElevation = SetBed(physics);
physics.incert('bedElva', bedElevation);

% initialize the bed elevation according to the case name
switch physics.getVal('caseName')
    case 'DamBreakDry'
        [h, q] = DamBreakInit(mesh, 2);
    case 'DamBreakWet'
        [h, q] = DamBreakInit(mesh, 1);
    case 'FlowDump'
        initCase = 3;
        [h, q] = FlowDumpInit(mesh, bedElevation, initCase);
    case 'ParabolicBowl'
        [h, q] = ParaBowlInit(mesh, bedElevation);
end% switch
end% func

function [h, q] = ParaBowlInit(mesh, bedElva)
q = zeros(size(mesh.x)); %hDelta = 0.0;

g = 9.8; B = 5; h0 = 10; a = 600;
w = sqrt(2*g*h0)./a;
% z = zeros(size(mesh.x));
z = -(4*B*w).*mesh.x./(4*g);
h = z - bedElva;
hmean = CellMean(mesh, h);
h(:, hmean < 0) = 0;
% h(h<0) = 0;
end% func

function [h, q] = FlowDumpInit(mesh, bedElva, initCase)
switch initCase
    case 1 % subcritical flow
        h = 0.5.*ones(size(mesh.x))- bedElva; 
        q = 0.18.*ones(size(mesh.x));
    case 2 % supercritical flow
        h = 2.0.*ones(size(mesh.x))- bedElva; 
        q = 25.0567.*ones(size(mesh.x));
    case 3 % transcritical flow
        h = 0.33.*ones(size(mesh.x))- bedElva;
        q = 0.18.*ones(size(mesh.x));
end% switch
end% func

function [h, q] = DamBreakInit(mesh, initCase)
% Idealized dam break problem of 1D shallow water equation
h = 10.*ones(size(mesh.x)); q = zeros(size(mesh.x));
damPosition = 500;
switch initCase
    case 1 % wet bed
        flag = mesh.x > damPosition;
        h(flag) = 2;
    case 2 % dry bed
        flag = mesh.x > damPosition;
        h(flag) = 1e-4;
end% switch
end% func

function bedElevation = SetBed(physics)
mesh = physics.getVal('mesh');
VX = physics.getVal('VX');
EToV = physics.getVal('EToV');
% Initialize the bed elevation according to the case name
switch physics.getVal('caseName')
    case 'DamBreakDry'
        VB = zeros(size(VX));
%         bedElevation = zeros(size(mesh.x));
    case 'DamBreakWet'
        VB = zeros(size(VX));
%         bedElevation = zeros(size(mesh.x));
    case 'FlowDump'
        VB = zeros(size(VX));
        flag = (VX >= 8) & (VX <=12);
        VB(flag) = 0.2 - 0.05*(VX(flag) -10).^2;        
%         bedElevation = zeros(size(mesh.x));
%         flag = (mesh.x >= 8) & (mesh.x <=12);
%         bedElevation(flag) = 0.2 - 0.05*(mesh.x(flag) -10).^2;
    case 'ParabolicBowl'
        a = 600; h0 = 10;
        VB = h0.*(VX.^2./a^2 - 1);
%         bedElevation = h0.*(mesh.x.^2./a^2 - 1);
end% switch
% all of the bottom level is linear polynomial
physics.incert('VB', VB);
vb = VB(EToV');
bedElevation = 0.5*((1-mesh.Shape.r)*vb(1,:) + (mesh.Shape.r+1)*vb(2,:));
end% func