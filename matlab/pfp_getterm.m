function [term] = pfp_getterm(ont, list)
%PFP_GETTERM Get term
%
% [term] = PFP_GETTERM(ont, list);
%
%   Returns a term structure array.
%
% Note
% ----
% 1. If 'alt_list' is presented in the ontology structure, 'list' will also be
%    searched against that list, and those corresponding "current IDs" will be
%    returned, if found.
%
% 2. For IDs that are not found, an empty string will be returned as a
%    placeholder for both of the term ID and name.
%
% Input
% -----
% [struct]
% ont:  The ontology structure. See pfp_ontbuild.m
%
% [cell or char]
% list: cell  - a cell of (char) term IDs.
%       char  - a single (char) term ID.
%
% Output
% ------
% [struct]
% term: An array of term structures.
%
% See Also
% --------
%[>]pfp_ontbuild.m

  % check inputs {{{
  if nargin ~= 2
    error('pfp_getterm:InputCount', 'Expected 2 inputs.');
  end

  % ont
  validateattributes(ont, {'struct'}, {'nonempty'}, '', 'ont', 1);

  % list
  validateattributes(list, {'cell', 'char'}, {'nonempty'}, '', 'list', 2);

  if ischar(list)
    list = {list};
  end
  % }}}

  % find ID of requested terms {{{
  acc  = repmat({''}, numel(list), 1);
  name = repmat({''}, numel(list), 1);

  if isfield(ont, 'alt_list') % has alternate id list structure
    [is_new, indexN] = ismember(list, {ont.term.id});
    [is_old, indexO] = ismember(list, ont.alt_list.old);

    is_conflict = is_new & is_old;

    % check for conflict
    if any(is_conflict)
      warning('pfp_getterm:AmbiguousID', 'Ambiguous ID found. They will be mapped to the latest ID.');
      is_old = is_old & ~is_new;
    end

    acc(is_new) = {ont.term(indexN(is_new)).id};
    acc(is_old) = ont.alt_list.new(indexO(is_old));
  else
    [found, index] = ismember(list, {ont.term.id});
    acc(found) = {ont.term(index(found)).id};
  end
  % }}}

  % get term names {{{
  [found, index] = ismember(acc, {ont.term.id});
  name(found) = {ont.term(index(found)).name};
  % }}}

  % prepare output {{{
  term = cell2struct([acc, name], {'id', 'name'}, 2);
  % }}}
return

% -------------
% Yuxiang Jiang (yuxjiang@indiana.edu)
% Department of Computer Science
% Indiana University Bloomington
% Last modified: Mon 23 May 2016 06:59:36 PM E
