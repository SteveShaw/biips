%% Matbiips: Tutorial 1
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



%% Installation of Matbiips
% Unzip the Matbiips archive in some folder
% and add the Matbiips folder to the Matlab path
% 

%% 
% *Add Matbiips functions in the search path*
matbiips_path = '../../matbiips';
addpath(matbiips_path)

%% General settings
%
set(0, 'DefaultAxesFontsize', 14);
set(0, 'Defaultlinelinewidth', 2)

% Set the random numbers generator seed for reproducibility
if isoctave() || verLessThan('matlab', '7.12')
    rand ('state', 0)
else
    rng('default')
end

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

%% Biips Sequential Monte Carlo
% Let now use Biips to run a particle filter. 

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
% The sequence of filtering distributions is automatically chosen by Biips
% based on the topology of the graphical model, and is returned in the
% subfield 'f.conditionals'. For this particular example, the sequence of
% filtering distributions is $\pi(x_{t}|y_{1:t})$, for $t=1,\ldots,t_{max}$.

fprintf('Filtering distributions:\n')
for i=1:length(out_smc.x.f.conditionals)
    fprintf('%i: x[%i]|',i, i);
    fprintf('%s,',out_smc.x.f.conditionals{i}{:});
     fprintf('\n')
end

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


%% Biips Particle Independent Metropolis-Hastings
% We now use Biips to run a Particle Independent Metropolis-Hastings

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
    [1 .7 .7]);
set(h, 'edgecolor', 'none')
hold on
plot(x_pimh_mean, 'r', 'linewidth', 3)
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
    plot(samples_pimh.x(tk, :), 'r')
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
    hist(samples_pimh.x(tk, :), -15:1:15);
    h = findobj(gca,'Type','patch');
    set(h,'FaceColor','r','EdgeColor','w')
    hold on    
    plot(data.x_true(tk), 0, '*g');
    xlabel(['x_{', num2str(tk), '}']);
    ylabel('Number of samples');
    title(['t=', num2str(tk)]);   
    xlim([-15,15])
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
    plot(kde_estimates_pimh.x(tk).x, kde_estimates_pimh.x(tk).f, 'r'); 
    hold on
    plot(data.x_true(tk), 0, '*g');
    xlabel(['x_{', num2str(tk) '}']);
    ylabel('Posterior density');
    title(['t=', num2str(tk)]);    
    xlim([-15,15])
    box off
end
h = legend({'Posterior density', 'True value'});
set(h, 'position',[0.7, 0.25, .1, .1])
legend('boxoff')

%% Clear model
% 

biips_clear()
