
% (#) refers to the equation number in p.1203.1
function o_22 = p1203_1_PV(frame_window, second, mode)

    % sec 8.1.1 quantization degradation d_q:
    quant = get_quant(mode, frame_window);          % param is operation mode
    q1 = 4.66; q2 = -0.07; q3 = 4.06;               % as defined by the recommendation;
    mos_q_hat = q1 + q2 * exp(q3 * quant);          % (2)
    mos_q_hat = max(min(mos_q_hat, 5), 1);

    d_q = 100 - r_from_mos(mos_q_hat);              % (1)
    d_q = max(min(d_q, 100), 0); 
    
    
    
    % sec 8.1.2 upscaling degradation d_u:
    dis_res = frame_window(end, 1);
    cod_res = frame_window(end, 6);
    u1 = 72.61; u2 = 0.32;                          % as defined by the recommendation;
    scale_factor = max(dis_res / cod_res, 1);       % (4)
    
    d_u = u1 * log10(u2 * (scale_factor - 1) + 1);  % (3)
    d_u = max(min(d_u, 100), 0);
    
    
    
    % sec 8.1.3 temporal degradation d_t:
    framerate = frame_window(end, 4);
    t1 = 30.98; t2 = 1.29; t3 = 64.65;              % as defined by the recommendation;
    
    d_t1 = (100 * (t1 - t2 * framerate)) / (t3 + framerate);    % (6)
    d_t2 = (d_q * (t1 - t2 * framerate)) / (t3 + framerate);    % (7)
    d_t3 = (d_u * (t1 - t2 * framerate)) / (t3 + framerate);    % (8)
    
    if framerate < 24                               % (5)
        d_t = d_t1 - d_t2 - d_t3;
    elseif framerate >= 24
        d_t = 0;
    end
    d_t = max(min(d_t, 100), 0);
    
    
    
    % sec 8.1.4 integrated degradation d:
    d = max(min(d_q + d_u + d_t, 100), 0);          % (9)
    
    
    % this q_hat calculation looks very redundant. q_hat = 100 - D appears 
    % to give the same result, so why bother with all this mess?
    if framerate < 24                               % (10)
        q_max_hat = 100 - d_u - d_t1;
    elseif framerate >= 24
        q_max_hat = 100 - d_u;
    end
    
    if framerate < 24                               % (11)
        q_hat = 100 - max(min((100 - q_max_hat) + d_q - d_t2 - d_t3, 100), 0);
    elseif framerate >= 24
        q_hat = 100 - max(min((100 - q_max_hat) + d_q, 100), 0);
    end
    
    assert(q_hat>=0 && q_hat<=100);
    assert(abs(q_hat - (100 - d)) < 0.001);         % (11) check if q_hat == 100 - D, like written 
                                                    %      in the recommendation

    mos_hat = mos_from_r(q_hat);                    % (12)
    
    if frame_window(end, 2) == 1
        o_22 = mos_hat;
    elseif frame_window(end, 2) == 2                % (13) handheld device
        htv1 = -0.60293;
        htv2 = 2.12382;
        htv3 = -0.36936;
        htv4 = 0.03409;
        o_22 = htv1 + htv2 * mos_hat + htv3 * mos_hat^2 + htv4 * mos_hat^3;
        o_22 = max(min(o_22, 5), 1);
    else
        error('unspported device');
    end
    
end

% Annexes A, B, C, D of p.1203.1: 
function quant = get_quant(mode, frame_window)
    fr = frame_window(end, 4);
    cod_res = frame_window(end, 6);
    br = frame_window(end, 3);
    switch mode
        case 0
            a1 = 11.99835;
            a2 = -2.99992;
            a3 = 41.24751;
            a4 = 0.13183;
            bpp = br / (cod_res * fr);                                  % (A.2)
            quant = a1 + a2 * log(a3 + log(br) + log(br * bpp + a4));   % (A.1)
        case 1
            error('mode not supported yet')
        case 2
            error('mode not supported yet')
        case 3
            error('mode not supported yet')
        otherwise
            error('unexisting mode')
    end
end