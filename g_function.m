function dq = g_function(q,t,mode,direction)
    m=.210;R=.031;g=9.8;mu_c=.3;mu_r=.03;I=(2/5)*m*R^2;tol=1e-12;
    v=[q(1:2);0];r=[0;0;-R];u=v+cross(q(7:9),r);
    if nargin<3 || isempty(mode)
        if norm(u)>tol
            mode='glissement';
        elseif norm(v)>tol
            mode='roulement';
        else
            mode='immobile';
        end
    end
    dq=zeros(9,1);dq(4:6)=v;
    switch mode
        case 'glissement'
            if nargin<4 || isempty(direction)
                if norm(u)<=tol,return;end
                direction=u/norm(u);
            end
            F=-mu_c*m*g*direction;
            dq(1:3)=F/m;
            dq(7:9)=cross(r,F)/I;
        case 'roulement'
            if nargin<4 || isempty(direction)
                if norm(v)<=tol,return;end
                direction=v/norm(v);
            end
            a=-mu_r*g*direction;
            dq(1:3)=a;
            dq(7:9)=[-a(2)/R;a(1)/R;0];
        case 'immobile'
            dq(:)=0;
    end
end
