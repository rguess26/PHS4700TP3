function [coll tr tt xb yb xr yr xj yj]=Devoir3(xyb, xyr, xyj, Vb0)
    
    % rayon des balles
    R = 0.031;

    % q de la balle blanche
    qs_b = zeros(9, 1);
    
    qs_b(1:3) = Vb0;
    qs_b(4:5) = xyb;
    qs_b(6) = R; % z: 0 + rayon de la balle en metre

    % q de la balle rouge
    qs_r = zeros(9, 1);

    qs_r(1:3) = zeros(3, 1);
    qs_r(4:5) = xyr;
    qs_r(6) = R;

    % q de la balle jaune
    qs_j = zeros(9, 1);

    qs_j(1:3) = zeros(3, 1);
    qs_j(4:5) = xyj;
    qs_j(6) = R;
    
    % pas de temps en secondes
    dt = 0.00001;
    t = zeros(1, 1000001);
    
    i = 0;
    while q_b ~= zeros(3, 1)
        i = i + 1;

        qs_b = Runge_Kutta(qs_b, t(i), dt, g_function);

        qs_r = Runge_Kutta(qs_r, t(i), dt, g_function);

        qs_j = Runge_Kutta(qs_j, t(i), dt, g_function);
    end
end

function F_g = force_gravite(masse)
    F_g = masse * [0; 0; -9.8];
end

function F_f = force_frottement(u_c, N, v)
    F_f = -u_c  * N * (v/norm(v));
end

function F_r = force_roulement(u_r, N, v)
    F_r = -u_r  * N * (v/norm(v));
end

function qs =  Runge_Kutta(q0, t0, DeltaT, g)
    k1 = feval(g, q0, t0);
    k2 = feval(g, q0 + k1*DeltaT/2, t0 + DeltaT/2);
    k3 = feval(g, q0 + k2*DeltaT/2, t0 + DeltaT/2);
    k4 = feval(g, q0 + k3*DeltaT, t0 + DeltaT);
    qs = q0 + DeltaT*(k1 + 2*k2 + 2*k3 + k4)/6;
end

function g = g_function(q, t)
    masse = 0.21; % kg

    u_r = 0.03;
    u_c = 0.3;
    
    % TODO bien faire les différentes forces
    F_g = force_gravite(masse);
    F_n = -F_g;

    F_r = force_roulement(u_r, norm(F_n), q(1:3));

    F_f = force_frottement(u_c, norm(F_n), q(1:3));

    a = F_r + F_f / masse;

    g = zeros(size(q));
    
    g(1:3) = a;
    g(4:6) = q(1:3);
    g(7:9) = 0; % TODO accélération angulaire
end
