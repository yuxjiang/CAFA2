function [ev] = cafa_eval_seq_fmax_bst(id, bm, pr, ev_mode, BI, beta)
%CAFA_EVAL_SEQ_FMAX_BST CAFA evaluation sequence-centric Fmax
% {{{
%
% [ev] = CAFA_EVAL_SEQ_FMAX_BST(id, bm, pr, ev_mode, BI, beta);
%
%   Calculates the maximum F-measure averaged over bootstrapped benchmarks.
%
% Input
% -----
% (required)
% [char]
% id:       A string for model ID.
%
% [char or cell]
% bm:       A benchmark filename or a list of benchmark target IDs.
%           (it contains m sequences).
%
% [struct]
% pr:       The pre-computed precision-recall per sequence.
%           [cell of char]
%           .object   n-by-1 sequence ID.
%
%           [cell of double]
%           .metric   1-by-k precision-recall pair sets, where 'k' is the number
%                     of distinct thresholds. In most cases, k = 101,
%                     corresponding to 101 thresholds: tau = 0.00 : 0.01 : 1.00.
%                     Each cell contains a n-by-2 double array, which is the
%                     (precision, recall) pair of n sequences at a specific
%                     threshold.
%
%           [logical]
%           .covered  n-by-1 indicator of if sequence i is predicted by this
%                     model.
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
% (optional)
% [double]
% beta:     The beta in F_{beta}-max.
%           default: 1.
%
% Output
% ------
% [struct]
% ev: The precision-recall curve structure for each model:
%
%     [char]
%     .id             The model name, used for naming files.
%
%     [double]
%     .fmax_bst       B-by-1, bootstrapped F1-max.
%
%     [double]
%     .point_bst      B-by-2, the corresponding (precision, recall) point for
%                     each bootstrap.
%
%     [double]
%     .tau_bst        B-by-1, the corresponding threshold for each bootstrap.
%
%     [double]
%     .ncovered_bst   B-by-1, number of covered proteins in 'bm'.
%
%     [double]
%     .coverage_bst   B-by-1, coverage of the model for each bootstrap.
%
%                     Note that 'coverge' always refers to the one in 'full' 
%                     evaluation mode. ('partial' mode has a trivial 100% 
%                     coverage)
%
% Dependency
% ----------
%[>]pfp_loaditem.m
%[>]pfp_fmaxc.m
%[>]pfp_seqcm.m
% }}}

  % check inputs {{{
  if nargin < 5 || nargin > 6
    error('cafa_eval_seq_fmax_bst:InputCount', 'Expected 5 or 6 inputs.');
  end

  if nargin == 5
    beta = 1;
  end

  % check the 1st input 'id' {{{
  validateattributes(id, {'char'}, {'nonempty'}, '', 'id', 1);
  % }}}

  % check the 2nd input 'bm' {{{
  validateattributes(bm, {'char', 'cell'}, {'nonempty'}, '', 'bm', 2);
  if ischar(bm) % load the benchmark if a file name is given
    bm = pfp_loaditem(bm, 'char');
  end
  m = numel(bm);
  % }}}

  % check the 3rd input 'pr' {{{
  validateattributes(pr, {'struct'}, {'nonempty'}, '', 'pr', 3);
  % }}}

  % check the 4th input 'ev_mode' {{{
  ev_mode = validatestring(ev_mode, {'1', 'full', '2', 'partial'}, '', 'ev_mode', 4);
  % }}}

  % check the 5th input 'BI' {{{
  validateattributes(BI, {'double'}, {'>', 0, 'ncols', m}, '', 'BI', 5);
  % }}}

  % check the 6th input 'beta' {{{
  validateattributes(beta, {'double'}, {'positive'}, '', 'beta', 6);
  % }}}
  % }}}

  % evaluation {{{
  B = size(BI, 1);
  k = numel(pr.tau);

  % place-holder for resulting structure 'ev'
  ev.id           = id;
  ev.fmax_bst     = zeros(B, 1);
  ev.point_bst    = zeros(B, 2);
  ev.tau_bst      = zeros(B, 1);
  ev.ncovered_bst = zeros(B, 1);
  ev.coverage_bst = zeros(B, 1);
  
  [~, ev_index] = ismember(bm, pr.object);

  for b = 1 : B
    % draw a bootstrap sample
    bootidx = BI(b, :);

    % compute coverage over this sample
    ev_index_bst = ev_index(bootidx);
    ev.ncovered_bst(b) = sum(pr.covered(ev_index_bst));
    ev.coverage_bst(b) = ev.ncovered_bst(b) / m;

    if ismember(ev_mode, {'2', 'partial'})
      ev_index_bst(~pr.covered(ev_index_bst)) = [];
    end

    % compute the average prcurve
    prcurve = zeros(k, 2);
    for i = 1 : k
      prcurve(i, :) = nanmean(pr.metric{i}(ev_index_bst, :), 1);
    end

    [ev.fmax_bst(b), ev.point_bst(b, :), ev.tau_bst(b)] = pfp_fmaxc(prcurve, pr.tau, beta);
  end
  % }}}
return

% -------------
% Yuxiang Jiang (yuxjiang@indiana.edu)
% Department of Computer Science
% Indiana University Bloomington
% Last modified: Tue 15 Sep 2015 01:31:11 PM E
