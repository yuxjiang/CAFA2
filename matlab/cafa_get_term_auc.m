function [aucs] = cafa_get_term_auc(aucs, mids)
%CAFA_GET_TERM_AUC CAFA get term AUC
%
% [aucs] = CAFA_GET_TERM_AUC(aucs, mids);
%
%   Picks specified 'auc' structures.
%
% Input
% -----
% [cell]
% aucs: The collected 'term_auc' structures, which has the following fields
%       .id   [char]    The model name, used for naming files.
%       .term [cell]    1-by-m, term names. ('m': the number of terms)
%       .auc  [double]  1-by-m, AUC estimates.
%       .mode [double]  The evaluation mode, passed through from input.
%       .npos [double]  The number of positive annotations cutoff, passed
%                       through from input.
%       See cafa_eval_term_auc.m, cafa_collect.m
%
% [cell]
% mids: 1-by-k method name.
%
% Output
% ------
% [cell]
% aucs: The filtered cell 'aucs'.
%
% Dependency
% ----------
%[>]cafa_eval_term_auc.m
%[>]cafa_collect.m

  % check inputs {{{
  if nargin ~= 2
    error('cafa_get_term_auc:InputCount', 'Expected 2 input.');
  end

  % aucs
  validateattributes(aucs, {'cell'}, {'nonempty'}, '', 'aucs', 1);
  n = numel(aucs);

  % mids
  validateattributes(mids, {'cell'}, {'nonempty'}, '', 'mids', 2);
  % }}}

  % filtering {{{
  ids = cell(1, n);
  for i = 1 : n
    ids{i} = aucs{i}.id;
  end
  [found, index] = ismember(mids, ids);
  if ~all(found)
    error('cafa_get_term_auc:NotFound', 'Some methods are not found.');
  end
  aucs = aucs(index);
  %}}}
return

% -------------
% Yuxiang Jiang (yuxjiang@indiana.edu)
% Department of Computer Science
% Indiana University, Bloomington
% Last modified: Mon 23 May 2016 06:05:50 PM E
