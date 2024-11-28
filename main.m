addpath("data");
addpath(genpath("functions"));

%% Load data
DATA = file_reader("./data/PICMUS/carotid_cross_expe_dataset_rf.hdf5", "PICMUS");

%% Apply DAS beamforming
bf_DAS_data = DAS_bf(DATA);