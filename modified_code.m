clear; clc; close all;

fprintf('🚀 === 5G Network Simulation Configuration ===\n');
fprintf('Select Simulation Configuration:\n');
fprintf('1. Fixed gNB Environment Testing\n');
fprintf('2. Mobile gNB Scalability Testing\n');
config = input('Enter choice (1 or 2): ');

if config ~= 1 && config ~= 2
    error('Invalid configuration choice. Please select 1 or 2.');
end

fprintf('\n📱 User Equipment Configuration:\n');
ue_count = input('Enter number of UEs (recommended: 50-500): ');

if ue_count < 1 || ue_count > 1000
    error('Invalid UE count. Please enter a value between 1 and 1000.');
end

fprintf('\n📡 gNodeB Configuration:\n');
if config == 1
    fprintf('Fixed gNodeB mode selected.\n');
    gnb_count = input('Enter number of gNodeBs (recommended: 4-25): ');
    gNB_mobility = false;
else
    fprintf('Mobile gNodeB mode selected.\n');
    gnb_count = input('Enter number of gNodeBs (recommended: 9-50): ');
    gNB_mobility = true;
end

if gnb_count < 1 || gnb_count > 100
    error('Invalid gNodeB count. Please enter a value between 1 and 100.');
end

fprintf('\n✅ Configuration Summary:\n');
if config == 1
    fprintf('  Mode: Fixed gNodeB Environment Testing\n');
else
    fprintf('  Mode: Mobile gNodeB Scalability Testing\n');
end
fprintf('  UEs: %d\n', ue_count);
fprintf('  gNodeBs: %d\n', gnb_count);
if gNB_mobility
    fprintf('  gNodeB Mobility: Enabled\n');
else
    fprintf('  gNodeB Mobility: Disabled\n');
end
fprintf('  Environments: Urban, Suburban, Rural (Auto-run)\n');
fprintf('  Simulation Duration: 25 time steps\n');

proceed = input('\nProceed with simulation? (y/n): ', 's');
if ~strcmpi(proceed, 'y') && ~strcmpi(proceed, 'yes')
    fprintf('Simulation cancelled.\n');
    return;
end

time_steps = 25;
movement_range = 15;
gNB_movement_range = 5;
colors = lines(50);

apps = {'Emergency','Video_Call','Voice_Call','Streaming',...
        'Online_Gaming','Background','Web_Browsing','IoT_Temp','Video_Streaming'};
req_bw_range = [5 3 1.5 2.5 2 0.8 1.2 0.1 2];

all_data = {};
environment_results = struct();
handover_visualization_data = struct();

environments = {
    struct('name', 'Urban', 'area_size', 500, 'interference_base', 1.2, 'path_loss_exp', 3.5, 'base_latency', 4);
    struct('name', 'Suburban', 'area_size', 800, 'interference_base', 1.0, 'path_loss_exp', 3.0, 'base_latency', 6);
    struct('name', 'Rural', 'area_size', 1200, 'interference_base', 0.8, 'path_loss_exp', 2.5, 'base_latency', 8);
};

if config == 1
    fprintf('\n🏙️ === CASE 1: FIXED gNODEB ENVIRONMENT TESTING ===\n');
    fprintf('Features: Fixed gNodeB positions, Environment comparison\n');
else
    fprintf('\n🚀 === CASE 2: MOBILE gNODEB SCALABILITY TESTING ===\n');
    fprintf('Features: Mobile gNodeBs, Advanced mobility patterns\n');
end

