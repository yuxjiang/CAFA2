function [result] = cafa_collect(res_dir, varname, models)
%CAFA_COLLECT CAFA collect
%
% [result] = CAFA_COLLECT(res_dir, varname);
%
%   Collects variables from each .mat file under the given folder.
%
% [result] = CAFA_COLLECT(res_dir, varname, models);
%
%   Collects variables from specified .mat files under the given folder.
%
% Input
% -----
% [char]
% res_dir:  The result folder.
%
% [char]
% varname:  The name of the variable needs to be collected.
%
% (optional)
% [cell]
% models:   A list of model IDs (should be the same as filenames without
%           extension), If 'models' is not given or given as empty, then all
%           models in that directory would be collected.
%           default: {}
%
% Output
% ------
% [cell]
% result: A cell array of result.

  % check inputs {{{
  if nargin ~= 2 && nargin ~= 3
    error('cafa_collect:InputCount', 'Expected 2 or 3 inputs.');
  end

  if nargin == 2
    models = {};
  end

  % res_dir
  validateattributes(res_dir, {'char'}, {'nonempty'}, '', 'res_dir', 1);
  if ~exist(res_dir, 'dir')
    error('cafa_collect:NoDir', 'Result folder doesn''t exist.');
  end
  res_dir = regexprep([res_dir, '/'], '//', '/');

  % varname
  validateattributes(varname, {'char'}, {'nonempty'}, '', 'varname', 2);

  % models
  validateattributes(models, {'cell'}, {}, '', 'models', 3);
  % }}}

  % collect data {{{
  files = dir(strcat(res_dir, '*.mat'));
  if ~isempty(models)
    drop = false(1, numel(files));
    for i = 1 : numel(files)
      if ~ismember(regexprep(files(i).name, '\..*', ''), models)
        drop(i) = true;
      end
    end
    files(drop) = [];

    % reorder files according to 'models'
    [~, order] = ismember(models, regexprep({files.name}, '\..*', ''));
    files = files(order);
  end
  n = numel(files);

  result = cell(1, n);
  fprintf('Collecting %s ... ', varname);
  for i = 1 : n
    data = load(strcat(res_dir, files(i).name), varname);
    result{i} = data.(varname);
  end
  fprintf('done.\n');
  % }}}
return

% -------------
% Yuxiang Jiang (yuxjiang@indiana.edu)
% Department of Computer Science
% Indiana University Bloomington
% Last modified: Mon 23 May 2016 06:34:41 PM E
