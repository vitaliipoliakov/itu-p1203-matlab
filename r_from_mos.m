

% RfromMOS lookup table (section 2 of Annex E of p.1203.1)
% here q is acturally R (scales from 1 to 100). Stupid naming.
function q = r_from_mos(mos)
    format short; % or otherwise hash lookup won't work >:(
    load('rfrommos_table.mat');
    mos_max = 4.9;
    mos_min = 1.05;
    mos = min(mos_max, max(mos, mos_min));                  % (E.4)
    for i = 1:max(size(mos_keys))
        if mos >= mos_keys(i)
            Kp = mos_keys(i);
            Kq = mos_keys(i+1);
            Vp = tbl(Kp);
            Vq = tbl(Kq);
        end
    end
    
    q = (Vp * (Kq - mos) + Vq * (mos - Kp)) / (Kq - Kp);    % (E.5)
    
    assert(abs(mos - mos_from_r(q)) <= 0.01,...             % (E.3)
                'recommendation suggests the RfromMOS conversion error to be less than 0.01');
end