for env_idx = 1:length(environments)
    env = environments{env_idx};
    fprintf('\n🌍 === RUNNING %s ENVIRONMENT ===\n', upper(env.name));
    
    environment_results.(env.name) = struct();
    handover_visualization_data.(env.name) = struct();
    
    fprintf('\n=== %s: %d UEs, %d gNBs ===\n', env.name, ue_count, gnb_count);
    
    if gnb_count <= 4
        rows = 2; cols = 2;
        fprintf('  Grid Layout: 2x2 (Small network)\n');
    elseif gnb_count <= 9
        rows = 3; cols = 3;
        fprintf('  Grid Layout: 3x3 (Medium network)\n');
    elseif gnb_count <= 16
        rows = 4; cols = 4;
        fprintf('  Grid Layout: 4x4 (Large network)\n');
    elseif gnb_count <= 25
        rows = 5; cols = 5;
        fprintf('  Grid Layout: 5x5 (Very large network)\n');
    elseif gnb_count <= 36
        rows = 6; cols = 6;
        fprintf('  Grid Layout: 6x6 (Dense network)\n');
    else
        rows = ceil(sqrt(gnb_count));
        cols = rows;
        fprintf('  Grid Layout: %dx%d (Ultra-dense network)\n', rows, cols);
    end
    
    spacing_x = env.area_size / (cols + 1);
    spacing_y = env.area_size / (rows + 1);
    gNB_pos = zeros(gnb_count, 2, time_steps);
    
    g = 1;
    for r = 1:rows
        for c = 1:cols
            if g > gnb_count
                break;
            end
            gNB_pos(g,:,1) = [c*spacing_x, r*spacing_y];
            g = g + 1;
        end
        if g > gnb_count
            break;
        end
    end
    
    UE_pos = zeros(ue_count, 2, time_steps);
    UE_gnb_assoc = zeros(ue_count, time_steps);
    handover_count = zeros(ue_count, 1);
    handover_times = cell(ue_count, 1);
    data = {};
    
    UE_app = repmat(apps, 1, ceil(ue_count / length(apps)));
    UE_app = UE_app(1:ue_count);
    
    for i = 1:ue_count
        gnb_idx = mod(i-1, gnb_count) + 1;
        center = gNB_pos(gnb_idx,:,1);
        UE_pos(i,:,1) = center + randi([-20,20], 1, 2);
        UE_pos(i,:,1) = min(max(UE_pos(i,:,1), 10), env.area_size-10);
        handover_times{i} = [];
    end
    
    fprintf('📡 Displaying initial network topology...\n');
    fig_sim = figure('Name', sprintf('%s Environment - Live Simulation', env.name), ...
                   'Position', [50, 50, 900, 700]);
    
    clf; hold on; grid on;
    title(sprintf('Initial Topology - %s Environment\n%d gNBs, %d UEs', ...
        env.name, gnb_count, ue_count), 'FontSize', 14, 'FontWeight', 'bold');
    xlabel('X Position (m)'); ylabel('Y Position (m)');
    xlim([0 env.area_size]); ylim([0 env.area_size]);
    
    scatter(gNB_pos(:,1,1), gNB_pos(:,2,1), 300, 'ks', 'filled', 'MarkerEdgeColor', 'white', 'LineWidth', 2);
    for g = 1:gnb_count
        text(gNB_pos(g,1,1)+10, gNB_pos(g,2,1)+10, sprintf('gNB %d', g), ...
            'FontWeight','bold', 'FontSize', 12, 'Color', 'blue');
    end
    
    initial_pos = UE_pos(:,:,1);
    scatter(initial_pos(:,1), initial_pos(:,2), 50, 'ro', 'filled', 'MarkerEdgeColor', 'black');
    
    legend({'gNodeBs', 'User Equipment'}, 'Location', 'best', 'FontSize', 12);
    
    if gNB_mobility
        mobility_text = 'Yes';
    else
        mobility_text = 'No';
    end
    
    text(env.area_size*0.02, env.area_size*0.95, sprintf('Environment: %s\nArea: %dx%d m\nMoving gNBs: %s', ...
        env.name, env.area_size, env.area_size, mobility_text), ...
        'FontSize', 10, 'BackgroundColor', 'white', 'EdgeColor', 'black');
    
    drawnow;
    pause(3);
    
    gNB_max_capacity = 200;
    
    fprintf('🚀 Starting dynamic simulation...\n');
    
    for t = 1:time_steps
        
        gNB_current_load = zeros(gnb_count, 1);
        interference_factor = zeros(ue_count, 1);
        handovers_this_step = [];
        
        if t > 1
            if config == 1
                gNB_pos(:,:,t) = gNB_pos(:,:,t-1);
            else
                for g = 1:gnb_count
                    if gnb_count <= 9
                        gNB_move = randi([-gNB_movement_range, gNB_movement_range], 1, 2);
                    elseif gnb_count <= 25
                        gNB_move = randi([-gNB_movement_range+2, gNB_movement_range-2], 1, 2);
                    else
                        gNB_move = randi([-gNB_movement_range+3, gNB_movement_range-3], 1, 2);
                    end
                    
                    gNB_pos(g,:,t) = gNB_pos(g,:,t-1) + gNB_move;
                    margin = env.area_size * 0.1;
                    gNB_pos(g,:,t) = min(max(gNB_pos(g,:,t), margin), env.area_size - margin);
                end
            end
        else
            gNB_pos(:,:,1) = gNB_pos(:,:,1);
        end
        
        for i = 1:ue_count
            if t > 1
                move = randi([-movement_range, movement_range], 1, 2);
                UE_pos(i,:,t) = UE_pos(i,:,t-1) + move;
                UE_pos(i,:,t) = min(max(UE_pos(i,:,t), 0), env.area_size);
            end
            
            pos = UE_pos(i,:,t);
            current_gNB_pos = gNB_pos(:,:,t);
            distances = sqrt(sum((current_gNB_pos - pos).^2, 2));
            [min_dist, new_gnb] = min(distances);
            UE_gnb_assoc(i,t) = new_gnb;
            
            other_gNBs = setdiff(1:gnb_count, new_gnb);
            interference_power = 0;
            for other_gnb = other_gNBs
                other_dist = distances(other_gnb);
                interference_power = interference_power + ...
                    10^((-45 - other_dist * 0.035 * env.path_loss_exp)/10);
            end
            interference_factor(i) = interference_power * env.interference_base;
            
            if t > 1 && UE_gnb_assoc(i,t) ~= UE_gnb_assoc(i,t-1)
                handover_count(i) = handover_count(i) + 1;
                handover_times{i}(end+1) = t;
                handovers_this_step(end+1) = i;
            end
        end
        
        clf; hold on; grid on;
        title(sprintf('%s Environment - Time Step %d/%d\nHandovers this step: %d', ...
            env.name, t, time_steps, length(handovers_this_step)), ...
            'FontSize', 14, 'FontWeight', 'bold');
        xlabel('X Position (m)'); ylabel('Y Position (m)');
        xlim([0 env.area_size]); ylim([0 env.area_size]);
        
        current_gNB_pos = gNB_pos(:,:,t);
        scatter(current_gNB_pos(:,1), current_gNB_pos(:,2), 300, 'ks', 'filled', ...
               'MarkerEdgeColor', 'white', 'LineWidth', 2);
        
        for g = 1:gnb_count
            text(current_gNB_pos(g,1)+10, current_gNB_pos(g,2)+10, sprintf('gNB %d', g), ...
                'FontWeight','bold', 'FontSize', 10, 'Color', 'blue');
        end
        
        current_ue_pos = UE_pos(:,:,t);
        for i = 1:ue_count
            serving_gnb = UE_gnb_assoc(i,t);
            
            if ismember(i, handovers_this_step)
                scatter(current_ue_pos(i,1), current_ue_pos(i,2), 80, 'y', 'd', 'filled', ...
                       'MarkerEdgeColor', 'red', 'LineWidth', 2);
            else
                scatter(current_ue_pos(i,1), current_ue_pos(i,2), 40, colors(serving_gnb,:), 'o', 'filled', ...
                       'MarkerEdgeColor', 'black');
            end
            
            if ismember(i, handovers_this_step)
                text(current_ue_pos(i,1)+5, current_ue_pos(i,2)+5, sprintf('UE%d', i), ...
                    'FontSize', 8, 'Color', 'red', 'FontWeight', 'bold');
            end
        end
        
        if gNB_mobility
            mobility_status = 'Yes';
        else
            mobility_status = 'No';
        end
        
        info_text = sprintf('Time: %d/%d\nTotal UEs: %d\nActive gNBs: %d\nHandovers: %d\nMoving gNBs: %s', ...
            t, time_steps, ue_count, gnb_count, length(handovers_this_step), mobility_status);
        text(env.area_size*0.02, env.area_size*0.95, info_text, ...
            'FontSize', 9, 'BackgroundColor', 'white', 'EdgeColor', 'black', ...
            'VerticalAlignment', 'top');
        
        drawnow;
        pause(0.5);
        
        for i = 1:ue_count
            pos = UE_pos(i,:,t);
            current_gNB_pos = gNB_pos(:,:,t);
            distances = sqrt(sum((current_gNB_pos - pos).^2, 2));
            [min_dist, new_gnb] = min(distances);
            
            RSSI = -30 - min_dist * 0.8 - 10*log10(1 + interference_factor(i));
            RSRP = RSSI - 5;
            
            signal_power = 10^(RSRP/10);
            noise_power = 10^(-100/10);
            interference_power_linear = interference_factor(i) * 10^(-80/10);
            SINR = 10*log10(signal_power / (interference_power_linear + noise_power));
            SINR = max(-10, min(SINR, 30));
            
            RSRQ = RSRP - RSSI;
            RSRQ = max(-20, min(RSRQ, -3));
            
            latency = env.base_latency + 0.4 * min_dist + randi([0,3]);
            
            app = UE_app{i};
            app_idx = find(strcmp(apps, app));
            required_bw = req_bw_range(app_idx);
            
            base_throughput_clean = max(2.0, 15 - 0.4 * min_dist);
            interference_penalty = 1 / (1 + interference_factor(i));
            sinr_bonus = max(0.5, min(2.0, 1 + SINR/30));
            base_throughput = base_throughput_clean * interference_penalty * sinr_bonus;
            
            UEs_on_same_gNB = sum(UE_gnb_assoc(:,t) == new_gnb);
            congestion_factor = max(0.3, 1 - (UEs_on_same_gNB - 1) * 0.05);
            available_throughput = base_throughput * congestion_factor;
            
            remaining_capacity = gNB_max_capacity - gNB_current_load(new_gnb);
            capacity_limited_throughput = min(available_throughput, remaining_capacity);
            
            theoretical_allocation = min(required_bw, capacity_limited_throughput);
            
            if strcmp(app, 'Emergency')
                allocation_efficiency = 0.90 + 0.10 * rand();
            elseif strcmp(app, 'Voice_Call')
                allocation_efficiency = 0.85 + 0.10 * rand();
            else
                allocation_efficiency = 0.70 + 0.20 * rand();
            end
            
            allocated_bw = theoretical_allocation * allocation_efficiency;
            gNB_current_load(new_gnb) = gNB_current_load(new_gnb) + allocated_bw;
            
            alloc_percent = round((allocated_bw / required_bw) * 100);
            alloc_percent = max(5, min(alloc_percent, 100));
            
            data(end+1,:) = {
                t, ['User_' num2str(i)], app, ...
                sprintf('%.1f dBm', RSSI), sprintf('%.1f dBm', RSRP), ...
                sprintf('%.1f dB', SINR), sprintf('%.1f dB', RSRQ), ...
                sprintf('%d ms', round(latency)), ...
                sprintf('%.2f Mbps', required_bw), sprintf('%.2f Mbps', allocated_bw), ...
                sprintf('%d%%', alloc_percent), ...
                gnb_count, ue_count, env.name, gNB_mobility
            };
        end
        
        if mod(t, 5) == 0 || t == time_steps
            fprintf('  ⏱️  Step %d/%d completed, Handovers: %d\n', t, time_steps, length(handovers_this_step));
        end
    end
    
    config_key = sprintf('UE_%d_gNB_%d', ue_count, gnb_count);
    
    total_handovers = sum(handover_count);
    handover_ues = sum(handover_count > 0);
    avg_handovers_per_ue = total_handovers / ue_count;
    max_handovers = max(handover_count);
    
    environment_results.(env.name).(config_key) = struct(...
        'total_handovers', total_handovers, ...
        'handover_ues', handover_ues, ...
        'avg_handovers_per_ue', avg_handovers_per_ue, ...
        'max_handovers', max_handovers, ...
        'handover_rate', handover_ues/ue_count * 100 ...
    );
    
    handover_visualization_data.(env.name).(config_key) = struct(...
        'UE_pos', UE_pos, ...
        'gNB_pos', gNB_pos, ...
        'UE_gnb_assoc', UE_gnb_assoc, ...
        'handover_count', handover_count, ...
        'handover_times', {handover_times}, ...
        'area_size', env.area_size, ...
        'gNB_mobility', gNB_mobility ...
    );
    
    all_data = [all_data; data];
    
    avg_allocation = mean(cellfun(@(x) str2double(x(1:end-1)), data(end-ue_count+1:end, 11)));
    fprintf('✅ Completed: %d handover UEs (%.1f%%), Total: %d, Avg allocation: %.1f%%\n', ...
        handover_ues, handover_ues/ue_count*100, total_handovers, avg_allocation);
    
    if ishandle(fig_sim)
        close(fig_sim);
    end
    
