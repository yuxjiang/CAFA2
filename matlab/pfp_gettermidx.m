function [idx] = pfp_gettermidx(ont, list)
%PFP_GETTERMIDX Get term index
%
% [idx] = PFP_GETTERMIDX(ont, list);
%
%   Returns an array of indices of the given term list.
%
% Note
% ----
% 1. If 'alt_list' is presented in the ontology structure, 'list' will also be
%    searched against that list, and if hit, their current IDs will be returned;
%
% 2. For IDs that are not found, 0 will be returned as an index.
%
% Input
% -----
% [struct]
% ont:  The ontology structure. See pfp_ontbuild.m
%
% [cell, char or struct]
% list: cell    - A cell of (char) term IDs.
%       char    - A single (char) term ID.
%       struct  - An array of term structures.
%
% Output
% ------
% [double]
% idx:  An array of indices.
%
% See Also
% --------
%[>]pfp_ontbuild.m

  % check inputs {{{
  if nargin ~= 2
    error('pfp_gettermidx:InputCount', 'Expected 2 inputs.');
  end

  % ont
  validateattributes(ont, {'struct'}, {'nonempty'}, '', 'ont', 1);

  % list
  validateattributes(list, {'cell', 'char', 'struct'}, {'nonempty'}, '', 'list', 2);
  switch class(list)
  case 'char'
    list = {list};
  case 'struct'
    list = {list.id};
  otherwise
    % case: cell, nothing to do
  end
  % }}}

  % find ID of requested terms {{{
  idx = zeros(numel(list), 1);

  if isfield(ont, 'alt_list') % has alternate id list structure
    [is_new, indexN] = ismember(list, {ont.term.id});
    [is_old, index_alt_in_O] = ismember(list, ont.alt_list.old);
    [~, indexO] = ismember( ont.alt_list.new(index_alt_in_O(is_old)), {ont.term.id})

    is_conflict = is_new & is_old;

    % checking
    if any(is_conflict)
      warning('pfp_gettermidx:AbmiguousID', 'Some IDs are ambiguous, mapped to the latest ID.');
    %  is_old = is_old & ~is_new;
    end

    idx(is_old) = indexO
    idx(is_new) = indexN(is_new); % IDs which have a conflict, will be overwritten with the latest index; i.e. if is_old and is_new, both are 1, then the index in the GO_list directly is considered, and the alternate mapping for it is not used.
    
  else
    [found, index] = ismember(list, {ont.term.id});
    idx(found) = index(found);
  end
  idx = reshape(idx, 1, []);
  % }}}
return

% -------------
% Yuxiang Jiang (yuxjiang@indiana.edu)
% Department of Computer Science
% Indiana University Bloomington

% Modified by Rashika Ramola (ramola.r@northeastern.edu)
% Khoury College of Computer Sciences
% Northeastern University
% Last modified: Mon 27 Nov 2023 2:09 PM E 
