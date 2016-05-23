function [ev] = cafa_eval_seq_smin_bst(id, bm, rm, ev_mode, BI)
%CAFA_EVAL_SEQ_SMIN_BST CAFA evaluation sequence-centric smin_bst
%
% [ev] = CAFA_EVAL_SEQ_SMIN_BST(id, bm, rm, ev_mode, BI);
%
%   Calculates the minimum semantic distance averaged over bootstrapped
%   benchmarks.
%
% Input
% -----
% [char]
% id:       A string for model ID.
%
% [char or cell]
% bm:       A benchmark filename or a list of benchmark target IDs.
%           (it contains m sequences).
%
% [struct]
% rm:       The pre-computed RU-MI per sequence.
%           .object   [cell]    n-by-1 sequence ID
%           .metric   [cell]    1-by-k RU-MI pair sets, where 'k' is the number
%                               of distinct thresholds. In most cases, k = 101,
%                               corresponding to 101 thresholds: tau =
%                               0.00:0.01:1.00 Each cell contains a n-by-2
%                               double array, which is the (RU, MI) pair of n
%                               sequences at a specific threshold.
%           .covered  [logical] n-by-1 indicator of if sequence i is predicted
%                               by this model.
%           See pfp_convcmstruct.m
%
% [char]
% ev_mode:  The mode of evaluation.
%           '1', 'full'     - averaged over the entire benchmark sets.
%                             missing prediction are treated as 0.
%           '2', 'partial'  - averaged over the predicted subset (partial).
%
% [double]
% BI:       B-by-m bootstrapped index, where B is the number of bootstrap
%           samples and m is the number of benchmark sequences.
%
%           Note that we need to draw samples ahead of time since we would
%           like to have all the method assessed over the same sample.
%
% Output
% ------
% [struct]
% ev: The RU-MI curve structure for each model:
%     .id           [char]    The model name, used for naming files.
%     .smin_bst     [double]  B-by-1, bootstrapped S-min
%     .point_bst    [double]  B-by-2, the corresponding (RU, MI) point for each
%                             bootstrap.
%     .tau_bst      [double]  B-by-1, the corresponding threshold for each bootstrap.
%     .ncovered_bst [double]  B-by-1, number of covered proteins in 'bm'.
%     .coverage_bst [double]  B-by-1, coverage of the model for each bootstrap.
%
%     Note that 'coverge' always refers to the one in 'full' evaluation mode.
%     ('partial' mode has a trivial 100% coverage)
%
% Dependency
% ----------
%[>]pfp_loaditem.m
%[>]pfp_sminc.m
%
% See Also
% --------
%[>]pfp_convcmstruct.m

  % check inputs {{{
  if nargin ~= 5
    error('cafa_eval_seq_smin_bst:InputCount', 'Expected 5 inputs.');
  end

  % id
  validateattributes(id, {'char'}, {'nonempty'}, '', 'id', 1);

  % bm
  validateattributes(bm, {'char', 'cell'}, {'nonempty'}, '', 'bm', 2);
  if ischar(bm) % load the benchmark if a file name is given
    bm = pfp_loaditem(bm, 'char');
  end
  m = numel(bm);

  % rm
  validateattributes(rm, {'struct'}, {'nonempty'}, '', 'rm', 3);

  % ev_mode
  ev_mode = validatestring(ev_mode, {'1', 'full', '2', 'partial'}, '', 'ev_mode', 4);

  % BI
  validateattributes(BI, {'double'}, {'>', 0, 'ncols', m}, '', 'BI', 5);
  % }}}

  % evaluation {{{
  B = size(BI, 1);
  k = numel(rm.tau);

  % place-holder for resulting structure 'ev'
  ev.id           = id;
  ev.smin_bst     = zeros(B, 1);
  ev.point_bst    = zeros(B, 2);
  ev.tau_bst      = zeros(B, 1);
  ev.ncovered_bst = zeros(B, 1);
  ev.coverage_bst = zeros(B, 1);

  [~, ev_index] = ismember(bm, rm.object);

  for b = 1 : B
    % draw a bootstrap sample
    bootidx = BI(b, :);

    % compute coverage over this sample
    ev_index_bst = ev_index(bootidx);
    ev.ncovered_bst(b) = sum(rm.covered(ev_index_bst));
    ev.coverage_bst(b) = ev.ncovered_bst(b) / m;

    if ismember(ev_mode, {'2', 'partial'})
      ev_index_bst(~rm.covered(ev_index_bst)) = [];
    end

    % compute the average rmcurve
    rmcurve = zeros(k, 2);
    for i = 1 : k
      rmcurve(i, :) = nanmean(rm.metric{i}(ev_index_bst, :), 1);
    end

    [ev.smin_bst(b), ev.point_bst(b, :), ev.tau_bst(b)] = pfp_sminc(rmcurve, rm.tau);
  end
  % }}}
return

% -------------
% Yuxiang Jiang (yuxjiang@indiana.edu)
% Department of Computer Science
% Indiana University Bloomington
% Last modified: Mon 23 May 2016 06:31:48 PM E
