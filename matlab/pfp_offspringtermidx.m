function [idx] = pfp_offspringtermidx(ont, term_lst)
%PFP_OFFSPRINGTERMIDX Offspring term index
% {{{
%
% [idx] = PFP_OFFSPRINGTERMIDX(ont, term_lst);
%
%   Returns the indices of the union of all offsprings terms (self-included).
%
% Input
% -----
% [struct]
% ont:      The ontology structure.
%           See pfp_ontbuild.m
%
% [cell, char or struct]
% term_lst: [cell]    - A cell of (char) term IDs.
%           [char]    - A single (char) term ID.
%           [struct]  - An array of term structures.
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
% }}}

  % check inputs {{{
  if nargin ~= 2
    error('pfp_offspringtermidx:InputCount', 'Expected 2 inputs.');
  end

  % check the 1st argument 'ont' {{{
  validateattributes(ont, {'struct'}, {'nonempty'}, '', 'ont', 1);
  % check the 1st argument 'ont' }}}

  % check the 2nd arugment 'term_lst' {{{
  validateattributes(term_lst, {'cell', 'char', 'struct'}, {'nonempty'}, '', 'term_lst', 2);
  % check the 2nd arugment 'term_lst' }}}
  % check inputs }}}

  % find indices {{{
  index = pfp_gettermidx(ont, term_lst);
  index(index == 0) = [];
  % find indices }}}

  % find offsprings {{{
  walking        = false(numel(ont.term), 1);
  walking(index) = true;
  visited        = walking;
  while any(walking)
    visited = visited | walking;
    walking = full(any(ont.DAG(:, walking), 2)) & ~visited;
  end
  idx = reshape(find(visited), 1, []);
  % find offsprings }}}
return

% -------------
% Yuxiang Jiang (yuxjiang@indiana.edu)
% Department of Computer Science
% Indiana University Bloomington
% Last modified: Wed 13 Jan 2016 09:21:52 AM E
