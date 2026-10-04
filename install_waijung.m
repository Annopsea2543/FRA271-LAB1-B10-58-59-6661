%% =========================================================================
%  MATLAB Master Script: Magnetic Sensor Real-Time Scope & Data Logger
%  Target: STM32G474RE | Sensor: DRV5055 | Lab 1.2
% =========================================================================

clear; clc; close all;

%% 1. ตั้งค่าระบบ (System Configuration)
COM_PORT    = 'COM3';      % ST-LINK VCP Port
BAUD_RATE   = 2000000;     % Baud Rate 2 Mbps สอดคล้องกับ Simulink
VCC         = 3300;        % Supply Voltage (mV)
ADC_RES     = 4095;        % 12-bit ADC Resolution
VQ          = 1650;        % Quiescent Voltage (mV) @ 3.3V
SENSITIVITY = 25;          % Sens (mV/mT) ตามรุ่น DRV5055

%% 2. เมนูเลือกเงื่อนไขการทดลอง (Interactive Setup)
fprintf('=====================================================\n');
fprintf('   MATLAB Expert System: Magnetic Sensor Master Control\n');
fprintf('=====================================================\n');

pole_choice   = input('เลือกขั้วแม่เหล็ก (1: North, 2: South): ');
shield_choice = input('เลือกการใส่ Shield (1: No Shield, 2: Shield): ');

if pole_choice == 1, pole_str = 'North'; else, pole_str = 'South'; end
if shield_choice == 1, shield_str = 'No_Shield'; else, shield_str = 'Shield'; end

% สร้างโครงสร้างโฟลเดอร์จัดเก็บข้อมูลอัตโนมัติ
folder_name   = sprintf('Experiment_Data/%s_%s', pole_str, shield_str);
if ~exist(folder_name, 'dir'), mkdir(folder_name); end
timestamp_str = datestr(now, 'yyyymmdd_HHMMSS');
csv_filename  = fullfile(folder_name, sprintf('Data_%s_%s_%s.csv', pole_str, shield_str, timestamp_str));

%% 3. เชื่อมต่อพอร์ตและเตรียมหน้าต่าง Real-Time Scope
try
    s = serialport(COM_PORT, BAUD_RATE);
    configureTerminator(s, "CR/LF");
    flush(s);
catch ME
    error('ไม่สามารถเปิด Serial Port %s ได้ กรุณาตรวจสอบพอร์ตการเชื่อมต่อหรือการเปิดซ้ำ', COM_PORT);
end

% สร้าง GUI Live Scope Control Panel
fig_scope = figure('Name', 'Real-Time Magnetic Scope Control', ...
                   'NumberTitle', 'off', 'Position', [100, 100, 900, 500], ...
                   'Color', [0.15 0.15 0.15]);

% กราฟ Real-time Scope
ax_scope = axes('Parent', fig_scope, 'Position', [0.1, 0.35, 0.85, 0.55], ...
                'Color', [0.05 0.05 0.05], 'XColor', 'w', 'YColor', 'w');
grid(ax_scope, 'on'); hold(ax_scope, 'on');
ax_scope.GridColor = [0.3 0.3 0.3]; ax_scope.GridAlpha = 0.8;
xlabel(ax_scope, 'Time (s)', 'Color', 'w');
ylabel(ax_scope, 'Vout (mV)', 'Color', 'w');
title(ax_scope, sprintf('Scope: Live Output Voltage (%s | %s)', pole_str, shield_str), 'Color', 'w');
h_line = animatedline(ax_scope, 'Color', [0 1 0.8], 'LineWidth', 1.5); % สีสไตล์ Oscilloscope

% ปุ่มควบคุม (Stop Button)
stop_flag = false;
btn_stop = uicontrol('Parent', fig_scope, 'Style', 'pushbutton', ...
                     'String', 'STOP & SAVE (เมื่อเลื่อนถึง 0 cm)', ...
                     'Position', [320, 25, 260, 45], 'FontSize', 11, 'FontWeight', 'bold', ...
                     'BackgroundColor', [0.85, 0.2, 0.2], 'ForegroundColor', [1, 1, 1], ...
                     'Callback', @(src, event) assignin('caller', 'stop_flag', true));

%% 4. เริ่มบันทึกข้อมูล Real-Time
time_data = []; adc_data = []; vout_data = []; b_data = [];
start_time = tic;

fprintf('\n---> เริ่มอ่านค่า Real-Time (เลื่อนแม่เหล็กจาก 4.5 cm -> 0 cm ตามสะดวก)... <---\n');

