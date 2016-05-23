function [mids] = cafa_pick_models(k, cfg, rho)
%CAFA_PICK_MODELS CAFA pick models
%
% [mids] = CAFA_PICK_MODELS(k, bm, rho;
%
%   Picks k "best" predictors from the pool of submitted predictions.
%
% Note
% ----
% 1. The selected models should be:
%    (a) Of high quality in terms of F-measure in general (i.e. does well on the
%        specific benchmark, 'all' if not specified)
%    (b) Non-redundant. ("dissimilar" to each other)
%
% Input
% -----
% [double]
% k:    The number of models to pick.
%       k = Inf indicates to pick all available models.
%
% [char or struct]
% cfg:  The configuration file (job descriptor) or a parsed config structure.
%       See cafa_parse_config.m
%
% [double]
% rho:  The correlation lower bound used to enforce non-redundancy.
%
% Output
% ------
% [cell]
% mids: The cell of model IDs.
%
% Dependency
% ----------
%[>]cafa_parse_config.m
%[>]cafa_collect.m
%[>]cafa_sel_top_seq_fmax.m

  % CAFA environment setting {{{
  CAFA_DIR = '~/cafa';
  % }}}

  % check inputs {{{
  if nargin ~= 3
    error('cafa_pick_models:InputCount', 'Expected 3 inputs');
  end

  % k
  validateattributes(k, {'double'}, {'nonnegative'}, '', 'k', 1);

  % cfg
  config = cafa_parse_config(cfg);

  % rho
  validateattributes(rho, {'double'}, {'nonnegative'}, '', 'rho', 3);
  % }}}

  % sort models {{{
  fmaxs = cafa_collect(config.eval_dir, 'seq_fmax_bst');
  reg = fullfile(CAFA_DIR, 'register', 'register.tab');
  [tops, ~, info] = cafa_sel_top_seq_fmax(Inf, fmaxs, 'BN4S', 'BB4S', reg, false);
  % }}}

  % selection {{{
  if ~isinf(k) && (numel(tops) < k)
    mids = info.top_mid;
    warning('cafa_pick_models:LessThanK', 'Not enough models at this k');
    return;
  end

  mid_index = [];
  nsel = 0;

  % load the pre-computed Pearson's correlation coefficient structure: 'ps'
  % ps.xxo has two fields:
  % xxo.mid [cell]    model ID
  % xxo.pcc [double]  correlation
  % where xxo could be mfo, bpo, cco, or hpo
  load(fullfile(CAFA_DIR, 'analysis', 'methods', 'pcc_struct.mat'), 'ps');
  pcorr = ps.(config.ont).pcc;
  [found, index] = ismember(info.top_mid, ps.(config.ont).mid);
  if ~all(found)
    error('cafa_pick_models:ModelNotFound', 'Some model(s) are not found.');
  end
  for i = 1 : numel(info.top_mid)
    okay = true;
    for j = 1 : numel(mid_index)
      if abs(pcorr(index(i), index(mid_index(j)))) > rho
        okay = false;
        break;
      end
    end
    if okay
      % pick this model
      mid_index = [mid_index, i];
      nsel = nsel + 1;
    end
    if nsel >= k
      break;
    end
  end
  mids = info.top_mid(mid_index);
  if ~isinf(k) && (numel(mid_index) < k)
    warning('cafa_pick_models:LessThanK', 'Not enough models at this cutoff.');
  end
  % }}}
return

% -------------
% Yuxiang Jiang (yuxjiang@indiana.edu)
% Department of Computer Science
% Indiana University, Bloomington
% Last modified: Mon 23 May 2016 05:39:07 PM E
