

% RfromMOS lookup table (section 2.1 of Annex E of p.1203.1)
% pitch here is table resolution. It's vital to have a unique MOS value for
% each R, so having too much resolution will violate this requirement due
% to low resolution of the MOSfromR calculation (p.1203.1 Annex E Sec 1)
function make_lookup_table(pitch)
% pitch of 5 works for the moment
    if pitch < 5
        warning('make sure that such a small pitch will not impact MOS uniqueness. Check the comment to this function');
    end
    r_values = 0:pitch:100;
    mos_keys = zeros(1, 100/pitch+1);
    for i = 1:100/pitch+1
        mos_keys(i) = mos_from_r(r_values(i));
    end
    tbl = containers.Map(mos_keys, r_values);
    save('rfrommos_table.mat', 'tbl', 'mos_keys', 'r_values');
end