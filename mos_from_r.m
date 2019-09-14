

% MOSfromR lookup table (section 1 of Annex E of p.1203.1)
% here q is actually R (scales from 1 to 100). Why would they mess up notations?
function mos = mos_from_r(q)
    mos_max = 4.9;
    mos_min = 1.05;
    mos = mos_min + (mos_max - mos_min) * q / 100 + q * (q - 60)...
          * (100 - q) * 0.000007;                                       % (E.1)
    mos = min(mos_max, max(mos, mos_min));                              % (E.2)
end