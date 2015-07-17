function [result] = cafa_duel_seq_fmax(group1, group2)
%CAFA_DUEL_SEQ_FMAX CAFA duel sequence-centric Fmax
% {{{
%
% [result] = CAFA_DUEL_SEQ_FMAX(group1, group2);
%
%   Returns the duel result of two groups of models (Fmax).
%
% Note
% ----
% 1. CAFA duel is used for comparing CAFA1 and CAFA2 methods, only Fmax is used
%    for duel, as it is the only main metric in CAFA1.
%
% 2. These two groups of evaluation results should be computed using the same
%    bootstrap indices, and of course, on the same benchmark.
%
% Input
% -----
% [cell]
% group1:   A 1-by-n cell of 'seq_fmax_bst' result structures.
%
%           [char]
%           .id           internal ID, used for naming files.
%
%           [double]
%           .fmax_bst     B-by-1, bootstrapped F1-max.
%
%           [double]
%           .point_bst    B-by-2, the corresponding (precision, recall) point
%                         for each bootstrap.
%
%           [double]
%           .tau_bst      B-by-1, the corresponding threshold for each
%                         bootstrap.
%
%           [double]
%           .coverage_bst B-by-1, coverage of the model for each bootstrap.
%
%           See cafa_eval_seq_fmax_bst.m for details.
%
% [cell]
% group2:   A 1-by-m cell of 'seq_fmax_bst' result structures.
%
% Output
% ------
% [struct]
% result:   The duel result:
%
%           [cell]
%           .group1   1-by-n tags (will not be show in the plot for now)
%
%           [cell]
%           .group2   1-by-m tags (will not be show in the plot for now)
%
%           [double]
%           .winner   n-by-m (usually n = m = 5), indicates which model wins.
%                     possible value: 1 or 2
%                     winner(i, j) shows the results of group1(i) v.s. group2(j)
%
%           [double]
%           .margin   n-by-m, winning margin.
%
%           [double]
%           .nwins    n-by-m, how many time the winner wins.
%
% Dependency
% ----------
%[>]cafa_eval_seq_fmax_bst.m
% }}}

  % check inputs {{{
  if nargin ~= 2
    error('cafa_duel_seq_fmax:InputCount', 'Expected 2 inputs.');
  end

  % check the 1st input 'group1' {{{
  validateattributes(group1, {'cell'}, {'nonempty'}, '', 'group1', 1);
  n = numel(group1);
  % }}}

  % check the 2nd input 'group2' {{{
  validateattributes(group2, {'cell'}, {'nonempty'}, '', 'group2', 2);
  m = numel(group2);
  % }}}
  % }}}

  % duel {{{
  result.group1 = cell(1, n);
  result.group2 = cell(1, m);
  result.winner = zeros(n, m);
  result.margin = zeros(n, m);
  result.nwins  = zeros(n, m);

  for i = 1 : n
    result.group1{i} = group1{i}.id;
  end

  for i = 1 : m
    result.group2{i} = group2{i}.id;
  end

  N = numel(group1{1}.fmax_bst);
  for i = 1 : n
    for j = 1 : m
      b1 = mean(group1{i}.fmax_bst);
      b2 = mean(group2{j}.fmax_bst);
      if b1 >= b2
        result.winner(i, j) = 1;
        result.nwins(i, j) = sum(group1{i}.fmax_bst > group2{j}.fmax_bst);
      else
        result.winner(i, j) = 2;
        result.nwins(i, j) = sum(group1{i}.fmax_bst < group2{j}.fmax_bst);
      end
      result.margin(i, j) = abs(b1 - b2);
    end
  end
  % }}}
return

% -------------
% Yuxiang Jiang (yuxjiang@indiana.edu)
% Department of Computer Science
% Indiana University Bloomington
% Last modified: Fri 17 Jul 2015 10:49:41 AM E