end

T = cell2table(all_data, 'VariableNames', ...
    {'Timestamp','User_ID','Application','RSSI','RSRP','SINR','RSRQ','Latency', ...
     'Required_Mbps','Allocated_Mbps','Resource_Allocation', ...
     'gNB_Count','UE_Count','Environment','gNB_Mobile'});

if config == 1
    config_name = 'FixedgNB_EnvironmentTest';
else
    config_name = 'MobilegNB_ScalabilityTest';
end

filename = sprintf('5G_dataset_%s_UE%d_gNB%d.csv', config_name, ue_count, gnb_count);
writetable(T, filename);
fprintf('\n✅ Enhanced dataset saved as %s\n', filename);
fprintf('📊 Total records: %d\n', height(T));

%% === COMPREHENSIVE GRAPH ANALYSIS ===
fprintf('\n📊 Generating comprehensive analysis graphs...\n');

% === 1. Environment Comparison Bar Charts ===
figure('Name', 'Environment Performance Comparison', 'Position', [100, 100, 1400, 800]);

env_names = {'Urban', 'Suburban', 'Rural'};
config_key = sprintf('UE_%d_gNB_%d', ue_count, gnb_count);

% Collect data for all environments
handover_rates = [];
total_handovers = [];
avg_handovers = [];
max_handovers = [];

