function [oa] = pfp_oaproj(oa, lst, option)
%PFP_OAPROJ Ontology annotation projection
% {{{
%
% [oa] = PFP_OAPROJ(oa, lst, 'object');
%
%   Projects the ontology annotations to a list of objects.
%
% [oa] = PFP_OAPROJ(oa, lst, 'term');
%
%   Projects the ontology annotations to a subset of terms.
%
% Note
% ----
% In the case of option being 'term', 'lst' must be a subset of terms in the
% given ontology (oa.ontology), otherwise an error message will be prompted.
%
% In the case of projecting to another ontology which have different structures,
% e.g., allowing different sets of relationships, see pfp_oaconv.m.
%
% 'eia' of the given oa will be removed due to the change of ontology structure.
%
% Input
% -----
% [struct]
% oa:     The ontology annotation structure.
%
% [cell]
% lst:    A cell array of (char) object IDs or terms.
%
% [char]
% option: Must be either 'object' or 'term'.
%
% Output
% ------
% oa: The projected ontology annotation structure.
%
% Dependency
% ----------
%[>]pfp_oabuild.m
%[>]pfp_subont.m
%
% See Also
% --------
%[>]pfp_oaconv.m
% }}}

  % check inputs {{{
  if nargin ~= 3
    error('pfp_oaproj:InputCount', 'Expected 3 inputs.');
  end

  % check the 1st argument 'oa' {{{
  validateattributes(oa, {'struct'}, {'nonempty'}, '', 'oa', 1);
  % }}}

  % check the 2nd argument 'lst' {{{
  validateattributes(lst, {'cell'}, {'nonempty'}, '', 'lst', 2);
  % }}}

  % check the 3rd argument 'option' {{{
  option = validatestring(option, {'object', 'term'}, '', 'option', 3);
  % }}}
  % }}}

  % project oa {{{
  switch option
  case 'object'
    [found, index] = ismember(lst, oa.object);
    if ~all(found)
      warning('pfp_oaproj:NoAnnot', 'Some objects do not have annotations.');
    end

    annotation           = logical(sparse(numel(lst), numel(oa.ontology.term)));
    annotation(found, :) = oa.annotation(index(found), :);

    % set up output
    oa.object = reshape(lst, [], 1);
  case 'term'
    if isstruct(lst)
      lst = {lst.id};
    end
    [found, index] = ismember(lst, {oa.ontology.term.id});
    annotation     = oa.annotation(:, index(found));

    if ~all(found)
      error('pfp_oaproj:NotSubset', '''lst'' must be contained in the ontology of ''oa''.');
    end

    % set up output
    oa.ontology = pfp_subont(oa.ontology, lst);
    if isfield(oa, 'eia')
      oa = rmfield(oa, 'eia');
    end
  otherwise
    % nop
  end
  % }}}

  % update oa {{{
  oa.annotation = annotation;
  oa.date = datestr(now, 'mm/dd/yyyy HH:MM');
  % }}}
return

% -------------
% Yuxiang Jiang (yuxjiang@indiana.edu)
% Department of Computer Science
% Indiana University Bloomington
% Last modified: Sun 06 Mar 2016 07:46:59 PM E
