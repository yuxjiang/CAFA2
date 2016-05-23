function [ev] = cafa_eval_seq_smin(id, bm, rm, md)
%CAFA_EVAL_SEQ_SMIN CAFA evaluation sequence-centric Smin
%
% [ev] = CAFA_EVAL_SEQ_SMIN(id, bm, rm, md);
%
%   Computes the minimum semantic distance of a curve averaged over a given
%   benchmark.
%
% Note
% ----
% Could also be used to compute normalized S-min, depends on the given 'rm'.
%
% Input
% -----
% [char]
% id: A string for model ID.
%
% [char or cell]
% bm: A benchmark filename or a list of benchmark target IDs.
%
% [struct]
% rm: The pre-computed RU-MI per sequence.
%     .centric  [char]    'sequence'
%     .object   [cell]    An n-by-1 array of (char) object ID.
%     .metric   [cell]    A 1-by-k cell of RU-MI metrics.
%     .tau      [double]  A 1-by-k array of thresholds.
%     .covered  [logical] A n-by-1 logical array indicating if the correspond.
%                         object is predicted ("covered") by the model.
%     See pfp_convcmstruct.m.
%
% [char]
% md: The mode of evaluation.
%     '1', 'full'     - averaged over the entire benchmark sets.
%                       missing prediction are treated as 0.
%     '2', 'partial'  - averaged over the predicted subset (partial).
%
% Output
% ------
% [struct]
% ev: The S-min structure for each model:
%     .id       [char]    The model name, used for naming files.
%     .smin     [double]  scalar, S2-min.
%     .point    [double]  1-by-2, the corresponding (RU, MI) point.
%     .tau      [double]  scalar, the corresponding threshold.
%     .ncovered [double]  scalar, number of covered proteins in 'bm'.
%     .coverage [double]  scalar, coverage of the model.
%                         Note that 'coverge' always refers to the one in 'full'
%                         evaluation mode. ('partial' mode has a trivial 100%
%                         coverage)
%     .mode     [char]    evaluation mode. 'full' or 'partial'.
%
% Dependency
% ----------
%[>]pfp_loaditem.m
%[>]pfp_sminc.m
%[>]cafa_eval_seq_curve.m
%
% See Also
% --------
%[>]pfp_convcmstruct.m

  % check inputs {{{
  if nargin ~= 4
    error('cafa_eval_seq_smin:InputCount', 'Expected 4 inputs.');
  end

  % id
  validateattributes(id, {'char'}, {'nonempty'}, '', 'id', 1);

  % bm
  validateattributes(bm, {'char', 'cell'}, {'nonempty'}, '', 'bm', 2);
  if ischar(bm) % load the benchmark if a file name is given
    bm = pfp_loaditem(bm, 'char');
  end

  % rm
  validateattributes(rm, {'struct'}, {'nonempty'}, '', 'rm', 3);

  % md
  md = validatestring(md, {'1', 'full', '2', 'partial'}, '', 'md', 4);
  % }}}

  % evaluation {{{
  ev_rmcurve = cafa_eval_seq_curve(id, bm, rm, md);
  ev.id                       = ev_rmcurve.id;
  [ev.smin, ev.point, ev.tau] = pfp_sminc(ev_rmcurve.curve, ev_rmcurve.tau);
  ev.ncovered                 = ev_rmcurve.ncovered;
  ev.coverage                 = ev_rmcurve.coverage;
  ev.mode                     = ev_rmcurve.mode;
  % }}}
return

% -------------
% Yuxiang Jiang (yuxjiang@indiana.edu)
% Department of Computer Science
% Indiana University Bloomington
% Last modified: Mon 23 May 2016 06:20:56 PM E
