function set_west_wave_depth_obc1( obj )
%SET_WAVE_DEPTH_OBC1 Summary of this function goes here
%   Detailed explanation goes here

casename = 'SWE2D/@swe2d_channel/mesh/quad';
[ obj.mesh ] = read_mesh_file(obj.mesh.cell.N, casename, ...
    ndg_lib.std_cell_type.Quad);
obj.EToB = get_bc_id(obj); % 读取开边界类型
obj.obc_vert = get_obc_vert(casename); % 读取开边界顶点编号
% 设定开边界条件 EToBS
% westid = (obj.EToB == 1);
% obj.mesh.EToBS(westid) = ndg_lib.bc_type.NonSlipWall; % 固壁边界条件
westid = (obj.EToB == 2);
obj.mesh.EToBS(westid) = ndg_lib.bc_type.Clamped; % 西侧边界条件
eastid = (obj.EToB == 3);
obj.mesh.EToBS(eastid) = ndg_lib.bc_type.Clamped; % 东侧边界条件
% 生成新网格对象
obj.mesh = ndg_lib.mesh.mesh2d(obj.mesh.cell, ...
    obj.mesh.Nv, obj.mesh.vx, obj.mesh.vy, ...
    obj.mesh.K, obj.mesh.EToV, obj.mesh.EToR, obj.mesh.EToBS);

obj.init(); % 变量初始化
% 设定边界信息
Nv = numel(obj.obc_vert); % 顶点个数
Nt = ceil(obj.ftime/obj.obc_time_interval);
Nfield = 3; % 开边界物理场个数
vx = obj.mesh.vx(obj.obc_vert);
time = linspace(0, obj.ftime, Nt); % 开边界数据时间
f_Q = zeros(Nv, Nfield, Nt);

% 开边界数据
w = 2*pi/obj.T;
c = sqrt(obj.gra*obj.H);
k = w/c;
for t = 1:Nt
    tloc = time(t);
    temp = cos(k.*vx - w*tloc);
    h = obj.eta*temp + obj.H;
    u = obj.eta*sqrt(obj.gra/obj.H)*temp;
    f_Q(:, 1, t) = h;
    f_Q(:, 2, t) = h.*u;
end

% 生成开边界文件
obj.obc_file = ndg_lib.phys.obc_file();
obj.obc_file.make_obc_file([casename, '.nc'], time, obj.obc_vert, f_Q);
obj.obc_file.set_file([casename, '.nc']);

% 设定初始条件
h = obj.eta*cos(k.*obj.mesh.x)+obj.H;
u = obj.eta*sqrt(obj.gra/obj.H)*cos(k.*obj.mesh.x);

obj.f_Q = zeros(obj.mesh.cell.Np, obj.mesh.K, obj.Nfield);
obj.f_Q(:, :, 1) = h;
obj.f_Q(:, :, 2) = h.*u;
% obj.f_Q(:, :, 2) = obj.eta*sqrt(obj.gra/obj.H);
end
