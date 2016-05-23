function [oa] = pfp_oaproj(oa, list, op)
%PFP_OAPROJ Ontology annotation projection
%
% [oa] = PFP_OAPROJ(oa, list);
% [oa] = PFP_OAPROJ(oa, list, 'object');
%
%   Projects the ontology annotations to a list of objects.
%
% [oa] = PFP_OAPROJ(oa, list, 'term');
%
%   Projects the ontology annotations to a subset of terms.
%
% Note
% ----
% In the case of 'op' = 'term', 'list' must be a subset of terms in the
% given ontology (oa.ontology), otherwise an error message will be prompted.
%
% In the case of projecting to another ontology which have different structures,
% e.g., allowing different sets of relationships, see pfp_oaconv.m.
%
% Input
% -----
% (required)
% [struct]
% oa:   The ontology annotation structure. See pfp_oabuild.m
%
% [cell]
% list: A cell array of (char) object IDs or terms.
%
% (optional)
% [char]
% op:   Must be either 'object' or 'term'.
%       default: 'object'
%
% Output
% ------
% oa: The projected ontology annotation structure.
%
% Dependency
% ----------
%[>]pfp_subont.m
%
% See Also
% --------
%[>]pfp_oabuild.m
%[>]pfp_oaconv.m

  % check inputs {{{
  if nargin ~= 2 && nargin ~= 3
    error('pfp_oaproj:InputCount', 'Expected 2 or 3 inputs.');
  end

  if nargin == 2
    op = 'object';
  end

  % oa
  validateattributes(oa, {'struct'}, {'nonempty'}, '', 'oa', 1);

  % list
  validateattributes(list, {'cell'}, {'nonempty'}, '', 'list', 2);

  % op
  op = validatestring(op, {'object', 'term'}, '', 'op', 3);
  % }}}

  % project oa {{{
  switch op
  case 'object'
    [found, index] = ismember(list, oa.object);
    if ~all(found)
      warning('pfp_oaproj:NoAnnot', 'Some objects do not have annotations.');
    end

    annotation           = logical(sparse(numel(list), numel(oa.ontology.term)));
    annotation(found, :) = oa.annotation(index(found), :);

    % set up output
    oa.object = reshape(list, [], 1);
  case 'term'
    if isstruct(list)
      list = {list.id};
    end
    [found, index] = ismember(list, {oa.ontology.term.id});
    annotation     = oa.annotation(:, index(found));

    if ~all(found)
      error('pfp_oaproj:NotSubset', '''list'' must be contained in the ontology of ''oa''.');
    end

    % set up output
    oa.ontology = pfp_subont(oa.ontology, list);
  otherwise
    % nop
  end
  % }}}

  % update oa {{{
  oa.annotation = annotation;
  oa.date       = datestr(now, 'mm/dd/yyyy HH:MM');
  % }}}
return

% -------------
% Yuxiang Jiang (yuxjiang@indiana.edu)
% Department of Computer Science
% Indiana University Bloomington
% Last modified: Sun 22 May 2016 04:08:47 PM E
