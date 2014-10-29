function [obj_pmmh, samples_pmmh, varargout] = biips_pmmh_samples(obj_pmmh, n_iter, n_part, varargin)
% BIIPS_PMMH_SAMPLES Perform iterations for the PMMH algorithm and returns samples.
% [obj_pmmh, samples_pmmh, log_marg_like_pen, log_marg_like, info_pmmh] = ... 
%     biips_pmmh_samples(obj_pmmh, n_iter, n_part, 'PropertyName', PropertyValue, ...)
%
%   INPUT 
%   - obj_pmmh:     PMMH structure as returned by BIIPS_PMMH_INIT
%   - n_iter:       integer. Number of iterations
%   - n_part:       integer. Number of particles used in SMC algorithms
%   Optional Inputs:
%   - thin:         integer. Thinning interval. Returns samples every 'thin' iterations
%                   (default = 1).
%   - rs_thres, rs_type, ... : Additional arguments to be passed to the SMC
%      algorithm. See BIIPS_SMC_SAMPLES for for details.
%
%   OUTPUT
%   - obj_pmmh:          structure. updated PMMH object
%   - samples_pmmh:      structure. PMMH samples for each monitored variable
%   Optional Output:
%   - log_marg_like_pen: vector of penalized log marginal likelihood estimates over iterations
%   - log_marg_like:     vector of log marginal likelihood estimates over iterations
%   - info_pmmh:          structure. Additional information on the MCMC run
%                         with the fields:
%                         * accept_rate: vector of acceptance rates over
%                         iterations
%                         * n_fail: number of failed SMC algorithms
%                         * rw_step: standard deviations of the random walk
%                         over iterations.
%
%   See also BIIPS_MODEL, BIIPS_PMMH_INIT, BIIPS_PMMH_UPDATE
%--------------------------------------------------------------------------
% EXAMPLE:
% modelfile = 'hmm.bug';
% type(modelfile);
% 
% logtau_true = 10;
% data = struct('tmax', 10);
% model = biips_model(modelfile, data, 'sample_data', true);
% 
% n_part = 50;
% obj_pmmh = biips_pmmh_init(model, {'logtau'}, 'latent_names', {'x'}, 'inits', {-2}); % Initialize
% [obj_pmmh, plml_pmmh_burn] = biips_pmmh_update(obj_pmmh, 100, n_part); % Burn-in
% [obj_pmmh, out_pmmh, plml_pmmh] = biips_pmmh_samples(obj_pmmh, 100, n_part, 'thin', 1); % Samples
% 
% out_pmmh
% summ_pmmh = biips_summary(out_pmmh)
% dens_pmmh = biips_density(out_pmmh)
% 
% out_pmmh.x
% summ_pmmh = biips_summary(out_pmmh.x)
% dens_pmmh = biips_density(out_pmmh.x)
% 
% figure
% subplot(2,2,1); hold on
% plot([plml_pmmh_burn, plml_pmmh])
% xlabel('PMMH iteration')
% ylabel('penalized log marginal likelihood')
% 
% subplot(2,2,2); hold on
% plot(0, logtau_true, 'g>', 'markerfacecolor', 'g')
% plot(out_pmmh.logtau)
% xlabel('PMMH iteration')
% ylabel('logtau')
% 
% summ_pmmh = biips_summary(out_pmmh, 'order', 2, 'probs', [.025, .975]);
% 
% subplot(2,2,3); hold on
% plot(model.data.x_true, 'g')
% plot(summ_pmmh.x.mean, 'b')
% plot(summ_pmmh.x.quant{1}, '--b')
% plot(summ_pmmh.x.quant{2}, '--b')
% xlabel('t')
% ylabel('x[t]')
% legend('true', 'PMMH estimate')
% legend boxoff
% 
% dens_pmmh = biips_density(out_pmmh);
% 
% subplot(2,2,4); hold on
% plot(logtau_true, 0, '^g', 'markerfacecolor', 'g')
% plot(dens_pmmh.logtau.x, dens_pmmh.logtau.f, 'b')
% xlabel('logtau')
% ylabel('posterior density')
%--------------------------------------------------------------------------

% Biips Project - Bayesian Inference with interacting Particle Systems
% Matbiips interface
% Authors: Adrien Todeschini, Marc Fuentes, Fran�ois Caron
% Copyright (C) Inria
% License: GPL-3
% Jan 2014; Last revision: 21-10-2014
%--------------------------------------------------------------------------

%% PROCESS AND CHECK INPUTS
optarg_names = {'thin', 'max_fail', 'rs_thres', 'rs_type'};
optarg_default = {1, 0, .5, 'stratified'};
optarg_valid = {[0, n_iter], [0, n_part],...
    {'stratified', 'systematic', 'residual', 'multinomial'}};
optarg_type = {'numeric', 'numeric', 'numeric', 'char'};
[thin, max_fail, rs_thres, rs_type] = parsevar(varargin, optarg_names,...
    optarg_type, optarg_valid, optarg_default);

%% Call pmmh_algo internal routine
return_samples = true;

varargout = cell(nargout-2,1);
[obj_pmmh, samples_pmmh, varargout{:}] = pmmh_algo(obj_pmmh, n_iter, n_part,...
    return_samples, 'thin', thin, 'max_fail',...
    max_fail, 'rs_thres', rs_thres, 'rs_type', rs_type);
