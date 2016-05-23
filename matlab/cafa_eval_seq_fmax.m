function [ev] = cafa_eval_seq_fmax(id, bm, pr, md, beta)
%CAFA_EVAL_SEQ_FMAX CAFA evaluation sequence-centric Fmax
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
%       .centric  [char]    'sequence'
%       .object   [cell]    An n-by-1 array of (char) object ID.
%       .metric   [cell]    A 1-by-k cell of pr-rc metrics.
%       .tau      [double]  A 1-by-k array of thresholds.
%       .covered  [logical] A n-by-1 logical array indicating if the correspond.
%                           object is predicted ("covered") by the model.
%       See pfp_convcmstruct.m.
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
%       default: 1
%
% Output
% ------
% [struct]
% ev: The Fmax structure for each model:
%     .id         [char]    The model name, used for naming files.
%     .fmax       [double]  scalar, Fmax.
%     .point      [double]  1-by-2, the corresponding (precision, recall) point.
%     .tau        [double]  scalar, the corresponding threshold.
%     .ncovered   [double]  scalar, number of covered proteins in 'bm'.
%     .coverage   [double]  scalar, coverage of the model.
%                           Note that 'coverge' always refers to the one in
%                           'full' evaluation mode. ('partial' mode has a
%                           trivial 100% coverage)
%     .mode       [char]    evaluation mode. 'full' or 'partial'
%     .beta       [double]  the beta for F_{beta}-max.
%
% Dependency
% ----------
%[>]pfp_loaditem.m
%[>]pfp_fmaxc.m
%[>]cafa_eval_seq_curve.m
%
% See Also
% --------
%[>]pfp_convcmstruct.m

  % check inputs {{{
  if nargin ~=4 && nargin ~= 5
    error('cafa_eval_seq_fmax:InputCount', 'Expected 4 or 5 inputs.');
  end

  if nargin == 4
    beta = 1;
  end

  % id
  validateattributes(id, {'char'}, {'nonempty'}, '', 'id', 1);

  % bm
  validateattributes(bm, {'char', 'cell'}, {'nonempty'}, '', 'bm', 2);
  if ischar(bm) % load the benchmark if a file name is given
    bm = pfp_loaditem(bm, 'char');
  end

  % pr
  validateattributes(pr, {'struct'}, {'nonempty'}, '', 'pr', 3);

  % md
  md = validatestring(md, {'1', 'full', '2', 'partial'}, '', 'md', 4);

  % beta
  validateattributes(beta, {'double'}, {'positive'}, '', 'beta', 5);
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
% Last modified: Mon 23 May 2016 06:24:43 PM E