for env_idx = 1:3
    env_name = env_names{env_idx};
    if isfield(environment_results.(env_name), config_key)
        result = environment_results.(env_name).(config_key);
        handover_rates(end+1) = result.handover_rate;
        total_handovers(end+1) = result.total_handovers;
        avg_handovers(end+1) = result.avg_handovers_per_ue;
        max_handovers(end+1) = result.max_handovers;
    end
end

% Plot 1: Handover Rate Comparison
subplot(2, 2, 1);
bar(handover_rates, 'FaceColor', [0.3, 0.7, 0.9], 'EdgeColor', 'black', 'LineWidth', 1.5);
xlabel('Environment', 'FontSize', 12, 'FontWeight', 'bold');
ylabel('Handover Rate (%)', 'FontSize', 12, 'FontWeight', 'bold');
title('Handover Rate by Environment', 'FontSize', 14, 'FontWeight', 'bold');
xticklabels(env_names);
grid on;
% Add value labels on bars
for i = 1:length(handover_rates)
    text(i, handover_rates(i) + max(handover_rates)*0.02, sprintf('%.1f%%', handover_rates(i)), ...
        'HorizontalAlignment', 'center', 'FontWeight', 'bold');
end

% Plot 2: Total Handovers
subplot(2, 2, 2);
bar(total_handovers, 'FaceColor', [0.9, 0.3, 0.3], 'EdgeColor', 'black', 'LineWidth', 1.5);
xlabel('Environment', 'FontSize', 12, 'FontWeight', 'bold');
ylabel('Total Handovers', 'FontSize', 12, 'FontWeight', 'bold');
title('Total Handovers by Environment', 'FontSize', 14, 'FontWeight', 'bold');
xticklabels(env_names);
grid on;
% Add value labels on bars
for i = 1:length(total_handovers)
    text(i, total_handovers(i) + max(total_handovers)*0.02, sprintf('%d', total_handovers(i)), ...
        'HorizontalAlignment', 'center', 'FontWeight', 'bold');
