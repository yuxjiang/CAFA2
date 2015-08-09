function [config] = cafa_parse_config(config_file)
%CAFA_PARSE_CONFIG CAFA parse configuration
% {{{
%
% [config] = CAFA_PARSE_CONFIG(config_file);
%
%   Parses a CAFA evaluation job configuration file.
%
% Input
% -----
% [char]
%   config_file:  the configuration file (job descriptor)
%
% Output
% ------
% [struct]
%   config:       the parsed structure.
%
% Dependency
% ----------
%[>]pfp_loaditem.m
%[>]cafa_parse_config.m
%[>]cafa_eval_seq_curve.m
%[>]cafa_eval_seq_fmax.m
%[>]cafa_eval_seq_smin.m
%[>]cafa_eval_seq_fmax_bst.m
%[>]cafa_eval_seq_smin_bst.m
%[>]cafa_eval_term_auc.m
% }}}

  % check_inputs {{{
  if nargin ~= 1
    error('cafa_parse_config:InputCount', 'Expected 1 input.');
  end

  % check the 1st input 'config_file' {{{
  validateattributes(config_file, {'char'}, {'nonempty'}, '', 'config_file', 1);
  fid = fopen(config_file, 'r');
  if fid == -1
    error('cafa_parse_config:FileErr', 'Cannot open the configuration file [%s]', config_file);
  end
  % }}}
  % }}}

  % read and parse {{{
  metric       = {};
  models       = {};
  models_plus  = {};
  models_minus = {};

  tline = fgetl(fid);
  while ischar(tline)
    % remove comments, anything after #
    tline = strtrim(regexprep(tline, '#.*', ''));

    if ~isempty(tline)
      % split: tag = value
      parsed = strsplit(tline, '\s*=\s*', 'DelimiterType', 'RegularExpression');

      fprintf('[%s] = [%s]\n', parsed{1}, parsed{2});

      % parse (tag, value) pairs {{{
      if strcmp(parsed{1}, 'prev_dir')
        config.prev_dir = regexprep(strcat(parsed{2}, '/'), '//', '/');
      elseif strcmp(parsed{1}, 'eval_dir')
        eval_dir = regexprep(strcat(parsed{2}, '/'), '//', '/');
      elseif strcmp(parsed{1}, 'pred_dir')
        config.pred_dir = regexprep(strcat(parsed{2}, '/'), '//', '/');
      elseif strcmp(parsed{1}, 'ont_term')
        config.ont_term = parsed{2};
      elseif strcmp(parsed{1}, 'benchmark')
        config.bm = pfp_loaditem(parsed{2}, 'char');
      elseif strcmp(parsed{1}, 'annotation')
        load(parsed{2}, 'oa');
        config.oa = oa;
      elseif strcmp(parsed{1}, 'bootstrap')
        bootstrap_file = parsed{2};
      elseif strcmp(parsed{1}, 'ontology')
        config.ont = parsed{2};
      elseif strcmp(parsed{1}, 'category')
        config.cat = parsed{2};
      elseif strcmp(parsed{1}, 'type')
        config.tp = parsed{2};
      elseif strcmp(parsed{1}, 'mode')
        config.md = parsed{2};
      elseif strcmp(parsed{1}, 'metric')
        metric = [metric, parsed(2)];
      elseif strcmp(parsed{1}, 'beta')
        config.beta = str2double(parsed{2});
      elseif strcmp(parsed{1}, 'model')
        if parsed{2}(1) == '+'
          models_plus = [models_plus, parsed{2}(2:end)];
        elseif parsed{2}(1) == '-'
          models_minus = [models_minus, parsed{2}(2:end)];
        else
          models = [models, parsed{2}];
        end
      elseif strcmp(parsed{1}, 'naive')
        config.naive = parsed{2};
      elseif strcmp(parsed{1}, 'blast')
        config.blast = parsed{2};
      else
        error('cafa_parse_config:UnknownTag', 'Unknown configuration tag [%s]', parsed{1});
      end
    end
    % }}}

    % read the next line
    tline = fgetl(fid);
  end
  fclose(fid);
  % }}}

  % default beta {{{
  if ~isfield(config, 'beta')
    config.beta = 1;
  end
  % }}}

  % translate metrics {{{
  config.do_seq_fmax  = false;
  config.do_seq_smin  = false;
  config.do_seq_wfmax = false;
  config.do_seq_nsmin = false;
  config.do_term_auc  = false;

  if ismember('f', metric)
    config.do_seq_fmax = true;
  end

  if ismember('wf', metric)
    config.do_seq_wfmax = true;
  end

  if ismember('s', metric)
    config.do_seq_smin = true;
  end

  if ismember('ns', metric)
    config.do_seq_nsmin = true;
  end

  if ismember('auc', metric)
    config.do_term_auc = true;
  end
  % }}}

  % translate models {{{
  if ismember('all', models)
    models = setdiff(models, 'all');
    files = dir(strcat(config.pred_dir, 'M*.mat'));
    models = union(models, regexprep({files.name}, '\.mat$', ''));
  end
  models = union(models, models_plus);
  models = setdiff(models, models_minus);
  config.model = unique(models);

  if ismember('none', models)
    config.model = {};
  end
  % }}}

  % load / make bootstrap indices {{{
  if exist(bootstrap_file, 'file')
    load(bootstrap_file, 'BI');
  else
    N = 10000;
    m = numel(config.bm);
    BI = zeros(N, m);
    for i = 1 : N
      BI(i, :) = randsample(m, m, true);
    end
    save(bootstrap_file, 'BI');
  end
  config.bi = BI;
  clear BI;
  % }}}

  % generate result sub-dir {{{
  sub_dir = sprintf('%s_%s_type%s_mode%s/', config.ont, config.cat, config.tp, config.md);
  config.eval_dir = strcat(eval_dir, sub_dir);
  if ~exist(config.eval_dir, 'dir')
    mkdir(config.eval_dir);
  end
  % }}}
return

% -------------
% Yuxiang Jiang (yuxjiang@indiana.edu)
% Department of Computer Science
% Indiana University, Bloomington
% Last modified: Sun 09 Aug 2015 05:08:59 PM E
