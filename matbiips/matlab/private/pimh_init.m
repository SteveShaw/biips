function [sample, log_marg_like] = pimh_init(console, variable_names, n_part, rs_thres, rs_type)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% PIMH_INIT Initialisation of the Particle Independent Metropolis
% Hastings algorithm
% sample = pimh_init(console, variable_names, n_part, rs_thres, rs_type)
% INPUT: 
% - console :           integer. Id of the console containing the model, 
%                       returned by the 'biips_model' function
% - variable_names :    cell of strings. Contains the names of the 
%                       unobserved variables to monitor.
%                       Possible value: {'var1', 'var2[1]', 'var3[1:10]',
%                                                       'var4[1, 5:10, 3]'}
%                       Dimensions and indices must be a valid subset of 
%                       the variables of the model.
% - n_part :            positive integer. Number of particles used in SMC algorithms
%
% - rs_thres :  positive real 
%               Threshold for the resampling step (adaptive SMC).
%               if rs_thres is in [0,1] --> resampling occurs when 
%                                           (ESS > rs_thres * nb_part)
%               if rs_thres is in [2,nb_part] --> resampling occurs when 
%                                               (ESS > rs_thres)
% - rs_type :   string 
%               Possible values are 'stratified', 'systematic', 'residual', 'multinomial'
%               Indicates the type of algorithm used for the resampling step.           

% OUTPUT:
% sample:       sampled value from the SMC output
% log_marg_like:log marginal likelihood
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% BiiPS Project - Bayesian Inference with interacting Particle Systems
% MatBiips interface
% Authors: Adrien Todeschini, Marc Fuentes, Fran�ois Caron
% Copyright: INRIA
% Jan 2014; Last revision: 13-03-2014
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%
monitored = is_monitored(console, variable_names, 's', false);
if ~monitored
    % monitor variables
    monitor_biips(console, variable_names, 's'); 
end

if (~inter_biips('is_sampler_built', console))
   inter_biips('build_smc_sampler', console, false);
end

atend = inter_biips('is_smc_sampler_at_end', console);
% Get the normalizing constant
if (~monitored || ~atend)
    % Run SMC sampler
    inter_biips('message', 'Initializing PIMH');
    run_smc_forward(console, n_part, rs_thres, rs_type, get_seed());
end
log_marg_like = inter_biips('get_log_norm_const', console);

% Get sampled value
sampled_value = inter_biips('get_sampled_gen_tree_smooth_particle', console);
if (isempty(fieldnames(sampled_value)))
    % Sample one particle
    inter_biips('sample_gen_tree_smooth_particle', console, get_seed());
    sampled_value = inter_biips('get_sampled_gen_tree_smooth_particle', console);
end
cell_struct = cell(length(variable_names), 1);
for i=1:length(variable_names)
    cell_struct{i} = getfield(sampled_value, variable_names{i});
end
sample = cell2struct_weaknames(cell_struct, variable_names);