end

% Plot 3: Average Handovers per UE
subplot(2, 2, 3);
bar(avg_handovers, 'FaceColor', [0.3, 0.9, 0.3], 'EdgeColor', 'black', 'LineWidth', 1.5);
xlabel('Environment', 'FontSize', 12, 'FontWeight', 'bold');
ylabel('Avg Handovers per UE', 'FontSize', 12, 'FontWeight', 'bold');
title('Average Handovers per UE', 'FontSize', 14, 'FontWeight', 'bold');
xticklabels(env_names);
grid on;
% Add value labels on bars
for i = 1:length(avg_handovers)
    text(i, avg_handovers(i) + max(avg_handovers)*0.02, sprintf('%.2f', avg_handovers(i)), ...
        'HorizontalAlignment', 'center', 'FontWeight', 'bold');
end

% Plot 4: Maximum Handovers
subplot(2, 2, 4);
bar(max_handovers, 'FaceColor', [0.9, 0.7, 0.3], 'EdgeColor', 'black', 'LineWidth', 1.5);
xlabel('Environment', 'FontSize', 12, 'FontWeight', 'bold');
ylabel('Maximum Handovers', 'FontSize', 12, 'FontWeight', 'bold');
title('Maximum Handovers per UE', 'FontSize', 14, 'FontWeight', 'bold');
xticklabels(env_names);
grid on;
% Add value labels on bars
for i = 1:length(max_handovers)
    text(i, max_handovers(i) + max(max_handovers)*0.02, sprintf('%d', max_handovers(i)), ...
        'HorizontalAlignment', 'center', 'FontWeight', 'bold');
end

sgtitle(sprintf('Handover Performance Analysis - %s\n%d UEs, %d gNBs', config_name, ue_count, gnb_count), ...
    'FontSize', 16, 'FontWeight', 'bold');

% === 2. UE Movement and Handover Visualization ===
figure('Name', 'UE Movement Trails and Handover Analysis', 'Position', [150, 150, 1600, 1000]);

