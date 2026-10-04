%% LAB 1.2 Magnetic Sensor (DRV5055) - Master Data Acquisition & Plotting
%  สคริปต์ควบคุมการเก็บบันทึก ประมวลผล และส่งออกข้อมูลการทดลองอัตโนมัติ (.png และ .fig)
clear; clc; close all;

% =========================================================================
% 1. ตั้งค่าคอนฟิกและโครงสร้างโฟลเดอร์ (System Configurations)
% =========================================================================
modelName = 'sensorExpoler'; % ชื่อไฟล์ Simulink Model (.slx)
V_Q = 1650;                       % Quiescent Voltage (mV) ที่วัดได้จริงขณะ B = 0
Sensitivity = 15;                % Sensitivity (mV/mT) สำหรับ DRV5055A3 ที่ Vcc = 3.3V
distances = [4.5, 4.0, 3.5, 3.0, 2.5, 2.0, 1.5, 1.0, 0.5, 0.0]; % ระยะห่าง (cm)

conditions = {'North_NoShield', 'North_Shielded', 'South_NoShield', 'South_Shielded'};
baseDir = 'Data_LAB1_2';

if ~exist(baseDir, 'dir'), mkdir(baseDir); end
for c = 1:length(conditions)
    folderPath = fullfile(baseDir, conditions{c});
    if ~exist(folderPath, 'dir'), mkdir(folderPath); end
end

% =========================================================================
% 2. เมนูเลือกสภาวะการทดลอง และรัน Simulink Real-time 20 วินาที
% =========================================================================
disp('=================================================================');
disp('   LAB 1.2 DRV5055 MAGNETIC SENSOR DATA ACQUISITION SYSTEM       ');
disp('=================================================================');
disp('เลือกสภาวะการทดลองที่ต้องการบันทึก:');
disp(' 1) North Pole - No Shield');
disp(' 2) North Pole - Shielded');
disp(' 3) South Pole - No Shield');
disp(' 4) South Pole - Shielded');
choice = input('ระบุหมายเลขสภาวะ (1-4): ');

currentCond = conditions{choice};
targetFolder = fullfile(baseDir, currentCond);

disp(['---> สภาวะที่เลือก: ' currentCond]);
disp('---> กำหนดเวลาบันทึก Simulink เป็น 20 วินาที อัตโนมัติ...');
set_param(modelName, 'StopTime', '20');

% สั่งรัน Simulink สำหรับเก็บ Real-time 20 วินาที ณ จุดอ้างอิง
disp('---> กำลังเริ่มบันทึกสัญญาณ Real-time (20 วินาที)...');
sim(modelName);

% ดึงข้อมูล Real-time จาก Simulink Workspace
t_rt = B_data.Time;
B_rt = B_data.Data;          % SI Derived Unit: mT
Vout_rt = Vout_data.Data;    % mV
Analog_rt = Analog_data.Data;% Raw ADC (0-4095)

% บันทึกไฟล์ Real-time (.mat & .csv)
save(fullfile(targetFolder, 'Realtime_Data.mat'), 't_rt', 'B_rt', 'Vout_rt', 'Analog_rt');
writetable(table(t_rt, Analog_rt, Vout_rt, B_rt), fullfile(targetFolder, 'Realtime_Data.csv'));

% =========================================================================
% 3. การกรอก/บันทึกผลการเลื่อนระยะ (Distance Sweeping Data Entry)
% =========================================================================
disp('-----------------------------------------------------------------');
disp('ป้อนค่าเฉลี่ย Raw ADC ที่อ่านได้จาก Simulink ในแต่ละระยะทาง (cm):');
Analog_dist = zeros(size(distances));
for d = 1:length(distances)
    Analog_dist(d) = input(sprintf('  ระยะ x = %.1f cm (Raw ADC): ', distances(d)));
end

% คำนวณ Vout และ B ตามลำดับ
Vout_dist = Analog_dist * (3300 / 4095);     % mV
B_dist = (Vout_dist - V_Q) / Sensitivity;     % mT

% บันทึกไฟล์ Distance Sweeping (.mat & .csv)
save(fullfile(targetFolder, 'Distance_Data.mat'), 'distances', 'Analog_dist', 'Vout_dist', 'B_dist');
writetable(table(distances', Analog_dist', Vout_dist', B_dist', ...
    'VariableNames', {'Distance_cm', 'Analog_Raw', 'Vout_mV', 'B_mT'}), ...
    fullfile(targetFolder, 'Distance_Data.csv'));

% =========================================================================
% 4. การสร้างและส่งออกรูปกราฟทั้ง 7 รูปแบบ (.png และ .fig)
% =========================================================================
disp('---> กำลังสร้างและบันทึกรูปกราฟทั้ง 7 รูปแบบ (.png และ .fig)...');

