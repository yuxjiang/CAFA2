function [idx] = pfp_offspringtermidx(ont, list)
%PFP_OFFSPRINGTERMIDX Offspring term index
%
% [idx] = PFP_OFFSPRINGTERMIDX(ont, list);
%
%   Returns the indices of the union of all offsprings terms (self-included).
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
% idx:  An array of offspring term indices.
%
% Dependency
% ----------
%[>]pfp_gettermidx.m
%
% See Also
% --------
%[>]pfp_ontbuild.m

  % check inputs {{{
  if nargin ~= 2
    error('pfp_offspringtermidx:InputCount', 'Expected 2 inputs.');
  end

  % ont
  validateattributes(ont, {'struct'}, {'nonempty'}, '', 'ont', 1);

  % list
  validateattributes(list, {'cell', 'char', 'struct'}, {'nonempty'}, '', 'list', 2);
  % }}}

  % find indices {{{
  index = pfp_gettermidx(ont, list);
  index(index == 0) = [];
  % }}}

  % find offsprings {{{
  walking        = false(numel(ont.term), 1);
  walking(index) = true;
  visited        = walking;
  while any(walking)
    visited = visited | walking;
    walking = full(any(ont.DAG(:, walking), 2)) & ~visited;
  end
  idx = reshape(find(visited), 1, []);
  % }}}
return

% -------------
% Yuxiang Jiang (yuxjiang@indiana.edu)
% Department of Computer Science
% Indiana University Bloomington
% Last modified: Mon 23 May 2016 06:54:27 PM E
