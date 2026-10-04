%% LAB 1.2 - Comparative Analysis Script (Shielding & Repeatability)
%  สคริปต์ดึงข้อมูล 4 สภาวะมาพล็อตเปรียบเทียบผลของ Magnetic Shielding (.png & .fig)
clear; clc; close all;

baseDir = 'Data_LAB1_2';
conds = {'North_NoShield', 'North_Shielded', 'South_NoShield', 'South_Shielded'};

% ตรวจสอบว่าเก็บข้อมูลครบทั้ง 4 โฟลเดอร์หรือยัง
for c = 1:length(conds)
    filePath = fullfile(baseDir, conds{c}, 'Distance_Data.mat');
    if ~exist(filePath, 'file')
        error('ไม่พบไฟล์ %s กรุณารัน Master Script เก็บข้อมูลสภาวะ %s ให้ครบก่อนครับ', filePath, conds{c});
    end
end

% โหลดข้อมูลจากทั้ง 4 สภาวะ
data_N_NS = load(fullfile(baseDir, conds{1}, 'Distance_Data.mat'));
data_N_S  = load(fullfile(baseDir, conds{2}, 'Distance_Data.mat'));
data_S_NS = load(fullfile(baseDir, conds{3}, 'Distance_Data.mat'));
data_S_S  = load(fullfile(baseDir, conds{4}, 'Distance_Data.mat'));

% =========================================================================
% 1. กราฟเปรียบเทียบรวม 2 Subplots (North vs South)
% =========================================================================
fig_comp = figure('Visible', 'off', 'Position', [100 100 1000 450]);

% Subplot 1: North Pole
subplot(1,2,1);
plot(data_N_NS.distances, data_N_NS.B_dist, '-ob', 'LineWidth', 2, 'MarkerFaceColor', 'b'); hold on;
plot(data_N_S.distances,  data_N_S.B_dist,  '--sr', 'LineWidth', 2, 'MarkerFaceColor', 'r');
grid on; xlabel('Distance from Sensor (cm)'); ylabel('Magnetic Flux Density B (mT)');
title('Shielding Effect (North Pole)');
legend('Unshielded', 'Shielded', 'Location', 'best');

% Subplot 2: South Pole
subplot(1,2,2);
plot(data_S_NS.distances, data_S_NS.B_dist, '-ob', 'LineWidth', 2, 'MarkerFaceColor', 'b'); hold on;
plot(data_S_S.distances,  data_S_S.B_dist,  '--sr', 'LineWidth', 2, 'MarkerFaceColor', 'r');
grid on; xlabel('Distance from Sensor (cm)'); ylabel('Magnetic Flux Density B (mT)');
title('Shielding Effect (South Pole)');
legend('Unshielded', 'Shielded', 'Location', 'best');

% บันทึกกราฟรวมทั้ง .png และ .fig ไว้ที่โฟลเดอร์หลัก Data_LAB1_2
saveas(fig_comp, fullfile(baseDir, 'Shielding_Comparison_Analysis.png'));
savefig(fig_comp, fullfile(baseDir, 'Shielding_Comparison_Analysis.fig'));

% =========================================================================
% 2. กราฟเปรียบเทียบรวม 4 เส้นในรูปเดียว (Combined All Conditions)
% =========================================================================
fig_all = figure('Visible', 'off');
plot(data_N_NS.distances, data_N_NS.B_dist, '-ob', 'LineWidth', 2, 'MarkerFaceColor', 'b'); hold on;
plot(data_N_S.distances,  data_N_S.B_dist,  '--oc', 'LineWidth', 2, 'MarkerFaceColor', 'c');
plot(data_S_NS.distances, data_S_NS.B_dist, '-sr', 'LineWidth', 2, 'MarkerFaceColor', 'r');
plot(data_S_S.distances,  data_S_S.B_dist,  '--sm', 'LineWidth', 2, 'MarkerFaceColor', 'm');
grid on; xlabel('Distance from Sensor (cm)'); ylabel('Magnetic Flux Density B (mT)');
title('Combined Shielding & Polarity Comparison');
legend('North - Unshielded', 'North - Shielded', 'South - Unshielded', 'South - Shielded', 'Location', 'best');

% บันทึกกราฟรวม 4 เส้นทั้ง .png และ .fig
saveas(fig_all, fullfile(baseDir, 'All_Conditions_Comparison.png'));
savefig(fig_all, fullfile(baseDir, 'All_Conditions_Comparison.fig'));

disp('=================================================================');
disp('   สร้างและบันทึกกราฟเปรียบเทียบ (.png & .fig) เรียบร้อยแล้ว!      ');
disp('=================================================================');