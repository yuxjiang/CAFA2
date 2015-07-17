function [aucs] = cafa_sel_top5_term_auc(aucs, mids)
%CAFA_SEL_TOP5_TERM_AUC CAFA select top 5 term AUC
% {{{
%
% [aucs] = CAFA_SEL_TOP5_TERM_AUC(aucs, mids);
%
%   Picks top 5 Fmax methods.
%
% Input
% -----
% [cell]
% aucs:     The collected 'term_auc' structures
%           Each cell has the following fields.
%
%           [char]
%           .id     (Internel) model of the model
%
%           [cell]
%           .term   1-by-m, term ID list
%
%           [double]
%           .auc    1-by-m, AUC per term
%
%           See cafa_collect.m
%
% [cell]
% mids:     1-by-5 method ID, (internal ID)
%
% Output
% ------
% [cell]
% aucs:     The filtered cell 'aucs'.
%
% Dependency
% ----------
%[>]cafa_collect.m
% }}}

  % check inputs {{{
  if nargin ~= 2
    error('cafa_sel_top5_term_auc:InputCount', 'Expected 2 input.');
  end

  % check the 1st input 'aucs' {{{
  validateattributes(aucs, {'cell'}, {'nonempty'}, '', 'aucs', 1);
  n = numel(aucs);
  % }}}

  % check the 2nd input 'mids' {{{
  validateattributes(mids, {'cell'}, {'numel', 5}, '', 'mids', 2);
  % }}}
  % }}}

  %filtering {{{
  ids = cell(1, n);
  for i = 1 : n
    ids{i} = aucs{i}.id;
  end
  [found, index] = ismember(mids, ids);
  if ~all(found)
    error('cafa_sel_top5_term_auc:NotFound', 'Some methods are not found.');
  end
  aucs = aucs(index);
  %}}}
return

% -------------
% Yuxiang Jiang (yuxjiang@indiana.edu)
% Department of Computer Science
% Indiana University, Bloomington
% Last modified: Mon 13 Jul 2015 02:36:20 PM E
