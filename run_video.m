function o_46 = run_video(base_bw, policy)

    warning('TODO: verify; measurement window'); 
    

    mode = 0; % other modes will be supported later   
    
    a = 0.7; % EWMA weight
    segment_dur = 2;                        
    n_segments = 200;
    
    ewma = 0;
    buffer = 0;
    max_buffer = 60; % in sec
    chunk_qualities = zeros(1, n_segments);
    stalls = [];
    buffers = zeros(1, n_segments);
    
    
    qualities = 1e3 * [350, 470, 630, 845, 1130, 1520, 2040, 2750]; % in bps
    resolutions = [320*194, 368*226, 448*256, 576*322, 704*418, 848*480, 1056*610, 1280*738];
    framerates = [12, 12, 24, 24, 24, 24, 24, 24];
    video_segments = zeros(max(size(qualities)), n_segments);
    
    % make up segment sizes
    for i = 1:max(size(qualities))
        avg_chunk_size = qualities(i) * segment_dur; % in bps
        video_segments(i, :) = normrnd(avg_chunk_size, avg_chunk_size/11, [1, n_segments]);
    end
    
%     bw_trace = normrnd(1, 0.5, [1, n_segments]); % in Mbps
    bw_trace = base_bw * ones(1, n_segments); % in Mbps
    bw_trace(bw_trace < 0) = 0.2;
        
        
    switch policy
        case 1
            % Rate-based adaptation
            for chunk = 1:n_segments
                buffers(chunk) = buffer;
                if chunk == 1
                    chunk_qualities(1) = 1; % min quality for the first one
                    bw = bw_trace(1) * 1e6; % in bps
                    startup_time = video_segments(1, 1) / bw; % check which column is the filesize
                    stalls = [stalls; 0, startup_time];
                    ewma = bw;
                    buffer = buffer + segment_dur;
                else
                    % choose a quality to request
                    chunk_qualities(chunk) = 1;
                    qual_i = 1;
                    for i = 2:max(size(qualities))
                        if qualities(i) < ewma
                            qual_i = i;
                            chunk_qualities(chunk) = qual_i;
                        end
                    end
                    % calculate the dl time
                    bw = bw_trace(chunk) * 1e6; % in bps
                    dl_time = video_segments(qual_i, chunk) / bw;
                    % video plays from buffer for the duration of dl_time
                    buffer = buffer - dl_time;
                    % register a stall in case the buffer was too low and reset the
                    % latter to 0
                    if buffer < 0
                        stalls = [stalls; chunk*segment_dur, -1 * buffer]; % stall start timestamp, duration
                        buffer = 0;
                    end
                    % update the ewma
                    ewma = a * bw + (1 - a) * ewma;
                    % buffer now has another segment stored
                    buffer = buffer + segment_dur;
                    % if the buffer is overflown, wait for the duration of a segment
                    if buffer >= max_buffer
                        buffer = buffer - segment_dur;
                    end
                end
            end
        case 2
            % Buffer-based adaptation
            reservoir = segment_dur * 4; % 4 segments long
            cushion = ceil(max_buffer * 2/3);
            for chunk = 1:n_segments
                buffers(chunk) = buffer;
                if chunk == 1
                    chunk_qualities(1) = 1; % min quality for the first one
                    bw = bw_trace(1) * 1e6; % in bps
                    startup_time = video_segments(1, 1) / bw; % check which column is the filesize
                    stalls = [stalls; 0, startup_time];
                    buffer = buffer + segment_dur;
                else
                    % choose a quality to request
                    prev_qual = chunk_qualities(chunk - 1);
                    f_buf = bba_f(qualities(1), qualities(end), cushion, reservoir, buffer);
                    if prev_qual == max(size(qualities))
                        rate_plus = qualities(end); % max quality
                    else
                        rate_plus = qualities(prev_qual + 1);
                    end
                    
                    if prev_qual == 1
                        rate_minus = qualities(1);
                    else
                        rate_minus = qualities(prev_qual - 1);
                    end
                    
                    if buffer <= reservoir
                        chunk_qualities(chunk) = 1;
                    elseif buffer >= (reservoir + cushion)
                        chunk_qualities(chunk) = max(size(qualities));
                    elseif f_buf >= rate_plus 
                        tmp = max(qualities(qualities<f_buf));
                        chunk_qualities(chunk) = find(qualities==tmp);
                    elseif f_buf <= rate_minus
                        tmp = min(qualities(qualities>f_buf));
                        chunk_qualities(chunk) = find(qualities==tmp);
                    else
                        chunk_qualities(chunk) = prev_qual;
                    end
                                        
                    % calculate the dl time
                    bw = bw_trace(chunk) * 1e6; % in bps
                    dl_time = video_segments(chunk_qualities(chunk), chunk) / bw;
                    % video plays from buffer for the duration of dl_time
                    buffer = buffer - dl_time;
                    % register a stall in case the buffer was too low and reset the
                    % latter to 0
                    if buffer < 0
                        stalls = [stalls; chunk*segment_dur, -1 * buffer]; % stall start timestamp, duration
                        buffer = 0;
                    end
                    % buffer now has another segment stored
                    buffer = buffer + segment_dur;
                    % if the buffer is overflown, wait for the duration of a segment
                    if buffer >= max_buffer
                        buffer = buffer - segment_dur;
                    end
                end
            end
        otherwise
            error('inexisting adaptation policy');
    end
    
    
    o_21 = 4.95 * ones(1, segment_dur * n_segments);
    o_22 = zeros(1, segment_dur * n_segments);
    video = [];
    
    i_gen_0 = 1920*1080;                % client display res, in pixels
    i_gen_1 = 1;                        % client device (1 - PC, 2 - mobile)
    
    i_13_13 = segment_dur;              % segment duration
    i_13_15 = 1;                        % decoder and profile (like 'h264-hi') NOT IMPLEMENTED
    
    for second = 1:segment_dur * n_segments
        chunk = ceil(second/i_13_13);
        i_13_11 = qualities(chunk_qualities(chunk));     % video bitrate
        i_13_12 = framerates(chunk_qualities(chunk));    % video fps
        i_13_14 = resolutions(chunk_qualities(chunk));   % video res, in pixels
        for frame = 1:i_13_12
                        
            i_13_16 = second * i_13_12 + frame; % frame no.#
            i_13_17 = 1 / i_13_12;              % frame duration
            i_13_18 = -1;                       % frame presentation timestamp NOT IMPLEMENTED
            i_13_19 = -1;                       % frame decoding timestamp NOT IMPLEMENTED
            i_13_20 = i_13_11 / 8 / i_13_12;    % frame size in bytes NOT IMPLEMENTED
            i_13_21 = 1;                        % frame type (i, p, b) NOT IMPLEMENTED
            i_13_22 = 1;                        % encoded frame bytestream NOT IMPLEMENTED

            new_line = [i_gen_0, i_gen_1, i_13_11, i_13_12, i_13_13, ...
                        i_13_14, i_13_15, i_13_16, i_13_17, i_13_18, ...
                        i_13_19, i_13_20, i_13_21, i_13_22];

            video = [video; new_line];
        end
        o_22(second) = p1203_1_PV(video, second, mode);
    end
        
        
        
    [o_23, o_34, o_35, o_46] = p1203_3_int(o_22, o_21, stalls);
    save(strcat('experiments/qoe_',num2str(base_bw),'_',num2str(policy),'.mat'), 'o_23', 'o_34', 'o_35', 'o_46', 'stalls');
%     disp(1)    
    
    
end

function value = bba_f(r_min, r_max, c, r, buffer)
    slope = (r_max - r_min) / c;
    value = r_min + slope * (buffer - r);
end
    






























