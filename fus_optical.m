%% Code by Shubham Mirg
%%% Kothapalli Lab
%%% Load baseline normalized roi averaged traces
%% ---- Load ----
load('seed_traces_raw.mat');          % Sample seedTrace (Fig 1)
t_fus = seedTrace.t_fus;
t_opt = seedTrace.t_opt;
frameRate_opt = seedTrace.params.frameRate_opt;
frameRate_fus = seedTrace.params.frameRate_fus;

%% ---- Processing parameters ----
f_low   = 0.02;          % bandpass low cutoff (Hz)
f_high  = 0.5;           % bandpass high cutoff (Hz)
f_lowc  = 0.02;          % calcium high-pass cutoff (Hz)
wincorr = 20;            % xcorr lag window (samples)

[fil1, fil2]         = butter(4, [f_low f_high]/(frameRate_opt/2), 'bandpass');
[fil1c, fil2c]       = butter(4, [f_lowc]/(frameRate_opt/2),       'high');
[fil1_fus, fil2_fus] = butter(4, [f_low f_high]/(frameRate_fus/2), 'bandpass');

%% ---- Apply filtering ----
fus_f = filtfilt(fil1_fus, fil2_fus, seedTrace.fus(:)).';
hbo_f = filtfilt(fil1,  fil2,  seedTrace.hbo(:)).';
hbr_f = filtfilt(fil1,  fil2,  seedTrace.hbr(:)).';
hbt_f = filtfilt(fil1,  fil2,  seedTrace.hbt(:)).';
ca_f  = filtfilt(fil1c, fil2c, seedTrace.ca(:)).';

%% ---- Interpolate optical -> fUS time base ----
hbo_int = interp1(t_opt, hbo_f, t_fus, 'linear', 'extrap');
hbr_int = interp1(t_opt, hbr_f, t_fus, 'linear', 'extrap');
hbt_int = interp1(t_opt, hbt_f, t_fus, 'linear', 'extrap');
ca_int  = interp1(t_opt, ca_f,  t_fus, 'linear', 'extrap');

%% ---- 10 colorblind-friendly colors ----
cb10 = [ ...
    0.000 0.000 0.000;  % black
    0.902 0.624 0.000;  % orange
    0.337 0.706 0.914;  % sky blue
    0.000 0.620 0.451;  % bluish green
    0.941 0.894 0.259;  % yellow
    0.000 0.447 0.698;  % blue
    0.835 0.369 0.000;  % vermillion
    0.800 0.475 0.655;  % reddish purple
    0.600 0.600 0.600;  % gray
    0.800 0.600 0.200]; % brown

fntz = 13;

%% ============ Figure 1: raw separate traces (non-normalized) ============
figure('Color','w');

subplot(5,1,1)
plot(t_fus, seedTrace.fus, 'Color', cb10(1,:), 'LineWidth', 1.5);
ylabel('CBV (fUS)', 'FontSize', fntz); axis tight; box off
title('Raw seed traces');

subplot(5,1,2)
plot(t_opt, seedTrace.hbo, 'Color', cb10(2,:), 'LineWidth', 1.5);
ylabel('HbO (\muM)', 'FontSize', fntz); axis tight; box off

subplot(5,1,3)
plot(t_opt, seedTrace.hbr, 'Color', cb10(8,:), 'LineWidth', 1.5);
ylabel('HbR (\muM)', 'FontSize', fntz); axis tight; box off

subplot(5,1,4)
plot(t_opt, seedTrace.hbt, 'Color', cb10(3,:), 'LineWidth', 1.5);
ylabel('HbT (\muM)', 'FontSize', fntz); axis tight; box off

subplot(5,1,5)
plot(t_opt, seedTrace.ca, 'Color', cb10(9,:), 'LineWidth', 1.5);
ylabel('Ca^{2+}', 'FontSize', fntz); xlabel('Time (s)', 'FontSize', fntz);
axis tight; box off

%% ============ Figure 2: filtered separate traces ============
figure('Color','w');

subplot(5,1,1)
plot(t_fus, fus_f, 'Color', cb10(1,:), 'LineWidth', 1.5);
ylabel('CBV (fUS)', 'FontSize', fntz); axis tight; box off
title(sprintf('Filtered seed traces (%.2f-%.2f Hz)', f_low, f_high));

subplot(5,1,2)
plot(t_opt, hbo_f, 'Color', cb10(2,:), 'LineWidth', 1.5);
ylabel('HbO (\muM)', 'FontSize', fntz); axis tight; box off

