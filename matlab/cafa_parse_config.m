function [config] = cafa_parse_config(config_file)
%CAFA_PARSE_CONFIG CAFA parse configuration
% {{{
%
% [config] = CAFA_PARSE_CONFIG(config_file);
%
%   Parses a CAFA pre-evalation/evaluation job configuration file.
%
% Input
% -----
% [char]
% config_file:  The configuration file (job descriptor)
%
% Output
% ------
% [struct]
% config: The parsed structure, which contains:
%         [P] [E] [fields]      [description]
%          +   +  pred_dir:     where (imported) prediction structures are
%          +   +  prev_dir:     where pre-evaluation structures are
%              +  eval_dir:     where evaluation result structures are
%          +   +  oa:           the ontology annotation structure (groundtruth)
%          +   +  bm:           benchmark of this evaluation category
%          +   +  ont:          which ontology {'mfo', 'bpo', 'cco', 'hpo'}
%              +  cat:          benchmark category
%              +  tp:           benchmark type, '1' or '2'
%              +  md:           evaluation mode, '1', or '2'
%          +   +  beta:         the beta in F_{beta} measure (default: 1)
%          +   +  order:        the order in S_{order} measure (default: 2)
%          +   +  do_seq_fmax:  toggle for compute 'seq_fmax'
%          +   +  do_seq_smin:  toggle for compute 'seq_smin'
%          +   +  do_seq_wfmax: toggle for compute 'seq_wfmax'
%          +   +  do_seq_nsmin: toggle for compute 'seq_nsmin'
%              +  do_term_auc:  toggle for compute 'term_auc'
%          +   +  model:        a cel array of model IDs of interest
%              +  bi:           an index of bootstrap benchmark IDs
%
%          Note: fields marked (with +) in the [P] column are read/required by
%          "cafa_driver_preeval.m"; while those marked in the [E] column are
%          read/required by "cafa_driver_eval.m".
%
% See Also
% --------
%[>]cafa_driver_preeval.m
%[>]cafa_driver_eval.m
%
% Dependency
% ----------
%[>]pfp_loaditem.m
%[>]pfp_savevar.m
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

  % default toggles {{{
  config.do_seq_fmax  = false;
  config.do_seq_smin  = false;
  config.do_seq_wfmax = false;
  config.do_seq_nsmin = false;
  config.do_term_auc  = false;
  % }}}

  % default values {{{
  config.beta  = 1.0;
  config.order = 2.0;
  % }}}

  save_for_later = [];

  tline = fgetl(fid);
  while ischar(tline)
    % remove comments, anything after #
    tline = strtrim(regexprep(tline, '#.*', ''));

    if ~isempty(tline)
      % split: tag = value
      parsed = strsplit(tline, '\s*=\s*', 'DelimiterType', 'RegularExpression');
      % fprintf('[%s] = [%s]\n', parsed{1}, parsed{2});
      % parse (tag, value) pairs {{{
      if strcmp(parsed{1}, 'prev_dir')
        config.prev_dir = regexprep(strcat(parsed{2}, '/'), '//', '/');
      elseif strcmp(parsed{1}, 'eval_dir')
        config.eval_dir = regexprep(strcat(parsed{2}, '/'), '//', '/');
      elseif strcmp(parsed{1}, 'pred_dir')
        config.pred_dir = regexprep(strcat(parsed{2}, '/'), '//', '/');
      elseif strcmp(parsed{1}, 'benchmark')
        config.bm = pfp_loaditem(parsed{2}, 'char');
      elseif strcmp(parsed{1}, 'annotation')
        data = load(parsed{2});
        config.oa = data.oa;
        clear data;
      elseif strcmp(parsed{1}, 'bootstrap')
        save_for_later.bootstrap_file = parsed{2};
      elseif strcmp(parsed{1}, 'ontology')
        config.ont = parsed{2};
      elseif strcmp(parsed{1}, 'category')
        config.cat = parsed{2};
      elseif strcmp(parsed{1}, 'type')
        config.tp = parsed{2};
      elseif strcmp(parsed{1}, 'mode')
        config.md = parsed{2};
      elseif strcmp(parsed{1}, 'metric')
        if strcmp(parsed{2}, 'f')
          config.do_seq_fmax = true;
        elseif strcmp(parsed{2}, 's')
          config.do_seq_smin = true;
        elseif strcmp(parsed{2}, 'wf')
          config.do_seq_wfmax = true;
        elseif strcmp(parsed{2}, 'ns')
          config.do_seq_nsmin = true;
        elseif strcmp(parsed{2}, 'auc')
          config.do_term_auc = true;
        else
          % skip
        end
      elseif strcmp(parsed{1}, 'beta')
        config.beta = str2double(parsed{2});
      elseif strcmp(parsed{1}, 'order')
        config.order = str2double(parsed{2});
      elseif strcmp(parsed{1}, 'model')
        if parsed{2}(1) == '+'
          models_plus = [models_plus, parsed{2}(2:end)];
        elseif parsed{2}(1) == '-'
          models_minus = [models_minus, parsed{2}(2:end)];
        else
          models = [models, parsed{2}];
        end
      % elseif strcmp(parsed{1}, 'naive')
      %   config.naive = parsed{2};
      % elseif strcmp(parsed{1}, 'blast')
      %   config.blast = parsed{2};
      else
        error('cafa_parse_config:UnknownTag', 'Unknown configuration tag [%s]', parsed{1});
      end
    % }}}
    end

    % read the next line
    tline = fgetl(fid);
  end
  fclose(fid);
  % }}}

  % translate models {{{
  % models = (all) + models_plus - model_minus
  if ismember('all', models)
    % get all model ids in prediction dir
    models = setdiff(models, 'all');
    files  = dir(strcat(config.cons_dir, 'M*'));
    models = union(models, regexprep({files.name}, '\..*', ''));
  end
  models = union(models, models_plus);
  models = setdiff(models, models_minus);
  config.model = unique(models);

  if ismember('none', models)
    config.model = {};
  end
  % }}}

  % load / make bootstrap indices {{{
  if isfield(save_for_later, 'bootstrap_file')
    if exist(save_for_later.bootstrap_file, 'file')
      data = load(save_for_later.bootstrap_file, 'BI');
    else
      N = 10000;
      m = numel(config.bm);
      data.BI = zeros(N, m);
      for i = 1 : N
        data.BI(i, :) = randsample(m, m, true); % bootstrap
      end
      pfp_savevar(save_for_later.bootstrap_file, data.BI, 'BI');
    end
    config.bi = data.BI;
    clear data;
  end
  % }}}

  % create result sub-dir {{{
  sub_dir = sprintf('%s_%s_type%s_mode%s/', config.ont, config.cat, config.tp, config.md);
  config.eval_dir = fullfile(config.eval_dir, sub_dir);
  if ~exist(config.eval_dir, 'dir')
    mkdir(config.eval_dir);
  end
  % }}}
return

% -------------
% Yuxiang Jiang (yuxjiang@indiana.edu)
% Department of Computer Science
% Indiana University, Bloomington
% Last modified: Mon 07 Mar 2016 12:05:00 AM E
