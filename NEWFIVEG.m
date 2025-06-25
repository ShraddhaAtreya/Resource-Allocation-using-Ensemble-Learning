clear; clc; close all;

% === Parameters ===
num_gNB = 9;
UEs_per_gNB = 10;
total_UEs = num_gNB * UEs_per_gNB;
area_size = 200;
time_steps = 25; % Increased simulation time
movement_range = 10;

% === gNB Grid Placement ===
rows = 3; cols = 3;
spacing = area_size / (rows + 1);
gNB_pos = zeros(num_gNB, 2);
g = 1;
for r = 1:rows
    for c = 1:cols
        if g > num_gNB, break; end
        gNB_pos(g,:) = [c*spacing, r*spacing];
        g = g + 1;
    end
end

% === Initial UE Positions and Associations ===
UE_pos = zeros(total_UEs, 2, time_steps);
UE_gnb_assoc = zeros(total_UEs, time_steps);
handover_count = zeros(total_UEs, 1);
colors = lines(num_gNB);
data = {};

% === Application assignment ===
apps = {'Emergency','Video_Call','Voice_Call','Streaming',...
        'Online_Gaming','Background','Web_Browsing','IoT_Temp','Video_Streaming'};
req_bw_range = [5 3 1.5 2.5 2 0.8 1.2 0.1 2]; % Mbps

UE_app = repmat(apps, 1, ceil(total_UEs / length(apps)));
UE_app = UE_app(1:total_UEs);

% === Initial positioning ===
for i = 1:total_UEs
    gnb_idx = mod(i-1, num_gNB) + 1;
    center = gNB_pos(gnb_idx,:);
    UE_pos(i,:,1) = center + randi([-10,10], 1, 2);
end

% === gNB Capacity and Load Tracking ===
gNB_max_capacity = 150; % Mbps (Increased)
gNB_current_load = zeros(num_gNB, 1);
interference_factor = zeros(total_UEs, 1);

% === Simulation ===
f = figure('Name','Improved 5G Handover Visualization', 'Position', [200, 200, 700, 500]);

for t = 1:time_steps
    clf; hold on; grid on;
    title(['Time Step ', num2str(t)], 'FontSize', 14);
    xlabel('X'); ylabel('Y');
    xlim([0 area_size]); ylim([0 area_size]);

    for g = 1:num_gNB
        plot(gNB_pos(g,1), gNB_pos(g,2), 'ks', 'MarkerSize', 12, 'MarkerFaceColor', 'k');
        text(gNB_pos(g,1)+2, gNB_pos(g,2)+2, sprintf('gNB %d', g), 'FontWeight','bold', 'FontSize', 11);
    end

    gNB_current_load = zeros(num_gNB, 1);
    
    for i = 1:total_UEs
        if t > 1
            move = randi([-movement_range, movement_range], 1, 2);
            UE_pos(i,:,t) = min(max(UE_pos(i,:,t-1) + move, 0), area_size);
        end

        pos = UE_pos(i,:,t);
        distances = sqrt(sum((gNB_pos - pos).^2, 2));
        [min_dist, new_gnb] = min(distances);
        UE_gnb_assoc(i,t) = new_gnb;

        % Interference
        other_gNBs = setdiff(1:num_gNB, new_gnb);
        interference_power = 0;
        for other_gnb = other_gNBs
            other_dist = distances(other_gnb);
            interference_power = interference_power + 10^((-40 - other_dist*0.3)/10);
        end
        interference_factor(i) = interference_power;
    end

    for i = 1:total_UEs
        pos = UE_pos(i,:,t);
        distances = sqrt(sum((gNB_pos - pos).^2, 2));
        [min_dist, new_gnb] = min(distances);

        if t > 1 && UE_gnb_assoc(i,t) ~= UE_gnb_assoc(i,t-1)
            handover_count(i) = handover_count(i) + 1;
            marker = 'd';
        else
            marker = 'o';
        end

        RSSI = -30 - min_dist - 10*log10(1 + interference_factor(i));
        latency = 6 + 0.3 * min_dist + randi([0,4]);

        app = UE_app{i};
        app_idx = find(strcmp(apps, app));
        required_bw = req_bw_range(app_idx);

        base_throughput_clean = max(1.5, 12 - 0.3 * min_dist);
        interference_penalty = 1 / (1 + interference_factor(i));
        base_throughput = base_throughput_clean * interference_penalty;

        UEs_on_same_gNB = sum(UE_gnb_assoc(:,t) == new_gnb);
        congestion_factor = max(0.4, 1 - (UEs_on_same_gNB - 1) * 0.08);
        available_throughput = base_throughput * congestion_factor;

        remaining_capacity = gNB_max_capacity - gNB_current_load(new_gnb);
        capacity_limited_throughput = min(available_throughput, remaining_capacity);

        theoretical_allocation = min(required_bw, capacity_limited_throughput);

        if strcmp(app, 'Emergency')
            allocation_efficiency = 0.85 + 0.15 * rand();
        else
            allocation_efficiency = 0.7 + 0.2 * rand();
        end

        allocated_bw = theoretical_allocation * allocation_efficiency;
        gNB_current_load(new_gnb) = gNB_current_load(new_gnb) + allocated_bw;

        alloc_percent = round((allocated_bw / required_bw) * 100);
        alloc_percent = max(5, min(alloc_percent, 100));

        data(end+1,:) = {t, ['User_' num2str(i)], app, ...
                         sprintf('%d dBm', round(RSSI)), ...
                         sprintf('%d ms', round(latency)), ...
                         sprintf('%.2f Mbps', required_bw), ...
                         sprintf('%.2f Mbps', allocated_bw), ...
                         [num2str(alloc_percent) '%']};

        plot(pos(1), pos(2), marker, ...
            'Color', colors(new_gnb,:), 'MarkerFaceColor', colors(new_gnb,:), 'MarkerSize', 6);
        text(pos(1)+1.5, pos(2), sprintf('%d', i), 'FontSize', 8);
    end

    drawnow;
    pause(0.4);
end

T = cell2table(data, 'VariableNames', ...
    {'Timestamp','User_ID','Application','Signal_Str','Latency', ...
     'Required_','Allocated_','Resource_Allocation'});
writetable(T, 'handover_dataset_custom.csv');
disp('✅ CSV saved as handover_dataset_custom.csv');

fprintf('\n=== Handover Summary ===\n');
handover_occurred = find(handover_count > 0);
if isempty(handover_occurred)
    disp('❌ No handovers occurred.');
else
    fprintf('✅ %d UEs experienced at least one handover.\n', length(handover_occurred));
    fprintf('%-7s %-12s %-10s %-11s\n', 'UE_ID', 'Initial_gNB', 'Final_gNB', '#Handovers');
    for i = handover_occurred'
        initial = UE_gnb_assoc(i,1);
        final = UE_gnb_assoc(i,end);
        fprintf('%-7d %-12d %-10d %-11d\n', i, initial, final, handover_count(i));
    end
end