subplot(5,1,3)
plot(t_opt, hbr_f, 'Color', cb10(8,:), 'LineWidth', 1.5);
ylabel('HbR (\muM)', 'FontSize', fntz); axis tight; box off

subplot(5,1,4)
plot(t_opt, hbt_f, 'Color', cb10(3,:), 'LineWidth', 1.5);
ylabel('HbT (\muM)', 'FontSize', fntz); axis tight; box off

subplot(5,1,5)
plot(t_opt, ca_f, 'Color', cb10(9,:), 'LineWidth', 1.5);
ylabel('Ca^{2+}', 'FontSize', fntz); xlabel('Time (s)', 'FontSize', fntz);
axis tight; box off

%% ============ Figure 3: cross-correlation ============
[chboxfus, lag] = xcorr(fus_f, hbo_int, wincorr, 'normalized');
[chbrxfus, ~]   = xcorr(fus_f, hbr_int, wincorr, 'normalized');
[chbtxfus, ~]   = xcorr(fus_f, hbt_int, wincorr, 'normalized');
[caxfus,   ~]   = xcorr(fus_f, ca_int,  wincorr, 'normalized');

lagTime = lag / frameRate_fus;

figure('Color','w'); hold on
plot(lagTime, chboxfus, 'Color', cb10(2,:), 'LineWidth', 2);
plot(lagTime, chbrxfus, 'Color', cb10(8,:), 'LineWidth', 2);
plot(lagTime, chbtxfus, 'Color', cb10(3,:), 'LineWidth', 2);
plot(lagTime, caxfus,   'Color', cb10(9,:), 'LineWidth', 2);
xline(0, '--', 'Color', cb10(1,:), 'LineWidth', 2, 'HandleVisibility', 'off');
legend('HbO','HbR','HbT','Ca^{2+}', 'FontSize', 15);
xlabel('Lag (s)', 'FontSize', fntz); ylabel('Corr. coeff.', 'FontSize', fntz);
axis tight; ylim([-1 1]); box on
title('Seed-based cross-correlation');

%% ============ Figure 4: coherogram (time-frequency coherence), 4 panels ============

 
fhi_coh = frameRate_fus;                                  % low-pass cutoff (Hz)
[lp1, lp2] = butter(2, fhi_coh/(frameRate_opt/2), 'low'); % 2nd-order low-pass
 
% optical: low-pass on optical base, then interp to fUS base
hbo_lp = interp1(t_opt, filtfilt(lp1, lp2, seedTrace.hbo(:)).', t_fus, 'linear', 'extrap');
hbr_lp = interp1(t_opt, filtfilt(lp1, lp2, seedTrace.hbr(:)).', t_fus, 'linear', 'extrap');
hbt_lp = interp1(t_opt, filtfilt(lp1, lp2, seedTrace.hbt(:)).', t_fus, 'linear', 'extrap');
ca_lp  = interp1(t_opt, filtfilt(lp1, lp2, seedTrace.ca(:)).',  t_fus, 'linear', 'extrap');
 
% fUS: unfiltered raw ROI mean (already on fUS base)
fus_coh = seedTrace.fus(:);
 
coh_sig = {hbo_lp, hbr_lp, hbt_lp, ca_lp};
sig_lab = {'HbO','HbR','HbT','Ca'};
sig_col = [cb10(2,:); cb10(8,:); cb10(3,:); cb10(9,:)];
 
cparams          = struct();
cparams.Fs       = frameRate_fus;
cparams.tapers   = [5 9];
cparams.fpass    = [0 1];
cparams.pad      = 0;
cparams.trialave = 1;
 
movingwin = [30 2];             % [window step] in seconds
 
xc = detrend(fus_coh, 'linear'); xc = xc - mean(xc);
 
figure('Color','w');
for s = 1:numel(coh_sig)
    yy = detrend(coh_sig{s}(:), 'linear'); yy = yy - mean(yy);
    [C, ~, ~, ~, ~, t, f] = cohgramc(xc, yy, movingwin, cparams);
 
    subplot(2,2,s);
    imagesc(t, f, C'); axis xy; colorbar
    xlabel('Time (s)', 'FontSize', fntz); ylabel('Frequency (Hz)', 'FontSize', fntz);
    title(sprintf('fUS vs %s', sig_lab{s}));
    colormap parula; clim([0 1])
end
sgtitle('Time-varying coherence (cohgramc)');
