
% (#) refers to the equation number in p.1203.3
function [o_23, o_34, o_35, o_46] = p1203_3_int(o_22, o_21, stalls)

    warning('check if I need to use the device type somewhere');
    
    num_stalls = size(stalls, 1);
    o_22_size = max(size(o_22));
    o_21_size = max(size(o_21));
    T = min(o_21_size, o_22_size);
    
    assert(o_22_size == o_21_size, 'lengths of O.21 and O.22 must be equal in this implementation');

    % sec 8.1.1
    
    c_ref_7 = 0.48412879;
    c_ref_8 = 10;
    w_stall = [];
    warning('check if I need to have the initial stall here');
    for stall = 1:num_stalls
        stall_pos_from_end = T - stalls(stall, 1);                      % (2)
        w_stall(stall) = c_ref_7 + (1 - c_ref_7)...                     % (1)
                * exp(-(stall_pos_from_end * (log(0.5) / -c_ref_8)));   
    end
    total_stall_len = 0 + sum(w_stall' .* stalls(:, 2));                % (3)
    
    ints = [0];
    for i = 1:num_stalls-1
        ints(i) = stalls(i, 2) - stalls(i, 1);
    end
    avg_stall_intvl = mean(ints);                                       % sec. 8.1.1.2
    
   
    % sec 8.1.2.1 negative bias is calculated later
    % sec 8.1.2.2
    vid_qual_spread = max(o_22) - min(o_22);
    
    % sec 8.1.2.3
    tmp = circshift(o_22, -1) - o_22;
    vid_qual_chg_rate = sum(tmp(1:end-1)>0.2) / T;
    
    % sec 8.1.2.4
    o_22_ma = movmean(o_22, 5); % violation; check the warning and the respective section in p.1203.3
    warning('slight violation of the recommendation: moving average should be taken from a padded O.22 output! (why so?)');
    tmp = circshift(o_22_ma, -1) - o_22_ma;
    tmp = tmp(1:3:end);
    qc = double(tmp>0.2) - double(tmp<-0.2);
    q_dir_chg_tot = 0;
    for i = 2:size(qc)
        last = qc(i-1);
        if qc(i) ~= last
            q_dir_chg_tot = q_dir_chg_tot + 1;
        end
    end
    
    % sec 8.1.2.5
    qc_len = [];
    for i = 1:size(qc)
        if qc(i) ~= 0 && ~isempty(qc_len)
            if qc_len(end, 2) ~= qc(i)
                qc_len = [qc_len; i, qc(i)];
            end
        elseif qc(i) ~= 0 && isempty(qc_len)
            qc_len = [qc_len; 1, qc(i)];
        end
    end
    if ~isempty(qc_len)
        qc_len = [1, 0; qc_len; size(qc_len, 1), 0];
        tmp = circshift(qc_len(:, 1), -1) - qc_len(:, 1);
        dists = tmp(1:end-1);
        q_dir_chg_longest = max(dists) * 3; % 3 is the step size
    else
        q_dir_chg_longest = max(size(o_22));
    end
    
    % sec 8.4.1 RF prediction; also includes calculation of 8.1.3 Features.
    % NOTE: supplied decision trees refer to features with IDs of 0 to 13
    % (not from 1 to 14, as could be assumed from the recommendation)
    stall_count_wo_initial = size(stalls, 1) - 1;
    stall_dur = 1/3 * stalls(1, 2) + sum(stalls(2:end, 2));         % (8)
    if ~isempty(stalls(2:end, :))
        time_last_stall_to_end = T - stalls(end, 1);                % (11)
    else
        time_last_stall_to_end = T;
    end
    rf_features = [...
                    stall_count_wo_initial,...                      
                    stall_dur,...  
                    stall_count_wo_initial / T,...                  % (9) stall_freq
                    stall_dur / T,...                               % (10) stall_ratio
                    time_last_stall_to_end,...
                    sum(o_22(1:floor(o_22_size/3))) / floor(o_22_size/3),...                        % (12) avg_pv_score_one
                    sum(o_22(floor(o_22_size/3)+1:2*floor(o_22_size/3))) / floor(o_22_size/3),...   % (13) avg_pv_score_two    
                    sum(o_22(2*floor(o_22_size/3)+1:end)) / floor(o_22_size/3),...                  % (14) avg_pv_score_three 
                    prctile(o_22, 1),...                            % 1_percentile_pv_score
                    prctile(o_22, 5),...                            % 5_percentile_pv_score
                    prctile(o_22, 10),...                           % 10_percentile_pv_score
                    sum(o_21(1:floor(o_21_size/2))) / floor(o_21_size/2),...                        % (15) avg_pa_score_one
                    sum(o_21(floor(o_21_size/2)+1:end)) / floor(o_21_size/2),...                    % (16) avg_pa_score_two
                    T
                  ];
      
              
    % sec 8.2 O.34
    av1 = -0.00069084;
    av2 = 0.15374283;
    av3 = 0.97153861;
    av4 = 0.02461776;
    o_34 = max(min(av1*ones(1, T) + av2 * o_21 + av3 * o_22 + av4 * (o_21 .* o_22), 5), 1);   % (17)
    

    % sec 8.1.2.1 negative bias (calculated per each second)
    t = 1:o_22_size; % a vector of all seconds in the video
    
    c1 = 1.87403625;
    c2 = 7.85416481;
    c23 = 0.01853820;
    w_diff = c1 + (1 - c1)...
                * exp(-1 * ((T - t) * log(0.5) / (-1 * c2)));           % (5) check the log
        % the rest is calculated in the next clause
    
    
    % sec 8.3 O.35
    t1 = 0.00666620027943848;
    t2 = 0.0000404018840273729;
    t3 = 0.156497800436237;
    t4 = 0.143179744942738;
    t5 = 0.0238641564518876;
    c1 = 0.67756080;
    c2 = -8.05533303;
    c3 = 0.17332553;
    c4 = -0.01035647;
    
    w_1 = t1 + t2 * exp((t / T) / t3);                              % (20)
    w_2 = t4 - t5 * o_34;                                           % (21)
    o_35_base = sum(w_1 .* w_2 .* o_34) / sum(w_1 .* w_2);          % (19)
    
    o_34_diff = (o_34 - o_35_base*ones(1, T)) .* w_diff;            % (4)
    neg_perc = prctile(o_34_diff, 10);                              % (6)
    negative_bias = max(0, -1 * neg_perc) * c23;                    % (7)
    
    q_diff = max(0, 1 + log10(vid_qual_spread + 0.001));            % (27)
    
    if ((q_dir_chg_tot / T) < 0.25 && q_dir_chg_longest < 30)       % (24)
        osc_comp = max(0, min(q_diff...
                    * exp(c1 * q_dir_chg_longest + c2), 1.5));      % (23)
    else
        osc_comp = 0;                                               % (23)
    end
        
    if (q_dir_chg_tot / T) < 0.25                                   % (26)
        adapt_comp = max(0, min(...
            c3 * vid_qual_spread * vid_qual_chg_rate + c4, 0.5));   % (25)
    else
        adapt_comp = 0;                                             % (25)
    end
    
    o_35 = o_35_base - negative_bias - osc_comp - adapt_comp;       % (18)
    
    
    % sec 8.4.1. RFPrediction
    load('rf_trees.mat'); % loads the 'trees' variable
    rf_mos = zeros(1, 20);
    for i = 1:20
        feature = 1;
        node = 1;
        tree = trees{i};
        while feature ~= -1
            feature = tree(node, 2);
            tresh = tree(node, 3);
            if feature < 0
                break
            end
            
            % feature + 1 in the condition below is for the matlab not being capable of 
            % starting indexing from 0, contrary to all the proper programming languages
            if rf_features(feature + 1) < tresh 
                node = tree(node, 4) + 1;
            else
                node = tree(node, 5) + 1;
            end
        end
        rf_mos(i) = tresh;
    end
    RF_prediction = mean(rf_mos);
    
    
    
    % sec 8.4 O.46
    s1 = 9.35158684;
    s2 = 0.91890815;
    s3 = 11.0567558;
    SI = exp(-1 * num_stalls / s1)...                               % (29)
         * exp(-1 * (total_stall_len / T) / s2)...
         * exp(-1 * (avg_stall_intvl / T) / s3);
     
    o_46_temp = 0.75 * (1 + (o_35 - 1) * SI) + 0.25 * RF_prediction;% (28)
    o_46 = 0.02833052 + 0.98117059 * o_46_temp;                     % (30)
    
    
    % 8.5 O.23
    o_23 = 1 + 4 * SI;                                              % (31)
    
   

end
