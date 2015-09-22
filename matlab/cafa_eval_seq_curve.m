function [ev] = cafa_eval_seq_curve(id, bm, preeval, md)
%CAFA_EVAL_SEQ_CURVE CAFA evaluation sequence-centric curve
% {{{
%
% [ev] = CAFA_EVAL_SEQ_CURVE(id, bm, preeval, md);
%
%   Returns the (macro) averaged curve over a given benchmark.
%
% Note
% ----
% This function is used to average pre-computed curves for each sequence. The
% curves could be one of the following kinds:
% 1. precision-recall
% 2. weighted precision-recall (by information content)
% 3. RU-MI
% 4. normalized RU-MI
%
% This function does MACRO-average and depends on a structure 'preeval' having
% pre-computed curves for each sequence to be averaged.
%
% input
% -----
% [char]
% id:       a string for model id.
%
% [char or cell]
% bm:       a benchmark filename or a list of benchmark target ids.
%
% [struct]
% preeval:  the pre-computed curve per sequence.
%           [cell of char]
%           .centric  - should always be 'sequence' (not used)
%
%           .object   - n-by-1 sequence id
%
%           [cell of n-by-2 double]
%           .metric   - 1-by-k, consists of k sets of points, where 'k' is the 
%                       number of distinct thresholds. In most cases, k = 101,
%                       corresponding to 101 thresholds:
%
%                       tau = 0.00 : 0.01 : 1.00
%
%                       Each cell contains a n-by-2 double array, corresponding
%                       to n points at that threshold.
%
%           [double]
%           .tau      - A 1-by-k array of thresholds. (not used)
%           
%           [logical]
%           .covered  - n-by-1 indicator of if sequence i is predicted by the
%                       model.
%
%           See pfp_convcmstruct.m
%
% [char]
% md:       The mode of evaluation.
%           '1', 'full'     - averaged over the entire benchmark sets.
%                             missing prediction are treated as 0.
%           '2', 'partial'  - averaged over the predicted subset (partial).
%
% Output
% ------
% [struct]
% ev: The returning structure for each model:
%
%     [char]
%     .id         The model name, used for naming files.
%
%     [double]
%     .curve      k-by-2, points on that curve.
%
%     [double]
%     .tau        1-by-k, the corresp. thresholds.
%
%     [double]
%     .ncovered   scalar, number of covered proteins in 'bm'.
%
%     [double]
%     .coverage   scalar, coverage of the model.
%
%     [char]
%     .mode       evaluation mode. 'full' or 'partial'
%
% Dependency
% ----------
%[>]pfp_loaditem.m
%[>]pfp_convcmstruct.m
% }}}

  % check inputs {{{
  if nargin ~= 4
    error('cafa_eval_seq_curve:InputCount', 'Expected 4 inputs.');
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

  % check the 3rd input 'preeval' {{{
  validateattributes(preeval, {'struct'}, {'nonempty'}, '', 'preeval', 3);
  % }}}

  % check the 4th input 'md' {{{
  md = validatestring(md, {'1', 'full', '2', 'partial'}, '', 'md', 4);
  % }}}
  % }}}

  % preparation {{{
  k = numel(preeval.tau);

  ev.id    = id;
  ev.curve = zeros(k, 2);
  ev.tau   = reshape(preeval.tau, 1, []);
  
  [~, ev_index] = ismember(bm, preeval.object);
  ev.ncovered = sum(preeval.covered(ev_index));
  ev.coverage = ev.ncovered / numel(bm);

  if ismember(md, {'1', 'full'})
    % nop
    ev.mode = 'full';
  elseif ismember(md, {'2', 'partial'})
    pred_index = find(preeval.covered); % predicted sequences
    % only evaluates on the predicted sequences in the benchmark (partial)
    ev_index = intersect(ev_index, pred_index);
    ev.mode = 'partial';
  else
    error('cafa_eval_seq_curve:ModeErr', 'Unknown evaluation mode.');
  end
  % }}}

  % averaging {{{

  % Note
  % ----
  % For (weighted) precision-recall, (weighted) precision could be NaN which
  % means the model under evaluation didn't make predictions on that sequence,
  % thus, treated as 0.0, and "(weighted) precision" in this case is undefined.
  %
  % But for (weighted) recall as well as (normalized) RU, (normalized) MI, they
  % shall never have NaN values.
  % 
  % In short, we will always use 'nanmean' to avoid this issue.
  for i = 1 : k
    ev.curve(i, :) = nanmean(preeval.metric{i}(ev_index, :), 1);
  end
  % }}}
return

% -------------
% Yuxiang Jiang (yuxjiang@indiana.edu)
% Department of Computer Science
% Indiana University Bloomington
% Last modified: Tue 15 Sep 2015 02:57:54 PM E
