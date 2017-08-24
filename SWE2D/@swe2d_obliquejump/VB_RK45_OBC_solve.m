function [ obj ] = VB_RK45_OBC_solve( obj )
%SOLVE 采用 SSP RK-45 时间离散格式求解浅水方程半离散方程。
%   Detailed explanation goes here

rk4a = [            0.0 ...
        -567301805773.0/1357537059087.0 ...
        -2404267990393.0/2016746695238.0 ...
        -3550918686646.0/2091501179385.0  ...
        -1275806237668.0/842570457699.0];
rk4b = [ 1432997174477.0/9575080441755.0 ...
         5161836677717.0/13612068292357.0 ...
         1720146321549.0/2090206949498.0  ...
         3134564353537.0/4481467310338.0  ...
         2277821191437.0/14882151754819.0];
rk4c = [             0.0  ...
         1432997174477.0/9575080441755.0 ...
         2526269341429.0/6820363962896.0 ...
         2006345519317.0/3224310063776.0 ...
         2802321613138.0/2924317926251.0];

time = 0;
ftime = obj.ftime;

resQ = zeros(obj.mesh.cell.Np, obj.mesh.K, obj.Nfield);
f_Q  = obj.f_Q;
obj.wetdry_detector(f_Q);
obj.topo_grad_term(); % 计算底坡梯度

is_Camera_on = 0; % 设定是否生成动画
if is_Camera_on
    writerObj = VideoWriter([pwd,'/ob.avi']);
    writerObj.FrameRate=15; % 设定动画帧率
    open(writerObj);	
end

contour = 1;
err1 = zeros(3, 100);
err2 = zeros(3, 100);
errInf = zeros(3, 100);
time_v = zeros(100, 1);
while(time < ftime)
    dt = time_interval(obj, f_Q);
%     dt = obj.time_interval(f_Q);
    if(time + dt > ftime)
        dt = ftime - time;
    end
    for INTRK = 1:5
        tloc = time + rk4c(INTRK)*dt;
        obj.update_ext(tloc);
        rhsQ = rhs_term(obj, f_Q);
        resQ = rk4a(INTRK).*resQ + dt.*rhsQ;
        
        f_Q = f_Q + rk4b(INTRK)*resQ;
        % 应用斜率限制器限制水位与流量
        f_Q(:,:,1) = obj.slopelimiter.limit( f_Q(:,:,1) + obj.bot );
        f_Q(:,:,2) = obj.slopelimiter.limit( f_Q(:,:,2) );
        f_Q(:,:,3) = obj.slopelimiter.limit( f_Q(:,:,3) );
        f_Q(:,:,1) = f_Q(:,:,1) - obj.bot;
        
        f_Q = obj.positive_preserve( f_Q );
        obj.wetdry_detector( f_Q ) ; % 重新判断干湿单元  
    end
    
    %obj.draw( f_Q ); drawnow;
    if is_Camera_on
        frame = getframe(gcf);
        writeVideo(writerObj,frame); 
    end% if
    time = time + dt;
    
    obj.f_Q = f_Q;
    
    err1(:, contour) = obj.norm_err1(time);
    err2(:, contour) = obj.norm_err2(time);
    errInf(:, contour) = obj.norm_errInf(time);
    time_v(contour) = time;
    contour = contour + 1;
    
end

draw_error(obj, time_v, err1, err2, errInf);

if is_Camera_on
    close(writerObj);
end

obj.f_Q = f_Q;
end

function draw_error(obj, time_v, err1, err2, errInf)
switch obj.mesh.cell.type
    case ndg_lib.std_cell_type.Tri
        c = 'r--';
    case ndg_lib.std_cell_type.Quad
        c = 'b-';
end
linewidth = 2;
markersize = 6;
figure(1); hold on;
plot(time_v, err1(1, :), c, ...
    'LineWidth', linewidth, ...
    'MarkerSize', markersize);
grid on; box on;
xlabel('time(s)', 'Interpreter', 'Latex', 'FontSize', 20);
ylabel('$L_1$', 'Interpreter', 'Latex', 'FontSize', 20);

figure(2); hold on;
plot(time_v, err2(1, :), c, ...
    'LineWidth', linewidth, ...
    'MarkerSize', markersize);
grid on; box on;
xlabel('time(s)', 'Interpreter', 'Latex', 'FontSize', 20);
ylabel('$L_2$', 'Interpreter', 'Latex', 'FontSize', 20);

end% func

function dt = time_interval(obj, f_Q)
spe = obj.char_len(f_Q); % Jacobian characteristic length
dt = bsxfun(@times, sqrt(obj.mesh.vol)/(2*obj.mesh.cell.N+1), 1./spe);
dt = min( min( dt ) );
end% func