for env_idx = 1:3
    env_name = env_names{env_idx};
    
    if isfield(handover_visualization_data.(env_name), config_key)
        viz_data = handover_visualization_data.(env_name).(config_key);
        
        % Top subplot: Movement trails
        subplot(3, 2, (env_idx-1)*2 + 1);
        hold on; grid on;
        
        % Plot gNB positions
        final_gNB_pos = viz_data.gNB_pos(:,:,end);
        scatter(final_gNB_pos(:,1), final_gNB_pos(:,2), 300, 'ks', 'filled', ...
               'MarkerEdgeColor', 'white', 'LineWidth', 3);
        
        % Plot gNB movement trails if mobile
        if viz_data.gNB_mobility
            for g = 1:min(gnb_count, 10) % Limit to first 10 for clarity
                gNB_trail = squeeze(viz_data.gNB_pos(g, :, :))';
                plot(gNB_trail(:,1), gNB_trail(:,2), 'k--', 'LineWidth', 2);
                % Mark start and end
                scatter(gNB_trail(1,1), gNB_trail(1,2), 80, 'g', 'filled', 's', 'MarkerEdgeColor', 'black');
                scatter(gNB_trail(end,1), gNB_trail(end,2), 80, 'r', 'filled', 's', 'MarkerEdgeColor', 'black');
            end
        end
        
        % Plot top handover UE trails
        [~, top_ho_idx] = sort(viz_data.handover_count, 'descend');
        top_ues = top_ho_idx(1:min(8, length(top_ho_idx)));
        
        trail_colors = lines(8);
        legend_entries = {'gNodeBs'};
        
        for i = 1:length(top_ues)
            ue_idx = top_ues(i);
            if viz_data.handover_count(ue_idx) > 0
                trail = squeeze(viz_data.UE_pos(ue_idx, :, :))';
                plot(trail(:,1), trail(:,2), '-', 'Color', trail_colors(i,:), 'LineWidth', 2.5);
                
                % Mark handover points
                ho_times = viz_data.handover_times{ue_idx};
                if ~isempty(ho_times)
                    ho_positions = trail(ho_times, :);
                    scatter(ho_positions(:,1), ho_positions(:,2), 120, 'y', 'filled', 'd', ...
                           'MarkerEdgeColor', 'red', 'LineWidth', 2);
                end
                
                % Mark start and end
                scatter(trail(1,1), trail(1,2), 100, 'g', 'filled', 'o', 'MarkerEdgeColor', 'black');
                scatter(trail(end,1), trail(end,2), 100, 'r', 'filled', 'o', 'MarkerEdgeColor', 'black');
                
                legend_entries{end+1} = sprintf('UE%d (%dHO)', ue_idx, viz_data.handover_count(ue_idx));
            end
        end
        
        if viz_data.gNB_mobility
            mobility_text_trail = 'Mobile gNBs';
        else
            mobility_text_trail = 'Fixed gNBs';
        end
        
        title(sprintf('%s: Top UE Movement Trails\n%s', env_name, mobility_text_trail), ...
            'FontSize', 12, 'FontWeight', 'bold');
        xlabel('X Position (m)'); ylabel('Y Position (m)');
        xlim([0, viz_data.area_size]); ylim([0, viz_data.area_size]);
        legend(legend_entries, 'Location', 'best', 'FontSize', 8);
        
        % Bottom subplot: Handover density heatmap
        subplot(3, 2, (env_idx-1)*2 + 2);
        hold on; grid on;
        
        % Create handover density scatter plot
        ue_final_pos = viz_data.UE_pos(:, :, end);
        
        % Plot gNBs
        scatter(final_gNB_pos(:,1), final_gNB_pos(:,2), 300, 'ks', 'filled', ...
               'MarkerEdgeColor', 'white', 'LineWidth', 3);
        
        % Color UEs by handover count
        max_ho = max(viz_data.handover_count);
        if max_ho > 0
            % Create color mapping
            handover_colors = viz_data.handover_count;
            scatter(ue_final_pos(:,1), ue_final_pos(:,2), 80, handover_colors, 'filled', 'o', ...
                   'MarkerEdgeColor', 'black', 'LineWidth', 1);
            
            % Add colorbar
            cb = colorbar;
            cb.Label.String = 'Handover Count';
            cb.Label.FontSize = 11;
            cb.Label.FontWeight = 'bold';
        else
            scatter(ue_final_pos(:,1), ue_final_pos(:,2), 80, 'b', 'filled', 'o', ...
                   'MarkerEdgeColor', 'black');
        end
        
        % Add gNB labels
        for g = 1:gnb_count
            text(final_gNB_pos(g,1), final_gNB_pos(g,2), sprintf('gNB%d', g), ...
                'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle', ...
                'Color', 'white', 'FontWeight', 'bold', 'FontSize', 9);
        end
        
        title(sprintf('%s: Handover Density Map\nMax: %d, Avg: %.2f handovers/UE', ...
            env_name, max_ho, mean(viz_data.handover_count)), ...
            'FontSize', 12, 'FontWeight', 'bold');
        xlabel('X Position (m)'); ylabel('Y Position (m)');
        xlim([0, viz_data.area_size]); ylim([0, viz_data.area_size]);
    end