while ~stop_flag && ishandle(fig_scope)
    t_curr = toc(start_time);
    
    if s.NumBytesAvailable > 0
        data_line = readline(s);
        str_data  = strtrim(char(data_line));
        
        if ~isempty(str_data)
            adc_val = str2double(str_data);
            
            if ~isnan(adc_val) && adc_val >= 0 && adc_val <= 4095
                vout    = (adc_val / ADC_RES) * VCC;
                b_field = (vout - VQ) / SENSITIVITY;
                
                time_data(end+1, 1) = t_curr;
                adc_data(end+1, 1)  = adc_val;
                vout_data(end+1, 1) = vout;
                b_data(end+1, 1)    = b_field;
                
                % อัปเดตกราฟ Live Scope
                addpoints(h_line, t_curr, vout);
                xlim(ax_scope, [max(0, t_curr - 10), max(10, t_curr)]);
                ylim(ax_scope, [0, 3300]);
                drawnow limitrate;
            end
        end
    end
    pause(0.001); % เหมาะสมกับการรับส่งข้อมูลความเร็วสูง 2 Mbps
end

% ปิดการเชื่อมต่อและบันทึกรูป Scope
if ishandle(fig_scope)
    saveas(fig_scope, fullfile(folder_name, 'Scope_Live_View.png'));
    close(fig_scope);
end
clear s;

%% 5. คำนวณระยะทางย้อนหลังและจัดเก็บไฟล์ CSV
if isempty(time_data)
    error('ไม่พบข้อมูลที่อ่านได้จาก Serial Port กรุณาตรวจสอบการส่งข้อมูลใน Simulink');
end

total_time = max(time_data);
dist_data  = 4.5 * (1 - (time_data / total_time));
dist_data(dist_data < 0) = 0;

data_table = table(time_data, dist_data, adc_data, vout_data, b_data, ...
    'VariableNames', {'Time_s', 'Distance_cm', 'ADC_Value', 'Vout_mV', 'B_mT'});
writetable(data_table, csv_filename);
fprintf('\nบันทึกไฟล์ CSV สำเร็จ: %s\n', csv_filename);

%% 6. ประมวลผลและสร้างรูปกราฟวิเคราะห์ 7 รูปแบบอัตโนมัติ
fprintf('กำลังบันทึกรูปกราฟวิเคราะห์ทั้ง 7 รูปแบบลงโฟลเดอร์...\n');

plots_config = {
    dist_data, b_data,     'Distance (cm)', 'B (mT)',       sprintf('1_B_vs_Distance (%s, %s)', pole_str, shield_str),       'r-', true;
    dist_data, vout_data,  'Distance (cm)', 'Vout (mV)',    sprintf('2_Vout_vs_Distance (%s, %s)', pole_str, shield_str),    'b-', true;
    dist_data, adc_data,   'Distance (cm)', 'ADC Value',    sprintf('3_Analog_vs_Distance (%s, %s)', pole_str, shield_str),  'm-', true;
    time_data, b_data,     'Time (s)',      'B (mT)',       sprintf('4_B_vs_Realtime (%s, %s)', pole_str, shield_str),       'r-', false;
    time_data, vout_data,  'Time (s)',      'Vout (mV)',    sprintf('5_Vout_vs_Realtime (%s, %s)', pole_str, shield_str),    'b-', false;
    time_data, adc_data,   'Time (s)',      'ADC Value',    sprintf('6_Analog_vs_Realtime (%s, %s)', pole_str, shield_str),  'm-', false;
};

for i = 1:size(plots_config, 1)
    f = figure('Visible', 'off');
    plot(plots_config{i,1}, plots_config{i,2}, plots_config{i,6}, 'LineWidth', 1.5);
    if plots_config{i,7}, set(gca, 'XDir', 'reverse'); end
    grid on; xlabel(plots_config{i,3}); ylabel(plots_config{i,4}); title(plots_config{i,5});
    saveas(f, fullfile(folder_name, [plots_config{i,5}(1:17) '.png']));
    close(f);
end

% กราฟที่ 7: Linearity (Vout vs B)
f7 = figure('Visible', 'off');
plot(b_data, vout_data, 'k.', 'MarkerSize', 8); grid on; hold on;
b_theory = linspace(min(b_data), max(b_data), 100);
v_theory = VQ + b_theory * SENSITIVITY;
plot(b_theory, v_theory, 'r--', 'LineWidth', 1.5);
xlabel('Magnetic Flux Density B (mT)'); ylabel('Output Voltage Vout (mV)');
title(sprintf('7_Linearity (Vout vs B) - %s, %s', pole_str, shield_str));
legend('Measured Data', 'Theoretical Linearity', 'Location', 'best');
saveas(f7, fullfile(folder_name, '7_Linearity_Vout_vs_B.png'));
close(f7);

fprintf('=== การบันทึกและประมวลผลเสร็จสมบูรณ์เรียบร้อย! ===\n');