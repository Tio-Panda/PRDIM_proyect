function beamformed_data_DAS = DAS_bf(DATA)
    % === Beamforming params ===
    DATA.tx_ang_idx_0 = DATA.tx_angles==0;

    % === Choose the ROI ===
    x_axis_org = DATA.elem_pos(:, 1);
    
    DATA.time_vector(:, 1) = ((0:size(DATA.data, 1)-1) / DATA.fs);
    z_axis_org = DATA.time_vector * DATA.c/2;
    
    % === Define the grid for the ROI ===
    [X_grid,Z_grid] = meshgrid(x_axis_org, z_axis_org);

    GRID = struct();
    GRID.X = X_grid;
    GRID.Z = Z_grid;
    GRID.x = X_grid(:);
    GRID.z = Z_grid(:);
    
    % === Focal delay ===
    DATA.probe_geometry = DATA.elem_pos(:, 1);
    DATA.elem_pitch = DATA.elem_pos(2,1) - DATA.elem_pos(1,1);

    % Conventional DAS beamforming for 75 angles
    beamformed_data_DAS = single(zeros(size(GRID.Z, 1), size(GRID.Z, 2), numel(DATA.tx_angles)));

    for tx_ang_idx = 1:numel(DATA.tx_angles)
        data_cube = data_cube_extract(DATA, GRID, tx_ang_idx);
        beamformed_data_DAS(:, :, tx_ang_idx) = DAS(data_cube, DATA, GRID);

        clc;
        disp(strcat('DAS beamforming: ', num2str(tx_ang_idx),'/',num2str(numel(DATA.tx_angles))));
    end

    beamformed_data_DAS(isnan(beamformed_data_DAS)) = 0;
    disp('DAS beamforming completed for all angles')

    figure();
    envData = abs(hilbert(squeeze(mean(beamformed_data_DAS, 3))));
    imagesc(x_axis_org*100 , z_axis_org*100, 20*log10(envData./max(envData(:))));
    axis equal tight
    xlabel('x [cm]')
    xlabel('z [cm]')
    colormap("gray")
    clim([-55,0])

end

function data_cube = data_cube_extract(DATA, GRID, idx)
    rf_data = squeeze(DATA.data(:,:,idx));
    n_elements = length(DATA.probe_geometry);
    data_cube = zeros(length(GRID.x), n_elements);
    tx_delay = GRID.z * cos(DATA.tx_angles(idx)) + GRID.x * (DATA.tx_angles(idx));

    for nrx = 1:n_elements
        rx_delay = sqrt((DATA.probe_geometry(nrx) - GRID.x).^2 + GRID.z.^2);
        delay = ((tx_delay + rx_delay) / DATA.c) + DATA.focal_delay(idx);
        data_cube(:, nrx) = interp1(DATA.time_vector, rf_data(:, nrx), delay, "spline", 0);
    end

    data_cube = (reshape(data_cube, size(GRID.X, 1), size(GRID.X, 2), n_elements));
end

function beamformed_data = DAS(data_cube, DATA, GRID)
    n_elements = size(data_cube, 3);
    pixels = length(GRID.z);

    rx_f_number = 1.75;
    rx_aperture = GRID.z / rx_f_number;

    rx_aperture_distance = abs(GRID.x * ones(1, n_elements) - ones(pixels, 1) * DATA.probe_geometry.');
    rx_apodization = apodization(rx_aperture_distance, rx_aperture * ones(1, n_elements), "tukey25");

    beamformed_data = sum(rx_apodization .* reshape(data_cube, pixels, n_elements), 2);
    beamformed_data(isnan(beamformed_data)) = 0;
    beamformed_data = reshape(beamformed_data, size(GRID.X));
end
