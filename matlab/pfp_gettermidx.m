function [idx] = pfp_gettermidx(ont, term_lst)
%PFP_GETTERMIDX Get term index
% {{{
%
% [idx] = PFP_GETTERMIDX(ont, term_lst);
%
%   Returns an array of indices of the given term list.
%
% Note
% ----
% 1. If 'alt_list' is presented in the ontology structure, 'term_lst' will
%    also be searched against that list, and if hit, their current IDs will be
%    returned;
%
% 2. For IDs that are not found, 0 will be returned as an index.
%
% Input
% -----
% [struct]
% ont:      The ontology structure.
%           See pfp_ontbuild.m
%
% [cell, char or struct]
% term_lst: [cell]      - A cell of (char) term IDs.
%           [char]      - A single (char) term ID.
%           [struct]    - An array of term structures.
%
% Output
% ------
% [double]
% idx:  An array of indices.
%
% See Also
% --------
%[>]pfp_ontbuild.m
% }}}

  % check inputs {{{
  % check the 1st argument 'ont' {{{
  validateattributes(ont, {'struct'}, {'nonempty'}, '', 'ont', 1);
  % }}}

  % check the 2nd argument 'term_lst' {{{
  validateattributes(term_lst, {'cell', 'char', 'struct'}, {'nonempty'}, '', 'term_lst', 2);
  % }}}
  switch class(term_lst)
  case 'char'
    term_lst = {term_lst};
  case 'struct'
    term_lst = {term_lst.id};
  otherwise
    % case: cell, nothing to do
  end
  % }}}

  % find ID of requested terms {{{
  idx = zeros(numel(term_lst), 1);

  if isfield(ont, 'alt_list') % has alternate id list structure
    [is_new, indexN] = ismember(term_lst, {ont.term.id});
    [is_old, indexO] = ismember(term_lst, ont.alt_list.old);

    is_conflict = is_new & is_old;

    % checking
    if any(is_conflict)
      warning('pfp_gettermidx:AbmiguousID', 'Some IDs are ambiguous, mapped to the latest ID.');
      is_old = is_old & ~is_new;
    end

    idx(is_new) = indexN(is_new);
    idx(is_old) = indexO(is_old);
  else
    [found, index] = ismember(term_lst, {ont.term.id});
    idx(found) = index(found);
  end
  idx = reshape(idx, 1, []);
  % }}}
return

% -------------
% Yuxiang Jiang (yuxjiang@indiana.edu)
% Department of Computer Science
% Indiana University Bloomington
% Last modified: Sat 09 Jan 2016 10:15:47 AM C
