function [ev] = cafa_eval_seq_smin(id, bm, rm, md)
%CAFA_EVAL_SEQ_SMIN CAFA evaluation sequence-centric Smin
% {{{
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
%     [cell of char]
%     .object     - n-by-1 sequence ID
%
%     [cell of double]
%     .metric     - 1-by-k (RU, MI) pair sets, where 'k'
%                   is the number of distinct thresholds. In most
%                   cases, k = 101, corresponding to 101 thresholds:
%                   tau = 0.00 : 0.01 : 1.00
%                   Each cell contains a n-by-2 double array, which
%                   is the (RU, MI) pair of n sequences
%                   at a specific threshold.
%
%     [logical]
%     .covered    - n-by-1 indicator of if sequence i is predicted
%                   by this model.
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
%
%     [char]
%     .id         The model name, used for naming files.
%
%     [double]
%     .smin       scalar, S2-min.
%
%     [double]
%     .point      1-by-2, the corresponding (RU, MI) point.
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
% Dependency
% ----------
%[>]pfp_loaditem.m
%[>]pfp_sminc.m
%[>]pfp_seqcm.m
%[>]cafa_eval_seq_curve.m
% }}}

  % check inputs {{{
  if nargin ~= 4
    error('cafa_eval_seq_smin:InputCount', 'Expected 4 inputs.');
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

  % check the 3rd input 'rm' {{{
  validateattributes(rm, {'struct'}, {'nonempty'}, '', 'rm', 3);
  % }}}

  % check the 4th input 'md' {{{
  md = validatestring(md, {'1', 'full', '2', 'partial'}, ...
      '', 'md', 4);
  % }}}
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
% Last modified: Tue 15 Sep 2015 01:31:55 PM E
