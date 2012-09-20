function varnames = biips_get_variable_names(p)
% BIIPS_GET_VARIABLE_NAMES returns the variable names of the current model
%  variable_names = biips_get_variable_names(p)
% INPUT
%  -p : number of the current console
% OUTPUT
%  - variable_names : cell containing the current variable names 
varnames= inter_biips('get_variable_names', p);
