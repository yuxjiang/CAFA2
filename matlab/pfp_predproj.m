function [pred] = pfp_predproj(pred, lst, op)
%PFP_PREDPROJ Prediction projection
% {{{
%
% [pred] = PFP_PREDPROJ(pred, lst);
%
% [pred] = PFP_PREDPROJ(pred, lst, 'object');
%
%   Projects the prediction to a list of objects.
%
% [pred] = PFP_PREDPROJ(pred, lst, 'term');
%
%   Projects the prediction to subset of ontology terms.
%
% Note
% ----
% In the case of op being 'term', 'lst' must be a subset of
% 'pred.ontology.term', otherwise the prediction consistency might be violated.
%
% Input
% -----
% [struct]
% pred: The prediction structure, which is similar to an 'oa'
%       (See pfp_oabuild.m), except that it has a field 'score' instead of
%       'annotation'.
%       See pfp_gotcha.m for an example 'pred' output
%
% [cell or struct]
% lst:  A list of object IDs or terms (structure or ID).
%
% (option)
% [char]
% op:   One of {'object', 'term'}.
%       default: 'object'
%
% Output
% ------
% [struct]
% pred:   The projected prediction structure.
%
% Dependency
% ----------
%[>]pfp_subont.m
% }}}

  % check inputs {{{
  if nargin < 2 || nargin > 3
    error('pfp_predproj:InputCount', 'Expected 2 or 3 inputs.');
  end

  if nargin == 2
    op = 'object';
  end

  % check the 1st input 'pred' {{{
  validateattributes(pred, {'struct'}, {'nonempty'}, '', 'pred', 1);
  % check the 1st input 'pred' }}}

  % check the 2nd input 'lst' {{{
  validateattributes(lst, {'cell', 'struct'}, {'nonempty'}, '', 'lst', 2);
  % check the 2nd input 'lst' }}}

  % check the 3rd input 'op' {{{
  validateattributes(op, {'char'}, {'nonempty'}, '', 'op', 3);
  op = validatestring(op, {'object', 'term'});
  % check the 3rd input 'op' }}}
  % check inputs }}}

  % project items {{{
  switch op
  case 'object'
    [found, index] = ismember(lst, pred.object);
    score = sparse(numel(lst), numel(pred.ontology.term));
    score(found, :) = pred.score(index(found), :);

    % set up output
    pred.object = reshape(lst, [], 1);
  case 'term'
    if isstruct(lst)
      lst = {lst.id};
    end

    [found, index] = ismember(lst, {pred.ontology.term.id});
    score = pred.score(:, index(found));

    if ~all(found)
      error('pfp_predproj:InputErr', 'Term list must be a subset of the original ontology terms.');
    end

    pred.ontology = pfp_subont(pred.ontology, lst(found));
  otherwise
    % nop
  end
  % project items }}}

  % prepare for the output {{{
  pred.score = score;
  pred.date = date;
  % prepare for the output }}}
return

% -------------
% Yuxiang Jiang
% School of Informatics and Computing
% Indiana University Bloomington
% Last modified: Sat 09 Jan 2016 10:35:59 AM C
