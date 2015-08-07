function [term] = pfp_getterm(ont, term_lst)
%PFP_GETTERM Get term
% {{{
%
% [term] = PFP_GETTERM(ont, term_lst);
%
%   Returns a term structure array.
%
% Note
% ----
% 1. If 'alt_list' is presented in the ontology structure, 'term_lst' will
%    also be searched against that list, and those corresponding "current IDs"
%    will be returned, if found.
%
% 2. For IDs that are not found, an empty string will be returned as a
%    placeholder for both of the term ID and name.
%
% Input
% -----
% [struct]
% ont:      The ontology structure.
%
% [cell or char]
% term_lst: [cell]  - a cell of (char) term IDs.
%           [char]  - a single (char) term ID.
%
% Output
% ------
% [struct]
% term:     An array of term structures.
%
% Dependency
% ----------
%[>]pfp_ontbuild.m
% }}}

  % check inputs {{{
  if nargin ~= 2
    error('pfp_getterm:InputCount', 'Expected 2 inputs.');
  end

  % check the 1st argument 'ont' {{{
  validateattributes(ont, {'struct'}, {'nonempty'}, '', 'ont', 1);
  % check the 1st argument 'ont' }}}

  % check the 2nd argument 'term_lst' {{{
  validateattributes(term_lst, {'cell', 'char'}, {'nonempty'}, '', 'term_lst', 2);

  if ischar(term_lst)
    term_lst = {term_lst};
  end
  % check the 2nd argument 'term_lst' }}}
  % check inputs }}}

  % find ID of requested terms {{{
  acc  = repmat({''}, numel(term_lst), 1);
  name = repmat({''}, numel(term_lst), 1);

  if isfield(ont, 'alt_list') % has alternate id list structure
    [is_new, indexN] = ismember(term_lst, {ont.term.id});
    [is_old, indexO] = ismember(term_lst, ont.alt_list.old);

    is_conflict = is_new & is_old;

    % check for conflict
    if any(is_conflict)
      warning('pfp_getterm:AmbiguousID', 'Ambiguous ID found. They will be mapped to the latest ID.');
      is_old = is_old & ~is_new;
    end

    acc(is_new) = {ont.term(indexN(is_new)).id};
    acc(is_old) = ont.alt_list.new(indexO(is_old));
  else
    [found, index] = ismember(term_lst, {ont.term.id});
    acc(found) = {ont.term(index(found)).id};
  end
  % find ID of requested terms }}}

  % get term names {{{
  [found, index] = ismember(acc, {ont.term.id});
  name(found) = {ont.term(index(found)).name};
  % get term names }}}

  % prepare output {{{
  term = cell2struct([acc, name], {'id', 'name'}, 2);
  % prepare output }}}
return

% -------------
% Yuxiang Jiang (yuxjiang@indiana.edu)
% Department of Computer Science
% Indiana University Bloomington
% Last modified: Fri 07 Aug 2015 01:40:40 PM E
