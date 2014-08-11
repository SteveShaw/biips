examples/object_tracking/hmm_4d_nonlin.m                                                            000664  001750  001750  00000013642 12351652231 023305  0                                                                                                    ustar 00adrien-alea                     adrien-alea                     000000  000000                                                                                                                                                                         %% Matbiips example: Object tracking
% In this example, we consider the tracking of an object in 2D, observed by
% a radar.
%
% Reference: B. Ristic. Beyond the Kalman filter: Particle filters for
% Tracking applications. Artech House, 2004.

%% Statistical model
%
%
% Let $X_t$ be a 4-D vector containing the position and velocity of an
% object in 2D. We obtain distance-angular measurements $Y_t$ from a radar. 
%
% The model is defined as follows. For $t=1,\ldots,t_{\max}$
%
% $$ X_t = F X_{t-1} + G V_t,~~ V_t\sim\mathcal N(0,Q)$$
%
% $$ Y_{t} = g(X_t) + W_t,~~ W_t \sim\mathcal N(0,R)$$
%
% $F$ and $G$ are known matrices, $g(X_t)$ is the known nonlinear measurement function and $Q$ and $R$ are known covariance matrices.


%% Statistical model in BUGS language
%

%%
%
% 
%     var v_true[2,t_max-1], x_true[4,t_max], x_radar_true[2,t_max],
%     v[2,t_max-1], x[4,t_max], x_radar[2,t_max], y[2,t_max]
% 
%     data
%     {
%       x_true[,1] ~ dmnorm(mean_x_init, prec_x_init)
%       x_radar_true[,1] <- x_true[1:2,1] - x_pos 
%       mu_y_true[1,1] <- sqrt(x_radar_true[1,1]^2+x_radar_true[2,1]^2)
%       mu_y_true[2,1] <- arctan(x_radar_true[2,1]/x_radar_true[1,1])
%       y[,1] ~ dmnorm(mu_y_true[,1], prec_y)
% 
%       for (t in 2:t_max)
%       {
%         v_true[,t-1] ~ dmnorm(mean_v, prec_v)
%         x_true[,t] <- F %*% x_true[,t-1] + G %*% v_true[,t-1]
%         x_radar_true[,t] <- x_true[1:2,t] - x_pos
%         mu_y_true[1,t] <- sqrt(x_radar_true[1,t]^2+x_radar_true[2,t]^2)
%         mu_y_true[2,t] <- arctan(x_radar_true[2,t]/x_radar_true[1,t])
%         y[,t] ~ dmnorm(mu_y_true[,t], prec_y)
%       }
%     }
% 
%     model
%     {
%       x[,1] ~ dmnorm(mean_x_init, prec_x_init)
%       x_radar[,1] <- x[1:2,1] - x_pos
%       mu_y[1,1] <- sqrt(x_radar[1,1]^2+x_radar[2,1]^2)
%       mu_y[2,1] <- arctan(x_radar[2,1]/x_radar[1,1])
%       y[,1] ~ dmnorm(mu_y[,1], prec_y)
% 
%       for (t in 2:t_max)
%       {
%         v[,t-1] ~ dmnorm(mean_v, prec_v)
%         x[,t] <- F %*% x[,t-1] + G %*% v[,t-1]
%         x_radar[,t] <- x[1:2,t] - x_pos
%         mu_y[1,t] <- sqrt(x_radar[1,t]^2+x_radar[2,t]^2)
%         mu_y[2,t] <- arctan(x_radar[2,t]/x_radar[1,t])
%         y[,t] ~ dmnorm(mu_y[,t], prec_y)
%       }
%     }

rng('default')

%% Installation of Matbiips
% Unzip the Matbiips archive in some folder
% and add the Matbiips folder to the Matlab path
% 

matbiips_path = '../../matbiips/matlab';
addpath(matbiips_path)

%% Load model and data
%

%%
% *Model parameters*
t_max = 20;
mean_x_init = [0 0 1 0]';
prec_x_init = diag(1000*ones(4,1));
x_pos = [60  0];
mean_v = zeros(2, 1);
prec_v = diag(1*ones(2,1));
prec_y = diag([100 500]);
delta_t = 1;
F =[1 0 delta_t 0
    0 1 0 delta_t
    0, 0, 1, 0
    0 0 0 1];
G = [ delta_t.^2/2 0
    0 delta_t.^2/2
    delta_t 0
    0 delta_t];
data = struct('t_max', t_max, 'mean_x_init', mean_x_init, 'prec_x_init', ...
    prec_x_init, 'x_pos', x_pos, 'mean_v', mean_v, 'prec_v', prec_v,...
    'prec_y', prec_y, 'delta_t', delta_t, 'F', F, 'G', G);


%%
% *Compile BUGS model and sample data*
sample_data = true; % Boolean
model = biips_model('hmm_4d_nonlin_tracking.bug', data, 'sample_data', sample_data);
data = model.data;
x_pos_true = data.x_true(1:2,:);

%% BiiPS: Particle filter
%

%%
% *Parameters of the algorithm*. 
n_part = 100000; % Number of particles
variables = {'x'}; % Variables to be monitored

%%
% *Run SMC*
out_smc = biips_smc_samples(model, {'x'}, n_part);

%% 
% *Diagnostic*
diagnostic = biips_diagnosis(out_smc);

%% 
% *Summary statistics*
summary = biips_summary(out_smc, 'probs', [.025, .975]);

%% 
% *Plot estimates*
x_f_mean = summary.x.f.mean;
x_s_mean = summary.x.s.mean;
figure('name', 'Filtering and Smoothing estimates')
plot(x_f_mean(1, :), x_f_mean(2, :), 'linewidth', 2)
hold on
plot(x_s_mean(1, :), x_s_mean(2, :), '-.r', 'linewidth', 2)
plot(x_pos_true(1,:), x_pos_true(2,:), '--g', 'linewidth', 2)
plot(x_pos(1), x_pos(2), 'sk')
legend('Filtering estimate', 'Smoothing estimate', 'True trajectory',...
    'Position of the radar', 'location', 'Northwest')
legend boxoff
xlabel('Position X')
ylabel('Position Y')

figure('name', 'Particles')
plot(out_smc.x.f.values(1,:), out_smc.x.f.values(2,:), 'ro', ...
    'markersize', 3, 'markerfacecolor', 'r')
hold on
plot(x_pos_true(1,:), x_pos_true(2,:), '--g', 'linewidth', 2)
plot(x_pos(1), x_pos(2), 'sk')
legend('Particles', 'True trajectory', 'Position of the radar', 'location', 'Northwest')
legend boxoff
xlabel('Position X')
ylabel('Position Y')



%%
% *Plot Filtering estimates*
x_f_quant = summary.x.f.quant;
title_fig = {'Position X', 'Position Y', 'Velocity X', 'Velocity Y'};
for k=1:4
    figure('name', 'SMC: Filtering estimates')
    title(title_fig{k})
    hold on
    h = fill([1:t_max, t_max:-1:1], [x_f_quant{1}(k,:), fliplr(x_f_quant{2}(k,:))],...
        [.7 .7 1]);
    set(h, 'edgecolor', 'none')
    hold on
    plot(x_f_mean(k, :), 'linewidth', 3)
    hold on
    plot(data.x_true(k,:), 'g', 'linewidth', 2)
    xlabel('Time')
    ylabel('Estimates')
    legend({'95 % credible interval', 'Filtering Mean Estimate', 'True value'},...
        'location', 'Northwest')
    legend('boxoff')
    box off
end

%%
% *Plot Smoothing estimates*
x_s_quant = summary.x.s.quant;
for k=1:4
    figure('name', 'SMC: Smoothing estimates')
    title(title_fig{k})
    hold on
    h = fill([1:t_max, t_max:-1:1], [x_f_quant{1}(k,:), fliplr(x_f_quant{2}(k,:))],...
    [.7 .7 1]);
    set(h, 'edgecolor', 'none')
    hold on
    plot(x_s_mean(k, :), 'linewidth', 3)
    hold on
    plot(data.x_true(k,:), 'g', 'linewidth', 2)
    xlabel('Time')
    ylabel('Estimates')
    legend({'95 % credible interval', 'Smoothing Mean Estimate', 'True value'},...
        'location', 'Northwest')
    legend('boxoff')
    box off
end

%% Clear model
% 

biips_clear()                                                                                              examples/tutorial/tutorial3.m                                                                       000664  001750  001750  00000012670 12364150125 021220  0                                                                                                    ustar 00adrien-alea                     adrien-alea                     000000  000000                                                                                                                                                                         %% Matbiips: Tutorial 3
% In this tutorial, we will see how to introduce user-defined functions in the BUGS model.

%% Statistical model
% The statistical model is defined as follows.
%
% $$ x_1\sim \mathcal N\left (\mu_0, \frac{1}{\lambda_0}\right )$$
%
% $$ y_1\sim \mathcal N\left (h(x_1), \frac{1}{\lambda_y}\right )$$
%
% For $t=2:t_{max}$
%
% $$ x_t|x_{t-1} \sim \mathcal N\left ( f(x_{t-1},t-1), \frac{1}{\lambda_x}\right )$$
%
% $$ y_t|x_t \sim \mathcal N\left ( h(x_{t}), \frac{1}{\lambda_y}\right )$$
%
% with $\mathcal N\left (m, S\right )$ stands for the Gaussian distribution 
% of mean $m$ and covariance matrix $S$, $h(x)=x^2/20$, $f(x,t-1)=0.5 x+25 x/(1+x^2)+8 \cos(1.2 (t-1))$, $\mu_0=0$, $\lambda_0 = 5$, $\lambda_x = 0.1$ and $\lambda_y=1$. 

%% Statistical model in BUGS language
% One needs to describe the model in BUGS language. We create the file
%  'hmm_1d_nonlin_funmat.bug':

%%
%
% 
%     var x_true[t_max], x[t_max], y[t_max]
% 
%     data
%     {
%       x_true[1] ~ dnorm(mean_x_init, prec_x_init)
%       y[1] ~ dnorm(x_true[1]^2/20, prec_y)
%       for (t in 2:t_max)
%       {
%         x_true[t] ~ dnorm(funmat(x_true[t-1],t-1), prec_x)
%         y[t] ~ dnorm(x_true[t]^2/20, prec_y)
%       }
%     }
% 
% 
%     model
%     {
%       x[1] ~ dnorm(mean_x_init, prec_x_init)
%       y[1] ~ dnorm(x[1]^2/20, prec_y)
%       for (t in 2:t_max)
%       {
%         x[t] ~ dnorm(funmat(x[t-1],t-1), prec_x)
%         y[t] ~ dnorm(x[t]^2/20, prec_y)
%       }
%     }
%
% Although the nonlinear function f can be defined in BUGS language, we
% choose here to use an external user-defined function 'funmat', which will
% call a Matlab function. 

%% User-defined functions in Matlab
% The BUGS model calls a function funcmat. In order to be able to use this
% function, one needs to create two functions in Matlab. The first
% function, called here 'f_eval.m' provides the evaluation of the function.
%
% *f_eval.m*
%
%     function out = f_eval(x, k)
% 
%     out = .5 * x + 25*x/(1+x^2) + 8*cos(1.2*k);
%
% The second function, f_dim.m, provides the dimensions of the output of f_eval, 
% possibly depending on the dimensions of the inputs.
%
% *f_dim.m* 
%
%     function out_dim = f_dim(x_dim, k_dim)
% 
%     out_dim = [1,1];


%% Installation of Matbiips
% Unzip the Matbiips archive in some folder
% and add the Matbiips folder to the Matlab path
% 

matbiips_path = '../../matbiips/matlab';
addpath(matbiips_path)

%% Load model and data
%

%%
% *Model parameters*
t_max = 20;
mean_x_init = 0;
prec_x_init = 1/5;
prec_x = 1/10;
prec_y = 1;
data = struct('t_max', t_max, 'prec_x_init', prec_x_init,...
    'prec_x', prec_x,  'prec_y', prec_y, 'mean_x_init', mean_x_init);

%%
% *Add the user-defined function 'funmat'*
fun_bugs = 'funmat'; fun_dim = 'f_dim';funeval = 'f_eval';fun_nb_inputs = 2;
biips_add_function(fun_bugs, fun_nb_inputs, fun_dim, funeval)


%%
% *Compile BUGS model and sample data*
model_filename = 'hmm_1d_nonlin_funmat.bug'; % BUGS model filename
sample_data = true; % Boolean
model = biips_model(model_filename, data, 'sample_data', sample_data); % Create biips model and sample data
data = model.data;

%% BiiPS Sequential Monte Carlo
% Let now use BiiPS to run a particle filter. 

%%
% *Parameters of the algorithm*. We want to monitor the variable x, and to
% get the filtering and smoothing particle approximations. The algorithm
% will use 10000 particles, stratified resampling, with a threshold of 0.5.
n_part = 10000; % Number of particles
variables = {'x'}; % Variables to be monitored
type = 'fs'; rs_type = 'stratified'; rs_thres = 0.5; % Optional parameters

%%
% *Run SMC*
out_smc = biips_smc_samples(model, variables, n_part,...
    'type', type, 'rs_type', rs_type, 'rs_thres', rs_thres);

%%
% *Diagnosis on the algorithm*. 
diag = biips_diagnosis(out_smc);

%%
% *Summary statistics*
summary = biips_summary(out_smc, 'probs', [.025, .975]);

%%
% *Plot Filtering estimates*
x_f_mean = summary.x.f.mean;
x_f_quant = summary.x.f.quant;
figure('name', 'SMC: Filtering estimates')
h = fill([1:t_max, t_max:-1:1], [x_f_quant{1}; flipud(x_f_quant{2})],...
    [.7 .7 1]);
set(h, 'edgecolor', 'none')
hold on
plot(x_f_mean, 'linewidth', 3)
hold on
plot(data.x_true, 'g', 'linewidth', 2)
xlabel('Time')
ylabel('Estimates')
legend({'95 % credible interval', 'Filtering mean estimate', 'True value'})
legend('boxoff')
box off

%%
% *Plot Smoothing estimates*
x_s_mean = summary.x.s.mean;
x_s_quant = summary.x.s.quant;
figure('name', 'SMC: Smoothing estimates')
h = fill([1:t_max, t_max:-1:1], [x_s_quant{1}; flipud(x_s_quant{2})],...
    [1 .7 .7]);
set(h, 'edgecolor', 'none')
hold on
plot(x_s_mean, 'r', 'linewidth', 3)
hold on
plot(data.x_true, 'g', 'linewidth', 2)
xlabel('Time')
ylabel('Estimates')
legend({'95 % credible interval', 'Smoothing mean estimate', 'True value'})
legend('boxoff')
box off

%%
% Marginal filtering and smoothing densities

kde_estimates = biips_density(out_smc);
time_index = [5, 10, 15];
figure('name', 'SMC: Marginal posteriors')
for k=1:length(time_index)
    tk = time_index(k);
    subplot(2, 2, k)
    plot(kde_estimates.x.f(tk).x, kde_estimates.x.f(tk).f);
    hold on
    plot(kde_estimates.x.s(tk).x, kde_estimates.x.s(tk).f, 'r');
    plot(data.x_true(tk), 0, '*g');
    xlabel(['x_{', num2str(tk), '}']);
    ylabel('Posterior density');
    title(['t=', num2str(tk)]);   
    box off
end
h = legend({'Filtering density', 'Smoothing density', 'True value'});
set(h, 'position',[0.7, 0.25, .1, .1])
legend('boxoff')

%% Clear model
% 

biips_clear()
                                                                        examples/tutorial/f_dim.m                                                                           000664  001750  001750  00000000072 12324336155 020346  0                                                                                                    ustar 00adrien-alea                     adrien-alea                     000000  000000                                                                                                                                                                         function out_dim = f_dim(x_dim, k_dim)

out_dim = [1,1];                                                                                                                                                                                                                                                                                                                                                                                                                                                                      examples/tutorial/tutorial2.m                                                                       000664  001750  001750  00000017746 12364150347 021236  0                                                                                                    ustar 00adrien-alea                     adrien-alea                     000000  000000                                                                                                                                                                         %% Matbiips: Tutorial 2
% In this tutorial, we consider applying sequential Monte Carlo methods for
% sensitivity analysis and parameter estimation in a nonlinear non-Gaussian hidden Markov model.

%% Statistical model
% The statistical model is defined as follows.
%
% $$ x_1\sim \mathcal N\left (\mu_0, \frac{1}{\lambda_0}\right )$$
%
% $$ y_1\sim \mathcal N\left (h(x_1), \frac{1}{\lambda_y}\right )$$
%
% For $t=2:t_{max}$
%
% $$ x_t|x_{t-1} \sim \mathcal N\left ( f(x_{t-1},t-1), \frac{1}{\lambda_x}\right )$$
%
% $$ y_t|x_t \sim \mathcal N\left ( h(x_{t}), \frac{1}{\lambda_y}\right )$$
%
% with $\mathcal N\left (m, S\right )$ stands for the Gaussian distribution
% of mean $m$ and covariance matrix $S$, $h(x)=x^2/20$, $f(x,t-1)=0.5
% x+25 x/(1+x^2)+8 \cos(1.2 (t-1))$, $\mu_0=0$, $\lambda_0 = 5$, $\lambda_x
% = 0.1$. The precision of the observation noise
% $\lambda_y$ is also assumed to be unknown. We will assume a uniform prior
% for $\log(\lambda_y)$:
%
% $$ \log(\lambda_y) \sim Unif([-3,3]) $$

%% Statistical model in BUGS language
% One needs to describe the model in BUGS language. We create the file
%  'hmm_1d_nonlin_param.bug':

%%
%
%
%         var x_true[t_max], x[t_max], y[t_max]
%
%         data
%         {
%           prec_y_true <- exp(log_prec_y_true)
%           x_true[1] ~ dnorm(mean_x_init, prec_x_init)
%           y[1] ~ dnorm(x_true[1]^2/20, prec_y_true)
%           for (t in 2:t_max)
%           {
%             x_true[t] ~ dnorm(0.5*x_true[t-1]+25*x_true[t-1]/(1+x_true[t-1]^2)+8*cos(1.2*(t-1)), prec_x)
%             y[t] ~ dnorm(x_true[t]^2/20, prec_y_true)
%           }
%         }
%
%         model
%         {
%           log_prec_y ~ dunif(-3, 3)
%           prec_y <- exp(log_prec_y)
%           x[1] ~ dnorm(mean_x_init, prec_x_init)
%           y[1] ~ dnorm(x[1]^2/20, prec_y)
%           for (t in 2:t_max)
%           {
%             x[t] ~ dnorm(0.5*x[t-1]+25*x[t-1]/(1+x[t-1]^2)+8*cos(1.2*(t-1)), prec_x)
%             y[t] ~ dnorm(x[t]^2/20, prec_y)
%           }
%         }

%% Installation of Matbiips
% Unzip the Matbiips archive in some folder
% and add the Matbiips folder to the Matlab path
%

matbiips_path = '../../matbiips/matlab';
addpath(matbiips_path)

%% Load model and data
%

%%
% *Model parameters*
t_max = 20;
mean_x_init = 0;
prec_x_init = 1;
prec_x = 10;
log_prec_y_true = log(1); % True value used to sample the data
data = struct('t_max', t_max, 'prec_x_init', prec_x_init,...
    'prec_x', prec_x,  'log_prec_y_true', log_prec_y_true, 'mean_x_init', mean_x_init);

%%
% *Compile BUGS model and sample data*
model = 'hmm_1d_nonlin_param.bug'; % BUGS model filename
sample_data = true; % Boolean
model = biips_model(model, data, 'sample_data', sample_data); % Create biips model and sample data
data = model.data;


%% BiiPS : Sensitivity analysis with Sequential Monte Carlo
% Let now use BiiPS to provide estimates of the marginal log-likelihood and
% log-posterior (up to a normalizing constant) given various values of the
% log-precision parameters $\log(\lambda_y)$ .

%%
% *Parameters of the algorithm*.
n_part = 100; % Number of particles
param_names = {'log_prec_y'}; % Parameter for which we want to study sensitivity
param_values = {-5:.2:3}; % Range of values

%%
% *Run sensitivity analysis with SMC*
out = biips_smc_sensitivity(model, param_names, param_values, n_part);

%%
% *Plot log-marginal likelihood and penalized log-marginal likelihood*
figure('name', 'Log-marginal likelihood');
plot(param_values{1}, out.log_marg_like, '.')
xlabel('Parameter log\_prec\_y')
ylabel('Log-marginal likelihood')

figure('name', 'Penalized log-marginal likelihood');
plot(param_values{1}, out.log_post, '.')
xlabel('Parameter log\_prec\_y')
ylabel('Penalized log-marginal likelihood')


%% BiiPS Particle Marginal Metropolis-Hastings
% We now use BiiPS to run a Particle Marginal Metropolis-Hastings in order
% to obtain posterior MCMC samples of the parameter and variables x.

%%
% *Parameters of the PMMH*
% param_names indicates the parameters to be sampled using a random walk
% Metroplis-Hastings step. For all the other variables, biips will use a
% sequential Monte Carlo as proposal.
n_burn = 2000; % nb of burn-in/adaptation iterations
n_iter = 2000; % nb of iterations after burn-in
thin = 1; % thinning of MCMC outputs
n_part = 50; % nb of particles for the SMC
var_name = 'log_prec_y';
param_names = {var_name}; % name of the variables updated with MCMC (others are updated with SMC)
latent_names = {'x'}; % name of the variables updated with SMC and that need to be monitored

%%
% *Init PMMH*
obj_pmmh = biips_pmmh_init(model, param_names, 'inits', {-2},...
    'latent_names', latent_names); % creates a pmmh object

%%
% *Run PMMH*
obj_pmmh = biips_pmmh_update(obj_pmmh, n_burn, n_part); % adaptation and burn-in iterations
[obj_pmmh, out_pmmh, log_post, log_marg_like, stats_pmmh] = biips_pmmh_samples(obj_pmmh, n_iter, n_part,...
    'thin', 1); % Samples

%%
% *Some summary statistics*
summary_pmmh = biips_summary(out_pmmh, 'probs', [.025, .975]);

%%
% *Compute kernel density estimates*
kde_estimates_pmmh = biips_density(out_pmmh);

%%
% *Posterior mean and credibilist interval for the parameter*
sum_var = getfield(summary_pmmh, var_name);
fprintf('Posterior mean of log_prec_y: %.1f\n', sum_var.mean);
fprintf('95%% credibilist interval for log_prec_y: [%.1f,%.1f]\n',...
    sum_var.quant{1},  sum_var.quant{2});


%%
% *Trace of MCMC samples for the parameter*
mcmc_samples = getfield(out_pmmh, var_name);
figure('name', 'PMMH: Trace samples parameter')
plot(mcmc_samples)
hold on
plot(0, data.log_prec_y_true, '*g');
xlabel('Iterations')
ylabel('PMMH samples')
title('log\_prec\_y')
box off
legend('boxoff')

%%
% *Histogram and kde estimate of the posterior for the parameter*
figure('name', 'PMMH: Histogram posterior parameter')
hist(mcmc_samples, 15)
hold on
plot(data.log_prec_y_true, 0, '*g');
xlabel('log\_prec\_y')
ylabel('Number of samples')
title('log\_prec\_y')
box off
legend('boxoff')

kde_var = getfield(kde_estimates_pmmh, var_name);
figure('name', 'PMMH: KDE estimate posterior parameter')
plot(kde_var.x, kde_var.f);
hold on
plot(data.log_prec_y_true, 0, '*g');
xlabel('log\_prec\_y');
ylabel('Posterior density');
box off
legend('boxoff')


%%
% *Posterior mean and quantiles for x*
x_pmmh_mean = summary_pmmh.x.mean;
x_pmmh_quant = summary_pmmh.x.quant;
figure('name', 'PMMH: Posterior mean and quantiles')
h = fill([1:t_max, t_max:-1:1], [x_pmmh_quant{1}; flipud(x_pmmh_quant{2})],...
    [.7 .7 1]);
set(h, 'edgecolor', 'none')
hold on
plot(x_pmmh_mean, 'linewidth', 3)
xlabel('Time')
ylabel('Estimates')
legend({'95 % credible interval', 'PMMH mean estimate'})
box off
legend('boxoff')

%%
% *Trace of MCMC samples for x*
time_index = [5, 10, 15];
figure('name', 'PMMH: Trace samples x')
for k=1:length(time_index)
    tk = time_index(k);
    subplot(2, 2, k)
    plot(out_pmmh.x(tk, :))
    hold on
    plot(0, data.x_true(tk), '*g');
    xlabel('Iterations')
    ylabel('PMMH samples')
    title(['t=', num2str(tk)]);
    legend('boxoff')
end
h = legend({'PMMH samples', 'True value'});
set(h, 'position',[0.7 0.25, .1, .1])
legend boxoff

%%
% *Histogram and kernel density estimate of posteriors of x*
figure('name', 'PMMH: Histograms marginal posteriors')
for k=1:length(time_index)
    tk = time_index(k);
    subplot(2, 2, k)
    hist(out_pmmh.x(tk, :), 15);
    hold on
    plot(data.x_true(tk), 0, '*g');
    xlabel(['x_{' num2str(tk) '}']);
    ylabel('Number of samples');
    title(['t=', num2str(tk)]);
    box off
end
h = legend({'Posterior samples', 'True value'});
set(h, 'position',[0.7 0.25, .1, .1])
legend boxoff

figure('name', 'PMMH: KDE estimates marginal posteriors')
for k=1:length(time_index)
    tk = time_index(k);
    subplot(2, 2, k)
    plot(kde_estimates_pmmh.x(tk).x, kde_estimates_pmmh.x(tk).f);
    hold on
    plot(data.x_true(tk), 0, '*g');
    xlabel(['x_{' num2str(tk) '}']);
    ylabel('Posterior density');
    title(['t=', num2str(tk)]);
    box off
end
h = legend({'Posterior density', 'True value'});
set(h, 'position',[0.7 0.25, .1, .1]);
legend boxoff


%% Clear model
%

biips_clear()
                          examples/tutorial/tutorial1.m                                                                       000664  001750  001750  00000017253 12364150277 021230  0                                                                                                    ustar 00adrien-alea                     adrien-alea                     000000  000000                                                                                                                                                                         %% Matbiips: Tutorial 1
% In this tutorial, we consider applying sequential Monte Carlo methods for
% Bayesian inference in a nonlinear non-Gaussian hidden Markov model.

%% Statistical model
% The statistical model is defined as follows.
%
% $$ x_1\sim \mathcal N\left (\mu_0, \frac{1}{\lambda_0}\right )$$
%
% $$ y_1\sim \mathcal N\left (h(x_1), \frac{1}{\lambda_y}\right )$$
%
% For $t=2:t_{max}$
%
% $$ x_t|x_{t-1} \sim \mathcal N\left ( f(x_{t-1},t-1), \frac{1}{\lambda_x}\right )$$
%
% $$ y_t|x_t \sim \mathcal N\left ( h(x_{t}), \frac{1}{\lambda_y}\right )$$
%
% with $\mathcal N\left (m, S\right )$ stands for the Gaussian distribution 
% of mean $m$ and covariance matrix $S$, $h(x)=x^2/20$, $f(x,t-1)=0.5 x+25 x/(1+x^2)+8 \cos(1.2 (t-1))$, $\mu_0=0$, $\lambda_0 = 5$, $\lambda_x = 0.1$ and $\lambda_y=1$. 

%% Statistical model in BUGS language
% One needs to describe the model in BUGS language. We create the file
%  'hmm_1d_nonlin.bug':

%%
%
% 
%     var x_true[t_max], x[t_max], y[t_max]
% 
%     data
%     {
%       x_true[1] ~ dnorm(mean_x_init, prec_x_init)
%       y[1] ~ dnorm(x_true[1]^2/20, prec_y)
%       for (t in 2:t_max)
%       {
%         x_true[t] ~ dnorm(0.5*x_true[t-1]+25*x_true[t-1]/(1+x_true[t-1]^2)+8*cos(1.2*(t-1)), prec_x)
%         y[t] ~ dnorm(x_true[t]^2/20, prec_y)
%       }
%     }
% 
%     model
%     {
%       x[1] ~ dnorm(mean_x_init, prec_x_init)
%       y[1] ~ dnorm(x[1]^2/20, prec_y)
%       for (t in 2:t_max)
%       {
%         x[t] ~ dnorm(0.5*x[t-1]+25*x[t-1]/(1+x[t-1]^2)+8*cos(1.2*(t-1)), prec_x)
%         y[t] ~ dnorm(x[t]^2/20, prec_y)
%       }
%     }

set(0, 'DefaultAxesFontsize', 14);

%% Installation of Matbiips
% Unzip the Matbiips archive in some folder
% and add the Matbiips folder to the Matlab path
% 

%% 
% *Add Matbiips functions in the search path*
matbiips_path = '../../matbiips/matlab';
addpath(matbiips_path)

%% Load model and data
%

%%
% *Model parameters*
t_max = 20;
mean_x_init = 0;
prec_x_init = 1/5;
prec_x = 1/10;
prec_y = 1;
data = struct('t_max', t_max, 'prec_x_init', prec_x_init,...
    'prec_x', prec_x,  'prec_y', prec_y, 'mean_x_init', mean_x_init);


%%
% *Compile BUGS model and sample data*
model_filename = 'hmm_1d_nonlin.bug'; % BUGS model filename
sample_data = true; % Boolean
model = biips_model(model_filename, data, 'sample_data', sample_data); % Create biips model and sample data
data = model.data;

%% BiiPS Sequential Monte Carlo
% Let now use BiiPS to run a particle filter. 

%%
% *Parameters of the algorithm*. We want to monitor the variable x, and to
% get the filtering and smoothing particle approximations. The algorithm
% will use 10000 particles, stratified resampling, with a threshold of 0.5.
n_part = 10000; % Number of particles
variables = {'x'}; % Variables to be monitored
type = 'fs'; rs_type = 'stratified'; rs_thres = 0.5; % Optional parameters

%%
% *Run SMC*
out_smc = biips_smc_samples(model, variables, n_part,...
    'type', type, 'rs_type', rs_type, 'rs_thres', rs_thres);

%%
% *Diagnosis on the algorithm*. 
biips_diagnosis(out_smc);

%%
% *Summary statistics*
summ = biips_summary(out_smc, 'probs', [.025, .975]);


%%
% *Plot Filtering estimates*
x_f_mean = summ.x.f.mean;
x_f_quant = summ.x.f.quant;
figure('name', 'SMC: Filtering estimates')
h = fill([1:t_max, t_max:-1:1], [x_f_quant{1}; flipud(x_f_quant{2})],...
    [.7 .7 1]);
set(h, 'edgecolor', 'none')
hold on
plot(x_f_mean, 'linewidth', 3)
hold on
plot(data.x_true, 'g', 'linewidth', 2)
xlabel('Time')
ylabel('Estimates')
legend({'95 % credible interval', 'Filtering mean estimate', 'True value'})
legend('boxoff')
box off

%%
% *Plot Smoothing estimates*
x_s_mean = summ.x.s.mean;
x_s_quant = summ.x.s.quant;
figure('name', 'SMC: Smoothing estimates')
h = fill([1:t_max, t_max:-1:1], [x_s_quant{1}; flipud(x_s_quant{2})],...
    [1 .7 .7]);
set(h, 'edgecolor', 'none')
hold on
plot(x_s_mean, 'r', 'linewidth', 3)
hold on
plot(data.x_true, 'g', 'linewidth', 2)
xlabel('Time')
ylabel('Estimates')
legend({'95 % credible interval', 'Smoothing mean estimate', 'True value'})
legend('boxoff')
box off

% %%
% % *Plot Backward smoothing estimates*
% x_b_mean = summ.x.b.mean;
% x_b_quant = summ.x.b.quant;
% figure('name', 'SMC: Backward smoothing estimates')
% h = fill([1:t_max, t_max:-1:1], [x_b_quant{1}; flipud(x_b_quant{2})],...
%     [.7 .7 1]);
% set(h, 'edgecolor', 'none')
% hold on
% plot(x_b_mean, 'linewidth', 3)
% xlabel('Time')
% ylabel('Estimates')
% legend({'95 % credible interval', 'Backward smoothing mean estimate'})
% legend('boxoff')
% box off

%%
% *Marginal filtering and smoothing densities*

kde_estimates = biips_density(out_smc);
time_index = [5, 10, 15];
figure('name', 'SMC: Marginal posteriors')
for k=1:length(time_index)
    tk = time_index(k);
    subplot(2, 2, k)
    plot(kde_estimates.x.f(tk).x, kde_estimates.x.f(tk).f);
    hold on
    plot(kde_estimates.x.s(tk).x, kde_estimates.x.s(tk).f, 'r');
    plot(data.x_true(tk), 0, '*g');
    xlabel(['x_{', num2str(tk), '}']);
    ylabel('Posterior density');
    title(['t=', num2str(tk)]);  
    xlim([-20,20])
    box off
end
h = legend({'Filtering density', 'Smoothing density', 'True value'});
set(h, 'position',[0.7, 0.25, .1, .1])
legend('boxoff')


%% BiiPS Particle Independent Metropolis-Hastings
% We now use BiiPS to run a Particle Independent Metropolis-Hastings

%%
% *Parameters of the PIMH*
n_burn = 500;
n_iter = 500;
thin = 1;
n_part = 100;

%%
% *Run PIMH*
obj_pimh = biips_pimh_init(model, variables);
obj_pimh = biips_pimh_update(obj_pimh, n_burn, n_part); % burn-in iterations
[obj_pimh, samples_pimh, log_marg_like_pimh] = biips_pimh_samples(obj_pimh,...
    n_iter, n_part, 'thin', thin);

%%
% *Some summary statistics*
summ_pimh = biips_summary(samples_pimh, 'probs', [.025, .975]);

%%
% *Posterior mean and quantiles*
x_pimh_mean = summ_pimh.x.mean;
x_pimh_quant = summ_pimh.x.quant;
figure('name', 'PIMH: Posterior mean and quantiles')
h = fill([1:t_max, t_max:-1:1], [x_pimh_quant{1}; flipud(x_pimh_quant{2})],...
    [.7 .7 1]);
set(h, 'edgecolor', 'none')
hold on
plot(x_pimh_mean, 'linewidth', 3)
plot(data.x_true, 'g', 'linewidth', 2)
xlabel('Time')
ylabel('Estimates')
legend({'95 % credible interval', 'PIMH mean estimate', 'True value'})
legend('boxoff')
box off

%%
% *Trace of MCMC samples*
time_index = [5, 10, 15];
figure('name', 'PIMH: Trace samples')
for k=1:length(time_index)
    tk = time_index(k);
    subplot(2, 2, k)
    plot(samples_pimh.x(tk, :))
    hold on
    plot(0, data.x_true(tk), '*g');  
    xlabel('Iterations')
    ylabel('PIMH samples')
    title(['t=', num2str(tk)]);
    box off
end
h = legend({'PIMH samples', 'True value'});
set(h, 'position',[0.7 0.25, .1, .1])
legend('boxoff')

%%
% *Histograms of posteriors*
figure('name', 'PIMH: Histograms marginal posteriors')
for k=1:length(time_index)
    tk = time_index(k);
    subplot(2, 2, k)
    hist(samples_pimh.x(tk, :), 20);
    hold on    
    plot(data.x_true(tk), 0, '*g');
    xlabel(['x_{', num2str(tk), '}']);
    ylabel('Number of samples');
    title(['t=', num2str(tk)]);   
    xlim([-20,20])
    box off
end
h = legend({'Posterior density', 'True value'});
set(h, 'position', [0.7, 0.25, .1, .1])
legend('boxoff')

%%
% *Kernel density estimates of posteriors*
kde_estimates_pimh = biips_density(samples_pimh);
figure('name', 'PIMH: KDE estimates marginal posteriors')
for k=1:length(time_index)
    tk = time_index(k);
    subplot(2, 2, k)
    plot(kde_estimates_pimh.x(tk).x, kde_estimates_pimh.x(tk).f); 
    hold on
    plot(data.x_true(tk), 0, '*g');
    xlabel(['x_{', num2str(tk) '}']);
    ylabel('Posterior density');
    title(['t=', num2str(tk)]);    
    xlim([-20,20])
    box off
end
h = legend({'Posterior density', 'True value'});
set(h, 'position',[0.7, 0.25, .1, .1])
legend('boxoff')

%% Clear model
% 

biips_clear()
                                                                                                                                                                                                                                                                                                                                                     examples/tutorial/f_eval.m                                                                          000664  001750  001750  00000000112 12324336155 020517  0                                                                                                    ustar 00adrien-alea                     adrien-alea                     000000  000000                                                                                                                                                                         function out = f_eval(x, k)

out = .5 * x + 25*x/(1+x^2) + 8*cos(1.2*k);                                                                                                                                                                                                                                                                                                                                                                                                                                                      examples/stoch_kinetic/stoch_kinetic.m                                                              000664  001750  001750  00000021163 12354240235 023101  0                                                                                                    ustar 00adrien-alea                     adrien-alea                     000000  000000                                                                                                                                                                         %% Matbiips example: Stochastic kinetic prey/predator model
%
%
% Reference: A. Golightly and D. J. Wilkinson. Bayesian parameter inference 
% for stochastic biochemical network models using particle Markov chain
% Monte Carlo. Interface Focus, vol.1, pp. 807-820, 2011.

%% Statistical model
%
% Let $\delta_t=1/m$ where $m$ is an integer, and $T$ a multiple of $m$.
% For $t=1,\ldots,T$
% $$ x_t|x_{t-1}\sim \mathcal N(x_{t-1}+\alpha(x_{t-1},c)\delta_t,\beta(x_{t-1},c)\delta_t)$$
% 
% where $$\alpha(x,c) = \left(
%                   \begin{array}{c}
%                     c_1x_1-c_2x_1x_2  \\
%                     c_2x_1x_2-c_3x_2 \\
%                   \end{array}
%                 \right)$$
% 
%      $$\beta(x,c) = \left(
%                   \begin{array}{cc}
%                     c_1x_1+c_2x_1x_2 & -c_2x_1x_2\\
%                     -c_2x_1x_2 & c_2x_1x_2 + c_3x_2 \\
%                   \end{array}
%                 \right)$$ 
% 
% 
% For $t=m,2m,3m,\ldots,T$, 
% $$y_t|x_t\sim \mathcal N(x_{1t},\sigma^2)$$
% 
%           
% and for $i=1,\ldots,3$
% 
% $$ \log(c_i)\sim Unif(-7,2) $$
% 
% 
% $x_{t1}$ and $x_{t2}$ respectively correspond to the number of preys and predators and $y_t$ is the approximated number of preys. The model is the approximation of the Lotka-Volterra model.



%% Statistical model in BUGS language
%
%     var x_true[2,t_max/dt],x_true_temp[2,t_max/dt],x_temp[2,t_max/dt], x[2,t_max/dt], y[t_max/dt], beta[2,2,t_max/dt], beta_true[2,2,t_max/dt], logc[3],c[3],c_true[3]
% 
%     data
%     {	
%       x_true[,1] ~ dmnormvar(x_init_mean,  x_init_var)
%       for (t in 2:t_max/dt)
%       { 
%         alpha_true[1,t] <- c_true[1] * x_true[1,t-1] - c_true[2]*x_true[1,t-1]*x_true[2,t-1]
%         alpha_true[2,t] <- c_true[2]*x_true[1,t-1]*x_true[2,t-1] - c_true[3]*x_true[2,t-1]
%         beta_true[1,1,t] <- c_true[1]*x_true[1,t-1] + c_true[2]*x_true[1,t-1]*x_true[2,t-1]
%         beta_true[1,2,t] <- -c_true[2]*x_true[1,t-1]*x_true[2,t-1]
%         beta_true[2,1,t] <- beta_true[1,2,t]
%         beta_true[2,2,t] <- c_true[2]*x_true[1,t-1]*x_true[2,t-1] + c_true[3]*x_true[2,t-1]
%         x_true_temp[,t] ~ dmnormvar(x_true[,t-1]+alpha_true[,t]*dt, (beta_true[,,t])*dt) 
%         # To avoid extinction
%         x_true[1,t] <- max(x_true_temp[1,t],1) 
%         x_true[2,t] <- max(x_true_temp[2,t],1) 
%       }
%       for (t in 1:t_max)	
%       {
%         y[t/dt] ~ dnorm(x_true[1,t/dt], prec_y) 
%       }
%     }
% 
%     model
%     {
%       logc[1] ~ dunif(-7,2)
%       logc[2] ~ dunif(-7,2)
%       logc[3] ~ dunif(-7,2)
%       c[1] <- exp(logc[1])
%       c[2] <- exp(logc[2])
%       c[3] <- exp(logc[3])
%       x[,1] ~ dmnormvar(x_init_mean,  x_init_var)
%       for (t in 2:t_max/dt)
%       { 
%         alpha[1,t] <- c[1]*x[1,t-1] - c[2]*x[1,t-1]*x[2,t-1]
%         alpha[2,t] <- c[2]*x[1,t-1]*x[2,t-1] - c[3]*x[2,t-1]
%         beta[1,1,t] <- c[1]*x[1,t-1] + c[2]*x[1,t-1]*x[2,t-1]
%         beta[1,2,t] <- -c[2]*x[1,t-1]*x[2,t-1]
%         beta[2,1,t] <- beta[1,2,t]
%         beta[2,2,t] <- c[2]*x[1,t-1]*x[2,t-1] + c[3]*x[2,t-1]
%         x_temp[,t] ~ dmnormvar(x[,t-1]+alpha[,t]*dt, beta[,,t]*dt)  
%         # To avoid extinction 
%         x[1,t] <- max(x_temp[1,t],1)
%         x[2,t] <- max(x_temp[2,t],1)
%       }
%       for (t in 1:t_max)	
%       {
%         y[t/dt] ~ dnorm(x[1,t/dt], prec_y) 
%       }
%     }

%% Installation of Matbiips
% Unzip the Matbiips archive in some folder
% and add the Matbiips folder to the Matlab path
% 

matbiips_path = '../../matbiips/matlab';
addpath(matbiips_path)

%% Load model and data
%

%%
% *Model parameters*
t_max = 20;
dt = 0.20;
x_init_mean = [100 ;100];
x_init_var = 10*eye(2);
c_true = [.5, 0.0025,.3];
prec_y = 1/10;
data = struct('t_max', t_max, 'dt', dt, 'c_true', c_true,...
    'x_init_mean', x_init_mean, 'x_init_var', x_init_var, 'prec_y', prec_y);


%%
% *Compile BUGS model and sample data*
model_filename = 'stoch_kinetic_cle.bug'; % BUGS model filename
sample_data = true; % Boolean
model = biips_model(model_filename, data, 'sample_data', sample_data); % Create biips model and sample data
data = model.data;

%%
% *Plot data*
figure('name', 'data')
plot(dt:dt:t_max, data.x_true(1,:), 'linewidth', 2)
hold on
plot(dt:dt:t_max, data.x_true(2,:), 'r', 'linewidth', 2)
hold on
plot(dt:dt:t_max, data.y, 'g*')
xlabel('Time')
ylabel('Number of individuals')
legend('Prey', 'Predator', 'Measurements')

%% BiiPS : Sensitivity analysis with Sequential Monte Carlo


%%
% *Parameters of the algorithm*. 
n_part = 100; % Number of particles
param_names = {'logc[1]','logc[2]','logc[3]'}; % Parameter for which we want to study sensitivity
param_values = {linspace(-7,1,20),log(c_true(2))*ones(20,1),log(c_true(3))*ones(20,1)}; % Range of values

% n_grid = 5;
% [param_values{1:3}] = meshgrid(linspace(-7,1,n_grid), linspace(-7,1,n_grid), linspace(-7,1,n_grid));
% param_values = cellfun(@(x) x(:), param_values, 'uniformoutput', false);

%%
% *Run sensitivity analysis with SMC*
out = biips_smc_sensitivity(model, param_names, param_values, n_part); 

%%
% *Plot penalized log-marginal likelihood*
figure('name', 'penalized log-marginal likelihood');
plot(param_values{1}, out.log_post, '.')
xlabel('log(c_1)')
ylabel('Penalized log-marginal likelihood')


%% BiiPS Particle Marginal Metropolis-Hastings
% We now use BiiPS to run a Particle Marginal Metropolis-Hastings in order
% to obtain posterior MCMC samples of the parameters and variables x.

%%
% *Parameters of the PMMH*
% param_names indicates the parameters to be sampled using a random walk
% Metroplis-Hastings step. For all the other variables, biips will use a
% sequential Monte Carlo as proposal.
n_burn = 20;%2000; % nb of burn-in/adaptation iterations
n_iter = 20;%2000; % nb of iterations after burn-in
thin = 20; % thinning of MCMC outputs
n_part = 100; % nb of particles for the SMC

param_names = {'logc[1]','logc[2]', 'logc[3]'}; % name of the variables updated with MCMC (others are updated with SMC)
latent_names = {'x'}; % name of the variables updated with SMC and that need to be monitored

%%
% *Init PMMH*
obj_pmmh = biips_pmmh_init(model, param_names, 'inits', {-1, -6, -1}...
    , 'latent_names', latent_names); % creates a pmmh object

%%
% *Run PMMH*
[obj_pmmh, stats] = biips_pmmh_update(obj_pmmh, n_burn, n_part); % adaptation and burn-in iterations
[obj_pmmh, out_pmmh, log_post, log_marg_like, stats_pmmh] = biips_pmmh_samples(obj_pmmh, n_iter, n_part,...
    'thin', 1); % Samples
 
%%
% *Some summary statistics*
summary_pmmh = biips_summary(out_pmmh, 'probs', [.025, .975]);

%%
% *Compute kernel density estimates*
kde_estimates_pmmh = biips_density(out_pmmh);

param_true = log(c_true);
leg = {'log(c_1)', 'log(c_2)', 'log(c_3)'};

%%
% *Posterior mean and credibilist interval for the parameter*
for i=1:length(param_names)
    fprintf('Posterior mean of %s: %.1f\n', leg{i}, summary_pmmh.(param_names{i}).mean);
    fprintf('95%% credibilist interval for %s: [%.1f,%.1f]\n',leg{i},...
        summary_pmmh.(param_names{1}).quant{1},  summary_pmmh.(param_names{1}).quant{2});
end



%%
% *Trace of MCMC samples for the parameter*
for i=1:length(param_names)
    figure('name', 'PMMH: Trace samples parameter')
    plot(out_pmmh.(param_names{i}))
    hold on
    plot(0, param_true(i), '*g');  
    xlabel('Iterations')
    ylabel('PMMH samples')
    title(leg{i})
end

%%
% *Histogram and kde estimate of the posterior for the parameter*
for i=1:length(param_names)
    figure('name', 'PMMH: Histogram posterior parameter')
    hist(out_pmmh.(param_names{i}), 15)
    hold on
    plot(param_true(i), 0, '*g');  
    xlabel(leg{i})
    ylabel('number of samples')
    title(leg{i})
end

for i=1:length(param_names)
    figure('name', 'PMMH: KDE estimate posterior parameter')
    plot(kde_estimates_pmmh.(param_names{i}).x,...
        kde_estimates_pmmh.(param_names{i}).f); 
    hold on
    plot(param_true(i), 0, '*g');  
    xlabel(leg{i});
    ylabel('posterior density');
end
   

%%
% *Posterior mean and quantiles for x*
x_pmmh_mean = summary_pmmh.x.mean;
x_pmmh_quant = summary_pmmh.x.quant;
figure('name', 'PMMH: Posterior mean and quantiles')
n_grid = fill([1:t_max/dt, t_max/dt:-1:1], [x_pmmh_quant{1}(1,:), fliplr(x_pmmh_quant{2}(1,:))],...
    [.7 .7 1]);
set(n_grid, 'edgecolor', 'none')
hold on
plot(x_pmmh_mean(1, :), 'linewidth', 3)
h2 = fill([1:t_max/dt, t_max/dt:-1:1], [x_pmmh_quant{1}(2,:), fliplr(x_pmmh_quant{2}(2,:))],...
    [1 .7 .7]);
set(h2, 'edgecolor', 'none')
plot(x_pmmh_mean(2, :),'r', 'linewidth', 3)
set(n_grid, 'edgecolor', 'none')
xlabel('Time')
ylabel('Estimates')
legend({'95 % credible interval - prey', 'PMMH Mean Estimate - prey',...
    '95 % credible interval - predator', 'PMMH Mean Estimate - predator'})
 

%% Clear model
% 

biips_clear(model)
                                                                                                                                                                                                                                                                                                                                                                                                             examples/stoch_kinetic/lotka_volterra_dim.m                                                         000664  001750  001750  00000000121 12324336155 024127  0                                                                                                    ustar 00adrien-alea                     adrien-alea                     000000  000000                                                                                                                                                                         function out_dim = f_dim(x_dim, c1_dim, c2_dim, c3_dim, dt_dim)

out_dim = [2,1];                                                                                                                                                                                                                                                                                                                                                                                                                                               examples/stoch_kinetic/lotka_volterra_gillespie.m                                                   000664  001750  001750  00000001235 12324336155 025342  0                                                                                                    ustar 00adrien-alea                     adrien-alea                     000000  000000                                                                                                                                                                         function x = lotka_volterra_gillespie(x, c1, c2, c3, dt)

% Simulation from a Lotka-Volterra model with the Gillepsie algorithm
% x1 is the number of prey
% x2 is the number of predator
% R1: (x1,x2) -> (x1+1,x2)      At rate c1x1
% R2: (x1,x2) -> (x1-1,x2+1)    At rate c2x1x2
% R3: (x1,x2) -> (x1,x2-1)      At rate c3xx2

z = [1, -1, 0;
    0, 1, -1];

t=0;
while 1   
    rate = [c1*x(1), c2*x(1)*x(2), c3*x(2)];
    sum_rate = sum(rate);
    t = t - log(rand)/sum_rate; % Sample next event from an exponential distribution
    ind = find((sum_rate*rand)<=cumsum(rate), 1); % Sample the type of event    
    if t>dt
        break
    end
    x = x + z(:, ind);
end                                                                                                                                                                                                                                                                                                                                                                   examples/stoch_kinetic/stoch_kinetic_gill.m                                                         000664  001750  001750  00000012675 12351652231 024120  0                                                                                                    ustar 00adrien-alea                     adrien-alea                     000000  000000                                                                                                                                                                         %% Matbiips example: Stochastic kinetic prey-predator model
% 
% Reference: R.J. Boys, D.J. Wilkinson and T.B.L. Kirkwood. Bayesian
% inference for a discretely observed stochastic kinetic model. Statistics
% and Computing (2008) 18:125-135.


%% Statistical model
% The continuous-time Lotka-Volterra Markov jump process describes the
% evolution of two species $X_{1}(t)$ (prey) and $X_{2}(t)$ (predator) at time $t$. Let $dt$ be an infinitesimal interval. The process evolves as
%  
% $$\Pr(X_1(t+dt)=x_1(t)+1,X_2(t+dt)=x_2(t)|x_1(t),x_2(t))=c_1x_1(t)dt+o(dt)$$
%
% $$\Pr(X_1(t+dt)=x_1(t)-1,X_2(t+dt)=x_2(t)+1|x_1(t),x_2(t))=c_2x_1(t)x_2(t)dt+o(dt)$$
%
% $$\Pr(X_1(t+dt)=x_1(t),X_2(t+dt)=x_2(t)-1|x_1(t),x_2(t))=c_3 x_2(t)dt+o(dt)$$
% 
% where $c_1=0.5$, $c_2=0.0025$ and $c_3=0.3$. Forward simulation can be done using the Gillespie algorithm. We additionally assume that we observe at some time $t=1,2,\ldots,t_{\max}$ the number of preys with some noise
%
% $$ Y(t)=X_1(t) + \epsilon(t), ~~\epsilon(t)\sim\mathcal N(0,\sigma^2) $$

%% Statistical model in BUGS language
%
% *Content of the file 'stoch_kinetic_gill.bug':*
%
%     var x_true[2,t_max], x[2,t_max], y[t_max],c[3]
% 
%     data
%     {
%       x_true[,1] ~ LV(x_init,c[1],c[2],c[3],1)
%       y[1] ~ dnorm(x_true[1,1], 1/sigma^2) 
%       for (t in 2:t_max)
%       {      
%         x_true[1:2, t] ~ LV(x_true[1:2,t-1],c[1],c[2],c[3],1)   
%         y[t] ~ dnorm(x_true[1,t], 1/sigma^2)  
%       }
%     }
% 
%     model
%     {
%       x[,1] ~ LV(x_init,c[1],c[2],c[3],1)
%       y[1] ~ dnorm(x_true[1,1], 1/sigma^2) 
%       for (t in 2:t_max)
%       {    
%         x[, t] ~ LV(x[,t-1],c[1],c[2],c[3],1) 
%         y[t] ~ dnorm(x[1,t], 1/sigma^2) 
%       }
%     }

%% User-defined Matlab functions
%
% *Content of the Matlab file `lotka_volterra_gillepsie.m':*
%
%     function x = lotka_volterra_gillespie(x, c1, c2, c3, dt)
% 
%     % Simulation from a Lotka-Volterra model with the Gillepsie algorithm
%     % x1 is the number of prey
%     % x2 is the number of predator
%     % R1: (x1,x2) -> (x1+1,x2)      At rate c1x1
%     % R2: (x1,x2) -> (x1-1,x2+1)    At rate c2x1x2
%     % R3: (x1,x2) -> (x1,x2-1)      At rate c3xx2
% 
%     z = [1, -1, 0;
%         0, 1, -1];
% 
%     t=0;
%     while 1   
%         rate = [c1*x(1), c2*x(1)*x(2), c3*x(2)];
%         sum_rate = sum(rate);
%         t = t - log(rand)/sum_rate; % Sample next event from an exponential distribution
%         ind = find((sum_rate*rand)<=cumsum(rate), 1); % Sample the type of event    
%         if t>dt
%             break
%         end
%         x = x + z(:, ind);
%     end

%%
% *Content of the Matlab file `lotka_volterra_dim.m':*
%
%     function out_dim = f_dim(x_dim, c1_dim, c2_dim, c3_dim, dt_dim)
% 
%     out_dim = [2,1];
%

set(0, 'DefaultAxesFontsize', 14)
set(0, 'Defaultlinelinewidth', 2)
rng('default')

%% Installation of Matbiips
% Unzip the Matbiips archive in some folder
% and add the Matbiips folder to the Matlab path
% 

matbiips_path = '../../matbiips/matlab';
addpath(matbiips_path)

%% Add new sampler to BiiPS
%


%%
% *Add the user-defined function 'LV' to simulate from the Lotka-Volterra model*
fun_bugs = 'LV'; fun_dim = 'lotka_volterra_dim';funeval = 'lotka_volterra_gillespie';fun_nb_inputs = 5;
biips_add_distribution(fun_bugs, fun_nb_inputs, fun_dim, funeval)

%% Load model and data
%

%%
% *Model parameters*
t_max = 40;
dt = 1;%0.20;
x_init = [100 ;100];
c = [.5,.0025,.3];
sigma = 10;
data = struct('t_max', t_max, 'dt', dt, 'c',c, 'x_init', x_init, 'sigma', sigma);



%%
% *Compile BUGS model and sample data*
model_filename = 'stoch_kinetic_gill.bug'; % BUGS model filename
sample_data = true; % Boolean
model = biips_model(model_filename, data, 'sample_data', sample_data); % Create biips model and sample data
data = model.data;

%%
% *Plot data*
figure('name', 'data')
plot(dt:dt:t_max, data.x_true(1,:), 'linewidth', 2)
hold on
plot(dt:dt:t_max, data.x_true(2,:), 'r', 'linewidth', 2)
hold on
plot(dt:dt:t_max, data.y, 'g*')
xlabel('Time')
ylabel('Number of individuals')
legend('Prey', 'Predator', 'Measurements')
legend('boxoff')
box off
ylim([0,450])
saveas(gca, 'kinetic_data', 'epsc2')

%% BiiPS Sequential Monte Carlo algorithm
%

%%
% *Run SMC*
n_part = 10000; % Number of particles
variables = {'x'}; % Variables to be monitored
out_smc = biips_smc_samples(model, variables, n_part, 'type', 'fs');

summary_smc = biips_summary(out_smc, 'probs', [.025, .975]);


%%
% *Smoothing ESS*
figure('name', 'SESS')
semilogy(out_smc.x.s.ess(1,:))
hold on
plot(30*ones(length(out_smc.x.s.ess(1,:)),1), 'k--')
xlabel('Time')
ylabel('SESS')
ylim([1,n_part])
saveas(gca, 'kinetic_sess', 'epsc2')


%%
% *Posterior mean and quantiles for x*
x_smc_mean = summary_smc.x.s.mean;
x_smc_quant = summary_smc.x.s.quant;
figure('name', 'PMMH: Posterior mean and quantiles')
h = fill([dt:dt:t_max, t_max:-dt:dt], [x_smc_quant{1}(1,:), fliplr(x_smc_quant{2}(1,:))],...
    [.7 .7 1]);
set(h, 'edgecolor', 'none')
hold on
plot(dt:dt:t_max,x_smc_mean(1, :), 'linewidth', 3)
h2 = fill([dt:dt:t_max, t_max:-dt:dt], [x_smc_quant{1}(2,:), fliplr(x_smc_quant{2}(2,:))],...
    [1 .7 .7]);
set(h2, 'edgecolor', 'none')
plot(dt:dt:t_max,x_smc_mean(2, :),'r', 'linewidth', 3)
set(h, 'edgecolor', 'none')
xlabel('Time')
ylabel('Estimates')
legend({'95 % interval (prey)', 'Posterior mean (prey)',...
    '95 % interval (predator)', 'Posterior mean (predator)'})
legend('boxoff')
box off
ylim([0,450])
alpha(.7)
saveas(gca, 'kinetic_smc', 'epsc2')

%% Clear model
% 

biips_clear(model)
                                                                   examples/stoch_kinetic/test_lotka.m                                                                 000664  001750  001750  00000000506 12324336155 022426  0                                                                                                    ustar 00adrien-alea                     adrien-alea                     000000  000000                                                                                                                                                                         % Test Matlab function Lotka-Volterra
close all
clear all
x(:,1)=[100;100];

delta = .5;
c1 = .5*delta;
c2 = .0025*delta;
c3 = .3*delta;
dt = 1;
n_part = 100;
T = 20;

profile on
tic
for i=1:n_part
    for t=2:T
        x(:, t) = lotka_volterra_gillespie(x(:,t-1), c1, c2, c3, dt);
    end
end
toc
profile off

figure
plot(x')                                                                                                                                                                                          examples/stoch_volatility/stoch_volatility.m                                                        000664  001750  001750  00000020156 12351652231 024426  0                                                                                                    ustar 00adrien-alea                     adrien-alea                     000000  000000                                                                                                                                                                         %% Matbiips example: Stochastic volatility
% In this example, we consider the stochastic volatility model SV0 for
% application e.g. in finance.
%
% Reference: S. Chib, F. Nardari, N. Shepard. Markov chain Monte Carlo methods
% for stochastic volatility models. Journal of econometrics, vol. 108, pp. 281-316, 2002.

%% Statistical model
%
% The stochastic volatility model is defined as follows
%
% $$ \alpha\sim \mathcal N (0, .0001),~~~$$
% $$ logit(\beta) \sim  \mathcal N (0, 10),~~~$$
% $$ log(\sigma) \sim  \mathcal N (0, 1)$$
%
% and for $t\leq t_{max}$
%
% $$x_t|(x_{t-1},\alpha,\beta,\sigma) \sim \mathcal N (\alpha + \beta(x_{t-1}
% -\alpha), \sigma^2)$$
%
% $$ y_t|x_t \sim \mathcal N (0, exp(x_t)) $$
%
% where $y_t$ is the response variable and $x_t$ is the unobserved
% log-volatility of $y_t$. $\mathcal N(m,\sigma^2)$ denotes the normal
% distribution of mean $m$ and variance $\sigma^2$.
%
% $\alpha$, $\beta$ and $\sigma$ are unknown
% parameters that need to be estimated.

%% Statistical model in BUGS language
% Content of the file `stoch_volatility.bug':

%%
%
%
%     var y[t_max,1], x[t_max,1], prec_y[t_max,1]
% 
%     data
%     {  
%       x_true[1,1] ~ dnorm(0, 1/sigma_true^2)
%       prec_y_true[1,1] <- exp(-x_true[1,1]) 
%       y[1,1] ~ dnorm(0, prec_y_true[1,1])
%       for (t in 2:t_max)
%       { 
%         x_true[t,1] ~ dnorm(alpha_true + beta_true*(x_true[t-1,1]-alpha_true), 1/sigma_true^2)
%         prec_y_true[t,1] <- exp(-x_true[t,1])  
%         y[t,1] ~ dnorm(0, prec_y_true[t,1])
%       }
%     }
% 
%     model
%     {
%       alpha ~ dnorm(0,10000)
%       logit_beta ~ dnorm(0,.1)
%       beta <- 1/(1+exp(-logit_beta))
%       log_sigma ~ dnorm(0, 1)
%       sigma <- exp(log_sigma)
% 
%       x[1,1] ~ dnorm(0, 1/sigma^2)
%       prec_y[1,1] <- exp(-x[1,1]) 
%       y[1,1] ~ dnorm(0, prec_y[1,1])
%       for (t in 2:t_max)
%       { 
%         x[t,1] ~ dnorm(alpha + beta*(x[t-1,1]-alpha), 1/sigma^2)
%         prec_y[t,1] <- exp(-x[t,1]) 
%         y[t,1] ~ dnorm(0, prec_y[t,1])
%       }
%     }


%% Installation of Matbiips
% Unzip the Matbiips archive in some folder
% and add the Matbiips folder to the Matlab path
% 

matbiips_path = '../../matbiips/matlab';
addpath(matbiips_path)

%% Load model and load or simulate data
%

sample_data = true; % Simulated data or SP500 data
t_max = 100;

if ~sample_data    
    % Load the data
    T = readtable('SP500.csv', 'delimiter', ';');
    y = diff(log(T.Close(end:-1:1)));
    SP500_date_str = T.Date(end:-1:2);

    ind = 1:t_max;
    y = y(ind);
    SP500_date_str = SP500_date_str(ind);

    SP500_date_num = datenum(SP500_date_str);
    
    % Plot the SP500 data
    figure('name', 'log-returns')
    plot(SP500_date_num, y)
    datetick('x', 'mmmyyyy', 'keepticks')
    ylabel('log-returns')
end

%%
% *Model parameters*

if ~sample_data
    data = struct('t_max', t_max, 'y', y);
else
    sigma_true = .4;
    alpha_true = 0;
    beta_true = .99;
    data = struct('t_max', t_max, 'sigma_true', sigma_true,...
        'alpha_true', alpha_true, 'beta_true', beta_true);
end


%%
% *Compile BUGS model and sample data if simulated data*
model_filename = 'stoch_volatility.bug'; % BUGS model filename
model = biips_model(model_filename, data, 'sample_data', sample_data); % Create biips model and sample data
data = model.data;


%% BiiPS Particle Marginal Metropolis-Hastings
% We now use BiiPS to run a Particle Marginal Metropolis-Hastings in order
% to obtain posterior MCMC samples of the parameters \alpha, \beta and \sigma,
% and of the variables x.

%%
% *Parameters of the PMMH*
n_burn = 5000; % nb of burn-in/adaptation iterations
n_iter = 5000; % nb of iterations after burn-in
thin = 5; % thinning of MCMC outputs
n_part = 50; % nb of particles for the SMC

param_names = {'alpha', 'logit_beta', 'log_sigma'}; % name of the variables updated with MCMC (others are updated with SMC)
latent_names = {'x'}; % name of the variables updated with SMC and that need to be monitored

%%
% *Init PMMH*
inits = {0,5,-2};
obj_pmmh = biips_pmmh_init(model, param_names, 'inits', inits,...
    'latent_names', latent_names); 

%%
% *Run PMMH*
[obj_pmmh, stats_pmmh_update] = biips_pmmh_update(obj_pmmh, n_burn, n_part); % adaptation and burn-in iterations
[obj_pmmh, out_pmmh, log_post, log_marg_like, stats_pmmh] = biips_pmmh_samples(obj_pmmh, n_iter, n_part,...
    'thin', thin); % Samples
 
%%
% *Some summary statistics*
summary_pmmh = biips_summary(out_pmmh, 'probs', [.025, .975]);

%%
% *Compute kernel density estimates*
kde_estimates_pmmh = biips_density(out_pmmh);

%%
% *Posterior mean and credibilist interval for the parameters*
for i=1:length(param_names)
    sum_param = getfield(summary_pmmh, param_names{i});
    fprintf('Posterior mean of %s: %.3f\n',param_names{i},sum_param.mean);
    fprintf('95%% credibilist interval for %s: [%.3f,%.3f]\n',...
        param_names{i}, sum_param.quant{1},  sum_param.quant{2});
end

%%
% *Trace of MCMC samples for the parameters*
if sample_data
    param_true = [alpha_true, log(data.beta_true/(1-data.beta_true)), log(sigma_true)];
end
title_names = {'\alpha', 'logit(\beta)', 'log(\sigma)'};
% figure('name', 'PMMH: Trace samples parameter')
for k=1:3
    out_pmmh_param = getfield(out_pmmh, param_names{k});
    figure
    plot(out_pmmh_param)
    if sample_data
        hold on
        plot(0, param_true(k), '*g');  
    end
    xlabel('Iterations')
    ylabel('PMMH samples')
    title(title_names{k})
end


%%
% *Histogram and kde estimate of the posterior for the parameters*
for k=1:3
    out_pmmh_param = getfield(out_pmmh, param_names{k});
    figure('name', 'PMMH: Histogram posterior parameter')
    hist(out_pmmh_param, 15)
    if sample_data
        hold on
        plot(param_true(k),0, '*g');  
    end
    xlabel(title_names{k})
    ylabel('number of samples')
    title(title_names{k})
end
  

%%
% *Posterior mean and quantiles for x*
x_pmmh_mean = summary_pmmh.x.mean;
x_pmmh_quant = summary_pmmh.x.quant;
figure('name', 'PMMH: Posterior mean and quantiles')
h = fill([1:t_max, t_max:-1:1], [x_pmmh_quant{1}; flipud(x_pmmh_quant{2})],...
    [.7 .7 1]);
set(h, 'edgecolor', 'none')
hold on
plot(x_pmmh_mean, 'linewidth', 3)
if sample_data
    plot(data.x_true, 'g', 'linewidth', 2)
    legend({'95 % credible interval', 'PMMH Mean Estimate', 'True value'})
else
    legend({'95 % credible interval', 'PMMH Mean Estimate'})
end
xlabel('Time')
ylabel('Estimates')


%%
% *Trace of MCMC samples for x*
time_index = [5, 10, 15];
figure('name', 'PMMH: Trace samples x')
for k=1:length(time_index)
    tk = time_index(k);
    subplot(2, 2, k)
    plot(out_pmmh.x(tk, :))
    if sample_data
        hold on
        plot(0, data.x_true(tk), '*g');  
    end
    xlabel('Iterations')
    ylabel('PMMH samples')
    title(['t=', num2str(tk)]);
end
if sample_data
    h = legend({'PMMH samples', 'True value'});
    set(h, 'position',[0.7 0.25, .1, .1])
end

%%
% *Histogram and kernel density estimate of posteriors of x*
figure('name', 'PMMH: Histograms Marginal Posteriors')
for k=1:length(time_index)
    tk = time_index(k);
    subplot(2, 2, k)
    hist(out_pmmh.x(tk, :), 15);
    if sample_data
        hold on    
        plot(data.x_true(tk), 0, '*g');
    end
    xlabel(['x_{' num2str(tk) '}']);
    ylabel('number of samples');
    title(['t=', num2str(tk)]);    
end
if sample_data
    h = legend({'smoothing density', 'True value'});
    set(h, 'position',[0.7 0.25, .1, .1])
end

figure('name', 'PMMH: KDE estimates Marginal posteriors')
for k=1:length(time_index)
    tk = time_index(k);
    subplot(2, 2, k)
    plot(kde_estimates_pmmh.x(tk).x, kde_estimates_pmmh.x(tk).f); 
    if sample_data
        hold on
        plot(data.x_true(tk), 0, '*g');
    end
    xlabel(['x_{' num2str(tk) '}']);
    ylabel('posterior density');
    title(['t=', num2str(tk)]);    
end
if sample_data
    h = legend({'posterior density', 'True value'});
    set(h, 'position',[0.7 0.25, .1, .1])
end


%% Clear model
% 

biips_clear()                                                                                                                                                                                                                                                                                                                                                                                                                  examples/stoch_volatility/switch_stoch_volatility_param.m                                           000664  001750  001750  00000023465 12353261303 027173  0                                                                                                    ustar 00adrien-alea                     adrien-alea                     000000  000000                                                                                                                                                                         %% Matbiips example: Switching Stochastic volatility
% In this example, we consider the Markov switching stochastic volatility model for
% application e.g. in finance.
%
% Reference: C.M. Carvalho and H.F. Lopes. Simulation-based sequential analysis of Markov switching
% stochastic volatility models. Computational Statistics and Data analysis (2007) 4526-4542.

%% Statistical model
%
% Let $y_t$ be the response variable and $x_t$ the unobserved
% log-volatility of $y_t$. The stochastic volatility model is defined as follows
% for $t\leq t_{max}$
% 
% $$x_t|(x_{t-1},\alpha,\phi,\sigma,c_t) \sim \mathcal N (\alpha_{c_t} + \phi x_{t-1} , \sigma^2)$$
%
% $$ y_t|x_t \sim \mathcal N (0, \exp(x_t)) $$
%
% The regime variables $c_t$ follow a two-state Markov process with
% transition probabilities
%
% $$p_{ij}=Pr(c_t=j|c_{t-1}=i)$$
%
% We assume the following
% priors over the parameters $\alpha $, $\phi $, $\sigma $ and $p$:
%
% $$ \alpha_1=\gamma_1$$
%
% $$\alpha_2 = \gamma_1+\gamma_2$$
%
% $$\gamma_1 \sim \mathcal N(0,100)$$
%
% $$\gamma_2 \sim \mathcal {TN}_{(0,\infty)}(0,100)$$
%
% $$\phi \sim \mathcal {TN}_{(-1,1)}(0,100) $$
%
% $$\sigma^2 \sim invGamma(2.001,1) $$
%
% $$\pi_{11} \sim Beta(0.5,0.5)$$
%
% $$\pi_{22} \sim Beta(0.5,0.5)$$
%
% $\mathcal N(m,\sigma^2)$ denotes the normal
% distribution of mean $m$ and variance $\sigma^2$. 
% $\mathcal {TN}_{(a,b)}(m,\sigma^2)$ denotes the truncated normal
% distribution of mean $m$ and variance $\sigma^2$. 


%% Statistical model in BUGS language
% Content of the file `switch_stoch_volatility_param.bug':

%%
%
%
%         var y[t_max,1], x[t_max,1], prec_y[t_max,1],mu[t_max,1],mu_true[t_max,1],alpha[2,1],gamma[2,1],c[t_max],c_true[t_max],pi[2,2]
% 
%         data
%         {  
%           c_true[1] ~ dcat(pi_true[1,])
%           mu_true[1,1] <- alpha_true[1,1] * (c_true[1]==1) + alpha_true[2,1]*(c_true[1]==2)
%           x_true[1,1] ~ dnorm(mu_true[1,1], 1/sigma_true^2)
%           prec_y_true[1,1] <- exp(-x_true[1,1]) 
%           y[1,1] ~ dnorm(0, prec_y_true[1,1])
%           for (t in 2:t_max)
%           { 
%             c_true[t] ~ dcat(ifelse(c_true[t-1]==1,pi_true[1,],pi_true[2,]))
%             mu_true[t,1] <- alpha_true[1,1]*(c_true[t]==1) + alpha_true[2,1]*(c_true[t]==2) + phi_true*x_true[t-1,1];
%             x_true[t,1] ~ dnorm(mu_true[t,1], 1/sigma_true^2)
%             prec_y_true[t,1] <- exp(-x_true[t,1])  
%             y[t,1] ~ dnorm(0, prec_y_true[t,1])
%           }
%         }
% 
%         model
%         {
%           gamma[1,1] ~ dnorm(0, 1/100)
%           gamma[2,1] ~ dnorm(0, 1/100)T(0,)
%           alpha[1,1] <- gamma[1,1]
%           alpha[2,1] <- gamma[1,1] + gamma[2,1]
%           phi ~ dnorm(0, 1/100)T(-1,1)
%           tau ~ dgamma(2.001, 1)
%           sigma <- 1/sqrt(tau)
%           pi[1,1] ~ dbeta(.5, .5)
%           pi[1,2] <- 1.00 - pi[1,1]
%           pi[2,2] ~ dbeta(.5, .5)
%           pi[2,1] <- 1.00 - pi[2,2]
% 
% 
%           c[1] ~ dcat(pi[1,])
%           mu[1,1] <- alpha[1,1] * (c[1]==1) + alpha[2,1]*(c[1]==2)
%           x[1,1] ~ dnorm(mu[1,1], 1/sigma^2)
%           prec_y[1,1] <- exp(-x[1,1]) 
%           y[1,1] ~ dnorm(0, prec_y[1,1])
%           for (t in 2:t_max)
%           { 
%             c[t] ~ dcat(ifelse(c[t-1]==1, pi[1,], pi[2,]))
%             mu[t,1] <- alpha[1,1] * (c[t]==1) + alpha[2,1]*(c[t]==2) + phi*x[t-1,1]
%             x[t,1] ~ dnorm(mu[t,1], 1/sigma^2)
%             prec_y[t,1] <- exp(-x[t,1])  
%             y[t,1] ~ dnorm(0, prec_y[t,1])
%           }
%         }


%% Installation of Matbiips
% Unzip the Matbiips archive in some folder
% and add the Matbiips folder to the Matlab path
% 

matbiips_path = '../../matbiips/matlab';
addpath(matbiips_path)

%% Load model and load or simulate data
%

sample_data = true; % Simulated data or SP500 data
t_max = 200;

if ~sample_data    
    % Load the data
    T = readtable('SP500.csv', 'delimiter', ';');
    y = diff(log(T.Close(end:-1:1)));
    SP500_date_str = T.Date(end:-1:2);

    ind = 1:t_max;
    y = y(ind);
    SP500_date_str = SP500_date_str(ind);

    SP500_date_num = datenum(SP500_date_str);
    
    % Plot the SP500 data
    figure('name', 'log-returns')
    plot(SP500_date_num, y)
    datetick('x', 'mmmyyyy', 'keepticks')
    ylabel('log-returns')
end

%%
% *Model parameters*
if ~sample_data
    data = struct('t_max', t_max, 'y', y);
else
    sigma_true = .4;
    alpha_true = [-2.5; -1];
    phi_true = .5;    
    pi11 = .9;
    pi22 = .9;
    pi_true = [
        pi11, 1-pi11;
        1-pi22, pi22];
    
    data = struct('t_max', t_max, 'sigma_true', sigma_true,...
        'alpha_true', alpha_true, 'phi_true', phi_true, 'pi_true', pi_true);
end


%%
% *Compile BUGS model and sample data if simulated data*
model_filename = 'switch_stoch_volatility_param.bug'; % BUGS model filename
model = biips_model(model_filename, data, 'sample_data', sample_data); % Create biips model and sample data
data = model.data;

%% BiiPS Particle Marginal Metropolis-Hastings
% We now use BiiPS to run a Particle Marginal Metropolis-Hastings in order
% to obtain posterior MCMC samples of the parameters \alpha, \beta and \sigma,
% and of the variables x.

%%
% *Parameters of the PMMH*
n_burn = 200;%2000; % nb of burn-in/adaptation iterations
n_iter = 200;%2000; % nb of iterations after burn-in
thin = 1; % thinning of MCMC outputs
n_part = 50; % nb of particles for the SMC

param_names = {'gamma[1,1]','gamma[2,1]', 'phi', 'tau', 'pi[1,1]', 'pi[2,2]'}; % name of the variables updated with MCMC (others are updated with SMC)
latent_names = {'x','alpha[1,1]','alpha[2,1]', 'sigma'}; % name of the variables updated with SMC and that need to be monitored

%%
% *Init PMMH*
inits = {-1, 1,.5,5,.8,.8};
obj_pmmh = biips_pmmh_init(model, param_names, 'inits', inits, 'latent_names', latent_names); % creates a pmmh object
% pause
%%
% *Run PMMH*
[obj_pmmh, stats_pmmh_update] = biips_pmmh_update(obj_pmmh, n_burn, n_part); % adaptation and burn-in iterations
[obj_pmmh, out_pmmh, log_post, log_marg_like, stats_pmmh] =...
    biips_pmmh_samples(obj_pmmh, n_iter, n_part,'thin', thin); % Samples
 
%%
% *Some summary statistics*
summary_pmmh = biips_summary(out_pmmh, 'probs', [.025, .975]);

%%
% *Compute kernel density estimates*
kde_estimates_pmmh = biips_density(out_pmmh);

param_plot = {'alpha[1,1]','alpha[2,1]', 'phi', 'sigma','pi[1,1]','pi[2,2]'};
%%
% *Posterior mean and credibilist interval for the parameters*
for i=1:length(param_plot)
    sum_param = getfield(summary_pmmh, param_plot{i});
    fprintf('Posterior mean of %s: %.3f\n',param_plot{i},sum_param.mean);
    fprintf('95%% credibilist interval for %s: [%.3f,%.3f]\n',...
        param_plot{i}, sum_param.quant{1},  sum_param.quant{2});
end

%%
% *Trace of MCMC samples for the parameters*
if sample_data
    param_true = [alpha_true', phi_true, sigma_true, pi11, pi22];
end
title_names = {'\alpha[1]','\alpha[2]', '\phi', '\sigma','\pi[1,1]','\pi[2,2]'};
% figure('name', 'PMMH: Trace samples parameter')
for k=1:length(param_plot)
    out_pmmh_param = getfield(out_pmmh, param_plot{k});
    figure
    plot(out_pmmh_param)
    if sample_data
        hold on
        plot(0, param_true(k), '*g');  
    end
    xlabel('Iterations')
    ylabel('PMMH samples')
    title(title_names{k})
end


%%
% *Histogram and kde estimate of the posterior for the parameters*
for k=1:length(param_plot)
    out_pmmh_param = getfield(out_pmmh, param_plot{k});
    figure('name', 'PMMH: Histogram posterior parameter')
    hist(out_pmmh_param, 15)
    if sample_data
        hold on
        plot(param_true(k),0, '*g');  
    end
    xlabel(title_names{k})
    ylabel('number of samples')
    title(title_names{k})
end
  

%%
% *Posterior mean and quantiles for x*
x_pmmh_mean = summary_pmmh.x.mean;
x_pmmh_quant = summary_pmmh.x.quant;
figure('name', 'PMMH: Posterior mean and quantiles')
h = fill([1:t_max, t_max:-1:1], [x_pmmh_quant{1}; flipud(x_pmmh_quant{2})],...
    [.7 .7 1]);
set(h, 'edgecolor', 'none')
hold on
plot(x_pmmh_mean, 'linewidth', 3)
if sample_data
    plot(data.x_true, 'g', 'linewidth', 2)
    legend({'95 % credible interval', 'PMMH Mean Estimate', 'True value'})
else
    legend({'95 % credible interval', 'PMMH Mean Estimate'})
end
xlabel('Time')
ylabel('Estimates')


%%
% *Trace of MCMC samples for x*
time_index = [5, 10, 15, 20];
figure('name', 'PMMH: Trace samples x')
for k=1:length(time_index)
    tk = time_index(k);
    subplot(2, 2, k)
    plot(out_pmmh.x(tk, :))
    if sample_data
        hold on
        plot(0, data.x_true(tk), '*g');  
    end
    xlabel('Iterations')
    ylabel('PMMH samples')
    title(['t=', num2str(tk)]);
end
if sample_data
    legend({'PMMH samples', 'True value'});
end

%%
% *Histogram and kernel density estimate of posteriors of x*
figure('name', 'PMMH: Histograms Marginal Posteriors')
for k=1:length(time_index)
    tk = time_index(k);
    subplot(2, 2, k)
    hist(out_pmmh.x(tk, :), 15);
    if sample_data
        hold on    
        plot(data.x_true(tk), 0, '*g');
    end
    xlabel(['x_{' num2str(tk) '}']);
    ylabel('number of samples');
    title(['t=', num2str(tk)]);    
end
if sample_data
    legend({'smoothing density', 'True value'});
end

figure('name', 'PMMH: KDE estimates Marginal posteriors')
for k=1:length(time_index)
    tk = time_index(k);
    subplot(2, 2, k)
    plot(kde_estimates_pmmh.x(tk).x, kde_estimates_pmmh.x(tk).f); 
    if sample_data
        hold on
        plot(data.x_true(tk), 0, '*g');
    end
    xlabel(['x_{' num2str(tk) '}']);
    ylabel('posterior density');
    title(['t=', num2str(tk)]);    
end
if sample_data
    legend({'posterior density', 'True value'});
end


%% Clear model
% 

biips_clear()                                                                                                                                                                                                           examples/stoch_volatility/switch_stoch_volatility.m                                                 000664  001750  001750  00000022136 12351652231 026007  0                                                                                                    ustar 00adrien-alea                     adrien-alea                     000000  000000                                                                                                                                                                         %% Matbiips example: Switching Stochastic volatility
% In this example, we consider the Markov switching stochastic volatility model.
%
% Reference: C.M. Carvalho and H.F. Lopes. Simulation-based sequential analysis of Markov switching
% stochastic volatility models. Computational Statistics and Data analysis (2007) 4526-4542.

%% Statistical model
%
% Let $y_t$ be the response variable and $x_t$ the unobserved
% log-volatility of $y_t$. The stochastic volatility model is defined as follows
% for $t\leq t_{max}$
% 
% $$x_t|(x_{t-1},\alpha,\phi,\sigma,c_t) \sim \mathcal N (\alpha_{c_t} + \phi x_{t-1} , \sigma^2)$$
%
% $$ y_t|x_t \sim \mathcal N (0, \exp(x_t)) $$
%
% The regime variables $c_t$ follow a two-state Markov process with
% transition probabilities
%
% $$p_{ij}=Pr(c_t=j|c_{t-1}=i)$$
%
% $\mathcal N(m,\sigma^2)$ denotes the normal
% distribution of mean $m$ and variance $\sigma^2$. 


%% Statistical model in BUGS language
% Content of the file `switch_stoch_volatility.bug':

%%
%
%
%     var y[t_max,1], x[t_max,1],mu[t_max,1],mu_true[t_max,1],c[t_max],c_true[t_max]
% 
%     data
%     {
%       c_true[1] ~ dcat(pi[c0,])
%       mu_true[1,1] <- alpha[1,1] * (c[1]==1) + alpha[2,1]*(c[1]==2) + phi*x0
%       x_true[1,1] ~ dnorm(mu_true[1,1], 1/sigma^2)
%       y[1,1] ~ dnorm(0, exp(-x_true[1,1]))
%       for (t in 2:t_max)
%       {
%         c_true[t] ~ dcat(ifelse(c_true[t-1]==1,pi[1,],pi[2,]))
%         mu_true[t,1] <- alpha[1,1]*(c_true[t]==1) + alpha[2,1]*(c_true[t]==2) + phi*x_true[t-1,1];
%         x_true[t,1] ~ dnorm(mu_true[t,1], 1/sigma_true^2)
%         y[t,1] ~ dnorm(0, exp(-x_true[t,1])
%       }
%     }
% 
%     model
%     {
%       c[1] ~ dcat(pi[c0,])
%       mu[1,1] <- alpha[1,1] * (c[1]==1) + alpha[2,1]*(c[1]==2)  + phi*x0
%       x[1,1] ~ dnorm(mu[1,1], 1/sigma^2)
%       y[1,1] ~ dnorm(0, exp(-x[1,1]))
%       for (t in 2:t_max)
%       {
%         c[t] ~ dcat(ifelse(c[t-1]==1, pi[1,], pi[2,]))
%         mu[t,1] <- alpha[1,1] * (c[t]==1) + alpha[2,1]*(c[t]==2) + phi*x[t-1,1]
%         x[t,1] ~ dnorm(mu[t,1], 1/sigma^2)
%         y[t,1] ~ dnorm(0, exp(-x[t,1]))
%       }
%     }

set(0, 'DefaultAxesFontsize', 14)
set(0, 'Defaultlinelinewidth', 2)
rng('default')

%% Installation of Matbiips
% Unzip the Matbiips archive in some folder
% and add the Matbiips folder to the Matlab path
% 

matbiips_path = '../../matbiips/matlab';
addpath(matbiips_path)

%% Load model and data
%

%%
% *Model parameters*
sigma = .4;alpha = [-2.5; -1]; phi = .5; c0 = 1; x0 = 0; t_max = 100;
pi = [.9, .1; .1, .9];
data = struct('t_max', t_max, 'sigma', sigma,...
        'alpha', alpha, 'phi', phi, 'pi', pi, 'c0', c0, 'x0', x0);

%%
% *Parse and compile BUGS model, and sample data*
model_filename = 'switch_stoch_volatility.bug'; % BUGS model filename
model = biips_model(model_filename, data, 'sample_data', true);
data = model.data;


%% BiiPS Sequential Monte Carlo
% 

%%
% *Run SMC*
n_part = 5000; % Number of particles
variables = {'x'}; % Variables to be monitored
out_smc = biips_smc_samples(model, variables, n_part);

%%
% *Diagnostic on the algorithm*. 
diag = biips_diagnosis(out_smc);

%%
% *Plot ESS*
figure('name', 'ESS')
semilogy(out_smc.x.s.ess)
hold on
plot(1:t_max, 30*ones(t_max,1), '--k')
xlabel('Time')
ylabel('SESS')
box off
legend('Effective sample size (smoothing)')
legend boxoff
saveas(gca, 'volatility_ess', 'png')
% pause

%% 
% *Plot weighted particles*
figure('name', 'Particles')
hold on
for t=1:t_max
    val = unique(out_smc.x.s.values(t,:,:));
    for j=1:length(val)
        ind = out_smc.x.s.values(t,:,:)==val(j);
        weight(j) = sum(out_smc.x.s.weights(t,:,ind));
        plot(t, val(j), 'ro',...
                'markersize', min(7, n_part/10* weight(j)),'markerfacecolor', 'r')

    end 
end
xlabel('Time')
ylabel('Particles (smoothing)')
saveas(gca, 'volatility_particles_s', 'png')


%%
% *Summary statistics*
summary = biips_summary(out_smc, 'probs', [.025, .975]);

%%
% *Plot Filtering estimates*
x_f_mean = summary.x.f.mean;
x_f_quant = summary.x.f.quant;
figure('name', 'SMC: Filtering estimates')
h = fill([1:t_max, t_max:-1:1], [x_f_quant{1}; flipud(x_f_quant{2})],...
    [.7 .7 1]);
set(h, 'edgecolor', 'none')
hold on
plot(x_f_mean, 'linewidth', 3)
xlabel('Time')
ylabel('Estimates')
legend({'95 % credible interval', 'Filtering Mean Estimate'})
legend('boxoff')
box off
ylim([-8,0])
saveas(gca, 'volatility_f', 'epsc2')

%%
% *Plot Smoothing estimates*
x_s_mean = summary.x.s.mean;
x_s_quant = summary.x.s.quant;
figure('name', 'SMC: Smoothing estimates')
h = fill([1:t_max, t_max:-1:1], [x_s_quant{1}; flipud(x_s_quant{2})],...
    [.7 .7 1]);
set(h, 'edgecolor', 'none')
hold on
plot(x_s_mean, 'linewidth', 3)
xlabel('Time')
ylabel('Estimates')
legend({'95 % credible interval', 'Smoothing Mean Estimate'})
legend('boxoff')
box off
ylim([-8,0])
saveas(gca, 'volatility_s', 'epsc2')

%%
% *Marginal filtering and smoothing densities*

kde_estimates = biips_density(out_smc);
time_index = [5, 10, 15];
figure('name', 'SMC: Marginal posteriors')
for k=1:length(time_index)
    tk = time_index(k);
    subplot(2, 2, k)
    plot(kde_estimates.x.f(tk).x, kde_estimates.x.f(tk).f, '--');
    hold on
    plot(kde_estimates.x.s(tk).x, kde_estimates.x.s(tk).f, 'r');
    plot(data.x_true(tk), 0, '*g');
    xlabel(['x_{' num2str(tk) '}']);
    ylabel('posterior density');
    title(['t=', num2str(tk)]);    
end
h =legend({'filtering density', 'smoothing density', 'True value'});
set(h, 'position',[0.7 0.25, .1, .1])
legend('boxoff')
saveas(gca, 'volatility_kde', 'epsc2')



%% BiiPS Particle Independent Metropolis-Hastings
% 

%%
% *Parameters of the PIMH*
n_burn = 10000;
n_iter = 10000;
thin = 1;
n_part = 50;

%%
% *Run PIMH*
obj_pimh = biips_pimh_init(model, variables);
obj_pimh = biips_pimh_update(obj_pimh, n_burn, n_part); % burn-in iterations
[obj_pimh, out_pimh, log_marg_like_pimh] = biips_pimh_samples(obj_pimh,...
    n_iter, n_part, 'thin', thin);

%%
% *Some summary statistics*
summary_pimh = biips_summary(out_pimh, 'probs', [.025, .975]);

%%
% *Posterior mean and quantiles*
x_pimh_mean = summary_pimh.x.mean;
x_pimh_quant = summary_pimh.x.quant;
figure('name', 'PIMH: Posterior mean and quantiles')
h = fill([1:t_max, t_max:-1:1], [x_pimh_quant{1}; flipud(x_pimh_quant{2})],...
    [.7 .7 1]);
set(h, 'edgecolor', 'none')
hold on
plot(x_pimh_mean, 'linewidth', 3)
xlabel('Time')
ylabel('Estimates')
legend({'95 % credible interval', 'PIMH Mean Estimate'})
legend('boxoff')
box off
saveas(gca, 'volatility_pimh_s', 'epsc2')

%%
% *Trace of MCMC samples*
time_index = [5, 10, 15];
figure('name', 'PIMH: Trace samples')
for k=1:length(time_index)
    tk = time_index(k);
    subplot(2, 2, k)
    plot(out_pimh.x(tk, :))
    hold on
    plot(0, data.x_true(tk), '*g');  
    xlabel('Iterations')
    ylabel('PIMH samples')
    title(['t=', num2str(tk)]);
end
h = legend({'PIMH samples', 'True value'});
set(h, 'position',[0.7 0.25, .1, .1])
legend('boxoff')

%%
% *Histograms of posteriors*
figure('name', 'PIMH: Histograms Marginal Posteriors')
for k=1:length(time_index)
    tk = time_index(k);
    subplot(2, 2, k)
    hist(out_pimh.x(tk, :), 20);
    hold on    
    plot(data.x_true(tk), 0, '*g');
    xlabel(['x_{' num2str(tk) '}']);
    ylabel('number of samples');
    title(['t=', num2str(tk)]);    
end
h =legend({'PIMH samples', 'True value'});
set(h, 'position',[0.7 0.25, .1, .1])
legend('boxoff')

%%
% *Kernel density estimates of posteriors*
kde_estimates_pimh = biips_density(out_pimh);
figure('name', 'PIMH: KDE estimates Marginal posteriors')
for k=1:length(time_index)
    tk = time_index(k);
    subplot(2, 2, k)
    plot(kde_estimates_pimh.x(tk).x, kde_estimates_pimh.x(tk).f); 
    hold on
    plot(data.x_true(tk), 0, '*g');
    xlabel(['x_{' num2str(tk) '}']);
    ylabel('posterior density');
    title(['t=', num2str(tk)]);    
end
h = legend({'posterior density', 'True value'});
set(h, 'position',[0.7 0.25, .1, .1])
legend('boxoff')
saveas(gca, 'volatility_pimh_kde', 'epsc2')


%% BiiPS Sensitivity analysis
%

%%
% *Parameters of the algorithm*. 
n_part = 50; % Number of particles
param_names = {'alpha[1:2,1]'}; % Parameter for which we want to study sensitivity
[A, B] = meshgrid(-5:.2:2, -5:.2:2);
param_values = {[A(:), B(:)]'}; % Range of values

%%
% *Run sensitivity analysis with SMC*
out_sensitivity = biips_smc_sensitivity(model, param_names, param_values, n_part); 

%%
% *Plot log-marginal likelihood and penalized log-marginal likelihood*
figure('name', 'Sensitivity: log-likelihood')
surf(A, B, reshape(out_sensitivity.log_marg_like, size(A)))
shading interp
caxis([0,max(out_sensitivity.log_marg_like(:))])
colormap(hot)
view(2)
xlim([min(A(:)), max(A(:))])
colorbar
xlabel('$\alpha_1$', 'interpreter', 'latex', 'fontsize', 20)
ylabel('$\alpha_2$', 'interpreter', 'latex', 'fontsize', 20)
saveas(gca, 'volatility_sensitivity', 'epsc2')
saveas(gca, 'volatility_sensitivity', 'png')


%% Clear model
% 

biips_clear()                                                                                                                                                                                                                                                                                                                                                                                                                                  examples/tvdp/tvdp.bug                                                                              000664  001750  001750  00000001526 12324336155 017705  0                                                                                                    ustar 00adrien-alea                     adrien-alea                     000000  000000                                                                                                                                                                         var c[t_max, clust_max],mu[t_max, clust_max],mu_y[t_max], m[t_max, clust_max],m_up[t_max, clust_max], p[t_max,clust_max],y[t_max,1]


model
{
  m[1,1] <- 1
  c[1,1] <- 1
  for (i in 2:clust_max)
  {
    m[1,i] <- 0
    c[1,i] <- 0
  }
  for (i in 1:clust_max)
  {
      mu[1,i] ~ dnorm(mu_0, prec_0)  
  }
  y[1,1] ~ dnorm(mu[1,1], prec_y)
  for (t in 2:t_max)
  {
    for (i in 1:clust_max)
    {
        m_up[t-1,i] ~ dbinom(rho, m[t-1,i])
    }
    p[t,] <- (m_up[t-1,] + alpha/clust_max)/(sum(m_up[t-1,])+alpha)    
    c[t,] ~ dmulti(p[t,], 1)
    m[t,] <- m_up[t-1,] + c[t,]
    
    # Cluster evolution
    for (i in 1:clust_max)
    {
        mu[t,i] ~ dnorm(gamma * mu[t-1,i] + (1-gamma)*mu_0, 1/(1-gamma^2)*prec_0)
    }
    
    mu_y[t] <- sum(c[t,]*mu[t,])
    
    y[t,1] ~ dnorm(mu_y[t], prec_y)
  }
}
                                                                                                                                                                          examples/object_tracking/hmm_4d_nonlin_tracking.bug                                                 000664  001750  001750  00000002415 12324336155 025510  0                                                                                                    ustar 00adrien-alea                     adrien-alea                     000000  000000                                                                                                                                                                         var v_true[2,t_max-1], x_true[4,t_max], x_radar_true[2,t_max],
v[2,t_max-1], x[4,t_max], x_radar[2,t_max], y[2,t_max]

data
{
  x_true[,1] ~ dmnorm(mean_x_init, prec_x_init)
  x_radar_true[,1] <- x_true[1:2,1] - x_pos 
  mu_y_true[1,1] <- sqrt(x_radar_true[1,1]^2+x_radar_true[2,1]^2)
  mu_y_true[2,1] <- arctan(x_radar_true[2,1]/x_radar_true[1,1])
  y[,1] ~ dmnorm(mu_y_true[,1], prec_y)

  for (t in 2:t_max)
  {
    v_true[,t-1] ~ dmnorm(mean_v, prec_v)
    x_true[,t] <- F %*% x_true[,t-1] + G %*% v_true[,t-1]
    x_radar_true[,t] <- x_true[1:2,t] - x_pos
    mu_y_true[1,t] <- sqrt(x_radar_true[1,t]^2+x_radar_true[2,t]^2)
    mu_y_true[2,t] <- arctan(x_radar_true[2,t]/x_radar_true[1,t])
    y[,t] ~ dmnorm(mu_y_true[,t], prec_y)
  }
}

model
{
  x[,1] ~ dmnorm(mean_x_init, prec_x_init)
  x_radar[,1] <- x[1:2,1] - x_pos
  mu_y[1,1] <- sqrt(x_radar[1,1]^2+x_radar[2,1]^2)
  mu_y[2,1] <- arctan(x_radar[2,1]/x_radar[1,1])
  y[,1] ~ dmnorm(mu_y[,1], prec_y)

  for (t in 2:t_max)
  {
    v[,t-1] ~ dmnorm(mean_v, prec_v)
    x[,t] <- F %*% x[,t-1] + G %*% v[,t-1]
    x_radar[,t] <- x[1:2,t] - x_pos
    mu_y[1,t] <- sqrt(x_radar[1,t]^2+x_radar[2,t]^2)
    mu_y[2,t] <- arctan(x_radar[2,t]/x_radar[1,t])
    y[,t] ~ dmnorm(mu_y[,t], prec_y)
  }
}
                                                                                                                                                                                                                                                   examples/tutorial/hmm_1d_nonlin_param.bug                                                           000664  001750  001750  00000001232 12364236156 023516  0                                                                                                    ustar 00adrien-alea                     adrien-alea                     000000  000000                                                                                                                                                                         var x_true[t_max], x[t_max], y[t_max]

data
{
  #log_prec_y_true ~ dunif(-3, 3)
  prec_y_true <- exp(log_prec_y_true)
  x_true[1] ~ dnorm(mean_x_init, prec_x_init)
  y[1] ~ dnorm(x_true[1]^2/20, prec_y_true)
  for (t in 2:t_max)
  {
    x_true[t] ~ dnorm(0.5*x_true[t-1]+25*x_true[t-1]/(1+x_true[t-1]^2)+8*cos(1.2*(t-1)), prec_x)
    y[t] ~ dnorm(x_true[t]^2/20, prec_y_true)
  }
}

model
{
  log_prec_y ~ dunif(-3, 3)
  prec_y <- exp(log_prec_y)
  x[1] ~ dnorm(mean_x_init, prec_x_init)
  y[1] ~ dnorm(x[1]^2/20, prec_y)
  for (t in 2:t_max)
  {
    x[t] ~ dnorm(0.5*x[t-1]+25*x[t-1]/(1+x[t-1]^2)+8*cos(1.2*(t-1)), prec_x)
    y[t] ~ dnorm(x[t]^2/20, prec_y)
  }
}
                                                                                                                                                                                                                                                                                                                                                                      examples/tutorial/hmm_1d_nonlin_funmat.bug                                                          000664  001750  001750  00000000737 12324336155 023715  0                                                                                                    ustar 00adrien-alea                     adrien-alea                     000000  000000                                                                                                                                                                         var x_true[t_max], x[t_max], y[t_max]

data
{
  x_true[1] ~ dnorm(mean_x_init, prec_x_init)
  y[1] ~ dnorm(x_true[1]^2/20, prec_y)
  for (t in 2:t_max)
  {
    x_true[t] ~ dnorm(funmat(x_true[t-1],t-1), prec_x)
    y[t] ~ dnorm(x_true[t]^2/20, prec_y)
  }
}


model
{
  x[1] ~ dnorm(mean_x_init, prec_x_init)
  y[1] ~ dnorm(x[1]^2/20, prec_y)
  for (t in 2:t_max)
  {
    x[t] ~ dnorm(funmat(x[t-1],t-1), prec_x)
    y[t] ~ dnorm(x[t]^2/20, prec_y)
  }
}
                                 examples/tutorial/hmm_1d_nonlin.bug                                                                 000664  001750  001750  00000001021 12364235672 022334  0                                                                                                    ustar 00adrien-alea                     adrien-alea                     000000  000000                                                                                                                                                                         var x_true[t_max], x[t_max], y[t_max]

data
{
  x_true[1] ~ dnorm(mean_x_init, prec_x_init)
  y[1] ~ dnorm(x_true[1]^2/20, prec_y)
  for (t in 2:t_max)
  {
    x_true[t] ~ dnorm(0.5*x_true[t-1]+25*x_true[t-1]/(1+x_true[t-1]^2)+8*cos(1.2*(t-1)), prec_x)
    y[t] ~ dnorm(x_true[t]^2/20, prec_y)
  }
}


model
{
  x[1] ~ dnorm(mean_x_init, prec_x_init)
  y[1] ~ dnorm(x[1]^2/20, prec_y)
  for (t in 2:t_max)
  {
    x[t] ~ dnorm(0.5*x[t-1]+25*x[t-1]/(1+x[t-1]^2)+8*cos(1.2*(t-1)), prec_x)
    y[t] ~ dnorm(x[t]^2/20, prec_y)
  }
}
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               examples/stoch_kinetic/stoch_kinetic.bug                                                            000664  001750  001750  00000002441 12324336155 023424  0                                                                                                    ustar 00adrien-alea                     adrien-alea                     000000  000000                                                                                                                                                                         # Stochastic kinetic prey - predator model
# cf Boys, Wilkinson and Kirkwood
# Bayesian inference for a discretely observed stochastic kinetic model


var x_true[2,t_max], c_true[t_max], vect_true[4,t_max],
    x[2,t_max], c[t_max], vect[4,t_max], y[t_max]

data
{
  x_true[,1] <- x_init+0.0
  for (t in 2:t_max)
  { 
    vect_true[1, t] <- alpha_true*x_true[1, t-1]*dt
    vect_true[2, t] <- beta*x_true[1,t-1]*dt
    vect_true[3, t] <- gamma*x_true[2, t-1]*dt
    vect_true[4, t] <- 1.0-  alpha_true*x_true[1, t-1]*dt- beta*x_true[1,t-1]*dt-gamma*x_true[2, t-1]*dt
    c_true[t] ~ dcat(vect_true[,t])
    x_true[1, t] <- x_true[1, t-1] + (c_true[t]==1) - (c_true[t]==2)
    x_true[2, t] <- x_true[2, t-1] + (c_true[t]==2) - (c_true[t]==3)    
  }
  for (t in 1:t_max)	
  {
    y[t] ~ dnorm(x_true[1,t], prec_y) 
  }
}
model
{
  logalpha ~ dunif(-7,2)
  alpha <- exp(logalpha)
  x[,1] <- x_init+0.0
  for (t in 2:t_max)
  { 
    vect[1, t] <- alpha*x[1, t-1]*dt
    vect[2, t] <- beta*x[1,t-1]*dt
    vect[3, t] <- gamma*x[2, t-1]*dt
    vect[4, t] <- 1.0-  alpha*x[1, t-1]*dt- beta*x[1,t-1]*dt-gamma*x[2, t-1]*dt
    c[t] ~ dcat(vect[,t])
    x[1, t] <- x[1, t-1] + (c[t]==1) - (c[t]==2)
    x[2, t] <- x[2, t-1] + (c[t]==2) - (c[t]==3)    
  }
  for (t in 1:t_max)	
  {
    y[t] ~ dnorm(x[1,t], prec_y) 
  }
}
                                                                                                                                                                                                                               examples/stoch_kinetic/stoch_kinetic_cle.bug                                                        000664  001750  001750  00000004060 12354234607 024250  0                                                                                                    ustar 00adrien-alea                     adrien-alea                     000000  000000                                                                                                                                                                         # Stochastic kinetic prey - predator model
# with chemical Langevin equations
#
# Reference: A. Golightly and D. J. Wilkinson. Bayesian parameter inference 
# for stochastic biochemical network models using particle Markov chain
# Monte Carlo. Interface Focus, vol.1, pp. 807-820, 2011.

var x_true[2,t_max/dt],x_true_temp[2,t_max/dt],x_temp[2,t_max/dt], x[2,t_max/dt], y[t_max/dt], beta[2,2,t_max/dt], beta_true[2,2,t_max/dt], logc[3],c[3],c_true[3]

data
{	
  x_true[,1] ~ dmnormvar(x_init_mean,  x_init_var)
  for (t in 2:t_max/dt)
  { 
    alpha_true[1,t] <- c_true[1] * x_true[1,t-1] - c_true[2]*x_true[1,t-1]*x_true[2,t-1]
    alpha_true[2,t] <- c_true[2]*x_true[1,t-1]*x_true[2,t-1] - c_true[3]*x_true[2,t-1]
    beta_true[1,1,t] <- c_true[1]*x_true[1,t-1] + c_true[2]*x_true[1,t-1]*x_true[2,t-1]
    beta_true[1,2,t] <- -c_true[2]*x_true[1,t-1]*x_true[2,t-1]
    beta_true[2,1,t] <- beta_true[1,2,t]
    beta_true[2,2,t] <- c_true[2]*x_true[1,t-1]*x_true[2,t-1] + c_true[3]*x_true[2,t-1]
    x_true_temp[,t] ~ dmnormvar(x_true[,t-1]+alpha_true[,t]*dt, (beta_true[,,t])*dt) 
    # To avoid extinction
    x_true[1,t] <- max(x_true_temp[1,t],1) 
    x_true[2,t] <- max(x_true_temp[2,t],1) 
  }
  for (t in 1:t_max)	
  {
    y[t/dt] ~ dnorm(x_true[1,t/dt], prec_y) 
  }
}

model
{
  logc[1] ~ dunif(-7,2)
  logc[2] ~ dunif(-7,2)
  logc[3] ~ dunif(-7,2)
  c[1] <- exp(logc[1])
  c[2] <- exp(logc[2])
  c[3] <- exp(logc[3])
  x[,1] ~ dmnormvar(x_init_mean,  x_init_var)
  for (t in 2:t_max/dt)
  { 
    alpha[1,t] <- c[1]*x[1,t-1] - c[2]*x[1,t-1]*x[2,t-1]
    alpha[2,t] <- c[2]*x[1,t-1]*x[2,t-1] - c[3]*x[2,t-1]
    beta[1,1,t] <- c[1]*x[1,t-1] + c[2]*x[1,t-1]*x[2,t-1]
    beta[1,2,t] <- -c[2]*x[1,t-1]*x[2,t-1]
    beta[2,1,t] <- beta[1,2,t]
    beta[2,2,t] <- c[2]*x[1,t-1]*x[2,t-1] + c[3]*x[2,t-1]
    x_temp[,t] ~ dmnormvar(x[,t-1]+alpha[,t]*dt, beta[,,t]*dt)  
    # To avoid extinction 
    x[1,t] <- max(x_temp[1,t],1)
    x[2,t] <- max(x_temp[2,t],1)
  }
  for (t in 1:t_max)	
  {
    y[t/dt] ~ dnorm(x[1,t/dt], prec_y) 
  }
}                                                                                                                                                                                                                                                                                                                                                                                                                                                                                examples/stoch_kinetic/stoch_kinetic_gill.bug                                                       000664  001750  001750  00000001167 12324336155 024437  0                                                                                                    ustar 00adrien-alea                     adrien-alea                     000000  000000                                                                                                                                                                         # Stochastic kinetic prey - predator model
# cf Boys, Wilkinson and Kirkwood
# Bayesian inference for a discretely observed stochastic kinetic model

var x_true[2,t_max], x[2,t_max], y[t_max],c[3]

data
{
  x_true[,1] ~ LV(x_init,c[1],c[2],c[3],1)
  y[1] ~ dnorm(x_true[1,1], 1/sigma^2) 
  for (t in 2:t_max)
  {      
    x_true[1:2, t] ~ LV(x_true[1:2,t-1],c[1],c[2],c[3],1)   
    y[t] ~ dnorm(x_true[1,t], 1/sigma^2)  
  }
}

model
{
  x[,1] ~ LV(x_init,c[1],c[2],c[3],1)
  y[1] ~ dnorm(x_true[1,1], 1/sigma^2) 
  for (t in 2:t_max)
  {    
    x[, t] ~ LV(x[,t-1],c[1],c[2],c[3],1) 
    y[t] ~ dnorm(x[1,t], 1/sigma^2) 
  }
}
                                                                                                                                                                                                                                                                                                                                                                                                         examples/stoch_volatility/switch_stoch_volatility_param.bug                                         000664  001750  001750  00000003411 12324336155 027507  0                                                                                                    ustar 00adrien-alea                     adrien-alea                     000000  000000                                                                                                                                                                         # Switching Stochastic Volatility Model
# Reference: C.M. Carvalho and H.F. Lopes. Simulation-based sequential analysis of Markov switching
# stochastic volatility models. Computational Statistics and Data analysis (2007) 4526-4542.

var y[t_max,1], x[t_max,1], prec_y[t_max,1],mu[t_max,1],mu_true[t_max,1],alpha[2,1],gamma[2,1],c[t_max],c_true[t_max],pi[2,2]

data
{  
  c_true[1] ~ dcat(pi_true[1,])
  mu_true[1,1] <- alpha_true[1,1] * (c_true[1]==1) + alpha_true[2,1]*(c_true[1]==2)
  x_true[1,1] ~ dnorm(mu_true[1,1], 1/sigma_true^2)
  prec_y_true[1,1] <- exp(-x_true[1,1]) 
  y[1,1] ~ dnorm(0, prec_y_true[1,1])
  for (t in 2:t_max)
  { 
    c_true[t] ~ dcat(ifelse(c_true[t-1]==1,pi_true[1,],pi_true[2,]))
    mu_true[t,1] <- alpha_true[1,1]*(c_true[t]==1) + alpha_true[2,1]*(c_true[t]==2) + phi_true*x_true[t-1,1];
    x_true[t,1] ~ dnorm(mu_true[t,1], 1/sigma_true^2)
    prec_y_true[t,1] <- exp(-x_true[t,1])  
    y[t,1] ~ dnorm(0, prec_y_true[t,1])
  }
}

model
{
  gamma[1,1] ~ dnorm(0, 1/100)
  gamma[2,1] ~ dnorm(0, 1/100)T(0,)
  alpha[1,1] <- gamma[1,1]
  alpha[2,1] <- gamma[1,1] + gamma[2,1]
  phi ~ dnorm(0, 1/100)T(-1,1)
  tau ~ dgamma(2.001, 1)
  sigma <- 1/sqrt(tau)
  pi[1,1] ~ dbeta(.5, .5)
  pi[1,2] <- 1.00 - pi[1,1]
  pi[2,2] ~ dbeta(.5, .5)
  pi[2,1] <- 1.00 - pi[2,2]
  
  
  c[1] ~ dcat(pi[1,])
  mu[1,1] <- alpha[1,1] * (c[1]==1) + alpha[2,1]*(c[1]==2)
  x[1,1] ~ dnorm(mu[1,1], 1/sigma^2)
  prec_y[1,1] <- exp(-x[1,1]) 
  y[1,1] ~ dnorm(0, prec_y[1,1])
  for (t in 2:t_max)
  { 
    c[t] ~ dcat(ifelse(c[t-1]==1, pi[1,], pi[2,]))
    mu[t,1] <- alpha[1,1] * (c[t]==1) + alpha[2,1]*(c[t]==2) + phi*x[t-1,1]
    x[t,1] ~ dnorm(mu[t,1], 1/sigma^2)
    prec_y[t,1] <- exp(-x[t,1])  
    y[t,1] ~ dnorm(0, prec_y[t,1])
  }
}                                                                                                                                                                                                                                                       examples/stoch_volatility/stoch_volatility.bug                                                      000664  001750  001750  00000002004 12324336155 024743  0                                                                                                    ustar 00adrien-alea                     adrien-alea                     000000  000000                                                                                                                                                                         # Stochastic volatility model SV_0
# Reference: S. Chib, F. Nardari, N. Shepard. Markov chain Monte Carlo methods
# for stochastic volatility models. Journal of econometrics, vol. 108, pp. 281-316, 2002.

var y[t_max,1], x[t_max,1], prec_y[t_max,1]

data
{  
  x_true[1,1] ~ dnorm(0, 1/sigma_true^2)
  prec_y_true[1,1] <- exp(-x_true[1,1]) 
  y[1,1] ~ dnorm(0, prec_y_true[1,1])
  for (t in 2:t_max)
  { 
    x_true[t,1] ~ dnorm(alpha_true + beta_true*(x_true[t-1,1]-alpha_true), 1/sigma_true^2)
    prec_y_true[t,1] <- exp(-x_true[t,1])  
    y[t,1] ~ dnorm(0, prec_y_true[t,1])
  }
}

model
{
  alpha ~ dnorm(0,10000)
  logit_beta ~ dnorm(0,.1)
  beta <- 1/(1+exp(-logit_beta))
  log_sigma ~ dnorm(0, 1)
  sigma <- exp(log_sigma)
  
  x[1,1] ~ dnorm(0, 1/sigma^2)
  prec_y[1,1] <- exp(-x[1,1]) 
  y[1,1] ~ dnorm(0, prec_y[1,1])
  for (t in 2:t_max)
  { 
    x[t,1] ~ dnorm(alpha + beta*(x[t-1,1]-alpha), 1/sigma^2)
    prec_y[t,1] <- exp(-x[t,1]) 
    y[t,1] ~ dnorm(0, prec_y[t,1])
  }
}
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            examples/stoch_volatility/switch_stoch_volatility.bug                                               000664  001750  001750  00000001741 12324336155 026333  0                                                                                                    ustar 00adrien-alea                     adrien-alea                     000000  000000                                                                                                                                                                         var y[t_max,1], x[t_max,1],mu[t_max,1],mu_true[t_max,1],c[t_max],c_true[t_max]

data
{
  c_true[1] ~ dcat(pi[c0,])
  mu_true[1,1] <- alpha[1,1] * (c_true[1]==1) + alpha[2,1]*(c_true[1]==2) + phi*x0
  x_true[1,1] ~ dnorm(mu_true[1,1], 1/sigma^2)
  y[1,1] ~ dnorm(0, exp(-x_true[1,1]))
  for (t in 2:t_max)
  {
    c_true[t] ~ dcat(ifelse(c_true[t-1]==1,pi[1,],pi[2,]))
    mu_true[t,1] <- alpha[1,1]*(c_true[t]==1) + alpha[2,1]*(c_true[t]==2) + phi*x_true[t-1,1];
    x_true[t,1] ~ dnorm(mu_true[t,1], 1/sigma^2)
    y[t,1] ~ dnorm(0, exp(-x_true[t,1]))
  }
}

model
{
  c[1] ~ dcat(pi[c0,])
  mu[1,1] <- alpha[1,1] * (c[1]==1) + alpha[2,1]*(c[1]==2)  + phi*x0
  x[1,1] ~ dnorm(mu[1,1], 1/sigma^2)
  y[1,1] ~ dnorm(0, exp(-x[1,1]))
  for (t in 2:t_max)
  {
    c[t] ~ dcat(ifelse(c[t-1]==1, pi[1,], pi[2,]))
    mu[t,1] <- alpha[1,1] * (c[t]==1) + alpha[2,1]*(c[t]==2) + phi*x[t-1,1]
    x[t,1] ~ dnorm(mu[t,1], 1/sigma^2)
    y[t,1] ~ dnorm(0, exp(-x[t,1]))
  }
}                               examples/README.md                                                                                  000664  001750  001750  00000001211 12324336155 016522  0                                                                                                    ustar 00adrien-alea                     adrien-alea                     000000  000000                                                                                                                                                                         Contents
==================
* `hmm_1d_lin`:              Linear gaussian univariate Hidden Markov Model (HMM)
* `hmm_1d_lin_param`:        Fixed parameter estimation of linear gaussian univariate HMM
* `hmm_1d_nonlin`:           Nonlinear gaussian univariate HMM
* `hmm_1d_nonlin_param`:     Fixed parameter estimation of nonlinear gaussian univariate HMM
* `dyn_beta_reg`:            Dynamic Beta regression
* `stoch_volatility`:        Stochastic volatility
* `stoch_volatility_anim`:   Animation of the particle filter applied to a model stochastic volatility
* `hmm_4d_lin_tracking`:     GPS tracking
* `hmm_4d_nonlin_tracking`:  Radar tracking
                                                                                                                                                                                                                                                                                                                                                                                       examples/stoch_volatility/SP500.csv                                                                 000664  001750  001750  00003240472 12324336155 022150  0                                                                                                    ustar 00adrien-alea                     adrien-alea                     000000  000000                                                                                                                                                                         Date;Open;High;Low;Close;Volume;AdjClose
2012-05-24;1318.72;1324.14;1310.50;1320.68;3937670000;1320.68
2012-05-23;1316.02;1320.71;1296.53;1318.86;4108330000;1318.86
2012-05-22;1316.09;1328.49;1310.04;1316.63;4123680000;1316.63
2012-05-21;1295.73;1316.39;1295.73;1315.99;3786750000;1315.99
2012-05-18;1305.05;1312.24;1291.98;1295.22;4512470000;1295.22
2012-05-17;1324.82;1326.36;1304.86;1304.86;4664280000;1304.86
2012-05-16;1330.78;1341.78;1324.79;1324.80;4280420000;1324.80
2012-05-15;1338.36;1344.94;1328.41;1330.66;4114040000;1330.66
2012-05-14;1351.93;1351.93;1336.61;1338.35;3688120000;1338.35
2012-05-11;1358.11;1365.66;1348.89;1353.39;3869070000;1353.39
2012-05-10;1354.58;1365.88;1354.58;1357.99;3727990000;1357.99
2012-05-09;1363.20;1363.73;1343.13;1354.58;4288540000;1354.58
2012-05-08;1369.16;1369.16;1347.75;1363.72;4261670000;1363.72
2012-05-07;1368.79;1373.91;1363.94;1369.58;3559390000;1369.58
2012-05-04;1391.51;1391.51;1367.96;1369.10;3975140000;1369.10
2012-05-03;1402.32;1403.07;1388.71;1391.57;4004910000;1391.57
2012-05-02;1405.50;1405.50;1393.92;1402.31;3803860000;1402.31
2012-05-01;1397.86;1415.32;1395.73;1405.82;3807950000;1405.82
2012-04-30;1403.26;1403.26;1394.00;1397.91;3574010000;1397.91
2012-04-27;1400.19;1406.64;1397.31;1403.36;3645830000;1403.36
2012-04-26;1390.64;1402.09;1387.28;1399.98;4034700000;1399.98
2012-04-25;1372.11;1391.37;1372.11;1390.69;3998430000;1390.69
2012-04-24;1366.97;1375.57;1366.82;1371.97;3617100000;1371.97
2012-04-23;1378.53;1378.53;1358.79;1366.94;3654860000;1366.94
2012-04-20;1376.96;1387.40;1376.96;1378.53;3833320000;1378.53
2012-04-19;1385.08;1390.46;1370.30;1376.92;4180020000;1376.92
2012-04-18;1390.78;1390.78;1383.29;1385.14;3463140000;1385.14
2012-04-17;1369.57;1392.76;1369.57;1390.78;3456200000;1390.78
2012-04-16;1370.27;1379.66;1365.38;1369.57;3574780000;1369.57
2012-04-13;1387.61;1387.61;1369.85;1370.26;3631160000;1370.26
2012-04-12;1368.77;1388.13;1368.77;1387.57;3618280000;1387.57
2012-04-11;1358.98;1374.71;1358.98;1368.71;3743040000;1368.71
2012-04-10;1382.18;1383.01;1357.38;1358.59;4631730000;1358.59
2012-04-09;1397.45;1397.45;1378.24;1382.20;3468980000;1382.20
2012-04-05;1398.79;1401.60;1392.92;1398.08;3303740000;1398.08
2012-04-04;1413.09;1413.09;1394.09;1398.96;3938290000;1398.96
2012-04-03;1418.98;1419.00;1404.62;1413.38;3822090000;1413.38
2012-04-02;1408.47;1422.38;1404.46;1419.04;3572010000;1419.04
2012-03-30;1403.31;1410.89;1401.42;1408.47;3676890000;1408.47
2012-03-29;1405.39;1405.39;1391.56;1403.28;3832000000;1403.28
2012-03-28;1412.52;1413.65;1397.20;1405.54;3892800000;1405.54
2012-03-27;1416.55;1419.15;1411.95;1412.52;3513640000;1412.52
2012-03-26;1397.11;1416.58;1397.11;1416.51;3576950000;1416.51
2012-03-23;1392.78;1399.18;1386.87;1397.11;3472950000;1397.11
2012-03-22;1402.89;1402.89;1388.73;1392.78;3740590000;1392.78
2012-03-21;1405.52;1407.75;1400.64;1402.89;3573590000;1402.89
2012-03-20;1409.59;1409.59;1397.68;1405.52;3695280000;1405.52
2012-03-19;1404.17;1414.00;1402.43;1409.75;3932570000;1409.75
2012-03-16;1402.55;1405.88;1401.47;1404.17;5163950000;1404.17
2012-03-15;1394.17;1402.63;1392.78;1402.60;4271650000;1402.60
2012-03-14;1395.95;1399.42;1389.97;1394.28;4502280000;1394.28
2012-03-13;1371.92;1396.13;1371.92;1395.95;4386470000;1395.95
2012-03-12;1370.78;1373.04;1366.69;1371.09;3081870000;1371.09
2012-03-09;1365.97;1374.76;1365.97;1370.87;3639470000;1370.87
2012-03-08;1352.65;1368.72;1352.65;1365.91;3543060000;1365.91
2012-03-07;1343.39;1354.85;1343.39;1352.63;3580380000;1352.63
2012-03-06;1363.63;1363.63;1340.03;1343.36;4191060000;1343.36
2012-03-05;1369.59;1369.59;1359.13;1364.33;3429480000;1364.33
2012-03-02;1374.09;1374.53;1366.42;1369.63;3283490000;1369.63
2012-03-01;1365.90;1376.17;1365.90;1374.09;3919240000;1374.09
2012-02-29;1372.20;1378.04;1363.81;1365.68;4482370000;1365.68
2012-02-28;1367.56;1373.09;1365.97;1372.18;3579120000;1372.18
2012-02-27;1365.20;1371.94;1354.92;1367.59;3648890000;1367.59
2012-02-24;1363.46;1368.92;1363.46;1365.74;3505360000;1365.74
2012-02-23;1357.53;1364.24;1352.28;1363.46;3786450000;1363.46
2012-02-22;1362.11;1362.70;1355.53;1357.66;3633710000;1357.66
2012-02-21;1361.22;1367.76;1358.11;1362.21;3795200000;1362.21
2012-02-17;1358.06;1363.40;1357.24;1361.23;3717640000;1361.23
2012-02-16;1342.61;1359.02;1341.22;1358.04;4108880000;1358.04
2012-02-15;1350.52;1355.87;1340.80;1343.23;4080340000;1343.23
2012-02-14;1351.30;1351.30;1340.83;1350.50;3889520000;1350.50
2012-02-13;1343.06;1353.35;1343.06;1351.77;3618040000;1351.77
2012-02-10;1351.21;1351.21;1337.35;1342.64;3877580000;1342.64
2012-02-09;1349.97;1354.32;1344.63;1351.95;4209890000;1351.95
2012-02-08;1347.04;1351.00;1341.95;1349.96;4096730000;1349.96
2012-02-07;1344.33;1349.24;1335.92;1347.05;3742460000;1347.05
2012-02-06;1344.32;1344.36;1337.52;1344.33;3379700000;1344.33
2012-02-03;1326.21;1345.34;1326.21;1344.90;4608550000;1344.90
2012-02-02;1324.24;1329.19;1321.57;1325.54;4120920000;1325.54
2012-02-01;1312.45;1330.52;1312.45;1324.09;4504360000;1324.09
2012-01-31;1313.53;1321.41;1306.69;1312.41;4235550000;1312.41
2012-01-30;1316.16;1316.16;1300.49;1313.01;3659010000;1313.01
2012-01-27;1318.25;1320.06;1311.72;1316.33;3860430000;1316.33
2012-01-26;1326.28;1333.47;1313.60;1318.43;4522070000;1318.43
2012-01-25;1314.40;1328.30;1307.65;1326.06;4410910000;1326.06
2012-01-24;1315.96;1315.96;1306.06;1314.65;3693560000;1314.65
2012-01-23;1315.29;1322.28;1309.89;1316.00;3770910000;1316.00
2012-01-20;1314.49;1315.38;1309.17;1315.38;3912620000;1315.38
2012-01-19;1308.07;1315.49;1308.07;1314.50;4465890000;1314.50
2012-01-18;1293.65;1308.11;1290.99;1308.04;4096160000;1308.04
2012-01-17;1290.22;1303.00;1290.22;1293.67;4010490000;1293.67
2012-01-13;1294.82;1294.82;1277.58;1289.09;3692370000;1289.09
2012-01-12;1292.48;1296.82;1285.77;1295.50;4019890000;1295.50
2012-01-11;1292.02;1293.80;1285.41;1292.48;3968120000;1292.48
2012-01-10;1280.77;1296.46;1280.77;1292.08;4221960000;1292.08
2012-01-09;1277.83;1281.99;1274.55;1280.70;3371600000;1280.70
2012-01-06;1280.93;1281.84;1273.34;1277.81;3656830000;1277.81
2012-01-05;1277.30;1283.05;1265.26;1281.06;4315950000;1281.06
2012-01-04;1277.03;1278.73;1268.10;1277.30;3592580000;1277.30
2012-01-03;1258.86;1284.62;1258.86;1277.06;3943710000;1277.06
2011-12-30;1262.82;1264.12;1257.46;1257.60;2271850000;1257.60
2011-12-29;1249.75;1263.54;1249.75;1263.02;2278130000;1263.02
2011-12-28;1265.38;1265.85;1248.64;1249.64;2349980000;1249.64
2011-12-27;1265.02;1269.37;1262.30;1265.43;2130590000;1265.43
2011-12-23;1254.00;1265.42;1254.00;1265.33;2233830000;1265.33
2011-12-22;1243.72;1255.22;1243.72;1254.00;3492250000;1254.00
2011-12-21;1241.25;1245.09;1229.51;1243.72;2959020000;1243.72
2011-12-20;1205.72;1242.82;1205.72;1241.30;4055590000;1241.30
2011-12-19;1219.74;1224.57;1202.37;1205.35;3659820000;1205.35
2011-12-16;1216.09;1231.04;1215.20;1219.66;5345800000;1219.66
2011-12-15;1212.12;1225.60;1212.12;1215.75;3810340000;1215.75
2011-12-14;1225.73;1225.73;1209.47;1211.82;4298290000;1211.82
2011-12-13;1236.83;1249.86;1219.43;1225.73;4121570000;1225.73
2011-12-12;1255.05;1255.05;1227.25;1236.47;3600570000;1236.47
2011-12-09;1234.48;1258.25;1234.48;1255.19;3830610000;1255.19
2011-12-08;1260.87;1260.87;1231.47;1234.35;4298370000;1234.35
2011-12-07;1258.14;1267.06;1244.80;1261.01;4160540000;1261.01
2011-12-06;1257.19;1266.03;1253.03;1258.47;3734230000;1258.47
2011-12-05;1244.33;1266.73;1244.33;1257.08;4148060000;1257.08
2011-12-02;1246.03;1260.08;1243.35;1244.28;4144310000;1244.28
2011-12-01;1246.91;1251.09;1239.73;1244.58;3818680000;1244.58
2011-11-30;1196.72;1247.11;1196.72;1246.96;5801910000;1246.96
2011-11-29;1192.56;1203.67;1191.80;1195.19;3992650000;1195.19
2011-11-28;1158.67;1197.35;1158.67;1192.55;3920750000;1192.55
2011-11-25;1161.41;1172.66;1158.66;1158.67;1664200000;1158.67
2011-11-23;1187.48;1187.48;1161.79;1161.79;3798940000;1161.79
2011-11-22;1192.98;1196.81;1181.65;1188.04;3911710000;1188.04
2011-11-21;1215.62;1215.62;1183.16;1192.98;4050070000;1192.98
2011-11-18;1216.19;1223.51;1211.36;1215.65;3827610000;1215.65
2011-11-17;1236.56;1237.73;1209.43;1216.13;4596450000;1216.13
2011-11-16;1257.81;1259.61;1235.67;1236.91;4085010000;1236.91
2011-11-15;1251.70;1264.25;1244.34;1257.81;3599300000;1257.81
2011-11-14;1263.85;1263.85;1246.68;1251.78;3219680000;1251.78
2011-11-11;1240.12;1266.98;1240.12;1263.85;3329830000;1263.85
2011-11-10;1229.59;1246.22;1227.70;1239.70;4002760000;1239.70
2011-11-09;1275.18;1275.18;1226.64;1229.10;4659740000;1229.10
2011-11-08;1261.12;1277.55;1254.99;1275.92;3908490000;1275.92
2011-11-07;1253.21;1261.70;1240.75;1261.12;3429740000;1261.12
2011-11-04;1260.82;1260.82;1238.92;1253.23;3830650000;1253.23
2011-11-03;1238.25;1263.21;1234.81;1261.15;4849140000;1261.15
2011-11-02;1219.62;1242.48;1219.62;1237.90;4110530000;1237.90
2011-11-01;1251.00;1251.00;1215.42;1218.28;5645540000;1218.28
2011-10-31;1284.96;1284.96;1253.16;1253.30;4310210000;1253.30
2011-10-28;1284.39;1287.08;1277.01;1285.09;4536690000;1285.09
2011-10-27;1243.97;1292.66;1243.97;1284.59;6367610000;1284.59
2011-10-26;1229.17;1246.28;1221.06;1242.00;4873530000;1242.00
2011-10-25;1254.19;1254.19;1226.79;1229.05;4473970000;1229.05
2011-10-24;1238.72;1256.55;1238.72;1254.19;4309380000;1254.19
2011-10-21;1215.39;1239.03;1215.39;1238.25;4980770000;1238.25
2011-10-20;1209.92;1219.53;1197.34;1215.39;4870290000;1215.39
2011-10-19;1223.46;1229.64;1206.31;1209.88;4846390000;1209.88
2011-10-18;1200.75;1233.10;1191.48;1225.38;4840170000;1225.38
2011-10-17;1224.47;1224.47;1198.55;1200.86;4300700000;1200.86
2011-10-14;1205.65;1224.61;1205.65;1224.58;4116690000;1224.58
2011-10-13;1206.96;1207.46;1190.58;1203.66;4436270000;1203.66
2011-10-12;1196.19;1220.25;1196.19;1207.25;5355360000;1207.25
2011-10-11;1194.60;1199.24;1187.30;1195.54;4424500000;1195.54
2011-10-10;1158.15;1194.91;1158.15;1194.89;4446800000;1194.89
2011-10-07;1165.03;1171.40;1150.26;1155.46;5580380000;1155.46
2011-10-06;1144.11;1165.55;1134.95;1164.97;5098330000;1164.97
2011-10-05;1124.03;1146.07;1115.68;1144.03;2510620000;1144.03
2011-10-04;1097.42;1125.12;1074.77;1123.95;3714670000;1123.95
2011-10-03;1131.21;1138.99;1098.92;1099.23;5670340000;1099.23
2011-09-30;1159.93;1159.93;1131.34;1131.42;4416790000;1131.42
2011-09-29;1151.74;1175.87;1139.93;1160.40;5285740000;1160.40
2011-09-28;1175.39;1184.71;1150.40;1151.06;4787920000;1151.06
2011-09-27;1163.32;1195.86;1163.32;1175.38;5548130000;1175.38
2011-09-26;1136.91;1164.19;1131.07;1162.95;4762830000;1162.95
2011-09-23;1128.82;1141.72;1121.36;1136.43;5639930000;1136.43
2011-09-22;1164.55;1164.55;1114.22;1129.56;6703140000;1129.56
2011-09-21;1203.63;1206.30;1166.21;1166.76;4728550000;1166.76
2011-09-20;1204.50;1220.39;1201.29;1202.09;4315610000;1202.09
2011-09-19;1214.99;1214.99;1188.36;1204.09;4254190000;1204.09
2011-09-16;1209.21;1220.06;1204.46;1216.01;5248890000;1216.01
2011-09-15;1189.44;1209.11;1189.44;1209.11;4479730000;1209.11
2011-09-14;1173.32;1202.38;1162.73;1188.68;4986740000;1188.68
2011-09-13;1162.59;1176.41;1157.44;1172.87;4681370000;1172.87
2011-09-12;1153.50;1162.52;1136.07;1162.27;5168550000;1162.27
2011-09-09;1185.37;1185.37;1148.37;1154.23;4586370000;1154.23
2011-09-08;1197.98;1204.40;1183.34;1185.90;4465170000;1185.90
2011-09-07;1165.85;1198.62;1165.85;1198.62;4441040000;1198.62
2011-09-06;1173.97;1173.97;1140.13;1165.24;5103980000;1165.24
2011-09-02;1203.90;1203.90;1170.56;1173.97;4401740000;1173.97
2011-09-01;1219.12;1229.29;1203.85;1204.42;4780410000;1204.42
2011-08-31;1213.00;1230.71;1209.35;1218.89;5267840000;1218.89
2011-08-30;1209.76;1220.10;1195.77;1212.92;4572570000;1212.92
2011-08-29;1177.91;1210.28;1177.91;1210.08;4228070000;1210.08
2011-08-26;1158.85;1181.23;1135.91;1176.80;5035320000;1176.80
2011-08-25;1176.69;1190.68;1155.47;1159.27;5748420000;1159.27
2011-08-24;1162.16;1178.56;1156.30;1177.60;5315310000;1177.60
2011-08-23;1124.36;1162.35;1124.36;1162.35;5013170000;1162.35
2011-08-22;1123.55;1145.49;1121.09;1123.82;5436260000;1123.82
2011-08-19;1140.47;1154.54;1122.05;1123.53;5167560000;1123.53
2011-08-18;1189.62;1189.62;1131.03;1140.65;3234810000;1140.65
2011-08-17;1192.89;1208.47;1184.36;1193.89;4388340000;1193.89
2011-08-16;1204.22;1204.22;1180.53;1192.76;5071600000;1192.76
2011-08-15;1178.86;1204.49;1178.86;1204.49;4272850000;1204.49
2011-08-12;1172.87;1189.04;1170.74;1178.81;5640380000;1178.81
2011-08-11;1121.30;1186.29;1121.30;1172.64;3685050000;1172.64
2011-08-10;1171.77;1171.77;1118.01;1120.76;5018070000;1120.76
2011-08-09;1120.23;1172.88;1101.54;1172.53;2366660000;1172.53
2011-08-08;1198.48;1198.48;1119.28;1119.46;2615150000;1119.46
2011-08-05;1200.28;1218.11;1168.09;1199.38;5454590000;1199.38
2011-08-04;1260.23;1260.23;1199.54;1200.07;4266530000;1200.07
2011-08-03;1254.25;1261.20;1234.56;1260.34;6446940000;1260.34
2011-08-02;1286.56;1286.56;1254.03;1254.05;5206290000;1254.05
2011-08-01;1292.59;1307.38;1274.73;1286.94;4967390000;1286.94
2011-07-29;1300.12;1304.16;1282.86;1292.28;5061190000;1292.28
2011-07-28;1304.84;1316.32;1299.16;1300.67;4951800000;1300.67
2011-07-27;1331.91;1331.91;1303.49;1304.89;3479040000;1304.89
2011-07-26;1337.39;1338.51;1329.59;1331.94;4007050000;1331.94
2011-07-25;1344.32;1344.32;1331.09;1337.43;3536890000;1337.43
2011-07-22;1343.80;1346.10;1336.95;1345.02;3522830000;1345.02
2011-07-21;1325.65;1347.00;1325.65;1343.80;4837430000;1343.80
2011-07-20;1328.66;1330.43;1323.65;1325.84;3767420000;1325.84
2011-07-19;1307.07;1328.14;1307.07;1326.73;4304600000;1326.73
2011-07-18;1315.94;1315.94;1295.92;1305.44;4118160000;1305.44
2011-07-15;1308.87;1317.70;1307.52;1316.14;4242760000;1316.14
2011-07-14;1317.74;1326.88;1306.51;1308.87;4358570000;1308.87
2011-07-13;1314.45;1331.48;1314.45;1317.72;4060080000;1317.72
2011-07-12;1319.61;1327.17;1313.33;1313.64;4227890000;1313.64
2011-07-11;1343.31;1343.31;1316.42;1319.49;3879130000;1319.49
2011-07-08;1352.39;1352.39;1333.71;1343.80;3594360000;1343.80
2011-07-07;1339.62;1356.48;1339.62;1353.22;4069530000;1353.22
2011-07-06;1337.56;1340.94;1330.92;1339.22;3564190000;1339.22
2011-07-05;1339.59;1340.89;1334.30;1337.88;3722320000;1337.88
2011-07-01;1320.64;1341.01;1318.18;1339.67;3796930000;1339.67
2011-06-30;1307.64;1321.97;1307.64;1320.64;4200500000;1320.64
2011-06-29;1296.85;1309.21;1296.85;1307.41;4347540000;1307.41
2011-06-28;1280.21;1296.80;1280.21;1296.67;3681500000;1296.67
2011-06-27;1268.44;1284.91;1267.53;1280.10;3479070000;1280.10
2011-06-24;1283.04;1283.93;1267.24;1268.45;3665340000;1268.45
2011-06-23;1286.60;1286.60;1262.87;1283.50;4983450000;1283.50
2011-06-22;1295.48;1298.61;1286.79;1287.14;3718420000;1287.14
2011-06-21;1278.40;1297.62;1278.40;1295.52;4056150000;1295.52
2011-06-20;1271.50;1280.42;1267.56;1278.36;3464660000;1278.36
2011-06-17;1268.58;1279.82;1267.40;1271.50;4916460000;1271.50
2011-06-16;1265.53;1274.11;1258.07;1267.64;3846250000;1267.64
2011-06-15;1287.87;1287.87;1261.90;1265.42;4070500000;1265.42
2011-06-14;1272.22;1292.50;1272.22;1287.87;3500280000;1287.87
2011-06-13;1271.31;1277.04;1265.64;1271.83;4132520000;1271.83
2011-06-10;1288.60;1288.60;1268.28;1270.98;3846250000;1270.98
2011-06-09;1279.63;1294.54;1279.63;1289.00;3332510000;1289.00
2011-06-08;1284.63;1287.04;1277.42;1279.56;3970810000;1279.56
2011-06-07;1286.31;1296.22;1284.74;1284.94;3846250000;1284.94
2011-06-06;1300.26;1300.26;1284.72;1286.17;3555980000;1286.17
2011-06-03;1312.94;1312.94;1297.90;1300.16;3505030000;1300.16
2011-06-02;1314.55;1318.03;1305.61;1312.94;3762170000;1312.94
2011-06-01;1345.20;1345.20;1313.71;1314.55;4241090000;1314.55
2011-05-31;1331.10;1345.20;1331.10;1345.20;4696240000;1345.20
2011-05-27;1325.69;1334.62;1325.69;1331.10;3124560000;1331.10
2011-05-26;1320.64;1328.51;1314.41;1325.69;3259470000;1325.69
2011-05-25;1316.36;1325.86;1311.80;1320.47;4109670000;1320.47
2011-05-24;1317.70;1323.72;1313.87;1316.28;3846250000;1316.28
2011-05-23;1333.07;1333.07;1312.88;1317.37;3255580000;1317.37
2011-05-20;1342.00;1342.00;1330.67;1333.27;4066020000;1333.27
2011-05-19;1342.40;1346.82;1336.36;1343.60;3626110000;1343.60
2011-05-18;1328.54;1341.82;1326.59;1340.68;3922030000;1340.68
2011-05-17;1326.10;1330.42;1318.51;1328.98;4053970000;1328.98
2011-05-16;1334.77;1343.33;1327.32;1329.47;3846250000;1329.47
2011-05-13;1348.69;1350.47;1333.36;1337.77;3426660000;1337.77
2011-05-12;1339.39;1351.05;1332.03;1348.65;3777210000;1348.65
2011-05-11;1354.51;1354.51;1336.36;1342.08;3846250000;1342.08
2011-05-10;1348.34;1359.44;1348.34;1357.16;4223740000;1357.16
2011-05-09;1340.20;1349.44;1338.64;1346.29;4265250000;1346.29
2011-05-06;1340.24;1354.36;1335.58;1340.20;4223740000;1340.20
2011-05-05;1344.16;1348.00;1329.17;1335.10;3846250000;1335.10
2011-05-04;1355.90;1355.90;1341.50;1347.32;4223740000;1347.32
2011-05-03;1359.76;1360.84;1349.52;1356.62;4223740000;1356.62
2011-05-02;1365.21;1370.58;1358.59;1361.22;3846250000;1361.22
2011-04-29;1360.14;1364.56;1358.69;1363.61;3479070000;1363.61
2011-04-28;1353.86;1361.71;1353.60;1360.48;4036820000;1360.48
2011-04-27;1348.43;1357.49;1344.25;1355.66;4051570000;1355.66
2011-04-26;1336.75;1349.55;1336.75;1347.24;3908060000;1347.24
2011-04-25;1337.14;1337.55;1331.47;1335.25;2142130000;1335.25
2011-04-21;1333.23;1337.49;1332.83;1337.38;3587240000;1337.38
2011-04-20;1319.12;1332.66;1319.12;1330.36;4236280000;1330.36
2011-04-19;1305.99;1312.70;1303.97;1312.62;3886300000;1312.62
2011-04-18;1313.35;1313.35;1294.70;1305.14;4223740000;1305.14
2011-04-15;1314.54;1322.88;1313.68;1319.68;4223740000;1319.68
2011-04-14;1311.13;1316.79;1302.42;1314.52;3872630000;1314.52
2011-04-13;1314.03;1321.35;1309.19;1314.41;3850860000;1314.41
2011-04-12;1321.96;1321.96;1309.51;1314.16;4275490000;1314.16
2011-04-11;1329.01;1333.77;1321.06;1324.46;3478970000;1324.46
2011-04-08;1336.16;1339.46;1322.94;1328.17;3582810000;1328.17
2011-04-07;1334.82;1338.80;1326.56;1333.51;4005600000;1333.51
2011-04-06;1335.94;1339.38;1331.09;1335.54;4223740000;1335.54
2011-04-05;1332.03;1338.21;1330.03;1332.63;3852280000;1332.63
2011-04-04;1333.56;1336.74;1329.10;1332.87;4223740000;1332.87
2011-04-01;1329.48;1337.85;1328.89;1332.41;4223740000;1332.41
2011-03-31;1327.44;1329.77;1325.03;1325.83;3566270000;1325.83
2011-03-30;1321.89;1331.74;1321.89;1328.26;3809570000;1328.26
2011-03-29;1309.37;1319.45;1305.26;1319.44;3482580000;1319.44
2011-03-28;1315.45;1319.74;1310.19;1310.19;3215170000;1310.19
2011-03-25;1311.80;1319.18;1310.15;1313.80;4223740000;1313.80
2011-03-24;1300.61;1311.34;1297.74;1309.66;4223740000;1309.66
2011-03-23;1292.19;1300.51;1284.05;1297.54;3842350000;1297.54
2011-03-22;1298.29;1299.35;1292.70;1293.77;3576550000;1293.77
2011-03-21;1281.65;1300.58;1281.65;1298.38;4223730000;1298.38
2011-03-18;1276.71;1288.88;1276.18;1279.21;4685500000;1279.21
2011-03-17;1261.61;1278.88;1261.61;1273.72;4134950000;1273.72
2011-03-16;1279.46;1280.91;1249.05;1256.88;5833000000;1256.88
2011-03-15;1288.46;1288.46;1261.12;1281.87;5201400000;1281.87
2011-03-14;1301.19;1301.19;1286.37;1296.39;4050370000;1296.39
2011-03-11;1293.43;1308.35;1291.99;1304.28;3740400000;1304.28
2011-03-10;1315.72;1315.72;1294.21;1295.11;4723020000;1295.11
2011-03-09;1319.92;1323.21;1312.27;1320.02;3709520000;1320.02
2011-03-08;1311.05;1325.74;1306.86;1321.82;4531420000;1321.82
2011-03-07;1322.72;1327.68;1303.99;1310.13;3964730000;1310.13
2011-03-04;1330.73;1331.08;1312.59;1321.15;4223740000;1321.15
2011-03-03;1312.37;1332.28;1312.37;1330.97;4340470000;1330.97
2011-03-02;1305.47;1314.19;1302.58;1308.44;1025000000;1308.44
2011-03-01;1328.64;1332.09;1306.14;1306.33;1180420000;1306.33
2011-02-28;1321.61;1329.38;1320.55;1327.22;1252850000;1327.22
2011-02-25;1307.34;1320.61;1307.34;1319.88;3836030000;1319.88
2011-02-24;1307.09;1310.91;1294.26;1306.10;1222900000;1306.10
2011-02-23;1315.44;1317.91;1299.55;1307.40;1330340000;1307.40
2011-02-22;1338.91;1338.91;1312.33;1315.44;1322780000;1315.44
2011-02-18;1340.38;1344.07;1338.12;1343.01;1966450000;1343.01
2011-02-17;1334.37;1341.50;1331.00;1340.43;1966450000;1340.43
2011-02-16;1329.51;1337.61;1329.51;1336.32;1966450000;1336.32
2011-02-15;1330.43;1330.43;1324.61;1328.01;3926860000;1328.01
2011-02-14;1328.73;1332.96;1326.90;1332.32;3567040000;1332.32
2011-02-11;1318.66;1330.79;1316.08;1329.15;4219300000;1329.15
2011-02-10;1318.13;1322.78;1311.74;1321.87;4184610000;1321.87
2011-02-09;1322.48;1324.54;1314.89;1320.88;3922240000;1320.88
2011-02-08;1318.76;1324.87;1316.03;1324.57;3881530000;1324.57
2011-02-07;1311.85;1322.85;1311.85;1319.05;3902270000;1319.05
2011-02-04;1307.01;1311.00;1301.67;1310.87;3925950000;1310.87
2011-02-03;1302.77;1308.60;1294.83;1307.10;4370990000;1307.10
2011-02-02;1305.91;1307.61;1302.62;1304.03;4098260000;1304.03
2011-02-01;1289.14;1308.86;1289.14;1307.59;5164500000;1307.59
2011-01-31;1276.50;1287.17;1276.50;1286.12;4167160000;1286.12
2011-01-28;1299.63;1302.67;1275.10;1276.34;5618630000;1276.34
2011-01-27;1297.51;1301.29;1294.41;1299.54;4309190000;1299.54
2011-01-26;1291.97;1299.74;1291.97;1296.63;4730980000;1296.63
2011-01-25;1288.17;1291.26;1281.07;1291.18;4595380000;1291.18
2011-01-24;1283.29;1291.93;1282.47;1290.84;3902470000;1290.84
2011-01-21;1283.63;1291.21;1282.07;1283.35;4935320000;1283.35
2011-01-20;1280.85;1283.35;1271.26;1280.26;4935320000;1280.26
2011-01-19;1294.52;1294.60;1278.92;1281.92;4743710000;1281.92
2011-01-18;1293.22;1296.06;1290.16;1295.02;5284990000;1295.02
2011-01-14;1282.90;1293.24;1281.24;1293.24;4661590000;1293.24
2011-01-13;1285.78;1286.70;1280.47;1283.76;4310840000;1283.76
2011-01-12;1275.65;1286.87;1275.65;1285.96;4226940000;1285.96
2011-01-11;1272.58;1277.25;1269.62;1274.48;4050750000;1274.48
2011-01-10;1270.84;1271.52;1262.18;1269.75;4036450000;1269.75
2011-01-07;1274.41;1276.83;1261.70;1271.50;4963110000;1271.50
2011-01-06;1276.29;1278.17;1270.43;1273.85;4844100000;1273.85
2011-01-05;1268.78;1277.63;1265.36;1276.56;4764920000;1276.56
2011-01-04;1272.95;1274.12;1262.66;1270.20;4796420000;1270.20
2011-01-03;1257.62;1276.17;1257.62;1271.87;4286670000;1271.87
2010-12-31;1256.76;1259.34;1254.19;1257.64;1799770000;1257.64
2010-12-30;1259.44;1261.09;1256.32;1257.88;1970720000;1257.88
2010-12-29;1258.78;1262.60;1258.78;1259.78;2214380000;1259.78
2010-12-28;1259.10;1259.90;1256.22;1258.51;2478450000;1258.51
2010-12-27;1254.66;1258.43;1251.48;1257.54;1992470000;1257.54
2010-12-23;1257.53;1258.59;1254.05;1256.77;2515020000;1256.77
2010-12-22;1254.94;1259.39;1254.94;1258.84;1285590000;1258.84
2010-12-21;1249.43;1255.82;1249.43;1254.60;3479670000;1254.60
2010-12-20;1245.76;1250.20;1241.51;1247.08;3548140000;1247.08
2010-12-17;1243.63;1245.81;1239.87;1243.91;4632470000;1243.91
2010-12-16;1236.34;1243.75;1232.85;1242.87;4736820000;1242.87
2010-12-15;1241.58;1244.25;1234.01;1235.23;4407340000;1235.23
2010-12-14;1241.84;1246.59;1238.17;1241.59;4132350000;1241.59
2010-12-13;1242.52;1246.73;1240.34;1240.46;4361240000;1240.46
2010-12-10;1233.85;1240.40;1232.58;1240.40;4547310000;1240.40
2010-12-09;1230.14;1234.71;1226.85;1233.00;4522510000;1233.00
2010-12-08;1225.02;1228.93;1219.50;1228.28;4607590000;1228.28
2010-12-07;1227.25;1235.05;1223.25;1223.75;6970630400;1223.75
2010-12-06;1223.87;1225.80;1220.67;1223.12;3527370000;1223.12
2010-12-03;1219.93;1225.57;1216.82;1224.71;3735780000;1224.71
2010-12-02;1206.81;1221.89;1206.81;1221.53;4970800000;1221.53
2010-12-01;1186.60;1207.61;1186.60;1206.07;4548110000;1206.07
2010-11-30;1182.96;1187.40;1174.14;1180.55;4284700000;1180.55
2010-11-29;1189.08;1190.34;1173.64;1187.76;3673450000;1187.76
2010-11-26;1194.16;1194.16;1186.93;1189.40;1613820000;1189.40
2010-11-24;1183.70;1198.62;1183.70;1198.35;3384250000;1198.35
2010-11-23;1192.51;1192.51;1176.91;1180.73;4133070000;1180.73
2010-11-22;1198.07;1198.94;1184.58;1197.84;3689500000;1197.84
2010-11-19;1196.12;1199.97;1189.44;1199.73;3675390000;1199.73
2010-11-18;1183.75;1200.29;1183.75;1196.69;4687260000;1196.69
2010-11-17;1178.33;1183.56;1175.82;1178.59;3904780000;1178.59
2010-11-16;1194.79;1194.79;1173.00;1178.34;5116380000;1178.34
2010-11-15;1200.44;1207.43;1197.15;1197.75;3503370000;1197.75
2010-11-12;1209.07;1210.50;1194.08;1199.21;4213620000;1199.21
2010-11-11;1213.04;1215.45;1204.49;1213.54;3931120000;1213.54
2010-11-10;1213.14;1218.75;1204.33;1218.71;4561300000;1218.71
2010-11-09;1223.59;1226.84;1208.94;1213.40;4848040000;1213.40
2010-11-08;1223.24;1224.57;1217.55;1223.25;3937230000;1223.25
2010-11-05;1221.20;1227.08;1220.29;1225.85;5637460000;1225.85
2010-11-04;1198.34;1221.25;1198.34;1221.06;5695470000;1221.06
2010-11-03;1193.79;1198.30;1183.56;1197.96;4665480000;1197.96
2010-11-02;1187.86;1195.88;1187.86;1193.57;3866200000;1193.57
2010-11-01;1185.71;1195.81;1177.65;1184.38;4129180000;1184.38
2010-10-29;1183.87;1185.46;1179.70;1183.26;3537880000;1183.26
2010-10-28;1184.47;1189.53;1177.10;1183.78;4283460000;1183.78
2010-10-27;1183.84;1183.84;1171.70;1182.45;4335670000;1182.45
2010-10-26;1184.88;1187.11;1177.72;1185.64;4203680000;1185.64
2010-10-25;1184.74;1196.14;1184.74;1185.62;4221380000;1185.62
2010-10-22;1180.52;1183.93;1178.99;1183.08;3177890000;1183.08
2010-10-21;1179.82;1189.43;1171.17;1180.26;4625470000;1180.26
2010-10-20;1166.74;1182.94;1166.74;1178.17;5027880000;1178.17
2010-10-19;1178.64;1178.64;1159.71;1165.90;5600120000;1165.90
2010-10-18;1176.83;1185.53;1174.55;1184.71;4450050000;1184.71
2010-10-15;1177.47;1181.20;1167.12;1176.19;5724910000;1176.19
2010-10-14;1177.82;1178.89;1166.71;1173.81;4969410000;1173.81
2010-10-13;1171.32;1184.38;1171.32;1178.10;4969410000;1178.10
2010-10-12;1164.28;1172.58;1155.71;1169.77;4076170000;1169.77
2010-10-11;1165.32;1168.68;1162.02;1165.32;2505900000;1165.32
2010-10-08;1158.36;1167.73;1155.58;1165.15;3871420000;1165.15
2010-10-07;1161.57;1163.87;1151.41;1158.06;3910550000;1158.06
2010-10-06;1159.81;1162.33;1154.85;1159.97;4073160000;1159.97
2010-10-05;1140.68;1162.76;1140.68;1160.75;4068840000;1160.75
2010-10-04;1144.96;1148.16;1131.87;1137.03;3604110000;1137.03
2010-10-01;1143.49;1150.30;1139.42;1146.24;4298910000;1146.24
2010-09-30;1145.97;1157.16;1136.08;1141.20;4284160000;1141.20
2010-09-29;1146.75;1148.63;1140.26;1144.73;3990280000;1144.73
2010-09-28;1142.31;1150.00;1132.09;1147.70;4025840000;1147.70
2010-09-27;1148.64;1149.92;1142.00;1142.16;3587860000;1142.16
2010-09-24;1131.69;1148.90;1131.69;1148.67;4123950000;1148.67
2010-09-23;1131.10;1136.77;1122.79;1124.83;3847850000;1124.83
2010-09-22;1139.49;1144.38;1131.58;1134.28;3911070000;1134.28
2010-09-21;1142.82;1148.59;1136.22;1139.78;4175660000;1139.78
2010-09-20;1126.57;1144.86;1126.57;1142.71;3364080000;1142.71
2010-09-17;1126.39;1131.47;1122.43;1125.59;4086140000;1125.59
2010-09-16;1123.89;1125.44;1118.88;1124.66;3364080000;1124.66
2010-09-15;1119.43;1126.46;1114.63;1125.07;3369840000;1125.07
2010-09-14;1121.16;1127.36;1115.58;1121.10;4521050000;1121.10
2010-09-13;1113.38;1123.87;1113.38;1121.90;4521050000;1121.90
2010-09-10;1104.57;1110.88;1103.92;1109.55;3061160000;1109.55
2010-09-09;1101.15;1110.27;1101.15;1104.18;3387770000;1104.18
2010-09-08;1092.36;1103.26;1092.36;1098.87;3224640000;1098.87
2010-09-07;1102.60;1102.60;1091.15;1091.84;3107380000;1091.84
2010-09-03;1093.61;1105.10;1093.61;1104.51;3534500000;1104.51
2010-09-02;1080.66;1090.10;1080.39;1090.10;3704210000;1090.10
2010-09-01;1049.72;1081.30;1049.72;1080.29;4396880000;1080.29
2010-08-31;1046.88;1055.14;1040.88;1049.33;4038770000;1049.33
2010-08-30;1062.90;1064.40;1048.79;1048.92;2917990000;1048.92
2010-08-27;1049.27;1065.21;1039.70;1064.59;4102460000;1064.59
2010-08-26;1056.28;1061.45;1045.40;1047.22;3646710000;1047.22
2010-08-25;1048.98;1059.38;1039.83;1055.33;4360190000;1055.33
2010-08-24;1063.20;1063.20;1046.68;1051.87;4436330000;1051.87
2010-08-23;1073.36;1081.58;1067.08;1067.36;3210950000;1067.36
2010-08-20;1075.63;1075.63;1063.91;1071.69;3761570000;1071.69
2010-08-19;1092.44;1092.44;1070.66;1075.63;4290540000;1075.63
2010-08-18;1092.08;1099.77;1085.76;1094.16;3724260000;1094.16
2010-08-17;1081.16;1100.14;1081.16;1092.54;3968210000;1092.54
2010-08-16;1077.49;1082.62;1069.49;1079.38;3142450000;1079.38
2010-08-13;1082.22;1086.25;1079.00;1079.25;3328890000;1079.25
2010-08-12;1081.48;1086.72;1076.69;1083.61;4521050000;1083.61
2010-08-11;1116.89;1116.89;1088.55;1089.47;4511860000;1089.47
2010-08-10;1122.92;1127.16;1111.58;1121.06;3979360000;1121.06
2010-08-09;1122.80;1129.24;1120.91;1127.79;3191630000;1127.79
2010-08-06;1122.07;1123.06;1107.17;1121.64;3857890000;1121.64
2010-08-05;1125.78;1126.56;1118.81;1125.81;3685560000;1125.81
2010-08-04;1121.06;1128.75;1119.46;1127.24;4057850000;1127.24
2010-08-03;1125.34;1125.44;1116.76;1120.46;4071820000;1120.46
2010-08-02;1107.53;1127.30;1107.53;1125.86;4144180000;1125.86
2010-07-30;1098.44;1106.44;1088.01;1101.60;4006450000;1101.60
2010-07-29;1108.07;1115.90;1092.82;1101.53;4612420000;1101.53
2010-07-28;1112.84;1114.66;1103.11;1106.13;4002390000;1106.13
2010-07-27;1117.36;1120.95;1109.78;1113.84;4725690000;1113.84
2010-07-26;1102.89;1115.01;1101.30;1115.01;4009650000;1115.01
2010-07-23;1092.17;1103.73;1087.88;1102.66;4524570000;1102.66
2010-07-22;1072.14;1097.50;1072.14;1093.67;4826900000;1093.67
2010-07-21;1086.67;1088.96;1065.25;1069.59;4747180000;1069.59
2010-07-20;1064.53;1083.94;1056.88;1083.48;4713280000;1083.48
2010-07-19;1066.85;1074.70;1061.11;1071.25;4089500000;1071.25
2010-07-16;1093.85;1093.85;1063.32;1064.88;5297350000;1064.88
2010-07-15;1094.46;1098.66;1080.53;1096.48;4552470000;1096.48
2010-07-14;1095.61;1099.08;1087.68;1095.17;4521050000;1095.17
2010-07-13;1080.65;1099.46;1080.65;1095.34;4640460000;1095.34
2010-07-12;1077.23;1080.78;1070.45;1078.75;3426990000;1078.75
2010-07-09;1070.50;1078.16;1068.10;1077.96;3506570000;1077.96
2010-07-08;1062.92;1071.25;1058.24;1070.25;4548460000;1070.25
2010-07-07;1028.54;1060.89;1028.54;1060.27;4931220000;1060.27
2010-07-06;1028.09;1042.50;1018.35;1028.06;4691240000;1028.06
2010-07-02;1027.65;1032.95;1015.93;1022.58;3968500000;1022.58
2010-07-01;1031.10;1033.58;1010.91;1027.37;6435770000;1027.37
2010-06-30;1040.56;1048.08;1028.33;1030.71;5067080000;1030.71
2010-06-29;1071.10;1071.10;1035.18;1041.24;6136700000;1041.24
2010-06-28;1077.50;1082.60;1071.45;1074.57;3896410000;1074.57
2010-06-25;1075.10;1083.56;1067.89;1076.76;5128840000;1076.76
2010-06-24;1090.93;1090.93;1071.60;1073.69;4814830000;1073.69
2010-06-23;1095.57;1099.64;1085.31;1092.04;4526150000;1092.04
2010-06-22;1113.90;1118.50;1094.18;1095.31;4514380000;1095.31
2010-06-21;1122.79;1131.23;1108.24;1113.20;4514360000;1113.20
2010-06-18;1116.16;1121.01;1113.93;1117.51;4555360000;1117.51
2010-06-17;1115.98;1117.72;1105.87;1116.04;4557760000;1116.04
2010-06-16;1114.02;1118.74;1107.13;1114.61;5002600000;1114.61
2010-06-15;1091.21;1115.59;1091.21;1115.23;4644490000;1115.23
2010-06-14;1095.00;1105.91;1089.03;1089.63;4425830000;1089.63
2010-06-11;1082.65;1092.25;1077.12;1091.60;4059280000;1091.60
2010-06-10;1058.77;1087.85;1058.77;1086.84;5144780000;1086.84
2010-06-09;1062.75;1077.74;1052.25;1055.69;5983200000;1055.69
2010-06-08;1050.81;1063.15;1042.17;1062.00;6192750000;1062.00
2010-06-07;1065.84;1071.36;1049.86;1050.47;5467560000;1050.47
2010-06-04;1098.43;1098.43;1060.50;1064.88;6180580000;1064.88
2010-06-03;1098.82;1105.67;1091.81;1102.83;4995970000;1102.83
2010-06-02;1073.01;1098.56;1072.03;1098.38;5026360000;1098.38
2010-06-01;1087.30;1094.77;1069.89;1070.71;5271480000;1070.71
2010-05-28;1102.59;1102.59;1084.78;1089.41;4871210000;1089.41
2010-05-27;1074.27;1103.52;1074.27;1103.06;5698460000;1103.06
2010-05-26;1075.51;1090.75;1065.59;1067.95;4521050000;1067.95
2010-05-25;1067.42;1074.75;1040.78;1074.03;7329580000;1074.03
2010-05-24;1084.78;1089.95;1072.70;1073.65;5224040000;1073.65
2010-05-21;1067.26;1090.16;1055.90;1087.69;5452130000;1087.69
2010-05-20;1107.34;1107.34;1071.58;1071.59;8328569600;1071.59
2010-05-19;1119.57;1124.27;1100.66;1115.05;6765800000;1115.05
2010-05-18;1138.78;1148.66;1117.20;1120.80;6170840000;1120.80
2010-05-17;1136.52;1141.88;1114.96;1136.94;5922920000;1136.94
2010-05-14;1157.19;1157.19;1126.14;1135.68;6126400000;1135.68
2010-05-13;1170.04;1173.57;1156.14;1157.44;4870640000;1157.44
2010-05-12;1155.43;1172.87;1155.43;1171.67;5225460000;1171.67
2010-05-11;1156.39;1170.48;1147.71;1155.79;5842550000;1155.79
2010-05-10;1122.27;1163.85;1122.27;1159.73;6893700000;1159.73
2010-05-07;1127.04;1135.13;1094.15;1110.88;9472910400;1110.88
2010-05-06;1164.38;1167.58;1065.79;1128.15;10617809600;1128.15
2010-05-05;1169.24;1175.95;1158.15;1165.87;6795940000;1165.87
2010-05-04;1197.50;1197.50;1168.12;1173.60;6594720000;1173.60
2010-05-03;1188.58;1205.13;1188.58;1202.26;4938050000;1202.26
2010-04-30;1206.77;1207.99;1186.32;1186.69;6048260000;1186.69
2010-04-29;1193.30;1209.36;1193.30;1206.78;6059410000;1206.78
2010-04-28;1184.59;1195.05;1181.81;1191.36;6342310000;1191.36
2010-04-27;1209.92;1211.38;1181.62;1183.71;7454540000;1183.71
2010-04-26;1217.07;1219.80;1211.07;1212.05;5647760000;1212.05
2010-04-23;1207.87;1217.28;1205.10;1217.28;5326060000;1217.28
2010-04-22;1202.52;1210.27;1190.19;1208.67;6035780000;1208.67
2010-04-21;1207.16;1210.99;1198.85;1205.94;5724310000;1205.94
2010-04-20;1199.04;1208.58;1199.04;1207.17;5316590000;1207.17
2010-04-19;1192.06;1197.87;1183.68;1197.52;6597740000;1197.52
2010-04-16;1210.17;1210.17;1186.77;1192.13;8108470400;1192.13
2010-04-15;1210.77;1213.92;1208.50;1211.67;5995330000;1211.67
2010-04-14;1198.69;1210.65;1198.69;1210.65;5760040000;1210.65
2010-04-13;1195.94;1199.04;1188.82;1197.30;5403580000;1197.30
2010-04-12;1194.94;1199.20;1194.71;1196.48;4607090000;1196.48
2010-04-09;1187.47;1194.66;1187.15;1194.37;4511570000;1194.37
2010-04-08;1181.75;1188.55;1175.12;1186.44;4726970000;1186.44
2010-04-07;1188.23;1189.60;1177.25;1182.45;5101430000;1182.45
2010-04-06;1186.01;1191.80;1182.77;1189.44;4086180000;1189.44
2010-04-05;1178.71;1187.73;1178.71;1187.44;3881620000;1187.44
2010-04-01;1171.23;1181.43;1170.69;1178.10;4006870000;1178.10
2010-03-31;1171.75;1174.56;1165.77;1169.43;4484340000;1169.43
2010-03-30;1173.75;1177.83;1168.92;1173.27;4085000000;1173.27
2010-03-29;1167.71;1174.85;1167.71;1173.22;4375580000;1173.22
2010-03-26;1167.58;1173.93;1161.48;1166.59;4708420000;1166.59
2010-03-25;1170.03;1180.69;1165.09;1165.73;5668900000;1165.73
2010-03-24;1172.70;1173.04;1166.01;1167.72;4705750000;1167.72
2010-03-23;1166.47;1174.72;1163.83;1174.17;4411640000;1174.17
2010-03-22;1157.25;1167.82;1152.88;1165.81;4261680000;1165.81
2010-03-19;1166.68;1169.20;1155.33;1159.90;5212410000;1159.90
2010-03-18;1166.13;1167.77;1161.16;1165.83;4234510000;1165.83
2010-03-17;1159.94;1169.84;1159.94;1166.21;4963200000;1166.21
2010-03-16;1150.83;1160.28;1150.35;1159.46;4369770000;1159.46
2010-03-15;1148.53;1150.98;1141.45;1150.51;4164110000;1150.51
2010-03-12;1151.71;1153.41;1146.97;1149.99;4928160000;1149.99
2010-03-11;1143.96;1150.24;1138.99;1150.24;4669060000;1150.24
2010-03-10;1140.22;1148.26;1140.09;1145.61;5469120000;1145.61
2010-03-09;1137.56;1145.37;1134.90;1140.45;5185570000;1140.45
2010-03-08;1138.40;1141.05;1136.77;1138.50;3774680000;1138.50
2010-03-05;1125.12;1139.38;1125.12;1138.70;4133000000;1138.70
2010-03-04;1119.12;1123.73;1116.66;1122.97;3945010000;1122.97
2010-03-03;1119.36;1125.64;1116.58;1118.79;3951320000;1118.79
2010-03-02;1117.01;1123.46;1116.51;1118.31;4134680000;1118.31
2010-03-01;1105.36;1116.11;1105.36;1115.71;3847640000;1115.71
2010-02-26;1103.10;1107.24;1097.56;1104.49;3945190000;1104.49
2010-02-25;1101.24;1103.50;1086.02;1102.94;4521130000;1102.94
2010-02-24;1095.89;1106.42;1095.50;1105.24;4168360000;1105.24
2010-02-23;1107.49;1108.58;1092.18;1094.60;4521050000;1094.60
2010-02-22;1110.00;1112.29;1105.38;1108.01;3814440000;1108.01
2010-02-19;1105.49;1112.42;1100.80;1109.17;3944280000;1109.17
2010-02-18;1099.03;1108.24;1097.48;1106.75;3878620000;1106.75
2010-02-17;1096.14;1101.03;1094.72;1099.51;4259230000;1099.51
2010-02-16;1079.13;1095.67;1079.13;1094.87;4080770000;1094.87
2010-02-12;1075.95;1077.81;1062.97;1075.51;4160680000;1075.51
2010-02-11;1067.10;1080.04;1060.59;1078.47;4400870000;1078.47
2010-02-10;1069.68;1073.67;1059.34;1068.13;4251450000;1068.13
2010-02-09;1060.06;1079.28;1060.06;1070.52;5114260000;1070.52
2010-02-08;1065.51;1071.20;1056.51;1056.74;4089820000;1056.74
2010-02-05;1064.12;1067.13;1044.50;1066.19;6438900000;1066.19
2010-02-04;1097.25;1097.25;1062.78;1063.11;5859690000;1063.11
2010-02-03;1100.67;1102.72;1093.97;1097.28;4285450000;1097.28
2010-02-02;1090.05;1104.73;1087.96;1103.32;4749540000;1103.32
2010-02-01;1073.89;1089.38;1073.89;1089.19;4077610000;1089.19
2010-01-29;1087.61;1096.45;1071.59;1073.87;5412850000;1073.87
2010-01-28;1096.93;1100.22;1078.46;1084.53;5452400000;1084.53
2010-01-27;1091.94;1099.51;1083.11;1097.50;5319120000;1097.50
2010-01-26;1095.80;1103.69;1089.86;1092.17;4731910000;1092.17
2010-01-25;1092.40;1102.97;1092.40;1096.78;4481390000;1096.78
2010-01-22;1115.49;1115.49;1090.18;1091.76;6208650000;1091.76
2010-01-21;1138.68;1141.58;1114.84;1116.48;6874289600;1116.48
2010-01-20;1147.95;1147.95;1129.25;1138.04;4810560000;1138.04
2010-01-19;1136.03;1150.45;1135.77;1150.23;4724830000;1150.23
2010-01-15;1147.72;1147.77;1131.39;1136.03;4758730000;1136.03
2010-01-14;1145.68;1150.41;1143.80;1148.46;3915200000;1148.46
2010-01-13;1137.31;1148.40;1133.18;1145.68;4170360000;1145.68
2010-01-12;1143.81;1143.81;1131.77;1136.22;4716160000;1136.22
2010-01-11;1145.96;1149.74;1142.02;1146.98;4255780000;1146.98
2010-01-08;1140.52;1145.39;1136.22;1144.98;4389590000;1144.98
2010-01-07;1136.27;1142.46;1131.32;1141.69;5270680000;1141.69
2010-01-06;1135.71;1139.19;1133.95;1137.14;4972660000;1137.14
2010-01-05;1132.66;1136.63;1129.66;1136.52;2491020000;1136.52
2010-01-04;1116.56;1133.87;1116.56;1132.99;3991400000;1132.99
2009-12-31;1126.60;1127.64;1114.81;1115.10;2076990000;1115.10
2009-12-30;1125.53;1126.42;1121.94;1126.42;2277300000;1126.42
2009-12-29;1128.55;1130.38;1126.08;1126.20;2491020000;1126.20
2009-12-28;1127.53;1130.38;1123.51;1127.78;2716400000;1127.78
2009-12-24;1121.08;1126.48;1121.08;1126.48;1267710000;1126.48
2009-12-23;1118.84;1121.58;1116.00;1120.59;3166870000;1120.59
2009-12-22;1114.51;1120.27;1114.51;1118.02;3641130000;1118.02
2009-12-21;1105.31;1117.68;1105.31;1114.05;3977340000;1114.05
2009-12-18;1097.86;1103.74;1093.88;1102.47;6325890000;1102.47
2009-12-17;1106.36;1106.36;1095.88;1096.08;7615070400;1096.08
2009-12-16;1108.61;1116.21;1107.96;1109.18;4829820000;1109.18
2009-12-15;1114.11;1114.11;1105.35;1107.93;5045100000;1107.93
2009-12-14;1107.84;1114.76;1107.84;1114.11;4548490000;1114.11
2009-12-11;1103.96;1108.50;1101.34;1106.41;3791090000;1106.41
2009-12-10;1098.69;1106.25;1098.69;1102.35;3996490000;1102.35
2009-12-09;1091.07;1097.04;1085.89;1095.95;4115410000;1095.95
2009-12-08;1103.04;1103.04;1088.61;1091.94;4748030000;1091.94
2009-12-07;1105.52;1110.72;1100.83;1103.25;4103360000;1103.25
2009-12-04;1100.43;1119.13;1096.52;1105.98;5781140000;1105.98
2009-12-03;1110.59;1117.28;1098.74;1099.92;4810030000;1099.92
2009-12-02;1109.03;1115.58;1105.29;1109.24;3941340000;1109.24
2009-12-01;1098.89;1112.28;1098.89;1108.86;4249310000;1108.86
2009-11-30;1091.07;1097.24;1086.25;1095.63;3895520000;1095.63
2009-11-27;1105.47;1105.47;1083.74;1091.49;2362910000;1091.49
2009-11-25;1106.49;1111.18;1104.75;1110.63;3036350000;1110.63
2009-11-24;1105.83;1107.56;1097.63;1105.65;3700820000;1105.65
2009-11-23;1094.86;1112.38;1094.86;1106.24;3827920000;1106.24
2009-11-20;1094.66;1094.66;1086.81;1091.38;3751230000;1091.38
2009-11-19;1106.44;1106.44;1088.40;1094.90;4178030000;1094.90
2009-11-18;1109.44;1111.10;1102.70;1109.80;4293340000;1109.80
2009-11-17;1109.22;1110.52;1102.19;1110.32;3824070000;1110.32
2009-11-16;1094.13;1113.69;1094.13;1109.30;4565850000;1109.30
2009-11-13;1087.59;1097.79;1085.33;1093.48;3792610000;1093.48
2009-11-12;1098.31;1101.97;1084.90;1087.24;4160250000;1087.24
2009-11-11;1096.04;1105.37;1093.81;1098.51;4286700000;1098.51
2009-11-10;1091.86;1096.42;1087.40;1093.01;4394770000;1093.01
2009-11-09;1072.31;1093.19;1072.31;1093.08;4460030000;1093.08
2009-11-06;1064.95;1071.48;1059.32;1069.30;4277130000;1069.30
2009-11-05;1047.30;1066.65;1047.30;1066.63;4848350000;1066.63
2009-11-04;1047.14;1061.00;1045.15;1046.50;5635510000;1046.50
2009-11-03;1040.92;1046.36;1033.94;1045.41;5487500000;1045.41
2009-11-02;1036.18;1052.18;1029.38;1042.88;6202640000;1042.88
2009-10-30;1065.41;1065.41;1033.38;1036.19;6512420000;1036.19
2009-10-29;1043.69;1066.83;1043.69;1066.11;5595040000;1066.11
2009-10-28;1061.51;1063.26;1042.19;1042.63;6600350000;1042.63
2009-10-27;1067.54;1072.48;1060.62;1063.41;5337380000;1063.41
2009-10-26;1080.36;1091.75;1065.23;1066.95;6363380000;1066.95
2009-10-23;1095.62;1095.83;1075.49;1079.60;4767460000;1079.60
2009-10-22;1080.96;1095.21;1074.31;1092.91;5192410000;1092.91
2009-10-21;1090.36;1101.36;1080.77;1081.40;5616290000;1081.40
2009-10-20;1098.64;1098.64;1086.16;1091.06;5396930000;1091.06
2009-10-19;1088.22;1100.17;1086.48;1097.91;4619240000;1097.91
2009-10-16;1094.67;1094.67;1081.53;1087.68;4894740000;1087.68
2009-10-15;1090.36;1096.56;1086.41;1096.56;5369780000;1096.56
2009-10-14;1078.68;1093.17;1078.68;1092.02;5406420000;1092.02
2009-10-13;1074.96;1075.30;1066.71;1073.19;4320480000;1073.19
2009-10-12;1071.63;1079.46;1071.63;1076.19;3710430000;1076.19
2009-10-09;1065.28;1071.51;1063.00;1071.49;3763780000;1071.49
2009-10-08;1060.03;1070.67;1060.03;1065.48;4988400000;1065.48
2009-10-07;1053.65;1058.02;1050.10;1057.58;4238220000;1057.58
2009-10-06;1042.02;1060.55;1042.02;1054.72;5029840000;1054.72
2009-10-05;1026.87;1042.58;1025.92;1040.46;4313310000;1040.46
2009-10-02;1029.71;1030.60;1019.95;1025.21;5583240000;1025.21
2009-10-01;1054.91;1054.91;1029.45;1029.85;5791450000;1029.85
2009-09-30;1061.02;1063.40;1046.47;1057.08;5998860000;1057.08
2009-09-29;1063.69;1069.62;1057.83;1060.61;4949900000;1060.61
2009-09-28;1045.38;1065.13;1045.38;1062.98;3726950000;1062.98
2009-09-25;1049.48;1053.47;1041.17;1044.38;4507090000;1044.38
2009-09-24;1062.56;1066.29;1045.85;1050.78;5505610000;1050.78
2009-09-23;1072.69;1080.15;1060.39;1060.87;5531930000;1060.87
2009-09-22;1066.35;1073.81;1066.35;1071.66;5246600000;1071.66
2009-09-21;1067.14;1067.28;1057.46;1064.66;4615280000;1064.66
2009-09-18;1066.60;1071.52;1064.27;1068.30;5607970000;1068.30
2009-09-17;1067.87;1074.77;1061.20;1065.49;6668110000;1065.49
2009-09-16;1053.99;1068.76;1052.87;1068.76;6793529600;1068.76
2009-09-15;1049.03;1056.04;1043.42;1052.63;6185620000;1052.63
2009-09-14;1040.15;1049.74;1035.00;1049.34;4979610000;1049.34
2009-09-11;1043.92;1048.18;1038.40;1042.73;4922600000;1042.73
2009-09-10;1032.99;1044.14;1028.04;1044.14;5191380000;1044.14
2009-09-09;1025.36;1036.34;1023.97;1033.37;5202550000;1033.37
2009-09-08;1018.67;1026.07;1018.67;1025.39;5235160000;1025.39
2009-09-04;1003.84;1016.48;1001.65;1016.40;4097370000;1016.40
2009-09-03;996.12;1003.43;992.25;1003.24;4624280000;1003.24
2009-09-02;996.07;1000.34;991.97;994.75;5842730000;994.75
2009-09-01;1019.52;1028.45;996.28;998.04;6862360000;998.04
2009-08-31;1025.21;1025.21;1014.62;1020.62;5004560000;1020.62
2009-08-28;1031.62;1039.47;1023.13;1028.93;5785780000;1028.93
2009-08-27;1027.81;1033.33;1016.20;1030.98;5785880000;1030.98
2009-08-26;1027.35;1032.47;1021.57;1028.12;5080060000;1028.12
2009-08-25;1026.63;1037.75;1026.21;1028.00;5768740000;1028.00
2009-08-24;1026.59;1035.82;1022.48;1025.57;6302450000;1025.57
2009-08-21;1009.06;1027.59;1009.06;1026.13;5885550000;1026.13
2009-08-20;996.41;1008.92;996.39;1007.37;4893160000;1007.37
2009-08-19;986.88;999.61;980.62;996.46;4257000000;996.46
2009-08-18;980.62;991.20;980.62;989.67;4198970000;989.67
2009-08-17;998.18;998.18;978.51;979.73;4088570000;979.73
2009-08-14;1012.23;1012.60;994.60;1004.09;4940750000;1004.09
2009-08-13;1005.86;1013.14;1000.82;1012.73;5250660000;1012.73
2009-08-12;994.00;1012.78;993.36;1005.81;5498170000;1005.81
2009-08-11;1005.77;1005.77;992.40;994.35;5773160000;994.35
2009-08-10;1008.89;1010.12;1000.99;1007.10;5406080000;1007.10
2009-08-07;999.83;1018.00;999.83;1010.48;6827089600;1010.48
2009-08-06;1004.06;1008.00;992.49;997.08;6753380000;997.08
2009-08-05;1005.41;1006.64;994.31;1002.72;7242120000;1002.72
2009-08-04;1001.41;1007.12;996.68;1005.65;5713700000;1005.65
2009-08-03;990.22;1003.61;990.22;1002.63;5603440000;1002.63
2009-07-31;986.80;993.18;982.85;987.48;5139070000;987.48
2009-07-30;976.01;996.68;976.01;986.75;6035180000;986.75
2009-07-29;977.66;977.76;968.65;975.15;5178770000;975.15
2009-07-28;981.48;982.35;969.35;979.62;5490350000;979.62
2009-07-27;978.63;982.49;972.29;982.18;4631290000;982.18
2009-07-24;972.16;979.79;965.95;979.26;4458300000;979.26
2009-07-23;954.07;979.42;953.27;976.29;5761650000;976.29
2009-07-22;953.40;959.83;947.75;954.07;4634100000;954.07
2009-07-21;951.97;956.53;943.22;954.58;5309300000;954.58
2009-07-20;942.07;951.62;940.99;951.13;4853150000;951.13
2009-07-17;940.56;941.89;934.65;940.38;5141380000;940.38
2009-07-16;930.17;943.96;927.45;940.74;4898640000;940.74
2009-07-15;910.15;933.95;910.15;932.68;5238830000;932.68
2009-07-14;900.77;905.84;896.50;905.84;4149030000;905.84
2009-07-13;879.57;901.05;875.32;901.05;4499440000;901.05
2009-07-10;880.03;883.57;872.81;879.13;3912080000;879.13
2009-07-09;881.28;887.86;878.45;882.68;4347170000;882.68
2009-07-08;881.90;886.80;869.32;879.56;5721780000;879.56
2009-07-07;898.60;898.60;879.93;881.03;4673300000;881.03
2009-07-06;894.27;898.72;886.36;898.72;4712580000;898.72
2009-07-02;921.24;921.24;896.42;896.42;3931000000;896.42
2009-07-01;920.82;931.92;920.82;923.33;3919400000;923.33
2009-06-30;927.15;930.01;912.86;919.32;4627570000;919.32
2009-06-29;919.86;927.99;916.18;927.23;4211760000;927.23
2009-06-26;918.84;922.00;913.03;918.90;6076660000;918.90
2009-06-25;899.45;921.42;896.27;920.26;4911240000;920.26
2009-06-24;896.31;910.85;896.31;900.94;4636720000;900.94
2009-06-23;893.46;898.69;888.86;895.10;5071020000;895.10
2009-06-22;918.13;918.13;893.04;893.04;4903940000;893.04
2009-06-19;919.96;927.09;915.80;921.23;5713390000;921.23
2009-06-18;910.86;921.93;907.94;918.37;4684010000;918.37
2009-06-17;911.89;918.44;903.78;910.71;5523650000;910.71
2009-06-16;925.60;928.00;911.60;911.97;4951200000;911.97
2009-06-15;942.45;942.45;919.65;923.72;4697880000;923.72
2009-06-12;943.44;946.30;935.66;946.21;4528120000;946.21
2009-06-11;939.04;956.23;939.04;944.89;5500840000;944.89
2009-06-10;942.73;949.77;927.97;939.15;5379420000;939.15
2009-06-09;940.35;946.92;936.15;942.43;4439950000;942.43
2009-06-08;938.12;946.33;926.44;939.14;4483430000;939.14
2009-06-05;945.67;951.69;934.13;940.09;5277910000;940.09
2009-06-04;932.49;942.47;929.32;942.46;5352890000;942.46
2009-06-03;942.51;942.51;923.85;931.76;5323770000;931.76
2009-06-02;942.87;949.38;938.46;944.74;5987340000;944.74
2009-06-01;923.26;947.77;923.26;942.87;6370440000;942.87
2009-05-29;907.02;920.02;903.56;919.14;6050420000;919.14
2009-05-28;892.96;909.45;887.60;906.83;5738980000;906.83
2009-05-27;909.95;913.84;891.87;893.06;5698800000;893.06
2009-05-26;887.00;911.76;881.46;910.33;5667050000;910.33
2009-05-22;888.68;896.65;883.75;887.00;5155320000;887.00
2009-05-21;900.42;900.42;879.61;888.33;6019840000;888.33
2009-05-20;908.62;924.60;901.37;903.47;8205060000;903.47
2009-05-19;909.67;916.39;905.22;908.13;6616270000;908.13
2009-05-18;886.07;910.00;886.07;909.71;5702150000;909.71
2009-05-15;892.76;896.97;878.94;882.88;5439720000;882.88
2009-05-14;884.24;898.36;882.52;893.07;6134870000;893.07
2009-05-13;905.40;905.40;882.80;883.92;7091820000;883.92
2009-05-12;910.52;915.57;896.46;908.35;6871750400;908.35
2009-05-11;922.99;922.99;908.68;909.24;6150600000;909.24
2009-05-08;909.03;930.17;909.03;929.23;8163280000;929.23
2009-05-07;919.58;929.58;901.36;907.39;9120100000;907.39
2009-05-06;903.95;920.28;903.95;919.53;8555040000;919.53
2009-05-05;906.10;907.70;897.34;903.80;6882860000;903.80
2009-05-04;879.21;907.85;879.21;907.24;7038840000;907.24
2009-05-01;872.74;880.48;866.10;877.52;5312170000;877.52
2009-04-30;876.59;888.70;868.51;872.81;6862540000;872.81
2009-04-29;856.85;882.06;856.85;873.64;6101620000;873.64
2009-04-28;854.48;864.48;847.12;855.16;6328000000;855.16
2009-04-27;862.82;868.83;854.65;857.51;5613460000;857.51
2009-04-24;853.91;871.80;853.91;866.23;7114440000;866.23
2009-04-23;844.62;852.87;835.45;851.92;6563100000;851.92
2009-04-22;847.26;861.78;840.57;843.55;7327860000;843.55
2009-04-21;831.25;850.09;826.83;850.08;7436489600;850.08
2009-04-20;868.27;868.27;832.39;832.39;6973960000;832.39
2009-04-17;865.18;875.63;860.87;869.60;7352009600;869.60
2009-04-16;854.54;870.35;847.04;865.30;6598670000;865.30
2009-04-15;839.44;852.93;835.58;852.06;6241100000;852.06
2009-04-14;856.88;856.88;840.25;841.50;7569840000;841.50
2009-04-13;855.33;864.31;845.35;858.73;6434890000;858.73
2009-04-09;829.29;856.91;829.29;856.56;7600710400;856.56
2009-04-08;816.76;828.42;814.84;825.16;5938460000;825.16
2009-04-07;834.12;834.12;814.53;815.55;5155580000;815.55
2009-04-06;839.75;839.75;822.79;835.48;6210000000;835.48
2009-04-03;835.13;842.50;826.70;842.50;5855640000;842.50
2009-04-02;814.53;845.61;814.53;834.38;7542809600;834.38
2009-04-01;793.59;813.62;783.32;811.08;6034140000;811.08
2009-03-31;790.88;810.48;790.88;797.87;6089100000;797.87
2009-03-30;809.07;809.07;779.81;787.53;5912660000;787.53
2009-03-27;828.68;828.68;813.43;815.94;5600210000;815.94
2009-03-26;814.06;832.98;814.06;832.86;6992960000;832.86
2009-03-25;806.81;826.78;791.37;813.88;7687180000;813.88
2009-03-24;820.60;823.65;805.48;806.12;6767980000;806.12
2009-03-23;772.31;823.37;772.31;822.92;7715769600;822.92
2009-03-20;784.58;788.91;766.20;768.54;7643720000;768.54
2009-03-19;797.92;803.24;781.82;784.04;9033870400;784.04
2009-03-18;776.01;803.04;765.64;794.35;9098449600;794.35
2009-03-17;753.88;778.12;749.93;778.12;6156800000;778.12
2009-03-16;758.84;774.53;753.37;753.89;7883540000;753.89
2009-03-13;751.97;758.29;742.46;756.55;6787089600;756.55
2009-03-12;720.89;752.63;714.76;750.74;7326630400;750.74
2009-03-11;719.59;731.92;713.85;721.36;7287809600;721.36
2009-03-10;679.28;719.60;679.28;719.60;8618329600;719.60
2009-03-09;680.76;695.27;672.88;676.53;7277320000;676.53
2009-03-06;684.04;699.09;666.79;683.38;7331830400;683.38
2009-03-05;708.27;708.27;677.93;682.55;7507249600;682.55
2009-03-04;698.60;724.12;698.60;712.87;7673620000;712.87
2009-03-03;704.44;711.67;692.30;696.33;7583230400;696.33
2009-03-02;729.57;729.57;699.70;700.82;7868289600;700.82
2009-02-27;749.93;751.27;734.52;735.09;8926480000;735.09
2009-02-26;765.76;779.42;751.75;752.83;7599969600;752.83
2009-02-25;770.64;780.12;752.89;764.90;7483640000;764.90
2009-02-24;744.69;775.49;744.69;773.14;7234489600;773.14
2009-02-23;773.25;777.85;742.37;743.33;6509300000;743.33
2009-02-20;775.87;778.69;754.25;770.05;8210590400;770.05
2009-02-19;787.91;797.58;777.03;778.94;5746940000;778.94
2009-02-18;791.06;796.17;780.43;788.42;5740710000;788.42
2009-02-17;818.61;818.61;789.17;789.17;5907820000;789.17
2009-02-13;833.95;839.43;825.21;826.84;5296650000;826.84
2009-02-12;829.91;835.48;808.06;835.19;6476460000;835.19
2009-02-11;827.41;838.22;822.30;833.74;5926460000;833.74
2009-02-10;866.87;868.05;822.99;827.16;6770169600;827.16
2009-02-09;868.24;875.01;861.65;869.89;5574370000;869.89
2009-02-06;846.09;870.75;845.42;868.60;6484100000;868.60
2009-02-05;831.75;850.55;819.91;845.85;6624030000;845.85
2009-02-04;837.77;851.85;829.18;832.23;6420450000;832.23
2009-02-03;825.69;842.60;821.98;838.51;5886310000;838.51
2009-02-02;823.09;830.78;812.87;825.44;5673270000;825.44
2009-01-30;845.69;851.66;821.67;825.88;5350580000;825.88
2009-01-29;868.89;868.89;844.15;845.14;5067060000;845.14
2009-01-28;845.73;877.86;845.73;874.09;6199180000;874.09
2009-01-27;837.30;850.45;835.40;845.71;5353260000;845.71
2009-01-26;832.50;852.53;827.69;836.57;6039940000;836.57
2009-01-23;822.16;838.61;806.07;831.95;5832160000;831.95
2009-01-22;839.74;839.74;811.29;827.50;5843830000;827.50
2009-01-21;806.77;841.72;804.30;840.24;6467830000;840.24
2009-01-20;849.64;849.64;804.47;805.22;6375230000;805.22
2009-01-16;844.45;858.13;830.66;850.12;6786040000;850.12
2009-01-15;841.99;851.59;817.04;843.74;7807350400;843.74
2009-01-14;867.28;867.28;836.93;842.62;5407880000;842.62
2009-01-13;869.79;877.02;862.02;871.79;5017470000;871.79
2009-01-12;890.40;890.40;864.32;870.26;4725050000;870.26
2009-01-09;909.91;911.93;888.31;890.35;4716500000;890.35
2009-01-08;905.73;910.00;896.81;909.73;4991550000;909.73
2009-01-07;927.45;927.45;902.37;906.65;4704940000;906.65
2009-01-06;931.17;943.85;927.28;934.70;5392620000;934.70
2009-01-05;929.17;936.63;919.53;927.45;5413910000;927.45
2009-01-02;902.99;934.73;899.35;931.80;4048270000;931.80
2008-12-31;890.59;910.32;889.67;903.25;4172940000;903.25
2008-12-30;870.58;891.12;870.58;890.64;3627800000;890.64
2008-12-29;872.37;873.70;857.07;869.42;3323430000;869.42
2008-12-26;869.51;873.74;866.52;872.80;1880050000;872.80
2008-12-24;863.87;869.79;861.44;868.15;1546550000;868.15
2008-12-23;874.31;880.44;860.10;863.16;4051970000;863.16
2008-12-22;887.20;887.37;857.09;871.63;4869850000;871.63
2008-12-19;886.96;905.47;883.02;887.88;6705310000;887.88
2008-12-18;905.98;911.02;877.44;885.28;5675000000;885.28
2008-12-17;908.16;918.85;895.94;904.42;5907380000;904.42
2008-12-16;871.53;914.66;871.53;913.18;6009780000;913.18
2008-12-15;881.07;884.63;857.72;868.57;4982390000;868.57
2008-12-12;871.79;883.24;851.35;879.73;5959590000;879.73
2008-12-11;898.35;904.63;868.73;873.59;5513840000;873.59
2008-12-10;892.17;908.27;885.45;899.24;5942130000;899.24
2008-12-09;906.48;916.26;885.38;888.67;5693110000;888.67
2008-12-08;882.71;918.57;882.71;909.70;6553600000;909.70
2008-12-05;844.43;879.42;818.41;876.07;6165370000;876.07
2008-12-04;869.75;875.60;833.60;845.22;5860390000;845.22
2008-12-03;843.60;873.12;827.60;870.74;6221880000;870.74
2008-12-02;817.94;850.54;817.94;848.81;6170100000;848.81
2008-12-01;888.61;888.61;815.69;816.21;6052010000;816.21
2008-11-28;886.89;896.25;881.21;896.24;2740860000;896.24
2008-11-26;852.90;887.68;841.37;887.68;5793260000;887.68
2008-11-25;853.40;868.94;834.99;857.39;6952700000;857.39
2008-11-24;801.20;865.60;801.20;851.81;7879440000;851.81
2008-11-21;755.84;801.20;741.02;800.03;9495900000;800.03
2008-11-20;805.87;820.52;747.78;752.44;9093740000;752.44
2008-11-19;859.03;864.57;806.18;806.58;6548600000;806.58
2008-11-18;852.34;865.90;826.84;859.12;6679470000;859.12
2008-11-17;873.23;882.29;848.98;850.75;4927490000;850.75
2008-11-14;904.36;916.88;869.88;873.29;5881030000;873.29
2008-11-13;853.13;913.01;818.69;911.29;7849120000;911.29
2008-11-12;893.39;893.39;850.48;852.30;5764180000;852.30
2008-11-11;917.15;917.15;884.90;898.95;4998340000;898.95
2008-11-10;936.75;951.95;907.47;919.21;4572000000;919.21
2008-11-07;907.44;931.46;906.90;930.99;4931640000;930.99
2008-11-06;952.40;952.40;899.73;904.88;6102230000;904.88
2008-11-05;1001.84;1001.84;949.86;952.77;5426640000;952.77
2008-11-04;971.31;1007.51;971.31;1005.75;5531290000;1005.75
2008-11-03;968.67;975.57;958.82;966.30;4492280000;966.30
2008-10-31;953.11;984.38;944.59;968.75;6394350000;968.75
2008-10-30;939.38;963.23;928.50;954.09;6175830000;954.09
2008-10-29;939.51;969.97;922.26;930.09;7077800000;930.09
2008-10-28;848.92;940.51;845.27;940.51;7096950400;940.51
2008-10-27;874.28;893.78;846.75;848.92;5558050000;848.92
2008-10-24;895.22;896.30;852.85;876.77;6550050000;876.77
2008-10-23;899.08;922.83;858.44;908.11;7184180000;908.11
2008-10-22;951.67;951.67;875.81;896.78;6147980000;896.78
2008-10-21;980.40;985.44;952.47;955.05;5121830000;955.05
2008-10-20;943.51;985.40;943.51;985.40;5175640000;985.40
2008-10-17;942.29;984.64;918.74;940.55;6581780000;940.55
2008-10-16;909.53;947.71;865.83;946.43;7984500000;946.43
2008-10-15;994.60;994.60;903.99;907.84;6542330000;907.84
2008-10-14;1009.97;1044.31;972.07;998.01;8161990400;998.01
2008-10-13;912.75;1006.93;912.75;1003.35;7263369600;1003.35
2008-10-10;902.31;936.36;839.80;899.22;11456230400;899.22
2008-10-09;988.42;1005.25;909.19;909.92;6819000000;909.92
2008-10-08;988.91;1021.06;970.97;984.94;8716329600;984.94
2008-10-07;1057.60;1072.91;996.23;996.23;7069209600;996.23
2008-10-06;1097.56;1097.56;1007.97;1056.89;7956020000;1056.89
2008-10-03;1115.16;1153.82;1098.14;1099.23;6716120000;1099.23
2008-10-02;1160.64;1160.64;1111.43;1114.28;6285640000;1114.28
2008-10-01;1164.17;1167.03;1140.77;1161.06;5782130000;1161.06
2008-09-30;1113.78;1168.03;1113.78;1166.36;4937680000;1166.36
2008-09-29;1209.07;1209.07;1106.42;1106.42;7305060000;1106.42
2008-09-26;1204.47;1215.77;1187.54;1213.27;5383610000;1213.27
2008-09-25;1187.87;1220.03;1187.87;1209.18;5877640000;1209.18
2008-09-24;1188.79;1197.41;1179.79;1185.87;4820360000;1185.87
2008-09-23;1207.61;1221.15;1187.06;1188.22;5185730000;1188.22
2008-09-22;1255.37;1255.37;1205.61;1207.09;5332130000;1207.09
2008-09-19;1213.11;1265.12;1213.11;1255.08;9387169600;1255.08
2008-09-18;1157.08;1211.14;1133.50;1206.51;10082689600;1206.51
2008-09-17;1210.34;1210.34;1155.88;1156.39;9431870400;1156.39
2008-09-16;1188.31;1214.84;1169.28;1213.60;9459830400;1213.60
2008-09-15;1250.92;1250.92;1192.70;1192.70;8279510400;1192.70
2008-09-12;1245.88;1255.09;1233.81;1251.70;6273260000;1251.70
2008-09-11;1229.04;1249.98;1211.54;1249.05;6869249600;1249.05
2008-09-10;1227.50;1243.90;1221.60;1232.04;6543440000;1232.04
2008-09-09;1267.98;1268.66;1224.51;1224.51;7380630400;1224.51
2008-09-08;1249.50;1274.42;1247.12;1267.79;7351340000;1267.79
2008-09-05;1233.21;1244.94;1217.23;1242.31;5017080000;1242.31
2008-09-04;1271.80;1271.80;1232.83;1236.83;5212500000;1236.83
2008-09-03;1276.61;1280.60;1265.59;1274.98;5056980000;1274.98
2008-09-02;1287.83;1303.04;1272.20;1277.58;4783560000;1277.58
2008-08-29;1296.49;1297.59;1282.74;1282.83;3288120000;1282.83
2008-08-28;1283.79;1300.68;1283.79;1300.68;3854280000;1300.68
2008-08-27;1271.29;1285.05;1270.03;1281.66;3499610000;1281.66
2008-08-26;1267.03;1275.65;1263.21;1271.51;3587570000;1271.51
2008-08-25;1290.47;1290.47;1264.87;1266.84;3420600000;1266.84
2008-08-22;1277.59;1293.09;1277.59;1292.20;3741070000;1292.20
2008-08-21;1271.07;1281.40;1265.22;1277.72;4032590000;1277.72
2008-08-20;1267.34;1276.01;1261.16;1274.54;4555030000;1274.54
2008-08-19;1276.65;1276.65;1263.11;1266.69;4159760000;1266.69
2008-08-18;1298.14;1300.22;1274.51;1278.60;3829290000;1278.60
2008-08-15;1293.85;1302.05;1290.74;1298.20;4041820000;1298.20
2008-08-14;1282.11;1300.11;1276.84;1292.93;4064000000;1292.93
2008-08-13;1288.64;1294.03;1274.86;1285.83;4787600000;1285.83
2008-08-12;1304.79;1304.79;1285.64;1289.59;4711290000;1289.59
2008-08-11;1294.42;1313.15;1291.41;1305.32;5067310000;1305.32
2008-08-08;1266.29;1297.85;1262.11;1296.32;4966810000;1296.32
2008-08-07;1286.51;1286.51;1264.29;1266.07;5319380000;1266.07
2008-08-06;1283.99;1291.67;1276.00;1289.19;4873420000;1289.19
2008-08-05;1254.87;1284.88;1254.67;1284.88;1219310000;1284.88
2008-08-04;1253.27;1260.49;1247.45;1249.01;4562280000;1249.01
2008-08-01;1269.42;1270.52;1254.54;1260.31;4684870000;1260.31
2008-07-31;1281.37;1284.93;1265.97;1267.38;5346050000;1267.38
2008-07-30;1264.52;1284.33;1264.52;1284.26;5631330000;1284.26
2008-07-29;1236.38;1263.20;1236.38;1263.20;5414240000;1263.20
2008-07-28;1257.76;1260.09;1234.37;1234.37;4282960000;1234.37
2008-07-25;1253.51;1263.23;1251.75;1257.76;4672560000;1257.76
2008-07-24;1283.22;1283.22;1251.48;1252.54;6127980000;1252.54
2008-07-23;1278.87;1291.17;1276.06;1282.19;6705830000;1282.19
2008-07-22;1257.08;1277.42;1248.83;1277.00;6180230000;1277.00
2008-07-21;1261.82;1267.74;1255.70;1260.00;4630640000;1260.00
2008-07-18;1258.22;1262.23;1251.81;1260.68;5653280000;1260.68
2008-07-17;1246.31;1262.31;1241.49;1260.32;7365209600;1260.32
2008-07-16;1214.65;1245.52;1211.39;1245.36;6738630400;1245.36
2008-07-15;1226.83;1234.35;1200.44;1214.91;7363640000;1214.91
2008-07-14;1241.61;1253.50;1225.01;1228.30;5434860000;1228.30
2008-07-11;1248.66;1257.27;1225.35;1239.49;6742200000;1239.49
2008-07-10;1245.25;1257.65;1236.76;1253.39;5840430000;1253.39
2008-07-09;1273.38;1277.36;1244.57;1244.69;5181000000;1244.69
2008-07-08;1251.84;1274.17;1242.84;1273.70;6034110000;1273.70
2008-07-07;1262.90;1273.95;1240.68;1252.31;5265420000;1252.31
2008-07-03;1262.96;1271.48;1252.01;1262.90;3247590000;1262.90
2008-07-02;1285.82;1292.17;1261.51;1261.52;5276090000;1261.52
2008-07-01;1276.69;1285.31;1260.68;1284.91;5846290000;1284.91
2008-06-30;1278.06;1290.31;1274.86;1280.00;5032330000;1280.00
2008-06-27;1283.60;1289.45;1272.00;1278.38;6208260000;1278.38
2008-06-26;1316.29;1316.29;1283.15;1283.15;5231280000;1283.15
2008-06-25;1314.54;1335.63;1314.54;1321.97;4825640000;1321.97
2008-06-24;1317.23;1326.02;1304.42;1314.29;4705050000;1314.29
2008-06-23;1319.77;1323.78;1315.31;1318.00;4186370000;1318.00
2008-06-20;1341.02;1341.02;1314.46;1317.93;5324900000;1317.93
2008-06-19;1336.89;1347.66;1330.50;1342.83;4811670000;1342.83
2008-06-18;1349.59;1349.59;1333.40;1337.81;4573570000;1337.81
2008-06-17;1360.71;1366.59;1350.54;1350.93;3801960000;1350.93
2008-06-16;1358.85;1364.70;1352.07;1360.14;3706940000;1360.14
2008-06-13;1341.81;1360.03;1341.71;1360.03;4080420000;1360.03
2008-06-12;1335.78;1353.03;1331.29;1339.87;4734240000;1339.87
2008-06-11;1357.09;1357.09;1335.47;1335.49;4779980000;1335.49
2008-06-10;1358.98;1366.84;1351.56;1358.44;4635070000;1358.44
2008-06-09;1360.83;1370.63;1350.62;1361.76;4404570000;1361.76
2008-06-06;1400.06;1400.06;1359.90;1360.68;4771660000;1360.68
2008-06-05;1377.48;1404.05;1377.48;1404.05;4350790000;1404.05
2008-06-04;1376.26;1388.18;1371.74;1377.20;4338640000;1377.20
2008-06-03;1386.42;1393.12;1370.12;1377.65;4396380000;1377.65
2008-06-02;1399.62;1399.62;1377.79;1385.67;3714320000;1385.67
2008-05-30;1398.36;1404.46;1398.08;1400.38;3845630000;1400.38
2008-05-29;1390.50;1406.32;1388.59;1398.26;3894440000;1398.26
2008-05-28;1386.54;1391.25;1378.16;1390.84;3927240000;1390.84
2008-05-27;1375.97;1387.40;1373.07;1385.35;3588860000;1385.35
2008-05-23;1392.20;1392.20;1373.72;1375.93;3516380000;1375.93
2008-05-22;1390.83;1399.07;1390.23;1394.35;3955960000;1394.35
2008-05-21;1414.06;1419.12;1388.81;1390.71;4517990000;1390.71
2008-05-20;1424.49;1424.49;1409.09;1413.40;3854320000;1413.40
2008-05-19;1425.28;1440.24;1421.63;1426.63;3683970000;1426.63
2008-05-16;1423.89;1425.82;1414.35;1425.35;3842590000;1425.35
2008-05-15;1408.36;1424.40;1406.87;1423.57;3836480000;1423.57
2008-05-14;1405.65;1420.19;1405.65;1408.66;3979370000;1408.66
2008-05-13;1404.40;1406.30;1396.26;1403.04;4018590000;1403.04
2008-05-12;1389.40;1404.06;1386.20;1403.58;3370630000;1403.58
2008-05-09;1394.90;1394.90;1384.11;1388.28;3518620000;1388.28
2008-05-08;1394.29;1402.35;1389.39;1397.68;3827550000;1397.68
2008-05-07;1417.49;1419.54;1391.16;1392.57;4075860000;1392.57
2008-05-06;1405.60;1421.57;1397.10;1418.26;3924100000;1418.26
2008-05-05;1415.34;1415.34;1404.37;1407.49;3410090000;1407.49
2008-05-02;1409.16;1422.72;1406.25;1413.90;3953030000;1413.90
2008-05-01;1385.97;1410.07;1383.07;1409.34;4448780000;1409.34
2008-04-30;1391.22;1404.57;1384.25;1385.59;4508890000;1385.59
2008-04-29;1395.61;1397.00;1386.70;1390.94;3815320000;1390.94
2008-04-28;1397.96;1402.90;1394.40;1396.37;3607000000;1396.37
2008-04-25;1387.88;1399.11;1379.98;1397.84;3891150000;1397.84
2008-04-24;1380.52;1397.72;1371.09;1388.82;4461660000;1388.82
2008-04-23;1378.40;1387.87;1372.24;1379.93;4103610000;1379.93
2008-04-22;1386.43;1386.43;1369.84;1375.94;3821900000;1375.94
2008-04-21;1387.72;1390.23;1379.25;1388.17;3420570000;1388.17
2008-04-18;1369.00;1395.90;1369.00;1390.33;4222380000;1390.33
2008-04-17;1363.37;1368.60;1357.25;1365.56;3713880000;1365.56
2008-04-16;1337.02;1365.49;1337.02;1364.71;4260370000;1364.71
2008-04-15;1331.72;1337.72;1324.35;1334.43;3581230000;1334.43
2008-04-14;1332.20;1335.64;1326.16;1328.32;3565020000;1328.32
2008-04-11;1357.98;1357.98;1331.21;1332.83;3723790000;1332.83
2008-04-10;1355.37;1367.24;1350.11;1360.55;3686150000;1360.55
2008-04-09;1365.50;1368.39;1349.97;1354.49;3556670000;1354.49
2008-04-08;1370.16;1370.16;1360.62;1365.54;3602500000;1365.54
2008-04-07;1373.69;1386.74;1369.02;1372.54;3747780000;1372.54
2008-04-04;1369.85;1380.91;1362.83;1370.40;3703100000;1370.40
2008-04-03;1365.69;1375.66;1358.68;1369.31;3920100000;1369.31
2008-04-02;1369.96;1377.95;1361.55;1367.53;4320440000;1367.53
2008-04-01;1326.41;1370.18;1326.41;1370.18;4745120000;1370.18
2008-03-31;1315.92;1328.52;1312.81;1322.70;4188990000;1322.70
2008-03-28;1327.02;1334.87;1312.95;1315.22;3686980000;1315.22
2008-03-27;1340.34;1345.62;1325.66;1325.76;4037930000;1325.76
2008-03-26;1352.45;1352.45;1336.41;1341.13;4055670000;1341.13
2008-03-25;1349.07;1357.47;1341.21;1352.99;4145120000;1352.99
2008-03-24;1330.29;1359.68;1330.29;1349.88;4499000000;1349.88
2008-03-20;1299.67;1330.67;1295.22;1329.51;6145220000;1329.51
2008-03-19;1330.97;1341.51;1298.42;1298.42;1203830000;1298.42
2008-03-18;1277.16;1330.74;1277.16;1330.74;5335630000;1330.74
2008-03-17;1283.21;1287.50;1256.98;1276.60;5683010000;1276.60
2008-03-14;1316.05;1321.47;1274.86;1288.14;5153780000;1288.14
2008-03-13;1305.26;1321.68;1282.11;1315.48;5073360000;1315.48
2008-03-12;1321.13;1333.26;1307.86;1308.77;4414280000;1308.77
2008-03-11;1274.40;1320.65;1274.40;1320.65;5109080000;1320.65
2008-03-10;1293.16;1295.01;1272.66;1273.37;4261240000;1273.37
2008-03-07;1301.53;1313.24;1282.43;1293.37;4565410000;1293.37
2008-03-06;1332.20;1332.20;1303.42;1304.34;4323460000;1304.34
2008-03-05;1327.69;1344.19;1320.22;1333.70;4277710000;1333.70
2008-03-04;1329.58;1331.03;1307.39;1326.75;4757180000;1326.75
2008-03-03;1330.45;1335.13;1320.04;1331.34;4117570000;1331.34
2008-02-29;1364.07;1364.07;1325.42;1330.63;4426730000;1330.63
2008-02-28;1378.16;1378.16;1363.16;1367.68;3938580000;1367.68
2008-02-27;1378.95;1388.34;1372.00;1380.02;3904700000;1380.02
2008-02-26;1371.76;1387.34;1363.29;1381.29;4096060000;1381.29
2008-02-25;1352.75;1374.36;1346.03;1371.80;3866350000;1371.80
2008-02-22;1344.22;1354.30;1327.04;1353.11;3572660000;1353.11
2008-02-21;1362.21;1367.94;1339.34;1342.53;3696660000;1342.53
2008-02-20;1348.39;1363.71;1336.55;1360.03;3870520000;1360.03
2008-02-19;1355.86;1367.28;1345.05;1348.78;3613550000;1348.78
2008-02-15;1347.52;1350.00;1338.13;1349.99;3583300000;1349.99
2008-02-14;1367.33;1368.16;1347.31;1348.86;3644760000;1348.86
2008-02-13;1353.12;1369.23;1350.78;1367.21;3856420000;1367.21
2008-02-12;1340.55;1362.10;1339.36;1348.86;4044640000;1348.86
2008-02-11;1331.92;1341.40;1320.32;1339.13;3593140000;1339.13
2008-02-08;1336.88;1341.22;1321.06;1331.29;3768490000;1331.29
2008-02-07;1324.01;1347.16;1316.75;1336.91;4589160000;1336.91
2008-02-06;1339.48;1351.96;1324.34;1326.45;4008120000;1326.45
2008-02-05;1380.28;1380.28;1336.64;1336.64;4315740000;1336.64
2008-02-04;1395.38;1395.38;1379.69;1380.82;3495780000;1380.82
2008-02-01;1378.60;1396.02;1375.93;1395.42;4650770000;1395.42
2008-01-31;1351.98;1385.62;1334.08;1378.55;4970290000;1378.55
2008-01-30;1362.22;1385.86;1352.95;1355.81;4742760000;1355.81
2008-01-29;1355.94;1364.93;1350.19;1362.30;4232960000;1362.30
2008-01-28;1330.70;1353.97;1322.26;1353.96;4100930000;1353.96
2008-01-25;1357.32;1368.56;1327.50;1330.61;4882250000;1330.61
2008-01-24;1340.13;1355.15;1334.31;1352.07;5735300000;1352.07
2008-01-23;1310.41;1339.09;1270.05;1338.60;3241680000;1338.60
2008-01-22;1312.94;1322.09;1274.29;1310.50;6544690000;1310.50
2008-01-18;1333.90;1350.28;1312.51;1325.19;6004840000;1325.19
2008-01-17;1374.79;1377.72;1330.67;1333.25;5303130000;1333.25
2008-01-16;1377.41;1391.99;1364.27;1373.20;5440620000;1373.20
2008-01-15;1411.88;1411.88;1380.60;1380.95;4601640000;1380.95
2008-01-14;1402.91;1417.89;1402.91;1416.25;3682090000;1416.25
2008-01-11;1419.91;1419.91;1394.83;1401.02;4495840000;1401.02
2008-01-10;1406.78;1429.09;1395.31;1420.33;5170490000;1420.33
2008-01-09;1390.25;1409.19;1378.70;1409.13;5351030000;1409.13
2008-01-08;1415.71;1430.28;1388.30;1390.19;4705390000;1390.19
2008-01-07;1414.07;1423.87;1403.45;1416.18;4221260000;1416.18
2008-01-04;1444.01;1444.01;1411.19;1411.63;4166000000;1411.63
2008-01-03;1447.55;1456.80;1443.73;1447.16;3429500000;1447.16
2008-01-02;1467.97;1471.77;1442.07;1447.16;3452650000;1447.16
2007-12-31;1475.25;1475.83;1465.13;1468.36;2440880000;1468.36
2007-12-28;1479.83;1488.01;1471.70;1478.49;2420510000;1478.49
2007-12-27;1495.05;1495.05;1475.86;1476.27;2365770000;1476.27
2007-12-26;1495.12;1498.85;1488.20;1497.66;2010500000;1497.66
2007-12-24;1484.55;1497.63;1484.55;1496.45;1267420000;1496.45
2007-12-21;1463.19;1485.40;1463.19;1484.46;4508590000;1484.46
2007-12-20;1456.42;1461.53;1447.22;1460.12;3526890000;1460.12
2007-12-19;1454.70;1464.42;1445.31;1453.00;3401300000;1453.00
2007-12-18;1445.92;1460.16;1435.65;1454.98;3723690000;1454.98
2007-12-17;1465.05;1465.05;1445.43;1445.90;3569030000;1445.90
2007-12-14;1486.19;1486.67;1467.78;1467.95;3401050000;1467.95
2007-12-13;1483.27;1489.40;1469.21;1488.41;3635170000;1488.41
2007-12-12;1487.58;1511.96;1468.23;1486.59;4482120000;1486.59
2007-12-11;1516.68;1523.57;1475.99;1477.65;4080180000;1477.65
2007-12-10;1505.11;1518.27;1504.96;1515.96;2911760000;1515.96
2007-12-07;1508.60;1510.63;1502.66;1504.66;3177710000;1504.66
2007-12-06;1484.59;1508.02;1482.19;1507.34;3568570000;1507.34
2007-12-05;1465.22;1486.09;1465.22;1485.01;3663660000;1485.01
2007-12-04;1471.34;1471.34;1460.66;1462.79;3343620000;1462.79
2007-12-03;1479.63;1481.16;1470.08;1472.42;3323250000;1472.42
2007-11-30;1471.83;1488.94;1470.89;1481.14;4422200000;1481.14
2007-11-29;1467.41;1473.81;1458.36;1469.72;3524730000;1469.72
2007-11-28;1432.95;1471.62;1432.95;1469.02;4508020000;1469.02
2007-11-27;1409.59;1429.49;1407.43;1428.23;4320720000;1428.23
2007-11-26;1440.74;1446.09;1406.10;1407.22;3706470000;1407.22
2007-11-23;1417.62;1440.86;1417.62;1440.70;1612720000;1440.70
2007-11-21;1434.71;1436.40;1415.64;1416.77;4076230000;1416.77
2007-11-20;1434.51;1452.64;1419.28;1439.70;4875150000;1439.70
2007-11-19;1456.70;1456.70;1430.42;1433.27;4119650000;1433.27
2007-11-16;1453.09;1462.18;1443.99;1458.74;4168870000;1458.74
2007-11-15;1468.04;1472.67;1443.49;1451.15;3941010000;1451.15
2007-11-14;1483.40;1492.14;1466.47;1470.58;4031470000;1470.58
2007-11-13;1441.35;1481.37;1441.35;1481.05;4141310000;1481.05
2007-11-12;1453.66;1464.94;1438.53;1439.18;4192520000;1439.18
2007-11-09;1467.59;1474.09;1448.51;1453.70;4587050000;1453.70
2007-11-08;1475.27;1482.50;1450.31;1474.77;5439720000;1474.77
2007-11-07;1515.46;1515.46;1475.04;1475.62;4353160000;1475.62
2007-11-06;1505.33;1520.77;1499.07;1520.27;3879160000;1520.27
2007-11-05;1505.61;1510.84;1489.95;1502.17;3819330000;1502.17
2007-11-02;1511.07;1513.15;1492.53;1509.65;4285990000;1509.65
2007-11-01;1545.79;1545.79;1506.66;1508.44;4241470000;1508.44
2007-10-31;1532.15;1552.76;1529.40;1549.38;3953070000;1549.38
2007-10-30;1539.42;1539.42;1529.55;1531.02;3212520000;1531.02
2007-10-29;1536.92;1544.67;1536.43;1540.98;3124480000;1540.98
2007-10-26;1522.17;1535.53;1520.18;1535.28;3612120000;1535.28
2007-10-25;1516.15;1523.24;1500.46;1514.40;4183960000;1514.40
2007-10-24;1516.61;1517.23;1489.56;1515.88;4003300000;1515.88
2007-10-23;1509.30;1520.01;1503.61;1519.59;3309120000;1519.59
2007-10-22;1497.79;1508.06;1490.40;1506.33;3471830000;1506.33
2007-10-19;1540.00;1540.00;1500.26;1500.63;4160970000;1500.63
2007-10-18;1539.29;1542.79;1531.76;1540.08;3203210000;1540.08
2007-10-17;1544.44;1550.66;1526.01;1541.24;3638070000;1541.24
2007-10-16;1547.81;1547.81;1536.29;1538.53;3234560000;1538.53
2007-10-15;1562.25;1564.74;1540.81;1548.71;3139290000;1548.71
2007-10-12;1555.41;1563.03;1554.09;1561.80;2788690000;1561.80
2007-10-11;1564.72;1576.09;1546.72;1554.41;3911260000;1554.41
2007-10-10;1564.98;1565.42;1555.46;1562.47;3044760000;1562.47
2007-10-09;1553.18;1565.26;1551.82;1565.15;2932040000;1565.15
2007-10-08;1556.51;1556.51;1549.00;1552.58;2040650000;1552.58
2007-10-05;1543.84;1561.91;1543.84;1557.59;2919030000;1557.59
2007-10-04;1539.91;1544.02;1537.63;1542.84;2690430000;1542.84
2007-10-03;1545.80;1545.84;1536.34;1539.59;3065320000;1539.59
2007-10-02;1546.96;1548.01;1540.37;1546.63;3101910000;1546.63
2007-10-01;1527.29;1549.02;1527.25;1547.04;3281990000;1547.04
2007-09-28;1531.24;1533.74;1521.99;1526.75;2925350000;1526.75
2007-09-27;1527.32;1532.46;1525.81;1531.38;2872180000;1531.38
2007-09-26;1518.62;1529.39;1518.62;1525.42;3237390000;1525.42
2007-09-25;1516.34;1518.27;1507.13;1517.21;3187770000;1517.21
2007-09-24;1525.75;1530.18;1516.15;1517.73;3131310000;1517.73
2007-09-21;1518.75;1530.89;1518.75;1525.75;3679460000;1525.75
2007-09-20;1528.69;1529.14;1516.42;1518.75;2957700000;1518.75
2007-09-19;1519.75;1538.74;1519.75;1529.03;3846750000;1529.03
2007-09-18;1476.63;1519.89;1476.63;1519.78;3708940000;1519.78
2007-09-17;1484.24;1484.24;1471.82;1476.65;2598390000;1476.65
2007-09-14;1483.95;1485.99;1473.18;1484.25;2641740000;1484.25
2007-09-13;1471.47;1489.58;1471.47;1483.95;2877080000;1483.95
2007-09-12;1471.10;1479.50;1465.75;1471.56;2885720000;1471.56
2007-09-11;1451.69;1472.48;1451.69;1471.49;3015330000;1471.49
2007-09-10;1453.50;1462.25;1439.29;1451.70;2835720000;1451.70
2007-09-07;1478.55;1478.55;1449.07;1453.55;3191080000;1453.55
2007-09-06;1472.03;1481.49;1467.41;1478.55;2459590000;1478.55
2007-09-05;1488.76;1488.76;1466.34;1472.29;2991600000;1472.29
2007-09-04;1473.96;1496.40;1472.15;1489.42;2766600000;1489.42
2007-08-31;1457.61;1481.47;1457.61;1473.99;2731610000;1473.99
2007-08-30;1463.67;1468.43;1451.25;1457.64;2582960000;1457.64
2007-08-29;1432.01;1463.76;1432.01;1463.76;2824070000;1463.76
2007-08-28;1466.72;1466.72;1432.01;1432.36;3078090000;1432.36
2007-08-27;1479.36;1479.36;1465.98;1466.79;2406180000;1466.79
2007-08-24;1462.34;1479.40;1460.54;1479.37;2541400000;1479.37
2007-08-23;1464.05;1472.06;1453.88;1462.50;3084390000;1462.50
2007-08-22;1447.03;1464.86;1447.03;1464.07;3309120000;1464.07
2007-08-21;1445.55;1455.32;1439.76;1447.12;3012150000;1447.12
2007-08-20;1445.94;1451.75;1430.54;1445.55;3321340000;1445.55
2007-08-17;1411.26;1450.33;1411.26;1445.94;3570040000;1445.94
2007-08-16;1406.64;1415.97;1370.60;1411.27;6509300000;1411.27
2007-08-15;1426.15;1440.78;1404.36;1406.70;4290930000;1406.70
2007-08-14;1452.87;1456.74;1426.20;1426.54;3814630000;1426.54
2007-08-13;1453.42;1466.29;1451.54;1452.92;3696280000;1452.92
2007-08-10;1453.09;1462.02;1429.74;1453.64;5345780000;1453.64
2007-08-09;1497.21;1497.21;1453.09;1453.09;5889600000;1453.09
2007-08-08;1476.22;1503.89;1476.22;1497.49;5499560000;1497.49
2007-08-07;1467.62;1488.30;1455.80;1476.71;4909390000;1476.71
2007-08-06;1433.04;1467.67;1427.39;1467.67;5067200000;1467.67
2007-08-03;1472.18;1473.23;1432.80;1433.06;4272110000;1433.06
2007-08-02;1465.46;1476.43;1460.58;1472.20;4368850000;1472.20
2007-08-01;1455.18;1468.38;1439.59;1465.81;5256780000;1465.81
2007-07-31;1473.90;1488.30;1454.25;1455.27;4524520000;1455.27
2007-07-30;1458.93;1477.88;1454.32;1473.91;4128780000;1473.91
2007-07-27;1482.44;1488.53;1458.95;1458.95;4784650000;1458.95
2007-07-26;1518.09;1518.09;1465.30;1482.66;4472550000;1482.66
2007-07-25;1511.03;1524.31;1503.73;1518.09;4283200000;1518.09
2007-07-24;1541.57;1541.57;1508.62;1511.04;4115830000;1511.04
2007-07-23;1534.06;1547.23;1534.06;1541.57;3102700000;1541.57
2007-07-20;1553.19;1553.19;1529.20;1534.10;3745780000;1534.10
2007-07-19;1546.13;1555.20;1546.13;1553.08;3251450000;1553.08
2007-07-18;1549.20;1549.20;1533.67;1546.17;3609220000;1546.17
2007-07-17;1549.52;1555.32;1547.74;1549.37;3007140000;1549.37
2007-07-16;1552.50;1555.90;1546.69;1549.52;2704110000;1549.52
2007-07-13;1547.68;1555.10;1544.85;1552.50;2801120000;1552.50
2007-07-12;1518.74;1547.92;1518.74;1547.70;3489600000;1547.70
2007-07-11;1509.93;1519.34;1506.10;1518.76;3082920000;1518.76
2007-07-10;1531.85;1531.85;1510.01;1510.12;3244280000;1510.12
2007-07-09;1530.43;1534.26;1527.45;1531.85;2715330000;1531.85
2007-07-06;1524.96;1532.40;1520.47;1530.44;2441520000;1530.44
2007-07-05;1524.86;1526.57;1517.72;1525.40;2622950000;1525.40
2007-07-03;1519.12;1526.01;1519.12;1524.87;1560790000;1524.87
2007-07-02;1504.66;1519.45;1504.66;1519.43;2644990000;1519.43
2007-06-29;1505.70;1517.53;1493.61;1503.35;3165410000;1503.35
2007-06-28;1506.32;1514.84;1503.41;1505.71;3006710000;1505.71
2007-06-27;1492.62;1506.80;1484.18;1506.34;3398150000;1506.34
2007-06-26;1497.68;1506.12;1490.54;1492.89;3398530000;1492.89
2007-06-25;1502.56;1514.29;1492.68;1497.74;3287250000;1497.74
2007-06-22;1522.19;1522.19;1500.74;1502.56;4284320000;1502.56
2007-06-21;1512.50;1522.90;1504.75;1522.19;3161110000;1522.19
2007-06-20;1533.68;1537.32;1512.36;1512.84;3286900000;1512.84
2007-06-19;1531.02;1535.85;1525.67;1533.70;2873590000;1533.70
2007-06-18;1532.90;1535.44;1529.31;1531.05;2480240000;1531.05
2007-06-15;1522.97;1538.71;1522.97;1532.91;3406030000;1532.91
2007-06-14;1515.58;1526.45;1515.58;1522.97;2813630000;1522.97
2007-06-13;1492.65;1515.70;1492.65;1515.67;3077930000;1515.67
2007-06-12;1509.12;1511.33;1492.97;1493.00;3056200000;1493.00
2007-06-11;1507.64;1515.53;1503.35;1509.12;2525280000;1509.12
2007-06-08;1490.71;1507.76;1487.41;1507.67;2993460000;1507.67
2007-06-07;1517.36;1517.36;1490.37;1490.72;3538470000;1490.72
2007-06-06;1530.57;1530.57;1514.13;1517.38;2964190000;1517.38
2007-06-05;1539.12;1539.12;1525.62;1530.95;2939450000;1530.95
2007-06-04;1536.28;1540.53;1532.31;1539.18;2738930000;1539.18
2007-06-01;1530.62;1540.56;1530.62;1536.34;2927020000;1536.34
2007-05-31;1530.19;1535.56;1528.26;1530.62;3335530000;1530.62
2007-05-30;1517.60;1530.23;1510.06;1530.23;2980210000;1530.23
2007-05-29;1515.55;1521.80;1512.02;1518.11;2571790000;1518.11
2007-05-25;1507.50;1517.41;1507.50;1515.73;2316250000;1515.73
2007-05-24;1522.10;1529.31;1505.18;1507.51;3365530000;1507.51
2007-05-23;1524.09;1532.43;1521.90;1522.28;3084260000;1522.28
2007-05-22;1525.10;1529.24;1522.05;1524.12;2860500000;1524.12
2007-05-21;1522.75;1529.87;1522.71;1525.10;3465360000;1525.10
2007-05-18;1512.74;1522.75;1512.74;1522.75;2959050000;1522.75
2007-05-17;1514.01;1517.14;1509.29;1512.75;2868640000;1512.75
2007-05-16;1500.75;1514.15;1500.75;1514.14;2915350000;1514.14
2007-05-15;1503.11;1514.83;1500.43;1501.19;3071020000;1501.19
2007-05-14;1505.76;1510.90;1498.34;1503.15;2776130000;1503.15
2007-05-11;1491.47;1506.24;1491.47;1505.85;2720780000;1505.85
2007-05-10;1512.33;1512.33;1491.42;1491.47;3031240000;1491.47
2007-05-09;1507.32;1513.80;1503.77;1512.58;2935550000;1512.58
2007-05-08;1509.36;1509.36;1500.66;1507.72;2795720000;1507.72
2007-05-07;1505.57;1511.00;1505.54;1509.48;2545090000;1509.48
2007-05-04;1502.35;1510.34;1501.80;1505.62;2761930000;1505.62
2007-05-03;1495.56;1503.34;1495.56;1502.39;3007970000;1502.39
2007-05-02;1486.13;1499.10;1486.13;1495.92;3189800000;1495.92
2007-05-01;1482.37;1487.27;1476.70;1486.30;3400350000;1486.30
2007-04-30;1494.07;1497.16;1482.29;1482.37;3093420000;1482.37
2007-04-27;1494.21;1497.32;1488.67;1494.07;2732810000;1494.07
2007-04-26;1495.27;1498.02;1491.17;1494.25;3211800000;1494.25
2007-04-25;1480.28;1496.59;1480.28;1495.42;3252590000;1495.42
2007-04-24;1480.93;1483.82;1473.74;1480.41;3119750000;1480.41
2007-04-23;1484.33;1487.32;1480.19;1480.93;2575020000;1480.93
2007-04-20;1470.69;1484.74;1470.69;1484.35;3329940000;1484.35
2007-04-19;1472.48;1474.23;1464.47;1470.73;2913610000;1470.73
2007-04-18;1471.47;1476.57;1466.41;1472.50;2971330000;1472.50
2007-04-17;1468.47;1474.35;1467.15;1471.48;2920570000;1471.48
2007-04-16;1452.84;1468.62;1452.84;1468.33;2870140000;1468.33
2007-04-13;1447.80;1453.11;1444.15;1452.85;2690020000;1452.85
2007-04-12;1438.87;1448.02;1433.91;1447.80;2770570000;1447.80
2007-04-11;1448.23;1448.39;1436.15;1438.87;2950190000;1438.87
2007-04-10;1444.58;1448.73;1443.99;1448.39;2510110000;1448.39
2007-04-09;1443.77;1448.10;1443.28;1444.61;2349410000;1444.61
2007-04-05;1438.94;1444.88;1436.67;1443.76;2357230000;1443.76
2007-04-04;1437.75;1440.16;1435.08;1439.37;2616320000;1439.37
2007-04-03;1424.27;1440.57;1424.27;1437.77;2921760000;1437.77
2007-04-02;1420.83;1425.49;1416.37;1424.55;2875880000;1424.55
2007-03-30;1422.52;1429.22;1408.90;1420.86;2903960000;1420.86
2007-03-29;1417.17;1426.24;1413.27;1422.53;2854710000;1422.53
2007-03-28;1428.35;1428.35;1414.07;1417.23;3000440000;1417.23
2007-03-27;1437.49;1437.49;1425.54;1428.61;2673040000;1428.61
2007-03-26;1436.11;1437.65;1423.28;1437.50;2754660000;1437.50
2007-03-23;1434.54;1438.89;1433.21;1436.11;2619020000;1436.11
2007-03-22;1435.04;1437.66;1429.88;1434.54;3129970000;1434.54
2007-03-21;1410.92;1437.77;1409.75;1435.04;3184770000;1435.04
2007-03-20;1402.04;1411.53;1400.70;1410.94;2795940000;1410.94
2007-03-19;1386.95;1403.20;1386.95;1402.06;2777180000;1402.06
2007-03-16;1392.28;1397.51;1383.63;1386.95;3393640000;1386.95
2007-03-15;1387.11;1395.73;1385.16;1392.28;2821900000;1392.28
2007-03-14;1377.86;1388.09;1363.98;1387.17;3758350000;1387.17
2007-03-13;1406.23;1406.23;1377.71;1377.95;3485570000;1377.95
2007-03-12;1402.80;1409.34;1398.40;1406.60;2664000000;1406.60
2007-03-09;1401.89;1410.15;1397.30;1402.84;2623050000;1402.84
2007-03-08;1391.88;1407.93;1391.88;1401.89;3014850000;1401.89
2007-03-07;1395.02;1401.16;1390.64;1391.97;3141350000;1391.97
2007-03-06;1374.06;1397.90;1374.06;1395.41;3358160000;1395.41
2007-03-05;1387.11;1391.86;1373.97;1374.12;3480520000;1374.12
2007-03-02;1403.16;1403.40;1386.87;1387.17;3312260000;1387.17
2007-03-01;1406.80;1409.46;1380.87;1403.17;3874910000;1403.17
2007-02-28;1398.64;1415.89;1396.65;1406.82;3925250000;1406.82
2007-02-27;1449.25;1449.25;1389.42;1399.04;4065230000;1399.04
2007-02-26;1451.04;1456.95;1445.48;1449.37;2822170000;1449.37
2007-02-23;1456.22;1456.22;1448.36;1451.19;2579950000;1451.19
2007-02-22;1457.29;1461.57;1450.51;1456.38;1950770000;1456.38
2007-02-21;1459.60;1459.60;1452.02;1457.63;2606980000;1457.63
2007-02-20;1455.53;1460.53;1449.20;1459.68;2337860000;1459.68
2007-02-16;1456.77;1456.77;1451.57;1455.54;2399450000;1455.54
2007-02-15;1455.15;1457.97;1453.19;1456.81;2490920000;1456.81
2007-02-14;1443.91;1457.65;1443.91;1455.30;2699290000;1455.30
2007-02-13;1433.22;1444.41;1433.22;1444.26;2652150000;1444.26
2007-02-12;1438.00;1439.11;1431.44;1433.37;2395680000;1433.37
2007-02-09;1448.25;1452.45;1433.44;1438.06;2951810000;1438.06
2007-02-08;1449.99;1450.45;1442.81;1448.31;2816180000;1448.31
2007-02-07;1447.41;1452.99;1446.44;1450.02;2618820000;1450.02
2007-02-06;1446.98;1450.19;1443.40;1448.00;2608710000;1448.00
2007-02-05;1448.33;1449.38;1443.85;1446.99;2439430000;1446.99
2007-02-02;1445.94;1449.33;1444.49;1448.39;2569450000;1448.39
2007-02-01;1437.90;1446.64;1437.90;1445.94;2914890000;1445.94
2007-01-31;1428.65;1441.61;1424.78;1438.24;2976690000;1438.24
2007-01-30;1420.61;1428.82;1420.61;1428.82;2706250000;1428.82
2007-01-29;1422.03;1426.94;1418.46;1420.62;2730480000;1420.62
2007-01-26;1423.90;1427.27;1416.96;1422.18;2626620000;1422.18
2007-01-25;1440.12;1440.69;1422.34;1423.90;2994330000;1423.90
2007-01-24;1427.96;1440.14;1427.96;1440.13;2783180000;1440.13
2007-01-23;1422.95;1431.33;1421.66;1427.99;2975070000;1427.99
2007-01-22;1430.47;1431.39;1420.40;1422.95;2540120000;1422.95
2007-01-19;1426.35;1431.57;1425.19;1430.50;2777480000;1430.50
2007-01-18;1430.59;1432.96;1424.21;1426.37;2822430000;1426.37
2007-01-17;1431.77;1435.27;1428.57;1430.62;2690270000;1430.62
2007-01-16;1430.73;1433.93;1428.62;1431.90;2599530000;1431.90
2007-01-12;1423.82;1431.23;1422.58;1430.73;2686480000;1430.73
2007-01-11;1414.84;1427.12;1414.84;1423.82;2857870000;1423.82
2007-01-10;1408.70;1415.99;1405.32;1414.85;2764660000;1414.85
2007-01-09;1412.84;1415.61;1405.42;1412.11;3038380000;1412.11
2007-01-08;1409.26;1414.98;1403.97;1412.84;2763340000;1412.84
2007-01-05;1418.34;1418.34;1405.75;1409.71;2919400000;1409.71
2007-01-04;1416.60;1421.84;1408.43;1418.34;3004460000;1418.34
2007-01-03;1418.03;1429.42;1407.86;1416.60;3429160000;1416.60
2006-12-29;1424.71;1427.00;1416.84;1418.30;1678200000;1418.30
2006-12-28;1426.77;1427.26;1422.05;1424.73;1508570000;1424.73
2006-12-27;1416.63;1427.72;1416.63;1426.84;1667370000;1426.84
2006-12-26;1410.75;1417.91;1410.45;1416.90;1310310000;1416.90
2006-12-22;1418.10;1418.82;1410.28;1410.76;1647590000;1410.76
2006-12-21;1423.20;1426.40;1415.90;1418.30;2322410000;1418.30
2006-12-20;1425.51;1429.05;1423.51;1423.53;2387630000;1423.53
2006-12-19;1422.42;1428.30;1414.88;1425.55;2717060000;1425.55
2006-12-18;1427.08;1431.81;1420.65;1422.48;2568140000;1422.48
2006-12-15;1425.48;1431.63;1425.48;1427.09;3229580000;1427.09
2006-12-14;1413.16;1427.23;1413.16;1425.49;2729700000;1425.49
2006-12-13;1411.32;1416.64;1411.05;1413.21;2552260000;1413.21
2006-12-12;1413.00;1413.78;1404.75;1411.56;2738170000;1411.56
2006-12-11;1409.81;1415.60;1408.56;1413.04;2289900000;1413.04
2006-12-08;1407.27;1414.09;1403.67;1409.84;2440460000;1409.84
2006-12-07;1412.86;1418.27;1406.80;1407.29;2743150000;1407.29
2006-12-06;1414.40;1415.93;1411.05;1412.90;2725280000;1412.90
2006-12-05;1409.10;1415.27;1408.78;1414.76;2755700000;1414.76
2006-12-04;1396.67;1411.23;1396.67;1409.12;2766320000;1409.12
2006-12-01;1400.63;1402.46;1385.93;1396.71;2800980000;1396.71
2006-11-30;1399.47;1406.30;1393.83;1400.63;4006230000;1400.63
2006-11-29;1386.11;1401.14;1386.11;1399.48;2790970000;1399.48
2006-11-28;1381.61;1387.91;1377.83;1386.72;2639750000;1386.72
2006-11-27;1400.95;1400.95;1381.44;1381.96;2711210000;1381.96
2006-11-24;1405.94;1405.94;1399.25;1400.95;832550000;1400.95
2006-11-22;1402.69;1407.89;1402.26;1406.09;2237710000;1406.09
2006-11-21;1400.43;1403.49;1399.99;1402.81;2597940000;1402.81
2006-11-20;1401.17;1404.37;1397.85;1400.50;2546710000;1400.50
2006-11-17;1399.76;1401.21;1394.55;1401.20;2726100000;1401.20
2006-11-16;1396.53;1403.76;1396.53;1399.76;2835730000;1399.76
2006-11-15;1392.91;1401.35;1392.13;1396.57;2831130000;1396.57
2006-11-14;1384.36;1394.49;1379.07;1393.22;3027480000;1393.22
2006-11-13;1380.58;1387.61;1378.80;1384.42;2386340000;1384.42
2006-11-10;1378.33;1381.04;1375.60;1380.90;2290200000;1380.90
2006-11-09;1385.43;1388.92;1377.31;1378.33;3012050000;1378.33
2006-11-08;1382.50;1388.61;1379.33;1385.72;2814820000;1385.72
2006-11-07;1379.75;1388.19;1379.19;1382.84;2636390000;1382.84
2006-11-06;1364.27;1381.40;1364.27;1379.78;2533550000;1379.78
2006-11-03;1367.31;1371.68;1360.98;1364.30;2419730000;1364.30
2006-11-02;1367.44;1368.39;1362.21;1367.34;2646180000;1367.34
2006-11-01;1377.76;1381.95;1366.26;1367.81;2821160000;1367.81
2006-10-31;1377.93;1381.21;1372.19;1377.94;2803030000;1377.94
2006-10-30;1377.30;1381.22;1373.46;1377.93;2770440000;1377.93
2006-10-27;1388.89;1388.89;1375.85;1377.34;2458450000;1377.34
2006-10-26;1382.21;1389.45;1379.47;1389.08;2793350000;1389.08
2006-10-25;1377.36;1383.61;1376.00;1382.22;2953540000;1382.22
2006-10-24;1377.02;1377.78;1372.42;1377.38;2876890000;1377.38
2006-10-23;1368.58;1377.40;1363.94;1377.02;2480430000;1377.02
2006-10-20;1366.94;1368.66;1362.10;1368.60;2526410000;1368.60
2006-10-19;1365.95;1368.09;1362.06;1366.96;2619830000;1366.96
2006-10-18;1363.93;1372.87;1360.95;1365.80;2658840000;1365.80
2006-10-17;1369.05;1369.05;1356.87;1364.05;2519620000;1364.05
2006-10-16;1365.61;1370.20;1364.48;1369.06;2305920000;1369.06
2006-10-13;1362.82;1366.63;1360.50;1365.62;2482920000;1365.62
2006-10-12;1349.94;1363.76;1349.94;1362.83;2514350000;1362.83
2006-10-11;1353.28;1353.97;1343.57;1349.95;2521000000;1349.95
2006-10-10;1350.62;1354.23;1348.60;1353.42;2376140000;1353.42
2006-10-09;1349.58;1352.69;1346.55;1350.66;1935170000;1350.66
2006-10-06;1353.22;1353.22;1344.21;1349.59;2523000000;1349.59
2006-10-05;1349.84;1353.79;1347.75;1353.22;2817240000;1353.22
2006-10-04;1333.81;1350.20;1331.48;1350.20;3019880000;1350.20
2006-10-03;1331.32;1338.31;1327.10;1334.11;2682690000;1334.11
2006-10-02;1335.82;1338.54;1330.28;1331.32;2154480000;1331.32
2006-09-29;1339.15;1339.88;1335.64;1335.85;2273430000;1335.85
2006-09-28;1336.56;1340.28;1333.75;1338.88;2397820000;1338.88
2006-09-27;1336.12;1340.08;1333.54;1336.59;2749190000;1336.59
2006-09-26;1326.35;1336.60;1325.30;1336.35;2673350000;1336.35
2006-09-25;1314.78;1329.35;1311.58;1326.37;2710240000;1326.37
2006-09-22;1318.03;1318.03;1310.94;1314.78;2162880000;1314.78
2006-09-21;1324.89;1328.19;1315.45;1318.03;2627440000;1318.03
2006-09-20;1318.28;1328.53;1318.28;1325.18;2543070000;1325.18
2006-09-19;1321.17;1322.04;1312.17;1317.64;2390850000;1317.64
2006-09-18;1319.85;1324.87;1318.16;1321.18;2325080000;1321.18
2006-09-15;1316.28;1324.65;1316.28;1319.66;3198030000;1319.66
2006-09-14;1318.00;1318.00;1313.25;1316.28;2351220000;1316.28
2006-09-13;1312.74;1319.92;1311.12;1318.07;2597220000;1318.07
2006-09-12;1299.53;1314.28;1299.53;1313.00;2791580000;1313.00
2006-09-11;1298.86;1302.36;1290.93;1299.54;2506430000;1299.54
2006-09-08;1294.02;1300.14;1294.02;1298.92;2132890000;1298.92
2006-09-07;1300.21;1301.25;1292.13;1294.02;2325850000;1294.02
2006-09-06;1313.04;1313.04;1299.28;1300.26;2329870000;1300.26
2006-09-05;1310.94;1314.67;1308.82;1313.25;2114480000;1313.25
2006-09-01;1303.80;1312.03;1303.80;1311.01;1800520000;1311.01
2006-08-31;1304.25;1306.11;1302.45;1303.82;1974540000;1303.82
2006-08-30;1303.70;1306.74;1302.15;1305.37;2060690000;1305.37
2006-08-29;1301.57;1305.02;1295.29;1304.28;2093720000;1304.28
2006-08-28;1295.09;1305.02;1293.97;1301.78;1834920000;1301.78
2006-08-25;1295.92;1298.88;1292.39;1295.09;1667580000;1295.09
2006-08-24;1292.97;1297.23;1291.40;1296.06;1930320000;1296.06
2006-08-23;1298.73;1301.50;1289.82;1292.99;1893670000;1292.99
2006-08-22;1297.52;1302.49;1294.44;1298.82;1908740000;1298.82
2006-08-21;1302.30;1302.30;1295.51;1297.52;1759240000;1297.52
2006-08-18;1297.48;1302.30;1293.57;1302.30;2033910000;1302.30
2006-08-17;1295.37;1300.78;1292.71;1297.48;2458340000;1297.48
2006-08-16;1285.27;1296.21;1285.27;1295.43;2554570000;1295.43
2006-08-15;1268.19;1286.23;1268.19;1285.58;2334100000;1285.58
2006-08-14;1266.67;1278.90;1266.67;1268.21;2118020000;1268.21
2006-08-11;1271.64;1271.64;1262.08;1266.74;2004540000;1266.74
2006-08-10;1265.72;1272.55;1261.30;1271.81;2402190000;1271.81
2006-08-09;1271.13;1283.74;1264.73;1265.95;2555180000;1265.95
2006-08-08;1275.67;1282.75;1268.37;1271.48;2457840000;1271.48
2006-08-07;1279.31;1279.31;1273.00;1275.77;2045660000;1275.77
2006-08-04;1280.26;1292.92;1273.82;1279.36;2530970000;1279.36
2006-08-03;1278.22;1283.96;1271.25;1280.27;2728440000;1280.27
2006-08-02;1270.73;1283.42;1270.73;1277.41;2610750000;1277.41
2006-08-01;1278.53;1278.66;1265.71;1270.92;2527690000;1270.92
2006-07-31;1278.53;1278.66;1274.31;1276.66;2461300000;1276.66
2006-07-28;1263.15;1280.42;1263.15;1278.55;2480420000;1278.55
2006-07-27;1268.20;1275.85;1261.92;1263.20;2776710000;1263.20
2006-07-26;1268.87;1273.89;1261.94;1268.40;2667710000;1268.40
2006-07-25;1260.91;1272.39;1257.19;1268.88;2563930000;1268.88
2006-07-24;1240.25;1262.50;1240.25;1260.91;2312720000;1260.91
2006-07-21;1249.12;1250.96;1238.72;1240.29;2704090000;1240.29
2006-07-20;1259.81;1262.56;1249.13;1249.13;2345580000;1249.13
2006-07-19;1236.74;1261.81;1236.74;1259.81;2701980000;1259.81
2006-07-18;1234.48;1239.86;1224.54;1236.86;2481750000;1236.86
2006-07-17;1236.20;1240.07;1231.49;1234.49;2146410000;1234.49
2006-07-14;1242.29;1242.70;1228.45;1236.20;2467120000;1236.20
2006-07-13;1258.58;1258.58;1241.43;1242.28;2545760000;1242.28
2006-07-12;1272.39;1273.31;1257.29;1258.60;2250450000;1258.60
2006-07-11;1267.26;1273.64;1259.65;1272.43;2310850000;1272.43
2006-07-10;1265.46;1274.06;1264.46;1267.34;1854590000;1267.34
2006-07-07;1274.08;1275.38;1263.13;1265.48;1988150000;1265.48
2006-07-06;1270.58;1278.32;1270.58;1274.08;2009160000;1274.08
2006-07-05;1280.05;1280.05;1265.91;1270.91;2165070000;1270.91
2006-07-03;1270.06;1280.38;1270.06;1280.19;1114470000;1280.19
2006-06-30;1272.86;1276.30;1270.20;1270.20;3049560000;1270.20
2006-06-29;1245.94;1272.88;1245.94;1272.87;2621250000;1272.87
2006-06-28;1238.99;1247.06;1237.59;1246.00;2085490000;1246.00
2006-06-27;1250.55;1253.37;1238.94;1239.20;2203130000;1239.20
2006-06-26;1244.50;1250.92;1243.68;1250.56;1878580000;1250.56
2006-06-23;1245.59;1253.13;1241.43;1244.50;2017270000;1244.50
2006-06-22;1251.92;1251.92;1241.53;1245.60;2148180000;1245.60
2006-06-21;1240.09;1257.96;1240.09;1252.20;2361230000;1252.20
2006-06-20;1240.12;1249.01;1238.87;1240.12;2232950000;1240.12
2006-06-19;1251.54;1255.93;1237.17;1240.13;2517200000;1240.13
2006-06-16;1256.16;1256.27;1246.33;1251.54;2783390000;1251.54
2006-06-15;1230.01;1258.64;1230.01;1256.16;2775480000;1256.16
2006-06-14;1223.66;1231.46;1219.29;1230.04;2667990000;1230.04
2006-06-13;1236.08;1243.37;1222.52;1223.69;3215770000;1223.69
2006-06-12;1252.27;1255.22;1236.43;1237.44;2247010000;1237.44
2006-06-09;1257.93;1262.58;1250.03;1252.30;2214000000;1252.30
2006-06-08;1256.08;1259.85;1235.18;1257.93;3543790000;1257.93
2006-06-07;1263.61;1272.47;1255.77;1256.15;2644170000;1256.15
2006-06-06;1265.23;1269.88;1254.46;1263.85;2697650000;1263.85
2006-06-05;1288.16;1288.16;1264.66;1265.29;2313470000;1265.29
2006-06-02;1285.71;1290.68;1280.22;1288.22;2295540000;1288.22
2006-06-01;1270.05;1285.71;1269.19;1285.71;2360160000;1285.71
2006-05-31;1259.38;1270.09;1259.38;1270.09;2692160000;1270.09
2006-05-30;1280.04;1280.04;1259.87;1259.87;2176190000;1259.87
2006-05-26;1272.71;1280.54;1272.50;1280.16;1814020000;1280.16
2006-05-25;1258.41;1273.26;1258.41;1272.88;2372730000;1272.88
2006-05-24;1256.56;1264.53;1245.34;1258.57;2999030000;1258.57
2006-05-23;1262.06;1273.67;1256.15;1256.58;2605250000;1256.58
2006-05-22;1267.03;1268.77;1252.98;1262.07;2773010000;1262.07
2006-05-19;1261.81;1272.15;1256.28;1267.03;2982300000;1267.03
2006-05-18;1270.25;1274.89;1261.75;1261.81;2537490000;1261.81
2006-05-17;1291.73;1291.73;1267.31;1270.32;2830200000;1270.32
2006-05-16;1294.50;1297.88;1288.51;1292.08;2386210000;1292.08
2006-05-15;1291.19;1294.81;1284.51;1294.50;2505660000;1294.50
2006-05-12;1305.88;1305.88;1290.38;1291.24;2567970000;1291.24
2006-05-11;1322.63;1322.63;1303.45;1305.92;2531520000;1305.92
2006-05-10;1324.57;1325.51;1317.44;1322.85;2268550000;1322.85
2006-05-09;1324.66;1326.60;1322.48;1325.14;2157290000;1325.14
2006-05-08;1325.76;1326.70;1322.87;1324.66;2151300000;1324.66
2006-05-05;1312.25;1326.53;1312.25;1325.76;2294760000;1325.76
2006-05-04;1307.85;1315.14;1307.85;1312.25;2431450000;1312.25
2006-05-03;1313.21;1313.47;1303.92;1308.12;2395230000;1308.12
2006-05-02;1305.19;1313.66;1305.19;1313.21;2403470000;1313.21
2006-05-01;1310.61;1317.21;1303.46;1305.19;2437040000;1305.19
2006-04-28;1309.72;1316.04;1306.16;1310.61;2419920000;1310.61
2006-04-27;1305.41;1315.00;1295.57;1309.72;2772010000;1309.72
2006-04-26;1301.74;1310.97;1301.74;1305.41;2502690000;1305.41
2006-04-25;1308.11;1310.79;1299.17;1301.74;2366380000;1301.74
2006-04-24;1311.28;1311.28;1303.79;1308.11;2117330000;1308.11
2006-04-21;1311.46;1317.67;1306.59;1311.28;2392630000;1311.28
2006-04-20;1309.93;1318.16;1306.38;1311.46;2512920000;1311.46
2006-04-19;1307.65;1310.39;1302.79;1309.93;2447310000;1309.93
2006-04-18;1285.33;1309.02;1285.33;1307.28;2595440000;1307.28
2006-04-17;1289.12;1292.45;1280.74;1285.33;1794650000;1285.33
2006-04-13;1288.12;1292.09;1283.37;1289.12;1891940000;1289.12
2006-04-12;1286.57;1290.93;1286.45;1288.12;1938100000;1288.12
2006-04-11;1296.60;1300.71;1282.96;1286.57;2232880000;1286.57
2006-04-10;1295.51;1300.74;1293.17;1296.62;1898320000;1296.62
2006-04-07;1309.04;1314.07;1294.18;1295.50;2082470000;1295.50
2006-04-06;1311.56;1311.99;1302.44;1309.04;2281680000;1309.04
2006-04-05;1305.93;1312.81;1304.82;1311.56;2420020000;1311.56
2006-04-04;1297.81;1307.55;1294.71;1305.93;2147660000;1305.93
2006-04-03;1302.88;1309.19;1296.65;1297.81;2494080000;1297.81
2006-03-31;1300.25;1303.00;1294.87;1294.87;2236710000;1294.87
2006-03-30;1302.89;1310.15;1296.72;1300.25;2294560000;1300.25
2006-03-29;1293.23;1305.60;1293.23;1302.89;2143540000;1302.89
2006-03-28;1301.61;1306.24;1291.84;1293.23;2148580000;1293.23
2006-03-27;1302.95;1303.74;1299.09;1301.61;2029700000;1301.61
2006-03-24;1301.67;1306.53;1298.89;1302.95;2326070000;1302.95
2006-03-23;1305.04;1305.04;1298.11;1301.67;1980940000;1301.67
2006-03-22;1297.23;1305.97;1295.81;1305.04;2039810000;1305.04
2006-03-21;1305.08;1310.88;1295.82;1297.23;2147370000;1297.23
2006-03-20;1307.25;1310.00;1303.59;1305.08;1976830000;1305.08
2006-03-17;1305.33;1309.79;1305.32;1307.25;2549620000;1307.25
2006-03-16;1303.02;1310.45;1303.02;1305.33;2292180000;1305.33
2006-03-15;1297.48;1304.40;1294.97;1303.02;2293000000;1303.02
2006-03-14;1284.13;1298.14;1282.67;1297.48;2165270000;1297.48
2006-03-13;1281.58;1287.37;1281.58;1284.13;2070330000;1284.13
2006-03-10;1272.23;1284.37;1271.11;1281.42;2123450000;1281.42
2006-03-09;1278.47;1282.74;1272.23;1272.23;2140110000;1272.23
2006-03-08;1275.88;1280.33;1268.42;1278.47;2442870000;1278.47
2006-03-07;1278.26;1278.26;1271.11;1275.88;2268050000;1275.88
2006-03-06;1287.23;1288.23;1275.67;1278.26;2280190000;1278.26
2006-03-03;1289.14;1297.33;1284.20;1287.23;2152950000;1287.23
2006-03-02;1291.24;1291.24;1283.21;1289.14;2494590000;1289.14
2006-03-01;1280.66;1291.80;1280.66;1291.24;2308320000;1291.24
2006-02-28;1294.12;1294.12;1278.66;1280.66;2370860000;1280.66
2006-02-27;1289.43;1297.57;1289.43;1294.12;1975320000;1294.12
2006-02-24;1287.79;1292.11;1285.62;1289.43;1933010000;1289.43
2006-02-23;1292.67;1293.84;1285.14;1287.79;2144210000;1287.79
2006-02-22;1283.03;1294.17;1283.03;1292.67;2222380000;1292.67
2006-02-21;1287.24;1291.92;1281.33;1283.03;2104320000;1283.03
2006-02-17;1289.38;1289.47;1284.07;1287.24;2128260000;1287.24
2006-02-16;1280.00;1289.39;1280.00;1289.38;2251490000;1289.38
2006-02-15;1275.53;1281.00;1271.06;1280.00;2317590000;1280.00
2006-02-14;1262.86;1278.21;1260.80;1275.53;2437940000;1275.53
2006-02-13;1266.99;1266.99;1258.34;1262.86;1850080000;1262.86
2006-02-10;1263.82;1269.89;1254.98;1266.99;2290050000;1266.99
2006-02-09;1265.65;1274.56;1262.80;1263.78;2441920000;1263.78
2006-02-08;1254.78;1266.47;1254.78;1265.65;2456860000;1265.65
2006-02-07;1265.02;1265.78;1253.61;1254.78;2366370000;1254.78
2006-02-06;1264.03;1267.04;1261.62;1265.02;2132360000;1265.02
2006-02-03;1270.84;1270.87;1261.02;1264.03;2282210000;1264.03
2006-02-02;1282.46;1282.46;1267.72;1270.84;2565300000;1270.84
2006-02-01;1280.08;1283.33;1277.57;1282.46;2589410000;1282.46
2006-01-31;1285.20;1285.20;1276.85;1280.08;2708310000;1280.08
2006-01-30;1283.72;1287.94;1283.51;1285.19;2282730000;1285.19
2006-01-27;1273.83;1286.38;1273.83;1283.72;2623620000;1283.72
2006-01-26;1264.68;1276.44;1264.68;1273.83;2856780000;1273.83
2006-01-25;1266.86;1271.87;1259.42;1264.68;2617060000;1264.68
2006-01-24;1263.82;1271.47;1263.82;1266.86;2608720000;1266.86
2006-01-23;1261.49;1268.19;1261.49;1263.82;2256070000;1263.82
2006-01-20;1285.04;1285.04;1260.92;1261.49;2845810000;1261.49
2006-01-19;1277.93;1287.79;1277.93;1285.04;2444020000;1285.04
2006-01-18;1282.93;1282.93;1272.08;1277.93;2233200000;1277.93
2006-01-17;1287.61;1287.61;1278.61;1283.03;2179970000;1283.03
2006-01-13;1286.06;1288.96;1282.78;1287.61;2206510000;1287.61
2006-01-12;1294.18;1294.18;1285.04;1286.06;2318350000;1286.06
2006-01-11;1289.72;1294.90;1288.12;1294.18;2406130000;1294.18
2006-01-10;1290.15;1290.15;1283.76;1289.69;2373080000;1289.69
2006-01-09;1285.45;1290.78;1284.82;1290.15;2301490000;1290.15
2006-01-06;1273.48;1286.09;1273.48;1285.45;2446560000;1285.45
2006-01-05;1273.46;1276.91;1270.30;1273.48;2433340000;1273.48
2006-01-04;1268.80;1275.37;1267.74;1273.46;2515330000;1273.46
2006-01-03;1248.29;1270.22;1245.74;1268.80;2554570000;1268.80
2005-12-30;1254.42;1254.42;1246.59;1248.29;1443500000;1248.29
2005-12-29;1258.17;1260.61;1254.18;1254.42;1382540000;1254.42
2005-12-28;1256.54;1261.10;1256.54;1258.17;1422360000;1258.17
2005-12-27;1268.66;1271.83;1256.54;1256.54;1540470000;1256.54
2005-12-23;1268.12;1269.76;1265.92;1268.66;1285810000;1268.66
2005-12-22;1262.79;1268.19;1262.50;1268.12;1888500000;1268.12
2005-12-21;1259.62;1269.37;1259.62;1262.79;2065170000;1262.79
2005-12-20;1259.92;1263.86;1257.21;1259.62;1996690000;1259.62
2005-12-19;1267.32;1270.51;1259.28;1259.92;2208810000;1259.92
2005-12-16;1270.94;1275.24;1267.32;1267.32;2584190000;1267.32
2005-12-15;1272.74;1275.17;1267.74;1270.94;2180590000;1270.94
2005-12-14;1267.43;1275.80;1267.07;1272.74;2145520000;1272.74
2005-12-13;1260.43;1272.11;1258.56;1267.43;2390020000;1267.43
2005-12-12;1259.37;1263.86;1255.52;1260.43;1876550000;1260.43
2005-12-09;1255.84;1263.08;1254.24;1259.37;1896290000;1259.37
2005-12-08;1257.37;1263.36;1250.91;1255.84;2178300000;1255.84
2005-12-07;1263.70;1264.85;1253.02;1257.37;2093830000;1257.37
2005-12-06;1262.09;1272.89;1262.09;1263.70;2110740000;1263.70
2005-12-05;1265.08;1265.08;1258.12;1262.09;2325840000;1262.09
2005-12-02;1264.67;1266.85;1261.42;1265.08;2125580000;1265.08
2005-12-01;1249.48;1266.17;1249.48;1264.67;2614830000;1264.67
2005-11-30;1257.48;1260.93;1249.39;1249.48;2374690000;1249.48
2005-11-29;1257.46;1266.18;1257.46;1257.48;2268340000;1257.48
2005-11-28;1268.25;1268.44;1257.17;1257.46;2016900000;1257.46
2005-11-25;1265.61;1268.78;1265.54;1268.25;724940000;1268.25
2005-11-23;1261.23;1270.64;1259.51;1265.61;1985400000;1265.61
2005-11-22;1254.85;1261.90;1251.40;1261.23;2291420000;1261.23
2005-11-21;1248.27;1255.89;1246.90;1254.85;2117350000;1254.85
2005-11-18;1242.80;1249.58;1240.71;1248.27;2453290000;1248.27
2005-11-17;1231.21;1242.96;1231.21;1242.80;2298040000;1242.80
2005-11-16;1229.01;1232.24;1227.18;1231.21;2121580000;1231.21
2005-11-15;1233.76;1237.94;1226.41;1229.01;2359370000;1229.01
2005-11-14;1234.72;1237.20;1231.78;1233.76;1899780000;1233.76
2005-11-11;1230.96;1235.70;1230.72;1234.72;1773140000;1234.72
2005-11-10;1220.65;1232.41;1215.05;1230.96;2378460000;1230.96
2005-11-09;1218.59;1226.59;1216.53;1220.65;2214460000;1220.65
2005-11-08;1222.81;1222.81;1216.08;1218.59;1965050000;1218.59
2005-11-07;1220.14;1224.18;1217.29;1222.81;1987580000;1222.81
2005-11-04;1219.94;1222.52;1214.45;1220.14;2050510000;1220.14
2005-11-03;1214.76;1224.70;1214.76;1219.94;2716630000;1219.94
2005-11-02;1202.76;1215.17;1201.07;1214.76;2648090000;1214.76
2005-11-01;1207.01;1207.34;1201.66;1202.76;2457850000;1202.76
2005-10-31;1198.41;1211.43;1198.41;1207.01;2567470000;1207.01
2005-10-28;1178.90;1198.41;1178.90;1198.41;2379400000;1198.41
2005-10-27;1191.38;1192.65;1178.89;1178.90;2395370000;1178.90
2005-10-26;1196.54;1204.01;1191.38;1191.38;2467750000;1191.38
2005-10-25;1199.38;1201.30;1189.29;1196.54;2312470000;1196.54
2005-10-24;1179.59;1199.39;1179.59;1199.38;2197790000;1199.38
2005-10-21;1177.80;1186.46;1174.92;1179.59;2470920000;1179.59
2005-10-20;1195.76;1197.30;1173.30;1177.80;2617250000;1177.80
2005-10-19;1178.14;1195.76;1170.55;1195.76;2703590000;1195.76
2005-10-18;1190.10;1190.10;1178.13;1178.14;2197010000;1178.14
2005-10-17;1186.57;1191.21;1184.48;1190.10;2054570000;1190.10
2005-10-14;1176.84;1187.13;1175.44;1186.57;2188940000;1186.57
2005-10-13;1177.68;1179.56;1168.20;1176.84;2351150000;1176.84
2005-10-12;1184.87;1190.02;1173.65;1177.68;2491280000;1177.68
2005-10-11;1187.33;1193.10;1183.16;1184.87;2299040000;1184.87
2005-10-10;1195.90;1196.52;1186.12;1187.33;2195990000;1187.33
2005-10-07;1191.49;1199.71;1191.46;1195.90;2126080000;1195.90
2005-10-06;1196.39;1202.14;1181.92;1191.49;2792030000;1191.49
2005-10-05;1214.47;1214.47;1196.25;1196.39;2546780000;1196.39
2005-10-04;1226.70;1229.88;1214.02;1214.47;2341420000;1214.47
2005-10-03;1228.81;1233.34;1225.15;1226.70;2097490000;1226.70
2005-09-30;1227.68;1229.57;1225.22;1228.81;2097520000;1228.81
2005-09-29;1216.89;1228.70;1211.54;1227.68;2176120000;1227.68
2005-09-28;1215.66;1220.98;1212.72;1216.89;2106980000;1216.89
2005-09-27;1215.63;1220.17;1211.11;1215.66;1976270000;1215.66
2005-09-26;1215.29;1222.56;1211.84;1215.63;2022220000;1215.63
2005-09-23;1214.62;1218.83;1209.80;1215.29;1973020000;1215.29
2005-09-22;1210.20;1216.64;1205.35;1214.62;2424720000;1214.62
2005-09-21;1221.34;1221.52;1209.89;1210.20;2548150000;1210.20
2005-09-20;1231.02;1236.49;1220.07;1221.34;2319250000;1221.34
2005-09-19;1237.91;1237.91;1227.65;1231.02;2076540000;1231.02
2005-09-16;1228.42;1237.95;1228.42;1237.91;3152470000;1237.91
2005-09-15;1227.16;1231.88;1224.85;1227.73;2079340000;1227.73
2005-09-14;1231.20;1234.74;1226.16;1227.16;1986750000;1227.16
2005-09-13;1240.57;1240.57;1231.20;1231.20;2082360000;1231.20
2005-09-12;1241.48;1242.60;1239.15;1240.56;1938050000;1240.56
2005-09-09;1231.67;1243.13;1231.67;1241.48;1992560000;1241.48
2005-09-08;1236.36;1236.36;1229.51;1231.67;1955380000;1231.67
2005-09-07;1233.39;1237.06;1230.93;1236.36;2067700000;1236.36
2005-09-06;1218.02;1233.61;1218.02;1233.39;1932090000;1233.39
2005-09-02;1221.59;1224.45;1217.75;1218.02;1640160000;1218.02
2005-09-01;1220.33;1227.29;1216.18;1221.59;2229860000;1221.59
2005-08-31;1208.41;1220.36;1204.40;1220.33;2365510000;1220.33
2005-08-30;1212.28;1212.28;1201.07;1208.41;1916470000;1208.41
2005-08-29;1205.10;1214.28;1201.53;1212.28;1599450000;1212.28
2005-08-26;1212.40;1212.40;1204.23;1205.10;1541090000;1205.10
2005-08-25;1209.59;1213.73;1209.57;1212.37;1571110000;1212.37
2005-08-24;1217.57;1224.15;1209.37;1209.59;1930800000;1209.59
2005-08-23;1221.73;1223.04;1214.44;1217.59;1678620000;1217.59
2005-08-22;1219.71;1228.96;1216.47;1221.73;1621330000;1221.73
2005-08-19;1219.02;1225.08;1219.02;1219.71;1558790000;1219.71
2005-08-18;1220.24;1222.64;1215.93;1219.02;1808170000;1219.02
2005-08-17;1219.34;1225.63;1218.07;1220.24;1859150000;1220.24
2005-08-16;1233.87;1233.87;1219.05;1219.34;1820410000;1219.34
2005-08-15;1230.40;1236.24;1226.20;1233.87;1562880000;1233.87
2005-08-12;1237.81;1237.81;1225.87;1230.39;1709300000;1230.39
2005-08-11;1229.13;1237.81;1228.33;1237.81;1941560000;1237.81
2005-08-10;1231.38;1242.69;1226.58;1229.13;2172320000;1229.13
2005-08-09;1223.13;1234.11;1223.13;1231.38;1897520000;1231.38
2005-08-08;1226.42;1232.28;1222.67;1223.13;1804140000;1223.13
2005-08-05;1235.86;1235.86;1225.62;1226.42;1930280000;1226.42
2005-08-04;1245.04;1245.04;1235.15;1235.86;1981220000;1235.86
2005-08-03;1244.12;1245.86;1240.57;1245.04;1999980000;1245.04
2005-08-02;1235.35;1244.69;1235.35;1244.12;2043120000;1244.12
2005-08-01;1234.18;1239.10;1233.80;1235.35;1716870000;1235.35
2005-07-29;1243.72;1245.04;1234.18;1234.18;1789600000;1234.18
2005-07-28;1236.79;1245.15;1235.81;1243.72;2001680000;1243.72
2005-07-27;1231.16;1237.64;1230.15;1236.79;1945800000;1236.79
2005-07-26;1229.03;1234.42;1229.03;1231.16;1934180000;1231.16
2005-07-25;1233.68;1238.36;1228.15;1229.03;1717580000;1229.03
2005-07-22;1227.04;1234.19;1226.15;1233.68;1766990000;1233.68
2005-07-21;1235.20;1235.83;1224.70;1227.04;2129840000;1227.04
2005-07-20;1229.35;1236.56;1222.91;1235.20;2063340000;1235.20
2005-07-19;1221.13;1230.34;1221.13;1229.35;2041280000;1229.35
2005-07-18;1227.92;1227.92;1221.13;1221.13;1582100000;1221.13
2005-07-15;1226.50;1229.53;1223.50;1227.92;1716400000;1227.92
2005-07-14;1223.29;1233.16;1223.29;1226.50;2048710000;1226.50
2005-07-13;1222.21;1224.46;1219.64;1223.29;1812500000;1223.29
2005-07-12;1219.44;1225.54;1216.60;1222.21;1932010000;1222.21
2005-07-11;1211.86;1220.03;1211.86;1219.44;1846300000;1219.44
2005-07-08;1197.87;1212.73;1197.20;1211.86;1900810000;1211.86
2005-07-07;1194.94;1198.46;1183.55;1197.87;1952440000;1197.87
2005-07-06;1204.99;1206.11;1194.78;1194.94;1883470000;1194.94
2005-07-05;1194.44;1206.34;1192.49;1204.99;1805820000;1204.99
2005-07-01;1191.33;1197.89;1191.33;1194.44;1593820000;1194.44
2005-06-30;1199.85;1203.27;1190.51;1191.33;2109490000;1191.33
2005-06-29;1201.57;1204.07;1198.70;1199.85;1769280000;1199.85
2005-06-28;1190.69;1202.54;1190.69;1201.57;1772410000;1201.57
2005-06-27;1191.57;1194.33;1188.30;1190.69;1738620000;1190.69
2005-06-24;1200.73;1200.90;1191.45;1191.57;2418800000;1191.57
2005-06-23;1213.88;1216.45;1200.72;1200.73;2029920000;1200.73
2005-06-22;1213.61;1219.59;1211.69;1213.88;1823250000;1213.88
2005-06-21;1216.10;1217.13;1211.86;1213.61;1720700000;1213.61
2005-06-20;1216.96;1219.10;1210.65;1216.10;1714530000;1216.10
2005-06-17;1210.93;1219.55;1210.93;1216.96;2407370000;1216.96
2005-06-16;1206.55;1212.10;1205.47;1210.96;1776040000;1210.96
2005-06-15;1203.91;1208.08;1198.66;1206.58;1840440000;1206.58
2005-06-14;1200.82;1207.53;1200.18;1203.91;1698150000;1203.91
2005-06-13;1198.11;1206.03;1194.51;1200.82;1661350000;1200.82
2005-06-10;1200.93;1202.79;1192.64;1198.11;1664180000;1198.11
2005-06-09;1194.67;1201.86;1191.09;1200.93;1824120000;1200.93
2005-06-08;1197.26;1201.97;1193.33;1194.67;1715490000;1194.67
2005-06-07;1197.51;1208.85;1197.26;1197.26;1851370000;1197.26
2005-06-06;1196.02;1198.78;1192.75;1197.51;1547120000;1197.51
2005-06-03;1204.29;1205.09;1194.55;1196.02;1627520000;1196.02
2005-06-02;1202.27;1204.67;1198.42;1204.29;1813790000;1204.29
2005-06-01;1191.50;1205.64;1191.03;1202.22;1810100000;1202.22
2005-05-31;1198.78;1198.78;1191.50;1191.50;1840680000;1191.50
2005-05-27;1197.62;1199.56;1195.28;1198.78;1381430000;1198.78
2005-05-26;1190.01;1198.95;1190.01;1197.62;1654110000;1197.62
2005-05-25;1194.07;1194.07;1185.96;1190.01;1742180000;1190.01
2005-05-24;1193.86;1195.29;1189.87;1194.07;1681000000;1194.07
2005-05-23;1189.28;1197.44;1188.76;1193.86;1681170000;1193.86
2005-05-20;1191.08;1191.22;1185.19;1189.28;1631750000;1189.28
2005-05-19;1185.56;1191.09;1184.49;1191.08;1775860000;1191.08
2005-05-18;1173.80;1187.90;1173.80;1185.56;2266320000;1185.56
2005-05-17;1165.69;1174.35;1159.86;1173.80;1887260000;1173.80
2005-05-16;1154.05;1165.75;1153.64;1165.69;1856860000;1165.69
2005-05-13;1159.36;1163.75;1146.18;1154.05;2188590000;1154.05
2005-05-12;1171.11;1173.37;1157.76;1159.36;1995290000;1159.36
2005-05-11;1166.22;1171.77;1157.71;1171.11;1834970000;1171.11
2005-05-10;1178.84;1178.84;1162.98;1166.22;1889660000;1166.22
2005-05-09;1171.35;1178.87;1169.38;1178.84;1857020000;1178.84
2005-05-06;1172.63;1177.75;1170.50;1171.35;1707200000;1171.35
2005-05-05;1175.65;1178.62;1166.77;1172.63;1997100000;1172.63
2005-05-04;1161.17;1176.01;1161.17;1175.65;2306480000;1175.65
2005-05-03;1162.16;1166.89;1156.71;1161.17;2167020000;1161.17
2005-05-02;1156.85;1162.87;1154.71;1162.16;1980040000;1162.16
2005-04-29;1143.22;1156.97;1139.19;1156.85;2362360000;1156.85
2005-04-28;1156.38;1156.38;1143.22;1143.22;2182270000;1143.22
2005-04-27;1151.74;1159.87;1144.42;1156.38;2151520000;1156.38
2005-04-26;1162.10;1164.80;1151.83;1151.83;1959740000;1151.83
2005-04-25;1152.12;1164.05;1152.12;1162.10;1795030000;1162.10
2005-04-22;1159.95;1159.95;1142.95;1152.12;2045880000;1152.12
2005-04-21;1137.50;1159.95;1137.50;1159.95;2308560000;1159.95
2005-04-20;1152.78;1155.50;1136.15;1137.50;2217050000;1137.50
2005-04-19;1145.98;1154.67;1145.98;1152.78;2142700000;1152.78
2005-04-18;1142.62;1148.92;1139.80;1145.98;2180670000;1145.98
2005-04-15;1162.05;1162.05;1141.92;1142.62;2689960000;1142.62
2005-04-14;1173.79;1174.67;1161.70;1162.05;2355040000;1162.05
2005-04-13;1187.76;1187.76;1171.40;1173.79;2049740000;1173.79
2005-04-12;1181.21;1190.17;1170.85;1187.76;1979830000;1187.76
2005-04-11;1181.20;1184.07;1178.69;1181.21;1525310000;1181.21
2005-04-08;1191.14;1191.75;1181.13;1181.20;1661330000;1181.20
2005-04-07;1184.07;1191.88;1183.81;1191.14;1900620000;1191.14
2005-04-06;1181.39;1189.34;1181.39;1184.07;1797400000;1184.07
2005-04-05;1176.12;1183.56;1176.12;1181.39;1870800000;1181.39
2005-04-04;1172.79;1178.61;1167.72;1176.12;2079770000;1176.12
2005-04-01;1180.59;1189.80;1169.91;1172.92;2168690000;1172.92
2005-03-31;1181.41;1184.53;1179.49;1180.59;2214230000;1180.59
2005-03-30;1165.36;1181.54;1165.36;1181.41;2097110000;1181.41
2005-03-29;1174.28;1179.39;1163.69;1165.36;2223250000;1165.36
2005-03-28;1171.42;1179.91;1171.42;1174.28;1746220000;1174.28
2005-03-24;1172.53;1180.11;1171.42;1171.42;1721720000;1171.42
2005-03-23;1171.71;1176.26;1168.70;1172.53;2246870000;1172.53
2005-03-22;1183.78;1189.59;1171.63;1171.71;2114470000;1171.71
2005-03-21;1189.65;1189.65;1178.82;1183.78;1819440000;1183.78
2005-03-18;1190.21;1191.98;1182.78;1189.65;2344370000;1189.65
2005-03-17;1188.07;1193.28;1186.34;1190.21;1581930000;1190.21
2005-03-16;1197.75;1197.75;1185.61;1188.07;1653190000;1188.07
2005-03-15;1206.83;1210.54;1197.75;1197.75;1513530000;1197.75
2005-03-14;1200.08;1206.83;1199.51;1206.83;1437430000;1206.83
2005-03-11;1209.25;1213.04;1198.15;1200.08;1449820000;1200.08
2005-03-10;1207.01;1211.23;1201.41;1209.25;1604020000;1209.25
2005-03-09;1219.43;1219.43;1206.66;1207.01;1704970000;1207.01
2005-03-08;1225.31;1225.69;1218.57;1219.43;1523090000;1219.43
2005-03-07;1222.12;1229.11;1222.12;1225.31;1488830000;1225.31
2005-03-04;1210.47;1224.76;1210.47;1222.12;1636820000;1222.12
2005-03-03;1210.08;1215.72;1204.45;1210.47;1616240000;1210.47
2005-03-02;1210.41;1215.79;1204.22;1210.08;1568540000;1210.08
2005-03-01;1203.60;1212.25;1203.60;1210.41;1708060000;1210.41
2005-02-28;1211.37;1211.37;1198.13;1203.60;1795480000;1203.60
2005-02-25;1200.20;1212.15;1199.61;1211.37;1523680000;1211.37
2005-02-24;1190.80;1200.42;1187.80;1200.20;1518750000;1200.20
2005-02-23;1184.16;1193.52;1184.16;1190.80;1501090000;1190.80
2005-02-22;1201.59;1202.48;1184.16;1184.16;1744940000;1184.16
2005-02-18;1200.75;1202.92;1197.35;1201.59;1551200000;1201.59
2005-02-17;1210.34;1211.33;1200.74;1200.75;1580120000;1200.75
2005-02-16;1210.12;1212.44;1205.06;1210.34;1490100000;1210.34
2005-02-15;1206.14;1212.44;1205.52;1210.12;1527080000;1210.12
2005-02-14;1205.30;1206.93;1203.59;1206.14;1290180000;1206.14
2005-02-11;1197.01;1208.38;1193.28;1205.30;1562300000;1205.30
2005-02-10;1191.99;1198.75;1191.54;1197.01;1491670000;1197.01
2005-02-09;1202.30;1203.83;1191.54;1191.99;1511040000;1191.99
2005-02-08;1201.72;1205.11;1200.16;1202.30;1416170000;1202.30
2005-02-07;1203.03;1204.15;1199.27;1201.72;1347270000;1201.72
2005-02-04;1189.89;1203.47;1189.67;1203.03;1648160000;1203.03
2005-02-03;1193.19;1193.19;1185.64;1189.89;1554460000;1189.89
2005-02-02;1189.41;1195.25;1188.92;1193.19;1561740000;1193.19
2005-02-01;1181.27;1190.39;1180.95;1189.41;1681980000;1189.41
2005-01-31;1171.36;1182.07;1171.36;1181.27;1679800000;1181.27
2005-01-28;1174.55;1175.61;1166.25;1171.36;1641800000;1171.36
2005-01-27;1174.07;1177.50;1170.15;1174.55;1600600000;1174.55
2005-01-26;1168.41;1175.96;1168.41;1174.07;1635900000;1174.07
2005-01-25;1163.75;1174.30;1163.75;1168.41;1610400000;1168.41
2005-01-24;1167.87;1173.03;1163.75;1163.75;1494600000;1163.75
2005-01-21;1175.41;1179.45;1167.82;1167.87;1643500000;1167.87
2005-01-20;1184.63;1184.63;1173.42;1175.41;1692000000;1175.41
2005-01-19;1195.98;1195.98;1184.41;1184.63;1498700000;1184.63
2005-01-18;1184.52;1195.98;1180.10;1195.98;1596800000;1195.98
2005-01-14;1177.45;1185.21;1177.45;1184.52;1335400000;1184.52
2005-01-13;1187.70;1187.70;1175.81;1177.45;1510300000;1177.45
2005-01-12;1182.99;1187.92;1175.64;1187.70;1562100000;1187.70
2005-01-11;1190.25;1190.25;1180.43;1182.99;1488800000;1182.99
2005-01-10;1186.19;1194.78;1184.80;1190.25;1490400000;1190.25
2005-01-07;1187.89;1192.20;1182.16;1186.19;1477900000;1186.19
2005-01-06;1183.74;1191.63;1183.27;1187.89;1569100000;1187.89
2005-01-05;1188.05;1192.73;1183.72;1183.74;1738900000;1183.74
2005-01-04;1202.08;1205.84;1185.39;1188.05;1721000000;1188.05
2005-01-03;1211.92;1217.80;1200.32;1202.08;1510800000;1202.08
2004-12-31;1213.55;1217.33;1211.65;1211.92;786900000;1211.92
2004-12-30;1213.45;1216.47;1213.41;1213.55;829800000;1213.55
2004-12-29;1213.54;1213.85;1210.95;1213.45;925900000;1213.45
2004-12-28;1204.92;1213.54;1204.92;1213.54;983000000;1213.54
2004-12-27;1210.13;1214.13;1204.92;1204.92;922000000;1204.92
2004-12-23;1209.57;1213.66;1208.71;1210.13;956100000;1210.13
2004-12-22;1205.45;1211.42;1203.85;1209.57;1390800000;1209.57
2004-12-21;1194.65;1205.93;1194.65;1205.45;1483700000;1205.45
2004-12-20;1194.20;1203.43;1193.36;1194.65;1422800000;1194.65
2004-12-17;1203.21;1203.21;1193.49;1194.20;2335000000;1194.20
2004-12-16;1205.72;1207.97;1198.41;1203.21;1793900000;1203.21
2004-12-15;1203.38;1206.61;1199.44;1205.72;1695800000;1205.72
2004-12-14;1198.68;1205.29;1197.84;1203.38;1544400000;1203.38
2004-12-13;1188.00;1198.74;1188.00;1198.68;1436100000;1198.68
2004-12-10;1189.24;1191.45;1185.24;1188.00;1443700000;1188.00
2004-12-09;1182.81;1190.51;1173.79;1189.24;1624700000;1189.24
2004-12-08;1177.07;1184.05;1177.07;1182.81;1525200000;1182.81
2004-12-07;1190.25;1192.17;1177.07;1177.07;1533900000;1177.07
2004-12-06;1191.17;1192.41;1185.18;1190.25;1354400000;1190.25
2004-12-03;1190.33;1197.46;1187.71;1191.17;1566700000;1191.17
2004-12-02;1191.37;1194.80;1186.72;1190.33;1774900000;1190.33
2004-12-01;1173.78;1191.37;1173.78;1191.37;1772800000;1191.37
2004-11-30;1178.57;1178.66;1173.81;1173.82;1553500000;1173.82
2004-11-29;1182.65;1186.94;1172.37;1178.57;1378500000;1178.57
2004-11-26;1181.76;1186.62;1181.08;1182.65;504580000;1182.65
2004-11-24;1176.94;1182.46;1176.94;1181.76;1149600000;1181.76
2004-11-23;1177.24;1179.52;1171.41;1176.94;1428300000;1176.94
2004-11-22;1170.34;1178.18;1167.89;1177.24;1392700000;1177.24
2004-11-19;1183.55;1184.00;1169.19;1170.34;1526600000;1170.34
2004-11-18;1181.94;1184.90;1180.15;1183.55;1456700000;1183.55
2004-11-17;1175.43;1188.46;1175.43;1181.94;1684200000;1181.94
2004-11-16;1183.81;1183.81;1175.32;1175.43;1364400000;1175.43
2004-11-15;1184.17;1184.48;1179.85;1183.81;1453300000;1183.81
2004-11-12;1173.48;1184.17;1171.43;1184.17;1531600000;1184.17
2004-11-11;1162.91;1174.80;1162.91;1173.48;1393000000;1173.48
2004-11-10;1164.08;1169.25;1162.51;1162.91;1504300000;1162.91
2004-11-09;1164.89;1168.96;1162.48;1164.08;1450800000;1164.08
2004-11-08;1166.17;1166.77;1162.32;1164.89;1358700000;1164.89
2004-11-05;1161.67;1170.87;1160.66;1166.17;1724400000;1166.17
2004-11-04;1143.20;1161.67;1142.34;1161.67;1782700000;1161.67
2004-11-03;1130.54;1147.57;1130.54;1143.20;1767500000;1143.20
2004-11-02;1130.51;1140.48;1128.12;1130.56;1659000000;1130.56
2004-11-01;1130.20;1133.41;1127.60;1130.51;1395900000;1130.51
2004-10-29;1127.44;1131.40;1124.62;1130.20;1500800000;1130.20
2004-10-28;1125.34;1130.67;1120.60;1127.44;1628200000;1127.44
2004-10-27;1111.09;1126.29;1107.43;1125.40;1741900000;1125.40
2004-10-26;1094.81;1111.10;1094.81;1111.09;1685400000;1111.09
2004-10-25;1095.74;1096.81;1090.29;1094.80;1380500000;1094.80
2004-10-22;1106.49;1108.14;1095.47;1095.74;1469600000;1095.74
2004-10-21;1103.66;1108.87;1098.47;1106.49;1673000000;1106.49
2004-10-20;1103.23;1104.09;1094.25;1103.66;1685700000;1103.66
2004-10-19;1114.02;1117.96;1103.15;1103.23;1737500000;1103.23
2004-10-18;1108.20;1114.46;1103.33;1114.02;1373300000;1114.02
2004-10-15;1103.29;1113.17;1102.14;1108.20;1645100000;1108.20
2004-10-14;1113.65;1114.96;1102.06;1103.29;1489500000;1103.29
2004-10-13;1121.84;1127.01;1109.63;1113.65;1546200000;1113.65
2004-10-12;1124.39;1124.39;1115.77;1121.84;1320100000;1121.84
2004-10-11;1122.14;1126.20;1122.14;1124.39;943800000;1124.39
2004-10-08;1130.65;1132.92;1120.19;1122.14;1291600000;1122.14
2004-10-07;1142.05;1142.05;1130.50;1130.65;1447500000;1130.65
2004-10-06;1134.48;1142.05;1132.94;1142.05;1416700000;1142.05
2004-10-05;1135.17;1137.87;1132.03;1134.48;1418400000;1134.48
2004-10-04;1131.50;1140.13;1131.50;1135.17;1534000000;1135.17
2004-10-01;1114.58;1131.64;1114.58;1131.50;1582200000;1131.50
2004-09-30;1114.80;1116.31;1109.68;1114.58;1748000000;1114.58
2004-09-29;1110.06;1114.80;1107.42;1114.80;1402900000;1114.80
2004-09-28;1103.52;1111.77;1101.29;1110.06;1396600000;1110.06
2004-09-27;1110.11;1110.11;1103.24;1103.52;1263500000;1103.52
2004-09-24;1108.36;1113.81;1108.36;1110.11;1255400000;1110.11
2004-09-23;1113.56;1113.61;1108.05;1108.36;1286300000;1108.36
2004-09-22;1129.30;1129.30;1112.67;1113.56;1379900000;1113.56
2004-09-21;1122.20;1131.54;1122.20;1129.30;1325000000;1129.30
2004-09-20;1128.55;1128.55;1120.34;1122.20;1197600000;1122.20
2004-09-17;1123.50;1130.14;1123.50;1128.55;1422600000;1128.55
2004-09-16;1120.37;1126.06;1120.37;1123.50;1113900000;1123.50
2004-09-15;1128.33;1128.33;1119.82;1120.37;1256000000;1120.37
2004-09-14;1125.82;1129.46;1124.72;1128.33;1204500000;1128.33
2004-09-13;1123.92;1129.78;1123.35;1125.82;1299800000;1125.82
2004-09-10;1118.38;1125.26;1114.39;1123.92;1261200000;1123.92
2004-09-09;1116.27;1121.30;1113.62;1118.38;1371300000;1118.38
2004-09-08;1121.30;1123.05;1116.27;1116.27;1246300000;1116.27
2004-09-07;1113.63;1124.08;1113.63;1121.30;1214400000;1121.30
2004-09-03;1118.31;1120.80;1113.57;1113.63;924170000;1113.63
2004-09-02;1105.91;1119.11;1105.60;1118.31;1118400000;1118.31
2004-09-01;1104.24;1109.24;1099.18;1105.91;1142100000;1105.91
2004-08-31;1099.15;1104.24;1094.72;1104.24;1138200000;1104.24
2004-08-30;1107.77;1107.77;1099.15;1099.15;843100000;1099.15
2004-08-27;1105.09;1109.68;1104.62;1107.77;845400000;1107.77
2004-08-26;1104.96;1106.78;1102.46;1105.09;1023600000;1105.09
2004-08-25;1096.19;1106.29;1093.24;1104.96;1192200000;1104.96
2004-08-24;1095.68;1100.94;1092.82;1096.19;1092500000;1096.19
2004-08-23;1098.35;1101.40;1094.73;1095.68;1021900000;1095.68
2004-08-20;1091.23;1100.26;1089.57;1098.35;1199900000;1098.35
2004-08-19;1095.17;1095.17;1086.28;1091.23;1249400000;1091.23
2004-08-18;1081.71;1095.17;1078.93;1095.17;1282500000;1095.17
2004-08-17;1079.34;1086.78;1079.34;1081.71;1267800000;1081.71
2004-08-16;1064.80;1080.66;1064.80;1079.34;1206200000;1079.34
2004-08-13;1063.23;1067.58;1060.72;1064.80;1175100000;1064.80
2004-08-12;1075.79;1075.79;1062.82;1063.23;1405100000;1063.23
2004-08-11;1079.04;1079.04;1065.92;1075.79;1410400000;1075.79
2004-08-10;1065.22;1079.04;1065.22;1079.04;1245600000;1079.04
2004-08-09;1063.97;1069.46;1063.97;1065.22;1086000000;1065.22
2004-08-06;1080.70;1080.70;1062.23;1063.97;1521000000;1063.97
2004-08-05;1098.63;1098.79;1079.98;1080.70;1397400000;1080.70
2004-08-04;1099.69;1102.45;1092.40;1098.63;1369200000;1098.63
2004-08-03;1106.62;1106.62;1099.26;1099.69;1338300000;1099.69
2004-08-02;1101.72;1108.60;1097.34;1106.62;1276000000;1106.62
2004-07-30;1100.43;1103.73;1096.96;1101.72;1298200000;1101.72
2004-07-29;1095.42;1103.51;1095.42;1100.43;1530100000;1100.43
2004-07-28;1094.83;1098.84;1082.17;1095.42;1554300000;1095.42
2004-07-27;1084.07;1096.65;1084.07;1094.83;1610800000;1094.83
2004-07-26;1086.20;1089.82;1078.78;1084.07;1413400000;1084.07
2004-07-23;1096.84;1096.84;1083.56;1086.20;1337500000;1086.20
2004-07-22;1093.88;1099.66;1084.16;1096.84;1680800000;1096.84
2004-07-21;1108.67;1116.27;1093.88;1093.88;1679500000;1093.88
2004-07-20;1100.90;1108.88;1099.10;1108.67;1445800000;1108.67
2004-07-19;1101.39;1105.52;1096.55;1100.90;1319900000;1100.90
2004-07-16;1106.69;1112.17;1101.07;1101.39;1450300000;1101.39
2004-07-15;1111.47;1114.63;1106.67;1106.69;1408700000;1106.69
2004-07-14;1115.14;1119.60;1107.83;1111.47;1462000000;1111.47
2004-07-13;1114.35;1116.30;1112.99;1115.14;1199700000;1115.14
2004-07-12;1112.81;1116.11;1106.71;1114.35;1114600000;1114.35
2004-07-09;1109.11;1115.57;1109.11;1112.81;1186300000;1112.81
2004-07-08;1118.33;1119.12;1108.72;1109.11;1401100000;1109.11
2004-07-07;1116.21;1122.37;1114.92;1118.33;1328600000;1118.33
2004-07-06;1125.38;1125.38;1113.21;1116.21;1283300000;1116.21
2004-07-02;1128.94;1129.15;1123.26;1125.38;1085000000;1125.38
2004-07-01;1140.84;1140.84;1123.06;1128.94;1495700000;1128.94
2004-06-30;1136.20;1144.20;1133.62;1140.84;1473800000;1140.84
2004-06-29;1133.35;1138.26;1131.81;1136.20;1375000000;1136.20
2004-06-28;1134.43;1142.60;1131.72;1133.35;1354600000;1133.35
2004-06-25;1140.65;1145.97;1134.24;1134.43;1812900000;1134.43
2004-06-24;1144.06;1146.34;1139.94;1140.65;1394900000;1140.65
2004-06-23;1134.41;1145.15;1131.73;1144.06;1444200000;1144.06
2004-06-22;1130.30;1135.05;1124.37;1134.41;1382300000;1134.41
2004-06-21;1135.02;1138.05;1129.64;1130.30;1123900000;1130.30
2004-06-18;1132.05;1138.96;1129.83;1135.02;1500600000;1135.02
2004-06-17;1133.56;1133.56;1126.89;1132.05;1296700000;1132.05
2004-06-16;1132.01;1135.28;1130.55;1133.56;1168400000;1133.56
2004-06-15;1125.29;1137.36;1125.29;1132.01;1345900000;1132.01
2004-06-14;1136.47;1136.47;1122.16;1125.29;1179400000;1125.29
2004-06-10;1131.33;1136.47;1131.33;1136.47;1160600000;1136.47
2004-06-09;1142.18;1142.18;1131.17;1131.33;1276800000;1131.33
2004-06-08;1140.42;1142.18;1135.45;1142.18;1190300000;1142.18
2004-06-07;1122.50;1140.54;1122.50;1140.42;1211800000;1140.42
2004-06-04;1116.64;1129.17;1116.64;1122.50;1115300000;1122.50
2004-06-03;1124.99;1125.31;1116.57;1116.64;1232400000;1116.64
2004-06-02;1121.20;1128.10;1118.64;1124.99;1251700000;1124.99
2004-06-01;1120.68;1122.70;1113.32;1121.20;1238000000;1121.20
2004-05-28;1121.28;1122.69;1118.10;1120.68;1172600000;1120.68
2004-05-27;1114.94;1123.95;1114.86;1121.28;1447500000;1121.28
2004-05-26;1113.05;1116.71;1109.91;1114.94;1369400000;1114.94
2004-05-25;1095.41;1113.80;1090.74;1113.05;1545700000;1113.05
2004-05-24;1093.56;1101.28;1091.77;1095.41;1227500000;1095.41
2004-05-21;1089.19;1099.64;1089.19;1093.56;1258600000;1093.56
2004-05-20;1088.68;1092.62;1085.43;1089.19;1211000000;1089.19
2004-05-19;1091.49;1105.93;1088.49;1088.68;1548600000;1088.68
2004-05-18;1084.10;1094.10;1084.10;1091.49;1353000000;1091.49
2004-05-17;1095.70;1095.70;1079.36;1084.10;1430100000;1084.10
2004-05-14;1096.44;1102.10;1088.24;1095.70;1335900000;1095.70
2004-05-13;1097.28;1102.77;1091.76;1096.44;1411100000;1096.44
2004-05-12;1095.45;1097.55;1076.32;1097.28;1697600000;1097.28
2004-05-11;1087.12;1095.69;1087.12;1095.45;1533800000;1095.45
2004-05-10;1098.70;1098.70;1079.63;1087.12;1918400000;1087.12
2004-05-07;1113.99;1117.30;1098.63;1098.70;1653600000;1098.70
2004-05-06;1121.53;1121.53;1106.30;1113.99;1509300000;1113.99
2004-05-05;1119.55;1125.07;1117.90;1121.53;1469000000;1121.53
2004-05-04;1117.49;1127.74;1112.89;1119.55;1662100000;1119.55
2004-05-03;1107.30;1118.72;1107.30;1117.49;1571600000;1117.49
2004-04-30;1113.89;1119.26;1107.23;1107.30;1634700000;1107.30
2004-04-29;1122.41;1128.80;1108.04;1113.89;1859000000;1113.89
2004-04-28;1138.11;1138.11;1121.70;1122.41;1855600000;1122.41
2004-04-27;1135.53;1146.56;1135.53;1138.11;1518000000;1138.11
2004-04-26;1140.60;1145.08;1132.91;1135.53;1290600000;1135.53
2004-04-23;1139.93;1141.92;1134.81;1140.60;1396100000;1140.60
2004-04-22;1124.09;1142.77;1121.95;1139.93;1826700000;1139.93
2004-04-21;1118.15;1125.72;1116.03;1124.09;1738100000;1124.09
2004-04-20;1135.82;1139.26;1118.09;1118.15;1508500000;1118.15
2004-04-19;1134.56;1136.18;1129.84;1135.82;1194900000;1135.82
2004-04-16;1128.84;1136.80;1126.90;1134.61;1487800000;1134.61
2004-04-15;1128.17;1134.08;1120.75;1128.84;1568700000;1128.84
2004-04-14;1129.44;1132.52;1122.15;1128.17;1547700000;1128.17
2004-04-13;1145.20;1147.78;1127.70;1129.44;1423200000;1129.44
2004-04-12;1139.32;1147.29;1139.32;1145.20;1102400000;1145.20
2004-04-08;1140.53;1148.97;1134.52;1139.32;1199800000;1139.32
2004-04-07;1148.16;1148.16;1138.41;1140.53;1458800000;1140.53
2004-04-06;1150.57;1150.57;1143.30;1148.16;1397700000;1148.16
2004-04-05;1141.81;1150.57;1141.64;1150.57;1413700000;1150.57
2004-04-02;1132.17;1144.81;1132.17;1141.81;1629200000;1141.81
2004-04-01;1126.21;1135.67;1126.20;1132.17;1560700000;1132.17
2004-03-31;1127.00;1130.83;1121.46;1126.21;1560700000;1126.21
2004-03-30;1122.47;1127.60;1119.66;1127.00;1332400000;1127.00
2004-03-29;1108.06;1124.37;1108.06;1122.47;1405500000;1122.47
2004-03-26;1109.19;1115.27;1106.13;1108.06;1319100000;1108.06
2004-03-25;1091.33;1110.38;1091.33;1109.19;1471700000;1109.19
2004-03-24;1093.95;1098.32;1087.16;1091.33;1527800000;1091.33
2004-03-23;1095.40;1101.52;1091.57;1093.95;1458200000;1093.95
2004-03-22;1109.78;1109.78;1089.54;1095.40;1452300000;1095.40
2004-03-19;1122.32;1122.72;1109.69;1109.78;1457400000;1109.78
2004-03-18;1123.75;1125.50;1113.25;1122.32;1369200000;1122.32
2004-03-17;1110.70;1125.76;1110.70;1123.75;1490100000;1123.75
2004-03-16;1104.49;1113.76;1102.61;1110.70;1500700000;1110.70
2004-03-15;1120.57;1120.57;1103.36;1104.49;1600600000;1104.49
2004-03-12;1106.78;1120.63;1106.78;1120.57;1388500000;1120.57
2004-03-11;1123.89;1125.96;1105.87;1106.78;1889900000;1106.78
2004-03-10;1140.58;1141.45;1122.53;1123.89;1648400000;1123.89
2004-03-09;1147.20;1147.32;1136.84;1140.58;1499400000;1140.58
2004-03-08;1156.86;1159.94;1146.97;1147.20;1254400000;1147.20
2004-03-05;1154.87;1163.23;1148.77;1156.86;1398200000;1156.86
2004-03-04;1151.03;1154.97;1149.81;1154.87;1265800000;1154.87
2004-03-03;1149.10;1152.44;1143.78;1151.03;1334500000;1151.03
2004-03-02;1155.97;1156.54;1147.31;1149.10;1476000000;1149.10
2004-03-01;1144.94;1157.45;1144.94;1155.97;1497100000;1155.97
2004-02-27;1145.80;1151.68;1141.80;1144.94;1540400000;1144.94
2004-02-26;1143.67;1147.23;1138.62;1144.91;1383900000;1144.91
2004-02-25;1139.09;1145.24;1138.96;1143.67;1360700000;1143.67
2004-02-24;1140.99;1144.54;1134.43;1139.09;1543600000;1139.09
2004-02-23;1144.11;1146.69;1136.98;1140.99;1380400000;1140.99
2004-02-20;1147.06;1149.81;1139.00;1144.11;1479600000;1144.11
2004-02-19;1151.82;1158.57;1146.85;1147.06;1562800000;1147.06
2004-02-18;1156.99;1157.40;1149.54;1151.82;1382400000;1151.82
2004-02-17;1145.81;1158.98;1145.81;1156.99;1396500000;1156.99
2004-02-13;1152.11;1156.88;1143.24;1145.81;1329200000;1145.81
2004-02-12;1157.76;1157.76;1151.44;1152.11;1464300000;1152.11
2004-02-11;1145.54;1158.89;1142.33;1157.76;1699300000;1157.76
2004-02-10;1139.81;1147.02;1138.70;1145.54;1403900000;1145.54
2004-02-09;1142.76;1144.46;1139.21;1139.81;1303500000;1139.81
2004-02-06;1128.59;1142.79;1128.39;1142.76;1477600000;1142.76
2004-02-05;1126.52;1131.17;1124.44;1128.59;1566600000;1128.59
2004-02-04;1136.03;1136.03;1124.74;1126.52;1634800000;1126.52
2004-02-03;1135.26;1137.44;1131.33;1136.03;1476900000;1136.03
2004-02-02;1131.13;1142.45;1127.87;1135.26;1599200000;1135.26
2004-01-30;1134.11;1134.17;1127.73;1131.13;1635000000;1131.13
2004-01-29;1128.48;1134.39;1122.38;1134.11;1921900000;1134.11
2004-01-28;1144.05;1149.14;1126.50;1128.48;1842000000;1128.48
2004-01-27;1155.37;1155.37;1144.05;1144.05;1673100000;1144.05
2004-01-26;1141.55;1155.38;1141.00;1155.37;1480600000;1155.37
2004-01-23;1143.94;1150.31;1136.85;1141.55;1561200000;1141.55
2004-01-22;1147.62;1150.51;1143.01;1143.94;1693700000;1143.94
2004-01-21;1138.77;1149.21;1134.62;1147.62;1757600000;1147.62
2004-01-20;1139.83;1142.93;1135.40;1138.77;1698200000;1138.77
2004-01-16;1132.05;1139.83;1132.05;1139.83;1721100000;1139.83
2004-01-15;1130.52;1137.11;1124.54;1132.05;1695000000;1132.05
2004-01-14;1121.22;1130.75;1121.22;1130.52;1514600000;1130.52
2004-01-13;1127.23;1129.07;1115.19;1121.22;1595900000;1121.22
2004-01-12;1121.86;1127.85;1120.90;1127.23;1510200000;1127.23
2004-01-09;1131.92;1131.92;1120.90;1121.86;1720700000;1121.86
2004-01-08;1126.33;1131.92;1124.91;1131.92;1868400000;1131.92
2004-01-07;1123.67;1126.33;1116.45;1126.33;1704900000;1126.33
2004-01-06;1122.22;1124.46;1118.44;1123.67;1494500000;1123.67
2004-01-05;1108.48;1122.22;1108.48;1122.22;1578200000;1122.22
2004-01-02;1111.92;1118.85;1105.08;1108.48;1153200000;1108.48
2003-12-31;1109.64;1112.56;1106.21;1111.92;1027500000;1111.92
2003-12-30;1109.48;1109.75;1106.41;1109.64;1012600000;1109.64
2003-12-29;1095.89;1109.48;1095.89;1109.48;1058800000;1109.48
2003-12-26;1094.04;1098.47;1094.04;1095.89;356070000;1095.89
2003-12-24;1096.02;1096.40;1092.73;1094.04;518060000;1094.04
2003-12-23;1092.94;1096.95;1091.73;1096.02;1145300000;1096.02
2003-12-22;1088.66;1092.94;1086.14;1092.94;1251700000;1092.94
2003-12-19;1089.18;1091.06;1084.19;1088.66;1657300000;1088.66
2003-12-18;1076.48;1089.50;1076.48;1089.18;1579900000;1089.18
2003-12-17;1075.13;1076.54;1071.14;1076.48;1441700000;1076.48
2003-12-16;1068.04;1075.94;1068.04;1075.13;1547900000;1075.13
2003-12-15;1074.14;1082.79;1068.00;1068.04;1520800000;1068.04
2003-12-12;1071.21;1074.76;1067.64;1074.14;1223100000;1074.14
2003-12-11;1059.05;1073.63;1059.05;1071.21;1441100000;1071.21
2003-12-10;1060.18;1063.02;1053.41;1059.05;1444000000;1059.05
2003-12-09;1069.30;1071.94;1059.16;1060.18;1465500000;1060.18
2003-12-08;1061.50;1069.59;1060.93;1069.30;1218900000;1069.30
2003-12-05;1069.72;1069.72;1060.09;1061.50;1265900000;1061.50
2003-12-04;1064.73;1070.37;1063.15;1069.72;1463100000;1069.72
2003-12-03;1066.62;1074.30;1064.63;1064.73;1441700000;1064.73
2003-12-02;1070.12;1071.22;1065.22;1066.62;1383200000;1066.62
2003-12-01;1058.20;1070.47;1058.20;1070.12;1375000000;1070.12
2003-11-28;1058.45;1060.63;1056.77;1058.20;487220000;1058.20
2003-11-26;1053.89;1058.45;1048.28;1058.45;1097700000;1058.45
2003-11-25;1052.08;1058.05;1049.31;1053.89;1333700000;1053.89
2003-11-24;1035.28;1052.08;1035.28;1052.08;1302800000;1052.08
2003-11-21;1033.65;1037.57;1031.20;1035.28;1273800000;1035.28
2003-11-20;1042.44;1046.48;1033.42;1033.65;1326700000;1033.65
2003-11-19;1034.15;1043.95;1034.15;1042.44;1326200000;1042.44
2003-11-18;1043.63;1048.77;1034.00;1034.15;1354300000;1034.15
2003-11-17;1050.35;1050.35;1035.28;1043.63;1374300000;1043.63
2003-11-14;1058.41;1063.65;1048.11;1050.35;1356100000;1050.35
2003-11-13;1058.56;1059.62;1052.96;1058.41;1383000000;1058.41
2003-11-12;1046.57;1059.10;1046.57;1058.53;1349300000;1058.53
2003-11-11;1047.11;1048.23;1043.46;1046.57;1162500000;1046.57
2003-11-10;1053.21;1053.65;1045.58;1047.11;1243600000;1047.11
2003-11-07;1058.05;1062.39;1052.17;1053.21;1440500000;1053.21
2003-11-06;1051.81;1058.94;1046.93;1058.05;1453900000;1058.05
2003-11-05;1053.25;1054.54;1044.88;1051.81;1401800000;1051.81
2003-11-04;1059.02;1059.02;1051.70;1053.25;1417600000;1053.25
2003-11-03;1050.71;1061.44;1050.71;1059.02;1378200000;1059.02
2003-10-31;1046.94;1053.09;1046.94;1050.71;1498900000;1050.71
2003-10-30;1048.11;1052.81;1043.82;1046.94;1629700000;1046.94
2003-10-29;1046.79;1049.83;1043.35;1048.11;1562600000;1048.11
2003-10-28;1031.13;1046.79;1031.13;1046.79;1629200000;1046.79
2003-10-27;1028.91;1037.75;1028.91;1031.13;1371800000;1031.13
2003-10-24;1033.77;1033.77;1018.32;1028.91;1420300000;1028.91
2003-10-23;1030.36;1035.44;1025.89;1033.77;1604300000;1033.77
2003-10-22;1046.03;1046.03;1028.39;1030.36;1647200000;1030.36
2003-10-21;1044.68;1048.57;1042.59;1046.03;1498000000;1046.03
2003-10-20;1039.32;1044.69;1036.13;1044.68;1172600000;1044.68
2003-10-17;1050.07;1051.89;1036.57;1039.32;1352000000;1039.32
2003-10-16;1046.76;1052.94;1044.04;1050.07;1417700000;1050.07
2003-10-15;1049.48;1053.79;1043.15;1046.76;1521100000;1046.76
2003-10-14;1045.35;1049.49;1040.84;1049.48;1271900000;1049.48
2003-10-13;1038.06;1048.90;1038.06;1045.35;1040500000;1045.35
2003-10-10;1038.73;1040.84;1035.74;1038.06;1108100000;1038.06
2003-10-09;1033.78;1048.28;1033.78;1038.73;1578700000;1038.73
2003-10-08;1039.25;1040.06;1030.96;1033.78;1262500000;1033.78
2003-10-07;1034.35;1039.25;1026.27;1039.25;1279500000;1039.25
2003-10-06;1029.85;1036.48;1029.15;1034.35;1025800000;1034.35
2003-10-03;1020.24;1039.31;1020.24;1029.85;1570500000;1029.85
2003-10-02;1018.22;1021.87;1013.38;1020.24;1269300000;1020.24
2003-10-01;995.97;1018.22;995.97;1018.22;1566300000;1018.22
2003-09-30;1006.58;1006.58;990.36;995.97;1590500000;995.97
2003-09-29;996.85;1006.89;995.31;1006.58;1366500000;1006.58
2003-09-26;1003.27;1003.45;996.08;996.85;1472500000;996.85
2003-09-25;1009.38;1015.97;1003.26;1003.27;1530000000;1003.27
2003-09-24;1029.03;1029.83;1008.93;1009.38;1556000000;1009.38
2003-09-23;1022.82;1030.12;1021.54;1029.03;1301700000;1029.03
2003-09-22;1036.30;1036.30;1018.30;1022.82;1278800000;1022.82
2003-09-19;1039.58;1040.29;1031.89;1036.30;1518600000;1036.30
2003-09-18;1025.97;1040.16;1025.75;1039.58;1498800000;1039.58
2003-09-17;1029.32;1031.34;1024.53;1025.97;1338210000;1025.97
2003-09-16;1014.81;1029.66;1014.81;1029.32;1403200000;1029.32
2003-09-15;1018.63;1019.79;1013.59;1014.81;1151300000;1014.81
2003-09-12;1016.42;1019.65;1007.71;1018.63;1236700000;1018.63
2003-09-11;1010.92;1020.88;1010.92;1016.42;1335900000;1016.42
2003-09-10;1023.17;1023.17;1009.74;1010.92;1582100000;1010.92
2003-09-09;1031.64;1031.64;1021.14;1023.17;1414800000;1023.17
2003-09-08;1021.39;1032.41;1021.39;1031.64;1299300000;1031.64
2003-09-05;1027.97;1029.21;1018.19;1021.39;1465200000;1021.39
2003-09-04;1026.27;1029.17;1022.19;1027.97;1453900000;1027.97
2003-09-03;1021.99;1029.34;1021.99;1026.27;1675600000;1026.27
2003-09-02;1008.01;1022.59;1005.73;1021.99;1470500000;1021.99
2003-08-29;1002.84;1008.85;999.52;1008.01;945100000;1008.01
2003-08-28;996.79;1004.12;991.42;1002.84;1165200000;1002.84
2003-08-27;996.73;998.05;993.33;996.79;1051400000;996.79
2003-08-26;993.71;997.93;983.57;996.73;1178700000;996.73
2003-08-25;993.06;993.71;987.91;993.71;971700000;993.71
2003-08-22;1003.27;1011.01;992.62;993.06;1308900000;993.06
2003-08-21;1000.30;1009.53;999.33;1003.27;1407100000;1003.27
2003-08-20;1002.35;1003.54;996.62;1000.30;1210800000;1000.30
2003-08-19;999.74;1003.30;995.30;1002.35;1300600000;1002.35
2003-08-18;990.67;1000.35;990.67;999.74;1127600000;999.74
2003-08-15;990.51;992.39;987.10;990.67;636370000;990.67
2003-08-14;984.03;991.91;980.36;990.51;1186800000;990.51
2003-08-13;990.35;992.50;980.85;984.03;1208800000;984.03
2003-08-12;980.59;990.41;979.90;990.35;1132300000;990.35
2003-08-11;977.59;985.46;974.21;980.59;1022200000;980.59
2003-08-08;974.12;980.57;973.83;977.59;1086600000;977.59
2003-08-07;967.08;974.89;963.82;974.12;1389300000;974.12
2003-08-06;965.46;975.74;960.84;967.08;1491000000;967.08
2003-08-05;982.82;982.82;964.97;965.46;1351700000;965.46
2003-08-04;980.15;985.75;966.79;982.82;1318700000;982.82
2003-08-01;990.31;990.31;978.86;980.15;1390600000;980.15
2003-07-31;987.49;1004.59;987.49;990.31;1608000000;990.31
2003-07-30;989.28;992.62;985.96;987.49;1391900000;987.49
2003-07-29;996.52;998.64;984.15;989.28;1508900000;989.28
2003-07-28;998.68;1000.68;993.59;996.52;1328600000;996.52
2003-07-25;981.60;998.71;977.49;998.68;1397500000;998.68
2003-07-24;988.61;998.89;981.07;981.60;1559000000;981.60
2003-07-23;988.11;989.86;979.79;988.61;1362700000;988.61
2003-07-22;978.80;990.29;976.08;988.11;1439700000;988.11
2003-07-21;993.32;993.32;975.63;978.80;1254200000;978.80
2003-07-18;981.73;994.25;981.71;993.32;1365200000;993.32
2003-07-17;994.00;994.00;978.60;981.73;1661400000;981.73
2003-07-16;1000.42;1003.47;989.30;994.09;1662000000;994.09
2003-07-15;1003.86;1009.61;996.67;1000.42;1518600000;1000.42
2003-07-14;998.14;1015.41;998.14;1003.86;1448900000;1003.86
2003-07-11;988.70;1000.86;988.70;998.14;1212700000;998.14
2003-07-10;1002.21;1002.21;983.63;988.70;1465700000;988.70
2003-07-09;1007.84;1010.43;998.17;1002.21;1618000000;1002.21
2003-07-08;1004.42;1008.92;998.73;1007.84;1565700000;1007.84
2003-07-07;985.70;1005.56;985.70;1004.42;1429100000;1004.42
2003-07-03;993.75;995.00;983.34;985.70;775900000;985.70
2003-07-02;982.32;993.78;982.32;993.75;1519300000;993.75
2003-07-01;974.50;983.26;962.10;982.32;1460200000;982.32
2003-06-30;976.22;983.61;973.60;974.50;1587200000;974.50
2003-06-27;985.82;988.88;974.29;976.22;1267800000;976.22
2003-06-26;975.32;986.53;973.80;985.82;1387400000;985.82
2003-06-25;983.45;991.64;974.86;975.32;1459200000;975.32
2003-06-24;981.64;987.84;979.08;983.45;1388300000;983.45
2003-06-23;995.69;995.69;977.40;981.64;1398100000;981.64
2003-06-20;994.70;1002.09;993.36;995.69;1698000000;995.69
2003-06-19;1010.09;1011.22;993.08;994.70;1530100000;994.70
2003-06-18;1011.66;1015.12;1004.61;1010.09;1488900000;1010.09
2003-06-17;1010.74;1015.33;1007.04;1011.66;1479700000;1011.66
2003-06-16;988.61;1010.86;988.61;1010.74;1345900000;1010.74
2003-06-13;998.51;1000.92;984.27;988.61;1271600000;988.61
2003-06-12;997.48;1002.74;991.27;998.51;1553100000;998.51
2003-06-11;984.84;997.48;981.61;997.48;1520000000;997.48
2003-06-10;975.93;984.84;975.93;984.84;1275400000;984.84
2003-06-09;987.76;987.76;972.59;975.93;1307000000;975.93
2003-06-06;990.14;1007.69;986.01;987.76;1837200000;987.76
2003-06-05;986.24;990.14;978.13;990.14;1693100000;990.14
2003-06-04;971.56;987.85;970.72;986.24;1618700000;986.24
2003-06-03;967.00;973.02;964.47;971.56;1450200000;971.56
2003-06-02;963.59;979.11;963.59;967.00;1662500000;967.00
2003-05-30;949.64;965.38;949.64;963.59;1688800000;963.59
2003-05-29;953.22;962.08;946.23;949.64;1685800000;949.64
2003-05-28;951.48;959.39;950.12;953.22;1559000000;953.22
2003-05-27;933.22;952.76;927.33;951.48;1532000000;951.48
2003-05-23;931.87;935.20;927.42;933.22;1201000000;933.22
2003-05-22;923.42;935.30;922.54;931.87;1448500000;931.87
2003-05-21;919.73;923.85;914.91;923.42;1457800000;923.42
2003-05-20;920.77;925.34;912.05;919.73;1505300000;919.73
2003-05-19;944.30;944.30;920.23;920.77;1375700000;920.77
2003-05-16;946.67;948.65;938.60;944.30;1505500000;944.30
2003-05-15;939.28;948.23;938.79;946.67;1508700000;946.67
2003-05-14;942.30;947.29;935.24;939.28;1401800000;939.28
2003-05-13;945.11;947.51;938.91;942.30;1418100000;942.30
2003-05-12;933.41;946.84;929.30;945.11;1378800000;945.11
2003-05-09;920.27;933.77;920.27;933.41;1326100000;933.41
2003-05-08;929.62;929.62;919.72;920.27;1379600000;920.27
2003-05-07;934.39;937.22;926.41;929.62;1531900000;929.62
2003-05-06;926.55;939.61;926.38;934.39;1649600000;934.39
2003-05-05;930.08;933.88;924.55;926.55;1446300000;926.55
2003-05-02;916.30;930.56;912.35;930.08;1554300000;930.08
2003-05-01;916.92;919.68;902.83;916.30;1397500000;916.30
2003-04-30;917.84;922.01;911.70;916.92;1788510000;916.92
2003-04-29;914.84;924.24;911.10;917.84;1525600000;917.84
2003-04-28;898.81;918.15;898.81;914.84;1273000000;914.84
2003-04-25;911.43;911.43;897.52;898.81;1335800000;898.81
2003-04-24;919.02;919.02;906.69;911.43;1648100000;911.43
2003-04-23;911.37;919.74;909.89;919.02;1667200000;919.02
2003-04-22;892.01;911.74;886.70;911.37;1631200000;911.37
2003-04-21;893.58;898.01;888.17;892.01;1118700000;892.01
2003-04-17;879.91;893.83;879.20;893.58;1430600000;893.58
2003-04-16;890.81;896.77;877.93;879.91;1587600000;879.91
2003-04-15;885.23;891.27;881.85;890.81;1460200000;890.81
2003-04-14;868.30;885.26;868.30;885.23;1131000000;885.23
2003-04-11;871.58;883.34;865.92;868.30;1141600000;868.30
2003-04-10;865.99;871.78;862.76;871.58;1275300000;871.58
2003-04-09;878.29;887.35;865.72;865.99;1293700000;865.99
2003-04-08;879.93;883.11;874.68;878.29;1235400000;878.29
2003-04-07;878.85;904.89;878.85;879.93;1494000000;879.93
2003-04-04;876.45;882.73;874.23;878.85;1241200000;878.85
2003-04-03;880.90;885.89;876.12;876.45;1339500000;876.45
2003-04-02;858.48;884.57;858.48;880.90;1589800000;880.90
2003-04-01;848.18;861.28;847.85;858.48;1461600000;858.48
2003-03-31;863.50;863.50;843.68;848.18;1495500000;848.18
2003-03-28;868.52;869.88;860.83;863.50;1227000000;863.50
2003-03-27;869.95;874.15;858.09;868.52;1232900000;868.52
2003-03-26;874.74;875.80;866.47;869.95;1319700000;869.95
2003-03-25;864.23;879.87;862.59;874.74;1333400000;874.74
2003-03-24;895.79;895.79;862.02;864.23;1293000000;864.23
2003-03-21;875.84;895.90;875.84;895.79;1883710000;895.79
2003-03-20;874.02;879.60;859.01;875.67;1439100000;875.67
2003-03-19;866.45;874.99;861.21;874.02;1473400000;874.02
2003-03-18;862.79;866.94;857.36;866.45;1555100000;866.45
2003-03-17;833.27;862.79;827.17;862.79;1700420000;862.79
2003-03-14;831.89;841.39;828.26;833.27;1541900000;833.27
2003-03-13;804.19;832.02;804.19;831.90;1816300000;831.90
2003-03-12;800.73;804.19;788.90;804.19;1620000000;804.19
2003-03-11;807.48;814.25;800.30;800.73;1427700000;800.73
2003-03-10;828.89;828.89;806.57;807.48;1255000000;807.48
2003-03-07;822.10;829.55;811.23;828.89;1368500000;828.89
2003-03-06;829.85;829.85;819.85;822.10;1299200000;822.10
2003-03-05;821.99;829.87;819.00;829.85;1332700000;829.85
2003-03-04;834.81;835.43;821.96;821.99;1256600000;821.99
2003-03-03;841.15;852.34;832.74;834.81;1208900000;834.81
2003-02-28;837.28;847.00;837.28;841.15;1373300000;841.15
2003-02-27;827.55;842.19;827.55;837.28;1287800000;837.28
2003-02-26;838.57;840.10;826.68;827.55;1374400000;827.55
2003-02-25;832.58;839.55;818.54;838.57;1483700000;838.57
2003-02-24;848.17;848.17;832.16;832.58;1229200000;832.58
2003-02-21;837.10;852.28;831.48;848.17;1398200000;848.17
2003-02-20;845.13;849.37;836.56;837.10;1194100000;837.10
2003-02-19;851.17;851.17;838.79;845.13;1075600000;845.13
2003-02-18;834.89;852.87;834.89;851.17;1250800000;851.17
2003-02-14;817.37;834.89;815.03;834.89;1404600000;834.89
2003-02-13;818.68;821.25;806.29;817.37;1489300000;817.37
2003-02-12;829.20;832.12;818.49;818.68;1260500000;818.68
2003-02-11;835.97;843.02;825.09;829.20;1307000000;829.20
2003-02-10;829.69;837.16;823.53;835.97;1238200000;835.97
2003-02-07;838.15;845.73;826.70;829.69;1276800000;829.69
2003-02-06;843.59;844.23;833.25;838.15;1430900000;838.15
2003-02-05;848.20;861.63;842.11;843.59;1450800000;843.59
2003-02-04;860.32;860.32;840.19;848.20;1451600000;848.20
2003-02-03;855.70;864.64;855.70;860.32;1258500000;860.32
2003-01-31;844.61;858.33;840.34;855.70;1578530000;855.70
2003-01-30;864.36;865.48;843.74;844.61;1510300000;844.61
2003-01-29;858.54;868.72;845.86;864.36;1595400000;864.36
2003-01-28;847.48;860.76;847.48;858.54;1459100000;858.54
2003-01-27;861.40;863.95;844.25;847.48;1435900000;847.48
2003-01-24;887.34;887.34;859.71;861.40;1574800000;861.40
2003-01-23;878.36;890.25;876.89;887.34;1744550000;887.34
2003-01-22;887.62;889.74;877.64;878.36;1560800000;878.36
2003-01-21;901.78;906.00;887.62;887.62;1335200000;887.62
2003-01-17;914.60;914.60;899.02;901.78;1358200000;901.78
2003-01-16;918.22;926.03;911.98;914.60;1534600000;914.60
2003-01-15;931.66;932.59;916.70;918.22;1432100000;918.22
2003-01-14;926.26;931.66;921.72;931.66;1379400000;931.66
2003-01-13;927.57;935.05;922.05;926.26;1396300000;926.26
2003-01-10;927.58;932.89;917.66;927.57;1485400000;927.57
2003-01-09;909.93;928.31;909.93;927.57;1560300000;927.57
2003-01-08;922.93;922.93;908.32;909.93;1467600000;909.93
2003-01-07;929.01;930.81;919.93;922.93;1545200000;922.93
2003-01-06;908.59;931.77;908.59;929.01;1435900000;929.01
2003-01-03;909.03;911.25;903.07;908.59;1130800000;908.59
2003-01-02;879.82;909.03;879.82;909.03;1229200000;909.03
2002-12-31;879.39;881.93;869.45;879.82;1088500000;879.82
2002-12-30;875.40;882.10;870.23;879.39;1057800000;879.39
2002-12-27;889.66;890.46;873.62;875.40;758400000;875.40
2002-12-26;892.47;903.89;887.48;889.66;721100000;889.66
2002-12-24;897.38;897.38;892.29;892.47;458310000;892.47
2002-12-23;895.74;902.43;892.26;897.38;1112100000;897.38
2002-12-20;884.25;897.79;884.25;895.76;1782730000;895.76
2002-12-19;890.02;899.19;880.32;884.25;1385900000;884.25
2002-12-18;902.99;902.99;887.82;891.12;1446200000;891.12
2002-12-17;910.40;911.22;901.74;902.99;1251800000;902.99
2002-12-16;889.48;910.42;889.48;910.40;1271600000;910.40
2002-12-13;901.58;901.58;888.48;889.48;1330800000;889.48
2002-12-12;904.96;908.37;897.00;901.58;1255300000;901.58
2002-12-11;904.45;909.94;896.48;904.96;1285100000;904.96
2002-12-10;892.00;904.95;892.00;904.45;1286600000;904.45
2002-12-09;912.23;912.23;891.97;892.00;1320800000;892.00
2002-12-06;906.55;915.48;895.96;912.23;1241100000;912.23
2002-12-05;917.58;921.49;905.90;906.55;1250200000;906.55
2002-12-04;920.75;925.25;909.51;917.58;1588900000;917.58
2002-12-03;934.53;934.53;918.73;920.75;1488400000;920.75
2002-12-02;936.31;954.28;927.72;934.53;1612000000;934.53
2002-11-29;938.87;941.82;935.58;936.31;643460000;936.31
2002-11-27;913.31;940.41;913.31;938.87;1350300000;938.87
2002-11-26;932.87;932.87;912.10;913.31;1543600000;913.31
2002-11-25;930.55;937.15;923.31;932.87;1574000000;932.87
2002-11-22;933.76;937.28;928.41;930.55;1626800000;930.55
2002-11-21;914.15;935.13;914.15;933.76;2415100000;933.76
2002-11-20;896.74;915.01;894.93;914.15;1517300000;914.15
2002-11-19;900.36;905.45;893.09;896.74;1337400000;896.74
2002-11-18;909.83;915.91;899.48;900.36;1282600000;900.36
2002-11-15;904.27;910.21;895.35;909.83;1400100000;909.83
2002-11-14;882.53;904.27;882.53;904.27;1519000000;904.27
2002-11-13;882.95;892.51;872.05;882.53;1463400000;882.53
2002-11-12;876.19;894.30;876.19;882.95;1377100000;882.95
2002-11-11;894.74;894.74;874.63;876.19;1113000000;876.19
2002-11-08;902.65;910.11;891.62;894.74;1446500000;894.74
2002-11-07;923.76;923.76;898.68;902.65;1466900000;902.65
2002-11-06;915.39;925.66;905.00;923.76;1674000000;923.76
2002-11-05;908.35;915.83;904.91;915.39;1354100000;915.39
2002-11-04;900.96;924.58;900.96;908.35;1645900000;908.35
2002-11-01;885.76;903.42;877.71;900.96;1450400000;900.96
2002-10-31;890.71;898.83;879.75;885.76;1641300000;885.76
2002-10-30;882.15;895.28;879.19;890.71;1422300000;890.71
2002-10-29;890.23;890.64;867.91;882.15;1529700000;882.15
2002-10-28;897.65;907.44;886.15;890.23;1382600000;890.23
2002-10-25;882.50;897.71;877.03;897.65;1340400000;897.65
2002-10-24;896.14;902.94;879.00;882.50;1700570000;882.50
2002-10-23;890.16;896.14;873.82;896.14;1593900000;896.14
2002-10-22;899.72;899.72;882.40;890.16;1549200000;890.16
2002-10-21;884.39;900.69;873.06;899.72;1447000000;899.72
2002-10-18;879.20;886.68;866.58;884.39;1423100000;884.39
2002-10-17;860.02;885.35;860.02;879.20;1780390000;879.20
2002-10-16;881.27;881.27;856.28;860.02;1585000000;860.02
2002-10-15;841.44;881.27;841.44;881.27;1956000000;881.27
2002-10-14;835.32;844.39;828.37;841.44;1200300000;841.44
2002-10-11;803.92;843.27;803.92;835.32;1854130000;835.32
2002-10-10;776.76;806.51;768.63;803.92;2090230000;803.92
2002-10-09;798.55;798.55;775.80;776.76;1885030000;776.76
2002-10-08;785.28;808.86;779.50;798.55;1938430000;798.55
2002-10-07;800.58;808.21;782.96;785.28;1576500000;785.28
2002-10-04;818.95;825.90;794.10;800.58;1835930000;800.58
2002-10-03;827.91;840.02;817.25;818.95;1674500000;818.95
2002-10-02;843.77;851.93;826.50;827.91;1668900000;827.91
2002-10-01;815.28;847.93;812.82;847.91;1780900000;847.91
2002-09-30;827.37;827.37;800.20;815.28;1721870000;815.28
2002-09-27;854.95;854.95;826.84;827.37;1507300000;827.37
2002-09-26;839.66;856.60;839.66;854.95;1650000000;854.95
2002-09-25;819.27;844.22;818.46;839.66;1651500000;839.66
2002-09-24;833.70;833.70;817.38;819.29;1670240000;819.29
2002-09-23;845.39;845.39;825.76;833.70;1381100000;833.70
2002-09-20;843.32;849.32;839.09;845.39;1792800000;845.39
2002-09-19;869.46;869.46;843.09;843.32;1524000000;843.32
2002-09-18;873.52;878.45;857.39;869.46;1501000000;869.46
2002-09-17;891.10;902.68;872.38;873.52;1448600000;873.52
2002-09-16;889.81;891.84;878.91;891.10;1001400000;891.10
2002-09-13;886.91;892.75;877.05;889.81;1271000000;889.81
2002-09-12;909.45;909.45;884.84;886.91;1191600000;886.91
2002-09-11;910.63;924.02;908.47;909.45;846600000;909.45
2002-09-10;902.96;909.89;900.50;909.58;1186400000;909.58
2002-09-09;893.92;907.34;882.92;902.96;1130600000;902.96
2002-09-06;879.15;899.07;879.15;893.92;1184500000;893.92
2002-09-05;893.40;893.40;870.50;879.15;1401300000;879.15
2002-09-04;878.02;896.10;875.73;893.40;1372100000;893.40
2002-09-03;916.07;916.07;877.51;878.02;1289800000;878.02
2002-08-30;917.80;928.15;910.17;916.07;929900000;916.07
2002-08-29;917.87;924.59;903.33;917.80;1271100000;917.80
2002-08-28;934.82;934.82;913.21;917.87;1146600000;917.87
2002-08-27;947.95;955.82;930.36;934.82;1307700000;934.82
2002-08-26;940.86;950.80;930.42;947.95;1016900000;947.95
2002-08-23;962.70;962.70;937.17;940.86;1071500000;940.86
2002-08-22;949.36;965.00;946.43;962.70;1373000000;962.70
2002-08-21;937.43;951.59;931.32;949.36;1353100000;949.36
2002-08-20;950.70;950.70;931.86;937.43;1308500000;937.43
2002-08-19;928.77;951.17;927.21;950.70;1299800000;950.70
2002-08-16;930.25;935.38;916.21;928.77;1265300000;928.77
2002-08-15;919.62;933.29;918.17;930.25;1505100000;930.25
2002-08-14;884.21;920.21;876.20;919.62;1533800000;919.62
2002-08-13;903.80;911.71;883.62;884.21;1297700000;884.21
2002-08-12;908.64;908.64;892.38;903.80;1036500000;903.80
2002-08-09;898.73;913.95;890.77;908.64;1294900000;908.64
2002-08-08;876.77;905.84;875.17;905.46;1646700000;905.46
2002-08-07;859.57;878.74;854.15;876.77;1490400000;876.77
2002-08-06;834.60;874.44;834.60;859.57;1514100000;859.57
2002-08-05;864.24;864.24;833.44;834.60;1425500000;834.60
2002-08-02;884.40;884.72;853.95;864.24;1538100000;864.24
2002-08-01;911.62;911.62;882.48;884.66;1672200000;884.66
2002-07-31;902.78;911.64;889.88;911.62;2049360000;911.62
2002-07-30;898.96;909.81;884.70;902.78;1826090000;902.78
2002-07-29;852.84;898.96;852.84;898.96;1778650000;898.96
2002-07-26;838.68;852.85;835.92;852.84;1796100000;852.84
2002-07-25;843.42;853.83;816.11;838.68;2424700000;838.68
2002-07-24;797.71;844.32;775.68;843.43;2775560000;843.43
2002-07-23;819.85;827.69;796.13;797.70;2441020000;797.70
2002-07-22;847.76;854.13;813.26;819.85;2248060000;819.85
2002-07-19;881.56;881.56;842.07;847.75;2654100000;847.75
2002-07-18;905.45;907.80;880.60;881.56;1736300000;881.56
2002-07-17;901.05;926.52;895.03;906.04;2566500000;906.04
2002-07-16;917.93;918.65;897.13;900.94;1843700000;900.94
2002-07-15;921.39;921.39;876.46;917.93;2574800000;917.93
2002-07-12;927.37;934.31;913.71;921.39;1607400000;921.39
2002-07-11;920.47;929.16;900.94;927.37;2080480000;927.37
2002-07-10;952.83;956.34;920.29;920.47;1816900000;920.47
2002-07-09;976.98;979.63;951.71;952.83;1348900000;952.83
2002-07-08;989.03;993.56;972.91;976.98;1184400000;976.98
2002-07-05;953.99;989.07;953.99;989.03;699400000;989.03
2002-07-03;948.09;954.30;934.87;953.99;1527800000;953.99
2002-07-02;968.65;968.65;945.54;948.09;1823000000;948.09
2002-07-01;989.82;994.46;967.43;968.65;1425500000;968.65
2002-06-28;990.64;1001.79;988.31;989.82;2117000000;989.82
2002-06-27;973.53;990.67;963.74;990.64;1908600000;990.64
2002-06-26;976.14;977.43;952.92;973.53;2014290000;973.53
2002-06-25;992.72;1005.88;974.21;976.14;1513700000;976.14
2002-06-24;989.14;1002.11;970.85;992.72;1552600000;992.72
2002-06-21;1006.29;1006.29;985.65;989.14;1497200000;989.14
2002-06-20;1019.99;1023.33;1004.59;1006.29;1389700000;1006.29
2002-06-19;1037.14;1037.61;1017.88;1019.99;1336100000;1019.99
2002-06-18;1036.17;1040.83;1030.92;1037.14;1193100000;1037.14
2002-06-17;1007.27;1036.17;1007.27;1036.17;1236600000;1036.17
2002-06-14;1009.56;1009.56;981.63;1007.27;1549000000;1007.27
2002-06-13;1020.26;1023.47;1008.12;1009.56;1405500000;1009.56
2002-06-12;1013.26;1021.85;1002.58;1020.26;1795720000;1020.26
2002-06-11;1030.74;1039.04;1012.94;1013.60;1212400000;1013.60
2002-06-10;1027.53;1038.18;1025.45;1030.74;1226200000;1030.74
2002-06-07;1029.15;1033.02;1012.49;1027.53;1341300000;1027.53
2002-06-06;1049.90;1049.90;1026.91;1029.15;1601500000;1029.15
2002-06-05;1040.69;1050.11;1038.84;1049.90;1300100000;1049.90
2002-06-04;1040.68;1046.06;1030.52;1040.69;1466600000;1040.69
2002-06-03;1067.14;1070.74;1039.90;1040.68;1324300000;1040.68
2002-05-31;1064.66;1079.93;1064.66;1067.14;1277300000;1067.14
2002-05-30;1067.66;1069.50;1054.26;1064.66;1286600000;1064.66
2002-05-29;1074.55;1074.83;1067.66;1067.66;1081800000;1067.66
2002-05-28;1083.82;1085.98;1070.31;1074.55;996500000;1074.55
2002-05-24;1097.08;1097.08;1082.19;1083.82;885400000;1083.82
2002-05-23;1086.02;1097.10;1080.55;1097.08;1192900000;1097.08
2002-05-22;1079.88;1086.02;1075.64;1086.02;1136300000;1086.02
2002-05-21;1091.88;1099.55;1079.08;1079.88;1200500000;1079.88
2002-05-20;1106.59;1106.59;1090.61;1091.88;989800000;1091.88
2002-05-17;1098.23;1106.59;1096.77;1106.59;1274400000;1106.59
2002-05-16;1091.07;1099.29;1089.17;1098.23;1256600000;1098.23
2002-05-15;1097.28;1104.23;1088.94;1091.07;1420200000;1091.07
2002-05-14;1074.56;1097.71;1074.56;1097.28;1414500000;1097.28
2002-05-13;1054.99;1074.84;1053.90;1074.56;1088600000;1074.56
2002-05-10;1073.01;1075.43;1053.93;1054.99;1171900000;1054.99
2002-05-09;1088.85;1088.85;1072.23;1073.01;1153000000;1073.01
2002-05-08;1049.49;1088.92;1049.49;1088.85;1502000000;1088.85
2002-05-07;1052.67;1058.67;1048.96;1049.49;1354700000;1049.49
2002-05-06;1073.43;1075.96;1052.65;1052.67;1122600000;1052.67
2002-05-03;1084.56;1084.56;1068.89;1073.43;1284500000;1073.43
2002-05-02;1086.46;1091.42;1079.46;1084.56;1364000000;1084.56
2002-05-01;1076.92;1088.32;1065.29;1086.46;1451400000;1086.46
2002-04-30;1065.45;1082.62;1063.46;1076.92;1628600000;1076.92
2002-04-29;1076.32;1078.95;1063.62;1065.45;1314700000;1065.45
2002-04-26;1091.48;1096.77;1076.31;1076.32;1374200000;1076.32
2002-04-25;1093.14;1094.36;1084.81;1091.48;1517400000;1091.48
2002-04-24;1100.96;1108.46;1092.51;1093.14;1373200000;1093.14
2002-04-23;1107.83;1111.17;1098.94;1100.96;1388500000;1100.96
2002-04-22;1125.17;1125.17;1105.62;1107.83;1181800000;1107.83
2002-04-19;1124.47;1128.82;1122.59;1125.17;1185000000;1125.17
2002-04-18;1126.07;1130.49;1109.29;1124.47;1359300000;1124.47
2002-04-17;1128.37;1133.00;1123.37;1126.07;1376900000;1126.07
2002-04-16;1102.55;1129.40;1102.55;1128.37;1341300000;1128.37
2002-04-15;1111.01;1114.86;1099.41;1102.55;1120400000;1102.55
2002-04-12;1103.69;1112.77;1102.74;1111.01;1282100000;1111.01
2002-04-11;1130.47;1130.47;1102.42;1103.69;1505600000;1103.69
2002-04-10;1117.80;1131.76;1117.80;1130.47;1447900000;1130.47
2002-04-09;1125.29;1128.29;1116.73;1117.80;1235400000;1117.80
2002-04-08;1122.73;1125.41;1111.79;1125.29;1095300000;1125.29
2002-04-05;1126.34;1133.31;1119.49;1122.73;1110200000;1122.73
2002-04-04;1125.40;1130.45;1120.06;1126.34;1283800000;1126.34
2002-04-03;1136.76;1138.85;1119.68;1125.40;1219700000;1125.40
2002-04-02;1146.54;1146.54;1135.71;1136.76;1176700000;1136.76
2002-04-01;1147.39;1147.84;1132.87;1146.54;1050900000;1146.54
2002-03-28;1144.58;1154.45;1144.58;1147.39;1147600000;1147.39
2002-03-27;1138.49;1146.95;1135.33;1144.58;1180100000;1144.58
2002-03-26;1131.87;1147.00;1131.61;1138.49;1223600000;1138.49
2002-03-25;1148.70;1151.04;1131.87;1131.87;1057900000;1131.87
2002-03-22;1153.59;1156.49;1144.60;1148.70;1243300000;1148.70
2002-03-21;1151.85;1155.10;1139.48;1153.59;1339200000;1153.59
2002-03-20;1170.29;1170.29;1151.61;1151.85;1304900000;1151.85
2002-03-19;1165.55;1173.94;1165.55;1170.29;1255000000;1170.29
2002-03-18;1166.16;1172.73;1159.14;1165.55;1169500000;1165.55
2002-03-15;1153.04;1166.48;1153.04;1166.16;1493900000;1166.16
2002-03-14;1154.09;1157.83;1151.08;1153.04;1208800000;1153.04
2002-03-13;1165.58;1165.58;1151.01;1154.09;1354000000;1154.09
2002-03-12;1168.26;1168.26;1154.34;1165.58;1304400000;1165.58
2002-03-11;1164.31;1173.03;1159.58;1168.26;1210200000;1168.26
2002-03-08;1157.54;1172.76;1157.54;1164.31;1412000000;1164.31
2002-03-07;1162.77;1167.94;1150.69;1157.54;1517400000;1157.54
2002-03-06;1146.14;1165.29;1145.11;1162.77;1541300000;1162.77
2002-03-05;1153.84;1157.74;1144.78;1146.14;1549300000;1146.14
2002-03-04;1131.78;1153.84;1130.93;1153.84;1594300000;1153.84
2002-03-01;1106.73;1131.79;1106.73;1131.78;1456500000;1131.78
2002-02-28;1109.89;1121.57;1106.73;1106.73;1392200000;1106.73
2002-02-27;1109.38;1123.06;1102.26;1109.89;1393800000;1109.89
2002-02-26;1109.43;1115.05;1101.72;1109.38;1309200000;1109.38
2002-02-25;1089.84;1112.71;1089.84;1109.43;1367400000;1109.43
2002-02-22;1080.95;1093.93;1074.39;1089.84;1411000000;1089.84
2002-02-21;1097.98;1101.50;1080.24;1080.95;1381600000;1080.95
2002-02-20;1083.34;1098.32;1074.36;1097.98;1438900000;1097.98
2002-02-19;1104.18;1104.18;1082.24;1083.34;1189900000;1083.34
2002-02-15;1116.48;1117.09;1103.23;1104.18;1359200000;1104.18
2002-02-14;1118.51;1124.72;1112.30;1116.48;1272500000;1116.48
2002-02-13;1107.50;1120.56;1107.50;1118.51;1215900000;1118.51
2002-02-12;1111.94;1112.68;1102.98;1107.50;1094200000;1107.50
2002-02-11;1096.22;1112.01;1094.68;1111.94;1159400000;1111.94
2002-02-08;1080.17;1096.30;1079.91;1096.22;1371900000;1096.22
2002-02-07;1083.51;1094.03;1078.44;1080.17;1441600000;1080.17
2002-02-06;1090.02;1093.58;1077.78;1083.51;1665800000;1083.51
2002-02-05;1094.44;1100.96;1082.58;1090.02;1778300000;1090.02
2002-02-04;1122.20;1122.20;1092.25;1094.44;1437600000;1094.44
2002-02-01;1130.20;1130.20;1118.51;1122.20;1367200000;1122.20
2002-01-31;1113.57;1130.21;1113.30;1130.20;1557000000;1130.20
2002-01-30;1100.64;1113.79;1081.66;1113.57;2019600000;1113.57
2002-01-29;1133.06;1137.47;1098.74;1100.64;1812000000;1100.64
2002-01-28;1133.28;1138.63;1126.66;1133.06;1186800000;1133.06
2002-01-25;1132.15;1138.31;1127.82;1133.28;1345100000;1133.28
2002-01-24;1128.18;1139.50;1128.18;1132.15;1552800000;1132.15
2002-01-23;1119.31;1131.94;1117.43;1128.18;1479200000;1128.18
2002-01-22;1127.58;1135.26;1117.91;1119.31;1311600000;1119.31
2002-01-18;1138.88;1138.88;1124.45;1127.58;1333300000;1127.58
2002-01-17;1127.57;1139.27;1127.57;1138.88;1380100000;1138.88
2002-01-16;1146.19;1146.19;1127.49;1127.57;1482500000;1127.57
2002-01-15;1138.41;1148.81;1136.88;1146.19;1386900000;1146.19
2002-01-14;1145.60;1145.60;1138.15;1138.41;1286400000;1138.41
2002-01-11;1156.55;1159.41;1145.45;1145.60;1211900000;1145.60
2002-01-10;1155.14;1159.93;1150.85;1156.55;1299000000;1156.55
2002-01-09;1160.71;1174.26;1151.89;1155.14;1452000000;1155.14
2002-01-08;1164.89;1167.60;1157.46;1160.71;1258800000;1160.71
2002-01-07;1172.51;1176.97;1163.55;1164.89;1308300000;1164.89
2002-01-04;1165.27;1176.55;1163.42;1172.51;1513000000;1172.51
2002-01-03;1154.67;1165.27;1154.01;1165.27;1398900000;1165.27
2002-01-02;1148.08;1154.67;1136.23;1154.67;1171000000;1154.67
2001-12-31;1161.02;1161.16;1148.04;1148.08;943600000;1148.08
2001-12-28;1157.13;1164.64;1157.13;1161.02;917400000;1161.02
2001-12-27;1149.37;1157.13;1149.37;1157.13;876300000;1157.13
2001-12-26;1144.65;1159.18;1144.65;1149.37;791100000;1149.37
2001-12-24;1144.89;1147.83;1144.62;1144.65;439670000;1144.65
2001-12-21;1139.93;1147.46;1139.93;1144.89;1694000000;1144.89
2001-12-20;1149.56;1151.42;1139.93;1139.93;1490500000;1139.93
2001-12-19;1142.92;1152.44;1134.75;1149.56;1484900000;1149.56
2001-12-18;1134.36;1145.10;1134.36;1142.92;1354000000;1142.92
2001-12-17;1123.09;1137.30;1122.66;1134.36;1260400000;1134.36
2001-12-14;1119.38;1128.28;1114.53;1123.09;1306800000;1123.09
2001-12-13;1137.07;1137.07;1117.85;1119.38;1511500000;1119.38
2001-12-12;1136.76;1141.58;1126.01;1137.07;1449700000;1137.07
2001-12-11;1139.93;1150.89;1134.32;1136.76;1367200000;1136.76
2001-12-10;1158.31;1158.31;1139.66;1139.93;1218700000;1139.93
2001-12-07;1167.10;1167.10;1152.66;1158.31;1248200000;1158.31
2001-12-06;1170.35;1173.35;1164.43;1167.10;1487900000;1167.10
2001-12-05;1143.77;1173.62;1143.77;1170.35;1765300000;1170.35
2001-12-04;1129.90;1144.80;1128.86;1144.80;1318500000;1144.80
2001-12-03;1139.45;1139.45;1125.78;1129.90;1202900000;1129.90
2001-11-30;1140.20;1143.57;1135.89;1139.45;1343600000;1139.45
2001-11-29;1128.52;1140.40;1125.51;1140.20;1375700000;1140.20
2001-11-28;1149.50;1149.50;1128.29;1128.52;1423700000;1128.52
2001-11-27;1157.42;1163.38;1140.81;1149.50;1288000000;1149.50
2001-11-26;1150.34;1157.88;1146.17;1157.42;1129800000;1157.42
2001-11-23;1137.03;1151.05;1135.90;1150.34;410300000;1150.34
2001-11-21;1142.66;1142.66;1129.78;1137.03;1029300000;1137.03
2001-11-20;1151.06;1152.45;1142.17;1142.66;1330200000;1142.66
2001-11-19;1138.65;1151.06;1138.65;1151.06;1316800000;1151.06
2001-11-16;1142.24;1143.52;1129.92;1138.65;1337400000;1138.65
2001-11-15;1141.21;1146.46;1135.06;1142.24;1454500000;1142.24
2001-11-14;1139.09;1148.28;1132.87;1141.21;1443400000;1141.21
2001-11-13;1118.33;1139.14;1118.33;1139.09;1370100000;1139.09
2001-11-12;1120.31;1121.71;1098.32;1118.33;991600000;1118.33
2001-11-09;1118.54;1123.02;1111.13;1120.31;1093800000;1120.31
2001-11-08;1115.80;1135.75;1115.42;1118.54;1517500000;1118.54
2001-11-07;1118.86;1126.62;1112.98;1115.80;1411300000;1115.80
2001-11-06;1102.84;1119.73;1095.36;1118.86;1356000000;1118.86
2001-11-05;1087.20;1106.72;1087.20;1102.84;1267700000;1102.84
2001-11-02;1084.10;1089.63;1075.58;1087.20;1121900000;1087.20
2001-11-01;1059.78;1085.61;1054.31;1084.10;1317400000;1084.10
2001-10-31;1059.79;1074.79;1057.55;1059.78;1352500000;1059.78
2001-10-30;1078.30;1078.30;1053.61;1059.79;1297400000;1059.79
2001-10-29;1104.61;1104.61;1078.30;1078.30;1106100000;1078.30
2001-10-26;1100.09;1110.61;1094.24;1104.61;1244500000;1104.61
2001-10-25;1085.20;1100.09;1065.64;1100.09;1364400000;1100.09
2001-10-24;1084.78;1090.26;1079.98;1085.20;1336200000;1085.20
2001-10-23;1089.90;1098.99;1081.53;1084.78;1317300000;1084.78
2001-10-22;1073.48;1090.57;1070.79;1089.90;1105700000;1089.90
2001-10-19;1068.61;1075.52;1057.24;1073.48;1294900000;1073.48
2001-10-18;1077.09;1077.94;1064.54;1068.61;1262900000;1068.61
2001-10-17;1097.54;1107.12;1076.57;1077.09;1452200000;1077.09
2001-10-16;1089.98;1101.66;1087.13;1097.54;1210500000;1097.54
2001-10-15;1091.65;1091.65;1078.19;1089.98;1024700000;1089.98
2001-10-12;1097.43;1097.43;1072.15;1091.65;1331400000;1091.65
2001-10-11;1080.99;1099.16;1080.99;1097.43;1704580000;1097.43
2001-10-10;1056.75;1081.62;1052.76;1080.99;1312400000;1080.99
2001-10-09;1062.44;1063.37;1053.83;1056.75;1227800000;1056.75
2001-10-08;1071.37;1071.37;1056.88;1062.44;979000000;1062.44
2001-10-05;1069.62;1072.35;1053.50;1071.38;1301700000;1071.38
2001-10-04;1072.28;1084.12;1067.82;1069.63;1609100000;1069.63
2001-10-03;1051.33;1075.38;1041.48;1072.28;1650600000;1072.28
2001-10-02;1038.55;1051.33;1034.47;1051.33;1289800000;1051.33
2001-10-01;1040.94;1040.94;1026.76;1038.55;1175600000;1038.55
2001-09-28;1018.61;1040.94;1018.61;1040.94;1631500000;1040.94
2001-09-27;1007.04;1018.92;998.24;1018.61;1467000000;1018.61
2001-09-26;1012.27;1020.29;1002.62;1007.04;1519100000;1007.04
2001-09-25;1003.45;1017.14;998.33;1012.27;1613800000;1012.27
2001-09-24;965.80;1008.44;965.80;1003.45;1746600000;1003.45
2001-09-21;984.54;984.54;944.75;965.80;2317300000;965.80
2001-09-20;1016.10;1016.10;984.49;984.54;2004800000;984.54
2001-09-19;1032.74;1038.91;984.62;1016.10;2120550000;1016.10
2001-09-18;1038.77;1046.42;1029.25;1032.74;1650410000;1032.74
2001-09-17;1092.54;1092.54;1037.46;1038.77;2330830000;1038.77
2001-09-10;1085.78;1096.94;1073.15;1092.54;1276600000;1092.54
2001-09-07;1106.40;1106.40;1082.12;1085.78;1424300000;1085.78
2001-09-06;1131.74;1131.74;1105.83;1106.40;1359700000;1106.40
2001-09-05;1132.94;1135.52;1114.86;1131.74;1384500000;1131.74
2001-09-04;1133.58;1155.40;1129.06;1132.94;1178300000;1132.94
2001-08-31;1129.03;1141.83;1126.38;1133.58;920100000;1133.58
2001-08-30;1148.60;1151.75;1124.87;1129.03;1157000000;1129.03
2001-08-29;1161.51;1166.97;1147.38;1148.56;963700000;1148.56
2001-08-28;1179.21;1179.66;1161.17;1161.51;987100000;1161.51
2001-08-27;1184.93;1186.85;1178.07;1179.21;842600000;1179.21
2001-08-24;1162.09;1185.15;1162.09;1184.93;1043600000;1184.93
2001-08-23;1165.31;1169.86;1160.96;1162.09;986200000;1162.09
2001-08-22;1157.26;1168.56;1153.34;1165.31;1110800000;1165.31
2001-08-21;1171.41;1179.85;1156.56;1157.26;1041600000;1157.26
2001-08-20;1161.97;1171.41;1160.94;1171.41;897100000;1171.41
2001-08-17;1181.66;1181.66;1156.07;1161.97;974300000;1161.97
2001-08-16;1178.02;1181.80;1166.08;1181.66;1055400000;1181.66
2001-08-15;1186.73;1191.21;1177.61;1178.02;1065600000;1178.02
2001-08-14;1191.29;1198.79;1184.26;1186.73;964600000;1186.73
2001-08-13;1190.16;1193.82;1185.12;1191.29;837600000;1191.29
2001-08-10;1183.43;1193.33;1169.55;1190.16;960900000;1190.16
2001-08-09;1183.53;1184.71;1174.68;1183.43;1104200000;1183.43
2001-08-08;1204.40;1206.79;1181.27;1183.53;1124600000;1183.53
2001-08-07;1200.47;1207.56;1195.64;1204.40;1012000000;1204.40
2001-08-06;1214.35;1214.35;1197.35;1200.48;811700000;1200.48
2001-08-03;1220.75;1220.75;1205.31;1214.35;939900000;1214.35
2001-08-02;1215.93;1226.27;1215.31;1220.75;1218300000;1220.75
2001-08-01;1211.23;1223.04;1211.23;1215.93;1340300000;1215.93
2001-07-31;1204.52;1222.74;1204.52;1211.23;1129200000;1211.23
2001-07-30;1205.82;1209.05;1200.41;1204.52;909100000;1204.52
2001-07-27;1202.93;1209.26;1195.99;1205.82;1015300000;1205.82
2001-07-26;1190.49;1204.18;1182.65;1202.93;1213900000;1202.93
2001-07-25;1171.65;1190.52;1171.28;1190.49;1280700000;1190.49
2001-07-24;1191.03;1191.03;1165.54;1171.65;1198700000;1171.65
2001-07-23;1210.85;1215.22;1190.50;1191.03;986900000;1191.03
2001-07-20;1215.02;1215.69;1207.04;1210.85;1170900000;1210.85
2001-07-19;1207.71;1225.04;1205.80;1215.02;1343500000;1215.02
2001-07-18;1214.44;1214.44;1198.33;1207.71;1316300000;1207.71
2001-07-17;1202.45;1215.36;1196.14;1214.44;1238100000;1214.44
2001-07-16;1215.68;1219.63;1200.05;1202.45;1039800000;1202.45
2001-07-13;1208.14;1218.54;1203.61;1215.68;1121700000;1215.68
2001-07-12;1180.18;1210.25;1180.18;1208.14;1394000000;1208.14
2001-07-11;1181.52;1184.93;1168.46;1180.18;1384100000;1180.18
2001-07-10;1198.78;1203.43;1179.93;1181.52;1263800000;1181.52
2001-07-09;1190.59;1201.76;1189.75;1198.78;1045700000;1198.78
2001-07-06;1219.24;1219.24;1188.74;1190.59;1056700000;1190.59
2001-07-05;1234.45;1234.45;1219.15;1219.24;934900000;1219.24
2001-07-03;1236.71;1236.71;1229.43;1234.45;622110000;1234.45
2001-07-02;1224.42;1239.78;1224.03;1236.72;1128300000;1236.72
2001-06-29;1226.20;1237.29;1221.14;1224.38;1832360000;1224.38
2001-06-28;1211.07;1234.44;1211.07;1226.20;1327300000;1226.20
2001-06-27;1216.76;1219.92;1207.29;1211.07;1162100000;1211.07
2001-06-26;1218.60;1220.70;1204.64;1216.76;1198900000;1216.76
2001-06-25;1225.35;1231.50;1213.60;1218.60;1050100000;1218.60
2001-06-22;1237.04;1237.73;1221.41;1225.35;1189200000;1225.35
2001-06-21;1223.14;1240.24;1220.25;1237.04;1546820000;1237.04
2001-06-20;1212.58;1225.61;1210.07;1223.14;1350100000;1223.14
2001-06-19;1208.43;1226.11;1207.71;1212.58;1184900000;1212.58
2001-06-18;1214.36;1221.23;1208.33;1208.43;1111600000;1208.43
2001-06-15;1219.87;1221.50;1203.03;1214.36;1635550000;1214.36
2001-06-14;1241.60;1241.60;1218.90;1219.87;1242900000;1219.87
2001-06-13;1255.85;1259.75;1241.59;1241.60;1063600000;1241.60
2001-06-12;1254.39;1261.00;1235.75;1255.85;1136500000;1255.85
2001-06-11;1264.96;1264.96;1249.23;1254.39;870100000;1254.39
2001-06-08;1276.96;1277.11;1259.99;1264.96;726200000;1264.96
2001-06-07;1270.03;1277.08;1265.08;1276.96;1089600000;1276.96
2001-06-06;1283.57;1283.85;1269.01;1270.03;1061900000;1270.03
2001-06-05;1267.11;1286.62;1267.11;1283.57;1116800000;1283.57
2001-06-04;1260.67;1267.17;1256.36;1267.11;836500000;1267.11
2001-06-01;1255.82;1265.34;1246.88;1260.67;1015000000;1260.67
2001-05-31;1248.08;1261.91;1248.07;1255.82;1226600000;1255.82
2001-05-30;1267.93;1267.93;1245.96;1248.08;1158600000;1248.08
2001-05-29;1277.89;1278.42;1265.41;1267.93;1026000000;1267.93
2001-05-25;1293.17;1293.17;1276.42;1277.89;828100000;1277.89
2001-05-24;1289.05;1295.04;1281.22;1293.17;1100700000;1293.17
2001-05-23;1309.38;1309.38;1288.70;1289.05;1134800000;1289.05
2001-05-22;1312.83;1315.93;1306.89;1309.38;1260400000;1309.38
2001-05-21;1291.96;1312.95;1287.87;1312.83;1174900000;1312.83
2001-05-18;1288.49;1292.06;1281.15;1291.96;1130800000;1291.96
2001-05-17;1284.99;1296.48;1282.65;1288.49;1355600000;1288.49
2001-05-16;1249.44;1286.39;1243.02;1284.99;1405300000;1284.99
2001-05-15;1248.92;1257.45;1245.36;1249.44;1071800000;1249.44
2001-05-14;1245.67;1249.68;1241.02;1248.92;858200000;1248.92
2001-05-11;1255.18;1259.84;1240.79;1245.67;906200000;1245.67
2001-05-10;1255.54;1268.14;1254.56;1255.18;1056700000;1255.18
2001-05-09;1261.20;1261.65;1247.83;1255.54;1132400000;1255.54
2001-05-08;1266.71;1267.01;1253.00;1261.20;1006300000;1261.20
2001-05-07;1266.61;1270.00;1259.19;1263.51;949000000;1263.51
2001-05-04;1248.58;1267.51;1232.00;1266.61;1082100000;1266.61
2001-05-03;1267.43;1267.43;1239.88;1248.58;1137900000;1248.58
2001-05-02;1266.44;1272.93;1257.70;1267.43;1342200000;1267.43
2001-05-01;1249.46;1266.47;1243.55;1266.44;1181300000;1266.44
2001-04-30;1253.05;1269.30;1243.99;1249.46;1266800000;1249.46
2001-04-27;1234.52;1253.07;1234.52;1253.05;1091300000;1253.05
2001-04-26;1228.75;1248.30;1228.75;1234.52;1345200000;1234.52
2001-04-25;1209.47;1232.36;1207.38;1228.75;1203600000;1228.75
2001-04-24;1224.36;1233.54;1208.89;1209.47;1216500000;1209.47
2001-04-23;1242.98;1242.98;1217.47;1224.36;1012600000;1224.36
2001-04-20;1253.70;1253.70;1234.41;1242.98;1338700000;1242.98
2001-04-19;1238.16;1253.71;1233.39;1253.69;1486800000;1253.69
2001-04-18;1191.81;1248.42;1191.81;1238.16;1918900000;1238.16
2001-04-17;1179.68;1192.25;1168.90;1191.81;1109600000;1191.81
2001-04-16;1183.50;1184.64;1167.38;1179.68;913900000;1179.68
2001-04-12;1165.89;1183.51;1157.73;1183.50;1102000000;1183.50
2001-04-11;1168.38;1182.24;1160.26;1165.89;1290300000;1165.89
2001-04-10;1137.59;1173.92;1137.59;1168.38;1349600000;1168.38
2001-04-09;1128.43;1146.13;1126.38;1137.59;1062800000;1137.59
2001-04-06;1151.44;1151.44;1119.29;1128.43;1266800000;1128.43
2001-04-05;1103.25;1151.47;1103.25;1151.44;1368000000;1151.44
2001-04-04;1106.46;1117.50;1091.99;1103.25;1425590000;1103.25
2001-04-03;1145.87;1145.87;1100.19;1106.46;1386100000;1106.46
2001-04-02;1160.33;1169.51;1137.51;1145.87;1254900000;1145.87
2001-03-30;1147.95;1162.80;1143.83;1160.33;1280800000;1160.33
2001-03-29;1153.29;1161.69;1136.26;1147.95;1234500000;1147.95
2001-03-28;1182.17;1182.17;1147.83;1153.29;1333400000;1153.29
2001-03-27;1152.69;1183.35;1150.96;1182.17;1314200000;1182.17
2001-03-26;1139.83;1160.02;1139.83;1152.69;1114000000;1152.69
2001-03-23;1117.58;1141.83;1117.58;1139.83;1364900000;1139.83
2001-03-22;1122.14;1124.27;1081.19;1117.58;1723950000;1117.58
2001-03-21;1142.62;1149.39;1118.74;1122.14;1346300000;1122.14
2001-03-20;1170.81;1180.56;1142.19;1142.62;1235900000;1142.62
2001-03-19;1150.53;1173.50;1147.18;1170.81;1126200000;1170.81
2001-03-16;1173.56;1173.56;1148.64;1150.53;1543560000;1150.53
2001-03-15;1166.71;1182.04;1166.71;1173.56;1259500000;1173.56
2001-03-14;1197.66;1197.66;1155.35;1166.71;1397400000;1166.71
2001-03-13;1180.16;1197.83;1171.50;1197.66;1360900000;1197.66
2001-03-12;1233.42;1233.42;1176.78;1180.16;1229000000;1180.16
2001-03-09;1264.74;1264.74;1228.42;1233.42;1085900000;1233.42
2001-03-08;1261.89;1266.50;1257.60;1264.74;1114100000;1264.74
2001-03-07;1253.80;1263.86;1253.80;1261.89;1132200000;1261.89
2001-03-06;1241.41;1267.42;1241.41;1253.80;1091800000;1253.80
2001-03-05;1234.18;1242.55;1234.04;1241.41;929200000;1241.41
2001-03-02;1241.23;1251.01;1219.74;1234.18;1294000000;1234.18
2001-03-01;1239.94;1241.36;1214.50;1241.23;1294900000;1241.23
2001-02-28;1257.94;1263.47;1229.65;1239.94;1225300000;1239.94
2001-02-27;1267.65;1272.76;1252.26;1257.94;1114100000;1257.94
2001-02-26;1245.86;1267.69;1241.71;1267.65;1130800000;1267.65
2001-02-23;1252.82;1252.82;1215.44;1245.86;1231300000;1245.86
2001-02-22;1255.27;1259.94;1228.33;1252.82;1365900000;1252.82
2001-02-21;1278.94;1282.97;1253.16;1255.27;1208500000;1255.27
2001-02-20;1301.53;1307.16;1278.44;1278.94;1112200000;1278.94
2001-02-16;1326.61;1326.61;1293.18;1301.53;1257200000;1301.53
2001-02-15;1315.92;1331.29;1315.92;1326.61;1153700000;1326.61
2001-02-14;1318.80;1320.73;1304.72;1315.92;1150300000;1315.92
2001-02-13;1330.31;1336.62;1317.51;1318.80;1075200000;1318.80
2001-02-12;1314.76;1330.96;1313.64;1330.31;1039100000;1330.31
2001-02-09;1332.53;1332.53;1309.98;1314.76;1075500000;1314.76
2001-02-08;1341.10;1350.32;1332.42;1332.53;1107200000;1332.53
2001-02-07;1352.26;1352.26;1334.26;1340.89;1158300000;1340.89
2001-02-06;1354.31;1363.55;1350.04;1352.26;1059600000;1352.26
2001-02-05;1349.47;1354.56;1344.48;1354.31;1013000000;1354.31
2001-02-02;1373.47;1376.38;1348.72;1349.47;1048400000;1349.47
2001-02-01;1366.01;1373.50;1359.34;1373.47;1118800000;1373.47
2001-01-31;1373.73;1383.37;1364.66;1366.01;1295300000;1366.01
2001-01-30;1364.17;1375.68;1356.20;1373.73;1149800000;1373.73
2001-01-29;1354.92;1365.54;1350.36;1364.17;1053100000;1364.17
2001-01-26;1357.51;1357.51;1342.75;1354.95;1098000000;1354.95
2001-01-25;1364.30;1367.35;1354.63;1357.51;1258000000;1357.51
2001-01-24;1360.40;1369.75;1357.28;1364.30;1309000000;1364.30
2001-01-23;1342.90;1362.90;1339.63;1360.40;1232600000;1360.40
2001-01-22;1342.54;1353.62;1333.84;1342.90;1164000000;1342.90
2001-01-19;1347.97;1354.55;1336.74;1342.54;1407800000;1342.54
2001-01-18;1329.89;1352.71;1327.41;1347.97;1445000000;1347.97
2001-01-17;1326.65;1346.92;1325.41;1329.47;1349100000;1329.47
2001-01-16;1318.32;1327.81;1313.33;1326.65;1205700000;1326.65
2001-01-12;1326.82;1333.21;1311.59;1318.55;1276000000;1318.55
2001-01-11;1313.27;1332.19;1309.72;1326.82;1411200000;1326.82
2001-01-10;1300.80;1313.76;1287.28;1313.27;1296500000;1313.27
2001-01-09;1295.86;1311.72;1295.14;1300.80;1191300000;1300.80
2001-01-08;1298.35;1298.35;1276.29;1295.86;1115500000;1295.86
2001-01-05;1333.34;1334.77;1294.95;1298.35;1430800000;1298.35
2001-01-04;1347.56;1350.24;1329.14;1333.34;2131000000;1333.34
2001-01-03;1283.27;1347.76;1274.62;1347.56;1880700000;1347.56
2001-01-02;1320.28;1320.28;1276.05;1283.27;1129400000;1283.27
2000-12-29;1334.22;1340.10;1317.51;1320.28;1035500000;1320.28
2000-12-28;1328.92;1335.93;1325.78;1334.22;1015300000;1334.22
2000-12-27;1315.19;1332.03;1310.96;1328.92;1092700000;1328.92
2000-12-26;1305.97;1315.94;1301.64;1315.19;806500000;1315.19
2000-12-22;1274.86;1305.97;1274.86;1305.95;1087100000;1305.95
2000-12-21;1264.74;1285.31;1254.07;1274.86;1449900000;1274.86
2000-12-20;1305.60;1305.60;1261.16;1264.74;1421600000;1264.74
2000-12-19;1322.96;1346.44;1305.20;1305.60;1324900000;1305.60
2000-12-18;1312.15;1332.32;1312.15;1322.74;1189900000;1322.74
2000-12-15;1340.93;1340.93;1305.38;1312.15;1561100000;1312.15
2000-12-14;1359.99;1359.99;1340.48;1340.93;1061300000;1340.93
2000-12-13;1371.18;1385.82;1358.48;1359.99;1195100000;1359.99
2000-12-12;1380.20;1380.27;1370.27;1371.18;1083400000;1371.18
2000-12-11;1369.89;1389.05;1364.14;1380.20;1202400000;1380.20
2000-12-08;1343.55;1380.33;1343.55;1369.89;1358300000;1369.89
2000-12-07;1351.46;1353.50;1339.26;1343.55;1128000000;1343.55
2000-12-06;1376.54;1376.54;1346.15;1351.46;1399300000;1351.46
2000-12-05;1324.97;1376.56;1324.97;1376.54;900300000;1376.54
2000-12-04;1315.18;1332.06;1310.23;1324.97;1103000000;1324.97
2000-12-01;1314.95;1334.67;1307.02;1315.23;1195200000;1315.23
2000-11-30;1341.91;1341.91;1294.90;1314.95;1186530000;1314.95
2000-11-29;1336.09;1352.38;1329.28;1341.93;402100000;1341.93
2000-11-28;1348.97;1358.81;1334.97;1336.09;1028200000;1336.09
2000-11-27;1341.77;1362.50;1341.77;1348.97;946100000;1348.97
2000-11-24;1322.36;1343.83;1322.36;1341.77;404870000;1341.77
2000-11-22;1347.35;1347.35;1321.89;1322.36;963200000;1322.36
2000-11-21;1342.62;1355.87;1333.62;1347.35;1137100000;1347.35
2000-11-20;1367.72;1367.72;1341.67;1342.62;955800000;1342.62
2000-11-17;1372.32;1384.85;1355.55;1367.72;1070400000;1367.72
2000-11-16;1389.81;1394.76;1370.39;1372.32;956300000;1372.32
2000-11-15;1382.95;1395.96;1374.75;1389.81;1066800000;1389.81
2000-11-14;1351.26;1390.06;1351.26;1382.95;1118800000;1382.95
2000-11-13;1365.98;1365.98;1328.62;1351.26;1129300000;1351.26
2000-11-10;1400.14;1400.14;1365.97;1365.98;962500000;1365.98
2000-11-09;1409.28;1409.28;1369.68;1400.14;1111000000;1400.14
2000-11-08;1431.87;1437.28;1408.78;1409.28;909300000;1409.28
2000-11-07;1432.19;1436.22;1423.26;1431.87;880900000;1431.87
2000-11-06;1428.76;1438.46;1427.72;1432.19;930900000;1432.19
2000-11-03;1428.32;1433.21;1420.92;1426.69;997700000;1426.69
2000-11-02;1421.22;1433.40;1421.22;1428.32;1167700000;1428.32
2000-11-01;1429.40;1429.60;1410.45;1421.22;1206800000;1421.22
2000-10-31;1398.66;1432.22;1398.66;1429.40;1366400000;1429.40
2000-10-30;1379.58;1406.36;1376.86;1398.66;1186500000;1398.66
2000-10-27;1364.44;1384.57;1364.13;1379.58;1086300000;1379.58
2000-10-26;1364.90;1372.72;1337.81;1364.44;1303800000;1364.44
2000-10-25;1398.13;1398.13;1362.21;1364.90;1315600000;1364.90
2000-10-24;1395.78;1415.64;1388.13;1398.13;1158600000;1398.13
2000-10-23;1396.93;1406.96;1387.75;1395.78;1046800000;1395.78
2000-10-20;1388.76;1408.47;1382.19;1396.93;1177400000;1396.93
2000-10-19;1342.13;1389.93;1342.13;1388.76;1297900000;1388.76
2000-10-18;1349.97;1356.65;1305.79;1342.13;1441700000;1342.13
2000-10-17;1374.62;1380.99;1342.34;1349.97;1161500000;1349.97
2000-10-16;1374.17;1379.48;1365.06;1374.62;1005400000;1374.62
2000-10-13;1329.78;1374.17;1327.08;1374.17;1223900000;1374.17
2000-10-12;1364.59;1374.93;1328.06;1329.78;1388600000;1329.78
2000-10-11;1387.02;1387.02;1349.67;1364.59;1387500000;1364.59
2000-10-10;1402.03;1408.83;1383.85;1387.02;1044000000;1387.02
2000-10-09;1408.99;1409.69;1392.48;1402.03;716600000;1402.03
2000-10-06;1436.28;1443.30;1397.06;1408.99;1150100000;1408.99
2000-10-05;1434.32;1444.17;1431.80;1436.28;1176100000;1436.28
2000-10-04;1426.46;1439.99;1416.31;1434.32;1167400000;1434.32
2000-10-03;1436.23;1454.82;1425.28;1426.46;1098100000;1426.46
2000-10-02;1436.52;1445.60;1429.83;1436.23;1051200000;1436.23
2000-09-29;1458.29;1458.29;1436.29;1436.51;1197100000;1436.51
2000-09-28;1426.57;1461.69;1425.78;1458.29;1206200000;1458.29
2000-09-27;1427.21;1437.22;1419.44;1426.57;1174700000;1426.57
2000-09-26;1439.03;1448.04;1425.25;1427.21;1106600000;1427.21
2000-09-25;1448.72;1457.42;1435.93;1439.03;982400000;1439.03
2000-09-22;1449.05;1449.05;1421.88;1448.72;1185500000;1448.72
2000-09-21;1451.34;1452.77;1436.30;1449.05;1105400000;1449.05
2000-09-20;1459.90;1460.49;1430.95;1451.34;1104000000;1451.34
2000-09-19;1444.51;1461.16;1444.51;1459.90;1024900000;1459.90
2000-09-18;1465.81;1467.77;1441.92;1444.51;962500000;1444.51
2000-09-15;1480.87;1480.96;1460.22;1465.81;1268400000;1465.81
2000-09-14;1484.91;1494.16;1476.73;1480.87;1014000000;1480.87
2000-09-13;1481.99;1487.45;1473.61;1484.91;1068300000;1484.91
2000-09-12;1489.26;1496.93;1479.67;1481.99;991200000;1481.99
2000-09-11;1494.50;1506.76;1483.01;1489.26;899300000;1489.26
2000-09-08;1502.51;1502.51;1489.88;1494.50;961000000;1494.50
2000-09-07;1492.25;1505.34;1492.25;1502.51;985500000;1502.51
2000-09-06;1507.08;1512.61;1492.12;1492.25;995100000;1492.25
2000-09-05;1520.77;1520.77;1504.21;1507.08;838500000;1507.08
2000-09-01;1517.68;1530.09;1515.53;1520.77;767700000;1520.77
2000-08-31;1502.59;1525.21;1502.59;1517.68;1056600000;1517.68
2000-08-30;1509.84;1510.49;1500.09;1502.59;818400000;1502.59
2000-08-29;1514.09;1514.81;1505.46;1509.84;795600000;1509.84
2000-08-28;1506.45;1523.95;1506.45;1514.09;733600000;1514.09
2000-08-25;1508.31;1513.47;1505.09;1506.45;685600000;1506.45
2000-08-24;1505.97;1511.16;1501.25;1508.31;837100000;1508.31
2000-08-23;1498.13;1507.20;1489.52;1505.97;871000000;1505.97
2000-08-22;1499.48;1508.45;1497.42;1498.13;818800000;1498.13
2000-08-21;1491.72;1502.84;1491.13;1499.48;731600000;1499.48
2000-08-18;1496.07;1499.47;1488.99;1491.72;821400000;1491.72
2000-08-17;1479.85;1499.32;1479.85;1496.07;922400000;1496.07
2000-08-16;1484.43;1496.09;1475.74;1479.85;929800000;1479.85
2000-08-15;1491.56;1493.12;1482.74;1484.43;895900000;1484.43
2000-08-14;1471.84;1491.64;1468.56;1491.56;783800000;1491.56
2000-08-11;1460.25;1475.72;1453.06;1471.84;835500000;1471.84
2000-08-10;1472.87;1475.15;1459.89;1460.25;940800000;1460.25
2000-08-09;1482.80;1490.33;1471.16;1472.87;1054000000;1472.87
2000-08-08;1479.32;1484.52;1472.61;1482.80;992200000;1482.80
2000-08-07;1462.93;1480.80;1460.72;1479.32;854800000;1479.32
2000-08-04;1452.56;1462.93;1451.31;1462.93;956000000;1462.93
2000-08-03;1438.70;1454.19;1425.43;1452.56;1095600000;1452.56
2000-08-02;1438.10;1451.59;1433.49;1438.70;994500000;1438.70
2000-08-01;1430.83;1443.54;1428.96;1438.10;938700000;1438.10
2000-07-31;1419.89;1437.65;1418.71;1430.83;952600000;1430.83
2000-07-28;1449.62;1456.68;1413.89;1419.89;980000000;1419.89
2000-07-27;1452.42;1464.91;1445.33;1449.62;1156400000;1449.62
2000-07-26;1474.47;1474.47;1452.42;1452.42;1235800000;1452.42
2000-07-25;1464.29;1476.23;1464.29;1474.47;969400000;1474.47
2000-07-24;1480.19;1485.88;1463.80;1464.29;880300000;1464.29
2000-07-21;1495.57;1495.57;1477.91;1480.19;968300000;1480.19
2000-07-20;1481.96;1501.92;1481.96;1495.57;1064600000;1495.57
2000-07-19;1493.74;1495.63;1479.92;1481.96;909400000;1481.96
2000-07-18;1510.49;1510.49;1491.35;1493.74;908300000;1493.74
2000-07-17;1509.98;1517.32;1505.26;1510.49;906000000;1510.49
2000-07-14;1495.84;1509.99;1494.56;1509.98;960600000;1509.98
2000-07-13;1492.92;1501.39;1489.65;1495.84;1026800000;1495.84
2000-07-12;1480.88;1497.69;1480.88;1492.92;1001200000;1492.92
2000-07-11;1475.62;1488.77;1470.48;1480.88;980500000;1480.88
2000-07-10;1478.90;1486.56;1474.76;1475.62;838700000;1475.62
2000-07-07;1456.67;1484.12;1456.67;1478.90;931700000;1478.90
2000-07-06;1446.23;1461.65;1439.56;1456.67;947300000;1456.67
2000-07-05;1469.54;1469.54;1442.45;1446.23;1019300000;1446.23
2000-07-03;1454.60;1469.58;1450.85;1469.54;451900000;1469.54
2000-06-30;1442.39;1454.68;1438.71;1454.60;1459700000;1454.60
2000-06-29;1454.82;1455.14;1434.63;1442.39;1110900000;1442.39
2000-06-28;1450.55;1467.63;1450.55;1454.82;1095100000;1454.82
2000-06-27;1455.31;1463.35;1450.55;1450.55;1042500000;1450.55
2000-06-26;1441.48;1459.66;1441.48;1455.31;889000000;1455.31
2000-06-23;1452.18;1459.94;1438.31;1441.48;847600000;1441.48
2000-06-22;1479.13;1479.13;1448.03;1452.18;1022700000;1452.18
2000-06-21;1475.95;1482.19;1468.00;1479.13;1009600000;1479.13
2000-06-20;1486.00;1487.32;1470.18;1475.95;1031500000;1475.95
2000-06-19;1464.46;1488.93;1459.05;1486.00;921700000;1486.00
2000-06-16;1478.73;1480.77;1460.42;1464.46;1250800000;1464.46
2000-06-15;1470.54;1482.04;1464.62;1478.73;1011400000;1478.73
2000-06-14;1469.44;1483.62;1467.71;1470.54;929700000;1470.54
2000-06-13;1446.00;1470.42;1442.38;1469.44;935900000;1469.44
2000-06-12;1456.95;1462.93;1445.99;1446.00;774100000;1446.00
2000-06-09;1461.67;1472.67;1454.96;1456.95;786000000;1456.95
2000-06-08;1471.36;1475.65;1456.49;1461.67;854300000;1461.67
2000-06-07;1457.84;1474.64;1455.06;1471.36;854600000;1471.36
2000-06-06;1467.63;1471.36;1454.74;1457.84;950100000;1457.84
2000-06-05;1477.26;1477.28;1464.68;1467.63;838600000;1467.63
2000-06-02;1448.81;1483.23;1448.81;1477.26;1162400000;1477.26
2000-06-01;1420.60;1448.81;1420.60;1448.81;960100000;1448.81
2000-05-31;1422.44;1434.49;1415.50;1420.60;960500000;1420.60
2000-05-30;1378.02;1422.45;1378.02;1422.45;844200000;1422.45
2000-05-26;1381.52;1391.42;1369.75;1378.02;722600000;1378.02
2000-05-25;1399.05;1411.65;1373.93;1381.52;984500000;1381.52
2000-05-24;1373.86;1401.75;1361.09;1399.05;1152300000;1399.05
2000-05-23;1400.72;1403.77;1373.43;1373.86;869900000;1373.86
2000-05-22;1406.95;1410.55;1368.73;1400.72;869000000;1400.72
2000-05-19;1437.21;1437.21;1401.74;1406.95;853700000;1406.95
2000-05-18;1447.80;1458.04;1436.59;1437.21;807900000;1437.21
2000-05-17;1466.04;1466.04;1441.67;1447.80;820500000;1447.80
2000-05-16;1452.36;1470.40;1450.76;1466.04;955500000;1466.04
2000-05-15;1420.96;1452.39;1416.54;1452.36;854600000;1452.36
2000-05-12;1407.81;1430.13;1407.81;1420.96;858200000;1420.96
2000-05-11;1383.05;1410.26;1383.05;1407.81;953600000;1407.81
2000-05-10;1412.14;1412.14;1375.14;1383.05;1006400000;1383.05
2000-05-09;1424.17;1430.28;1401.85;1412.14;896600000;1412.14
2000-05-08;1432.63;1432.63;1417.05;1424.17;787600000;1424.17
2000-05-05;1409.57;1436.03;1405.08;1432.63;805500000;1432.63
2000-05-04;1415.10;1420.99;1404.94;1409.57;925800000;1409.57
2000-05-03;1446.29;1446.29;1398.36;1415.10;991600000;1415.10
2000-05-02;1468.25;1468.25;1445.22;1446.29;1011500000;1446.29
2000-05-01;1452.43;1481.51;1452.43;1468.25;966300000;1468.25
2000-04-28;1464.92;1473.62;1448.15;1452.43;984600000;1452.43
2000-04-27;1460.99;1469.21;1434.81;1464.92;1111000000;1464.92
2000-04-26;1477.44;1482.94;1456.98;1460.99;999600000;1460.99
2000-04-25;1429.86;1477.67;1429.86;1477.44;1071100000;1477.44
2000-04-24;1434.54;1434.54;1407.13;1429.86;868700000;1429.86
2000-04-20;1427.47;1435.49;1422.08;1434.54;896200000;1434.54
2000-04-19;1441.61;1447.69;1424.26;1427.47;1001400000;1427.47
2000-04-18;1401.44;1441.61;1397.81;1441.61;1109400000;1441.61
2000-04-17;1356.56;1401.53;1346.50;1401.44;1204700000;1401.44
2000-04-14;1440.51;1440.51;1339.40;1356.56;1279700000;1356.56
2000-04-13;1467.17;1477.52;1439.34;1440.51;1032000000;1440.51
2000-04-12;1500.59;1509.08;1466.15;1467.17;1175900000;1467.17
2000-04-11;1504.46;1512.80;1486.78;1500.59;971400000;1500.59
2000-04-10;1516.35;1527.19;1503.35;1504.46;853700000;1504.46
2000-04-07;1501.34;1518.68;1501.34;1516.35;891600000;1516.35
2000-04-06;1487.37;1511.76;1487.37;1501.34;1008000000;1501.34
2000-04-05;1494.73;1506.55;1478.05;1487.37;1110300000;1487.37
2000-04-04;1505.98;1526.45;1416.41;1494.73;1515460000;1494.73
2000-04-03;1498.58;1507.19;1486.96;1505.97;1021700000;1505.97
2000-03-31;1487.92;1519.81;1484.38;1498.58;1227400000;1498.58
2000-03-30;1508.52;1517.38;1474.63;1487.92;1193400000;1487.92
2000-03-29;1507.73;1521.45;1497.45;1508.52;1061900000;1508.52
2000-03-28;1523.86;1527.36;1507.09;1507.73;959100000;1507.73
2000-03-27;1527.46;1534.63;1518.46;1523.86;901000000;1523.86
2000-03-24;1527.35;1552.87;1516.83;1527.46;1052200000;1527.46
2000-03-23;1500.64;1532.50;1492.39;1527.35;1078300000;1527.35
2000-03-22;1493.87;1505.08;1487.33;1500.64;1075000000;1500.64
2000-03-21;1456.63;1493.92;1446.06;1493.87;1065900000;1493.87
2000-03-20;1464.47;1470.30;1448.49;1456.63;920800000;1456.63
2000-03-17;1458.47;1477.33;1453.32;1464.47;1295100000;1464.47
2000-03-16;1392.15;1458.47;1392.15;1458.47;1482300000;1458.47
2000-03-15;1359.15;1397.99;1356.99;1392.14;1302800000;1392.14
2000-03-14;1383.62;1395.15;1359.15;1359.15;1094000000;1359.15
2000-03-13;1395.07;1398.39;1364.84;1383.62;1016100000;1383.62
2000-03-10;1401.69;1413.46;1392.07;1395.07;1138800000;1395.07
2000-03-09;1366.70;1401.82;1357.88;1401.69;1123000000;1401.69
2000-03-08;1355.62;1373.79;1346.62;1366.70;1203000000;1366.70
2000-03-07;1391.28;1399.21;1349.99;1355.62;1314100000;1355.62
2000-03-06;1409.17;1409.74;1384.75;1391.28;1029000000;1391.28
2000-03-03;1381.76;1410.88;1381.76;1409.17;1150300000;1409.17
2000-03-02;1379.19;1386.56;1370.35;1381.76;1198600000;1381.76
2000-03-01;1366.42;1383.46;1366.42;1379.19;1274100000;1379.19
2000-02-29;1348.05;1369.63;1348.05;1366.42;1204300000;1366.42
2000-02-28;1333.36;1360.82;1325.07;1348.05;1026500000;1348.05
2000-02-25;1353.43;1362.14;1329.15;1333.36;1065200000;1333.36
2000-02-24;1360.69;1364.80;1329.88;1353.43;1215000000;1353.43
2000-02-23;1352.17;1370.11;1342.44;1360.69;993700000;1360.69
2000-02-22;1346.09;1358.11;1331.88;1352.17;980000000;1352.17
2000-02-18;1388.26;1388.59;1345.32;1346.09;1042300000;1346.09
2000-02-17;1387.67;1399.88;1380.07;1388.26;1034800000;1388.26
2000-02-16;1402.05;1404.55;1385.58;1387.67;1018800000;1387.67
2000-02-15;1389.94;1407.72;1376.25;1402.05;1092100000;1402.05
2000-02-14;1387.12;1394.93;1380.53;1389.94;927300000;1389.94
2000-02-11;1416.83;1416.83;1378.89;1387.12;1025700000;1387.12
2000-02-10;1411.70;1422.10;1406.43;1416.83;1058800000;1416.83
2000-02-09;1441.72;1444.55;1411.65;1411.71;1050500000;1411.71
2000-02-08;1424.24;1441.83;1424.24;1441.72;1047700000;1441.72
2000-02-07;1424.37;1427.15;1413.33;1424.24;918100000;1424.24
2000-02-04;1424.97;1435.91;1420.63;1424.37;1045100000;1424.37
2000-02-03;1409.12;1425.78;1398.52;1424.97;1146500000;1424.97
2000-02-02;1409.28;1420.61;1403.49;1409.12;1038600000;1409.12
2000-02-01;1394.46;1412.49;1384.79;1409.28;981000000;1409.28
2000-01-31;1360.16;1394.48;1350.14;1394.46;993800000;1394.46
2000-01-28;1398.56;1398.56;1356.20;1360.16;1095800000;1360.16
2000-01-27;1404.09;1418.86;1370.99;1398.56;1129500000;1398.56
2000-01-26;1410.03;1412.73;1400.16;1404.09;1117300000;1404.09
2000-01-25;1401.53;1414.26;1388.49;1410.03;1073700000;1410.03
2000-01-24;1441.36;1454.09;1395.42;1401.53;1115800000;1401.53
2000-01-21;1445.57;1453.18;1439.60;1441.36;1209800000;1441.36
2000-01-20;1455.90;1465.71;1438.54;1445.57;1100700000;1445.57
2000-01-19;1455.14;1461.39;1448.68;1455.90;1087800000;1455.90
2000-01-18;1465.15;1465.15;1451.30;1455.14;1056700000;1455.14
2000-01-14;1449.68;1473.00;1449.68;1465.15;1085900000;1465.15
2000-01-13;1432.25;1454.20;1432.25;1449.68;1030400000;1449.68
2000-01-12;1438.56;1442.60;1427.08;1432.25;974600000;1432.25
2000-01-11;1457.60;1458.66;1434.42;1438.56;1014000000;1438.56
2000-01-10;1441.47;1464.36;1441.47;1457.60;1064800000;1457.60
2000-01-07;1403.45;1441.47;1400.73;1441.47;1225200000;1441.47
2000-01-06;1402.11;1411.90;1392.10;1403.45;1092300000;1403.45
2000-01-05;1399.42;1413.27;1377.68;1402.11;1085500000;1402.11
2000-01-04;1455.22;1455.22;1397.43;1399.42;1009000000;1399.42
2000-01-03;1469.25;1478.00;1438.36;1455.22;931800000;1455.22
1999-12-31;1464.47;1472.42;1458.19;1469.25;374050000;1469.25
1999-12-30;1463.46;1473.10;1462.60;1464.47;554680000;1464.47
1999-12-29;1457.66;1467.47;1457.66;1463.46;567860000;1463.46
1999-12-28;1457.09;1462.68;1452.78;1457.66;655400000;1457.66
1999-12-27;1458.34;1463.19;1450.83;1457.10;722600000;1457.10
1999-12-23;1436.13;1461.44;1436.13;1458.34;728600000;1458.34
1999-12-22;1433.43;1440.02;1429.13;1436.13;850000000;1436.13
1999-12-21;1418.09;1436.47;1414.80;1433.43;963500000;1433.43
1999-12-20;1421.03;1429.16;1411.10;1418.09;904600000;1418.09
1999-12-17;1418.78;1431.77;1418.78;1421.03;1349800000;1421.03
1999-12-16;1413.32;1423.11;1408.35;1418.78;1070300000;1418.78
1999-12-15;1403.17;1417.40;1396.20;1413.33;1033900000;1413.33
1999-12-14;1415.22;1418.30;1401.59;1403.17;1027800000;1403.17
1999-12-13;1417.04;1421.58;1410.10;1415.22;977600000;1415.22
1999-12-10;1408.11;1421.58;1405.65;1417.04;987200000;1417.04
1999-12-09;1403.88;1418.43;1391.47;1408.11;1122100000;1408.11
1999-12-08;1409.17;1415.66;1403.88;1403.88;957000000;1403.88
1999-12-07;1423.33;1426.81;1409.17;1409.17;1085800000;1409.17
1999-12-06;1433.30;1434.15;1418.25;1423.33;916800000;1423.33
1999-12-03;1409.04;1447.42;1409.04;1433.30;1006400000;1433.30
1999-12-02;1397.72;1409.04;1397.72;1409.04;900700000;1409.04
1999-12-01;1388.91;1400.12;1387.38;1397.72;884000000;1397.72
1999-11-30;1407.83;1410.59;1386.95;1388.91;951500000;1388.91
1999-11-29;1416.62;1416.62;1404.15;1407.83;866100000;1407.83
1999-11-26;1417.08;1425.24;1416.14;1416.62;312120000;1416.62
1999-11-24;1404.64;1419.71;1399.17;1417.08;734800000;1417.08
1999-11-23;1420.94;1423.91;1402.20;1404.64;926100000;1404.64
1999-11-22;1422.00;1425.00;1412.40;1420.94;873500000;1420.94
1999-11-19;1424.94;1424.94;1417.54;1422.00;893800000;1422.00
1999-11-18;1410.71;1425.31;1410.71;1424.94;1022800000;1424.94
1999-11-17;1420.07;1423.44;1410.69;1410.71;960000000;1410.71
1999-11-16;1394.39;1420.36;1394.39;1420.07;942200000;1420.07
1999-11-15;1396.06;1398.58;1392.28;1394.39;795700000;1394.39
1999-11-12;1381.46;1396.12;1368.54;1396.06;900200000;1396.06
1999-11-11;1373.46;1382.12;1372.19;1381.46;891300000;1381.46
1999-11-10;1365.28;1379.18;1359.98;1373.46;984700000;1373.46
1999-11-09;1377.01;1383.81;1361.45;1365.28;854300000;1365.28
1999-11-08;1370.23;1380.78;1365.87;1377.01;806800000;1377.01
1999-11-05;1362.64;1387.48;1362.64;1370.23;1007300000;1370.23
1999-11-04;1354.93;1369.41;1354.93;1362.64;981700000;1362.64
1999-11-03;1347.74;1360.33;1347.74;1354.93;914400000;1354.93
1999-11-02;1354.12;1369.32;1346.41;1347.74;904500000;1347.74
1999-11-01;1362.93;1367.30;1354.05;1354.12;861000000;1354.12
1999-10-29;1342.44;1373.17;1342.44;1362.93;1120500000;1362.93
1999-10-28;1296.71;1342.47;1296.71;1342.44;1135100000;1342.44
1999-10-27;1281.91;1299.39;1280.48;1296.71;950100000;1296.71
1999-10-26;1293.63;1303.46;1281.86;1281.91;878300000;1281.91
1999-10-25;1301.65;1301.68;1286.07;1293.63;777000000;1293.63
1999-10-22;1283.61;1308.81;1283.61;1301.65;959200000;1301.65
1999-10-21;1289.43;1289.43;1265.61;1283.61;1012500000;1283.61
1999-10-20;1261.32;1289.44;1261.32;1289.43;928800000;1289.43
1999-10-19;1254.13;1279.32;1254.13;1261.32;905700000;1261.32
1999-10-18;1247.41;1254.13;1233.70;1254.13;818700000;1254.13
1999-10-15;1283.42;1283.42;1245.39;1247.41;912600000;1247.41
1999-10-14;1285.55;1289.63;1267.62;1283.42;892300000;1283.42
1999-10-13;1313.04;1313.04;1282.80;1285.55;821500000;1285.55
1999-10-12;1335.21;1335.21;1311.80;1313.04;778300000;1313.04
1999-10-11;1336.02;1339.23;1332.96;1335.21;655900000;1335.21
1999-10-08;1317.64;1336.61;1311.88;1336.02;897300000;1336.02
1999-10-07;1325.40;1328.05;1314.13;1317.64;827800000;1317.64
1999-10-06;1301.35;1325.46;1301.35;1325.40;895200000;1325.40
1999-10-05;1304.60;1316.41;1286.44;1301.35;965700000;1301.35
1999-10-04;1282.81;1304.60;1282.81;1304.60;803300000;1304.60
1999-10-01;1282.71;1283.17;1265.78;1282.81;896200000;1282.81
1999-09-30;1268.37;1291.31;1268.37;1282.71;1017600000;1282.71
1999-09-29;1282.20;1288.83;1268.16;1268.37;856000000;1268.37
1999-09-28;1283.31;1285.55;1256.26;1282.20;885400000;1282.20
1999-09-27;1277.36;1295.03;1277.36;1283.31;780600000;1283.31
1999-09-24;1280.41;1281.17;1263.84;1277.36;872800000;1277.36
1999-09-23;1310.51;1315.25;1277.30;1280.41;890800000;1280.41
1999-09-22;1307.58;1316.18;1297.81;1310.51;822200000;1310.51
1999-09-21;1335.52;1335.53;1301.97;1307.58;817300000;1307.58
1999-09-20;1335.42;1338.38;1330.61;1335.53;568000000;1335.53
1999-09-17;1318.48;1337.59;1318.48;1335.42;861900000;1335.42
1999-09-16;1317.97;1322.51;1299.97;1318.48;739000000;1318.48
1999-09-15;1336.29;1347.21;1317.97;1317.97;787300000;1317.97
1999-09-14;1344.13;1344.18;1330.61;1336.29;734500000;1336.29
1999-09-13;1351.66;1351.66;1341.70;1344.13;657900000;1344.13
1999-09-10;1347.66;1357.62;1346.20;1351.66;808500000;1351.66
1999-09-09;1344.15;1347.66;1333.91;1347.66;773900000;1347.66
1999-09-08;1350.45;1355.18;1337.36;1344.15;791200000;1344.15
1999-09-07;1357.24;1361.39;1349.59;1350.45;715300000;1350.45
1999-09-03;1319.11;1357.74;1319.11;1357.24;663200000;1357.24
1999-09-02;1331.07;1331.07;1304.88;1319.11;687100000;1319.11
1999-09-01;1320.41;1331.18;1320.39;1331.07;708200000;1331.07
1999-08-31;1324.02;1333.27;1306.96;1320.41;861700000;1320.41
1999-08-30;1348.27;1350.70;1322.80;1324.02;597900000;1324.02
1999-08-27;1362.01;1365.63;1347.35;1348.27;570050000;1348.27
1999-08-26;1381.79;1381.79;1361.53;1362.01;719000000;1362.01
1999-08-25;1363.50;1382.84;1359.20;1381.79;864600000;1381.79
1999-08-24;1360.22;1373.32;1353.63;1363.50;732700000;1363.50
1999-08-23;1336.61;1360.24;1336.61;1360.22;682600000;1360.22
1999-08-20;1323.59;1336.61;1323.59;1336.61;661200000;1336.61
1999-08-19;1332.84;1332.84;1315.35;1323.59;684200000;1323.59
1999-08-18;1344.16;1344.16;1332.13;1332.84;682800000;1332.84
1999-08-17;1330.77;1344.16;1328.76;1344.16;691500000;1344.16
1999-08-16;1327.68;1331.05;1320.51;1330.77;583550000;1330.77
1999-08-13;1298.16;1327.72;1298.16;1327.68;691700000;1327.68
1999-08-12;1301.93;1313.61;1298.06;1298.16;745600000;1298.16
1999-08-11;1281.43;1301.93;1281.43;1301.93;792300000;1301.93
1999-08-10;1297.80;1298.62;1267.73;1281.43;836200000;1281.43
1999-08-09;1300.29;1306.68;1295.99;1297.80;684300000;1297.80
1999-08-06;1313.71;1316.74;1293.19;1300.29;698900000;1300.29
1999-08-05;1305.33;1313.71;1287.23;1313.71;859300000;1313.71
1999-08-04;1322.18;1330.16;1304.50;1305.33;789300000;1305.33
1999-08-03;1328.05;1336.13;1314.91;1322.18;739600000;1322.18
1999-08-02;1328.72;1344.69;1325.21;1328.05;649550000;1328.05
1999-07-30;1341.03;1350.92;1328.49;1328.72;736800000;1328.72
1999-07-29;1365.40;1365.40;1332.82;1341.03;770100000;1341.03
1999-07-28;1362.84;1370.53;1355.54;1365.40;690900000;1365.40
1999-07-27;1347.75;1368.70;1347.75;1362.84;723800000;1362.84
1999-07-26;1356.94;1358.61;1346.20;1347.76;613450000;1347.76
1999-07-23;1360.97;1367.41;1349.91;1356.94;630580000;1356.94
1999-07-22;1379.29;1379.29;1353.98;1360.97;771700000;1360.97
1999-07-21;1377.10;1386.66;1372.63;1379.29;785500000;1379.29
1999-07-20;1407.65;1407.65;1375.15;1377.10;754800000;1377.10
1999-07-19;1418.78;1420.33;1404.56;1407.65;642330000;1407.65
1999-07-16;1409.62;1418.78;1407.07;1418.78;714100000;1418.78
1999-07-15;1398.17;1409.84;1398.17;1409.62;818800000;1409.62
1999-07-14;1393.56;1400.05;1386.51;1398.17;756100000;1398.17
1999-07-13;1399.10;1399.10;1386.84;1393.56;736000000;1393.56
1999-07-12;1403.28;1406.82;1394.70;1399.10;685300000;1399.10
1999-07-09;1394.42;1403.28;1394.42;1403.28;701000000;1403.28
1999-07-08;1395.86;1403.25;1386.69;1394.42;830600000;1394.42
1999-07-07;1388.12;1395.88;1384.95;1395.86;791200000;1395.86
1999-07-06;1391.22;1405.29;1387.08;1388.12;722900000;1388.12
1999-07-02;1380.96;1391.22;1379.57;1391.22;613570000;1391.22
1999-07-01;1372.71;1382.80;1360.80;1380.96;843400000;1380.96
1999-06-30;1351.45;1372.93;1338.78;1372.71;1117000000;1372.71
1999-06-29;1331.35;1351.51;1328.40;1351.45;820100000;1351.45
1999-06-28;1315.31;1333.68;1315.31;1331.35;652910000;1331.35
1999-06-25;1315.78;1329.13;1312.64;1315.31;623460000;1315.31
1999-06-24;1333.06;1333.06;1308.47;1315.78;690400000;1315.78
1999-06-23;1335.87;1335.88;1322.55;1333.06;731800000;1333.06
1999-06-22;1349.00;1351.12;1335.52;1335.88;716500000;1335.88
1999-06-21;1342.84;1349.06;1337.63;1349.00;686600000;1349.00
1999-06-18;1339.90;1344.48;1333.52;1342.84;914500000;1342.84
1999-06-17;1330.41;1343.54;1322.75;1339.90;700300000;1339.90
1999-06-16;1301.16;1332.83;1301.16;1330.41;806800000;1330.41
1999-06-15;1294.00;1310.76;1294.00;1301.16;696600000;1301.16
1999-06-14;1293.64;1301.99;1292.20;1294.00;669400000;1294.00
1999-06-11;1302.82;1311.97;1287.88;1293.64;698200000;1293.64
1999-06-10;1318.64;1318.64;1293.28;1302.82;716500000;1302.82
1999-06-09;1317.33;1326.01;1314.73;1318.64;662000000;1318.64
1999-06-08;1334.52;1334.52;1312.83;1317.33;685900000;1317.33
1999-06-07;1327.75;1336.42;1325.89;1334.52;664300000;1334.52
1999-06-04;1299.54;1327.75;1299.54;1327.75;694500000;1327.75
1999-06-03;1294.81;1304.15;1294.20;1299.54;719600000;1299.54
1999-06-02;1294.26;1297.10;1277.47;1294.81;728000000;1294.81
1999-06-01;1301.84;1301.84;1281.44;1294.26;683800000;1294.26
1999-05-28;1281.41;1304.00;1281.41;1301.84;649960000;1301.84
1999-05-27;1304.76;1304.76;1277.31;1281.41;811400000;1281.41
1999-05-26;1284.40;1304.85;1278.43;1304.76;870800000;1304.76
1999-05-25;1306.65;1317.52;1284.38;1284.40;826700000;1284.40
1999-05-24;1330.29;1333.02;1303.53;1306.65;754700000;1306.65
1999-05-21;1338.83;1340.88;1326.19;1330.29;686600000;1330.29
1999-05-20;1344.23;1350.49;1338.83;1338.83;752200000;1338.83
1999-05-19;1333.32;1344.23;1327.05;1344.23;801100000;1344.23
1999-05-18;1339.49;1345.44;1323.46;1333.32;753400000;1333.32
1999-05-17;1337.80;1339.95;1321.19;1339.49;665500000;1339.49
1999-05-14;1367.56;1367.56;1332.63;1337.80;727800000;1337.80
1999-05-13;1364.00;1375.98;1364.00;1367.56;796900000;1367.56
1999-05-12;1355.61;1367.36;1333.10;1364.00;825500000;1364.00
1999-05-11;1340.30;1360.00;1340.30;1355.61;836100000;1355.61
1999-05-10;1345.00;1352.01;1334.00;1340.30;773300000;1340.30
1999-05-07;1332.05;1345.99;1332.05;1345.00;814900000;1345.00
1999-05-06;1347.31;1348.36;1322.56;1332.05;875400000;1332.05
1999-05-05;1332.00;1347.32;1317.44;1347.31;913500000;1347.31
1999-05-04;1354.63;1354.64;1330.64;1332.00;933100000;1332.00
1999-05-03;1335.18;1354.63;1329.01;1354.63;811400000;1354.63
1999-04-30;1342.83;1351.83;1314.58;1335.18;936500000;1335.18
1999-04-29;1350.91;1356.75;1336.81;1342.83;1003600000;1342.83
1999-04-28;1362.80;1368.62;1348.29;1350.91;951700000;1350.91
1999-04-27;1360.04;1371.56;1356.55;1362.80;891700000;1362.80
1999-04-26;1356.85;1363.56;1353.72;1360.04;712000000;1360.04
1999-04-23;1358.83;1363.65;1348.45;1356.85;744900000;1356.85
1999-04-22;1336.12;1358.84;1336.12;1358.82;927900000;1358.82
1999-04-21;1306.17;1336.12;1301.84;1336.12;920000000;1336.12
1999-04-20;1289.48;1306.30;1284.21;1306.17;985400000;1306.17
1999-04-19;1319.00;1340.10;1284.48;1289.48;1214400000;1289.48
1999-04-16;1322.86;1325.03;1311.40;1319.00;1002300000;1319.00
1999-04-15;1328.44;1332.41;1308.38;1322.85;1089800000;1322.85
1999-04-14;1349.82;1357.24;1326.41;1328.44;952000000;1328.44
1999-04-13;1358.64;1362.38;1344.03;1349.82;810900000;1349.82
1999-04-12;1348.35;1358.69;1333.48;1358.63;810800000;1358.63
1999-04-09;1343.98;1351.22;1335.24;1348.35;716100000;1348.35
1999-04-08;1326.89;1344.08;1321.60;1343.98;850500000;1343.98
1999-04-07;1317.89;1329.58;1312.59;1326.89;816400000;1326.89
1999-04-06;1321.12;1326.76;1311.07;1317.89;787500000;1317.89
1999-04-05;1293.72;1321.12;1293.72;1321.12;695800000;1321.12
1999-04-01;1286.37;1294.54;1282.56;1293.72;703000000;1293.72
1999-03-31;1300.75;1313.60;1285.87;1286.37;924300000;1286.37
1999-03-30;1310.17;1310.17;1295.47;1300.75;729000000;1300.75
1999-03-29;1282.80;1311.76;1282.80;1310.17;747900000;1310.17
1999-03-26;1289.99;1289.99;1277.25;1282.80;707200000;1282.80
1999-03-25;1268.59;1289.99;1268.59;1289.99;784200000;1289.99
1999-03-24;1262.14;1269.02;1256.43;1268.59;761900000;1268.59
1999-03-23;1297.01;1297.01;1257.46;1262.14;811300000;1262.14
1999-03-22;1299.29;1303.84;1294.26;1297.01;658200000;1297.01
1999-03-19;1316.55;1323.82;1298.92;1299.29;914700000;1299.29
1999-03-18;1297.82;1317.62;1294.75;1316.55;831000000;1316.55
1999-03-17;1306.38;1306.55;1292.63;1297.82;752300000;1297.82
1999-03-16;1307.26;1311.11;1302.29;1306.38;751900000;1306.38
1999-03-15;1294.59;1307.47;1291.03;1307.26;727200000;1307.26
1999-03-12;1297.68;1304.42;1289.17;1294.59;825800000;1294.59
1999-03-11;1286.84;1306.43;1286.84;1297.68;904800000;1297.68
1999-03-10;1279.84;1287.02;1275.16;1286.84;841900000;1286.84
1999-03-09;1282.73;1293.74;1275.11;1279.84;803700000;1279.84
1999-03-08;1275.47;1282.74;1271.58;1282.73;714600000;1282.73
1999-03-05;1246.64;1275.73;1246.64;1275.47;834900000;1275.47
1999-03-04;1227.70;1247.74;1227.70;1246.64;770900000;1246.64
1999-03-03;1225.50;1231.63;1216.03;1227.70;751700000;1227.70
1999-03-02;1236.16;1248.31;1221.87;1225.50;753600000;1225.50
1999-03-01;1238.33;1238.70;1221.88;1236.16;699500000;1236.16
1999-02-26;1245.02;1246.73;1226.24;1238.33;784600000;1238.33
1999-02-25;1253.41;1253.41;1225.01;1245.02;740500000;1245.02
1999-02-24;1271.18;1283.84;1251.94;1253.41;782000000;1253.41
1999-02-23;1272.14;1280.38;1263.36;1271.18;781100000;1271.18
1999-02-22;1239.22;1272.22;1239.22;1272.14;718500000;1272.14
1999-02-19;1237.28;1247.91;1232.03;1239.22;700000000;1239.22
1999-02-18;1224.03;1239.13;1220.70;1237.28;742400000;1237.28
1999-02-17;1241.87;1249.31;1220.92;1224.03;735100000;1224.03
1999-02-16;1230.13;1252.17;1230.13;1241.87;653760000;1241.87
1999-02-12;1254.04;1254.04;1225.53;1230.13;691500000;1230.13
1999-02-11;1223.55;1254.05;1223.19;1254.04;815800000;1254.04
1999-02-10;1216.14;1226.78;1211.89;1223.55;721400000;1223.55
1999-02-09;1243.77;1243.97;1215.63;1216.14;736000000;1216.14
1999-02-08;1239.40;1246.93;1231.98;1243.77;705400000;1243.77
1999-02-05;1248.49;1251.86;1232.28;1239.40;872000000;1239.40
1999-02-04;1272.07;1272.23;1248.36;1248.49;854400000;1248.49
1999-02-03;1261.99;1276.04;1255.27;1272.07;876500000;1272.07
1999-02-02;1273.00;1273.49;1247.56;1261.99;845500000;1261.99
1999-02-01;1279.64;1283.75;1271.31;1273.00;799400000;1273.00
1999-01-29;1265.37;1280.37;1255.18;1279.64;917000000;1279.64
1999-01-28;1243.17;1266.40;1243.17;1265.37;848800000;1265.37
1999-01-27;1252.31;1262.61;1242.82;1243.17;893800000;1243.17
1999-01-26;1233.98;1253.25;1233.98;1252.31;896400000;1252.31
1999-01-25;1225.19;1233.98;1219.46;1233.98;723900000;1233.98
1999-01-22;1235.16;1236.41;1217.97;1225.19;785900000;1225.19
1999-01-21;1256.62;1256.94;1232.19;1235.16;871800000;1235.16
1999-01-20;1252.00;1274.07;1251.54;1256.62;905700000;1256.62
1999-01-19;1243.26;1253.27;1234.91;1252.00;785500000;1252.00
1999-01-15;1212.19;1243.26;1212.19;1243.26;798100000;1243.26
1999-01-14;1234.40;1236.81;1209.54;1212.19;797200000;1212.19
1999-01-13;1239.51;1247.75;1205.46;1234.40;931500000;1234.40
1999-01-12;1263.88;1264.45;1238.29;1239.51;800200000;1239.51
1999-01-11;1275.09;1276.22;1253.34;1263.88;818000000;1263.88
1999-01-08;1269.73;1278.24;1261.82;1275.09;937800000;1275.09
1999-01-07;1272.34;1272.34;1257.68;1269.73;863000000;1269.73
1999-01-06;1244.78;1272.50;1244.78;1272.34;986900000;1272.34
1999-01-05;1228.10;1246.11;1228.10;1244.78;775000000;1244.78
1999-01-04;1229.23;1248.81;1219.10;1228.10;877000000;1228.10
1998-12-31;1231.93;1237.18;1224.96;1229.23;719200000;1229.23
1998-12-30;1241.81;1244.93;1231.20;1231.93;594220000;1231.93
1998-12-29;1225.49;1241.86;1220.78;1241.81;586490000;1241.81
1998-12-28;1226.27;1231.52;1221.17;1225.49;531560000;1225.49
1998-12-24;1228.54;1229.72;1224.85;1226.27;246980000;1226.27
1998-12-23;1203.57;1229.89;1203.57;1228.54;697500000;1228.54
1998-12-22;1202.84;1209.22;1192.72;1203.57;680500000;1203.57
1998-12-21;1188.03;1210.88;1188.03;1202.84;744800000;1202.84
1998-12-18;1179.98;1188.89;1178.27;1188.03;839600000;1188.03
1998-12-17;1161.94;1180.03;1161.94;1179.98;739400000;1179.98
1998-12-16;1162.83;1166.29;1154.69;1161.94;725500000;1161.94
1998-12-15;1141.20;1162.83;1141.20;1162.83;777900000;1162.83
1998-12-14;1166.46;1166.46;1136.89;1141.20;741800000;1141.20
1998-12-11;1165.02;1167.89;1153.19;1166.46;688900000;1166.46
1998-12-10;1183.49;1183.77;1163.75;1165.02;748600000;1165.02
1998-12-09;1181.38;1185.22;1175.89;1183.49;694200000;1183.49
1998-12-08;1187.70;1193.53;1172.78;1181.38;727700000;1181.38
1998-12-07;1176.74;1188.96;1176.71;1187.70;671200000;1187.70
1998-12-04;1150.14;1176.74;1150.14;1176.74;709700000;1176.74
1998-12-03;1171.25;1176.99;1149.61;1150.14;799100000;1150.14
1998-12-02;1175.28;1175.28;1157.76;1171.25;727400000;1171.25
1998-12-01;1163.63;1175.89;1150.31;1175.28;789200000;1175.28
1998-11-30;1192.33;1192.72;1163.63;1163.63;687900000;1163.63
1998-11-27;1186.87;1192.97;1186.83;1192.33;256950000;1192.33
1998-11-25;1182.99;1187.16;1179.37;1186.87;583580000;1186.87
1998-11-24;1188.21;1191.30;1181.81;1182.99;766200000;1182.99
1998-11-23;1163.55;1188.21;1163.55;1188.21;774100000;1188.21
1998-11-20;1152.61;1163.55;1152.61;1163.55;721200000;1163.55
1998-11-19;1144.48;1155.10;1144.42;1152.61;671000000;1152.61
1998-11-18;1139.32;1144.52;1133.07;1144.48;652510000;1144.48
1998-11-17;1135.87;1151.71;1129.67;1139.32;705200000;1139.32
1998-11-16;1125.72;1138.72;1125.72;1135.87;615580000;1135.87
1998-11-13;1117.69;1126.34;1116.76;1125.72;602270000;1125.72
1998-11-12;1120.97;1126.57;1115.55;1117.69;662300000;1117.69
1998-11-11;1128.26;1136.25;1117.40;1120.97;715700000;1120.97
1998-11-10;1130.20;1135.37;1122.80;1128.26;671300000;1128.26
1998-11-09;1141.01;1141.01;1123.17;1130.20;592990000;1130.20
1998-11-06;1133.85;1141.30;1131.18;1141.01;683100000;1141.01
1998-11-05;1118.67;1133.88;1109.55;1133.85;770200000;1133.85
1998-11-04;1110.84;1127.18;1110.59;1118.67;861100000;1118.67
1998-11-03;1111.60;1115.02;1106.42;1110.84;704300000;1110.84
1998-11-02;1098.67;1114.44;1098.67;1111.60;753800000;1111.60
1998-10-30;1085.93;1103.78;1085.93;1098.67;785000000;1098.67
1998-10-29;1068.09;1086.11;1065.95;1085.93;699400000;1085.93
1998-10-28;1065.34;1072.79;1059.65;1068.09;677500000;1068.09
1998-10-27;1072.32;1087.08;1063.06;1065.34;764500000;1065.34
1998-10-26;1070.67;1081.23;1068.17;1072.32;609910000;1072.32
1998-10-23;1078.48;1078.48;1067.43;1070.67;637640000;1070.67
1998-10-22;1069.92;1080.43;1061.47;1078.48;754900000;1078.48
1998-10-21;1063.93;1073.61;1058.08;1069.92;745100000;1069.92
1998-10-20;1062.39;1084.06;1060.61;1063.93;958200000;1063.93
1998-10-19;1056.42;1065.21;1054.23;1062.39;738600000;1062.39
1998-10-16;1047.49;1062.65;1047.49;1056.42;1042200000;1056.42
1998-10-15;1005.53;1053.09;1000.12;1047.49;937600000;1047.49
1998-10-14;994.80;1014.42;987.80;1005.53;791200000;1005.53
1998-10-13;997.71;1000.78;987.55;994.80;733300000;994.80
1998-10-12;984.39;1010.71;984.39;997.71;691100000;997.71
1998-10-09;959.44;984.42;953.04;984.39;878100000;984.39
1998-10-08;970.68;970.68;923.32;959.44;1114600000;959.44
1998-10-07;984.59;995.66;957.15;970.68;977000000;970.68
1998-10-06;988.56;1008.77;974.81;984.59;845700000;984.59
1998-10-05;1002.60;1002.60;964.72;988.56;817500000;988.56
1998-10-02;986.39;1005.45;971.69;1002.60;902900000;1002.60
1998-10-01;1017.01;1017.01;981.29;986.39;899700000;986.39
1998-09-30;1049.02;1049.02;1015.73;1017.01;800100000;1017.01
1998-09-29;1048.69;1056.31;1039.88;1049.02;760100000;1049.02
1998-09-28;1044.75;1061.46;1042.23;1048.69;690500000;1048.69
1998-09-25;1042.72;1051.89;1028.49;1044.75;736800000;1044.75
1998-09-24;1066.09;1066.11;1033.04;1042.72;805900000;1042.72
1998-09-23;1029.63;1066.09;1029.63;1066.09;899700000;1066.09
1998-09-22;1023.89;1033.89;1021.96;1029.63;694900000;1029.63
1998-09-21;1020.09;1026.02;993.82;1023.89;609880000;1023.89
1998-09-18;1018.87;1022.01;1011.86;1020.09;794700000;1020.09
1998-09-17;1045.48;1045.48;1016.05;1018.87;694500000;1018.87
1998-09-16;1037.68;1046.07;1029.31;1045.48;797500000;1045.48
1998-09-15;1029.72;1037.90;1021.42;1037.68;724600000;1037.68
1998-09-14;1009.06;1038.38;1009.06;1029.72;714400000;1029.72
1998-09-11;980.19;1009.06;969.71;1009.06;819100000;1009.06
1998-09-10;1006.20;1006.20;968.64;980.19;880300000;980.19
1998-09-09;1023.46;1027.72;1004.56;1006.20;704300000;1006.20
1998-09-08;973.89;1023.46;973.89;1023.46;814800000;1023.46
1998-09-04;982.26;991.41;956.51;973.89;780300000;973.89
1998-09-03;990.47;990.47;969.32;982.26;880500000;982.26
1998-09-02;994.26;1013.19;988.40;990.48;894600000;990.48
1998-09-01;957.28;1000.71;939.98;994.26;1216600000;994.26
1998-08-31;1027.14;1033.47;957.28;957.28;917500000;957.28
1998-08-28;1042.59;1051.80;1021.04;1027.14;840300000;1027.14
1998-08-27;1084.19;1084.19;1037.61;1042.59;938600000;1042.59
1998-08-26;1092.85;1092.85;1075.91;1084.19;674100000;1084.19
1998-08-25;1088.14;1106.64;1085.53;1092.85;664900000;1092.85
1998-08-24;1081.24;1093.82;1081.24;1088.14;558100000;1088.14
1998-08-21;1091.60;1091.60;1054.92;1081.24;725700000;1081.24
1998-08-20;1098.06;1098.79;1089.55;1091.60;621630000;1091.60
1998-08-19;1101.20;1106.32;1094.93;1098.06;633630000;1098.06
1998-08-18;1083.67;1101.72;1083.67;1101.20;690600000;1101.20
1998-08-17;1062.75;1083.67;1055.08;1083.67;584380000;1083.67
1998-08-14;1074.91;1083.92;1057.22;1062.75;644030000;1062.75
1998-08-13;1084.22;1091.50;1074.91;1074.91;660700000;1074.91
1998-08-12;1068.98;1084.70;1068.98;1084.22;711700000;1084.22
1998-08-11;1083.14;1083.14;1054.00;1068.98;774400000;1068.98
1998-08-10;1089.45;1092.82;1081.76;1083.14;579180000;1083.14
1998-08-07;1089.63;1102.54;1084.72;1089.45;759100000;1089.45
1998-08-06;1081.43;1090.95;1074.94;1089.63;768400000;1089.63
1998-08-05;1072.12;1084.80;1057.35;1081.43;851600000;1081.43
1998-08-04;1112.44;1119.73;1071.82;1072.12;852600000;1072.12
1998-08-03;1120.67;1121.79;1110.39;1112.44;620400000;1112.44
1998-07-31;1142.95;1142.97;1114.30;1120.67;645910000;1120.67
1998-07-30;1125.21;1143.07;1125.21;1142.95;687400000;1142.95
1998-07-29;1130.24;1138.56;1121.98;1125.21;644350000;1125.21
1998-07-28;1147.27;1147.27;1119.44;1130.24;703600000;1130.24
1998-07-27;1140.80;1147.27;1128.19;1147.27;619990000;1147.27
1998-07-24;1139.75;1150.14;1129.11;1140.80;698600000;1140.80
1998-07-23;1164.08;1164.35;1139.75;1139.75;741600000;1139.75
1998-07-22;1165.07;1167.67;1155.20;1164.08;739800000;1164.08
1998-07-21;1184.10;1187.37;1163.05;1165.07;659700000;1165.07
1998-07-20;1186.75;1190.58;1179.19;1184.10;560580000;1184.10
1998-07-17;1183.99;1188.10;1182.42;1186.75;618030000;1186.75
1998-07-16;1174.81;1184.02;1170.40;1183.99;677800000;1183.99
1998-07-15;1177.58;1181.48;1174.73;1174.81;723900000;1174.81
1998-07-14;1165.19;1179.76;1165.19;1177.58;700300000;1177.58
1998-07-13;1164.33;1166.98;1160.21;1165.19;574880000;1165.19
1998-07-10;1158.57;1166.93;1150.88;1164.33;576080000;1164.33
1998-07-09;1166.38;1166.38;1156.03;1158.56;663600000;1158.56
1998-07-08;1154.66;1166.89;1154.66;1166.38;607230000;1166.38
1998-07-07;1157.33;1159.81;1152.85;1154.66;624890000;1154.66
1998-07-06;1146.42;1157.33;1145.03;1157.33;514750000;1157.33
1998-07-02;1148.56;1148.56;1142.99;1146.42;510210000;1146.42
1998-07-01;1133.84;1148.56;1133.84;1148.56;701600000;1148.56
1998-06-30;1138.49;1140.80;1131.98;1133.84;757200000;1133.84
1998-06-29;1133.20;1145.15;1133.20;1138.49;564350000;1138.49
1998-06-26;1129.28;1136.83;1129.28;1133.20;520050000;1133.20
1998-06-25;1132.88;1142.04;1127.60;1129.28;669900000;1129.28
1998-06-24;1119.49;1134.40;1115.10;1132.88;714900000;1132.88
1998-06-23;1103.21;1119.49;1103.21;1119.49;657100000;1119.49
1998-06-22;1100.65;1109.01;1099.42;1103.21;531550000;1103.21
1998-06-19;1106.37;1111.25;1097.10;1100.65;715500000;1100.65
1998-06-18;1107.11;1109.36;1103.71;1106.37;590440000;1106.37
1998-06-17;1087.59;1112.87;1087.58;1107.11;744400000;1107.11
1998-06-16;1077.01;1087.59;1074.67;1087.59;664600000;1087.59
1998-06-15;1098.84;1098.84;1077.01;1077.01;595820000;1077.01
1998-06-12;1094.58;1098.84;1080.83;1098.84;633300000;1098.84
1998-06-11;1112.28;1114.20;1094.28;1094.58;627470000;1094.58
1998-06-10;1118.41;1126.00;1110.27;1112.28;609410000;1112.28
1998-06-09;1115.72;1119.92;1111.31;1118.41;563610000;1118.41
1998-06-08;1113.86;1119.70;1113.31;1115.72;543390000;1115.72
1998-06-05;1095.10;1113.88;1094.83;1113.86;558440000;1113.86
1998-06-04;1082.73;1095.93;1078.10;1094.83;577470000;1094.83
1998-06-03;1093.22;1097.43;1081.09;1082.73;584480000;1082.73
1998-06-02;1090.98;1098.71;1089.67;1093.22;590930000;1093.22
1998-06-01;1090.82;1097.85;1084.22;1090.98;537660000;1090.98
1998-05-29;1097.60;1104.16;1090.82;1090.82;556780000;1090.82
1998-05-28;1092.23;1099.73;1089.06;1097.60;588900000;1097.60
1998-05-27;1094.02;1094.44;1074.39;1092.23;682040000;1092.23
1998-05-26;1110.47;1116.79;1094.01;1094.02;541410000;1094.02
1998-05-22;1114.64;1116.89;1107.99;1110.47;444070000;1110.47
1998-05-21;1119.06;1124.45;1111.94;1114.64;551970000;1114.64
1998-05-20;1109.52;1119.08;1107.51;1119.06;587240000;1119.06
1998-05-19;1105.82;1113.50;1105.82;1109.52;566020000;1109.52
1998-05-18;1108.73;1112.44;1097.99;1105.82;519100000;1105.82
1998-05-15;1117.37;1118.66;1107.11;1108.73;621990000;1108.73
1998-05-14;1118.86;1124.03;1112.43;1117.37;578380000;1117.37
1998-05-13;1115.79;1122.22;1114.93;1118.86;600010000;1118.86
1998-05-12;1106.64;1115.96;1102.78;1115.79;604420000;1115.79
1998-05-11;1108.14;1119.13;1103.72;1106.64;560840000;1106.64
1998-05-08;1095.14;1111.42;1094.53;1108.14;567890000;1108.14
1998-05-07;1104.92;1105.58;1094.59;1095.14;582240000;1095.14
1998-05-06;1115.50;1118.39;1104.64;1104.92;606540000;1104.92
1998-05-05;1122.07;1122.07;1111.16;1115.50;583630000;1115.50
1998-05-04;1121.00;1130.52;1121.00;1122.07;551700000;1122.07
1998-05-01;1111.75;1121.02;1111.75;1121.00;581970000;1121.00
1998-04-30;1094.63;1116.97;1094.63;1111.75;695600000;1111.75
1998-04-29;1085.11;1098.24;1084.65;1094.62;638790000;1094.62
1998-04-28;1086.54;1095.94;1081.49;1085.11;678600000;1085.11
1998-04-27;1107.90;1107.90;1076.70;1086.54;685960000;1086.54
1998-04-24;1119.58;1122.81;1104.77;1107.90;633890000;1107.90
1998-04-23;1130.54;1130.54;1117.49;1119.58;653190000;1119.58
1998-04-22;1126.67;1132.98;1126.29;1130.54;696740000;1130.54
1998-04-21;1123.65;1129.65;1119.54;1126.67;675640000;1126.67
1998-04-20;1122.72;1124.88;1118.43;1123.65;595190000;1123.65
1998-04-17;1108.17;1122.72;1104.95;1122.72;672290000;1122.72
1998-04-16;1119.32;1119.32;1105.27;1108.17;699570000;1108.17
1998-04-15;1115.75;1119.90;1112.24;1119.32;685020000;1119.32
1998-04-14;1109.69;1115.95;1109.48;1115.75;613730000;1115.75
1998-04-13;1110.67;1110.75;1100.60;1109.69;564480000;1109.69
1998-04-09;1101.65;1111.45;1101.65;1110.67;548940000;1110.67
1998-04-08;1109.55;1111.60;1098.21;1101.65;616330000;1101.65
1998-04-07;1121.38;1121.38;1102.44;1109.55;670760000;1109.55
1998-04-06;1122.70;1131.99;1121.37;1121.38;625810000;1121.38
1998-04-03;1120.01;1126.36;1118.12;1122.70;653880000;1122.70
1998-04-02;1108.15;1121.01;1107.89;1120.01;674340000;1120.01
1998-04-01;1101.75;1109.19;1095.29;1108.15;677310000;1108.15
1998-03-31;1093.55;1110.13;1093.55;1101.75;674930000;1101.75
1998-03-30;1095.44;1099.10;1090.02;1093.60;497400000;1093.60
1998-03-27;1100.80;1107.18;1091.14;1095.44;582190000;1095.44
1998-03-26;1101.93;1106.28;1097.00;1100.80;606770000;1100.80
1998-03-25;1105.65;1113.07;1092.84;1101.93;676550000;1101.93
1998-03-24;1095.55;1106.75;1095.55;1105.65;605720000;1105.65
1998-03-23;1099.16;1101.16;1094.25;1095.55;631350000;1095.55
1998-03-20;1089.74;1101.04;1089.39;1099.16;717310000;1099.16
1998-03-19;1085.52;1089.74;1084.30;1089.74;598240000;1089.74
1998-03-18;1080.45;1085.52;1077.77;1085.52;632690000;1085.52
1998-03-17;1079.27;1080.52;1073.29;1080.45;680960000;1080.45
1998-03-16;1068.61;1079.46;1068.61;1079.27;548980000;1079.27
1998-03-13;1069.92;1075.86;1066.57;1068.61;597800000;1068.61
1998-03-12;1068.47;1071.87;1063.54;1069.92;594940000;1069.92
1998-03-11;1064.25;1069.18;1064.22;1068.47;655260000;1068.47
1998-03-10;1052.31;1064.59;1052.31;1064.25;631920000;1064.25
1998-03-09;1055.69;1058.55;1050.02;1052.31;624700000;1052.31
1998-03-06;1035.05;1055.69;1035.05;1055.69;665500000;1055.69
1998-03-05;1047.33;1047.33;1030.87;1035.05;648270000;1035.05
1998-03-04;1052.02;1052.02;1042.74;1047.33;644280000;1047.33
1998-03-03;1047.70;1052.02;1043.41;1052.02;612360000;1052.02
1998-03-02;1049.34;1053.98;1044.70;1047.70;591470000;1047.70
1998-02-27;1048.67;1051.66;1044.40;1049.34;574480000;1049.34
1998-02-26;1042.90;1048.68;1039.85;1048.67;646280000;1048.67
1998-02-25;1030.56;1045.79;1030.56;1042.90;611350000;1042.90
1998-02-24;1038.14;1038.73;1028.89;1030.56;589880000;1030.56
1998-02-23;1034.21;1038.68;1031.76;1038.14;550730000;1038.14
1998-02-20;1028.28;1034.21;1022.69;1034.21;594300000;1034.21
1998-02-19;1032.08;1032.93;1026.62;1028.28;581820000;1028.28
1998-02-18;1022.76;1032.08;1021.70;1032.08;606000000;1032.08
1998-02-17;1020.09;1028.02;1020.09;1022.76;605890000;1022.76
1998-02-13;1024.14;1024.14;1017.71;1020.09;531940000;1020.09
1998-02-12;1020.01;1026.30;1008.55;1024.14;611480000;1024.14
1998-02-11;1019.01;1020.71;1016.38;1020.01;599300000;1020.01
1998-02-10;1010.74;1022.15;1010.71;1019.01;642800000;1019.01
1998-02-09;1012.46;1015.33;1006.28;1010.74;524810000;1010.74
1998-02-06;1003.54;1013.07;1003.36;1012.46;569650000;1012.46
1998-02-05;1006.90;1013.51;1000.27;1003.54;703980000;1003.54
1998-02-04;1006.00;1009.52;999.43;1006.90;695420000;1006.90
1998-02-03;1001.27;1006.13;996.90;1006.00;692120000;1006.00
1998-02-02;980.28;1002.48;980.28;1001.27;724320000;1001.27
1998-01-30;985.49;987.41;979.63;980.28;613380000;980.28
1998-01-29;977.46;992.65;975.21;985.49;750760000;985.49
1998-01-28;969.02;978.63;969.02;977.46;708470000;977.46
1998-01-27;956.95;973.23;956.26;969.02;679140000;969.02
1998-01-26;957.59;963.04;954.24;956.95;555080000;956.95
1998-01-23;963.04;966.44;950.86;957.59;635770000;957.59
1998-01-22;970.81;970.81;959.49;963.04;646570000;963.04
1998-01-21;978.60;978.60;963.29;970.81;626160000;970.81
1998-01-20;961.51;978.60;961.48;978.60;644790000;978.60
1998-01-16;950.73;965.12;950.73;961.51;670080000;961.51
1998-01-15;957.94;957.94;950.27;950.73;569050000;950.73
1998-01-14;952.12;958.12;948.00;957.94;603280000;957.94
1998-01-13;939.21;952.14;939.21;952.12;646740000;952.12
1998-01-12;927.69;939.25;912.83;939.21;705450000;939.21
1998-01-09;956.05;956.05;921.72;927.69;746420000;927.69
1998-01-08;964.00;964.00;955.04;956.05;652140000;956.05
1998-01-07;966.58;966.58;952.67;964.00;667390000;964.00
1998-01-06;977.07;977.07;962.68;966.58;618360000;966.58
1998-01-05;975.04;982.63;969.00;977.07;628070000;977.07
1998-01-02;970.43;975.04;965.73;975.04;366730000;975.04
1997-12-31;970.84;975.02;967.41;970.43;467280000;970.43
1997-12-30;953.35;970.84;953.35;970.84;499500000;970.84
1997-12-29;936.46;953.95;936.46;953.35;443160000;953.35
1997-12-26;932.70;939.99;932.70;936.46;154900000;936.46
1997-12-24;939.13;942.88;932.70;932.70;265980000;932.70
1997-12-23;953.70;954.51;938.91;939.13;515070000;939.13
1997-12-22;946.78;956.73;946.25;953.70;530670000;953.70
1997-12-19;955.30;955.30;924.92;946.78;793200000;946.78
1997-12-18;965.54;965.54;950.55;955.30;618870000;955.30
1997-12-17;968.04;974.30;964.25;965.54;618900000;965.54
1997-12-16;963.39;973.00;963.39;968.04;623320000;968.04
1997-12-15;953.39;965.96;953.39;963.39;597150000;963.39
1997-12-12;954.94;961.32;947.00;953.39;579280000;953.39
1997-12-11;969.79;969.79;951.89;954.94;631770000;954.94
1997-12-10;975.78;975.78;962.68;969.79;602290000;969.79
1997-12-09;982.37;982.37;973.81;975.78;539130000;975.78
1997-12-08;983.79;985.67;979.57;982.37;490320000;982.37
1997-12-05;973.10;986.25;969.10;983.79;563590000;983.79
1997-12-04;976.77;983.36;971.37;973.10;633470000;973.10
1997-12-03;971.68;980.81;966.16;976.77;624610000;976.77
1997-12-02;974.78;976.20;969.83;971.68;576120000;971.68
1997-12-01;955.40;974.77;955.40;974.77;590300000;974.77
1997-11-28;951.64;959.13;951.64;955.40;189070000;955.40
1997-11-26;950.82;956.47;950.82;951.64;487750000;951.64
1997-11-25;946.67;954.47;944.71;950.82;587890000;950.82
1997-11-24;963.09;963.09;945.22;946.67;514920000;946.67
1997-11-21;958.98;964.55;954.60;963.09;611000000;963.09
1997-11-20;944.59;961.83;944.59;958.98;602610000;958.98
1997-11-19;938.23;947.28;934.83;944.59;542720000;944.59
1997-11-18;946.20;947.65;937.43;938.23;521380000;938.23
1997-11-17;928.35;949.66;928.35;946.20;576540000;946.20
1997-11-14;916.66;930.44;915.34;928.35;635760000;928.35
1997-11-13;905.96;917.79;900.61;916.66;653960000;916.66
1997-11-12;923.78;923.88;905.34;905.96;585340000;905.96
1997-11-11;921.13;928.29;919.63;923.78;435660000;923.78
1997-11-10;927.51;935.90;920.26;921.13;464140000;921.13
1997-11-07;938.03;938.03;915.39;927.51;569980000;927.51
1997-11-06;942.76;942.85;934.16;938.03;522890000;938.03
1997-11-05;940.76;949.62;938.16;942.76;565680000;942.76
1997-11-04;938.99;941.40;932.66;940.76;541590000;940.76
1997-11-03;914.62;939.02;914.62;938.99;564740000;938.99
1997-10-31;903.68;919.93;903.68;914.62;638070000;914.62
1997-10-30;919.16;923.28;903.68;903.68;712230000;903.68
1997-10-29;921.85;935.24;913.88;919.16;777660000;919.16
1997-10-28;876.99;923.09;855.27;921.85;1202550000;921.85
1997-10-27;941.64;941.64;876.73;876.99;693730000;876.99
1997-10-24;950.69;960.04;937.55;941.64;677630000;941.64
1997-10-23;968.49;968.49;944.16;950.69;673270000;950.69
1997-10-22;972.28;972.61;965.66;968.49;613490000;968.49
1997-10-21;955.61;972.56;955.61;972.28;582310000;972.28
1997-10-20;944.16;955.72;941.43;955.61;483880000;955.61
1997-10-17;955.23;955.23;931.58;944.16;624980000;944.16
1997-10-16;965.72;973.38;950.77;955.25;597010000;955.25
1997-10-15;970.28;970.28;962.75;965.72;505310000;965.72
1997-10-14;968.10;972.86;961.87;970.28;510330000;970.28
1997-10-13;966.98;973.46;966.95;968.10;354800000;968.10
1997-10-10;970.62;970.62;963.42;966.98;500680000;966.98
1997-10-09;973.84;974.72;963.34;970.62;551840000;970.62
1997-10-08;983.12;983.12;968.65;973.84;573110000;973.84
1997-10-07;972.69;983.12;971.95;983.12;551970000;983.12
1997-10-06;965.03;974.16;965.03;972.69;495620000;972.69
1997-10-03;960.46;975.47;955.13;965.03;623370000;965.03
1997-10-02;955.41;960.46;952.94;960.46;474760000;960.46
1997-10-01;947.28;956.71;947.28;955.41;598660000;955.41
1997-09-30;953.34;955.17;947.28;947.28;587500000;947.28
1997-09-29;945.22;953.96;941.94;953.34;477100000;953.34
1997-09-26;937.91;946.44;937.91;945.22;505340000;945.22
1997-09-25;944.48;947.00;937.38;937.91;524880000;937.91
1997-09-24;951.93;959.78;944.07;944.48;639460000;944.48
1997-09-23;955.43;955.78;948.07;951.93;522930000;951.93
1997-09-22;950.51;960.59;950.51;955.43;490900000;955.43
1997-09-19;947.29;952.35;943.90;950.51;631040000;950.51
1997-09-18;943.00;958.19;943.00;947.29;566830000;947.29
1997-09-17;945.64;950.29;941.99;943.00;590550000;943.00
1997-09-16;919.77;947.66;919.77;945.64;636380000;945.64
1997-09-15;923.91;928.90;919.41;919.77;468030000;919.77
1997-09-12;912.59;925.05;906.70;923.91;544150000;923.91
1997-09-11;919.03;919.03;902.56;912.59;575020000;912.59
1997-09-10;933.62;933.62;918.76;919.03;517620000;919.03
1997-09-09;931.20;938.90;927.28;933.62;502200000;933.62
1997-09-08;929.05;936.50;929.05;931.20;466430000;931.20
1997-09-05;930.87;940.37;924.05;929.05;536400000;929.05
1997-09-04;927.86;933.36;925.59;930.87;559310000;930.87
1997-09-03;927.58;935.90;926.87;927.86;549060000;927.86
1997-09-02;899.47;927.58;899.47;927.58;491870000;927.58
1997-08-29;903.67;907.28;896.82;899.47;413910000;899.47
1997-08-28;913.70;915.90;898.65;903.67;486300000;903.67
1997-08-27;913.02;916.23;903.83;913.70;492150000;913.70
1997-08-26;920.16;922.47;911.72;913.02;449110000;913.02
1997-08-25;923.55;930.93;917.29;920.16;388990000;920.16
1997-08-22;925.05;925.05;905.42;923.54;460160000;923.54
1997-08-21;939.35;939.47;921.35;925.05;499000000;925.05
1997-08-20;926.01;939.35;924.58;939.35;521270000;939.35
1997-08-19;912.49;926.01;912.49;926.01;545630000;926.01
1997-08-18;900.81;912.57;893.34;912.49;514330000;912.49
1997-08-15;924.77;924.77;900.81;900.81;537820000;900.81
1997-08-14;922.02;930.07;916.92;924.77;530460000;924.77
1997-08-13;926.53;935.77;916.54;922.02;587210000;922.02
1997-08-12;937.00;942.99;925.66;926.53;499310000;926.53
1997-08-11;933.54;938.50;925.39;937.00;480340000;937.00
1997-08-08;951.19;951.19;925.74;933.54;563420000;933.54
1997-08-07;960.32;964.17;950.87;951.19;576030000;951.19
1997-08-06;952.37;962.43;949.45;960.32;565200000;960.32
1997-08-05;950.30;954.21;948.92;952.37;525710000;952.37
1997-08-04;947.14;953.18;943.60;950.30;456000000;950.30
1997-08-01;954.29;955.35;939.04;947.14;513750000;947.14
1997-07-31;952.29;957.73;948.89;954.31;547830000;954.31
1997-07-30;942.29;953.98;941.98;952.29;568470000;952.29
1997-07-29;936.45;942.96;932.56;942.29;544540000;942.29
1997-07-28;938.79;942.97;935.19;936.45;466920000;936.45
1997-07-25;940.30;945.65;936.09;938.79;521510000;938.79
1997-07-24;936.56;941.51;926.91;940.30;571020000;940.30
1997-07-23;933.98;941.80;933.98;936.56;616930000;936.56
1997-07-22;912.94;934.38;912.94;933.98;579590000;933.98
1997-07-21;915.30;915.38;907.12;912.94;459500000;912.94
1997-07-18;931.61;931.61;912.90;915.30;589710000;915.30
1997-07-17;936.59;936.96;927.90;931.61;629250000;931.61
1997-07-16;925.76;939.32;925.76;936.59;647390000;936.59
1997-07-15;918.38;926.15;914.52;925.76;598370000;925.76
1997-07-14;916.68;921.78;912.02;918.38;485960000;918.38
1997-07-11;913.78;919.74;913.11;916.68;500050000;916.68
1997-07-10;907.54;916.54;904.31;913.78;551340000;913.78
1997-07-09;918.75;922.03;902.48;907.54;589110000;907.54
1997-07-08;912.20;918.76;911.56;918.75;526010000;918.75
1997-07-07;916.92;923.26;909.69;912.20;518780000;912.20
1997-07-03;904.03;917.82;904.03;916.92;374680000;916.92
1997-07-02;891.03;904.05;891.03;904.03;526970000;904.03
1997-07-01;885.14;893.88;884.54;891.03;544190000;891.03
1997-06-30;887.30;892.62;879.82;885.14;561540000;885.14
1997-06-27;883.68;894.70;883.68;887.30;472540000;887.30
1997-06-26;888.99;893.21;879.32;883.68;499780000;883.68
1997-06-25;896.34;902.09;882.24;888.99;603040000;888.99
1997-06-24;878.62;896.75;878.62;896.34;542650000;896.34
1997-06-23;898.70;898.70;878.43;878.62;492940000;878.62
1997-06-20;897.99;901.77;897.77;898.70;653110000;898.70
1997-06-19;889.06;900.09;888.99;897.99;536940000;897.99
1997-06-18;894.42;894.42;887.03;889.06;491740000;889.06
1997-06-17;893.90;897.60;886.19;894.42;543010000;894.42
1997-06-16;893.27;895.17;891.21;893.90;414280000;893.90
1997-06-13;883.48;894.69;883.48;893.27;575810000;893.27
1997-06-12;869.57;884.34;869.01;883.46;592730000;883.46
1997-06-11;865.27;870.66;865.15;869.57;513740000;869.57
1997-06-10;862.91;870.05;862.18;865.27;526980000;865.27
1997-06-09;858.01;865.14;858.01;862.91;465810000;862.91
1997-06-06;843.43;859.24;843.36;858.01;488940000;858.01
1997-06-05;840.11;848.89;840.11;843.43;452610000;843.43
1997-06-04;845.48;845.55;838.82;840.11;466690000;840.11
1997-06-03;846.36;850.56;841.51;845.48;527120000;845.48
1997-06-02;848.28;851.34;844.61;846.36;435950000;846.36
1997-05-30;844.08;851.87;831.87;848.28;537200000;848.28
1997-05-29;847.21;848.96;842.61;844.08;462600000;844.08
1997-05-28;849.71;850.95;843.21;847.21;487340000;847.21
1997-05-27;847.03;851.53;840.96;849.71;436150000;849.71
1997-05-23;835.66;848.49;835.66;847.03;417030000;847.03
1997-05-22;839.35;841.91;833.86;835.66;426940000;835.66
1997-05-21;841.66;846.87;835.22;839.35;540730000;839.35
1997-05-20;833.27;841.96;826.41;841.66;450850000;841.66
1997-05-19;829.75;835.92;828.87;833.27;345140000;833.27
1997-05-16;841.88;841.88;829.15;829.75;486780000;829.75
1997-05-15;836.04;842.45;833.34;841.88;458170000;841.88
1997-05-14;833.13;841.29;833.13;836.04;504960000;836.04
1997-05-13;837.66;838.49;829.12;833.13;489760000;833.13
1997-05-12;824.78;838.56;824.78;837.66;459370000;837.66
1997-05-09;820.26;827.69;815.78;824.78;455690000;824.78
1997-05-08;815.62;829.09;811.84;820.26;534120000;820.26
1997-05-07;827.76;827.76;814.70;815.62;500580000;815.62
1997-05-06;830.24;832.29;824.70;827.76;603680000;827.76
1997-05-05;812.97;830.29;811.80;830.29;549410000;830.29
1997-05-02;798.53;812.99;798.53;812.97;499770000;812.97
1997-05-01;801.34;802.95;793.21;798.53;460380000;798.53
1997-04-30;794.05;804.13;791.21;801.34;556070000;801.34
1997-04-29;772.96;794.44;772.96;794.05;547690000;794.05
1997-04-28;765.37;773.89;763.30;772.96;404470000;772.96
1997-04-25;771.18;771.18;764.63;765.37;414350000;765.37
1997-04-24;773.64;779.89;769.72;771.18;493640000;771.18
1997-04-23;774.61;778.19;771.90;773.64;489350000;773.64
1997-04-22;760.37;774.64;759.90;774.61;507500000;774.61
1997-04-21;766.34;767.39;756.38;760.37;397300000;760.37
1997-04-18;761.77;767.93;761.77;766.34;468940000;766.34
1997-04-17;763.53;768.55;760.49;761.77;503760000;761.77
1997-04-16;754.72;763.53;751.99;763.53;498820000;763.53
1997-04-15;743.73;754.72;743.73;754.72;507370000;754.72
1997-04-14;737.65;743.73;733.54;743.73;406800000;743.73
1997-04-11;758.34;758.34;737.64;737.65;444380000;737.65
1997-04-10;760.60;763.73;757.65;758.34;421790000;758.34
1997-04-09;766.12;769.53;759.15;760.60;451500000;760.60
1997-04-08;762.13;766.25;758.36;766.12;450790000;766.12
1997-04-07;757.90;764.82;757.90;762.13;453790000;762.13
1997-04-04;750.32;757.90;744.04;757.90;544580000;757.90
1997-04-03;750.11;751.04;744.40;750.32;498010000;750.32
1997-04-02;759.64;759.65;747.59;750.11;478210000;750.11
1997-04-01;757.12;761.49;751.26;759.64;515770000;759.64
1997-03-31;773.88;773.88;756.13;757.12;555880000;757.12
1997-03-27;790.50;792.58;767.32;773.88;476790000;773.88
1997-03-26;789.07;794.89;786.77;790.50;506670000;790.50
1997-03-25;790.89;798.11;788.39;789.07;487520000;789.07
1997-03-24;784.10;791.01;780.79;790.89;451970000;790.89
1997-03-21;782.65;786.44;782.65;784.10;638760000;784.10
1997-03-20;785.77;786.29;778.04;782.65;497480000;782.65
1997-03-19;789.66;791.59;780.03;785.77;535580000;785.77
1997-03-18;795.71;797.18;785.47;789.66;467330000;789.66
1997-03-17;793.17;796.28;782.98;795.71;495260000;795.71
1997-03-14;789.56;796.88;789.56;793.17;491540000;793.17
1997-03-13;804.26;804.26;789.44;789.56;507560000;789.56
1997-03-12;811.34;811.34;801.07;804.26;490200000;804.26
1997-03-11;813.65;814.90;810.77;811.34;493250000;811.34
1997-03-10;804.97;813.66;803.66;813.65;468780000;813.65
1997-03-07;798.56;808.19;798.56;804.97;508270000;804.97
1997-03-06;801.99;804.11;797.50;798.56;540310000;798.56
1997-03-05;790.95;801.99;790.95;801.99;532500000;801.99
1997-03-04;795.31;798.93;789.98;790.95;537890000;790.95
1997-03-03;790.82;795.31;785.66;795.31;437220000;795.31
1997-02-28;795.07;795.70;788.50;790.82;508280000;790.82
1997-02-27;805.68;805.68;795.06;795.07;464660000;795.07
1997-02-26;812.10;812.70;798.13;805.68;573920000;805.68
1997-02-25;810.28;812.85;807.65;812.03;527450000;812.03
1997-02-24;801.77;810.64;798.42;810.28;462450000;810.28
1997-02-21;802.80;804.94;799.99;801.77;478450000;801.77
1997-02-20;812.49;812.49;800.35;802.80;492220000;802.80
1997-02-19;816.29;817.68;811.20;812.49;519350000;812.49
1997-02-18;808.48;816.29;806.34;816.29;474110000;816.29
1997-02-14;811.82;812.20;808.15;808.48;491540000;808.48
1997-02-13;802.77;812.93;802.77;811.82;593710000;811.82
1997-02-12;789.59;802.77;789.59;802.77;563890000;802.77
1997-02-11;785.43;789.60;780.95;789.59;483090000;789.59
1997-02-10;789.56;793.46;784.69;785.43;471590000;785.43
1997-02-07;780.15;789.72;778.19;789.56;540910000;789.56
1997-02-06;778.28;780.35;774.45;780.15;519660000;780.15
1997-02-05;789.26;792.71;773.43;778.28;580520000;778.28
1997-02-04;786.73;789.28;783.68;789.26;506530000;789.26
1997-02-03;786.16;787.14;783.12;786.73;463600000;786.73
1997-01-31;784.17;791.86;784.17;786.16;578550000;786.16
1997-01-30;772.50;784.17;772.50;784.17;524160000;784.17
1997-01-29;765.02;772.70;765.02;772.50;498390000;772.50
1997-01-28;765.02;776.32;761.75;765.02;541580000;765.02
1997-01-27;770.52;771.43;764.18;765.02;445760000;765.02
1997-01-24;777.56;778.21;768.17;770.52;542920000;770.52
1997-01-23;786.23;794.67;776.64;777.56;685070000;777.56
1997-01-22;782.72;786.23;779.56;786.23;589230000;786.23
1997-01-21;776.70;783.72;772.00;782.72;571280000;782.72
1997-01-20;776.17;780.08;774.19;776.70;440470000;776.70
1997-01-17;769.75;776.37;769.72;776.17;534640000;776.17
1997-01-16;767.20;772.05;765.25;769.75;537290000;769.75
1997-01-15;768.86;770.95;763.72;767.20;524990000;767.20
1997-01-14;759.51;772.04;759.51;768.86;531600000;768.86
1997-01-13;759.50;762.85;756.69;759.51;445400000;759.51
1997-01-10;754.85;759.65;746.92;759.50;545850000;759.50
1997-01-09;748.41;757.68;748.41;754.85;555370000;754.85
1997-01-08;753.23;755.72;747.71;748.41;557510000;748.41
1997-01-07;747.65;753.26;742.18;753.23;538220000;753.23
1997-01-06;748.03;753.31;743.82;747.65;531350000;747.65
1997-01-03;737.01;748.24;737.01;748.03;452970000;748.03
1997-01-02;740.74;742.81;729.55;737.01;463230000;737.01
1996-12-31;753.85;753.95;740.74;740.74;399760000;740.74
1996-12-30;756.79;759.20;752.73;753.85;339060000;753.85
1996-12-27;755.82;758.75;754.82;756.79;253810000;756.79
1996-12-26;751.03;757.07;751.02;755.82;254630000;755.82
1996-12-24;746.92;751.03;746.92;751.03;165140000;751.03
1996-12-23;748.87;750.40;743.28;746.92;343280000;746.92
1996-12-20;745.76;755.41;745.76;748.87;654340000;748.87
1996-12-19;731.54;746.06;731.54;745.76;526410000;745.76
1996-12-18;726.04;732.76;726.04;731.54;500490000;731.54
1996-12-17;720.98;727.67;716.69;726.04;519840000;726.04
1996-12-16;728.64;732.68;719.40;720.98;447560000;720.98
1996-12-13;729.33;731.40;721.97;728.64;458540000;728.64
1996-12-12;740.73;744.86;729.30;729.30;492920000;729.30
1996-12-11;747.54;747.54;732.75;740.73;494210000;740.73
1996-12-10;749.76;753.43;747.02;747.54;446120000;747.54
1996-12-09;739.60;749.76;739.60;749.76;381570000;749.76
1996-12-06;744.38;744.38;726.89;739.60;500860000;739.60
1996-12-05;745.10;747.65;742.61;744.38;483710000;744.38
1996-12-04;748.28;748.40;738.46;745.10;498240000;745.10
1996-12-03;756.56;761.75;747.58;748.28;516160000;748.28
1996-12-02;757.02;757.03;751.49;756.56;412520000;756.56
1996-11-29;755.00;758.27;755.00;757.02;14990000;757.02
1996-11-27;755.96;757.30;753.18;755.00;377780000;755.00
1996-11-26;757.03;762.12;752.83;755.96;527380000;755.96
1996-11-25;748.73;757.05;747.99;757.03;475260000;757.03
1996-11-22;742.75;748.73;742.75;748.73;525210000;748.73
1996-11-21;743.95;745.20;741.08;742.75;464430000;742.75
1996-11-20;742.16;746.99;740.40;743.95;497900000;743.95
1996-11-19;737.02;742.18;736.87;742.16;461980000;742.16
1996-11-18;737.62;739.24;734.39;737.02;388520000;737.02
1996-11-15;735.88;741.92;735.15;737.62;529100000;737.62
1996-11-14;731.13;735.99;729.20;735.88;480350000;735.88
1996-11-13;729.56;732.11;728.03;731.13;429840000;731.13
1996-11-12;731.87;733.04;728.20;729.56;471740000;729.56
1996-11-11;730.82;732.60;729.94;731.87;353960000;731.87
1996-11-08;727.65;730.82;725.22;730.82;402320000;730.82
1996-11-07;724.59;729.49;722.23;727.65;502530000;727.65
1996-11-06;714.14;724.60;712.83;724.59;509600000;724.59
1996-11-05;706.73;714.56;706.73;714.14;486660000;714.14
1996-11-04;703.77;707.02;702.84;706.73;398790000;706.73
1996-11-01;705.27;708.60;701.30;703.77;465510000;703.77
1996-10-31;700.90;706.61;700.35;705.27;482840000;705.27
1996-10-30;701.50;703.44;700.05;700.90;437770000;700.90
1996-10-29;697.26;703.25;696.22;701.50;443890000;701.50
1996-10-28;700.92;705.40;697.25;697.26;383620000;697.26
1996-10-25;702.29;704.11;700.53;700.92;367640000;700.92
1996-10-24;707.27;708.25;702.11;702.29;418970000;702.29
1996-10-23;706.57;707.31;700.98;707.27;442170000;707.27
1996-10-22;709.85;709.85;704.55;706.57;410790000;706.57
1996-10-21;710.82;714.10;707.71;709.85;414630000;709.85
1996-10-18;706.99;711.04;706.11;710.82;473020000;710.82
1996-10-17;705.00;708.52;704.76;706.99;478550000;706.99
1996-10-16;702.57;704.42;699.15;704.41;441410000;704.41
1996-10-15;703.54;708.07;699.07;702.57;458980000;702.57
1996-10-14;700.66;705.16;700.66;703.54;322000000;703.54
1996-10-11;694.61;700.67;694.61;700.66;396050000;700.66
1996-10-10;696.74;696.82;693.34;694.61;394950000;694.61
1996-10-09;700.64;702.36;694.42;696.74;408450000;696.74
1996-10-08;703.34;705.76;699.88;700.64;435070000;700.64
1996-10-07;701.46;704.17;701.39;703.34;380750000;703.34
1996-10-04;692.78;701.74;692.78;701.46;463940000;701.46
1996-10-03;694.01;694.81;691.78;692.78;386500000;692.78
1996-10-02;689.08;694.82;689.08;694.01;440130000;694.01
1996-10-01;687.31;689.54;684.44;689.08;421550000;689.08
1996-09-30;686.19;690.11;686.03;687.33;388570000;687.33
1996-09-27;685.86;687.11;683.73;686.19;414760000;686.19
1996-09-26;685.83;690.15;683.77;685.86;500870000;685.86
1996-09-25;685.61;688.26;684.92;685.83;451710000;685.83
1996-09-24;686.48;690.88;683.54;685.61;460150000;685.61
1996-09-23;687.03;687.03;681.01;686.48;297760000;686.48
1996-09-20;683.00;687.07;683.00;687.03;519420000;687.03
1996-09-19;681.47;684.07;679.06;683.00;398580000;683.00
1996-09-18;682.94;683.77;679.75;681.47;396600000;681.47
1996-09-17;683.98;685.80;679.96;682.94;449850000;682.94
1996-09-16;680.54;686.48;680.53;683.98;430080000;683.98
1996-09-13;671.15;681.39;671.15;680.54;488360000;680.54
1996-09-12;667.28;673.07;667.28;671.15;398820000;671.15
1996-09-11;663.81;667.73;661.79;667.28;376880000;667.28
1996-09-10;663.76;665.57;661.55;663.81;372960000;663.81
1996-09-09;655.68;663.77;655.68;663.76;311530000;663.76
1996-09-06;649.44;658.21;649.44;655.68;348710000;655.68
1996-09-05;655.61;655.61;648.89;649.44;361430000;649.44
1996-09-04;654.72;655.82;652.93;655.61;351290000;655.61
1996-09-03;651.99;655.13;643.97;654.72;345740000;654.72
1996-08-30;657.40;657.71;650.52;651.99;258380000;651.99
1996-08-29;664.81;664.81;655.35;657.40;321120000;657.40
1996-08-28;666.40;667.41;664.39;664.81;296440000;664.81
1996-08-27;663.88;666.40;663.50;666.40;310520000;666.40
1996-08-26;667.03;667.03;662.36;663.88;281430000;663.88
1996-08-23;670.68;670.68;664.93;667.03;308010000;667.03
1996-08-22;665.07;670.68;664.88;670.68;354950000;670.68
1996-08-21;665.69;665.69;662.16;665.07;348820000;665.07
1996-08-20;666.58;666.99;665.15;665.69;334960000;665.69
1996-08-19;665.21;667.12;665.00;666.58;294080000;666.58
1996-08-16;662.28;666.34;662.26;665.21;337650000;665.21
1996-08-15;662.05;664.18;660.64;662.28;323950000;662.28
1996-08-14;660.20;662.42;658.47;662.05;343460000;662.05
1996-08-13;665.77;665.77;659.13;660.20;362470000;660.20
1996-08-12;662.10;665.77;658.95;665.77;312170000;665.77
1996-08-09;662.59;665.37;660.31;662.10;327280000;662.10
1996-08-08;664.16;664.17;661.28;662.59;334570000;662.59
1996-08-07;662.38;664.61;660.00;664.16;394340000;664.16
1996-08-06;660.23;662.75;656.83;662.38;347290000;662.38
1996-08-05;662.49;663.64;659.03;660.23;307240000;660.23
1996-08-02;650.02;662.49;650.02;662.49;442080000;662.49
1996-08-01;639.95;650.66;639.49;650.02;439110000;650.02
1996-07-31;635.26;640.54;633.74;639.95;403560000;639.95
1996-07-30;630.91;635.26;629.22;635.26;341090000;635.26
1996-07-29;635.90;635.90;630.90;630.91;281560000;630.91
1996-07-26;631.17;636.23;631.17;635.90;349900000;635.90
1996-07-25;626.65;633.57;626.65;631.17;405390000;631.17
1996-07-24;626.19;629.10;616.43;626.65;463030000;626.65
1996-07-23;633.79;637.70;625.65;626.87;421900000;626.87
1996-07-22;638.73;638.73;630.38;633.77;327300000;633.77
1996-07-19;643.51;643.51;635.50;638.73;408070000;638.73
1996-07-18;634.07;644.44;633.29;643.56;474460000;643.56
1996-07-17;628.37;636.61;628.37;634.07;513830000;634.07
1996-07-16;629.80;631.99;605.88;628.37;682980000;628.37
1996-07-15;646.19;646.19;629.69;629.80;419020000;629.80
1996-07-12;645.67;647.64;640.21;646.19;396740000;646.19
1996-07-11;656.06;656.06;639.52;645.67;520470000;645.67
1996-07-10;654.75;656.27;648.39;656.06;421350000;656.06
1996-07-09;652.54;656.60;652.54;654.75;400170000;654.75
1996-07-08;657.44;657.65;651.13;652.54;367560000;652.54
1996-07-05;672.40;672.40;657.41;657.44;181470000;657.44
1996-07-03;673.61;673.64;670.21;672.40;336260000;672.40
1996-07-02;675.88;675.88;672.55;673.61;388000000;673.61
1996-07-01;670.63;675.88;670.63;675.88;345750000;675.88
1996-06-28;668.55;672.68;668.55;670.63;470460000;670.63
1996-06-27;664.39;668.90;661.56;668.55;405580000;668.55
1996-06-26;668.48;668.49;663.67;664.39;386520000;664.39
1996-06-25;668.85;670.65;667.29;668.48;391900000;668.48
1996-06-24;666.84;671.07;666.84;668.85;333840000;668.85
1996-06-21;662.10;666.84;662.10;666.84;520340000;666.84
1996-06-20;661.96;664.96;658.75;662.10;441060000;662.10
1996-06-19;662.06;665.62;661.21;661.96;383610000;661.96
1996-06-18;665.16;666.36;661.34;662.06;373290000;662.06
1996-06-17;665.85;668.27;664.09;665.16;298410000;665.16
1996-06-14;667.92;668.40;664.35;665.85;390630000;665.85
1996-06-13;669.04;670.54;665.49;667.92;397620000;667.92
1996-06-12;670.97;673.67;668.77;669.04;397190000;669.04
1996-06-11;672.16;676.72;669.94;670.97;405390000;670.97
1996-06-10;673.31;673.61;670.15;672.16;337480000;672.16
1996-06-07;673.03;673.31;662.48;673.31;445710000;673.31
1996-06-06;678.44;680.32;673.02;673.03;466940000;673.03
1996-06-05;672.56;678.45;672.09;678.44;380360000;678.44
1996-06-04;667.68;672.60;667.68;672.56;386040000;672.56
1996-06-03;669.12;669.12;665.19;667.68;318470000;667.68
1996-05-31;671.70;673.46;667.00;669.12;351750000;669.12
1996-05-30;667.93;673.51;664.56;671.70;381960000;671.70
1996-05-29;672.23;673.73;666.09;667.93;346730000;667.93
1996-05-28;678.51;679.98;671.52;672.23;341480000;672.23
1996-05-24;676.00;679.72;676.00;678.51;329150000;678.51
1996-05-23;678.42;681.10;673.45;676.00;431850000;676.00
1996-05-22;672.76;678.42;671.23;678.42;423670000;678.42
1996-05-21;673.15;675.56;672.26;672.76;409610000;672.76
1996-05-20;668.91;673.66;667.64;673.15;385000000;673.15
1996-05-17;664.85;669.84;664.85;668.91;429140000;668.91
1996-05-16;665.42;667.11;662.79;664.85;392070000;664.85
1996-05-15;665.60;669.82;664.46;665.42;447790000;665.42
1996-05-14;661.51;666.96;661.51;665.60;460440000;665.60
1996-05-13;652.09;662.16;652.09;661.51;394180000;661.51
1996-05-10;645.44;653.00;645.44;652.09;428370000;652.09
1996-05-09;644.77;647.95;643.18;645.44;404310000;645.44
1996-05-08;638.26;644.79;630.07;644.77;495460000;644.77
1996-05-07;640.81;641.40;636.96;638.26;410770000;638.26
1996-05-06;641.63;644.64;636.19;640.81;375820000;640.81
1996-05-03;643.38;648.45;640.23;641.63;434010000;641.63
1996-05-02;654.58;654.58;642.13;643.38;442960000;643.38
1996-05-01;654.17;656.44;652.26;654.58;404620000;654.58
1996-04-30;654.16;654.59;651.05;654.17;393390000;654.17
1996-04-29;653.46;654.71;651.60;654.16;344030000;654.16
1996-04-26;652.87;656.43;651.96;653.46;402530000;653.46
1996-04-25;650.17;654.18;647.06;652.87;462120000;652.87
1996-04-24;651.58;653.37;648.25;650.17;494220000;650.17
1996-04-23;647.89;651.59;647.70;651.58;452690000;651.58
1996-04-22;645.07;650.91;645.07;647.89;395370000;647.89
1996-04-19;643.61;647.32;643.61;645.07;435690000;645.07
1996-04-18;641.61;644.66;640.76;643.61;415150000;643.61
1996-04-17;645.00;645.00;638.71;641.61;465200000;641.61
1996-04-16;642.49;645.57;642.15;645.00;453310000;645.00
1996-04-15;636.71;642.49;636.71;642.49;346370000;642.49
1996-04-12;631.18;637.14;631.18;636.71;413270000;636.71
1996-04-11;633.50;635.26;624.14;631.18;519710000;631.18
1996-04-10;642.19;642.78;631.76;633.50;475150000;633.50
1996-04-09;644.24;646.33;640.84;642.19;426790000;642.19
1996-04-08;655.86;655.86;638.04;644.24;411810000;644.24
1996-04-04;655.88;656.68;654.89;655.86;383400000;655.86
1996-04-03;655.26;655.89;651.81;655.88;386620000;655.88
1996-04-02;653.73;655.27;652.81;655.26;406640000;655.26
1996-04-01;645.50;653.87;645.50;653.73;392120000;653.73
1996-03-29;648.94;650.96;644.89;645.50;413510000;645.50
1996-03-28;648.91;649.58;646.36;648.94;370750000;648.94
1996-03-27;652.97;653.94;647.60;648.91;406280000;648.91
1996-03-26;650.04;654.31;648.15;652.97;400090000;652.97
1996-03-25;650.62;655.50;648.82;650.04;336700000;650.04
1996-03-22;649.19;652.08;649.19;650.62;329390000;650.62
1996-03-21;649.98;651.54;648.10;649.19;367180000;649.19
1996-03-20;651.69;653.13;645.57;649.98;409780000;649.98
1996-03-19;652.65;656.18;649.80;651.69;438300000;651.69
1996-03-18;641.43;652.65;641.43;652.65;437100000;652.65
1996-03-15;640.87;642.87;638.35;641.43;529970000;641.43
1996-03-14;638.55;644.17;638.55;640.87;492630000;640.87
1996-03-13;637.09;640.52;635.19;638.55;413030000;638.55
1996-03-12;640.02;640.02;628.82;637.09;454980000;637.09
1996-03-11;633.50;640.41;629.95;640.02;449500000;640.02
1996-03-08;653.65;653.65;627.63;633.50;546550000;633.50
1996-03-07;652.00;653.65;649.54;653.65;425790000;653.65
1996-03-06;655.79;656.97;651.61;652.00;428220000;652.00
1996-03-05;650.81;655.80;648.77;655.79;445700000;655.79
1996-03-04;644.37;653.54;644.37;650.81;417270000;650.81
1996-03-01;640.43;644.38;635.00;644.37;471480000;644.37
1996-02-29;644.75;646.95;639.01;640.43;453170000;640.43
1996-02-28;647.24;654.39;643.99;644.75;447790000;644.75
1996-02-27;650.46;650.62;643.87;647.24;431340000;647.24
1996-02-26;659.08;659.08;650.16;650.46;399330000;650.46
1996-02-23;658.86;663.00;652.25;659.08;443130000;659.08
1996-02-22;648.10;659.75;648.10;658.86;485470000;658.86
1996-02-21;640.65;648.11;640.65;648.10;431220000;648.10
1996-02-20;647.98;647.98;638.79;640.65;395910000;640.65
1996-02-16;651.32;651.42;646.99;647.98;445570000;647.98
1996-02-15;655.58;656.84;651.15;651.32;415320000;651.32
1996-02-14;660.51;661.53;654.36;655.58;421790000;655.58
1996-02-13;661.45;664.23;657.92;660.51;441540000;660.51
1996-02-12;656.37;662.95;656.34;661.45;397890000;661.45
1996-02-09;656.07;661.08;653.64;656.37;477640000;656.37
1996-02-08;649.93;656.54;647.93;656.07;474970000;656.07
1996-02-07;646.33;649.93;645.59;649.93;462730000;649.93
1996-02-06;641.43;646.67;639.68;646.33;465940000;646.33
1996-02-05;635.84;641.43;633.71;641.43;377760000;641.43
1996-02-02;638.46;639.26;634.29;635.84;420020000;635.84
1996-02-01;636.02;638.46;634.54;638.46;461430000;638.46
1996-01-31;630.15;636.18;629.48;636.02;472210000;636.02
1996-01-30;624.22;630.29;624.22;630.15;464350000;630.15
1996-01-29;621.62;624.22;621.42;624.22;363330000;624.22
1996-01-26;617.03;621.70;615.26;621.62;385700000;621.62
1996-01-25;619.96;620.15;616.62;617.03;453270000;617.03
1996-01-24;612.79;619.96;612.79;619.96;476380000;619.96
1996-01-23;613.40;613.40;610.65;612.79;416910000;612.79
1996-01-22;611.83;613.45;610.95;613.40;398040000;613.40
1996-01-19;608.24;612.92;606.76;611.83;497720000;611.83
1996-01-18;606.37;608.27;604.12;608.24;450410000;608.24
1996-01-17;608.44;609.93;604.70;606.37;458720000;606.37
1996-01-16;599.82;608.44;599.05;608.44;425220000;608.44
1996-01-15;601.81;603.43;598.47;599.82;306180000;599.82
1996-01-12;602.69;604.80;597.46;601.81;383400000;601.81
1996-01-11;598.48;602.71;597.54;602.69;408800000;602.69
1996-01-10;609.45;609.45;597.29;598.48;496830000;598.48
1996-01-09;618.46;619.15;608.21;609.45;417400000;609.45
1996-01-08;616.71;618.46;616.49;618.46;130360000;618.46
1996-01-05;617.70;617.70;612.02;616.71;437110000;616.71
1996-01-04;621.32;624.49;613.96;617.70;512580000;617.70
1996-01-03;620.73;623.25;619.56;621.32;468950000;621.32
1996-01-02;615.93;620.74;613.17;620.73;364180000;620.73
1995-12-29;614.12;615.93;612.36;615.93;321250000;615.93
1995-12-28;614.53;615.50;612.40;614.12;288660000;614.12
1995-12-27;614.30;615.73;613.75;614.53;252300000;614.53
1995-12-26;611.96;614.50;611.96;614.30;217280000;614.30
1995-12-22;610.49;613.50;610.45;611.95;289600000;611.95
1995-12-21;605.94;610.52;605.94;610.49;415810000;610.49
1995-12-20;611.93;614.27;605.93;605.94;437680000;605.94
1995-12-19;606.81;611.94;605.05;611.93;478280000;611.93
1995-12-18;616.34;616.34;606.13;606.81;426270000;606.81
1995-12-15;616.92;617.72;614.46;616.34;636800000;616.34
1995-12-14;621.69;622.88;616.13;616.92;465300000;616.92
1995-12-13;618.78;622.02;618.27;621.69;415290000;621.69
1995-12-12;619.52;619.55;617.68;618.78;349860000;618.78
1995-12-11;617.48;620.90;617.14;619.52;342070000;619.52
1995-12-08;616.17;617.82;614.32;617.48;327900000;617.48
1995-12-07;620.18;620.19;615.21;616.17;379260000;616.17
1995-12-06;617.68;621.11;616.69;620.18;417780000;620.18
1995-12-05;613.68;618.48;613.14;617.68;437360000;617.68
1995-12-04;606.98;613.83;606.84;613.68;405480000;613.68
1995-12-01;605.37;608.11;605.37;606.98;393310000;606.98
1995-11-30;607.64;608.69;605.37;605.37;440050000;605.37
1995-11-29;606.45;607.66;605.47;607.64;398280000;607.64
1995-11-28;601.32;606.45;599.02;606.45;408860000;606.45
1995-11-27;599.97;603.35;599.97;601.32;359130000;601.32
1995-11-24;598.40;600.24;598.40;599.97;125870000;599.97
1995-11-22;600.24;600.71;598.40;598.40;404980000;598.40
1995-11-21;596.85;600.28;595.42;600.24;408320000;600.24
1995-11-20;600.07;600.40;596.17;596.85;333150000;596.85
1995-11-17;597.34;600.14;597.30;600.07;437200000;600.07
1995-11-16;593.96;597.91;593.52;597.34;423280000;597.34
1995-11-15;589.29;593.97;588.36;593.96;376100000;593.96
1995-11-14;592.30;592.30;588.98;589.29;354420000;589.29
1995-11-13;592.72;593.72;590.58;592.30;295840000;592.30
1995-11-10;593.26;593.26;590.39;592.72;298690000;592.72
1995-11-09;591.71;593.90;590.89;593.26;380760000;593.26
1995-11-08;586.32;591.71;586.32;591.71;359780000;591.71
1995-11-07;588.46;588.46;584.24;586.32;364680000;586.32
1995-11-06;590.57;590.64;588.31;588.46;309100000;588.46
1995-11-03;589.72;590.57;588.65;590.57;348500000;590.57
1995-11-02;584.22;589.72;584.22;589.72;397070000;589.72
1995-11-01;581.50;584.24;581.04;584.22;378090000;584.22
1995-10-31;583.25;586.71;581.50;581.50;377390000;581.50
1995-10-30;579.70;583.79;579.70;583.25;319160000;583.25
1995-10-27;576.72;579.71;573.21;579.70;379230000;579.70
1995-10-26;582.47;582.63;572.53;576.72;464270000;576.72
1995-10-25;586.54;587.19;581.41;582.47;433620000;582.47
1995-10-24;585.06;587.31;584.75;586.54;415540000;586.54
1995-10-23;587.46;587.46;583.73;585.06;330750000;585.06
1995-10-20;590.65;590.66;586.78;587.46;389360000;587.46
1995-10-19;587.44;590.66;586.34;590.65;406620000;590.65
1995-10-18;586.78;589.77;586.27;587.44;411270000;587.44
1995-10-17;583.03;586.78;581.90;586.78;356380000;586.78
1995-10-16;584.50;584.86;582.63;583.03;300750000;583.03
1995-10-13;583.10;587.39;583.10;584.50;374680000;584.50
1995-10-12;579.46;583.12;579.46;583.10;344060000;583.10
1995-10-11;577.52;579.52;577.08;579.46;340740000;579.46
1995-10-10;578.37;578.37;571.55;577.52;412710000;577.52
1995-10-09;582.49;582.49;576.35;578.37;275320000;578.37
1995-10-06;582.63;584.54;582.10;582.49;313680000;582.49
1995-10-05;581.47;582.63;579.58;582.63;367480000;582.63
1995-10-04;582.34;582.34;579.91;581.47;339380000;581.47
1995-10-03;581.72;582.34;578.48;582.34;385940000;582.34
1995-10-02;584.41;585.05;580.54;581.72;304990000;581.72
1995-09-29;585.87;587.61;584.00;584.41;335250000;584.41
1995-09-28;581.04;585.88;580.69;585.87;367720000;585.87
1995-09-27;581.41;581.42;574.68;581.04;411300000;581.04
1995-09-26;581.81;584.66;580.65;581.41;363630000;581.41
1995-09-25;581.73;582.14;579.50;581.81;273120000;581.81
1995-09-22;583.00;583.00;578.25;581.73;370790000;581.73
1995-09-21;586.77;586.79;580.91;583.00;367100000;583.00
1995-09-20;584.20;586.77;584.18;586.77;400050000;586.77
1995-09-19;582.78;584.24;580.75;584.20;371170000;584.20
1995-09-18;583.35;583.37;579.36;582.77;326090000;582.77
1995-09-15;583.61;585.07;581.79;583.35;459370000;583.35
1995-09-14;578.77;583.99;578.77;583.61;382880000;583.61
1995-09-13;576.51;579.72;575.47;578.77;384380000;578.77
1995-09-12;573.91;576.51;573.11;576.51;344540000;576.51
1995-09-11;572.68;575.15;572.68;573.91;296840000;573.91
1995-09-08;570.29;572.68;569.27;572.68;317940000;572.68
1995-09-07;570.17;571.11;569.23;570.29;321720000;570.29
1995-09-06;569.17;570.53;569.00;570.17;369540000;570.17
1995-09-05;563.86;569.20;563.84;569.17;332670000;569.17
1995-09-01;561.88;564.62;561.01;563.84;256730000;563.84
1995-08-31;561.09;562.36;560.49;561.88;300920000;561.88
1995-08-30;560.00;561.52;559.49;560.92;329840000;560.92
1995-08-29;559.05;560.01;555.71;560.00;311290000;560.00
1995-08-28;560.10;562.22;557.99;559.05;267860000;559.05
1995-08-25;557.46;561.31;557.46;560.10;255990000;560.10
1995-08-24;557.14;558.63;555.20;557.46;299200000;557.46
1995-08-23;559.52;560.00;557.08;557.14;291890000;557.14
1995-08-22;558.11;559.52;555.87;559.52;290890000;559.52
1995-08-21;559.21;563.34;557.89;558.11;303200000;558.11
1995-08-18;559.04;561.24;558.34;559.21;320490000;559.21
1995-08-17;559.97;559.97;557.42;559.04;354460000;559.04
1995-08-16;558.57;559.98;557.37;559.97;390170000;559.97
1995-08-15;559.74;559.98;555.22;558.57;330070000;558.57
1995-08-14;555.11;559.74;554.76;559.74;264920000;559.74
1995-08-11;557.45;558.50;553.04;555.11;267850000;555.11
1995-08-10;559.71;560.63;556.05;557.45;306660000;557.45
1995-08-09;560.39;561.59;559.29;559.71;303390000;559.71
1995-08-08;560.03;561.53;558.32;560.39;306090000;560.39
1995-08-07;558.94;561.24;558.94;560.03;277050000;560.03
1995-08-04;558.75;559.57;557.91;558.94;314740000;558.94
1995-08-03;558.80;558.80;554.10;558.75;353110000;558.75
1995-08-02;559.64;565.62;557.87;558.80;374330000;558.80
1995-08-01;562.06;562.11;556.67;559.64;332210000;559.64
1995-07-31;562.93;563.49;560.06;562.06;291950000;562.06
1995-07-28;565.22;565.40;562.04;562.93;311590000;562.93
1995-07-27;561.61;565.33;561.61;565.22;356570000;565.22
1995-07-26;561.10;563.78;560.85;561.61;393470000;561.61
1995-07-25;556.63;561.75;556.34;561.10;373200000;561.10
1995-07-24;553.62;557.21;553.62;556.63;315300000;556.63
1995-07-21;553.34;554.73;550.91;553.62;431830000;553.62
1995-07-20;550.98;554.43;549.10;553.54;383380000;553.54
1995-07-19;556.58;558.46;542.51;550.98;489850000;550.98
1995-07-18;562.55;562.72;556.86;558.46;372230000;558.46
1995-07-17;560.34;562.94;559.45;562.72;322540000;562.72
1995-07-14;561.00;561.00;556.41;559.89;312930000;559.89
1995-07-13;560.89;562.00;559.07;561.00;387500000;561.00
1995-07-12;555.27;561.56;554.27;560.89;416360000;560.89
1995-07-11;556.78;557.19;553.80;554.78;376770000;554.78
1995-07-10;556.37;558.48;555.77;557.19;409700000;557.19
1995-07-07;553.90;556.57;553.05;556.37;466540000;556.37
1995-07-06;547.26;553.99;546.59;553.99;420500000;553.99
1995-07-05;547.09;549.98;546.28;547.26;357850000;547.26
1995-07-03;544.75;547.10;544.43;547.09;117900000;547.09
1995-06-30;543.87;546.82;543.51;544.75;311650000;544.75
1995-06-29;544.73;546.25;540.79;543.87;313080000;543.87
1995-06-28;542.43;546.33;540.72;544.73;368060000;544.73
1995-06-27;544.11;547.07;542.19;542.43;346950000;542.43
1995-06-26;549.71;549.79;544.06;544.13;296720000;544.13
1995-06-23;551.07;551.07;548.23;549.71;321660000;549.71
1995-06-22;543.98;551.07;543.98;551.07;421000000;551.07
1995-06-21;544.98;545.93;543.90;543.98;398210000;543.98
1995-06-20;545.22;545.44;543.43;544.98;382370000;544.98
1995-06-19;539.83;545.22;539.83;545.22;322990000;545.22
1995-06-16;537.51;539.98;537.12;539.83;442740000;539.83
1995-06-15;536.48;539.07;535.56;537.12;334700000;537.12
1995-06-14;536.05;536.48;533.83;536.47;330770000;536.47
1995-06-13;530.88;536.23;530.88;536.05;339660000;536.05
1995-06-12;527.94;532.54;527.94;530.88;289920000;530.88
1995-06-09;532.35;532.35;526.00;527.94;327570000;527.94
1995-06-08;533.13;533.56;531.65;532.35;289880000;532.35
1995-06-07;535.55;535.55;531.66;533.13;327790000;533.13
1995-06-06;535.60;537.09;535.14;535.55;340490000;535.55
1995-06-05;532.51;537.73;532.47;535.60;337520000;535.60
1995-06-02;533.49;536.91;529.55;532.51;366000000;532.51
1995-06-01;533.40;534.21;530.05;533.49;345920000;533.49
1995-05-31;523.70;533.41;522.17;533.40;358180000;533.40
1995-05-30;523.65;525.58;521.38;523.58;283020000;523.58
1995-05-26;528.59;528.59;522.51;523.65;291220000;523.65
1995-05-25;528.37;529.04;524.89;528.59;341820000;528.59
1995-05-24;528.59;531.91;525.57;528.61;391770000;528.61
1995-05-23;523.65;528.59;523.65;528.59;362690000;528.59
1995-05-22;519.19;524.34;519.19;523.65;285600000;523.65
1995-05-19;519.58;519.58;517.07;519.19;354010000;519.19
1995-05-18;526.88;526.88;519.58;519.58;351900000;519.58
1995-05-17;528.19;528.42;525.38;527.07;347930000;527.07
1995-05-16;527.74;529.08;526.45;528.19;366180000;528.19
1995-05-15;525.55;527.74;525.00;527.74;316240000;527.74
1995-05-12;524.37;527.05;523.30;525.55;361000000;525.55
1995-05-11;524.33;524.89;522.70;524.37;339900000;524.37
1995-05-10;523.74;524.40;521.53;524.36;381990000;524.36
1995-05-09;523.96;525.99;521.79;523.56;361300000;523.56
1995-05-08;520.09;525.15;519.14;523.96;291810000;523.96
1995-05-05;520.75;522.35;518.28;520.12;342380000;520.12
1995-05-04;520.48;525.40;519.44;520.54;434990000;520.54
1995-05-03;514.93;520.54;514.86;520.48;392370000;520.48
1995-05-02;514.23;515.18;513.03;514.86;302560000;514.86
1995-05-01;514.76;515.60;513.42;514.26;296830000;514.26
1995-04-28;513.64;515.29;510.90;514.71;320440000;514.71
1995-04-27;512.70;513.62;511.63;513.55;350850000;513.55
1995-04-26;511.99;513.04;510.47;512.66;350810000;512.66
1995-04-25;512.80;513.54;511.32;512.10;351790000;512.10
1995-04-24;508.49;513.02;507.44;512.89;326280000;512.89
1995-04-21;505.63;508.49;505.63;508.49;403250000;508.49
1995-04-20;504.92;506.50;503.44;505.29;368450000;505.29
1995-04-19;505.37;505.89;501.19;504.92;378050000;504.92
1995-04-18;506.43;507.65;504.12;505.37;344680000;505.37
1995-04-17;509.23;512.03;505.43;506.13;333930000;506.13
1995-04-13;507.19;509.83;507.17;509.23;301580000;509.23
1995-04-12;505.59;507.17;505.07;507.17;327880000;507.17
1995-04-11;507.24;508.85;505.29;505.53;310660000;505.53
1995-04-10;506.30;507.01;504.61;507.01;260980000;507.01
1995-04-07;506.13;507.19;503.59;506.42;314760000;506.42
1995-04-06;505.63;507.10;505.00;506.08;320460000;506.08
1995-04-05;505.27;505.57;503.17;505.57;315170000;505.57
1995-04-04;501.85;505.26;501.85;505.24;330580000;505.24
1995-04-03;500.70;501.91;500.20;501.85;296430000;501.85
1995-03-31;501.94;502.22;495.70;500.71;353060000;500.71
1995-03-30;503.17;504.66;501.00;502.22;362940000;502.22
1995-03-29;503.92;508.15;500.96;503.12;385940000;503.12
1995-03-28;503.19;503.91;501.83;503.90;320360000;503.90
1995-03-27;500.97;503.20;500.93;503.20;296270000;503.20
1995-03-24;496.07;500.97;496.07;500.97;358370000;500.97
1995-03-23;495.67;496.77;494.19;495.95;318530000;495.95
1995-03-22;495.07;495.67;493.67;495.67;313120000;495.67
1995-03-21;496.15;499.19;494.04;495.07;367110000;495.07
1995-03-20;495.52;496.61;495.27;496.14;301740000;496.14
1995-03-17;495.43;496.67;494.95;495.52;417380000;495.52
1995-03-16;491.87;495.74;491.78;495.41;336670000;495.41
1995-03-15;492.89;492.89;490.83;491.88;309540000;491.88
1995-03-14;490.05;493.69;490.05;492.89;346160000;492.89
1995-03-13;489.57;491.28;489.35;490.05;275280000;490.05
1995-03-10;483.16;490.37;483.16;489.57;382940000;489.57
1995-03-09;483.14;483.74;482.05;483.16;319320000;483.16
1995-03-08;482.12;484.08;481.57;483.14;349780000;483.14
1995-03-07;485.63;485.63;479.70;482.12;355550000;482.12
1995-03-06;485.42;485.70;481.52;485.63;298870000;485.63
1995-03-03;485.13;485.42;483.07;485.42;330840000;485.42
1995-03-02;485.65;485.71;483.19;485.13;330030000;485.13
1995-03-01;487.39;487.83;484.92;485.65;362600000;485.65
1995-02-28;483.81;487.44;483.77;487.39;317220000;487.39
1995-02-27;488.26;488.26;483.18;483.81;285790000;483.81
1995-02-24;486.82;488.28;485.70;488.11;302930000;488.11
1995-02-23;485.07;489.19;485.07;486.91;394280000;486.91
1995-02-22;482.74;486.15;482.45;485.07;339460000;485.07
1995-02-21;481.95;483.26;481.94;482.72;308090000;482.72
1995-02-17;485.15;485.22;481.97;481.97;347970000;481.97
1995-02-16;484.56;485.22;483.05;485.22;360990000;485.22
1995-02-15;482.55;485.54;481.77;484.54;378040000;484.54
1995-02-14;481.65;482.94;480.89;482.55;300720000;482.55
1995-02-13;481.46;482.86;481.07;481.65;256270000;481.65
1995-02-10;480.19;481.96;479.53;481.46;295600000;481.46
1995-02-09;481.19;482.00;479.91;480.19;325570000;480.19
1995-02-08;480.81;482.60;480.40;481.19;318430000;481.19
1995-02-07;481.14;481.32;479.69;480.81;314660000;480.81
1995-02-06;478.64;481.95;478.36;481.14;325660000;481.14
1995-02-03;472.78;479.91;472.78;478.65;441000000;478.65
1995-02-02;470.40;472.79;469.95;472.79;322110000;472.79
1995-02-01;470.42;472.75;469.29;470.40;395310000;470.40
1995-01-31;468.51;471.03;468.18;470.42;411590000;470.42
1995-01-30;470.39;470.52;467.49;468.51;318550000;468.51
1995-01-27;468.32;471.36;468.32;470.39;339510000;470.39
1995-01-26;467.44;468.62;466.90;468.32;304730000;468.32
1995-01-25;465.86;469.51;464.40;467.44;342610000;467.44
1995-01-24;465.81;466.88;465.47;465.86;315430000;465.86
1995-01-23;464.78;466.23;461.14;465.82;325830000;465.82
1995-01-20;466.95;466.99;463.99;464.78;378190000;464.78
1995-01-19;469.72;469.72;466.40;466.95;297220000;466.95
1995-01-18;470.05;470.43;468.03;469.71;344660000;469.71
1995-01-17;469.38;470.15;468.19;470.05;331520000;470.05
1995-01-16;465.97;470.39;465.97;469.38;315810000;469.38
1995-01-13;461.64;466.43;461.64;465.97;336740000;465.97
1995-01-12;461.64;461.93;460.63;461.64;313040000;461.64
1995-01-11;461.68;463.61;458.65;461.66;346310000;461.66
1995-01-10;460.90;464.59;460.90;461.68;352450000;461.68
1995-01-09;460.67;461.77;459.74;460.83;278790000;460.83
1995-01-06;460.38;462.49;459.47;460.68;308070000;460.68
1995-01-05;460.73;461.30;459.75;460.34;309050000;460.34
1995-01-04;459.13;460.72;457.56;460.71;319510000;460.71
1995-01-03;459.21;459.27;457.20;459.11;262450000;459.11
1994-12-30;461.17;462.12;459.24;459.27;256260000;459.27
1994-12-29;460.92;461.81;460.36;461.17;250650000;461.17
1994-12-28;462.47;462.49;459.00;460.86;246260000;460.86
1994-12-27;459.85;462.73;459.85;462.47;211180000;462.47
1994-12-23;459.70;461.32;459.39;459.83;196540000;459.83
1994-12-22;459.62;461.21;459.33;459.68;340330000;459.68
1994-12-21;457.24;461.70;457.17;459.61;379130000;459.61
1994-12-20;458.08;458.45;456.37;457.10;326530000;457.10
1994-12-19;458.78;458.78;456.64;457.91;271850000;457.91
1994-12-16;455.35;458.80;455.35;458.80;481860000;458.80
1994-12-15;454.97;456.84;454.50;455.34;332790000;455.34
1994-12-14;450.05;456.16;450.05;454.97;355000000;454.97
1994-12-13;449.52;451.69;449.43;450.15;307110000;450.15
1994-12-12;446.95;449.48;445.62;449.47;285730000;449.47
1994-12-09;445.45;446.98;442.88;446.96;336440000;446.96
1994-12-08;451.23;452.06;444.59;445.45;362290000;445.45
1994-12-07;453.11;453.11;450.01;451.23;283490000;451.23
1994-12-06;453.29;453.93;450.35;453.11;298930000;453.11
1994-12-05;453.30;455.04;452.06;453.32;258490000;453.32
1994-12-02;448.92;453.31;448.00;453.30;284750000;453.30
1994-12-01;453.55;453.91;447.97;448.92;285920000;448.92
1994-11-30;455.17;457.13;453.27;453.69;298650000;453.69
1994-11-29;454.23;455.17;452.14;455.17;286620000;455.17
1994-11-28;452.26;454.19;451.04;454.16;265480000;454.16
1994-11-25;449.94;452.87;449.94;452.29;118290000;452.29
1994-11-23;450.01;450.61;444.18;449.93;430760000;449.93
1994-11-22;457.95;458.03;450.08;450.09;387270000;450.09
1994-11-21;461.69;463.41;457.55;458.30;293030000;458.30
1994-11-18;463.60;463.84;460.25;461.47;356730000;461.47
1994-11-17;465.71;465.83;461.47;463.57;323190000;463.57
1994-11-16;465.06;466.25;464.28;465.62;296980000;465.62
1994-11-15;466.04;468.51;462.95;465.03;336450000;465.03
1994-11-14;462.44;466.29;462.35;466.04;260380000;466.04
1994-11-11;464.17;464.17;461.45;462.35;220800000;462.35
1994-11-10;465.40;467.79;463.73;464.37;280910000;464.37
1994-11-09;465.65;469.95;463.46;465.40;337780000;465.40
1994-11-08;463.08;467.54;463.07;465.65;290860000;465.65
1994-11-07;462.31;463.56;461.25;463.07;255030000;463.07
1994-11-04;467.96;469.28;462.28;462.28;280560000;462.28
1994-11-03;466.50;468.64;466.40;467.91;285170000;467.91
1994-11-02;468.41;470.92;466.36;466.51;331360000;466.51
1994-11-01;472.26;472.26;467.64;468.42;314940000;468.42
1994-10-31;473.76;474.74;472.33;472.35;302820000;472.35
1994-10-28;465.84;473.78;465.80;473.77;381450000;473.77
1994-10-27;462.68;465.85;462.62;465.85;327790000;465.85
1994-10-26;461.55;463.77;461.22;462.62;322570000;462.62
1994-10-25;460.83;461.95;458.26;461.53;326110000;461.53
1994-10-24;464.89;466.37;460.80;460.83;282800000;460.83
1994-10-21;466.69;466.69;463.83;464.89;315310000;464.89
1994-10-20;470.37;470.37;465.39;466.85;331460000;466.85
1994-10-19;467.69;471.43;465.96;470.28;317030000;470.28
1994-10-18;469.02;469.19;466.54;467.66;259730000;467.66
1994-10-17;469.11;469.88;468.16;468.96;238490000;468.96
1994-10-14;467.78;469.53;466.11;469.10;251770000;469.10
1994-10-13;465.56;471.30;465.56;467.79;337900000;467.79
1994-10-12;465.78;466.70;464.79;465.47;269550000;465.47
1994-10-11;459.04;466.34;459.04;465.79;355540000;465.79
1994-10-10;455.12;459.29;455.12;459.04;213110000;459.04
1994-10-07;452.37;455.67;452.13;455.10;284230000;455.10
1994-10-06;453.52;454.49;452.13;452.36;272620000;452.36
1994-10-05;454.59;454.59;449.27;453.52;359670000;453.52
1994-10-04;461.77;462.46;454.03;454.59;325620000;454.59
1994-10-03;462.69;463.31;460.33;461.74;269130000;461.74
1994-09-30;462.27;465.30;461.91;462.71;291900000;462.71
1994-09-29;464.84;464.84;461.51;462.24;302280000;462.24
1994-09-28;462.10;465.55;462.10;464.84;330020000;464.84
1994-09-27;460.82;462.75;459.83;462.05;290330000;462.05
1994-09-26;459.65;460.87;459.31;460.82;272530000;460.82
1994-09-23;461.27;462.14;459.01;459.67;300060000;459.67
1994-09-22;461.45;463.22;460.96;461.27;305210000;461.27
1994-09-21;463.42;464.01;458.47;461.46;351830000;461.46
1994-09-20;470.83;470.83;463.36;463.36;326050000;463.36
1994-09-19;471.21;473.15;470.68;470.85;277110000;470.85
1994-09-16;474.81;474.81;470.06;471.19;410750000;471.19
1994-09-15;468.80;474.81;468.79;474.81;281920000;474.81
1994-09-14;467.55;468.86;466.82;468.80;297480000;468.80
1994-09-13;466.27;468.76;466.27;467.51;293370000;467.51
1994-09-12;468.18;468.42;466.15;466.21;244680000;466.21
1994-09-09;473.13;473.13;466.55;468.18;293360000;468.18
1994-09-08;470.96;473.40;470.86;473.14;295010000;473.14
1994-09-07;471.86;472.41;470.20;470.99;290330000;470.99
1994-09-06;471.00;471.92;469.64;471.86;199670000;471.86
1994-09-02;473.20;474.89;470.67;470.99;216150000;470.99
1994-09-01;475.49;475.49;471.74;473.17;282830000;473.17
1994-08-31;476.07;477.59;474.43;475.49;354650000;475.49
1994-08-30;474.59;476.61;473.56;476.07;294520000;476.07
1994-08-29;473.89;477.14;473.89;474.59;266080000;474.59
1994-08-26;468.08;474.65;468.08;473.80;305120000;473.80
1994-08-25;469.07;470.12;467.64;468.08;284230000;468.08
1994-08-24;464.51;469.05;464.51;469.03;310510000;469.03
1994-08-23;462.39;466.58;462.39;464.51;307240000;464.51
1994-08-22;463.61;463.61;461.46;462.32;235870000;462.32
1994-08-19;463.25;464.37;461.81;463.68;276630000;463.68
1994-08-18;465.10;465.10;462.30;463.17;287330000;463.17
1994-08-17;465.11;465.91;464.57;465.17;309250000;465.17
1994-08-16;461.22;465.20;459.89;465.01;306640000;465.01
1994-08-15;461.97;463.34;461.21;461.23;223210000;461.23
1994-08-12;458.88;462.27;458.88;461.94;249280000;461.94
1994-08-11;460.31;461.41;456.88;458.88;275690000;458.88
1994-08-10;457.98;460.48;457.98;460.30;279500000;460.30
1994-08-09;457.89;458.16;456.66;457.92;259140000;457.92
1994-08-08;457.08;458.30;457.01;457.89;217680000;457.89
1994-08-05;458.34;458.34;456.08;457.09;230270000;457.09
1994-08-04;461.45;461.49;458.40;458.40;289150000;458.40
1994-08-03;460.65;461.46;459.51;461.45;283840000;461.45
1994-08-02;461.01;462.77;459.70;460.56;294740000;460.56
1994-08-01;458.28;461.01;458.08;461.01;258180000;461.01
1994-07-29;454.25;459.33;454.25;458.26;269560000;458.26
1994-07-28;452.57;454.93;452.30;454.24;245990000;454.24
1994-07-27;453.36;453.38;451.36;452.57;251680000;452.57
1994-07-26;454.25;454.25;452.78;453.36;232670000;453.36
1994-07-25;453.10;454.32;452.76;454.25;213470000;454.25
1994-07-22;452.61;454.03;452.33;453.11;261600000;453.11
1994-07-21;451.60;453.22;451.00;452.61;292120000;452.61
1994-07-20;453.89;454.16;450.69;451.60;267840000;451.60
1994-07-19;455.22;455.30;453.86;453.86;251530000;453.86
1994-07-18;454.41;455.71;453.26;455.22;227460000;455.22
1994-07-15;453.28;454.33;452.80;454.16;275860000;454.16
1994-07-14;448.73;454.33;448.73;453.41;322330000;453.41
1994-07-13;448.03;450.06;447.97;448.73;265840000;448.73
1994-07-12;448.02;448.16;444.65;447.95;252250000;447.95
1994-07-11;449.56;450.24;445.27;448.06;222970000;448.06
1994-07-08;448.38;449.75;446.53;449.55;236520000;449.55
1994-07-07;446.15;448.64;446.15;448.38;259740000;448.38
1994-07-06;446.29;447.28;444.18;446.13;236230000;446.13
1994-07-05;446.20;447.62;445.14;446.37;195410000;446.37
1994-07-01;444.27;446.45;443.58;446.20;199030000;446.20
1994-06-30;447.63;448.61;443.66;444.27;293410000;444.27
1994-06-29;446.05;449.83;446.04;447.63;264430000;447.63
1994-06-28;447.36;448.47;443.08;446.07;267740000;446.07
1994-06-27;442.78;447.76;439.83;447.31;250080000;447.31
1994-06-24;449.63;449.63;442.51;442.80;261260000;442.80
1994-06-23;453.09;454.16;449.43;449.63;256480000;449.63
1994-06-22;451.40;453.91;451.40;453.09;251110000;453.09
1994-06-21;455.48;455.48;449.45;451.34;298730000;451.34
1994-06-20;458.45;458.45;454.46;455.48;229520000;455.48
1994-06-17;461.93;462.16;458.44;458.45;373450000;458.45
1994-06-16;460.61;461.93;459.80;461.93;256390000;461.93
1994-06-15;462.38;463.23;459.95;460.61;269740000;460.61
1994-06-14;459.10;462.52;459.10;462.37;288550000;462.37
1994-06-13;458.67;459.36;457.18;459.10;243640000;459.10
1994-06-10;457.86;459.48;457.36;458.67;222480000;458.67
1994-06-09;457.06;457.87;455.86;457.86;252870000;457.86
1994-06-08;458.21;459.74;455.43;457.06;256000000;457.06
1994-06-07;458.88;459.46;457.65;458.21;234680000;458.21
1994-06-06;460.13;461.87;458.85;458.88;259080000;458.88
1994-06-03;457.65;460.86;456.27;460.13;271490000;460.13
1994-06-02;457.62;458.50;457.26;457.65;271630000;457.65
1994-06-01;456.50;458.29;453.99;457.63;279910000;457.63
1994-05-31;457.32;457.61;455.16;456.50;216700000;456.50
1994-05-27;457.03;457.33;454.67;457.33;186430000;457.33
1994-05-26;456.33;457.77;455.79;457.06;255740000;457.06
1994-05-25;454.84;456.34;452.20;456.34;254420000;456.34
1994-05-24;453.21;456.77;453.21;454.81;280040000;454.81
1994-05-23;454.92;454.92;451.79;453.20;249420000;453.20
1994-05-20;456.48;456.48;454.22;454.92;295180000;454.92
1994-05-19;453.69;456.88;453.00;456.48;303680000;456.48
1994-05-18;449.39;454.45;448.87;453.69;337670000;453.69
1994-05-17;444.49;449.37;443.70;449.37;311280000;449.37
1994-05-16;444.15;445.82;443.62;444.49;234700000;444.49
1994-05-13;443.62;444.72;441.21;444.14;252070000;444.14
1994-05-12;441.50;444.80;441.50;443.75;272770000;443.75
1994-05-11;446.03;446.03;440.78;441.49;277400000;441.49
1994-05-10;442.37;446.84;442.37;446.01;297660000;446.01
1994-05-09;447.82;447.82;441.84;442.32;250870000;442.32
1994-05-06;451.37;451.37;445.64;447.82;291910000;447.82
1994-05-05;451.72;452.82;450.72;451.38;255690000;451.38
1994-05-04;453.04;453.11;449.87;451.72;267940000;451.72
1994-05-03;453.06;453.98;450.51;453.03;288270000;453.03
1994-05-02;450.91;453.57;449.05;453.02;296130000;453.02
1994-04-29;449.07;451.35;447.91;450.91;293970000;450.91
1994-04-28;451.84;452.23;447.97;449.10;325200000;449.10
1994-04-26;452.71;452.79;450.66;451.87;288120000;451.87
1994-04-25;447.64;452.71;447.58;452.71;262320000;452.71
1994-04-22;448.73;449.96;447.16;447.63;295710000;447.63
1994-04-21;441.96;449.14;441.96;448.73;378770000;448.73
1994-04-20;442.54;445.01;439.40;441.96;366540000;441.96
1994-04-19;442.54;444.82;438.83;442.54;323280000;442.54
1994-04-18;446.27;447.87;441.48;442.46;271470000;442.46
1994-04-15;446.38;447.85;445.81;446.18;309550000;446.18
1994-04-14;446.26;447.55;443.57;446.38;275130000;446.38
1994-04-13;447.63;448.57;442.62;446.26;278030000;446.26
1994-04-12;449.83;450.80;447.33;447.57;257990000;447.57
1994-04-11;447.12;450.34;447.10;449.87;243180000;449.87
1994-04-08;450.89;450.89;445.51;447.10;264090000;447.10
1994-04-07;448.11;451.10;446.38;450.88;289280000;450.88
1994-04-06;448.29;449.63;444.98;448.05;302000000;448.05
1994-04-05;439.14;448.29;439.14;448.29;365990000;448.29
1994-04-04;445.66;445.66;435.86;438.92;344390000;438.92
1994-03-31;445.55;447.16;436.16;445.77;403580000;445.77
1994-03-30;452.48;452.49;445.55;445.55;390520000;445.55
1994-03-29;460.00;460.32;452.43;452.48;305360000;452.48
1994-03-28;460.58;461.12;456.10;460.00;287350000;460.00
1994-03-25;464.35;465.29;460.58;460.58;249640000;460.58
1994-03-24;468.57;468.57;462.41;464.35;303740000;464.35
1994-03-23;468.89;470.38;468.52;468.54;281500000;468.54
1994-03-22;468.40;470.47;467.88;468.80;282240000;468.80
1994-03-21;471.06;471.06;467.23;468.54;247380000;468.54
1994-03-18;470.89;471.09;467.83;471.06;462240000;471.06
1994-03-17;469.42;471.05;468.62;470.90;303930000;470.90
1994-03-16;467.04;469.85;465.48;469.42;307640000;469.42
1994-03-15;467.39;468.99;466.04;467.01;303750000;467.01
1994-03-14;466.44;467.60;466.08;467.39;260150000;467.39
1994-03-11;463.86;466.61;462.54;466.44;303890000;466.44
1994-03-10;467.08;467.29;462.46;463.90;369370000;463.90
1994-03-09;465.94;467.42;463.40;467.06;309810000;467.06
1994-03-08;466.92;467.79;465.02;465.88;298110000;465.88
1994-03-07;464.74;468.07;464.74;466.91;285590000;466.91
1994-03-04;463.03;466.16;462.41;464.74;311850000;464.74
1994-03-03;464.81;464.83;462.50;463.01;291790000;463.01
1994-03-02;464.40;464.87;457.49;464.81;361130000;464.81
1994-03-01;467.19;467.43;462.02;464.44;304450000;464.44
1994-02-28;466.07;469.16;466.07;467.14;268690000;467.14
1994-02-25;464.33;466.48;464.33;466.07;273680000;466.07
1994-02-24;470.65;470.65;464.26;464.26;342940000;464.26
1994-02-23;471.48;472.41;469.47;470.69;309910000;470.69
1994-02-22;467.69;471.65;467.58;471.46;270900000;471.46
1994-02-18;470.29;471.09;466.07;467.69;293210000;467.69
1994-02-17;472.79;475.12;468.44;470.34;340030000;470.34
1994-02-16;472.53;474.16;471.94;472.79;295450000;472.79
1994-02-15;470.23;473.41;470.23;472.52;306790000;472.52
1994-02-14;470.18;471.99;469.05;470.23;263190000;470.23
1994-02-11;468.93;471.13;466.89;470.18;213740000;470.18
1994-02-10;472.81;473.13;468.91;468.93;327250000;468.93
1994-02-09;471.05;473.41;471.05;472.77;332670000;472.77
1994-02-08;471.76;472.33;469.50;471.05;318180000;471.05
1994-02-07;469.81;472.09;467.57;471.76;348270000;471.76
1994-02-04;480.68;481.02;469.28;469.81;378380000;469.81
1994-02-03;481.96;481.96;478.71;480.71;318350000;480.71
1994-02-02;479.62;482.23;479.57;482.00;328960000;482.00
1994-02-01;481.60;481.64;479.18;479.62;322510000;479.62
1994-01-31;478.70;482.85;478.70;481.61;322870000;481.61
1994-01-28;477.05;479.75;477.05;478.70;313140000;478.70
1994-01-27;473.20;477.52;473.20;477.05;346500000;477.05
1994-01-26;470.92;473.44;470.72;473.20;304660000;473.20
1994-01-25;471.97;472.56;470.27;470.92;326120000;470.92
1994-01-24;474.72;475.20;471.49;471.97;296900000;471.97
1994-01-21;474.98;475.56;473.72;474.72;346350000;474.72
1994-01-20;474.30;475.00;473.42;474.98;310450000;474.98
1994-01-19;474.25;474.70;472.21;474.30;311370000;474.30
1994-01-18;473.30;475.19;473.29;474.25;308840000;474.25
1994-01-17;474.91;474.91;472.84;473.30;233980000;473.30
1994-01-14;472.50;475.32;472.50;474.91;304920000;474.91
1994-01-13;474.17;474.17;471.80;472.47;277970000;472.47
1994-01-12;474.13;475.06;472.14;474.17;310690000;474.17
1994-01-11;475.27;475.28;473.27;474.13;305490000;474.13
1994-01-10;469.90;475.27;469.55;475.27;319490000;475.27
1994-01-07;467.09;470.26;467.03;469.90;324920000;469.90
1994-01-06;467.55;469.00;467.02;467.12;365960000;467.12
1994-01-05;466.89;467.82;465.92;467.55;400030000;467.55
1994-01-04;465.44;466.89;464.44;466.89;326600000;466.89
1994-01-03;466.51;466.94;464.36;465.44;270140000;465.44
1993-12-31;468.66;470.75;466.45;466.45;168590000;466.45
1993-12-30;470.58;470.58;468.09;468.64;195860000;468.64
1993-12-29;470.88;471.29;469.87;470.58;269570000;470.58
1993-12-28;470.61;471.05;469.43;470.94;200960000;470.94
1993-12-27;467.40;470.55;467.35;470.54;171200000;470.54
1993-12-23;467.30;468.97;467.30;467.38;227240000;467.38
1993-12-22;465.08;467.38;465.08;467.32;272440000;467.32
1993-12-21;465.84;465.92;464.03;465.30;273370000;465.30
1993-12-20;466.38;466.90;465.53;465.85;255900000;465.85
1993-12-17;463.34;466.38;463.34;466.38;363750000;466.38
1993-12-16;461.86;463.98;461.86;463.34;284620000;463.34
1993-12-15;463.06;463.69;461.84;461.84;331770000;461.84
1993-12-14;465.73;466.12;462.46;463.06;275050000;463.06
1993-12-13;463.93;465.71;462.71;465.70;256580000;465.70
1993-12-10;464.18;464.87;462.66;463.93;245620000;463.93
1993-12-09;466.29;466.54;463.87;464.18;287570000;464.18
1993-12-08;465.88;466.73;465.42;466.29;314460000;466.29
1993-12-07;466.43;466.77;465.44;466.76;285690000;466.76
1993-12-06;464.89;466.89;464.40;466.43;292370000;466.43
1993-12-03;463.13;464.89;462.67;464.89;268360000;464.89
1993-12-02;461.89;463.22;461.45;463.11;256370000;463.11
1993-12-01;461.93;464.47;461.63;461.89;293870000;461.89
1993-11-30;461.90;463.62;460.45;461.79;286660000;461.79
1993-11-29;463.06;464.83;461.83;461.90;272710000;461.90
1993-11-26;462.36;463.63;462.36;463.06;90220000;463.06
1993-11-24;461.03;462.90;461.03;462.36;230630000;462.36
1993-11-23;459.13;461.77;458.47;461.03;260400000;461.03
1993-11-22;462.60;462.60;457.08;459.13;280130000;459.13
1993-11-19;463.59;463.60;460.03;462.60;302970000;462.60
1993-11-18;464.83;464.88;461.73;463.62;313490000;463.62
1993-11-17;466.74;467.24;462.73;464.81;316940000;464.81
1993-11-16;463.75;466.74;462.97;466.74;303980000;466.74
1993-11-15;465.39;466.13;463.01;463.75;251030000;463.75
1993-11-12;462.64;465.84;462.64;465.39;326240000;465.39
1993-11-11;463.72;464.96;462.49;462.64;283820000;462.64
1993-11-10;460.40;463.72;459.57;463.72;283450000;463.72
1993-11-09;460.21;463.42;460.21;460.33;276360000;460.33
1993-11-08;459.57;461.54;458.78;460.21;234340000;460.21
1993-11-05;457.49;459.63;454.36;459.57;336890000;459.57
1993-11-04;463.02;463.16;457.26;457.49;323430000;457.49
1993-11-03;468.44;468.61;460.95;463.02;342110000;463.02
1993-11-02;469.10;469.10;466.20;468.44;304780000;468.44
1993-11-01;467.83;469.11;467.33;469.10;256030000;469.10
1993-10-29;467.72;468.20;467.37;467.83;270570000;467.83
1993-10-28;464.52;468.76;464.52;467.73;301220000;467.73
1993-10-27;464.30;464.61;463.36;464.61;279830000;464.61
1993-10-26;464.20;464.32;462.65;464.30;284530000;464.30
1993-10-25;463.27;464.49;462.05;464.20;260310000;464.20
1993-10-22;465.36;467.82;463.27;463.27;301440000;463.27
1993-10-21;466.06;466.64;464.38;465.36;289600000;465.36
1993-10-20;466.21;466.87;464.54;466.07;305670000;466.07
1993-10-19;468.41;468.64;464.80;466.21;304400000;466.21
1993-10-18;469.50;470.04;468.02;468.45;329580000;468.45
1993-10-15;466.83;471.10;466.83;469.50;366110000;469.50
1993-10-14;461.55;466.83;461.55;466.83;352530000;466.83
1993-10-13;461.12;461.98;460.76;461.49;290930000;461.49
1993-10-12;461.04;462.47;460.73;461.12;263970000;461.12
1993-10-11;460.31;461.87;460.31;460.88;183060000;460.88
1993-10-08;459.18;460.99;456.40;460.31;243600000;460.31
1993-10-07;460.71;461.13;459.08;459.18;255210000;459.18
1993-10-06;461.24;462.60;460.26;460.74;277070000;460.74
1993-10-05;461.34;463.15;459.45;461.20;294570000;461.20
1993-10-04;461.28;461.80;460.02;461.34;229380000;461.34
1993-10-01;458.93;461.48;458.35;461.28;256880000;461.28
1993-09-30;460.11;460.56;458.28;458.93;280980000;458.93
1993-09-29;461.60;462.17;459.51;460.11;277690000;460.11
1993-09-28;461.84;462.08;460.91;461.53;243320000;461.53
1993-09-27;457.63;461.81;457.63;461.80;244920000;461.80
1993-09-24;457.74;458.56;456.92;457.63;248270000;457.63
1993-09-23;456.25;458.69;456.25;457.74;275350000;457.74
1993-09-22;452.94;456.92;452.94;456.20;298960000;456.20
1993-09-21;455.05;455.80;449.64;452.95;300310000;452.95
1993-09-20;458.84;459.91;455.00;455.05;231130000;455.05
1993-09-17;459.43;459.43;457.09;458.83;381370000;458.83
1993-09-16;461.54;461.54;459.00;459.43;229700000;459.43
1993-09-15;459.90;461.96;456.31;461.60;294410000;461.60
1993-09-14;461.93;461.93;458.15;459.90;258650000;459.90
1993-09-13;461.70;463.38;461.41;462.06;244970000;462.06
1993-09-10;457.49;461.86;457.49;461.72;269950000;461.72
1993-09-09;456.65;458.11;455.17;457.50;258070000;457.50
1993-09-08;458.52;458.53;453.75;456.65;283100000;456.65
1993-09-07;461.34;462.07;457.95;458.52;229500000;458.52
1993-09-03;461.30;462.05;459.91;461.34;197160000;461.34
1993-09-02;463.13;463.54;461.07;461.30;259870000;461.30
1993-09-01;463.55;463.80;461.77;463.15;245040000;463.15
1993-08-31;461.90;463.56;461.29;463.56;252830000;463.56
1993-08-30;460.54;462.58;460.28;461.90;194180000;461.90
1993-08-27;461.05;461.05;459.19;460.54;196140000;460.54
1993-08-26;460.04;462.87;458.82;461.04;254070000;461.04
1993-08-25;459.75;462.04;459.30;460.13;301650000;460.13
1993-08-24;455.23;459.77;455.04;459.77;270700000;459.77
1993-08-23;456.12;456.12;454.29;455.23;212500000;455.23
1993-08-20;456.51;456.68;454.60;456.16;276800000;456.16
1993-08-19;456.01;456.76;455.20;456.43;293330000;456.43
1993-08-18;453.21;456.99;453.21;456.04;312940000;456.04
1993-08-17;452.38;453.70;451.96;453.13;261320000;453.13
1993-08-16;450.25;453.41;450.25;452.38;233640000;452.38
1993-08-13;448.97;450.25;448.97;450.14;214370000;450.14
1993-08-12;450.47;451.63;447.53;448.96;278530000;448.96
1993-08-11;449.60;451.00;449.60;450.46;268330000;450.46
1993-08-10;450.71;450.71;449.10;449.45;255520000;449.45
1993-08-09;448.68;451.51;448.31;450.72;232750000;450.72
1993-08-06;448.13;449.26;447.87;448.68;221170000;448.68
1993-08-05;448.55;449.61;446.94;448.13;261900000;448.13
1993-08-04;449.27;449.72;447.93;448.54;230040000;448.54
1993-08-03;450.15;450.43;447.59;449.27;253110000;449.27
1993-08-02;448.13;450.15;448.03;450.15;230380000;450.15
1993-07-30;450.19;450.22;446.98;448.13;254420000;448.13
1993-07-29;447.19;450.77;447.19;450.24;261240000;450.24
1993-07-28;448.25;448.61;446.59;447.19;273100000;447.19
1993-07-27;449.00;449.44;446.76;448.24;256750000;448.24
1993-07-26;447.06;449.50;447.04;449.09;222580000;449.09
1993-07-23;444.54;447.10;444.54;447.10;222170000;447.10
1993-07-22;447.18;447.23;443.72;444.51;249630000;444.51
1993-07-21;447.28;447.50;445.84;447.18;278590000;447.18
1993-07-20;446.03;447.63;443.71;447.31;277420000;447.31
1993-07-19;445.75;446.78;444.83;446.03;216370000;446.03
1993-07-16;449.07;449.08;445.66;445.75;263100000;445.75
1993-07-15;450.09;450.12;447.26;449.22;277810000;449.22
1993-07-14;448.08;451.12;448.08;450.08;297430000;450.08
1993-07-13;449.00;450.70;448.07;448.09;236720000;448.09
1993-07-12;448.13;449.11;447.71;448.98;202310000;448.98
1993-07-09;448.64;448.94;446.74;448.11;235210000;448.11
1993-07-08;442.84;448.64;442.84;448.64;282910000;448.64
1993-07-07;441.40;443.63;441.40;442.83;253170000;442.83
1993-07-06;445.86;446.87;441.42;441.43;234810000;441.43
1993-07-02;449.02;449.02;445.20;445.84;220750000;445.84
1993-07-01;450.54;451.15;448.71;449.02;292040000;449.02
1993-06-30;450.69;451.47;450.15;450.53;281120000;450.53
1993-06-29;451.89;451.90;449.67;450.69;276310000;450.69
1993-06-28;447.60;451.90;447.60;451.85;242090000;451.85
1993-06-25;446.62;448.64;446.62;447.60;210430000;447.60
1993-06-24;443.04;447.21;442.50;446.62;267450000;446.62
1993-06-23;445.96;445.96;443.19;443.19;278260000;443.19
1993-06-22;446.25;446.29;444.94;445.93;259530000;445.93
1993-06-21;443.68;446.22;443.68;446.22;223650000;446.22
1993-06-18;448.54;448.59;443.68;443.68;300500000;443.68
1993-06-17;447.43;448.98;446.91;448.54;239810000;448.54
1993-06-16;446.27;447.43;443.61;447.43;267500000;447.43
1993-06-15;447.73;448.28;446.18;446.27;234110000;446.27
1993-06-14;447.26;448.64;447.23;447.71;210440000;447.71
1993-06-11;445.38;448.19;445.38;447.26;256750000;447.26
1993-06-10;445.78;446.22;444.09;445.38;232600000;445.38
1993-06-09;444.71;447.39;444.66;445.78;249030000;445.78
1993-06-08;447.65;447.65;444.31;444.71;240640000;444.71
1993-06-07;450.07;450.75;447.32;447.69;236920000;447.69
1993-06-04;452.43;452.43;448.92;450.06;226440000;450.06
1993-06-03;453.84;453.85;451.12;452.49;285570000;452.49
1993-06-02;453.83;454.53;452.68;453.85;295560000;453.85
1993-06-01;450.23;455.63;450.23;453.83;229690000;453.83
1993-05-28;452.41;452.41;447.67;450.19;207820000;450.19
1993-05-27;453.44;454.55;451.14;452.41;300810000;452.41
1993-05-26;448.85;453.51;448.82;453.44;274230000;453.44
1993-05-25;448.00;449.04;447.70;448.85;222090000;448.85
1993-05-24;445.84;448.44;445.26;448.00;197990000;448.00
1993-05-21;450.59;450.59;444.89;445.84;279120000;445.84
1993-05-20;447.57;450.59;447.36;450.59;289160000;450.59
1993-05-19;440.32;447.86;436.86;447.57;342420000;447.57
1993-05-18;440.39;441.26;437.95;440.32;264300000;440.32
1993-05-17;439.56;440.38;437.83;440.37;227580000;440.37
1993-05-14;439.22;439.82;438.10;439.56;252910000;439.56
1993-05-13;444.75;444.75;439.23;439.23;293920000;439.23
1993-05-12;444.32;445.16;442.87;444.80;255680000;444.80
1993-05-11;442.80;444.57;441.52;444.36;218480000;444.36
1993-05-10;442.34;445.42;442.05;442.80;235580000;442.80
1993-05-07;443.28;443.70;441.69;442.31;223570000;442.31
1993-05-06;444.60;444.81;442.90;443.26;255460000;443.26
1993-05-05;443.98;446.09;443.76;444.52;274240000;444.52
1993-05-04;442.58;445.19;442.45;444.05;268310000;444.05
1993-05-03;440.19;442.59;438.25;442.46;224970000;442.46
1993-04-30;438.89;442.29;438.89;440.19;247460000;440.19
1993-04-29;438.02;438.96;435.59;438.89;249760000;438.89
1993-04-28;438.01;438.80;436.68;438.02;267980000;438.02
1993-04-27;433.52;438.02;433.14;438.01;284140000;438.01
1993-04-26;437.03;438.35;432.30;433.54;283260000;433.54
1993-04-23;439.49;439.49;436.82;437.03;259810000;437.03
1993-04-22;443.55;445.73;439.46;439.46;310390000;439.46
1993-04-21;445.09;445.77;443.08;443.63;287300000;443.63
1993-04-20;447.46;447.46;441.81;445.10;317990000;445.10
1993-04-19;448.94;449.14;445.85;447.46;244710000;447.46
1993-04-16;448.41;449.39;447.67;448.94;305160000;448.94
1993-04-15;448.60;449.11;446.39;448.40;259500000;448.40
1993-04-14;449.22;450.00;448.02;448.66;257340000;448.66
1993-04-13;448.41;450.40;447.66;449.22;286690000;449.22
1993-04-12;441.84;448.37;441.84;448.37;259690000;448.37
1993-04-08;442.71;443.77;440.02;441.84;284370000;441.84
1993-04-07;441.16;442.73;440.50;442.73;300000000;442.73
1993-04-06;442.29;443.38;439.48;441.16;293680000;441.16
1993-04-05;441.42;442.43;440.53;442.29;296080000;442.29
1993-04-02;450.28;450.28;440.71;441.39;323330000;441.39
1993-04-01;451.67;452.63;449.60;450.30;234530000;450.30
1993-03-31;451.97;454.88;451.67;451.67;279190000;451.67
1993-03-30;450.79;452.06;449.63;451.97;231190000;451.97
1993-03-29;447.76;452.81;447.75;450.77;199970000;450.77
1993-03-26;450.91;452.09;447.69;447.78;226650000;447.78
1993-03-25;448.09;451.75;447.93;450.88;251530000;450.88
1993-03-24;448.71;450.90;446.10;448.07;274300000;448.07
1993-03-23;448.88;449.80;448.30;448.76;232730000;448.76
1993-03-22;450.17;450.17;446.08;448.88;233190000;448.88
1993-03-19;451.90;453.32;449.91;450.18;339660000;450.18
1993-03-18;448.36;452.39;448.36;451.89;241180000;451.89
1993-03-17;451.36;451.36;447.99;448.31;241270000;448.31
1993-03-16;451.43;452.36;451.01;451.37;218820000;451.37
1993-03-15;449.83;451.43;449.40;451.43;195930000;451.43
1993-03-12;453.70;453.70;447.04;449.83;255420000;449.83
1993-03-11;456.35;456.76;453.48;453.72;257060000;453.72
1993-03-10;454.40;456.34;452.70;456.33;255610000;456.33
1993-03-09;454.67;455.52;453.68;454.40;290670000;454.40
1993-03-08;446.12;454.71;446.12;454.71;275290000;454.71
1993-03-05;447.34;449.59;445.56;446.11;253480000;446.11
1993-03-04;449.26;449.52;446.72;447.34;234220000;447.34
1993-03-03;447.90;450.00;447.73;449.26;277380000;449.26
1993-03-02;442.00;447.91;441.07;447.90;269750000;447.90
1993-03-01;443.38;444.18;441.34;442.01;232460000;442.01
1993-02-26;442.34;443.77;440.98;443.38;234160000;443.38
1993-02-25;440.70;442.34;439.67;442.34;252860000;442.34
1993-02-24;434.76;440.87;434.68;440.87;316750000;440.87
1993-02-23;435.34;436.84;432.41;434.80;329060000;434.80
1993-02-22;434.21;436.49;433.53;435.24;311570000;435.24
1993-02-19;431.93;434.26;431.68;434.22;310700000;434.22
1993-02-18;433.30;437.79;428.25;431.90;311180000;431.90
1993-02-17;433.93;433.97;430.92;433.30;302210000;433.30
1993-02-16;444.53;444.53;433.47;433.91;332850000;433.91
1993-02-12;447.66;447.70;444.58;444.58;216810000;444.58
1993-02-11;446.21;449.36;446.21;447.66;257190000;447.66
1993-02-10;445.33;446.37;444.24;446.23;251910000;446.23
1993-02-09;448.04;448.04;444.52;445.33;240410000;445.33
1993-02-08;448.94;450.04;447.70;447.85;243400000;447.85
1993-02-05;449.56;449.56;446.95;448.93;324710000;448.93
1993-02-04;447.20;449.86;447.20;449.56;351140000;449.56
1993-02-03;442.56;447.35;442.56;447.20;345410000;447.20
1993-02-02;442.52;442.87;440.76;442.55;271560000;442.55
1993-02-01;438.78;442.52;438.78;442.52;238570000;442.52
1993-01-29;438.67;438.93;436.91;438.78;247200000;438.78
1993-01-28;438.13;439.14;437.30;438.66;256980000;438.66
1993-01-27;439.95;440.04;436.82;438.11;277020000;438.11
1993-01-26;440.05;442.66;439.54;439.95;314110000;439.95
1993-01-25;436.11;440.53;436.11;440.01;288740000;440.01
1993-01-22;435.49;437.81;435.49;436.11;293320000;436.11
1993-01-21;433.37;435.75;432.48;435.49;257620000;435.49
1993-01-20;435.14;436.23;433.37;433.37;268790000;433.37
1993-01-19;436.84;437.70;434.59;435.13;283240000;435.13
1993-01-18;437.13;437.13;435.92;436.84;196030000;436.84
1993-01-15;435.87;439.49;435.84;437.15;309720000;437.15
1993-01-14;433.08;435.96;433.08;435.94;281040000;435.94
1993-01-13;431.03;433.44;429.99;433.03;245360000;433.03
1993-01-12;430.95;431.39;428.19;431.04;239410000;431.04
1993-01-11;429.04;431.04;429.01;430.95;217150000;430.95
1993-01-08;430.73;430.73;426.88;429.05;263470000;429.05
1993-01-07;434.52;435.46;429.76;430.73;304850000;430.73
1993-01-06;434.34;435.17;432.52;434.52;295240000;434.52
1993-01-05;435.38;435.40;433.55;434.34;240350000;434.34
1993-01-04;435.70;437.32;434.48;435.38;201210000;435.38
1992-12-31;438.82;439.59;435.71;435.71;165910000;435.71
1992-12-30;437.98;439.37;437.12;438.82;183930000;438.82
1992-12-29;439.15;442.65;437.60;437.98;213660000;437.98
1992-12-28;439.77;439.77;437.26;439.15;143970000;439.15
1992-12-24;439.03;439.81;439.03;439.77;95240000;439.77
1992-12-23;440.29;441.11;439.03;439.03;234140000;439.03
1992-12-22;440.70;441.64;438.25;440.31;250430000;440.31
1992-12-21;441.26;441.26;439.65;440.70;224680000;440.70
1992-12-18;435.46;441.29;435.46;441.28;389300000;441.28
1992-12-17;431.52;435.44;431.46;435.43;251640000;435.43
1992-12-16;432.58;434.22;430.88;431.52;242130000;431.52
1992-12-15;432.82;433.66;431.92;432.57;227770000;432.57
1992-12-14;433.73;435.26;432.83;432.84;187040000;432.84
1992-12-11;434.64;434.64;433.34;433.73;164510000;433.73
1992-12-10;435.66;435.66;432.65;434.64;240640000;434.64
1992-12-09;436.99;436.99;433.98;435.65;230060000;435.65
1992-12-08;435.31;436.99;434.68;436.99;234330000;436.99
1992-12-07;432.06;435.31;432.06;435.31;217700000;435.31
1992-12-04;429.93;432.89;429.74;432.06;234960000;432.06
1992-12-03;429.98;430.99;428.80;429.91;238050000;429.91
1992-12-02;430.78;430.87;428.61;429.89;247010000;429.89
1992-12-01;431.35;431.47;429.20;430.78;259050000;430.78
1992-11-30;430.19;431.53;429.36;431.35;230150000;431.35
1992-11-27;429.19;431.93;429.17;430.16;106020000;430.16
1992-11-25;427.59;429.41;427.58;429.19;207700000;429.19
1992-11-24;425.14;429.31;424.83;427.59;241540000;427.59
1992-11-23;426.65;426.65;424.95;425.12;192530000;425.12
1992-11-20;423.61;426.98;423.61;426.65;257460000;426.65
1992-11-19;422.86;423.61;422.50;423.61;218720000;423.61
1992-11-18;419.27;423.49;419.24;422.85;219080000;422.85
1992-11-17;420.63;420.97;418.31;419.27;187660000;419.27
1992-11-16;422.44;422.44;420.35;420.68;173600000;420.68
1992-11-13;422.89;422.91;421.04;422.43;192950000;422.43
1992-11-12;422.20;423.10;421.70;422.87;226010000;422.87
1992-11-11;418.62;422.33;418.40;422.20;243750000;422.20
1992-11-10;418.59;419.71;417.98;418.62;223180000;418.62
1992-11-09;417.58;420.13;416.79;418.59;197560000;418.59
1992-11-06;418.35;418.35;417.01;417.58;205310000;417.58
1992-11-05;417.08;418.40;415.58;418.34;219730000;418.34
1992-11-04;419.91;421.07;416.61;417.11;194400000;417.11
1992-11-03;422.75;422.81;418.59;419.92;208140000;419.92
1992-11-02;418.66;422.75;418.12;422.75;203280000;422.75
1992-10-30;420.86;421.13;418.54;418.68;201930000;418.68
1992-10-29;420.15;421.16;419.83;420.86;206550000;420.86
1992-10-28;418.49;420.13;417.56;420.13;203910000;420.13
1992-10-27;418.18;419.20;416.97;418.49;201730000;418.49
1992-10-26;414.09;418.17;413.71;418.16;188060000;418.16
1992-10-23;414.90;416.23;413.68;414.10;199060000;414.10
1992-10-22;415.67;416.81;413.10;414.90;216400000;414.90
1992-10-21;415.53;416.15;414.54;415.67;219100000;415.67
1992-10-20;414.98;417.98;414.49;415.48;258210000;415.48
1992-10-19;411.73;414.98;410.66;414.98;222150000;414.98
1992-10-16;409.60;411.73;407.43;411.73;235920000;411.73
1992-10-15;409.34;411.03;407.92;409.60;213590000;409.60
1992-10-14;409.30;411.52;407.86;409.37;175900000;409.37
1992-10-13;407.44;410.64;406.83;409.30;186650000;409.30
1992-10-12;402.66;407.44;402.66;407.44;126670000;407.44
1992-10-09;407.75;407.75;402.42;402.66;178940000;402.66
1992-10-08;404.29;408.04;404.29;407.75;205000000;407.75
1992-10-07;407.17;408.60;403.91;404.25;184380000;404.25
1992-10-06;407.57;408.56;404.84;407.18;203500000;407.18
1992-10-05;410.47;410.47;396.80;407.57;286550000;407.57
1992-10-02;416.29;416.35;410.45;410.47;188030000;410.47
1992-10-01;417.80;418.67;415.46;416.29;204780000;416.29
1992-09-30;416.79;418.58;416.67;417.80;184470000;417.80
1992-09-29;416.62;417.38;415.34;416.80;170750000;416.80
1992-09-28;414.35;416.62;413.00;416.62;158760000;416.62
1992-09-25;418.47;418.63;412.71;414.35;213670000;414.35
1992-09-24;417.46;419.01;417.46;418.47;187960000;418.47
1992-09-23;417.14;417.88;416.00;417.44;205700000;417.44
1992-09-22;422.14;422.14;417.13;417.14;188810000;417.14
1992-09-21;422.90;422.90;421.18;422.14;153940000;422.14
1992-09-18;419.92;422.93;419.92;422.93;237440000;422.93
1992-09-17;419.92;421.43;419.62;419.93;188270000;419.93
1992-09-16;419.71;422.44;417.77;419.92;231450000;419.92
1992-09-15;425.22;425.22;419.54;419.77;211860000;419.77
1992-09-14;419.65;425.27;419.65;425.27;250940000;425.27
1992-09-11;419.95;420.58;419.13;419.58;180560000;419.58
1992-09-10;416.34;420.52;416.34;419.95;221990000;419.95
1992-09-09;414.44;416.44;414.44;416.36;178800000;416.36
1992-09-08;417.08;417.18;414.30;414.44;161440000;414.44
1992-09-04;417.98;418.62;416.76;417.08;124380000;417.08
1992-09-03;417.98;420.31;417.49;417.98;212500000;417.98
1992-09-02;416.07;418.28;415.31;417.98;187480000;417.98
1992-09-01;414.03;416.07;413.35;416.07;172680000;416.07
1992-08-31;414.87;415.29;413.76;414.03;161480000;414.03
1992-08-28;413.54;414.95;413.38;414.84;152260000;414.84
1992-08-27;413.51;415.83;413.51;413.53;178600000;413.53
1992-08-26;411.65;413.61;410.53;413.51;171860000;413.51
1992-08-25;410.73;411.64;408.30;411.61;202760000;411.61
1992-08-24;414.80;414.80;410.07;410.72;165690000;410.72
1992-08-21;418.27;420.35;413.58;414.85;204800000;414.85
1992-08-20;418.19;418.85;416.93;418.26;183420000;418.26
1992-08-19;421.34;421.62;418.19;418.19;187070000;418.19
1992-08-18;420.74;421.40;419.78;421.34;171750000;421.34
1992-08-17;419.89;421.89;419.44;420.74;152830000;420.74
1992-08-14;417.74;420.40;417.74;419.91;166820000;419.91
1992-08-13;417.78;419.88;416.40;417.73;185750000;417.73
1992-08-12;418.89;419.75;416.43;417.78;176560000;417.78
1992-08-11;419.45;419.72;416.53;418.90;173940000;418.90
1992-08-10;418.87;419.42;417.04;419.42;142480000;419.42
1992-08-07;420.59;423.45;418.51;418.88;190640000;418.88
1992-08-06;422.19;422.36;420.26;420.59;181440000;420.59
1992-08-05;424.35;424.35;421.92;422.19;172450000;422.19
1992-08-04;425.09;425.14;423.10;424.36;166760000;424.36
1992-08-03;424.19;425.09;422.84;425.09;164460000;425.09
1992-07-31;423.92;424.80;422.46;424.21;172920000;424.21
1992-07-30;422.20;423.94;421.57;423.92;193410000;423.92
1992-07-29;417.52;423.02;417.52;422.23;275850000;422.23
1992-07-28;411.55;417.55;411.55;417.52;218060000;417.52
1992-07-27;411.60;412.67;411.27;411.54;164700000;411.54
1992-07-24;412.07;412.07;409.93;411.60;163890000;411.60
1992-07-23;410.93;412.08;409.81;412.08;175490000;412.08
1992-07-22;413.74;413.74;409.95;410.93;190160000;410.93
1992-07-21;413.75;414.92;413.10;413.76;173760000;413.76
1992-07-20;415.62;415.62;410.72;413.75;165760000;413.75
1992-07-17;417.54;417.54;412.96;415.62;192120000;415.62
1992-07-16;417.04;417.93;414.79;417.54;206900000;417.54
1992-07-15;417.68;417.81;416.29;417.10;206560000;417.10
1992-07-14;414.86;417.69;414.33;417.68;195570000;417.68
1992-07-13;414.62;415.86;413.93;414.87;148870000;414.87
1992-07-10;414.23;415.88;413.34;414.62;164770000;414.62
1992-07-09;410.28;414.69;410.26;414.23;207980000;414.23
1992-07-08;409.15;410.28;407.20;410.28;201030000;410.28
1992-07-07;413.83;415.33;408.58;409.16;226050000;409.16
1992-07-06;411.77;413.84;410.46;413.84;186920000;413.84
1992-07-02;412.88;415.71;410.07;411.77;220200000;411.77
1992-07-01;408.20;412.88;408.20;412.88;214250000;412.88
1992-06-30;408.94;409.63;407.85;408.14;195530000;408.14
1992-06-29;403.47;408.96;403.47;408.94;176750000;408.94
1992-06-26;403.12;403.51;401.94;403.45;154430000;403.45
1992-06-25;403.83;405.53;402.01;403.12;182960000;403.12
1992-06-24;404.05;404.76;403.26;403.84;193870000;403.84
1992-06-23;403.40;405.41;403.40;404.04;189190000;404.04
1992-06-22;403.64;403.64;399.92;403.40;169370000;403.40
1992-06-19;400.96;404.23;400.96;403.67;233460000;403.67
1992-06-18;402.26;402.68;400.51;400.96;225600000;400.96
1992-06-17;408.33;408.33;401.98;402.26;227760000;402.26
1992-06-16;410.29;411.40;408.32;408.32;194400000;408.32
1992-06-15;409.76;411.68;408.13;410.29;164080000;410.29
1992-06-12;409.08;411.86;409.08;409.76;181860000;409.76
1992-06-11;407.25;409.05;406.11;409.05;204780000;409.05
1992-06-10;410.06;410.10;406.81;407.25;210750000;407.25
1992-06-09;413.40;413.56;409.30;410.06;191170000;410.06
1992-06-08;413.48;413.95;412.03;413.36;161240000;413.36
1992-06-05;413.26;413.85;410.97;413.48;199050000;413.48
1992-06-04;414.60;414.98;412.97;413.26;204450000;413.26
1992-06-03;413.50;416.54;413.04;414.59;215770000;414.59
1992-06-02;417.30;417.30;413.50;413.50;202560000;413.50
1992-06-01;415.35;417.30;412.44;417.30;180800000;417.30
1992-05-29;416.74;418.36;415.35;415.35;204010000;415.35
1992-05-28;412.17;416.77;411.81;416.74;195300000;416.74
1992-05-27;411.41;412.68;411.06;412.17;182240000;412.17
1992-05-26;414.02;414.02;410.23;411.41;197700000;411.41
1992-05-22;412.61;414.82;412.60;414.02;146710000;414.02
1992-05-21;415.40;415.41;411.57;412.60;184860000;412.60
1992-05-20;416.37;416.83;415.37;415.39;198180000;415.39
1992-05-19;412.82;416.51;412.26;416.37;187130000;416.37
1992-05-18;410.13;413.34;410.13;412.81;151380000;412.81
1992-05-15;413.14;413.14;409.85;410.09;192740000;410.09
1992-05-14;416.45;416.52;411.82;413.14;189150000;413.14
1992-05-13;416.29;417.04;415.86;416.45;175850000;416.45
1992-05-12;418.49;418.68;414.69;416.29;192870000;416.29
1992-05-11;416.05;418.75;416.05;418.49;155730000;418.49
1992-05-08;415.87;416.85;414.41;416.05;168720000;416.05
1992-05-07;416.79;416.84;415.38;415.85;168980000;415.85
1992-05-06;416.84;418.48;416.40;416.79;199950000;416.79
1992-05-05;416.91;418.53;415.77;416.84;200550000;416.84
1992-05-04;412.54;417.84;412.54;416.91;174540000;416.91
1992-05-01;414.95;415.21;409.87;412.53;177390000;412.53
1992-04-30;412.02;414.95;412.02;414.95;223590000;414.95
1992-04-29;409.11;412.31;409.11;412.02;206780000;412.02
1992-04-28;408.45;409.69;406.33;409.11;189220000;409.11
1992-04-27;409.03;409.60;407.64;408.45;172900000;408.45
1992-04-24;411.60;412.48;408.74;409.02;199310000;409.02
1992-04-23;409.81;411.60;406.86;411.60;235860000;411.60
1992-04-22;410.26;411.30;409.23;409.81;218850000;409.81
1992-04-21;410.16;411.09;408.20;410.26;214460000;410.26
1992-04-20;416.05;416.05;407.93;410.18;191980000;410.18
1992-04-16;416.28;416.28;413.40;416.04;233230000;416.04
1992-04-15;412.39;416.28;412.39;416.28;229710000;416.28
1992-04-14;406.08;413.86;406.08;412.39;231130000;412.39
1992-04-13;404.28;406.08;403.90;406.08;143140000;406.08
1992-04-10;400.59;405.12;400.59;404.29;199530000;404.29
1992-04-09;394.50;401.04;394.50;400.64;231430000;400.64
1992-04-08;398.05;398.05;392.41;394.50;249280000;394.50
1992-04-07;405.59;405.75;397.97;398.06;205210000;398.06
1992-04-06;401.54;405.93;401.52;405.59;179910000;405.59
1992-04-03;400.50;401.59;398.21;401.55;188580000;401.55
1992-04-02;404.17;404.63;399.28;400.50;185210000;400.50
1992-04-01;403.67;404.50;400.75;404.23;186530000;404.23
1992-03-31;403.00;405.21;402.22;403.69;182360000;403.69
1992-03-30;403.50;404.30;402.97;403.00;133990000;403.00
1992-03-27;407.86;407.86;402.87;403.50;166140000;403.50
1992-03-26;407.52;409.44;406.75;407.86;176720000;407.86
1992-03-25;408.88;409.87;407.52;407.52;192650000;407.52
1992-03-24;409.91;411.43;407.99;408.88;191610000;408.88
1992-03-23;411.29;411.29;408.87;409.91;157050000;409.91
1992-03-20;409.80;411.30;408.53;411.30;246210000;411.30
1992-03-19;409.15;410.57;409.12;409.80;197310000;409.80
1992-03-18;409.58;410.84;408.23;409.15;191720000;409.15
1992-03-17;406.39;409.72;406.39;409.58;187250000;409.58
1992-03-16;405.85;406.40;403.55;406.39;155950000;406.39
1992-03-13;403.92;406.69;403.92;405.84;177900000;405.84
1992-03-12;404.03;404.72;401.94;403.89;180310000;403.89
1992-03-11;406.88;407.02;402.64;404.03;186330000;404.03
1992-03-10;405.21;409.16;405.21;406.89;203000000;406.89
1992-03-09;404.45;405.64;404.25;405.21;160650000;405.21
1992-03-06;406.51;407.51;403.65;404.44;185190000;404.44
1992-03-05;409.33;409.33;405.42;406.51;205770000;406.51
1992-03-04;412.86;413.27;409.33;409.33;206860000;409.33
1992-03-03;412.45;413.78;411.88;412.85;200890000;412.85
1992-03-02;412.68;413.74;411.52;412.45;180380000;412.45
1992-02-28;413.86;416.07;411.80;412.70;202320000;412.70
1992-02-27;415.35;415.99;413.47;413.86;215110000;413.86
1992-02-26;410.48;415.35;410.48;415.35;241500000;415.35
1992-02-25;412.27;412.27;408.02;410.45;210350000;410.45
1992-02-24;411.46;412.94;410.34;412.27;177540000;412.27
1992-02-21;413.90;414.26;409.72;411.43;261650000;411.43
1992-02-20;408.26;413.90;408.26;413.90;270650000;413.90
1992-02-19;407.38;408.70;406.54;408.26;232970000;408.26
1992-02-18;412.48;413.27;406.34;407.38;234300000;407.38
1992-02-14;413.69;413.84;411.20;412.48;215110000;412.48
1992-02-13;417.13;417.77;412.07;413.69;229360000;413.69
1992-02-12;413.77;418.08;413.36;417.13;237630000;417.13
1992-02-11;413.77;414.38;412.24;413.76;200130000;413.76
1992-02-10;411.07;413.77;411.07;413.77;184410000;413.77
1992-02-07;413.82;415.29;408.04;411.09;231120000;411.09
1992-02-06;413.87;414.55;411.93;413.82;242050000;413.82
1992-02-05;413.88;416.17;413.18;413.84;262440000;413.84
1992-02-04;409.60;413.85;409.28;413.85;233680000;413.85
1992-02-03;408.79;409.95;407.45;409.53;185290000;409.53
1992-01-31;411.65;412.63;408.64;408.78;197620000;408.78
1992-01-30;410.34;412.17;409.26;411.62;194680000;411.62
1992-01-29;414.96;417.83;409.17;410.34;248940000;410.34
1992-01-28;414.98;416.41;414.54;414.96;218400000;414.96
1992-01-27;415.44;416.84;414.48;414.99;190970000;414.99
1992-01-24;414.96;417.27;414.29;415.48;213630000;415.48
1992-01-23;418.13;419.78;414.36;414.96;234580000;414.96
1992-01-22;412.65;418.13;412.49;418.13;228140000;418.13
1992-01-21;416.36;416.39;411.32;412.64;218750000;412.64
1992-01-20;418.86;418.86;415.80;416.36;180900000;416.36
1992-01-17;418.20;419.45;416.00;418.86;287370000;418.86
1992-01-16;420.77;420.85;415.37;418.21;336240000;418.21
1992-01-15;420.45;421.18;418.79;420.77;314830000;420.77
1992-01-14;414.34;420.44;414.32;420.44;265900000;420.44
1992-01-13;415.05;415.36;413.54;414.34;200270000;414.34
1992-01-10;417.62;417.62;413.31;415.10;236130000;415.10
1992-01-09;418.09;420.50;415.85;417.61;292350000;417.61
1992-01-08;417.36;420.23;415.02;418.10;290750000;418.10
1992-01-07;417.96;417.96;415.20;417.40;252780000;417.40
1992-01-06;419.31;419.44;416.92;417.96;251210000;417.96
1992-01-03;417.27;419.79;416.16;419.34;224270000;419.34
1992-01-02;417.03;417.27;411.04;417.26;207570000;417.26
1991-12-31;415.14;418.32;412.73;417.09;247080000;417.09
1991-12-30;406.49;415.14;406.49;415.14;245600000;415.14
1991-12-27;404.84;406.58;404.59;406.46;157950000;406.46
1991-12-26;399.33;404.92;399.31;404.84;149230000;404.84
1991-12-24;396.82;401.79;396.82;399.33;162640000;399.33
1991-12-23;387.05;397.44;386.96;396.82;228900000;396.82
1991-12-20;382.52;388.24;382.52;387.04;316140000;387.04
1991-12-19;383.46;383.46;380.64;382.52;199330000;382.52
1991-12-18;382.74;383.51;380.88;383.48;192410000;383.48
1991-12-17;384.46;385.05;382.60;382.74;191310000;382.74
1991-12-16;384.48;385.84;384.37;384.46;173080000;384.46
1991-12-13;381.55;385.04;381.55;384.47;194470000;384.47
1991-12-12;377.70;381.62;377.70;381.55;192950000;381.55
1991-12-11;377.90;379.42;374.78;377.70;207430000;377.70
1991-12-10;378.26;379.57;376.64;377.90;192920000;377.90
1991-12-09;379.09;381.42;377.67;378.26;174760000;378.26
1991-12-06;377.39;382.39;375.41;379.10;199160000;379.10
1991-12-05;380.07;380.07;376.58;377.39;166350000;377.39
1991-12-04;380.96;381.51;378.07;380.07;187960000;380.07
1991-12-03;381.40;381.48;379.92;380.96;187230000;380.96
1991-12-02;375.11;381.40;371.36;381.40;188410000;381.40
1991-11-29;376.55;376.55;374.65;375.22;76830000;375.22
1991-11-27;377.96;378.11;375.98;376.55;167720000;376.55
1991-11-26;375.34;378.29;371.63;377.96;213810000;377.96
1991-11-25;376.14;377.07;374.00;375.34;175870000;375.34
1991-11-22;380.05;380.05;374.52;376.14;188240000;376.14
1991-11-21;378.53;381.12;377.41;380.06;195130000;380.06
1991-11-20;379.42;381.51;377.84;378.53;192760000;378.53
1991-11-19;385.24;385.24;374.90;379.42;243880000;379.42
1991-11-18;382.62;385.40;379.70;385.24;241940000;385.24
1991-11-15;397.15;397.16;382.62;382.62;239690000;382.62
1991-11-14;397.41;398.22;395.85;397.15;200030000;397.15
1991-11-13;396.74;397.42;394.01;397.41;184480000;397.41
1991-11-12;393.12;397.13;393.12;396.74;198610000;396.74
1991-11-11;392.90;393.57;392.32;393.12;128920000;393.12
1991-11-08;393.72;396.43;392.42;392.89;183260000;392.89
1991-11-07;389.97;393.72;389.97;393.72;205480000;393.72
1991-11-06;388.71;389.97;387.58;389.97;167440000;389.97
1991-11-05;390.28;392.17;388.19;388.71;172090000;388.71
1991-11-04;391.29;391.29;388.09;390.28;155660000;390.28
1991-11-01;392.46;395.10;389.67;391.32;205780000;391.32
1991-10-31;392.96;392.96;391.58;392.45;179680000;392.45
1991-10-30;391.48;393.11;390.78;392.96;195400000;392.96
1991-10-29;389.52;391.70;386.88;391.48;192810000;391.48
1991-10-28;384.20;389.52;384.20;389.52;161630000;389.52
1991-10-25;385.07;386.13;382.97;384.20;167310000;384.20
1991-10-24;387.94;388.32;383.45;385.07;179040000;385.07
1991-10-23;387.83;389.08;386.52;387.94;185390000;387.94
1991-10-22;390.02;391.20;387.40;387.83;194160000;387.83
1991-10-21;392.49;392.49;388.96;390.02;154140000;390.02
1991-10-18;391.92;392.80;391.77;392.50;204090000;392.50
1991-10-17;392.79;393.81;390.32;391.92;206030000;391.92
1991-10-16;391.01;393.29;390.14;392.80;225380000;392.80
1991-10-15;386.47;391.50;385.95;391.01;213540000;391.01
1991-10-14;381.45;386.47;381.45;386.47;130120000;386.47
1991-10-11;380.55;381.46;379.90;381.45;148850000;381.45
1991-10-10;376.80;380.55;376.11;380.55;164240000;380.55
1991-10-09;380.57;380.57;376.35;376.80;186710000;376.80
1991-10-08;379.50;381.23;379.18;380.67;177120000;380.67
1991-10-07;381.22;381.27;379.07;379.50;148430000;379.50
1991-10-04;384.47;385.19;381.24;381.25;164000000;381.25
1991-10-03;388.23;388.23;384.47;384.47;174360000;384.47
1991-10-02;389.20;390.03;387.62;388.26;166380000;388.26
1991-10-01;387.86;389.56;387.86;389.20;163570000;389.20
1991-09-30;385.91;388.29;384.32;387.86;146780000;387.86
1991-09-27;386.49;389.09;384.87;385.90;160660000;385.90
1991-09-26;386.87;388.39;385.30;386.49;158980000;386.49
1991-09-25;387.72;388.25;385.99;386.88;153910000;386.88
1991-09-24;385.92;388.13;384.46;387.71;170350000;387.71
1991-09-23;387.90;388.55;385.76;385.92;145940000;385.92
1991-09-20;387.56;388.82;386.49;387.92;254520000;387.92
1991-09-19;386.94;389.42;386.27;387.56;211010000;387.56
1991-09-18;385.49;386.94;384.28;386.94;141340000;386.94
1991-09-17;385.78;387.13;384.97;385.50;168340000;385.50
1991-09-16;383.59;385.79;382.77;385.78;172560000;385.78
1991-09-13;387.16;387.95;382.85;383.59;169630000;383.59
1991-09-12;385.09;387.34;385.09;387.34;160420000;387.34
1991-09-11;384.56;385.60;383.59;385.09;148000000;385.09
1991-09-10;388.57;388.63;383.78;384.56;143390000;384.56
1991-09-09;389.11;389.34;387.88;388.57;115100000;388.57
1991-09-06;389.14;390.71;387.36;389.10;166560000;389.10
1991-09-05;389.97;390.97;388.49;389.14;162380000;389.14
1991-09-04;392.15;392.62;388.68;389.97;157520000;389.97
1991-09-03;395.43;397.62;392.10;392.15;153600000;392.15
1991-08-30;396.47;396.47;393.60;395.43;143440000;395.43
1991-08-29;396.65;396.82;395.14;396.47;154150000;396.47
1991-08-28;393.06;396.64;393.05;396.64;169890000;396.64
1991-08-27;393.85;393.87;391.77;393.06;144670000;393.06
1991-08-26;394.17;394.39;392.75;393.85;130570000;393.85
1991-08-23;391.33;395.34;390.69;394.17;188870000;394.17
1991-08-22;390.59;391.98;390.21;391.33;173090000;391.33
1991-08-21;379.55;390.59;379.55;390.59;232690000;390.59
1991-08-20;376.47;380.35;376.47;379.43;184260000;379.43
1991-08-19;385.58;385.58;374.09;376.47;230350000;376.47
1991-08-16;389.33;390.41;383.16;385.58;189480000;385.58
1991-08-15;389.91;391.92;389.29;389.33;174690000;389.33
1991-08-14;389.62;391.85;389.13;389.90;124230000;389.90
1991-08-13;388.02;392.12;388.02;389.62;212760000;389.62
1991-08-12;387.11;388.17;385.90;388.02;145440000;388.02
1991-08-09;389.32;389.89;387.04;387.12;143740000;387.12
1991-08-08;390.56;391.80;388.15;389.32;163890000;389.32
1991-08-07;390.62;391.59;389.86;390.56;172220000;390.56
1991-08-06;385.06;390.80;384.29;390.62;174460000;390.62
1991-08-05;387.17;387.17;384.48;385.06;128050000;385.06
1991-08-02;387.12;389.56;386.05;387.18;162270000;387.18
1991-08-01;387.81;387.95;386.48;387.12;170610000;387.12
1991-07-31;386.69;387.81;386.19;387.81;166830000;387.81
1991-07-30;383.15;386.92;383.15;386.69;169010000;386.69
1991-07-29;380.93;383.15;380.45;383.15;136000000;383.15
1991-07-26;380.96;381.76;379.81;380.93;127760000;380.93
1991-07-25;378.64;381.13;378.15;380.96;145800000;380.96
1991-07-24;379.42;380.46;378.29;378.64;158700000;378.64
1991-07-23;382.88;384.86;379.39;379.42;160190000;379.42
1991-07-22;384.21;384.55;381.84;382.88;149050000;382.88
1991-07-19;385.38;385.83;383.65;384.22;190700000;384.22
1991-07-18;381.18;385.37;381.18;385.37;200930000;385.37
1991-07-17;381.50;382.86;381.13;381.18;195460000;381.18
1991-07-16;382.39;382.94;380.80;381.54;182990000;381.54
1991-07-15;380.28;383.00;380.24;382.39;161750000;382.39
1991-07-12;376.97;381.41;375.79;380.25;174770000;380.25
1991-07-11;375.73;377.68;375.51;376.97;157930000;376.97
1991-07-10;376.11;380.35;375.20;375.74;178290000;375.74
1991-07-09;377.94;378.58;375.37;376.11;151820000;376.11
1991-07-08;374.09;377.94;370.92;377.94;138330000;377.94
1991-07-05;373.34;375.51;372.17;374.08;69910000;374.08
1991-07-03;377.47;377.47;372.08;373.33;140580000;373.33
1991-07-02;377.92;377.93;376.62;377.47;157290000;377.47
1991-07-01;371.18;377.92;371.18;377.92;167480000;377.92
1991-06-28;374.40;374.40;367.98;371.16;163770000;371.16
1991-06-27;371.59;374.40;371.59;374.40;163080000;374.40
1991-06-26;370.65;372.73;368.34;371.59;187170000;371.59
1991-06-25;370.94;372.62;369.56;370.65;155710000;370.65
1991-06-24;377.74;377.74;370.73;370.94;137940000;370.94
1991-06-21;375.42;377.75;375.33;377.75;193310000;377.75
1991-06-20;375.09;376.29;373.87;375.42;163980000;375.42
1991-06-19;378.57;378.57;374.36;375.09;156440000;375.09
1991-06-18;380.13;381.83;377.99;378.59;155200000;378.59
1991-06-17;382.30;382.31;380.13;380.13;134230000;380.13
1991-06-14;377.63;382.30;377.63;382.29;167950000;382.29
1991-06-13;376.65;377.90;376.08;377.63;145650000;377.63
1991-06-12;381.05;381.05;374.46;376.65;166140000;376.65
1991-06-11;378.57;381.63;378.57;381.05;161610000;381.05
1991-06-10;379.43;379.75;377.95;378.57;127720000;378.57
1991-06-07;383.63;383.63;378.76;379.43;169570000;379.43
1991-06-06;385.10;385.85;383.13;383.63;168260000;383.63
1991-06-05;387.74;388.23;384.45;385.09;186560000;385.09
1991-06-04;388.06;388.06;385.14;387.74;180450000;387.74
1991-06-03;389.81;389.81;386.97;388.06;173990000;388.06
1991-05-31;386.96;389.85;385.01;389.83;232040000;389.83
1991-05-30;382.79;388.17;382.50;386.96;234440000;386.96
1991-05-29;381.94;383.66;381.37;382.79;188450000;382.79
1991-05-28;377.49;382.10;377.12;381.94;162350000;381.94
1991-05-24;374.97;378.08;374.97;377.49;124640000;377.49
1991-05-23;376.19;378.07;373.55;374.96;173080000;374.96
1991-05-22;375.35;376.50;374.40;376.19;159310000;376.19
1991-05-21;372.28;376.66;372.28;375.35;176620000;375.35
1991-05-20;372.39;373.65;371.26;372.28;109510000;372.28
1991-05-17;372.19;373.01;369.44;372.39;174210000;372.39
1991-05-16;368.57;372.51;368.57;372.19;154460000;372.19
1991-05-15;371.55;372.47;365.83;368.57;193110000;368.57
1991-05-14;375.51;375.53;370.82;371.62;207890000;371.62
1991-05-13;375.74;377.02;374.62;376.76;129620000;376.76
1991-05-10;383.26;383.91;375.61;375.74;172730000;375.74
1991-05-09;378.51;383.56;378.51;383.25;180460000;383.25
1991-05-08;377.33;379.26;376.21;378.51;157240000;378.51
1991-05-07;380.08;380.91;377.31;377.32;153290000;377.32
1991-05-06;380.78;380.78;377.86;380.08;129110000;380.08
1991-05-03;380.52;381.00;378.82;380.80;158150000;380.80
1991-05-02;380.29;382.14;379.82;380.52;187090000;380.52
1991-05-01;375.35;380.46;375.27;380.29;181900000;380.29
1991-04-30;373.66;377.86;373.01;375.34;206230000;375.34
1991-04-29;379.01;380.96;373.66;373.66;149860000;373.66
1991-04-26;379.25;380.11;376.77;379.02;154550000;379.02
1991-04-25;382.89;382.89;378.43;379.25;166940000;379.25
1991-04-24;381.76;383.02;379.99;382.76;166800000;382.76
1991-04-23;380.95;383.55;379.67;381.76;167840000;381.76
1991-04-22;384.19;384.19;380.16;380.95;164410000;380.95
1991-04-19;388.46;388.46;383.90;384.20;195520000;384.20
1991-04-18;390.45;390.97;388.13;388.46;217410000;388.46
1991-04-17;387.62;391.26;387.30;390.45;246930000;390.45
1991-04-16;381.19;387.62;379.64;387.62;214480000;387.62
1991-04-15;380.40;382.32;378.78;381.19;161800000;381.19
1991-04-12;377.65;381.07;376.89;380.40;198610000;380.40
1991-04-11;373.15;379.53;373.15;377.63;196570000;377.63
1991-04-10;373.57;374.83;371.21;373.15;167940000;373.15
1991-04-09;378.65;379.02;373.11;373.56;169940000;373.56
1991-04-08;375.35;378.76;374.69;378.66;138580000;378.66
1991-04-05;379.78;381.12;374.15;375.36;187410000;375.36
1991-04-04;378.94;381.88;377.05;379.77;198120000;379.77
1991-04-03;379.50;381.56;378.49;378.94;213720000;378.94
1991-04-02;371.30;379.50;371.30;379.50;189530000;379.50
1991-04-01;375.22;375.22;370.27;371.30;144010000;371.30
1991-03-28;375.35;376.60;374.40;375.22;150750000;375.22
1991-03-27;376.28;378.48;374.73;375.35;201830000;375.35
1991-03-26;369.83;376.30;369.37;376.30;198720000;376.30
1991-03-25;367.48;371.31;367.46;369.83;153920000;369.83
1991-03-22;366.58;368.22;365.58;367.48;160890000;367.48
1991-03-21;367.94;371.01;366.51;366.58;199830000;366.58
1991-03-20;366.59;368.85;365.80;367.92;196810000;367.92
1991-03-19;372.11;372.11;366.54;366.59;177070000;366.59
1991-03-18;373.59;374.09;369.46;372.11;163100000;372.11
1991-03-15;373.50;374.58;370.21;373.59;237650000;373.59
1991-03-14;374.59;378.28;371.76;373.50;232070000;373.50
1991-03-13;370.03;374.65;370.03;374.57;176000000;374.57
1991-03-12;372.96;374.35;369.55;370.03;176440000;370.03
1991-03-11;374.94;375.10;372.52;372.96;161600000;372.96
1991-03-08;375.91;378.69;374.43;374.95;206850000;374.95
1991-03-07;376.16;377.49;375.58;375.91;197060000;375.91
1991-03-06;376.72;379.66;375.02;376.17;262290000;376.17
1991-03-05;369.33;377.89;369.33;376.72;253700000;376.72
1991-03-04;370.47;371.99;369.07;369.33;199830000;369.33
1991-03-01;367.07;370.47;363.73;370.47;221510000;370.47
1991-02-28;367.73;369.91;365.95;367.07;223010000;367.07
1991-02-27;362.81;368.38;362.81;367.74;211410000;367.74
1991-02-26;367.26;367.26;362.19;362.81;164170000;362.81
1991-02-25;365.65;370.19;365.16;367.26;193820000;367.26
1991-02-22;364.97;370.96;364.23;365.65;218760000;365.65
1991-02-21;365.14;366.79;364.50;364.97;180770000;364.97
1991-02-20;369.37;369.37;364.38;365.14;185680000;365.14
1991-02-19;369.06;370.11;367.05;369.39;189900000;369.39
1991-02-15;364.23;369.49;364.23;369.06;228480000;369.06
1991-02-14;369.02;370.26;362.77;364.22;230750000;364.22
1991-02-13;365.50;369.49;364.64;369.02;209960000;369.02
1991-02-12;368.58;370.54;365.50;365.50;256160000;365.50
1991-02-11;359.36;368.58;359.32;368.58;265350000;368.58
1991-02-08;356.52;359.35;356.02;359.35;187830000;359.35
1991-02-07;358.07;363.43;355.53;356.52;292190000;356.52
1991-02-06;351.26;358.07;349.58;358.07;276940000;358.07
1991-02-05;348.34;351.84;347.21;351.26;290570000;351.26
1991-02-04;343.05;348.71;342.96;348.34;250750000;348.34
1991-02-01;343.91;344.90;340.37;343.05;246670000;343.05
1991-01-31;340.92;343.93;340.47;343.93;204520000;343.93
1991-01-30;335.80;340.91;335.71;340.91;226790000;340.91
1991-01-29;336.03;336.03;334.26;335.84;155740000;335.84
1991-01-28;336.06;337.41;335.81;336.03;141270000;336.03
1991-01-25;334.78;336.92;334.20;336.07;194350000;336.07
1991-01-24;330.21;335.83;330.19;334.78;223150000;334.78
1991-01-23;328.30;331.04;327.93;330.21;168620000;330.21
1991-01-22;331.06;331.26;327.83;328.31;177060000;328.31
1991-01-21;332.23;332.23;328.87;331.06;136290000;331.06
1991-01-18;327.93;332.23;327.08;332.23;226770000;332.23
1991-01-17;316.25;327.97;316.25;327.97;319080000;327.97
1991-01-16;313.73;316.94;312.94;316.17;134560000;316.17
1991-01-15;312.49;313.73;311.84;313.73;110000000;313.73
1991-01-14;315.23;315.23;309.35;312.49;120830000;312.49
1991-01-11;314.53;315.24;313.59;315.23;123050000;315.23
1991-01-10;311.51;314.77;311.51;314.53;124510000;314.53
1991-01-09;314.90;320.73;310.93;311.49;191100000;311.49
1991-01-08;315.44;316.97;313.79;314.90;143390000;314.90
1991-01-07;320.97;320.97;315.44;315.44;130610000;315.44
1991-01-04;321.91;322.35;318.87;321.00;140820000;321.00
1991-01-03;326.46;326.53;321.90;321.91;141450000;321.91
1991-01-02;330.20;330.75;326.45;326.45;126280000;326.45
1990-12-31;328.71;330.23;327.50;330.22;114130000;330.22
1990-12-28;328.29;328.72;327.24;328.72;111030000;328.72
1990-12-27;330.85;331.04;328.23;328.29;102900000;328.29
1990-12-26;329.89;331.69;329.89;330.85;78730000;330.85
1990-12-24;331.74;331.74;329.16;329.90;57200000;329.90
1990-12-21;330.12;332.47;330.12;331.75;233400000;331.75
1990-12-20;330.20;330.74;326.94;330.12;174700000;330.12
1990-12-19;330.04;330.80;329.39;330.20;180380000;330.20
1990-12-18;326.02;330.43;325.75;330.05;176460000;330.05
1990-12-17;326.82;326.82;324.46;326.02;118560000;326.02
1990-12-14;329.34;329.34;325.16;326.82;151010000;326.82
1990-12-13;330.14;330.58;328.77;329.34;162110000;329.34
1990-12-12;326.44;330.36;326.44;330.19;182270000;330.19
1990-12-11;328.88;328.88;325.65;326.44;145330000;326.44
1990-12-10;327.75;328.97;326.15;328.89;138650000;328.89
1990-12-07;329.09;329.39;326.39;327.75;164950000;327.75
1990-12-06;329.94;333.98;328.37;329.07;256380000;329.07
1990-12-05;326.36;329.92;325.66;329.92;205820000;329.92
1990-12-04;324.11;326.77;321.97;326.35;185820000;326.35
1990-12-03;322.23;324.90;322.23;324.10;177000000;324.10
1990-11-30;316.42;323.02;315.42;322.22;192350000;322.22
1990-11-29;317.95;317.95;315.03;316.42;140920000;316.42
1990-11-28;318.11;319.96;317.62;317.95;145490000;317.95
1990-11-27;316.51;318.69;315.80;318.10;147590000;318.10
1990-11-26;315.08;316.51;311.48;316.51;131540000;316.51
1990-11-23;316.03;317.30;315.06;315.10;63350000;315.10
1990-11-21;315.31;316.15;312.42;316.03;140660000;316.03
1990-11-20;319.34;319.34;315.31;315.31;161170000;315.31
1990-11-19;317.15;319.39;317.15;319.34;140950000;319.34
1990-11-16;317.02;318.80;314.99;317.12;165440000;317.12
1990-11-15;320.40;320.40;316.13;317.02;151370000;317.02
1990-11-14;317.66;321.70;317.23;320.40;179310000;320.40
1990-11-13;319.48;319.48;317.26;317.67;160240000;317.67
1990-11-12;313.74;319.77;313.73;319.48;161390000;319.48
1990-11-09;307.61;313.78;307.61;313.74;145160000;313.74
1990-11-08;306.01;309.77;305.03;307.61;155570000;307.61
1990-11-07;311.62;311.62;305.79;306.01;149130000;306.01
1990-11-06;314.59;314.76;311.43;311.62;142660000;311.62
1990-11-05;311.85;314.61;311.41;314.59;147510000;314.59
1990-11-02;307.02;311.94;306.88;311.85;168700000;311.85
1990-11-01;303.99;307.27;301.61;307.02;159270000;307.02
1990-10-31;304.06;305.70;302.33;304.00;156060000;304.00
1990-10-30;301.88;304.36;299.44;304.06;153450000;304.06
1990-10-29;304.74;307.41;300.69;301.88;133980000;301.88
1990-10-26;310.17;310.17;304.71;304.71;130190000;304.71
1990-10-25;312.60;313.71;309.70;310.17;141460000;310.17
1990-10-24;312.36;313.51;310.74;312.60;149290000;312.60
1990-10-23;314.76;315.06;312.06;312.36;146300000;312.36
1990-10-22;312.48;315.83;310.47;314.76;152650000;314.76
1990-10-19;305.74;312.48;305.74;312.48;221480000;312.48
1990-10-18;298.75;305.74;298.75;305.74;204110000;305.74
1990-10-17;298.92;301.50;297.79;298.76;161260000;298.76
1990-10-16;303.23;304.34;298.12;298.92;149570000;298.92
1990-10-15;300.03;304.79;296.41;303.23;164980000;303.23
1990-10-12;295.45;301.68;295.22;300.03;187940000;300.03
1990-10-11;300.39;301.45;294.51;295.46;180060000;295.46
1990-10-10;305.09;306.43;299.21;300.39;169190000;300.39
1990-10-09;313.46;313.46;305.09;305.10;145610000;305.10
1990-10-08;311.50;315.03;311.50;313.48;99470000;313.48
1990-10-05;312.69;314.79;305.76;311.50;153380000;311.50
1990-10-04;311.40;313.40;308.59;312.69;145410000;312.69
1990-10-03;315.21;316.26;310.70;311.40;135490000;311.40
1990-10-02;314.94;319.69;314.94;315.21;188360000;315.21
1990-10-01;306.10;314.94;306.10;314.94;202210000;314.94
1990-09-28;300.97;306.05;295.98;306.05;201010000;306.05
1990-09-27;305.06;307.47;299.10;300.97;182690000;300.97
1990-09-26;308.26;308.28;303.05;305.06;155570000;305.06
1990-09-25;305.46;308.27;304.23;308.26;155940000;308.26
1990-09-24;311.30;311.30;303.58;304.59;164070000;304.59
1990-09-21;311.53;312.17;307.98;311.32;201050000;311.32
1990-09-20;316.60;316.60;310.55;311.48;145100000;311.48
1990-09-19;318.60;319.35;316.25;316.60;147530000;316.60
1990-09-18;317.77;318.85;314.27;318.60;141130000;318.60
1990-09-17;316.83;318.05;315.21;317.77;110600000;317.77
1990-09-14;318.65;318.65;314.76;316.83;133390000;316.83
1990-09-13;322.51;322.51;318.02;318.65;123390000;318.65
1990-09-12;321.04;322.55;319.60;322.54;129890000;322.54
1990-09-11;321.63;322.18;319.60;321.04;113220000;321.04
1990-09-10;323.42;326.53;320.31;321.63;119730000;321.63
1990-09-07;320.46;324.18;319.71;323.40;123800000;323.40
1990-09-06;324.39;324.39;319.37;320.46;125620000;320.46
1990-09-05;323.09;324.52;320.99;324.39;120610000;324.39
1990-09-04;322.56;323.09;319.11;323.09;92940000;323.09
1990-08-31;318.71;322.57;316.59;322.56;96480000;322.56
1990-08-30;324.19;324.57;317.82;318.71;120890000;318.71
1990-08-29;321.34;325.83;320.87;324.19;134240000;324.19
1990-08-28;321.44;322.20;320.25;321.34;127660000;321.34
1990-08-27;311.55;323.11;311.55;321.44;160150000;321.44
1990-08-24;307.06;311.65;306.18;311.51;199040000;311.51
1990-08-23;316.55;316.55;306.56;307.06;250440000;307.06
1990-08-22;321.86;324.15;316.55;316.55;175550000;316.55
1990-08-21;328.51;328.51;318.78;321.86;194630000;321.86
1990-08-20;327.83;329.90;327.07;328.51;129630000;328.51
1990-08-17;332.36;332.36;324.63;327.83;212560000;327.83
1990-08-16;340.06;340.06;332.39;332.39;138850000;332.39
1990-08-15;339.39;341.92;339.38;340.06;136710000;340.06
1990-08-14;338.84;340.96;337.19;339.39;130320000;339.39
1990-08-13;335.39;338.88;332.02;338.84;122820000;338.84
1990-08-10;339.90;339.90;334.22;335.52;145340000;335.52
1990-08-09;338.35;340.56;337.56;339.94;155810000;339.94
1990-08-08;334.83;339.21;334.83;338.35;190400000;338.35
1990-08-07;334.43;338.63;332.22;334.83;231580000;334.83
1990-08-06;344.86;344.86;333.27;334.43;240400000;334.43
1990-08-03;351.48;351.48;338.20;344.86;295880000;344.86
1990-08-02;355.52;355.52;349.73;351.48;253090000;351.48
1990-08-01;356.15;357.35;353.82;355.52;178260000;355.52
1990-07-31;355.55;357.54;353.91;356.15;175380000;356.15
1990-07-30;353.44;355.55;351.15;355.55;146470000;355.55
1990-07-27;355.90;355.94;352.14;353.44;149070000;353.44
1990-07-26;357.09;357.47;353.95;355.91;155040000;355.91
1990-07-25;355.79;357.52;354.80;357.09;163530000;357.09
1990-07-24;355.31;356.09;351.46;355.79;181920000;355.79
1990-07-23;361.61;361.61;350.09;355.31;209030000;355.31
1990-07-20;365.32;366.64;361.58;361.61;177810000;361.61
1990-07-19;364.22;365.32;361.29;365.32;161990000;365.32
1990-07-18;367.52;367.52;362.95;364.22;168760000;364.22
1990-07-17;368.95;369.40;364.99;367.52;176790000;367.52
1990-07-16;367.31;369.78;367.31;368.95;149430000;368.95
1990-07-13;365.45;369.68;365.45;367.31;215600000;367.31
1990-07-12;361.23;365.46;360.57;365.44;213180000;365.44
1990-07-11;356.49;361.23;356.49;361.23;162220000;361.23
1990-07-10;359.52;359.74;356.41;356.49;147630000;356.49
1990-07-09;358.42;360.05;358.11;359.52;119390000;359.52
1990-07-06;355.69;359.02;354.64;358.42;111730000;358.42
1990-07-05;360.16;360.16;354.86;355.68;128320000;355.68
1990-07-03;359.54;360.73;359.44;360.16;130050000;360.16
1990-07-02;358.02;359.58;357.54;359.54;130200000;359.54
1990-06-29;357.64;359.09;357.30;358.02;145510000;358.02
1990-06-28;355.16;357.63;355.16;357.63;136120000;357.63
1990-06-27;352.06;355.89;351.23;355.14;146620000;355.14
1990-06-26;352.32;356.09;351.85;352.06;141420000;352.06
1990-06-25;355.42;356.41;351.91;352.31;133100000;352.31
1990-06-22;360.52;363.20;355.31;355.43;172570000;355.43
1990-06-21;359.10;360.88;357.63;360.47;138570000;360.47
1990-06-20;358.47;359.91;357.00;359.10;137420000;359.10
1990-06-19;356.88;358.90;356.18;358.47;134930000;358.47
1990-06-18;362.91;362.91;356.88;356.88;133470000;356.88
1990-06-15;362.89;363.14;360.71;362.91;205130000;362.91
1990-06-14;364.90;364.90;361.64;362.90;135770000;362.90
1990-06-13;366.25;367.09;364.51;364.90;158910000;364.90
1990-06-12;361.63;367.27;361.15;366.25;157100000;366.25
1990-06-11;358.71;361.63;357.70;361.63;119550000;361.63
1990-06-08;363.15;363.49;357.68;358.71;142600000;358.71
1990-06-07;365.92;365.92;361.60;363.15;160360000;363.15
1990-06-06;366.64;366.64;364.42;364.96;164030000;364.96
1990-06-05;367.40;368.78;365.49;366.64;199720000;366.64
1990-06-04;363.16;367.85;362.43;367.40;175520000;367.40
1990-06-01;361.26;363.52;361.21;363.16;187860000;363.16
1990-05-31;360.86;361.84;360.23;361.23;165690000;361.23
1990-05-30;360.65;362.26;360.00;360.86;199540000;360.86
1990-05-29;354.58;360.65;354.55;360.65;137410000;360.65
1990-05-25;358.41;358.41;354.32;354.58;120250000;354.58
1990-05-24;359.29;359.56;357.87;358.41;155140000;358.41
1990-05-23;358.43;359.29;356.99;359.29;172330000;359.29
1990-05-22;358.00;360.50;356.09;358.43;203350000;358.43
1990-05-21;354.64;359.07;353.78;358.00;166280000;358.00
1990-05-18;354.47;354.64;352.52;354.64;162520000;354.64
1990-05-17;354.00;356.92;354.00;354.47;164770000;354.47
1990-05-16;354.27;354.68;351.95;354.00;159810000;354.00
1990-05-15;354.75;355.09;352.84;354.28;165730000;354.28
1990-05-14;352.00;358.41;351.95;354.75;225410000;354.75
1990-05-11;343.82;352.31;343.82;352.00;234040000;352.00
1990-05-10;342.87;344.98;342.77;343.82;158460000;343.82
1990-05-09;342.01;343.08;340.90;342.86;152220000;342.86
1990-05-08;340.53;342.03;340.17;342.01;144230000;342.01
1990-05-07;338.39;341.07;338.11;340.53;132760000;340.53
1990-05-04;335.58;338.46;335.17;338.39;140550000;338.39
1990-05-03;334.48;337.02;334.47;335.57;145560000;335.57
1990-05-02;332.25;334.48;332.15;334.48;141610000;334.48
1990-05-01;330.80;332.83;330.80;332.25;149020000;332.25
1990-04-30;329.11;331.31;327.76;330.80;122750000;330.80
1990-04-27;332.92;333.57;328.71;329.11;130630000;329.11
1990-04-26;332.03;333.76;330.67;332.92;141330000;332.92
1990-04-25;330.36;332.74;330.36;332.03;133480000;332.03
1990-04-24;331.05;332.97;329.71;330.36;137360000;330.36
1990-04-23;335.12;335.12;330.09;331.05;136150000;331.05
1990-04-20;338.09;338.52;333.41;335.12;174260000;335.12
1990-04-19;340.72;340.72;337.59;338.09;152930000;338.09
1990-04-18;344.68;345.33;340.11;340.72;147130000;340.72
1990-04-17;344.74;345.19;342.06;344.68;127990000;344.68
1990-04-16;344.34;347.30;344.10;344.74;142810000;344.74
1990-04-12;341.92;344.79;341.91;344.34;142470000;344.34
1990-04-11;342.07;343.00;341.26;341.92;141080000;341.92
1990-04-10;341.37;342.41;340.62;342.07;136020000;342.07
1990-04-09;340.08;341.83;339.88;341.37;114970000;341.37
1990-04-06;340.73;341.73;338.94;340.08;137490000;340.08
1990-04-05;341.09;342.85;340.63;340.73;144170000;340.73
1990-04-04;343.64;344.12;340.40;341.09;159530000;341.09
1990-04-03;338.70;343.76;338.70;343.64;154310000;343.64
1990-04-02;339.94;339.94;336.33;338.70;124360000;338.70
1990-03-30;340.79;341.41;338.21;339.94;139340000;339.94
1990-03-29;342.00;342.07;339.77;340.79;132190000;340.79
1990-03-28;341.50;342.58;340.60;342.00;142300000;342.00
1990-03-27;337.63;341.50;337.03;341.50;131610000;341.50
1990-03-26;337.22;339.74;337.22;337.63;116110000;337.63
1990-03-23;335.69;337.58;335.69;337.22;132070000;337.22
1990-03-22;339.74;339.77;333.62;335.69;175930000;335.69
1990-03-21;341.57;342.34;339.56;339.74;130990000;339.74
1990-03-20;343.53;344.49;340.87;341.57;177320000;341.57
1990-03-19;341.91;343.76;339.12;343.53;142300000;343.53
1990-03-16;338.07;341.91;338.07;341.91;222520000;341.91
1990-03-15;336.87;338.91;336.87;338.07;144410000;338.07
1990-03-14;336.00;337.63;334.93;336.87;145060000;336.87
1990-03-13;338.67;338.67;335.36;336.00;145440000;336.00
1990-03-12;337.93;339.08;336.14;338.67;114790000;338.67
1990-03-09;340.12;340.27;336.84;337.93;150410000;337.93
1990-03-08;336.95;340.66;336.95;340.27;170900000;340.27
1990-03-07;337.93;338.84;336.33;336.95;163580000;336.95
1990-03-06;333.74;337.93;333.57;337.93;143640000;337.93
1990-03-05;335.54;336.38;333.49;333.74;140110000;333.74
1990-03-02;332.74;335.54;332.72;335.54;164330000;335.54
1990-03-01;331.89;334.40;331.08;332.74;157930000;332.74
1990-02-28;330.26;333.48;330.16;331.89;184400000;331.89
1990-02-27;328.68;331.94;328.47;330.26;152590000;330.26
1990-02-26;324.16;328.67;323.98;328.67;148900000;328.67
1990-02-23;325.70;326.15;322.10;324.15;148490000;324.15
1990-02-22;327.67;330.98;325.70;325.70;184320000;325.70
1990-02-21;327.91;328.17;324.47;327.67;159240000;327.67
1990-02-20;332.72;332.72;326.26;327.99;147300000;327.99
1990-02-16;334.89;335.64;332.42;332.72;166840000;332.72
1990-02-15;332.01;335.21;331.61;334.89;174620000;334.89
1990-02-14;331.02;333.20;330.64;332.01;138530000;332.01
1990-02-13;330.08;331.61;327.92;331.02;144490000;331.02
1990-02-12;333.62;333.62;329.97;330.08;118390000;330.08
1990-02-09;333.02;334.60;332.41;333.62;146910000;333.62
1990-02-08;333.75;336.09;332.00;332.96;176240000;332.96
1990-02-07;329.66;333.76;326.55;333.75;186710000;333.75
1990-02-06;331.85;331.86;328.20;329.66;134070000;329.66
1990-02-05;330.92;332.16;330.45;331.85;130950000;331.85
1990-02-02;328.79;332.10;328.09;330.92;164400000;330.92
1990-02-01;329.08;329.86;327.76;328.79;154580000;328.79
1990-01-31;322.98;329.08;322.98;329.08;189660000;329.08
1990-01-30;325.20;325.73;319.83;322.98;186030000;322.98
1990-01-29;325.80;327.31;321.79;325.20;150770000;325.20
1990-01-26;326.09;328.58;321.44;325.80;198190000;325.80
1990-01-25;330.26;332.33;325.33;326.08;172270000;326.08
1990-01-24;331.61;331.71;324.17;330.26;207830000;330.26
1990-01-23;330.38;332.76;328.67;331.61;179300000;331.61
1990-01-22;339.14;339.96;330.28;330.38;148380000;330.38
1990-01-19;338.19;340.48;338.19;339.15;185590000;339.15
1990-01-18;337.40;338.38;333.98;338.19;178590000;338.19
1990-01-17;340.77;342.01;336.26;337.40;170470000;337.40
1990-01-16;337.00;340.75;333.37;340.75;186070000;340.75
1990-01-15;339.93;339.94;336.57;337.00;140590000;337.00
1990-01-12;348.53;348.53;339.49;339.93;183880000;339.93
1990-01-11;347.31;350.14;347.31;348.53;154390000;348.53
1990-01-10;349.62;349.62;344.32;347.31;175990000;347.31
1990-01-09;353.83;354.17;349.61;349.62;155210000;349.62
1990-01-08;352.20;354.24;350.54;353.79;140110000;353.79
1990-01-05;355.67;355.67;351.35;352.20;158530000;352.20
1990-01-04;358.76;358.76;352.89;355.67;177000000;355.67
1990-01-03;359.69;360.59;357.89;358.76;192330000;358.76
1990-01-02;353.40;359.69;351.98;359.69;162070000;359.69
1989-12-29;350.68;353.41;350.67;353.40;145940000;353.40
1989-12-28;348.80;350.68;348.76;350.67;128030000;350.67
1989-12-27;346.84;349.12;346.81;348.81;133740000;348.81
1989-12-26;347.42;347.87;346.53;346.81;77610000;346.81
1989-12-22;344.78;347.53;344.76;347.42;120980000;347.42
1989-12-21;342.84;345.03;342.84;344.78;175150000;344.78
1989-12-20;342.50;343.70;341.79;342.84;176520000;342.84
1989-12-19;343.69;343.74;339.63;342.46;186060000;342.46
1989-12-18;350.14;350.88;342.19;343.69;184750000;343.69
1989-12-15;350.97;351.86;346.08;350.14;240390000;350.14
1989-12-14;352.74;352.75;350.08;350.93;178700000;350.93
1989-12-13;351.70;354.10;351.65;352.75;184660000;352.75
1989-12-12;348.56;352.21;348.41;351.73;176820000;351.73
1989-12-11;348.68;348.74;346.39;348.56;147130000;348.56
1989-12-08;347.60;349.60;347.59;348.69;144910000;348.69
1989-12-07;348.55;349.84;346.00;347.59;161980000;347.59
1989-12-06;349.58;349.94;347.91;348.55;145850000;348.55
1989-12-05;351.41;352.24;349.58;349.58;154640000;349.58
1989-12-04;350.63;351.51;350.32;351.41;150360000;351.41
1989-12-01;346.01;351.88;345.99;350.63;199200000;350.63
1989-11-30;343.60;346.50;343.57;345.99;153200000;345.99
1989-11-29;345.77;345.77;343.36;343.60;147270000;343.60
1989-11-28;345.61;346.33;344.41;345.77;153770000;345.77
1989-11-27;343.98;346.24;343.97;345.61;149390000;345.61
1989-11-24;341.92;344.24;341.91;343.97;86290000;343.97
1989-11-22;339.59;341.92;339.59;341.91;145730000;341.91
1989-11-21;339.35;340.21;337.53;339.59;147900000;339.59
1989-11-20;341.61;341.90;338.29;339.35;128170000;339.35
1989-11-17;340.58;342.24;339.85;341.61;151020000;341.61
1989-11-16;340.54;341.02;338.93;340.58;148370000;340.58
1989-11-15;338.00;340.54;337.14;340.54;155130000;340.54
1989-11-14;339.55;340.41;337.06;337.99;143170000;337.99
1989-11-13;339.08;340.51;337.93;339.55;140750000;339.55
1989-11-10;336.57;339.10;336.57;339.10;131800000;339.10
1989-11-09;338.15;338.73;336.21;336.57;143390000;336.57
1989-11-08;334.81;339.41;334.81;338.15;170150000;338.15
1989-11-07;332.61;334.82;330.91;334.81;163000000;334.81
1989-11-06;337.61;337.62;332.33;332.61;135480000;332.61
1989-11-03;338.48;339.67;337.37;337.62;131500000;337.62
1989-11-02;341.20;341.20;336.61;338.48;152440000;338.48
1989-11-01;340.36;341.74;339.79;341.20;154240000;341.20
1989-10-31;335.08;340.86;335.07;340.36;176100000;340.36
1989-10-30;335.06;337.04;334.48;335.07;126630000;335.07
1989-10-27;337.93;337.97;333.26;335.06;170330000;335.06
1989-10-26;342.50;342.50;337.20;337.93;175240000;337.93
1989-10-25;343.70;344.51;341.96;342.50;155650000;342.50
1989-10-24;344.83;344.83;335.13;343.70;237960000;343.70
1989-10-23;347.11;348.19;344.22;344.83;135860000;344.83
1989-10-20;347.04;347.57;344.47;347.16;164830000;347.16
1989-10-19;341.76;348.82;341.76;347.13;198120000;347.13
1989-10-18;341.16;343.39;339.03;341.76;166900000;341.76
1989-10-17;342.84;342.85;335.69;341.16;224070000;341.16
1989-10-16;333.65;342.87;327.12;342.85;416290000;342.85
1989-10-13;355.39;355.53;332.81;333.65;251170000;333.65
1989-10-12;356.99;356.99;354.91;355.39;160120000;355.39
1989-10-11;359.13;359.13;356.08;356.99;164070000;356.99
1989-10-10;359.80;360.44;358.11;359.13;147560000;359.13
1989-10-09;358.76;359.86;358.06;359.80;86810000;359.80
1989-10-06;356.97;359.05;356.97;358.78;172520000;358.78
1989-10-05;356.94;357.63;356.28;356.97;177890000;356.97
1989-10-04;354.71;357.49;354.71;356.94;194590000;356.94
1989-10-03;350.87;354.73;350.85;354.71;182550000;354.71
1989-10-02;349.15;350.99;348.35;350.87;127410000;350.87
1989-09-29;348.60;350.31;348.12;349.15;155300000;349.15
1989-09-28;345.10;348.61;345.10;348.60;164240000;348.60
1989-09-27;344.33;345.47;342.85;345.10;158400000;345.10
1989-09-26;344.23;347.02;344.13;344.33;158350000;344.33
1989-09-25;347.05;347.05;343.70;344.23;121130000;344.23
1989-09-22;345.70;347.57;345.69;347.05;133350000;347.05
1989-09-21;346.47;348.46;344.96;345.70;146930000;345.70
1989-09-20;346.55;347.27;346.18;346.47;136640000;346.47
1989-09-19;346.73;348.17;346.44;346.55;141610000;346.55
1989-09-18;345.06;346.84;344.60;346.73;136940000;346.73
1989-09-15;343.16;345.06;341.37;345.06;234860000;345.06
1989-09-14;345.46;345.61;342.55;343.16;149250000;343.16
1989-09-13;348.70;350.10;345.46;345.46;175330000;345.46
1989-09-12;347.66;349.46;347.50;348.70;142140000;348.70
1989-09-11;348.76;348.76;345.91;347.66;126020000;347.66
1989-09-08;348.35;349.18;345.74;348.76;154090000;348.76
1989-09-07;349.24;350.31;348.15;348.35;160160000;348.35
1989-09-06;352.56;352.56;347.98;349.24;161800000;349.24
1989-09-05;353.73;354.13;351.82;352.56;145180000;352.56
1989-09-01;351.45;353.90;350.88;353.73;133300000;353.73
1989-08-31;350.65;351.45;350.21;351.45;144820000;351.45
1989-08-30;349.84;352.27;348.66;350.65;174350000;350.65
1989-08-29;352.09;352.12;348.86;349.84;175210000;349.84
1989-08-28;350.52;352.09;349.08;352.09;131180000;352.09
1989-08-25;351.52;352.73;350.09;350.52;165930000;350.52
1989-08-24;344.70;351.52;344.70;351.52;225520000;351.52
1989-08-23;341.19;344.80;341.19;344.70;159640000;344.70
1989-08-22;340.67;341.25;339.00;341.19;141930000;341.19
1989-08-21;346.03;346.25;340.55;340.67;136800000;340.67
1989-08-18;344.45;346.03;343.89;346.03;145810000;346.03
1989-08-17;345.66;346.39;342.97;344.45;157560000;344.45
1989-08-16;344.71;346.37;344.71;345.66;150060000;345.66
1989-08-15;343.06;345.03;343.05;344.71;148770000;344.71
1989-08-14;344.71;345.44;341.96;343.06;142010000;343.06
1989-08-11;348.28;351.18;344.01;344.74;197550000;344.74
1989-08-10;346.94;349.78;345.31;348.25;198660000;348.25
1989-08-09;349.30;351.00;346.86;346.94;209900000;346.94
1989-08-08;349.41;349.84;348.28;349.35;200340000;349.35
1989-08-07;343.92;349.42;343.91;349.41;197580000;349.41
1989-08-04;344.74;345.42;342.60;343.92;169750000;343.92
1989-08-03;344.34;345.22;343.81;344.74;168690000;344.74
1989-08-02;343.75;344.34;342.47;344.34;181760000;344.34
1989-08-01;346.08;347.99;342.93;343.75;225280000;343.75
1989-07-31;342.13;346.08;342.02;346.08;166650000;346.08
1989-07-28;341.94;342.96;341.30;342.15;180610000;342.15
1989-07-27;338.05;342.00;338.05;341.99;213680000;341.99
1989-07-26;333.88;338.05;333.19;338.05;188270000;338.05
1989-07-25;333.67;336.29;332.60;333.88;179270000;333.88
1989-07-24;335.90;335.90;333.44;333.67;136260000;333.67
1989-07-21;333.50;335.91;332.46;335.90;174880000;335.90
1989-07-20;335.74;337.40;333.22;333.51;204590000;333.51
1989-07-19;331.37;335.73;331.35;335.73;215740000;335.73
1989-07-18;332.42;332.44;330.75;331.35;152350000;331.35
1989-07-17;331.78;333.02;331.02;332.44;131960000;332.44
1989-07-14;329.96;331.89;327.13;331.84;183480000;331.84
1989-07-13;329.81;330.37;329.08;329.95;153820000;329.95
1989-07-12;328.78;330.39;327.92;329.81;160550000;329.81
1989-07-11;327.07;330.42;327.07;328.78;171590000;328.78
1989-07-10;324.93;327.07;324.91;327.07;131870000;327.07
1989-07-07;321.55;325.87;321.08;324.91;166430000;324.91
1989-07-06;320.64;321.55;320.45;321.55;140450000;321.55
1989-07-05;319.23;321.22;317.26;320.64;127710000;320.64
1989-07-03;317.98;319.27;317.27;319.23;68870000;319.23
1989-06-30;319.67;319.97;314.38;317.98;170490000;317.98
1989-06-29;325.81;325.81;319.54;319.68;167100000;319.68
1989-06-28;328.44;328.44;324.30;325.81;158470000;325.81
1989-06-27;326.60;329.19;326.59;328.44;171090000;328.44
1989-06-26;328.00;328.15;326.31;326.60;143600000;326.60
1989-06-23;322.32;328.00;322.32;328.00;198720000;328.00
1989-06-22;320.48;322.34;320.20;322.32;176510000;322.32
1989-06-21;321.25;321.87;319.25;320.48;168830000;320.48
1989-06-20;321.89;322.78;321.03;321.25;167650000;321.25
1989-06-19;321.35;321.89;320.40;321.89;130720000;321.89
1989-06-16;319.96;321.36;318.69;321.35;244510000;321.35
1989-06-15;323.83;323.83;319.21;320.08;179480000;320.08
1989-06-14;323.91;324.89;322.80;323.83;170540000;323.83
1989-06-13;326.24;326.24;322.96;323.91;164870000;323.91
1989-06-12;326.69;326.69;323.73;326.24;151460000;326.24
1989-06-09;326.75;327.32;325.16;326.69;173240000;326.69
1989-06-08;326.95;327.37;325.92;326.75;212310000;326.75
1989-06-07;324.24;327.39;324.24;326.95;213710000;326.95
1989-06-06;322.03;324.48;321.27;324.24;187570000;324.24
1989-06-05;325.52;325.93;322.02;322.03;163420000;322.03
1989-06-02;321.97;325.63;321.97;325.52;229140000;325.52
1989-06-01;320.51;322.57;320.01;321.97;223160000;321.97
1989-05-31;319.05;321.30;318.68;320.52;162530000;320.52
1989-05-30;321.59;322.53;317.83;319.05;151780000;319.05
1989-05-26;319.17;321.59;319.14;321.59;143120000;321.59
1989-05-25;319.14;319.60;318.42;319.17;154470000;319.17
1989-05-24;318.32;319.14;317.58;319.14;178600000;319.14
1989-05-23;321.98;321.98;318.20;318.32;187690000;318.32
1989-05-22;321.24;323.06;320.45;321.98;185010000;321.98
1989-05-19;317.97;321.38;317.97;321.24;242410000;321.24
1989-05-18;317.48;318.52;316.54;317.97;177480000;317.97
1989-05-17;315.28;317.94;315.11;317.48;191210000;317.48
1989-05-16;316.16;316.16;314.99;315.28;173100000;315.28
1989-05-15;313.84;316.16;313.84;316.16;179350000;316.16
1989-05-12;306.95;313.84;306.95;313.84;221490000;313.84
1989-05-11;305.80;307.34;305.80;306.95;151620000;306.95
1989-05-10;305.19;306.25;304.85;305.80;146000000;305.80
1989-05-09;306.00;306.99;304.06;305.19;150090000;305.19
1989-05-08;307.61;307.61;304.74;306.00;135130000;306.00
1989-05-05;307.77;310.69;306.98;307.61;180810000;307.61
1989-05-04;308.16;308.40;307.32;307.77;153130000;307.77
1989-05-03;308.12;308.52;307.11;308.16;171690000;308.16
1989-05-02;309.13;310.45;308.12;308.12;172560000;308.12
1989-05-01;309.64;309.64;307.40;309.12;138050000;309.12
1989-04-28;309.58;309.65;308.48;309.64;158390000;309.64
1989-04-27;306.93;310.45;306.93;309.58;191170000;309.58
1989-04-26;306.78;307.30;306.07;306.93;146090000;306.93
1989-04-25;308.69;309.65;306.74;306.75;165430000;306.75
1989-04-24;309.61;309.61;307.83;308.69;142100000;308.69
1989-04-21;306.19;309.61;306.19;309.61;187310000;309.61
1989-04-20;307.15;307.96;304.53;306.19;175970000;306.19
1989-04-19;306.02;307.68;305.36;307.15;191510000;307.15
1989-04-18;301.72;306.25;301.72;306.02;208650000;306.02
1989-04-17;301.36;302.01;300.71;301.72;128540000;301.72
1989-04-14;296.40;301.38;296.40;301.36;169780000;301.36
1989-04-13;298.99;299.00;296.27;296.40;141590000;296.40
1989-04-12;298.49;299.81;298.49;298.99;165200000;298.99
1989-04-11;297.11;298.87;297.11;298.49;146830000;298.49
1989-04-10;297.16;297.94;296.85;297.11;123990000;297.11
1989-04-07;295.29;297.62;294.35;297.16;156950000;297.16
1989-04-06;296.22;296.24;294.52;295.29;146530000;295.29
1989-04-05;295.31;296.43;295.28;296.24;165880000;296.24
1989-04-04;296.40;296.40;294.72;295.31;160680000;295.31
1989-04-03;294.87;297.04;294.62;296.39;164660000;296.39
1989-03-31;292.52;294.96;292.52;294.87;170960000;294.87
1989-03-30;292.35;293.80;291.50;292.52;159950000;292.52
1989-03-29;291.59;292.75;291.42;292.35;144240000;292.35
1989-03-28;290.57;292.32;290.57;291.59;146420000;291.59
1989-03-27;288.98;290.57;288.07;290.57;112960000;290.57
1989-03-23;290.49;291.51;288.56;288.98;153750000;288.98
1989-03-22;291.33;291.46;289.90;290.49;146570000;290.49
1989-03-21;289.92;292.38;289.92;291.33;142010000;291.33
1989-03-20;292.69;292.69;288.56;289.92;151260000;289.92
1989-03-17;299.44;299.44;291.08;292.69;242900000;292.69
1989-03-16;296.67;299.99;296.66;299.44;196040000;299.44
1989-03-15;295.14;296.78;295.14;296.67;167070000;296.67
1989-03-14;295.32;296.29;294.63;295.14;139970000;295.14
1989-03-13;292.88;296.18;292.88;295.32;140460000;295.32
1989-03-10;293.93;293.93;291.60;292.88;146830000;292.88
1989-03-09;294.08;294.69;293.85;293.93;143160000;293.93
1989-03-08;293.87;295.62;293.51;294.08;167620000;294.08
1989-03-07;294.81;295.16;293.50;293.87;172500000;293.87
1989-03-06;291.20;294.81;291.18;294.81;168880000;294.81
1989-03-03;289.94;291.18;289.44;291.18;151790000;291.18
1989-03-02;287.11;290.32;287.11;289.95;161980000;289.95
1989-03-01;288.86;290.28;286.46;287.11;177210000;287.11
1989-02-28;287.82;289.42;287.63;288.86;147430000;288.86
1989-02-27;287.13;288.12;286.26;287.82;139900000;287.82
1989-02-24;292.05;292.05;287.13;287.13;160680000;287.13
1989-02-23;290.91;292.05;289.83;292.05;150370000;292.05
1989-02-22;295.98;295.98;290.76;290.91;163140000;290.91
1989-02-21;296.76;297.04;295.16;295.98;141950000;295.98
1989-02-17;294.81;297.12;294.69;296.76;159520000;296.76
1989-02-16;294.24;295.15;294.22;294.81;177450000;294.81
1989-02-15;291.81;294.42;291.49;294.24;154220000;294.24
1989-02-14;292.54;294.37;291.41;291.81;150610000;291.81
1989-02-13;292.02;293.07;290.88;292.54;143520000;292.54
1989-02-10;296.06;296.06;291.96;292.02;173560000;292.02
1989-02-09;298.65;298.79;295.16;296.06;224220000;296.06
1989-02-08;299.62;300.57;298.41;298.65;189420000;298.65
1989-02-07;296.04;300.34;295.78;299.63;217260000;299.63
1989-02-06;296.97;296.99;294.96;296.04;150980000;296.04
1989-02-03;296.84;297.66;296.15;296.97;172980000;296.97
1989-02-02;297.09;297.92;295.81;296.84;183430000;296.84
1989-02-01;297.47;298.33;296.22;297.09;215640000;297.09
1989-01-31;294.99;297.51;293.57;297.47;194050000;297.47
1989-01-30;293.82;295.13;293.54;294.99;167830000;294.99
1989-01-27;291.69;296.08;291.69;293.82;254870000;293.82
1989-01-26;289.14;292.62;288.13;291.69;212250000;291.69
1989-01-25;288.49;289.15;287.97;289.14;183610000;289.14
1989-01-24;284.50;288.49;284.50;288.49;189620000;288.49
1989-01-23;287.85;287.98;284.50;284.50;141640000;284.50
1989-01-20;286.90;287.04;285.75;286.63;166120000;286.63
1989-01-19;286.53;287.90;286.14;286.91;192030000;286.91
1989-01-18;283.55;286.87;282.65;286.53;187450000;286.53
1989-01-17;284.14;284.14;283.06;283.55;143930000;283.55
1989-01-16;283.87;284.88;283.63;284.14;117380000;284.14
1989-01-13;283.17;284.12;282.71;283.87;132320000;283.87
1989-01-12;282.01;284.63;282.01;283.17;183000000;283.17
1989-01-11;280.38;282.01;280.21;282.01;148950000;282.01
1989-01-10;280.98;281.58;279.44;280.38;140420000;280.38
1989-01-09;280.67;281.89;280.32;280.98;163180000;280.98
1989-01-06;280.01;282.06;280.01;280.67;161330000;280.67
1989-01-05;279.43;281.51;279.43;280.01;174040000;280.01
1989-01-04;275.31;279.75;275.31;279.43;149700000;279.43
1989-01-03;277.72;277.72;273.81;275.31;128500000;275.31
1988-12-30;279.39;279.78;277.72;277.72;127210000;277.72
1988-12-29;277.08;279.42;277.08;279.40;131290000;279.40
1988-12-28;276.83;277.55;276.17;277.08;110630000;277.08
1988-12-27;277.87;278.09;276.74;276.83;87490000;276.83
1988-12-23;276.87;277.99;276.87;277.87;81760000;277.87
1988-12-22;277.38;277.89;276.86;276.87;150510000;276.87
1988-12-21;277.47;277.83;276.30;277.38;147250000;277.38
1988-12-20;278.91;280.45;277.47;277.47;161090000;277.47
1988-12-19;276.29;279.31;275.61;278.91;162250000;278.91
1988-12-16;274.28;276.29;274.28;276.29;196480000;276.29
1988-12-15;275.32;275.62;274.01;274.28;136820000;274.28
1988-12-14;276.31;276.31;274.58;275.31;132350000;275.31
1988-12-13;276.52;276.52;274.58;276.31;132340000;276.31
1988-12-12;277.03;278.82;276.52;276.52;124160000;276.52
1988-12-09;276.57;277.82;276.34;277.03;133770000;277.03
1988-12-08;278.13;278.13;276.55;276.59;124150000;276.59
1988-12-07;277.59;279.01;277.34;278.13;148360000;278.13
1988-12-06;274.93;277.89;274.62;277.59;158340000;277.59
1988-12-05;274.93;275.62;271.81;274.93;144660000;274.93
1988-12-02;272.49;272.49;270.47;271.81;124610000;271.81
1988-12-01;273.68;273.70;272.27;272.49;129380000;272.49
1988-11-30;270.91;274.36;270.90;273.70;157810000;273.70
1988-11-29;268.60;271.31;268.13;270.91;127420000;270.91
1988-11-28;267.22;268.98;266.97;268.64;123480000;268.64
1988-11-25;268.99;269.00;266.47;267.23;72090000;267.23
1988-11-23;267.22;269.56;267.21;269.00;112010000;269.00
1988-11-22;266.19;267.85;265.42;267.21;127000000;267.21
1988-11-21;266.35;266.47;263.41;266.22;120430000;266.22
1988-11-18;264.60;266.62;264.60;266.47;119320000;266.47
1988-11-17;264.61;265.63;263.45;264.60;141280000;264.60
1988-11-16;268.41;268.41;262.85;263.82;161710000;263.82
1988-11-15;267.73;268.75;267.72;268.34;115170000;268.34
1988-11-14;267.93;269.25;266.79;267.72;142900000;267.72
1988-11-11;273.65;273.69;267.92;267.92;135500000;267.92
1988-11-10;273.32;274.37;272.98;273.69;128920000;273.69
1988-11-09;275.14;275.15;272.15;273.33;153140000;273.33
1988-11-08;273.95;275.80;273.93;275.15;141660000;275.15
1988-11-07;276.30;276.31;273.62;273.93;133870000;273.93
1988-11-04;279.11;279.20;276.31;276.31;143580000;276.31
1988-11-03;279.04;280.37;279.04;279.20;152980000;279.20
1988-11-02;279.07;279.45;277.08;279.06;161300000;279.06
1988-11-01;278.97;279.57;278.01;279.06;151250000;279.06
1988-10-31;278.54;279.39;277.14;278.97;143460000;278.97
1988-10-28;277.29;279.48;277.28;278.53;146300000;278.53
1988-10-27;281.35;281.38;276.00;277.28;196540000;277.28
1988-10-26;282.37;282.52;280.54;281.38;181550000;281.38
1988-10-25;282.28;282.84;281.87;282.38;155190000;282.38
1988-10-24;283.63;283.95;282.28;282.28;170590000;282.28
1988-10-21;282.88;283.66;281.16;283.66;195410000;283.66
1988-10-20;276.97;282.88;276.93;282.88;189580000;282.88
1988-10-19;279.40;280.53;274.41;276.97;186350000;276.97
1988-10-18;276.43;279.39;276.41;279.38;162500000;279.38
1988-10-17;275.48;276.65;275.01;276.41;119290000;276.41
1988-10-14;275.27;277.01;274.08;275.50;160240000;275.50
1988-10-13;273.95;275.83;273.39;275.22;154530000;275.22
1988-10-12;277.91;277.93;273.05;273.98;154840000;273.98
1988-10-11;278.15;278.24;276.33;277.93;140900000;277.93
1988-10-10;278.06;278.69;277.10;278.24;124660000;278.24
1988-10-07;272.38;278.07;272.37;278.07;216390000;278.07
1988-10-06;271.87;272.39;271.30;272.39;153570000;272.39
1988-10-05;270.63;272.45;270.08;271.86;175130000;271.86
1988-10-04;271.37;271.79;270.34;270.62;157760000;270.62
1988-10-03;271.89;271.91;268.84;271.38;130380000;271.38
1988-09-30;272.55;274.87;271.66;271.91;175750000;271.91
1988-09-29;269.09;273.02;269.08;272.59;155790000;272.59
1988-09-28;268.22;269.08;267.77;269.08;113720000;269.08
1988-09-27;268.89;269.36;268.01;268.26;113010000;268.26
1988-09-26;269.77;269.80;268.61;268.88;116420000;268.88
1988-09-23;269.16;270.31;268.28;269.76;145100000;269.76
1988-09-22;270.19;270.58;268.26;269.18;150670000;269.18
1988-09-21;269.76;270.64;269.48;270.16;127400000;270.16
1988-09-20;268.83;270.07;268.50;269.73;142220000;269.73
1988-09-19;270.64;270.65;267.41;268.82;135770000;268.82
1988-09-16;268.13;270.81;267.33;270.65;211110000;270.65
1988-09-15;269.30;269.78;268.03;268.13;161210000;268.13
1988-09-14;267.50;269.47;267.41;269.31;177220000;269.31
1988-09-13;266.45;267.43;265.22;267.43;162490000;267.43
1988-09-12;266.85;267.64;266.22;266.47;114880000;266.47
1988-09-09;265.88;268.26;263.66;266.84;141540000;266.84
1988-09-08;265.87;266.54;264.88;265.88;149380000;265.88
1988-09-07;265.62;266.98;264.93;265.87;139590000;265.87
1988-09-06;264.42;265.94;264.40;265.59;122250000;265.59
1988-09-02;258.35;264.90;258.35;264.48;159840000;264.48
1988-09-01;261.52;261.52;256.98;258.35;144090000;258.35
1988-08-31;262.51;263.80;261.21;261.52;130480000;261.52
1988-08-30;262.33;263.18;261.53;262.51;108720000;262.51
1988-08-29;259.68;262.56;259.68;262.33;99280000;262.33
1988-08-26;259.18;260.15;258.87;259.68;89240000;259.68
1988-08-25;261.10;261.13;257.56;259.18;127640000;259.18
1988-08-24;257.16;261.13;257.09;261.13;127800000;261.13
1988-08-23;256.99;257.86;256.53;257.09;119540000;257.09
1988-08-22;260.24;260.71;256.94;256.98;122250000;256.98
1988-08-19;261.05;262.27;260.23;260.24;122370000;260.24
1988-08-18;260.76;262.76;260.75;261.03;139820000;261.03
1988-08-17;260.57;261.84;259.33;260.77;169500000;260.77
1988-08-16;258.68;262.61;257.50;260.56;162790000;260.56
1988-08-15;262.49;262.55;258.68;258.69;128560000;258.69
1988-08-12;262.70;262.94;261.37;262.55;176960000;262.55
1988-08-11;261.92;262.77;260.34;262.75;173000000;262.75
1988-08-10;266.43;266.49;261.03;261.90;200950000;261.90
1988-08-09;270.00;270.20;265.06;266.49;200710000;266.49
1988-08-08;271.13;272.47;269.93;269.98;148800000;269.98
1988-08-05;271.70;271.93;270.08;271.15;113400000;271.15
1988-08-04;273.00;274.20;271.77;271.93;157240000;271.93
1988-08-03;272.03;273.42;271.15;272.98;203590000;272.98
1988-08-02;272.19;273.68;270.37;272.06;166660000;272.06
1988-08-01;272.03;272.80;271.21;272.21;138170000;272.21
1988-07-29;266.04;272.02;266.02;272.02;192340000;272.02
1988-07-28;262.52;266.55;262.50;266.02;154570000;266.02
1988-07-27;265.18;265.83;262.48;262.50;135890000;262.50
1988-07-26;264.70;266.09;264.32;265.19;121960000;265.19
1988-07-25;263.49;265.17;263.03;264.68;215140000;264.68
1988-07-22;266.65;266.66;263.29;263.50;148880000;263.50
1988-07-21;269.99;270.00;266.66;266.66;149460000;266.66
1988-07-20;268.52;270.24;268.47;270.00;151990000;270.00
1988-07-19;270.49;271.21;267.01;268.47;144110000;268.47
1988-07-18;271.99;272.05;268.66;270.51;156210000;270.51
1988-07-15;270.23;272.06;269.53;272.05;199710000;272.05
1988-07-14;269.33;270.69;268.58;270.26;172410000;270.26
1988-07-13;267.87;269.46;266.12;269.32;218930000;269.32
1988-07-12;270.54;270.70;266.96;267.85;161650000;267.85
1988-07-11;270.03;271.64;270.02;270.55;123300000;270.55
1988-07-08;271.76;272.31;269.86;270.02;136070000;270.02
1988-07-07;272.00;272.05;269.31;271.78;156100000;271.78
1988-07-06;275.80;276.36;269.92;272.02;189630000;272.02
1988-07-05;271.78;275.81;270.51;275.81;171790000;275.81
1988-07-01;273.50;273.80;270.78;271.78;238330000;271.78
1988-06-30;271.00;273.51;270.97;273.50;227410000;273.50
1988-06-29;272.32;273.01;269.49;270.98;159590000;270.98
1988-06-28;269.07;272.80;269.06;272.31;152370000;272.31
1988-06-27;273.78;273.79;268.85;269.06;264410000;269.06
1988-06-24;274.81;275.19;273.53;273.78;179880000;273.78
1988-06-23;275.62;275.89;274.26;274.82;185770000;274.82
1988-06-22;271.69;276.88;271.67;275.66;217510000;275.66
1988-06-21;268.95;271.67;267.52;271.67;155060000;271.67
1988-06-20;270.67;270.68;268.59;268.94;116750000;268.94
1988-06-17;269.79;270.77;268.09;270.68;343920000;270.68
1988-06-16;274.44;274.45;268.76;269.77;161550000;269.77
1988-06-15;274.29;274.45;272.75;274.45;150260000;274.45
1988-06-14;271.58;276.14;271.44;274.30;227150000;274.30
1988-06-13;271.28;271.94;270.53;271.43;125310000;271.43
1988-06-10;270.22;273.21;270.20;271.26;155710000;271.26
1988-06-09;271.50;272.29;270.19;270.20;235160000;270.20
1988-06-08;265.32;272.01;265.17;271.52;310030000;271.52
1988-06-07;267.02;267.28;264.50;265.17;168710000;265.17
1988-06-06;266.46;267.05;264.97;267.05;152460000;267.05
1988-06-03;265.34;267.11;264.42;266.45;189600000;266.45
1988-06-02;266.65;266.71;264.12;265.33;193540000;265.33
1988-06-01;262.16;267.43;262.10;266.69;234560000;266.69
1988-05-31;253.44;262.16;253.42;262.16;247610000;262.16
1988-05-27;254.62;254.63;252.74;253.42;133590000;253.42
1988-05-26;253.75;254.98;253.52;254.63;164260000;254.63
1988-05-25;253.52;255.34;253.51;253.76;138310000;253.76
1988-05-24;250.84;253.51;250.83;253.51;139930000;253.51
1988-05-23;253.00;253.02;249.82;250.83;102640000;250.83
1988-05-20;252.61;253.70;251.79;253.02;120600000;253.02
1988-05-19;251.36;252.57;248.85;252.57;165160000;252.57
1988-05-18;255.40;255.67;250.73;251.35;209420000;251.35
1988-05-17;258.72;260.20;255.35;255.39;133850000;255.39
1988-05-16;256.75;258.71;256.28;258.71;155010000;258.71
1988-05-13;253.88;256.83;253.85;256.78;147240000;256.78
1988-05-12;253.32;254.87;253.31;253.85;143880000;253.85
1988-05-11;257.60;257.62;252.32;253.31;176720000;253.31
1988-05-10;256.53;258.30;255.93;257.62;131200000;257.62
1988-05-09;257.47;258.22;255.45;256.54;166320000;256.54
1988-05-06;258.80;260.31;257.03;257.48;129080000;257.48
1988-05-05;260.30;260.32;258.13;258.79;171840000;258.79
1988-05-04;263.05;263.23;260.31;260.32;141320000;260.32
1988-05-03;261.55;263.70;261.55;263.00;176920000;263.00
1988-05-02;261.36;261.56;259.99;261.56;136470000;261.56
1988-04-29;262.59;262.61;259.97;261.33;135620000;261.33
1988-04-28;263.79;263.80;262.22;262.61;128680000;262.61
1988-04-27;263.94;265.09;263.45;263.80;133810000;263.80
1988-04-26;262.45;265.06;262.18;263.93;152300000;263.93
1988-04-25;260.15;263.29;260.14;262.51;156950000;262.51
1988-04-22;256.45;261.16;256.42;260.14;152520000;260.14
1988-04-21;256.15;260.44;254.71;256.42;168440000;256.42
1988-04-20;257.91;258.54;256.12;256.13;147590000;256.13
1988-04-19;259.24;262.38;257.91;257.92;161910000;257.92
1988-04-18;259.75;259.81;258.03;259.21;144650000;259.21
1988-04-15;259.74;260.39;255.97;259.77;234160000;259.77
1988-04-14;271.55;271.57;259.37;259.75;211810000;259.75
1988-04-13;271.33;271.70;269.23;271.58;185120000;271.58
1988-04-12;269.88;272.05;269.66;271.37;146400000;271.37
1988-04-11;269.43;270.41;268.61;270.16;146370000;270.16
1988-04-08;266.15;270.22;266.11;269.43;169300000;269.43
1988-04-07;265.51;267.32;265.22;266.16;177840000;266.16
1988-04-06;258.52;265.50;258.22;265.49;189760000;265.49
1988-04-05;256.10;258.52;256.03;258.51;135290000;258.51
1988-04-04;258.89;259.06;255.68;256.09;182240000;256.09
1988-03-31;258.03;259.03;256.16;258.89;139870000;258.89
1988-03-30;260.06;261.59;257.92;258.07;151810000;258.07
1988-03-29;258.11;260.86;258.06;260.07;152690000;260.07
1988-03-28;258.50;258.51;256.07;258.06;142820000;258.06
1988-03-25;263.34;263.44;258.12;258.51;163170000;258.51
1988-03-24;268.91;268.91;262.48;263.35;184910000;263.35
1988-03-23;268.81;269.79;268.01;268.91;167370000;268.91
1988-03-22;268.73;269.61;267.90;268.84;142000000;268.84
1988-03-21;271.10;271.12;267.42;268.74;128830000;268.74
1988-03-18;271.22;272.64;269.76;271.12;245750000;271.12
1988-03-17;268.66;271.22;268.65;271.22;211920000;271.22
1988-03-16;266.11;268.68;264.81;268.65;153590000;268.65
1988-03-15;266.34;266.41;264.92;266.13;133170000;266.13
1988-03-14;264.93;266.55;264.52;266.37;131890000;266.37
1988-03-11;263.85;264.94;261.27;264.94;200020000;264.94
1988-03-10;269.07;269.35;263.80;263.84;197260000;263.84
1988-03-09;269.46;270.76;268.65;269.06;210900000;269.06
1988-03-08;267.38;270.06;267.38;269.43;237680000;269.43
1988-03-07;267.28;267.69;265.94;267.38;152980000;267.38
1988-03-04;267.87;268.40;264.72;267.30;201410000;267.30
1988-03-03;267.98;268.40;266.82;267.88;203310000;267.88
1988-03-02;267.23;268.75;267.00;267.98;199630000;267.98
1988-03-01;267.82;267.95;265.39;267.22;199990000;267.22
1988-02-29;262.46;267.82;262.46;267.82;236050000;267.82
1988-02-26;261.56;263.00;261.38;262.46;158060000;262.46
1988-02-25;264.39;267.75;261.05;261.58;213490000;261.58
1988-02-24;265.01;266.25;263.87;264.43;212730000;264.43
1988-02-23;265.62;266.12;263.11;265.02;192260000;265.02
1988-02-22;261.60;266.06;260.88;265.64;178930000;265.64
1988-02-19;257.90;261.61;257.62;261.61;180300000;261.61
1988-02-18;258.82;259.60;256.90;257.91;151430000;257.91
1988-02-17;259.94;261.47;257.83;259.21;176830000;259.21
1988-02-16;257.61;259.84;256.57;259.83;135380000;259.83
1988-02-12;255.95;258.86;255.85;257.63;177190000;257.63
1988-02-11;256.63;257.77;255.12;255.95;200760000;255.95
1988-02-10;251.74;256.92;251.72;256.66;187980000;256.66
1988-02-09;249.11;251.72;248.66;251.72;162350000;251.72
1988-02-08;250.95;250.96;247.82;249.10;168850000;249.10
1988-02-05;252.22;253.85;250.90;250.96;161310000;250.96
1988-02-04;252.20;253.03;250.34;252.21;186490000;252.21
1988-02-03;255.56;256.98;250.56;252.21;237270000;252.21
1988-02-02;255.05;256.08;252.80;255.57;164920000;255.57
1988-02-01;257.05;258.27;254.93;255.04;210660000;255.04
1988-01-29;253.31;257.07;252.70;257.07;211880000;257.07
1988-01-28;249.39;253.66;249.38;253.29;166430000;253.29
1988-01-27;249.58;253.02;248.50;249.38;176360000;249.38
1988-01-26;252.13;252.17;249.10;249.57;138380000;249.57
1988-01-25;246.53;252.87;246.50;252.17;275250000;252.17
1988-01-22;243.14;246.50;243.14;246.50;147050000;246.50
1988-01-21;242.65;244.25;240.17;243.14;158080000;243.14
1988-01-20;249.31;249.32;241.14;242.63;181660000;242.63
1988-01-19;251.84;253.33;248.75;249.32;153550000;249.32
1988-01-18;252.05;252.86;249.98;251.88;135100000;251.88
1988-01-15;246.02;253.65;245.88;252.05;197940000;252.05
1988-01-14;245.83;247.00;243.97;245.88;140570000;245.88
1988-01-13;245.41;249.25;241.41;245.81;154020000;245.81
1988-01-12;247.44;247.49;240.46;245.42;165730000;245.42
1988-01-11;243.38;247.51;241.07;247.49;158980000;247.49
1988-01-08;261.05;261.07;242.95;243.40;197300000;243.40
1988-01-07;258.87;261.32;256.18;261.07;175360000;261.07
1988-01-06;258.64;259.79;257.18;258.89;169730000;258.89
1988-01-05;255.95;261.78;255.95;258.63;209520000;258.63
1988-01-04;247.10;256.44;247.08;255.94;181810000;255.94
1987-12-31;247.84;247.86;245.22;247.08;170140000;247.08
1987-12-30;244.63;248.06;244.59;247.86;149230000;247.86
1987-12-29;245.58;245.88;244.28;244.59;111580000;244.59
1987-12-28;252.01;252.02;244.19;245.57;131220000;245.57
1987-12-24;253.13;253.16;251.68;252.03;108800000;252.03
1987-12-23;249.96;253.35;249.95;253.16;203110000;253.16
1987-12-22;249.56;249.97;247.01;249.95;192650000;249.95
1987-12-21;249.14;250.25;248.30;249.54;161790000;249.54
1987-12-18;243.01;249.18;243.01;249.16;276220000;249.16
1987-12-17;248.08;248.60;242.96;242.98;191780000;242.98
1987-12-16;242.81;248.11;242.80;248.08;193820000;248.08
1987-12-15;242.19;245.59;241.31;242.81;214970000;242.81
1987-12-14;235.30;242.34;235.04;242.19;187680000;242.19
1987-12-11;233.60;235.48;233.35;235.32;151680000;235.32
1987-12-10;238.89;240.05;233.40;233.57;188960000;233.57
1987-12-09;234.91;240.09;233.83;238.89;231430000;238.89
1987-12-08;228.77;234.92;228.69;234.91;227310000;234.91
1987-12-07;223.98;228.77;223.92;228.76;146660000;228.76
1987-12-04;225.20;225.77;221.24;223.92;184800000;223.92
1987-12-03;233.46;233.90;225.21;225.21;204160000;225.21
1987-12-02;232.01;234.56;230.31;233.45;148890000;233.45
1987-12-01;230.32;234.02;230.30;232.00;149870000;232.00
1987-11-30;240.27;240.34;225.75;230.30;268910000;230.30
1987-11-27;244.11;244.12;240.34;240.34;86360000;240.34
1987-11-25;246.42;246.54;244.08;244.10;139780000;244.10
1987-11-24;242.98;247.90;242.98;246.39;199520000;246.39
1987-11-23;242.00;242.99;240.50;242.99;143160000;242.99
1987-11-20;240.04;242.01;235.89;242.00;189170000;242.00
1987-11-19;245.54;245.55;239.70;240.05;157140000;240.05
1987-11-18;243.09;245.55;240.67;245.55;158270000;245.55
1987-11-17;246.73;246.76;240.81;243.04;148240000;243.04
1987-11-16;245.69;249.54;244.98;246.76;164340000;246.76
1987-11-13;248.54;249.42;245.64;245.64;174920000;245.64
1987-11-12;241.93;249.90;241.90;248.52;206280000;248.52
1987-11-11;239.01;243.86;239.00;241.90;147850000;241.90
1987-11-10;243.14;243.17;237.64;239.00;184310000;239.00
1987-11-09;250.41;250.41;243.01;243.17;160690000;243.17
1987-11-06;254.49;257.21;249.68;250.41;228290000;250.41
1987-11-05;248.93;256.09;247.72;254.48;226000000;254.48
1987-11-04;250.81;251.00;246.34;248.96;202500000;248.96
1987-11-03;255.75;255.75;242.78;250.82;227800000;250.82
1987-11-02;251.73;255.75;249.15;255.75;176000000;255.75
1987-10-30;244.77;254.04;244.77;251.79;303400000;251.79
1987-10-29;233.31;246.69;233.28;244.77;258100000;244.77
1987-10-28;233.19;238.58;226.26;233.28;279400000;233.28
1987-10-27;227.67;237.81;227.67;233.19;260200000;233.19
1987-10-26;248.20;248.22;227.26;227.67;308800000;227.67
1987-10-23;248.29;250.70;242.76;248.22;245600000;248.22
1987-10-22;258.24;258.38;242.99;248.25;392200000;248.25
1987-10-21;236.83;259.27;236.83;258.38;449600000;258.38
1987-10-20;225.06;245.62;216.46;236.83;608100000;236.83
1987-10-19;282.70;282.70;224.83;224.84;604300000;224.84
1987-10-16;298.08;298.92;281.52;282.70;338500000;282.70
1987-10-15;305.21;305.23;298.07;298.08;263200000;298.08
1987-10-14;314.52;314.52;304.78;305.23;207400000;305.23
1987-10-13;309.39;314.53;309.39;314.52;172900000;314.52
1987-10-12;311.07;311.07;306.76;309.39;141900000;309.39
1987-10-09;314.16;315.04;310.97;311.07;158300000;311.07
1987-10-08;318.54;319.34;312.02;314.16;198700000;314.16
1987-10-07;319.22;319.39;315.78;318.54;186300000;318.54
1987-10-06;328.08;328.08;319.17;319.22;175600000;319.22
1987-10-05;328.07;328.57;326.09;328.08;159700000;328.08
1987-10-02;327.33;328.94;327.22;328.07;189100000;328.07
1987-10-01;321.83;327.34;321.83;327.33;193200000;327.33
1987-09-30;321.69;322.53;320.16;321.83;183100000;321.83
1987-09-29;323.20;324.63;320.27;321.69;173500000;321.69
1987-09-28;320.16;325.33;320.16;323.20;188100000;323.20
1987-09-25;319.72;320.55;318.10;320.16;138000000;320.16
1987-09-24;321.09;322.01;319.12;319.72;162200000;319.72
1987-09-23;319.49;321.83;319.12;321.19;220300000;321.19
1987-09-22;310.54;319.51;308.69;319.50;209500000;319.50
1987-09-21;314.92;317.66;310.12;310.54;170100000;310.54
1987-09-18;314.98;316.99;314.86;314.86;188100000;314.86
1987-09-17;314.94;316.08;313.45;314.93;150700000;314.93
1987-09-16;317.75;319.50;314.61;314.86;195700000;314.86
1987-09-15;323.07;323.08;317.63;317.74;136200000;317.74
1987-09-14;322.02;323.81;320.40;323.08;154400000;323.08
1987-09-11;317.14;322.45;317.13;321.98;178000000;321.98
1987-09-10;313.92;317.59;313.92;317.13;179800000;317.13
1987-09-09;313.60;315.41;312.29;313.92;164900000;313.92
1987-09-08;316.68;316.70;308.56;313.56;242900000;313.56
1987-09-04;320.21;322.03;316.53;316.70;129100000;316.70
1987-09-03;321.47;324.29;317.39;320.21;165200000;320.21
1987-09-02;323.40;324.53;318.76;321.68;199900000;321.68
1987-09-01;329.81;332.18;322.83;323.40;193500000;323.40
1987-08-31;327.03;330.09;326.99;329.80;165800000;329.80
1987-08-28;331.37;331.38;327.03;327.04;156300000;327.04
1987-08-27;334.56;334.57;331.10;331.38;163600000;331.38
1987-08-26;336.77;337.39;334.46;334.57;196200000;334.57
1987-08-25;333.37;337.89;333.33;336.77;213500000;336.77
1987-08-24;335.89;335.90;331.92;333.33;149400000;333.33
1987-08-21;334.85;336.37;334.30;335.90;189600000;335.90
1987-08-20;331.49;335.19;329.83;334.84;196600000;334.84
1987-08-19;329.26;329.89;326.54;329.83;180900000;329.83
1987-08-18;334.10;334.11;326.43;329.25;198400000;329.25
1987-08-17;333.98;335.43;332.88;334.11;166100000;334.11
1987-08-14;334.63;336.08;332.63;333.99;196100000;333.99
1987-08-13;332.38;335.52;332.38;334.65;217100000;334.65
1987-08-12;333.32;334.57;331.06;332.39;235800000;332.39
1987-08-11;328.02;333.40;328.00;333.33;278100000;333.33
1987-08-10;322.98;328.00;322.95;328.00;187200000;328.00
1987-08-07;322.10;324.15;321.82;323.00;212700000;323.00
1987-08-06;318.49;322.09;317.50;322.09;192000000;322.09
1987-08-05;316.25;319.74;316.23;318.45;192700000;318.45
1987-08-04;317.59;318.25;314.51;316.23;166500000;316.23
1987-08-03;318.62;320.26;316.52;317.57;207800000;317.57
1987-07-31;318.05;318.85;317.56;318.66;181900000;318.66
1987-07-30;315.69;318.53;315.65;318.05;208000000;318.05
1987-07-29;312.34;315.65;311.73;315.65;196200000;315.65
1987-07-28;310.65;312.33;310.28;312.33;172600000;312.33
1987-07-27;309.30;310.70;308.61;310.65;152000000;310.65
1987-07-24;307.82;309.28;307.78;309.27;158400000;309.27
1987-07-23;308.50;309.63;306.10;307.81;163700000;307.81
1987-07-22;308.56;309.12;307.22;308.47;174700000;308.47
1987-07-21;311.36;312.41;307.51;308.55;186600000;308.55
1987-07-20;314.56;314.59;311.24;311.39;168100000;311.39
1987-07-17;312.71;314.59;312.38;314.59;210000000;314.59
1987-07-16;311.00;312.83;310.42;312.70;210900000;312.70
1987-07-15;310.67;312.08;309.07;310.42;202300000;310.42
1987-07-14;307.67;310.69;307.46;310.68;185900000;310.68
1987-07-13;308.41;308.41;305.49;307.63;152500000;307.63
1987-07-10;307.55;308.40;306.96;308.37;172100000;308.37
1987-07-09;308.30;309.56;307.42;307.52;195400000;307.52
1987-07-08;307.41;308.48;306.01;308.29;207500000;308.29
1987-07-07;304.91;308.63;304.73;307.40;200700000;307.40
1987-07-06;305.64;306.75;304.23;304.92;155000000;304.92
1987-07-02;302.96;306.34;302.94;305.63;154900000;305.63
1987-07-01;303.99;304.00;302.53;302.94;157000000;302.94
1987-06-30;307.89;308.00;303.01;304.00;165500000;304.00
1987-06-29;307.15;308.15;306.75;307.90;142500000;307.90
1987-06-26;308.94;308.96;306.36;307.16;150500000;307.16
1987-06-25;306.87;309.44;306.86;308.96;173500000;308.96
1987-06-24;308.44;308.91;306.32;306.86;153800000;306.86
1987-06-23;309.66;310.27;307.48;308.43;194200000;308.43
1987-06-22;306.98;310.20;306.97;309.65;178200000;309.65
1987-06-19;305.71;306.97;305.55;306.97;220500000;306.97
1987-06-18;304.78;306.13;303.38;305.69;168600000;305.69
1987-06-17;304.77;305.74;304.03;304.81;184700000;304.81
1987-06-16;303.12;304.86;302.60;304.76;157800000;304.76
1987-06-15;301.62;304.11;301.62;303.14;156900000;303.14
1987-06-12;298.77;302.26;298.73;301.62;175100000;301.62
1987-06-11;297.50;298.94;297.47;298.73;138900000;298.73
1987-06-10;297.28;300.81;295.66;297.47;197400000;297.47
1987-06-09;296.72;297.59;295.90;297.28;164200000;297.28
1987-06-08;293.46;297.03;291.55;296.72;136400000;296.72
1987-06-05;295.11;295.11;292.80;293.45;129100000;293.45
1987-06-04;293.46;295.09;292.76;295.09;140300000;295.09
1987-06-03;288.56;293.47;288.56;293.47;164200000;293.47
1987-06-02;289.82;290.94;286.93;288.46;153400000;288.46
1987-06-01;290.12;291.96;289.23;289.83;149300000;289.83
1987-05-29;290.77;292.87;289.70;290.10;153500000;290.10
1987-05-28;288.73;291.50;286.33;290.76;153800000;290.76
1987-05-27;289.07;290.78;288.19;288.73;171400000;288.73
1987-05-26;282.16;289.11;282.16;289.11;152500000;289.11
1987-05-22;280.17;283.33;280.17;282.16;135800000;282.16
1987-05-21;278.23;282.31;278.21;280.17;164800000;280.17
1987-05-20;279.62;280.89;277.01;278.21;206800000;278.21
1987-05-19;286.66;287.39;278.83;279.62;175400000;279.62
1987-05-18;287.43;287.43;282.57;286.65;174200000;286.65
1987-05-15;294.23;294.24;287.11;287.43;180800000;287.43
1987-05-14;293.98;295.10;292.95;294.24;152000000;294.24
1987-05-13;293.31;294.54;290.74;293.98;171000000;293.98
1987-05-12;291.57;293.30;290.18;293.30;155300000;293.30
1987-05-11;293.37;298.69;291.55;291.57;203700000;291.57
1987-05-08;294.73;296.18;291.73;293.37;161900000;293.37
1987-05-07;295.45;296.80;294.07;294.71;215200000;294.71
1987-05-06;295.35;296.19;293.60;295.47;196600000;295.47
1987-05-05;289.36;295.40;289.34;295.34;192300000;295.34
1987-05-04;288.02;289.99;286.39;289.36;140600000;289.36
1987-05-01;286.99;289.71;286.52;288.03;160100000;288.03
1987-04-30;284.58;290.08;284.57;288.36;183100000;288.36
1987-04-29;282.58;286.42;282.58;284.57;173600000;284.57
1987-04-28;281.83;285.95;281.83;282.51;180100000;282.51
1987-04-27;281.52;284.45;276.22;281.83;222700000;281.83
1987-04-24;286.81;286.82;281.18;281.52;178000000;281.52
1987-04-23;287.19;289.12;284.28;286.82;173900000;286.82
1987-04-22;293.05;293.46;286.98;287.19;185900000;287.19
1987-04-21;285.88;293.07;282.89;293.07;191300000;293.07
1987-04-20;286.91;288.36;284.55;286.09;139100000;286.09
1987-04-16;284.45;289.57;284.44;286.91;189600000;286.91
1987-04-15;279.17;285.14;279.16;284.44;198200000;284.44
1987-04-14;285.61;285.62;275.67;279.16;266500000;279.16
1987-04-13;292.48;293.36;285.62;285.62;181000000;285.62
1987-04-10;292.82;293.74;290.94;292.49;169500000;292.49
1987-04-09;297.25;297.71;291.50;292.86;180300000;292.86
1987-04-08;296.72;299.20;295.18;297.26;179800000;297.26
1987-04-07;301.94;303.65;296.67;296.69;186400000;296.69
1987-04-06;300.46;302.21;300.41;301.95;173700000;301.95
1987-04-03;293.64;301.30;292.30;300.41;213400000;300.41
1987-04-02;292.41;294.47;292.02;293.63;183000000;293.63
1987-04-01;291.59;292.38;288.34;292.38;182600000;292.38
1987-03-31;289.21;291.87;289.07;291.70;171800000;291.70
1987-03-30;296.10;296.13;286.69;289.20;208400000;289.20
1987-03-27;300.96;301.41;296.06;296.13;184400000;296.13
1987-03-26;300.39;302.72;300.38;300.93;196000000;300.93
1987-03-25;301.52;301.85;299.36;300.38;171300000;300.38
1987-03-24;301.17;301.92;300.14;301.64;189900000;301.64
1987-03-23;298.16;301.17;297.50;301.16;189100000;301.16
1987-03-20;294.08;298.17;294.08;298.17;234000000;298.17
1987-03-19;292.73;294.46;292.26;294.08;166100000;294.08
1987-03-18;292.49;294.58;290.87;292.78;198100000;292.78
1987-03-17;288.09;292.47;287.96;292.47;177300000;292.47
1987-03-16;289.88;289.89;286.64;288.23;134900000;288.23
1987-03-13;291.22;291.79;289.88;289.89;150900000;289.89
1987-03-12;290.33;291.91;289.66;291.22;174500000;291.22
1987-03-11;290.87;292.51;289.33;290.31;186900000;290.31
1987-03-10;288.30;290.87;287.89;290.86;174800000;290.86
1987-03-09;290.66;290.66;287.12;288.30;165400000;288.30
1987-03-06;290.52;290.67;288.77;290.66;181600000;290.66
1987-03-05;288.62;291.24;288.60;290.52;205400000;290.52
1987-03-04;284.12;288.62;284.12;288.62;198400000;288.62
1987-03-03;283.00;284.19;282.92;284.12;149200000;284.12
1987-03-02;284.17;284.83;282.30;283.00;156700000;283.00
1987-02-27;282.96;284.55;282.77;284.20;142800000;284.20
1987-02-26;284.00;284.40;280.73;282.96;165800000;282.96
1987-02-25;282.88;285.35;282.14;284.00;184100000;284.00
1987-02-24;282.38;283.33;281.45;282.88;151300000;282.88
1987-02-23;285.48;285.50;279.37;282.38;170500000;282.38
1987-02-20;285.57;285.98;284.31;285.48;175800000;285.48
1987-02-19;285.42;286.24;283.84;285.57;181500000;285.57
1987-02-18;285.49;287.55;282.97;285.42;218200000;285.42
1987-02-17;279.70;285.49;279.70;285.49;187800000;285.49
1987-02-13;275.62;280.91;275.01;279.70;184400000;279.70
1987-02-12;277.54;278.04;273.89;275.62;200400000;275.62
1987-02-11;275.07;277.71;274.71;277.54;172400000;277.54
1987-02-10;278.16;278.16;273.49;275.07;168300000;275.07
1987-02-09;280.04;280.04;277.24;278.16;143300000;278.16
1987-02-06;281.16;281.79;279.87;280.04;184100000;280.04
1987-02-05;279.64;282.26;278.66;281.16;256700000;281.16
1987-02-04;275.99;279.65;275.35;279.64;222400000;279.64
1987-02-03;276.45;277.83;275.84;275.99;198100000;275.99
1987-02-02;274.08;277.35;273.16;276.45;177400000;276.45
1987-01-30;274.24;274.24;271.38;274.08;163400000;274.08
1987-01-29;275.40;276.85;272.54;274.24;205300000;274.24
1987-01-28;273.75;275.71;273.03;275.40;195800000;275.40
1987-01-27;269.61;274.31;269.61;273.75;192300000;273.75
1987-01-26;270.10;270.40;267.73;269.61;138900000;269.61
1987-01-23;273.91;280.96;268.41;270.10;302400000;270.10
1987-01-22;267.84;274.05;267.32;273.91;188700000;273.91
1987-01-21;269.04;270.87;267.35;267.84;184200000;267.84
1987-01-20;269.34;271.03;267.65;269.04;224800000;269.04
1987-01-19;266.26;269.34;264.00;269.34;162800000;269.34
1987-01-16;265.46;267.24;264.31;266.28;218400000;266.28
1987-01-15;262.65;266.68;262.64;265.49;253100000;265.49
1987-01-14;259.95;262.72;259.62;262.64;214200000;262.64
1987-01-13;260.30;260.45;259.21;259.95;170900000;259.95
1987-01-12;258.72;261.36;257.92;260.30;184200000;260.30
1987-01-09;257.26;259.20;256.11;258.73;193000000;258.73
1987-01-08;255.36;257.28;254.97;257.28;194500000;257.28
1987-01-07;252.78;255.72;252.65;255.33;190900000;255.33
1987-01-06;252.20;253.99;252.14;252.78;189300000;252.78
1987-01-05;246.45;252.57;246.45;252.19;181900000;252.19
1987-01-02;242.17;246.45;242.17;246.45;91880000;246.45
1986-12-31;243.37;244.03;241.28;242.17;139200000;242.17
1986-12-30;244.66;244.67;243.04;243.37;126200000;243.37
1986-12-29;246.90;246.92;244.31;244.67;99800000;244.67
1986-12-26;246.75;247.09;246.73;246.92;48860000;246.92
1986-12-24;246.34;247.22;246.02;246.75;95410000;246.75
1986-12-23;248.75;248.75;245.85;246.34;188700000;246.34
1986-12-22;249.73;249.73;247.45;248.75;157600000;248.75
1986-12-19;246.79;249.96;245.89;249.73;244700000;249.73
1986-12-18;247.56;247.81;246.45;246.78;155400000;246.78
1986-12-17;250.01;250.04;247.19;247.56;148800000;247.56
1986-12-16;248.21;250.04;247.40;250.04;157000000;250.04
1986-12-15;247.31;248.23;244.92;248.21;148200000;248.21
1986-12-12;248.17;248.31;247.02;247.35;126600000;247.35
1986-12-11;250.97;250.98;247.15;248.17;136000000;248.17
1986-12-10;249.28;251.53;248.94;250.96;139700000;250.96
1986-12-09;251.16;251.27;249.25;249.28;128700000;249.28
1986-12-08;251.16;252.36;248.82;251.16;159000000;251.16
1986-12-05;253.05;253.89;250.71;251.17;139800000;251.17
1986-12-04;253.85;254.42;252.88;253.04;156900000;253.04
1986-12-03;254.00;254.87;253.24;253.85;200100000;253.85
1986-12-02;249.06;254.00;249.05;254.00;230400000;254.00
1986-12-01;249.22;249.22;245.72;249.05;133800000;249.05
1986-11-28;248.82;249.22;248.07;249.22;93530000;249.22
1986-11-26;248.14;248.90;247.73;248.77;152000000;248.77
1986-11-25;247.44;248.18;246.30;248.17;154600000;248.17
1986-11-24;245.86;248.00;245.21;247.45;150800000;247.45
1986-11-21;242.03;246.38;241.97;245.86;200700000;245.86
1986-11-20;237.66;242.05;237.66;242.05;158100000;242.05
1986-11-19;236.77;237.94;235.51;237.66;183300000;237.66
1986-11-18;243.20;243.23;236.65;236.78;185300000;236.78
1986-11-17;244.50;244.80;242.29;243.21;133300000;243.21
1986-11-14;243.01;244.51;241.96;244.50;172100000;244.50
1986-11-13;246.63;246.66;242.98;243.02;164000000;243.02
1986-11-12;247.06;247.67;245.68;246.64;162200000;246.64
1986-11-11;246.15;247.10;246.12;247.08;118500000;247.08
1986-11-10;245.75;246.22;244.68;246.13;120200000;246.13
1986-11-07;245.85;246.13;244.92;245.77;142300000;245.77
1986-11-06;246.54;246.90;244.30;245.87;165300000;245.87
1986-11-05;246.09;247.05;245.21;246.58;183200000;246.58
1986-11-04;245.80;246.43;244.42;246.20;163200000;246.20
1986-11-03;243.97;245.80;243.93;245.80;138200000;245.80
1986-10-31;243.70;244.51;242.95;243.98;147200000;243.98
1986-10-30;240.97;244.08;240.94;243.71;194200000;243.71
1986-10-29;239.23;241.00;238.98;240.94;164400000;240.94
1986-10-28;238.81;240.58;238.77;239.26;145900000;239.26
1986-10-27;238.22;238.77;236.72;238.77;133200000;238.77
1986-10-24;239.30;239.65;238.25;238.26;137500000;238.26
1986-10-23;236.28;239.76;236.26;239.28;150900000;239.28
1986-10-22;235.89;236.64;235.82;236.26;114000000;236.26
1986-10-21;236.03;236.49;234.95;235.88;110000000;235.88
1986-10-20;238.84;238.84;234.78;235.97;109000000;235.97
1986-10-17;239.50;239.53;237.71;238.84;124100000;238.84
1986-10-16;238.83;240.18;238.80;239.53;156900000;239.53
1986-10-15;235.36;239.03;235.27;238.80;144300000;238.80
1986-10-14;235.90;236.37;234.37;235.37;116800000;235.37
1986-10-13;235.52;235.91;235.02;235.91;54990000;235.91
1986-10-10;235.84;236.27;235.31;235.48;105100000;235.48
1986-10-09;236.67;238.20;235.72;235.85;153400000;235.85
1986-10-08;234.41;236.84;233.68;236.68;141700000;236.68
1986-10-07;234.74;235.18;233.46;234.41;125100000;234.41
1986-10-06;233.71;235.34;233.17;234.78;88250000;234.78
1986-10-03;233.92;236.16;232.79;233.71;128100000;233.71
1986-10-02;233.60;234.33;232.77;233.92;128100000;233.92
1986-10-01;231.32;234.62;231.32;233.60;143600000;233.60
1986-09-30;229.91;233.01;229.91;231.32;124900000;231.32
1986-09-29;232.23;232.23;228.08;229.91;115600000;229.91
1986-09-26;231.83;233.68;230.64;232.23;115300000;232.23
1986-09-25;231.83;236.28;230.67;231.83;134300000;231.83
1986-09-24;235.66;237.06;235.53;236.28;134600000;236.28
1986-09-23;234.96;235.88;234.50;235.67;132600000;235.67
1986-09-22;232.20;234.93;232.20;234.93;126100000;234.93
1986-09-19;232.30;232.31;230.69;232.21;153900000;232.21
1986-09-18;231.67;232.87;230.57;232.31;132200000;232.31
1986-09-17;231.73;233.81;231.38;231.68;141000000;231.68
1986-09-16;231.93;231.94;228.32;231.72;131200000;231.72
1986-09-15;230.67;232.82;229.44;231.94;155600000;231.94
1986-09-12;235.18;235.45;228.74;230.67;240500000;230.67
1986-09-11;247.06;247.06;234.67;235.18;237600000;235.18
1986-09-10;247.67;247.76;246.11;247.06;140300000;247.06
1986-09-09;248.14;250.21;246.94;247.67;137500000;247.67
1986-09-08;250.47;250.47;247.02;248.14;153300000;248.14
1986-09-05;253.83;254.13;250.33;250.47;180600000;250.47
1986-09-04;250.08;254.01;250.03;253.83;189400000;253.83
1986-09-03;248.52;250.08;247.59;250.08;154300000;250.08
1986-09-02;252.93;253.30;248.14;248.52;135500000;248.52
1986-08-29;252.84;254.07;251.73;252.93;125300000;252.93
1986-08-28;253.30;253.67;251.91;252.84;125100000;252.84
1986-08-27;252.84;254.24;252.66;253.30;143300000;253.30
1986-08-26;247.81;252.91;247.81;252.84;156600000;252.84
1986-08-25;250.19;250.26;247.76;247.81;104400000;247.81
1986-08-22;249.67;250.61;249.27;250.19;118100000;250.19
1986-08-21;249.77;250.45;249.11;249.67;135200000;249.67
1986-08-20;246.53;249.77;246.51;249.77;156600000;249.77
1986-08-19;247.38;247.42;245.82;246.51;109300000;246.51
1986-08-18;247.15;247.83;245.48;247.38;112800000;247.38
1986-08-15;246.25;247.15;245.70;247.15;123500000;247.15
1986-08-14;245.67;246.79;245.53;246.25;123800000;246.25
1986-08-13;243.34;246.51;243.06;245.67;156400000;245.67
1986-08-12;240.68;243.37;240.35;243.34;131700000;243.34
1986-08-11;236.88;241.20;236.87;240.68;125600000;240.68
1986-08-08;237.04;238.06;236.37;236.88;106300000;236.88
1986-08-07;236.84;238.02;236.31;237.04;122400000;237.04
1986-08-06;237.03;237.35;235.48;236.84;127500000;236.84
1986-08-05;235.99;238.31;235.97;237.03;153100000;237.03
1986-08-04;234.91;236.86;231.92;235.99;130000000;235.99
1986-08-01;236.12;236.89;234.59;234.91;114900000;234.91
1986-07-31;236.59;236.92;235.89;236.12;112700000;236.12
1986-07-30;234.57;237.38;233.07;236.59;146700000;236.59
1986-07-29;235.72;236.01;234.40;234.55;115700000;234.55
1986-07-28;240.20;240.25;235.23;236.01;128000000;236.01
1986-07-25;237.99;240.36;237.95;240.22;132000000;240.22
1986-07-24;238.69;239.05;237.32;237.95;134700000;237.95
1986-07-23;238.19;239.25;238.17;238.67;133300000;238.67
1986-07-22;236.24;238.42;235.92;238.18;138500000;238.18
1986-07-21;236.36;236.45;235.53;236.24;106300000;236.24
1986-07-18;236.07;238.22;233.94;236.36;149700000;236.36
1986-07-17;235.01;236.65;235.01;236.07;132400000;236.07
1986-07-16;233.66;236.19;233.66;235.01;160800000;235.01
1986-07-15;238.09;238.12;233.60;233.66;184000000;233.66
1986-07-14;242.22;242.22;238.04;238.11;123200000;238.11
1986-07-11;243.01;243.48;241.68;242.22;124500000;242.22
1986-07-10;242.82;243.44;239.66;243.01;146200000;243.01
1986-07-09;241.59;243.07;241.46;242.82;142900000;242.82
1986-07-08;244.05;244.06;239.07;241.59;174100000;241.59
1986-07-07;251.79;251.81;243.63;244.05;138200000;244.05
1986-07-03;252.70;252.94;251.23;251.79;108300000;251.79
1986-07-02;252.04;253.20;251.79;252.70;150000000;252.70
1986-07-01;250.67;252.04;250.53;252.04;147700000;252.04
1986-06-30;249.60;251.81;249.60;250.84;135100000;250.84
1986-06-27;248.74;249.74;248.74;249.60;123800000;249.60
1986-06-26;248.93;249.43;247.72;248.74;134100000;248.74
1986-06-25;247.03;250.13;247.03;248.93;161800000;248.93
1986-06-24;245.26;248.26;244.53;247.03;140600000;247.03
1986-06-23;247.58;247.58;244.45;245.26;123800000;245.26
1986-06-20;244.06;247.60;243.98;247.58;149100000;247.58
1986-06-19;244.99;245.80;244.05;244.06;129000000;244.06
1986-06-18;244.35;245.25;242.57;244.99;117000000;244.99
1986-06-17;246.13;246.26;243.60;244.35;123100000;244.35
1986-06-16;245.73;246.50;245.17;246.13;112100000;246.13
1986-06-13;241.71;245.91;241.71;245.73;141200000;245.73
1986-06-12;241.24;241.64;240.70;241.49;109100000;241.49
1986-06-11;239.58;241.13;239.21;241.13;127400000;241.13
1986-06-10;239.96;240.08;238.23;239.58;125000000;239.58
1986-06-09;245.67;245.67;239.68;239.96;123300000;239.96
1986-06-06;245.65;246.07;244.43;245.67;110900000;245.67
1986-06-05;243.94;245.66;243.41;245.65;110900000;245.65
1986-06-04;245.51;246.30;242.59;243.94;117000000;243.94
1986-06-03;245.04;245.51;243.67;245.51;114700000;245.51
1986-06-02;246.04;247.74;243.83;245.04;120600000;245.04
1986-05-30;247.98;249.19;246.43;247.35;151200000;247.35
1986-05-29;246.63;248.32;245.29;247.98;135700000;247.98
1986-05-28;244.75;247.40;244.75;246.63;159600000;246.63
1986-05-27;241.35;244.76;241.35;244.75;121200000;244.75
1986-05-23;240.12;242.16;240.12;241.35;130200000;241.35
1986-05-22;235.45;240.25;235.45;240.12;144900000;240.12
1986-05-21;236.11;236.83;235.45;235.45;117100000;235.45
1986-05-20;233.20;236.12;232.58;236.11;113000000;236.11
1986-05-19;232.76;233.54;232.41;233.20;85840000;233.20
1986-05-16;234.43;234.43;232.26;232.76;113500000;232.76
1986-05-15;237.54;237.54;233.93;234.43;131600000;234.43
1986-05-14;236.41;237.54;235.85;237.54;132100000;237.54
1986-05-13;237.58;237.87;236.02;236.41;119200000;236.41
1986-05-12;237.85;238.53;237.02;237.58;125400000;237.58
1986-05-09;237.13;238.01;235.85;237.85;137400000;237.85
1986-05-08;236.08;237.96;236.08;237.13;136000000;237.13
1986-05-07;236.56;237.24;233.98;236.08;129900000;236.08
1986-05-06;237.73;238.28;236.26;237.24;121200000;237.24
1986-05-05;234.79;237.73;234.79;237.73;102400000;237.73
1986-05-02;235.16;236.52;234.15;234.79;126300000;234.79
1986-05-01;235.52;236.01;234.21;235.16;146500000;235.16
1986-04-30;240.52;240.52;235.26;235.52;147500000;235.52
1986-04-29;243.08;243.57;239.23;240.51;148800000;240.51
1986-04-28;242.29;243.08;241.23;243.08;123900000;243.08
1986-04-25;242.02;242.80;240.91;242.29;142300000;242.29
1986-04-24;241.75;243.13;241.65;242.02;146600000;242.02
1986-04-23;242.42;242.42;240.08;241.75;149700000;241.75
1986-04-22;244.74;245.47;241.30;242.42;161500000;242.42
1986-04-21;242.38;244.78;241.88;244.74;136100000;244.74
1986-04-18;243.03;243.47;241.74;242.38;153600000;242.38
1986-04-17;242.22;243.36;241.89;243.03;161400000;243.03
1986-04-16;237.73;242.57;237.73;242.22;173800000;242.22
1986-04-15;237.28;238.09;236.64;237.73;123700000;237.73
1986-04-14;235.97;237.48;235.43;237.28;106700000;237.28
1986-04-11;236.44;237.85;235.13;235.97;139400000;235.97
1986-04-10;233.75;236.54;233.75;236.44;184800000;236.44
1986-04-09;233.52;235.57;232.13;233.75;156300000;233.75
1986-04-08;228.63;233.70;228.63;233.52;146300000;233.52
1986-04-07;228.69;228.83;226.30;228.63;129800000;228.63
1986-04-04;232.47;232.56;228.32;228.69;147300000;228.69
1986-04-03;235.71;236.42;232.07;232.47;148200000;232.47
1986-04-02;235.14;235.71;233.40;235.71;145300000;235.71
1986-04-01;238.90;239.10;234.57;235.14;167400000;235.14
1986-03-31;238.97;239.86;238.08;238.90;134400000;238.90
1986-03-27;237.30;240.11;237.30;238.97;178100000;238.97
1986-03-26;234.72;237.79;234.71;237.30;161500000;237.30
1986-03-25;235.33;235.33;233.62;234.72;139300000;234.72
1986-03-24;233.34;235.33;232.92;235.33;143800000;235.33
1986-03-21;236.54;237.35;233.29;233.34;199100000;233.34
1986-03-20;235.60;237.09;235.60;236.54;148000000;236.54
1986-03-19;235.78;236.52;235.13;235.60;150000000;235.60
1986-03-18;234.67;236.52;234.14;235.78;148000000;235.78
1986-03-17;236.55;236.55;233.69;234.67;137500000;234.67
1986-03-14;233.19;236.55;232.58;236.55;181900000;236.55
1986-03-13;232.54;233.89;231.27;233.19;171500000;233.19
1986-03-12;231.69;234.70;231.68;232.54;210300000;232.54
1986-03-11;226.58;231.81;226.58;231.69;187300000;231.69
1986-03-10;225.57;226.98;225.36;226.58;129900000;226.58
1986-03-07;225.13;226.33;224.44;225.57;163200000;225.57
1986-03-06;224.39;225.50;224.13;225.13;159000000;225.13
1986-03-05;224.14;224.37;222.18;224.34;154600000;224.34
1986-03-04;225.42;227.33;223.94;224.38;174500000;224.38
1986-03-03;226.92;226.92;224.41;225.42;142700000;225.42
1986-02-28;226.77;227.92;225.42;226.92;191700000;226.92
1986-02-27;224.04;226.88;223.41;226.77;181700000;226.77
1986-02-26;223.72;224.59;223.15;224.04;158000000;224.04
1986-02-25;224.34;224.40;222.63;223.79;148000000;223.79
1986-02-24;224.58;225.29;223.31;224.34;144700000;224.34
1986-02-21;222.22;224.62;222.22;224.62;177600000;224.62
1986-02-20;219.76;222.22;219.22;222.22;139700000;222.22
1986-02-19;222.45;222.96;219.73;219.76;152000000;219.76
1986-02-18;219.76;222.45;219.26;222.45;160200000;222.45
1986-02-14;217.40;219.76;217.22;219.76;155600000;219.76
1986-02-13;215.97;217.41;215.38;217.40;136500000;217.40
1986-02-12;215.92;216.28;215.13;215.97;136400000;215.97
1986-02-11;216.24;216.67;215.54;215.92;141300000;215.92
1986-02-10;214.56;216.24;214.47;216.24;129900000;216.24
1986-02-07;213.47;215.27;211.13;214.56;144400000;214.56
1986-02-06;212.96;214.51;212.60;213.47;146100000;213.47
1986-02-05;212.84;213.03;211.21;212.96;134300000;212.96
1986-02-04;213.96;214.57;210.82;212.79;175700000;212.79
1986-02-03;211.78;214.18;211.60;213.96;145300000;213.96
1986-01-31;209.33;212.42;209.19;211.78;143500000;211.78
1986-01-30;210.29;211.54;209.15;209.33;125300000;209.33
1986-01-29;209.81;212.36;209.81;210.29;193800000;210.29
1986-01-28;207.42;209.82;207.40;209.81;145700000;209.81
1986-01-27;206.43;207.69;206.43;207.39;122900000;207.39
1986-01-24;204.25;206.43;204.25;206.43;128900000;206.43
1986-01-23;203.49;204.43;202.60;204.25;130300000;204.25
1986-01-22;205.79;206.03;203.41;203.49;131200000;203.49
1986-01-21;207.53;207.78;205.05;205.79;128300000;205.79
1986-01-20;208.43;208.43;206.62;207.53;85340000;207.53
1986-01-17;209.17;209.40;207.59;208.43;132100000;208.43
1986-01-16;208.26;209.18;207.61;209.17;130500000;209.17
1986-01-15;206.64;208.27;206.64;208.26;122400000;208.26
1986-01-14;206.72;207.37;206.06;206.64;113900000;206.64
1986-01-13;205.96;206.83;205.52;206.72;108700000;206.72
1986-01-10;206.11;207.33;205.52;205.96;122800000;205.96
1986-01-09;207.97;207.97;204.51;206.11;176500000;206.11
1986-01-08;213.80;214.57;207.49;207.97;180300000;207.97
1986-01-07;210.65;213.80;210.65;213.80;153000000;213.80
1986-01-06;210.88;210.98;209.93;210.65;99610000;210.65
1986-01-03;209.59;210.88;209.51;210.88;105000000;210.88
1986-01-02;211.28;211.28;208.93;209.59;98960000;209.59
1985-12-31;210.68;211.61;210.68;211.28;112700000;211.28
1985-12-30;209.61;210.70;209.17;210.68;91970000;210.68
1985-12-27;207.65;209.62;207.65;209.61;81560000;209.61
1985-12-26;207.14;207.76;207.05;207.65;62050000;207.65
1985-12-24;208.57;208.57;206.44;207.14;78300000;207.14
1985-12-23;210.57;210.94;208.44;208.57;107900000;208.57
1985-12-20;210.02;211.77;210.02;210.94;170300000;210.94
1985-12-19;209.81;210.13;209.25;210.02;130200000;210.02
1985-12-18;210.65;211.23;209.24;209.81;137900000;209.81
1985-12-17;212.02;212.45;210.58;210.65;155200000;210.65
1985-12-16;209.94;213.08;209.91;212.02;176000000;212.02
1985-12-13;206.73;210.31;206.73;209.94;177900000;209.94
1985-12-12;206.31;207.65;205.83;206.73;170500000;206.73
1985-12-11;204.39;206.68;204.17;206.31;178500000;206.31
1985-12-10;204.25;205.16;203.68;204.39;156500000;204.39
1985-12-09;202.99;204.65;202.98;204.25;144000000;204.25
1985-12-06;203.88;203.88;202.45;202.99;125500000;202.99
1985-12-05;204.23;205.86;203.79;203.88;181000000;203.88
1985-12-04;200.86;204.23;200.86;204.23;153200000;204.23
1985-12-03;200.46;200.98;200.10;200.86;109700000;200.86
1985-12-02;202.17;202.19;200.20;200.46;103500000;200.46
1985-11-29;202.54;203.40;201.92;202.17;84060000;202.17
1985-11-27;200.67;202.65;200.67;202.54;143700000;202.54
1985-11-26;200.35;201.16;200.11;200.67;123100000;200.67
1985-11-25;201.52;201.52;200.08;200.35;91710000;200.35
1985-11-22;201.41;202.01;201.05;201.52;133800000;201.52
1985-11-21;198.99;201.43;198.99;201.41;150300000;201.41
1985-11-20;198.67;199.20;198.52;198.99;105100000;198.99
1985-11-19;198.71;199.52;198.01;198.67;126100000;198.67
1985-11-18;198.11;198.71;197.51;198.71;108400000;198.71
1985-11-15;199.06;199.58;197.90;198.11;130200000;198.11
1985-11-14;197.10;199.19;196.88;199.06;124900000;199.06
1985-11-13;198.08;198.11;196.91;197.10;109700000;197.10
1985-11-12;197.28;198.66;196.97;198.08;170800000;198.08
1985-11-11;193.72;197.29;193.70;197.28;126500000;197.28
1985-11-08;192.62;193.97;192.53;193.72;115000000;193.72
1985-11-07;192.78;192.96;192.16;192.62;119000000;192.62
1985-11-06;192.37;193.01;191.83;192.76;129500000;192.76
1985-11-05;191.25;192.43;190.99;192.37;119200000;192.37
1985-11-04;191.45;191.96;190.66;191.25;104900000;191.25
1985-11-01;189.82;191.53;189.37;191.53;129400000;191.53
1985-10-31;190.07;190.15;189.35;189.82;121500000;189.82
1985-10-30;189.23;190.09;189.14;190.07;120400000;190.07
1985-10-29;187.76;189.78;187.76;189.23;110600000;189.23
1985-10-28;187.52;187.76;186.93;187.76;97880000;187.76
1985-10-25;188.50;188.51;187.32;187.52;101800000;187.52
1985-10-24;189.09;189.45;188.41;188.50;123100000;188.50
1985-10-23;188.04;189.09;188.04;189.09;121700000;189.09
1985-10-22;186.96;188.56;186.96;188.04;111300000;188.04
1985-10-21;187.04;187.30;186.79;186.96;95680000;186.96
1985-10-18;187.66;188.11;186.89;187.04;107100000;187.04
1985-10-17;187.98;188.52;187.42;187.66;140500000;187.66
1985-10-16;186.08;187.98;186.08;187.98;117400000;187.98
1985-10-15;186.37;187.16;185.66;186.08;110400000;186.08
1985-10-14;184.31;186.37;184.28;186.37;78540000;186.37
1985-10-11;182.78;184.28;182.61;184.28;96370000;184.28
1985-10-10;182.52;182.79;182.05;182.78;90910000;182.78
1985-10-09;181.87;183.27;181.87;182.52;99140000;182.52
1985-10-08;181.87;182.30;181.16;181.87;97170000;181.87
1985-10-07;183.22;183.22;181.30;181.87;95550000;181.87
1985-10-04;184.36;184.36;182.65;183.22;101200000;183.22
1985-10-03;184.06;185.17;183.59;184.36;127500000;184.36
1985-10-02;185.07;185.94;184.06;184.06;147300000;184.06
1985-10-01;182.06;185.08;182.02;185.07;130200000;185.07
1985-09-30;181.30;182.08;181.22;182.08;103600000;182.08
1985-09-26;180.66;181.29;179.45;181.29;106100000;181.29
1985-09-25;182.62;182.62;180.62;180.66;92120000;180.66
1985-09-24;184.30;184.30;182.42;182.62;97870000;182.62
1985-09-23;182.05;184.65;182.05;184.30;104800000;184.30
1985-09-20;183.39;183.99;182.04;182.05;101400000;182.05
1985-09-19;181.71;183.40;181.71;183.39;100300000;183.39
1985-09-18;181.36;181.83;180.81;181.71;105700000;181.71
1985-09-17;182.88;182.88;180.78;181.36;111900000;181.36
1985-09-16;182.91;182.91;182.45;182.88;66700000;182.88
1985-09-13;183.69;184.19;182.05;182.91;111400000;182.91
1985-09-12;185.03;185.21;183.49;183.69;107100000;183.69
1985-09-11;186.90;186.90;184.79;185.03;100400000;185.03
1985-09-10;188.25;188.26;186.50;186.90;104700000;186.90
1985-09-09;188.24;188.80;187.90;188.25;89850000;188.25
1985-09-06;187.27;188.43;187.27;188.24;95040000;188.24
1985-09-05;187.37;187.52;186.89;187.27;94480000;187.27
1985-09-04;187.91;187.92;186.97;187.37;85510000;187.37
1985-09-03;188.63;188.63;187.38;187.91;81190000;187.91
1985-08-30;188.93;189.13;188.00;188.63;81620000;188.63
1985-08-29;188.73;188.94;188.38;188.93;85660000;188.93
1985-08-28;188.10;188.83;187.90;188.83;88530000;188.83
1985-08-27;187.31;188.10;187.31;188.10;82140000;188.10
1985-08-26;187.17;187.44;186.46;187.31;70290000;187.31
1985-08-23;187.22;187.35;186.59;187.17;75270000;187.17
1985-08-22;189.11;189.23;187.20;187.36;90600000;187.36
1985-08-21;188.08;189.16;188.08;189.16;94880000;189.16
1985-08-20;186.38;188.27;186.38;188.08;91230000;188.08
1985-08-19;186.10;186.82;186.10;186.38;67930000;186.38
1985-08-16;187.26;187.26;186.10;186.10;87910000;186.10
1985-08-15;187.41;187.74;186.62;187.26;86100000;187.26
1985-08-14;187.30;187.87;187.30;187.41;85780000;187.41
1985-08-13;187.63;188.15;186.51;187.30;80300000;187.30
1985-08-12;188.32;188.32;187.43;187.63;77340000;187.63
1985-08-09;188.95;189.05;188.11;188.32;81750000;188.32
1985-08-08;187.68;188.96;187.68;188.95;102900000;188.95
1985-08-07;187.93;187.93;187.39;187.68;100000000;187.68
1985-08-06;190.62;190.72;187.87;187.93;104000000;187.93
1985-08-05;191.48;191.48;189.95;190.62;79610000;190.62
1985-08-02;192.11;192.11;191.27;191.48;87860000;191.48
1985-08-01;190.92;192.17;190.91;192.11;121500000;192.11
1985-07-31;189.93;191.33;189.93;190.92;124200000;190.92
1985-07-30;189.62;190.05;189.30;189.93;102300000;189.93
1985-07-29;192.40;192.42;189.53;189.60;95960000;189.60
1985-07-26;192.06;192.78;191.58;192.40;107000000;192.40
1985-07-25;191.58;192.23;191.17;192.06;123300000;192.06
1985-07-24;192.55;192.55;190.66;191.58;128600000;191.58
1985-07-23;194.35;194.98;192.28;192.55;143600000;192.55
1985-07-22;195.13;195.13;193.58;194.35;93540000;194.35
1985-07-19;194.38;195.13;194.28;195.13;114800000;195.13
1985-07-18;195.65;195.65;194.34;194.38;131400000;194.38
1985-07-17;194.86;196.07;194.72;195.65;159900000;195.65
1985-07-16;192.72;194.72;192.72;194.72;132500000;194.72
1985-07-15;193.29;193.84;192.55;192.72;103900000;192.72
1985-07-12;192.94;193.32;192.64;193.29;120300000;193.29
1985-07-11;192.37;192.95;192.28;192.94;122800000;192.94
1985-07-10;191.05;192.37;190.99;192.37;108200000;192.37
1985-07-09;191.93;191.93;190.81;191.05;99060000;191.05
1985-07-08;192.47;192.52;191.26;191.93;83670000;191.93
1985-07-05;191.45;192.67;191.45;192.52;62450000;192.52
1985-07-03;192.01;192.08;191.37;191.45;98410000;191.45
1985-07-02;192.43;192.63;191.84;192.01;111100000;192.01
1985-07-01;191.85;192.43;191.17;192.43;96080000;192.43
1985-06-28;191.23;191.85;191.04;191.85;105200000;191.85
1985-06-27;190.06;191.36;190.06;191.23;106700000;191.23
1985-06-26;189.74;190.26;189.44;190.06;94130000;190.06
1985-06-25;189.15;190.96;189.15;189.74;115700000;189.74
1985-06-24;188.77;189.61;187.84;189.15;96040000;189.15
1985-06-21;186.73;189.66;186.43;189.61;125400000;189.61
1985-06-20;186.63;186.74;185.97;186.73;87500000;186.73
1985-06-19;187.34;187.98;186.63;186.63;108300000;186.63
1985-06-18;186.53;187.65;186.51;187.34;106900000;187.34
1985-06-17;187.10;187.10;185.98;186.53;82170000;186.53
1985-06-14;185.33;187.10;185.33;187.10;93090000;187.10
1985-06-13;187.61;187.61;185.03;185.33;107000000;185.33
1985-06-12;189.04;189.04;187.59;187.61;97700000;187.61
1985-06-11;189.51;189.61;188.78;189.04;102100000;189.04
1985-06-10;189.68;189.68;188.82;189.51;87940000;189.51
1985-06-07;191.06;191.29;189.55;189.68;99630000;189.68
1985-06-06;189.75;191.06;189.13;191.06;117200000;191.06
1985-06-05;190.04;191.02;190.04;190.16;143900000;190.16
1985-06-04;189.32;190.27;188.88;190.04;115400000;190.04
1985-06-03;189.55;190.36;188.93;189.32;125000000;189.32
1985-05-31;187.75;189.59;187.45;189.55;134100000;189.55
1985-05-30;187.68;188.04;187.09;187.75;108300000;187.75
1985-05-29;187.86;187.86;187.11;187.68;96540000;187.68
1985-05-28;188.29;188.94;187.38;187.86;90600000;187.86
1985-05-24;187.60;188.29;187.29;188.29;85970000;188.29
1985-05-23;188.56;188.56;187.45;187.60;101000000;187.60
1985-05-22;189.64;189.64;187.71;188.56;101400000;188.56
1985-05-21;189.72;189.81;188.78;189.64;130200000;189.64
1985-05-20;187.42;189.98;187.42;189.72;146300000;189.72
1985-05-17;185.66;187.94;185.47;187.42;124600000;187.42
1985-05-16;184.54;185.74;184.54;185.66;99420000;185.66
1985-05-15;183.87;185.43;183.86;184.54;106100000;184.54
1985-05-14;184.61;185.17;183.65;183.87;97360000;183.87
1985-05-13;184.28;184.61;184.19;184.61;85830000;184.61
1985-05-10;181.92;184.74;181.92;184.28;140300000;184.28
1985-05-09;180.62;181.97;180.62;181.92;111000000;181.92
1985-05-08;180.76;180.76;179.96;180.62;101300000;180.62
1985-05-07;179.99;181.09;179.87;180.76;100200000;180.76
1985-05-06;180.08;180.56;179.82;179.99;85650000;179.99
1985-05-03;179.01;180.30;179.01;180.08;94870000;180.08
1985-05-02;178.37;179.01;178.37;179.01;107700000;179.01
1985-05-01;179.83;180.04;178.35;178.37;101600000;178.37
1985-04-30;180.63;180.63;178.86;179.83;111800000;179.83
1985-04-29;182.18;182.34;180.62;180.63;88860000;180.63
1985-04-26;183.43;183.61;182.11;182.18;86570000;182.18
1985-04-25;182.26;183.43;182.12;183.43;108600000;183.43
1985-04-24;181.88;182.27;181.74;182.26;99600000;182.26
1985-04-23;180.70;181.97;180.34;181.88;108900000;181.88
1985-04-22;181.11;181.23;180.25;180.70;79930000;180.70
1985-04-19;180.84;181.25;180.42;181.11;81110000;181.11
1985-04-18;181.68;182.56;180.75;180.84;100600000;180.84
1985-04-17;181.20;181.91;181.14;181.68;96020000;181.68
1985-04-16;180.92;181.78;180.19;181.20;98480000;181.20
1985-04-15;180.54;181.15;180.45;180.92;80660000;180.92
1985-04-12;180.19;180.55;180.06;180.54;86220000;180.54
1985-04-11;179.42;180.91;179.42;180.19;108400000;180.19
1985-04-10;178.21;179.90;178.21;179.42;108200000;179.42
1985-04-09;178.03;178.67;177.97;178.21;83980000;178.21
1985-04-08;179.03;179.46;177.86;178.03;79960000;178.03
1985-04-04;179.11;179.13;178.29;179.03;86910000;179.03
1985-04-03;180.53;180.53;178.64;179.11;95480000;179.11
1985-04-02;181.27;181.86;180.28;180.53;101700000;180.53
1985-04-01;180.66;181.27;180.43;181.27;89900000;181.27
1985-03-29;179.54;180.66;179.54;180.66;101400000;180.66
1985-03-28;179.54;180.60;179.43;179.54;99780000;179.54
1985-03-27;178.43;179.80;178.43;179.54;101000000;179.54
1985-03-26;177.97;178.86;177.88;178.43;89930000;178.43
1985-03-25;179.04;179.04;177.85;177.97;74040000;177.97
1985-03-22;179.35;179.92;178.86;179.04;99250000;179.04
1985-03-21;179.08;180.22;178.89;179.35;95930000;179.35
1985-03-20;179.54;179.78;178.79;179.08;107500000;179.08
1985-03-19;176.88;179.56;176.87;179.54;119200000;179.54
1985-03-18;176.53;177.66;176.53;176.88;94020000;176.88
1985-03-15;177.84;178.41;176.53;176.53;105200000;176.53
1985-03-14;178.19;178.53;177.61;177.84;103400000;177.84
1985-03-13;179.66;179.96;178.02;178.19;101700000;178.19
1985-03-12;178.79;180.14;178.70;179.66;92840000;179.66
1985-03-11;179.10;179.46;178.15;178.79;84110000;178.79
1985-03-08;179.51;179.97;179.07;179.10;96390000;179.10
1985-03-07;180.65;180.65;179.44;179.51;112100000;179.51
1985-03-06;182.23;182.25;180.59;180.65;116900000;180.65
1985-03-05;182.06;182.65;181.42;182.23;116400000;182.23
1985-03-04;183.23;183.41;181.40;182.06;102100000;182.06
1985-03-01;181.18;183.89;181.16;183.23;139900000;183.23
1985-02-28;180.71;181.21;180.33;181.18;100700000;181.18
1985-02-27;181.17;181.87;180.50;180.71;107700000;180.71
1985-02-26;179.23;181.58;179.16;181.17;114200000;181.17
1985-02-25;179.36;179.36;178.13;179.23;89740000;179.23
1985-02-22;180.19;180.41;179.23;179.36;93680000;179.36
1985-02-21;181.18;181.18;180.02;180.19;104000000;180.19
1985-02-20;181.33;182.10;180.64;181.18;118200000;181.18
1985-02-19;181.60;181.61;180.95;181.33;90400000;181.33
1985-02-15;182.41;182.65;181.23;181.60;106500000;181.60
1985-02-14;183.35;183.95;182.39;182.41;139700000;182.41
1985-02-13;180.56;183.86;180.50;183.35;142500000;183.35
1985-02-12;180.51;180.75;179.45;180.56;111100000;180.56
1985-02-11;182.19;182.19;180.11;180.51;104000000;180.51
1985-02-08;181.82;182.39;181.67;182.19;116500000;182.19
1985-02-07;180.43;181.96;180.43;181.82;151700000;181.82
1985-02-06;180.61;181.50;180.32;180.43;141000000;180.43
1985-02-05;180.35;181.53;180.07;180.61;143900000;180.61
1985-02-04;178.63;180.35;177.75;180.35;113700000;180.35
1985-02-01;179.63;179.63;178.44;178.63;105400000;178.63
1985-01-31;179.39;179.83;178.56;179.63;132500000;179.63
1985-01-30;179.18;180.27;179.05;179.39;170000000;179.39
1985-01-29;177.40;179.19;176.58;179.18;115700000;179.18
1985-01-28;177.35;178.19;176.56;177.40;128400000;177.40
1985-01-25;176.71;177.75;176.54;177.35;122400000;177.35
1985-01-24;177.30;178.16;176.56;176.71;160700000;176.71
1985-01-23;175.48;177.30;175.15;177.30;144400000;177.30
1985-01-22;175.23;176.63;175.14;175.48;174800000;175.48
1985-01-21;171.32;175.45;171.31;175.23;146800000;175.23
1985-01-18;170.73;171.42;170.66;171.32;104700000;171.32
1985-01-17;171.19;171.34;170.22;170.73;113600000;170.73
1985-01-16;170.81;171.94;170.41;171.19;135500000;171.19
1985-01-15;170.51;171.82;170.40;170.81;155300000;170.81
1985-01-14;167.91;170.55;167.58;170.51;124900000;170.51
1985-01-11;168.31;168.72;167.58;167.91;107600000;167.91
1985-01-10;165.18;168.31;164.99;168.31;124700000;168.31
1985-01-09;163.99;165.57;163.99;165.18;99230000;165.18
1985-01-08;164.24;164.59;163.91;163.99;92110000;163.99
1985-01-07;163.68;164.71;163.68;164.24;86190000;164.24
1985-01-04;164.55;164.55;163.36;163.68;77480000;163.68
1985-01-03;165.37;166.11;164.38;164.57;88880000;164.57
1985-01-02;167.20;167.20;165.19;165.37;67820000;165.37
1984-12-31;166.26;167.34;166.06;167.24;80260000;167.24
1984-12-28;165.75;166.32;165.67;166.26;77070000;166.26
1984-12-27;166.47;166.50;165.62;165.75;70100000;165.75
1984-12-26;166.76;166.76;166.29;166.47;46700000;166.47
1984-12-24;165.51;166.93;165.50;166.76;55550000;166.76
1984-12-21;166.34;166.38;164.62;165.51;101200000;165.51
1984-12-20;167.16;167.58;166.29;166.38;93220000;166.38
1984-12-19;168.11;169.03;166.84;167.16;139600000;167.16
1984-12-18;163.61;168.11;163.61;168.11;169000000;168.11
1984-12-17;162.69;163.63;162.44;163.61;89490000;163.61
1984-12-14;161.81;163.53;161.63;162.69;95060000;162.69
1984-12-13;162.63;162.92;161.54;161.81;80850000;161.81
1984-12-12;163.07;163.18;162.55;162.63;78710000;162.63
1984-12-11;162.83;163.18;162.56;163.07;80240000;163.07
1984-12-10;162.26;163.32;161.54;162.83;81140000;162.83
1984-12-07;162.76;163.31;162.26;162.26;81000000;162.26
1984-12-06;162.10;163.11;161.76;162.76;96560000;162.76
1984-12-05;163.38;163.40;161.93;162.10;88700000;162.10
1984-12-04;162.82;163.91;162.82;163.38;81250000;163.38
1984-12-03;163.58;163.58;162.29;162.82;95300000;162.82
1984-11-30;163.91;163.91;162.99;163.58;77580000;163.58
1984-11-29;165.02;165.02;163.78;163.91;75860000;163.91
1984-11-28;166.29;166.90;164.97;165.02;86300000;165.02
1984-11-27;165.55;166.85;165.07;166.29;95470000;166.29
1984-11-26;166.92;166.92;165.37;165.55;76520000;165.55
1984-11-23;164.52;166.92;164.52;166.92;73910000;166.92
1984-11-21;164.18;164.68;163.29;164.51;81620000;164.51
1984-11-20;163.10;164.47;163.10;164.18;83240000;164.18
1984-11-19;164.10;164.34;163.03;163.09;69730000;163.09
1984-11-16;165.89;166.24;164.09;164.10;83140000;164.10
1984-11-15;165.99;166.49;165.61;165.89;81530000;165.89
1984-11-14;165.97;166.43;165.39;165.99;73940000;165.99
1984-11-13;167.36;167.38;165.79;165.97;69790000;165.97
1984-11-12;167.65;167.65;166.67;167.36;55610000;167.36
1984-11-09;168.68;169.46;167.44;167.60;83620000;167.60
1984-11-08;169.19;169.27;168.27;168.68;88580000;168.68
1984-11-07;170.41;170.41;168.44;169.17;110800000;169.17
1984-11-06;168.58;170.41;168.58;170.41;101200000;170.41
1984-11-05;167.42;168.65;167.33;168.58;84730000;168.58
1984-11-02;167.49;167.95;167.24;167.42;96810000;167.42
1984-11-01;166.09;167.83;166.09;167.49;107300000;167.49
1984-10-31;166.74;166.95;165.99;166.09;91890000;166.09
1984-10-30;164.78;167.33;164.78;166.84;95200000;166.84
1984-10-29;165.29;165.29;164.67;164.78;63200000;164.78
1984-10-26;166.31;166.31;164.93;165.29;83900000;165.29
1984-10-25;167.20;167.62;166.17;166.31;92760000;166.31
1984-10-24;167.09;167.54;166.82;167.20;91620000;167.20
1984-10-23;167.36;168.27;166.83;167.09;92260000;167.09
1984-10-22;167.96;168.36;167.26;167.36;81020000;167.36
1984-10-19;168.08;169.62;167.31;167.96;186900000;167.96
1984-10-18;164.14;168.10;163.80;168.10;149500000;168.10
1984-10-17;164.78;165.04;163.71;164.14;99740000;164.14
1984-10-16;165.78;165.78;164.66;164.78;82930000;164.78
1984-10-15;164.18;166.15;164.09;165.77;87590000;165.77
1984-10-12;162.78;164.47;162.78;164.18;92190000;164.18
1984-10-11;162.11;162.87;162.00;162.78;87020000;162.78
1984-10-10;161.67;162.12;160.02;162.11;94270000;162.11
1984-10-09;162.13;162.84;161.62;161.67;76840000;161.67
1984-10-08;162.68;162.68;161.80;162.13;46360000;162.13
1984-10-05;162.92;163.32;162.51;162.68;82950000;162.68
1984-10-04;162.44;163.22;162.44;162.92;76700000;162.92
1984-10-03;163.59;163.59;162.20;162.44;92400000;162.44
1984-10-02;164.62;165.24;163.55;163.59;89360000;163.59
1984-10-01;166.10;166.10;164.48;164.62;73630000;164.62
1984-09-28;166.96;166.96;165.77;166.10;78950000;166.10
1984-09-27;166.75;167.18;166.33;166.96;88880000;166.96
1984-09-26;165.62;167.20;165.61;166.28;100200000;166.28
1984-09-25;165.28;165.97;164.45;165.62;86250000;165.62
1984-09-24;165.67;166.12;164.98;165.28;76380000;165.28
1984-09-21;167.47;168.67;165.66;165.67;120600000;165.67
1984-09-20;166.94;167.47;166.70;167.47;92030000;167.47
1984-09-19;167.65;168.76;166.89;166.94;119900000;166.94
1984-09-18;168.87;168.87;167.64;167.65;107700000;167.65
1984-09-17;168.78;169.37;167.99;168.87;88790000;168.87
1984-09-14;167.94;169.65;167.94;168.78;137400000;168.78
1984-09-13;164.68;167.94;164.68;167.94;110500000;167.94
1984-09-12;164.45;164.81;164.14;164.68;77980000;164.68
1984-09-11;165.22;166.17;164.28;164.45;101300000;164.45
1984-09-10;164.37;165.05;163.06;164.26;74410000;164.26
1984-09-07;165.65;166.31;164.22;164.37;84110000;164.37
1984-09-06;164.29;165.95;164.29;165.65;91920000;165.65
1984-09-05;164.88;164.88;163.84;164.29;69250000;164.29
1984-09-04;166.68;166.68;164.73;164.88;62110000;164.88
1984-08-31;166.60;166.68;165.78;166.68;57460000;166.68
1984-08-30;167.10;167.19;166.55;166.60;70840000;166.60
1984-08-29;167.40;168.21;167.03;167.09;90660000;167.09
1984-08-28;166.44;167.43;166.21;167.40;70560000;167.40
1984-08-27;167.51;167.51;165.81;166.44;57660000;166.44
1984-08-24;167.12;167.52;167.12;167.51;69640000;167.51
1984-08-23;167.06;167.78;166.61;167.12;83130000;167.12
1984-08-22;167.83;168.80;166.92;167.06;116000000;167.06
1984-08-21;164.94;168.22;164.93;167.83;128100000;167.83
1984-08-20;164.14;164.94;163.76;164.94;75450000;164.94
1984-08-17;164.30;164.61;163.78;164.14;71500000;164.14
1984-08-16;162.80;164.42;162.75;163.77;93610000;163.77
1984-08-15;164.42;164.42;162.75;162.80;91880000;162.80
1984-08-14;165.43;166.09;164.28;164.42;81470000;164.42
1984-08-13;164.84;165.49;163.98;165.43;77960000;165.43
1984-08-10;165.54;168.59;165.24;165.42;171000000;165.42
1984-08-09;161.75;165.88;161.47;165.54;131100000;165.54
1984-08-08;162.71;163.87;161.75;161.75;121200000;161.75
1984-08-07;162.60;163.58;160.81;162.72;127900000;162.72
1984-08-06;162.35;165.27;162.09;162.60;203000000;162.60
1984-08-03;160.28;162.56;158.00;162.35;236500000;162.35
1984-08-02;154.08;157.99;154.08;157.99;172800000;157.99
1984-08-01;150.66;154.08;150.66;154.08;127500000;154.08
1984-07-31;150.19;150.77;149.65;150.66;86910000;150.66
1984-07-30;151.19;151.19;150.14;150.19;72330000;150.19
1984-07-27;150.08;151.38;149.99;151.19;101350000;151.19
1984-07-26;148.83;150.16;148.83;150.08;90410000;150.08
1984-07-25;147.82;149.30;147.26;148.83;90520000;148.83
1984-07-24;148.95;149.28;147.78;147.82;74370000;147.82
1984-07-23;149.55;149.55;147.85;148.95;77990000;148.95
1984-07-20;150.37;150.58;149.07;149.55;79090000;149.55
1984-07-19;151.40;151.40;150.27;150.37;85230000;150.37
1984-07-18;152.38;152.38;151.11;151.40;76640000;151.40
1984-07-17;151.60;152.60;151.26;152.38;82890000;152.38
1984-07-16;150.88;151.60;150.01;151.60;73420000;151.60
1984-07-13;150.03;151.16;150.03;150.88;75480000;150.88
1984-07-12;150.56;151.06;149.63;150.03;86050000;150.03
1984-07-11;152.89;152.89;150.55;150.56;89540000;150.56
1984-07-10;153.36;153.53;152.57;152.89;74010000;152.89
1984-07-09;152.24;153.53;151.44;153.36;74830000;153.36
1984-07-06;152.76;152.76;151.63;152.24;65850000;152.24
1984-07-05;153.70;153.87;152.71;152.76;66100000;152.76
1984-07-03;153.20;153.86;153.10;153.70;69960000;153.70
1984-07-02;153.16;153.22;152.44;153.20;69230000;153.20
1984-06-29;152.84;154.08;152.82;153.18;90770000;153.18
1984-06-28;151.64;153.07;151.62;152.84;77660000;152.84
1984-06-27;152.71;152.88;151.30;151.64;78400000;151.64
1984-06-26;153.97;153.97;152.47;152.71;82600000;152.71
1984-06-25;154.46;154.67;153.86;153.97;72850000;153.97
1984-06-22;154.51;154.92;153.89;154.46;98400000;154.46
1984-06-21;154.84;155.64;154.05;154.51;123380000;154.51
1984-06-20;151.89;154.84;150.96;154.84;99090000;154.84
1984-06-19;151.73;153.00;151.73;152.61;98000000;152.61
1984-06-18;149.03;151.92;148.53;151.73;94900000;151.73
1984-06-15;150.49;150.71;149.02;149.03;85460000;149.03
1984-06-14;152.12;152.14;150.31;150.39;79120000;150.39
1984-06-13;152.19;152.85;151.86;152.13;67510000;152.13
1984-06-12;153.06;153.07;151.61;152.19;84660000;152.19
1984-06-11;155.17;155.17;153.00;153.06;69050000;153.06
1984-06-08;154.92;155.40;154.57;155.17;67840000;155.17
1984-06-07;155.01;155.11;154.36;154.92;82120000;154.92
1984-06-06;153.65;155.03;153.38;155.01;83440000;155.01
1984-06-05;154.34;154.34;153.28;153.65;84840000;153.65
1984-06-04;153.24;155.10;153.24;154.34;96740000;154.34
1984-06-01;150.55;153.24;150.55;153.24;96040000;153.24
1984-05-31;150.35;150.69;149.76;150.55;81890000;150.55
1984-05-30;150.29;151.43;148.68;150.35;105660000;150.35
1984-05-29;151.62;151.86;149.95;150.29;69060000;150.29
1984-05-25;151.23;152.02;150.85;151.62;78190000;151.62
1984-05-24;153.15;153.15;150.80;151.23;99040000;151.23
1984-05-23;153.88;154.02;153.10;153.15;82690000;153.15
1984-05-22;154.73;154.73;152.99;153.88;88030000;153.88
1984-05-21;155.78;156.11;154.63;154.73;73380000;154.73
1984-05-18;156.57;156.77;155.24;155.78;81270000;155.78
1984-05-17;157.99;157.99;156.15;156.57;90310000;156.57
1984-05-16;158.00;158.41;157.83;157.99;89210000;157.99
1984-05-15;157.50;158.27;157.29;158.00;88250000;158.00
1984-05-14;158.49;158.49;157.20;157.50;64900000;157.50
1984-05-11;160.00;160.00;157.42;158.49;82780000;158.49
1984-05-10;160.11;160.45;159.61;160.00;101810000;160.00
1984-05-09;160.52;161.31;159.39;160.11;100590000;160.11
1984-05-08;159.47;160.52;159.14;160.52;81610000;160.52
1984-05-07;159.11;159.48;158.63;159.47;72760000;159.47
1984-05-04;161.20;161.20;158.93;159.11;98580000;159.11
1984-05-03;161.90;161.90;160.95;161.20;91910000;161.20
1984-05-02;161.68;162.11;161.41;161.90;107080000;161.90
1984-05-01;160.05;161.69;160.05;161.68;110550000;161.68
1984-04-30;159.89;160.43;159.30;160.05;72740000;160.05
1984-04-27;160.30;160.69;159.77;159.89;88530000;159.89
1984-04-26;158.65;160.50;158.65;160.30;98000000;160.30
1984-04-25;158.07;158.77;157.80;158.65;83520000;158.65
1984-04-24;156.80;158.38;156.61;158.07;87060000;158.07
1984-04-23;158.02;158.05;156.79;156.80;73080000;156.80
1984-04-19;157.90;158.02;157.10;158.02;75860000;158.02
1984-04-18;158.97;158.97;157.64;157.90;85040000;157.90
1984-04-17;158.32;159.59;158.32;158.97;98150000;158.97
1984-04-16;157.31;158.35;156.49;158.32;73870000;158.32
1984-04-13;157.73;158.87;157.13;157.31;99620000;157.31
1984-04-12;155.00;157.74;154.17;157.73;96330000;157.73
1984-04-11;155.93;156.31;154.90;155.00;80280000;155.00
1984-04-10;155.45;156.57;155.45;155.87;78990000;155.87
1984-04-09;155.48;155.86;154.71;155.45;71570000;155.45
1984-04-06;155.04;155.48;154.12;155.48;86620000;155.48
1984-04-05;157.54;158.10;154.96;155.04;101750000;155.04
1984-04-04;157.66;158.11;157.29;157.54;92860000;157.54
1984-04-03;157.99;158.27;157.17;157.66;87980000;157.66
1984-04-02;159.18;159.87;157.63;157.98;85680000;157.98
1984-03-30;159.52;159.52;158.92;159.18;71590000;159.18
1984-03-29;159.88;160.46;159.52;159.52;81470000;159.52
1984-03-28;157.30;159.90;157.30;159.88;104870000;159.88
1984-03-27;156.67;157.30;156.61;157.30;73670000;157.30
1984-03-26;156.86;157.18;156.31;156.67;69070000;156.67
1984-03-23;156.69;156.92;156.02;156.86;79760000;156.86
1984-03-22;158.66;158.67;156.61;156.69;87340000;156.69
1984-03-21;158.86;159.26;158.59;158.66;87170000;158.66
1984-03-20;157.78;159.17;157.78;158.86;86460000;158.86
1984-03-19;159.27;159.27;157.28;157.78;64060000;157.78
1984-03-16;157.41;160.45;157.41;159.27;118000000;159.27
1984-03-15;156.78;158.05;156.73;157.41;79520000;157.41
1984-03-14;156.78;157.17;156.22;156.77;77250000;156.77
1984-03-13;156.34;157.93;156.34;156.78;102600000;156.78
1984-03-12;154.35;156.35;154.35;156.34;84470000;156.34
1984-03-09;155.12;155.19;153.77;154.35;73170000;154.35
1984-03-08;154.57;155.80;154.35;155.19;80630000;155.19
1984-03-07;156.25;156.25;153.81;154.57;90080000;154.57
1984-03-06;157.89;158.37;156.21;156.25;83590000;156.25
1984-03-05;159.24;159.24;157.59;157.89;69870000;157.89
1984-03-02;158.19;159.90;158.19;159.24;108270000;159.24
1984-03-01;157.06;158.19;156.77;158.19;82010000;158.19
1984-02-29;156.82;158.27;156.41;157.06;92810000;157.06
1984-02-28;159.30;159.30;156.59;156.82;91010000;156.82
1984-02-27;157.51;159.58;157.08;159.30;99140000;159.30
1984-02-24;154.31;157.51;154.29;157.51;102620000;157.51
1984-02-23;154.02;154.45;152.13;154.29;100220000;154.29
1984-02-22;154.52;155.10;153.94;154.31;90080000;154.31
1984-02-21;155.71;155.74;154.47;154.64;71890000;154.64
1984-02-17;156.13;156.80;155.51;155.74;76600000;155.74
1984-02-16;155.94;156.44;155.44;156.13;81750000;156.13
1984-02-15;156.61;157.48;156.10;156.25;94870000;156.25
1984-02-14;154.95;156.61;154.95;156.61;91800000;156.61
1984-02-13;156.30;156.32;154.13;154.95;78460000;154.95
1984-02-10;155.42;156.52;155.42;156.30;92220000;156.30
1984-02-09;155.85;156.17;154.30;155.42;128190000;155.42
1984-02-08;158.74;159.07;155.67;155.85;96890000;155.85
1984-02-07;157.91;158.81;157.01;158.74;107640000;158.74
1984-02-06;160.91;160.91;158.02;158.08;109090000;158.08
1984-02-03;163.44;163.98;160.82;160.91;109100000;160.91
1984-02-02;162.74;163.36;162.24;163.36;111330000;163.36
1984-02-01;163.41;164.00;162.27;162.74;107100000;162.74
1984-01-31;162.87;163.60;162.03;163.41;113510000;163.41
1984-01-30;164.40;164.67;162.40;162.87;103120000;162.87
1984-01-27;164.24;164.33;163.07;163.94;103720000;163.94
1984-01-26;164.84;165.55;164.12;164.24;111100000;164.24
1984-01-25;165.94;167.12;164.74;164.84;113470000;164.84
1984-01-24;164.87;166.35;164.84;165.94;103050000;165.94
1984-01-23;166.21;166.21;164.83;164.87;82010000;164.87
1984-01-20;167.04;167.06;165.87;166.21;93360000;166.21
1984-01-19;167.55;167.65;166.67;167.04;98340000;167.04
1984-01-18;167.83;168.34;167.02;167.55;109010000;167.55
1984-01-17;167.18;167.84;167.01;167.83;92750000;167.83
1984-01-16;167.02;167.55;166.77;167.18;93790000;167.18
1984-01-13;167.75;168.59;166.64;167.02;101790000;167.02
1984-01-12;167.79;168.40;167.68;167.75;99410000;167.75
1984-01-11;167.95;168.07;167.27;167.80;98660000;167.80
1984-01-10;168.90;169.54;167.87;167.95;109570000;167.95
1984-01-09;169.18;169.46;168.48;168.90;107100000;168.90
1984-01-06;168.81;169.31;168.49;169.28;137590000;169.28
1984-01-05;166.78;169.10;166.78;168.81;159990000;168.81
1984-01-04;164.09;166.78;164.04;166.78;112980000;166.78
1984-01-03;164.93;164.93;163.98;164.04;71340000;164.04
1983-12-30;164.86;165.05;164.58;164.93;71840000;164.93
1983-12-29;165.33;165.84;164.83;164.86;86560000;164.86
1983-12-28;164.69;165.34;164.30;165.34;85660000;165.34
1983-12-27;163.22;164.76;163.22;164.76;63800000;164.76
1983-12-23;163.27;163.31;162.90;163.22;62710000;163.22
1983-12-22;163.56;164.18;163.17;163.53;106260000;163.53
1983-12-21;162.00;163.57;161.99;163.56;108080000;163.56
1983-12-20;162.33;162.80;161.64;162.00;83740000;162.00
1983-12-19;162.34;162.88;162.27;162.32;75180000;162.32
1983-12-16;161.69;162.39;161.58;162.39;81030000;162.39
1983-12-15;163.33;163.33;161.66;161.66;88300000;161.66
1983-12-14;164.93;164.93;163.25;163.33;85430000;163.33
1983-12-13;165.62;165.63;164.85;164.93;93500000;164.93
1983-12-12;165.13;165.62;164.99;165.62;77340000;165.62
1983-12-09;165.20;165.29;164.50;165.08;98280000;165.08
1983-12-08;165.91;166.01;164.86;165.20;96530000;165.20
1983-12-07;165.47;166.34;165.35;165.91;105670000;165.91
1983-12-06;165.77;165.93;165.34;165.47;89690000;165.47
1983-12-05;165.44;165.79;164.71;165.76;88330000;165.76
1983-12-02;166.49;166.70;165.25;165.44;93960000;165.44
1983-12-01;166.37;166.77;166.08;166.49;106970000;166.49
1983-11-30;167.91;168.07;166.33;166.40;120130000;166.40
1983-11-29;166.54;167.92;166.17;167.91;100460000;167.91
1983-11-28;167.20;167.22;166.21;166.54;78210000;166.54
1983-11-25;167.02;167.20;166.73;167.18;57820000;167.18
1983-11-23;166.88;167.21;166.26;166.96;108080000;166.96
1983-11-22;166.05;167.26;166.05;166.84;117550000;166.84
1983-11-21;165.04;166.05;165.00;166.05;97740000;166.05
1983-11-18;166.08;166.13;164.50;165.09;88280000;165.09
1983-11-17;166.08;166.49;165.51;166.13;80740000;166.13
1983-11-16;165.36;166.41;165.34;166.08;83380000;166.08
1983-11-15;166.58;166.59;165.28;165.36;77840000;165.36
1983-11-14;166.29;167.58;166.27;166.58;86880000;166.58
1983-11-11;164.41;166.30;164.34;166.29;74270000;166.29
1983-11-10;163.99;164.71;163.97;164.41;88730000;164.41
1983-11-09;161.74;163.97;161.74;163.97;83100000;163.97
1983-11-08;161.91;162.15;161.63;161.76;64900000;161.76
1983-11-07;162.42;162.56;161.84;161.91;69400000;161.91
1983-11-04;162.68;163.45;162.22;162.44;72080000;162.44
1983-11-03;164.84;164.85;163.42;163.45;85350000;163.45
1983-11-02;165.21;165.21;163.55;164.84;95210000;164.84
1983-11-01;163.55;163.66;162.37;163.66;84460000;163.66
1983-10-31;163.37;164.58;162.86;163.55;79460000;163.55
1983-10-28;164.89;165.19;163.23;163.37;81180000;163.37
1983-10-27;165.31;165.38;164.41;164.84;79570000;164.84
1983-10-26;166.49;166.65;165.36;165.38;79570000;165.38
1983-10-25;166.00;167.15;166.00;166.47;82530000;166.47
1983-10-24;165.85;165.99;163.85;165.99;85420000;165.99
1983-10-21;166.97;167.23;164.98;165.95;91640000;165.95
1983-10-20;166.77;167.35;166.44;166.98;86000000;166.98
1983-10-19;167.81;167.81;165.67;166.73;107790000;166.73
1983-10-18;170.41;170.41;167.67;167.81;91080000;167.81
1983-10-17;169.85;171.18;169.63;170.43;77730000;170.43
1983-10-14;169.88;169.99;169.18;169.86;71600000;169.86
1983-10-13;169.63;170.12;169.13;169.87;67750000;169.87
1983-10-12;170.34;170.84;169.34;169.62;75630000;169.62
1983-10-11;172.59;172.59;170.34;170.34;79510000;170.34
1983-10-10;170.77;172.65;170.05;172.65;67050000;172.65
1983-10-07;170.32;171.10;170.31;170.80;103630000;170.80
1983-10-06;167.76;170.28;167.76;170.28;118270000;170.28
1983-10-05;166.29;167.74;165.92;167.74;101710000;167.74
1983-10-04;165.81;166.80;165.81;166.27;90270000;166.27
1983-10-03;165.99;166.07;164.93;165.81;77230000;165.81
1983-09-30;167.23;167.23;165.63;166.07;70860000;166.07
1983-09-29;168.02;168.35;167.23;167.23;73730000;167.23
1983-09-28;168.42;168.53;167.52;168.00;75820000;168.00
1983-09-27;170.02;170.02;167.95;168.43;81100000;168.43
1983-09-26;169.53;170.41;169.16;170.07;86400000;170.07
1983-09-23;169.76;170.17;168.88;169.51;93180000;169.51
1983-09-22;168.40;169.78;168.22;169.76;97050000;169.76
1983-09-21;169.27;169.30;168.21;168.41;91280000;168.41
1983-09-20;167.64;169.38;167.64;169.24;103050000;169.24
1983-09-19;166.27;168.09;166.26;167.62;85630000;167.62
1983-09-16;164.42;166.57;164.39;166.25;75530000;166.25
1983-09-15;165.39;165.58;164.38;164.38;70420000;164.38
1983-09-14;164.80;165.42;164.63;165.35;73370000;165.35
1983-09-13;165.48;165.48;164.17;164.80;73970000;164.80
1983-09-12;166.95;169.20;165.27;165.48;114020000;165.48
1983-09-09;167.77;167.77;166.91;166.92;77990000;166.92
1983-09-08;167.96;168.14;167.12;167.77;79250000;167.77
1983-09-07;167.90;168.48;167.46;167.96;94240000;167.96
1983-09-06;165.20;167.90;165.03;167.89;87500000;167.89
1983-09-02;164.25;165.07;164.21;165.00;59300000;165.00
1983-09-01;164.40;164.66;163.95;164.23;76120000;164.23
1983-08-31;162.55;164.40;162.32;164.40;80800000;164.40
1983-08-30;162.25;163.13;162.11;162.58;62370000;162.58
1983-08-29;162.14;162.32;160.97;162.25;53030000;162.25
1983-08-26;160.85;162.16;160.25;162.14;61650000;162.14
1983-08-25;161.27;161.28;159.96;160.84;70140000;160.84
1983-08-24;162.77;162.77;161.20;161.25;72200000;161.25
1983-08-23;164.33;164.33;162.54;162.77;66800000;162.77
1983-08-22;164.18;165.64;163.77;164.34;76420000;164.34
1983-08-19;163.58;164.27;163.22;163.98;58950000;163.98
1983-08-18;165.29;165.91;163.55;163.55;82280000;163.55
1983-08-17;163.58;165.40;163.43;165.29;87800000;165.29
1983-08-16;163.74;163.84;162.72;163.41;71780000;163.41
1983-08-15;162.22;164.76;162.22;163.70;83200000;163.70
1983-08-12;161.55;162.60;161.55;162.16;71840000;162.16
1983-08-11;161.55;162.14;161.41;161.54;70630000;161.54
1983-08-10;160.11;161.77;159.47;161.54;82900000;161.54
1983-08-09;159.20;160.14;158.50;160.13;81420000;160.13
1983-08-08;161.73;161.73;159.18;159.18;71460000;159.18
1983-08-05;161.33;161.88;160.89;161.74;67850000;161.74
1983-08-04;163.28;163.42;159.63;161.33;100870000;161.33
1983-08-03;162.01;163.44;161.52;163.44;80370000;163.44
1983-08-02;162.06;163.04;161.97;162.01;74460000;162.01
1983-08-01;162.34;162.78;161.55;162.04;77210000;162.04
1983-07-29;165.03;165.03;161.50;162.56;95240000;162.56
1983-07-28;167.32;167.79;164.99;165.04;78410000;165.04
1983-07-27;170.68;170.72;167.49;167.59;99290000;167.59
1983-07-26;169.62;170.63;169.26;170.53;91280000;170.53
1983-07-25;167.67;169.74;167.63;169.53;73680000;169.53
1983-07-22;168.51;169.08;168.40;168.89;68850000;168.89
1983-07-21;169.29;169.80;168.33;169.06;101830000;169.06
1983-07-20;164.89;169.29;164.89;169.29;109310000;169.29
1983-07-19;163.95;165.18;163.95;164.82;74030000;164.82
1983-07-18;164.28;164.29;163.30;163.95;69110000;163.95
1983-07-15;166.01;166.04;164.03;164.29;63160000;164.29
1983-07-14;165.61;166.96;165.61;166.01;83500000;166.01
1983-07-13;165.00;165.68;164.77;165.46;68900000;165.46
1983-07-12;168.05;168.05;165.51;165.53;70220000;165.53
1983-07-11;167.09;168.11;167.09;168.11;61610000;168.11
1983-07-08;167.56;167.98;166.95;167.08;66520000;167.08
1983-07-07;168.48;169.15;167.08;167.56;97130000;167.56
1983-07-06;166.71;168.88;166.49;168.48;85670000;168.48
1983-07-05;166.55;168.80;165.80;166.60;67320000;166.60
1983-07-01;168.11;168.64;167.77;168.64;65110000;168.64
1983-06-30;167.64;167.64;167.64;167.64;76310000;167.64
1983-06-29;165.78;166.64;165.43;166.64;81580000;166.64
1983-06-28;168.45;168.81;165.67;165.68;82730000;165.68
1983-06-27;170.40;170.46;168.32;168.46;69360000;168.46
1983-06-24;170.57;170.69;170.03;170.41;80810000;170.41
1983-06-23;170.99;171.00;170.13;170.57;89590000;170.57
1983-06-22;170.53;171.60;170.42;170.99;110270000;170.99
1983-06-21;169.03;170.60;168.25;170.53;102880000;170.53
1983-06-20;169.13;170.10;168.59;169.02;84270000;169.02
1983-06-17;169.11;169.64;168.60;169.13;93630000;169.13
1983-06-16;167.11;169.38;167.11;169.14;124560000;169.14
1983-06-15;165.52;167.12;165.07;167.12;93410000;167.12
1983-06-14;164.87;165.93;164.87;165.53;97710000;165.53
1983-06-13;162.70;164.84;162.70;164.84;90700000;164.84
1983-06-10;161.86;162.76;161.86;162.68;78470000;162.68
1983-06-09;161.37;161.92;160.80;161.83;87440000;161.83
1983-06-08;162.78;162.78;161.35;161.36;96600000;161.36
1983-06-07;164.84;164.93;162.77;162.77;88550000;162.77
1983-06-06;164.43;165.09;163.75;164.83;87670000;164.83
1983-06-03;163.96;164.79;163.96;164.42;83110000;164.42
1983-06-02;162.56;164.00;162.56;163.98;89750000;163.98
1983-06-01;162.38;162.64;161.33;162.55;84460000;162.55
1983-05-31;164.44;164.44;162.12;162.39;73910000;162.39
1983-05-27;165.49;165.49;164.33;164.46;76290000;164.46
1983-05-26;166.22;166.39;165.27;165.48;94980000;165.48
1983-05-25;165.54;166.21;164.79;166.21;121050000;166.21
1983-05-24;163.45;165.59;163.45;165.54;109850000;165.54
1983-05-23;162.06;163.50;160.29;163.43;84960000;163.43
1983-05-20;161.97;162.14;161.25;162.14;73150000;162.14
1983-05-19;163.27;163.61;161.98;161.99;83260000;161.99
1983-05-18;163.73;165.18;163.16;163.27;99780000;163.27
1983-05-17;163.40;163.71;162.55;163.71;79510000;163.71
1983-05-16;164.90;164.90;162.33;163.40;76250000;163.40
1983-05-13;164.26;165.23;164.26;164.91;83110000;164.91
1983-05-12;164.98;165.35;163.82;164.25;84060000;164.25
1983-05-11;165.95;166.30;164.53;164.96;99820000;164.96
1983-05-10;165.82;166.40;165.74;165.95;104010000;165.95
1983-05-09;166.10;166.46;164.90;165.81;93670000;165.81
1983-05-06;164.30;166.99;164.30;166.10;128200000;166.10
1983-05-05;163.35;164.30;163.35;164.28;107860000;164.28
1983-05-04;162.38;163.64;162.38;163.31;101690000;163.31
1983-05-03;162.10;162.35;160.80;162.34;89550000;162.34
1983-05-02;164.41;164.42;161.99;162.11;88170000;162.11
1983-04-29;162.97;164.43;162.72;164.43;105750000;164.43
1983-04-28;161.44;162.96;161.44;162.95;94410000;162.95
1983-04-27;161.85;162.77;160.76;161.44;118140000;161.44
1983-04-26;158.81;161.81;158.07;161.81;91210000;161.81
1983-04-25;160.43;160.83;158.72;158.81;90150000;158.81
1983-04-22;160.04;160.76;160.02;160.42;92270000;160.42
1983-04-21;160.73;161.08;159.96;160.05;106170000;160.05
1983-04-20;158.71;160.83;158.71;160.71;110240000;160.71
1983-04-19;159.74;159.74;158.54;158.71;91210000;158.71
1983-04-18;158.75;159.75;158.41;159.74;88560000;159.74
1983-04-15;158.11;158.75;158.11;158.75;89590000;158.75
1983-04-14;156.80;158.12;156.55;158.12;90160000;158.12
1983-04-13;155.82;157.22;155.82;156.77;100520000;156.77
1983-04-12;155.15;155.82;154.78;155.82;79900000;155.82
1983-04-11;152.87;155.14;152.87;155.14;81440000;155.14
1983-04-08;151.77;152.85;151.39;152.85;67710000;152.85
1983-04-07;151.04;151.76;150.81;151.76;69480000;151.76
1983-04-06;151.90;151.90;150.17;151.04;77140000;151.04
1983-04-05;153.04;153.92;151.81;151.90;76810000;151.90
1983-04-04;152.92;153.02;152.23;153.02;66010000;153.02
1983-03-31;153.41;155.02;152.86;152.96;100570000;152.96
1983-03-30;151.60;153.39;151.60;153.39;75800000;153.39
1983-03-29;151.85;152.46;151.42;151.59;65300000;151.59
1983-03-28;152.67;152.67;151.56;151.85;58510000;151.85
1983-03-25;153.37;153.71;152.30;152.67;77330000;152.67
1983-03-24;152.82;153.78;152.82;153.37;92340000;153.37
1983-03-23;150.65;152.98;150.65;152.81;94980000;152.81
1983-03-22;151.21;151.59;150.60;150.66;79610000;150.66
1983-03-21;149.82;151.20;149.32;151.19;72160000;151.19
1983-03-18;149.59;150.29;149.56;149.90;75110000;149.90
1983-03-17;149.80;149.80;149.12;149.59;70290000;149.59
1983-03-16;151.36;151.62;149.78;149.81;83570000;149.81
1983-03-15;150.83;151.37;150.40;151.37;62410000;151.37
1983-03-14;151.28;151.30;150.24;150.83;61890000;150.83
1983-03-11;151.75;151.75;150.65;151.24;67240000;151.24
1983-03-10;152.87;154.01;151.75;151.80;95410000;151.80
1983-03-09;151.25;152.87;150.84;152.87;84250000;152.87
1983-03-08;153.63;153.63;151.26;151.26;79410000;151.26
1983-03-07;153.67;154.00;152.65;153.67;84020000;153.67
1983-03-04;153.47;153.67;152.53;153.67;90930000;153.67
1983-03-03;152.31;154.16;152.31;153.48;114440000;153.48
1983-03-02;150.91;152.63;150.91;152.30;112600000;152.30
1983-03-01;148.07;150.88;148.07;150.88;103750000;150.88
1983-02-28;149.74;149.74;147.81;148.06;83750000;148.06
1983-02-25;149.60;150.88;149.60;149.74;100970000;149.74
1983-02-24;146.80;149.67;146.80;149.60;113220000;149.60
1983-02-23;145.47;146.79;145.40;146.79;84100000;146.79
1983-02-22;148.01;148.11;145.42;145.48;84080000;145.48
1983-02-18;147.44;148.29;147.21;148.00;77420000;148.00
1983-02-17;147.43;147.57;143.84;147.44;74930000;147.44
1983-02-16;148.31;148.66;147.41;147.43;82100000;147.43
1983-02-15;148.94;149.41;148.13;148.30;89040000;148.30
1983-02-14;147.71;149.14;147.40;148.93;72640000;148.93
1983-02-11;147.51;148.81;147.18;147.65;86700000;147.65
1983-02-10;145.04;147.75;145.04;147.50;93510000;147.50
1983-02-09;145.70;145.83;144.09;145.00;84520000;145.00
1983-02-08;146.93;147.21;145.52;145.70;76580000;145.70
1983-02-07;146.14;147.42;146.14;146.93;86030000;146.93
1983-02-04;144.26;146.14;144.14;146.14;87000000;146.14
1983-02-03;143.25;144.43;143.25;144.26;78890000;144.26
1983-02-02;142.95;143.52;141.90;143.23;77220000;143.23
1983-02-01;145.29;145.29;142.96;142.96;82750000;142.96
1983-01-31;144.51;145.30;143.93;145.30;67140000;145.30
1983-01-28;144.31;145.47;144.25;144.51;89490000;144.51
1983-01-27;141.54;144.30;141.54;144.27;88120000;144.27
1983-01-26;141.77;142.16;141.16;141.54;73720000;141.54
1983-01-25;139.98;141.75;139.98;141.75;79740000;141.75
1983-01-24;143.84;143.84;139.10;139.97;90800000;139.97
1983-01-21;146.30;146.30;143.25;143.85;77110000;143.85
1983-01-20;145.29;146.62;145.29;146.29;82790000;146.29
1983-01-19;146.40;146.45;144.51;145.27;80900000;145.27
1983-01-18;146.71;146.74;145.52;146.40;78380000;146.40
1983-01-17;146.65;147.90;146.64;146.72;89210000;146.72
1983-01-14;145.72;147.12;145.72;146.65;86480000;146.65
1983-01-13;146.67;146.94;145.67;145.73;77030000;145.73
1983-01-12;145.76;148.36;145.76;146.69;109850000;146.69
1983-01-11;146.79;146.83;145.38;145.78;98250000;145.78
1983-01-10;145.19;147.25;144.58;146.78;101890000;146.78
1983-01-07;145.27;146.46;145.15;145.18;127290000;145.18
1983-01-06;142.01;145.77;142.01;145.27;129410000;145.27
1983-01-05;141.35;142.60;141.15;141.96;95390000;141.96
1983-01-04;138.33;141.36;138.08;141.36;75530000;141.36
1983-01-03;140.65;141.33;138.20;138.34;59080000;138.34
1982-12-31;140.34;140.78;140.27;140.64;42110000;140.64
1982-12-30;141.24;141.68;140.22;140.33;56380000;140.33
1982-12-29;140.77;141.73;140.68;141.24;54810000;141.24
1982-12-28;142.18;142.34;140.75;140.77;58610000;140.77
1982-12-27;139.73;142.32;139.72;142.17;64690000;142.17
1982-12-23;138.84;139.94;138.84;139.72;62880000;139.72
1982-12-22;138.63;139.69;138.60;138.83;83470000;138.83
1982-12-21;136.24;139.27;136.07;138.61;78010000;138.61
1982-12-20;137.49;137.84;136.19;136.25;62210000;136.25
1982-12-17;135.35;137.71;135.35;137.49;76010000;137.49
1982-12-16;135.22;135.78;134.79;135.30;73680000;135.30
1982-12-15;137.40;137.40;135.12;135.24;81030000;135.24
1982-12-14;139.99;142.50;137.34;137.40;98380000;137.40
1982-12-13;139.57;140.12;139.50;139.95;63140000;139.95
1982-12-10;139.99;141.15;139.35;139.57;86430000;139.57
1982-12-09;141.80;141.80;139.92;140.00;90320000;140.00
1982-12-08;142.71;143.58;141.82;141.82;97430000;141.82
1982-12-07;141.79;143.68;141.79;142.72;111620000;142.72
1982-12-06;138.70;141.77;138.01;141.77;83880000;141.77
1982-12-03;138.87;139.59;138.59;138.69;71540000;138.69
1982-12-02;138.72;139.63;138.66;138.82;77600000;138.82
1982-12-01;138.56;140.37;138.35;138.72;107850000;138.72
1982-11-30;134.20;138.53;134.19;138.53;93470000;138.53
1982-11-29;134.89;135.29;133.69;134.20;61080000;134.20
1982-11-26;133.89;134.88;133.89;134.88;38810000;134.88
1982-11-24;132.92;133.88;132.92;133.88;67220000;133.88
1982-11-23;134.21;134.28;132.89;132.93;72920000;132.93
1982-11-22;137.03;137.10;134.21;134.22;74960000;134.22
1982-11-19;138.35;138.93;137.00;137.02;70310000;137.02
1982-11-18;137.93;138.78;137.47;138.34;77620000;138.34
1982-11-17;135.47;137.93;135.47;137.93;84440000;137.93
1982-11-16;136.97;136.97;134.05;135.42;102910000;135.42
1982-11-15;139.54;139.54;137.00;137.03;78900000;137.03
1982-11-12;141.75;141.85;139.53;139.53;95080000;139.53
1982-11-11;141.15;141.75;139.88;141.75;78410000;141.75
1982-11-10;143.04;144.36;140.80;141.16;113240000;141.16
1982-11-09;140.48;143.16;140.46;143.02;111220000;143.02
1982-11-08;142.12;142.12;139.98;140.44;75240000;140.44
1982-11-05;141.85;142.43;141.32;142.16;96550000;142.16
1982-11-04;142.85;143.99;141.65;141.85;149350000;141.85
1982-11-03;137.53;142.88;137.53;142.87;137010000;142.87
1982-11-02;135.48;138.51;135.48;137.49;104770000;137.49
1982-11-01;133.72;136.03;133.22;135.47;73530000;135.47
1982-10-29;133.54;134.02;132.64;133.72;74830000;133.72
1982-10-28;135.28;135.42;133.59;133.59;73590000;133.59
1982-10-27;134.48;135.92;134.48;135.29;81670000;135.29
1982-10-26;133.29;134.48;131.50;134.48;102080000;134.48
1982-10-25;138.81;138.81;133.32;133.32;83720000;133.32
1982-10-22;139.06;140.40;138.75;138.83;101120000;138.83
1982-10-21;139.23;140.27;137.63;139.06;122460000;139.06
1982-10-20;136.58;139.23;136.37;139.23;98680000;139.23
1982-10-19;136.73;137.96;135.72;136.58;100850000;136.58
1982-10-18;133.59;136.73;133.59;136.73;83790000;136.73
1982-10-15;134.55;134.61;133.28;133.57;80290000;133.57
1982-10-14;136.71;136.89;134.55;134.57;107530000;134.57
1982-10-13;134.42;137.97;134.14;136.71;139800000;136.71
1982-10-12;134.48;135.85;133.59;134.44;126310000;134.44
1982-10-11;131.06;135.53;131.06;134.47;138530000;134.47
1982-10-08;128.79;131.11;128.79;131.05;122250000;131.05
1982-10-07;125.99;128.96;125.99;128.80;147070000;128.80
1982-10-06;122.00;125.97;122.00;125.97;93570000;125.97
1982-10-05;121.60;122.73;121.60;121.98;69770000;121.98
1982-10-04;121.97;121.97;120.56;121.51;55650000;121.51
1982-10-01;120.40;121.97;120.15;121.97;65000000;121.97
1982-09-30;121.62;121.62;120.14;120.42;62610000;120.42
1982-09-29;123.24;123.24;121.28;121.63;62550000;121.63
1982-09-28;123.62;124.16;123.21;123.24;65900000;123.24
1982-09-27;123.32;123.62;122.75;123.62;44840000;123.62
1982-09-24;123.79;123.80;123.11;123.32;54600000;123.32
1982-09-23;123.99;124.19;122.96;123.81;68260000;123.81
1982-09-22;124.90;126.43;123.99;123.99;113150000;123.99
1982-09-21;122.51;124.91;122.51;124.88;82920000;124.88
1982-09-20;122.54;122.54;121.48;122.51;58520000;122.51
1982-09-17;123.76;123.76;122.34;122.55;63950000;122.55
1982-09-16;124.28;124.88;123.65;123.77;78900000;123.77
1982-09-15;123.09;124.81;122.72;124.29;69680000;124.29
1982-09-14;122.27;123.69;122.27;123.10;83070000;123.10
1982-09-13;120.94;122.24;120.25;122.24;59520000;122.24
1982-09-10;121.97;121.98;120.27;120.97;71080000;120.97
1982-09-09;122.19;123.22;121.90;121.97;73090000;121.97
1982-09-08;121.33;123.11;121.19;122.20;77960000;122.20
1982-09-07;122.68;122.68;121.19;121.37;68960000;121.37
1982-09-03;120.31;123.64;120.31;122.68;130910000;122.68
1982-09-02;118.24;120.32;117.84;120.29;74740000;120.29
1982-09-01;119.52;120.05;117.98;118.25;82830000;118.25
1982-08-31;117.65;119.60;117.65;119.51;86360000;119.51
1982-08-30;117.05;117.66;115.79;117.66;59560000;117.66
1982-08-27;117.38;118.56;116.63;117.11;74410000;117.11
1982-08-26;117.57;120.26;117.57;118.55;137330000;118.55
1982-08-25;115.35;118.12;115.11;117.58;106200000;117.58
1982-08-24;116.11;116.39;115.08;115.35;121650000;115.35
1982-08-23;113.02;116.11;112.65;116.11;110310000;116.11
1982-08-20;109.19;113.02;109.19;113.02;95890000;113.02
1982-08-19;108.53;109.86;108.34;109.16;78270000;109.16
1982-08-18;109.04;111.58;108.46;108.54;132690000;108.54
1982-08-17;105.40;109.04;104.09;109.04;92860000;109.04
1982-08-16;103.86;105.52;103.86;104.09;55420000;104.09
1982-08-13;102.42;103.85;102.40;103.85;44720000;103.85
1982-08-12;102.60;103.22;102.39;102.42;50080000;102.42
1982-08-11;102.83;103.01;102.48;102.60;49040000;102.60
1982-08-10;103.11;103.84;102.82;102.84;52680000;102.84
1982-08-09;103.69;103.69;102.20;103.08;54560000;103.08
1982-08-06;105.16;105.16;103.67;103.71;48660000;103.71
1982-08-05;106.10;106.10;104.76;105.16;54700000;105.16
1982-08-04;107.83;107.83;106.11;106.14;53440000;106.14
1982-08-03;108.98;109.43;107.81;107.83;60480000;107.83
1982-08-02;107.71;109.09;107.11;108.98;53460000;108.98
1982-07-30;107.35;107.95;107.01;107.09;39270000;107.09
1982-07-29;107.42;107.92;106.62;107.72;55680000;107.72
1982-07-28;109.42;109.42;107.53;107.74;53830000;107.74
1982-07-27;110.26;110.35;109.36;109.43;45740000;109.43
1982-07-26;110.66;111.16;110.29;110.36;37740000;110.36
1982-07-23;111.46;111.58;111.05;111.17;47280000;111.17
1982-07-22;110.95;112.02;110.94;111.48;53870000;111.48
1982-07-21;112.15;112.39;111.38;111.42;66770000;111.42
1982-07-20;111.11;111.56;110.35;111.54;61060000;111.54
1982-07-19;111.75;111.78;110.66;110.73;53030000;110.73
1982-07-16;110.16;111.48;110.16;111.07;58740000;111.07
1982-07-15;110.83;110.95;110.27;110.47;61090000;110.47
1982-07-14;109.68;110.44;109.08;110.44;58160000;110.44
1982-07-13;109.19;110.07;109.19;109.45;66170000;109.45
1982-07-12;109.48;109.62;108.89;109.57;74690000;109.57
1982-07-09;108.23;108.97;107.56;108.83;65870000;108.83
1982-07-08;106.85;107.53;105.57;107.53;63270000;107.53
1982-07-07;107.08;107.61;106.99;107.22;46920000;107.22
1982-07-06;107.27;107.67;106.74;107.29;44350000;107.29
1982-07-02;108.10;108.71;107.60;107.65;43760000;107.65
1982-07-01;109.52;109.63;108.62;108.71;47900000;108.71
1982-06-30;110.95;111.00;109.50;109.61;65280000;109.61
1982-06-29;110.26;110.57;109.68;110.21;46990000;110.21
1982-06-28;109.30;110.45;109.17;110.26;40700000;110.26
1982-06-25;109.56;109.83;109.09;109.14;38740000;109.14
1982-06-24;110.25;110.92;109.79;109.83;55860000;109.83
1982-06-23;108.59;110.14;108.09;110.14;62710000;110.14
1982-06-22;107.25;108.30;107.17;108.30;55290000;108.30
1982-06-21;107.28;107.88;107.01;107.20;50370000;107.20
1982-06-18;107.60;107.60;107.07;107.28;53800000;107.28
1982-06-17;108.01;108.85;107.48;107.60;49230000;107.60
1982-06-16;110.10;110.13;108.82;108.87;56280000;108.87
1982-06-15;109.63;109.96;108.98;109.69;44970000;109.69
1982-06-14;110.50;111.22;109.90;109.96;40100000;109.96
1982-06-11;111.11;111.48;109.65;111.24;68610000;111.24
1982-06-10;109.35;109.70;108.96;109.61;50950000;109.61
1982-06-09;109.46;109.63;108.53;108.99;55770000;108.99
1982-06-08;110.33;110.33;109.60;109.63;46820000;109.63
1982-06-07;109.59;110.59;109.42;110.12;44630000;110.12
1982-06-04;111.66;111.85;110.02;110.09;44110000;110.09
1982-06-03;112.04;112.48;111.45;111.86;48450000;111.86
1982-06-02;111.74;112.19;111.55;112.04;49220000;112.04
1982-06-01;111.97;112.07;111.66;111.68;41650000;111.68
1982-05-28;112.79;112.80;111.66;111.88;43900000;111.88
1982-05-27;113.11;113.12;112.58;112.66;44730000;112.66
1982-05-26;113.68;114.40;112.88;113.11;51250000;113.11
1982-05-25;115.50;115.51;114.40;114.40;44010000;114.40
1982-05-24;114.46;114.86;114.24;114.79;38510000;114.79
1982-05-21;115.03;115.13;114.60;114.89;45260000;114.89
1982-05-20;114.85;115.07;114.37;114.59;48330000;114.59
1982-05-19;115.61;115.96;114.82;114.89;48840000;114.89
1982-05-18;116.35;116.70;115.71;115.84;48970000;115.84
1982-05-17;117.62;118.02;116.66;116.71;45600000;116.71
1982-05-14;118.20;118.40;118.01;118.01;49900000;118.01
1982-05-13;119.08;119.20;118.13;118.22;58230000;118.22
1982-05-12;119.89;119.92;118.76;119.17;59210000;119.17
1982-05-11;118.54;119.59;118.32;119.42;54680000;119.42
1982-05-10;119.08;119.49;118.37;118.38;46300000;118.38
1982-05-07;119.08;119.89;118.71;119.47;67130000;119.47
1982-05-06;118.82;118.83;117.68;118.68;67540000;118.68
1982-05-05;117.85;118.05;117.31;117.67;58860000;117.67
1982-05-04;117.41;117.64;116.85;117.46;58720000;117.46
1982-05-03;115.96;116.82;115.91;116.82;46490000;116.82
1982-04-30;116.21;116.78;116.07;116.44;48200000;116.44
1982-04-29;116.40;117.24;116.11;116.14;51330000;116.14
1982-04-28;117.83;118.05;116.94;117.26;50530000;117.26
1982-04-27;119.07;119.26;117.73;118.00;56480000;118.00
1982-04-26;118.94;119.33;118.25;119.26;60500000;119.26
1982-04-23;118.02;118.64;117.19;118.64;71840000;118.64
1982-04-22;115.72;117.25;115.72;117.19;64470000;117.19
1982-04-21;115.48;115.87;115.30;115.72;57820000;115.72
1982-04-20;115.80;117.14;114.83;115.44;54610000;115.44
1982-04-19;116.81;118.16;115.83;116.70;58470000;116.70
1982-04-16;116.35;117.70;115.68;116.81;55890000;116.81
1982-04-15;115.83;116.86;115.02;116.35;45700000;116.35
1982-04-14;115.99;116.69;114.80;115.83;45150000;115.83
1982-04-13;116.00;117.12;115.16;115.99;48660000;115.99
1982-04-12;116.22;117.02;115.16;116.00;46520000;116.00
1982-04-08;115.46;116.94;114.94;116.22;60190000;116.22
1982-04-07;115.36;116.45;114.58;115.46;53130000;115.46
1982-04-06;114.73;115.92;113.70;115.36;43200000;115.36
1982-04-05;115.12;115.90;113.94;114.73;46900000;114.73
1982-04-02;113.79;115.79;113.65;115.12;59800000;115.12
1982-04-01;111.96;114.22;111.48;113.79;57100000;113.79
1982-03-31;112.27;113.17;111.32;111.96;43300000;111.96
1982-03-30;112.30;113.09;111.30;112.27;43900000;112.27
1982-03-29;111.94;112.82;110.90;112.30;37100000;112.30
1982-03-26;113.21;113.43;111.26;111.94;42400000;111.94
1982-03-25;112.97;114.26;112.02;113.21;51970000;113.21
1982-03-24;113.55;114.31;112.23;112.97;49380000;112.97
1982-03-23;112.77;114.51;112.29;113.55;67130000;113.55
1982-03-22;110.71;113.35;110.71;112.77;57610000;112.77
1982-03-19;110.30;111.59;109.64;110.61;46250000;110.61
1982-03-18;109.08;111.02;108.85;110.30;54270000;110.30
1982-03-17;109.28;110.10;108.11;109.08;48900000;109.08
1982-03-16;109.45;110.92;108.57;109.28;48900000;109.28
1982-03-15;108.61;109.99;107.47;109.45;43370000;109.45
1982-03-12;109.36;109.72;104.46;108.61;49600000;108.61
1982-03-11;109.41;110.87;108.38;109.36;52960000;109.36
1982-03-10;108.83;110.98;108.09;109.41;59440000;109.41
1982-03-09;107.34;109.88;106.17;108.83;76060000;108.83
1982-03-08;109.34;111.06;107.03;107.34;67330000;107.34
1982-03-05;109.88;110.90;108.31;109.34;67440000;109.34
1982-03-04;110.92;111.78;108.77;109.88;74340000;109.88
1982-03-03;112.51;112.51;109.98;110.92;70230000;110.92
1982-03-02;113.31;114.80;112.03;112.68;63800000;112.68
1982-03-01;113.11;114.32;111.86;113.31;53010000;113.31
1982-02-26;113.21;114.01;112.04;113.11;43840000;113.11
1982-02-25;113.47;114.86;112.44;113.21;54160000;113.21
1982-02-24;111.51;113.88;110.71;113.47;64800000;113.47
1982-02-23;111.59;112.46;110.03;111.51;60100000;111.51
1982-02-22;113.22;114.90;111.20;111.59;58310000;111.59
1982-02-19;113.82;114.58;112.33;113.22;51340000;113.22
1982-02-18;113.69;115.04;112.97;113.82;60810000;113.82
1982-02-17;114.06;115.09;112.97;113.69;47660000;113.69
1982-02-16;114.38;114.63;112.06;114.06;48880000;114.06
1982-02-12;114.43;115.39;113.70;114.38;37070000;114.38
1982-02-11;114.66;115.59;113.41;114.43;46730000;114.43
1982-02-10;113.68;115.62;113.45;114.66;46620000;114.66
1982-02-09;114.63;115.15;112.82;113.68;54420000;113.68
1982-02-08;117.04;117.04;114.20;114.63;48500000;114.63
1982-02-05;116.42;118.26;115.74;117.26;53350000;117.26
1982-02-04;116.48;117.49;114.88;116.42;53300000;116.42
1982-02-03;118.01;118.67;116.04;116.48;49560000;116.48
1982-02-02;117.78;119.15;116.91;118.01;45020000;118.01
1982-02-01;119.81;119.81;117.14;117.78;47720000;117.78
1982-01-29;118.92;121.38;118.64;120.40;73400000;120.40
1982-01-28;116.10;119.35;116.10;118.92;66690000;118.92
1982-01-27;115.19;116.60;114.38;115.74;50060000;115.74
1982-01-26;115.41;116.60;114.49;115.19;44870000;115.19
1982-01-25;115.38;115.93;113.63;115.41;43170000;115.41
1982-01-22;115.75;116.53;114.58;115.38;44370000;115.38
1982-01-21;115.27;116.92;114.60;115.75;48610000;115.75
1982-01-20;115.97;116.64;114.29;115.27;48860000;115.27
1982-01-19;117.22;118.15;115.52;115.97;45070000;115.97
1982-01-18;116.33;117.69;114.85;117.22;44920000;117.22
1982-01-15;115.54;117.14;115.10;116.33;43310000;116.33
1982-01-14;114.88;116.30;114.07;115.54;42940000;115.54
1982-01-13;116.30;117.46;114.24;114.88;49130000;114.88
1982-01-12;116.78;117.49;115.18;116.30;49800000;116.30
1982-01-11;119.55;120.34;116.47;116.78;51900000;116.78
1982-01-08;118.93;120.59;118.55;119.55;42050000;119.55
1982-01-07;119.18;119.88;117.70;118.93;43410000;118.93
1982-01-06;120.05;120.45;117.99;119.18;51510000;119.18
1982-01-05;122.61;122.61;119.57;120.05;47510000;120.05
1982-01-04;122.55;123.72;121.48;122.74;36760000;122.74
1981-12-31;122.30;123.42;121.57;122.55;40780000;122.55
1981-12-30;121.67;123.11;121.04;122.30;42960000;122.30
1981-12-29;122.27;122.90;121.12;121.67;35300000;121.67
1981-12-28;122.54;123.36;121.73;122.27;28320000;122.27
1981-12-24;122.31;123.06;121.57;122.54;23940000;122.54
1981-12-23;122.88;123.59;121.58;122.31;42910000;122.31
1981-12-22;123.34;124.17;122.19;122.88;48320000;122.88
1981-12-21;124.00;124.71;122.67;123.34;41290000;123.34
1981-12-18;123.12;124.87;122.56;124.00;50940000;124.00
1981-12-17;122.42;123.79;121.82;123.12;47230000;123.12
1981-12-16;122.99;123.66;121.73;122.42;42770000;122.42
1981-12-15;122.78;123.78;121.83;122.99;44130000;122.99
1981-12-14;124.37;124.37;122.17;122.78;44740000;122.78
1981-12-11;125.71;126.26;124.32;124.93;45850000;124.93
1981-12-10;125.48;126.54;124.60;125.71;47020000;125.71
1981-12-09;124.82;126.08;124.09;125.48;44810000;125.48
1981-12-08;125.19;125.75;123.52;124.82;45140000;124.82
1981-12-07;126.26;126.91;124.67;125.19;45720000;125.19
1981-12-04;125.12;127.32;125.12;126.26;55040000;126.26
1981-12-03;124.69;125.84;123.63;125.12;43770000;125.12
1981-12-02;126.10;126.45;124.18;124.69;44510000;124.69
1981-12-01;126.35;127.30;124.84;126.10;53980000;126.10
1981-11-30;125.09;126.97;124.18;126.35;47580000;126.35
1981-11-27;124.05;125.71;123.63;125.09;32770000;125.09
1981-11-25;123.51;125.29;123.07;124.05;58570000;124.05
1981-11-24;121.60;124.04;121.22;123.51;53200000;123.51
1981-11-23;121.71;123.09;120.76;121.60;45250000;121.60
1981-11-20;120.71;122.59;120.13;121.71;52010000;121.71
1981-11-19;120.26;121.67;119.42;120.71;48890000;120.71
1981-11-18;121.15;121.66;119.61;120.26;49980000;120.26
1981-11-17;120.24;121.78;119.50;121.15;43190000;121.15
1981-11-16;121.64;121.64;119.13;120.24;43740000;120.24
1981-11-13;123.19;123.61;121.06;121.67;45550000;121.67
1981-11-12;122.92;124.71;122.19;123.19;55720000;123.19
1981-11-11;122.70;123.82;121.51;122.92;41920000;122.92
1981-11-10;123.29;124.69;122.01;122.70;53940000;122.70
1981-11-09;122.67;124.13;121.59;123.29;48310000;123.29
1981-11-06;123.54;124.03;121.85;122.67;43270000;122.67
1981-11-05;124.74;125.80;122.98;123.54;50860000;123.54
1981-11-04;124.80;126.00;123.64;124.74;53450000;124.74
1981-11-03;124.20;125.52;123.14;124.80;54620000;124.80
1981-11-02;122.35;125.14;122.35;124.20;65100000;124.20
1981-10-30;119.06;122.53;118.43;121.89;59570000;121.89
1981-10-29;119.45;120.37;118.14;119.06;40070000;119.06
1981-10-28;119.29;120.96;118.39;119.45;48100000;119.45
1981-10-27;118.16;120.43;117.80;119.29;53030000;119.29
1981-10-26;118.60;119.00;116.81;118.16;38210000;118.16
1981-10-23;119.64;119.92;117.78;118.60;41990000;118.60
1981-10-22;120.10;120.78;118.48;119.64;40630000;119.64
1981-10-21;120.28;121.94;119.35;120.10;48490000;120.10
1981-10-20;118.98;121.29;118.78;120.28;51530000;120.28
1981-10-19;119.19;119.85;117.58;118.98;41590000;118.98
1981-10-16;119.71;120.46;118.38;119.19;37800000;119.19
1981-10-15;118.80;120.58;118.01;119.71;42830000;119.71
1981-10-14;120.78;120.97;118.38;118.80;40260000;118.80
1981-10-13;121.21;122.37;119.96;120.78;43360000;120.78
1981-10-12;121.45;122.37;120.17;121.21;30030000;121.21
1981-10-09;122.31;123.28;120.63;121.45;50060000;121.45
1981-10-08;121.31;123.08;120.23;122.31;47090000;122.31
1981-10-07;119.39;121.87;119.09;121.31;50030000;121.31
1981-10-06;119.51;121.39;118.08;119.39;45460000;119.39
1981-10-05;119.36;121.54;118.61;119.51;51290000;119.51
1981-10-02;117.08;120.16;117.07;119.36;54540000;119.36
1981-10-01;116.18;117.66;115.00;117.08;41600000;117.08
1981-09-30;115.94;117.05;114.60;116.18;40700000;116.18
1981-09-29;115.53;117.75;114.75;115.94;49800000;115.94
1981-09-28;112.77;115.83;110.19;115.53;61320000;115.53
1981-09-25;114.69;114.69;111.64;112.77;54390000;112.77
1981-09-24;115.65;117.47;114.32;115.01;48880000;115.01
1981-09-23;116.68;116.68;113.60;115.65;52700000;115.65
1981-09-22;117.24;118.19;115.93;116.68;46830000;116.68
1981-09-21;116.26;118.07;115.04;117.24;44570000;117.24
1981-09-18;117.15;117.69;115.18;116.26;47350000;116.26
1981-09-17;118.87;119.87;116.63;117.15;48300000;117.15
1981-09-16;119.77;120.00;117.89;118.87;43660000;118.87
1981-09-15;120.66;121.77;119.27;119.77;38580000;119.77
1981-09-14;121.61;122.00;119.67;120.66;34040000;120.66
1981-09-11;120.14;122.13;119.29;121.61;42170000;121.61
1981-09-10;118.40;122.18;118.33;120.14;47430000;120.14
1981-09-09;117.98;119.49;116.87;118.40;43910000;118.40
1981-09-08;120.07;120.12;116.85;117.98;47340000;117.98
1981-09-04;121.24;121.54;119.24;120.07;42760000;120.07
1981-09-03;123.49;124.16;120.82;121.24;41730000;121.24
1981-09-02;123.02;124.58;122.54;123.49;37570000;123.49
1981-09-01;122.79;123.92;121.59;123.02;45110000;123.02
1981-08-31;124.08;125.58;122.29;122.79;40360000;122.79
1981-08-28;123.51;125.09;122.85;124.08;38020000;124.08
1981-08-27;124.96;125.31;122.90;123.51;43900000;123.51
1981-08-26;125.13;126.17;123.99;124.96;39980000;124.96
1981-08-25;125.50;125.77;123.00;125.13;54600000;125.13
1981-08-24;128.59;128.59;125.02;125.50;46750000;125.50
1981-08-21;130.69;131.06;128.70;129.23;37670000;129.23
1981-08-20;130.49;131.74;129.84;130.69;38270000;130.69
1981-08-19;130.11;131.20;128.99;130.49;39390000;130.49
1981-08-18;131.22;131.73;129.10;130.11;47270000;130.11
1981-08-17;132.49;133.02;130.75;131.22;40840000;131.22
1981-08-14;133.51;134.33;131.91;132.49;42580000;132.49
1981-08-13;133.40;134.58;132.53;133.51;42460000;133.51
1981-08-12;133.85;135.18;132.73;133.40;53650000;133.40
1981-08-11;132.54;134.63;132.09;133.85;52600000;133.85
1981-08-10;131.75;133.32;130.83;132.54;38370000;132.54
1981-08-07;132.64;133.04;130.96;131.75;38370000;131.75
1981-08-06;132.67;134.04;131.74;132.64;52070000;132.64
1981-08-05;131.18;133.39;130.76;132.67;54290000;132.67
1981-08-04;130.48;131.66;129.43;131.18;39460000;131.18
1981-08-03;130.92;131.74;129.42;130.48;39650000;130.48
1981-07-31;130.01;131.78;129.60;130.92;43480000;130.92
1981-07-30;129.16;130.68;128.56;130.01;41560000;130.01
1981-07-29;129.14;130.09;128.37;129.16;37610000;129.16
1981-07-28;129.90;130.44;128.28;129.14;38160000;129.14
1981-07-27;128.46;130.61;128.43;129.90;39610000;129.90
1981-07-24;127.40;129.31;127.11;128.46;38880000;128.46
1981-07-23;127.13;128.26;125.96;127.40;41790000;127.40
1981-07-22;128.34;129.72;126.70;127.13;47500000;127.13
1981-07-21;128.72;129.60;127.08;128.34;47280000;128.34
1981-07-20;130.60;130.60;127.98;128.72;40240000;128.72
1981-07-17;130.34;131.60;129.49;130.76;42780000;130.76
1981-07-16;130.23;131.41;129.30;130.34;39010000;130.34
1981-07-15;129.65;131.59;128.89;130.23;48950000;130.23
1981-07-14;129.64;130.78;128.14;129.65;45230000;129.65
1981-07-13;129.37;130.82;128.79;129.64;38100000;129.64
1981-07-10;129.30;130.43;128.38;129.37;39950000;129.37
1981-07-09;128.32;130.08;127.57;129.30;45510000;129.30
1981-07-08;128.24;129.57;126.95;128.32;46000000;128.32
1981-07-07;127.37;129.60;126.39;128.24;53560000;128.24
1981-07-06;128.64;128.99;126.44;127.37;44590000;127.37
1981-07-02;129.77;130.48;127.84;128.64;45100000;128.64
1981-07-01;131.21;131.69;129.04;129.77;49080000;129.77
1981-06-30;131.89;132.67;130.31;131.21;41550000;131.21
1981-06-29;132.56;133.50;131.20;131.89;37930000;131.89
1981-06-26;132.81;133.75;131.71;132.56;39240000;132.56
1981-06-25;132.66;134.30;131.78;132.81;43920000;132.81
1981-06-24;133.35;133.90;131.65;132.66;46650000;132.66
1981-06-23;131.95;133.98;131.16;133.35;51840000;133.35
1981-06-22;132.27;133.54;131.10;131.95;41790000;131.95
1981-06-19;131.64;133.27;130.49;132.27;46430000;132.27
1981-06-18;133.32;133.98;130.94;131.64;48400000;131.64
1981-06-17;132.15;133.98;130.81;133.32;55470000;133.32
1981-06-16;133.61;134.00;131.29;132.15;57780000;132.15
1981-06-15;133.49;135.67;132.78;133.61;63350000;133.61
1981-06-12;133.75;135.09;132.40;133.49;60790000;133.49
1981-06-11;132.32;134.31;131.58;133.75;59530000;133.75
1981-06-10;131.97;133.49;131.04;132.32;53200000;132.32
1981-06-09;132.24;133.30;130.94;131.97;44600000;131.97
1981-06-08;132.22;133.68;131.29;132.24;41580000;132.24
1981-06-05;130.96;132.98;130.17;132.22;47180000;132.22
1981-06-04;130.71;132.21;129.72;130.96;48940000;130.96
1981-06-03;130.62;131.37;128.77;130.71;54700000;130.71
1981-06-02;132.41;132.96;129.84;130.62;53930000;130.62
1981-06-01;132.59;134.62;131.49;132.41;62170000;132.41
1981-05-29;133.45;134.36;131.52;132.59;51580000;132.59
1981-05-28;133.77;134.92;132.00;133.45;59500000;133.45
1981-05-27;132.77;134.65;131.85;133.77;58730000;133.77
1981-05-26;131.33;133.30;130.64;132.77;42760000;132.77
1981-05-22;131.75;132.65;130.42;131.33;40710000;131.33
1981-05-21;132.00;133.03;130.70;131.75;46820000;131.75
1981-05-20;132.09;133.03;130.59;132.00;42370000;132.00
1981-05-19;132.54;133.22;130.78;132.09;42220000;132.09
1981-05-18;132.17;133.65;131.49;132.54;42510000;132.54
1981-05-15;131.28;133.21;130.75;132.17;45460000;132.17
1981-05-14;130.55;132.15;129.91;131.28;42750000;131.28
1981-05-13;130.72;131.96;129.53;130.55;42600000;130.55
1981-05-12;129.71;131.17;128.78;130.72;40440000;130.72
1981-05-11;131.66;132.23;129.11;129.71;37640000;129.71
1981-05-08;131.67;132.69;130.84;131.66;41860000;131.66
1981-05-07;130.78;132.41;130.21;131.67;42590000;131.67
1981-05-06;130.32;132.38;130.09;130.78;47100000;130.78
1981-05-05;130.67;131.33;128.93;130.32;49000000;130.32
1981-05-04;131.78;131.78;129.61;130.67;40430000;130.67
1981-05-01;132.81;134.17;131.43;132.72;48360000;132.72
1981-04-30;133.05;134.44;131.85;132.81;47970000;132.81
1981-04-29;134.33;134.69;131.82;133.05;53340000;133.05
1981-04-28;135.48;136.09;133.10;134.33;58210000;134.33
1981-04-27;135.14;136.56;134.13;135.48;51080000;135.48
1981-04-24;133.94;136.00;132.88;135.14;60000000;135.14
1981-04-23;134.14;135.90;132.90;133.94;64200000;133.94
1981-04-22;134.23;135.54;132.72;134.14;60660000;134.14
1981-04-21;135.45;136.38;133.49;134.23;60280000;134.23
1981-04-20;134.70;136.25;133.19;135.45;51020000;135.45
1981-04-16;134.17;135.82;133.43;134.70;52950000;134.70
1981-04-15;132.68;134.79;132.20;134.17;56040000;134.17
1981-04-14;133.15;134.03;131.58;132.68;48350000;132.68
1981-04-13;134.51;134.91;132.24;133.15;49860000;133.15
1981-04-10;134.67;136.23;133.18;134.51;58130000;134.51
1981-04-09;134.31;135.80;132.59;134.67;59520000;134.67
1981-04-08;133.91;135.34;133.26;134.31;48000000;134.31
1981-04-07;133.93;135.27;132.96;133.91;44540000;133.91
1981-04-06;135.49;135.61;132.91;133.93;43190000;133.93
1981-04-03;136.32;137.04;134.67;135.49;48680000;135.49
1981-04-02;136.57;137.72;135.16;136.32;52570000;136.32
1981-04-01;136.00;137.56;135.04;136.57;54880000;136.57
1981-03-31;134.68;137.15;134.68;136.00;50980000;136.00
1981-03-30;134.65;135.87;133.51;134.28;33500000;134.28
1981-03-27;136.27;136.89;133.91;134.65;46930000;134.65
1981-03-26;137.11;138.38;135.29;136.27;60370000;136.27
1981-03-25;134.67;137.32;133.92;137.11;56320000;137.11
1981-03-24;135.69;137.40;134.10;134.67;66400000;134.67
1981-03-23;134.08;136.50;133.41;135.69;57880000;135.69
1981-03-20;133.46;135.29;132.50;134.08;61980000;134.08
1981-03-19;134.22;135.37;132.37;133.46;62440000;133.46
1981-03-18;133.92;135.66;132.80;134.22;55740000;134.22
1981-03-17;134.68;136.09;132.80;133.92;65920000;133.92
1981-03-16;133.11;135.35;132.10;134.68;49940000;134.68
1981-03-13;133.19;135.53;132.39;133.11;68290000;133.11
1981-03-12;129.95;133.56;129.76;133.19;54640000;133.19
1981-03-11;130.46;131.20;128.72;129.95;47390000;129.95
1981-03-10;131.12;132.64;129.72;130.46;56610000;130.46
1981-03-09;129.85;131.94;129.39;131.12;46180000;131.12
1981-03-06;129.93;131.18;128.56;129.85;43940000;129.85
1981-03-05;130.86;131.82;129.25;129.93;45380000;129.93
1981-03-04;130.56;132.07;129.57;130.86;47260000;130.86
1981-03-03;132.01;132.72;129.66;130.56;48730000;130.56
1981-03-02;131.27;132.96;130.15;132.01;47710000;132.01
1981-02-27;130.10;132.02;129.35;131.27;53210000;131.27
1981-02-26;128.52;130.93;128.02;130.10;60300000;130.10
1981-02-25;127.39;129.21;125.77;128.52;45710000;128.52
1981-02-24;127.35;128.76;126.49;127.39;43960000;127.39
1981-02-23;126.58;128.28;125.69;127.35;39590000;127.35
1981-02-20;126.61;127.65;124.66;126.58;41900000;126.58
1981-02-19;128.48;129.07;125.98;126.61;41630000;126.61
1981-02-18;127.81;129.25;127.09;128.48;40410000;128.48
1981-02-17;126.98;128.75;126.43;127.81;37940000;127.81
1981-02-13;127.48;128.34;126.04;126.98;33360000;126.98
1981-02-12;128.24;128.95;126.78;127.48;34700000;127.48
1981-02-11;129.24;129.92;127.60;128.24;37770000;128.24
1981-02-10;129.27;130.19;128.05;129.24;40820000;129.24
1981-02-09;130.60;131.39;128.61;129.27;38330000;129.27
1981-02-06;129.63;131.81;129.03;130.60;45820000;130.60
1981-02-05;128.59;130.49;127.99;129.63;45320000;129.63
1981-02-04;128.46;129.71;127.29;128.59;45520000;128.59
1981-02-03;126.91;128.92;125.89;128.46;45950000;128.46
1981-02-02;129.48;129.48;125.82;126.91;44070000;126.91
1981-01-30;130.24;131.65;128.61;129.55;41160000;129.55
1981-01-29;130.34;131.78;128.97;130.24;38170000;130.24
1981-01-28;131.12;132.41;129.82;130.34;36690000;130.34
1981-01-27;129.84;131.95;129.32;131.12;42260000;131.12
1981-01-26;130.23;131.18;128.57;129.84;35380000;129.84
1981-01-23;130.26;131.34;129.00;130.23;37220000;130.23
1981-01-22;131.36;132.08;129.23;130.26;39880000;130.26
1981-01-21;131.65;132.48;129.93;131.36;39190000;131.36
1981-01-20;134.37;135.30;131.26;131.65;41750000;131.65
1981-01-19;134.77;135.86;133.51;134.37;36470000;134.37
1981-01-16;134.22;135.91;133.35;134.77;43260000;134.77
1981-01-15;133.47;135.15;132.44;134.22;39640000;134.22
1981-01-14;133.29;135.25;132.65;133.47;41390000;133.47
1981-01-13;133.52;134.27;131.69;133.29;40890000;133.29
1981-01-12;133.48;135.88;132.79;133.52;48760000;133.52
1981-01-09;133.06;134.76;131.71;133.48;50190000;133.48
1981-01-08;135.08;136.10;131.96;133.06;55350000;133.06
1981-01-07;136.02;136.02;132.30;135.08;92890000;135.08
1981-01-06;137.97;140.32;135.78;138.12;67400000;138.12
1981-01-05;136.34;139.24;135.86;137.97;58710000;137.97
1981-01-02;135.76;137.10;134.61;136.34;28870000;136.34
1980-12-31;135.33;136.76;134.29;135.76;41210000;135.76
1980-12-30;135.03;136.51;134.04;135.33;39750000;135.33
1980-12-29;136.57;137.51;134.36;135.03;36060000;135.03
1980-12-26;135.88;137.02;135.20;136.57;16130000;136.57
1980-12-24;135.30;136.55;134.15;135.88;29490000;135.88
1980-12-23;135.78;137.48;134.01;135.30;55260000;135.30
1980-12-22;133.70;136.68;132.88;135.78;51950000;135.78
1980-12-19;133.00;134.00;131.80;133.70;50770000;133.70
1980-12-18;132.89;135.90;131.89;133.00;69570000;133.00
1980-12-17;130.60;133.59;130.22;132.89;50800000;132.89
1980-12-16;129.45;131.22;128.33;130.60;41630000;130.60
1980-12-15;129.23;131.33;128.64;129.45;39700000;129.45
1980-12-12;127.36;129.98;127.15;129.23;39530000;129.23
1980-12-11;128.26;128.73;125.32;127.36;60220000;127.36
1980-12-10;130.48;131.99;127.94;128.26;49860000;128.26
1980-12-09;130.61;131.92;128.77;130.48;53220000;130.48
1980-12-08;133.19;133.19;129.71;130.61;53390000;130.61
1980-12-05;136.37;136.37;132.91;134.03;51990000;134.03
1980-12-04;136.71;138.40;135.09;136.48;51170000;136.48
1980-12-03;136.97;138.09;135.43;136.71;43430000;136.71
1980-12-02;137.21;138.11;134.37;136.97;52340000;136.97
1980-12-01;140.52;140.66;136.75;137.21;48180000;137.21
1980-11-28;140.17;141.54;139.00;140.52;34240000;140.52
1980-11-26;139.33;141.96;138.60;140.17;55340000;140.17
1980-11-25;138.31;140.83;137.42;139.33;55840000;139.33
1980-11-24;139.11;139.36;136.36;138.31;51120000;138.31
1980-11-21;140.40;141.24;138.10;139.11;55950000;139.11
1980-11-20;139.06;141.24;137.79;140.40;60180000;140.40
1980-11-19;139.70;141.76;138.06;139.06;69230000;139.06
1980-11-18;137.91;140.92;137.91;139.70;70380000;139.70
1980-11-17;137.15;138.46;134.90;137.75;50260000;137.75
1980-11-14;136.49;138.96;135.12;137.15;71630000;137.15
1980-11-13;134.59;137.21;134.12;136.49;69340000;136.49
1980-11-12;131.33;135.12;131.33;134.59;58500000;134.59
1980-11-11;129.48;132.30;129.48;131.26;41520000;131.26
1980-11-10;129.18;130.51;128.19;129.48;35720000;129.48
1980-11-07;128.91;130.08;127.74;129.18;40070000;129.18
1980-11-06;131.30;131.30;128.23;128.91;48890000;128.91
1980-11-05;130.77;135.65;130.77;131.33;84080000;131.33
1980-11-03;127.47;129.85;127.23;129.04;35820000;129.04
1980-10-31;126.29;128.24;125.29;127.47;40110000;127.47
1980-10-30;127.91;128.71;125.78;126.29;39060000;126.29
1980-10-29;128.05;129.91;127.07;127.91;37200000;127.91
1980-10-28;127.88;128.86;126.36;128.05;40300000;128.05
1980-10-27;129.85;129.94;127.34;127.88;34430000;127.88
1980-10-24;129.53;130.55;128.04;129.85;41050000;129.85
1980-10-23;131.92;132.54;128.87;129.53;49200000;129.53
1980-10-22;131.84;132.97;130.62;131.92;43060000;131.92
1980-10-21;132.61;134.01;130.78;131.84;51220000;131.84
1980-10-20;131.52;133.21;130.04;132.61;40910000;132.61
1980-10-17;132.22;133.07;130.22;131.52;43920000;131.52
1980-10-16;133.70;135.88;131.64;132.22;65450000;132.22
1980-10-15;132.02;134.35;131.59;133.70;48260000;133.70
1980-10-14;132.03;133.57;131.16;132.02;48830000;132.02
1980-10-13;130.29;132.46;129.37;132.03;31360000;132.03
1980-10-10;131.04;132.15;129.58;130.29;44040000;130.29
1980-10-09;131.65;132.65;130.25;131.04;43980000;131.04
1980-10-08;131.00;132.78;130.28;131.65;46580000;131.65
1980-10-07;131.73;132.88;130.10;131.00;50310000;131.00
1980-10-06;129.35;132.38;129.35;131.73;50130000;131.73
1980-10-03;128.09;130.44;127.65;129.33;47510000;129.33
1980-10-02;127.13;128.82;126.04;128.09;46160000;128.09
1980-10-01;125.46;127.88;124.66;127.13;48720000;127.13
1980-09-30;123.54;126.09;123.54;125.46;40290000;125.46
1980-09-29;125.41;125.41;122.87;123.54;46410000;123.54
1980-09-26;128.17;128.17;125.29;126.35;49460000;126.35
1980-09-25;130.37;131.53;128.13;128.72;49510000;128.72
1980-09-24;129.43;131.34;128.45;130.37;56860000;130.37
1980-09-23;130.40;132.17;128.55;129.43;64390000;129.43
1980-09-22;129.25;130.99;127.89;130.40;53140000;130.40
1980-09-19;128.40;130.33;127.57;129.25;53780000;129.25
1980-09-18;128.87;130.38;127.63;128.40;63390000;128.40
1980-09-17;126.74;129.68;126.37;128.87;63990000;128.87
1980-09-16;125.67;127.78;125.15;126.74;57290000;126.74
1980-09-15;125.54;126.35;124.09;125.67;44630000;125.67
1980-09-12;125.66;126.75;124.72;125.54;47180000;125.54
1980-09-11;124.81;126.48;124.19;125.66;44770000;125.66
1980-09-10;124.07;125.95;123.60;124.81;51430000;124.81
1980-09-09;123.31;124.52;121.94;124.07;44460000;124.07
1980-09-08;124.88;125.67;122.78;123.31;42050000;123.31
1980-09-05;125.42;126.12;124.08;124.88;37990000;124.88
1980-09-04;126.12;127.70;124.42;125.42;59030000;125.42
1980-09-03;123.87;126.43;123.87;126.12;52370000;126.12
1980-09-02;122.38;124.36;121.79;123.74;35290000;123.74
1980-08-29;122.08;123.01;121.06;122.38;33510000;122.38
1980-08-28;123.52;123.91;121.61;122.08;39890000;122.08
1980-08-27;124.84;124.98;122.93;123.52;44000000;123.52
1980-08-26;125.16;126.29;124.01;124.84;41700000;124.84
1980-08-25;126.02;126.28;124.65;125.16;35400000;125.16
1980-08-22;125.46;127.78;125.18;126.02;58210000;126.02
1980-08-21;123.77;125.99;123.61;125.46;50770000;125.46
1980-08-20;122.60;124.27;121.91;123.77;42560000;123.77
1980-08-19;123.39;124.00;121.97;122.60;41930000;122.60
1980-08-18;125.28;125.28;122.82;123.39;41890000;123.39
1980-08-15;125.25;126.61;124.57;125.72;47780000;125.72
1980-08-14;123.28;125.62;122.68;125.25;47700000;125.25
1980-08-13;123.79;124.67;122.49;123.28;44350000;123.28
1980-08-12;124.78;125.78;123.29;123.79;52050000;123.79
1980-08-11;123.61;125.31;122.85;124.78;44690000;124.78
1980-08-08;123.30;125.23;122.82;123.61;58860000;123.61
1980-08-07;121.66;123.84;121.66;123.30;61820000;123.30
1980-08-06;120.74;122.01;119.94;121.55;45050000;121.55
1980-08-05;120.98;122.09;119.96;120.74;45510000;120.74
1980-08-04;121.21;121.63;119.42;120.98;41550000;120.98
1980-08-01;121.67;122.38;120.08;121.21;46440000;121.21
1980-07-31;122.23;122.34;119.40;121.67;54610000;121.67
1980-07-30;122.40;123.93;121.16;122.23;58060000;122.23
1980-07-29;121.43;122.99;120.76;122.40;44840000;122.40
1980-07-28;120.78;122.02;119.78;121.43;35330000;121.43
1980-07-25;121.79;121.96;119.94;120.78;36250000;120.78
1980-07-24;121.93;122.98;120.83;121.79;42420000;121.79
1980-07-23;122.19;123.26;120.93;121.93;45890000;121.93
1980-07-22;122.51;123.90;121.38;122.19;52230000;122.19
1980-07-21;122.04;123.15;120.85;122.51;42750000;122.51
1980-07-18;121.44;123.19;120.88;122.04;58040000;122.04
1980-07-17;119.63;121.84;119.43;121.44;48850000;121.44
1980-07-16;119.30;120.87;118.54;119.63;49140000;119.63
1980-07-15;120.01;121.56;118.85;119.30;60920000;119.30
1980-07-14;117.84;120.37;117.45;120.01;45500000;120.01
1980-07-11;116.95;118.38;116.29;117.84;38310000;117.84
1980-07-10;117.98;118.57;116.38;116.95;43730000;116.95
1980-07-09;117.84;119.52;117.10;117.98;52010000;117.98
1980-07-08;118.29;119.11;117.07;117.84;45830000;117.84
1980-07-07;117.46;118.85;116.96;118.29;42540000;118.29
1980-07-03;115.68;117.80;115.49;117.46;47230000;117.46
1980-07-02;114.93;116.44;114.36;115.68;42950000;115.68
1980-07-01;114.24;115.45;113.54;114.93;34340000;114.93
1980-06-30;116.00;116.04;113.55;114.24;29910000;114.24
1980-06-27;116.19;116.93;115.06;116.00;33110000;116.00
1980-06-26;116.72;117.98;115.58;116.19;45110000;116.19
1980-06-25;115.14;117.37;115.07;116.72;46500000;116.72
1980-06-24;114.51;115.75;113.76;115.14;37730000;115.14
1980-06-23;114.06;115.28;113.35;114.51;34180000;114.51
1980-06-20;114.66;114.90;113.12;114.06;36530000;114.06
1980-06-19;116.26;116.81;114.36;114.66;38280000;114.66
1980-06-18;116.03;116.84;114.77;116.26;41960000;116.26
1980-06-17;116.09;117.16;115.13;116.03;41990000;116.03
1980-06-16;115.81;116.80;114.78;116.09;36190000;116.09
1980-06-13;115.52;116.94;114.67;115.81;41880000;115.81
1980-06-12;116.02;117.01;114.28;115.52;47300000;115.52
1980-06-11;114.66;116.64;114.22;116.02;43800000;116.02
1980-06-10;113.71;115.50;113.17;114.66;42030000;114.66
1980-06-09;113.20;114.51;112.68;113.71;36820000;113.71
1980-06-06;112.78;114.01;112.11;113.20;37230000;113.20
1980-06-05;112.61;114.38;111.89;112.78;49070000;112.78
1980-06-04;110.51;113.45;110.22;112.61;44180000;112.61
1980-06-03;110.76;111.63;109.77;110.51;33150000;110.51
1980-06-02;111.24;112.15;110.06;110.76;32710000;110.76
1980-05-30;110.27;111.55;108.87;111.24;34820000;111.24
1980-05-29;112.06;112.64;109.86;110.27;42000000;110.27
1980-05-28;111.40;112.72;110.42;112.06;38580000;112.06
1980-05-27;110.62;112.30;110.35;111.40;40810000;111.40
1980-05-23;109.01;111.37;109.01;110.62;45790000;110.62
1980-05-22;107.72;109.73;107.34;109.01;41040000;109.01
1980-05-21;107.62;108.31;106.54;107.72;34830000;107.72
1980-05-20;107.67;108.39;106.75;107.62;31800000;107.62
1980-05-19;107.35;108.43;106.51;107.67;30970000;107.67
1980-05-16;106.99;107.89;106.25;107.35;31710000;107.35
1980-05-15;106.85;107.99;106.07;106.99;41120000;106.99
1980-05-14;106.30;107.89;106.00;106.85;40840000;106.85
1980-05-13;104.78;106.76;104.44;106.30;35460000;106.30
1980-05-12;104.72;105.48;103.50;104.78;28220000;104.78
1980-05-09;106.13;106.20;104.18;104.72;30280000;104.72
1980-05-08;107.18;108.02;105.50;106.13;39280000;106.13
1980-05-07;106.25;108.12;105.83;107.18;42600000;107.18
1980-05-06;106.38;107.83;105.36;106.25;40160000;106.25
1980-05-05;105.58;106.83;104.64;106.38;34090000;106.38
1980-05-02;105.46;106.25;104.61;105.58;28040000;105.58
1980-05-01;106.29;106.86;104.72;105.46;32480000;105.46
1980-04-30;105.86;106.72;104.50;106.29;30850000;106.29
1980-04-29;105.64;106.70;104.86;105.86;27940000;105.86
1980-04-28;105.16;106.79;104.64;105.64;30600000;105.64
1980-04-25;104.40;105.57;103.02;105.16;28590000;105.16
1980-04-24;103.73;105.43;102.93;104.40;35790000;104.40
1980-04-23;103.43;105.11;102.81;103.73;42620000;103.73
1980-04-22;100.81;104.02;100.81;103.43;47920000;103.43
1980-04-21;100.55;101.26;98.95;99.80;27560000;99.80
1980-04-18;101.05;102.07;99.97;100.55;26880000;100.55
1980-04-17;101.54;102.21;100.12;101.05;32770000;101.05
1980-04-16;102.63;104.42;101.13;101.54;39730000;101.54
1980-04-15;102.84;103.94;101.85;102.63;26670000;102.63
1980-04-14;103.79;103.92;102.08;102.84;23060000;102.84
1980-04-11;104.08;105.15;103.20;103.79;29960000;103.79
1980-04-10;103.11;105.00;102.81;104.08;33940000;104.08
1980-04-09;101.20;103.60;101.01;103.11;33020000;103.11
1980-04-08;100.19;101.88;99.23;101.20;31700000;101.20
1980-04-07;102.15;102.27;99.73;100.19;29130000;100.19
1980-04-03;102.68;103.34;101.31;102.15;27970000;102.15
1980-04-02;102.18;103.87;101.45;102.68;35210000;102.68
1980-04-01;102.09;103.28;100.85;102.18;32230000;102.18
1980-03-31;100.68;102.65;100.02;102.09;35840000;102.09
1980-03-28;98.22;101.43;97.72;100.68;46720000;100.68
1980-03-27;98.68;99.58;94.23;98.22;63680000;98.22
1980-03-26;99.19;101.22;98.10;98.68;37370000;98.68
1980-03-25;99.28;100.58;97.89;99.19;43790000;99.19
1980-03-24;102.18;102.18;98.88;99.28;39230000;99.28
1980-03-21;103.12;103.73;101.55;102.31;32220000;102.31
1980-03-20;104.31;105.17;102.52;103.12;32580000;103.12
1980-03-19;104.10;105.72;103.35;104.31;36520000;104.31
1980-03-18;102.26;104.71;101.14;104.10;47340000;104.10
1980-03-17;105.23;105.23;101.82;102.26;37020000;102.26
1980-03-14;105.62;106.49;104.01;105.43;35180000;105.43
1980-03-13;106.87;107.55;105.10;105.62;33070000;105.62
1980-03-12;107.78;108.40;105.42;106.87;37990000;106.87
1980-03-11;106.51;108.54;106.18;107.78;41350000;107.78
1980-03-10;106.90;107.86;104.92;106.51;43750000;106.51
1980-03-07;108.65;108.96;105.99;106.90;50950000;106.90
1980-03-06;111.13;111.29;107.85;108.65;49610000;108.65
1980-03-05;112.78;113.94;110.58;111.13;49240000;111.13
1980-03-04;112.50;113.41;110.83;112.78;44310000;112.78
1980-03-03;113.66;114.34;112.01;112.50;38690000;112.50
1980-02-29;112.35;114.12;111.77;113.66;38810000;113.66
1980-02-28;112.38;113.70;111.33;112.35;40330000;112.35
1980-02-27;113.98;115.12;111.91;112.38;46430000;112.38
1980-02-26;113.33;114.76;112.30;113.98;40000000;113.98
1980-02-25;114.93;114.93;112.62;113.33;39140000;113.33
1980-02-22;115.28;116.46;113.43;115.04;48210000;115.04
1980-02-21;116.47;117.90;114.44;115.28;51530000;115.28
1980-02-20;114.60;117.18;114.06;116.47;44340000;116.47
1980-02-19;115.41;115.67;113.35;114.60;39480000;114.60
1980-02-15;116.70;116.70;114.12;115.41;46680000;115.41
1980-02-14;118.44;119.30;116.04;116.72;50540000;116.72
1980-02-13;117.90;120.22;117.57;118.44;65230000;118.44
1980-02-12;117.12;118.41;115.75;117.90;48090000;117.90
1980-02-11;117.95;119.05;116.31;117.12;58660000;117.12
1980-02-08;116.28;118.66;115.72;117.95;57860000;117.95
1980-02-07;115.72;117.87;115.22;116.28;57690000;116.28
1980-02-06;114.66;116.57;113.65;115.72;51950000;115.72
1980-02-05;114.37;115.25;112.15;114.66;41880000;114.66
1980-02-04;115.12;116.01;113.83;114.37;43070000;114.37
1980-02-01;114.16;115.54;113.13;115.12;46610000;115.12
1980-01-31;115.20;117.17;113.78;114.16;65900000;114.16
1980-01-30;114.07;115.85;113.37;115.20;51170000;115.20
1980-01-29;114.85;115.77;113.03;114.07;55480000;114.07
1980-01-28;113.61;115.65;112.93;114.85;53620000;114.85
1980-01-25;113.70;114.45;112.36;113.61;47100000;113.61
1980-01-24;113.44;115.27;112.95;113.70;59070000;113.70
1980-01-23;111.51;113.93;110.93;113.44;50730000;113.44
1980-01-22;112.10;113.10;110.92;111.51;50620000;111.51
1980-01-21;111.07;112.90;110.66;112.10;48040000;112.10
1980-01-18;110.70;111.74;109.88;111.07;47150000;111.07
1980-01-17;111.05;112.01;109.81;110.70;54170000;110.70
1980-01-16;111.14;112.90;110.38;111.05;67700000;111.05
1980-01-15;110.38;111.93;109.45;111.14;52320000;111.14
1980-01-14;109.92;111.44;109.34;110.38;52930000;110.38
1980-01-11;109.89;111.16;108.89;109.92;52890000;109.92
1980-01-10;109.05;110.86;108.47;109.89;55980000;109.89
1980-01-09;108.95;111.09;108.41;109.05;65260000;109.05
1980-01-08;106.81;109.29;106.29;108.95;53390000;108.95
1980-01-07;106.52;107.80;105.80;106.81;44500000;106.81
1980-01-04;105.22;107.08;105.09;106.52;39130000;106.52
1980-01-03;105.76;106.08;103.26;105.22;50480000;105.22
1980-01-02;107.94;108.43;105.29;105.76;40610000;105.76
1979-12-31;107.84;108.53;107.26;107.94;31530000;107.94
1979-12-28;107.96;108.61;107.16;107.84;34430000;107.84
1979-12-27;107.78;108.50;107.14;107.96;31410000;107.96
1979-12-26;107.66;108.37;107.06;107.78;24960000;107.78
1979-12-24;107.59;108.08;106.80;107.66;19150000;107.66
1979-12-21;108.26;108.76;106.99;107.59;36160000;107.59
1979-12-20;108.20;109.24;107.40;108.26;40380000;108.26
1979-12-19;108.30;108.79;107.02;108.20;41780000;108.20
1979-12-18;109.33;109.83;107.83;108.30;43310000;108.30
1979-12-17;108.92;110.33;108.36;109.33;43830000;109.33
1979-12-14;107.67;109.49;107.37;108.92;41800000;108.92
1979-12-13;107.52;108.29;106.68;107.67;36690000;107.67
1979-12-12;107.49;108.32;106.78;107.52;34630000;107.52
1979-12-11;107.67;108.58;106.79;107.49;36160000;107.49
1979-12-10;107.52;108.27;106.65;107.67;32270000;107.67
1979-12-07;108.00;109.24;106.55;107.52;42370000;107.52
1979-12-06;107.25;108.47;106.71;108.00;37510000;108.00
1979-12-05;106.79;108.36;106.60;107.25;39300000;107.25
1979-12-04;105.83;107.25;105.66;106.79;33510000;106.79
1979-12-03;106.16;106.65;105.07;105.83;29030000;105.83
1979-11-30;106.81;107.16;105.56;106.16;30480000;106.16
1979-11-29;106.77;107.84;106.17;106.81;33550000;106.81
1979-11-28;106.38;107.55;105.29;106.77;39690000;106.77
1979-11-27;106.80;107.89;105.64;106.38;45140000;106.38
1979-11-26;104.83;107.44;104.83;106.80;47940000;106.80
1979-11-23;103.89;105.13;103.56;104.67;23300000;104.67
1979-11-21;103.69;104.23;102.04;103.89;37020000;103.89
1979-11-20;104.23;105.11;103.14;103.69;35010000;103.69
1979-11-19;103.79;105.08;103.17;104.23;33090000;104.23
1979-11-16;104.13;104.72;103.07;103.79;30060000;103.79
1979-11-15;103.39;104.94;103.10;104.13;32380000;104.13
1979-11-14;102.94;104.13;101.91;103.39;30970000;103.39
1979-11-13;103.51;104.21;102.42;102.94;29240000;102.94
1979-11-12;101.51;103.72;101.27;103.51;26640000;103.51
1979-11-09;100.58;102.18;100.58;101.51;30060000;101.51
1979-11-08;99.87;101.00;99.49;100.30;26270000;100.30
1979-11-07;100.97;100.97;99.42;99.87;30830000;99.87
1979-11-06;101.82;102.01;100.77;101.20;21960000;101.20
1979-11-05;102.51;102.66;101.24;101.82;20470000;101.82
1979-11-02;102.57;103.21;101.92;102.51;23670000;102.51
1979-11-01;101.82;103.07;101.10;102.57;25880000;102.57
1979-10-31;102.67;103.16;101.38;101.82;27780000;101.82
1979-10-30;100.71;102.83;100.41;102.67;28890000;102.67
1979-10-29;100.57;101.56;100.13;100.71;22720000;100.71
1979-10-26;100.00;101.31;99.59;100.57;29660000;100.57
1979-10-25;100.44;101.39;99.56;100.00;28440000;100.00
1979-10-24;100.28;101.45;99.66;100.44;31480000;100.44
1979-10-23;100.71;101.44;99.61;100.28;32910000;100.28
1979-10-22;101.38;101.38;99.06;100.71;45240000;100.71
1979-10-19;103.58;103.58;101.24;101.60;42430000;101.60
1979-10-18;103.39;104.62;102.92;103.61;29590000;103.61
1979-10-17;103.19;104.54;102.74;103.39;29650000;103.39
1979-10-16;103.36;104.37;102.52;103.19;33770000;103.19
1979-10-15;104.49;104.74;102.69;103.36;34850000;103.36
1979-10-12;105.05;106.20;104.01;104.49;36390000;104.49
1979-10-11;105.30;106.33;103.70;105.05;47530000;105.05
1979-10-10;106.23;106.23;102.31;105.30;81620000;105.30
1979-10-09;109.43;109.43;106.04;106.63;55560000;106.63
1979-10-08;111.27;111.83;109.65;109.88;32610000;109.88
1979-10-05;110.17;112.16;110.16;111.27;48250000;111.27
1979-10-04;109.59;110.81;109.14;110.17;38800000;110.17
1979-10-03;109.59;110.43;108.88;109.59;36470000;109.59
1979-10-02;108.56;110.08;108.03;109.59;38310000;109.59
1979-10-01;109.19;109.19;107.70;108.56;24980000;108.56
1979-09-28;110.21;110.67;108.70;109.32;35950000;109.32
1979-09-27;109.96;110.75;109.19;110.21;33110000;110.21
1979-09-26;109.68;111.25;109.37;109.96;37700000;109.96
1979-09-25;109.61;110.19;108.27;109.68;32410000;109.68
1979-09-24;110.47;110.90;109.16;109.61;33790000;109.61
1979-09-21;110.51;111.58;109.46;110.47;52380000;110.47
1979-09-20;108.28;110.69;107.59;110.51;45100000;110.51
1979-09-19;108.00;109.02;107.52;108.28;35370000;108.28
1979-09-18;108.84;109.00;107.32;108.00;38750000;108.00
1979-09-17;108.76;110.06;108.40;108.84;37610000;108.84
1979-09-14;107.85;109.48;107.42;108.76;41980000;108.76
1979-09-13;107.82;108.53;107.06;107.85;35240000;107.85
1979-09-12;107.51;108.41;106.72;107.82;39350000;107.82
1979-09-11;108.17;108.83;106.80;107.51;42530000;107.51
1979-09-10;107.66;108.71;107.21;108.17;32980000;108.17
1979-09-07;106.85;108.09;106.30;107.66;34360000;107.66
1979-09-06;106.40;107.61;105.97;106.85;30330000;106.85
1979-09-05;107.19;107.19;105.38;106.40;41650000;106.40
1979-09-04;109.32;109.41;107.22;107.44;33350000;107.44
1979-08-31;109.02;109.80;108.58;109.32;26370000;109.32
1979-08-30;109.02;109.59;108.40;109.02;29300000;109.02
1979-08-29;109.02;109.59;108.36;109.02;30810000;109.02
1979-08-28;109.14;109.65;108.47;109.02;29430000;109.02
1979-08-27;108.60;109.84;108.12;109.14;32050000;109.14
1979-08-24;108.63;109.11;107.65;108.60;32730000;108.60
1979-08-23;108.99;109.59;108.12;108.63;35710000;108.63
1979-08-22;108.91;109.56;108.09;108.99;38450000;108.99
1979-08-21;108.83;109.68;108.17;108.91;38860000;108.91
1979-08-20;108.30;109.32;107.69;108.83;32300000;108.83
1979-08-17;108.09;108.94;107.25;108.30;31630000;108.30
1979-08-16;108.25;109.18;107.38;108.09;47000000;108.09
1979-08-15;107.52;108.64;106.75;108.25;46130000;108.25
1979-08-14;107.42;108.03;106.60;107.52;40910000;107.52
1979-08-13;106.40;107.90;106.28;107.42;41980000;107.42
1979-08-10;105.49;106.79;104.81;106.40;36740000;106.40
1979-08-09;105.98;106.25;104.89;105.49;34630000;105.49
1979-08-08;105.65;106.84;105.20;105.98;44970000;105.98
1979-08-07;104.30;106.23;104.12;105.65;45410000;105.65
1979-08-06;104.04;104.66;103.27;104.30;27190000;104.30
1979-08-03;104.10;104.56;103.36;104.04;28160000;104.04
1979-08-02;104.17;105.02;103.59;104.10;37720000;104.10
1979-08-01;103.81;104.57;103.14;104.17;36570000;104.17
1979-07-31;103.15;104.26;102.89;103.81;34360000;103.81
1979-07-30;103.10;103.63;102.42;103.15;28640000;103.15
1979-07-27;103.10;103.50;102.29;103.10;27760000;103.10
1979-07-26;103.08;103.63;102.34;103.10;32270000;103.10
1979-07-25;101.97;103.44;101.85;103.08;34890000;103.08
1979-07-24;101.59;102.50;101.14;101.97;29690000;101.97
1979-07-23;101.82;102.13;100.84;101.59;26860000;101.59
1979-07-20;101.61;102.32;101.06;101.82;26360000;101.82
1979-07-19;101.69;102.42;101.04;101.61;26780000;101.61
1979-07-18;101.83;102.06;100.35;101.69;35950000;101.69
1979-07-17;102.74;103.06;101.27;101.83;34270000;101.83
1979-07-16;102.32;103.20;101.81;102.74;26620000;102.74
1979-07-13;102.69;102.99;101.49;102.32;33080000;102.32
1979-07-12;103.64;103.72;102.22;102.69;31780000;102.69
1979-07-11;104.20;104.34;102.87;103.64;36650000;103.64
1979-07-10;104.47;105.17;103.52;104.20;39730000;104.20
1979-07-09;103.62;105.07;103.36;104.47;42460000;104.47
1979-07-06;102.43;103.91;102.12;103.62;38570000;103.62
1979-07-05;102.09;102.88;101.59;102.43;30290000;102.43
1979-07-03;101.99;102.57;101.31;102.09;31670000;102.09
1979-07-02;102.91;103.00;101.45;101.99;32060000;101.99
1979-06-29;102.80;103.67;102.04;102.91;34690000;102.91
1979-06-28;102.27;103.46;101.91;102.80;38470000;102.80
1979-06-27;101.66;102.95;101.29;102.27;36720000;102.27
1979-06-26;102.09;102.09;101.22;101.66;34680000;101.66
1979-06-25;102.64;102.91;101.45;102.09;31330000;102.09
1979-06-22;102.09;103.16;101.91;102.64;36410000;102.64
1979-06-21;101.63;102.74;101.20;102.09;36490000;102.09
1979-06-20;101.58;102.19;100.93;101.63;33790000;101.63
1979-06-19;101.56;102.28;100.91;101.58;30780000;101.58
1979-06-18;102.09;102.48;101.05;101.56;30970000;101.56
1979-06-15;102.20;102.78;101.38;102.09;40740000;102.09
1979-06-14;102.31;102.63;101.04;102.20;37850000;102.20
1979-06-13;102.85;103.58;101.83;102.31;40740000;102.31
1979-06-12;101.91;103.64;101.81;102.85;45450000;102.85
1979-06-11;101.49;102.24;100.91;101.91;28270000;101.91
1979-06-08;101.79;102.23;100.91;101.49;31470000;101.49
1979-06-07;101.30;102.54;101.15;101.79;43380000;101.79
1979-06-06;100.62;101.96;100.38;101.30;39830000;101.30
1979-06-05;99.32;101.07;99.17;100.62;35050000;100.62
1979-06-04;99.17;99.76;98.61;99.32;24040000;99.32
1979-06-01;99.08;99.70;98.57;99.17;24560000;99.17
1979-05-31;99.11;99.61;98.29;99.08;30300000;99.08
1979-05-30;100.05;100.25;98.79;99.11;29250000;99.11
1979-05-29;100.22;100.76;99.56;100.05;27040000;100.05
1979-05-25;99.93;100.68;99.52;100.22;27810000;100.22
1979-05-24;99.89;100.44;99.14;99.93;25710000;99.93
1979-05-23;100.51;101.31;99.63;99.89;30390000;99.89
1979-05-22;100.14;100.93;99.45;100.51;30400000;100.51
1979-05-21;99.93;100.75;99.37;100.14;25550000;100.14
1979-05-18;99.94;100.73;99.33;99.93;26590000;99.93
1979-05-17;98.42;100.22;98.29;99.94;30550000;99.94
1979-05-16;98.14;98.80;97.49;98.42;28350000;98.42
1979-05-15;98.06;98.90;97.60;98.14;26190000;98.14
1979-05-14;98.52;98.95;97.71;98.06;22450000;98.06
1979-05-11;98.52;99.03;97.92;98.52;24010000;98.52
1979-05-10;99.46;99.63;98.22;98.52;25230000;98.52
1979-05-09;99.17;100.01;98.50;99.46;27670000;99.46
1979-05-08;99.02;99.56;97.98;99.17;32720000;99.17
1979-05-07;100.37;100.37;98.78;99.02;30480000;99.02
1979-05-04;101.81;102.08;100.42;100.69;30630000;100.69
1979-05-03;101.72;102.57;101.25;101.81;30870000;101.81
1979-05-02;101.68;102.28;101.00;101.72;30510000;101.72
1979-05-01;101.76;102.50;101.22;101.68;31040000;101.68
1979-04-30;101.80;102.24;100.91;101.76;26440000;101.76
1979-04-27;102.01;102.32;101.04;101.80;29610000;101.80
1979-04-26;102.50;102.91;101.58;102.01;32400000;102.01
1979-04-25;102.20;103.07;101.79;102.50;31750000;102.50
1979-04-24;101.57;103.02;101.39;102.20;35540000;102.20
1979-04-23;101.23;102.00;100.68;101.57;25610000;101.57
1979-04-20;101.28;101.81;100.46;101.23;28830000;101.23
1979-04-19;101.70;102.40;100.88;101.28;31150000;101.28
1979-04-18;101.24;102.23;100.96;101.70;29510000;101.70
1979-04-17;101.12;101.94;100.65;101.24;29260000;101.24
1979-04-16;102.00;102.02;100.67;101.12;28050000;101.12
1979-04-12;102.31;102.77;101.51;102.00;26780000;102.00
1979-04-11;103.34;103.77;101.92;102.31;32900000;102.31
1979-04-10;102.87;103.83;102.42;103.34;31900000;103.34
1979-04-09;103.18;103.56;102.28;102.87;27230000;102.87
1979-04-06;103.26;103.95;102.58;103.18;34710000;103.18
1979-04-05;102.65;103.60;102.16;103.26;34520000;103.26
1979-04-04;102.40;103.73;102.16;102.65;41940000;102.65
1979-04-03;100.90;102.67;100.81;102.40;33530000;102.40
1979-04-02;101.56;101.56;100.14;100.90;28990000;100.90
1979-03-30;102.03;102.51;101.03;101.59;29970000;101.59
1979-03-29;102.12;102.78;101.43;102.03;28510000;102.03
1979-03-28;102.48;103.31;101.74;102.12;39920000;102.12
1979-03-27;101.04;102.71;100.81;102.48;32940000;102.48
1979-03-26;101.60;101.77;100.60;101.04;23430000;101.04
1979-03-23;101.67;102.37;101.02;101.60;33570000;101.60
1979-03-22;101.25;102.41;101.04;101.67;34380000;101.67
1979-03-21;100.50;101.48;99.87;101.25;31120000;101.25
1979-03-20;101.06;101.34;100.01;100.50;27180000;100.50
1979-03-19;100.69;101.94;100.35;101.06;34620000;101.06
1979-03-16;99.86;101.16;99.53;100.69;31770000;100.69
1979-03-15;99.71;100.57;99.11;99.86;29370000;99.86
1979-03-14;99.84;100.43;99.23;99.71;24630000;99.71
1979-03-13;99.67;100.66;99.13;99.84;31170000;99.84
1979-03-12;99.54;100.04;98.56;99.67;25740000;99.67
1979-03-09;99.58;100.58;99.12;99.54;33410000;99.54
1979-03-08;98.44;99.82;98.10;99.58;32000000;99.58
1979-03-07;97.87;99.23;97.67;98.44;28930000;98.44
1979-03-06;98.06;98.53;97.36;97.87;24490000;97.87
1979-03-05;97.03;98.64;97.03;98.06;25690000;98.06
1979-03-02;96.90;97.55;96.44;96.97;23130000;96.97
1979-03-01;96.28;97.28;95.98;96.90;23830000;96.90
1979-02-28;96.13;96.69;95.38;96.28;25090000;96.28
1979-02-27;97.65;97.65;95.69;96.13;31470000;96.13
1979-02-26;97.78;98.28;97.20;97.67;22620000;97.67
1979-02-23;98.33;98.50;97.29;97.78;22750000;97.78
1979-02-22;99.07;99.21;97.88;98.33;26290000;98.33
1979-02-21;99.42;100.07;98.69;99.07;26050000;99.07
1979-02-20;98.67;99.67;98.26;99.42;22010000;99.42
1979-02-16;98.73;99.23;98.11;98.67;21110000;98.67
1979-02-15;98.87;99.13;97.96;98.73;22550000;98.73
1979-02-14;98.93;99.64;98.21;98.87;27220000;98.87
1979-02-13;98.25;99.58;98.25;98.93;28470000;98.93
1979-02-12;97.87;98.55;97.05;98.20;20610000;98.20
1979-02-09;97.65;98.50;97.28;97.87;24320000;97.87
1979-02-08;97.16;98.11;96.82;97.65;23360000;97.65
1979-02-07;98.05;98.07;96.51;97.16;28450000;97.16
1979-02-06;98.09;98.74;97.48;98.05;23570000;98.05
1979-02-05;99.07;99.07;97.57;98.09;26490000;98.09
1979-02-02;99.96;100.52;99.10;99.50;25350000;99.50
1979-02-01;99.93;100.38;99.01;99.96;27930000;99.96
1979-01-31;101.05;101.41;99.47;99.93;30330000;99.93
1979-01-30;101.55;102.07;100.68;101.05;26910000;101.05
1979-01-29;101.86;102.33;100.99;101.55;24170000;101.55
1979-01-26;101.19;102.59;101.03;101.86;34230000;101.86
1979-01-25;100.16;101.66;99.99;101.19;31440000;101.19
1979-01-24;100.60;101.31;99.67;100.16;31730000;100.16
1979-01-23;99.90;101.05;99.35;100.60;30130000;100.60
1979-01-22;99.75;100.35;98.90;99.90;24390000;99.90
1979-01-19;99.72;100.57;99.22;99.75;26800000;99.75
1979-01-18;99.48;100.35;98.91;99.72;27260000;99.72
1979-01-17;99.46;100.00;98.33;99.48;25310000;99.48
1979-01-16;100.69;100.88;99.11;99.46;30340000;99.46
1979-01-15;99.93;101.13;99.58;100.69;27520000;100.69
1979-01-12;99.32;100.91;99.32;99.93;37120000;99.93
1979-01-11;98.77;99.41;97.95;99.10;24580000;99.10
1979-01-10;99.33;99.75;98.28;98.77;24990000;98.77
1979-01-09;98.80;99.96;98.62;99.33;27340000;99.33
1979-01-08;99.13;99.30;97.83;98.80;21440000;98.80
1979-01-05;98.58;99.79;98.25;99.13;28890000;99.13
1979-01-04;97.80;99.42;97.52;98.58;33290000;98.58
1979-01-03;96.81;98.54;96.81;97.80;29180000;97.80
1979-01-02;96.11;96.96;95.22;96.73;18340000;96.73
1978-12-29;96.28;97.03;95.48;96.11;30030000;96.11
1978-12-28;96.66;97.19;95.82;96.28;25440000;96.28
1978-12-27;97.51;97.51;96.15;96.66;23580000;96.66
1978-12-26;96.31;97.89;95.99;97.52;21470000;97.52
1978-12-22;94.77;96.62;94.77;96.31;23790000;96.31
1978-12-21;94.68;95.66;94.11;94.71;28670000;94.71
1978-12-20;94.24;95.20;93.70;94.68;26520000;94.68
1978-12-19;93.44;94.85;93.05;94.24;25960000;94.24
1978-12-18;94.33;94.33;92.64;93.44;32900000;93.44
1978-12-15;96.04;96.28;94.88;95.33;23620000;95.33
1978-12-14;96.06;96.44;95.20;96.04;20840000;96.04
1978-12-13;96.59;97.07;95.59;96.06;22480000;96.06
1978-12-12;97.11;97.58;96.27;96.59;22210000;96.59
1978-12-11;96.63;97.56;96.07;97.11;21000000;97.11
1978-12-08;97.08;97.48;96.14;96.63;18560000;96.63
1978-12-07;97.49;98.10;96.58;97.08;21170000;97.08
1978-12-06;97.44;98.58;96.83;97.49;29680000;97.49
1978-12-05;96.15;97.70;95.88;97.44;25670000;97.44
1978-12-04;96.28;96.96;95.37;96.15;22020000;96.15
1978-12-01;95.01;96.69;95.01;96.28;26830000;96.28
1978-11-30;93.75;94.94;93.29;94.70;19900000;94.70
1978-11-29;94.92;94.92;93.48;93.75;21160000;93.75
1978-11-28;95.99;96.51;94.88;95.15;22740000;95.15
1978-11-27;95.79;96.52;95.17;95.99;19790000;95.99
1978-11-24;95.48;96.17;94.98;95.79;14590000;95.79
1978-11-22;95.01;95.91;94.54;95.48;20010000;95.48
1978-11-21;95.25;95.83;94.49;95.01;20750000;95.01
1978-11-20;94.42;95.86;94.29;95.25;24440000;95.25
1978-11-17;93.71;95.03;93.59;94.42;25170000;94.42
1978-11-16;92.71;94.08;92.59;93.71;21340000;93.71
1978-11-15;92.49;94.00;92.29;92.71;26280000;92.71
1978-11-14;93.13;93.53;91.77;92.49;30610000;92.49
1978-11-13;94.77;94.90;92.96;93.13;20960000;93.13
1978-11-10;94.42;95.39;93.94;94.77;16750000;94.77
1978-11-09;94.45;95.50;93.81;94.42;23320000;94.42
1978-11-08;93.85;94.74;92.89;94.45;23560000;94.45
1978-11-07;94.75;94.75;93.14;93.85;25320000;93.85
1978-11-06;96.18;96.49;94.84;95.19;20450000;95.19
1978-11-03;95.61;96.98;94.78;96.18;25990000;96.18
1978-11-02;96.85;97.31;94.84;95.61;41030000;95.61
1978-11-01;94.13;97.41;94.13;96.85;50450000;96.85
1978-10-31;95.06;95.80;92.72;93.15;42720000;93.15
1978-10-30;94.59;95.49;91.65;95.06;59480000;95.06
1978-10-27;96.03;96.62;94.30;94.59;40360000;94.59
1978-10-26;97.31;97.71;95.59;96.03;31990000;96.03
1978-10-25;97.49;98.56;96.33;97.31;31380000;97.31
1978-10-24;98.18;98.95;97.13;97.49;28880000;97.49
1978-10-23;97.95;98.84;96.63;98.18;36090000;98.18
1978-10-20;99.26;99.26;97.12;97.95;43670000;97.95
1978-10-19;100.49;101.03;99.04;99.33;31810000;99.33
1978-10-18;101.26;101.76;99.89;100.49;32940000;100.49
1978-10-17;102.35;102.35;100.47;101.26;37870000;101.26
1978-10-16;104.63;104.63;102.43;102.61;24600000;102.61
1978-10-13;104.88;105.34;104.07;104.66;21920000;104.66
1978-10-12;105.39;106.23;104.42;104.88;30170000;104.88
1978-10-11;104.46;105.64;103.80;105.39;21740000;105.39
1978-10-10;104.59;105.36;103.90;104.46;25470000;104.46
1978-10-09;103.52;104.89;103.31;104.59;19720000;104.59
1978-10-06;103.27;104.23;102.82;103.52;27380000;103.52
1978-10-05;103.06;104.10;102.54;103.27;27820000;103.27
1978-10-04;102.60;103.36;101.76;103.06;25090000;103.06
1978-10-03;102.96;103.56;102.18;102.60;22540000;102.60
1978-10-02;102.54;103.42;102.13;102.96;18700000;102.96
1978-09-29;101.96;103.08;101.65;102.54;23610000;102.54
1978-09-28;101.66;102.38;100.94;101.96;24390000;101.96
1978-09-27;102.62;103.44;101.33;101.66;28370000;101.66
1978-09-26;101.86;103.15;101.58;102.62;26330000;102.62
1978-09-25;101.84;102.36;101.05;101.86;20970000;101.86
1978-09-22;101.90;102.69;101.13;101.84;27960000;101.84
1978-09-21;101.73;102.54;100.66;101.90;33640000;101.90
1978-09-20;102.53;103.29;101.28;101.73;35080000;101.73
1978-09-19;103.21;103.82;102.12;102.53;31660000;102.53
1978-09-18;104.12;105.03;102.75;103.21;35860000;103.21
1978-09-15;105.10;105.12;103.56;104.12;37290000;104.12
1978-09-14;106.34;106.62;104.77;105.10;37400000;105.10
1978-09-13;106.99;107.85;105.87;106.34;43340000;106.34
1978-09-12;106.98;107.48;106.02;106.99;34400000;106.99
1978-09-11;106.79;108.05;106.42;106.98;39670000;106.98
1978-09-08;105.50;107.19;105.50;106.79;42170000;106.79
1978-09-07;105.38;106.49;104.76;105.42;40310000;105.42
1978-09-06;104.51;106.19;104.51;105.38;42600000;105.38
1978-09-05;103.68;104.83;103.31;104.49;32170000;104.49
1978-09-01;103.29;104.27;102.73;103.68;35070000;103.68
1978-08-31;103.50;104.05;102.63;103.29;33850000;103.29
1978-08-30;103.39;104.26;102.70;103.50;37750000;103.50
1978-08-29;103.96;104.34;102.92;103.39;33780000;103.39
1978-08-28;104.90;105.14;103.61;103.96;31760000;103.96
1978-08-25;105.08;105.68;104.24;104.90;36190000;104.90
1978-08-24;104.91;105.86;104.29;105.08;38500000;105.08
1978-08-23;104.31;105.68;104.12;104.91;39630000;104.91
1978-08-22;103.89;104.79;103.14;104.31;29620000;104.31
1978-08-21;104.73;105.20;103.44;103.89;29440000;103.89
1978-08-18;105.08;105.98;104.23;104.73;34650000;104.73
1978-08-17;104.65;106.27;104.34;105.08;45270000;105.08
1978-08-16;103.85;105.15;103.41;104.65;36120000;104.65
1978-08-15;103.97;104.38;102.86;103.85;29760000;103.85
1978-08-14;103.96;104.98;103.40;103.97;32320000;103.97
1978-08-11;103.66;104.67;102.85;103.96;33550000;103.96
1978-08-10;104.50;105.11;103.10;103.66;39760000;103.66
1978-08-09;104.01;105.72;103.70;104.50;48800000;104.50
1978-08-08;103.55;104.35;102.60;104.01;34290000;104.01
1978-08-07;103.92;104.84;103.03;103.55;33350000;103.55
1978-08-04;103.51;104.67;102.75;103.92;37910000;103.92
1978-08-03;102.92;105.41;102.82;103.51;66370000;103.51
1978-08-02;100.66;103.21;100.18;102.92;47470000;102.92
1978-08-01;100.68;101.46;99.95;100.66;34810000;100.66
1978-07-31;100.00;101.18;99.37;100.68;33990000;100.68
1978-07-28;99.54;100.51;98.90;100.00;33390000;100.00
1978-07-27;99.08;100.17;98.60;99.54;33970000;99.54
1978-07-26;99.08;99.08;99.08;99.08;36830000;99.08
1978-07-25;97.72;98.73;97.20;98.44;25400000;98.44
1978-07-24;97.75;98.13;96.72;97.72;23280000;97.72
1978-07-21;98.03;98.57;97.02;97.75;26060000;97.75
1978-07-20;98.12;99.18;97.49;98.03;33350000;98.03
1978-07-19;96.87;98.41;96.71;98.12;30850000;98.12
1978-07-18;97.78;97.98;96.52;96.87;22860000;96.87
1978-07-17;97.58;98.84;97.24;97.78;29180000;97.78
1978-07-14;96.25;97.88;95.89;97.58;28370000;97.58
1978-07-13;96.24;96.66;95.42;96.25;23620000;96.25
1978-07-12;95.93;96.83;95.50;96.24;26640000;96.24
1978-07-11;95.27;96.49;94.92;95.93;27470000;95.93
1978-07-10;94.89;95.67;94.28;95.27;22470000;95.27
1978-07-07;94.32;95.32;94.02;94.89;23480000;94.89
1978-07-06;94.27;94.83;93.59;94.32;24990000;94.32
1978-07-05;95.09;95.20;93.78;94.27;23730000;94.27
1978-07-03;95.53;95.65;94.62;95.09;11560000;95.09
1978-06-30;95.57;95.96;94.87;95.53;18100000;95.53
1978-06-29;95.40;96.26;95.00;95.57;21660000;95.57
1978-06-28;94.98;95.79;94.44;95.40;23260000;95.40
1978-06-27;94.60;95.48;93.99;94.98;29280000;94.98
1978-06-26;95.85;96.06;94.31;94.60;29250000;94.60
1978-06-23;96.24;96.98;95.49;95.85;28530000;95.85
1978-06-22;96.01;96.76;95.52;96.24;27160000;96.24
1978-06-21;96.51;96.74;95.42;96.01;29100000;96.01
1978-06-20;97.49;97.78;96.15;96.51;27920000;96.51
1978-06-19;97.42;97.94;96.53;97.49;25500000;97.49
1978-06-16;98.34;98.59;97.10;97.42;27690000;97.42
1978-06-15;99.48;99.54;97.97;98.34;29280000;98.34
1978-06-14;99.57;100.68;98.89;99.48;37290000;99.48
1978-06-13;99.55;99.98;98.43;99.57;30760000;99.57
1978-06-12;99.93;100.60;99.16;99.55;24440000;99.55
1978-06-09;100.21;100.71;99.30;99.93;32470000;99.93
1978-06-08;100.12;101.21;99.55;100.21;39380000;100.21
1978-06-07;100.32;100.81;99.36;100.12;33060000;100.12
1978-06-06;99.95;101.84;99.90;100.32;51970000;100.32
1978-06-05;98.14;100.27;97.97;99.95;39580000;99.95
1978-06-02;97.35;98.52;97.01;98.14;31860000;98.14
1978-06-01;97.24;97.95;96.63;97.35;28750000;97.35
1978-05-31;96.86;97.97;96.50;97.24;29070000;97.24
1978-05-30;96.58;97.23;95.95;96.86;21040000;96.86
1978-05-26;96.80;97.14;96.01;96.58;21410000;96.58
1978-05-25;97.08;97.80;96.30;96.80;28410000;96.80
1978-05-24;97.74;97.74;96.27;97.08;31450000;97.08
1978-05-23;99.09;99.17;97.53;98.05;33230000;98.05
1978-05-22;98.12;99.43;97.65;99.09;28680000;99.09
1978-05-19;98.62;99.06;97.42;98.12;34360000;98.12
1978-05-18;99.60;100.04;98.19;98.62;42270000;98.62
1978-05-17;99.35;100.32;98.63;99.60;45490000;99.60
1978-05-16;98.76;100.16;98.61;99.35;48170000;99.35
1978-05-15;98.07;99.11;97.40;98.76;33890000;98.76
1978-05-12;97.20;98.89;97.14;98.07;46600000;98.07
1978-05-11;95.92;97.47;95.60;97.20;36630000;97.20
1978-05-10;95.90;96.69;95.35;95.92;33330000;95.92
1978-05-09;96.19;96.68;95.33;95.90;30860000;95.90
1978-05-08;96.53;97.50;95.82;96.19;34680000;96.19
1978-05-05;95.93;97.44;95.56;96.53;42680000;96.53
1978-05-04;96.26;96.43;94.57;95.93;37520000;95.93
1978-05-03;97.25;97.61;95.84;96.26;37560000;96.26
1978-05-02;97.67;98.11;96.44;97.25;41400000;97.25
1978-05-01;96.83;98.30;96.41;97.67;37020000;97.67
1978-04-28;95.86;97.10;95.24;96.83;32850000;96.83
1978-04-27;96.82;96.93;95.30;95.86;35470000;95.86
1978-04-26;96.64;97.75;95.96;96.82;44430000;96.82
1978-04-25;96.05;97.91;96.05;96.64;55800000;96.64
1978-04-24;94.34;96.00;94.08;95.77;34510000;95.77
1978-04-21;94.54;95.09;93.71;94.34;31540000;94.34
1978-04-20;93.97;95.71;93.97;94.54;43230000;94.54
1978-04-19;93.43;94.48;92.75;93.86;35060000;93.86
1978-04-18;94.45;94.72;92.87;93.43;38950000;93.43
1978-04-17;93.60;95.89;93.60;94.45;63510000;94.45
1978-04-14;91.40;93.31;91.40;92.92;52280000;92.92
1978-04-13;90.11;91.27;89.82;90.98;31580000;90.98
1978-04-12;90.25;90.78;89.65;90.11;26210000;90.11
1978-04-11;90.49;90.79;89.77;90.25;24300000;90.25
1978-04-10;90.17;90.88;89.73;90.49;25740000;90.49
1978-04-07;89.79;90.59;89.39;90.17;25160000;90.17
1978-04-06;89.64;90.46;89.31;89.79;27360000;89.79
1978-04-05;88.86;89.91;88.62;89.64;27260000;89.64
1978-04-04;88.46;89.18;88.16;88.86;20130000;88.86
1978-04-03;89.20;89.20;88.07;88.46;20230000;88.46
1978-03-31;89.41;89.64;88.68;89.21;20130000;89.21
1978-03-30;89.64;89.89;88.97;89.41;20460000;89.41
1978-03-29;89.50;90.17;89.14;89.64;25450000;89.64
1978-03-28;88.87;89.76;88.47;89.50;21600000;89.50
1978-03-27;89.36;89.50;88.51;88.87;18870000;88.87
1978-03-23;89.47;89.90;88.83;89.36;21290000;89.36
1978-03-22;89.79;90.07;88.99;89.47;21950000;89.47
1978-03-21;90.82;91.06;89.50;89.79;24410000;89.79
1978-03-20;90.20;91.35;90.10;90.82;28360000;90.82
1978-03-17;89.51;90.52;89.17;90.20;28470000;90.20
1978-03-16;89.12;89.77;88.58;89.51;25400000;89.51
1978-03-15;89.35;89.73;88.52;89.12;23340000;89.12
1978-03-14;88.95;89.62;88.21;89.35;24300000;89.35
1978-03-13;88.88;89.77;88.48;88.95;24070000;88.95
1978-03-10;87.89;89.25;87.82;88.88;27090000;88.88
1978-03-09;87.84;88.49;87.34;87.89;21820000;87.89
1978-03-08;87.36;88.08;86.97;87.84;22030000;87.84
1978-03-07;86.90;87.63;86.55;87.36;19900000;87.36
1978-03-06;87.45;87.52;86.48;86.90;17230000;86.90
1978-03-03;87.32;87.98;86.83;87.45;20120000;87.45
1978-03-02;87.19;87.81;86.69;87.32;20280000;87.32
1978-03-01;87.04;87.63;86.45;87.19;21010000;87.19
1978-02-28;87.72;87.76;86.58;87.04;19750000;87.04
1978-02-27;88.49;88.97;87.49;87.72;19990000;87.72
1978-02-24;87.66;88.87;87.66;88.49;22510000;88.49
1978-02-23;87.56;87.92;86.83;87.64;18720000;87.64
1978-02-22;87.59;88.15;87.19;87.56;18450000;87.56
1978-02-21;87.96;88.19;87.09;87.59;21890000;87.59
1978-02-17;88.08;88.70;87.55;87.96;18500000;87.96
1978-02-16;88.77;88.77;87.64;88.08;21570000;88.08
1978-02-15;89.04;89.40;88.30;88.83;20170000;88.83
1978-02-14;89.86;89.89;88.70;89.04;20470000;89.04
1978-02-13;90.08;90.30;89.38;89.86;16810000;89.86
1978-02-10;90.30;90.69;89.56;90.08;19480000;90.08
1978-02-09;90.83;90.96;89.84;90.30;17940000;90.30
1978-02-08;90.33;91.32;90.09;90.83;21300000;90.83
1978-02-07;89.50;90.53;89.38;90.33;14730000;90.33
1978-02-06;89.62;89.85;88.95;89.50;11630000;89.50
1978-02-03;90.13;90.32;89.19;89.62;19400000;89.62
1978-02-02;89.93;90.91;89.54;90.13;23050000;90.13
1978-02-01;89.25;90.24;88.82;89.93;22240000;89.93
1978-01-31;89.34;89.92;88.61;89.25;19870000;89.25
1978-01-30;88.58;89.67;88.26;89.34;17400000;89.34
1978-01-27;88.58;89.10;88.02;88.58;17600000;88.58
1978-01-26;89.39;89.79;88.31;88.58;19600000;88.58
1978-01-25;89.25;89.94;88.83;89.39;18690000;89.39
1978-01-24;89.24;89.80;88.67;89.25;18690000;89.25
1978-01-23;89.89;90.08;88.81;89.24;19380000;89.24
1978-01-20;90.09;90.27;89.41;89.89;7580000;89.89
1978-01-19;90.56;91.04;89.74;90.09;21500000;90.09
1978-01-18;89.88;90.86;89.59;90.56;21390000;90.56
1978-01-17;89.43;90.31;89.05;89.88;19360000;89.88
1978-01-16;89.69;90.11;88.88;89.43;18760000;89.43
1978-01-13;89.82;90.47;89.26;89.69;18010000;89.69
1978-01-12;89.74;90.60;89.25;89.82;22730000;89.82
1978-01-11;90.17;90.70;89.23;89.74;22880000;89.74
1978-01-10;90.64;91.29;89.72;90.17;25180000;90.17
1978-01-09;91.48;91.48;89.97;90.64;27990000;90.64
1978-01-06;92.66;92.66;91.05;91.62;26150000;91.62
1978-01-05;93.52;94.53;92.51;92.74;23570000;92.74
1978-01-04;93.82;94.10;92.57;93.52;24090000;93.52
1978-01-03;95.10;95.15;93.49;93.82;17720000;93.82
1977-12-30;94.94;95.67;94.44;95.10;23560000;95.10
1977-12-29;94.75;95.43;94.10;94.94;23610000;94.94
1977-12-28;94.69;95.20;93.99;94.75;19630000;94.75
1977-12-27;94.69;95.21;94.09;94.69;16750000;94.69
1977-12-23;93.80;94.99;93.75;94.69;20080000;94.69
1977-12-22;93.05;94.37;93.05;93.80;28100000;93.80
1977-12-21;92.50;93.58;92.20;93.05;24510000;93.05
1977-12-20;92.69;93.00;91.76;92.50;23250000;92.50
1977-12-19;93.40;93.71;92.42;92.69;21150000;92.69
1977-12-16;93.55;94.04;92.93;93.40;20270000;93.40
1977-12-15;94.03;94.42;93.23;93.55;21610000;93.55
1977-12-14;93.56;94.26;92.94;94.03;22110000;94.03
1977-12-13;93.63;94.04;92.90;93.56;19190000;93.56
1977-12-12;93.65;94.29;93.18;93.63;18180000;93.63
1977-12-09;92.96;94.11;92.77;93.65;19210000;93.65
1977-12-08;92.78;93.76;92.51;92.96;20400000;92.96
1977-12-07;92.83;93.39;92.15;92.78;21050000;92.78
1977-12-06;94.09;94.09;92.44;92.83;23770000;92.83
1977-12-05;94.67;95.01;93.91;94.27;19160000;94.27
1977-12-02;94.69;95.25;94.08;94.67;21160000;94.67
1977-12-01;94.83;95.45;94.23;94.69;24220000;94.69
1977-11-30;94.55;95.17;93.78;94.83;22670000;94.83
1977-11-29;96.04;96.09;94.28;94.55;22950000;94.55
1977-11-28;96.69;96.98;95.67;96.04;21570000;96.04
1977-11-25;96.49;97.11;95.86;96.69;17910000;96.69
1977-11-23;96.09;96.94;95.60;96.49;29150000;96.49
1977-11-22;95.25;96.52;95.05;96.09;28600000;96.09
1977-11-21;95.33;95.77;94.59;95.25;20110000;95.25
1977-11-18;95.16;95.88;94.70;95.33;23930000;95.33
1977-11-17;95.45;95.88;94.59;95.16;25110000;95.16
1977-11-16;95.93;96.47;95.06;95.45;24950000;95.45
1977-11-15;95.32;96.47;94.73;95.93;27740000;95.93
1977-11-14;95.98;96.38;94.91;95.32;23220000;95.32
1977-11-11;95.10;96.49;95.10;95.98;35260000;95.98
1977-11-10;92.98;95.10;92.69;94.71;31980000;94.71
1977-11-09;92.46;93.27;92.01;92.98;21330000;92.98
1977-11-08;92.29;92.97;91.82;92.46;19210000;92.46
1977-11-07;91.58;92.70;91.32;92.29;21270000;92.29
1977-11-04;90.76;91.97;90.72;91.58;21700000;91.58
1977-11-03;90.71;91.18;90.01;90.76;18090000;90.76
1977-11-02;91.35;91.59;90.29;90.71;20760000;90.71
1977-11-01;92.19;92.19;91.00;91.35;17170000;91.35
1977-10-31;92.61;93.03;91.85;92.34;17070000;92.34
1977-10-28;92.34;93.13;91.88;92.61;18050000;92.61
1977-10-27;92.10;93.15;91.54;92.34;21920000;92.34
1977-10-26;91.00;92.46;90.44;92.10;24860000;92.10
1977-10-25;91.63;91.71;90.20;91.00;23590000;91.00
1977-10-24;92.32;92.62;91.36;91.63;19210000;91.63
1977-10-21;92.67;92.99;91.80;92.32;20230000;92.32
1977-10-20;92.38;93.12;91.60;92.67;20520000;92.67
1977-10-19;93.46;93.71;92.07;92.38;22030000;92.38
1977-10-18;93.47;94.19;93.01;93.46;20130000;93.46
1977-10-17;93.56;94.03;92.87;93.47;17340000;93.47
1977-10-14;93.46;94.19;92.88;93.56;20410000;93.56
1977-10-13;94.04;94.32;92.89;93.46;23870000;93.46
1977-10-12;94.82;94.82;93.40;94.04;22440000;94.04
1977-10-11;95.75;95.97;94.73;94.93;17870000;94.93
1977-10-10;95.97;96.15;95.32;95.75;10580000;95.75
1977-10-07;96.05;96.51;95.48;95.97;16250000;95.97
1977-10-06;95.68;96.45;95.30;96.05;18490000;96.05
1977-10-05;96.03;96.36;95.20;95.68;18300000;95.68
1977-10-04;96.74;97.27;95.73;96.03;20850000;96.03
1977-10-03;96.53;97.11;95.86;96.74;19460000;96.74
1977-09-30;95.85;96.85;95.66;96.53;21170000;96.53
1977-09-29;95.31;96.28;95.09;95.85;21160000;95.85
1977-09-28;95.24;95.91;94.73;95.31;17960000;95.31
1977-09-27;95.38;96.01;94.76;95.24;19080000;95.24
1977-09-26;95.04;95.68;94.44;95.38;18230000;95.38
1977-09-23;95.09;95.69;94.60;95.04;18760000;95.04
1977-09-22;95.10;95.61;94.51;95.09;16660000;95.09
1977-09-21;95.89;96.52;94.83;95.10;22200000;95.10
1977-09-20;95.85;96.29;95.23;95.89;19030000;95.89
1977-09-19;96.48;96.59;95.46;95.85;16890000;95.85
1977-09-16;96.80;97.30;96.05;96.48;18340000;96.48
1977-09-15;96.55;97.31;96.15;96.80;18230000;96.80
1977-09-14;96.09;96.88;95.66;96.55;17330000;96.55
1977-09-13;96.03;96.56;95.48;96.09;14900000;96.09
1977-09-12;96.37;96.64;95.37;96.03;18700000;96.03
1977-09-09;97.10;97.10;95.97;96.37;18100000;96.37
1977-09-08;98.01;98.43;97.01;97.28;18290000;97.28
1977-09-07;97.71;98.38;97.33;98.01;18070000;98.01
1977-09-06;97.45;98.13;96.93;97.71;16130000;97.71
1977-09-02;96.83;97.76;96.51;97.45;15620000;97.45
1977-09-01;96.77;97.54;96.35;96.83;18820000;96.83
1977-08-31;96.38;97.00;95.59;96.77;19080000;96.77
1977-08-30;96.92;97.55;96.04;96.38;18220000;96.38
1977-08-29;96.06;97.25;95.93;96.92;15280000;96.92
1977-08-26;96.15;96.42;95.04;96.06;18480000;96.06
1977-08-25;97.18;97.18;95.81;96.15;19400000;96.15
1977-08-24;97.62;97.99;96.77;97.23;18170000;97.23
1977-08-23;97.79;98.52;97.18;97.62;20290000;97.62
1977-08-22;97.51;98.29;96.84;97.79;17870000;97.79
1977-08-19;97.68;98.29;96.78;97.51;20800000;97.51
1977-08-18;97.74;98.69;97.21;97.68;21040000;97.68
1977-08-17;97.73;98.40;97.12;97.74;20920000;97.74
1977-08-16;98.18;98.60;97.35;97.73;19340000;97.73
1977-08-15;97.88;98.56;97.14;98.18;15750000;98.18
1977-08-12;98.16;98.51;97.31;97.88;16870000;97.88
1977-08-11;98.92;99.45;97.90;98.16;21740000;98.16
1977-08-10;98.05;99.06;97.67;98.92;18280000;98.92
1977-08-09;97.99;98.63;97.48;98.05;19900000;98.05
1977-08-08;98.76;98.86;97.68;97.99;15870000;97.99
1977-08-05;98.74;99.44;98.31;98.76;19940000;98.76
1977-08-04;98.37;99.19;97.79;98.74;18870000;98.74
1977-08-03;98.50;98.86;97.53;98.37;21710000;98.37
1977-08-02;99.12;99.27;98.14;98.50;17910000;98.50
1977-08-01;98.85;99.84;98.46;99.12;17920000;99.12
1977-07-29;98.79;99.21;97.71;98.85;20350000;98.85
1977-07-28;98.64;99.36;97.78;98.79;26340000;98.79
1977-07-27;100.27;100.29;98.31;98.64;26440000;98.64
1977-07-26;100.85;100.92;99.72;100.27;21390000;100.27
1977-07-25;101.67;101.85;100.46;100.85;20430000;100.85
1977-07-22;101.59;102.28;101.02;101.67;23110000;101.67
1977-07-21;101.73;102.19;100.85;101.59;26880000;101.59
1977-07-20;101.79;102.57;101.14;101.73;29380000;101.73
1977-07-19;100.95;102.17;100.68;101.79;31930000;101.79
1977-07-18;100.18;101.40;99.94;100.95;29890000;100.95
1977-07-15;99.59;100.68;99.28;100.18;29120000;100.18
1977-07-13;99.45;99.99;98.83;99.59;23160000;99.59
1977-07-12;99.55;100.01;98.81;99.45;22470000;99.45
1977-07-11;99.79;100.16;98.90;99.55;19790000;99.55
1977-07-08;99.93;100.62;99.37;99.79;23820000;99.79
1977-07-07;99.58;100.30;99.12;99.93;21740000;99.93
1977-07-06;100.09;100.41;99.20;99.58;21230000;99.58
1977-07-05;100.10;100.72;99.62;100.09;16850000;100.09
1977-07-01;100.48;100.76;99.63;100.10;18160000;100.10
1977-06-30;100.11;100.88;99.68;100.48;19410000;100.48
1977-06-29;100.14;100.49;99.30;100.11;19000000;100.11
1977-06-28;100.98;101.36;99.87;100.14;22670000;100.14
1977-06-27;101.19;101.63;100.47;100.98;19870000;100.98
1977-06-24;100.62;101.65;100.41;101.19;27490000;101.19
1977-06-23;100.46;101.10;99.88;100.62;24330000;100.62
1977-06-22;100.74;101.07;99.90;100.46;25070000;100.46
1977-06-21;100.42;101.41;100.16;100.74;29730000;100.74
1977-06-20;99.97;100.76;99.56;100.42;22950000;100.42
1977-06-17;99.85;100.47;99.34;99.97;21960000;99.97
1977-06-16;99.61;100.33;98.91;99.85;24310000;99.85
1977-06-15;99.86;100.31;99.12;99.61;22640000;99.61
1977-06-14;98.76;100.12;98.76;99.86;25390000;99.86
1977-06-13;98.46;99.21;98.06;98.74;20250000;98.74
1977-06-10;98.14;98.86;97.68;98.46;20630000;98.46
1977-06-09;98.20;98.62;97.51;98.14;19940000;98.14
1977-06-08;97.73;98.75;97.49;98.20;22200000;98.20
1977-06-07;97.23;98.01;96.60;97.73;21110000;97.73
1977-06-06;97.69;98.26;96.89;97.23;18930000;97.23
1977-06-03;96.74;98.12;96.55;97.69;20330000;97.69
1977-06-02;96.93;97.53;96.23;96.74;18620000;96.74
1977-06-01;96.12;97.27;95.89;96.93;18320000;96.93
1977-05-31;96.27;96.75;95.52;96.12;17800000;96.12
1977-05-27;97.01;97.26;95.92;96.27;15730000;96.27
1977-05-26;96.77;97.47;96.20;97.01;18620000;97.01
1977-05-25;97.67;98.14;96.50;96.77;20710000;96.77
1977-05-24;98.15;98.25;97.00;97.67;20050000;97.67
1977-05-23;99.35;99.35;97.88;98.15;18290000;98.15
1977-05-20;99.88;100.12;98.91;99.45;18950000;99.45
1977-05-19;100.30;100.74;99.49;99.88;21280000;99.88
1977-05-18;99.77;100.93;99.58;100.30;27800000;100.30
1977-05-17;99.47;100.11;98.76;99.77;22290000;99.77
1977-05-16;99.03;99.98;98.79;99.47;21170000;99.47
1977-05-13;98.73;99.52;98.37;99.03;19780000;99.03
1977-05-12;98.78;99.25;97.91;98.73;21980000;98.73
1977-05-11;99.47;99.77;98.40;98.78;18980000;98.78
1977-05-10;99.18;100.09;98.82;99.47;21090000;99.47
1977-05-09;99.49;99.78;98.66;99.18;15230000;99.18
1977-05-06;100.11;100.20;98.95;99.49;19370000;99.49
1977-05-05;99.96;100.79;99.28;100.11;23450000;100.11
1977-05-04;99.43;100.56;98.90;99.96;23330000;99.96
1977-05-03;98.93;99.96;98.72;99.43;21950000;99.43
1977-05-02;98.44;99.26;97.97;98.93;17970000;98.93
1977-04-29;98.20;98.87;97.58;98.44;18330000;98.44
1977-04-28;97.96;98.77;97.47;98.20;18370000;98.20
1977-04-27;97.11;98.47;96.90;97.96;20590000;97.96
1977-04-26;97.15;97.94;96.53;97.11;20040000;97.11
1977-04-25;98.32;98.32;96.54;97.15;20440000;97.15
1977-04-22;99.67;99.67;98.08;98.44;20700000;98.44
1977-04-21;100.40;101.20;99.35;99.75;22740000;99.75
1977-04-20;100.07;100.98;99.49;100.40;25090000;100.40
1977-04-19;100.54;100.81;99.58;100.07;19510000;100.07
1977-04-18;101.04;101.36;100.09;100.54;17830000;100.54
1977-04-15;101.00;101.63;100.35;101.04;20230000;101.04
1977-04-14;100.42;102.07;100.42;101.00;30490000;101.00
1977-04-13;100.15;100.72;99.02;100.16;21800000;100.16
1977-04-12;98.97;100.58;98.97;100.15;23760000;100.15
1977-04-11;98.35;99.37;98.08;98.88;17650000;98.88
1977-04-07;97.91;98.65;97.48;98.35;17260000;98.35
1977-04-06;98.01;98.61;97.45;97.91;16600000;97.91
1977-04-05;98.23;98.60;97.43;98.01;18330000;98.01
1977-04-04;99.21;99.50;97.98;98.23;16250000;98.23
1977-04-01;98.42;99.57;98.38;99.21;17050000;99.21
1977-03-31;98.54;99.14;97.80;98.42;16510000;98.42
1977-03-30;99.69;99.99;98.18;98.54;18810000;98.54
1977-03-29;99.00;100.12;98.95;99.69;17030000;99.69
1977-03-28;99.06;99.54;98.35;99.00;16710000;99.00
1977-03-25;99.70;100.05;98.71;99.06;16550000;99.06
1977-03-24;100.20;100.60;99.26;99.70;19650000;99.70
1977-03-23;101.00;101.42;99.88;100.20;19360000;100.20
1977-03-22;101.31;101.58;100.35;101.00;18660000;101.00
1977-03-21;101.86;102.13;100.92;101.31;18040000;101.31
1977-03-18;102.08;102.61;101.39;101.86;19840000;101.86
1977-03-17;102.17;102.58;101.28;102.08;20700000;102.08
1977-03-16;101.98;102.70;101.52;102.17;22140000;102.17
1977-03-15;101.42;102.61;101.34;101.98;23940000;101.98
1977-03-14;100.65;101.75;100.24;101.42;19290000;101.42
1977-03-11;100.67;101.37;100.14;100.65;18230000;100.65
1977-03-10;100.10;100.96;99.49;100.67;18620000;100.67
1977-03-09;100.87;100.89;99.63;100.10;19680000;100.10
1977-03-08;101.25;101.85;100.48;100.87;19520000;100.87
1977-03-07;101.20;101.77;100.64;101.25;17410000;101.25
1977-03-04;100.88;101.67;100.52;101.20;18950000;101.20
1977-03-03;100.39;101.28;100.01;100.88;17560000;100.88
1977-03-02;100.66;101.24;99.97;100.39;18010000;100.39
1977-03-01;99.82;101.03;99.65;100.66;19480000;100.66
1977-02-28;99.48;100.06;98.91;99.82;16220000;99.82
1977-02-25;99.60;100.02;98.82;99.48;17610000;99.48
1977-02-24;100.19;100.42;99.18;99.60;19730000;99.60
1977-02-23;100.49;100.95;99.78;100.19;18240000;100.19
1977-02-22;100.49;101.22;99.94;100.49;17730000;100.49
1977-02-18;100.92;101.13;99.95;100.49;18040000;100.49
1977-02-17;101.50;101.76;100.43;100.92;19040000;100.92
1977-02-16;101.04;102.22;100.68;101.50;23430000;101.50
1977-02-15;100.74;101.67;100.35;101.04;21620000;101.04
1977-02-14;100.22;101.06;99.51;100.74;19230000;100.74
1977-02-11;100.82;101.18;99.74;100.22;20510000;100.22
1977-02-10;100.73;101.51;100.16;100.82;22340000;100.82
1977-02-09;101.60;101.88;100.12;100.73;23640000;100.73
1977-02-08;101.89;102.65;101.16;101.60;24040000;101.60
1977-02-07;101.88;102.43;101.25;101.89;20700000;101.89
1977-02-04;101.85;102.71;101.30;101.88;23130000;101.88
1977-02-03;102.36;102.57;101.28;101.85;23790000;101.85
1977-02-02;102.54;103.32;101.89;102.36;25700000;102.36
1977-02-01;102.03;103.06;101.57;102.54;23700000;102.54
1977-01-31;101.93;102.44;100.91;102.03;22920000;102.03
1977-01-28;101.79;102.61;101.08;101.93;22700000;101.93
1977-01-27;102.34;102.81;101.27;101.79;24360000;101.79
1977-01-26;103.13;103.48;101.84;102.34;27840000;102.34
1977-01-25;103.25;104.08;102.42;103.13;26340000;103.13
1977-01-24;103.32;104.06;102.50;103.25;22890000;103.25
1977-01-21;102.97;103.91;102.35;103.32;23930000;103.32
1977-01-20;103.85;104.45;102.50;102.97;26520000;102.97
1977-01-19;103.32;104.38;102.83;103.85;27120000;103.85
1977-01-18;103.73;104.29;102.71;103.32;24380000;103.32
1977-01-17;104.01;104.37;103.04;103.73;21060000;103.73
1977-01-14;104.20;104.71;103.37;104.01;24480000;104.01
1977-01-13;103.40;104.60;103.21;104.20;24780000;104.20
1977-01-12;104.12;104.18;102.75;103.40;22670000;103.40
1977-01-11;105.20;105.60;103.76;104.12;24100000;104.12
1977-01-10;105.01;105.75;104.46;105.20;20860000;105.20
1977-01-07;105.02;105.59;104.30;105.01;21720000;105.01
1977-01-06;104.76;105.86;104.40;105.02;23920000;105.02
1977-01-05;105.70;106.07;104.33;104.76;25010000;104.76
1977-01-04;107.00;107.31;105.40;105.70;22740000;105.70
1977-01-03;107.46;107.97;106.42;107.00;21280000;107.00
1976-12-31;106.88;107.82;106.55;107.46;19170000;107.46
1976-12-30;106.34;107.41;105.97;106.88;23700000;106.88
1976-12-29;106.77;107.17;105.83;106.34;21910000;106.34
1976-12-28;106.06;107.36;105.90;106.77;25790000;106.77
1976-12-27;104.84;106.31;104.58;106.06;20130000;106.06
1976-12-23;104.71;105.49;104.09;104.84;24560000;104.84
1976-12-22;104.22;105.59;104.03;104.71;26970000;104.71
1976-12-21;103.65;104.66;102.99;104.22;24390000;104.22
1976-12-20;104.26;104.63;103.21;103.65;20690000;103.65
1976-12-17;104.80;105.60;103.89;104.26;23870000;104.26
1976-12-16;105.14;105.53;104.07;104.80;23920000;104.80
1976-12-15;105.07;105.89;104.33;105.14;28300000;105.14
1976-12-14;104.63;105.44;103.80;105.07;25130000;105.07
1976-12-13;104.70;105.33;103.94;104.63;24830000;104.63
1976-12-10;104.51;105.36;103.90;104.70;25960000;104.70
1976-12-09;104.08;105.27;103.71;104.51;31800000;104.51
1976-12-08;103.49;104.40;102.94;104.08;24560000;104.08
1976-12-07;103.56;104.40;102.96;103.49;26140000;103.49
1976-12-06;102.76;104.15;102.53;103.56;24830000;103.56
1976-12-03;102.12;103.31;101.75;102.76;22640000;102.76
1976-12-02;102.49;103.30;101.70;102.12;23300000;102.12
1976-12-01;102.10;103.03;101.62;102.49;21960000;102.49
1976-11-30;102.44;102.72;101.46;102.10;17030000;102.10
1976-11-29;103.15;103.46;102.07;102.44;18750000;102.44
1976-11-26;102.41;103.51;102.13;103.15;15000000;103.15
1976-11-24;101.96;102.85;101.41;102.41;20420000;102.41
1976-11-23;102.59;102.90;101.50;101.96;19090000;101.96
1976-11-22;101.92;103.15;101.63;102.59;20930000;102.59
1976-11-19;101.89;102.77;101.17;101.92;24550000;101.92
1976-11-18;100.61;102.22;100.49;101.89;24000000;101.89
1976-11-17;100.04;101.32;99.64;100.61;19900000;100.61
1976-11-16;99.90;101.12;99.44;100.04;21020000;100.04
1976-11-15;99.24;100.16;98.53;99.90;16710000;99.90
1976-11-12;99.64;99.95;98.51;99.24;15550000;99.24
1976-11-11;98.81;99.89;98.35;99.64;13230000;99.64
1976-11-10;99.32;99.98;98.18;98.81;18890000;98.81
1976-11-09;99.60;100.21;98.38;99.32;19210000;99.32
1976-11-08;100.62;100.62;99.10;99.60;16520000;99.60
1976-11-05;102.41;102.70;100.48;100.82;20780000;100.82
1976-11-04;101.92;103.16;101.40;102.41;21700000;102.41
1976-11-03;102.49;102.49;100.73;101.92;19350000;101.92
1976-11-01;102.90;103.78;102.19;103.10;18390000;103.10
1976-10-29;101.61;103.10;101.15;102.90;17030000;102.90
1976-10-28;101.76;102.50;101.12;101.61;16920000;101.61
1976-10-27;101.06;102.12;100.61;101.76;15790000;101.76
1976-10-26;100.07;101.50;99.91;101.06;15490000;101.06
1976-10-25;99.96;100.60;99.21;100.07;13310000;100.07
1976-10-22;100.77;100.93;99.24;99.96;17870000;99.96
1976-10-21;101.74;102.32;100.49;100.77;17980000;100.77
1976-10-20;101.45;102.23;100.81;101.74;15860000;101.74
1976-10-19;101.47;102.04;100.42;101.45;16200000;101.45
1976-10-18;100.88;101.99;100.62;101.47;15710000;101.47
1976-10-15;100.85;101.50;100.02;100.88;16210000;100.88
1976-10-14;102.12;102.14;100.28;100.85;18610000;100.85
1976-10-13;100.81;102.44;100.54;102.12;21690000;102.12
1976-10-12;101.64;102.19;100.38;100.81;18210000;100.81
1976-10-11;102.48;102.48;100.98;101.64;14620000;101.64
1976-10-08;103.54;104.00;102.24;102.56;16740000;102.56
1976-10-07;102.97;103.90;102.16;103.54;19830000;103.54
1976-10-06;103.23;103.72;102.05;102.97;20870000;102.97
1976-10-05;104.03;104.25;102.51;103.23;19200000;103.23
1976-10-04;104.17;104.62;103.42;104.03;12630000;104.03
1976-10-01;105.24;105.75;103.60;104.17;20620000;104.17
1976-09-30;105.37;105.84;104.57;105.24;14700000;105.24
1976-09-29;105.92;106.45;104.83;105.37;18090000;105.37
1976-09-28;107.27;107.54;105.61;105.92;20440000;105.92
1976-09-27;106.80;107.70;106.35;107.27;17430000;107.27
1976-09-24;106.92;107.36;106.03;106.80;17400000;106.80
1976-09-23;107.46;107.96;106.40;106.92;24210000;106.92
1976-09-22;107.83;108.72;106.92;107.46;32970000;107.46
1976-09-21;106.32;108.13;106.09;107.83;30300000;107.83
1976-09-20;106.27;107.20;105.74;106.32;21730000;106.32
1976-09-17;105.34;106.81;105.14;106.27;28270000;106.27
1976-09-16;104.25;105.59;103.84;105.34;19620000;105.34
1976-09-15;103.94;104.70;103.28;104.25;17570000;104.25
1976-09-14;104.29;104.50;103.31;103.94;15550000;103.94
1976-09-13;104.65;105.29;103.88;104.29;16100000;104.29
1976-09-10;104.40;105.03;103.79;104.65;16930000;104.65
1976-09-09;104.94;105.12;103.91;104.40;16540000;104.40
1976-09-08;105.03;105.73;104.34;104.94;19750000;104.94
1976-09-07;104.30;105.31;103.93;105.03;16310000;105.03
1976-09-03;103.92;104.63;103.36;104.30;13280000;104.30
1976-09-02;104.06;104.84;103.47;103.92;18920000;103.92
1976-09-01;102.91;104.30;102.60;104.06;18640000;104.06
1976-08-31;102.07;103.38;101.94;102.91;15480000;102.91
1976-08-30;101.48;102.51;101.22;102.07;11140000;102.07
1976-08-27;101.32;101.90;100.55;101.48;12120000;101.48
1976-08-26;102.03;102.59;101.01;101.32;15270000;101.32
1976-08-25;101.27;102.41;100.43;102.03;17400000;102.03
1976-08-24;101.96;102.65;100.98;101.27;16740000;101.27
1976-08-23;102.37;102.49;101.04;101.96;15450000;101.96
1976-08-20;103.31;103.31;101.96;102.37;14920000;102.37
1976-08-19;104.56;104.74;103.01;103.39;17230000;103.39
1976-08-18;104.80;105.41;104.12;104.56;17150000;104.56
1976-08-17;104.43;105.25;103.98;104.80;18500000;104.80
1976-08-16;104.25;104.99;103.74;104.43;16210000;104.43
1976-08-13;104.22;104.79;103.61;104.25;13930000;104.25
1976-08-12;104.06;104.64;103.38;104.22;15560000;104.22
1976-08-11;104.41;105.24;103.73;104.06;18710000;104.06
1976-08-10;103.49;104.71;103.21;104.41;16690000;104.41
1976-08-09;103.79;104.02;103.01;103.49;11700000;103.49
1976-08-06;103.85;104.25;103.10;103.79;13930000;103.79
1976-08-05;104.43;104.76;103.48;103.85;15530000;103.85
1976-08-04;104.14;105.18;103.72;104.43;20650000;104.43
1976-08-03;103.19;104.49;102.79;104.14;18500000;104.14
1976-08-02;103.44;103.98;102.64;103.19;13870000;103.19
1976-07-30;102.93;103.88;102.47;103.44;14830000;103.44
1976-07-29;103.05;103.59;102.36;102.93;13330000;102.93
1976-07-28;103.48;103.58;102.31;103.05;16000000;103.05
1976-07-27;104.07;104.51;103.13;103.48;15580000;103.48
1976-07-26;104.06;104.69;103.46;104.07;13530000;104.07
1976-07-23;103.93;104.71;103.49;104.06;15870000;104.06
1976-07-22;103.82;104.42;103.15;103.93;15600000;103.93
1976-07-21;103.72;104.56;103.21;103.82;18350000;103.82
1976-07-20;104.29;104.57;103.05;103.72;18810000;103.72
1976-07-19;104.68;105.32;103.84;104.29;18200000;104.29
1976-07-16;105.20;105.27;103.87;104.68;20450000;104.68
1976-07-15;105.95;106.25;104.76;105.20;20400000;105.20
1976-07-14;105.67;106.61;105.05;105.95;23840000;105.95
1976-07-13;105.90;106.78;105.15;105.67;27550000;105.67
1976-07-12;104.98;106.30;104.74;105.90;23750000;105.90
1976-07-09;103.98;105.41;103.80;104.98;23500000;104.98
1976-07-08;103.83;104.75;103.44;103.98;21710000;103.98
1976-07-07;103.54;104.23;102.80;103.83;18470000;103.83
1976-07-06;104.11;104.67;103.19;103.54;16130000;103.54
1976-07-02;103.59;104.53;103.13;104.11;16730000;104.11
1976-07-01;104.28;104.98;103.14;103.59;21130000;103.59
1976-06-30;103.86;105.07;103.52;104.28;23830000;104.28
1976-06-29;103.43;104.33;102.95;103.86;19620000;103.86
1976-06-28;103.72;104.35;102.97;103.43;17490000;103.43
1976-06-25;103.79;104.54;103.17;103.72;17830000;103.72
1976-06-24;103.25;104.37;102.90;103.79;19850000;103.79
1976-06-23;103.47;103.90;102.40;103.25;17530000;103.25
1976-06-22;104.28;104.82;103.16;103.47;21150000;103.47
1976-06-21;103.76;104.73;103.18;104.28;18930000;104.28
1976-06-18;103.61;104.80;103.06;103.76;25720000;103.76
1976-06-17;102.01;104.12;101.97;103.61;27810000;103.61
1976-06-16;101.46;102.65;100.96;102.01;21620000;102.01
1976-06-15;101.95;102.39;100.84;101.46;18440000;101.46
1976-06-14;101.00;102.51;101.00;101.95;21250000;101.95
1976-06-11;99.56;101.22;99.38;100.92;19470000;100.92
1976-06-10;98.74;99.98;98.55;99.56;16100000;99.56
1976-06-09;98.80;99.49;98.23;98.74;14560000;98.74
1976-06-08;98.63;99.71;98.32;98.80;16660000;98.80
1976-06-07;99.15;99.39;97.97;98.63;14510000;98.63
1976-06-04;100.13;100.27;98.79;99.15;15960000;99.15
1976-06-03;100.22;101.10;99.68;100.13;18900000;100.13
1976-06-02;99.85;100.69;99.26;100.22;16120000;100.22
1976-06-01;100.18;100.74;99.36;99.85;13880000;99.85
1976-05-28;99.38;100.64;99.00;100.18;16860000;100.18
1976-05-27;99.34;99.77;98.26;99.38;15310000;99.38
1976-05-26;99.49;100.14;98.65;99.34;16750000;99.34
1976-05-25;99.44;100.02;98.48;99.49;18770000;99.49
1976-05-24;101.07;101.07;99.11;99.44;16560000;99.44
1976-05-21;102.00;102.34;100.81;101.26;18730000;101.26
1976-05-20;101.18;102.53;100.69;102.00;22560000;102.00
1976-05-19;101.26;102.01;100.55;101.18;18450000;101.18
1976-05-18;101.09;102.00;100.72;101.26;17410000;101.26
1976-05-17;101.34;101.71;100.41;101.09;14720000;101.09
1976-05-14;102.16;102.23;100.82;101.34;16800000;101.34
1976-05-13;102.77;103.03;101.73;102.16;16730000;102.16
1976-05-12;102.95;103.55;102.14;102.77;18510000;102.77
1976-05-11;103.10;103.99;102.39;102.95;23590000;102.95
1976-05-10;101.88;103.51;101.76;103.10;22760000;103.10
1976-05-07;101.16;102.27;100.77;101.88;17810000;101.88
1976-05-06;100.88;101.70;100.31;101.16;16200000;101.16
1976-05-05;101.46;101.92;100.45;100.88;14970000;100.88
1976-05-04;100.92;101.93;100.29;101.46;17240000;101.46
1976-05-03;101.64;101.73;100.14;100.92;15180000;100.92
1976-04-30;102.13;102.65;101.16;101.64;14530000;101.64
1976-04-29;102.13;102.97;101.45;102.13;17740000;102.13
1976-04-28;101.86;102.46;100.91;102.13;15790000;102.13
1976-04-27;102.43;103.18;101.51;101.86;17760000;101.86
1976-04-26;102.29;102.80;101.36;102.43;15520000;102.43
1976-04-23;102.98;103.21;101.70;102.29;17000000;102.29
1976-04-22;103.32;104.04;102.52;102.98;20220000;102.98
1976-04-21;102.87;104.03;102.30;103.32;26600000;103.32
1976-04-20;101.44;103.32;101.42;102.87;23500000;102.87
1976-04-19;100.67;101.83;100.32;101.44;16500000;101.44
1976-04-15;100.31;101.18;99.73;100.67;15100000;100.67
1976-04-14;101.05;101.77;99.98;100.31;18440000;100.31
1976-04-13;100.20;101.39;99.64;101.05;15990000;101.05
1976-04-12;100.35;101.30;99.57;100.20;16030000;100.20
1976-04-09;101.28;101.74;99.87;100.35;19050000;100.35
1976-04-08;102.21;102.38;100.53;101.28;20860000;101.28
1976-04-07;103.36;103.85;101.92;102.21;20190000;102.21
1976-04-06;103.51;104.63;102.93;103.36;24170000;103.36
1976-04-05;102.32;104.13;102.32;103.51;21940000;103.51
1976-04-02;102.24;102.76;101.23;102.25;17420000;102.25
1976-04-01;102.77;103.24;101.50;102.24;17910000;102.24
1976-03-31;102.01;103.08;101.60;102.77;17520000;102.77
1976-03-30;102.41;103.36;101.25;102.01;17930000;102.01
1976-03-29;102.85;103.36;101.99;102.41;16100000;102.41
1976-03-26;102.85;103.65;102.20;102.85;18510000;102.85
1976-03-25;103.42;104.00;102.19;102.85;22510000;102.85
1976-03-24;102.51;104.39;102.51;103.42;32610000;103.42
1976-03-23;100.71;102.54;100.32;102.24;22450000;102.24
1976-03-22;100.58;101.53;100.14;100.71;19410000;100.71
1976-03-19;100.45;101.23;99.70;100.58;18090000;100.58
1976-03-18;100.86;101.37;99.73;100.45;20330000;100.45
1976-03-17;100.92;102.01;100.28;100.86;26190000;100.86
1976-03-16;99.80;101.25;99.38;100.92;22780000;100.92
1976-03-15;100.86;100.90;99.24;99.80;19570000;99.80
1976-03-12;101.89;102.46;100.49;100.86;26020000;100.86
1976-03-11;100.94;102.41;100.62;101.89;27300000;101.89
1976-03-10;100.58;101.80;99.98;100.94;24900000;100.94
1976-03-09;100.19;101.90;99.95;100.58;31770000;100.58
1976-03-08;99.11;100.71;98.93;100.19;25060000;100.19
1976-03-05;98.92;99.88;98.23;99.11;23030000;99.11
1976-03-04;99.98;100.40;98.49;98.92;24410000;98.92
1976-03-03;100.58;100.97;99.23;99.98;25450000;99.98
1976-03-02;100.02;101.26;99.61;100.58;25590000;100.58
1976-03-01;99.71;100.64;98.67;100.02;22070000;100.02
1976-02-27;100.11;100.53;98.60;99.71;26940000;99.71
1976-02-26;101.69;102.36;99.74;100.11;34320000;100.11
1976-02-25;102.03;102.71;100.69;101.69;34680000;101.69
1976-02-24;101.61;102.92;101.03;102.03;34380000;102.03
1976-02-23;102.10;102.54;100.69;101.61;31460000;101.61
1976-02-20;101.41;103.07;101.18;102.10;44510000;102.10
1976-02-19;99.94;101.92;99.94;101.41;39210000;101.41
1976-02-18;99.05;100.43;98.50;99.85;29900000;99.85
1976-02-17;99.67;100.25;98.56;99.05;25460000;99.05
1976-02-13;100.25;100.66;99.01;99.67;23870000;99.67
1976-02-12;100.77;101.55;99.82;100.25;28610000;100.25
1976-02-11;100.47;101.80;100.10;100.77;32300000;100.77
1976-02-10;99.62;100.96;99.11;100.47;27660000;100.47
1976-02-09;99.46;100.66;98.77;99.62;25340000;99.62
1976-02-06;100.39;100.53;98.64;99.46;27360000;99.46
1976-02-05;101.91;102.30;100.06;100.39;33780000;100.39
1976-02-04;101.18;102.57;100.70;101.91;38270000;101.91
1976-02-03;100.87;101.97;99.58;101.18;34080000;101.18
1976-02-02;100.86;101.39;99.74;100.87;24000000;100.87
1976-01-30;100.11;101.99;99.94;100.86;38510000;100.86
1976-01-29;98.53;100.54;98.32;100.11;29800000;100.11
1976-01-28;99.07;99.64;97.66;98.53;27370000;98.53
1976-01-27;99.68;100.52;98.28;99.07;32070000;99.07
1976-01-26;99.21;100.75;98.92;99.68;34470000;99.68
1976-01-23;98.04;99.88;97.68;99.21;33640000;99.21
1976-01-22;98.24;98.79;97.07;98.04;27420000;98.04
1976-01-21;98.86;99.24;97.12;98.24;34470000;98.24
1976-01-20;98.32;99.44;97.43;98.86;36690000;98.86
1976-01-19;97.00;98.84;96.36;98.32;29450000;98.32
1976-01-16;96.61;97.73;95.84;97.00;25940000;97.00
1976-01-15;97.13;98.34;96.15;96.61;38450000;96.61
1976-01-14;95.57;97.47;94.91;97.13;30340000;97.13
1976-01-13;96.33;97.39;95.11;95.57;34530000;95.57
1976-01-12;94.95;96.76;94.38;96.33;30440000;96.33
1976-01-09;94.58;95.71;94.05;94.95;26510000;94.95
1976-01-08;93.95;95.47;93.41;94.58;29030000;94.58
1976-01-07;93.53;95.15;92.91;93.95;33170000;93.95
1976-01-06;92.58;94.18;92.37;93.53;31270000;93.53
1976-01-05;90.90;92.84;90.85;92.58;21960000;92.58
1976-01-02;90.19;91.18;89.81;90.90;10300000;90.90
1975-12-31;89.77;90.75;89.17;90.19;16970000;90.19
1975-12-30;90.13;90.55;89.20;89.77;16040000;89.77
1975-12-29;90.25;91.09;89.63;90.13;17070000;90.13
1975-12-26;89.46;90.45;89.25;90.25;10020000;90.25
1975-12-24;88.73;89.84;88.73;89.46;11150000;89.46
1975-12-23;88.14;89.23;87.64;88.73;17750000;88.73
1975-12-22;88.80;89.13;87.74;88.14;15340000;88.14
1975-12-19;89.43;89.81;88.39;88.80;17720000;88.80
1975-12-18;89.15;90.09;88.62;89.43;18040000;89.43
1975-12-17;88.93;89.80;88.46;89.15;16560000;89.15
1975-12-16;88.09;89.49;87.78;88.93;18350000;88.93
1975-12-15;87.83;88.64;87.32;88.09;13960000;88.09
1975-12-12;87.80;88.22;87.05;87.83;13100000;87.83
1975-12-11;88.08;88.79;87.41;87.80;15300000;87.80
1975-12-10;87.30;88.39;86.91;88.08;15680000;88.08
1975-12-09;87.07;87.80;86.16;87.30;16040000;87.30
1975-12-08;86.82;87.75;86.15;87.07;14150000;87.07
1975-12-05;87.84;88.38;86.54;86.82;14050000;86.82
1975-12-04;87.60;88.39;86.68;87.84;16380000;87.84
1975-12-03;88.83;88.83;87.08;87.60;21320000;87.60
1975-12-02;90.67;90.81;89.08;89.33;17930000;89.33
1975-12-01;91.24;91.90;90.33;90.67;16050000;90.67
1975-11-28;90.94;91.74;90.44;91.24;12870000;91.24
1975-11-26;90.71;91.58;90.17;90.94;18780000;90.94
1975-11-25;89.70;91.10;89.66;90.71;17490000;90.71
1975-11-24;89.53;90.17;88.65;89.70;13930000;89.70
1975-11-21;89.64;90.23;88.79;89.53;14110000;89.53
1975-11-20;89.98;90.68;89.09;89.64;16460000;89.64
1975-11-19;91.00;91.28;89.47;89.98;16820000;89.98
1975-11-18;91.46;92.30;90.60;91.00;20760000;91.00
1975-11-17;90.97;91.99;90.50;91.46;17660000;91.46
1975-11-14;91.04;91.59;90.19;90.97;16460000;90.97
1975-11-13;91.19;92.33;90.56;91.04;25070000;91.04
1975-11-12;89.87;91.63;89.80;91.19;23960000;91.19
1975-11-11;89.34;90.47;89.04;89.87;14640000;89.87
1975-11-10;89.33;89.98;88.35;89.34;14910000;89.34
1975-11-07;89.55;90.18;88.67;89.33;15930000;89.33
1975-11-06;89.15;90.15;88.16;89.55;18600000;89.55
1975-11-05;88.51;90.08;88.32;89.15;17390000;89.15
1975-11-04;88.09;89.03;87.63;88.51;11570000;88.51
1975-11-03;89.04;89.21;87.78;88.09;11400000;88.09
1975-10-31;89.31;89.80;88.35;89.04;12910000;89.04
1975-10-30;89.39;90.20;88.70;89.31;15080000;89.31
1975-10-29;90.51;90.61;88.89;89.39;16110000;89.39
1975-10-28;89.73;91.01;89.40;90.51;17060000;90.51
1975-10-27;89.83;90.40;88.85;89.73;13100000;89.73
1975-10-24;91.24;91.52;89.46;89.83;18120000;89.83
1975-10-23;90.71;91.75;90.09;91.24;17900000;91.24
1975-10-22;90.56;91.38;89.77;90.71;16060000;90.71
1975-10-21;89.82;91.43;89.79;90.56;20800000;90.56
1975-10-20;88.86;90.14;88.43;89.82;13250000;89.82
1975-10-17;89.37;89.87;88.08;88.86;15650000;88.86
1975-10-16;89.23;90.73;88.90;89.37;18910000;89.37
1975-10-15;89.28;90.07;88.50;89.23;14440000;89.23
1975-10-14;89.46;90.80;88.81;89.28;19960000;89.28
1975-10-13;88.21;89.67;87.73;89.46;12020000;89.46
1975-10-10;88.37;89.17;87.44;88.21;14880000;88.21
1975-10-09;87.94;89.42;87.60;88.37;17770000;88.37
1975-10-08;86.77;88.46;86.34;87.94;17800000;87.94
1975-10-07;86.88;87.32;85.56;86.77;13530000;86.77
1975-10-06;85.98;87.64;85.98;86.88;15470000;86.88
1975-10-03;83.88;86.21;83.88;85.95;16360000;85.95
1975-10-02;82.93;84.33;82.82;83.82;14290000;83.82
1975-10-01;83.87;85.45;82.57;82.93;14070000;82.93
1975-09-30;85.01;85.01;83.44;83.87;12520000;83.87
1975-09-29;86.19;86.38;84.74;85.03;10580000;85.03
1975-09-26;85.64;86.86;85.13;86.19;12570000;86.19
1975-09-25;85.74;86.41;84.79;85.64;12890000;85.64
1975-09-24;85.03;86.70;85.03;85.74;16060000;85.74
1975-09-23;85.07;85.51;83.80;84.94;12800000;84.94
1975-09-22;85.88;86.70;84.70;85.07;14750000;85.07
1975-09-19;84.26;86.39;84.26;85.88;20830000;85.88
1975-09-18;82.37;84.34;82.23;84.06;14560000;84.06
1975-09-17;82.09;82.93;81.57;82.37;12190000;82.37
1975-09-16;82.88;83.43;81.79;82.09;13090000;82.09
1975-09-15;83.30;83.49;82.29;82.88;8670000;82.88
1975-09-12;83.45;84.47;82.84;83.30;12230000;83.30
1975-09-11;83.79;84.30;82.88;83.45;11100000;83.45
1975-09-10;84.59;84.59;83.00;83.79;14780000;83.79
1975-09-09;85.89;86.73;84.37;84.60;15790000;84.60
1975-09-08;85.62;86.31;84.89;85.89;11500000;85.89
1975-09-05;86.20;86.49;85.19;85.62;11680000;85.62
1975-09-04;86.03;86.91;85.29;86.20;12810000;86.20
1975-09-03;85.48;86.38;84.62;86.03;12260000;86.03
1975-09-02;86.88;87.42;85.21;85.48;11460000;85.48
1975-08-29;86.40;87.73;86.10;86.88;15480000;86.88
1975-08-28;84.68;86.64;84.68;86.40;14530000;86.40
1975-08-27;83.96;84.79;83.35;84.43;11100000;84.43
1975-08-26;85.06;85.40;83.65;83.96;11350000;83.96
1975-08-25;84.28;85.58;84.06;85.06;11250000;85.06
1975-08-22;83.07;84.61;82.79;84.28;13050000;84.28
1975-08-21;83.22;84.15;82.21;83.07;16610000;83.07
1975-08-20;84.78;84.78;82.76;83.22;18630000;83.22
1975-08-19;86.20;86.47;84.66;84.95;14990000;84.95
1975-08-18;86.36;87.21;85.76;86.20;10810000;86.20
1975-08-15;85.60;86.76;85.33;86.36;10610000;86.36
1975-08-14;85.97;86.34;85.02;85.60;12460000;85.60
1975-08-13;87.12;87.41;85.61;85.97;12000000;85.97
1975-08-12;86.55;88.17;86.49;87.12;14510000;87.12
1975-08-11;86.02;86.89;85.34;86.55;12350000;86.55
1975-08-08;86.30;87.00;85.52;86.02;11660000;86.02
1975-08-07;86.25;87.24;85.69;86.30;12390000;86.30
1975-08-06;86.23;87.04;85.34;86.25;16280000;86.25
1975-08-05;87.15;87.81;85.89;86.23;15470000;86.23
1975-08-04;87.99;88.17;86.68;87.15;12620000;87.15
1975-08-01;88.75;89.04;87.46;87.99;13320000;87.99
1975-07-31;88.83;90.07;88.31;88.75;14540000;88.75
1975-07-30;88.19;89.49;87.68;88.83;16150000;88.83
1975-07-29;88.69;89.91;87.71;88.19;19000000;88.19
1975-07-28;89.29;89.68;88.02;88.69;14850000;88.69
1975-07-25;90.07;90.72;88.72;89.29;15110000;89.29
1975-07-24;90.18;90.95;88.90;90.07;20550000;90.07
1975-07-23;91.45;92.15;89.83;90.18;20150000;90.18
1975-07-22;92.44;92.49;90.63;91.45;20660000;91.45
1975-07-21;93.20;93.93;92.03;92.44;16690000;92.44
1975-07-18;93.63;93.96;92.39;93.20;16870000;93.20
1975-07-17;94.61;95.03;92.99;93.63;21420000;93.63
1975-07-16;95.61;96.37;94.20;94.61;25250000;94.61
1975-07-15;95.19;96.58;94.71;95.61;28340000;95.61
1975-07-14;94.66;95.76;94.04;95.19;21900000;95.19
1975-07-11;94.81;95.69;93.83;94.66;22210000;94.66
1975-07-10;94.80;96.19;94.25;94.81;28880000;94.81
1975-07-09;93.39;95.22;93.38;94.80;26350000;94.80
1975-07-08;93.54;94.03;92.51;93.39;18990000;93.39
1975-07-07;94.36;94.82;93.16;93.54;15850000;93.54
1975-07-03;94.18;95.04;93.49;94.36;19000000;94.36
1975-07-02;94.85;94.91;93.37;94.18;18530000;94.18
1975-07-01;95.19;95.73;94.13;94.85;20390000;94.85
1975-06-30;94.81;95.85;94.30;95.19;19430000;95.19
1975-06-27;94.81;95.66;94.10;94.81;18820000;94.81
1975-06-26;94.62;95.72;93.88;94.81;24560000;94.81
1975-06-25;94.19;95.29;93.53;94.62;21610000;94.62
1975-06-24;93.62;95.23;93.31;94.19;26620000;94.19
1975-06-23;92.61;93.98;91.81;93.62;20720000;93.62
1975-06-20;92.02;93.75;91.83;92.61;26260000;92.61
1975-06-19;90.39;92.37;90.12;92.02;21450000;92.02
1975-06-18;90.58;91.07;89.60;90.39;15590000;90.39
1975-06-17;91.46;92.22;90.17;90.58;19440000;90.58
1975-06-16;90.52;91.85;90.12;91.46;16660000;91.46
1975-06-13;90.08;91.06;89.30;90.52;16300000;90.52
1975-06-12;90.55;91.36;89.64;90.08;15970000;90.08
1975-06-11;90.44;91.67;90.00;90.55;18230000;90.55
1975-06-10;91.21;91.21;89.46;90.44;21130000;90.44
1975-06-09;92.48;92.87;90.91;91.21;20670000;91.21
1975-06-06;92.69;93.60;91.75;92.48;22230000;92.48
1975-06-05;92.60;93.16;91.41;92.69;21610000;92.69
1975-06-04;92.89;93.61;91.82;92.60;24900000;92.60
1975-06-03;92.58;93.76;91.88;92.89;26560000;92.89
1975-06-02;91.32;93.41;91.32;92.58;28240000;92.58
1975-05-30;89.87;91.62;89.87;91.15;22670000;91.15
1975-05-29;89.71;90.59;88.83;89.68;18570000;89.68
1975-05-28;90.34;91.14;89.07;89.71;21850000;89.71
1975-05-27;90.58;91.29;89.60;90.34;17050000;90.34
1975-05-23;89.39;91.02;89.30;90.58;17870000;90.58
1975-05-22;89.06;90.30;88.35;89.39;17610000;89.39
1975-05-21;90.07;90.25;88.47;89.06;17640000;89.06
1975-05-20;90.53;91.45;89.58;90.07;18310000;90.07
1975-05-19;90.43;91.07;88.98;90.53;17870000;90.53
1975-05-16;91.41;91.59;89.74;90.43;16630000;90.43
1975-05-15;92.27;93.51;90.94;91.41;27690000;91.41
1975-05-14;91.58;93.23;91.17;92.27;29050000;92.27
1975-05-13;90.61;92.26;89.99;91.58;24950000;91.58
1975-05-12;90.53;91.67;89.91;90.61;22410000;90.61
1975-05-09;89.56;91.24;89.33;90.53;28440000;90.53
1975-05-08;89.08;90.13;88.23;89.56;22980000;89.56
1975-05-07;88.64;89.75;87.60;89.08;22250000;89.08
1975-05-06;90.08;90.86;88.15;88.64;25410000;88.64
1975-05-05;89.22;90.82;88.26;90.08;22370000;90.08
1975-05-02;88.10;89.98;87.91;89.22;25210000;89.22
1975-05-01;87.30;89.10;86.94;88.10;20660000;88.10
1975-04-30;85.64;87.61;85.00;87.30;18060000;87.30
1975-04-29;86.23;86.79;85.04;85.64;17740000;85.64
1975-04-28;86.62;87.33;85.54;86.23;17850000;86.23
1975-04-25;86.04;87.50;85.62;86.62;20260000;86.62
1975-04-24;86.12;86.92;85.00;86.04;19050000;86.04
1975-04-23;87.09;87.42;85.65;86.12;20040000;86.12
1975-04-22;87.23;88.64;86.58;87.09;26120000;87.09
1975-04-21;86.30;87.99;85.92;87.23;23960000;87.23
1975-04-18;87.25;87.59;85.53;86.30;26610000;86.30
1975-04-17;86.60;88.79;86.43;87.25;32650000;87.25
1975-04-16;86.30;87.10;84.93;86.60;22970000;86.60
1975-04-15;85.60;87.24;85.03;86.30;29620000;86.30
1975-04-14;84.18;86.12;83.98;85.60;26800000;85.60
1975-04-11;83.77;84.68;82.93;84.18;20160000;84.18
1975-04-10;82.84;84.70;82.68;83.77;24990000;83.77
1975-04-09;80.99;83.22;80.91;82.84;18120000;82.84
1975-04-08;80.35;81.65;80.13;80.99;14320000;80.99
1975-04-07;80.88;81.11;79.66;80.35;13860000;80.35
1975-04-04;81.51;81.90;80.29;80.88;14170000;80.88
1975-04-03;82.43;82.84;80.88;81.51;13920000;81.51
1975-04-02;82.64;83.57;81.80;82.43;15600000;82.43
1975-04-01;83.36;83.59;81.98;82.64;14480000;82.64
1975-03-31;83.85;84.62;82.84;83.36;16270000;83.36
1975-03-27;83.59;84.88;83.04;83.85;18300000;83.85
1975-03-26;82.16;84.24;82.16;83.59;18580000;83.59
1975-03-25;81.42;82.67;80.08;82.06;18500000;82.06
1975-03-24;82.39;82.39;80.60;81.42;17810000;81.42
1975-03-21;83.61;84.11;82.52;83.39;15940000;83.39
1975-03-20;84.34;85.30;83.02;83.61;20960000;83.61
1975-03-19;85.13;85.17;83.43;84.34;19030000;84.34
1975-03-18;86.01;87.08;84.75;85.13;29180000;85.13
1975-03-17;84.76;86.52;84.39;86.01;26780000;86.01
1975-03-14;83.74;85.43;83.50;84.76;24840000;84.76
1975-03-13;83.59;84.26;82.52;83.74;18620000;83.74
1975-03-12;84.36;84.73;82.87;83.59;21560000;83.59
1975-03-11;84.95;85.89;83.80;84.36;31280000;84.36
1975-03-10;84.30;85.47;83.43;84.95;25890000;84.95
1975-03-07;83.69;85.14;83.25;84.30;25930000;84.30
1975-03-06;83.90;84.17;81.94;83.69;21780000;83.69
1975-03-05;83.56;84.71;82.16;83.90;24120000;83.90
1975-03-04;83.03;85.43;82.85;83.56;34140000;83.56
1975-03-03;81.59;83.46;81.32;83.03;24100000;83.03
1975-02-28;80.77;82.02;80.07;81.59;17560000;81.59
1975-02-27;80.37;81.64;80.06;80.77;16430000;80.77
1975-02-26;79.53;80.89;78.91;80.37;18790000;80.37
1975-02-25;81.09;81.09;79.05;79.53;20910000;79.53
1975-02-24;82.62;82.71;80.87;81.44;19150000;81.44
1975-02-21;82.21;83.56;81.72;82.62;24440000;82.62
1975-02-20;81.44;82.78;80.82;82.21;22260000;82.21
1975-02-19;80.93;81.94;79.83;81.44;21930000;81.44
1975-02-18;81.50;82.45;80.16;80.93;23990000;80.93
1975-02-14;81.01;82.33;80.13;81.50;23290000;81.50
1975-02-13;79.98;82.53;79.98;81.01;35160000;81.01
1975-02-12;78.58;80.21;77.94;79.92;19790000;79.92
1975-02-11;78.36;79.07;77.38;78.58;16470000;78.58
1975-02-10;78.63;79.40;77.77;78.36;16120000;78.36
1975-02-07;78.56;79.12;77.00;78.63;19060000;78.63
1975-02-06;78.95;80.72;78.09;78.56;32020000;78.56
1975-02-05;77.61;79.40;76.81;78.95;25830000;78.95
1975-02-04;77.82;78.37;76.00;77.61;25040000;77.61
1975-02-03;76.98;78.55;76.36;77.82;25400000;77.82
1975-01-31;76.21;77.72;75.41;76.98;24640000;76.98
1975-01-30;77.26;78.69;75.82;76.21;29740000;76.21
1975-01-29;76.03;78.03;75.23;77.26;27410000;77.26
1975-01-28;75.37;77.59;75.36;76.03;31760000;76.03
1975-01-27;73.76;76.03;73.76;75.37;32130000;75.37
1975-01-24;72.07;73.57;71.55;72.98;20670000;72.98
1975-01-23;71.74;73.11;71.09;72.07;17960000;72.07
1975-01-22;70.70;71.97;69.86;71.74;15330000;71.74
1975-01-21;71.08;72.04;70.25;70.70;14780000;70.70
1975-01-20;70.96;71.46;69.80;71.08;13450000;71.08
1975-01-17;72.05;72.36;70.56;70.96;14260000;70.96
1975-01-16;72.14;72.93;71.26;72.05;17110000;72.05
1975-01-15;71.68;72.77;70.45;72.14;16580000;72.14
1975-01-14;72.31;72.70;71.02;71.68;16610000;71.68
1975-01-13;72.61;73.81;71.83;72.31;19780000;72.31
1975-01-10;71.60;73.75;71.60;72.61;25890000;72.61
1975-01-09;70.04;71.42;69.04;71.17;16340000;71.17
1975-01-08;71.02;71.53;69.65;70.04;15600000;70.04
1975-01-07;71.07;71.75;69.92;71.02;14890000;71.02
1975-01-06;70.71;72.24;70.33;71.07;17550000;71.07
1975-01-03;70.23;71.64;69.29;70.71;15270000;70.71
1975-01-02;68.65;70.92;68.65;70.23;14800000;70.23
1974-12-31;67.16;69.04;67.15;68.56;20970000;68.56
1974-12-30;67.14;67.65;66.23;67.16;18520000;67.16
1974-12-27;67.44;67.99;66.49;67.14;13060000;67.14
1974-12-26;66.88;68.19;66.62;67.44;11810000;67.44
1974-12-24;65.96;67.25;65.86;66.88;9540000;66.88
1974-12-23;66.91;67.18;65.34;65.96;18040000;65.96
1974-12-20;67.65;67.93;66.36;66.91;15840000;66.91
1974-12-19;67.90;68.62;66.93;67.65;15900000;67.65
1974-12-18;67.58;69.01;67.30;67.90;18050000;67.90
1974-12-17;66.46;67.92;65.86;67.58;16880000;67.58
1974-12-16;67.07;67.74;66.02;66.46;15370000;66.46
1974-12-13;67.45;68.15;66.32;67.07;14000000;67.07
1974-12-12;67.67;68.61;66.56;67.45;15390000;67.45
1974-12-11;67.28;69.03;66.83;67.67;15700000;67.67
1974-12-10;65.88;68.17;65.88;67.28;15690000;67.28
1974-12-09;65.01;66.29;64.13;65.60;14660000;65.60
1974-12-06;66.13;66.20;64.40;65.01;15500000;65.01
1974-12-05;67.41;68.00;65.90;66.13;12890000;66.13
1974-12-04;67.17;68.32;66.61;67.41;12580000;67.41
1974-12-03;68.11;68.13;66.62;67.17;13620000;67.17
1974-12-02;69.80;69.80;67.81;68.11;11140000;68.11
1974-11-29;69.94;70.49;69.18;69.97;7400000;69.97
1974-11-27;69.47;71.31;69.17;69.94;14810000;69.94
1974-11-26;68.83;70.36;68.19;69.47;13600000;69.47
1974-11-25;68.90;69.68;67.79;68.83;11300000;68.83
1974-11-22;68.24;70.00;68.24;68.90;13020000;68.90
1974-11-21;67.90;68.94;66.85;68.18;13820000;68.18
1974-11-20;68.20;69.25;67.36;67.90;12430000;67.90
1974-11-19;69.27;69.71;67.66;68.20;15720000;68.20
1974-11-18;71.10;71.10;68.95;69.27;15230000;69.27
1974-11-15;73.06;73.27;71.41;71.91;12480000;71.91
1974-11-14;73.35;74.54;72.53;73.06;13540000;73.06
1974-11-13;73.67;74.25;72.32;73.35;16040000;73.35
1974-11-12;75.15;75.59;73.34;73.67;15040000;73.67
1974-11-11;74.91;75.70;74.04;75.15;13220000;75.15
1974-11-08;75.21;76.00;74.01;74.91;15890000;74.91
1974-11-07;74.75;76.30;73.85;75.21;17150000;75.21
1974-11-06;75.11;77.41;74.23;74.75;23930000;74.75
1974-11-05;73.08;75.36;72.49;75.11;15960000;75.11
1974-11-04;73.80;73.80;71.93;73.08;12740000;73.08
1974-11-01;73.90;74.85;72.68;73.88;13470000;73.88
1974-10-31;74.31;75.90;73.15;73.90;18840000;73.90
1974-10-30;72.83;75.45;72.40;74.31;20130000;74.31
1974-10-29;70.49;73.19;70.49;72.83;15610000;72.83
1974-10-28;70.12;70.67;68.89;70.09;10540000;70.09
1974-10-25;70.22;71.59;69.46;70.12;12650000;70.12
1974-10-24;70.98;70.98;68.80;70.22;14910000;70.22
1974-10-23;72.81;72.81;70.40;71.03;14200000;71.03
1974-10-22;73.50;75.09;72.55;73.13;18930000;73.13
1974-10-21;72.28;73.92;71.24;73.50;14500000;73.50
1974-10-18;71.20;73.34;71.20;72.28;16460000;72.28
1974-10-17;70.33;72.00;69.41;71.17;14470000;71.17
1974-10-16;71.44;71.98;69.54;70.33;14790000;70.33
1974-10-15;72.74;73.35;70.61;71.44;17390000;71.44
1974-10-14;71.17;74.43;71.17;72.74;19770000;72.74
1974-10-11;69.79;71.99;68.80;71.14;20090000;71.14
1974-10-10;68.30;71.48;68.30;69.79;26360000;69.79
1974-10-09;64.84;68.15;63.74;67.82;18820000;67.82
1974-10-08;64.95;66.07;63.95;64.84;15460000;64.84
1974-10-07;62.78;65.40;62.78;64.95;15000000;64.95
1974-10-04;62.28;63.23;60.96;62.34;15910000;62.34
1974-10-03;63.38;63.48;61.66;62.28;13150000;62.28
1974-10-02;63.39;64.62;62.74;63.38;12230000;63.38
1974-10-01;63.54;64.37;61.75;63.39;16890000;63.39
1974-09-30;64.85;64.85;62.52;63.54;15000000;63.54
1974-09-27;66.46;67.09;64.58;64.94;12320000;64.94
1974-09-26;67.40;67.40;65.79;66.46;9060000;66.46
1974-09-25;68.02;69.77;66.86;67.57;17620000;67.57
1974-09-24;69.03;69.03;67.42;68.02;9840000;68.02
1974-09-23;70.14;71.02;68.79;69.42;12130000;69.42
1974-09-20;70.09;71.12;68.62;70.14;16250000;70.14
1974-09-19;68.36;70.76;68.36;70.09;17000000;70.09
1974-09-18;67.38;68.14;65.92;67.72;11760000;67.72
1974-09-17;66.45;68.84;66.45;67.38;13730000;67.38
1974-09-16;65.20;66.92;64.15;66.26;18370000;66.26
1974-09-13;66.71;66.91;64.74;65.20;16070000;65.20
1974-09-12;68.54;68.54;66.22;66.71;16920000;66.71
1974-09-11;69.24;70.00;68.22;68.55;11820000;68.55
1974-09-10;69.72;70.47;68.55;69.24;11980000;69.24
1974-09-09;71.35;71.35;69.38;69.72;11160000;69.72
1974-09-06;70.87;72.42;70.08;71.42;15130000;71.42
1974-09-05;68.69;71.30;68.65;70.87;14210000;70.87
1974-09-04;69.85;69.85;67.64;68.69;16930000;68.69
1974-09-03;72.15;73.01;70.28;70.52;12750000;70.52
1974-08-30;70.22;72.68;70.22;72.15;16230000;72.15
1974-08-29;70.76;71.22;69.37;69.99;13690000;69.99
1974-08-28;70.94;72.17;70.13;70.76;16670000;70.76
1974-08-27;72.16;72.50;70.50;70.94;12970000;70.94
1974-08-26;71.55;73.17;70.42;72.16;14630000;72.16
1974-08-23;72.80;73.71;70.75;71.55;13590000;71.55
1974-08-22;73.51;74.05;71.61;72.80;15690000;72.80
1974-08-21;74.95;75.50;73.16;73.51;11650000;73.51
1974-08-20;74.57;76.11;73.82;74.95;13820000;74.95
1974-08-19;75.65;75.65;73.78;74.57;11670000;74.57
1974-08-16;76.30;77.02;75.29;75.67;10510000;75.67
1974-08-15;76.73;77.52;75.19;76.30;11130000;76.30
1974-08-14;76.73;76.73;76.73;76.73;11750000;76.73
1974-08-13;79.75;79.95;77.83;78.49;10140000;78.49
1974-08-12;80.86;81.26;79.30;79.75;7780000;79.75
1974-08-09;81.57;81.88;80.11;80.86;10160000;80.86
1974-08-08;82.65;83.53;80.86;81.57;16060000;81.57
1974-08-07;80.52;82.93;80.13;82.65;13380000;82.65
1974-08-06;79.78;82.65;79.78;80.52;15770000;80.52
1974-08-05;78.59;80.31;78.03;79.29;11230000;79.29
1974-08-02;78.75;79.39;77.84;78.59;10110000;78.59
1974-08-01;79.31;80.02;77.97;78.75;11470000;78.75
1974-07-31;80.50;80.82;78.96;79.31;10960000;79.31
1974-07-30;80.94;81.52;79.58;80.50;11360000;80.50
1974-07-29;82.02;82.02;80.22;80.94;11560000;80.94
1974-07-26;83.98;84.17;82.00;82.40;10420000;82.40
1974-07-25;84.99;85.67;83.13;83.98;13310000;83.98
1974-07-24;84.65;85.64;83.61;84.99;12870000;84.99
1974-07-23;83.81;85.63;83.67;84.65;12910000;84.65
1974-07-22;83.54;84.44;82.59;83.81;9290000;83.81
1974-07-19;83.78;84.67;82.87;83.54;11080000;83.54
1974-07-18;83.70;85.39;83.13;83.78;13980000;83.78
1974-07-17;82.81;84.13;81.70;83.70;11320000;83.70
1974-07-16;83.78;83.85;82.14;82.81;9920000;82.81
1974-07-15;83.15;84.89;82.65;83.78;13560000;83.78
1974-07-12;80.97;83.65;80.97;83.15;17770000;83.15
1974-07-11;79.99;81.08;79.08;79.89;14640000;79.89
1974-07-10;81.48;82.22;79.74;79.99;13490000;79.99
1974-07-09;81.09;82.50;80.35;81.48;15580000;81.48
1974-07-08;83.13;83.13;80.48;81.09;15510000;81.09
1974-07-05;84.25;84.45;83.17;83.66;7400000;83.66
1974-07-03;84.30;85.15;83.46;84.25;13430000;84.25
1974-07-02;86.02;86.26;83.98;84.30;13460000;84.30
1974-07-01;86.00;86.89;85.32;86.02;10270000;86.02
1974-06-28;86.31;86.78;85.13;86.00;12010000;86.00
1974-06-27;87.61;87.61;85.88;86.31;12650000;86.31
1974-06-26;88.98;89.12;87.30;87.61;11410000;87.61
1974-06-25;87.69;89.48;87.67;88.98;11920000;88.98
1974-06-24;87.46;88.38;86.70;87.69;9960000;87.69
1974-06-21;88.21;88.31;86.77;87.46;11830000;87.46
1974-06-20;88.84;89.35;87.80;88.21;11990000;88.21
1974-06-19;89.45;89.80;88.39;88.84;10550000;88.84
1974-06-18;90.04;90.53;88.92;89.45;10110000;89.45
1974-06-17;91.30;91.34;89.63;90.04;9680000;90.04
1974-06-14;92.23;92.23;90.73;91.30;10030000;91.30
1974-06-13;92.06;93.33;91.48;92.34;11540000;92.34
1974-06-12;92.28;92.61;90.89;92.06;11150000;92.06
1974-06-11;93.10;93.57;91.76;92.28;12380000;92.28
1974-06-10;92.55;93.64;91.53;93.10;13540000;93.10
1974-06-07;91.96;93.76;91.74;92.55;19020000;92.55
1974-06-06;90.31;92.31;89.71;91.96;13360000;91.96
1974-06-05;90.14;91.42;89.04;90.31;13680000;90.31
1974-06-04;89.10;91.13;89.09;90.14;16040000;90.14
1974-06-03;87.28;89.40;86.78;89.10;12490000;89.10
1974-05-31;87.43;88.02;86.19;87.28;10810000;87.28
1974-05-30;86.89;88.09;85.87;87.43;13580000;87.43
1974-05-29;88.37;88.84;86.52;86.89;12300000;86.89
1974-05-28;88.58;89.37;87.69;88.37;10580000;88.37
1974-05-24;87.29;89.27;87.20;88.58;13740000;88.58
1974-05-23;87.09;87.98;86.12;87.29;14770000;87.29
1974-05-22;87.91;88.79;86.72;87.09;15450000;87.09
1974-05-21;87.86;88.98;87.19;87.91;12190000;87.91
1974-05-20;88.21;89.09;87.19;87.86;10550000;87.86
1974-05-17;89.53;89.53;87.67;88.21;13870000;88.21
1974-05-16;90.45;91.31;89.36;89.72;12090000;89.72
1974-05-15;90.69;91.22;89.65;90.45;11240000;90.45
1974-05-14;90.66;91.68;90.05;90.69;10880000;90.69
1974-05-13;91.47;91.72;89.91;90.66;11290000;90.66
1974-05-10;92.96;93.57;91.03;91.47;15270000;91.47
1974-05-09;91.64;93.49;91.27;92.96;14710000;92.96
1974-05-08;91.46;92.34;90.71;91.64;11850000;91.64
1974-05-07;91.12;92.36;90.69;91.46;10710000;91.46
1974-05-06;91.29;91.60;90.13;91.12;9450000;91.12
1974-05-03;92.09;92.27;90.59;91.29;11080000;91.29
1974-05-02;92.22;93.59;91.46;92.09;13620000;92.09
1974-05-01;90.31;93.03;89.82;92.22;15120000;92.22
1974-04-30;90.00;91.09;89.38;90.31;10980000;90.31
1974-04-29;90.18;90.78;89.02;90.00;10170000;90.00
1974-04-26;89.57;91.10;89.06;90.18;13250000;90.18
1974-04-25;90.30;90.53;88.62;89.57;15870000;89.57
1974-04-24;91.81;91.82;89.91;90.30;16010000;90.30
1974-04-23;93.38;93.51;91.53;91.81;14110000;91.81
1974-04-22;93.75;94.12;92.71;93.38;10520000;93.38
1974-04-19;94.77;94.77;93.20;93.75;10710000;93.75
1974-04-18;94.36;95.42;93.75;94.78;12470000;94.78
1974-04-17;93.66;95.04;93.12;94.36;14020000;94.36
1974-04-16;92.05;94.06;92.05;93.66;14530000;93.66
1974-04-15;92.12;92.94;91.49;92.05;10130000;92.05
1974-04-11;92.40;92.92;91.55;92.12;9970000;92.12
1974-04-10;92.61;93.52;91.89;92.40;11160000;92.40
1974-04-09;92.03;93.28;91.61;92.61;11330000;92.61
1974-04-08;93.00;93.00;91.50;92.03;10740000;92.03
1974-04-05;94.24;94.24;92.55;93.01;11670000;93.01
1974-04-04;94.33;95.14;93.55;94.33;11650000;94.33
1974-04-03;93.35;94.70;92.94;94.33;11500000;94.33
1974-04-02;93.25;94.15;92.59;93.35;12010000;93.35
1974-04-01;93.98;94.68;92.82;93.25;11470000;93.25
1974-03-29;94.82;95.12;93.44;93.98;12150000;93.98
1974-03-28;96.20;96.20;94.36;94.82;14940000;94.82
1974-03-27;97.95;98.26;96.32;96.59;11690000;96.59
1974-03-26;97.64;98.66;97.11;97.95;11840000;97.95
1974-03-25;97.27;98.02;95.69;97.64;10540000;97.64
1974-03-22;97.34;98.04;96.35;97.27;11930000;97.27
1974-03-21;97.57;98.59;96.82;97.34;12950000;97.34
1974-03-20;97.23;98.22;96.67;97.57;12960000;97.57
1974-03-19;98.05;98.20;96.63;97.23;12800000;97.23
1974-03-18;99.28;99.71;97.62;98.05;14010000;98.05
1974-03-15;99.65;99.99;98.22;99.28;14500000;99.28
1974-03-14;99.74;101.05;98.80;99.65;19770000;99.65
1974-03-13;99.15;100.73;98.72;99.74;16820000;99.74
1974-03-12;98.88;100.02;97.97;99.15;17250000;99.15
1974-03-11;97.78;99.40;96.38;98.88;18470000;98.88
1974-03-08;96.94;98.28;95.77;97.78;16210000;97.78
1974-03-07;97.98;98.20;96.37;96.94;14500000;96.94
1974-03-06;97.32;98.57;96.54;97.98;19140000;97.98
1974-03-05;95.98;98.17;95.98;97.32;21980000;97.32
1974-03-04;95.53;95.95;94.19;95.53;12270000;95.53
1974-03-01;96.22;96.40;94.81;95.53;12880000;95.53
1974-02-28;96.40;96.98;95.20;96.22;13680000;96.22
1974-02-27;96.00;97.43;95.49;96.40;18730000;96.40
1974-02-26;95.03;96.38;94.20;96.00;15860000;96.00
1974-02-25;95.39;95.96;94.24;95.03;12900000;95.03
1974-02-22;94.71;96.19;94.08;95.39;16360000;95.39
1974-02-21;93.44;95.19;93.20;94.71;13930000;94.71
1974-02-20;92.12;93.92;91.34;93.44;11670000;93.44
1974-02-19;92.27;94.44;91.68;92.12;15940000;92.12
1974-02-15;90.95;92.98;90.62;92.27;12640000;92.27
1974-02-14;90.98;91.89;90.17;90.95;12230000;90.95
1974-02-13;90.94;92.13;90.37;90.98;10990000;90.98
1974-02-12;90.66;91.60;89.53;90.94;12920000;90.94
1974-02-11;92.33;92.54;90.26;90.66;12930000;90.66
1974-02-08;93.30;93.79;91.87;92.33;12990000;92.33
1974-02-07;93.26;94.09;92.43;93.30;11750000;93.30
1974-02-06;93.00;94.09;92.37;93.26;11610000;93.26
1974-02-05;93.29;94.17;92.26;93.00;12820000;93.00
1974-02-04;94.89;94.89;92.74;93.29;14380000;93.29
1974-02-01;96.57;96.63;94.66;95.32;12480000;95.32
1974-01-31;97.06;98.06;96.11;96.57;14020000;96.57
1974-01-30;96.02;97.90;96.02;97.06;16790000;97.06
1974-01-29;96.09;96.81;94.97;96.01;12850000;96.01
1974-01-28;96.63;97.32;95.37;96.09;13410000;96.09
1974-01-25;96.82;97.64;95.68;96.63;14860000;96.63
1974-01-24;97.07;97.75;95.49;96.82;15980000;96.82
1974-01-23;96.55;98.11;95.88;97.07;16890000;97.07
1974-01-22;95.40;97.41;94.92;96.55;17330000;96.55
1974-01-21;95.56;95.96;93.23;95.40;15630000;95.40
1974-01-18;97.30;97.63;95.00;95.56;16470000;95.56
1974-01-17;95.67;98.35;95.67;97.30;21040000;97.30
1974-01-16;94.23;96.20;93.78;95.67;14930000;95.67
1974-01-15;93.42;95.26;92.84;94.23;13250000;94.23
1974-01-14;93.66;95.24;92.35;93.42;14610000;93.42
1974-01-11;92.39;94.57;91.75;93.66;15140000;93.66
1974-01-10;93.42;94.63;91.62;92.39;16120000;92.39
1974-01-09;95.40;95.40;92.63;93.42;18070000;93.42
1974-01-08;98.07;98.26;95.58;96.12;18080000;96.12
1974-01-07;98.90;99.31;96.86;98.07;19070000;98.07
1974-01-04;99.80;100.70;97.70;98.90;21700000;98.90
1974-01-03;98.02;100.94;98.02;99.80;24850000;99.80
1974-01-02;97.55;98.38;96.25;97.68;12060000;97.68
1973-12-31;97.54;98.30;95.95;97.55;23470000;97.55
1973-12-28;97.74;98.76;96.41;97.54;21310000;97.54
1973-12-27;96.00;98.53;96.00;97.74;22720000;97.74
1973-12-26;93.87;96.52;93.87;95.74;18620000;95.74
1973-12-24;93.54;93.77;91.68;92.90;11540000;92.90
1973-12-21;94.55;95.11;92.70;93.54;18680000;93.54
1973-12-20;94.82;96.26;93.51;94.55;17340000;94.55
1973-12-19;94.74;96.83;93.81;94.82;20670000;94.82
1973-12-18;92.75;95.41;92.18;94.74;19490000;94.74
1973-12-17;93.29;94.00;91.87;92.75;12930000;92.75
1973-12-14;92.38;94.53;91.05;93.29;20000000;93.29
1973-12-13;93.57;94.68;91.64;92.38;18130000;92.38
1973-12-12;95.52;95.52;92.90;93.57;18190000;93.57
1973-12-11;97.95;99.09;95.62;96.04;20100000;96.04
1973-12-10;96.51;98.58;95.44;97.95;18590000;97.95
1973-12-07;94.49;97.58;94.49;96.51;23230000;96.51
1973-12-06;92.16;94.89;91.68;94.42;23260000;94.42
1973-12-05;93.59;93.93;91.55;92.16;19180000;92.16
1973-12-04;93.90;95.23;92.60;93.59;19030000;93.59
1973-12-03;95.83;95.83;92.92;93.90;17900000;93.90
1973-11-30;97.31;97.55;95.40;95.96;15380000;95.96
1973-11-29;97.65;98.72;96.01;97.31;18870000;97.31
1973-11-28;95.70;98.40;95.22;97.65;19990000;97.65
1973-11-27;96.58;97.70;94.88;95.70;19750000;95.70
1973-11-26;98.64;98.64;95.79;96.58;19830000;96.58
1973-11-23;99.76;100.49;98.59;99.44;11470000;99.44
1973-11-21;98.66;101.33;97.87;99.76;24260000;99.76
1973-11-20;100.65;100.65;97.64;98.66;23960000;98.66
1973-11-19;103.65;103.65;100.37;100.71;16700000;100.71
1973-11-16;102.43;105.41;101.77;103.88;22510000;103.88
1973-11-15;102.45;103.85;100.69;102.43;24530000;102.43
1973-11-14;104.36;105.25;101.87;102.45;22710000;102.45
1973-11-13;104.44;105.42;102.91;104.36;20310000;104.36
1973-11-12;105.30;105.75;103.12;104.44;19250000;104.44
1973-11-09;107.02;107.27;104.77;105.30;17320000;105.30
1973-11-08;106.10;108.45;106.10;107.02;19650000;107.02
1973-11-07;104.96;106.72;104.53;105.80;16570000;105.80
1973-11-06;105.52;107.00;104.52;104.96;16430000;104.96
1973-11-05;106.97;106.97;104.87;105.52;17150000;105.52
1973-11-02;107.69;108.35;106.33;107.07;16340000;107.07
1973-11-01;108.29;109.20;106.88;107.69;16920000;107.69
1973-10-31;109.33;109.82;107.64;108.29;17890000;108.29
1973-10-30;111.15;111.30;108.95;109.33;17580000;109.33
1973-10-29;111.38;112.56;110.52;111.15;17960000;111.15
1973-10-26;110.50;112.31;110.08;111.38;17800000;111.38
1973-10-25;110.27;111.33;108.85;110.50;15580000;110.50
1973-10-24;109.75;110.98;109.03;110.27;15840000;110.27
1973-10-23;109.16;110.91;107.40;109.75;17230000;109.75
1973-10-22;110.22;110.56;108.18;109.16;14290000;109.16
1973-10-19;110.01;111.56;109.30;110.22;17880000;110.22
1973-10-18;109.97;111.43;108.97;110.01;19210000;110.01
1973-10-17;110.19;111.41;109.19;109.97;18600000;109.97
1973-10-16;110.05;110.80;108.50;110.19;18780000;110.19
1973-10-15;111.32;111.32;109.29;110.05;16160000;110.05
1973-10-12;111.09;112.82;110.52;111.44;22730000;111.44
1973-10-11;109.22;111.77;108.96;111.09;20740000;111.09
1973-10-10;110.13;111.31;108.51;109.22;19010000;109.22
1973-10-09;110.23;111.19;109.05;110.13;19440000;110.13
1973-10-08;109.85;110.93;108.02;110.23;18990000;110.23
1973-10-05;108.41;110.46;107.76;109.85;18820000;109.85
1973-10-04;108.78;109.53;107.30;108.41;19730000;108.41
1973-10-03;108.79;109.95;107.74;108.78;22040000;108.78
1973-10-02;108.21;109.46;107.48;108.79;20770000;108.79
1973-10-01;108.43;108.98;107.08;108.21;15830000;108.21
1973-09-28;109.08;109.42;107.48;108.43;16300000;108.43
1973-09-27;108.83;110.45;108.02;109.08;23660000;109.08
1973-09-26;108.05;109.61;107.43;108.83;21130000;108.83
1973-09-25;107.36;108.79;106.50;108.05;21530000;108.05
1973-09-24;107.20;108.36;106.21;107.36;19490000;107.36
1973-09-21;106.76;108.02;105.43;107.20;23760000;107.20
1973-09-20;105.88;107.55;105.32;106.76;25960000;106.76
1973-09-19;103.80;106.43;103.80;105.88;24570000;105.88
1973-09-18;104.15;104.62;102.41;103.77;16400000;103.77
1973-09-17;104.44;105.41;103.21;104.15;15100000;104.15
1973-09-14;103.36;104.75;102.66;104.44;13760000;104.44
1973-09-13;103.06;104.09;102.37;103.36;11670000;103.36
1973-09-12;103.22;103.98;102.15;103.06;12040000;103.06
1973-09-11;103.85;104.09;102.13;103.22;12690000;103.22
1973-09-10;104.76;105.12;103.33;103.85;11620000;103.85
1973-09-07;105.15;105.87;104.04;104.76;14930000;104.76
1973-09-06;104.64;105.95;104.05;105.15;15670000;105.15
1973-09-05;104.51;105.33;103.60;104.64;14580000;104.64
1973-09-04;104.25;105.35;103.60;104.51;14210000;104.51
1973-08-31;103.88;104.72;103.15;104.25;10530000;104.25
1973-08-30;104.03;104.84;103.29;103.88;12100000;103.88
1973-08-29;103.02;104.92;102.69;104.03;15690000;104.03
1973-08-28;102.42;103.66;102.06;103.02;11810000;103.02
1973-08-27;101.62;102.82;101.09;102.42;9740000;102.42
1973-08-24;101.91;102.65;100.88;101.62;11200000;101.62
1973-08-23;100.62;102.50;100.62;101.91;11390000;101.91
1973-08-22;100.89;101.39;99.74;100.53;10770000;100.53
1973-08-21;101.61;102.10;100.51;100.89;11480000;100.89
1973-08-20;102.31;102.54;101.11;101.61;8970000;101.61
1973-08-17;102.29;102.98;101.38;102.31;11110000;102.31
1973-08-16;103.01;103.97;101.85;102.29;12990000;102.29
1973-08-15;102.71;103.79;101.92;103.01;12040000;103.01
1973-08-14;103.71;104.29;102.34;102.71;11740000;102.71
1973-08-13;104.77;104.83;103.13;103.71;11330000;103.71
1973-08-10;105.61;106.03;104.21;104.77;10870000;104.77
1973-08-09;105.55;106.65;104.89;105.61;12880000;105.61
1973-08-08;106.55;106.73;105.04;105.55;12440000;105.55
1973-08-07;106.73;107.57;105.87;106.55;13510000;106.55
1973-08-06;106.49;107.54;105.45;106.73;12320000;106.73
1973-08-03;106.67;107.17;105.68;106.49;9940000;106.49
1973-08-02;106.83;107.38;105.51;106.67;16080000;106.67
1973-08-01;108.17;108.17;106.29;106.83;13530000;106.83
1973-07-31;109.25;110.09;107.89;108.22;13530000;108.22
1973-07-30;109.59;110.12;108.24;109.25;11170000;109.25
1973-07-27;109.85;110.49;108.70;109.59;12910000;109.59
1973-07-26;109.64;111.04;108.51;109.85;18410000;109.85
1973-07-25;108.14;110.76;107.92;109.64;22220000;109.64
1973-07-24;107.52;108.63;106.31;108.14;16280000;108.14
1973-07-23;107.14;108.42;106.54;107.52;15580000;107.52
1973-07-20;106.55;108.02;105.95;107.14;16300000;107.14
1973-07-19;106.35;107.58;105.06;106.55;18650000;106.55
1973-07-18;105.72;107.05;104.73;106.35;17020000;106.35
1973-07-17;105.67;107.28;104.99;105.72;18750000;105.72
1973-07-16;104.09;106.01;103.42;105.67;12920000;105.67
1973-07-13;105.50;105.80;103.66;104.09;11390000;104.09
1973-07-12;105.80;106.62;104.38;105.50;16400000;105.50
1973-07-11;103.64;106.21;103.64;105.80;18730000;105.80
1973-07-10;102.26;104.20;102.26;103.52;15090000;103.52
1973-07-09;101.28;102.45;100.44;102.14;11560000;102.14
1973-07-06;101.78;102.22;100.67;101.28;9980000;101.28
1973-07-05;101.87;102.48;100.80;101.78;10500000;101.78
1973-07-03;102.90;103.02;101.14;101.87;10560000;101.87
1973-07-02;104.10;104.10;102.44;102.90;9830000;102.90
1973-06-29;104.69;105.30;103.68;104.26;10770000;104.26
1973-06-28;103.62;105.17;103.18;104.69;12760000;104.69
1973-06-27;103.30;104.23;102.29;103.62;12660000;103.62
1973-06-26;102.25;103.78;101.45;103.30;14040000;103.30
1973-06-25;103.64;103.64;101.71;102.25;11670000;102.25
1973-06-22;103.21;105.66;103.07;103.70;18470000;103.70
1973-06-21;104.44;104.77;102.84;103.21;11630000;103.21
1973-06-20;103.99;105.13;103.51;104.44;10600000;104.44
1973-06-19;103.60;104.96;102.46;103.99;12970000;103.99
1973-06-18;104.96;104.96;103.08;103.60;11460000;103.60
1973-06-15;106.21;106.21;104.37;105.10;11970000;105.10
1973-06-14;107.60;108.27;105.83;106.40;13210000;106.40
1973-06-13;108.29;109.52;107.08;107.60;15700000;107.60
1973-06-12;106.70;108.78;106.40;108.29;13840000;108.29
1973-06-11;107.03;107.79;106.11;106.70;9940000;106.70
1973-06-08;105.84;107.75;105.60;107.03;14050000;107.03
1973-06-07;104.31;106.39;104.19;105.84;14160000;105.84
1973-06-06;104.62;105.78;103.60;104.31;13080000;104.31
1973-06-05;102.97;105.27;102.61;104.62;14080000;104.62
1973-06-04;103.93;103.98;102.33;102.97;11230000;102.97
1973-06-01;104.95;105.04;103.31;103.93;10410000;103.93
1973-05-31;105.91;106.30;104.35;104.95;12190000;104.95
1973-05-30;107.51;107.64;105.48;105.91;11730000;105.91
1973-05-29;107.94;108.58;106.77;107.51;11300000;107.51
1973-05-25;107.14;108.86;106.08;107.94;19270000;107.94
1973-05-24;104.07;107.44;103.59;107.14;17310000;107.14
1973-05-23;103.58;105.10;102.82;104.07;14950000;104.07
1973-05-22;102.73;105.04;102.58;103.58;18020000;103.58
1973-05-21;103.77;103.77;101.36;102.73;20690000;102.73
1973-05-18;105.41;105.41;103.18;103.86;17080000;103.86
1973-05-17;106.43;106.82;105.15;105.56;13060000;105.56
1973-05-16;106.57;107.61;105.49;106.43;13800000;106.43
1973-05-15;105.90;107.16;104.12;106.57;18530000;106.57
1973-05-14;107.74;107.74;105.52;105.90;13520000;105.90
1973-05-11;109.49;109.49;107.70;108.17;12980000;108.17
1973-05-10;110.44;110.86;108.86;109.54;13520000;109.54
1973-05-09;111.25;112.25;109.97;110.44;16050000;110.44
1973-05-08;110.53;111.72;109.46;111.25;13730000;111.25
1973-05-07;111.00;111.38;109.68;110.53;12500000;110.53
1973-05-04;110.22;111.99;109.89;111.00;19510000;111.00
1973-05-03;108.43;110.64;106.81;110.22;17760000;110.22
1973-05-02;107.10;109.06;106.95;108.43;14380000;108.43
1973-05-01;106.97;108.00;105.34;107.10;15380000;107.10
1973-04-30;107.23;107.90;105.44;106.97;14820000;106.97
1973-04-27;108.89;109.28;106.76;107.23;13730000;107.23
1973-04-26;108.34;109.66;107.14;108.89;16210000;108.89
1973-04-25;109.82;109.82;107.79;108.34;15960000;108.34
1973-04-24;111.57;111.89;109.64;109.99;13830000;109.99
1973-04-23;112.17;112.66;110.91;111.57;12580000;111.57
1973-04-19;111.54;112.93;111.06;112.17;14560000;112.17
1973-04-18;110.94;112.03;109.99;111.54;13890000;111.54
1973-04-17;111.44;111.81;110.19;110.94;12830000;110.94
1973-04-16;112.08;112.61;110.91;111.44;11350000;111.44
1973-04-13;112.58;112.91;111.23;112.08;14390000;112.08
1973-04-12;112.68;113.65;111.83;112.58;16360000;112.58
1973-04-11;112.21;113.27;111.21;112.68;14890000;112.68
1973-04-10;110.92;112.85;110.92;112.21;16770000;112.21
1973-04-09;109.28;111.24;108.74;110.86;13740000;110.86
1973-04-06;108.52;110.04;108.22;109.28;13890000;109.28
1973-04-05;108.77;109.15;107.44;108.52;12750000;108.52
1973-04-04;109.24;109.96;108.10;108.77;11890000;108.77
1973-04-03;110.18;110.35;108.47;109.24;12910000;109.24
1973-04-02;111.52;111.70;109.68;110.18;10640000;110.18
1973-03-30;112.71;112.87;110.89;111.52;13740000;111.52
1973-03-29;111.62;113.22;111.07;112.71;16050000;112.71
1973-03-28;111.56;112.47;110.54;111.62;15850000;111.62
1973-03-27;109.95;112.07;109.95;111.56;17500000;111.56
1973-03-26;108.88;110.40;108.29;109.84;14980000;109.84
1973-03-23;108.84;109.97;107.41;108.88;18470000;108.88
1973-03-22;110.39;110.39;108.19;108.84;17130000;108.84
1973-03-21;111.95;112.81;110.17;110.49;16080000;110.49
1973-03-20;112.17;112.68;111.02;111.95;13250000;111.95
1973-03-19;113.50;113.50;111.65;112.17;12460000;112.17
1973-03-16;114.12;114.62;112.84;113.54;15130000;113.54
1973-03-15;114.98;115.47;113.77;114.12;14450000;114.12
1973-03-14;114.48;115.61;113.97;114.98;14460000;114.98
1973-03-13;113.86;115.05;113.32;114.48;14210000;114.48
1973-03-12;113.79;114.80;113.25;113.86;13810000;113.86
1973-03-09;114.23;114.55;112.93;113.79;14070000;113.79
1973-03-08;114.45;115.23;113.57;114.23;15100000;114.23
1973-03-07;114.10;115.12;112.83;114.45;19310000;114.45
1973-03-06;112.68;114.71;112.57;114.10;17710000;114.10
1973-03-05;112.28;113.43;111.33;112.68;13720000;112.68
1973-03-02;111.05;112.62;109.45;112.28;17710000;112.28
1973-03-01;111.68;112.98;110.68;111.05;18210000;111.05
1973-02-28;110.90;112.21;109.80;111.68;17950000;111.68
1973-02-27;112.19;112.90;110.50;110.90;16130000;110.90
1973-02-26;113.16;113.26;111.15;112.19;15860000;112.19
1973-02-23;114.44;114.67;112.77;113.16;15450000;113.16
1973-02-22;114.69;115.20;113.44;114.44;14570000;114.44
1973-02-21;115.40;116.01;114.13;114.69;14880000;114.69
1973-02-20;114.98;116.26;114.57;115.40;14020000;115.40
1973-02-16;114.45;115.47;113.73;114.98;13320000;114.98
1973-02-15;115.10;115.68;113.70;114.45;13940000;114.45
1973-02-14;116.78;116.92;114.52;115.10;16520000;115.10
1973-02-13;116.09;118.98;116.09;116.78;25320000;116.78
1973-02-12;114.69;116.66;114.69;116.06;16130000;116.06
1973-02-09;113.16;115.20;113.08;114.68;19260000;114.68
1973-02-08;113.66;114.05;111.85;113.16;18440000;113.16
1973-02-07;114.45;115.48;113.24;113.66;17960000;113.66
1973-02-06;114.23;115.33;113.45;114.45;15720000;114.45
1973-02-05;114.35;115.15;113.62;114.23;14580000;114.23
1973-02-02;114.76;115.40;113.45;114.35;17470000;114.35
1973-02-01;116.03;117.01;114.26;114.76;20670000;114.76
1973-01-31;115.83;116.84;115.05;116.03;14870000;116.03
1973-01-30;116.01;117.11;115.26;115.83;15270000;115.83
1973-01-29;116.45;117.18;115.13;116.01;14680000;116.01
1973-01-26;116.73;117.29;114.97;116.45;21130000;116.45
1973-01-24;118.22;119.04;116.09;116.73;20870000;116.73
1973-01-23;118.21;119.00;116.84;118.22;19060000;118.22
1973-01-22;118.78;119.63;117.72;118.21;15570000;118.21
1973-01-19;118.85;119.45;117.46;118.78;17020000;118.78
1973-01-18;118.68;119.93;118.15;118.85;17810000;118.85
1973-01-17;118.14;119.35;117.61;118.68;17680000;118.68
1973-01-16;118.44;119.17;117.04;118.14;19170000;118.14
1973-01-15;119.30;120.82;118.04;118.44;21520000;118.44
1973-01-12;120.24;121.27;118.69;119.30;22230000;119.30
1973-01-11;119.43;121.74;119.01;120.24;25050000;120.24
1973-01-10;119.73;120.44;118.78;119.43;20880000;119.43
1973-01-09;119.85;120.40;118.89;119.73;16830000;119.73
1973-01-08;119.87;120.55;119.04;119.85;16840000;119.85
1973-01-05;119.40;120.71;118.88;119.87;19330000;119.87
1973-01-04;119.57;120.17;118.12;119.40;20230000;119.40
1973-01-03;119.10;120.45;118.69;119.57;20620000;119.57
1973-01-02;118.06;119.90;118.06;119.10;17090000;119.10
1972-12-29;116.93;118.77;116.70;118.05;27550000;118.05
1972-12-27;116.30;117.55;115.89;116.93;19100000;116.93
1972-12-26;115.83;116.87;115.54;116.30;11120000;116.30
1972-12-22;115.11;116.40;114.78;115.83;12540000;115.83
1972-12-21;115.95;116.60;114.63;115.11;18290000;115.11
1972-12-20;116.34;117.13;115.38;115.95;18490000;115.95
1972-12-19;116.90;117.37;115.69;116.34;17000000;116.34
1972-12-18;117.88;117.88;115.89;116.90;17540000;116.90
1972-12-15;118.24;119.25;117.37;118.26;18300000;118.26
1972-12-14;118.56;119.19;117.63;118.24;17930000;118.24
1972-12-13;118.66;119.23;117.77;118.56;16540000;118.56
1972-12-12;119.12;119.79;118.09;118.66;17040000;118.66
1972-12-11;118.86;119.78;118.24;119.12;17230000;119.12
1972-12-08;118.60;119.54;117.92;118.86;18030000;118.86
1972-12-07;118.01;119.17;117.57;118.60;19320000;118.60
1972-12-06;117.58;118.56;116.90;118.01;18610000;118.01
1972-12-05;117.77;118.42;116.89;117.58;17800000;117.58
1972-12-04;117.38;118.54;116.99;117.77;19730000;117.77
1972-12-01;116.67;118.18;116.29;117.38;22570000;117.38
1972-11-30;116.52;117.39;115.74;116.67;19340000;116.67
1972-11-29;116.47;117.14;115.56;116.52;17380000;116.52
1972-11-28;116.72;117.48;115.78;116.47;19210000;116.47
1972-11-27;117.27;117.55;115.66;116.72;18190000;116.72
1972-11-24;116.90;117.91;116.19;117.27;15760000;117.27
1972-11-22;116.21;117.61;115.67;116.90;24510000;116.90
1972-11-21;115.53;116.84;115.04;116.21;22110000;116.21
1972-11-20;115.49;116.25;114.57;115.53;16680000;115.53
1972-11-17;115.13;116.23;114.44;115.49;20220000;115.49
1972-11-16;114.50;115.57;113.73;115.13;19580000;115.13
1972-11-15;114.95;116.07;113.87;114.50;23270000;114.50
1972-11-14;113.90;115.41;113.36;114.95;20200000;114.95
1972-11-13;113.73;114.75;112.91;113.90;17210000;113.90
1972-11-10;113.50;115.15;112.85;113.73;24360000;113.73
1972-11-09;113.35;114.11;112.08;113.50;17040000;113.50
1972-11-08;113.98;115.23;112.77;113.35;24620000;113.35
1972-11-06;114.22;115.17;112.91;113.98;21330000;113.98
1972-11-03;113.23;114.81;112.71;114.22;22510000;114.22
1972-11-02;112.67;113.81;111.96;113.23;20690000;113.23
1972-11-01;111.58;113.31;111.32;112.67;21360000;112.67
1972-10-31;110.59;112.05;110.40;111.58;15450000;111.58
1972-10-30;110.62;111.19;109.66;110.59;11820000;110.59
1972-10-27;110.99;111.62;109.99;110.62;15470000;110.62
1972-10-26;110.72;112.26;110.26;110.99;20790000;110.99
1972-10-25;110.81;111.56;109.96;110.72;17430000;110.72
1972-10-24;110.35;111.34;109.38;110.81;15240000;110.81
1972-10-23;109.51;111.10;109.51;110.35;14190000;110.35
1972-10-20;108.05;109.79;107.59;109.24;15740000;109.24
1972-10-19;108.19;108.81;107.40;108.05;13850000;108.05
1972-10-18;107.50;109.11;107.36;108.19;17290000;108.19
1972-10-17;106.77;108.04;106.27;107.50;13410000;107.50
1972-10-16;107.92;108.40;106.38;106.77;10940000;106.77
1972-10-13;108.60;108.88;107.17;107.92;12870000;107.92
1972-10-12;109.50;109.69;108.03;108.60;13130000;108.60
1972-10-11;109.99;110.51;108.77;109.50;11900000;109.50
1972-10-10;109.90;111.11;109.32;109.99;13310000;109.99
1972-10-09;109.62;110.44;109.28;109.90;7940000;109.90
1972-10-06;108.89;110.49;107.78;109.62;16630000;109.62
1972-10-05;110.09;110.52;108.49;108.89;17730000;108.89
1972-10-04;110.30;111.35;109.58;110.09;16640000;110.09
1972-10-03;110.16;110.90;109.47;110.30;13090000;110.30
1972-10-02;110.55;110.98;109.49;110.16;12440000;110.16
1972-09-29;110.35;110.55;108.05;110.55;16250000;110.55
1972-09-28;109.66;110.75;108.75;110.35;14710000;110.35
1972-09-27;108.12;109.92;107.79;109.66;14620000;109.66
1972-09-26;108.05;108.97;107.35;108.12;13150000;108.12
1972-09-25;108.52;109.09;107.67;108.05;10920000;108.05
1972-09-22;108.43;109.20;107.72;108.52;12570000;108.52
1972-09-21;108.60;109.13;107.75;108.43;11940000;108.43
1972-09-20;108.55;109.12;107.84;108.60;11980000;108.60
1972-09-19;108.61;109.57;108.08;108.55;13330000;108.55
1972-09-18;108.81;109.22;107.86;108.61;8880000;108.61
1972-09-15;108.93;109.49;108.10;108.81;11690000;108.81
1972-09-14;108.90;109.64;108.21;108.93;12500000;108.93
1972-09-13;108.47;109.36;107.84;108.90;13070000;108.90
1972-09-12;109.51;109.84;107.81;108.47;13560000;108.47
1972-09-11;110.15;110.57;109.01;109.51;10710000;109.51
1972-09-08;110.29;110.90;109.67;110.15;10980000;110.15
1972-09-07;110.55;111.06;109.71;110.29;11090000;110.29
1972-09-06;111.23;111.38;110.04;110.55;12010000;110.55
1972-09-05;111.51;112.08;110.75;111.23;10630000;111.23
1972-09-01;111.09;112.12;110.70;111.51;11600000;111.51
1972-08-31;110.57;111.52;110.08;111.09;12340000;111.09
1972-08-30;110.41;111.33;109.90;110.57;12470000;110.57
1972-08-29;110.23;111.02;109.26;110.41;12300000;110.41
1972-08-28;110.67;111.24;109.71;110.23;10720000;110.23
1972-08-25;111.02;111.53;109.78;110.67;13840000;110.67
1972-08-24;112.26;112.81;110.62;111.02;18280000;111.02
1972-08-23;112.41;113.27;111.30;112.26;18670000;112.26
1972-08-22;111.72;113.16;111.28;112.41;18560000;112.41
1972-08-21;111.76;112.74;110.75;111.72;14290000;111.72
1972-08-18;111.34;112.53;110.81;111.76;16150000;111.76
1972-08-17;111.66;112.41;110.72;111.34;14360000;111.34
1972-08-16;112.06;112.80;110.87;111.66;14950000;111.66
1972-08-15;112.55;113.04;111.27;112.06;16670000;112.06
1972-08-14;111.95;113.45;111.66;112.55;18870000;112.55
1972-08-11;111.05;112.40;110.52;111.95;16570000;111.95
1972-08-10;110.86;111.68;110.09;111.05;15260000;111.05
1972-08-09;110.69;111.57;109.98;110.86;15730000;110.86
1972-08-08;110.61;111.32;109.67;110.69;14550000;110.69
1972-08-07;110.43;111.38;109.69;110.61;13220000;110.61
1972-08-04;110.14;111.12;109.37;110.43;15700000;110.43
1972-08-03;109.29;110.88;108.90;110.14;19970000;110.14
1972-08-02;108.40;109.85;108.12;109.29;17920000;109.29
1972-08-01;107.39;108.85;107.06;108.40;15540000;108.40
1972-07-31;107.38;108.06;106.60;107.39;11120000;107.39
1972-07-28;107.28;108.03;106.52;107.38;13050000;107.38
1972-07-27;107.53;108.31;106.61;107.28;13870000;107.28
1972-07-26;107.60;108.42;106.79;107.53;14130000;107.53
1972-07-25;107.92;108.88;107.06;107.60;17180000;107.60
1972-07-24;106.66;108.67;106.63;107.92;18020000;107.92
1972-07-21;105.81;107.05;104.99;106.66;14010000;106.66
1972-07-20;106.14;106.68;105.12;105.81;15050000;105.81
1972-07-19;105.83;107.36;105.47;106.14;17880000;106.14
1972-07-18;105.88;106.40;104.43;105.83;16820000;105.83
1972-07-17;106.80;107.37;105.55;105.88;13170000;105.88
1972-07-14;106.28;107.58;105.77;106.80;13910000;106.80
1972-07-13;106.89;107.30;105.62;106.28;14740000;106.28
1972-07-12;107.32;108.15;106.42;106.89;16150000;106.89
1972-07-11;108.11;108.35;106.87;107.32;12830000;107.32
1972-07-10;108.69;109.16;107.62;108.11;11700000;108.11
1972-07-07;109.04;109.66;108.16;108.69;12900000;108.69
1972-07-06;108.28;110.27;108.28;109.04;19520000;109.04
1972-07-05;107.49;108.80;107.14;108.10;14710000;108.10
1972-07-03;107.14;107.95;106.72;107.49;8140000;107.49
1972-06-30;106.82;107.91;106.40;107.14;12860000;107.14
1972-06-29;107.02;107.47;105.94;106.82;14610000;106.82
1972-06-28;107.37;107.87;106.49;107.02;12140000;107.02
1972-06-27;107.48;108.29;106.70;107.37;13750000;107.37
1972-06-26;108.23;108.23;106.68;107.48;12720000;107.48
1972-06-23;108.68;109.33;107.69;108.27;13940000;108.27
1972-06-22;108.79;109.26;107.62;108.68;13410000;108.68
1972-06-21;108.56;109.66;107.98;108.79;15510000;108.79
1972-06-20;108.11;109.12;107.64;108.56;14970000;108.56
1972-06-19;108.36;108.78;107.37;108.11;11660000;108.11
1972-06-16;108.44;108.94;107.54;108.36;13010000;108.36
1972-06-15;108.39;109.52;107.78;108.44;16940000;108.44
1972-06-14;107.55;109.15;107.38;108.39;18320000;108.39
1972-06-13;107.01;108.03;106.38;107.55;15710000;107.55
1972-06-12;106.86;107.92;106.29;107.01;13390000;107.01
1972-06-09;107.28;107.68;106.30;106.86;12790000;106.86
1972-06-08;107.65;108.52;106.90;107.28;13820000;107.28
1972-06-07;108.21;108.52;106.91;107.65;15220000;107.65
1972-06-06;108.82;109.32;107.71;108.21;15980000;108.21
1972-06-05;109.73;109.92;108.28;108.82;13450000;108.82
1972-06-02;109.69;110.51;108.93;109.73;15400000;109.73
1972-06-01;109.53;110.35;108.97;109.69;14910000;109.69
1972-05-31;110.35;110.52;108.92;109.53;15230000;109.53
1972-05-30;110.66;111.48;109.78;110.35;15810000;110.35
1972-05-26;110.46;111.31;109.84;110.66;15730000;110.66
1972-05-25;110.31;111.20;109.67;110.46;16480000;110.46
1972-05-24;109.78;111.07;109.39;110.31;17870000;110.31
1972-05-23;109.69;110.46;108.91;109.78;16410000;109.78
1972-05-22;108.98;110.37;108.79;109.69;16030000;109.69
1972-05-19;107.94;109.59;107.74;108.98;19580000;108.98
1972-05-18;106.89;108.39;106.72;107.94;17370000;107.94
1972-05-17;106.66;107.38;106.02;106.89;13600000;106.89
1972-05-16;106.86;107.55;106.13;106.66;14070000;106.66
1972-05-15;106.38;107.45;106.06;106.86;13600000;106.86
1972-05-12;105.77;107.02;105.49;106.38;13990000;106.38
1972-05-11;105.42;106.45;104.90;105.77;12900000;105.77
1972-05-10;104.74;106.10;104.43;105.42;13870000;105.42
1972-05-09;106.06;106.06;103.83;104.74;19910000;104.74
1972-05-08;106.63;106.81;105.36;106.14;11250000;106.14
1972-05-05;106.25;107.33;105.70;106.63;13210000;106.63
1972-05-04;105.99;106.81;105.14;106.25;14790000;106.25
1972-05-03;106.08;107.24;105.44;105.99;15900000;105.99
1972-05-02;106.69;107.37;105.55;106.08;15370000;106.08
1972-05-01;107.67;108.00;106.30;106.69;12880000;106.69
1972-04-28;107.05;108.28;106.70;107.67;14160000;107.67
1972-04-27;106.89;107.89;106.42;107.05;15740000;107.05
1972-04-26;107.12;107.89;106.18;106.89;17710000;106.89
1972-04-25;108.19;108.29;106.70;107.12;17030000;107.12
1972-04-24;108.89;109.19;107.62;108.19;14650000;108.19
1972-04-21;109.04;109.92;108.30;108.89;18200000;108.89
1972-04-20;109.20;109.69;108.08;109.04;18190000;109.04
1972-04-19;109.77;110.35;108.71;109.20;19180000;109.20
1972-04-18;109.51;110.64;109.02;109.77;19410000;109.77
1972-04-17;109.84;110.22;108.77;109.51;15390000;109.51
1972-04-14;109.91;110.56;109.07;109.84;17460000;109.84
1972-04-13;110.18;110.79;109.37;109.91;17990000;109.91
1972-04-12;109.76;111.11;109.36;110.18;24690000;110.18
1972-04-11;109.45;110.38;108.76;109.76;19930000;109.76
1972-04-10;109.62;110.54;108.89;109.45;19470000;109.45
1972-04-07;109.53;110.15;108.53;109.62;19900000;109.62
1972-04-06;109.00;110.29;108.53;109.53;22830000;109.53
1972-04-05;108.12;109.64;107.96;109.00;22960000;109.00
1972-04-04;107.48;108.62;106.77;108.12;18110000;108.12
1972-04-03;107.20;108.26;106.75;107.48;14990000;107.48
1972-03-30;106.49;107.67;106.07;107.20;14360000;107.20
1972-03-29;107.17;107.41;105.98;106.49;13860000;106.49
1972-03-28;107.30;108.08;106.22;107.17;15380000;107.17
1972-03-27;107.52;108.00;106.53;107.30;12180000;107.30
1972-03-24;107.75;108.36;106.95;107.52;15390000;107.52
1972-03-23;106.84;108.33;106.67;107.75;18380000;107.75
1972-03-22;106.69;107.52;106.00;106.84;15400000;106.84
1972-03-21;107.59;107.68;105.86;106.69;18610000;106.69
1972-03-20;107.92;108.81;107.18;107.59;16420000;107.59
1972-03-17;107.50;108.61;106.89;107.92;16040000;107.92
1972-03-16;107.75;108.22;106.55;107.50;16700000;107.50
1972-03-15;107.61;108.55;107.09;107.75;19460000;107.75
1972-03-14;107.33;108.20;106.71;107.61;22370000;107.61
1972-03-13;108.38;108.52;106.71;107.33;16730000;107.33
1972-03-10;108.94;109.37;107.77;108.38;19690000;108.38
1972-03-09;108.96;109.75;108.19;108.94;21460000;108.94
1972-03-08;108.87;109.68;108.04;108.96;21290000;108.96
1972-03-07;108.77;109.72;108.02;108.87;22640000;108.87
1972-03-06;107.94;109.40;107.64;108.77;21000000;108.77
1972-03-03;107.32;108.51;106.78;107.94;20420000;107.94
1972-03-02;107.35;108.39;106.63;107.32;22200000;107.32
1972-03-01;106.57;108.13;106.21;107.35;23670000;107.35
1972-02-29;106.19;107.16;105.45;106.57;20320000;106.57
1972-02-28;106.18;107.04;105.37;106.19;18200000;106.19
1972-02-25;105.45;106.73;105.04;106.18;18180000;106.18
1972-02-24;105.38;106.24;104.76;105.45;16000000;105.45
1972-02-23;105.29;106.18;104.72;105.38;16770000;105.38
1972-02-22;105.28;106.18;104.65;105.29;16670000;105.29
1972-02-18;105.59;106.01;104.47;105.28;16590000;105.28
1972-02-17;105.62;106.65;104.96;105.59;22330000;105.59
1972-02-16;105.03;106.25;104.65;105.62;20670000;105.62
1972-02-15;104.59;105.59;104.10;105.03;17770000;105.03
1972-02-14;105.08;105.53;104.03;104.59;15840000;104.59
1972-02-11;105.59;105.91;104.45;105.08;17850000;105.08
1972-02-10;105.55;106.69;104.97;105.59;23460000;105.59
1972-02-09;104.74;106.03;104.36;105.55;19850000;105.55
1972-02-08;104.54;105.22;103.90;104.74;17390000;104.74
1972-02-07;104.86;105.46;103.97;104.54;16930000;104.54
1972-02-04;104.64;105.48;104.05;104.86;17890000;104.86
1972-02-03;104.68;105.43;103.85;104.64;19880000;104.64
1972-02-02;104.01;105.41;103.50;104.68;24070000;104.68
1972-02-01;103.94;104.57;103.10;104.01;19600000;104.01
1972-01-31;104.16;104.88;103.30;103.94;18250000;103.94
1972-01-28;103.50;104.98;103.22;104.16;25000000;104.16
1972-01-27;102.50;103.93;102.20;103.50;20360000;103.50
1972-01-26;102.70;103.31;101.81;102.50;14940000;102.50
1972-01-25;102.57;103.59;101.63;102.70;17570000;102.70
1972-01-24;103.65;104.03;102.20;102.57;15640000;102.57
1972-01-21;103.88;104.40;102.75;103.65;18810000;103.65
1972-01-20;103.88;105.00;103.32;103.88;20210000;103.88
1972-01-19;104.05;104.61;102.83;103.88;18800000;103.88
1972-01-18;103.70;104.85;103.35;104.05;21070000;104.05
1972-01-17;103.39;104.24;102.80;103.70;15860000;103.70
1972-01-14;102.99;103.89;102.41;103.39;14960000;103.39
1972-01-13;103.59;103.80;102.29;102.99;16410000;102.99
1972-01-12;103.65;104.66;103.05;103.59;20970000;103.59
1972-01-11;103.32;104.30;102.85;103.65;17970000;103.65
1972-01-10;103.47;103.97;102.44;103.32;15320000;103.32
1972-01-07;103.51;104.29;102.38;103.47;17140000;103.47
1972-01-06;103.06;104.20;102.66;103.51;21100000;103.51
1972-01-05;102.09;103.69;101.90;103.06;21350000;103.06
1972-01-04;101.67;102.59;100.87;102.09;15190000;102.09
1972-01-03;102.09;102.85;101.19;101.67;12570000;101.67
1971-12-31;102.09;102.09;102.09;102.09;14040000;102.09
1971-12-30;101.78;101.78;101.78;101.78;13810000;101.78
1971-12-29;102.21;102.21;102.21;102.21;17150000;102.21
1971-12-28;101.95;101.95;101.95;101.95;15090000;101.95
1971-12-27;100.95;100.95;100.95;100.95;11890000;100.95
1971-12-23;100.74;100.74;100.74;100.74;16000000;100.74
1971-12-22;101.18;101.18;101.18;101.18;18930000;101.18
1971-12-21;101.80;101.80;101.80;101.80;20460000;101.80
1971-12-20;101.55;101.55;101.55;101.55;23810000;101.55
1971-12-17;100.26;100.26;100.26;100.26;18270000;100.26
1971-12-16;99.74;99.74;99.74;99.74;21070000;99.74
1971-12-15;98.54;98.54;98.54;98.54;16890000;98.54
1971-12-14;97.67;97.67;97.67;97.67;16070000;97.67
1971-12-13;97.97;97.97;97.97;97.97;17020000;97.97
1971-12-10;97.69;97.69;97.69;97.69;17510000;97.69
1971-12-09;96.96;96.96;96.96;96.96;14710000;96.96
1971-12-08;96.87;97.65;96.08;96.92;16650000;96.92
1971-12-07;96.51;97.35;95.40;96.87;15250000;96.87
1971-12-06;97.06;98.17;96.07;96.51;17480000;96.51
1971-12-03;95.84;97.57;95.36;97.06;16760000;97.06
1971-12-02;95.44;96.59;94.73;95.84;17780000;95.84
1971-12-01;93.99;96.12;93.95;95.44;21040000;95.44
1971-11-30;93.41;94.43;92.51;93.99;18320000;93.99
1971-11-29;92.04;94.90;92.04;93.41;18910000;93.41
1971-11-26;90.33;92.19;90.27;91.94;10870000;91.94
1971-11-24;90.16;91.14;89.73;90.33;11870000;90.33
1971-11-23;90.79;91.10;89.34;90.16;16840000;90.16
1971-11-22;91.61;92.12;90.51;90.79;11390000;90.79
1971-11-19;92.13;92.38;90.95;91.61;12420000;91.61
1971-11-18;92.85;93.62;91.88;92.13;13010000;92.13
1971-11-17;92.71;93.35;91.80;92.85;12840000;92.85
1971-11-16;91.81;93.15;91.21;92.71;13300000;92.71
1971-11-15;92.12;92.69;91.38;91.81;9370000;91.81
1971-11-12;92.12;92.90;90.93;92.12;14540000;92.12
1971-11-11;93.41;93.54;91.64;92.12;13310000;92.12
1971-11-10;94.46;94.84;93.10;93.41;13410000;93.41
1971-11-09;94.39;95.31;93.94;94.46;12080000;94.46
1971-11-08;94.46;94.97;93.78;94.39;8520000;94.39
1971-11-05;94.79;95.01;93.64;94.46;10780000;94.46
1971-11-04;94.91;96.08;94.37;94.79;15750000;94.79
1971-11-03;93.27;95.31;93.27;94.91;14590000;94.91
1971-11-02;92.80;93.73;91.84;93.18;13330000;93.18
1971-11-01;94.23;94.43;92.48;92.80;10960000;92.80
1971-10-29;93.96;94.71;93.28;94.23;11710000;94.23
1971-10-28;93.79;94.75;92.96;93.96;15530000;93.96
1971-10-27;94.74;94.99;93.39;93.79;13480000;93.79
1971-10-26;95.02;95.02;94.38;94.74;13390000;94.74
1971-10-25;95.57;95.76;94.57;95.10;7340000;95.10
1971-10-22;95.60;96.83;94.97;95.57;14560000;95.57
1971-10-21;95.65;96.33;94.59;95.60;14990000;95.60
1971-10-20;97.00;97.45;95.23;95.65;16340000;95.65
1971-10-19;97.35;97.66;96.05;97.00;13040000;97.00
1971-10-18;97.79;98.33;96.98;97.35;10420000;97.35
1971-10-15;98.13;98.45;97.03;97.79;13120000;97.79
1971-10-14;99.03;99.25;97.74;98.13;12870000;98.13
1971-10-13;99.57;100.08;98.61;99.03;13540000;99.03
1971-10-12;99.21;100.20;98.62;99.57;14340000;99.57
1971-10-11;99.36;99.62;98.58;99.21;7800000;99.21
1971-10-08;100.02;100.30;98.87;99.36;13870000;99.36
1971-10-07;99.82;100.96;99.42;100.02;17780000;100.02
1971-10-06;99.11;100.13;98.49;99.82;15630000;99.82
1971-10-05;99.21;99.78;98.34;99.11;12360000;99.11
1971-10-04;98.93;100.04;98.62;99.21;14570000;99.21
1971-10-01;98.34;99.49;97.96;98.93;13400000;98.93
1971-09-30;97.90;98.97;97.48;98.34;13490000;98.34
1971-09-29;97.88;98.51;97.29;97.90;8580000;97.90
1971-09-28;97.62;98.55;97.12;97.88;11250000;97.88
1971-09-27;98.15;98.41;96.97;97.62;10220000;97.62
1971-09-24;98.38;99.35;97.78;98.15;13460000;98.15
1971-09-23;98.47;99.12;97.61;98.38;13250000;98.38
1971-09-22;99.34;99.72;98.15;98.47;14250000;98.47
1971-09-21;99.68;100.08;98.71;99.34;10640000;99.34
1971-09-20;99.96;100.40;99.14;99.68;9540000;99.68
1971-09-17;99.66;100.52;99.26;99.96;11020000;99.96
1971-09-16;99.77;100.35;99.07;99.66;10550000;99.66
1971-09-15;99.34;100.24;98.79;99.77;11080000;99.77
1971-09-14;100.07;100.35;98.99;99.34;11410000;99.34
1971-09-13;100.42;100.84;99.49;100.07;10000000;100.07
1971-09-10;100.80;101.01;99.69;100.42;11380000;100.42
1971-09-09;101.34;101.88;100.38;100.80;15790000;100.80
1971-09-08;101.15;101.94;100.52;101.34;14230000;101.34
1971-09-07;100.69;102.25;100.43;101.15;17080000;101.15
1971-09-03;99.29;100.93;99.10;100.69;14040000;100.69
1971-09-02;99.07;99.80;98.52;99.29;10690000;99.29
1971-09-01;99.03;99.84;98.50;99.07;10770000;99.07
1971-08-31;99.52;99.76;98.32;99.03;10430000;99.03
1971-08-30;100.48;100.89;99.17;99.52;11140000;99.52
1971-08-27;100.24;101.22;99.76;100.48;12490000;100.48
1971-08-26;100.41;101.12;99.40;100.24;13990000;100.24
1971-08-25;100.40;101.51;99.77;100.41;18280000;100.41
1971-08-24;99.25;101.02;99.15;100.40;18700000;100.40
1971-08-23;98.33;99.96;98.09;99.25;13040000;99.25
1971-08-20;98.16;98.94;97.52;98.33;11890000;98.33
1971-08-19;98.60;99.07;97.35;98.16;14190000;98.16
1971-08-18;99.99;100.19;98.06;98.60;20680000;98.60
1971-08-17;98.76;101.00;98.49;99.99;26790000;99.99
1971-08-16;97.90;100.96;97.90;98.76;31730000;98.76
1971-08-13;96.00;96.53;95.19;95.69;9960000;95.69
1971-08-12;94.81;96.50;94.81;96.00;15910000;96.00
1971-08-11;93.54;95.06;93.35;94.66;11370000;94.66
1971-08-10;93.53;94.13;92.81;93.54;9460000;93.54
1971-08-09;94.25;94.55;93.17;93.53;8110000;93.53
1971-08-06;94.09;94.91;93.63;94.25;9490000;94.25
1971-08-05;93.89;94.89;93.33;94.09;12100000;94.09
1971-08-04;94.51;95.34;93.35;93.89;15410000;93.89
1971-08-03;95.96;96.11;94.06;94.51;13490000;94.51
1971-08-02;95.58;96.76;95.22;95.96;11870000;95.96
1971-07-30;96.02;96.78;95.08;95.58;12970000;95.58
1971-07-29;97.07;97.22;95.37;96.02;14570000;96.02
1971-07-28;97.78;98.15;96.51;97.07;13940000;97.07
1971-07-27;98.14;98.99;97.42;97.78;11560000;97.78
1971-07-26;98.94;99.47;96.67;98.14;9930000;98.14
1971-07-23;99.11;99.60;98.26;98.94;12370000;98.94
1971-07-22;99.28;99.82;98.50;99.11;12570000;99.11
1971-07-21;99.32;100.00;98.74;99.28;11920000;99.28
1971-07-20;98.93;100.01;98.60;99.32;12540000;99.32
1971-07-19;99.11;99.57;98.11;98.93;11430000;98.93
1971-07-16;99.28;100.35;98.64;99.11;13870000;99.11
1971-07-15;99.22;100.48;98.76;99.28;13080000;99.28
1971-07-14;99.50;99.83;98.23;99.22;14360000;99.22
1971-07-13;100.82;101.06;99.07;99.50;13540000;99.50
1971-07-12;100.69;101.52;100.19;100.82;12020000;100.82
1971-07-09;100.34;101.33;99.86;100.69;12640000;100.69
1971-07-08;100.04;101.03;99.59;100.34;13920000;100.34
1971-07-07;99.76;100.83;99.25;100.04;14520000;100.04
1971-07-06;99.78;100.35;99.10;99.76;10440000;99.76
1971-07-02;99.78;100.31;99.09;99.78;9960000;99.78
1971-07-01;99.16;100.65;99.16;99.78;13090000;99.78
1971-06-30;98.82;100.29;98.68;98.70;15410000;98.70
1971-06-29;97.74;99.39;97.61;98.82;14460000;98.82
1971-06-28;97.99;98.48;97.02;97.74;9810000;97.74
1971-06-25;98.13;98.66;97.33;97.99;10580000;97.99
1971-06-24;98.41;99.00;97.59;98.13;11360000;98.13
1971-06-23;97.59;98.95;97.36;98.41;12640000;98.41
1971-06-22;97.87;98.66;96.92;97.59;15200000;97.59
1971-06-21;98.97;99.18;97.22;97.87;16490000;97.87
1971-06-18;100.50;100.63;98.65;98.97;15040000;98.97
1971-06-17;100.52;101.37;99.87;100.50;13980000;100.50
1971-06-16;100.32;101.29;99.68;100.52;14300000;100.52
1971-06-15;100.22;101.10;99.45;100.32;13550000;100.32
1971-06-14;101.07;101.28;99.78;100.22;11530000;100.22
1971-06-11;100.64;101.71;100.18;101.07;12270000;101.07
1971-06-10;100.29;101.23;99.78;100.64;12450000;100.64
1971-06-09;100.32;100.97;99.28;100.29;14250000;100.29
1971-06-08;101.09;101.50;99.91;100.32;13610000;100.32
1971-06-07;101.30;102.02;100.55;101.09;13800000;101.09
1971-06-04;101.01;101.88;100.43;101.30;14400000;101.30
1971-06-03;100.96;102.07;100.30;101.01;18790000;101.01
1971-06-02;100.20;101.53;99.89;100.96;17740000;100.96
1971-06-01;99.63;100.76;99.22;100.20;11930000;100.20
1971-05-28;99.40;100.17;98.68;99.63;11760000;99.63
1971-05-27;99.59;100.14;98.78;99.40;12610000;99.40
1971-05-26;99.47;100.49;98.93;99.59;13550000;99.59
1971-05-25;100.13;100.39;98.73;99.47;16050000;99.47
1971-05-24;100.99;101.24;99.72;100.13;12060000;100.13
1971-05-21;101.31;101.84;100.41;100.99;12090000;100.99
1971-05-20;101.07;102.17;100.61;101.31;11740000;101.31
1971-05-19;100.83;101.75;100.30;101.07;17640000;101.07
1971-05-18;100.69;101.62;99.68;100.83;17640000;100.83
1971-05-17;102.08;102.08;100.25;100.69;15980000;100.69
1971-05-14;102.69;103.17;101.65;102.21;16430000;102.21
1971-05-13;102.90;103.57;101.98;102.69;17640000;102.69
1971-05-12;102.62;103.57;102.12;102.90;15140000;102.90
1971-05-11;102.36;103.37;101.50;102.62;17730000;102.62
1971-05-10;102.87;103.15;101.71;102.36;12810000;102.36
1971-05-07;103.23;103.50;101.86;102.87;16490000;102.87
1971-05-06;103.78;104.42;102.80;103.23;19300000;103.23
1971-05-05;103.79;104.28;102.68;103.78;17270000;103.78
1971-05-04;103.29;104.36;102.71;103.79;17310000;103.79
1971-05-03;103.95;104.11;102.37;103.29;16120000;103.29
1971-04-30;104.63;104.96;103.25;103.95;17490000;103.95
1971-04-29;104.77;105.58;103.90;104.63;20340000;104.63
1971-04-28;104.59;105.60;103.85;104.77;24820000;104.77
1971-04-27;103.94;105.07;103.23;104.59;21250000;104.59
1971-04-26;104.05;104.83;103.19;103.94;18860000;103.94
1971-04-23;103.56;104.63;102.79;104.05;20150000;104.05
1971-04-22;103.36;104.27;102.58;103.56;19270000;103.56
1971-04-21;103.61;104.16;102.55;103.36;17040000;103.36
1971-04-20;104.01;104.58;103.06;103.61;17880000;103.61
1971-04-19;103.49;104.63;103.09;104.01;17730000;104.01
1971-04-16;103.52;104.18;102.68;103.49;18280000;103.49
1971-04-15;103.37;104.40;102.76;103.52;22540000;103.52
1971-04-14;102.98;104.01;102.28;103.37;19440000;103.37
1971-04-13;102.88;103.96;102.25;102.98;23200000;102.98
1971-04-12;102.10;103.54;101.75;102.88;19410000;102.88
1971-04-08;101.98;102.86;101.30;102.10;17590000;102.10
1971-04-07;101.51;102.87;101.13;101.98;22270000;101.98
1971-04-06;100.79;102.11;100.30;101.51;19990000;101.51
1971-04-05;100.56;101.41;99.88;100.79;16040000;100.79
1971-04-02;100.39;101.23;99.86;100.56;14520000;100.56
1971-04-01;100.31;100.99;99.63;100.39;13470000;100.39
1971-03-31;100.26;101.05;99.69;100.31;17610000;100.31
1971-03-30;100.03;100.86;99.41;100.26;15430000;100.26
1971-03-29;99.95;100.74;99.36;100.03;13650000;100.03
1971-03-26;99.61;100.65;99.18;99.95;15560000;99.95
1971-03-25;99.62;100.03;98.36;99.61;15870000;99.61
1971-03-24;100.28;100.63;99.15;99.62;15770000;99.62
1971-03-23;100.62;101.06;99.62;100.28;16470000;100.28
1971-03-22;101.01;101.46;100.08;100.62;14290000;100.62
1971-03-19;101.19;101.74;100.35;101.01;15150000;101.01
1971-03-18;101.12;102.03;100.43;101.19;17910000;101.19
1971-03-17;101.21;101.66;99.98;101.12;17070000;101.12
1971-03-16;100.71;101.94;100.36;101.21;22270000;101.21
1971-03-15;99.57;101.15;99.12;100.71;18920000;100.71
1971-03-12;99.39;100.09;98.64;99.57;14680000;99.57
1971-03-11;99.30;100.29;98.57;99.39;19830000;99.39
1971-03-10;99.46;100.10;98.63;99.30;17220000;99.30
1971-03-09;99.38;100.31;98.72;99.46;20490000;99.46
1971-03-08;98.96;99.44;98.42;99.38;19340000;99.38
1971-03-05;97.92;99.49;97.82;98.96;22430000;98.96
1971-03-04;96.95;98.38;96.90;97.92;17350000;97.92
1971-03-03;96.98;97.54;96.30;96.95;14680000;96.95
1971-03-02;97.00;97.60;96.32;96.98;14870000;96.98
1971-03-01;96.75;97.48;96.11;97.00;13020000;97.00
1971-02-26;96.96;97.54;95.84;96.75;17250000;96.75
1971-02-25;96.73;97.71;96.08;96.96;16200000;96.96
1971-02-24;96.09;97.34;95.86;96.73;15930000;96.73
1971-02-23;95.72;96.67;94.92;96.09;15080000;96.09
1971-02-22;96.65;96.65;94.97;95.72;15840000;95.72
1971-02-19;97.56;97.79;96.25;96.74;17860000;96.74
1971-02-18;98.20;98.60;96.96;97.56;16650000;97.56
1971-02-17;98.66;99.32;97.32;98.20;18720000;98.20
1971-02-16;98.43;99.59;97.85;98.66;21350000;98.66
1971-02-12;97.91;98.96;97.56;98.43;18470000;98.43
1971-02-11;97.39;98.49;96.99;97.91;19260000;97.91
1971-02-10;97.51;97.97;96.23;97.39;19040000;97.39
1971-02-09;97.45;98.50;96.90;97.51;28250000;97.51
1971-02-08;96.93;98.04;96.13;97.45;25590000;97.45
1971-02-05;96.62;97.58;95.84;96.93;20480000;96.93
1971-02-04;96.63;97.26;95.69;96.62;20860000;96.62
1971-02-03;96.43;97.19;95.58;96.63;21680000;96.63
1971-02-02;96.42;97.19;95.60;96.43;22030000;96.43
1971-02-01;95.88;97.05;95.38;96.42;20650000;96.42
1971-01-29;95.21;96.49;94.79;95.88;20960000;95.88
1971-01-28;94.89;95.78;94.12;95.21;18840000;95.21
1971-01-27;95.59;95.78;93.96;94.89;20640000;94.89
1971-01-26;95.28;96.36;94.69;95.59;21380000;95.59
1971-01-25;94.88;95.93;94.16;95.28;19050000;95.28
1971-01-22;94.19;95.53;93.96;94.88;21680000;94.88
1971-01-21;93.78;94.69;93.15;94.19;19060000;94.19
1971-01-20;93.76;94.53;93.07;93.78;18330000;93.78
1971-01-19;93.41;94.28;92.85;93.76;15800000;93.76
1971-01-18;93.03;94.11;92.63;93.41;15400000;93.41
1971-01-15;92.80;93.94;92.25;93.03;18010000;93.03
1971-01-14;92.56;93.36;91.67;92.80;17600000;92.80
1971-01-13;92.72;93.66;91.88;92.56;19070000;92.56
1971-01-12;91.98;93.28;91.63;92.72;17820000;92.72
1971-01-11;92.19;92.67;90.99;91.98;14720000;91.98
1971-01-08;92.38;93.02;91.60;92.19;14100000;92.19
1971-01-07;92.35;93.26;91.75;92.38;16460000;92.38
1971-01-06;91.80;93.00;91.50;92.35;16960000;92.35
1971-01-05;91.15;92.28;90.69;91.80;12600000;91.80
1971-01-04;92.15;92.19;90.64;91.15;10010000;91.15
1970-12-31;92.27;92.79;91.36;92.15;13390000;92.15
1970-12-30;92.08;92.99;91.60;92.27;19140000;92.27
1970-12-29;91.09;92.38;90.73;92.08;17750000;92.08
1970-12-28;90.61;91.49;90.28;91.09;12290000;91.09
1970-12-24;90.10;91.08;89.81;90.61;12140000;90.61
1970-12-23;90.04;90.86;89.35;90.10;15400000;90.10
1970-12-22;89.94;90.84;89.35;90.04;14510000;90.04
1970-12-21;90.22;90.77;89.36;89.94;12690000;89.94
1970-12-18;90.04;90.77;89.42;90.22;14360000;90.22
1970-12-17;89.72;90.61;89.31;90.04;13660000;90.04
1970-12-16;89.66;90.22;88.77;89.72;14240000;89.72
1970-12-15;89.80;90.32;88.93;89.66;13420000;89.66
1970-12-14;90.26;90.81;89.28;89.80;13810000;89.80
1970-12-11;89.92;90.93;89.44;90.26;15790000;90.26
1970-12-10;89.54;90.87;89.01;89.92;14610000;89.92
1970-12-09;89.47;90.03;88.48;89.54;13550000;89.54
1970-12-08;89.94;90.47;88.87;89.47;14370000;89.47
1970-12-07;89.46;90.39;88.76;89.94;15530000;89.94
1970-12-04;88.90;89.89;88.12;89.46;15980000;89.46
1970-12-03;88.48;89.87;88.11;88.90;20480000;88.90
1970-12-02;87.47;88.83;86.72;88.48;17960000;88.48
1970-12-01;87.20;88.61;86.11;87.47;20170000;87.47
1970-11-30;85.93;87.60;85.79;87.20;17700000;87.20
1970-11-27;85.09;86.21;84.67;85.93;10130000;85.93
1970-11-25;84.78;85.70;84.35;85.09;13490000;85.09
1970-11-24;84.24;85.18;83.59;84.78;12560000;84.78
1970-11-23;83.72;84.92;83.47;84.24;12720000;84.24
1970-11-20;82.91;84.06;82.49;83.72;10920000;83.72
1970-11-19;82.79;83.48;82.23;82.91;9280000;82.91
1970-11-18;83.47;83.53;82.41;82.79;9850000;82.79
1970-11-17;83.24;84.17;82.81;83.47;9450000;83.47
1970-11-16;83.37;83.75;82.34;83.24;9160000;83.24
1970-11-13;84.15;84.33;82.92;83.37;11890000;83.37
1970-11-12;85.03;85.54;83.81;84.15;12520000;84.15
1970-11-11;84.79;86.24;84.69;85.03;13520000;85.03
1970-11-10;84.67;85.69;84.18;84.79;12030000;84.79
1970-11-09;84.22;85.27;83.82;84.67;10890000;84.67
1970-11-06;84.10;84.73;83.55;84.22;9970000;84.22
1970-11-05;84.39;84.79;83.53;84.10;10800000;84.10
1970-11-04;84.22;85.26;83.82;84.39;12180000;84.39
1970-11-03;83.51;84.77;83.21;84.22;11760000;84.22
1970-11-02;83.25;83.99;82.66;83.51;9470000;83.51
1970-10-30;83.36;83.80;82.52;83.25;10520000;83.25
1970-10-29;83.43;84.10;82.82;83.36;10440000;83.36
1970-10-28;83.12;83.81;82.29;83.43;10660000;83.43
1970-10-27;83.31;83.73;82.52;83.12;9680000;83.12
1970-10-26;83.77;84.26;82.89;83.31;9200000;83.31
1970-10-23;83.38;84.30;82.91;83.77;10270000;83.77
1970-10-22;83.66;84.04;82.77;83.38;9000000;83.38
1970-10-21;83.64;84.72;83.21;83.66;11330000;83.66
1970-10-20;83.15;84.19;82.62;83.64;10630000;83.64
1970-10-19;84.28;84.29;82.81;83.15;9890000;83.15
1970-10-16;84.65;85.21;83.83;84.28;11300000;84.28
1970-10-15;84.19;85.28;83.82;84.65;11250000;84.65
1970-10-14;84.06;84.83;83.42;84.19;9920000;84.19
1970-10-13;84.17;84.70;83.24;84.06;9500000;84.06
1970-10-12;85.05;85.05;83.58;84.17;8570000;84.17
1970-10-09;85.95;86.25;84.54;85.08;13980000;85.08
1970-10-08;86.89;87.37;85.55;85.95;14500000;85.95
1970-10-07;86.85;87.47;85.55;86.89;15610000;86.89
1970-10-06;86.47;87.75;86.04;86.85;20240000;86.85
1970-10-05;85.16;86.99;85.01;86.47;19760000;86.47
1970-10-02;84.32;85.56;84.06;85.16;15420000;85.16
1970-10-01;84.30;84.70;83.46;84.32;9700000;84.32
1970-09-30;83.86;84.99;82.78;84.30;14830000;84.30
1970-09-29;83.91;84.57;83.11;83.86;17880000;83.86
1970-09-28;82.83;84.56;82.61;83.91;14390000;83.91
1970-09-25;81.66;83.60;81.41;82.83;20470000;82.83
1970-09-24;81.91;82.24;80.82;81.66;21340000;81.66
1970-09-23;81.86;83.15;81.52;81.91;16940000;81.91
1970-09-22;81.91;82.24;80.82;81.86;12110000;81.86
1970-09-21;82.62;83.15;81.52;81.91;12540000;81.91
1970-09-18;82.29;83.50;81.77;82.62;15900000;82.62
1970-09-17;81.79;83.09;81.51;82.29;15530000;82.29
1970-09-16;81.36;82.57;80.61;81.79;12090000;81.79
1970-09-15;82.07;82.11;80.75;81.36;9830000;81.36
1970-09-14;82.52;83.13;81.43;82.07;11900000;82.07
1970-09-11;82.30;83.19;81.81;82.52;12140000;82.52
1970-09-10;82.79;82.98;81.62;82.30;11900000;82.30
1970-09-09;83.04;83.78;81.90;82.79;16250000;82.79
1970-09-08;82.83;83.69;81.48;83.04;17110000;83.04
1970-09-04;82.09;83.42;81.79;82.83;15360000;82.83
1970-09-03;80.96;82.63;80.88;82.09;14110000;82.09
1970-09-02;80.95;81.35;79.95;80.96;9710000;80.96
1970-09-01;81.52;81.80;80.43;80.95;10960000;80.95
1970-08-31;81.86;82.33;80.95;81.52;10740000;81.52
1970-08-28;81.08;82.47;80.69;81.86;13820000;81.86
1970-08-27;81.21;81.91;80.13;81.08;12440000;81.08
1970-08-26;81.12;82.26;80.60;81.21;15970000;81.21
1970-08-25;80.99;81.81;79.69;81.12;17520000;81.12
1970-08-24;79.41;81.62;79.41;80.99;18910000;80.99
1970-08-21;77.84;79.60;77.46;79.24;13420000;79.24
1970-08-20;76.96;77.99;76.30;77.84;10170000;77.84
1970-08-19;76.20;77.58;76.01;76.96;9870000;76.96
1970-08-18;75.33;76.79;75.30;76.20;9500000;76.20
1970-08-17;75.18;75.79;74.52;75.33;6940000;75.33
1970-08-14;74.76;75.74;74.39;75.18;7850000;75.18
1970-08-13;75.42;75.69;74.13;74.76;8640000;74.76
1970-08-12;75.82;76.24;75.04;75.42;7440000;75.42
1970-08-11;76.20;76.33;75.16;75.82;7330000;75.82
1970-08-10;77.28;77.40;75.72;76.20;7580000;76.20
1970-08-07;77.08;78.09;76.46;77.28;9370000;77.28
1970-08-06;77.18;77.68;76.39;77.08;7560000;77.08
1970-08-05;77.19;77.86;76.59;77.18;7660000;77.18
1970-08-04;77.02;77.56;76.12;77.19;8310000;77.19
1970-08-03;78.05;78.24;76.56;77.02;7650000;77.02
1970-07-31;78.07;79.03;77.44;78.05;11640000;78.05
1970-07-30;78.04;78.66;77.36;78.07;10430000;78.07
1970-07-29;77.77;78.81;77.28;78.04;12580000;78.04
1970-07-28;77.65;78.35;76.96;77.77;9040000;77.77
1970-07-27;77.82;78.27;77.07;77.65;7460000;77.65
1970-07-24;78.00;78.48;76.96;77.82;9520000;77.82
1970-07-23;77.03;78.51;76.46;78.00;12460000;78.00
1970-07-22;76.98;78.20;76.22;77.03;12460000;77.03
1970-07-21;77.79;77.94;76.39;76.98;9940000;76.98
1970-07-20;77.69;78.72;77.04;77.79;11660000;77.79
1970-07-17;76.37;78.23;76.37;77.69;13870000;77.69
1970-07-16;75.23;77.09;75.12;76.34;12200000;76.34
1970-07-15;74.42;75.68;74.06;75.23;8860000;75.23
1970-07-14;74.55;75.04;73.78;74.42;7360000;74.42
1970-07-13;74.45;75.37;73.83;74.55;7450000;74.55
1970-07-10;74.06;75.21;73.49;74.45;10160000;74.45
1970-07-09;73.00;74.77;72.88;74.06;12820000;74.06
1970-07-08;71.23;73.30;70.99;73.00;10970000;73.00
1970-07-07;71.78;72.32;70.69;71.23;10470000;71.23
1970-07-06;72.92;73.12;71.38;71.78;9340000;71.78
1970-07-02;72.94;73.92;72.43;72.92;8440000;72.92
1970-07-01;72.72;73.66;72.11;72.94;8610000;72.94
1970-06-30;72.89;73.89;72.25;72.72;9280000;72.72
1970-06-29;73.47;73.86;72.34;72.89;8770000;72.89
1970-06-26;74.02;74.68;73.09;73.47;9160000;73.47
1970-06-25;73.97;74.93;73.30;74.02;8200000;74.02
1970-06-24;74.76;75.42;73.40;73.97;12630000;73.97
1970-06-23;76.64;76.83;74.52;74.76;10790000;74.76
1970-06-22;77.05;77.43;75.61;76.64;8700000;76.64
1970-06-19;76.51;78.05;76.31;77.05;10980000;77.05
1970-06-18;76.00;77.17;74.99;76.51;8870000;76.51
1970-06-17;76.15;78.04;75.63;76.00;9870000;76.00
1970-06-16;74.58;76.76;74.21;76.15;11330000;76.15
1970-06-15;73.88;75.27;73.67;74.58;6920000;74.58
1970-06-12;74.45;74.84;73.25;73.88;8890000;73.88
1970-06-11;75.48;75.52;73.96;74.45;7770000;74.45
1970-06-10;76.25;76.62;74.92;75.48;7240000;75.48
1970-06-09;76.29;79.96;75.58;76.25;7050000;76.25
1970-06-08;76.17;77.37;75.30;76.29;8040000;76.29
1970-06-05;77.36;77.48;75.25;76.17;12450000;76.17
1970-06-04;78.52;79.42;76.99;77.36;14380000;77.36
1970-06-03;77.84;79.22;76.97;78.52;16600000;78.52
1970-06-02;77.84;78.73;76.51;77.84;13480000;77.84
1970-06-01;76.55;78.40;75.84;77.84;15020000;77.84
1970-05-29;74.61;76.92;73.53;76.55;14630000;76.55
1970-05-28;72.77;75.44;72.59;74.61;18910000;74.61
1970-05-27;69.37;73.22;69.37;72.77;17460000;72.77
1970-05-26;70.25;71.17;68.61;69.29;17030000;69.29
1970-05-25;72.16;72.16;69.92;70.25;12660000;70.25
1970-05-22;72.16;73.42;71.42;72.25;12170000;72.25
1970-05-21;73.51;73.51;70.94;72.16;16710000;72.16
1970-05-20;75.35;75.35;73.25;73.52;13020000;73.52
1970-05-19;76.96;77.20;75.21;75.46;9480000;75.46
1970-05-18;76.90;77.68;76.07;76.96;8280000;76.96
1970-05-15;75.44;77.42;74.59;76.90;14570000;76.90
1970-05-14;76.53;76.64;74.03;75.44;13920000;75.44
1970-05-13;77.75;77.75;75.92;76.53;10720000;76.53
1970-05-12;78.60;79.15;77.06;77.85;10850000;77.85
1970-05-11;79.44;79.72;78.29;78.60;6650000;78.60
1970-05-08;79.83;80.15;78.71;79.44;6930000;79.44
1970-05-07;79.47;80.60;78.89;79.83;9530000;79.83
1970-05-06;78.60;80.91;78.23;79.47;14380000;79.47
1970-05-05;79.37;79.83;78.02;78.60;10580000;78.60
1970-05-04;81.28;81.28;78.85;79.37;11450000;79.37
1970-05-01;81.52;82.32;80.27;81.44;8290000;81.44
1970-04-30;81.81;82.57;80.76;81.52;9880000;81.52
1970-04-29;80.27;83.23;79.31;81.81;15800000;81.81
1970-04-28;81.46;82.16;79.86;80.27;12620000;80.27
1970-04-27;82.77;83.08;81.08;81.46;10240000;81.46
1970-04-24;83.04;83.62;81.96;82.77;10410000;82.77
1970-04-23;84.27;84.30;82.61;83.04;11050000;83.04
1970-04-22;85.38;85.51;83.84;84.27;10780000;84.27
1970-04-21;85.83;86.54;84.99;85.38;8490000;85.38
1970-04-20;85.67;86.36;84.99;85.83;8280000;85.83
1970-04-17;85.88;86.36;84.75;85.67;10990000;85.67
1970-04-16;86.73;87.13;85.51;85.88;10250000;85.88
1970-04-15;86.89;87.71;86.53;86.73;9410000;86.73
1970-04-14;87.64;87.73;86.01;86.89;10840000;86.89
1970-04-13;88.24;88.67;87.15;87.64;8810000;87.64
1970-04-10;88.53;89.14;87.82;88.24;10020000;88.24
1970-04-09;88.49;89.32;87.96;88.53;9060000;88.53
1970-04-08;88.52;89.09;87.83;88.49;9070000;88.49
1970-04-07;88.76;89.31;87.94;88.52;8490000;88.52
1970-04-06;89.39;89.61;88.15;88.76;8380000;88.76
1970-04-03;89.79;90.16;88.81;89.39;9920000;89.39
1970-04-02;90.07;90.70;89.28;89.79;10520000;89.79
1970-04-01;89.63;90.62;89.30;90.07;9810000;90.07
1970-03-31;89.63;90.17;88.85;89.63;8370000;89.63
1970-03-30;89.92;90.41;88.91;89.63;9600000;89.63
1970-03-26;89.77;90.65;89.18;89.92;11350000;89.92
1970-03-25;88.11;91.07;88.11;89.77;17500000;89.77
1970-03-24;86.99;88.43;86.90;87.98;8840000;87.98
1970-03-23;87.06;87.64;86.19;86.99;7330000;86.99
1970-03-20;87.42;87.77;86.43;87.06;7910000;87.06
1970-03-19;87.54;88.20;86.88;87.42;8930000;87.42
1970-03-18;87.29;88.28;86.93;87.54;9790000;87.54
1970-03-17;86.91;87.86;86.36;87.29;9090000;87.29
1970-03-16;87.86;87.97;86.39;86.91;8910000;86.91
1970-03-13;88.33;89.43;87.29;87.86;9560000;87.86
1970-03-12;88.69;89.09;87.68;88.33;9140000;88.33
1970-03-11;88.75;89.58;88.11;88.69;9180000;88.69
1970-03-10;88.51;89.41;87.89;88.75;9450000;88.75
1970-03-09;89.43;89.43;87.94;88.51;9760000;88.51
1970-03-06;90.00;90.36;88.84;89.44;10980000;89.44
1970-03-05;90.04;90.99;89.38;90.00;11370000;90.00
1970-03-04;90.23;91.05;89.32;90.04;11850000;90.04
1970-03-03;89.71;90.67;88.96;90.23;11700000;90.23
1970-03-02;89.50;90.80;88.92;89.71;12270000;89.71
1970-02-27;88.90;90.33;88.42;89.50;12890000;89.50
1970-02-26;89.35;89.63;87.63;88.90;11540000;88.90
1970-02-25;87.99;89.80;87.11;89.35;13210000;89.35
1970-02-24;88.03;88.91;87.28;87.99;10810000;87.99
1970-02-20;87.76;88.74;86.87;88.03;10790000;88.03
1970-02-19;87.44;88.70;86.94;87.76;12890000;87.76
1970-02-18;86.37;88.07;86.19;87.44;11950000;87.44
1970-02-17;86.47;87.08;85.57;86.37;10140000;86.37
1970-02-16;86.54;87.30;85.80;86.47;19780000;86.47
1970-02-13;86.73;87.30;85.71;86.54;11060000;86.54
1970-02-12;86.94;87.54;85.93;86.73;10010000;86.73
1970-02-11;86.10;87.38;85.30;86.94;12260000;86.94
1970-02-10;87.01;87.40;85.58;86.10;10110000;86.10
1970-02-09;86.33;87.85;86.16;87.01;10830000;87.01
1970-02-06;85.90;86.88;85.23;86.33;10150000;86.33
1970-02-05;86.24;86.62;84.95;85.90;9430000;85.90
1970-02-04;86.77;87.66;85.59;86.24;11040000;86.24
1970-02-03;85.75;87.54;84.64;86.77;16050000;86.77
1970-02-02;85.02;86.76;84.76;85.75;13440000;85.75
1970-01-30;85.69;86.33;84.42;85.02;12320000;85.02
1970-01-29;86.79;87.09;85.02;85.69;12210000;85.69
1970-01-28;87.62;88.24;86.44;86.79;10510000;86.79
1970-01-27;88.17;88.54;86.92;87.62;9630000;87.62
1970-01-26;89.23;89.23;87.49;88.17;10670000;88.17
1970-01-23;90.04;90.45;88.74;89.37;11000000;89.37
1970-01-22;89.95;90.80;89.20;90.04;11050000;90.04
1970-01-21;89.83;90.61;89.20;89.95;9880000;89.95
1970-01-20;89.65;90.45;88.64;89.83;11050000;89.83
1970-01-19;90.72;90.72;89.14;89.65;9500000;89.65
1970-01-16;91.68;92.49;90.36;90.92;11940000;90.92
1970-01-15;91.65;92.35;90.73;91.68;11120000;91.68
1970-01-14;91.92;92.40;90.88;91.65;10380000;91.65
1970-01-13;91.70;92.61;90.99;91.92;9870000;91.92
1970-01-12;92.40;92.67;91.20;91.70;8900000;91.70
1970-01-09;92.68;93.25;91.82;92.40;9380000;92.40
1970-01-08;92.63;93.47;91.99;92.68;10670000;92.68
1970-01-07;92.82;93.38;91.93;92.63;10010000;92.63
1970-01-06;93.46;93.81;92.13;92.82;11460000;92.82
1970-01-05;93.00;94.25;92.53;93.46;11490000;93.46
1970-01-02;92.06;93.54;91.79;93.00;8050000;93.00
1969-12-31;91.60;92.94;91.15;92.06;19380000;92.06
1969-12-30;91.25;92.20;90.47;91.60;15790000;91.60
1969-12-29;91.89;92.49;90.66;91.25;12500000;91.25
1969-12-26;91.18;92.30;90.94;91.89;6750000;91.89
1969-12-24;90.23;91.89;89.93;91.18;11670000;91.18
1969-12-23;90.58;91.13;89.40;90.23;13890000;90.23
1969-12-22;91.38;92.03;90.10;90.58;12680000;90.58
1969-12-19;90.61;92.34;90.33;91.38;15420000;91.38
1969-12-18;89.20;91.15;88.62;90.61;15950000;90.61
1969-12-17;89.72;90.32;88.94;89.20;12840000;89.20
1969-12-16;90.54;91.05;89.23;89.72;11880000;89.72
1969-12-15;90.81;91.42;89.96;90.54;11100000;90.54
1969-12-12;90.52;91.67;90.05;90.81;11630000;90.81
1969-12-11;90.48;91.37;89.74;90.52;10430000;90.52
1969-12-10;90.55;91.22;89.33;90.48;12590000;90.48
1969-12-09;90.84;91.79;89.93;90.55;12290000;90.55
1969-12-08;91.73;92.05;90.29;90.84;9990000;90.84
1969-12-05;91.95;92.91;91.14;91.73;11150000;91.73
1969-12-04;91.65;92.45;90.36;91.95;13230000;91.95
1969-12-03;92.65;93.05;91.25;91.65;11300000;91.65
1969-12-02;93.22;93.54;91.95;92.65;9940000;92.65
1969-12-01;93.81;94.47;92.78;93.22;9950000;93.22
1969-11-28;93.27;94.41;92.88;93.81;8550000;93.81
1969-11-26;92.94;93.85;92.24;93.27;10630000;93.27
1969-11-25;93.24;94.17;92.38;92.94;11560000;92.94
1969-11-24;94.32;94.43;92.63;93.24;10940000;93.24
1969-11-21;94.91;95.34;93.87;94.32;9840000;94.32
1969-11-20;95.90;95.94;94.12;94.91;12010000;94.91
1969-11-19;96.39;96.95;95.36;95.90;11240000;95.90
1969-11-18;96.41;97.00;95.57;96.39;11010000;96.39
1969-11-17;97.07;97.36;95.82;96.41;10120000;96.41
1969-11-14;97.42;97.44;96.36;97.07;10580000;97.07
1969-11-13;97.89;98.34;96.54;97.42;12090000;97.42
1969-11-12;98.07;98.72;97.28;97.89;12480000;97.89
1969-11-11;98.33;98.79;97.45;98.07;10080000;98.07
1969-11-10;98.26;99.23;97.65;98.33;12490000;98.33
1969-11-07;97.67;99.01;97.18;98.26;13280000;98.26
1969-11-06;97.64;98.31;96.80;97.67;11110000;97.67
1969-11-05;97.21;98.39;96.75;97.64;12110000;97.64
1969-11-04;97.15;97.82;95.84;97.21;12340000;97.21
1969-11-03;97.12;97.82;96.19;97.15;11140000;97.15
1969-10-31;96.93;98.03;96.33;97.12;13100000;97.12
1969-10-30;96.81;97.47;95.61;96.93;12820000;96.93
1969-10-29;97.66;97.92;96.26;96.81;12380000;96.81
1969-10-28;97.97;98.55;97.02;97.66;12410000;97.66
1969-10-27;98.12;98.78;97.49;97.97;12160000;97.97
1969-10-24;97.46;98.83;96.97;98.12;15430000;98.12
1969-10-23;97.83;98.39;96.46;97.46;14780000;97.46
1969-10-22;97.20;98.61;96.56;97.83;19320000;97.83
1969-10-21;96.46;97.84;95.86;97.20;16460000;97.20
1969-10-20;96.26;97.17;95.29;96.46;13540000;96.46
1969-10-17;96.37;97.24;95.38;96.26;13740000;96.26
1969-10-16;95.72;97.54;95.05;96.37;19500000;96.37
1969-10-15;95.70;96.56;94.65;95.72;15740000;95.72
1969-10-14;94.55;96.53;94.32;95.70;19950000;95.70
1969-10-13;93.56;94.86;93.20;94.55;13620000;94.55
1969-10-10;93.03;94.19;92.60;93.56;12210000;93.56
1969-10-09;92.67;93.55;91.75;93.03;10420000;93.03
1969-10-08;93.09;93.56;92.04;92.67;10370000;92.67
1969-10-07;93.38;94.03;92.59;93.09;10050000;93.09
1969-10-06;93.19;93.99;92.50;93.38;9180000;93.38
1969-10-03;93.24;94.39;92.65;93.19;12410000;93.19
1969-10-02;92.52;93.63;91.66;93.24;11430000;93.24
1969-10-01;93.12;93.51;92.12;92.52;9090000;92.52
1969-09-30;93.41;94.05;92.55;93.12;9180000;93.12
1969-09-29;94.16;94.45;92.62;93.41;10170000;93.41
1969-09-26;94.77;95.23;93.53;94.16;9680000;94.16
1969-09-25;95.50;95.92;94.28;94.77;10690000;94.77
1969-09-24;95.63;96.20;94.75;95.50;11320000;95.50
1969-09-23;95.63;96.62;94.86;95.63;13030000;95.63
1969-09-22;95.19;96.13;94.58;95.63;9280000;95.63
1969-09-19;94.90;95.92;94.35;95.19;12270000;95.19
1969-09-18;94.76;95.53;94.05;94.90;11170000;94.90
1969-09-17;94.95;95.70;94.04;94.76;10980000;94.76
1969-09-16;94.87;95.73;94.06;94.95;11160000;94.95
1969-09-15;94.13;95.61;93.73;94.87;10680000;94.87
1969-09-12;94.22;95.04;93.26;94.13;10800000;94.13
1969-09-11;94.95;95.77;93.72;94.22;12370000;94.22
1969-09-10;93.38;95.35;93.23;94.95;11490000;94.95
1969-09-09;92.70;93.94;91.77;93.38;10980000;93.38
1969-09-08;93.64;93.76;92.35;92.70;8310000;92.70
1969-09-05;94.20;94.51;93.09;93.64;8890000;93.64
1969-09-04;94.98;95.20;93.66;94.20;9380000;94.20
1969-09-03;95.54;96.11;94.38;94.98;8760000;94.98
1969-09-02;95.51;96.31;94.85;95.54;8560000;95.54
1969-08-29;94.89;95.51;94.46;95.51;8850000;95.51
1969-08-28;94.49;95.38;94.04;94.89;7730000;94.89
1969-08-27;94.30;95.16;93.76;94.49;9100000;94.49
1969-08-26;94.93;95.04;93.65;94.30;8910000;94.30
1969-08-25;95.92;96.13;94.52;94.93;8410000;94.93
1969-08-22;95.35;96.43;94.91;95.92;10140000;95.92
1969-08-21;95.07;95.87;94.56;95.35;8420000;95.35
1969-08-20;95.07;95.64;94.25;95.07;9680000;95.07
1969-08-19;94.57;95.18;93.95;95.07;12640000;95.07
1969-08-18;94.00;95.00;93.51;94.57;9420000;94.57
1969-08-15;93.34;94.50;92.92;94.00;10210000;94.00
1969-08-14;92.70;93.87;92.32;93.34;9690000;93.34
1969-08-13;92.63;93.26;91.48;92.70;9910000;92.70
1969-08-12;93.36;93.66;92.19;92.63;7870000;92.63
1969-08-11;93.94;94.24;92.77;93.36;6680000;93.36
1969-08-08;93.99;94.63;93.29;93.94;8760000;93.94
1969-08-07;93.92;94.77;93.17;93.99;9450000;93.99
1969-08-06;93.41;94.76;93.02;93.92;11100000;93.92
1969-08-05;92.99;94.02;92.13;93.41;8940000;93.41
1969-08-04;93.47;94.42;92.29;92.99;10700000;92.99
1969-08-01;91.92;94.19;91.92;93.47;15070000;93.47
1969-07-31;89.96;92.40;89.96;91.83;14160000;91.83
1969-07-30;89.48;90.82;88.04;89.93;15580000;89.93
1969-07-29;90.21;91.56;89.06;89.48;13630000;89.48
1969-07-28;91.91;91.91;89.83;90.21;11800000;90.21
1969-07-25;92.80;93.28;91.54;92.06;9800000;92.06
1969-07-24;93.12;93.87;92.29;92.80;9750000;92.80
1969-07-23;93.52;93.99;92.07;93.12;11680000;93.12
1969-07-22;94.95;95.45;93.15;93.52;9780000;93.52
1969-07-18;95.76;95.84;94.18;94.95;8590000;94.95
1969-07-17;95.18;96.71;95.07;95.76;10450000;95.76
1969-07-16;94.24;95.83;94.22;95.18;10470000;95.18
1969-07-15;94.55;95.00;93.11;94.24;11110000;94.24
1969-07-14;95.77;96.17;94.20;94.55;8310000;94.55
1969-07-11;95.38;96.65;94.81;95.77;11730000;95.77
1969-07-10;96.88;97.04;95.03;95.38;11450000;95.38
1969-07-09;97.63;97.85;96.33;96.88;9320000;96.88
1969-07-08;98.98;98.98;97.15;97.63;9320000;97.63
1969-07-07;99.61;100.33;98.45;99.03;9970000;99.03
1969-07-03;98.94;100.25;98.62;99.61;10110000;99.61
1969-07-02;98.08;99.50;97.81;98.94;11350000;98.94
1969-07-01;97.71;98.66;97.13;98.08;9890000;98.08
1969-06-30;97.33;98.64;96.82;97.71;8640000;97.71
1969-06-27;97.25;98.15;96.65;97.33;9020000;97.33
1969-06-26;97.01;97.91;95.97;97.25;10310000;97.25
1969-06-25;97.32;98.30;96.56;97.01;10490000;97.01
1969-06-24;96.29;98.04;96.29;97.32;11460000;97.32
1969-06-23;96.67;97.17;95.21;96.23;12900000;96.23
1969-06-20;97.24;98.22;96.29;96.67;11360000;96.67
1969-06-19;97.81;98.38;96.61;97.24;11160000;97.24
1969-06-18;97.95;99.20;97.45;97.81;11290000;97.81
1969-06-17;98.32;98.71;96.88;97.95;12210000;97.95
1969-06-16;98.65;99.64;97.91;98.32;10400000;98.32
1969-06-13;98.26;99.51;97.59;98.65;13070000;98.65
1969-06-12;99.05;99.78;97.96;98.26;11790000;98.26
1969-06-11;100.42;100.71;99.02;99.05;13640000;99.05
1969-06-10;101.20;101.76;100.02;100.42;10660000;100.42
1969-06-09;102.12;102.16;100.54;101.20;10650000;101.20
1969-06-06;102.76;103.41;101.68;102.12;12520000;102.12
1969-06-05;102.59;103.45;102.05;102.76;12350000;102.76
1969-06-04;102.63;103.45;102.07;102.59;10840000;102.59
1969-06-03;102.94;103.60;102.09;102.63;11190000;102.63
1969-06-02;103.46;103.75;102.40;102.94;9180000;102.94
1969-05-29;103.26;104.27;102.76;103.46;11770000;103.46
1969-05-28;103.57;103.91;102.29;103.26;11330000;103.26
1969-05-27;104.36;104.68;103.12;103.57;10580000;103.57
1969-05-26;104.59;105.14;103.80;104.36;9030000;104.36
1969-05-23;104.60;105.32;103.78;104.59;10900000;104.59
1969-05-22;104.47;105.66;103.92;104.60;13710000;104.60
1969-05-21;104.04;105.03;103.37;104.47;12100000;104.47
1969-05-20;104.97;105.16;103.56;104.04;10280000;104.04
1969-05-19;105.94;106.15;104.52;104.97;9790000;104.97
1969-05-16;105.85;106.59;105.18;105.94;12280000;105.94
1969-05-15;106.16;106.69;105.08;105.85;11930000;105.85
1969-05-14;105.34;106.74;105.07;106.16;14360000;106.16
1969-05-13;104.89;105.91;104.31;105.34;12910000;105.34
1969-05-12;105.05;105.65;104.12;104.89;10550000;104.89
1969-05-09;105.10;106.01;104.35;105.05;12530000;105.05
1969-05-08;104.67;105.74;104.10;105.10;13050000;105.10
1969-05-07;104.86;105.59;103.83;104.67;14030000;104.67
1969-05-06;104.37;105.50;103.84;104.86;14700000;104.86
1969-05-05;104.00;105.08;103.48;104.37;13300000;104.37
1969-05-02;103.51;104.63;102.98;104.00;13070000;104.00
1969-05-01;103.69;104.59;102.74;103.51;14380000;103.51
1969-04-30;102.79;104.56;102.50;103.69;19350000;103.69
1969-04-29;102.03;103.31;101.51;102.79;14730000;102.79
1969-04-28;101.72;102.65;100.97;102.03;11120000;102.03
1969-04-25;101.27;102.29;100.81;101.72;12480000;101.72
1969-04-24;100.80;101.80;100.21;101.27;11340000;101.27
1969-04-23;100.78;101.77;100.15;100.80;12220000;100.80
1969-04-22;100.56;101.29;99.52;100.78;10250000;100.78
1969-04-21;101.24;101.68;100.11;100.56;10010000;100.56
1969-04-18;100.78;102.09;100.30;101.24;10850000;101.24
1969-04-17;100.63;101.41;99.99;100.78;9360000;100.78
1969-04-16;101.53;101.78;100.16;100.63;9680000;100.63
1969-04-15;101.57;102.15;100.76;101.53;9610000;101.53
1969-04-14;101.65;102.40;101.02;101.57;8990000;101.57
1969-04-11;101.55;102.28;100.97;101.65;10650000;101.65
1969-04-10;101.02;102.22;100.73;101.55;12200000;101.55
1969-04-09;100.14;101.44;99.88;101.02;12530000;101.02
1969-04-08;99.89;101.27;99.35;100.14;9360000;100.14
1969-04-07;100.63;100.63;99.08;99.89;9430000;99.89
1969-04-03;100.78;101.30;99.87;100.68;10300000;100.68
1969-04-02;101.42;101.65;100.61;100.78;10110000;100.78
1969-04-01;101.51;102.45;100.84;101.42;12360000;101.42
1969-03-28;101.10;102.35;100.73;101.51;12430000;101.51
1969-03-27;100.39;101.81;100.03;101.10;11900000;101.10
1969-03-26;99.66;100.86;99.24;100.39;11030000;100.39
1969-03-25;99.50;100.30;98.88;99.66;9820000;99.66
1969-03-24;99.63;100.16;98.85;99.50;8110000;99.50
1969-03-21;99.84;100.37;98.88;99.63;9830000;99.63
1969-03-20;99.21;100.39;98.90;99.84;10260000;99.84
1969-03-19;98.49;99.70;98.03;99.21;9740000;99.21
1969-03-18;98.25;99.41;97.83;98.49;11210000;98.49
1969-03-17;98.00;98.71;97.06;98.25;9150000;98.25
1969-03-14;98.39;98.70;97.40;98.00;8640000;98.00
1969-03-13;99.05;99.35;97.82;98.39;10030000;98.39
1969-03-12;99.32;99.87;98.35;99.05;8720000;99.05
1969-03-11;98.99;100.14;98.58;99.32;9870000;99.32
1969-03-10;98.65;99.47;97.87;98.99;8920000;98.99
1969-03-07;98.70;99.13;97.32;98.65;10830000;98.65
1969-03-06;99.71;99.93;98.11;98.70;9670000;98.70
1969-03-05;99.32;100.48;98.95;99.71;11370000;99.71
1969-03-04;98.38;99.76;98.17;99.32;9320000;99.32
1969-03-03;98.13;99.08;97.61;98.38;8260000;98.38
1969-02-28;98.14;99.02;97.53;98.13;8990000;98.13
1969-02-27;98.45;99.00;97.50;98.14;9670000;98.14
1969-02-26;97.98;99.10;97.36;98.45;9540000;98.45
1969-02-25;98.60;99.65;97.50;97.98;9540000;97.98
1969-02-24;99.79;100.07;98.09;98.60;12730000;98.60
1969-02-20;100.65;101.03;99.29;99.79;10990000;99.79
1969-02-19;101.40;102.07;100.30;100.65;10390000;100.65
1969-02-18;102.27;102.27;100.58;101.40;12490000;101.40
1969-02-17;103.61;104.03;102.04;102.44;11670000;102.44
1969-02-14;103.71;104.37;102.88;103.61;11460000;103.61
1969-02-13;103.63;104.36;102.86;103.71;12010000;103.71
1969-02-12;103.65;104.34;102.98;103.63;11530000;103.63
1969-02-11;103.53;104.61;102.96;103.65;12320000;103.65
1969-02-07;103.54;104.22;102.50;103.53;12780000;103.53
1969-02-06;103.20;104.30;102.55;103.54;12570000;103.54
1969-02-05;102.92;103.84;102.26;103.20;13750000;103.20
1969-02-04;102.89;103.59;102.15;102.92;12550000;102.92
1969-02-03;103.01;103.75;102.04;102.89;12510000;102.89
1969-01-31;102.55;103.64;102.08;103.01;12020000;103.01
1969-01-30;102.51;103.33;101.73;102.55;13010000;102.55
1969-01-29;102.41;103.31;101.69;102.51;11470000;102.51
1969-01-28;102.40;103.30;101.56;102.41;12070000;102.41
1969-01-27;102.38;103.15;101.64;102.40;11020000;102.40
1969-01-24;102.43;103.23;101.71;102.38;12520000;102.38
1969-01-23;101.98;103.21;101.57;102.43;13140000;102.43
1969-01-22;101.63;102.55;101.06;101.98;11480000;101.98
1969-01-21;101.69;102.40;100.88;101.63;10910000;101.63
1969-01-20;102.03;102.60;101.00;101.69;10950000;101.69
1969-01-17;102.18;103.06;101.32;102.03;11590000;102.03
1969-01-16;101.62;103.25;101.27;102.18;13120000;102.18
1969-01-15;101.13;102.48;100.78;101.62;11810000;101.62
1969-01-14;100.44;101.63;99.04;101.13;10700000;101.13
1969-01-13;100.93;101.35;96.63;100.44;11160000;100.44
1969-01-10;101.22;102.14;100.32;100.93;12680000;100.93
1969-01-09;100.80;102.09;100.35;101.22;12100000;101.22
1969-01-08;101.22;102.12;100.14;100.80;13840000;100.80
1969-01-07;102.47;102.68;100.15;101.22;15740000;101.22
1969-01-06;103.99;104.36;101.94;102.47;12720000;102.47
1969-01-03;103.93;104.87;103.17;103.99;12750000;103.99
1969-01-02;103.86;104.85;103.21;103.93;9800000;103.93
1968-12-31;103.80;104.61;102.98;103.86;13130000;103.86
1968-12-30;104.74;104.99;103.09;103.80;12080000;103.80
1968-12-27;105.15;105.87;104.20;104.74;11200000;104.74
1968-12-26;105.04;106.03;104.29;105.15;9670000;105.15
1968-12-24;105.21;105.95;104.37;105.04;11540000;105.04
1968-12-23;106.34;106.68;104.61;105.21;12970000;105.21
1968-12-20;106.97;107.98;105.73;106.34;15910000;106.34
1968-12-19;106.66;107.67;105.10;106.97;19630000;106.97
1968-12-17;107.10;107.65;105.86;106.66;14700000;106.66
1968-12-16;107.58;108.40;106.40;107.10;15950000;107.10
1968-12-13;107.32;108.50;106.56;107.58;16740000;107.58
1968-12-12;107.39;108.43;106.33;107.32;18160000;107.32
1968-12-10;107.66;108.33;106.68;107.39;14500000;107.39
1968-12-09;107.93;108.77;106.89;107.66;15800000;107.66
1968-12-06;107.67;108.91;106.85;107.93;15320000;107.93
1968-12-05;108.02;108.90;106.71;107.67;19330000;107.67
1968-12-03;108.12;108.74;107.02;108.02;15460000;108.02
1968-12-02;108.37;109.37;107.15;108.12;15390000;108.12
1968-11-29;107.76;109.09;107.32;108.37;14390000;108.37
1968-11-27;107.26;108.55;106.59;107.76;16550000;107.76
1968-11-26;106.48;107.93;106.11;107.26;16360000;107.26
1968-11-25;106.30;107.29;105.47;106.48;14490000;106.48
1968-11-22;105.97;106.89;105.21;106.30;15420000;106.30
1968-11-21;106.14;106.77;104.85;105.97;18320000;105.97
1968-11-19;105.92;106.84;105.06;106.14;15120000;106.14
1968-11-18;105.78;106.74;105.05;105.92;14390000;105.92
1968-11-15;105.20;106.44;104.61;105.78;15040000;105.78
1968-11-14;105.13;106.01;104.34;105.20;14900000;105.20
1968-11-13;104.62;105.76;104.08;105.13;15660000;105.13
1968-11-12;103.95;105.28;103.51;104.62;17250000;104.62
1968-11-08;103.50;104.59;102.96;103.95;14250000;103.95
1968-11-07;103.27;104.47;102.31;103.50;11660000;103.50
1968-11-06;103.10;104.41;102.45;103.27;12640000;103.27
1968-11-04;103.06;103.69;101.85;103.10;10930000;103.10
1968-11-01;103.41;104.30;102.36;103.06;14480000;103.06
1968-10-31;103.30;104.57;102.43;103.41;17650000;103.41
1968-10-29;103.90;104.50;102.65;103.30;12340000;103.30
1968-10-28;104.20;104.89;103.16;103.90;11740000;103.90
1968-10-25;103.84;104.81;103.14;104.20;14150000;104.20
1968-10-24;104.57;105.15;103.15;103.84;18300000;103.84
1968-10-22;104.99;105.48;103.84;104.57;13970000;104.57
1968-10-21;104.82;105.78;104.09;104.99;14380000;104.99
1968-10-18;104.01;105.34;103.54;104.82;15130000;104.82
1968-10-17;103.81;105.01;103.81;104.01;21060000;104.01
1968-10-15;103.32;104.25;102.66;103.53;13410000;103.53
1968-10-14;103.18;104.03;102.48;103.32;11980000;103.32
1968-10-11;103.29;103.90;102.39;103.18;12650000;103.18
1968-10-10;103.74;104.30;102.61;103.29;17000000;103.29
1968-10-08;103.70;104.45;102.84;103.74;14000000;103.74
1968-10-07;103.71;104.40;102.93;103.70;12420000;103.70
1968-10-04;103.22;104.35;102.65;103.71;15350000;103.71
1968-10-03;102.86;104.13;102.34;103.22;21110000;103.22
1968-10-01;102.67;103.58;101.80;102.86;15560000;102.86
1968-09-30;102.31;103.29;101.71;102.67;13610000;102.67
1968-09-27;102.36;103.07;101.36;102.31;13860000;102.31
1968-09-26;102.59;103.63;101.59;102.36;18950000;102.36
1968-09-24;102.24;103.21;101.59;102.59;15210000;102.59
1968-09-23;101.66;102.82;101.20;102.24;11550000;102.24
1968-09-20;101.59;102.37;100.81;101.66;14190000;101.66
1968-09-19;101.50;102.53;100.84;101.59;17910000;101.59
1968-09-17;101.24;102.18;100.64;101.50;13920000;101.50
1968-09-16;100.86;102.01;100.33;101.24;13260000;101.24
1968-09-13;100.52;101.53;99.89;100.86;13070000;100.86
1968-09-12;100.73;101.40;99.70;100.52;14630000;100.52
1968-09-10;101.23;101.81;100.12;100.73;11430000;100.73
1968-09-09;101.20;102.09;100.47;101.23;11890000;101.23
1968-09-06;100.74;101.88;100.23;101.20;13180000;101.20
1968-09-05;100.02;101.34;99.63;100.74;12980000;100.74
1968-09-04;99.32;100.49;98.95;100.02;10040000;100.02
1968-09-03;98.86;99.89;98.31;99.32;8620000;99.32
1968-08-30;98.74;99.52;98.20;98.86;8190000;98.86
1968-08-29;98.81;99.49;97.90;98.74;10940000;98.74
1968-08-27;98.94;99.61;98.16;98.81;9710000;98.81
1968-08-26;98.69;99.67;98.29;98.94;9740000;98.94
1968-08-23;98.70;99.57;97.71;98.69;9890000;98.69
1968-08-22;98.96;99.58;97.71;98.70;15140000;98.70
1968-08-20;99.00;99.65;98.08;98.96;10640000;98.96
1968-08-19;98.68;99.64;98.16;99.00;9900000;99.00
1968-08-16;98.07;99.21;97.62;98.68;9940000;98.68
1968-08-15;98.53;99.36;97.48;98.07;12710000;98.07
1968-08-13;98.01;99.20;97.68;98.53;12730000;98.53
1968-08-12;97.01;98.49;96.72;98.01;10420000;98.01
1968-08-09;97.04;97.56;96.11;97.01;8390000;97.01
1968-08-08;97.25;98.32;96.58;97.04;12920000;97.04
1968-08-06;96.85;97.82;96.42;97.25;9620000;97.25
1968-08-05;96.63;97.51;95.95;96.85;8850000;96.85
1968-08-02;97.28;97.47;95.79;96.63;9860000;96.63
1968-08-01;97.74;98.82;96.78;97.28;14380000;97.28
1968-07-30;97.65;98.62;96.84;97.74;10250000;97.74
1968-07-29;98.34;98.78;96.89;97.65;10940000;97.65
1968-07-26;97.94;99.14;97.22;98.34;11690000;98.34
1968-07-25;99.21;100.07;97.43;97.94;16140000;97.94
1968-07-23;99.33;99.93;97.89;99.21;13570000;99.21
1968-07-22;100.46;100.88;98.51;99.33;13530000;99.33
1968-07-19;101.44;101.82;99.80;100.46;14620000;100.46
1968-07-18;101.70;102.65;100.49;101.44;17420000;101.44
1968-07-16;102.26;102.72;100.97;101.70;13380000;101.70
1968-07-15;102.34;103.15;101.44;102.26;13390000;102.26
1968-07-12;102.39;103.24;101.39;102.34;14810000;102.34
1968-07-11;102.23;103.67;101.41;102.39;20290000;102.39
1968-07-09;101.94;102.93;101.19;102.23;16540000;102.23
1968-07-08;100.91;102.76;100.72;101.94;16860000;101.94
1968-07-03;99.74;101.36;99.60;100.91;14390000;100.91
1968-07-02;99.40;100.60;98.60;99.74;13350000;99.74
1968-07-01;99.58;100.33;98.77;99.40;11280000;99.40
1968-06-28;99.98;100.63;98.91;99.58;12040000;99.58
1968-06-27;100.08;101.01;99.11;99.98;15370000;99.98
1968-06-25;100.39;101.10;99.28;100.08;13200000;100.08
1968-06-24;100.66;101.48;99.66;100.39;12320000;100.39
1968-06-21;101.51;101.59;99.80;100.66;13450000;100.66
1968-06-20;99.99;101.60;99.52;101.51;16290000;101.51
1968-06-18;100.13;101.09;99.43;99.99;13630000;99.99
1968-06-17;101.13;101.71;99.43;100.13;12570000;100.13
1968-06-14;101.25;101.82;99.98;101.13;14690000;101.13
1968-06-13;101.66;102.84;100.55;101.25;21350000;101.25
1968-06-11;101.41;102.40;100.74;101.66;15700000;101.66
1968-06-10;101.27;102.25;100.42;101.41;14640000;101.41
1968-06-07;100.65;101.89;100.24;101.27;17320000;101.27
1968-06-06;99.89;101.59;99.50;100.65;16130000;100.65
1968-06-05;100.38;101.13;99.26;99.89;15590000;99.89
1968-06-04;99.99;101.26;99.32;100.38;18030000;100.38
1968-06-03;98.72;100.62;98.72;99.99;14970000;99.99
1968-05-31;97.92;99.40;97.66;98.68;13090000;98.68
1968-05-29;97.62;98.74;97.01;97.92;14100000;97.92
1968-05-28;96.99;98.20;96.41;97.62;13850000;97.62
1968-05-27;97.15;97.81;96.29;96.99;12720000;96.99
1968-05-24;96.97;97.73;96.21;97.15;13300000;97.15
1968-05-23;97.18;97.79;96.38;96.97;12840000;96.97
1968-05-22;96.93;98.17;96.47;97.18;14200000;97.18
1968-05-21;96.45;97.52;95.92;96.93;13160000;96.93
1968-05-20;96.90;97.41;95.80;96.45;11180000;96.45
1968-05-17;97.60;97.81;96.11;96.90;11830000;96.90
1968-05-16;98.07;98.69;97.05;97.60;13030000;97.60
1968-05-15;98.12;98.79;97.32;98.07;13180000;98.07
1968-05-14;98.19;98.85;97.33;98.12;13160000;98.12
1968-05-13;98.50;99.10;97.52;98.19;11860000;98.19
1968-05-10;98.39;99.30;97.76;98.50;11700000;98.50
1968-05-09;98.91;99.47;97.68;98.39;12890000;98.39
1968-05-08;98.90;99.74;98.25;98.91;13120000;98.91
1968-05-07;98.35;99.59;97.86;98.90;13920000;98.90
1968-05-06;98.66;99.11;97.27;98.35;12160000;98.35
1968-05-03;98.59;100.19;97.98;98.66;17990000;98.66
1968-05-02;97.97;99.18;97.53;98.59;14260000;98.59
1968-05-01;97.46;98.61;96.84;97.97;14440000;97.97
1968-04-30;97.97;98.17;96.58;97.46;14380000;97.46
1968-04-29;97.21;98.61;96.81;97.97;12030000;97.97
1968-04-26;96.62;97.83;96.22;97.21;13500000;97.21
1968-04-25;96.92;97.48;95.68;96.62;14430000;96.62
1968-04-24;96.62;97.81;95.98;96.92;14810000;96.92
1968-04-23;95.68;97.48;95.68;96.62;14010000;96.62
1968-04-22;95.85;96.07;94.22;95.32;11720000;95.32
1968-04-19;97.08;97.08;95.15;95.85;14560000;95.85
1968-04-18;96.81;97.89;96.12;97.08;15890000;97.08
1968-04-17;96.62;97.40;95.76;96.81;14090000;96.81
1968-04-16;96.59;97.54;95.72;96.62;15680000;96.62
1968-04-15;96.53;97.36;95.33;96.59;14220000;96.59
1968-04-11;95.67;96.93;94.81;96.53;14230000;96.53
1968-04-10;94.95;97.11;94.74;95.67;20410000;95.67
1968-04-08;93.29;95.45;93.11;94.95;13010000;94.95
1968-04-05;93.84;94.51;92.67;93.29;12570000;93.29
1968-04-04;93.47;94.59;92.63;93.84;14340000;93.84
1968-04-03;92.64;95.13;92.24;93.47;19290000;93.47
1968-04-02;92.48;93.44;91.39;92.64;14520000;92.64
1968-04-01;91.11;93.55;91.11;92.48;17730000;92.48
1968-03-29;89.57;90.92;89.21;90.20;9000000;90.20
1968-03-28;89.66;90.40;89.05;89.57;8000000;89.57
1968-03-27;88.93;90.20;88.88;89.66;8970000;89.66
1968-03-26;88.33;89.50;88.10;88.93;8670000;88.93
1968-03-25;88.42;88.88;87.65;88.33;6700000;88.33
1968-03-22;88.33;89.14;87.50;88.42;9900000;88.42
1968-03-21;88.98;89.48;88.05;88.33;8580000;88.33
1968-03-20;88.99;89.65;88.48;88.98;7390000;88.98
1968-03-19;89.59;90.05;88.61;88.99;7410000;88.99
1968-03-18;89.11;91.09;89.11;89.59;10800000;89.59
1968-03-15;88.32;89.75;87.61;89.10;11210000;89.10
1968-03-14;89.75;89.75;87.81;88.32;11640000;88.32
1968-03-13;90.23;90.71;89.40;90.03;8990000;90.03
1968-03-12;90.13;90.78;89.39;90.23;9250000;90.23
1968-03-11;89.03;90.56;88.81;90.13;9520000;90.13
1968-03-08;89.10;89.57;88.23;89.03;7410000;89.03
1968-03-07;89.26;89.98;88.44;89.10;8630000;89.10
1968-03-06;87.72;89.76;87.64;89.26;9900000;89.26
1968-03-05;87.92;88.72;86.99;87.72;11440000;87.72
1968-03-04;89.11;89.33;87.52;87.92;10590000;87.92
1968-03-01;89.36;89.82;88.58;89.11;8610000;89.11
1968-02-29;90.08;90.24;88.93;89.36;7700000;89.36
1968-02-28;90.53;91.19;89.71;90.08;8020000;90.08
1968-02-27;90.18;90.91;89.56;90.53;7600000;90.53
1968-02-26;90.89;91.08;89.67;90.18;7810000;90.18
1968-02-23;91.24;91.80;90.28;90.89;8810000;90.89
1968-02-21;91.24;91.87;90.54;91.24;9170000;91.24
1968-02-20;90.31;91.34;89.95;91.24;8800000;91.24
1968-02-19;89.96;90.87;89.42;90.31;7270000;90.31
1968-02-16;90.30;90.62;89.28;89.96;9070000;89.96
1968-02-15;90.30;90.30;90.30;90.30;9770000;90.30
1968-02-14;89.07;90.60;88.66;90.14;11390000;90.14
1968-02-13;89.86;90.46;86.73;89.07;10830000;89.07
1968-02-09;90.90;91.00;89.23;89.86;11850000;89.86
1968-02-08;92.06;92.40;90.60;90.90;9660000;90.90
1968-02-07;91.90;92.74;91.48;92.06;8380000;92.06
1968-02-06;91.87;92.52;91.15;91.90;8560000;91.90
1968-02-05;92.27;92.72;91.24;91.87;8980000;91.87
1968-02-02;92.56;93.44;91.69;92.27;10120000;92.27
1968-02-01;92.24;93.14;91.57;92.56;10590000;92.56
1968-01-31;92.89;93.26;91.27;92.24;9410000;92.24
1968-01-30;93.35;93.71;92.18;92.89;10110000;92.89
1968-01-29;93.45;94.38;92.71;93.35;9950000;93.35
1968-01-26;93.30;94.34;92.77;93.45;9980000;93.45
1968-01-25;93.17;94.11;91.96;93.30;12410000;93.30
1968-01-24;93.66;94.12;92.45;93.17;10570000;93.17
1968-01-23;94.03;94.66;92.88;93.66;11030000;93.66
1968-01-22;95.24;95.40;93.55;94.03;10630000;94.03
1968-01-19;95.56;96.22;94.60;95.24;11950000;95.24
1968-01-18;95.64;96.66;95.01;95.56;13840000;95.56
1968-01-17;95.82;96.41;94.78;95.64;12910000;95.64
1968-01-16;96.42;96.91;95.32;95.82;12340000;95.82
1968-01-15;96.72;97.46;95.85;96.42;12640000;96.42
1968-01-12;96.62;97.44;95.87;96.72;13080000;96.72
1968-01-11;96.52;97.82;95.88;96.62;13220000;96.62
1968-01-10;96.50;97.26;95.66;96.52;11670000;96.52
1968-01-09;96.62;97.84;95.89;96.50;13720000;96.50
1968-01-08;95.94;97.40;95.54;96.62;14260000;96.62
1968-01-05;95.36;96.66;94.97;95.94;11880000;95.94
1968-01-04;95.67;96.23;94.31;95.36;13440000;95.36
1968-01-03;96.11;96.95;95.04;95.67;12650000;95.67
1968-01-02;96.47;97.33;95.31;96.11;11080000;96.11
1967-12-29;95.89;96.90;95.85;96.47;14950000;96.47
1967-12-28;95.91;96.65;94.91;95.89;12530000;95.89
1967-12-27;95.26;96.42;94.82;95.91;12690000;95.91
1967-12-26;95.20;96.02;94.61;95.26;9150000;95.26
1967-12-22;95.38;96.11;94.61;95.20;9570000;95.20
1967-12-21;95.15;96.25;94.69;95.38;11010000;95.38
1967-12-20;94.63;95.75;94.17;95.15;11390000;95.15
1967-12-19;94.77;95.41;94.00;94.63;10610000;94.63
1967-12-18;95.03;95.88;94.17;94.77;10320000;94.77
1967-12-15;95.47;96.20;94.51;95.03;11530000;95.03
1967-12-14;95.34;96.35;94.85;95.47;12310000;95.47
1967-12-13;95.01;96.00;94.58;95.34;12480000;95.34
1967-12-12;95.12;95.78;94.34;95.01;10860000;95.01
1967-12-11;95.42;95.99;94.50;95.12;10500000;95.12
1967-12-08;95.53;96.25;94.78;95.42;10710000;95.42
1967-12-07;95.64;96.67;95.04;95.53;12490000;95.53
1967-12-06;95.23;96.16;94.10;95.64;11940000;95.64
1967-12-05;95.10;96.27;94.52;95.23;12940000;95.23
1967-12-04;94.50;95.68;94.09;95.10;11740000;95.10
1967-12-01;94.00;94.95;93.41;94.50;9740000;94.50
1967-11-30;94.47;94.94;93.49;94.00;8860000;94.00
1967-11-29;94.49;95.51;93.85;94.47;11400000;94.47
1967-11-28;94.17;95.08;93.57;94.49;11040000;94.49
1967-11-27;93.90;94.80;93.32;94.17;10040000;94.17
1967-11-24;93.65;94.46;92.74;93.90;9470000;93.90
1967-11-22;93.10;94.41;92.70;93.65;12180000;93.65
1967-11-21;91.65;93.71;91.64;93.10;12300000;93.10
1967-11-20;92.38;92.38;90.09;91.65;12750000;91.65
1967-11-17;92.60;93.62;92.02;92.82;10050000;92.82
1967-11-16;91.76;93.28;91.50;92.60;10570000;92.60
1967-11-15;91.39;92.25;90.44;91.76;10000000;91.76
1967-11-14;91.97;92.49;90.81;91.39;10350000;91.39
1967-11-13;92.21;93.23;91.46;91.97;10130000;91.97
1967-11-10;91.59;92.84;91.29;92.21;9960000;92.21
1967-11-09;91.14;92.25;90.61;91.59;8890000;91.59
1967-11-08;91.48;93.07;90.80;91.14;12630000;91.14
1967-11-06;91.78;92.23;90.39;91.48;10320000;91.48
1967-11-03;92.34;92.90;91.33;91.78;8800000;91.78
1967-11-02;92.71;93.69;91.85;92.34;10760000;92.34
1967-11-01;93.30;94.21;92.45;92.71;10930000;92.71
1967-10-31;94.79;95.25;93.29;93.30;12020000;93.30
1967-10-30;94.96;95.67;94.14;94.79;10250000;94.79
1967-10-27;94.94;95.79;94.31;94.96;9880000;94.96
1967-10-26;94.52;95.56;93.99;94.94;9920000;94.94
1967-10-25;94.42;95.18;93.47;94.52;10300000;94.52
1967-10-24;94.96;95.98;94.05;94.42;11110000;94.42
1967-10-23;95.38;95.69;93.92;94.96;9680000;94.96
1967-10-20;95.43;96.12;94.62;95.38;9510000;95.38
1967-10-19;95.25;96.46;94.86;95.43;11620000;95.43
1967-10-18;95.00;95.82;94.34;95.25;10500000;95.25
1967-10-17;95.25;95.92;94.19;95.00;10290000;95.00
1967-10-16;96.00;96.55;94.85;95.25;9080000;95.25
1967-10-13;95.75;96.69;95.16;96.00;9040000;96.00
1967-10-12;96.37;96.70;95.32;95.75;7770000;95.75
1967-10-11;96.84;97.34;95.70;96.37;11230000;96.37
1967-10-10;97.51;98.15;96.38;96.84;12000000;96.84
1967-10-09;97.26;98.25;96.70;97.51;11180000;97.51
1967-10-06;96.67;97.83;96.34;97.26;9830000;97.26
1967-10-05;96.43;97.25;95.89;96.67;8490000;96.67
1967-10-04;96.65;97.47;95.94;96.43;11520000;96.43
1967-10-03;96.32;97.23;95.75;96.65;10320000;96.65
1967-10-02;96.71;97.25;95.82;96.32;9240000;96.32
1967-09-29;96.79;97.37;96.06;96.71;9710000;96.71
1967-09-28;96.79;97.59;96.19;96.79;10470000;96.79
1967-09-27;96.76;97.54;96.00;96.79;8810000;96.79
1967-09-26;97.59;98.20;96.40;96.76;10940000;96.76
1967-09-25;97.00;98.31;96.74;97.59;10910000;97.59
1967-09-22;96.75;97.61;96.11;97.00;11160000;97.00
1967-09-21;96.13;97.50;95.67;96.75;11290000;96.75
1967-09-20;96.17;96.84;95.39;96.13;10980000;96.13
1967-09-19;96.53;97.35;95.84;96.17;11540000;96.17
1967-09-18;96.27;97.31;95.73;96.53;11620000;96.53
1967-09-15;96.20;96.94;95.47;96.27;10270000;96.27
1967-09-14;95.99;97.40;95.59;96.20;12220000;96.20
1967-09-13;94.99;96.62;94.80;95.99;12400000;95.99
1967-09-12;94.54;95.48;94.01;94.99;9930000;94.99
1967-09-11;94.36;95.26;93.88;94.54;9170000;94.54
1967-09-08;94.33;95.04;93.70;94.36;9300000;94.36
1967-09-07;94.39;94.95;93.70;94.33;8910000;94.33
1967-09-06;94.21;95.06;93.72;94.39;9550000;94.39
1967-09-05;93.68;94.70;93.36;94.21;8320000;94.21
1967-09-01;93.64;94.21;93.00;93.68;7460000;93.68
1967-08-31;93.07;94.19;92.84;93.64;8840000;93.64
1967-08-30;92.88;93.67;92.43;93.07;7200000;93.07
1967-08-29;92.64;93.58;92.17;92.88;6350000;92.88
1967-08-28;92.70;93.31;92.01;92.64;6270000;92.64
1967-08-25;93.09;93.38;92.04;92.70;7250000;92.70
1967-08-24;93.61;94.28;92.77;93.09;7740000;93.09
1967-08-23;93.74;94.15;92.77;93.61;8760000;93.61
1967-08-22;94.25;94.72;93.35;93.74;7940000;93.74
1967-08-21;94.78;95.22;93.79;94.25;8600000;94.25
1967-08-18;94.63;95.40;94.16;94.78;8250000;94.78
1967-08-17;94.55;95.33;94.11;94.63;8790000;94.63
1967-08-16;94.77;95.15;93.93;94.55;8220000;94.55
1967-08-15;94.64;95.54;94.18;94.77;8710000;94.77
1967-08-14;95.15;95.40;94.02;94.64;7990000;94.64
1967-08-11;95.53;95.98;94.62;95.15;8250000;95.15
1967-08-10;95.78;96.67;95.05;95.53;9040000;95.53
1967-08-09;95.69;96.47;95.11;95.78;10100000;95.78
1967-08-08;95.58;96.28;95.04;95.69;8970000;95.69
1967-08-07;95.83;96.43;95.02;95.58;10160000;95.58
1967-08-04;95.66;96.54;95.15;95.83;11130000;95.83
1967-08-03;95.78;96.36;94.42;95.66;13440000;95.66
1967-08-02;95.37;96.64;95.03;95.78;13510000;95.78
1967-08-01;94.75;95.84;94.20;95.37;12290000;95.37
1967-07-31;94.49;95.51;94.01;94.75;10330000;94.75
1967-07-28;94.35;95.23;93.77;94.49;10900000;94.49
1967-07-27;94.06;95.19;93.51;94.35;12400000;94.35
1967-07-26;93.24;94.71;93.12;94.06;11160000;94.06
1967-07-25;93.73;94.56;93.03;93.24;9890000;93.24
1967-07-24;94.04;94.68;92.91;93.73;9580000;93.73
1967-07-21;93.85;94.92;93.24;94.04;11710000;94.04
1967-07-20;93.65;94.49;93.01;93.85;11160000;93.85
1967-07-19;93.50;94.40;92.83;93.65;12850000;93.65
1967-07-18;92.75;94.05;92.30;93.50;12060000;93.50
1967-07-17;92.74;93.53;92.10;92.75;10390000;92.75
1967-07-14;92.42;93.35;91.87;92.74;10880000;92.74
1967-07-13;92.40;93.17;91.82;92.42;10730000;92.42
1967-07-12;92.48;93.10;91.62;92.40;11240000;92.40
1967-07-11;92.05;93.16;91.58;92.48;12400000;92.48
1967-07-10;91.69;92.80;91.11;92.05;12130000;92.05
1967-07-07;91.32;92.28;90.76;91.69;11540000;91.69
1967-07-06;91.36;92.03;90.64;91.32;10170000;91.32
1967-07-05;90.91;91.91;90.56;91.36;9170000;91.36
1967-07-03;90.64;91.32;90.12;90.91;6040000;90.91
1967-06-30;90.64;90.64;90.64;90.64;7850000;90.64
1967-06-29;90.85;90.85;90.85;90.85;9940000;90.85
1967-06-28;91.31;91.31;91.31;91.31;9310000;91.31
1967-06-27;91.30;91.30;91.30;91.30;8780000;91.30
1967-06-26;91.64;91.64;91.64;91.64;9040000;91.64
1967-06-23;92.00;92.00;92.00;92.00;9130000;92.00
1967-06-22;91.97;91.97;91.97;91.97;9550000;91.97
1967-06-21;92.20;92.20;92.20;92.20;9760000;92.20
1967-06-20;92.48;92.48;92.48;92.48;10350000;92.48
1967-06-19;92.51;92.51;92.51;92.51;8570000;92.51
1967-06-16;92.49;93.28;91.98;92.54;10740000;92.54
1967-06-15;92.40;93.26;91.76;92.49;11240000;92.49
1967-06-14;92.62;93.21;91.81;92.40;10960000;92.40
1967-06-13;92.04;93.27;91.65;92.62;11570000;92.62
1967-06-12;91.56;92.66;91.12;92.04;10230000;92.04
1967-06-09;91.40;92.26;90.77;91.56;9650000;91.56
1967-06-08;90.91;91.78;90.24;91.40;8300000;91.40
1967-06-07;90.23;91.75;89.92;90.91;10170000;90.91
1967-06-06;88.48;90.59;88.48;90.23;9230000;90.23
1967-06-05;89.56;89.56;87.19;88.43;11110000;88.43
1967-06-02;90.23;90.90;89.27;89.79;8070000;89.79
1967-06-01;89.08;90.76;88.81;90.23;9040000;90.23
1967-05-31;90.39;90.39;88.71;89.08;8870000;89.08
1967-05-29;90.98;91.22;89.92;90.49;6590000;90.49
1967-05-26;91.19;91.70;90.34;90.98;7810000;90.98
1967-05-25;90.18;91.84;90.04;91.19;8960000;91.19
1967-05-24;91.23;91.36;89.68;90.18;10290000;90.18
1967-05-23;91.67;92.07;90.58;91.23;9810000;91.23
1967-05-22;92.07;92.40;90.83;91.67;9600000;91.67
1967-05-19;92.53;92.86;91.40;92.07;10560000;92.07
1967-05-18;92.78;93.30;91.98;92.53;10290000;92.53
1967-05-17;93.14;93.75;92.34;92.78;9560000;92.78
1967-05-16;92.71;93.85;92.19;93.14;10700000;93.14
1967-05-15;93.48;93.75;92.27;92.71;8320000;92.71
1967-05-12;93.75;94.45;92.94;93.48;10470000;93.48
1967-05-11;93.35;94.37;92.90;93.75;10320000;93.75
1967-05-10;93.60;94.04;92.51;93.35;10410000;93.35
1967-05-09;94.58;95.25;93.28;93.60;10830000;93.60
1967-05-08;94.44;95.22;93.71;94.58;10330000;94.58
1967-05-05;94.32;95.14;93.64;94.44;10630000;94.44
1967-05-04;93.91;94.92;93.41;94.32;12850000;94.32
1967-05-03;93.67;94.48;92.94;93.91;11550000;93.91
1967-05-02;93.84;94.42;93.06;93.67;10260000;93.67
1967-05-01;94.01;94.60;93.08;93.84;9410000;93.84
1967-04-28;93.81;94.77;93.33;94.01;11200000;94.01
1967-04-27;93.02;94.25;92.41;93.81;10250000;93.81
1967-04-26;93.11;93.99;92.44;93.02;10560000;93.02
1967-04-25;92.62;93.57;92.01;93.11;10420000;93.11
1967-04-24;92.30;93.45;91.78;92.62;10250000;92.62
1967-04-21;92.11;92.90;91.48;92.30;10210000;92.30
1967-04-20;91.94;92.61;91.21;92.11;9690000;92.11
1967-04-19;91.86;92.73;91.25;91.94;10860000;91.94
1967-04-18;91.07;92.31;90.70;91.86;10500000;91.86
1967-04-17;90.43;91.78;90.18;91.07;9070000;91.07
1967-04-14;89.46;91.08;89.26;90.43;8810000;90.43
1967-04-13;88.78;89.86;88.49;89.46;7610000;89.46
1967-04-12;88.88;89.54;88.36;88.78;7750000;88.78
1967-04-11;88.24;89.34;87.92;88.88;7710000;88.88
1967-04-10;89.32;89.32;87.86;88.24;8110000;88.24
1967-04-07;89.94;90.60;88.96;89.36;9090000;89.36
1967-04-06;89.79;90.74;89.44;89.94;9470000;89.94
1967-04-05;89.22;90.31;88.92;89.79;8810000;89.79
1967-04-04;89.24;89.93;88.45;89.22;8750000;89.22
1967-04-03;90.20;90.37;88.76;89.24;8530000;89.24
1967-03-31;90.70;91.15;89.75;90.20;8130000;90.20
1967-03-30;90.73;91.32;90.06;90.70;8340000;90.70
1967-03-29;90.91;91.45;90.17;90.73;8430000;90.73
1967-03-28;90.87;91.62;90.23;90.91;8940000;90.91
1967-03-27;90.94;91.72;90.19;90.87;9260000;90.87
1967-03-23;90.25;91.51;90.04;90.94;9500000;90.94
1967-03-22;90.00;90.70;89.17;90.25;8820000;90.25
1967-03-21;90.20;91.05;89.52;90.00;9820000;90.00
1967-03-20;90.25;90.87;89.35;90.20;9040000;90.20
1967-03-17;90.09;90.84;89.39;90.25;10020000;90.25
1967-03-16;89.19;90.66;89.09;90.09;12170000;90.09
1967-03-15;88.35;89.60;88.00;89.19;10830000;89.19
1967-03-14;88.43;89.07;87.58;88.35;10260000;88.35
1967-03-13;88.89;89.41;87.93;88.43;9910000;88.43
1967-03-10;88.53;90.37;88.46;88.89;14900000;88.89
1967-03-09;88.27;89.04;87.70;88.53;10480000;88.53
1967-03-08;88.16;89.10;87.69;88.27;11070000;88.27
1967-03-07;88.10;88.74;87.34;88.16;9810000;88.16
1967-03-06;88.29;89.08;87.46;88.10;10400000;88.10
1967-03-03;88.16;89.00;87.51;88.29;11100000;88.29
1967-03-02;87.68;88.85;87.39;88.16;11900000;88.16
1967-03-01;86.78;88.36;86.67;87.68;11510000;87.68
1967-02-28;86.46;87.26;85.61;86.78;9970000;86.78
1967-02-27;87.41;87.61;85.68;86.46;10210000;86.46
1967-02-24;87.45;88.16;86.76;87.41;9830000;87.41
1967-02-23;87.34;88.00;86.64;87.45;10010000;87.45
1967-02-21;87.40;88.01;86.80;87.34;9030000;87.34
1967-02-20;87.89;88.13;86.65;87.40;8640000;87.40
1967-02-17;87.86;88.40;87.25;87.89;8530000;87.89
1967-02-16;88.27;88.80;87.43;87.86;8490000;87.86
1967-02-15;88.17;89.00;87.62;88.27;10480000;88.27
1967-02-14;87.58;88.74;87.15;88.17;9760000;88.17
1967-02-13;87.63;88.19;86.95;87.58;7570000;87.58
1967-02-10;87.36;88.19;86.79;87.63;8850000;87.63
1967-02-09;87.72;88.57;86.99;87.36;10970000;87.36
1967-02-08;86.95;88.25;86.64;87.72;11220000;87.72
1967-02-07;87.18;87.52;86.48;86.95;6400000;86.95
1967-02-06;87.36;87.98;86.61;87.18;10680000;87.18
1967-02-03;86.73;87.97;86.51;87.36;12010000;87.36
1967-02-02;86.43;87.31;85.87;86.73;10720000;86.73
1967-02-01;86.61;87.04;85.68;86.43;9580000;86.43
1967-01-31;86.66;87.46;86.06;86.61;11540000;86.61
1967-01-30;86.16;87.35;85.84;86.66;10250000;86.66
1967-01-27;85.81;86.76;85.34;86.16;9690000;86.16
1967-01-26;85.85;86.66;84.87;85.81;10630000;85.81
1967-01-25;86.51;87.02;85.47;85.85;10260000;85.85
1967-01-24;86.39;87.00;85.29;86.51;10430000;86.51
1967-01-23;86.07;88.17;85.64;86.39;10830000;86.39
1967-01-20;85.82;86.47;85.07;86.07;9530000;86.07
1967-01-19;85.79;86.61;85.17;85.82;10230000;85.82
1967-01-18;85.24;86.36;84.90;85.79;11390000;85.79
1967-01-17;84.31;85.81;84.03;85.24;11590000;85.24
1967-01-16;84.53;85.28;83.73;84.31;10280000;84.31
1967-01-13;83.91;84.90;83.10;84.53;10000000;84.53
1967-01-12;83.47;84.80;83.11;83.91;12830000;83.91
1967-01-11;82.81;83.92;81.37;83.47;13230000;83.47
1967-01-10;82.81;83.54;82.22;82.81;8120000;82.81
1967-01-09;82.18;83.31;81.78;82.81;9180000;82.81
1967-01-06;81.60;82.79;81.32;82.18;7830000;82.18
1967-01-05;80.55;81.93;80.50;81.60;7320000;81.60
1967-01-04;80.38;81.01;79.43;80.55;6150000;80.55
1967-01-03;80.33;81.61;79.59;80.38;6100000;80.38
1966-12-30;80.37;81.14;79.66;80.33;11330000;80.33
1966-12-29;80.61;81.08;79.84;80.37;7900000;80.37
1966-12-28;81.00;81.67;80.29;80.61;7160000;80.61
1966-12-27;81.47;81.84;80.55;81.00;6280000;81.00
1966-12-23;81.69;82.22;80.97;81.47;7350000;81.47
1966-12-22;81.38;82.34;81.00;81.69;8560000;81.69
1966-12-21;80.96;81.91;80.42;81.38;7690000;81.38
1966-12-20;81.27;81.69;80.31;80.96;6830000;80.96
1966-12-19;81.58;82.06;80.56;81.27;7340000;81.27
1966-12-16;81.64;82.21;80.94;81.58;6980000;81.58
1966-12-15;82.64;82.89;81.20;81.64;7150000;81.64
1966-12-14;82.73;83.35;81.97;82.64;7470000;82.64
1966-12-13;83.00;83.88;82.28;82.73;9650000;82.73
1966-12-12;82.14;83.54;81.94;83.00;9530000;83.00
1966-12-09;82.05;82.68;81.33;82.14;7650000;82.14
1966-12-08;81.72;82.72;81.34;82.05;8370000;82.05
1966-12-07;80.84;82.19;80.59;81.72;8980000;81.72
1966-12-06;80.24;81.29;79.95;80.84;7670000;80.84
1966-12-05;80.13;80.81;79.60;80.24;6470000;80.24
1966-12-02;80.08;81.29;79.49;80.13;6230000;80.13
1966-12-01;80.45;81.04;79.66;80.08;8480000;80.08
1966-11-30;80.42;80.90;79.62;80.45;7230000;80.45
1966-11-29;80.71;81.16;79.94;80.42;7320000;80.42
1966-11-28;80.85;81.38;79.96;80.71;7630000;80.71
1966-11-25;80.21;81.37;79.83;80.85;6810000;80.85
1966-11-23;79.67;80.85;79.39;80.21;7350000;80.21
1966-11-22;80.09;80.32;78.89;79.67;6430000;79.67
1966-11-21;81.09;81.09;79.51;80.09;7450000;80.09
1966-11-18;81.80;82.05;80.79;81.26;6900000;81.26
1966-11-17;82.37;82.80;81.24;81.80;8900000;81.80
1966-11-16;81.69;83.01;81.55;82.37;10350000;82.37
1966-11-15;81.37;82.07;80.82;81.69;7190000;81.69
1966-11-14;81.94;82.18;80.81;81.37;6540000;81.37
1966-11-11;81.89;82.36;81.27;81.94;6690000;81.94
1966-11-10;81.38;82.43;81.00;81.89;8870000;81.89
1966-11-09;80.73;81.90;80.46;81.38;8390000;81.38
1966-11-07;80.81;81.48;80.16;80.73;6120000;80.73
1966-11-04;80.56;81.21;79.64;80.81;6530000;80.81
1966-11-03;80.88;81.35;79.98;80.56;5860000;80.56
1966-11-02;80.81;81.68;80.30;80.88;6740000;80.88
1966-11-01;80.20;81.18;79.79;80.81;6480000;80.81
1966-10-31;80.24;80.82;79.34;80.20;5860000;80.20
1966-10-28;80.23;80.91;79.49;80.24;6420000;80.24
1966-10-27;79.58;80.72;79.28;80.23;6670000;80.23
1966-10-26;78.90;80.29;78.70;79.58;6760000;79.58
1966-10-25;78.42;79.22;77.56;78.90;6190000;78.90
1966-10-24;78.19;79.20;77.73;78.42;5780000;78.42
1966-10-21;77.84;78.62;77.16;78.19;5690000;78.19
1966-10-20;78.05;78.96;77.26;77.84;6840000;77.84
1966-10-19;78.68;79.34;77.54;78.05;6460000;78.05
1966-10-18;77.47;79.08;77.35;78.68;7180000;78.68
1966-10-17;76.60;78.41;76.48;77.47;5570000;77.47
1966-10-14;76.89;77.80;76.01;76.60;5610000;76.60
1966-10-13;77.04;78.45;76.22;76.89;8680000;76.89
1966-10-12;74.91;77.26;74.37;77.04;6910000;77.04
1966-10-11;74.53;76.20;74.22;74.91;8430000;74.91
1966-10-10;73.20;74.97;72.28;74.53;9630000;74.53
1966-10-07;74.05;74.67;72.77;73.20;8140000;73.20
1966-10-06;74.69;75.09;73.47;74.05;8110000;74.05
1966-10-05;75.10;76.10;74.31;74.69;5880000;74.69
1966-10-04;74.90;75.76;73.91;75.10;8910000;75.10
1966-10-03;76.56;76.98;74.71;74.90;6490000;74.90
1966-09-30;76.31;77.09;75.45;76.56;6170000;76.56
1966-09-29;77.11;77.28;75.85;76.31;6110000;76.31
1966-09-28;78.10;78.36;76.70;77.11;5990000;77.11
1966-09-27;77.86;79.10;77.56;78.10;6300000;78.10
1966-09-26;77.67;78.34;76.88;77.86;4960000;77.86
1966-09-23;77.94;78.43;77.15;77.67;4560000;77.67
1966-09-22;77.71;78.41;76.81;77.94;5760000;77.94
1966-09-21;79.04;79.15;77.52;77.71;5360000;77.71
1966-09-20;79.59;79.90;78.57;79.04;4560000;79.04
1966-09-19;79.99;80.50;79.02;79.59;4920000;79.59
1966-09-16;80.08;80.81;79.33;79.99;5150000;79.99
1966-09-15;79.13;80.60;78.87;80.08;6140000;80.08
1966-09-14;78.32;79.43;77.73;79.13;6250000;79.13
1966-09-13;77.91;79.16;77.66;78.32;6870000;78.32
1966-09-12;76.47;78.34;76.47;77.91;6780000;77.91
1966-09-09;76.05;76.94;75.43;76.29;5280000;76.29
1966-09-08;76.37;76.95;75.03;76.05;6660000;76.05
1966-09-07;76.96;77.26;75.77;76.37;5530000;76.37
1966-09-06;77.42;78.16;76.55;76.96;4350000;76.96
1966-09-02;77.70;78.20;76.27;77.42;6080000;77.42
1966-09-01;77.10;78.50;76.66;77.70;6250000;77.70
1966-08-31;75.98;78.06;75.98;77.10;8690000;77.10
1966-08-30;74.53;76.46;73.91;75.86;11230000;75.86
1966-08-29;76.24;76.24;74.18;74.53;10900000;74.53
1966-08-26;77.85;77.85;76.10;76.41;8190000;76.41
1966-08-25;79.07;79.79;77.80;78.06;6760000;78.06
1966-08-24;78.11;79.63;77.92;79.07;7050000;79.07
1966-08-23;78.24;79.24;77.05;78.11;9830000;78.11
1966-08-22;79.62;79.88;77.58;78.24;8690000;78.24
1966-08-19;80.16;80.78;79.24;79.62;7070000;79.62
1966-08-18;81.18;81.38;79.60;80.16;7000000;80.16
1966-08-17;81.63;81.90;80.53;81.18;6630000;81.18
1966-08-16;82.71;82.71;81.26;81.63;6130000;81.63
1966-08-15;83.17;83.69;82.39;82.74;5680000;82.74
1966-08-12;83.02;83.88;82.57;83.17;6230000;83.17
1966-08-11;83.11;83.53;82.34;83.02;5700000;83.02
1966-08-10;83.49;83.83;82.69;83.11;5290000;83.11
1966-08-09;83.75;84.36;83.04;83.49;6270000;83.49
1966-08-08;84.00;84.31;82.97;83.75;4900000;83.75
1966-08-05;83.93;84.70;83.43;84.00;5500000;84.00
1966-08-04;83.15;84.54;83.07;83.93;6880000;83.93
1966-08-03;82.33;83.71;82.30;83.15;6220000;83.15
1966-08-02;82.31;83.04;81.77;82.33;5710000;82.33
1966-08-01;83.50;83.50;81.98;82.31;5880000;82.31
1966-07-29;83.77;84.30;83.10;83.60;5150000;83.60
1966-07-28;84.10;84.76;83.44;83.77;5680000;83.77
1966-07-27;83.70;84.83;83.50;84.10;6070000;84.10
1966-07-26;83.83;84.67;83.05;83.70;7610000;83.70
1966-07-25;85.41;85.57;83.56;83.83;7050000;83.83
1966-07-22;85.52;86.11;84.93;85.41;6540000;85.41
1966-07-21;85.51;86.24;84.77;85.52;6200000;85.52
1966-07-20;86.33;86.64;85.26;85.51;5470000;85.51
1966-07-19;86.99;87.17;85.75;86.33;5960000;86.33
1966-07-18;87.08;87.59;86.42;86.99;5110000;86.99
1966-07-15;86.82;87.68;86.44;87.08;6090000;87.08
1966-07-14;86.30;87.34;85.85;86.82;5950000;86.82
1966-07-13;86.88;87.06;85.83;86.30;5580000;86.30
1966-07-12;87.45;87.78;86.45;86.88;5180000;86.88
1966-07-11;87.61;88.19;86.97;87.45;6200000;87.45
1966-07-08;87.38;88.04;86.85;87.61;6100000;87.61
1966-07-07;87.06;88.02;86.67;87.38;7200000;87.38
1966-07-06;85.82;87.38;85.57;87.06;6860000;87.06
1966-07-05;85.61;86.41;85.09;85.82;4610000;85.82
1966-07-01;84.74;86.08;84.74;85.61;5200000;85.61
1966-06-30;84.86;85.37;83.75;84.74;7250000;84.74
1966-06-29;85.67;85.98;84.52;84.86;6020000;84.86
1966-06-28;86.08;86.43;85.00;85.67;6280000;85.67
1966-06-27;86.58;87.31;85.77;86.08;5330000;86.08
1966-06-24;86.50;87.31;85.68;86.58;7140000;86.58
1966-06-23;86.85;87.73;86.11;86.50;7930000;86.50
1966-06-22;86.71;87.38;86.15;86.85;7800000;86.85
1966-06-21;86.48;87.28;86.07;86.71;6860000;86.71
1966-06-20;86.51;87.03;85.84;86.48;5940000;86.48
1966-06-17;86.47;87.11;85.89;86.51;6580000;86.51
1966-06-16;86.73;87.18;85.88;86.47;6870000;86.47
1966-06-15;87.07;87.74;86.33;86.73;8520000;86.73
1966-06-14;86.83;87.57;86.02;87.07;7600000;87.07
1966-06-13;86.44;87.59;86.20;86.83;7600000;86.83
1966-06-10;85.50;86.97;85.32;86.44;8240000;86.44
1966-06-09;84.93;85.98;84.56;85.50;5810000;85.50
1966-06-08;84.83;85.43;84.31;84.93;4580000;84.93
1966-06-07;85.42;85.54;84.25;84.83;5040000;84.83
1966-06-06;86.06;86.28;85.03;85.42;4260000;85.42
1966-06-03;85.96;86.55;85.43;86.06;4430000;86.06
1966-06-02;86.10;86.85;85.55;85.96;5080000;85.96
1966-06-01;86.13;86.65;85.28;86.10;5290000;86.10
1966-05-31;87.33;87.65;85.80;86.13;5770000;86.13
1966-05-27;87.07;87.42;86.43;87.33;4790000;87.33
1966-05-26;87.07;87.88;86.54;87.07;6080000;87.07
1966-05-25;86.77;87.48;86.05;87.07;5820000;87.07
1966-05-24;86.20;87.70;86.19;86.77;7210000;86.77
1966-05-23;85.43;86.91;85.29;86.20;7080000;86.20
1966-05-20;85.02;85.79;84.21;85.43;6430000;85.43
1966-05-19;85.12;86.33;84.54;85.02;8640000;85.02
1966-05-18;83.72;85.64;83.72;85.12;9310000;85.12
1966-05-17;84.41;85.03;83.18;83.63;9870000;83.63
1966-05-16;85.47;86.04;83.90;84.41;9260000;84.41
1966-05-13;86.23;86.31;84.77;85.47;8970000;85.47
1966-05-12;87.23;87.49;85.72;86.23;8210000;86.23
1966-05-11;87.08;88.38;86.84;87.23;7470000;87.23
1966-05-10;86.32;87.88;86.12;87.08;9050000;87.08
1966-05-09;87.84;87.96;85.92;86.32;9290000;86.32
1966-05-06;87.93;88.52;86.24;87.84;13110000;87.84
1966-05-05;89.39;89.77;87.60;87.93;10100000;87.93
1966-05-04;89.85;90.11;88.54;89.39;9740000;89.39
1966-05-03;90.90;91.10;89.46;89.85;8020000;89.85
1966-05-02;91.06;91.75;90.43;90.90;7070000;90.90
1966-04-29;91.13;91.86;90.57;91.06;7220000;91.06
1966-04-28;91.76;91.92;90.24;91.13;8310000;91.13
1966-04-27;91.99;92.49;91.10;91.76;7950000;91.76
1966-04-26;92.08;92.77;91.47;91.99;7540000;91.99
1966-04-25;92.27;92.86;91.41;92.08;7270000;92.08
1966-04-22;92.42;92.87;91.60;92.27;8650000;92.27
1966-04-21;92.08;93.02;91.78;92.42;9560000;92.42
1966-04-20;91.57;92.75;91.34;92.08;10530000;92.08
1966-04-19;91.58;92.31;90.89;91.57;8820000;91.57
1966-04-18;91.99;92.59;91.09;91.58;9150000;91.58
1966-04-15;91.87;92.75;91.28;91.99;10270000;91.99
1966-04-14;91.54;92.80;91.12;91.87;12980000;91.87
1966-04-13;91.45;92.81;90.73;91.54;10440000;91.54
1966-04-12;91.79;92.51;90.92;91.45;10500000;91.45
1966-04-11;91.76;92.60;91.08;91.79;9310000;91.79
1966-04-07;91.56;92.42;90.99;91.76;9650000;91.76
1966-04-06;91.31;92.10;90.77;91.56;9040000;91.56
1966-04-05;90.76;92.04;90.47;91.31;10560000;91.31
1966-04-04;89.94;91.33;89.92;90.76;9360000;90.76
1966-04-01;89.23;90.37;88.96;89.94;9050000;89.94
1966-03-31;88.78;89.70;88.47;89.23;6690000;89.23
1966-03-30;89.27;89.57;88.31;88.78;7980000;88.78
1966-03-29;89.62;90.04;88.63;89.27;8300000;89.27
1966-03-28;89.54;90.41;89.15;89.62;8640000;89.62
1966-03-25;89.29;90.14;88.96;89.54;7750000;89.54
1966-03-24;89.13;89.80;88.68;89.29;7880000;89.29
1966-03-23;89.46;89.80;88.69;89.13;6720000;89.13
1966-03-22;89.20;90.28;89.01;89.46;8910000;89.46
1966-03-21;88.53;89.73;88.40;89.20;7230000;89.20
1966-03-18;88.17;89.23;87.82;88.53;6450000;88.53
1966-03-17;87.86;88.60;87.45;88.17;5460000;88.17
1966-03-16;87.35;88.55;87.09;87.86;7330000;87.86
1966-03-15;87.85;88.20;86.69;87.35;9440000;87.35
1966-03-14;88.85;88.92;87.56;87.85;7400000;87.85
1966-03-11;88.96;89.63;88.30;88.85;7000000;88.85
1966-03-10;88.96;90.14;88.36;88.96;10310000;88.96
1966-03-09;88.18;89.21;87.96;88.96;7980000;88.96
1966-03-08;88.04;89.00;87.17;88.18;10120000;88.18
1966-03-07;89.24;89.39;87.67;88.04;9370000;88.04
1966-03-04;89.47;90.25;88.72;89.24;9000000;89.24
1966-03-03;89.15;90.03;88.26;89.47;9900000;89.47
1966-03-02;90.06;90.65;88.70;89.15;10470000;89.15
1966-03-01;91.22;91.65;89.76;90.06;11030000;90.06
1966-02-28;91.14;91.95;90.65;91.22;9910000;91.22
1966-02-25;90.89;91.88;90.43;91.14;8140000;91.14
1966-02-24;91.48;91.81;90.45;90.89;7860000;90.89
1966-02-23;91.87;92.21;90.99;91.48;8080000;91.48
1966-02-21;92.41;92.83;91.35;91.87;8510000;91.87
1966-02-18;92.66;93.14;91.80;92.41;8470000;92.41
1966-02-17;93.16;93.58;92.11;92.66;9330000;92.66
1966-02-16;93.17;93.74;92.63;93.16;9180000;93.16
1966-02-15;93.53;94.04;92.67;93.17;8750000;93.17
1966-02-14;93.81;94.40;93.15;93.53;8360000;93.53
1966-02-11;93.83;94.52;93.25;93.81;8150000;93.81
1966-02-10;94.06;94.70;93.32;93.83;9790000;93.83
1966-02-09;93.55;94.72;93.29;94.06;9760000;94.06
1966-02-08;93.59;94.29;92.58;93.55;10560000;93.55
1966-02-07;93.26;94.22;92.85;93.59;8000000;93.59
1966-02-04;92.65;93.70;92.33;93.26;7560000;93.26
1966-02-03;92.53;93.67;92.11;92.65;8160000;92.65
1966-02-02;92.16;92.91;91.32;92.53;8130000;92.53
1966-02-01;92.88;93.36;91.61;92.16;9090000;92.16
1966-01-31;93.31;93.77;92.46;92.88;7800000;92.88
1966-01-28;93.67;94.15;92.84;93.31;9000000;93.31
1966-01-27;93.70;94.34;93.09;93.67;8970000;93.67
1966-01-26;93.85;94.53;93.18;93.70;9910000;93.70
1966-01-25;93.71;94.56;93.24;93.85;9300000;93.85
1966-01-24;93.47;94.41;93.07;93.71;8780000;93.71
1966-01-21;93.36;93.97;92.60;93.47;9180000;93.47
1966-01-20;93.69;94.33;92.87;93.36;8670000;93.36
1966-01-19;93.95;94.62;93.16;93.69;10230000;93.69
1966-01-18;93.77;94.64;93.23;93.95;9790000;93.95
1966-01-17;93.50;94.46;93.10;93.77;9430000;93.77
1966-01-14;93.36;94.14;92.98;93.50;9210000;93.50
1966-01-13;93.19;94.00;92.68;93.36;8860000;93.36
1966-01-12;93.41;93.98;92.80;93.19;8530000;93.19
1966-01-11;93.33;94.05;92.85;93.41;8910000;93.41
1966-01-10;93.14;93.94;92.75;93.33;7720000;93.33
1966-01-07;93.06;93.64;92.47;93.14;7600000;93.14
1966-01-06;92.85;93.65;92.51;93.06;7880000;93.06
1966-01-05;92.26;93.33;91.99;92.85;9650000;92.85
1966-01-04;92.18;93.04;91.68;92.26;7540000;92.26
1966-01-03;92.43;92.87;91.63;92.18;5950000;92.18
1965-12-31;92.20;93.05;91.82;92.43;7240000;92.43
1965-12-30;91.81;92.68;91.52;92.20;7060000;92.20
1965-12-29;91.53;92.39;91.14;91.81;7610000;91.81
1965-12-28;91.52;92.13;90.63;91.53;7280000;91.53
1965-12-27;92.19;92.71;91.28;91.52;5950000;91.52
1965-12-23;92.29;92.89;91.58;92.19;6870000;92.19
1965-12-22;92.01;93.07;91.53;92.29;9720000;92.29
1965-12-21;91.65;92.59;91.24;92.01;8230000;92.01
1965-12-20;92.08;92.35;91.09;91.65;7350000;91.65
1965-12-17;92.12;92.76;91.51;92.08;9490000;92.08
1965-12-16;92.02;92.95;91.53;92.12;9950000;92.12
1965-12-15;91.88;92.67;91.30;92.02;9560000;92.02
1965-12-14;91.83;92.59;91.35;91.88;9920000;91.88
1965-12-13;91.80;92.45;91.27;91.83;8660000;91.83
1965-12-10;91.56;92.28;91.14;91.80;8740000;91.80
1965-12-09;91.28;92.06;90.87;91.56;9150000;91.56
1965-12-08;91.39;92.24;90.84;91.28;10120000;91.28
1965-12-07;90.59;92.00;90.45;91.39;9340000;91.39
1965-12-06;91.20;91.20;89.20;90.59;11440000;90.59
1965-12-03;91.21;91.80;90.53;91.27;8160000;91.27
1965-12-02;91.50;91.95;90.69;91.21;9070000;91.21
1965-12-01;91.61;92.26;91.02;91.50;10140000;91.50
1965-11-30;91.80;92.14;90.81;91.61;8990000;91.61
1965-11-29;92.03;92.60;91.37;91.80;8760000;91.80
1965-11-26;91.94;92.65;91.39;92.03;6970000;92.03
1965-11-24;91.78;92.50;91.14;91.94;7870000;91.94
1965-11-23;91.64;92.24;91.15;91.78;7150000;91.78
1965-11-22;92.24;92.48;91.16;91.64;6370000;91.64
1965-11-19;92.22;92.88;91.73;92.24;6850000;92.24
1965-11-18;92.60;92.94;91.72;92.22;7040000;92.22
1965-11-17;92.41;93.28;91.85;92.60;9120000;92.60
1965-11-16;92.63;93.13;91.90;92.41;8380000;92.41
1965-11-15;92.55;93.30;92.04;92.63;8310000;92.63
1965-11-12;92.11;93.07;91.83;92.55;7780000;92.55
1965-11-11;91.83;92.37;91.31;92.11;5430000;92.11
1965-11-10;91.93;92.40;91.35;91.83;4860000;91.83
1965-11-09;92.23;92.65;91.47;91.93;6680000;91.93
1965-11-08;92.37;92.97;91.63;92.23;7000000;92.23
1965-11-05;92.46;92.92;91.78;92.37;7310000;92.37
1965-11-04;92.31;93.07;91.90;92.46;8380000;92.46
1965-11-03;92.23;92.79;91.62;92.31;7520000;92.31
1965-11-01;92.42;92.92;91.73;92.23;6340000;92.23
1965-10-29;92.21;92.94;91.83;92.42;7240000;92.42
1965-10-28;92.51;92.95;91.60;92.21;7230000;92.21
1965-10-27;92.20;93.19;91.95;92.51;7670000;92.51
1965-10-26;91.67;92.63;91.36;92.20;6750000;92.20
1965-10-25;91.98;92.72;91.34;91.67;7090000;91.67
1965-10-22;91.94;92.74;91.54;91.98;8960000;91.98
1965-10-21;91.78;92.51;91.42;91.94;9170000;91.94
1965-10-20;91.80;92.26;91.12;91.78;8200000;91.78
1965-10-19;91.68;92.45;91.35;91.80;8620000;91.80
1965-10-18;91.38;92.28;91.06;91.68;8180000;91.68
1965-10-15;91.19;92.09;90.76;91.38;7470000;91.38
1965-10-14;91.34;91.90;90.71;91.19;8580000;91.19
1965-10-13;91.35;91.81;90.73;91.34;9470000;91.34
1965-10-12;91.37;91.94;90.83;91.35;9470000;91.35
1965-10-11;90.85;91.84;90.73;91.37;9600000;91.37
1965-10-08;90.47;91.31;90.30;90.85;7670000;90.85
1965-10-07;90.54;91.09;90.09;90.47;6670000;90.47
1965-10-06;90.63;90.94;89.74;90.54;6010000;90.54
1965-10-05;90.08;91.02;89.92;90.63;6980000;90.63
1965-10-04;89.90;90.56;89.47;90.08;5590000;90.08
1965-10-01;89.96;90.48;89.30;89.90;7470000;89.90
1965-09-30;90.02;90.71;89.51;89.96;8670000;89.96
1965-09-29;90.43;91.11;89.56;90.02;10600000;90.02
1965-09-28;90.65;91.13;89.83;90.43;8750000;90.43
1965-09-27;90.65;90.65;90.65;90.65;6820000;90.65
1965-09-24;89.86;90.47;89.13;90.02;7810000;90.02
1965-09-23;90.22;90.78;89.43;89.86;9990000;89.86
1965-09-22;89.81;90.67;89.45;90.22;8290000;90.22
1965-09-21;90.08;90.66;89.43;89.81;7750000;89.81
1965-09-20;90.05;90.67;89.51;90.08;7040000;90.08
1965-09-17;90.02;90.47;89.32;90.05;6610000;90.05
1965-09-16;90.02;90.02;90.02;90.02;7410000;90.02
1965-09-15;89.03;89.96;88.71;89.52;6220000;89.52
1965-09-14;89.38;90.01;88.69;89.03;7830000;89.03
1965-09-13;89.12;89.91;88.77;89.38;7020000;89.38
1965-09-10;88.89;89.85;88.41;89.12;6650000;89.12
1965-09-09;88.66;89.46;88.35;88.89;7360000;88.89
1965-09-08;88.36;89.08;87.93;88.66;6240000;88.66
1965-09-07;88.06;88.77;87.76;88.36;5750000;88.36
1965-09-03;87.65;88.41;87.52;88.06;6010000;88.06
1965-09-02;87.17;87.96;86.98;87.65;6470000;87.65
1965-09-01;87.17;87.63;86.69;87.17;5890000;87.17
1965-08-31;87.21;87.79;86.78;87.17;5170000;87.17
1965-08-30;87.20;87.64;86.76;87.21;4400000;87.21
1965-08-27;87.14;87.74;86.81;87.20;5570000;87.20
1965-08-26;86.81;87.52;86.40;87.14;6010000;87.14
1965-08-25;86.71;87.27;86.33;86.81;6240000;86.81
1965-08-24;86.56;87.19;86.22;86.71;4740000;86.71
1965-08-23;86.69;87.10;86.22;86.56;4470000;86.56
1965-08-20;86.79;87.14;86.21;86.69;4170000;86.69
1965-08-19;86.99;87.48;86.49;86.79;5000000;86.79
1965-08-18;87.04;87.57;86.63;86.99;5850000;86.99
1965-08-17;86.87;87.42;86.48;87.04;4520000;87.04
1965-08-16;86.77;87.43;86.46;86.87;5270000;86.87
1965-08-13;86.38;87.14;86.09;86.77;5430000;86.77
1965-08-12;86.13;86.75;85.85;86.38;5160000;86.38
1965-08-11;85.87;86.48;85.64;86.13;5030000;86.13
1965-08-10;85.86;86.31;85.45;85.87;4690000;85.87
1965-08-09;86.07;86.54;85.52;85.86;4540000;85.86
1965-08-06;85.79;86.40;85.42;86.07;4200000;86.07
1965-08-05;85.79;86.28;85.43;85.79;4920000;85.79
1965-08-04;85.46;86.12;85.22;85.79;4830000;85.79
1965-08-03;85.42;85.81;84.80;85.46;4640000;85.46
1965-08-02;85.25;85.87;84.87;85.42;4220000;85.42
1965-07-30;84.68;85.64;84.64;85.25;5200000;85.25
1965-07-29;84.03;85.00;83.79;84.68;4690000;84.68
1965-07-28;83.87;84.52;83.30;84.03;4760000;84.03
1965-07-27;84.05;84.59;83.58;83.87;4190000;83.87
1965-07-26;84.07;84.47;83.49;84.05;3790000;84.05
1965-07-23;83.85;84.52;83.57;84.07;3600000;84.07
1965-07-22;84.07;84.45;83.53;83.85;3310000;83.85
1965-07-21;84.55;84.84;83.76;84.07;4350000;84.07
1965-07-20;85.63;85.85;84.39;84.55;4670000;84.55
1965-07-19;85.69;86.04;85.21;85.63;3220000;85.63
1965-07-16;85.72;86.14;85.26;85.69;3520000;85.69
1965-07-15;85.87;86.47;85.44;85.72;4420000;85.72
1965-07-14;85.59;86.23;85.18;85.87;4100000;85.87
1965-07-13;85.69;86.01;85.12;85.59;3260000;85.59
1965-07-12;85.71;86.08;85.24;85.69;3690000;85.69
1965-07-09;85.39;86.11;85.11;85.71;4800000;85.71
1965-07-08;84.67;85.60;84.29;85.39;4380000;85.39
1965-07-07;84.99;85.14;84.28;84.67;3020000;84.67
1965-07-06;85.16;85.63;84.57;84.99;3400000;84.99
1965-07-02;84.48;85.40;84.13;85.16;4260000;85.16
1965-07-01;84.12;84.64;83.57;84.48;4520000;84.48
1965-06-30;82.97;84.63;82.97;84.12;6930000;84.12
1965-06-29;81.60;83.04;80.73;82.41;10450000;82.41
1965-06-28;83.06;83.34;81.36;81.60;7650000;81.60
1965-06-25;83.56;83.83;82.60;83.06;5790000;83.06
1965-06-24;84.67;84.73;83.30;83.56;5840000;83.56
1965-06-23;85.21;85.59;84.52;84.67;3580000;84.67
1965-06-22;85.05;85.70;84.76;85.21;3330000;85.21
1965-06-21;85.34;85.64;84.53;85.05;3280000;85.05
1965-06-18;85.74;86.10;84.90;85.34;4330000;85.34
1965-06-17;85.20;86.22;84.98;85.74;5220000;85.74
1965-06-16;84.58;85.79;84.58;85.20;6290000;85.20
1965-06-15;84.01;84.86;83.01;84.49;8450000;84.49
1965-06-14;85.12;85.68;83.64;84.01;5920000;84.01
1965-06-11;84.73;85.68;84.50;85.12;5350000;85.12
1965-06-10;85.04;85.82;84.10;84.73;7470000;84.73
1965-06-09;85.93;86.37;84.75;85.04;7070000;85.04
1965-06-08;86.88;87.10;85.74;85.93;4660000;85.93
1965-06-07;87.11;87.45;86.04;86.88;4680000;86.88
1965-06-04;86.90;87.46;86.36;87.11;4530000;87.11
1965-06-03;87.09;88.05;86.58;86.90;5720000;86.90
1965-06-02;87.87;87.87;86.25;87.09;6790000;87.09
1965-06-01;88.42;88.80;87.88;88.72;4830000;88.72
1965-05-28;87.84;88.68;87.58;88.42;4270000;88.42
1965-05-27;88.30;88.36;87.24;87.84;5520000;87.84
1965-05-26;88.60;89.22;88.04;88.30;5330000;88.30
1965-05-25;88.09;88.96;87.82;88.60;4950000;88.60
1965-05-24;88.75;88.89;87.75;88.09;4790000;88.09
1965-05-21;89.18;89.41;88.40;88.75;4660000;88.75
1965-05-20;89.67;89.86;88.74;89.18;5750000;89.18
1965-05-19;89.46;90.15;89.17;89.67;5860000;89.67
1965-05-18;89.54;89.84;88.87;89.46;5130000;89.46
1965-05-17;90.10;90.44;89.24;89.54;4980000;89.54
1965-05-14;90.27;90.66;89.63;90.10;5860000;90.10
1965-05-13;89.94;90.68;89.68;90.27;6460000;90.27
1965-05-12;89.55;90.31;89.30;89.94;6310000;89.94
1965-05-11;89.66;89.98;89.05;89.55;5150000;89.55
1965-05-10;89.85;90.22;89.22;89.66;5600000;89.66
1965-05-07;89.92;90.30;89.33;89.85;5820000;89.85
1965-05-06;89.71;90.57;89.39;89.92;6340000;89.92
1965-05-05;89.51;90.40;89.14;89.71;6350000;89.71
1965-05-04;89.23;89.89;88.82;89.51;5720000;89.51
1965-05-03;89.11;89.68;88.62;89.23;5340000;89.23
1965-04-30;88.93;89.44;88.50;89.11;5190000;89.11
1965-04-29;89.00;89.43;88.47;88.93;5510000;88.93
1965-04-28;89.04;89.48;88.51;89.00;5680000;89.00
1965-04-27;88.89;89.64;88.71;89.04;6310000;89.04
1965-04-26;88.88;89.29;88.30;88.89;5410000;88.89
1965-04-23;88.78;89.41;88.48;88.88;5860000;88.88
1965-04-22;88.30;89.13;88.12;88.78;5990000;88.78
1965-04-21;88.46;88.82;87.70;88.30;5590000;88.30
1965-04-20;88.51;89.07;88.02;88.46;6480000;88.46
1965-04-19;88.15;88.90;87.90;88.51;5700000;88.51
1965-04-15;88.24;88.63;87.55;88.15;5830000;88.15
1965-04-14;88.04;88.65;87.71;88.24;6580000;88.24
1965-04-13;87.94;88.48;87.54;88.04;6690000;88.04
1965-04-12;87.56;88.36;87.31;87.94;6040000;87.94
1965-04-09;87.04;87.87;86.86;87.56;6580000;87.56
1965-04-08;86.55;87.35;86.34;87.04;5770000;87.04
1965-04-07;86.50;86.88;86.14;86.55;4430000;86.55
1965-04-06;86.53;86.91;86.08;86.50;4610000;86.50
1965-04-05;86.53;87.08;86.14;86.53;4920000;86.53
1965-04-02;86.32;86.89;86.08;86.53;5060000;86.53
1965-04-01;86.16;86.73;85.87;86.32;4890000;86.32
1965-03-31;86.20;86.64;85.83;86.16;4470000;86.16
1965-03-30;86.03;86.53;85.69;86.20;4270000;86.20
1965-03-29;86.20;86.66;85.65;86.03;4590000;86.03
1965-03-26;86.84;87.06;85.96;86.20;5020000;86.20
1965-03-25;87.09;87.50;86.55;86.84;5460000;86.84
1965-03-24;86.93;87.55;86.68;87.09;5420000;87.09
1965-03-23;86.83;87.34;86.45;86.93;4820000;86.93
1965-03-22;86.84;87.34;86.41;86.83;4920000;86.83
1965-03-19;86.81;87.37;86.43;86.84;5040000;86.84
1965-03-18;87.02;87.48;86.50;86.81;4990000;86.81
1965-03-17;87.13;87.51;86.63;87.02;5120000;87.02
1965-03-16;87.24;87.61;86.67;87.13;5480000;87.13
1965-03-15;87.21;87.92;86.82;87.24;6000000;87.24
1965-03-12;86.90;87.65;86.60;87.21;6370000;87.21
1965-03-11;86.54;87.29;86.17;86.90;5770000;86.90
1965-03-10;86.69;87.07;86.20;86.54;5100000;86.54
1965-03-09;86.83;87.27;86.33;86.69;5210000;86.69
1965-03-08;86.80;87.28;86.31;86.83;5250000;86.83
1965-03-05;86.98;87.26;86.00;86.80;6120000;86.80
1965-03-04;87.26;87.72;86.63;86.98;7300000;86.98
1965-03-03;87.40;87.83;86.88;87.26;6600000;87.26
1965-03-02;87.25;87.79;86.84;87.40;5730000;87.40
1965-03-01;87.43;87.93;86.92;87.25;5780000;87.25
1965-02-26;87.20;87.84;86.81;87.43;5800000;87.43
1965-02-25;87.17;87.70;86.70;87.20;6680000;87.20
1965-02-24;86.64;87.72;86.43;87.17;7160000;87.17
1965-02-23;86.21;87.01;86.03;86.64;5880000;86.64
1965-02-19;86.05;86.67;85.71;86.21;5560000;86.21
1965-02-18;85.77;86.48;85.47;86.05;6060000;86.05
1965-02-17;85.67;86.25;85.25;85.77;5510000;85.77
1965-02-16;86.07;86.31;85.33;85.67;5000000;85.67
1965-02-15;86.17;86.86;85.75;86.07;5760000;86.07
1965-02-12;85.54;86.48;85.54;86.17;4960000;86.17
1965-02-11;86.46;86.89;85.40;85.54;5800000;85.54
1965-02-10;87.24;87.70;86.20;86.46;7210000;86.46
1965-02-09;86.95;87.64;86.70;87.24;5690000;87.24
1965-02-08;87.00;87.00;85.95;86.95;6010000;86.95
1965-02-05;87.57;87.98;86.90;87.29;5690000;87.29
1965-02-04;87.63;88.06;87.06;87.57;6230000;87.57
1965-02-03;87.55;88.01;87.07;87.63;6130000;87.63
1965-02-02;87.58;87.94;87.03;87.55;5460000;87.55
1965-02-01;87.56;88.01;87.05;87.58;5690000;87.58
1965-01-29;87.48;88.19;87.18;87.56;6940000;87.56
1965-01-28;87.23;87.88;86.89;87.48;6730000;87.48
1965-01-27;86.94;87.67;86.70;87.23;6010000;87.23
1965-01-26;86.86;87.45;86.51;86.94;5760000;86.94
1965-01-25;86.74;87.27;86.39;86.86;5370000;86.86
1965-01-22;86.52;87.15;86.20;86.74;5430000;86.74
1965-01-21;86.60;86.90;86.02;86.52;4780000;86.52
1965-01-20;86.63;87.10;86.26;86.60;5550000;86.60
1965-01-19;86.49;87.09;86.15;86.63;5550000;86.63
1965-01-18;86.21;87.15;85.99;86.49;5550000;86.49
1965-01-15;85.84;86.52;85.60;86.21;5340000;86.21
1965-01-14;85.84;86.38;85.41;85.84;5810000;85.84
1965-01-13;85.61;86.27;85.35;85.84;6160000;85.84
1965-01-12;85.40;85.98;85.13;85.61;5400000;85.61
1965-01-11;85.37;85.81;84.90;85.40;5440000;85.40
1965-01-08;85.26;85.84;84.91;85.37;5340000;85.37
1965-01-07;84.89;85.62;84.66;85.26;5080000;85.26
1965-01-06;84.63;85.38;84.45;84.89;4850000;84.89
1965-01-05;84.23;85.02;84.02;84.63;4110000;84.63
1965-01-04;84.75;85.15;83.77;84.23;3930000;84.23
1964-12-31;84.30;85.18;84.18;84.75;6470000;84.75
1964-12-30;83.81;84.63;83.63;84.30;5610000;84.30
1964-12-29;84.07;84.35;83.38;83.81;4450000;83.81
1964-12-28;84.15;84.58;83.70;84.07;3990000;84.07
1964-12-24;84.15;84.59;83.74;84.15;3600000;84.15
1964-12-23;84.33;84.76;83.79;84.15;4470000;84.15
1964-12-22;84.38;84.88;83.94;84.33;4520000;84.33
1964-12-21;84.29;84.91;84.11;84.38;4470000;84.38
1964-12-18;83.90;84.65;83.73;84.29;4630000;84.29
1964-12-17;83.55;84.24;83.34;83.90;4850000;83.90
1964-12-16;83.22;83.94;83.00;83.55;4610000;83.55
1964-12-15;83.45;83.79;82.65;83.22;5340000;83.22
1964-12-14;83.66;84.17;83.10;83.45;4340000;83.45
1964-12-11;83.45;84.05;83.09;83.66;4530000;83.66
1964-12-10;83.46;83.96;82.98;83.45;4790000;83.45
1964-12-09;84.00;84.24;83.24;83.46;5120000;83.46
1964-12-08;84.33;84.71;83.69;84.00;4990000;84.00
1964-12-07;84.35;85.03;84.04;84.33;4770000;84.33
1964-12-04;84.35;84.35;84.35;84.35;4340000;84.35
1964-12-03;83.79;84.74;83.71;84.18;4250000;84.18
1964-12-02;83.55;84.23;83.12;83.79;4930000;83.79
1964-12-01;84.42;84.56;83.36;83.55;4940000;83.55
1964-11-30;85.16;85.41;84.10;84.42;4890000;84.42
1964-11-27;85.44;85.68;84.55;85.16;4070000;85.16
1964-11-25;85.73;86.18;85.10;85.44;4800000;85.44
1964-11-24;86.00;86.12;85.15;85.73;5070000;85.73
1964-11-23;86.28;86.59;85.48;86.00;4860000;86.00
1964-11-20;86.18;86.80;85.73;86.28;5210000;86.28
1964-11-19;86.22;86.57;85.60;86.18;5570000;86.18
1964-11-18;86.03;86.80;85.73;86.22;6560000;86.22
1964-11-17;85.65;86.55;85.48;86.03;5920000;86.03
1964-11-16;85.21;85.94;84.88;85.65;4870000;85.65
1964-11-13;85.19;85.68;84.76;85.21;4860000;85.21
1964-11-12;85.08;85.63;84.75;85.19;5250000;85.19
1964-11-11;84.84;85.30;84.49;85.08;3790000;85.08
1964-11-10;85.19;85.55;84.49;84.84;5020000;84.84
1964-11-09;85.23;85.72;84.93;85.19;4560000;85.19
1964-11-06;85.16;85.55;84.65;85.23;4810000;85.23
1964-11-05;85.14;85.62;84.72;85.16;4380000;85.16
1964-11-04;85.18;85.90;84.80;85.14;4720000;85.14
1964-11-02;84.86;85.54;84.51;85.18;4430000;85.18
1964-10-30;84.73;85.22;84.41;84.86;4120000;84.86
1964-10-29;84.69;85.15;84.36;84.73;4390000;84.73
1964-10-28;85.00;85.37;84.43;84.69;4890000;84.69
1964-10-27;85.00;85.40;84.61;85.00;4470000;85.00
1964-10-26;85.14;85.70;84.65;85.00;5230000;85.00
1964-10-23;84.94;85.42;84.57;85.14;3830000;85.14
1964-10-22;85.10;85.44;84.51;84.94;4670000;84.94
1964-10-21;85.18;85.64;84.77;85.10;5170000;85.10
1964-10-20;84.93;85.57;84.56;85.18;5140000;85.18
1964-10-19;84.83;85.36;84.47;84.93;5010000;84.93
1964-10-16;84.25;85.10;84.10;84.83;5140000;84.83
1964-10-15;84.79;84.99;83.65;84.25;6500000;84.25
1964-10-14;84.96;85.29;84.50;84.79;4530000;84.79
1964-10-13;85.24;85.57;84.63;84.96;5400000;84.96
1964-10-12;85.22;85.58;84.88;85.24;4110000;85.24
1964-10-09;85.04;85.60;84.72;85.22;5290000;85.22
1964-10-08;84.80;85.40;84.47;85.04;5060000;85.04
1964-10-07;84.79;85.25;84.42;84.80;5090000;84.80
1964-10-06;84.74;85.24;84.37;84.79;4820000;84.79
1964-10-05;84.36;85.25;84.20;84.74;4850000;84.74
1964-10-02;84.08;84.64;83.71;84.36;4370000;84.36
1964-10-01;84.18;84.53;83.74;84.08;4470000;84.08
1964-09-30;84.24;84.66;83.86;84.18;4720000;84.18
1964-09-29;84.28;84.80;83.84;84.24;5070000;84.24
1964-09-28;84.21;84.73;83.79;84.28;4810000;84.28
1964-09-25;84.00;84.62;83.56;84.21;6170000;84.21
1964-09-24;83.91;84.43;83.45;84.00;5840000;84.00
1964-09-23;83.89;84.37;83.45;83.91;5920000;83.91
1964-09-22;83.86;84.44;83.53;83.89;5250000;83.89
1964-09-21;83.48;84.32;83.41;83.86;5310000;83.86
1964-09-18;83.79;84.29;83.03;83.48;6160000;83.48
1964-09-17;83.24;84.18;83.17;83.79;6380000;83.79
1964-09-16;83.00;83.52;82.57;83.24;4230000;83.24
1964-09-15;83.22;83.68;82.69;83.00;5690000;83.00
1964-09-14;83.45;83.89;82.88;83.22;5370000;83.22
1964-09-11;83.10;83.84;82.79;83.45;5630000;83.45
1964-09-10;83.05;83.50;82.60;83.10;5470000;83.10
1964-09-09;82.87;83.51;82.54;83.05;5690000;83.05
1964-09-08;82.76;83.24;82.46;82.87;4090000;82.87
1964-09-04;82.56;83.03;82.31;82.76;4210000;82.76
1964-09-03;82.31;82.83;82.04;82.56;4310000;82.56
1964-09-02;82.18;82.76;81.95;82.31;4800000;82.31
1964-09-01;81.83;82.50;81.57;82.18;4650000;82.18
1964-08-31;81.99;82.48;81.46;81.83;3340000;81.83
1964-08-28;81.70;82.29;81.54;81.99;3760000;81.99
1964-08-27;81.32;81.94;81.07;81.70;3560000;81.70
1964-08-26;81.44;81.74;80.99;81.32;3300000;81.32
1964-08-25;81.91;82.13;81.20;81.44;3780000;81.44
1964-08-24;82.07;82.48;81.64;81.91;3790000;81.91
1964-08-21;81.94;82.43;81.64;82.07;3620000;82.07
1964-08-20;82.32;82.57;81.60;81.94;3840000;81.94
1964-08-19;82.40;82.80;81.99;82.32;4160000;82.32
1964-08-18;82.36;82.79;82.01;82.40;4180000;82.40
1964-08-17;82.35;82.85;82.02;82.36;3780000;82.36
1964-08-14;82.41;82.83;82.03;82.35;4080000;82.35
1964-08-13;82.17;82.87;81.98;82.41;4600000;82.41
1964-08-12;81.76;82.53;81.60;82.17;4140000;82.17
1964-08-11;81.78;82.25;81.45;81.76;3450000;81.76
1964-08-10;81.86;82.23;81.43;81.78;3050000;81.78
1964-08-07;81.34;82.20;81.19;81.86;3190000;81.86
1964-08-06;82.09;82.45;81.20;81.34;3940000;81.34
1964-08-05;81.96;82.41;80.80;82.09;6160000;82.09
1964-08-04;83.00;83.02;81.68;81.96;4780000;81.96
1964-08-03;83.18;83.49;82.65;83.00;3780000;83.00
1964-07-31;83.09;83.57;82.72;83.18;4220000;83.18
1964-07-30;82.92;83.50;82.63;83.09;4530000;83.09
1964-07-29;82.85;83.30;82.47;82.92;4050000;82.92
1964-07-28;83.08;83.30;82.40;82.85;3860000;82.85
1964-07-27;83.46;83.82;82.82;83.08;4090000;83.08
1964-07-24;83.48;83.92;83.07;83.46;4210000;83.46
1964-07-23;83.52;83.91;83.06;83.48;4560000;83.48
1964-07-22;83.54;83.95;82.96;83.52;4570000;83.52
1964-07-21;83.74;83.99;83.06;83.54;4570000;83.54
1964-07-20;84.01;84.33;83.44;83.74;4390000;83.74
1964-07-17;83.64;84.33;83.37;84.01;4640000;84.01
1964-07-16;83.34;83.98;83.06;83.64;4640000;83.64
1964-07-15;83.06;83.67;82.72;83.34;4610000;83.34
1964-07-14;83.31;83.71;82.72;83.06;4760000;83.06
1964-07-13;83.36;83.86;82.92;83.31;4800000;83.31
1964-07-10;83.22;83.99;82.87;83.36;5420000;83.36
1964-07-09;83.12;83.64;82.74;83.22;5040000;83.22
1964-07-08;83.12;83.56;82.58;83.12;4760000;83.12
1964-07-07;82.98;83.53;82.60;83.12;5240000;83.12
1964-07-06;82.60;83.38;82.37;82.98;5080000;82.98
1964-07-02;82.27;82.98;82.09;82.60;5230000;82.60
1964-07-01;81.69;82.51;81.46;82.27;5320000;82.27
1964-06-30;81.64;82.07;81.19;81.69;4360000;81.69
1964-06-29;81.46;82.10;81.10;81.64;4380000;81.64
1964-06-26;81.21;81.78;80.86;81.46;4440000;81.46
1964-06-25;81.06;81.73;80.75;81.21;5010000;81.21
1964-06-24;80.77;81.45;80.41;81.06;4840000;81.06
1964-06-23;81.11;81.43;80.50;80.77;4060000;80.77
1964-06-22;80.89;81.54;80.66;81.11;4540000;81.11
1964-06-19;80.79;81.23;80.39;80.89;4050000;80.89
1964-06-18;80.81;81.34;80.43;80.79;4730000;80.79
1964-06-17;80.40;81.13;80.22;80.81;5340000;80.81
1964-06-16;79.97;80.72;79.85;80.40;4590000;80.40
1964-06-15;79.60;80.33;79.39;79.97;4110000;79.97
1964-06-12;79.73;80.05;79.19;79.60;3840000;79.60
1964-06-11;79.44;80.13;79.24;79.73;3620000;79.73
1964-06-10;79.14;79.84;79.02;79.44;4170000;79.44
1964-06-09;78.64;79.39;78.15;79.14;4470000;79.14
1964-06-08;79.02;79.44;78.44;78.64;4010000;78.64
1964-06-05;78.67;79.45;78.50;79.02;4240000;79.02
1964-06-04;79.49;79.75;78.44;78.67;4880000;78.67
1964-06-03;79.70;80.12;79.27;79.49;3990000;79.49
1964-06-02;80.11;80.60;79.50;79.70;4180000;79.70
1964-06-01;80.37;80.83;79.83;80.11;4300000;80.11
1964-05-28;80.26;80.75;79.88;80.37;4560000;80.37
1964-05-27;80.39;80.72;79.78;80.26;4450000;80.26
1964-05-26;80.56;80.94;80.12;80.39;4290000;80.39
1964-05-25;80.73;81.16;80.21;80.56;3990000;80.56
1964-05-22;80.94;81.15;80.36;80.73;4640000;80.73
1964-05-21;80.66;81.49;80.36;80.94;5350000;80.94
1964-05-20;80.30;81.02;80.09;80.66;4790000;80.66
1964-05-19;80.72;81.04;79.96;80.30;4360000;80.30
1964-05-18;81.10;81.47;80.42;80.72;4590000;80.72
1964-05-15;80.86;81.45;80.49;81.10;5070000;81.10
1964-05-14;80.97;81.28;80.37;80.86;4720000;80.86
1964-05-13;81.16;81.65;80.66;80.97;5890000;80.97
1964-05-12;80.90;81.81;80.66;81.16;5200000;81.16
1964-05-11;81.00;81.51;80.58;80.90;4490000;80.90
1964-05-08;81.00;81.00;81.00;81.00;4910000;81.00
1964-05-07;81.06;81.72;80.67;81.15;5600000;81.15
1964-05-06;80.88;81.57;80.53;81.06;5560000;81.06
1964-05-05;80.47;81.20;79.99;80.88;5340000;80.88
1964-05-04;80.17;81.01;79.87;80.47;5360000;80.47
1964-05-01;79.46;80.47;79.46;80.17;5990000;80.17
1964-04-30;79.70;80.08;79.08;79.46;5690000;79.46
1964-04-29;79.90;80.60;79.29;79.70;6200000;79.70
1964-04-28;79.35;80.26;79.14;79.90;4790000;79.90
1964-04-27;79.75;80.01;78.90;79.35;5070000;79.35
1964-04-24;80.38;80.62;79.45;79.75;5610000;79.75
1964-04-23;80.49;81.20;80.09;80.38;6690000;80.38
1964-04-22;80.54;80.92;80.06;80.49;5390000;80.49
1964-04-21;80.50;80.98;80.05;80.54;5750000;80.54
1964-04-20;80.55;81.04;80.11;80.50;5560000;80.50
1964-04-17;80.20;80.98;79.99;80.55;6030000;80.55
1964-04-16;80.09;80.62;79.73;80.20;5240000;80.20
1964-04-15;79.99;80.50;79.63;80.09;5270000;80.09
1964-04-14;79.77;80.37;79.46;79.99;5120000;79.99
1964-04-13;79.85;80.30;79.42;79.77;5330000;79.77
1964-04-10;79.70;80.26;79.43;79.85;4990000;79.85
1964-04-09;79.75;80.23;79.36;79.70;5300000;79.70
1964-04-08;79.74;80.17;79.26;79.75;5380000;79.75
1964-04-07;80.02;80.44;79.41;79.74;5900000;79.74
1964-04-06;79.94;80.45;79.55;80.02;5840000;80.02
1964-04-03;79.70;80.37;79.45;79.94;5990000;79.94
1964-04-02;79.24;80.09;79.13;79.70;6840000;79.70
1964-04-01;78.98;79.58;78.67;79.24;5510000;79.24
1964-03-31;79.14;79.51;78.57;78.98;5270000;78.98
1964-03-30;79.19;79.67;78.75;79.14;6060000;79.14
1964-03-26;78.98;79.58;78.67;79.19;5760000;79.19
1964-03-25;78.79;79.33;78.17;78.98;5420000;78.98
1964-03-24;78.93;79.34;78.51;78.79;5210000;78.79
1964-03-23;78.92;79.33;78.45;78.93;4940000;78.93
1964-03-20;79.30;79.35;78.92;78.92;5020000;78.92
1964-03-19;79.38;79.85;78.94;79.30;5670000;79.30
1964-03-18;79.32;79.89;78.90;79.38;5890000;79.38
1964-03-17;79.14;79.65;78.77;79.32;5480000;79.32
1964-03-16;79.14;79.60;78.72;79.14;5140000;79.14
1964-03-13;79.08;79.59;78.74;79.14;5660000;79.14
1964-03-12;78.95;79.41;78.55;79.08;5290000;79.08
1964-03-11;78.59;79.42;78.45;78.95;6180000;78.95
1964-03-10;78.33;78.90;77.95;78.59;5500000;78.59
1964-03-09;78.31;78.88;77.95;78.33;5510000;78.33
1964-03-06;78.06;78.60;77.85;78.31;4790000;78.31
1964-03-05;78.07;78.44;77.58;78.06;4680000;78.06
1964-03-04;78.22;78.70;77.70;78.07;5250000;78.07
1964-03-03;77.97;78.66;77.69;78.22;5350000;78.22
1964-03-02;77.80;78.38;77.50;77.97;5690000;77.97
1964-02-28;77.62;78.06;77.20;77.80;4980000;77.80
1964-02-27;77.87;78.29;77.38;77.62;5420000;77.62
1964-02-26;77.68;78.13;77.33;77.87;5350000;77.87
1964-02-25;77.68;78.31;77.19;77.68;5010000;77.68
1964-02-24;77.62;78.16;77.27;77.68;5630000;77.68
1964-02-20;77.55;77.99;77.16;77.62;4690000;77.62
1964-02-19;77.47;77.98;77.13;77.55;4280000;77.55
1964-02-18;77.46;77.90;77.00;77.47;4660000;77.47
1964-02-17;77.48;77.93;77.04;77.46;4780000;77.46
1964-02-14;77.52;77.82;77.02;77.48;4360000;77.48
1964-02-13;77.57;77.93;77.10;77.52;4820000;77.52
1964-02-12;77.33;77.88;77.14;77.57;4650000;77.57
1964-02-11;77.05;77.65;76.81;77.33;4040000;77.33
1964-02-10;77.18;77.77;76.83;77.05;4150000;77.05
1964-02-07;76.93;77.51;76.66;77.18;4710000;77.18
1964-02-06;76.75;77.26;76.47;76.93;4110000;76.93
1964-02-05;76.88;77.28;76.36;76.75;4010000;76.75
1964-02-04;76.97;77.31;76.46;76.88;4320000;76.88
1964-02-03;77.04;77.55;76.53;76.97;4140000;76.97
1964-01-31;76.70;77.37;76.39;77.04;4000000;77.04
1964-01-30;76.63;77.20;76.26;76.70;4230000;76.70
1964-01-29;77.10;77.36;76.33;76.63;4450000;76.63
1964-01-28;77.08;77.56;76.63;77.10;4720000;77.10
1964-01-27;77.11;77.78;76.64;77.08;5240000;77.08
1964-01-24;77.09;77.56;76.58;77.11;5080000;77.11
1964-01-23;77.03;77.62;76.67;77.09;5380000;77.09
1964-01-22;76.62;77.62;76.45;77.03;5430000;77.03
1964-01-21;76.41;76.99;75.87;76.62;4800000;76.62
1964-01-20;76.56;77.19;76.02;76.41;5570000;76.41
1964-01-17;76.55;77.09;76.02;76.56;5600000;76.56
1964-01-16;76.64;77.21;76.05;76.55;6200000;76.55
1964-01-15;76.36;77.06;75.96;76.64;6750000;76.64
1964-01-14;76.22;76.85;75.88;76.36;6500000;76.36
1964-01-13;76.24;76.71;75.78;76.22;5440000;76.22
1964-01-10;76.28;76.67;75.74;76.24;5260000;76.24
1964-01-09;76.00;76.64;75.60;76.28;5180000;76.28
1964-01-08;75.69;76.35;75.39;76.00;5380000;76.00
1964-01-07;75.67;76.24;75.25;75.69;5700000;75.69
1964-01-06;75.50;76.12;75.18;75.67;5480000;75.67
1964-01-03;75.43;76.04;75.09;75.50;5550000;75.50
1964-01-02;75.02;75.79;74.82;75.43;4680000;75.43
1963-12-31;74.56;75.36;74.40;75.02;6730000;75.02
1963-12-30;74.44;74.94;74.13;74.56;4930000;74.56
1963-12-27;74.32;74.91;74.09;74.44;4360000;74.44
1963-12-26;73.97;74.63;73.74;74.32;3700000;74.32
1963-12-24;73.81;74.48;73.44;73.97;3970000;73.97
1963-12-23;74.28;74.45;73.49;73.81;4540000;73.81
1963-12-20;74.40;74.75;73.85;74.28;4600000;74.28
1963-12-19;74.63;74.92;74.08;74.40;4410000;74.40
1963-12-18;74.74;75.21;74.25;74.63;6000000;74.63
1963-12-17;74.30;75.08;74.07;74.74;5140000;74.74
1963-12-16;74.06;74.66;73.78;74.30;4280000;74.30
1963-12-13;73.91;74.39;73.68;74.06;4290000;74.06
1963-12-12;73.90;74.31;73.58;73.91;4220000;73.91
1963-12-11;73.99;74.37;73.58;73.90;4400000;73.90
1963-12-10;73.96;74.48;73.40;73.99;4560000;73.99
1963-12-09;74.00;74.41;73.56;73.96;4430000;73.96
1963-12-06;74.28;74.63;73.62;74.00;4830000;74.00
1963-12-05;73.80;74.57;73.45;74.28;5190000;74.28
1963-12-04;73.62;74.18;73.21;73.80;4790000;73.80
1963-12-03;73.66;74.01;73.14;73.62;4520000;73.62
1963-12-02;73.23;74.08;73.02;73.66;4770000;73.66
1963-11-29;72.25;73.47;72.05;73.23;4810000;73.23
1963-11-27;72.38;72.78;71.76;72.25;5210000;72.25
1963-11-26;71.40;72.74;71.40;72.38;9320000;72.38
1963-11-22;71.62;72.17;69.48;69.61;6630000;69.61
1963-11-21;72.56;72.86;71.40;71.62;5670000;71.62
1963-11-20;71.90;73.14;71.49;72.56;5330000;72.56
1963-11-19;71.83;72.61;71.42;71.90;4430000;71.90
1963-11-18;72.35;72.52;71.42;71.83;4730000;71.83
1963-11-15;72.95;73.20;72.09;72.35;4790000;72.35
1963-11-14;73.29;73.53;72.63;72.95;4610000;72.95
1963-11-13;73.23;73.67;72.89;73.29;4710000;73.29
1963-11-12;73.23;73.23;73.23;73.23;4610000;73.23
1963-11-11;73.52;73.52;73.52;73.52;3970000;73.52
1963-11-08;73.06;73.66;72.80;73.36;4570000;73.36
1963-11-07;72.81;73.48;72.58;73.06;4320000;73.06
1963-11-06;73.45;73.47;72.33;72.81;5600000;72.81
1963-11-04;73.83;74.27;73.09;73.45;5440000;73.45
1963-11-01;74.01;74.44;73.47;73.83;5240000;73.83
1963-10-31;73.80;74.35;73.25;74.01;5030000;74.01
1963-10-30;74.46;74.59;73.43;73.80;5170000;73.80
1963-10-29;74.48;75.18;73.97;74.46;6100000;74.46
1963-10-28;74.01;75.15;73.75;74.48;7150000;74.48
1963-10-25;73.28;74.41;73.06;74.01;6390000;74.01
1963-10-24;73.00;73.73;72.74;73.28;6280000;73.28
1963-10-23;72.96;73.55;72.59;73.00;5830000;73.00
1963-10-22;73.38;73.55;72.48;72.96;6420000;72.96
1963-10-21;73.32;73.87;73.03;73.38;5450000;73.38
1963-10-18;73.26;73.74;72.85;73.32;5830000;73.32
1963-10-17;72.97;73.77;72.84;73.26;6790000;73.26
1963-10-16;72.40;73.20;72.08;72.97;5570000;72.97
1963-10-15;72.30;72.79;71.99;72.40;4550000;72.40
1963-10-14;72.27;72.43;71.85;72.30;4270000;72.30
1963-10-11;72.20;72.71;71.87;72.27;4740000;72.27
1963-10-10;71.87;72.52;71.60;72.20;4470000;72.20
1963-10-09;71.98;71.98;71.60;71.87;5520000;71.87
1963-10-08;72.70;73.14;72.24;72.60;4920000;72.60
1963-10-07;72.85;73.27;72.39;72.70;4050000;72.70
1963-10-04;72.83;73.19;72.46;72.85;5120000;72.85
1963-10-03;72.30;73.10;72.10;72.83;4510000;72.83
1963-10-02;72.22;72.67;71.92;72.30;3780000;72.30
1963-10-01;71.70;72.65;71.57;72.22;4420000;72.22
1963-09-30;72.13;72.37;71.28;71.70;3730000;71.70
1963-09-27;72.27;72.60;71.60;72.13;4350000;72.13
1963-09-26;72.89;73.07;72.01;72.27;5100000;72.27
1963-09-25;73.30;73.87;72.58;72.89;6340000;72.89
1963-09-24;72.96;73.67;72.59;73.30;5520000;73.30
1963-09-23;73.30;73.53;72.62;72.96;5140000;72.96
1963-09-20;73.22;73.71;72.92;73.30;5310000;73.30
1963-09-19;72.80;73.47;72.61;73.22;4080000;73.22
1963-09-18;73.12;73.44;72.51;72.80;5070000;72.80
1963-09-17;73.07;73.64;72.79;73.12;4950000;73.12
1963-09-16;73.17;73.63;72.80;73.07;4740000;73.07
1963-09-13;73.15;73.59;72.82;73.17;5230000;73.17
1963-09-12;73.20;73.60;72.72;73.15;5560000;73.15
1963-09-11;72.99;73.79;72.83;73.20;6670000;73.20
1963-09-10;72.58;73.27;72.25;72.99;5310000;72.99
1963-09-09;72.84;73.23;72.26;72.58;5020000;72.58
1963-09-06;73.00;73.51;72.51;72.84;7160000;72.84
1963-09-05;72.64;73.19;72.15;73.00;5700000;73.00
1963-09-04;72.66;73.18;72.32;72.64;6070000;72.64
1963-09-03;72.50;73.09;72.30;72.66;5570000;72.66
1963-08-30;72.16;72.71;71.88;72.50;4560000;72.50
1963-08-29;72.04;72.56;71.83;72.16;5110000;72.16
1963-08-28;71.52;72.39;71.49;72.04;5120000;72.04
1963-08-27;71.91;72.04;71.27;71.52;4080000;71.52
1963-08-26;71.76;72.30;71.57;71.91;4700000;71.91
1963-08-23;71.54;72.14;71.33;71.76;4880000;71.76
1963-08-22;71.29;71.81;70.95;71.54;4540000;71.54
1963-08-21;71.38;71.73;71.00;71.29;3820000;71.29
1963-08-20;71.44;71.91;71.03;71.38;3660000;71.38
1963-08-19;71.49;71.92;71.15;71.44;3650000;71.44
1963-08-16;71.38;71.95;71.05;71.49;4130000;71.49
1963-08-15;71.07;71.71;70.81;71.38;4980000;71.38
1963-08-14;70.79;71.32;70.39;71.07;4420000;71.07
1963-08-13;70.59;71.09;70.32;70.79;4450000;70.79
1963-08-12;70.48;71.00;70.19;70.59;4770000;70.59
1963-08-09;70.02;70.65;69.83;70.48;4050000;70.48
1963-08-08;69.96;70.31;69.58;70.02;3460000;70.02
1963-08-07;70.17;70.53;69.69;69.96;3790000;69.96
1963-08-06;69.71;70.40;69.57;70.17;3760000;70.17
1963-08-05;69.30;69.97;69.20;69.71;3370000;69.71
1963-08-02;69.07;69.56;68.86;69.30;2940000;69.30
1963-08-01;69.13;69.47;68.64;69.07;3410000;69.07
1963-07-31;69.24;69.83;68.91;69.13;3960000;69.13
1963-07-30;68.67;69.45;68.58;69.24;3550000;69.24
1963-07-29;68.54;68.96;68.32;68.67;2840000;68.67
1963-07-26;68.26;68.76;68.03;68.54;2510000;68.54
1963-07-25;68.28;68.92;68.02;68.26;3710000;68.26
1963-07-24;67.91;68.54;67.76;68.28;2810000;68.28
1963-07-23;67.90;68.57;67.65;67.91;3500000;67.91
1963-07-22;68.35;68.60;67.54;67.90;3700000;67.90
1963-07-19;68.49;68.70;67.90;68.35;3340000;68.35
1963-07-18;68.93;69.27;68.34;68.49;3710000;68.49
1963-07-17;69.14;69.53;68.68;68.93;3940000;68.93
1963-07-16;69.20;69.51;68.85;69.14;3000000;69.14
1963-07-15;69.64;69.73;68.97;69.20;3290000;69.20
1963-07-12;69.76;70.13;69.36;69.64;3660000;69.64
1963-07-11;69.89;70.30;69.52;69.76;4100000;69.76
1963-07-10;70.04;70.31;69.56;69.89;3730000;69.89
1963-07-09;69.74;70.39;69.55;70.04;3830000;70.04
1963-07-08;70.22;70.35;69.47;69.74;3290000;69.74
1963-07-05;69.94;70.48;69.78;70.22;2910000;70.22
1963-07-03;69.46;70.28;69.42;69.94;4030000;69.94
1963-07-02;68.86;69.72;68.74;69.46;3540000;69.46
1963-07-01;69.37;69.53;68.58;68.86;3360000;68.86
1963-06-28;69.07;69.68;68.93;69.37;3020000;69.37
1963-06-27;69.41;69.81;68.78;69.07;4540000;69.07
1963-06-26;70.04;70.10;69.17;69.41;4500000;69.41
1963-06-25;70.20;70.51;69.75;70.04;4120000;70.04
1963-06-24;70.25;70.67;69.84;70.20;3700000;70.20
1963-06-21;70.01;70.57;69.79;70.25;4190000;70.25
1963-06-20;70.09;70.36;69.31;70.01;4970000;70.01
1963-06-19;70.02;70.47;69.75;70.09;3970000;70.09
1963-06-18;69.95;70.43;69.63;70.02;3910000;70.02
1963-06-17;69.95;69.95;69.95;69.95;3510000;69.95
1963-06-14;70.23;70.60;69.87;70.25;3840000;70.25
1963-06-13;70.41;70.85;69.98;70.23;4690000;70.23
1963-06-12;70.03;70.81;69.91;70.41;5210000;70.41
1963-06-11;69.94;70.41;69.58;70.03;4390000;70.03
1963-06-10;70.41;70.51;69.57;69.94;4690000;69.94
1963-06-07;70.58;70.98;70.10;70.41;5110000;70.41
1963-06-06;70.53;70.95;70.11;70.58;4990000;70.58
1963-06-05;70.70;71.17;70.17;70.53;5860000;70.53
1963-06-04;70.69;71.08;70.20;70.70;5970000;70.70
1963-06-03;70.80;71.24;70.39;70.69;5400000;70.69
1963-05-31;70.33;71.14;70.27;70.80;4680000;70.80
1963-05-29;70.01;70.65;69.86;70.33;4320000;70.33
1963-05-28;69.87;70.41;69.55;70.01;3860000;70.01
1963-05-27;70.02;70.27;69.48;69.87;3760000;69.87
1963-05-24;70.10;70.44;69.66;70.02;4320000;70.02
1963-05-23;70.14;70.53;69.79;70.10;4400000;70.10
1963-05-22;70.14;70.68;69.82;70.14;5560000;70.14
1963-05-21;69.96;70.51;69.62;70.14;5570000;70.14
1963-05-20;70.29;70.48;69.59;69.96;4710000;69.96
1963-05-17;70.25;70.63;69.83;70.29;4410000;70.29
1963-05-16;70.43;70.81;69.91;70.25;5640000;70.25
1963-05-15;70.21;70.77;69.87;70.43;5650000;70.43
1963-05-14;70.48;70.73;69.92;70.21;4740000;70.21
1963-05-13;70.52;70.89;70.11;70.48;4920000;70.48
1963-05-10;70.35;70.81;69.99;70.52;5260000;70.52
1963-05-09;70.01;70.74;69.86;70.35;5600000;70.35
1963-05-08;69.44;70.24;69.23;70.01;5140000;70.01
1963-05-07;69.53;69.92;69.03;69.44;4140000;69.44
1963-05-06;70.03;70.31;69.32;69.53;4090000;69.53
1963-05-03;70.17;70.51;69.78;70.03;4760000;70.03
1963-05-02;69.97;70.50;69.75;70.17;4480000;70.17
1963-05-01;69.80;70.43;69.61;69.97;5060000;69.97
1963-04-30;69.65;70.18;69.26;69.80;4680000;69.80
1963-04-29;69.70;70.04;69.26;69.65;3980000;69.65
1963-04-26;69.76;70.11;69.23;69.70;4490000;69.70
1963-04-25;69.72;70.08;69.25;69.76;5070000;69.76
1963-04-24;69.53;70.12;69.34;69.72;5910000;69.72
1963-04-23;69.30;69.83;68.95;69.53;5220000;69.53
1963-04-22;69.23;69.82;69.01;69.30;5180000;69.30
1963-04-19;68.89;69.46;68.60;69.23;4660000;69.23
1963-04-18;68.92;69.34;68.56;68.89;4770000;68.89
1963-04-17;69.14;69.37;68.47;68.92;5220000;68.92
1963-04-16;69.09;69.61;68.66;69.14;5570000;69.14
1963-04-15;68.77;69.56;68.58;69.09;5930000;69.09
1963-04-11;68.29;69.07;67.97;68.77;5250000;68.77
1963-04-10;68.45;68.89;67.66;68.29;5880000;68.29
1963-04-09;68.52;68.84;68.03;68.45;5090000;68.45
1963-04-08;68.28;68.91;68.05;68.52;5940000;68.52
1963-04-05;67.85;68.46;67.46;68.28;5240000;68.28
1963-04-04;67.36;68.12;67.28;67.85;5300000;67.85
1963-04-03;66.84;67.55;66.63;67.36;4660000;67.36
1963-04-02;66.85;67.36;66.51;66.84;4360000;66.84
1963-04-01;66.57;67.18;66.23;66.85;3890000;66.85
1963-03-29;66.58;66.90;66.23;66.57;3390000;66.57
1963-03-28;66.68;67.01;66.32;66.58;3890000;66.58
1963-03-27;66.40;66.93;66.21;66.68;4270000;66.68
1963-03-26;66.21;66.73;66.01;66.40;4100000;66.40
1963-03-25;66.19;66.60;65.92;66.21;3700000;66.21
1963-03-22;65.85;66.44;65.68;66.19;3820000;66.19
1963-03-21;65.95;66.25;65.60;65.85;3220000;65.85
1963-03-20;65.47;66.15;65.30;65.95;3690000;65.95
1963-03-19;65.61;65.85;65.19;65.47;3180000;65.47
1963-03-18;65.93;66.17;65.36;65.61;3250000;65.61
1963-03-15;65.60;66.22;65.39;65.93;3400000;65.93
1963-03-14;65.91;66.21;65.39;65.60;3540000;65.60
1963-03-13;65.67;66.27;65.54;65.91;4120000;65.91
1963-03-12;65.51;65.97;65.26;65.67;3350000;65.67
1963-03-11;65.33;65.86;65.11;65.51;3180000;65.51
1963-03-08;65.26;65.74;65.03;65.33;3360000;65.33
1963-03-07;64.85;65.60;64.81;65.26;3350000;65.26
1963-03-06;64.74;65.06;64.31;64.85;3100000;64.85
1963-03-05;64.72;65.27;64.41;64.74;3280000;64.74
1963-03-04;64.10;65.08;63.88;64.72;3650000;64.72
1963-03-01;64.29;64.75;63.80;64.10;3920000;64.10
1963-02-28;65.01;65.14;64.08;64.29;4090000;64.29
1963-02-27;65.47;65.74;64.86;65.01;3680000;65.01
1963-02-26;65.46;65.86;65.06;65.47;3670000;65.47
1963-02-25;65.92;66.09;65.24;65.46;3680000;65.46
1963-02-21;65.83;66.23;65.36;65.92;3980000;65.92
1963-02-20;66.20;66.28;65.44;65.83;4120000;65.83
1963-02-19;66.52;66.67;65.92;66.20;4130000;66.20
1963-02-18;66.41;66.96;66.10;66.52;4700000;66.52
1963-02-15;66.35;66.74;65.96;66.41;4410000;66.41
1963-02-14;66.15;66.75;65.93;66.35;5640000;66.35
1963-02-13;65.83;66.53;65.56;66.15;4960000;66.15
1963-02-12;65.76;66.01;65.16;65.83;3710000;65.83
1963-02-11;66.17;66.41;65.50;65.76;3880000;65.76
1963-02-08;66.17;66.45;65.65;66.17;3890000;66.17
1963-02-07;66.40;66.81;65.91;66.17;4240000;66.17
1963-02-06;66.11;66.76;65.88;66.40;4340000;66.40
1963-02-05;66.17;66.35;65.38;66.11;4050000;66.11
1963-02-04;66.31;66.66;65.89;66.17;3670000;66.17
1963-02-01;66.31;66.31;66.31;66.31;4280000;66.31
1963-01-31;65.85;66.45;65.51;66.20;4270000;66.20
1963-01-30;66.23;66.33;65.55;65.85;3740000;65.85
1963-01-29;66.24;66.58;65.83;66.23;4360000;66.23
1963-01-28;65.92;66.59;65.77;66.24;4720000;66.24
1963-01-25;65.75;66.23;65.38;65.92;4770000;65.92
1963-01-24;65.62;66.09;65.33;65.75;4810000;65.75
1963-01-23;65.44;65.91;65.23;65.62;4820000;65.62
1963-01-22;65.28;65.80;65.03;65.44;4810000;65.44
1963-01-21;65.18;65.52;64.64;65.28;4090000;65.28
1963-01-18;65.13;65.70;64.86;65.18;4760000;65.18
1963-01-17;64.67;65.40;64.35;65.13;5230000;65.13
1963-01-16;65.11;65.25;64.42;64.67;4260000;64.67
1963-01-15;65.20;65.62;64.82;65.11;5930000;65.11
1963-01-14;64.85;65.50;64.61;65.20;5000000;65.20
1963-01-11;64.71;65.10;64.31;64.85;4410000;64.85
1963-01-10;64.59;65.16;64.33;64.71;4520000;64.71
1963-01-09;64.74;65.22;64.32;64.59;5110000;64.59
1963-01-08;64.12;64.98;64.00;64.74;5410000;64.74
1963-01-07;64.13;64.59;63.67;64.12;4440000;64.12
1963-01-04;63.72;64.45;63.57;64.13;5400000;64.13
1963-01-03;62.69;63.89;62.67;63.72;4570000;63.72
1963-01-02;63.10;63.39;62.32;62.69;2540000;62.69
1962-12-31;62.96;63.43;62.68;63.10;5420000;63.10
1962-12-28;62.93;63.25;62.53;62.96;4140000;62.96
1962-12-27;63.02;63.41;62.67;62.93;3670000;62.93
1962-12-26;62.63;63.32;62.56;63.02;3370000;63.02
1962-12-24;62.64;63.03;62.19;62.63;3180000;62.63
1962-12-21;62.82;63.13;62.26;62.64;3470000;62.64
1962-12-20;62.58;63.28;62.44;62.82;4220000;62.82
1962-12-19;62.07;62.81;61.72;62.58;4000000;62.58
1962-12-18;62.37;62.66;61.78;62.07;3620000;62.07
1962-12-17;62.57;62.95;62.14;62.37;3590000;62.37
1962-12-14;62.42;62.83;61.96;62.57;3280000;62.57
1962-12-13;62.63;63.07;62.09;62.42;3380000;62.42
1962-12-12;62.32;63.16;62.13;62.63;3760000;62.63
1962-12-11;62.27;62.58;61.72;62.32;3700000;62.32
1962-12-10;63.06;63.35;61.96;62.27;4270000;62.27
1962-12-07;62.93;63.43;62.45;63.06;3900000;63.06
1962-12-06;62.39;63.36;62.28;62.93;4600000;62.93
1962-12-05;62.64;63.50;62.37;62.39;6280000;62.39
1962-12-04;61.94;62.93;61.77;62.64;5210000;62.64
1962-12-03;62.26;62.45;61.28;61.94;3810000;61.94
1962-11-30;62.41;62.78;61.78;62.26;4570000;62.26
1962-11-29;62.12;62.72;61.69;62.41;5810000;62.41
1962-11-28;61.73;62.48;61.51;62.12;5980000;62.12
1962-11-27;61.36;62.04;60.98;61.73;5500000;61.73
1962-11-26;61.54;62.13;60.95;61.36;5650000;61.36
1962-11-23;60.81;62.03;60.66;61.54;5660000;61.54
1962-11-21;60.45;61.18;60.19;60.81;5100000;60.81
1962-11-20;59.82;60.63;59.57;60.45;4290000;60.45
1962-11-19;60.16;60.42;59.46;59.82;3410000;59.82
1962-11-16;59.97;60.46;59.46;60.16;4000000;60.16
1962-11-15;60.16;60.67;59.74;59.97;5050000;59.97
1962-11-14;59.46;60.41;59.18;60.16;5090000;60.16
1962-11-13;59.59;60.06;59.06;59.46;4550000;59.46
1962-11-12;58.78;60.00;58.59;59.59;5090000;59.59
1962-11-09;58.32;58.99;57.90;58.78;4340000;58.78
1962-11-08;58.71;59.12;58.09;58.32;4160000;58.32
1962-11-07;58.35;59.11;57.76;58.71;4580000;58.71
1962-11-05;57.75;58.70;57.69;58.35;4320000;58.35
1962-11-02;57.12;58.19;56.78;57.75;5470000;57.75
1962-11-01;56.52;57.31;55.90;57.12;3400000;57.12
1962-10-31;56.54;57.00;56.19;56.52;3090000;56.52
1962-10-30;55.72;56.84;55.52;56.54;3830000;56.54
1962-10-29;55.34;56.38;55.34;55.72;4280000;55.72
1962-10-26;54.69;54.96;54.08;54.54;2580000;54.54
1962-10-25;55.17;55.17;53.82;54.69;3950000;54.69
1962-10-24;53.49;55.44;52.55;55.21;6720000;55.21
1962-10-23;54.96;55.19;53.24;53.49;6110000;53.49
1962-10-22;55.48;55.48;54.38;54.96;5690000;54.96
1962-10-19;56.34;56.54;55.34;55.59;4650000;55.59
1962-10-18;56.89;57.02;56.18;56.34;3280000;56.34
1962-10-17;57.08;57.23;56.37;56.89;3240000;56.89
1962-10-16;57.27;57.63;56.87;57.08;2860000;57.08
1962-10-15;56.95;57.50;56.66;57.27;2640000;57.27
1962-10-12;57.05;57.21;56.66;56.95;2020000;56.95
1962-10-11;57.24;57.46;56.78;57.05;2460000;57.05
1962-10-10;57.20;57.83;56.96;57.24;3040000;57.24
1962-10-09;57.07;57.40;56.71;57.20;2340000;57.20
1962-10-08;57.07;57.41;56.68;57.07;1950000;57.07
1962-10-05;56.70;57.30;56.55;57.07;2730000;57.07
1962-10-04;56.16;56.84;55.90;56.70;2530000;56.70
1962-10-03;56.10;56.71;55.84;56.16;2610000;56.16
1962-10-02;55.49;56.46;55.31;56.10;3000000;56.10
1962-10-01;56.27;56.31;55.26;55.49;3090000;55.49
1962-09-28;55.77;56.58;55.59;56.27;2850000;56.27
1962-09-27;56.15;56.55;55.53;55.77;3540000;55.77
1962-09-26;56.96;57.29;55.92;56.15;3550000;56.15
1962-09-25;56.63;57.22;56.12;56.96;3620000;56.96
1962-09-24;57.45;57.45;56.30;56.63;5000000;56.63
1962-09-21;58.54;58.64;57.43;57.69;4280000;57.69
1962-09-20;58.95;59.29;58.33;58.54;3350000;58.54
1962-09-19;59.03;59.26;58.59;58.95;2950000;58.95
1962-09-18;59.08;59.54;58.77;59.03;3690000;59.03
1962-09-17;58.89;59.42;58.65;59.08;3330000;59.08
1962-09-14;58.70;59.14;58.40;58.89;2880000;58.89
1962-09-13;58.84;59.18;58.46;58.70;3100000;58.70
1962-09-12;58.59;59.06;58.40;58.84;3100000;58.84
1962-09-11;58.45;58.93;58.17;58.59;3040000;58.59
1962-09-10;58.38;58.64;57.88;58.45;2520000;58.45
1962-09-07;58.36;58.90;58.09;58.38;2890000;58.38
1962-09-06;58.12;58.60;57.72;58.36;3180000;58.36
1962-09-05;58.56;58.77;57.95;58.12;3050000;58.12
1962-09-04;59.12;59.49;58.44;58.56;2970000;58.56
1962-08-31;58.68;59.25;58.45;59.12;2830000;59.12
1962-08-30;58.66;59.06;58.39;58.68;2260000;58.68
1962-08-29;58.79;58.96;58.17;58.66;2900000;58.66
1962-08-28;59.55;59.61;58.66;58.79;3180000;58.79
1962-08-27;59.58;59.94;59.24;59.55;3140000;59.55
1962-08-24;59.70;59.92;59.18;59.58;2890000;59.58
1962-08-23;59.78;60.33;59.47;59.70;4770000;59.70
1962-08-22;59.12;59.93;58.91;59.78;4520000;59.78
1962-08-21;59.37;59.66;58.90;59.12;3730000;59.12
1962-08-20;59.01;59.72;58.90;59.37;4580000;59.37
1962-08-17;58.64;59.24;58.43;59.01;3430000;59.01
1962-08-16;58.66;59.11;58.24;58.64;4180000;58.64
1962-08-15;58.25;59.11;58.22;58.66;4880000;58.66
1962-08-14;57.63;58.43;57.41;58.25;3640000;58.25
1962-08-13;57.55;57.90;57.22;57.63;2670000;57.63
1962-08-10;57.57;57.85;57.16;57.55;2470000;57.55
1962-08-09;57.51;57.88;57.19;57.57;2670000;57.57
1962-08-08;57.36;57.64;56.76;57.51;3080000;57.51
1962-08-07;57.75;57.81;57.07;57.36;2970000;57.36
1962-08-06;58.12;58.35;57.54;57.75;3110000;57.75
1962-08-03;57.98;58.32;57.63;58.12;5990000;58.12
1962-08-02;57.75;58.20;57.38;57.98;3410000;57.98
1962-08-01;58.23;58.30;57.51;57.75;3100000;57.75
1962-07-31;57.83;58.58;57.74;58.23;4190000;58.23
1962-07-30;57.20;57.98;57.08;57.83;3200000;57.83
1962-07-27;56.77;57.36;56.56;57.20;2890000;57.20
1962-07-26;56.46;57.18;56.16;56.77;2790000;56.77
1962-07-25;56.36;56.67;55.78;56.46;2910000;56.46
1962-07-24;56.80;56.93;56.14;56.36;2560000;56.36
1962-07-23;56.81;57.32;56.53;56.80;2770000;56.80
1962-07-20;56.42;57.09;56.27;56.81;2610000;56.81
1962-07-19;56.20;56.95;55.96;56.42;3090000;56.42
1962-07-18;56.78;56.81;55.86;56.20;3620000;56.20
1962-07-17;57.83;57.96;56.68;56.78;3500000;56.78
1962-07-16;57.83;58.10;57.18;57.83;3130000;57.83
1962-07-13;58.03;58.18;57.23;57.83;3380000;57.83
1962-07-12;57.73;58.67;57.59;58.03;5370000;58.03
1962-07-11;57.20;57.95;56.77;57.73;4250000;57.73
1962-07-10;56.99;58.36;56.99;57.20;7120000;57.20
1962-07-09;56.17;56.73;55.54;56.55;2950000;56.55
1962-07-06;56.73;56.73;55.64;56.17;3110000;56.17
1962-07-05;56.49;57.10;56.15;56.81;3350000;56.81
1962-07-03;55.86;56.74;55.57;56.49;3920000;56.49
1962-07-02;54.75;56.02;54.47;55.86;3450000;55.86
1962-06-29;54.41;55.47;54.20;54.75;4720000;54.75
1962-06-28;52.98;54.64;52.98;54.41;5440000;54.41
1962-06-27;52.32;52.83;51.77;52.60;3890000;52.60
1962-06-26;52.45;53.58;52.10;52.32;4630000;52.32
1962-06-25;52.68;52.96;51.35;52.45;7090000;52.45
1962-06-22;53.59;53.78;52.48;52.68;5640000;52.68
1962-06-21;54.78;54.78;53.50;53.59;4560000;53.59
1962-06-20;55.54;55.92;54.66;54.78;3360000;54.78
1962-06-19;55.74;55.88;54.98;55.54;2680000;55.54
1962-06-18;55.89;56.53;54.97;55.74;4580000;55.74
1962-06-15;54.33;55.96;53.66;55.89;7130000;55.89
1962-06-14;55.50;56.00;54.12;54.33;6240000;54.33
1962-06-13;56.34;56.80;55.24;55.50;5850000;55.50
1962-06-12;57.66;57.66;56.23;56.34;4690000;56.34
1962-06-11;58.45;58.58;57.51;57.82;2870000;57.82
1962-06-08;58.40;58.97;58.14;58.45;2560000;58.45
1962-06-07;58.39;58.90;58.00;58.40;2760000;58.40
1962-06-06;57.64;59.17;57.64;58.39;4190000;58.39
1962-06-05;57.27;58.42;56.33;57.57;6140000;57.57
1962-06-04;59.12;59.12;57.14;57.27;5380000;57.27
1962-06-01;59.63;59.96;58.52;59.38;5760000;59.38
1962-05-31;58.80;60.82;58.80;59.63;10710000;59.63
1962-05-29;55.50;58.29;53.13;58.08;14750000;58.08
1962-05-28;59.15;59.15;55.42;55.50;9350000;55.50
1962-05-25;60.62;60.98;59.00;59.47;6380000;59.47
1962-05-24;61.11;61.79;60.36;60.62;5250000;60.62
1962-05-23;62.34;62.42;60.90;61.11;5450000;61.11
1962-05-22;63.59;63.69;62.26;62.34;3640000;62.34
1962-05-21;63.82;64.00;63.21;63.59;2260000;63.59
1962-05-18;63.93;64.14;63.29;63.82;2490000;63.82
1962-05-17;64.27;64.41;63.38;63.93;2950000;63.93
1962-05-16;64.29;64.88;63.82;64.27;3360000;64.27
1962-05-15;63.41;64.87;63.41;64.29;4780000;64.29
1962-05-14;62.65;63.31;61.11;63.10;5990000;63.10
1962-05-11;63.57;64.10;62.44;62.65;4510000;62.65
1962-05-10;64.26;64.39;62.99;63.57;4730000;63.57
1962-05-09;65.17;65.17;64.02;64.26;3670000;64.26
1962-05-08;66.02;66.13;64.88;65.17;3020000;65.17
1962-05-07;66.24;66.56;65.66;66.02;2530000;66.02
1962-05-04;66.53;66.80;65.80;66.24;3010000;66.24
1962-05-03;65.99;66.93;65.81;66.53;3320000;66.53
1962-05-02;65.70;66.67;65.56;65.99;3780000;65.99
1962-05-01;65.24;65.94;63.76;65.70;5100000;65.70
1962-04-30;66.30;66.90;64.95;65.24;4150000;65.24
1962-04-27;67.05;67.61;65.99;66.30;4140000;66.30
1962-04-26;67.71;67.97;66.92;67.05;3650000;67.05
1962-04-25;68.46;68.58;67.53;67.71;3340000;67.71
1962-04-24;68.53;68.91;68.16;68.46;3040000;68.46
1962-04-23;68.59;69.01;68.17;68.53;3240000;68.53
1962-04-19;68.27;68.90;68.07;68.59;3100000;68.59
1962-04-18;67.90;68.72;67.83;68.27;3350000;68.27
1962-04-17;67.60;68.20;67.24;67.90;2940000;67.90
1962-04-16;67.90;68.19;67.21;67.60;3070000;67.60
1962-04-13;67.90;68.11;67.03;67.90;3470000;67.90
1962-04-12;68.41;68.43;67.47;67.90;3320000;67.90
1962-04-11;68.56;69.26;68.24;68.41;3240000;68.41
1962-04-10;68.31;68.80;67.94;68.56;2880000;68.56
1962-04-09;68.84;69.02;68.09;68.31;3020000;68.31
1962-04-06;68.91;69.42;68.58;68.84;2730000;68.84
1962-04-05;68.49;69.09;68.12;68.91;3130000;68.91
1962-04-04;68.81;69.22;68.33;68.49;3290000;68.49
1962-04-03;69.37;69.53;68.53;68.81;3350000;68.81
1962-04-02;69.55;69.82;69.13;69.37;2790000;69.37
1962-03-30;70.01;70.09;69.16;69.55;2950000;69.55
1962-03-29;70.04;70.50;69.81;70.01;2870000;70.01
1962-03-28;69.70;70.33;69.54;70.04;2940000;70.04
1962-03-27;69.89;70.20;69.41;69.70;3090000;69.70
1962-03-26;70.45;70.63;69.73;69.89;3040000;69.89
1962-03-23;70.40;70.78;70.12;70.45;3050000;70.45
1962-03-22;70.51;70.84;70.14;70.40;3130000;70.40
1962-03-21;70.66;70.93;70.16;70.51;3360000;70.51
1962-03-20;70.85;71.08;70.40;70.66;3060000;70.66
1962-03-19;70.94;71.31;70.53;70.85;3220000;70.85
1962-03-16;71.06;71.34;70.67;70.94;3060000;70.94
1962-03-15;70.91;71.44;70.59;71.06;3250000;71.06
1962-03-14;70.60;71.25;70.48;70.91;3670000;70.91
1962-03-13;70.40;70.86;70.06;70.60;3200000;70.60
1962-03-12;70.42;70.76;70.02;70.40;3280000;70.40
1962-03-09;70.19;70.71;70.00;70.42;3340000;70.42
1962-03-08;69.69;70.37;69.40;70.19;3210000;70.19
1962-03-07;69.78;70.07;69.37;69.69;2890000;69.69
1962-03-06;70.01;70.24;69.46;69.78;2870000;69.78
1962-03-05;70.16;70.48;69.65;70.01;3020000;70.01
1962-03-02;70.16;70.16;69.75;70.16;2980000;70.16
1962-03-01;69.96;70.60;69.76;70.20;2960000;70.20
1962-02-28;69.89;70.42;69.57;69.96;3030000;69.96
1962-02-27;69.76;70.32;69.48;69.89;3110000;69.89
1962-02-26;70.16;70.33;69.44;69.76;2910000;69.76
1962-02-23;70.32;70.57;69.73;70.16;3230000;70.16
1962-02-21;70.66;70.97;70.12;70.32;3310000;70.32
1962-02-20;70.41;70.91;70.13;70.66;3300000;70.66
1962-02-19;70.59;70.96;70.12;70.41;3350000;70.41
1962-02-16;70.74;71.13;70.27;70.59;3700000;70.59
1962-02-15;70.42;71.06;70.23;70.74;3470000;70.74
1962-02-14;70.45;70.79;70.03;70.42;3630000;70.42
1962-02-13;70.46;70.89;70.07;70.45;3400000;70.45
1962-02-12;70.48;70.81;70.14;70.46;2620000;70.46
1962-02-09;70.58;70.83;69.93;70.48;3370000;70.48
1962-02-08;70.42;70.95;70.16;70.58;3810000;70.58
1962-02-07;69.96;70.67;69.78;70.42;4140000;70.42
1962-02-06;69.88;70.32;69.41;69.96;3650000;69.96
1962-02-05;69.81;70.30;69.42;69.88;3890000;69.88
1962-02-02;69.26;70.02;69.02;69.81;3950000;69.81
1962-02-01;68.84;69.65;68.56;69.26;4260000;69.26
1962-01-31;68.17;69.09;68.12;68.84;3840000;68.84
1962-01-30;67.90;68.65;67.62;68.17;3520000;68.17
1962-01-29;68.13;68.50;67.55;67.90;3050000;67.90
1962-01-26;68.35;68.67;67.83;68.13;3330000;68.13
1962-01-25;68.40;69.05;68.10;68.35;3560000;68.35
1962-01-24;68.29;68.68;67.55;68.40;3760000;68.40
1962-01-23;68.81;68.96;68.00;68.29;3350000;68.29
1962-01-22;68.75;69.37;68.45;68.81;3810000;68.81
1962-01-19;68.39;70.08;68.14;68.75;3800000;68.75
1962-01-18;68.32;68.73;67.75;68.39;3460000;68.39
1962-01-17;69.07;69.31;68.13;68.32;3780000;68.32
1962-01-16;69.47;69.61;68.68;69.07;3650000;69.07
1962-01-15;69.61;69.96;69.06;69.47;3450000;69.47
1962-01-12;69.37;70.17;69.23;69.61;3730000;69.61
1962-01-11;68.96;69.54;68.57;69.37;3390000;69.37
1962-01-10;69.15;69.58;68.62;68.96;3300000;68.96
1962-01-09;69.12;69.93;68.83;69.15;3600000;69.15
1962-01-08;69.66;69.84;68.17;69.12;4620000;69.12
1962-01-05;70.64;70.84;69.35;69.66;4630000;69.66
1962-01-04;71.13;71.62;70.45;70.64;4450000;70.64
1962-01-03;70.96;71.48;70.38;71.13;3590000;71.13
1962-01-02;71.55;71.96;70.71;70.96;3120000;70.96
1961-12-29;71.55;71.55;71.55;71.55;5370000;71.55
1961-12-28;71.69;71.69;71.69;71.69;4530000;71.69
1961-12-27;71.65;71.65;71.65;71.65;4170000;71.65
1961-12-26;71.02;71.02;71.02;71.02;3180000;71.02
1961-12-22;70.91;70.91;70.91;70.91;3390000;70.91
1961-12-21;70.86;70.86;70.86;70.86;3440000;70.86
1961-12-20;71.12;71.12;71.12;71.12;3640000;71.12
1961-12-19;71.26;71.26;71.26;71.26;3440000;71.26
1961-12-18;71.76;71.76;71.76;71.76;3810000;71.76
1961-12-15;72.01;72.01;72.01;72.01;3710000;72.01
1961-12-14;71.98;71.98;71.98;71.98;4350000;71.98
1961-12-13;72.53;72.53;72.53;72.53;4890000;72.53
1961-12-12;72.64;72.64;72.64;72.64;4680000;72.64
1961-12-11;72.39;72.39;72.39;72.39;4360000;72.39
1961-12-08;72.04;72.04;72.04;72.04;4010000;72.04
1961-12-07;71.70;71.70;71.70;71.70;3900000;71.70
1961-12-06;71.99;71.99;71.99;71.99;4200000;71.99
1961-12-05;71.93;71.93;71.93;71.93;4330000;71.93
1961-12-04;72.01;72.01;72.01;72.01;4560000;72.01
1961-12-01;71.78;71.78;71.78;71.78;4420000;71.78
1961-11-30;71.32;71.32;71.32;71.32;4210000;71.32
1961-11-29;71.70;71.70;71.70;71.70;4550000;71.70
1961-11-28;71.75;71.75;71.75;71.75;4360000;71.75
1961-11-27;71.85;71.85;71.85;71.85;4700000;71.85
1961-11-24;71.84;71.84;71.84;71.84;4020000;71.84
1961-11-22;71.70;71.70;71.70;71.70;4500000;71.70
1961-11-21;71.78;71.78;71.78;71.78;4890000;71.78
1961-11-20;71.72;71.72;71.72;71.72;4190000;71.72
1961-11-17;71.62;71.62;71.62;71.62;3960000;71.62
1961-11-16;71.62;71.62;71.62;71.62;3980000;71.62
1961-11-15;71.67;71.67;71.67;71.67;4660000;71.67
1961-11-14;71.66;71.66;71.66;71.66;4750000;71.66
1961-11-13;71.27;71.27;71.27;71.27;4540000;71.27
1961-11-10;71.07;71.07;71.07;71.07;4180000;71.07
1961-11-09;70.77;70.77;70.77;70.77;4680000;70.77
1961-11-08;70.87;70.87;70.87;70.87;6090000;70.87
1961-11-06;70.01;70.01;70.01;70.01;4340000;70.01
1961-11-03;69.47;69.47;69.47;69.47;4070000;69.47
1961-11-02;69.11;69.11;69.11;69.11;3890000;69.11
1961-11-01;68.73;68.73;68.73;68.73;3210000;68.73
1961-10-31;68.62;68.62;68.62;68.62;3350000;68.62
1961-10-30;68.42;68.42;68.42;68.42;3430000;68.42
1961-10-27;68.34;68.34;68.34;68.34;3200000;68.34
1961-10-26;68.46;68.46;68.46;68.46;3330000;68.46
1961-10-25;68.34;68.34;68.34;68.34;3590000;68.34
1961-10-24;67.98;67.98;67.98;67.98;3430000;67.98
1961-10-23;68.06;68.06;68.06;68.06;3440000;68.06
1961-10-20;68.00;68.00;68.00;68.00;3470000;68.00
1961-10-19;68.45;68.45;68.45;68.45;3850000;68.45
1961-10-18;68.21;68.21;68.21;68.21;3520000;68.21
1961-10-17;67.87;67.87;67.87;67.87;3110000;67.87
1961-10-16;67.85;67.85;67.85;67.85;2840000;67.85
1961-10-13;68.04;68.04;68.04;68.04;3090000;68.04
1961-10-12;68.16;68.16;68.16;68.16;3060000;68.16
1961-10-11;68.17;68.17;68.17;68.17;3670000;68.17
1961-10-10;68.11;68.11;68.11;68.11;3430000;68.11
1961-10-09;67.94;67.94;67.94;67.94;2920000;67.94
1961-10-06;66.97;66.97;66.97;66.97;3470000;66.97
1961-10-05;67.77;67.77;67.77;67.77;3920000;67.77
1961-10-04;67.18;67.18;67.18;67.18;3380000;67.18
1961-10-03;66.73;66.73;66.73;66.73;2680000;66.73
1961-10-02;66.77;66.77;66.77;66.77;2800000;66.77
1961-09-29;66.73;66.73;66.73;66.73;3060000;66.73
1961-09-28;66.58;66.58;66.58;66.58;3000000;66.58
1961-09-27;66.47;66.47;66.47;66.47;3440000;66.47
1961-09-26;65.78;65.78;65.78;65.78;3320000;65.78
1961-09-25;65.77;65.77;65.77;65.77;3700000;65.77
1961-09-22;66.72;66.72;66.72;66.72;3070000;66.72
1961-09-21;66.99;66.99;66.99;66.99;3340000;66.99
1961-09-20;66.96;66.96;66.96;66.96;2700000;66.96
1961-09-19;66.08;66.08;66.08;66.08;3260000;66.08
1961-09-18;67.21;67.21;67.21;67.21;3550000;67.21
1961-09-15;67.65;67.65;67.65;67.65;3130000;67.65
1961-09-14;67.53;67.53;67.53;67.53;2920000;67.53
1961-09-13;68.01;68.01;68.01;68.01;3110000;68.01
1961-09-12;67.96;67.96;67.96;67.96;2950000;67.96
1961-09-11;67.28;67.28;67.28;67.28;2790000;67.28
1961-09-08;67.88;67.88;67.88;67.88;3430000;67.88
1961-09-07;68.35;68.35;68.35;68.35;3900000;68.35
1961-09-06;68.46;68.46;68.46;68.46;3440000;68.46
1961-09-05;67.96;67.96;67.96;67.96;3000000;67.96
1961-09-01;68.19;68.19;68.19;68.19;2710000;68.19
1961-08-31;68.07;68.07;68.07;68.07;2920000;68.07
1961-08-30;67.81;67.81;67.81;67.81;3220000;67.81
1961-08-29;67.55;67.55;67.55;67.55;3160000;67.55
1961-08-28;67.70;67.70;67.70;67.70;3150000;67.70
1961-08-25;67.67;67.67;67.67;67.67;3050000;67.67
1961-08-24;67.59;67.59;67.59;67.59;3090000;67.59
1961-08-23;67.98;67.98;67.98;67.98;3550000;67.98
1961-08-22;68.44;68.44;68.44;68.44;3640000;68.44
1961-08-21;68.43;68.43;68.43;68.43;3880000;68.43
1961-08-18;68.29;68.29;68.29;68.29;4030000;68.29
1961-08-17;68.11;68.11;68.11;68.11;4130000;68.11
1961-08-16;67.73;67.73;67.73;67.73;3430000;67.73
1961-08-15;67.55;67.55;67.55;67.55;3320000;67.55
1961-08-14;67.72;67.72;67.72;67.72;3120000;67.72
1961-08-11;68.06;68.06;68.06;68.06;3260000;68.06
1961-08-10;67.95;67.95;67.95;67.95;3570000;67.95
1961-08-09;67.74;67.74;67.74;67.74;3710000;67.74
1961-08-08;67.82;67.82;67.82;67.82;4050000;67.82
1961-08-07;67.67;67.67;67.67;67.67;3560000;67.67
1961-08-04;67.68;67.68;67.68;67.68;3710000;67.68
1961-08-03;67.29;67.29;67.29;67.29;3650000;67.29
1961-08-02;66.94;66.94;66.94;66.94;4300000;66.94
1961-08-01;67.37;67.37;67.37;67.37;3990000;67.37
1961-07-31;66.76;66.76;66.76;66.76;3170000;66.76
1961-07-28;66.71;66.71;66.71;66.71;3610000;66.71
1961-07-27;66.61;66.61;66.61;66.61;4170000;66.61
1961-07-26;65.84;65.84;65.84;65.84;4070000;65.84
1961-07-25;65.23;65.23;65.23;65.23;3010000;65.23
1961-07-24;64.87;64.87;64.87;64.87;2490000;64.87
1961-07-21;64.86;64.86;64.86;64.86;2360000;64.86
1961-07-20;64.71;64.71;64.71;64.71;2530000;64.71
1961-07-19;64.70;64.70;64.70;64.70;2940000;64.70
1961-07-18;64.41;64.41;64.41;64.41;3010000;64.41
1961-07-17;64.79;64.79;64.79;64.79;2690000;64.79
1961-07-14;65.28;65.28;65.28;65.28;2760000;65.28
1961-07-13;64.86;64.86;64.86;64.86;2670000;64.86
1961-07-12;65.32;65.32;65.32;65.32;3070000;65.32
1961-07-11;65.69;65.69;65.69;65.69;3160000;65.69
1961-07-10;65.71;65.71;65.71;65.71;3180000;65.71
1961-07-07;65.77;65.77;65.77;65.77;3030000;65.77
1961-07-06;65.81;65.81;65.81;65.81;3470000;65.81
1961-07-05;65.63;65.63;65.63;65.63;3270000;65.63
1961-07-03;65.21;65.21;65.21;65.21;2180000;65.21
1961-06-30;64.64;64.64;64.64;64.64;2380000;64.64
1961-06-29;64.52;64.52;64.52;64.52;2560000;64.52
1961-06-28;64.59;64.59;64.59;64.59;2830000;64.59
1961-06-27;64.47;64.47;64.47;64.47;3090000;64.47
1961-06-26;64.47;64.47;64.47;64.47;2690000;64.47
1961-06-23;65.16;65.16;65.16;65.16;2720000;65.16
1961-06-22;64.90;64.90;64.90;64.90;2880000;64.90
1961-06-21;65.14;65.14;65.14;65.14;3210000;65.14
1961-06-20;65.15;65.15;65.15;65.15;3280000;65.15
1961-06-19;64.58;64.58;64.58;64.58;3980000;64.58
1961-06-16;65.18;65.18;65.18;65.18;3380000;65.18
1961-06-15;65.69;65.69;65.69;65.69;3220000;65.69
1961-06-14;65.98;65.98;65.98;65.98;3430000;65.98
1961-06-13;65.80;65.80;65.80;65.80;3030000;65.80
1961-06-12;66.15;66.15;66.15;66.15;3260000;66.15
1961-06-09;66.66;66.66;66.66;66.66;3520000;66.66
1961-06-08;66.67;66.67;66.67;66.67;3810000;66.67
1961-06-07;65.64;65.64;65.64;65.64;3980000;65.64
1961-06-06;66.89;66.89;66.89;66.89;4250000;66.89
1961-06-05;67.08;67.08;67.08;67.08;4150000;67.08
1961-06-02;66.73;66.73;66.73;66.73;3670000;66.73
1961-06-01;66.56;66.56;66.56;66.56;3770000;66.56
1961-05-31;66.56;66.56;66.56;66.56;4320000;66.56
1961-05-26;66.43;66.43;66.43;66.43;3780000;66.43
1961-05-25;66.01;66.01;66.01;66.01;3760000;66.01
1961-05-24;66.26;66.26;66.26;66.26;3970000;66.26
1961-05-23;66.68;66.68;66.68;66.68;3660000;66.68
1961-05-22;66.85;66.85;66.85;66.85;4070000;66.85
1961-05-19;67.27;67.27;67.27;67.27;4200000;67.27
1961-05-18;66.99;66.99;66.99;66.99;4610000;66.99
1961-05-17;67.39;67.39;67.39;67.39;5520000;67.39
1961-05-16;67.08;67.08;67.08;67.08;5110000;67.08
1961-05-15;66.83;66.83;66.83;66.83;4840000;66.83
1961-05-12;66.50;66.50;66.50;66.50;4840000;66.50
1961-05-11;66.39;66.39;66.39;66.39;5170000;66.39
1961-05-10;66.41;66.41;66.41;66.41;5450000;66.41
1961-05-09;66.47;66.47;66.47;66.47;5380000;66.47
1961-05-08;66.41;66.41;66.41;66.41;5170000;66.41
1961-05-05;66.52;66.52;66.52;66.52;4980000;66.52
1961-05-04;66.44;66.44;66.44;66.44;5350000;66.44
1961-05-03;66.18;66.18;66.18;66.18;4940000;66.18
1961-05-02;65.64;65.64;65.64;65.64;4110000;65.64
1961-05-01;65.17;65.17;65.17;65.17;3710000;65.17
1961-04-28;65.31;65.31;65.31;65.31;3710000;65.31
1961-04-27;65.46;65.46;65.46;65.46;4450000;65.46
1961-04-26;65.55;65.55;65.55;65.55;4980000;65.55
1961-04-25;65.30;65.30;65.30;65.30;4670000;65.30
1961-04-24;64.40;64.40;64.40;64.40;4590000;64.40
1961-04-21;65.77;65.77;65.77;65.77;4340000;65.77
1961-04-20;65.82;65.82;65.82;65.82;4810000;65.82
1961-04-19;65.81;65.81;65.81;65.81;4870000;65.81
1961-04-18;66.20;66.20;66.20;66.20;4830000;66.20
1961-04-17;68.68;68.68;68.68;68.68;5860000;68.68
1961-04-14;66.37;66.37;66.37;66.37;5240000;66.37
1961-04-13;66.26;66.26;66.26;66.26;4770000;66.26
1961-04-12;66.31;66.31;66.31;66.31;4870000;66.31
1961-04-11;66.62;66.62;66.62;66.62;5230000;66.62
1961-04-10;66.53;66.53;66.53;66.53;5550000;66.53
1961-04-07;65.96;65.96;65.96;65.96;5100000;65.96
1961-04-06;65.61;65.61;65.61;65.61;4910000;65.61
1961-04-05;65.46;65.46;65.46;65.46;5430000;65.46
1961-04-04;65.66;65.66;65.66;65.66;7080000;65.66
1961-04-03;65.60;65.60;65.60;65.60;6470000;65.60
1961-03-30;65.06;65.06;65.06;65.06;5610000;65.06
1961-03-29;64.93;64.93;64.93;64.93;5330000;64.93
1961-03-28;64.38;64.38;64.38;64.38;4630000;64.38
1961-03-27;64.35;64.35;64.35;64.35;4190000;64.35
1961-03-24;64.42;64.42;64.42;64.42;4390000;64.42
1961-03-23;64.53;64.53;64.53;64.53;2170000;64.53
1961-03-22;64.70;64.70;64.70;64.70;5840000;64.70
1961-03-21;64.74;64.74;64.74;64.74;5800000;64.74
1961-03-20;64.86;64.86;64.86;64.86;5780000;64.86
1961-03-17;64.00;64.00;64.00;64.00;5960000;64.00
1961-03-16;64.21;64.21;64.21;64.21;5610000;64.21
1961-03-15;63.57;63.57;63.57;63.57;4900000;63.57
1961-03-14;63.38;63.38;63.38;63.38;4900000;63.38
1961-03-13;63.66;63.66;63.66;63.66;5080000;63.66
1961-03-10;63.48;63.48;63.48;63.48;5950000;63.48
1961-03-09;63.50;63.50;63.50;63.50;6010000;63.50
1961-03-08;63.44;63.44;63.44;63.44;5910000;63.44
1961-03-07;63.47;63.47;63.47;63.47;5540000;63.47
1961-03-06;64.05;64.05;64.05;64.05;5650000;64.05
1961-03-03;63.95;63.95;63.95;63.95;5530000;63.95
1961-03-02;63.85;63.85;63.85;63.85;5300000;63.85
1961-03-01;63.43;63.43;63.43;63.43;4970000;63.43
1961-02-28;63.44;63.44;63.44;63.44;5830000;63.44
1961-02-27;63.30;63.30;63.30;63.30;5470000;63.30
1961-02-24;62.84;62.84;62.84;62.84;5330000;62.84
1961-02-23;62.59;62.59;62.59;62.59;5620000;62.59
1961-02-21;62.36;62.36;62.36;62.36;5070000;62.36
1961-02-20;62.32;62.32;62.32;62.32;4680000;62.32
1961-02-17;62.10;62.10;62.10;62.10;4640000;62.10
1961-02-16;62.30;62.30;62.30;62.30;5070000;62.30
1961-02-15;61.92;61.92;61.92;61.92;5200000;61.92
1961-02-14;61.41;61.41;61.41;61.41;4490000;61.41
1961-02-13;61.14;61.14;61.14;61.14;3560000;61.14
1961-02-10;61.50;61.50;61.50;61.50;4840000;61.50
1961-02-09;62.02;62.02;62.02;62.02;5590000;62.02
1961-02-08;62.21;62.21;62.21;62.21;4940000;62.21
1961-02-07;61.65;61.65;61.65;61.65;4020000;61.65
1961-02-06;61.76;61.76;61.76;61.76;3890000;61.76
1961-02-03;62.22;62.22;62.22;62.22;5210000;62.22
1961-02-02;62.30;62.30;62.30;62.30;4900000;62.30
1961-02-01;61.90;61.90;61.90;61.90;4380000;61.90
1961-01-31;61.78;61.78;61.78;61.78;4690000;61.78
1961-01-30;61.97;61.97;61.97;61.97;5190000;61.97
1961-01-27;61.24;61.24;61.24;61.24;4510000;61.24
1961-01-26;60.62;60.62;60.62;60.62;4110000;60.62
1961-01-25;60.53;60.53;60.53;60.53;4470000;60.53
1961-01-24;60.45;60.45;60.45;60.45;4280000;60.45
1961-01-23;60.29;60.29;60.29;60.29;4450000;60.29
1961-01-20;59.96;59.96;59.96;59.96;3270000;59.96
1961-01-19;59.77;59.77;59.77;59.77;4740000;59.77
1961-01-18;59.68;59.68;59.68;59.68;4390000;59.68
1961-01-17;59.64;59.64;59.64;59.64;3830000;59.64
1961-01-16;59.58;59.58;59.58;59.58;4510000;59.58
1961-01-13;59.60;59.60;59.60;59.60;4520000;59.60
1961-01-12;59.32;59.32;59.32;59.32;4270000;59.32
1961-01-11;59.14;59.14;59.14;59.14;4370000;59.14
1961-01-10;58.97;58.97;58.97;58.97;4840000;58.97
1961-01-09;58.81;58.81;58.81;58.81;4210000;58.81
1961-01-06;58.40;58.40;58.40;58.40;3620000;58.40
1961-01-05;58.57;58.57;58.57;58.57;4130000;58.57
1961-01-04;58.36;58.36;58.36;58.36;3840000;58.36
1961-01-03;57.57;57.57;57.57;57.57;2770000;57.57
1960-12-30;58.11;58.11;58.11;58.11;5300000;58.11
1960-12-29;58.05;58.05;58.05;58.05;4340000;58.05
1960-12-28;57.78;57.78;57.78;57.78;3620000;57.78
1960-12-27;57.52;57.52;57.52;57.52;3270000;57.52
1960-12-23;57.44;57.44;57.44;57.44;3580000;57.44
1960-12-22;57.39;57.39;57.39;57.39;3820000;57.39
1960-12-21;57.55;57.55;57.55;57.55;4060000;57.55
1960-12-20;57.09;57.09;57.09;57.09;3340000;57.09
1960-12-19;57.13;57.13;57.13;57.13;3630000;57.13
1960-12-16;57.20;57.20;57.20;57.20;3770000;57.20
1960-12-15;56.68;56.68;56.68;56.68;3660000;56.68
1960-12-14;56.84;56.84;56.84;56.84;3880000;56.84
1960-12-13;56.88;56.88;56.88;56.88;3500000;56.88
1960-12-12;56.85;56.85;56.85;56.85;3020000;56.85
1960-12-09;56.65;56.65;56.65;56.65;4460000;56.65
1960-12-08;56.15;56.15;56.15;56.15;3540000;56.15
1960-12-07;56.02;56.02;56.02;56.02;3660000;56.02
1960-12-06;55.47;55.47;55.47;55.47;3360000;55.47
1960-12-05;55.31;55.31;55.31;55.31;3290000;55.31
1960-12-02;55.39;55.39;55.39;55.39;3140000;55.39
1960-12-01;55.30;55.30;55.30;55.30;3090000;55.30
1960-11-30;55.54;55.54;55.54;55.54;3080000;55.54
1960-11-29;55.83;55.83;55.83;55.83;3630000;55.83
1960-11-28;56.03;56.03;56.03;56.03;3860000;56.03
1960-11-25;56.13;56.13;56.13;56.13;3190000;56.13
1960-11-23;55.80;55.80;55.80;55.80;3000000;55.80
1960-11-22;55.72;55.72;55.72;55.72;3430000;55.72
1960-11-21;55.93;55.93;55.93;55.93;3090000;55.93
1960-11-18;55.82;55.82;55.82;55.82;2760000;55.82
1960-11-17;55.55;55.55;55.55;55.55;2450000;55.55
1960-11-16;55.70;55.70;55.70;55.70;3110000;55.70
1960-11-15;55.81;55.81;55.81;55.81;2990000;55.81
1960-11-14;55.59;55.59;55.59;55.59;2660000;55.59
1960-11-11;55.87;55.87;55.87;55.87;2730000;55.87
1960-11-10;56.43;56.43;56.43;56.43;4030000;56.43
1960-11-09;55.35;55.35;55.35;55.35;3450000;55.35
1960-11-07;55.11;55.11;55.11;55.11;3540000;55.11
1960-11-04;54.90;54.90;54.90;54.90;3050000;54.90
1960-11-03;54.43;54.43;54.43;54.43;2580000;54.43
1960-11-02;54.22;54.22;54.22;54.22;2780000;54.22
1960-11-01;53.94;53.94;53.94;53.94;2600000;53.94
1960-10-31;53.39;53.39;53.39;53.39;2460000;53.39
1960-10-28;53.41;53.41;53.41;53.41;2490000;53.41
1960-10-27;53.62;53.62;53.62;53.62;2900000;53.62
1960-10-26;53.05;53.05;53.05;53.05;3020000;53.05
1960-10-25;52.20;52.20;52.20;52.20;3030000;52.20
1960-10-24;52.70;52.70;52.70;52.70;4420000;52.70
1960-10-21;53.72;53.72;53.72;53.72;3090000;53.72
1960-10-20;53.86;53.86;53.86;53.86;2910000;53.86
1960-10-19;54.25;54.25;54.25;54.25;2410000;54.25
1960-10-18;54.35;54.35;54.35;54.35;2220000;54.35
1960-10-17;54.63;54.63;54.63;54.63;2280000;54.63
1960-10-14;54.86;54.86;54.86;54.86;2470000;54.86
1960-10-13;54.57;54.57;54.57;54.57;2220000;54.57
1960-10-12;54.15;54.15;54.15;54.15;1890000;54.15
1960-10-11;54.22;54.22;54.22;54.22;2350000;54.22
1960-10-10;54.14;54.14;54.14;54.14;2030000;54.14
1960-10-07;54.03;54.03;54.03;54.03;2530000;54.03
1960-10-06;53.72;53.72;53.72;53.72;2510000;53.72
1960-10-05;53.39;53.39;53.39;53.39;2650000;53.39
1960-10-04;52.99;52.99;52.99;52.99;2270000;52.99
1960-10-03;53.36;53.36;53.36;53.36;2220000;53.36
1960-09-30;53.52;53.52;53.52;53.52;3370000;53.52
1960-09-29;52.62;52.62;52.62;52.62;2850000;52.62
1960-09-28;52.48;52.48;52.48;52.48;3520000;52.48
1960-09-27;52.94;52.94;52.94;52.94;3170000;52.94
1960-09-26;53.06;53.06;53.06;53.06;3930000;53.06
1960-09-23;53.90;53.90;53.90;53.90;2580000;53.90
1960-09-22;54.36;54.36;54.36;54.36;1970000;54.36
1960-09-21;54.57;54.57;54.57;54.57;2930000;54.57
1960-09-20;54.01;54.01;54.01;54.01;3660000;54.01
1960-09-19;53.86;53.86;53.86;53.86;3790000;53.86
1960-09-16;55.11;55.11;55.11;55.11;2340000;55.11
1960-09-15;55.22;55.22;55.22;55.22;2870000;55.22
1960-09-14;55.44;55.44;55.44;55.44;2530000;55.44
1960-09-13;55.83;55.83;55.83;55.83;2180000;55.83
1960-09-12;55.72;55.72;55.72;55.72;2160000;55.72
1960-09-09;56.11;56.11;56.11;56.11;2750000;56.11
1960-09-08;55.74;55.74;55.74;55.74;2670000;55.74
1960-09-07;55.79;55.79;55.79;55.79;2850000;55.79
1960-09-06;56.49;56.49;56.49;56.49;2580000;56.49
1960-09-02;57.00;57.00;57.00;57.00;2680000;57.00
1960-09-01;57.09;57.09;57.09;57.09;3460000;57.09
1960-08-31;56.96;56.96;56.96;56.96;3130000;56.96
1960-08-30;56.84;56.84;56.84;56.84;2890000;56.84
1960-08-29;57.44;57.44;57.44;57.44;2780000;57.44
1960-08-26;57.60;57.60;57.60;57.60;2780000;57.60
1960-08-25;57.79;57.79;57.79;57.79;2680000;57.79
1960-08-24;58.07;58.07;58.07;58.07;3500000;58.07
1960-08-23;57.75;57.75;57.75;57.75;3560000;57.75
1960-08-22;57.19;57.19;57.19;57.19;2760000;57.19
1960-08-19;57.01;57.01;57.01;57.01;2570000;57.01
1960-08-18;56.81;56.81;56.81;56.81;2890000;56.81
1960-08-17;56.84;56.84;56.84;56.84;3090000;56.84
1960-08-16;56.72;56.72;56.72;56.72;2710000;56.72
1960-08-15;56.61;56.61;56.61;56.61;2450000;56.61
1960-08-12;56.66;56.66;56.66;56.66;3160000;56.66
1960-08-11;56.28;56.28;56.28;56.28;3070000;56.28
1960-08-10;56.07;56.07;56.07;56.07;2810000;56.07
1960-08-09;55.84;55.84;55.84;55.84;2700000;55.84
1960-08-08;55.52;55.52;55.52;55.52;2960000;55.52
1960-08-05;55.44;55.44;55.44;55.44;3000000;55.44
1960-08-04;54.89;54.89;54.89;54.89;2840000;54.89
1960-08-03;54.72;54.72;54.72;54.72;2470000;54.72
1960-08-02;55.04;55.04;55.04;55.04;2090000;55.04
1960-08-01;55.53;55.53;55.53;55.53;2440000;55.53
1960-07-29;55.51;55.51;55.51;55.51;2730000;55.51
1960-07-28;54.57;54.57;54.57;54.57;3020000;54.57
1960-07-27;54.17;54.17;54.17;54.17;2560000;54.17
1960-07-26;54.51;54.51;54.51;54.51;2720000;54.51
1960-07-25;54.18;54.18;54.18;54.18;2840000;54.18
1960-07-22;54.72;54.72;54.72;54.72;2850000;54.72
1960-07-21;55.10;55.10;55.10;55.10;2510000;55.10
1960-07-20;55.61;55.61;55.61;55.61;2370000;55.61
1960-07-19;55.70;55.70;55.70;55.70;2490000;55.70
1960-07-18;55.70;55.70;55.70;55.70;2350000;55.70
1960-07-15;56.05;56.05;56.05;56.05;2140000;56.05
1960-07-14;56.12;56.12;56.12;56.12;2480000;56.12
1960-07-13;56.10;56.10;56.10;56.10;2590000;56.10
1960-07-12;56.25;56.25;56.25;56.25;2860000;56.25
1960-07-11;56.87;56.87;56.87;56.87;2920000;56.87
1960-07-08;57.38;57.38;57.38;57.38;3010000;57.38
1960-07-07;57.24;57.24;57.24;57.24;3050000;57.24
1960-07-06;56.94;56.94;56.94;56.94;2970000;56.94
1960-07-05;57.02;57.02;57.02;57.02;2780000;57.02
1960-07-01;57.06;57.06;57.06;57.06;2620000;57.06
1960-06-30;56.92;56.92;56.92;56.92;2940000;56.92
1960-06-29;56.94;56.94;56.94;56.94;3160000;56.94
1960-06-28;56.94;56.94;56.94;56.94;3120000;56.94
1960-06-27;57.33;57.33;57.33;57.33;2960000;57.33
1960-06-24;57.68;57.68;57.68;57.68;3220000;57.68
1960-06-23;57.59;57.59;57.59;57.59;3620000;57.59
1960-06-22;57.28;57.28;57.28;57.28;3600000;57.28
1960-06-21;57.11;57.11;57.11;57.11;3860000;57.11
1960-06-20;57.16;57.16;57.16;57.16;3970000;57.16
1960-06-17;57.44;57.44;57.44;57.44;3920000;57.44
1960-06-16;57.50;57.50;57.50;57.50;3540000;57.50
1960-06-15;57.57;57.57;57.57;57.57;3630000;57.57
1960-06-14;57.91;57.91;57.91;57.91;3430000;57.91
1960-06-13;57.99;57.99;57.99;57.99;3180000;57.99
1960-06-10;57.97;57.97;57.97;57.97;2940000;57.97
1960-06-09;58.00;58.00;58.00;58.00;3820000;58.00
1960-06-08;57.89;57.89;57.89;57.89;3800000;57.89
1960-06-07;57.43;57.43;57.43;57.43;3710000;57.43
1960-06-06;56.89;56.89;56.89;56.89;3220000;56.89
1960-06-03;56.23;56.23;56.23;56.23;3340000;56.23
1960-06-02;56.13;56.13;56.13;56.13;3730000;56.13
1960-06-01;55.89;55.89;55.89;55.89;3770000;55.89
1960-05-31;55.83;55.83;55.83;55.83;3750000;55.83
1960-05-27;55.74;55.74;55.74;55.74;3040000;55.74
1960-05-26;55.71;55.71;55.71;55.71;3720000;55.71
1960-05-25;55.67;55.67;55.67;55.67;3440000;55.67
1960-05-24;55.70;55.70;55.70;55.70;3240000;55.70
1960-05-23;55.76;55.76;55.76;55.76;2530000;55.76
1960-05-20;55.73;55.73;55.73;55.73;3170000;55.73
1960-05-19;55.68;55.68;55.68;55.68;3700000;55.68
1960-05-18;55.44;55.44;55.44;55.44;5240000;55.44
1960-05-17;55.46;55.46;55.46;55.46;4080000;55.46
1960-05-16;55.25;55.25;55.25;55.25;3530000;55.25
1960-05-13;55.30;55.30;55.30;55.30;3750000;55.30
1960-05-12;54.85;54.85;54.85;54.85;3220000;54.85
1960-05-11;54.57;54.57;54.57;54.57;2900000;54.57
1960-05-10;54.42;54.42;54.42;54.42;2870000;54.42
1960-05-09;54.80;54.80;54.80;54.80;2670000;54.80
1960-05-06;54.75;54.75;54.75;54.75;2560000;54.75
1960-05-05;54.86;54.86;54.86;54.86;2670000;54.86
1960-05-04;55.04;55.04;55.04;55.04;2870000;55.04
1960-05-03;54.83;54.83;54.83;54.83;2910000;54.83
1960-05-02;54.13;54.13;54.13;54.13;2930000;54.13
1960-04-29;54.37;54.37;54.37;54.37;2850000;54.37
1960-04-28;54.56;54.56;54.56;54.56;3190000;54.56
1960-04-27;55.04;55.04;55.04;55.04;3020000;55.04
1960-04-26;55.04;55.04;55.04;55.04;2940000;55.04
1960-04-25;54.86;54.86;54.86;54.86;2980000;54.86
1960-04-22;55.42;55.42;55.42;55.42;2850000;55.42
1960-04-21;55.59;55.59;55.59;55.59;2700000;55.59
1960-04-20;55.44;55.44;55.44;55.44;3150000;55.44
1960-04-19;56.13;56.13;56.13;56.13;3080000;56.13
1960-04-18;56.59;56.59;56.59;56.59;3200000;56.59
1960-04-14;56.43;56.43;56.43;56.43;2730000;56.43
1960-04-13;56.30;56.30;56.30;56.30;2730000;56.30
1960-04-12;56.30;56.30;56.30;56.30;2470000;56.30
1960-04-11;56.17;56.17;56.17;56.17;2520000;56.17
1960-04-08;56.39;56.39;56.39;56.39;2820000;56.39
1960-04-07;56.52;56.52;56.52;56.52;3070000;56.52
1960-04-06;56.51;56.51;56.51;56.51;3450000;56.51
1960-04-05;55.37;55.37;55.37;55.37;2840000;55.37
1960-04-04;55.54;55.54;55.54;55.54;2450000;55.54
1960-04-01;55.43;55.43;55.43;55.43;2260000;55.43
1960-03-31;55.34;55.34;55.34;55.34;2690000;55.34
1960-03-30;55.66;55.66;55.66;55.66;2450000;55.66
1960-03-29;55.78;55.78;55.78;55.78;2320000;55.78
1960-03-28;55.86;55.86;55.86;55.86;2500000;55.86
1960-03-25;55.98;55.98;55.98;55.98;2640000;55.98
1960-03-24;55.98;55.98;55.98;55.98;2940000;55.98
1960-03-23;55.74;55.74;55.74;55.74;3020000;55.74
1960-03-22;55.29;55.29;55.29;55.29;2490000;55.29
1960-03-21;55.07;55.07;55.07;55.07;2500000;55.07
1960-03-18;55.01;55.01;55.01;55.01;2620000;55.01
1960-03-17;54.96;54.96;54.96;54.96;2140000;54.96
1960-03-16;55.04;55.04;55.04;55.04;2960000;55.04
1960-03-15;54.74;54.74;54.74;54.74;2690000;54.74
1960-03-14;54.32;54.32;54.32;54.32;2530000;54.32
1960-03-11;54.24;54.24;54.24;54.24;2770000;54.24
1960-03-10;53.83;53.83;53.83;53.83;3350000;53.83
1960-03-09;54.04;54.04;54.04;54.04;3580000;54.04
1960-03-08;53.47;53.47;53.47;53.47;3370000;53.47
1960-03-07;54.02;54.02;54.02;54.02;2900000;54.02
1960-03-04;54.57;54.57;54.57;54.57;4060000;54.57
1960-03-03;54.78;54.78;54.78;54.78;3160000;54.78
1960-03-02;55.62;55.62;55.62;55.62;3110000;55.62
1960-03-01;56.01;56.01;56.01;56.01;2920000;56.01
1960-02-29;56.12;56.12;56.12;56.12;2990000;56.12
1960-02-26;56.16;56.16;56.16;56.16;3380000;56.16
1960-02-25;55.93;55.93;55.93;55.93;3600000;55.93
1960-02-24;55.74;55.74;55.74;55.74;2740000;55.74
1960-02-23;55.94;55.94;55.94;55.94;2960000;55.94
1960-02-19;56.24;56.24;56.24;56.24;3230000;56.24
1960-02-18;55.80;55.80;55.80;55.80;3800000;55.80
1960-02-17;55.03;55.03;55.03;55.03;4210000;55.03
1960-02-16;54.73;54.73;54.73;54.73;3270000;54.73
1960-02-15;55.17;55.17;55.17;55.17;2780000;55.17
1960-02-12;55.46;55.46;55.46;55.46;2230000;55.46
1960-02-11;55.18;55.18;55.18;55.18;2610000;55.18
1960-02-10;55.49;55.49;55.49;55.49;2440000;55.49
1960-02-09;55.84;55.84;55.84;55.84;2860000;55.84
1960-02-08;55.32;55.32;55.32;55.32;3350000;55.32
1960-02-05;55.98;55.98;55.98;55.98;2530000;55.98
1960-02-04;56.27;56.27;56.27;56.27;2600000;56.27
1960-02-03;56.32;56.32;56.32;56.32;3020000;56.32
1960-02-02;56.82;56.82;56.82;56.82;3080000;56.82
1960-02-01;55.96;55.96;55.96;55.96;2820000;55.96
1960-01-29;55.61;55.61;55.61;55.61;3060000;55.61
1960-01-28;56.13;56.13;56.13;56.13;2630000;56.13
1960-01-27;56.72;56.72;56.72;56.72;2460000;56.72
1960-01-26;56.86;56.86;56.86;56.86;3060000;56.86
1960-01-25;56.78;56.78;56.78;56.78;2790000;56.78
1960-01-22;57.38;57.38;57.38;57.38;2690000;57.38
1960-01-21;57.21;57.21;57.21;57.21;2700000;57.21
1960-01-20;57.07;57.07;57.07;57.07;2720000;57.07
1960-01-19;57.27;57.27;57.27;57.27;3100000;57.27
1960-01-18;57.89;57.89;57.89;57.89;3020000;57.89
1960-01-15;58.38;58.38;58.38;58.38;3400000;58.38
1960-01-14;58.40;58.40;58.40;58.40;3560000;58.40
1960-01-13;58.08;58.08;58.08;58.08;3470000;58.08
1960-01-12;58.41;58.41;58.41;58.41;3760000;58.41
1960-01-11;58.77;58.77;58.77;58.77;3470000;58.77
1960-01-08;59.50;59.50;59.50;59.50;3290000;59.50
1960-01-07;59.69;59.69;59.69;59.69;3310000;59.69
1960-01-06;60.13;60.13;60.13;60.13;3730000;60.13
1960-01-05;60.39;60.39;60.39;60.39;3710000;60.39
1960-01-04;59.91;59.91;59.91;59.91;3990000;59.91
1959-12-31;59.89;59.89;59.89;59.89;3810000;59.89
1959-12-30;59.77;59.77;59.77;59.77;3680000;59.77
1959-12-29;59.30;59.30;59.30;59.30;3020000;59.30
1959-12-28;58.98;58.98;58.98;58.98;2830000;58.98
1959-12-24;59.00;59.00;59.00;59.00;2320000;59.00
1959-12-23;58.96;58.96;58.96;58.96;2890000;58.96
1959-12-22;59.14;59.14;59.14;59.14;2930000;59.14
1959-12-21;59.21;59.21;59.21;59.21;3290000;59.21
1959-12-18;59.14;59.14;59.14;59.14;3230000;59.14
1959-12-17;58.86;58.86;58.86;58.86;3040000;58.86
1959-12-16;58.97;58.97;58.97;58.97;3270000;58.97
1959-12-15;58.90;58.90;58.90;58.90;3450000;58.90
1959-12-14;59.04;59.04;59.04;59.04;3100000;59.04
1959-12-11;58.88;58.88;58.88;58.88;2910000;58.88
1959-12-10;59.02;59.02;59.02;59.02;3170000;59.02
1959-12-09;58.97;58.97;58.97;58.97;3430000;58.97
1959-12-08;59.34;59.34;59.34;59.34;3870000;59.34
1959-12-07;58.96;58.96;58.96;58.96;3620000;58.96
1959-12-04;58.85;58.85;58.85;58.85;3590000;58.85
1959-12-03;58.73;58.73;58.73;58.73;3280000;58.73
1959-12-02;58.60;58.60;58.60;58.60;3490000;58.60
1959-12-01;58.70;58.70;58.70;58.70;3990000;58.70
1959-11-30;58.28;58.28;58.28;58.28;3670000;58.28
1959-11-27;57.70;57.70;57.70;57.70;3030000;57.70
1959-11-25;57.44;57.44;57.44;57.44;3550000;57.44
1959-11-24;57.35;57.35;57.35;57.35;3650000;57.35
1959-11-23;57.08;57.08;57.08;57.08;3400000;57.08
1959-11-20;56.97;56.97;56.97;56.97;2960000;56.97
1959-11-19;56.94;56.94;56.94;56.94;3230000;56.94
1959-11-18;56.99;56.99;56.99;56.99;3660000;56.99
1959-11-17;56.38;56.38;56.38;56.38;3570000;56.38
1959-11-16;56.22;56.22;56.22;56.22;3710000;56.22
1959-11-13;56.85;56.85;56.85;56.85;3050000;56.85
1959-11-12;57.17;57.17;57.17;57.17;3600000;57.17
1959-11-11;57.49;57.49;57.49;57.49;2820000;57.49
1959-11-10;57.48;57.48;57.48;57.48;3020000;57.48
1959-11-09;57.50;57.50;57.50;57.50;3700000;57.50
1959-11-06;57.60;57.60;57.60;57.60;3450000;57.60
1959-11-05;57.32;57.32;57.32;57.32;3170000;57.32
1959-11-04;57.26;57.26;57.26;57.26;3940000;57.26
1959-11-02;57.41;57.41;57.41;57.41;3320000;57.41
1959-10-30;57.52;57.52;57.52;57.52;3560000;57.52
1959-10-29;57.41;57.41;57.41;57.41;3890000;57.41
1959-10-28;57.46;57.46;57.46;57.46;3920000;57.46
1959-10-27;57.42;57.42;57.42;57.42;4160000;57.42
1959-10-26;56.94;56.94;56.94;56.94;3580000;56.94
1959-10-23;56.56;56.56;56.56;56.56;2880000;56.56
1959-10-22;56.00;56.00;56.00;56.00;3060000;56.00
1959-10-21;56.55;56.55;56.55;56.55;2730000;56.55
1959-10-20;56.66;56.66;56.66;56.66;2740000;56.66
1959-10-19;57.01;57.01;57.01;57.01;2470000;57.01
1959-10-16;57.33;57.33;57.33;57.33;2760000;57.33
1959-10-15;56.87;56.87;56.87;56.87;2190000;56.87
1959-10-14;56.71;56.71;56.71;56.71;2320000;56.71
1959-10-13;57.16;57.16;57.16;57.16;2530000;57.16
1959-10-12;57.32;57.32;57.32;57.32;1750000;57.32
1959-10-09;57.00;57.00;57.00;57.00;2540000;57.00
1959-10-08;56.81;56.81;56.81;56.81;2510000;56.81
1959-10-07;56.94;56.94;56.94;56.94;2380000;56.94
1959-10-06;57.09;57.09;57.09;57.09;2330000;57.09
1959-10-05;57.14;57.14;57.14;57.14;2100000;57.14
1959-10-02;57.20;57.20;57.20;57.20;2270000;57.20
1959-10-01;56.94;56.94;56.94;56.94;2660000;56.94
1959-09-30;56.88;56.88;56.88;56.88;2850000;56.88
1959-09-29;57.51;57.51;57.51;57.51;3220000;57.51
1959-09-28;57.15;57.15;57.15;57.15;2640000;57.15
1959-09-25;56.73;56.73;56.73;56.73;3280000;56.73
1959-09-24;56.78;56.78;56.78;56.78;3480000;56.78
1959-09-23;55.82;55.82;55.82;55.82;3010000;55.82
1959-09-22;55.14;55.14;55.14;55.14;3000000;55.14
1959-09-21;55.27;55.27;55.27;55.27;3240000;55.27
1959-09-18;56.19;56.19;56.19;56.19;2530000;56.19
1959-09-17;56.41;56.41;56.41;56.41;2090000;56.41
1959-09-16;56.72;56.72;56.72;56.72;2180000;56.72
1959-09-15;56.68;56.68;56.68;56.68;2830000;56.68
1959-09-14;56.99;56.99;56.99;56.99;2590000;56.99
1959-09-11;57.41;57.41;57.41;57.41;2640000;57.41
1959-09-10;56.99;56.99;56.99;56.99;2520000;56.99
1959-09-09;57.29;57.29;57.29;57.29;3030000;57.29
1959-09-08;57.70;57.70;57.70;57.70;2940000;57.70
1959-09-04;58.54;58.54;58.54;58.54;2300000;58.54
1959-09-03;58.26;58.26;58.26;58.26;2330000;58.26
1959-09-02;58.92;58.92;58.92;58.92;2370000;58.92
1959-09-01;58.87;58.87;58.87;58.87;2430000;58.87
1959-08-31;59.60;59.60;59.60;59.60;2140000;59.60
1959-08-28;59.60;59.60;59.60;59.60;1930000;59.60
1959-08-27;59.58;59.58;59.58;59.58;2550000;59.58
1959-08-26;59.07;59.07;59.07;59.07;2210000;59.07
1959-08-25;58.99;58.99;58.99;58.99;1960000;58.99
1959-08-24;58.87;58.87;58.87;58.87;1860000;58.87
1959-08-21;59.08;59.08;59.08;59.08;2000000;59.08
1959-08-20;59.14;59.14;59.14;59.14;2450000;59.14
1959-08-19;58.27;58.27;58.27;58.27;3050000;58.27
1959-08-18;58.62;58.62;58.62;58.62;2280000;58.62
1959-08-17;59.17;59.17;59.17;59.17;1980000;59.17
1959-08-14;59.29;59.29;59.29;59.29;1990000;59.29
1959-08-13;59.15;59.15;59.15;59.15;2020000;59.15
1959-08-12;59.25;59.25;59.25;59.25;2700000;59.25
1959-08-11;59.39;59.39;59.39;59.39;2980000;59.39
1959-08-10;58.62;58.62;58.62;58.62;4190000;58.62
1959-08-07;59.87;59.87;59.87;59.87;2580000;59.87
1959-08-06;60.24;60.24;60.24;60.24;2610000;60.24
1959-08-05;60.30;60.30;60.30;60.30;2630000;60.30
1959-08-04;60.61;60.61;60.61;60.61;2530000;60.61
1959-08-03;60.71;60.71;60.71;60.71;2410000;60.71
1959-07-31;60.51;60.51;60.51;60.51;2270000;60.51
1959-07-30;60.50;60.50;60.50;60.50;3240000;60.50
1959-07-29;60.62;60.62;60.62;60.62;3460000;60.62
1959-07-28;60.32;60.32;60.32;60.32;3190000;60.32
1959-07-27;60.02;60.02;60.02;60.02;2910000;60.02
1959-07-24;59.65;59.65;59.65;59.65;2720000;59.65
1959-07-23;59.67;59.67;59.67;59.67;3310000;59.67
1959-07-22;59.61;59.61;59.61;59.61;3310000;59.61
1959-07-21;59.41;59.41;59.41;59.41;2950000;59.41
1959-07-20;58.91;58.91;58.91;58.91;2500000;58.91
1959-07-17;59.19;59.19;59.19;59.19;2510000;59.19
1959-07-16;59.41;59.41;59.41;59.41;3170000;59.41
1959-07-15;59.59;59.59;59.59;59.59;3280000;59.59
1959-07-14;59.55;59.55;59.55;59.55;3230000;59.55
1959-07-13;59.41;59.41;59.41;59.41;3360000;59.41
1959-07-10;59.91;59.91;59.91;59.91;3600000;59.91
1959-07-09;59.97;59.97;59.97;59.97;3560000;59.97
1959-07-08;60.03;60.03;60.03;60.03;4010000;60.03
1959-07-07;60.01;60.01;60.01;60.01;3840000;60.01
1959-07-06;59.65;59.65;59.65;59.65;3720000;59.65
1959-07-02;59.28;59.28;59.28;59.28;3610000;59.28
1959-07-01;58.97;58.97;58.97;58.97;3150000;58.97
1959-06-30;58.47;58.47;58.47;58.47;3200000;58.47
1959-06-29;58.37;58.37;58.37;58.37;3000000;58.37
1959-06-26;57.98;57.98;57.98;57.98;3100000;57.98
1959-06-25;57.73;57.73;57.73;57.73;3250000;57.73
1959-06-24;57.41;57.41;57.41;57.41;3180000;57.41
1959-06-23;57.12;57.12;57.12;57.12;2600000;57.12
1959-06-22;57.13;57.13;57.13;57.13;2630000;57.13
1959-06-19;57.13;57.13;57.13;57.13;2260000;57.13
1959-06-18;57.05;57.05;57.05;57.05;3150000;57.05
1959-06-17;57.09;57.09;57.09;57.09;2850000;57.09
1959-06-16;56.56;56.56;56.56;56.56;2440000;56.56
1959-06-15;56.99;56.99;56.99;56.99;2410000;56.99
1959-06-12;57.29;57.29;57.29;57.29;2580000;57.29
1959-06-11;57.25;57.25;57.25;57.25;3120000;57.25
1959-06-10;57.19;57.19;57.19;57.19;3310000;57.19
1959-06-09;56.36;56.36;56.36;56.36;3490000;56.36
1959-06-08;56.76;56.76;56.76;56.76;2970000;56.76
1959-06-05;57.51;57.51;57.51;57.51;2800000;57.51
1959-06-04;57.63;57.63;57.63;57.63;3210000;57.63
1959-06-03;58.25;58.25;58.25;58.25;2910000;58.25
1959-06-02;58.23;58.23;58.23;58.23;3120000;58.23
1959-06-01;58.63;58.63;58.63;58.63;2730000;58.63
1959-05-29;58.68;58.68;58.68;58.68;2790000;58.68
1959-05-28;58.39;58.39;58.39;58.39;2970000;58.39
1959-05-27;58.19;58.19;58.19;58.19;2940000;58.19
1959-05-26;58.09;58.09;58.09;58.09;2910000;58.09
1959-05-25;58.18;58.18;58.18;58.18;3260000;58.18
1959-05-22;58.33;58.33;58.33;58.33;3030000;58.33
1959-05-21;58.14;58.14;58.14;58.14;3230000;58.14
1959-05-20;58.09;58.09;58.09;58.09;3550000;58.09
1959-05-19;58.32;58.32;58.32;58.32;3170000;58.32
1959-05-18;58.15;58.15;58.15;58.15;2970000;58.15
1959-05-15;58.16;58.16;58.16;58.16;3510000;58.16
1959-05-14;58.37;58.37;58.37;58.37;3660000;58.37
1959-05-13;57.97;57.97;57.97;57.97;3540000;57.97
1959-05-12;57.96;57.96;57.96;57.96;3550000;57.96
1959-05-11;57.96;57.96;57.96;57.96;3860000;57.96
1959-05-08;57.32;57.32;57.32;57.32;3930000;57.32
1959-05-07;56.88;56.88;56.88;56.88;4530000;56.88
1959-05-06;57.61;57.61;57.61;57.61;4110000;57.61
1959-05-05;57.75;57.75;57.75;57.75;3360000;57.75
1959-05-04;57.65;57.65;57.65;57.65;3060000;57.65
1959-05-01;57.65;57.65;57.65;57.65;3020000;57.65
1959-04-30;57.59;57.59;57.59;57.59;3510000;57.59
1959-04-29;57.69;57.69;57.69;57.69;3470000;57.69
1959-04-28;57.92;57.92;57.92;57.92;3920000;57.92
1959-04-27;58.14;58.14;58.14;58.14;3850000;58.14
1959-04-24;57.96;57.96;57.96;57.96;3790000;57.96
1959-04-23;57.60;57.60;57.60;57.60;3310000;57.60
1959-04-22;57.73;57.73;57.73;57.73;3430000;57.73
1959-04-21;58.11;58.11;58.11;58.11;3650000;58.11
1959-04-20;58.17;58.17;58.17;58.17;3610000;58.17
1959-04-17;57.92;57.92;57.92;57.92;3870000;57.92
1959-04-16;57.43;57.43;57.43;57.43;3790000;57.43
1959-04-15;56.96;56.96;56.96;56.96;3680000;56.96
1959-04-14;56.71;56.71;56.71;56.71;3320000;56.71
1959-04-13;56.43;56.43;56.43;56.43;3140000;56.43
1959-04-10;56.22;56.22;56.22;56.22;3000000;56.22
1959-04-09;56.17;56.17;56.17;56.17;2830000;56.17
1959-04-08;56.21;56.21;56.21;56.21;3260000;56.21
1959-04-07;56.48;56.48;56.48;56.48;3020000;56.48
1959-04-06;56.60;56.60;56.60;56.60;3510000;56.60
1959-04-03;56.44;56.44;56.44;56.44;3680000;56.44
1959-04-02;56.00;56.00;56.00;56.00;3220000;56.00
1959-04-01;55.69;55.69;55.69;55.69;2980000;55.69
1959-03-31;55.44;55.44;55.44;55.44;2820000;55.44
1959-03-30;55.45;55.45;55.45;55.45;2940000;55.45
1959-03-26;55.76;55.76;55.76;55.76;2900000;55.76
1959-03-25;55.88;55.88;55.88;55.88;3280000;55.88
1959-03-24;55.96;55.96;55.96;55.96;3000000;55.96
1959-03-23;55.87;55.87;55.87;55.87;3700000;55.87
1959-03-20;56.39;56.39;56.39;56.39;3770000;56.39
1959-03-19;56.34;56.34;56.34;56.34;4150000;56.34
1959-03-18;56.39;56.39;56.39;56.39;4530000;56.39
1959-03-17;56.52;56.52;56.52;56.52;4730000;56.52
1959-03-16;56.06;56.06;56.06;56.06;4420000;56.06
1959-03-13;56.67;56.67;56.67;56.67;4880000;56.67
1959-03-12;56.60;56.60;56.60;56.60;4690000;56.60
1959-03-11;56.35;56.35;56.35;56.35;4160000;56.35
1959-03-10;56.31;56.31;56.31;56.31;3920000;56.31
1959-03-09;56.15;56.15;56.15;56.15;3530000;56.15
1959-03-06;56.21;56.21;56.21;56.21;3930000;56.21
1959-03-05;56.43;56.43;56.43;56.43;3930000;56.43
1959-03-04;56.35;56.35;56.35;56.35;4150000;56.35
1959-03-03;56.25;56.25;56.25;56.25;4790000;56.25
1959-03-02;55.73;55.73;55.73;55.73;4210000;55.73
1959-02-27;55.41;55.41;55.41;55.41;4300000;55.41
1959-02-26;55.34;55.34;55.34;55.34;3930000;55.34
1959-02-25;55.24;55.24;55.24;55.24;3780000;55.24
1959-02-24;55.48;55.48;55.48;55.48;4340000;55.48
1959-02-20;55.52;55.52;55.52;55.52;4190000;55.52
1959-02-19;55.50;55.50;55.50;55.50;4160000;55.50
1959-02-18;54.30;54.30;54.30;54.30;3480000;54.30
1959-02-17;54.29;54.29;54.29;54.29;3190000;54.29
1959-02-16;54.50;54.50;54.50;54.50;3480000;54.50
1959-02-13;54.42;54.42;54.42;54.42;3070000;54.42
1959-02-12;54.00;54.00;54.00;54.00;2630000;54.00
1959-02-11;54.35;54.35;54.35;54.35;3000000;54.35
1959-02-10;54.32;54.32;54.32;54.32;2960000;54.32
1959-02-09;53.58;53.58;53.58;53.58;3130000;53.58
1959-02-06;54.37;54.37;54.37;54.37;3010000;54.37
1959-02-05;54.81;54.81;54.81;54.81;3140000;54.81
1959-02-04;55.06;55.06;55.06;55.06;3170000;55.06
1959-02-03;55.28;55.28;55.28;55.28;3220000;55.28
1959-02-02;55.21;55.21;55.21;55.21;3610000;55.21
1959-01-30;55.45;55.45;55.45;55.45;3600000;55.45
1959-01-29;55.20;55.20;55.20;55.20;3470000;55.20
1959-01-28;55.16;55.16;55.16;55.16;4190000;55.16
1959-01-27;55.78;55.78;55.78;55.78;3480000;55.78
1959-01-26;55.77;55.77;55.77;55.77;3980000;55.77
1959-01-23;56.00;56.00;56.00;56.00;3600000;56.00
1959-01-22;55.97;55.97;55.97;55.97;4250000;55.97
1959-01-21;56.04;56.04;56.04;56.04;3940000;56.04
1959-01-20;55.72;55.72;55.72;55.72;3680000;55.72
1959-01-19;55.68;55.68;55.68;55.68;3840000;55.68
1959-01-16;55.81;55.81;55.81;55.81;4300000;55.81
1959-01-15;55.83;55.83;55.83;55.83;4500000;55.83
1959-01-14;55.62;55.62;55.62;55.62;4090000;55.62
1959-01-13;55.47;55.47;55.47;55.47;3790000;55.47
1959-01-12;55.78;55.78;55.78;55.78;4320000;55.78
1959-01-09;55.77;55.77;55.77;55.77;4760000;55.77
1959-01-08;55.40;55.40;55.40;55.40;4030000;55.40
1959-01-07;54.89;54.89;54.89;54.89;4140000;54.89
1959-01-06;55.59;55.59;55.59;55.59;3690000;55.59
1959-01-05;55.66;55.66;55.66;55.66;4210000;55.66
1959-01-02;55.44;55.44;55.44;55.44;3380000;55.44
1958-12-31;55.21;55.21;55.21;55.21;3970000;55.21
1958-12-30;54.93;54.93;54.93;54.93;3900000;54.93
1958-12-29;54.74;54.74;54.74;54.74;3790000;54.74
1958-12-24;54.11;54.11;54.11;54.11;3050000;54.11
1958-12-23;53.42;53.42;53.42;53.42;2870000;53.42
1958-12-22;53.71;53.71;53.71;53.71;3030000;53.71
1958-12-19;54.07;54.07;54.07;54.07;3540000;54.07
1958-12-18;54.15;54.15;54.15;54.15;3900000;54.15
1958-12-17;53.92;53.92;53.92;53.92;3900000;53.92
1958-12-16;53.57;53.57;53.57;53.57;3970000;53.57
1958-12-15;53.37;53.37;53.37;53.37;3340000;53.37
1958-12-12;53.22;53.22;53.22;53.22;3140000;53.22
1958-12-11;53.35;53.35;53.35;53.35;4250000;53.35
1958-12-10;53.46;53.46;53.46;53.46;4340000;53.46
1958-12-09;52.82;52.82;52.82;52.82;3790000;52.82
1958-12-08;52.46;52.46;52.46;52.46;3590000;52.46
1958-12-05;52.46;52.46;52.46;52.46;3360000;52.46
1958-12-04;52.55;52.55;52.55;52.55;3630000;52.55
1958-12-03;52.53;52.53;52.53;52.53;3460000;52.53
1958-12-02;52.46;52.46;52.46;52.46;3320000;52.46
1958-12-01;52.69;52.69;52.69;52.69;3800000;52.69
1958-11-28;52.48;52.48;52.48;52.48;4120000;52.48
1958-11-26;51.90;51.90;51.90;51.90;4090000;51.90
1958-11-25;51.02;51.02;51.02;51.02;3940000;51.02
1958-11-24;52.03;52.03;52.03;52.03;4770000;52.03
1958-11-21;52.70;52.70;52.70;52.70;3950000;52.70
1958-11-20;53.21;53.21;53.21;53.21;4320000;53.21
1958-11-19;53.20;53.20;53.20;53.20;4090000;53.20
1958-11-18;53.13;53.13;53.13;53.13;3820000;53.13
1958-11-17;53.24;53.24;53.24;53.24;4540000;53.24
1958-11-14;53.09;53.09;53.09;53.09;4390000;53.09
1958-11-13;52.83;52.83;52.83;52.83;4200000;52.83
1958-11-12;53.05;53.05;53.05;53.05;4440000;53.05
1958-11-11;52.98;52.98;52.98;52.98;4040000;52.98
1958-11-10;52.57;52.57;52.57;52.57;3730000;52.57
1958-11-07;52.26;52.26;52.26;52.26;3700000;52.26
1958-11-06;52.45;52.45;52.45;52.45;4890000;52.45
1958-11-05;52.03;52.03;52.03;52.03;4080000;52.03
1958-11-03;51.56;51.56;51.56;51.56;3240000;51.56
1958-10-31;51.33;51.33;51.33;51.33;3920000;51.33
1958-10-30;51.27;51.27;51.27;51.27;4360000;51.27
1958-10-29;51.07;51.07;51.07;51.07;4790000;51.07
1958-10-28;50.58;50.58;50.58;50.58;3670000;50.58
1958-10-27;50.42;50.42;50.42;50.42;3980000;50.42
1958-10-24;50.81;50.81;50.81;50.81;3770000;50.81
1958-10-23;50.97;50.97;50.97;50.97;3610000;50.97
1958-10-22;51.07;51.07;51.07;51.07;3500000;51.07
1958-10-21;51.27;51.27;51.27;51.27;4010000;51.27
1958-10-20;51.27;51.27;51.27;51.27;4560000;51.27
1958-10-17;51.46;51.46;51.46;51.46;5360000;51.46
1958-10-16;50.94;50.94;50.94;50.94;4560000;50.94
1958-10-15;50.58;50.58;50.58;50.58;4810000;50.58
1958-10-14;51.26;51.26;51.26;51.26;5110000;51.26
1958-10-13;51.62;51.62;51.62;51.62;4550000;51.62
1958-10-10;51.39;51.39;51.39;51.39;4610000;51.39
1958-10-09;51.05;51.05;51.05;51.05;3670000;51.05
1958-10-08;51.06;51.06;51.06;51.06;3680000;51.06
1958-10-07;51.07;51.07;51.07;51.07;3570000;51.07
1958-10-06;51.07;51.07;51.07;51.07;3570000;51.07
1958-10-03;50.37;50.37;50.37;50.37;3830000;50.37
1958-10-02;50.17;50.17;50.17;50.17;3750000;50.17
1958-10-01;49.98;49.98;49.98;49.98;3780000;49.98
1958-09-30;50.06;50.06;50.06;50.06;4160000;50.06
1958-09-29;49.87;49.87;49.87;49.87;3680000;49.87
1958-09-26;49.66;49.66;49.66;49.66;3420000;49.66
1958-09-25;49.57;49.57;49.57;49.57;4490000;49.57
1958-09-24;49.78;49.78;49.78;49.78;3120000;49.78
1958-09-23;49.56;49.56;49.56;49.56;3950000;49.56
1958-09-22;49.20;49.20;49.20;49.20;3490000;49.20
1958-09-19;49.40;49.40;49.40;49.40;3880000;49.40
1958-09-18;49.38;49.38;49.38;49.38;3460000;49.38
1958-09-17;49.35;49.35;49.35;49.35;3790000;49.35
1958-09-16;49.35;49.35;49.35;49.35;3940000;49.35
1958-09-15;48.96;48.96;48.96;48.96;3040000;48.96
1958-09-12;48.53;48.53;48.53;48.53;3100000;48.53
1958-09-11;48.64;48.64;48.64;48.64;3300000;48.64
1958-09-10;48.31;48.31;48.31;48.31;2820000;48.31
1958-09-09;48.46;48.46;48.46;48.46;3480000;48.46
1958-09-08;48.13;48.13;48.13;48.13;3030000;48.13
1958-09-05;47.97;47.97;47.97;47.97;2520000;47.97
1958-09-04;48.10;48.10;48.10;48.10;3100000;48.10
1958-09-03;48.18;48.18;48.18;48.18;3240000;48.18
1958-09-02;48.00;48.00;48.00;48.00;2930000;48.00
1958-08-29;47.75;47.75;47.75;47.75;2260000;47.75
1958-08-28;47.66;47.66;47.66;47.66;2540000;47.66
1958-08-27;47.91;47.91;47.91;47.91;3250000;47.91
1958-08-26;47.90;47.90;47.90;47.90;2910000;47.90
1958-08-25;47.74;47.74;47.74;47.74;2610000;47.74
1958-08-22;47.73;47.73;47.73;47.73;2660000;47.73
1958-08-21;47.63;47.63;47.63;47.63;2500000;47.63
1958-08-20;47.32;47.32;47.32;47.32;2460000;47.32
1958-08-19;47.30;47.30;47.30;47.30;2250000;47.30
1958-08-18;47.22;47.22;47.22;47.22;2390000;47.22
1958-08-15;47.50;47.50;47.50;47.50;2960000;47.50
1958-08-14;47.91;47.91;47.91;47.91;3370000;47.91
1958-08-13;47.81;47.81;47.81;47.81;2790000;47.81
1958-08-12;47.73;47.73;47.73;47.73;2600000;47.73
1958-08-11;48.16;48.16;48.16;48.16;2870000;48.16
1958-08-08;48.05;48.05;48.05;48.05;3650000;48.05
1958-08-07;47.77;47.77;47.77;47.77;3200000;47.77
1958-08-06;47.46;47.46;47.46;47.46;3440000;47.46
1958-08-05;47.75;47.75;47.75;47.75;4210000;47.75
1958-08-04;47.94;47.94;47.94;47.94;4000000;47.94
1958-08-01;47.49;47.49;47.49;47.49;3380000;47.49
1958-07-31;47.19;47.19;47.19;47.19;4440000;47.19
1958-07-30;47.09;47.09;47.09;47.09;3680000;47.09
1958-07-29;46.96;46.96;46.96;46.96;3310000;46.96
1958-07-28;47.15;47.15;47.15;47.15;3940000;47.15
1958-07-25;46.97;46.97;46.97;46.97;4430000;46.97
1958-07-24;46.65;46.65;46.65;46.65;3740000;46.65
1958-07-23;46.40;46.40;46.40;46.40;3550000;46.40
1958-07-22;46.41;46.41;46.41;46.41;3420000;46.41
1958-07-21;46.33;46.33;46.33;46.33;3440000;46.33
1958-07-18;45.77;45.77;45.77;45.77;3350000;45.77
1958-07-17;45.55;45.55;45.55;45.55;3180000;45.55
1958-07-16;45.25;45.25;45.25;45.25;3240000;45.25
1958-07-15;45.11;45.11;45.11;45.11;3090000;45.11
1958-07-14;45.14;45.14;45.14;45.14;2540000;45.14
1958-07-11;45.72;45.72;45.72;45.72;2400000;45.72
1958-07-10;45.42;45.42;45.42;45.42;2510000;45.42
1958-07-09;45.25;45.25;45.25;45.25;2630000;45.25
1958-07-08;45.40;45.40;45.40;45.40;2430000;45.40
1958-07-07;45.62;45.62;45.62;45.62;2510000;45.62
1958-07-03;45.47;45.47;45.47;45.47;2630000;45.47
1958-07-02;45.32;45.32;45.32;45.32;2370000;45.32
1958-07-01;45.28;45.28;45.28;45.28;2600000;45.28
1958-06-30;45.24;45.24;45.24;45.24;2820000;45.24
1958-06-27;44.90;44.90;44.90;44.90;2800000;44.90
1958-06-26;44.84;44.84;44.84;44.84;2910000;44.84
1958-06-25;44.63;44.63;44.63;44.63;2720000;44.63
1958-06-24;44.52;44.52;44.52;44.52;2560000;44.52
1958-06-23;44.69;44.69;44.69;44.69;2340000;44.69
1958-06-20;44.85;44.85;44.85;44.85;2590000;44.85
1958-06-19;44.61;44.61;44.61;44.61;2690000;44.61
1958-06-18;45.34;45.34;45.34;45.34;2640000;45.34
1958-06-17;44.94;44.94;44.94;44.94;2950000;44.94
1958-06-16;45.18;45.18;45.18;45.18;2870000;45.18
1958-06-13;45.02;45.02;45.02;45.02;3100000;45.02
1958-06-12;44.75;44.75;44.75;44.75;2760000;44.75
1958-06-11;44.49;44.49;44.49;44.49;2570000;44.49
1958-06-10;44.48;44.48;44.48;44.48;2390000;44.48
1958-06-09;44.57;44.57;44.57;44.57;2380000;44.57
1958-06-06;44.64;44.64;44.64;44.64;2680000;44.64
1958-06-05;44.55;44.55;44.55;44.55;2600000;44.55
1958-06-04;44.50;44.50;44.50;44.50;2690000;44.50
1958-06-03;44.46;44.46;44.46;44.46;2780000;44.46
1958-06-02;44.31;44.31;44.31;44.31;2770000;44.31
1958-05-29;44.09;44.09;44.09;44.09;2350000;44.09
1958-05-28;43.85;43.85;43.85;43.85;2260000;43.85
1958-05-27;43.79;43.79;43.79;43.79;2180000;43.79
1958-05-26;43.85;43.85;43.85;43.85;2500000;43.85
1958-05-23;43.87;43.87;43.87;43.87;2570000;43.87
1958-05-22;43.78;43.78;43.78;43.78;2950000;43.78
1958-05-21;43.55;43.55;43.55;43.55;2580000;43.55
1958-05-20;43.61;43.61;43.61;43.61;2500000;43.61
1958-05-19;43.24;43.24;43.24;43.24;1910000;43.24
1958-05-16;43.36;43.36;43.36;43.36;2030000;43.36
1958-05-15;43.34;43.34;43.34;43.34;2470000;43.34
1958-05-14;43.12;43.12;43.12;43.12;3060000;43.12
1958-05-13;43.62;43.62;43.62;43.62;2940000;43.62
1958-05-12;43.75;43.75;43.75;43.75;2780000;43.75
1958-05-09;44.09;44.09;44.09;44.09;2760000;44.09
1958-05-08;43.99;43.99;43.99;43.99;2790000;43.99
1958-05-07;43.93;43.93;43.93;43.93;2770000;43.93
1958-05-06;44.01;44.01;44.01;44.01;3110000;44.01
1958-05-05;43.79;43.79;43.79;43.79;2670000;43.79
1958-05-02;43.69;43.69;43.69;43.69;2290000;43.69
1958-05-01;43.54;43.54;43.54;43.54;2630000;43.54
1958-04-30;43.44;43.44;43.44;43.44;2900000;43.44
1958-04-29;43.00;43.00;43.00;43.00;2190000;43.00
1958-04-28;43.22;43.22;43.22;43.22;2400000;43.22
1958-04-25;43.36;43.36;43.36;43.36;3020000;43.36
1958-04-24;43.14;43.14;43.14;43.14;2870000;43.14
1958-04-23;42.80;42.80;42.80;42.80;2720000;42.80
1958-04-22;42.80;42.80;42.80;42.80;2440000;42.80
1958-04-21;42.93;42.93;42.93;42.93;2550000;42.93
1958-04-18;42.71;42.71;42.71;42.71;2700000;42.71
1958-04-17;42.25;42.25;42.25;42.25;2500000;42.25
1958-04-16;42.10;42.10;42.10;42.10;2240000;42.10
1958-04-15;42.43;42.43;42.43;42.43;2590000;42.43
1958-04-14;42.00;42.00;42.00;42.00;2180000;42.00
1958-04-11;41.74;41.74;41.74;41.74;2060000;41.74
1958-04-10;41.70;41.70;41.70;41.70;2000000;41.70
1958-04-09;41.65;41.65;41.65;41.65;2040000;41.65
1958-04-08;41.43;41.43;41.43;41.43;2190000;41.43
1958-04-07;41.33;41.33;41.33;41.33;2090000;41.33
1958-04-03;41.48;41.48;41.48;41.48;2130000;41.48
1958-04-02;41.60;41.60;41.60;41.60;2390000;41.60
1958-04-01;41.93;41.93;41.93;41.93;2070000;41.93
1958-03-31;42.10;42.10;42.10;42.10;2050000;42.10
1958-03-28;42.20;42.20;42.20;42.20;1930000;42.20
1958-03-27;42.17;42.17;42.17;42.17;2140000;42.17
1958-03-26;42.30;42.30;42.30;42.30;1990000;42.30
1958-03-25;42.44;42.44;42.44;42.44;2210000;42.44
1958-03-24;42.58;42.58;42.58;42.58;2580000;42.58
1958-03-21;42.42;42.42;42.42;42.42;2430000;42.42
1958-03-20;42.11;42.11;42.11;42.11;2280000;42.11
1958-03-19;42.09;42.09;42.09;42.09;2410000;42.09
1958-03-18;41.89;41.89;41.89;41.89;2070000;41.89
1958-03-17;42.04;42.04;42.04;42.04;2130000;42.04
1958-03-14;42.33;42.33;42.33;42.33;2150000;42.33
1958-03-13;42.46;42.46;42.46;42.46;2830000;42.46
1958-03-12;42.41;42.41;42.41;42.41;2420000;42.41
1958-03-11;42.51;42.51;42.51;42.51;2640000;42.51
1958-03-10;42.21;42.21;42.21;42.21;1980000;42.21
1958-03-07;42.07;42.07;42.07;42.07;2130000;42.07
1958-03-06;42.00;42.00;42.00;42.00;2470000;42.00
1958-03-05;41.47;41.47;41.47;41.47;2020000;41.47
1958-03-04;41.35;41.35;41.35;41.35;2010000;41.35
1958-03-03;41.13;41.13;41.13;41.13;1810000;41.13
1958-02-28;40.84;40.84;40.84;40.84;1580000;40.84
1958-02-27;40.68;40.68;40.68;40.68;1670000;40.68
1958-02-26;40.92;40.92;40.92;40.92;1880000;40.92
1958-02-25;40.61;40.61;40.61;40.61;1920000;40.61
1958-02-24;40.65;40.65;40.65;40.65;1570000;40.65
1958-02-21;40.88;40.88;40.88;40.88;1700000;40.88
1958-02-20;40.91;40.91;40.91;40.91;2060000;40.91
1958-02-19;41.15;41.15;41.15;41.15;2070000;41.15
1958-02-18;41.17;41.17;41.17;41.17;1680000;41.17
1958-02-17;41.11;41.11;41.11;41.11;1700000;41.11
1958-02-14;41.33;41.33;41.33;41.33;2070000;41.33
1958-02-13;40.94;40.94;40.94;40.94;1880000;40.94
1958-02-12;40.93;40.93;40.93;40.93;2030000;40.93
1958-02-11;41.11;41.11;41.11;41.11;2110000;41.11
1958-02-10;41.48;41.48;41.48;41.48;1900000;41.48
1958-02-07;41.73;41.73;41.73;41.73;2220000;41.73
1958-02-06;42.10;42.10;42.10;42.10;2210000;42.10
1958-02-05;42.19;42.19;42.19;42.19;2480000;42.19
1958-02-04;42.46;42.46;42.46;42.46;2970000;42.46
1958-02-03;42.04;42.04;42.04;42.04;2490000;42.04
1958-01-31;41.70;41.70;41.70;41.70;2030000;41.70
1958-01-30;41.68;41.68;41.68;41.68;2150000;41.68
1958-01-29;41.88;41.88;41.88;41.88;2220000;41.88
1958-01-28;41.63;41.63;41.63;41.63;2030000;41.63
1958-01-27;41.59;41.59;41.59;41.59;2320000;41.59
1958-01-24;41.71;41.71;41.71;41.71;2830000;41.71
1958-01-23;41.36;41.36;41.36;41.36;1910000;41.36
1958-01-22;41.20;41.20;41.20;41.20;2390000;41.20
1958-01-21;41.30;41.30;41.30;41.30;2160000;41.30
1958-01-20;41.35;41.35;41.35;41.35;2310000;41.35
1958-01-17;41.10;41.10;41.10;41.10;2200000;41.10
1958-01-16;41.06;41.06;41.06;41.06;3950000;41.06
1958-01-15;40.99;40.99;40.99;40.99;2080000;40.99
1958-01-14;40.67;40.67;40.67;40.67;2010000;40.67
1958-01-13;40.49;40.49;40.49;40.49;1860000;40.49
1958-01-10;40.37;40.37;40.37;40.37;2010000;40.37
1958-01-09;40.75;40.75;40.75;40.75;2180000;40.75
1958-01-08;40.99;40.99;40.99;40.99;2230000;40.99
1958-01-07;41.00;41.00;41.00;41.00;2220000;41.00
1958-01-06;40.68;40.68;40.68;40.68;2500000;40.68
1958-01-03;40.87;40.87;40.87;40.87;2440000;40.87
1958-01-02;40.33;40.33;40.33;40.33;1800000;40.33
1957-12-31;39.99;39.99;39.99;39.99;5070000;39.99
1957-12-30;39.58;39.58;39.58;39.58;3750000;39.58
1957-12-27;39.78;39.78;39.78;39.78;2620000;39.78
1957-12-26;39.92;39.92;39.92;39.92;2280000;39.92
1957-12-24;39.52;39.52;39.52;39.52;2220000;39.52
1957-12-23;39.48;39.48;39.48;39.48;2790000;39.48
1957-12-20;39.48;39.48;39.48;39.48;2500000;39.48
1957-12-19;39.80;39.80;39.80;39.80;2740000;39.80
1957-12-18;39.38;39.38;39.38;39.38;2750000;39.38
1957-12-17;39.42;39.42;39.42;39.42;2820000;39.42
1957-12-16;40.12;40.12;40.12;40.12;2350000;40.12
1957-12-13;40.73;40.73;40.73;40.73;2310000;40.73
1957-12-12;40.55;40.55;40.55;40.55;2330000;40.55
1957-12-11;40.51;40.51;40.51;40.51;2240000;40.51
1957-12-10;40.56;40.56;40.56;40.56;2360000;40.56
1957-12-09;40.92;40.92;40.92;40.92;2230000;40.92
1957-12-06;41.31;41.31;41.31;41.31;2350000;41.31
1957-12-05;41.52;41.52;41.52;41.52;2020000;41.52
1957-12-04;41.54;41.54;41.54;41.54;2220000;41.54
1957-12-03;41.37;41.37;41.37;41.37;2060000;41.37
1957-12-02;41.36;41.36;41.36;41.36;2430000;41.36
1957-11-29;41.72;41.72;41.72;41.72;2740000;41.72
1957-11-27;41.25;41.25;41.25;41.25;3330000;41.25
1957-11-26;40.09;40.09;40.09;40.09;3650000;40.09
1957-11-25;41.18;41.18;41.18;41.18;2600000;41.18
1957-11-22;40.87;40.87;40.87;40.87;2850000;40.87
1957-11-21;40.48;40.48;40.48;40.48;2900000;40.48
1957-11-20;39.92;39.92;39.92;39.92;2400000;39.92
1957-11-19;39.81;39.81;39.81;39.81;2240000;39.81
1957-11-18;40.04;40.04;40.04;40.04;2110000;40.04
1957-11-15;40.37;40.37;40.37;40.37;3510000;40.37
1957-11-14;39.44;39.44;39.44;39.44;2450000;39.44
1957-11-13;39.55;39.55;39.55;39.55;2120000;39.55
1957-11-12;39.60;39.60;39.60;39.60;2050000;39.60
1957-11-11;40.18;40.18;40.18;40.18;1540000;40.18
1957-11-08;40.19;40.19;40.19;40.19;2140000;40.19
1957-11-07;40.67;40.67;40.67;40.67;2580000;40.67
1957-11-06;40.43;40.43;40.43;40.43;2550000;40.43
1957-11-04;40.37;40.37;40.37;40.37;2380000;40.37
1957-11-01;40.44;40.44;40.44;40.44;2060000;40.44
1957-10-31;41.06;41.06;41.06;41.06;2170000;41.06
1957-10-30;41.02;41.02;41.02;41.02;2060000;41.02
1957-10-29;40.69;40.69;40.69;40.69;1860000;40.69
1957-10-28;40.42;40.42;40.42;40.42;1800000;40.42
1957-10-25;40.59;40.59;40.59;40.59;2400000;40.59
1957-10-24;40.71;40.71;40.71;40.71;4030000;40.71
1957-10-23;40.73;40.73;40.73;40.73;4600000;40.73
1957-10-22;38.98;38.98;38.98;38.98;5090000;38.98
1957-10-21;39.15;39.15;39.15;39.15;4670000;39.15
1957-10-18;40.33;40.33;40.33;40.33;2670000;40.33
1957-10-17;40.65;40.65;40.65;40.65;3060000;40.65
1957-10-16;41.33;41.33;41.33;41.33;2050000;41.33
1957-10-15;41.67;41.67;41.67;41.67;2620000;41.67
1957-10-14;41.24;41.24;41.24;41.24;2770000;41.24
1957-10-11;40.94;40.94;40.94;40.94;4460000;40.94
1957-10-10;40.96;40.96;40.96;40.96;3300000;40.96
1957-10-09;41.99;41.99;41.99;41.99;2120000;41.99
1957-10-08;41.95;41.95;41.95;41.95;3190000;41.95
1957-10-07;42.22;42.22;42.22;42.22;2490000;42.22
1957-10-04;42.79;42.79;42.79;42.79;1520000;42.79
1957-10-03;43.14;43.14;43.14;43.14;1590000;43.14
1957-10-02;43.10;43.10;43.10;43.10;1760000;43.10
1957-10-01;42.76;42.76;42.76;42.76;1680000;42.76
1957-09-30;42.42;42.42;42.42;42.42;1520000;42.42
1957-09-27;42.55;42.55;42.55;42.55;1750000;42.55
1957-09-26;42.57;42.57;42.57;42.57;2130000;42.57
1957-09-25;42.98;42.98;42.98;42.98;2770000;42.98
1957-09-24;42.98;42.98;42.98;42.98;2840000;42.98
1957-09-23;42.69;42.69;42.69;42.69;3160000;42.69
1957-09-20;43.69;43.69;43.69;43.69;2340000;43.69
1957-09-19;44.40;44.40;44.40;44.40;1520000;44.40
1957-09-18;44.69;44.69;44.69;44.69;1540000;44.69
1957-09-17;44.64;44.64;44.64;44.64;1490000;44.64
1957-09-16;44.58;44.58;44.58;44.58;1290000;44.58
1957-09-13;44.80;44.80;44.80;44.80;1620000;44.80
1957-09-12;44.82;44.82;44.82;44.82;2010000;44.82
1957-09-11;44.26;44.26;44.26;44.26;2130000;44.26
1957-09-10;43.87;43.87;43.87;43.87;1870000;43.87
1957-09-09;44.28;44.28;44.28;44.28;1420000;44.28
1957-09-06;44.68;44.68;44.68;44.68;1320000;44.68
1957-09-05;44.82;44.82;44.82;44.82;1420000;44.82
1957-09-04;45.05;45.05;45.05;45.05;1260000;45.05
1957-09-03;45.44;45.44;45.44;45.44;1490000;45.44
1957-08-30;45.22;45.22;45.22;45.22;1600000;45.22
1957-08-29;44.46;44.46;44.46;44.46;1630000;44.46
1957-08-28;44.64;44.64;44.64;44.64;1840000;44.64
1957-08-27;44.61;44.61;44.61;44.61;2250000;44.61
1957-08-26;43.89;43.89;43.89;43.89;2680000;43.89
1957-08-23;44.51;44.51;44.51;44.51;1960000;44.51
1957-08-22;45.16;45.16;45.16;45.16;1500000;45.16
1957-08-21;45.49;45.49;45.49;45.49;1720000;45.49
1957-08-20;45.29;45.29;45.29;45.29;2700000;45.29
1957-08-19;44.91;44.91;44.91;44.91;2040000;44.91
1957-08-16;45.83;45.83;45.83;45.83;1470000;45.83
1957-08-15;45.75;45.75;45.75;45.75;2040000;45.75
1957-08-14;45.73;45.73;45.73;45.73;2040000;45.73
1957-08-13;46.30;46.30;46.30;46.30;1580000;46.30
1957-08-12;46.33;46.33;46.33;46.33;1650000;46.33
1957-08-09;46.92;46.92;46.92;46.92;1570000;46.92
1957-08-08;46.90;46.90;46.90;46.90;1690000;46.90
1957-08-07;47.03;47.03;47.03;47.03;2460000;47.03
1957-08-06;46.67;46.67;46.67;46.67;1910000;46.67
1957-08-05;47.26;47.26;47.26;47.26;1790000;47.26
1957-08-02;47.68;47.68;47.68;47.68;1610000;47.68
1957-08-01;47.79;47.79;47.79;47.79;1660000;47.79
1957-07-31;47.91;47.91;47.91;47.91;1830000;47.91
1957-07-30;47.92;47.92;47.92;47.92;1780000;47.92
1957-07-29;47.92;47.92;47.92;47.92;1990000;47.92
1957-07-26;48.45;48.45;48.45;48.45;1710000;48.45
1957-07-25;48.61;48.61;48.61;48.61;1800000;48.61
1957-07-24;48.61;48.61;48.61;48.61;1730000;48.61
1957-07-23;48.56;48.56;48.56;48.56;1840000;48.56
1957-07-22;48.47;48.47;48.47;48.47;1950000;48.47
1957-07-19;48.58;48.58;48.58;48.58;1930000;48.58
1957-07-18;48.53;48.53;48.53;48.53;2130000;48.53
1957-07-17;48.58;48.58;48.58;48.58;2060000;48.58
1957-07-16;48.88;48.88;48.88;48.88;2510000;48.88
1957-07-15;49.13;49.13;49.13;49.13;2480000;49.13
1957-07-12;49.08;49.08;49.08;49.08;2240000;49.08
1957-07-11;48.86;48.86;48.86;48.86;2830000;48.86
1957-07-10;49.00;49.00;49.00;49.00;2880000;49.00
1957-07-09;48.90;48.90;48.90;48.90;2450000;48.90
1957-07-08;48.90;48.90;48.90;48.90;2840000;48.90
1957-07-05;48.69;48.69;48.69;48.69;2240000;48.69
1957-07-03;48.46;48.46;48.46;48.46;2720000;48.46
1957-07-02;47.90;47.90;47.90;47.90;2450000;47.90
1957-07-01;47.43;47.43;47.43;47.43;1840000;47.43
1957-06-28;47.37;47.37;47.37;47.37;1770000;47.37
1957-06-27;47.26;47.26;47.26;47.26;1800000;47.26
1957-06-26;47.09;47.09;47.09;47.09;1870000;47.09
1957-06-25;47.15;47.15;47.15;47.15;2000000;47.15
1957-06-24;46.78;46.78;46.78;46.78;2040000;46.78
1957-06-21;47.15;47.15;47.15;47.15;1970000;47.15
1957-06-20;47.43;47.43;47.43;47.43;2050000;47.43
1957-06-19;47.72;47.72;47.72;47.72;2220000;47.72
1957-06-18;48.04;48.04;48.04;48.04;2440000;48.04
1957-06-17;48.24;48.24;48.24;48.24;2220000;48.24
1957-06-14;48.15;48.15;48.15;48.15;2090000;48.15
1957-06-13;48.14;48.14;48.14;48.14;2630000;48.14
1957-06-12;48.05;48.05;48.05;48.05;2600000;48.05
1957-06-11;47.94;47.94;47.94;47.94;2850000;47.94
1957-06-10;47.90;47.90;47.90;47.90;2050000;47.90
1957-06-07;47.85;47.85;47.85;47.85;2380000;47.85
1957-06-06;47.80;47.80;47.80;47.80;2300000;47.80
1957-06-05;47.27;47.27;47.27;47.27;1940000;47.27
1957-06-04;47.28;47.28;47.28;47.28;2200000;47.28
1957-06-03;47.37;47.37;47.37;47.37;2050000;47.37
1957-05-31;47.43;47.43;47.43;47.43;2050000;47.43
1957-05-29;47.11;47.11;47.11;47.11;2270000;47.11
1957-05-28;46.69;46.69;46.69;46.69;2070000;46.69
1957-05-27;46.78;46.78;46.78;46.78;2290000;46.78
1957-05-24;47.21;47.21;47.21;47.21;2340000;47.21
1957-05-23;47.15;47.15;47.15;47.15;2110000;47.15
1957-05-22;47.14;47.14;47.14;47.14;2060000;47.14
1957-05-21;47.33;47.33;47.33;47.33;2370000;47.33
1957-05-20;47.35;47.35;47.35;47.35;2300000;47.35
1957-05-17;47.15;47.15;47.15;47.15;2510000;47.15
1957-05-16;47.02;47.02;47.02;47.02;2690000;47.02
1957-05-15;46.83;46.83;46.83;46.83;2590000;46.83
1957-05-14;46.67;46.67;46.67;46.67;2580000;46.67
1957-05-13;46.88;46.88;46.88;46.88;2720000;46.88
1957-05-10;46.59;46.59;46.59;46.59;2430000;46.59
1957-05-09;46.36;46.36;46.36;46.36;2520000;46.36
1957-05-08;46.31;46.31;46.31;46.31;2590000;46.31
1957-05-07;46.13;46.13;46.13;46.13;2300000;46.13
1957-05-06;46.27;46.27;46.27;46.27;2210000;46.27
1957-05-03;46.34;46.34;46.34;46.34;2390000;46.34
1957-05-02;46.39;46.39;46.39;46.39;2860000;46.39
1957-05-01;46.02;46.02;46.02;46.02;2310000;46.02
1957-04-30;45.74;45.74;45.74;45.74;2200000;45.74
1957-04-29;45.73;45.73;45.73;45.73;2290000;45.73
1957-04-26;45.50;45.50;45.50;45.50;2380000;45.50
1957-04-25;45.56;45.56;45.56;45.56;2640000;45.56
1957-04-24;45.72;45.72;45.72;45.72;2990000;45.72
1957-04-23;45.65;45.65;45.65;45.65;2840000;45.65
1957-04-22;45.48;45.48;45.48;45.48;2560000;45.48
1957-04-18;45.41;45.41;45.41;45.41;2480000;45.41
1957-04-17;45.08;45.08;45.08;45.08;2290000;45.08
1957-04-16;45.02;45.02;45.02;45.02;1890000;45.02
1957-04-15;44.95;44.95;44.95;44.95;2010000;44.95
1957-04-12;44.98;44.98;44.98;44.98;2370000;44.98
1957-04-11;44.98;44.98;44.98;44.98;2350000;44.98
1957-04-10;44.98;44.98;44.98;44.98;2920000;44.98
1957-04-09;44.79;44.79;44.79;44.79;2400000;44.79
1957-04-08;44.39;44.39;44.39;44.39;1950000;44.39
1957-04-05;44.49;44.49;44.49;44.49;1830000;44.49
1957-04-04;44.44;44.44;44.44;44.44;1820000;44.44
1957-04-03;44.54;44.54;44.54;44.54;2160000;44.54
1957-04-02;44.42;44.42;44.42;44.42;2300000;44.42
1957-04-01;44.14;44.14;44.14;44.14;1620000;44.14
1957-03-29;44.11;44.11;44.11;44.11;1650000;44.11
1957-03-28;44.18;44.18;44.18;44.18;1930000;44.18
1957-03-27;44.09;44.09;44.09;44.09;1710000;44.09
1957-03-26;43.91;43.91;43.91;43.91;1660000;43.91
1957-03-25;43.88;43.88;43.88;43.88;1590000;43.88
1957-03-22;44.06;44.06;44.06;44.06;1610000;44.06
1957-03-21;44.11;44.11;44.11;44.11;1630000;44.11
1957-03-20;44.10;44.10;44.10;44.10;1830000;44.10
1957-03-19;44.04;44.04;44.04;44.04;1540000;44.04
1957-03-18;43.85;43.85;43.85;43.85;1450000;43.85
1957-03-15;44.05;44.05;44.05;44.05;1600000;44.05
1957-03-14;44.07;44.07;44.07;44.07;1580000;44.07
1957-03-13;44.04;44.04;44.04;44.04;1840000;44.04
1957-03-12;43.75;43.75;43.75;43.75;1600000;43.75
1957-03-11;43.78;43.78;43.78;43.78;1650000;43.78
1957-03-08;44.07;44.07;44.07;44.07;1630000;44.07
1957-03-07;44.21;44.21;44.21;44.21;1830000;44.21
1957-03-06;44.23;44.23;44.23;44.23;1840000;44.23
1957-03-05;44.22;44.22;44.22;44.22;1860000;44.22
1957-03-04;44.06;44.06;44.06;44.06;1890000;44.06
1957-03-01;43.74;43.74;43.74;43.74;1700000;43.74
1957-02-28;43.26;43.26;43.26;43.26;1620000;43.26
1957-02-27;43.41;43.41;43.41;43.41;1620000;43.41
1957-02-26;43.45;43.45;43.45;43.45;1580000;43.45
1957-02-25;43.38;43.38;43.38;43.38;1710000;43.38
1957-02-21;43.48;43.48;43.48;43.48;1680000;43.48
1957-02-20;43.63;43.63;43.63;43.63;1790000;43.63
1957-02-19;43.49;43.49;43.49;43.49;1670000;43.49
1957-02-18;43.46;43.46;43.46;43.46;1800000;43.46
1957-02-15;43.51;43.51;43.51;43.51;2060000;43.51
1957-02-14;42.99;42.99;42.99;42.99;2220000;42.99
1957-02-13;43.04;43.04;43.04;43.04;2380000;43.04
1957-02-12;42.39;42.39;42.39;42.39;2550000;42.39
1957-02-11;42.57;42.57;42.57;42.57;2740000;42.57
1957-02-08;43.32;43.32;43.32;43.32;2120000;43.32
1957-02-07;43.62;43.62;43.62;43.62;1840000;43.62
1957-02-06;43.82;43.82;43.82;43.82;2110000;43.82
1957-02-05;43.89;43.89;43.89;43.89;2610000;43.89
1957-02-04;44.53;44.53;44.53;44.53;1750000;44.53
1957-02-01;44.62;44.62;44.62;44.62;1680000;44.62
1957-01-31;44.72;44.72;44.72;44.72;1920000;44.72
1957-01-30;44.91;44.91;44.91;44.91;1950000;44.91
1957-01-29;44.71;44.71;44.71;44.71;1800000;44.71
1957-01-28;44.49;44.49;44.49;44.49;1700000;44.49
1957-01-25;44.82;44.82;44.82;44.82;2010000;44.82
1957-01-24;45.03;45.03;45.03;45.03;1910000;45.03
1957-01-23;44.87;44.87;44.87;44.87;1920000;44.87
1957-01-22;44.53;44.53;44.53;44.53;1920000;44.53
1957-01-21;44.40;44.40;44.40;44.40;2740000;44.40
1957-01-18;44.64;44.64;44.64;44.64;2400000;44.64
1957-01-17;45.22;45.22;45.22;45.22;2140000;45.22
1957-01-16;45.23;45.23;45.23;45.23;2210000;45.23
1957-01-15;45.18;45.18;45.18;45.18;2370000;45.18
1957-01-14;45.86;45.86;45.86;45.86;2350000;45.86
1957-01-11;46.18;46.18;46.18;46.18;2340000;46.18
1957-01-10;46.27;46.27;46.27;46.27;2470000;46.27
1957-01-09;46.16;46.16;46.16;46.16;2330000;46.16
1957-01-08;46.25;46.25;46.25;46.25;2230000;46.25
1957-01-07;46.42;46.42;46.42;46.42;2500000;46.42
1957-01-04;46.66;46.66;46.66;46.66;2710000;46.66
1957-01-03;46.60;46.60;46.60;46.60;2260000;46.60
1957-01-02;46.20;46.20;46.20;46.20;1960000;46.20
1956-12-31;46.67;46.67;46.67;46.67;3680000;46.67
1956-12-28;46.56;46.56;46.56;46.56;2790000;46.56
1956-12-27;46.35;46.35;46.35;46.35;2420000;46.35
1956-12-26;46.39;46.39;46.39;46.39;2440000;46.39
1956-12-21;46.37;46.37;46.37;46.37;2380000;46.37
1956-12-20;46.07;46.07;46.07;46.07;2060000;46.07
1956-12-19;46.43;46.43;46.43;46.43;1900000;46.43
1956-12-18;46.54;46.54;46.54;46.54;2370000;46.54
1956-12-17;46.54;46.54;46.54;46.54;2500000;46.54
1956-12-14;46.54;46.54;46.54;46.54;2450000;46.54
1956-12-13;46.50;46.50;46.50;46.50;2370000;46.50
1956-12-12;46.13;46.13;46.13;46.13;2180000;46.13
1956-12-11;46.48;46.48;46.48;46.48;2210000;46.48
1956-12-10;46.80;46.80;46.80;46.80;2600000;46.80
1956-12-07;47.04;47.04;47.04;47.04;2400000;47.04
1956-12-06;46.81;46.81;46.81;46.81;2470000;46.81
1956-12-05;46.39;46.39;46.39;46.39;2360000;46.39
1956-12-04;45.84;45.84;45.84;45.84;2180000;45.84
1956-12-03;45.98;45.98;45.98;45.98;2570000;45.98
1956-11-30;45.08;45.08;45.08;45.08;2300000;45.08
1956-11-29;44.38;44.38;44.38;44.38;2440000;44.38
1956-11-28;44.43;44.43;44.43;44.43;2190000;44.43
1956-11-27;44.91;44.91;44.91;44.91;2130000;44.91
1956-11-26;44.87;44.87;44.87;44.87;2230000;44.87
1956-11-23;45.14;45.14;45.14;45.14;1880000;45.14
1956-11-21;44.67;44.67;44.67;44.67;2310000;44.67
1956-11-20;44.89;44.89;44.89;44.89;2240000;44.89
1956-11-19;45.29;45.29;45.29;45.29;2560000;45.29
1956-11-16;45.74;45.74;45.74;45.74;1820000;45.74
1956-11-15;45.72;45.72;45.72;45.72;2210000;45.72
1956-11-14;46.01;46.01;46.01;46.01;2290000;46.01
1956-11-13;46.27;46.27;46.27;46.27;2140000;46.27
1956-11-12;46.49;46.49;46.49;46.49;1600000;46.49
1956-11-09;46.34;46.34;46.34;46.34;1690000;46.34
1956-11-08;46.73;46.73;46.73;46.73;1970000;46.73
1956-11-07;47.11;47.11;47.11;47.11;2650000;47.11
1956-11-05;47.60;47.60;47.60;47.60;2830000;47.60
1956-11-02;46.98;46.98;46.98;46.98;2180000;46.98
1956-11-01;46.52;46.52;46.52;46.52;1890000;46.52
1956-10-31;45.58;45.58;45.58;45.58;2280000;45.58
1956-10-30;46.37;46.37;46.37;46.37;1830000;46.37
1956-10-29;46.40;46.40;46.40;46.40;2420000;46.40
1956-10-26;46.27;46.27;46.27;46.27;1800000;46.27
1956-10-25;45.85;45.85;45.85;45.85;1580000;45.85
1956-10-24;45.93;45.93;45.93;45.93;1640000;45.93
1956-10-23;46.12;46.12;46.12;46.12;1390000;46.12
1956-10-22;46.23;46.23;46.23;46.23;1430000;46.23
1956-10-19;46.24;46.24;46.24;46.24;1720000;46.24
1956-10-18;46.34;46.34;46.34;46.34;1640000;46.34
1956-10-17;46.26;46.26;46.26;46.26;1640000;46.26
1956-10-16;46.62;46.62;46.62;46.62;1580000;46.62
1956-10-15;46.86;46.86;46.86;46.86;1610000;46.86
1956-10-12;47.00;47.00;47.00;47.00;1330000;47.00
1956-10-11;46.81;46.81;46.81;46.81;1760000;46.81
1956-10-10;46.84;46.84;46.84;46.84;1620000;46.84
1956-10-09;46.20;46.20;46.20;46.20;1220000;46.20
1956-10-08;46.43;46.43;46.43;46.43;1450000;46.43
1956-10-05;46.45;46.45;46.45;46.45;1580000;46.45
1956-10-04;46.29;46.29;46.29;46.29;1600000;46.29
1956-10-03;46.28;46.28;46.28;46.28;2180000;46.28
1956-10-02;45.52;45.52;45.52;45.52;2400000;45.52
1956-10-01;44.70;44.70;44.70;44.70;2600000;44.70
1956-09-28;45.35;45.35;45.35;45.35;1720000;45.35
1956-09-27;45.60;45.60;45.60;45.60;1770000;45.60
1956-09-26;45.82;45.82;45.82;45.82;2370000;45.82
1956-09-25;45.75;45.75;45.75;45.75;2100000;45.75
1956-09-24;46.40;46.40;46.40;46.40;1840000;46.40
1956-09-21;46.58;46.58;46.58;46.58;2110000;46.58
1956-09-20;46.21;46.21;46.21;46.21;2150000;46.21
1956-09-19;46.24;46.24;46.24;46.24;2040000;46.24
1956-09-18;46.79;46.79;46.79;46.79;2200000;46.79
1956-09-17;47.10;47.10;47.10;47.10;1940000;47.10
1956-09-14;47.21;47.21;47.21;47.21;2110000;47.21
1956-09-13;46.09;46.09;46.09;46.09;2000000;46.09
1956-09-12;47.05;47.05;47.05;47.05;1930000;47.05
1956-09-11;47.38;47.38;47.38;47.38;1920000;47.38
1956-09-10;47.56;47.56;47.56;47.56;1860000;47.56
1956-09-07;47.81;47.81;47.81;47.81;1690000;47.81
1956-09-06;48.10;48.10;48.10;48.10;1550000;48.10
1956-09-05;48.02;48.02;48.02;48.02;2130000;48.02
1956-09-04;47.89;47.89;47.89;47.89;1790000;47.89
1956-08-31;47.51;47.51;47.51;47.51;1620000;47.51
1956-08-30;46.94;46.94;46.94;46.94;2050000;46.94
1956-08-29;47.36;47.36;47.36;47.36;1530000;47.36
1956-08-28;47.57;47.57;47.57;47.57;1400000;47.57
1956-08-27;47.66;47.66;47.66;47.66;1420000;47.66
1956-08-24;47.95;47.95;47.95;47.95;1530000;47.95
1956-08-23;48.00;48.00;48.00;48.00;1590000;48.00
1956-08-22;47.42;47.42;47.42;47.42;1570000;47.42
1956-08-21;47.89;47.89;47.89;47.89;2440000;47.89
1956-08-20;48.25;48.25;48.25;48.25;1770000;48.25
1956-08-17;48.82;48.82;48.82;48.82;1720000;48.82
1956-08-16;48.88;48.88;48.88;48.88;1790000;48.88
1956-08-15;48.99;48.99;48.99;48.99;2000000;48.99
1956-08-14;48.00;48.00;48.00;48.00;1790000;48.00
1956-08-13;48.58;48.58;48.58;48.58;1730000;48.58
1956-08-10;49.09;49.09;49.09;49.09;2040000;49.09
1956-08-09;49.32;49.32;49.32;49.32;2550000;49.32
1956-08-08;49.36;49.36;49.36;49.36;2480000;49.36
1956-08-07;49.16;49.16;49.16;49.16;2180000;49.16
1956-08-06;48.96;48.96;48.96;48.96;2280000;48.96
1956-08-03;49.64;49.64;49.64;49.64;2210000;49.64
1956-08-02;49.64;49.64;49.64;49.64;2530000;49.64
1956-08-01;49.62;49.62;49.62;49.62;2230000;49.62
1956-07-31;49.39;49.39;49.39;49.39;2520000;49.39
1956-07-30;49.00;49.00;49.00;49.00;2100000;49.00
1956-07-27;49.08;49.08;49.08;49.08;2240000;49.08
1956-07-26;49.48;49.48;49.48;49.48;2060000;49.48
1956-07-25;49.44;49.44;49.44;49.44;2220000;49.44
1956-07-24;49.33;49.33;49.33;49.33;2040000;49.33
1956-07-23;49.33;49.33;49.33;49.33;1970000;49.33
1956-07-20;49.35;49.35;49.35;49.35;2020000;49.35
1956-07-19;49.32;49.32;49.32;49.32;1950000;49.32
1956-07-18;49.30;49.30;49.30;49.30;2530000;49.30
1956-07-17;49.31;49.31;49.31;49.31;2520000;49.31
1956-07-16;49.14;49.14;49.14;49.14;2260000;49.14
1956-07-13;48.72;48.72;48.72;48.72;2020000;48.72
1956-07-12;48.58;48.58;48.58;48.58;2180000;48.58
1956-07-11;48.69;48.69;48.69;48.69;2520000;48.69
1956-07-10;48.54;48.54;48.54;48.54;2450000;48.54
1956-07-09;48.25;48.25;48.25;48.25;2180000;48.25
1956-07-06;48.04;48.04;48.04;48.04;2180000;48.04
1956-07-05;47.80;47.80;47.80;47.80;2240000;47.80
1956-07-03;47.32;47.32;47.32;47.32;1840000;47.32
1956-07-02;46.93;46.93;46.93;46.93;1610000;46.93
1956-06-29;46.97;46.97;46.97;46.97;1780000;46.97
1956-06-28;47.13;47.13;47.13;47.13;1900000;47.13
1956-06-27;47.07;47.07;47.07;47.07;2090000;47.07
1956-06-26;46.72;46.72;46.72;46.72;1730000;46.72
1956-06-25;46.41;46.41;46.41;46.41;1500000;46.41
1956-06-22;46.59;46.59;46.59;46.59;1630000;46.59
1956-06-21;46.73;46.73;46.73;46.73;1820000;46.73
1956-06-20;46.41;46.41;46.41;46.41;1670000;46.41
1956-06-19;46.22;46.22;46.22;46.22;1430000;46.22
1956-06-18;46.17;46.17;46.17;46.17;1440000;46.17
1956-06-15;46.37;46.37;46.37;46.37;1550000;46.37
1956-06-14;46.31;46.31;46.31;46.31;1670000;46.31
1956-06-13;46.42;46.42;46.42;46.42;1760000;46.42
1956-06-12;46.36;46.36;46.36;46.36;1900000;46.36
1956-06-11;45.71;45.71;45.71;45.71;2000000;45.71
1956-06-08;45.14;45.14;45.14;45.14;3630000;45.14
1956-06-07;45.99;45.99;45.99;45.99;1630000;45.99
1956-06-06;45.63;45.63;45.63;45.63;1460000;45.63
1956-06-05;45.86;45.86;45.86;45.86;1650000;45.86
1956-06-04;45.85;45.85;45.85;45.85;1500000;45.85
1956-06-01;45.58;45.58;45.58;45.58;1440000;45.58
1956-05-31;45.20;45.20;45.20;45.20;2020000;45.20
1956-05-29;45.11;45.11;45.11;45.11;2430000;45.11
1956-05-28;44.10;44.10;44.10;44.10;2780000;44.10
1956-05-25;44.62;44.62;44.62;44.62;2570000;44.62
1956-05-24;44.60;44.60;44.60;44.60;2600000;44.60
1956-05-23;45.02;45.02;45.02;45.02;2140000;45.02
1956-05-22;45.26;45.26;45.26;45.26;2290000;45.26
1956-05-21;45.99;45.99;45.99;45.99;1940000;45.99
1956-05-18;46.39;46.39;46.39;46.39;2020000;46.39
1956-05-17;46.61;46.61;46.61;46.61;1970000;46.61
1956-05-16;46.05;46.05;46.05;46.05;2080000;46.05
1956-05-15;46.37;46.37;46.37;46.37;2650000;46.37
1956-05-14;46.86;46.86;46.86;46.86;2440000;46.86
1956-05-11;47.12;47.12;47.12;47.12;2450000;47.12
1956-05-10;47.16;47.16;47.16;47.16;2850000;47.16
1956-05-09;47.94;47.94;47.94;47.94;2550000;47.94
1956-05-08;48.02;48.02;48.02;48.02;2440000;48.02
1956-05-07;48.22;48.22;48.22;48.22;2550000;48.22
1956-05-04;48.51;48.51;48.51;48.51;2860000;48.51
1956-05-03;48.34;48.34;48.34;48.34;2640000;48.34
1956-05-02;48.17;48.17;48.17;48.17;2440000;48.17
1956-05-01;48.16;48.16;48.16;48.16;2500000;48.16
1956-04-30;48.38;48.38;48.38;48.38;2730000;48.38
1956-04-27;47.99;47.99;47.99;47.99;2760000;47.99
1956-04-26;47.49;47.49;47.49;47.49;2630000;47.49
1956-04-25;47.09;47.09;47.09;47.09;2270000;47.09
1956-04-24;47.26;47.26;47.26;47.26;2500000;47.26
1956-04-23;47.65;47.65;47.65;47.65;2440000;47.65
1956-04-20;47.76;47.76;47.76;47.76;2320000;47.76
1956-04-19;47.57;47.57;47.57;47.57;2210000;47.57
1956-04-18;47.74;47.74;47.74;47.74;2470000;47.74
1956-04-17;47.93;47.93;47.93;47.93;2330000;47.93
1956-04-16;47.96;47.96;47.96;47.96;2310000;47.96
1956-04-13;47.95;47.95;47.95;47.95;2450000;47.95
1956-04-12;48.02;48.02;48.02;48.02;2700000;48.02
1956-04-11;48.31;48.31;48.31;48.31;2440000;48.31
1956-04-10;47.93;47.93;47.93;47.93;2590000;47.93
1956-04-09;48.61;48.61;48.61;48.61;2760000;48.61
1956-04-06;48.85;48.85;48.85;48.85;2600000;48.85
1956-04-05;48.57;48.57;48.57;48.57;2950000;48.57
1956-04-04;48.80;48.80;48.80;48.80;2760000;48.80
1956-04-03;48.53;48.53;48.53;48.53;2760000;48.53
1956-04-02;48.70;48.70;48.70;48.70;3120000;48.70
1956-03-29;48.48;48.48;48.48;48.48;3480000;48.48
1956-03-28;48.51;48.51;48.51;48.51;2610000;48.51
1956-03-27;48.25;48.25;48.25;48.25;2540000;48.25
1956-03-26;48.62;48.62;48.62;48.62;2720000;48.62
1956-03-23;48.83;48.83;48.83;48.83;2980000;48.83
1956-03-22;48.72;48.72;48.72;48.72;2650000;48.72
1956-03-21;48.23;48.23;48.23;48.23;2930000;48.23
1956-03-20;48.87;48.87;48.87;48.87;2960000;48.87
1956-03-19;48.59;48.59;48.59;48.59;2570000;48.59
1956-03-16;48.14;48.14;48.14;48.14;3120000;48.14
1956-03-15;47.99;47.99;47.99;47.99;3270000;47.99
1956-03-14;47.53;47.53;47.53;47.53;3140000;47.53
1956-03-13;47.06;47.06;47.06;47.06;2790000;47.06
1956-03-12;47.13;47.13;47.13;47.13;3110000;47.13
1956-03-09;46.70;46.70;46.70;46.70;3430000;46.70
1956-03-08;46.12;46.12;46.12;46.12;2500000;46.12
1956-03-07;46.01;46.01;46.01;46.01;2380000;46.01
1956-03-06;46.04;46.04;46.04;46.04;2770000;46.04
1956-03-05;46.06;46.06;46.06;46.06;3090000;46.06
1956-03-02;45.81;45.81;45.81;45.81;2860000;45.81
1956-03-01;45.54;45.54;45.54;45.54;2410000;45.54
1956-02-29;45.34;45.34;45.34;45.34;3900000;45.34
1956-02-28;45.43;45.43;45.43;45.43;2540000;45.43
1956-02-27;45.27;45.27;45.27;45.27;2440000;45.27
1956-02-24;45.32;45.32;45.32;45.32;2890000;45.32
1956-02-23;44.95;44.95;44.95;44.95;2900000;44.95
1956-02-21;44.56;44.56;44.56;44.56;2240000;44.56
1956-02-20;44.45;44.45;44.45;44.45;2530000;44.45
1956-02-17;44.52;44.52;44.52;44.52;2840000;44.52
1956-02-16;43.82;43.82;43.82;43.82;1750000;43.82
1956-02-15;44.04;44.04;44.04;44.04;3000000;44.04
1956-02-14;43.42;43.42;43.42;43.42;1590000;43.42
1956-02-13;43.58;43.58;43.58;43.58;1420000;43.58
1956-02-10;43.64;43.64;43.64;43.64;1770000;43.64
1956-02-09;43.66;43.66;43.66;43.66;2080000;43.66
1956-02-08;44.16;44.16;44.16;44.16;2170000;44.16
1956-02-07;44.60;44.60;44.60;44.60;2060000;44.60
1956-02-06;44.81;44.81;44.81;44.81;2230000;44.81
1956-02-03;44.78;44.78;44.78;44.78;2110000;44.78
1956-02-02;44.22;44.22;44.22;44.22;1900000;44.22
1956-02-01;44.03;44.03;44.03;44.03;2010000;44.03
1956-01-31;43.82;43.82;43.82;43.82;1900000;43.82
1956-01-30;43.50;43.50;43.50;43.50;1830000;43.50
1956-01-27;43.35;43.35;43.35;43.35;1950000;43.35
1956-01-26;43.46;43.46;43.46;43.46;1840000;43.46
1956-01-25;43.72;43.72;43.72;43.72;1950000;43.72
1956-01-24;43.65;43.65;43.65;43.65;2160000;43.65
1956-01-23;43.11;43.11;43.11;43.11;2720000;43.11
1956-01-20;43.22;43.22;43.22;43.22;2430000;43.22
1956-01-19;43.72;43.72;43.72;43.72;2500000;43.72
1956-01-18;44.17;44.17;44.17;44.17;2110000;44.17
1956-01-17;44.47;44.47;44.47;44.47;2050000;44.47
1956-01-16;44.14;44.14;44.14;44.14;2260000;44.14
1956-01-13;44.67;44.67;44.67;44.67;2120000;44.67
1956-01-12;44.75;44.75;44.75;44.75;2330000;44.75
1956-01-11;44.38;44.38;44.38;44.38;2310000;44.38
1956-01-10;44.16;44.16;44.16;44.16;2640000;44.16
1956-01-09;44.51;44.51;44.51;44.51;2700000;44.51
1956-01-06;45.14;45.14;45.14;45.14;2570000;45.14
1956-01-05;44.95;44.95;44.95;44.95;2110000;44.95
1956-01-04;45.00;45.00;45.00;45.00;2290000;45.00
1956-01-03;45.16;45.16;45.16;45.16;2390000;45.16
1955-12-30;45.48;45.48;45.48;45.48;2820000;45.48
1955-12-29;45.15;45.15;45.15;45.15;2190000;45.15
1955-12-28;45.05;45.05;45.05;45.05;1990000;45.05
1955-12-27;45.22;45.22;45.22;45.22;2010000;45.22
1955-12-23;45.50;45.50;45.50;45.50;2090000;45.50
1955-12-22;45.41;45.41;45.41;45.41;2650000;45.41
1955-12-21;45.84;45.84;45.84;45.84;2540000;45.84
1955-12-20;44.95;44.95;44.95;44.95;2280000;44.95
1955-12-19;45.02;45.02;45.02;45.02;2380000;45.02
1955-12-16;45.13;45.13;45.13;45.13;2310000;45.13
1955-12-15;45.06;45.06;45.06;45.06;2260000;45.06
1955-12-14;45.07;45.07;45.07;45.07;2670000;45.07
1955-12-13;45.45;45.45;45.45;45.45;2430000;45.45
1955-12-12;45.42;45.42;45.42;45.42;2510000;45.42
1955-12-09;45.89;45.89;45.89;45.89;2660000;45.89
1955-12-08;45.82;45.82;45.82;45.82;2970000;45.82
1955-12-07;45.55;45.55;45.55;45.55;2480000;45.55
1955-12-06;45.70;45.70;45.70;45.70;2540000;45.70
1955-12-05;45.70;45.70;45.70;45.70;2440000;45.70
1955-12-02;45.44;45.44;45.44;45.44;2400000;45.44
1955-12-01;45.35;45.35;45.35;45.35;2370000;45.35
1955-11-30;45.51;45.51;45.51;45.51;2900000;45.51
1955-11-29;45.56;45.56;45.56;45.56;2370000;45.56
1955-11-28;45.38;45.38;45.38;45.38;2460000;45.38
1955-11-25;45.68;45.68;45.68;45.68;2190000;45.68
1955-11-23;45.72;45.72;45.72;45.72;2550000;45.72
1955-11-22;45.66;45.66;45.66;45.66;2270000;45.66
1955-11-21;45.22;45.22;45.22;45.22;1960000;45.22
1955-11-18;45.54;45.54;45.54;45.54;2320000;45.54
1955-11-17;45.59;45.59;45.59;45.59;2310000;45.59
1955-11-16;45.91;45.91;45.91;45.91;2460000;45.91
1955-11-15;46.21;46.21;46.21;46.21;2560000;46.21
1955-11-14;46.41;46.41;46.41;46.41;2760000;46.41
1955-11-11;45.24;45.24;45.24;45.24;2000000;45.24
1955-11-10;44.72;44.72;44.72;44.72;2550000;44.72
1955-11-09;44.61;44.61;44.61;44.61;2580000;44.61
1955-11-07;44.15;44.15;44.15;44.15;2230000;44.15
1955-11-04;43.96;43.96;43.96;43.96;2430000;43.96
1955-11-03;43.24;43.24;43.24;43.24;2260000;43.24
1955-11-02;42.35;42.35;42.35;42.35;1610000;42.35
1955-11-01;42.28;42.28;42.28;42.28;1590000;42.28
1955-10-31;42.34;42.34;42.34;42.34;1800000;42.34
1955-10-28;42.37;42.37;42.37;42.37;1720000;42.37
1955-10-27;42.34;42.34;42.34;42.34;1830000;42.34
1955-10-26;42.29;42.29;42.29;42.29;1660000;42.29
1955-10-25;42.63;42.63;42.63;42.63;1950000;42.63
1955-10-24;42.91;42.91;42.91;42.91;1820000;42.91
1955-10-21;42.59;42.59;42.59;42.59;1710000;42.59
1955-10-20;42.59;42.59;42.59;42.59;2160000;42.59
1955-10-19;42.07;42.07;42.07;42.07;1760000;42.07
1955-10-18;41.65;41.65;41.65;41.65;1550000;41.65
1955-10-17;41.35;41.35;41.35;41.35;1480000;41.35
1955-10-14;41.22;41.22;41.22;41.22;1640000;41.22
1955-10-13;41.39;41.39;41.39;41.39;1980000;41.39
1955-10-12;41.52;41.52;41.52;41.52;1900000;41.52
1955-10-11;40.80;40.80;40.80;40.80;3590000;40.80
1955-10-10;41.15;41.15;41.15;41.15;3100000;41.15
1955-10-07;42.38;42.38;42.38;42.38;2150000;42.38
1955-10-06;42.70;42.70;42.70;42.70;1690000;42.70
1955-10-05;42.99;42.99;42.99;42.99;1920000;42.99
1955-10-04;42.82;42.82;42.82;42.82;2020000;42.82
1955-10-03;42.49;42.49;42.49;42.49;2720000;42.49
1955-09-30;43.67;43.67;43.67;43.67;2140000;43.67
1955-09-29;44.03;44.03;44.03;44.03;2560000;44.03
1955-09-28;44.31;44.31;44.31;44.31;3780000;44.31
1955-09-27;43.58;43.58;43.58;43.58;5500000;43.58
1955-09-26;42.61;42.61;42.61;42.61;7720000;42.61
1955-09-23;45.63;45.63;45.63;45.63;2540000;45.63
1955-09-22;45.39;45.39;45.39;45.39;2550000;45.39
1955-09-21;45.39;45.39;45.39;45.39;2460000;45.39
1955-09-20;45.13;45.13;45.13;45.13;2090000;45.13
1955-09-19;45.16;45.16;45.16;45.16;2390000;45.16
1955-09-16;45.09;45.09;45.09;45.09;2540000;45.09
1955-09-15;44.75;44.75;44.75;44.75;2890000;44.75
1955-09-14;44.99;44.99;44.99;44.99;2570000;44.99
1955-09-13;44.80;44.80;44.80;44.80;2580000;44.80
1955-09-12;44.19;44.19;44.19;44.19;2520000;44.19
1955-09-09;43.89;43.89;43.89;43.89;2480000;43.89
1955-09-08;43.88;43.88;43.88;43.88;2470000;43.88
1955-09-07;43.85;43.85;43.85;43.85;2380000;43.85
1955-09-06;43.86;43.86;43.86;43.86;2360000;43.86
1955-09-02;43.60;43.60;43.60;43.60;1700000;43.60
1955-09-01;43.37;43.37;43.37;43.37;1860000;43.37
1955-08-31;43.18;43.18;43.18;43.18;1850000;43.18
1955-08-30;42.92;42.92;42.92;42.92;1740000;42.92
1955-08-29;42.96;42.96;42.96;42.96;1910000;42.96
1955-08-26;42.99;42.99;42.99;42.99;2200000;42.99
1955-08-25;42.80;42.80;42.80;42.80;2120000;42.80
1955-08-24;42.61;42.61;42.61;42.61;2140000;42.61
1955-08-23;42.55;42.55;42.55;42.55;1890000;42.55
1955-08-22;41.98;41.98;41.98;41.98;1430000;41.98
1955-08-19;42.02;42.02;42.02;42.02;1400000;42.02
1955-08-18;41.84;41.84;41.84;41.84;1560000;41.84
1955-08-17;41.90;41.90;41.90;41.90;1570000;41.90
1955-08-16;41.86;41.86;41.86;41.86;1520000;41.86
1955-08-15;42.17;42.17;42.17;42.17;1230000;42.17
1955-08-12;42.21;42.21;42.21;42.21;1530000;42.21
1955-08-11;42.13;42.13;42.13;42.13;1620000;42.13
1955-08-10;41.74;41.74;41.74;41.74;1580000;41.74
1955-08-09;41.75;41.75;41.75;41.75;2240000;41.75
1955-08-08;42.31;42.31;42.31;42.31;1730000;42.31
1955-08-05;42.56;42.56;42.56;42.56;1690000;42.56
1955-08-04;42.36;42.36;42.36;42.36;2210000;42.36
1955-08-03;43.09;43.09;43.09;43.09;2190000;43.09
1955-08-02;43.03;43.03;43.03;43.03;2260000;43.03
1955-08-01;42.93;42.93;42.93;42.93;2190000;42.93
1955-07-29;43.52;43.52;43.52;43.52;2070000;43.52
1955-07-28;43.50;43.50;43.50;43.50;2090000;43.50
1955-07-27;43.76;43.76;43.76;43.76;2170000;43.76
1955-07-26;43.58;43.58;43.58;43.58;2340000;43.58
1955-07-25;43.48;43.48;43.48;43.48;2500000;43.48
1955-07-22;43.00;43.00;43.00;43.00;2500000;43.00
1955-07-21;42.64;42.64;42.64;42.64;2530000;42.64
1955-07-20;42.23;42.23;42.23;42.23;2080000;42.23
1955-07-19;42.10;42.10;42.10;42.10;2300000;42.10
1955-07-18;42.36;42.36;42.36;42.36;2160000;42.36
1955-07-15;42.40;42.40;42.40;42.40;2230000;42.40
1955-07-14;42.25;42.25;42.25;42.25;1980000;42.25
1955-07-13;42.24;42.24;42.24;42.24;2360000;42.24
1955-07-12;42.75;42.75;42.75;42.75;2630000;42.75
1955-07-11;42.75;42.75;42.75;42.75;2420000;42.75
1955-07-08;42.64;42.64;42.64;42.64;2450000;42.64
1955-07-07;42.58;42.58;42.58;42.58;3300000;42.58
1955-07-06;43.18;43.18;43.18;43.18;3140000;43.18
1955-07-05;41.69;41.69;41.69;41.69;2680000;41.69
1955-07-01;41.19;41.19;41.19;41.19;2540000;41.19
1955-06-30;41.03;41.03;41.03;41.03;2370000;41.03
1955-06-29;40.79;40.79;40.79;40.79;2180000;40.79
1955-06-28;40.77;40.77;40.77;40.77;2180000;40.77
1955-06-27;40.99;40.99;40.99;40.99;2250000;40.99
1955-06-24;40.96;40.96;40.96;40.96;2410000;40.96
1955-06-23;40.75;40.75;40.75;40.75;2900000;40.75
1955-06-22;40.60;40.60;40.60;40.60;3010000;40.60
1955-06-21;40.51;40.51;40.51;40.51;2720000;40.51
1955-06-20;40.14;40.14;40.14;40.14;2490000;40.14
1955-06-17;40.10;40.10;40.10;40.10;2340000;40.10
1955-06-16;39.96;39.96;39.96;39.96;2760000;39.96
1955-06-15;39.89;39.89;39.89;39.89;2650000;39.89
1955-06-14;39.67;39.67;39.67;39.67;2860000;39.67
1955-06-13;39.62;39.62;39.62;39.62;2770000;39.62
1955-06-10;39.25;39.25;39.25;39.25;2470000;39.25
1955-06-09;39.01;39.01;39.01;39.01;2960000;39.01
1955-06-08;39.22;39.22;39.22;39.22;3300000;39.22
1955-06-07;39.96;39.96;39.96;39.96;3230000;39.96
1955-06-06;39.69;39.69;39.69;39.69;2560000;39.69
1955-06-03;38.37;38.37;38.37;38.37;2590000;38.37
1955-06-02;38.01;38.01;38.01;38.01;2610000;38.01
1955-06-01;37.96;37.96;37.96;37.96;2510000;37.96
1955-05-31;37.91;37.91;37.91;37.91;1990000;37.91
1955-05-27;37.93;37.93;37.93;37.93;2220000;37.93
1955-05-26;37.85;37.85;37.85;37.85;2260000;37.85
1955-05-25;37.60;37.60;37.60;37.60;2100000;37.60
1955-05-24;37.46;37.46;37.46;37.46;1650000;37.46
1955-05-23;37.48;37.48;37.48;37.48;1900000;37.48
1955-05-20;37.74;37.74;37.74;37.74;2240000;37.74
1955-05-19;37.49;37.49;37.49;37.49;2380000;37.49
1955-05-18;37.28;37.28;37.28;37.28;2010000;37.28
1955-05-17;36.97;36.97;36.97;36.97;1900000;36.97
1955-05-16;37.02;37.02;37.02;37.02;2160000;37.02
1955-05-13;37.44;37.44;37.44;37.44;1860000;37.44
1955-05-12;37.20;37.20;37.20;37.20;2830000;37.20
1955-05-11;37.42;37.42;37.42;37.42;2120000;37.42
1955-05-10;37.85;37.85;37.85;37.85;2150000;37.85
1955-05-09;37.93;37.93;37.93;37.93;2090000;37.93
1955-05-06;37.89;37.89;37.89;37.89;2250000;37.89
1955-05-05;37.82;37.82;37.82;37.82;2270000;37.82
1955-05-04;37.64;37.64;37.64;37.64;2220000;37.64
1955-05-03;37.70;37.70;37.70;37.70;2630000;37.70
1955-05-02;38.04;38.04;38.04;38.04;2220000;38.04
1955-04-29;37.96;37.96;37.96;37.96;2230000;37.96
1955-04-28;37.68;37.68;37.68;37.68;2550000;37.68
1955-04-27;38.11;38.11;38.11;38.11;2660000;38.11
1955-04-26;38.31;38.31;38.31;38.31;2720000;38.31
1955-04-25;38.11;38.11;38.11;38.11;2720000;38.11
1955-04-22;38.01;38.01;38.01;38.01;2800000;38.01
1955-04-21;38.32;38.32;38.32;38.32;2810000;38.32
1955-04-20;38.28;38.28;38.28;38.28;3090000;38.28
1955-04-19;38.22;38.22;38.22;38.22;2700000;38.22
1955-04-18;38.27;38.27;38.27;38.27;3080000;38.27
1955-04-15;37.96;37.96;37.96;37.96;3180000;37.96
1955-04-14;37.79;37.79;37.79;37.79;2890000;37.79
1955-04-13;37.71;37.71;37.71;37.71;2820000;37.71
1955-04-12;37.66;37.66;37.66;37.66;2770000;37.66
1955-04-11;37.44;37.44;37.44;37.44;2680000;37.44
1955-04-07;37.34;37.34;37.34;37.34;2330000;37.34
1955-04-06;37.17;37.17;37.17;37.17;2500000;37.17
1955-04-05;36.98;36.98;36.98;36.98;2100000;36.98
1955-04-04;36.83;36.83;36.83;36.83;2500000;36.83
1955-04-01;36.95;36.95;36.95;36.95;2660000;36.95
1955-03-31;36.58;36.58;36.58;36.58;2680000;36.58
1955-03-30;36.52;36.52;36.52;36.52;3410000;36.52
1955-03-29;36.85;36.85;36.85;36.85;2770000;36.85
1955-03-28;36.83;36.83;36.83;36.83;2540000;36.83
1955-03-25;36.96;36.96;36.96;36.96;2540000;36.96
1955-03-24;36.93;36.93;36.93;36.93;3170000;36.93
1955-03-23;36.64;36.64;36.64;36.64;2730000;36.64
1955-03-22;36.17;36.17;36.17;36.17;1910000;36.17
1955-03-21;35.95;35.95;35.95;35.95;2020000;35.95
1955-03-18;36.18;36.18;36.18;36.18;2050000;36.18
1955-03-17;36.12;36.12;36.12;36.12;2200000;36.12
1955-03-16;35.98;35.98;35.98;35.98;2900000;35.98
1955-03-15;35.71;35.71;35.71;35.71;3160000;35.71
1955-03-14;34.96;34.96;34.96;34.96;4220000;34.96
1955-03-11;35.82;35.82;35.82;35.82;3040000;35.82
1955-03-10;36.45;36.45;36.45;36.45;2760000;36.45
1955-03-09;36.22;36.22;36.22;36.22;3590000;36.22
1955-03-08;36.58;36.58;36.58;36.58;3160000;36.58
1955-03-07;37.28;37.28;37.28;37.28;2630000;37.28
1955-03-04;37.52;37.52;37.52;37.52;2770000;37.52
1955-03-03;37.29;37.29;37.29;37.29;3330000;37.29
1955-03-02;37.15;37.15;37.15;37.15;3370000;37.15
1955-03-01;36.83;36.83;36.83;36.83;2830000;36.83
1955-02-28;36.76;36.76;36.76;36.76;2620000;36.76
1955-02-25;36.57;36.57;36.57;36.57;2540000;36.57
1955-02-24;36.62;36.62;36.62;36.62;2920000;36.62
1955-02-23;36.82;36.82;36.82;36.82;3030000;36.82
1955-02-21;36.85;36.85;36.85;36.85;3010000;36.85
1955-02-18;36.89;36.89;36.89;36.89;3660000;36.89
1955-02-17;36.84;36.84;36.84;36.84;3030000;36.84
1955-02-16;36.77;36.77;36.77;36.77;3660000;36.77
1955-02-15;36.89;36.89;36.89;36.89;3510000;36.89
1955-02-14;36.89;36.89;36.89;36.89;2950000;36.89
1955-02-11;37.15;37.15;37.15;37.15;3260000;37.15
1955-02-10;37.08;37.08;37.08;37.08;3460000;37.08
1955-02-09;36.75;36.75;36.75;36.75;3360000;36.75
1955-02-08;36.46;36.46;36.46;36.46;3400000;36.46
1955-02-07;36.96;36.96;36.96;36.96;3610000;36.96
1955-02-04;36.96;36.96;36.96;36.96;3370000;36.96
1955-02-03;36.44;36.44;36.44;36.44;2890000;36.44
1955-02-02;36.61;36.61;36.61;36.61;3210000;36.61
1955-02-01;36.72;36.72;36.72;36.72;3320000;36.72
1955-01-31;36.63;36.63;36.63;36.63;3500000;36.63
1955-01-28;36.19;36.19;36.19;36.19;3290000;36.19
1955-01-27;35.99;35.99;35.99;35.99;3500000;35.99
1955-01-26;35.95;35.95;35.95;35.95;3860000;35.95
1955-01-25;35.51;35.51;35.51;35.51;3230000;35.51
1955-01-24;35.52;35.52;35.52;35.52;2910000;35.52
1955-01-21;35.44;35.44;35.44;35.44;2690000;35.44
1955-01-20;35.13;35.13;35.13;35.13;2210000;35.13
1955-01-19;34.96;34.96;34.96;34.96;2760000;34.96
1955-01-18;34.80;34.80;34.80;34.80;3020000;34.80
1955-01-17;34.58;34.58;34.58;34.58;3360000;34.58
1955-01-14;35.28;35.28;35.28;35.28;2630000;35.28
1955-01-13;35.43;35.43;35.43;35.43;3350000;35.43
1955-01-12;35.58;35.58;35.58;35.58;3400000;35.58
1955-01-11;35.68;35.68;35.68;35.68;3680000;35.68
1955-01-10;35.79;35.79;35.79;35.79;4300000;35.79
1955-01-07;35.33;35.33;35.33;35.33;4030000;35.33
1955-01-06;35.04;35.04;35.04;35.04;5300000;35.04
1955-01-05;35.52;35.52;35.52;35.52;4640000;35.52
1955-01-04;36.42;36.42;36.42;36.42;4420000;36.42
1955-01-03;36.75;36.75;36.75;36.75;4570000;36.75
1954-12-31;35.98;35.98;35.98;35.98;3840000;35.98
1954-12-30;35.74;35.74;35.74;35.74;3590000;35.74
1954-12-29;35.74;35.74;35.74;35.74;4430000;35.74
1954-12-28;35.43;35.43;35.43;35.43;3660000;35.43
1954-12-27;35.07;35.07;35.07;35.07;2970000;35.07
1954-12-23;35.37;35.37;35.37;35.37;3310000;35.37
1954-12-22;35.34;35.34;35.34;35.34;3460000;35.34
1954-12-21;35.38;35.38;35.38;35.38;3630000;35.38
1954-12-20;35.33;35.33;35.33;35.33;3770000;35.33
1954-12-17;35.92;35.92;35.92;35.92;3730000;35.92
1954-12-16;34.93;34.93;34.93;34.93;3390000;34.93
1954-12-15;34.56;34.56;34.56;34.56;2740000;34.56
1954-12-14;34.35;34.35;34.35;34.35;2650000;34.35
1954-12-13;34.59;34.59;34.59;34.59;2750000;34.59
1954-12-10;34.56;34.56;34.56;34.56;3250000;34.56
1954-12-09;34.69;34.69;34.69;34.69;3300000;34.69
1954-12-08;34.86;34.86;34.86;34.86;4150000;34.86
1954-12-07;34.92;34.92;34.92;34.92;3820000;34.92
1954-12-06;34.76;34.76;34.76;34.76;3960000;34.76
1954-12-03;34.49;34.49;34.49;34.49;3790000;34.49
1954-12-02;34.18;34.18;34.18;34.18;3190000;34.18
1954-12-01;33.99;33.99;33.99;33.99;3100000;33.99
1954-11-30;34.24;34.24;34.24;34.24;3440000;34.24
1954-11-29;34.54;34.54;34.54;34.54;3300000;34.54
1954-11-26;34.55;34.55;34.55;34.55;3010000;34.55
1954-11-24;34.22;34.22;34.22;34.22;3990000;34.22
1954-11-23;34.03;34.03;34.03;34.03;3690000;34.03
1954-11-22;33.58;33.58;33.58;33.58;3000000;33.58
1954-11-19;33.45;33.45;33.45;33.45;3130000;33.45
1954-11-18;33.44;33.44;33.44;33.44;3530000;33.44
1954-11-17;33.63;33.63;33.63;33.63;3830000;33.63
1954-11-16;33.57;33.57;33.57;33.57;3260000;33.57
1954-11-15;33.47;33.47;33.47;33.47;3080000;33.47
1954-11-12;33.54;33.54;33.54;33.54;3720000;33.54
1954-11-11;33.47;33.47;33.47;33.47;2960000;33.47
1954-11-10;33.18;33.18;33.18;33.18;2070000;33.18
1954-11-09;33.15;33.15;33.15;33.15;3240000;33.15
1954-11-08;33.02;33.02;33.02;33.02;3180000;33.02
1954-11-05;32.71;32.71;32.71;32.71;2950000;32.71
1954-11-04;32.82;32.82;32.82;32.82;3140000;32.82
1954-11-03;32.44;32.44;32.44;32.44;2700000;32.44
1954-11-01;31.79;31.79;31.79;31.79;1790000;31.79
1954-10-29;31.68;31.68;31.68;31.68;1900000;31.68
1954-10-28;31.88;31.88;31.88;31.88;2190000;31.88
1954-10-27;32.02;32.02;32.02;32.02;2030000;32.02
1954-10-26;31.94;31.94;31.94;31.94;2010000;31.94
1954-10-25;31.96;31.96;31.96;31.96;2340000;31.96
1954-10-22;32.13;32.13;32.13;32.13;2080000;32.13
1954-10-21;32.13;32.13;32.13;32.13;2320000;32.13
1954-10-20;32.17;32.17;32.17;32.17;2380000;32.17
1954-10-19;31.91;31.91;31.91;31.91;1900000;31.91
1954-10-18;31.83;31.83;31.83;31.83;1790000;31.83
1954-10-15;31.71;31.71;31.71;31.71;2250000;31.71
1954-10-14;31.88;31.88;31.88;31.88;2540000;31.88
1954-10-13;32.27;32.27;32.27;32.27;2070000;32.27
1954-10-12;32.28;32.28;32.28;32.28;1620000;32.28
1954-10-11;32.41;32.41;32.41;32.41;2100000;32.41
1954-10-08;32.67;32.67;32.67;32.67;2120000;32.67
1954-10-07;32.69;32.69;32.69;32.69;1810000;32.69
1954-10-06;32.76;32.76;32.76;32.76;2570000;32.76
1954-10-05;32.63;32.63;32.63;32.63;2300000;32.63
1954-10-04;32.47;32.47;32.47;32.47;2000000;32.47
1954-10-01;32.29;32.29;32.29;32.29;1850000;32.29
1954-09-30;32.31;32.31;32.31;32.31;1840000;32.31
1954-09-29;32.50;32.50;32.50;32.50;1810000;32.50
1954-09-28;32.69;32.69;32.69;32.69;1800000;32.69
1954-09-27;32.53;32.53;32.53;32.53;2190000;32.53
1954-09-24;32.40;32.40;32.40;32.40;2340000;32.40
1954-09-23;32.18;32.18;32.18;32.18;2340000;32.18
1954-09-22;32.00;32.00;32.00;32.00;2260000;32.00
1954-09-21;31.79;31.79;31.79;31.79;1770000;31.79
1954-09-20;31.57;31.57;31.57;31.57;2060000;31.57
1954-09-17;31.71;31.71;31.71;31.71;2250000;31.71
1954-09-16;31.46;31.46;31.46;31.46;1880000;31.46
1954-09-15;31.29;31.29;31.29;31.29;2110000;31.29
1954-09-14;31.28;31.28;31.28;31.28;2120000;31.28
1954-09-13;31.12;31.12;31.12;31.12;2030000;31.12
1954-09-10;30.84;30.84;30.84;30.84;1870000;30.84
1954-09-09;30.73;30.73;30.73;30.73;1700000;30.73
1954-09-08;30.68;30.68;30.68;30.68;1970000;30.68
1954-09-07;30.66;30.66;30.66;30.66;1860000;30.66
1954-09-03;30.50;30.50;30.50;30.50;1630000;30.50
1954-09-02;30.27;30.27;30.27;30.27;1600000;30.27
1954-09-01;30.04;30.04;30.04;30.04;1790000;30.04
1954-08-31;29.83;29.83;29.83;29.83;2640000;29.83
1954-08-30;30.35;30.35;30.35;30.35;1950000;30.35
1954-08-27;30.66;30.66;30.66;30.66;1740000;30.66
1954-08-26;30.57;30.57;30.57;30.57;2060000;30.57
1954-08-25;30.65;30.65;30.65;30.65;2280000;30.65
1954-08-24;30.87;30.87;30.87;30.87;2000000;30.87
1954-08-23;31.00;31.00;31.00;31.00;2020000;31.00
1954-08-20;31.21;31.21;31.21;31.21;2110000;31.21
1954-08-19;31.16;31.16;31.16;31.16;2320000;31.16
1954-08-18;31.09;31.09;31.09;31.09;2390000;31.09
1954-08-17;31.12;31.12;31.12;31.12;2900000;31.12
1954-08-16;31.05;31.05;31.05;31.05;2760000;31.05
1954-08-13;30.72;30.72;30.72;30.72;2500000;30.72
1954-08-12;30.59;30.59;30.59;30.59;2680000;30.59
1954-08-11;30.72;30.72;30.72;30.72;3440000;30.72
1954-08-10;30.37;30.37;30.37;30.37;2890000;30.37
1954-08-09;30.12;30.12;30.12;30.12;2280000;30.12
1954-08-06;30.38;30.38;30.38;30.38;3350000;30.38
1954-08-05;30.77;30.77;30.77;30.77;3150000;30.77
1954-08-04;30.90;30.90;30.90;30.90;3620000;30.90
1954-08-03;30.93;30.93;30.93;30.93;2970000;30.93
1954-08-02;30.99;30.99;30.99;30.99;2850000;30.99
1954-07-30;30.88;30.88;30.88;30.88;2800000;30.88
1954-07-29;30.69;30.69;30.69;30.69;2710000;30.69
1954-07-28;30.58;30.58;30.58;30.58;2740000;30.58
1954-07-27;30.52;30.52;30.52;30.52;2690000;30.52
1954-07-26;30.34;30.34;30.34;30.34;2110000;30.34
1954-07-23;30.31;30.31;30.31;30.31;2520000;30.31
1954-07-22;30.27;30.27;30.27;30.27;2890000;30.27
1954-07-21;30.03;30.03;30.03;30.03;2510000;30.03
1954-07-20;29.84;29.84;29.84;29.84;2580000;29.84
1954-07-19;29.98;29.98;29.98;29.98;2370000;29.98
1954-07-16;30.06;30.06;30.06;30.06;2540000;30.06
1954-07-15;30.19;30.19;30.19;30.19;3000000;30.19
1954-07-14;30.09;30.09;30.09;30.09;2520000;30.09
1954-07-13;30.02;30.02;30.02;30.02;2430000;30.02
1954-07-12;30.12;30.12;30.12;30.12;2330000;30.12
1954-07-09;30.14;30.14;30.14;30.14;2240000;30.14
1954-07-08;29.94;29.94;29.94;29.94;2080000;29.94
1954-07-07;29.94;29.94;29.94;29.94;2380000;29.94
1954-07-06;29.92;29.92;29.92;29.92;2560000;29.92
1954-07-02;29.59;29.59;29.59;29.59;1980000;29.59
1954-07-01;29.21;29.21;29.21;29.21;1860000;29.21
1954-06-30;29.21;29.21;29.21;29.21;1950000;29.21
1954-06-29;29.43;29.43;29.43;29.43;2580000;29.43
1954-06-28;29.28;29.28;29.28;29.28;1890000;29.28
1954-06-25;29.20;29.20;29.20;29.20;2060000;29.20
1954-06-24;29.26;29.26;29.26;29.26;2260000;29.26
1954-06-23;29.13;29.13;29.13;29.13;2090000;29.13
1954-06-22;29.08;29.08;29.08;29.08;2100000;29.08
1954-06-21;29.06;29.06;29.06;29.06;1820000;29.06
1954-06-18;29.04;29.04;29.04;29.04;1580000;29.04
1954-06-17;28.96;28.96;28.96;28.96;1810000;28.96
1954-06-16;29.04;29.04;29.04;29.04;2070000;29.04
1954-06-15;28.83;28.83;28.83;28.83;1630000;28.83
1954-06-14;28.62;28.62;28.62;28.62;1420000;28.62
1954-06-11;28.58;28.58;28.58;28.58;1630000;28.58
1954-06-10;28.34;28.34;28.34;28.34;1610000;28.34
1954-06-09;28.15;28.15;28.15;28.15;2360000;28.15
1954-06-08;28.34;28.34;28.34;28.34;2540000;28.34
1954-06-07;28.99;28.99;28.99;28.99;1520000;28.99
1954-06-04;29.10;29.10;29.10;29.10;1720000;29.10
1954-06-03;29.15;29.15;29.15;29.15;1810000;29.15
1954-06-02;29.16;29.16;29.16;29.16;1930000;29.16
1954-06-01;29.19;29.19;29.19;29.19;1850000;29.19
1954-05-28;29.19;29.19;29.19;29.19;1940000;29.19
1954-05-27;29.05;29.05;29.05;29.05;2230000;29.05
1954-05-26;29.17;29.17;29.17;29.17;2180000;29.17
1954-05-25;28.93;28.93;28.93;28.93;2050000;28.93
1954-05-24;29.00;29.00;29.00;29.00;2330000;29.00
1954-05-21;28.99;28.99;28.99;28.99;2620000;28.99
1954-05-20;28.82;28.82;28.82;28.82;2070000;28.82
1954-05-19;28.72;28.72;28.72;28.72;2170000;28.72
1954-05-18;28.85;28.85;28.85;28.85;2250000;28.85
1954-05-17;28.84;28.84;28.84;28.84;2040000;28.84
1954-05-14;28.80;28.80;28.80;28.80;1970000;28.80
1954-05-13;28.56;28.56;28.56;28.56;2340000;28.56
1954-05-12;28.72;28.72;28.72;28.72;2210000;28.72
1954-05-11;28.49;28.49;28.49;28.49;1770000;28.49
1954-05-10;28.62;28.62;28.62;28.62;1800000;28.62
1954-05-07;28.65;28.65;28.65;28.65;2070000;28.65
1954-05-06;28.51;28.51;28.51;28.51;1980000;28.51
1954-05-05;28.29;28.29;28.29;28.29;2020000;28.29
1954-05-04;28.28;28.28;28.28;28.28;1990000;28.28
1954-05-03;28.21;28.21;28.21;28.21;1870000;28.21
1954-04-30;28.26;28.26;28.26;28.26;2450000;28.26
1954-04-29;28.18;28.18;28.18;28.18;2150000;28.18
1954-04-28;27.76;27.76;27.76;27.76;2120000;27.76
1954-04-27;27.71;27.71;27.71;27.71;1970000;27.71
1954-04-26;27.88;27.88;27.88;27.88;2150000;27.88
1954-04-23;27.78;27.78;27.78;27.78;1990000;27.78
1954-04-22;27.68;27.68;27.68;27.68;1750000;27.68
1954-04-21;27.64;27.64;27.64;27.64;1870000;27.64
1954-04-20;27.75;27.75;27.75;27.75;1860000;27.75
1954-04-19;27.76;27.76;27.76;27.76;2430000;27.76
1954-04-15;27.94;27.94;27.94;27.94;2200000;27.94
1954-04-14;27.85;27.85;27.85;27.85;2330000;27.85
1954-04-13;27.64;27.64;27.64;27.64;2020000;27.64
1954-04-12;27.57;27.57;27.57;27.57;1790000;27.57
1954-04-09;27.38;27.38;27.38;27.38;2360000;27.38
1954-04-08;27.38;27.38;27.38;27.38;2300000;27.38
1954-04-07;27.11;27.11;27.11;27.11;1830000;27.11
1954-04-06;27.01;27.01;27.01;27.01;2120000;27.01
1954-04-05;27.26;27.26;27.26;27.26;1710000;27.26
1954-04-02;27.21;27.21;27.21;27.21;1830000;27.21
1954-04-01;27.17;27.17;27.17;27.17;2270000;27.17
1954-03-31;26.94;26.94;26.94;26.94;2690000;26.94
1954-03-30;26.69;26.69;26.69;26.69;2130000;26.69
1954-03-29;26.66;26.66;26.66;26.66;1870000;26.66
1954-03-26;26.56;26.56;26.56;26.56;1550000;26.56
1954-03-25;26.42;26.42;26.42;26.42;1720000;26.42
1954-03-24;26.47;26.47;26.47;26.47;1900000;26.47
1954-03-23;26.60;26.60;26.60;26.60;2180000;26.60
1954-03-22;26.79;26.79;26.79;26.79;1800000;26.79
1954-03-19;26.81;26.81;26.81;26.81;1930000;26.81
1954-03-18;26.73;26.73;26.73;26.73;2020000;26.73
1954-03-17;26.62;26.62;26.62;26.62;1740000;26.62
1954-03-16;26.56;26.56;26.56;26.56;1540000;26.56
1954-03-15;26.57;26.57;26.57;26.57;1680000;26.57
1954-03-12;26.69;26.69;26.69;26.69;1980000;26.69
1954-03-11;26.69;26.69;26.69;26.69;2050000;26.69
1954-03-10;26.57;26.57;26.57;26.57;1870000;26.57
1954-03-09;26.51;26.51;26.51;26.51;1630000;26.51
1954-03-08;26.45;26.45;26.45;26.45;1650000;26.45
1954-03-05;26.52;26.52;26.52;26.52;2030000;26.52
1954-03-04;26.41;26.41;26.41;26.41;1830000;26.41
1954-03-03;26.32;26.32;26.32;26.32;2240000;26.32
1954-03-02;26.32;26.32;26.32;26.32;1980000;26.32
1954-03-01;26.25;26.25;26.25;26.25;2040000;26.25
1954-02-26;26.15;26.15;26.15;26.15;1910000;26.15
1954-02-25;25.91;25.91;25.91;25.91;1470000;25.91
1954-02-24;25.83;25.83;25.83;25.83;1350000;25.83
1954-02-23;25.83;25.83;25.83;25.83;1470000;25.83
1954-02-19;25.92;25.92;25.92;25.92;1510000;25.92
1954-02-18;25.86;25.86;25.86;25.86;1500000;25.86
1954-02-17;25.86;25.86;25.86;25.86;1740000;25.86
1954-02-16;25.81;25.81;25.81;25.81;1870000;25.81
1954-02-15;26.04;26.04;26.04;26.04;2080000;26.04
1954-02-12;26.12;26.12;26.12;26.12;1730000;26.12
1954-02-11;26.06;26.06;26.06;26.06;1860000;26.06
1954-02-10;26.14;26.14;26.14;26.14;1790000;26.14
1954-02-09;26.17;26.17;26.17;26.17;1880000;26.17
1954-02-08;26.23;26.23;26.23;26.23;2180000;26.23
1954-02-05;26.30;26.30;26.30;26.30;2030000;26.30
1954-02-04;26.20;26.20;26.20;26.20;2040000;26.20
1954-02-03;26.01;26.01;26.01;26.01;1690000;26.01
1954-02-02;25.92;25.92;25.92;25.92;1420000;25.92
1954-02-01;25.99;25.99;25.99;25.99;1740000;25.99
1954-01-29;26.08;26.08;26.08;26.08;1950000;26.08
1954-01-28;26.02;26.02;26.02;26.02;1730000;26.02
1954-01-27;26.01;26.01;26.01;26.01;2020000;26.01
1954-01-26;26.09;26.09;26.09;26.09;2120000;26.09
1954-01-25;25.93;25.93;25.93;25.93;1860000;25.93
1954-01-22;25.85;25.85;25.85;25.85;1890000;25.85
1954-01-21;25.79;25.79;25.79;25.79;1780000;25.79
1954-01-20;25.75;25.75;25.75;25.75;1960000;25.75
1954-01-19;25.68;25.68;25.68;25.68;1840000;25.68
1954-01-18;25.43;25.43;25.43;25.43;1580000;25.43
1954-01-15;25.43;25.43;25.43;25.43;2180000;25.43
1954-01-14;25.19;25.19;25.19;25.19;1530000;25.19
1954-01-13;25.07;25.07;25.07;25.07;1420000;25.07
1954-01-12;24.93;24.93;24.93;24.93;1250000;24.93
1954-01-11;24.80;24.80;24.80;24.80;1220000;24.80
1954-01-08;24.93;24.93;24.93;24.93;1260000;24.93
1954-01-07;25.06;25.06;25.06;25.06;1540000;25.06
1954-01-06;25.14;25.14;25.14;25.14;1460000;25.14
1954-01-05;25.10;25.10;25.10;25.10;1520000;25.10
1954-01-04;24.95;24.95;24.95;24.95;1310000;24.95
1953-12-31;24.81;24.81;24.81;24.81;2490000;24.81
1953-12-30;24.76;24.76;24.76;24.76;2050000;24.76
1953-12-29;24.55;24.55;24.55;24.55;2140000;24.55
1953-12-28;24.71;24.71;24.71;24.71;1570000;24.71
1953-12-24;24.80;24.80;24.80;24.80;1270000;24.80
1953-12-23;24.69;24.69;24.69;24.69;1570000;24.69
1953-12-22;24.76;24.76;24.76;24.76;1720000;24.76
1953-12-21;24.95;24.95;24.95;24.95;1690000;24.95
1953-12-18;24.99;24.99;24.99;24.99;1550000;24.99
1953-12-17;24.94;24.94;24.94;24.94;1600000;24.94
1953-12-16;24.96;24.96;24.96;24.96;1880000;24.96
1953-12-15;24.71;24.71;24.71;24.71;1450000;24.71
1953-12-14;24.69;24.69;24.69;24.69;1540000;24.69
1953-12-11;24.76;24.76;24.76;24.76;1440000;24.76
1953-12-10;24.78;24.78;24.78;24.78;1420000;24.78
1953-12-09;24.84;24.84;24.84;24.84;1410000;24.84
1953-12-08;24.87;24.87;24.87;24.87;1390000;24.87
1953-12-07;24.95;24.95;24.95;24.95;1410000;24.95
1953-12-04;24.98;24.98;24.98;24.98;1390000;24.98
1953-12-03;24.97;24.97;24.97;24.97;1740000;24.97
1953-12-02;24.95;24.95;24.95;24.95;1850000;24.95
1953-12-01;24.78;24.78;24.78;24.78;1580000;24.78
1953-11-30;24.76;24.76;24.76;24.76;1960000;24.76
1953-11-27;24.66;24.66;24.66;24.66;1600000;24.66
1953-11-25;24.52;24.52;24.52;24.52;1540000;24.52
1953-11-24;24.50;24.50;24.50;24.50;1470000;24.50
1953-11-23;24.36;24.36;24.36;24.36;1410000;24.36
1953-11-20;24.44;24.44;24.44;24.44;1300000;24.44
1953-11-19;24.40;24.40;24.40;24.40;1420000;24.40
1953-11-18;24.29;24.29;24.29;24.29;1250000;24.29
1953-11-17;24.25;24.25;24.25;24.25;1250000;24.25
1953-11-16;24.38;24.38;24.38;24.38;1490000;24.38
1953-11-13;24.54;24.54;24.54;24.54;1540000;24.54
1953-11-12;24.46;24.46;24.46;24.46;1390000;24.46
1953-11-10;24.37;24.37;24.37;24.37;1340000;24.37
1953-11-09;24.66;24.66;24.66;24.66;1440000;24.66
1953-11-06;24.61;24.61;24.61;24.61;1700000;24.61
1953-11-05;24.64;24.64;24.64;24.64;1720000;24.64
1953-11-04;24.51;24.51;24.51;24.51;1480000;24.51
1953-11-02;24.66;24.66;24.66;24.66;1340000;24.66
1953-10-30;24.54;24.54;24.54;24.54;1400000;24.54
1953-10-29;24.58;24.58;24.58;24.58;1610000;24.58
1953-10-28;24.29;24.29;24.29;24.29;1260000;24.29
1953-10-27;24.26;24.26;24.26;24.26;1170000;24.26
1953-10-26;24.31;24.31;24.31;24.31;1340000;24.31
1953-10-23;24.35;24.35;24.35;24.35;1330000;24.35
1953-10-22;24.30;24.30;24.30;24.30;1330000;24.30
1953-10-21;24.19;24.19;24.19;24.19;1320000;24.19
1953-10-20;24.17;24.17;24.17;24.17;1280000;24.17
1953-10-19;24.16;24.16;24.16;24.16;1190000;24.16
1953-10-16;24.14;24.14;24.14;24.14;1620000;24.14
1953-10-15;23.95;23.95;23.95;23.95;1710000;23.95
1953-10-14;23.68;23.68;23.68;23.68;1290000;23.68
1953-10-13;23.57;23.57;23.57;23.57;1130000;23.57
1953-10-09;23.66;23.66;23.66;23.66;900000;23.66
1953-10-08;23.62;23.62;23.62;23.62;960000;23.62
1953-10-07;23.58;23.58;23.58;23.58;1010000;23.58
1953-10-06;23.39;23.39;23.39;23.39;1100000;23.39
1953-10-05;23.48;23.48;23.48;23.48;930000;23.48
1953-10-02;23.59;23.59;23.59;23.59;890000;23.59
1953-10-01;23.49;23.49;23.49;23.49;940000;23.49
1953-09-30;23.35;23.35;23.35;23.35;940000;23.35
1953-09-29;23.49;23.49;23.49;23.49;1170000;23.49
1953-09-28;23.45;23.45;23.45;23.45;1150000;23.45
1953-09-25;23.30;23.30;23.30;23.30;910000;23.30
1953-09-24;23.24;23.24;23.24;23.24;1020000;23.24
1953-09-23;23.23;23.23;23.23;23.23;1240000;23.23
1953-09-22;23.20;23.20;23.20;23.20;1300000;23.20
1953-09-21;22.88;22.88;22.88;22.88;1070000;22.88
1953-09-18;22.95;22.95;22.95;22.95;1190000;22.95
1953-09-17;23.07;23.07;23.07;23.07;1290000;23.07
1953-09-16;23.01;23.01;23.01;23.01;1570000;23.01
1953-09-15;22.90;22.90;22.90;22.90;2850000;22.90
1953-09-14;22.71;22.71;22.71;22.71;2550000;22.71
1953-09-11;23.14;23.14;23.14;23.14;1930000;23.14
1953-09-10;23.41;23.41;23.41;23.41;1010000;23.41
1953-09-09;23.65;23.65;23.65;23.65;860000;23.65
1953-09-08;23.61;23.61;23.61;23.61;740000;23.61
1953-09-04;23.57;23.57;23.57;23.57;770000;23.57
1953-09-03;23.51;23.51;23.51;23.51;900000;23.51
1953-09-02;23.56;23.56;23.56;23.56;1110000;23.56
1953-09-01;23.42;23.42;23.42;23.42;1580000;23.42
1953-08-31;23.32;23.32;23.32;23.32;2190000;23.32
1953-08-28;23.74;23.74;23.74;23.74;1060000;23.74
1953-08-27;23.79;23.79;23.79;23.79;1290000;23.79
1953-08-26;23.86;23.86;23.86;23.86;1060000;23.86
1953-08-25;23.93;23.93;23.93;23.93;1470000;23.93
1953-08-24;24.09;24.09;24.09;24.09;1320000;24.09
1953-08-21;24.35;24.35;24.35;24.35;850000;24.35
1953-08-20;24.29;24.29;24.29;24.29;860000;24.29
1953-08-19;24.31;24.31;24.31;24.31;1400000;24.31
1953-08-18;24.46;24.46;24.46;24.46;1030000;24.46
1953-08-17;24.56;24.56;24.56;24.56;910000;24.56
1953-08-14;24.62;24.62;24.62;24.62;1000000;24.62
1953-08-13;24.73;24.73;24.73;24.73;1040000;24.73
1953-08-12;24.78;24.78;24.78;24.78;990000;24.78
1953-08-11;24.72;24.72;24.72;24.72;940000;24.72
1953-08-10;24.75;24.75;24.75;24.75;1090000;24.75
1953-08-07;24.78;24.78;24.78;24.78;950000;24.78
1953-08-06;24.80;24.80;24.80;24.80;1200000;24.80
1953-08-05;24.68;24.68;24.68;24.68;1080000;24.68
1953-08-04;24.78;24.78;24.78;24.78;1000000;24.78
1953-08-03;24.84;24.84;24.84;24.84;1160000;24.84
1953-07-31;24.75;24.75;24.75;24.75;1320000;24.75
1953-07-30;24.49;24.49;24.49;24.49;1200000;24.49
1953-07-29;24.26;24.26;24.26;24.26;1000000;24.26
1953-07-28;24.11;24.11;24.11;24.11;1080000;24.11
1953-07-27;24.07;24.07;24.07;24.07;1210000;24.07
1953-07-24;24.23;24.23;24.23;24.23;890000;24.23
1953-07-23;24.23;24.23;24.23;24.23;1000000;24.23
1953-07-22;24.19;24.19;24.19;24.19;900000;24.19
1953-07-21;24.16;24.16;24.16;24.16;850000;24.16
1953-07-20;24.22;24.22;24.22;24.22;830000;24.22
1953-07-17;24.35;24.35;24.35;24.35;840000;24.35
1953-07-16;24.18;24.18;24.18;24.18;790000;24.18
1953-07-15;24.15;24.15;24.15;24.15;840000;24.15
1953-07-14;24.08;24.08;24.08;24.08;1030000;24.08
1953-07-13;24.17;24.17;24.17;24.17;1120000;24.17
1953-07-10;24.41;24.41;24.41;24.41;860000;24.41
1953-07-09;24.43;24.43;24.43;24.43;910000;24.43
1953-07-08;24.50;24.50;24.50;24.50;950000;24.50
1953-07-07;24.51;24.51;24.51;24.51;1030000;24.51
1953-07-06;24.38;24.38;24.38;24.38;820000;24.38
1953-07-03;24.36;24.36;24.36;24.36;830000;24.36
1953-07-02;24.31;24.31;24.31;24.31;1030000;24.31
1953-07-01;24.24;24.24;24.24;24.24;910000;24.24
1953-06-30;24.14;24.14;24.14;24.14;820000;24.14
1953-06-29;24.14;24.14;24.14;24.14;800000;24.14
1953-06-26;24.21;24.21;24.21;24.21;830000;24.21
1953-06-25;24.19;24.19;24.19;24.19;1160000;24.19
1953-06-24;24.09;24.09;24.09;24.09;1030000;24.09
1953-06-23;24.12;24.12;24.12;24.12;1050000;24.12
1953-06-22;23.96;23.96;23.96;23.96;1030000;23.96
1953-06-19;23.84;23.84;23.84;23.84;890000;23.84
1953-06-18;23.84;23.84;23.84;23.84;1010000;23.84
1953-06-17;23.85;23.85;23.85;23.85;1150000;23.85
1953-06-16;23.55;23.55;23.55;23.55;1370000;23.55
1953-06-15;23.62;23.62;23.62;23.62;1090000;23.62
1953-06-12;23.82;23.82;23.82;23.82;920000;23.82
1953-06-11;23.75;23.75;23.75;23.75;1220000;23.75
1953-06-10;23.54;23.54;23.54;23.54;1960000;23.54
1953-06-09;23.60;23.60;23.60;23.60;2200000;23.60
1953-06-08;24.01;24.01;24.01;24.01;1000000;24.01
1953-06-05;24.09;24.09;24.09;24.09;1160000;24.09
1953-06-04;24.03;24.03;24.03;24.03;1400000;24.03
1953-06-03;24.18;24.18;24.18;24.18;1050000;24.18
1953-06-02;24.22;24.22;24.22;24.22;1450000;24.22
1953-06-01;24.15;24.15;24.15;24.15;1490000;24.15
1953-05-29;24.54;24.54;24.54;24.54;920000;24.54
1953-05-28;24.46;24.46;24.46;24.46;1240000;24.46
1953-05-27;24.64;24.64;24.64;24.64;1330000;24.64
1953-05-26;24.87;24.87;24.87;24.87;1160000;24.87
1953-05-25;24.99;24.99;24.99;24.99;1180000;24.99
1953-05-22;25.03;25.03;25.03;25.03;1350000;25.03
1953-05-21;25.06;25.06;25.06;25.06;1590000;25.06
1953-05-20;24.93;24.93;24.93;24.93;1690000;24.93
1953-05-19;24.70;24.70;24.70;24.70;1120000;24.70
1953-05-18;24.75;24.75;24.75;24.75;1080000;24.75
1953-05-15;24.84;24.84;24.84;24.84;1200000;24.84
1953-05-14;24.85;24.85;24.85;24.85;1210000;24.85
1953-05-13;24.71;24.71;24.71;24.71;1120000;24.71
1953-05-12;24.74;24.74;24.74;24.74;1080000;24.74
1953-05-11;24.91;24.91;24.91;24.91;1010000;24.91
1953-05-08;24.90;24.90;24.90;24.90;1220000;24.90
1953-05-07;24.90;24.90;24.90;24.90;1110000;24.90
1953-05-06;25.00;25.00;25.00;25.00;1110000;25.00
1953-05-05;25.03;25.03;25.03;25.03;1290000;25.03
1953-05-04;25.00;25.00;25.00;25.00;1520000;25.00
1953-05-01;24.73;24.73;24.73;24.73;1200000;24.73
1953-04-30;24.62;24.62;24.62;24.62;1140000;24.62
1953-04-29;24.68;24.68;24.68;24.68;1310000;24.68
1953-04-28;24.52;24.52;24.52;24.52;1330000;24.52
1953-04-27;24.34;24.34;24.34;24.34;1400000;24.34
1953-04-24;24.20;24.20;24.20;24.20;1780000;24.20
1953-04-23;24.19;24.19;24.19;24.19;1920000;24.19
1953-04-22;24.46;24.46;24.46;24.46;1390000;24.46
1953-04-21;24.67;24.67;24.67;24.67;1250000;24.67
1953-04-20;24.73;24.73;24.73;24.73;1520000;24.73
1953-04-17;24.62;24.62;24.62;24.62;1430000;24.62
1953-04-16;24.91;24.91;24.91;24.91;1310000;24.91
1953-04-15;24.96;24.96;24.96;24.96;1580000;24.96
1953-04-14;24.86;24.86;24.86;24.86;1480000;24.86
1953-04-13;24.77;24.77;24.77;24.77;1280000;24.77
1953-04-10;24.82;24.82;24.82;24.82;1360000;24.82
1953-04-09;24.88;24.88;24.88;24.88;1520000;24.88
1953-04-08;24.93;24.93;24.93;24.93;1860000;24.93
1953-04-07;24.71;24.71;24.71;24.71;2500000;24.71
1953-04-06;24.61;24.61;24.61;24.61;3050000;24.61
1953-04-02;25.23;25.23;25.23;25.23;1720000;25.23
1953-04-01;25.25;25.25;25.25;25.25;2240000;25.25
1953-03-31;25.29;25.29;25.29;25.29;3120000;25.29
1953-03-30;25.61;25.61;25.61;25.61;2740000;25.61
1953-03-27;25.99;25.99;25.99;25.99;1640000;25.99
1953-03-26;25.95;25.95;25.95;25.95;2000000;25.95
1953-03-25;26.10;26.10;26.10;26.10;2320000;26.10
1953-03-24;26.17;26.17;26.17;26.17;1970000;26.17
1953-03-23;26.02;26.02;26.02;26.02;1750000;26.02
1953-03-20;26.18;26.18;26.18;26.18;1730000;26.18
1953-03-19;26.22;26.22;26.22;26.22;1840000;26.22
1953-03-18;26.24;26.24;26.24;26.24;2110000;26.24
1953-03-17;26.33;26.33;26.33;26.33;2110000;26.33
1953-03-16;26.22;26.22;26.22;26.22;1770000;26.22
1953-03-13;26.18;26.18;26.18;26.18;1760000;26.18
1953-03-12;26.13;26.13;26.13;26.13;1780000;26.13
1953-03-11;26.12;26.12;26.12;26.12;1890000;26.12
1953-03-10;25.91;25.91;25.91;25.91;1530000;25.91
1953-03-09;25.83;25.83;25.83;25.83;1600000;25.83
1953-03-06;25.84;25.84;25.84;25.84;1690000;25.84
1953-03-05;25.79;25.79;25.79;25.79;1540000;25.79
1953-03-04;25.78;25.78;25.78;25.78;2010000;25.78
1953-03-03;26.00;26.00;26.00;26.00;1850000;26.00
1953-03-02;25.93;25.93;25.93;25.93;1760000;25.93
1953-02-27;25.90;25.90;25.90;25.90;1990000;25.90
1953-02-26;25.95;25.95;25.95;25.95;2290000;25.95
1953-02-25;25.91;25.91;25.91;25.91;2360000;25.91
1953-02-24;25.75;25.75;25.75;25.75;2300000;25.75
1953-02-20;25.63;25.63;25.63;25.63;1400000;25.63
1953-02-19;25.57;25.57;25.57;25.57;1390000;25.57
1953-02-18;25.48;25.48;25.48;25.48;1220000;25.48
1953-02-17;25.50;25.50;25.50;25.50;1290000;25.50
1953-02-16;25.65;25.65;25.65;25.65;1330000;25.65
1953-02-13;25.74;25.74;25.74;25.74;1350000;25.74
1953-02-11;25.64;25.64;25.64;25.64;1240000;25.64
1953-02-10;25.62;25.62;25.62;25.62;1350000;25.62
1953-02-09;25.69;25.69;25.69;25.69;1780000;25.69
1953-02-06;26.51;26.51;26.51;26.51;1870000;26.51
1953-02-05;26.15;26.15;26.15;26.15;1900000;26.15
1953-02-04;26.42;26.42;26.42;26.42;1660000;26.42
1953-02-03;26.54;26.54;26.54;26.54;1560000;26.54
1953-02-02;26.51;26.51;26.51;26.51;1890000;26.51
1953-01-30;26.38;26.38;26.38;26.38;1760000;26.38
1953-01-29;26.20;26.20;26.20;26.20;1830000;26.20
1953-01-28;26.13;26.13;26.13;26.13;1640000;26.13
1953-01-27;26.05;26.05;26.05;26.05;1550000;26.05
1953-01-26;26.02;26.02;26.02;26.02;1420000;26.02
1953-01-23;26.07;26.07;26.07;26.07;1340000;26.07
1953-01-22;26.12;26.12;26.12;26.12;1380000;26.12
1953-01-21;26.09;26.09;26.09;26.09;1300000;26.09
1953-01-20;26.14;26.14;26.14;26.14;1490000;26.14
1953-01-19;26.01;26.01;26.01;26.01;1360000;26.01
1953-01-16;26.02;26.02;26.02;26.02;1710000;26.02
1953-01-15;26.13;26.13;26.13;26.13;1450000;26.13
1953-01-14;26.08;26.08;26.08;26.08;1370000;26.08
1953-01-13;26.02;26.02;26.02;26.02;1680000;26.02
1953-01-12;25.86;25.86;25.86;25.86;1500000;25.86
1953-01-09;26.08;26.08;26.08;26.08;2080000;26.08
1953-01-08;26.33;26.33;26.33;26.33;1780000;26.33
1953-01-07;26.37;26.37;26.37;26.37;1760000;26.37
1953-01-06;26.48;26.48;26.48;26.48;2080000;26.48
1953-01-05;26.66;26.66;26.66;26.66;2130000;26.66
1953-01-02;26.54;26.54;26.54;26.54;1450000;26.54
1952-12-31;26.57;26.57;26.57;26.57;2050000;26.57
1952-12-30;26.59;26.59;26.59;26.59;2070000;26.59
1952-12-29;26.40;26.40;26.40;26.40;1820000;26.40
1952-12-26;26.25;26.25;26.25;26.25;1290000;26.25
1952-12-24;26.21;26.21;26.21;26.21;1510000;26.21
1952-12-23;26.19;26.19;26.19;26.19;2100000;26.19
1952-12-22;26.30;26.30;26.30;26.30;2100000;26.30
1952-12-19;26.15;26.15;26.15;26.15;2050000;26.15
1952-12-18;26.03;26.03;26.03;26.03;1860000;26.03
1952-12-17;26.04;26.04;26.04;26.04;1700000;26.04
1952-12-16;26.07;26.07;26.07;26.07;1980000;26.07
1952-12-15;26.04;26.04;26.04;26.04;1940000;26.04
1952-12-12;26.04;26.04;26.04;26.04;2030000;26.04
1952-12-11;25.96;25.96;25.96;25.96;1790000;25.96
1952-12-10;25.98;25.98;25.98;25.98;1880000;25.98
1952-12-09;25.93;25.93;25.93;25.93;2120000;25.93
1952-12-08;25.76;25.76;25.76;25.76;1790000;25.76
1952-12-05;25.62;25.62;25.62;25.62;1510000;25.62
1952-12-04;25.61;25.61;25.61;25.61;1570000;25.61
1952-12-03;25.71;25.71;25.71;25.71;1610000;25.71
1952-12-02;25.74;25.74;25.74;25.74;1610000;25.74
1952-12-01;25.68;25.68;25.68;25.68;2100000;25.68
1952-11-28;25.66;25.66;25.66;25.66;2160000;25.66
1952-11-26;25.52;25.52;25.52;25.52;1920000;25.52
1952-11-25;25.36;25.36;25.36;25.36;1930000;25.36
1952-11-24;25.42;25.42;25.42;25.42;2100000;25.42
1952-11-21;25.27;25.27;25.27;25.27;1760000;25.27
1952-11-20;25.28;25.28;25.28;25.28;1740000;25.28
1952-11-19;25.33;25.33;25.33;25.33;2350000;25.33
1952-11-18;25.16;25.16;25.16;25.16;2250000;25.16
1952-11-17;24.80;24.80;24.80;24.80;1490000;24.80
1952-11-14;24.75;24.75;24.75;24.75;1700000;24.75
1952-11-13;24.71;24.71;24.71;24.71;1330000;24.71
1952-11-12;24.65;24.65;24.65;24.65;1490000;24.65
1952-11-10;24.77;24.77;24.77;24.77;1360000;24.77
1952-11-07;24.78;24.78;24.78;24.78;1540000;24.78
1952-11-06;24.77;24.77;24.77;24.77;1390000;24.77
1952-11-05;24.67;24.67;24.67;24.67;2030000;24.67
1952-11-03;24.60;24.60;24.60;24.60;1670000;24.60
1952-10-31;24.52;24.52;24.52;24.52;1760000;24.52
1952-10-30;24.15;24.15;24.15;24.15;1090000;24.15
1952-10-29;24.15;24.15;24.15;24.15;1020000;24.15
1952-10-28;24.13;24.13;24.13;24.13;1080000;24.13
1952-10-27;24.09;24.09;24.09;24.09;1000000;24.09
1952-10-24;24.03;24.03;24.03;24.03;1060000;24.03
1952-10-23;23.87;23.87;23.87;23.87;1260000;23.87
1952-10-22;23.80;23.80;23.80;23.80;1160000;23.80
1952-10-21;24.07;24.07;24.07;24.07;990000;24.07
1952-10-20;24.13;24.13;24.13;24.13;1050000;24.13
1952-10-17;24.20;24.20;24.20;24.20;1360000;24.20
1952-10-16;23.91;23.91;23.91;23.91;1730000;23.91
1952-10-15;24.06;24.06;24.06;24.06;1730000;24.06
1952-10-14;24.48;24.48;24.48;24.48;1130000;24.48
1952-10-10;24.55;24.55;24.55;24.55;1070000;24.55
1952-10-09;24.57;24.57;24.57;24.57;1090000;24.57
1952-10-08;24.58;24.58;24.58;24.58;1260000;24.58
1952-10-07;24.40;24.40;24.40;24.40;950000;24.40
1952-10-06;24.44;24.44;24.44;24.44;1070000;24.44
1952-10-03;24.50;24.50;24.50;24.50;980000;24.50
1952-10-02;24.52;24.52;24.52;24.52;1040000;24.52
1952-10-01;24.48;24.48;24.48;24.48;1060000;24.48
1952-09-30;24.54;24.54;24.54;24.54;1120000;24.54
1952-09-29;24.68;24.68;24.68;24.68;970000;24.68
1952-09-26;24.73;24.73;24.73;24.73;1180000;24.73
1952-09-25;24.81;24.81;24.81;24.81;1210000;24.81
1952-09-24;24.79;24.79;24.79;24.79;1390000;24.79
1952-09-23;24.70;24.70;24.70;24.70;1240000;24.70
1952-09-22;24.59;24.59;24.59;24.59;1160000;24.59
1952-09-19;24.57;24.57;24.57;24.57;1150000;24.57
1952-09-18;24.51;24.51;24.51;24.51;1030000;24.51
1952-09-17;24.58;24.58;24.58;24.58;1000000;24.58
1952-09-16;24.53;24.53;24.53;24.53;1140000;24.53
1952-09-15;24.45;24.45;24.45;24.45;1100000;24.45
1952-09-12;24.71;24.71;24.71;24.71;1040000;24.71
1952-09-11;24.72;24.72;24.72;24.72;970000;24.72
1952-09-10;24.69;24.69;24.69;24.69;1590000;24.69
1952-09-09;24.86;24.86;24.86;24.86;1310000;24.86
1952-09-08;25.11;25.11;25.11;25.11;1170000;25.11
1952-09-05;25.21;25.21;25.21;25.21;1040000;25.21
1952-09-04;25.24;25.24;25.24;25.24;1120000;25.24
1952-09-03;25.25;25.25;25.25;25.25;1200000;25.25
1952-09-02;25.15;25.15;25.15;25.15;970000;25.15
1952-08-29;25.03;25.03;25.03;25.03;890000;25.03
1952-08-28;24.97;24.97;24.97;24.97;980000;24.97
1952-08-27;24.94;24.94;24.94;24.94;930000;24.94
1952-08-26;24.83;24.83;24.83;24.83;890000;24.83
1952-08-25;24.87;24.87;24.87;24.87;840000;24.87
1952-08-22;24.99;24.99;24.99;24.99;910000;24.99
1952-08-21;24.98;24.98;24.98;24.98;800000;24.98
1952-08-20;24.95;24.95;24.95;24.95;960000;24.95
1952-08-19;24.89;24.89;24.89;24.89;980000;24.89
1952-08-18;24.94;24.94;24.94;24.94;1090000;24.94
1952-08-15;25.20;25.20;25.20;25.20;890000;25.20
1952-08-14;25.28;25.28;25.28;25.28;930000;25.28
1952-08-13;25.28;25.28;25.28;25.28;990000;25.28
1952-08-12;25.31;25.31;25.31;25.31;1110000;25.31
1952-08-11;25.52;25.52;25.52;25.52;1160000;25.52
1952-08-08;25.55;25.55;25.55;25.55;1170000;25.55
1952-08-07;25.52;25.52;25.52;25.52;1180000;25.52
1952-08-06;25.44;25.44;25.44;25.44;1140000;25.44
1952-08-05;25.46;25.46;25.46;25.46;1050000;25.46
1952-08-04;25.43;25.43;25.43;25.43;950000;25.43
1952-08-01;25.45;25.45;25.45;25.45;1050000;25.45
1952-07-31;25.40;25.40;25.40;25.40;1230000;25.40
1952-07-30;25.37;25.37;25.37;25.37;1240000;25.37
1952-07-29;25.26;25.26;25.26;25.26;1010000;25.26
1952-07-28;25.20;25.20;25.20;25.20;1030000;25.20
1952-07-25;25.16;25.16;25.16;25.16;1130000;25.16
1952-07-24;25.24;25.24;25.24;25.24;1270000;25.24
1952-07-23;25.11;25.11;25.11;25.11;1020000;25.11
1952-07-22;25.00;25.00;25.00;25.00;910000;25.00
1952-07-21;24.95;24.95;24.95;24.95;780000;24.95
1952-07-18;24.85;24.85;24.85;24.85;1020000;24.85
1952-07-17;25.05;25.05;25.05;25.05;1010000;25.05
1952-07-16;25.16;25.16;25.16;25.16;1120000;25.16
1952-07-15;25.16;25.16;25.16;25.16;1220000;25.16
1952-07-14;25.03;25.03;25.03;25.03;1090000;25.03
1952-07-11;24.98;24.98;24.98;24.98;1040000;24.98
1952-07-10;24.81;24.81;24.81;24.81;1010000;24.81
1952-07-09;24.86;24.86;24.86;24.86;1120000;24.86
1952-07-08;24.96;24.96;24.96;24.96;850000;24.96
1952-07-07;24.97;24.97;24.97;24.97;1080000;24.97
1952-07-03;25.05;25.05;25.05;25.05;1150000;25.05
1952-07-02;25.06;25.06;25.06;25.06;1320000;25.06
1952-07-01;25.12;25.12;25.12;25.12;1450000;25.12
1952-06-30;24.96;24.96;24.96;24.96;1380000;24.96
1952-06-27;24.83;24.83;24.83;24.83;1210000;24.83
1952-06-26;24.75;24.75;24.75;24.75;1190000;24.75
1952-06-25;24.66;24.66;24.66;24.66;1230000;24.66
1952-06-24;24.60;24.60;24.60;24.60;1200000;24.60
1952-06-23;24.56;24.56;24.56;24.56;1200000;24.56
1952-06-20;24.59;24.59;24.59;24.59;1190000;24.59
1952-06-19;24.51;24.51;24.51;24.51;1320000;24.51
1952-06-18;24.43;24.43;24.43;24.43;1270000;24.43
1952-06-17;24.33;24.33;24.33;24.33;920000;24.33
1952-06-16;24.30;24.30;24.30;24.30;980000;24.30
1952-06-13;24.37;24.37;24.37;24.37;1130000;24.37
1952-06-12;24.31;24.31;24.31;24.31;1370000;24.31
1952-06-11;24.31;24.31;24.31;24.31;1190000;24.31
1952-06-10;24.23;24.23;24.23;24.23;1220000;24.23
1952-06-09;24.37;24.37;24.37;24.37;1270000;24.37
1952-06-06;24.26;24.26;24.26;24.26;1520000;24.26
1952-06-05;24.10;24.10;24.10;24.10;1410000;24.10
1952-06-04;23.95;23.95;23.95;23.95;1200000;23.95
1952-06-03;23.78;23.78;23.78;23.78;940000;23.78
1952-06-02;23.80;23.80;23.80;23.80;1190000;23.80
1952-05-29;23.86;23.86;23.86;23.86;1100000;23.86
1952-05-28;23.84;23.84;23.84;23.84;1130000;23.84
1952-05-27;23.88;23.88;23.88;23.88;1040000;23.88
1952-05-26;23.94;23.94;23.94;23.94;940000;23.94
1952-05-23;23.89;23.89;23.89;23.89;1150000;23.89
1952-05-22;23.91;23.91;23.91;23.91;1360000;23.91
1952-05-21;23.78;23.78;23.78;23.78;1210000;23.78
1952-05-20;23.74;23.74;23.74;23.74;1150000;23.74
1952-05-19;23.61;23.61;23.61;23.61;780000;23.61
1952-05-16;23.56;23.56;23.56;23.56;910000;23.56
1952-05-15;23.60;23.60;23.60;23.60;1050000;23.60
1952-05-14;23.68;23.68;23.68;23.68;950000;23.68
1952-05-13;23.78;23.78;23.78;23.78;890000;23.78
1952-05-12;23.75;23.75;23.75;23.75;800000;23.75
1952-05-09;23.84;23.84;23.84;23.84;960000;23.84
1952-05-08;23.86;23.86;23.86;23.86;1230000;23.86
1952-05-07;23.81;23.81;23.81;23.81;1120000;23.81
1952-05-06;23.67;23.67;23.67;23.67;1120000;23.67
1952-05-05;23.66;23.66;23.66;23.66;860000;23.66
1952-05-02;23.56;23.56;23.56;23.56;1300000;23.56
1952-05-01;23.17;23.17;23.17;23.17;1400000;23.17
1952-04-30;23.32;23.32;23.32;23.32;1000000;23.32
1952-04-29;23.49;23.49;23.49;23.49;1170000;23.49
1952-04-28;23.55;23.55;23.55;23.55;980000;23.55
1952-04-25;23.54;23.54;23.54;23.54;1240000;23.54
1952-04-24;23.43;23.43;23.43;23.43;1580000;23.43
1952-04-23;23.48;23.48;23.48;23.48;1090000;23.48
1952-04-22;23.58;23.58;23.58;23.58;1240000;23.58
1952-04-21;23.69;23.69;23.69;23.69;1110000;23.69
1952-04-18;23.50;23.50;23.50;23.50;1240000;23.50
1952-04-17;23.41;23.41;23.41;23.41;1620000;23.41
1952-04-16;23.58;23.58;23.58;23.58;1400000;23.58
1952-04-15;23.65;23.65;23.65;23.65;1720000;23.65
1952-04-14;23.95;23.95;23.95;23.95;1790000;23.95
1952-04-10;24.11;24.11;24.11;24.11;1130000;24.11
1952-04-09;23.94;23.94;23.94;23.94;980000;23.94
1952-04-08;23.91;23.91;23.91;23.91;1090000;23.91
1952-04-07;23.80;23.80;23.80;23.80;1230000;23.80
1952-04-04;24.02;24.02;24.02;24.02;1190000;24.02
1952-04-03;24.12;24.12;24.12;24.12;1280000;24.12
1952-04-02;24.12;24.12;24.12;24.12;1260000;24.12
1952-04-01;24.18;24.18;24.18;24.18;1720000;24.18
1952-03-31;24.37;24.37;24.37;24.37;1680000;24.37
1952-03-28;24.18;24.18;24.18;24.18;1560000;24.18
1952-03-27;23.99;23.99;23.99;23.99;1370000;23.99
1952-03-26;23.78;23.78;23.78;23.78;1030000;23.78
1952-03-25;23.79;23.79;23.79;23.79;1060000;23.79
1952-03-24;23.93;23.93;23.93;23.93;1040000;23.93
1952-03-21;23.93;23.93;23.93;23.93;1290000;23.93
1952-03-20;23.89;23.89;23.89;23.89;1240000;23.89
1952-03-19;23.82;23.82;23.82;23.82;1090000;23.82
1952-03-18;23.87;23.87;23.87;23.87;1170000;23.87
1952-03-17;23.92;23.92;23.92;23.92;1150000;23.92
1952-03-14;23.75;23.75;23.75;23.75;1350000;23.75
1952-03-13;23.75;23.75;23.75;23.75;1270000;23.75
1952-03-12;23.73;23.73;23.73;23.73;1310000;23.73
1952-03-11;23.62;23.62;23.62;23.62;1210000;23.62
1952-03-10;23.60;23.60;23.60;23.60;1170000;23.60
1952-03-07;23.72;23.72;23.72;23.72;1410000;23.72
1952-03-06;23.69;23.69;23.69;23.69;1210000;23.69
1952-03-05;23.71;23.71;23.71;23.71;1380000;23.71
1952-03-04;23.68;23.68;23.68;23.68;1570000;23.68
1952-03-03;23.29;23.29;23.29;23.29;1020000;23.29
1952-02-29;23.26;23.26;23.26;23.26;1000000;23.26
1952-02-28;23.29;23.29;23.29;23.29;1150000;23.29
1952-02-27;23.18;23.18;23.18;23.18;1260000;23.18
1952-02-26;23.15;23.15;23.15;23.15;1080000;23.15
1952-02-25;23.23;23.23;23.23;23.23;1200000;23.23
1952-02-21;23.16;23.16;23.16;23.16;1360000;23.16
1952-02-20;23.09;23.09;23.09;23.09;1970000;23.09
1952-02-19;23.36;23.36;23.36;23.36;1630000;23.36
1952-02-18;23.74;23.74;23.74;23.74;1140000;23.74
1952-02-15;23.86;23.86;23.86;23.86;1200000;23.86
1952-02-14;23.87;23.87;23.87;23.87;1340000;23.87
1952-02-13;23.92;23.92;23.92;23.92;1300000;23.92
1952-02-11;24.11;24.11;24.11;24.11;1140000;24.11
1952-02-08;24.24;24.24;24.24;24.24;1350000;24.24
1952-02-07;24.11;24.11;24.11;24.11;1170000;24.11
1952-02-06;24.18;24.18;24.18;24.18;1310000;24.18
1952-02-05;24.11;24.11;24.11;24.11;1590000;24.11
1952-02-04;24.12;24.12;24.12;24.12;1640000;24.12
1952-02-01;24.30;24.30;24.30;24.30;1350000;24.30
1952-01-31;24.14;24.14;24.14;24.14;1810000;24.14
1952-01-30;24.23;24.23;24.23;24.23;1880000;24.23
1952-01-29;24.57;24.57;24.57;24.57;1730000;24.57
1952-01-28;24.61;24.61;24.61;24.61;1590000;24.61
1952-01-25;24.55;24.55;24.55;24.55;1650000;24.55
1952-01-24;24.56;24.56;24.56;24.56;1570000;24.56
1952-01-23;24.54;24.54;24.54;24.54;1680000;24.54
1952-01-22;24.66;24.66;24.66;24.66;1920000;24.66
1952-01-21;24.46;24.46;24.46;24.46;1730000;24.46
1952-01-18;24.25;24.25;24.25;24.25;1740000;24.25
1952-01-17;24.20;24.20;24.20;24.20;1590000;24.20
1952-01-16;24.09;24.09;24.09;24.09;1430000;24.09
1952-01-15;24.06;24.06;24.06;24.06;1340000;24.06
1952-01-14;24.16;24.16;24.16;24.16;1510000;24.16
1952-01-11;23.98;23.98;23.98;23.98;1760000;23.98
1952-01-10;23.86;23.86;23.86;23.86;1520000;23.86
1952-01-09;23.74;23.74;23.74;23.74;1370000;23.74
1952-01-08;23.82;23.82;23.82;23.82;1390000;23.82
1952-01-07;23.91;23.91;23.91;23.91;1540000;23.91
1952-01-04;23.92;23.92;23.92;23.92;1480000;23.92
1952-01-03;23.88;23.88;23.88;23.88;1220000;23.88
1952-01-02;23.80;23.80;23.80;23.80;1070000;23.80
1951-12-31;23.77;23.77;23.77;23.77;1440000;23.77
1951-12-28;23.69;23.69;23.69;23.69;1470000;23.69
1951-12-27;23.65;23.65;23.65;23.65;1460000;23.65
1951-12-26;23.44;23.44;23.44;23.44;1520000;23.44
1951-12-24;23.54;23.54;23.54;23.54;680000;23.54
1951-12-21;23.51;23.51;23.51;23.51;1250000;23.51
1951-12-20;23.57;23.57;23.57;23.57;1340000;23.57
1951-12-19;23.57;23.57;23.57;23.57;1510000;23.57
1951-12-18;23.49;23.49;23.49;23.49;1290000;23.49
1951-12-17;23.41;23.41;23.41;23.41;1220000;23.41
1951-12-14;23.37;23.37;23.37;23.37;1360000;23.37
1951-12-13;23.39;23.39;23.39;23.39;1380000;23.39
1951-12-12;23.37;23.37;23.37;23.37;1280000;23.37
1951-12-11;23.30;23.30;23.30;23.30;1360000;23.30
1951-12-10;23.42;23.42;23.42;23.42;1340000;23.42
1951-12-07;23.38;23.38;23.38;23.38;1990000;23.38
1951-12-06;23.34;23.34;23.34;23.34;1840000;23.34
1951-12-05;23.07;23.07;23.07;23.07;1330000;23.07
1951-12-04;23.14;23.14;23.14;23.14;1280000;23.14
1951-12-03;23.01;23.01;23.01;23.01;1220000;23.01
1951-11-30;22.88;22.88;22.88;22.88;1530000;22.88
1951-11-29;22.67;22.67;22.67;22.67;1070000;22.67
1951-11-28;22.61;22.61;22.61;22.61;1150000;22.61
1951-11-27;22.66;22.66;22.66;22.66;1310000;22.66
1951-11-26;22.43;22.43;22.43;22.43;1180000;22.43
1951-11-23;22.40;22.40;22.40;22.40;1210000;22.40
1951-11-21;22.64;22.64;22.64;22.64;1090000;22.64
1951-11-20;22.68;22.68;22.68;22.68;1130000;22.68
1951-11-19;22.73;22.73;22.73;22.73;1030000;22.73
1951-11-16;22.82;22.82;22.82;22.82;1140000;22.82
1951-11-15;22.84;22.84;22.84;22.84;1200000;22.84
1951-11-14;22.85;22.85;22.85;22.85;1220000;22.85
1951-11-13;22.79;22.79;22.79;22.79;1160000;22.79
1951-11-09;22.75;22.75;22.75;22.75;1470000;22.75
1951-11-08;22.47;22.47;22.47;22.47;1410000;22.47
1951-11-07;22.49;22.49;22.49;22.49;1490000;22.49
1951-11-05;22.82;22.82;22.82;22.82;1130000;22.82
1951-11-02;22.93;22.93;22.93;22.93;1230000;22.93
1951-11-01;23.10;23.10;23.10;23.10;1430000;23.10
1951-10-31;22.94;22.94;22.94;22.94;1490000;22.94
1951-10-30;22.66;22.66;22.66;22.66;1530000;22.66
1951-10-29;22.69;22.69;22.69;22.69;1780000;22.69
1951-10-26;22.81;22.81;22.81;22.81;1710000;22.81
1951-10-25;22.96;22.96;22.96;22.96;1360000;22.96
1951-10-24;23.03;23.03;23.03;23.03;1670000;23.03
1951-10-23;22.84;22.84;22.84;22.84;2110000;22.84
1951-10-22;22.75;22.75;22.75;22.75;2690000;22.75
1951-10-19;23.32;23.32;23.32;23.32;1990000;23.32
1951-10-18;23.67;23.67;23.67;23.67;1450000;23.67
1951-10-17;23.69;23.69;23.69;23.69;1460000;23.69
1951-10-16;23.77;23.77;23.77;23.77;1730000;23.77
1951-10-15;23.85;23.85;23.85;23.85;1720000;23.85
1951-10-11;23.70;23.70;23.70;23.70;1760000;23.70
1951-10-10;23.61;23.61;23.61;23.61;1320000;23.61
1951-10-09;23.65;23.65;23.65;23.65;1750000;23.65
1951-10-08;23.75;23.75;23.75;23.75;1860000;23.75
1951-10-05;23.78;23.78;23.78;23.78;2080000;23.78
1951-10-04;23.72;23.72;23.72;23.72;1810000;23.72
1951-10-03;23.79;23.79;23.79;23.79;2780000;23.79
1951-10-02;23.64;23.64;23.64;23.64;1870000;23.64
1951-10-01;23.47;23.47;23.47;23.47;1330000;23.47
1951-09-28;23.26;23.26;23.26;23.26;1390000;23.26
1951-09-27;23.27;23.27;23.27;23.27;1540000;23.27
1951-09-26;23.40;23.40;23.40;23.40;1520000;23.40
1951-09-25;23.38;23.38;23.38;23.38;1740000;23.38
1951-09-24;23.30;23.30;23.30;23.30;1630000;23.30
1951-09-21;23.40;23.40;23.40;23.40;2180000;23.40
1951-09-20;23.57;23.57;23.57;23.57;2100000;23.57
1951-09-19;23.59;23.59;23.59;23.59;2070000;23.59
1951-09-18;23.59;23.59;23.59;23.59;2030000;23.59
1951-09-17;23.62;23.62;23.62;23.62;1800000;23.62
1951-09-14;23.69;23.69;23.69;23.69;2170000;23.69
1951-09-13;23.71;23.71;23.71;23.71;2350000;23.71
1951-09-12;23.60;23.60;23.60;23.60;2180000;23.60
1951-09-11;23.50;23.50;23.50;23.50;2040000;23.50
1951-09-10;23.62;23.62;23.62;23.62;2190000;23.62
1951-09-07;23.53;23.53;23.53;23.53;1970000;23.53
1951-09-06;23.47;23.47;23.47;23.47;2150000;23.47
1951-09-05;23.42;23.42;23.42;23.42;1850000;23.42
1951-09-04;23.28;23.28;23.28;23.28;1520000;23.28
1951-08-31;23.28;23.28;23.28;23.28;1530000;23.28
1951-08-30;23.24;23.24;23.24;23.24;1950000;23.24
1951-08-29;23.08;23.08;23.08;23.08;1520000;23.08
1951-08-28;22.90;22.90;22.90;22.90;1280000;22.90
1951-08-27;22.85;22.85;22.85;22.85;1080000;22.85
1951-08-24;22.88;22.88;22.88;22.88;1210000;22.88
1951-08-23;22.90;22.90;22.90;22.90;1230000;22.90
1951-08-22;22.75;22.75;22.75;22.75;1130000;22.75
1951-08-21;22.83;22.83;22.83;22.83;1400000;22.83
1951-08-20;22.93;22.93;22.93;22.93;1130000;22.93
1951-08-17;22.94;22.94;22.94;22.94;1620000;22.94
1951-08-16;22.87;22.87;22.87;22.87;1750000;22.87
1951-08-15;22.79;22.79;22.79;22.79;1340000;22.79
1951-08-14;22.70;22.70;22.70;22.70;1180000;22.70
1951-08-13;22.80;22.80;22.80;22.80;1320000;22.80
1951-08-10;22.79;22.79;22.79;22.79;1260000;22.79
1951-08-09;22.84;22.84;22.84;22.84;1500000;22.84
1951-08-08;22.93;22.93;22.93;22.93;1410000;22.93
1951-08-07;23.03;23.03;23.03;23.03;1810000;23.03
1951-08-06;23.01;23.01;23.01;23.01;1600000;23.01
1951-08-03;22.85;22.85;22.85;22.85;1570000;22.85
1951-08-02;22.82;22.82;22.82;22.82;2130000;22.82
1951-08-01;22.51;22.51;22.51;22.51;1680000;22.51
1951-07-31;22.40;22.40;22.40;22.40;1550000;22.40
1951-07-30;22.63;22.63;22.63;22.63;1600000;22.63
1951-07-27;22.53;22.53;22.53;22.53;1450000;22.53
1951-07-26;22.47;22.47;22.47;22.47;1480000;22.47
1951-07-25;22.32;22.32;22.32;22.32;1870000;22.32
1951-07-24;22.44;22.44;22.44;22.44;1740000;22.44
1951-07-23;22.10;22.10;22.10;22.10;1320000;22.10
1951-07-20;21.88;21.88;21.88;21.88;1390000;21.88
1951-07-19;21.84;21.84;21.84;21.84;1120000;21.84
1951-07-18;21.88;21.88;21.88;21.88;1370000;21.88
1951-07-17;21.92;21.92;21.92;21.92;1280000;21.92
1951-07-16;21.73;21.73;21.73;21.73;1200000;21.73
1951-07-13;21.98;21.98;21.98;21.98;1320000;21.98
1951-07-12;21.80;21.80;21.80;21.80;1050000;21.80
1951-07-11;21.68;21.68;21.68;21.68;970000;21.68
1951-07-10;21.63;21.63;21.63;21.63;990000;21.63
1951-07-09;21.73;21.73;21.73;21.73;1110000;21.73
1951-07-06;21.64;21.64;21.64;21.64;1170000;21.64
1951-07-05;21.64;21.64;21.64;21.64;1410000;21.64
1951-07-03;21.23;21.23;21.23;21.23;1250000;21.23
1951-07-02;21.10;21.10;21.10;21.10;1350000;21.10
1951-06-29;20.96;20.96;20.96;20.96;1730000;20.96
1951-06-28;21.10;21.10;21.10;21.10;1940000;21.10
1951-06-27;21.37;21.37;21.37;21.37;1360000;21.37
1951-06-26;21.30;21.30;21.30;21.30;1260000;21.30
1951-06-25;21.29;21.29;21.29;21.29;2440000;21.29
1951-06-22;21.55;21.55;21.55;21.55;1340000;21.55
1951-06-21;21.78;21.78;21.78;21.78;1100000;21.78
1951-06-20;21.91;21.91;21.91;21.91;1120000;21.91
1951-06-19;22.02;22.02;22.02;22.02;1100000;22.02
1951-06-18;22.05;22.05;22.05;22.05;1050000;22.05
1951-06-15;22.04;22.04;22.04;22.04;1370000;22.04
1951-06-14;21.84;21.84;21.84;21.84;1300000;21.84
1951-06-13;21.55;21.55;21.55;21.55;1060000;21.55
1951-06-12;21.52;21.52;21.52;21.52;1200000;21.52
1951-06-11;21.61;21.61;21.61;21.61;1220000;21.61
1951-06-08;21.49;21.49;21.49;21.49;1000000;21.49
1951-06-07;21.56;21.56;21.56;21.56;1340000;21.56
1951-06-06;21.48;21.48;21.48;21.48;1200000;21.48
1951-06-05;21.33;21.33;21.33;21.33;1180000;21.33
1951-06-04;21.24;21.24;21.24;21.24;1100000;21.24
1951-06-01;21.48;21.48;21.48;21.48;9810000;21.48
1951-05-31;21.52;21.52;21.52;21.52;1220000;21.52
1951-05-29;21.35;21.35;21.35;21.35;1190000;21.35
1951-05-28;21.21;21.21;21.21;21.21;1240000;21.21
1951-05-25;21.03;21.03;21.03;21.03;1210000;21.03
1951-05-24;21.05;21.05;21.05;21.05;2580000;21.05
1951-05-23;21.16;21.16;21.16;21.16;1540000;21.16
1951-05-22;21.36;21.36;21.36;21.36;1440000;21.36
1951-05-21;21.46;21.46;21.46;21.46;1580000;21.46
1951-05-18;21.51;21.51;21.51;21.51;1660000;21.51
1951-05-17;21.91;21.91;21.91;21.91;1370000;21.91
1951-05-16;21.69;21.69;21.69;21.69;1660000;21.69
1951-05-15;21.76;21.76;21.76;21.76;2020000;21.76
1951-05-14;22.18;22.18;22.18;22.18;1250000;22.18
1951-05-11;22.33;22.33;22.33;22.33;1640000;22.33
1951-05-10;22.51;22.51;22.51;22.51;1660000;22.51
1951-05-09;22.64;22.64;22.64;22.64;1960000;22.64
1951-05-08;22.61;22.61;22.61;22.61;1600000;22.61
1951-05-07;22.63;22.63;22.63;22.63;1580000;22.63
1951-05-04;22.77;22.77;22.77;22.77;2050000;22.77
1951-05-03;22.81;22.81;22.81;22.81;2060000;22.81
1951-05-02;22.62;22.62;22.62;22.62;1900000;22.62
1951-05-01;22.53;22.53;22.53;22.53;1760000;22.53
1951-04-30;22.43;22.43;22.43;22.43;1790000;22.43
1951-04-27;22.39;22.39;22.39;22.39;2120000;22.39
1951-04-26;22.16;22.16;22.16;22.16;1800000;22.16
1951-04-25;21.97;21.97;21.97;21.97;1520000;21.97
1951-04-24;21.96;21.96;21.96;21.96;1420000;21.96
1951-04-23;22.05;22.05;22.05;22.05;1160000;22.05
1951-04-20;22.04;22.04;22.04;22.04;940000;22.04
1951-04-19;22.04;22.04;22.04;22.04;1520000;22.04
1951-04-18;22.13;22.13;22.13;22.13;1780000;22.13
1951-04-17;22.09;22.09;22.09;22.09;1470000;22.09
1951-04-16;22.04;22.04;22.04;22.04;1730000;22.04
1951-04-13;22.09;22.09;22.09;22.09;2120000;22.09
1951-04-12;21.83;21.83;21.83;21.83;1530000;21.83
1951-04-11;21.64;21.64;21.64;21.64;1420000;21.64
1951-04-10;21.65;21.65;21.65;21.65;1280000;21.65
1951-04-09;21.68;21.68;21.68;21.68;1110000;21.68
1951-04-06;21.72;21.72;21.72;21.72;1450000;21.72
1951-04-05;21.69;21.69;21.69;21.69;1790000;21.69
1951-04-04;21.40;21.40;21.40;21.40;1300000;21.40
1951-04-03;21.26;21.26;21.26;21.26;1220000;21.26
1951-04-02;21.32;21.32;21.32;21.32;1280000;21.32
1951-03-30;21.48;21.48;21.48;21.48;1150000;21.48
1951-03-29;21.33;21.33;21.33;21.33;1300000;21.33
1951-03-28;21.26;21.26;21.26;21.26;1770000;21.26
1951-03-27;21.51;21.51;21.51;21.51;1250000;21.51
1951-03-26;21.53;21.53;21.53;21.53;1230000;21.53
1951-03-22;21.73;21.73;21.73;21.73;1290000;21.73
1951-03-21;21.64;21.64;21.64;21.64;1310000;21.64
1951-03-20;21.52;21.52;21.52;21.52;1020000;21.52
1951-03-19;21.56;21.56;21.56;21.56;1120000;21.56
1951-03-16;21.64;21.64;21.64;21.64;1660000;21.64
1951-03-15;21.29;21.29;21.29;21.29;2070000;21.29
1951-03-14;21.25;21.25;21.25;21.25;2110000;21.25
1951-03-13;21.41;21.41;21.41;21.41;2330000;21.41
1951-03-12;21.70;21.70;21.70;21.70;1640000;21.70
1951-03-09;21.95;21.95;21.95;21.95;1610000;21.95
1951-03-08;21.95;21.95;21.95;21.95;1440000;21.95
1951-03-07;21.86;21.86;21.86;21.86;1770000;21.86
1951-03-06;21.79;21.79;21.79;21.79;1490000;21.79
1951-03-05;21.79;21.79;21.79;21.79;1690000;21.79
1951-03-02;21.93;21.93;21.93;21.93;1570000;21.93
1951-03-01;21.85;21.85;21.85;21.85;1610000;21.85
1951-02-28;21.80;21.80;21.80;21.80;1640000;21.80
1951-02-27;21.76;21.76;21.76;21.76;1680000;21.76
1951-02-26;21.93;21.93;21.93;21.93;1650000;21.93
1951-02-23;21.92;21.92;21.92;21.92;1540000;21.92
1951-02-21;21.86;21.86;21.86;21.86;1670000;21.86
1951-02-20;21.79;21.79;21.79;21.79;2010000;21.79
1951-02-19;21.83;21.83;21.83;21.83;1910000;21.83
1951-02-16;22.13;22.13;22.13;22.13;1860000;22.13
1951-02-15;22.00;22.00;22.00;22.00;1700000;22.00
1951-02-14;22.12;22.12;22.12;22.12;2050000;22.12
1951-02-13;22.18;22.18;22.18;22.18;2400000;22.18
1951-02-09;22.17;22.17;22.17;22.17;2550000;22.17
1951-02-08;22.09;22.09;22.09;22.09;2120000;22.09
1951-02-07;21.99;21.99;21.99;21.99;2020000;21.99
1951-02-06;22.12;22.12;22.12;22.12;2370000;22.12
1951-02-05;22.20;22.20;22.20;22.20;2680000;22.20
1951-02-02;21.96;21.96;21.96;21.96;3030000;21.96
1951-02-01;21.77;21.77;21.77;21.77;2380000;21.77
1951-01-31;21.66;21.66;21.66;21.66;2340000;21.66
1951-01-30;21.74;21.74;21.74;21.74;2480000;21.74
1951-01-29;21.67;21.67;21.67;21.67;2630000;21.67
1951-01-26;21.26;21.26;21.26;21.26;2230000;21.26
1951-01-25;21.03;21.03;21.03;21.03;2520000;21.03
1951-01-24;21.16;21.16;21.16;21.16;1990000;21.16
1951-01-23;21.26;21.26;21.26;21.26;2080000;21.26
1951-01-22;21.18;21.18;21.18;21.18;2570000;21.18
1951-01-19;21.36;21.36;21.36;21.36;3170000;21.36
1951-01-18;21.40;21.40;21.40;21.40;3490000;21.40
1951-01-17;21.55;21.55;21.55;21.55;3880000;21.55
1951-01-16;21.46;21.46;21.46;21.46;3740000;21.46
1951-01-15;21.30;21.30;21.30;21.30;2830000;21.30
1951-01-12;21.11;21.11;21.11;21.11;2950000;21.11
1951-01-11;21.19;21.19;21.19;21.19;3490000;21.19
1951-01-10;20.85;20.85;20.85;20.85;3270000;20.85
1951-01-09;21.12;21.12;21.12;21.12;3800000;21.12
1951-01-08;21.00;21.00;21.00;21.00;2780000;21.00
1951-01-05;20.87;20.87;20.87;20.87;3390000;20.87
1951-01-04;20.87;20.87;20.87;20.87;3390000;20.87
1951-01-03;20.69;20.69;20.69;20.69;3370000;20.69
1951-01-02;20.77;20.77;20.77;20.77;3030000;20.77
1950-12-29;20.43;20.43;20.43;20.43;3440000;20.43
1950-12-28;20.38;20.38;20.38;20.38;3560000;20.38
1950-12-27;20.30;20.30;20.30;20.30;2940000;20.30
1950-12-26;19.92;19.92;19.92;19.92;2660000;19.92
1950-12-22;20.07;20.07;20.07;20.07;2720000;20.07
1950-12-21;19.98;19.98;19.98;19.98;3990000;19.98
1950-12-20;19.97;19.97;19.97;19.97;3510000;19.97
1950-12-19;19.96;19.96;19.96;19.96;3650000;19.96
1950-12-18;19.85;19.85;19.85;19.85;4500000;19.85
1950-12-15;19.33;19.33;19.33;19.33;2420000;19.33
1950-12-14;19.43;19.43;19.43;19.43;2660000;19.43
1950-12-13;19.67;19.67;19.67;19.67;2030000;19.67
1950-12-12;19.68;19.68;19.68;19.68;2140000;19.68
1950-12-11;19.72;19.72;19.72;19.72;2600000;19.72
1950-12-08;19.40;19.40;19.40;19.40;2310000;19.40
1950-12-07;19.40;19.40;19.40;19.40;1810000;19.40
1950-12-06;19.45;19.45;19.45;19.45;2010000;19.45
1950-12-05;19.31;19.31;19.31;19.31;1940000;19.31
1950-12-04;19.00;19.00;19.00;19.00;2510000;19.00
1950-12-01;19.66;19.66;19.66;19.66;1870000;19.66
1950-11-30;19.51;19.51;19.51;19.51;2080000;19.51
1950-11-29;19.37;19.37;19.37;19.37;2770000;19.37
1950-11-28;19.56;19.56;19.56;19.56;2970000;19.56
1950-11-27;20.18;20.18;20.18;20.18;1740000;20.18
1950-11-24;20.32;20.32;20.32;20.32;2620000;20.32
1950-11-22;20.16;20.16;20.16;20.16;2730000;20.16
1950-11-21;19.88;19.88;19.88;19.88;2010000;19.88
1950-11-20;19.93;19.93;19.93;19.93;2250000;19.93
1950-11-17;19.86;19.86;19.86;19.86;2130000;19.86
1950-11-16;19.72;19.72;19.72;19.72;1760000;19.72
1950-11-15;19.82;19.82;19.82;19.82;1620000;19.82
1950-11-14;19.86;19.86;19.86;19.86;1780000;19.86
1950-11-13;20.01;20.01;20.01;20.01;1630000;20.01
1950-11-10;19.94;19.94;19.94;19.94;1640000;19.94
1950-11-09;19.79;19.79;19.79;19.79;1760000;19.79
1950-11-08;19.56;19.56;19.56;19.56;1850000;19.56
1950-11-06;19.36;19.36;19.36;19.36;2580000;19.36
1950-11-03;19.85;19.85;19.85;19.85;1560000;19.85
1950-11-02;19.73;19.73;19.73;19.73;1580000;19.73
1950-11-01;19.56;19.56;19.56;19.56;1780000;19.56
1950-10-31;19.53;19.53;19.53;19.53;2010000;19.53
1950-10-30;19.61;19.61;19.61;19.61;1790000;19.61
1950-10-27;19.77;19.77;19.77;19.77;1800000;19.77
1950-10-26;19.61;19.61;19.61;19.61;3000000;19.61
1950-10-25;20.05;20.05;20.05;20.05;1930000;20.05
1950-10-24;20.08;20.08;20.08;20.08;1790000;20.08
1950-10-23;19.96;19.96;19.96;19.96;1850000;19.96
1950-10-20;19.96;19.96;19.96;19.96;1840000;19.96
1950-10-19;20.02;20.02;20.02;20.02;2250000;20.02
1950-10-18;20.01;20.01;20.01;20.01;2410000;20.01
1950-10-17;19.89;19.89;19.89;19.89;2010000;19.89
1950-10-16;19.71;19.71;19.71;19.71;1630000;19.71
1950-10-13;19.85;19.85;19.85;19.85;2030000;19.85
1950-10-11;19.86;19.86;19.86;19.86;2200000;19.86
1950-10-10;19.78;19.78;19.78;19.78;1870000;19.78
1950-10-09;20.00;20.00;20.00;20.00;2330000;20.00
1950-10-06;20.12;20.12;20.12;20.12;2360000;20.12
1950-10-05;19.89;19.89;19.89;19.89;2490000;19.89
1950-10-04;20.00;20.00;20.00;20.00;2920000;20.00
1950-10-03;19.66;19.66;19.66;19.66;2480000;19.66
1950-10-02;19.69;19.69;19.69;19.69;2200000;19.69
1950-09-29;19.45;19.45;19.45;19.45;1800000;19.45
1950-09-28;19.42;19.42;19.42;19.42;2200000;19.42
1950-09-27;19.41;19.41;19.41;19.41;2360000;19.41
1950-09-26;19.14;19.14;19.14;19.14;2280000;19.14
1950-09-25;19.42;19.42;19.42;19.42;2020000;19.42
1950-09-22;19.44;19.44;19.44;19.44;2510000;19.44
1950-09-21;19.37;19.37;19.37;19.37;1650000;19.37
1950-09-20;19.21;19.21;19.21;19.21;2100000;19.21
1950-09-19;19.31;19.31;19.31;19.31;1590000;19.31
1950-09-18;19.37;19.37;19.37;19.37;2040000;19.37
1950-09-15;19.29;19.29;19.29;19.29;2410000;19.29
1950-09-14;19.18;19.18;19.18;19.18;2350000;19.18
1950-09-13;19.09;19.09;19.09;19.09;2600000;19.09
1950-09-12;18.87;18.87;18.87;18.87;1680000;18.87
1950-09-11;18.61;18.61;18.61;18.61;1860000;18.61
1950-09-08;18.75;18.75;18.75;18.75;1960000;18.75
1950-09-07;18.59;18.59;18.59;18.59;1340000;18.59
1950-09-06;18.54;18.54;18.54;18.54;1300000;18.54
1950-09-05;18.68;18.68;18.68;18.68;1250000;18.68
1950-09-01;18.55;18.55;18.55;18.55;1290000;18.55
1950-08-31;18.42;18.42;18.42;18.42;1140000;18.42
1950-08-30;18.43;18.43;18.43;18.43;1490000;18.43
1950-08-29;18.54;18.54;18.54;18.54;1890000;18.54
1950-08-28;18.53;18.53;18.53;18.53;1300000;18.53
1950-08-25;18.54;18.54;18.54;18.54;1610000;18.54
1950-08-24;18.79;18.79;18.79;18.79;1620000;18.79
1950-08-23;18.82;18.82;18.82;18.82;1580000;18.82
1950-08-22;18.68;18.68;18.68;18.68;1550000;18.68
1950-08-21;18.70;18.70;18.70;18.70;1840000;18.70
1950-08-18;18.68;18.68;18.68;18.68;1780000;18.68
1950-08-17;18.54;18.54;18.54;18.54;2170000;18.54
1950-08-16;18.34;18.34;18.34;18.34;1770000;18.34
1950-08-15;18.32;18.32;18.32;18.32;1330000;18.32
1950-08-14;18.29;18.29;18.29;18.29;1280000;18.29
1950-08-11;18.28;18.28;18.28;18.28;1680000;18.28
1950-08-10;18.48;18.48;18.48;18.48;1870000;18.48
1950-08-09;18.61;18.61;18.61;18.61;1760000;18.61
1950-08-08;18.46;18.46;18.46;18.46;2180000;18.46
1950-08-07;18.41;18.41;18.41;18.41;1850000;18.41
1950-08-04;18.14;18.14;18.14;18.14;1600000;18.14
1950-08-03;17.99;17.99;17.99;17.99;1660000;17.99
1950-08-02;17.95;17.95;17.95;17.95;1980000;17.95
1950-08-01;18.02;18.02;18.02;18.02;1970000;18.02
1950-07-31;17.84;17.84;17.84;17.84;1590000;17.84
1950-07-28;17.69;17.69;17.69;17.69;2050000;17.69
1950-07-27;17.50;17.50;17.50;17.50;2300000;17.50
1950-07-26;17.27;17.27;17.27;17.27;2460000;17.27
1950-07-25;17.23;17.23;17.23;17.23;2770000;17.23
1950-07-24;17.48;17.48;17.48;17.48;2300000;17.48
1950-07-21;17.59;17.59;17.59;17.59;2810000;17.59
1950-07-20;17.61;17.61;17.61;17.61;3160000;17.61
1950-07-19;17.36;17.36;17.36;17.36;2430000;17.36
1950-07-18;17.06;17.06;17.06;17.06;1820000;17.06
1950-07-17;16.68;16.68;16.68;16.68;1520000;16.68
1950-07-14;16.87;16.87;16.87;16.87;1900000;16.87
1950-07-13;16.69;16.69;16.69;16.69;2660000;16.69
1950-07-12;16.87;16.87;16.87;16.87;3200000;16.87
1950-07-11;17.32;17.32;17.32;17.32;3250000;17.32
1950-07-10;17.59;17.59;17.59;17.59;1960000;17.59
1950-07-07;17.67;17.67;17.67;17.67;1870000;17.67
1950-07-06;17.91;17.91;17.91;17.91;1570000;17.91
1950-07-05;17.81;17.81;17.81;17.81;1400000;17.81
1950-07-03;17.64;17.64;17.64;17.64;1550000;17.64
1950-06-30;17.69;17.69;17.69;17.69;2660000;17.69
1950-06-29;17.44;17.44;17.44;17.44;3040000;17.44
1950-06-28;18.11;18.11;18.11;18.11;2600000;18.11
1950-06-27;17.91;17.91;17.91;17.91;4860000;17.91
1950-06-26;18.11;18.11;18.11;18.11;3950000;18.11
1950-06-23;19.14;19.14;19.14;19.14;1700000;19.14
1950-06-22;19.16;19.16;19.16;19.16;1830000;19.16
1950-06-21;19.00;19.00;19.00;19.00;1750000;19.00
1950-06-20;18.83;18.83;18.83;18.83;1470000;18.83
1950-06-19;18.92;18.92;18.92;18.92;1290000;18.92
1950-06-16;18.97;18.97;18.97;18.97;1180000;18.97
1950-06-15;18.93;18.93;18.93;18.93;1530000;18.93
1950-06-14;18.98;18.98;18.98;18.98;1650000;18.98
1950-06-13;19.25;19.25;19.25;19.25;1790000;19.25
1950-06-12;19.40;19.40;19.40;19.40;1790000;19.40
1950-06-09;19.26;19.26;19.26;19.26;2130000;19.26
1950-06-08;19.14;19.14;19.14;19.14;1780000;19.14
1950-06-07;18.93;18.93;18.93;18.93;1750000;18.93
1950-06-06;18.88;18.88;18.88;18.88;2250000;18.88
1950-06-05;18.60;18.60;18.60;18.60;1630000;18.60
1950-06-02;18.79;18.79;18.79;18.79;1450000;18.79
1950-06-01;18.77;18.77;18.77;18.77;1580000;18.77
1950-05-31;18.78;18.78;18.78;18.78;1530000;18.78
1950-05-29;18.72;18.72;18.72;18.72;1110000;18.72
1950-05-26;18.67;18.67;18.67;18.67;1330000;18.67
1950-05-25;18.69;18.69;18.69;18.69;1480000;18.69
1950-05-24;18.69;18.69;18.69;18.69;1850000;18.69
1950-05-23;18.71;18.71;18.71;18.71;1460000;18.71
1950-05-22;18.60;18.60;18.60;18.60;1620000;18.60
1950-05-19;18.68;18.68;18.68;18.68;2110000;18.68
1950-05-18;18.56;18.56;18.56;18.56;5240000;18.56
1950-05-17;18.52;18.52;18.52;18.52;2020000;18.52
1950-05-16;18.44;18.44;18.44;18.44;1730000;18.44
1950-05-15;18.26;18.26;18.26;18.26;1220000;18.26
1950-05-12;18.18;18.18;18.18;18.18;1790000;18.18
1950-05-11;18.29;18.29;18.29;18.29;1750000;18.29
1950-05-10;18.29;18.29;18.29;18.29;1880000;18.29
1950-05-09;18.27;18.27;18.27;18.27;1720000;18.27
1950-05-08;18.27;18.27;18.27;18.27;1680000;18.27
1950-05-05;18.22;18.22;18.22;18.22;1800000;18.22
1950-05-04;18.12;18.12;18.12;18.12;2150000;18.12
1950-05-03;18.27;18.27;18.27;18.27;2120000;18.27
1950-05-02;18.11;18.11;18.11;18.11;2250000;18.11
1950-05-01;18.22;18.22;18.22;18.22;2390000;18.22
1950-04-28;17.96;17.96;17.96;17.96;2190000;17.96
1950-04-27;17.86;17.86;17.86;17.86;2070000;17.86
1950-04-26;17.76;17.76;17.76;17.76;1880000;17.76
1950-04-25;17.83;17.83;17.83;17.83;1830000;17.83
1950-04-24;17.83;17.83;17.83;17.83;2310000;17.83
1950-04-21;17.96;17.96;17.96;17.96;2710000;17.96
1950-04-20;17.93;17.93;17.93;17.93;2590000;17.93
1950-04-19;18.05;18.05;18.05;18.05;2950000;18.05
1950-04-18;18.03;18.03;18.03;18.03;3320000;18.03
1950-04-17;17.88;17.88;17.88;17.88;2520000;17.88
1950-04-14;17.96;17.96;17.96;17.96;2750000;17.96
1950-04-13;17.98;17.98;17.98;17.98;2410000;17.98
1950-04-12;17.94;17.94;17.94;17.94;2010000;17.94
1950-04-11;17.75;17.75;17.75;17.75;2010000;17.75
1950-04-10;17.85;17.85;17.85;17.85;2070000;17.85
1950-04-06;17.78;17.78;17.78;17.78;2000000;17.78
1950-04-05;17.63;17.63;17.63;17.63;1430000;17.63
1950-04-04;17.55;17.55;17.55;17.55;2010000;17.55
1950-04-03;17.53;17.53;17.53;17.53;1570000;17.53
1950-03-31;17.29;17.29;17.29;17.29;1880000;17.29
1950-03-30;17.30;17.30;17.30;17.30;2370000;17.30
1950-03-29;17.44;17.44;17.44;17.44;2090000;17.44
1950-03-28;17.53;17.53;17.53;17.53;1780000;17.53
1950-03-27;17.46;17.46;17.46;17.46;1930000;17.46
1950-03-24;17.56;17.56;17.56;17.56;1570000;17.56
1950-03-23;17.56;17.56;17.56;17.56;2020000;17.56
1950-03-22;17.55;17.55;17.55;17.55;2010000;17.55
1950-03-21;17.45;17.45;17.45;17.45;1400000;17.45
1950-03-20;17.44;17.44;17.44;17.44;1430000;17.44
1950-03-17;17.45;17.45;17.45;17.45;1600000;17.45
1950-03-16;17.49;17.49;17.49;17.49;2060000;17.49
1950-03-15;17.45;17.45;17.45;17.45;1830000;17.45
1950-03-14;17.25;17.25;17.25;17.25;1140000;17.25
1950-03-13;17.12;17.12;17.12;17.12;1060000;17.12
1950-03-10;17.09;17.09;17.09;17.09;1260000;17.09
1950-03-09;17.07;17.07;17.07;17.07;1330000;17.07
1950-03-08;17.19;17.19;17.19;17.19;1360000;17.19
1950-03-07;17.20;17.20;17.20;17.20;1590000;17.20
1950-03-06;17.32;17.32;17.32;17.32;1470000;17.32
1950-03-03;17.29;17.29;17.29;17.29;1520000;17.29
1950-03-02;17.23;17.23;17.23;17.23;1340000;17.23
1950-03-01;17.24;17.24;17.24;17.24;1410000;17.24
1950-02-28;17.22;17.22;17.22;17.22;1310000;17.22
1950-02-27;17.28;17.28;17.28;17.28;1410000;17.28
1950-02-24;17.28;17.28;17.28;17.28;1710000;17.28
1950-02-23;17.21;17.21;17.21;17.21;1310000;17.21
1950-02-21;17.17;17.17;17.17;17.17;1260000;17.17
1950-02-20;17.20;17.20;17.20;17.20;1420000;17.20
1950-02-17;17.15;17.15;17.15;17.15;1940000;17.15
1950-02-16;16.99;16.99;16.99;16.99;1920000;16.99
1950-02-15;17.06;17.06;17.06;17.06;1730000;17.06
1950-02-14;17.06;17.06;17.06;17.06;2210000;17.06
1950-02-10;17.24;17.24;17.24;17.24;1790000;17.24
1950-02-09;17.28;17.28;17.28;17.28;1810000;17.28
1950-02-08;17.21;17.21;17.21;17.21;1470000;17.21
1950-02-07;17.23;17.23;17.23;17.23;1360000;17.23
1950-02-06;17.32;17.32;17.32;17.32;1490000;17.32
1950-02-03;17.29;17.29;17.29;17.29;2210000;17.29
1950-02-02;17.23;17.23;17.23;17.23;2040000;17.23
1950-02-01;17.05;17.05;17.05;17.05;1810000;17.05
1950-01-31;17.05;17.05;17.05;17.05;1690000;17.05
1950-01-30;17.02;17.02;17.02;17.02;1640000;17.02
1950-01-27;16.82;16.82;16.82;16.82;1250000;16.82
1950-01-26;16.73;16.73;16.73;16.73;1150000;16.73
1950-01-25;16.74;16.74;16.74;16.74;1700000;16.74
1950-01-24;16.86;16.86;16.86;16.86;1250000;16.86
1950-01-23;16.92;16.92;16.92;16.92;1340000;16.92
1950-01-20;16.90;16.90;16.90;16.90;1440000;16.90
1950-01-19;16.87;16.87;16.87;16.87;1170000;16.87
1950-01-18;16.85;16.85;16.85;16.85;1570000;16.85
1950-01-17;16.86;16.86;16.86;16.86;1790000;16.86
1950-01-16;16.72;16.72;16.72;16.72;1460000;16.72
1950-01-13;16.67;16.67;16.67;16.67;3330000;16.67
1950-01-12;16.76;16.76;16.76;16.76;2970000;16.76
1950-01-11;17.09;17.09;17.09;17.09;2630000;17.09
1950-01-10;17.03;17.03;17.03;17.03;2160000;17.03
1950-01-09;17.08;17.08;17.08;17.08;2520000;17.08
1950-01-06;16.98;16.98;16.98;16.98;2010000;16.98
1950-01-05;16.93;16.93;16.93;16.93;2550000;16.93
1950-01-04;16.85;16.85;16.85;16.85;1890000;16.85
1950-01-03;16.66;16.66;16.66;16.66;1260000;16.66
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      