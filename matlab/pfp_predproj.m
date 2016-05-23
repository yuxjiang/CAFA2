function [pred] = pfp_predproj(pred, list, op)
%PFP_PREDPROJ Prediction projection
%
% [pred] = PFP_PREDPROJ(pred, list);
% [pred] = PFP_PREDPROJ(pred, list, 'object');
%
%   Projects the prediction to a list of objects.
%
% [pred] = PFP_PREDPROJ(pred, list, 'term');
%
%   Projects the prediction to subset of ontology terms.
%
% Note
% ----
% In the case of op being 'term', 'list' must be a subset of
% 'pred.ontology.term', otherwise the prediction consistency might be violated.
%
% Input
% -----
% [struct]
% pred: The prediction structure, which is similar to an 'oa' (See
%       pfp_oabuild.m), except that it has a field 'score' instead of
%       'annotation'. See pfp_blast.m for an example 'pred' output.
%
% [cell or struct]
% list: A list of object IDs or terms (structure or ID).
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
%
% See Also
% --------
%[>]pfp_oabuild.m
%[>]pfp_blast.m

  % check inputs {{{
  if nargin < 2 || nargin > 3
    error('pfp_predproj:InputCount', 'Expected 2 or 3 inputs.');
  end

  if nargin == 2
    op = 'object';
  end

  % check the 1st input 'pred' {{{
  validateattributes(pred, {'struct'}, {'nonempty'}, '', 'pred', 1);
  % }}}

  % check the 2nd input 'list' {{{
  validateattributes(list, {'cell', 'struct'}, {'nonempty'}, '', 'list', 2);
  % }}}

  % op 
  validateattributes(op, {'char'}, {'nonempty'}, '', 'op', 3);
  op = validatestring(op, {'object', 'term'});
  % }}}

  % project items {{{
  switch op
  case 'object'
    [found, index] = ismember(list, pred.object);
    score = sparse(numel(list), numel(pred.ontology.term));
    score(found, :) = pred.score(index(found), :);

    % set up output
    pred.object = reshape(list, [], 1);
  case 'term'
    if isstruct(list)
      list = {list.id};
    end

    [found, index] = ismember(list, {pred.ontology.term.id});
    score = pred.score(:, index(found));

    if ~all(found)
      error('pfp_predproj:InputErr', 'Term list must be a subset of the original ontology terms.');
    end

    pred.ontology = pfp_subont(pred.ontology, list(found));
  otherwise
    % nop
  end
  % }}}

  % prepare for the output {{{
  pred.score = score;
  pred.date = datestr(now, 'mm/dd/yyyy HH:MM');
  % }}}
return

% -------------
% Yuxiang Jiang
% School of Informatics and Computing
% Indiana University Bloomington
% Last modified: Sun 22 May 2016 04:09:16 PM E