% 4.1 B vs Distance
fig1 = figure('Visible', 'off');
plot(distances, B_dist, '-o', 'LineWidth', 2, 'Color', [0 0.4470 0.7410], 'MarkerFaceColor', 'b');
grid on; title(['B vs Distance (', currentCond, ')']);
xlabel('Distance from Sensor (cm)'); ylabel('Magnetic Flux Density B (mT)');
saveas(fig1, fullfile(targetFolder, 'B_vs_Distance.png'));
savefig(fig1, fullfile(targetFolder, 'B_vs_Distance.fig'));

% 4.2 Vout vs Distance
fig2 = figure('Visible', 'off');
plot(distances, Vout_dist, '-s', 'LineWidth', 2, 'Color', [0.8500 0.3250 0.0980], 'MarkerFaceColor', 'r');
grid on; title(['V_{out} vs Distance (', currentCond, ')']);
xlabel('Distance from Sensor (cm)'); ylabel('Output Voltage V_{out} (mV)');
saveas(fig2, fullfile(targetFolder, 'Vout_vs_Distance.png'));
savefig(fig2, fullfile(targetFolder, 'Vout_vs_Distance.fig'));

% 4.3 Analog vs Distance
fig3 = figure('Visible', 'off');
plot(distances, Analog_dist, '-^', 'LineWidth', 2, 'Color', [0.9290 0.6940 0.1250], 'MarkerFaceColor', 'y');
grid on; title(['Analog (Raw ADC) vs Distance (', currentCond, ')']);
xlabel('Distance from Sensor (cm)'); ylabel('Raw ADC Value (12-bit)');
saveas(fig3, fullfile(targetFolder, 'Analog_vs_Distance.png'));
savefig(fig3, fullfile(targetFolder, 'Analog_vs_Distance.fig'));

% 4.4 B vs Realtime
fig4 = figure('Visible', 'off');
plot(t_rt, B_rt, 'LineWidth', 1.5, 'Color', [0 0.4470 0.7410]);
grid on; title(['Real-time B (20 seconds) - ', currentCond]);
xlabel('Time (s)'); ylabel('Magnetic Flux Density B (mT)');
saveas(fig4, fullfile(targetFolder, 'B_vs_Realtime.png'));
savefig(fig4, fullfile(targetFolder, 'B_vs_Realtime.fig'));

% 4.5 Vout vs Realtime
fig5 = figure('Visible', 'off');
plot(t_rt, Vout_rt, 'LineWidth', 1.5, 'Color', [0.8500 0.3250 0.0980]);
grid on; title(['Real-time V_{out} (20 seconds) - ', currentCond]);
xlabel('Time (s)'); ylabel('Output Voltage V_{out} (mV)');
saveas(fig5, fullfile(targetFolder, 'Vout_vs_Realtime.png'));
savefig(fig5, fullfile(targetFolder, 'Vout_vs_Realtime.fig'));

% 4.6 Analog vs Realtime
fig6 = figure('Visible', 'off');
plot(t_rt, Analog_rt, 'LineWidth', 1.5, 'Color', [0.4660 0.6740 0.1880]);
grid on; title(['Real-time Analog Signal (20 seconds) - ', currentCond]);
xlabel('Time (s)'); ylabel('Raw ADC Value');
saveas(fig6, fullfile(targetFolder, 'Analog_vs_Realtime.png'));
savefig(fig6, fullfile(targetFolder, 'Analog_vs_Realtime.fig'));

% 4.7 Linearity (Vout vs B) พร้อมการวิเคราะห์ Regression (R^2)
fig7 = figure('Visible', 'off');
scatter(B_dist, Vout_dist, 60, 'filled', 'MarkerFaceColor', [0.4940 0.1840 0.5560]); hold on;
p = polyfit(B_dist, Vout_dist, 1);
B_fit = linspace(min(B_dist), max(B_dist), 100);
Vout_fit = polyval(p, B_fit);
plot(B_fit, Vout_fit, '--r', 'LineWidth', 1.5);
yresid = Vout_dist - polyval(p, B_dist);
SSresid = sum(yresid.^2);
SStotal = (length(Vout_dist)-1) * var(Vout_dist);
r2 = 1 - SSresid/SStotal;
grid on; title(sprintf('Linearity (V_{out} vs B) | R^2 = %.4f', r2));
xlabel('Magnetic Flux Density B (mT)'); ylabel('Output Voltage V_{out} (mV)');
legend('Experimental Data', sprintf('Linear Fit: V_{out} = %.2f B + %.1f', p(1), p(2)), 'Location', 'southeast');
saveas(fig7, fullfile(targetFolder, 'Linearity_Vout_vs_B.png'));
savefig(fig7, fullfile(targetFolder, 'Linearity_Vout_vs_B.fig'));

disp('=================================================================');
disp('   การจัดเก็บข้อมูลและบันทึกรูปกราฟ (.png & .fig) เสร็จสิ้นสมบูรณ์!   ');
disp('=================================================================');


% วิธีรันโค้ดดูกราฟ พิมพ์อันนี้ลง command window และแก้ข้อมูลตามที่อยู่ไฟล์ที่อยากดู
% h = openfig('Data_LAB1_2/North_NoShield/B_vs_Distance.fig');
% set(h, 'Visible', 'on');