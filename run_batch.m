function run_batch(p, max, step) % p = 1: rba, p = 2: bba
    qoe = zeros(1, max / step);
    j = 1;
    bws = 0.1:step:max;
    for i = bws
        disp(i)
        qoe(j) = run_video(i, p);
        j = j + 1;
    end
    fm = fit(bws', qoe', 'linearinterp');
    save(strcat('batch-qoe_',num2str(p),'_',num2str(step),'_',num2str(max),'.mat'), 'bws', 'qoe', 'p', 'max', 'step', 'fm');

%     below code can generate seemengly proper coefficients for piecewise
%     linear interpolation of the results (note that it samples every third
%     value)

%     lin_coeffs = []
%     for i = 1:3:length(qoe)-1
%     f0 = fit([bws(i); bws(i+2)], [qoe(i); qoe(i+2)], 'poly1');
%     coeffs = [lin_coeffs; coeffvalues(f0)];
%     end

end