end

sgtitle(sprintf('UE Movement Analysis - %s\n%d UEs, %d gNBs', config_name, ue_count, gnb_count), ...
    'FontSize', 16, 'FontWeight', 'bold');

% === 3. Network Performance Metrics Analysis ===
figure('Name', 'Network Performance Metrics', 'Position', [200, 200, 1400, 900]);

% Extract performance data from the dataset
final_data_urban = T(strcmp(T.Environment, 'Urban'), :);
final_data_suburban = T(strcmp(T.Environment, 'Suburban'), :);
final_data_rural = T(strcmp(T.Environment, 'Rural'), :);

% Convert string data to numeric for analysis
rssi_urban = cellfun(@(x) str2double(x(1:end-4)), final_data_urban.RSSI);
rssi_suburban = cellfun(@(x) str2double(x(1:end-4)), final_data_suburban.RSSI);
rssi_rural = cellfun(@(x) str2double(x(1:end-4)), final_data_rural.RSSI);

sinr_urban = cellfun(@(x) str2double(x(1:end-3)), final_data_urban.SINR);
sinr_suburban = cellfun(@(x) str2double(x(1:end-3)), final_data_suburban.SINR);
sinr_rural = cellfun(@(x) str2double(x(1:end-3)), final_data_rural.SINR);

latency_urban = cellfun(@(x) str2double(x(1:end-3)), final_data_urban.Latency);
latency_suburban = cellfun(@(x) str2double(x(1:end-3)), final_data_suburban.Latency);
latency_rural = cellfun(@(x) str2double(x(1:end-3)), final_data_rural.Latency);

alloc_urban = cellfun(@(x) str2double(x(1:end-1)), final_data_urban.Resource_Allocation);
alloc_suburban = cellfun(@(x) str2double(x(1:end-1)), final_data_suburban.Resource_Allocation);
alloc_rural = cellfun(@(x) str2double(x(1:end-1)), final_data_rural.Resource_Allocation);

% Plot 1: RSSI Distribution
subplot(2, 3, 1);
hold on;
histogram(rssi_urban, 20, 'FaceColor', [0.8, 0.2, 0.2], 'FaceAlpha', 0.7, 'EdgeColor', 'black');
histogram(rssi_suburban, 20, 'FaceColor', [0.2, 0.8, 0.2], 'FaceAlpha', 0.7, 'EdgeColor', 'black');
histogram(rssi_rural, 20, 'FaceColor', [0.2, 0.2, 0.8], 'FaceAlpha', 0.7, 'EdgeColor', 'black');
xlabel('RSSI (dBm)', 'FontWeight', 'bold');
ylabel('Frequency', 'FontWeight', 'bold');
title('RSSI Distribution by Environment', 'FontWeight', 'bold');
legend({'Urban', 'Suburban', 'Rural'}, 'Location', 'best');
grid on;

% Plot 2: SINR Distribution
subplot(2, 3, 2);
hold on;
histogram(sinr_urban, 20, 'FaceColor', [0.8, 0.2, 0.2], 'FaceAlpha', 0.7, 'EdgeColor', 'black');
histogram(sinr_suburban, 20, 'FaceColor', [0.2, 0.8, 0.2], 'FaceAlpha', 0.7, 'EdgeColor', 'black');
histogram(sinr_rural, 20, 'FaceColor', [0.2, 0.2, 0.8], 'FaceAlpha', 0.7, 'EdgeColor', 'black');
xlabel('SINR (dB)', 'FontWeight', 'bold');
ylabel('Frequency', 'FontWeight', 'bold');
title('SINR Distribution by Environment', 'FontWeight', 'bold');
legend({'Urban', 'Suburban', 'Rural'}, 'Location', 'best');
grid on;

% Plot 3: Latency Comparison
subplot(2, 3, 3);
latency_data = [mean(latency_urban), mean(latency_suburban), mean(latency_rural)];
bar(latency_data, 'FaceColor', [0.6, 0.4, 0.8], 'EdgeColor', 'black', 'LineWidth', 1.5);
xlabel('Environment', 'FontWeight', 'bold');
ylabel('Average Latency (ms)', 'FontWeight', 'bold');
title('Average Latency by Environment', 'FontWeight', 'bold');
xticklabels(env_names);
grid on;
% Add value labels
for i = 1:length(latency_data)
    text(i, latency_data(i) + max(latency_data)*0.02, sprintf('%.1f ms', latency_data(i)), ...
        'HorizontalAlignment', 'center', 'FontWeight', 'bold');
