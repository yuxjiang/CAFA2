function [mids] = cafa_pick_models(k, bm, rho)
%CAFA_PICK_MODELS CAFA pick models
% {{{
%
% [mids] = CAFA_PICK_MODELS(k, bm, rho);
%
%   Picks k "best" predictors from the pool of submitted predictions.
%
% Note
% ----
% 1. The selected models should be:
%    (a) Of high quality in terms of F-measure in general (i.e. does well on the
%        specific benchmark, 'all' if not specified)
%
%    (b) Non-redundant. ("dissimilar" to each other)
%
% 2. This function assumes the CAFA assessment directory is
%    CAFA_DIR = ~/cafa
%
% Input
% -----
% [double]
% k:    The number of models to pick.
%       k = Inf indicates to pick all available models.
%
% [char]
% bm:   The benchmark, which is encoded as: <ontology>_<category>_<type>_<mode>
%
%       For example: mfo_HUMAN_type1_mode1
%
%       Also, the specified benchmark should have been evaluated, i.e. there must
%       be an existing subfolder (having the same name) under [CAFA_DIR]/evaluation/
%
% rho:  The correlation lower bound used to enforce non-redundancy.
%
% Output
% ------
% [cell]
% mids: The cell of model IDs.
%
% Dependency
% ----------
%[>]cafa_collect.m
%[>]cafa_sel_top_seq_fmax.m
% }}}

  % CAFA environment setting {{{
  CAFA_DIR = '~/cafa';
  % }}}

  % check inputs {{{
  if nargin ~= 3
    error('cafa_pick_models:InputCount', 'Expected 3 inputs');
  end

  % check the 1st input 'k' {{{
  validateattributes(k, {'double'}, {'nonnegative'}, '', 'k', 1);
  % }}}

  % check the 2nd input 'bm' {{{
  validateattributes(bm, {'char'}, {'nonempty'}, '', 'bm', 2);
  eval_dir = fullfile(CAFA_DIR, 'evaluation', bm);

  if ~exist(eval_dir, 'dir')
    error('cafa_pick_models:InputErr', 'Benchmark has not been evaluated');
  end
  tokens = strsplit(bm, '_');
  % }}}

  % check the 3rd input 'rho' {{{
  validateattributes(rho, {'double'}, {'nonnegative'}, '', 'rho', 3);
  % }}}
  % }}}

  % sort models {{{
  fmaxs  = cafa_collect(eval_dir, 'seq_fmax_bst');
  config = fullfile(CAFA_DIR, 'config', 'config.tab');
  [tops, ~, info] = cafa_sel_top_seq_fmax(Inf, fmaxs, 'BN4S', 'BB4S', config, false);
  % }}}

  % selection {{{
  if ~isinf(k) && (numel(tops) < k)
    mids = info.top_mid;
    warning('cafa_pick_models:LessThanK', 'Not enough models at this k');
    return;
  end

  mid_index = [];
  nsel = 0;

  % load the pre-computed Pearson's correlation coefficient matrix
  % xxo.team: model ID
  % xxo.sim:  correlation
  % where xxo could be mfo, bpo, cco, or hpo
  data  = load(fullfile(CAFA_DIR, 'analysis', 'methods', 'similarity.mat'), tokens{1});
  pcorr = data.(tokens{1}).sim;
  [found, index] = ismember(info.top_mid, data.(tokens{1}).team);
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
% Last modified: Mon 01 Feb 2016 04:11:15 PM E
