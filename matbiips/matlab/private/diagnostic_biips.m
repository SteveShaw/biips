function [diagn] = diagnostic_biips(parts, ess_thres, quiet, fsb)
% BIIPS_DIAGNOSTIC returns a diagnostic structure
% diagn = biips_diagnostic(particles, ess_thres, quiet)
% INPUT
% -particles : input structure containing the particles of different variables.
%              usually returned by biips_smc_samples function
% -ess_thres : integer. Threshold on the Effective Sample Size (ESS) of the
%              examined particles. If all the ESS components are over the
%              threshold, the diagnostic is valid, otherwise it is not
%              valid.
% -quiet : flag. deactivate message display
% -fsb : character 'f', 's' or 'b', indicating the SMC variant
% OUTPUT
% -diagn : output structure

ess_min = parts.ess;
dim = length(ess_min);

for d=dim:-1:1
    ess_min=min(ess_min);
end

diagn.ess_min = ess_min;
diagn.valid = (ess_min>ess_thres);

if ~quiet
end

if ~quiet
    switch (fsb)
        case 'f'
            name = 'Filtering (f)';
        case 's'
            name = 'Smoothing (s)';
        case 'b'
            name = 'Backward smoothing (b)';
    end
    if diagn.valid
        disp([name, ' diagnostic: GOOD']);
    else
        disp([name, ' diagnostic: POOR'])
        disp(['    The minimum effective sample size is too low: ', num2str(diagn.ess_min)])
        disp('    Estimates may be poor for some variables.')
        disp('    You should increase n_part.')
    end
end