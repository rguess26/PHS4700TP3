function [coll tr tt xb yb xr yr xj yj]=Devoir3(xyb, xyr, xyj, Vb0)

    R = 0.031;

    qs_b = zeros(9, 1);

    qs_b(1:3) = Vb0;
    qs_b(4:5) = xyb;
    qs_b(6) = R;

    qs_r = zeros(9, 1);

    qs_r(1:3) = zeros(3, 1);
    qs_r(4:5) = xyr;
    qs_r(6) = R;

    qs_j = zeros(9, 1);

    qs_j(1:3) = zeros(3, 1);
    qs_j(4:5) = xyj;
    qs_j(6) = R;

    dt = 0.00001;
    t = zeros(1, 1000001);

    i = 0;
    while q_b ~= zeros(3, 1)
        i = i + 1;

        [qs_b, ev_b] = mouvement_billes(qs_b, t(i), dt);

        [qs_r, ev_r] = mouvement_billes(qs_r, t(i), dt);

        [qs_j, ev_j] = mouvement_billes(qs_j, t(i), dt);
    end
end
