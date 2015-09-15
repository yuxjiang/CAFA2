function [ev] = cafa_eval_seq_fmax(id, bm, pr, md, beta)
%CAFA_EVAL_SEQ_FMAX CAFA evaluation sequence-centric Fmax
% {{{ 
%
% [ev] = CAFA_EVAL_SEQ_FMAX(id, bm, pr, md, beta);
%
%   Computes the maximum F-measure of a curve averaged over a given benchmark.
%
% Note
% ----
% Could also be used to compute weighted F-max, depends on the given 'pr'.
%
% Input
% -----
% [char]
% id:   A string for model ID.
%
% [char or cell]
% bm:   A benchmark filename or a list of benchmark target IDs.
%
% [struct]
% pr:   The pre-computed precision-recall per sequence.
%       [cell of char]
%       .object     - n-by-1 sequence ID
%
%       [cell of double]
%       .metric     - 1-by-k precision-recall pair sets, where 'k'
%                     is the number of distinct thresholds. In most 
%                     cases, k = 101, corresponding to 101 thresholds:
%                     tau = 0.00 : 0.01 : 1.00
%                     Each cell contains a n-by-2 double array, which
%                     is the (precision, recall) pair of n sequences
%                     at a specific threshold.
%
%       [logical]
%       .covered    - n-by-1 indicator of if sequence i is predicted
%                     by this model.
%
% [char]
% md:   The mode of evaluation.
%       '1', 'full'     - averaged over the entire benchmark sets.
%                         missing prediction are treated as 0.
%       '2', 'partial'  - averaged over the predicted subset (partial).
%
% (optional)
% [double]
% beta: The beta in F_{beta}-score.
%       default: 1.
%
% Output
% ------
% [struct]
% ev: The Fmax structure for each model:
%
%     [char]
%     .id         The model name, used for naming files.
%
%     [double]
%     .fmax       scalar, Fmax.
%
%     [double]
%     .point      1-by-2, the corresponding (precision, recall) point.
%
%     [double]
%     .tau        scalar, the corresponding threshold.
%
%     [double]
%     .ncovered   scalar, number of covered proteins in 'bm'.
%
%     [double]
%     .coverage   scalar, coverage of the model.
%
%                 Note that 'coverge' always refers to the one in 'full' 
%                 evaluation mode. ('partial' mode has a trivial 100% 
%                 coverage)
%
%     [char]
%     .mode       evaluation mode. 'full' or 'partial'
%
%     [double]
%     .beta       the beta for F_{beta}-max
%
% Dependency
% ----------
%[>]pfp_loaditem.m
%[>]pfp_fmaxc.m
%[>]pfp_seqcm.m
%[>]cafa_eval_seq_curve.m
% }}}

  % check inputs {{{
  if nargin < 4 || nargin > 5
    error('cafa_eval_seq_fmax:InputCount', 'Expected 4 or 5 inputs.');
  end

  if nargin == 4
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
  % }}}

  % check the 3rd input 'pr' {{{
  validateattributes(pr, {'struct'}, {'nonempty'}, '', 'pr', 3);
  % }}}

  % check the 4th input 'md' {{{
  md = validatestring(md, {'1', 'full', '2', 'partial'}, '', 'md', 4);
  % }}}

  % check the 5th input 'beta' {{{
  validateattributes(beta, {'double'}, {'positive'}, '', 'beta', 5);
  % }}}
  % }}}

  % compute {{{
  ev_prcurve = cafa_eval_seq_curve(id, bm, pr, md);

  ev.id                       = ev_prcurve.id;
  [ev.fmax, ev.point, ev.tau] = pfp_fmaxc(ev_prcurve.curve, ev_prcurve.tau, beta);
  ev.ncovered                 = ev_prcurve.ncovered;
  ev.coverage                 = ev_prcurve.coverage;
  ev.mode                     = ev_prcurve.mode;
  ev.beta                     = beta;
  % }}}
return

% -------------
% Yuxiang Jiang (yuxjiang@indiana.edu)
% Department of Computer Science
% Indiana University Bloomington
% Last modified: Tue 15 Sep 2015 01:31:22 PM E
