function data = file_reader(file_path, mode)
    data = struct();
    
    % Set default variables
    data.tx_type = 'plane_wave';
    data.fc = 5.2e06;
    data.flow_em_per_frame = 1;
    
    % PICMUS Dataset
    if mode == "PICMUS"
        %Load PICMUS dataset
        raw_data = us_dataset();
        raw_data.read_file(file_path);
        
        data.data = raw_data.data;
        
        data.fs = raw_data.sampling_frequency;
        data.c = raw_data.c0;
        data.lambda = data.c/data.fc;
        
        data.tx_angles = raw_data.angles;
        data.max_rx_steer_ang = max(data.tx_angles(:)) * 180/pi;
        data.rx_start_time = 0;
        data.n_elements = size(raw_data.data, 2);
        data.elem_pos = raw_data.probe_geometry;
        data.n_frames = raw_data.frames;
        data.PRF = raw_data.PRF;
        data.no_emission_types = raw_data.firings;
        data.focal_delay = zeros(size(data.tx_angles));
    end

end