end

% Plot 4: Resource Allocation Distribution
subplot(2, 3, 4);
hold on;
histogram(alloc_urban, 20, 'FaceColor', [0.8, 0.2, 0.2], 'FaceAlpha', 0.7, 'EdgeColor', 'black');
histogram(alloc_suburban, 20, 'FaceColor', [0.2, 0.8, 0.2], 'FaceAlpha', 0.7, 'EdgeColor', 'black');
histogram(alloc_rural, 20, 'FaceColor', [0.2, 0.2, 0.8], 'FaceAlpha', 0.7, 'EdgeColor', 'black');
xlabel('Resource Allocation (%)', 'FontWeight', 'bold');
ylabel('Frequency', 'FontWeight', 'bold');
title('Resource Allocation Distribution', 'FontWeight', 'bold');
legend({'Urban', 'Suburban', 'Rural'}, 'Location', 'best');
grid on;

% Plot 5: Average Resource Allocation
subplot(2, 3, 5);
alloc_data = [mean(alloc_urban), mean(alloc_suburban), mean(alloc_rural)];
bar(alloc_data, 'FaceColor', [0.9, 0.6, 0.2], 'EdgeColor', 'black', 'LineWidth', 1.5);
xlabel('Environment', 'FontWeight', 'bold');
ylabel('Avg Resource Allocation (%)', 'FontWeight', 'bold');
title('Average Resource Allocation', 'FontWeight', 'bold');
xticklabels(env_names);
grid on;
% Add value labels
for i = 1:length(alloc_data)
    text(i, alloc_data(i) + max(alloc_data)*0.02, sprintf('%.1f%%', alloc_data(i)), ...
        'HorizontalAlignment', 'center', 'FontWeight', 'bold');
end

% Plot 6: Performance Summary Radar-like Chart
subplot(2, 3, 6);
% Normalize metrics for comparison (higher is better)
norm_rssi = (([mean(rssi_urban), mean(rssi_suburban), mean(rssi_rural)] + 100) / 100) * 100;
norm_sinr = (([mean(sinr_urban), mean(sinr_suburban), mean(sinr_rural)] + 10) / 40) * 100;
norm_latency = 100 - (latency_data / max(latency_data) * 100); % Invert (lower latency is better)
norm_alloc = alloc_data;

summary_data = [norm_rssi; norm_sinr; norm_latency; norm_alloc];
bar(summary_data', 'grouped');
xlabel('Environment', 'FontWeight', 'bold');
ylabel('Normalized Performance (0-100)', 'FontWeight', 'bold');
title('Performance Summary (Normalized)', 'FontWeight', 'bold');
xticklabels(env_names);
legend({'RSSI', 'SINR', 'Latency (inv)', 'Allocation'}, 'Location', 'best');
grid on;

sgtitle(sprintf('Network Performance Analysis - %s\n%d UEs, %d gNBs', config_name, ue_count, gnb_count), ...
    'FontSize', 16, 'FontWeight', 'bold');

fprintf('\n🎯 === SIMULATION COMPLETE ===\n');
if config == 1
    config_type = 'Case 1: Fixed gNodeB Environment Testing';
    fprintf('Configuration: %s\n', config_type);
    fprintf('Features: Fixed gNB positions, Environment comparison\n');
else
    config_type = 'Case 2: Mobile gNodeB Scalability Testing';
    fprintf('Configuration: %s\n', config_type);
    fprintf('Features: Mobile gNBs, Advanced mobility patterns\n');
end

fprintf('User Equipment: %d UEs\n', ue_count);
fprintf('gNodeBs: %d gNBs\n', gnb_count);
fprintf('Total Environments: 3 (Urban, Suburban, Rural)\n');
fprintf('Simulation Duration: %d time steps\n', time_steps);
fprintf('Dataset Records: %d\n', height(T));
fprintf('Real-time Visualization: ✅ Enabled\n');

if gNB_mobility
    mobility_status_final = '✅ Yes';
else
    mobility_status_final = '❌ No';
end
fprintf('Moving gNBs: %s\n', mobility_status_final);

fprintf('\n🎯 Ready for ensemble learning analysis!\n');
fprintf('📁 Dataset saved as: %s\n', filename);