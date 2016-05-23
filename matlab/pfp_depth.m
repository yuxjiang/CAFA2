function [d] = pfp_depth(ont, list)
%PFP_DEPTH Depth
%
% [d] = PFP_DEPTH(ont);
%
%   Returns the depth of an ontology.
%
% [d] = PFP_DEPTH(ont, list);
%
%   Returns the depth of a (list of) term(s) in the ontology.
%
% Definition
% ----------
% [Term depth]: Length of the shortest path from the root to this term.
% [Ontology depth]: The maximum "term depth" in this ontology.
%
% Input
% -----
% [struct]
% ont:  The ontology structure. See pfp_ontbuild.m
%
% (optional)
% [struct or cell]
% list: struct  - an array of term structures.
%       cell    - a cell of (char) term IDs.
%
% Output
% ------
% [double]
% d:  The depth information.
%
% Dependency
% ----------
%[>]pfp_roottermidx.m
%
% See Also
% --------
%[>]pfp_ontbuild.m

  % check inputs {{{
  if nargin ~= 1 && nargin ~= 2
    error('pfp_depth:InputCount', 'Expected 1 or 2 inputs.');
  end

  if nargin == 1
    list = {};
  end

  % ont
  validateattributes(ont, {'struct'}, {'nonempty'}, '', 'ont', 1);

  % list
  validateattributes(list, {'struct', 'cell'}, {}, '', 'list', 2);
  if isempty(list)
    depth_mode = 'ont'; % compute the ontology depth
  else
    depth_mode = 'term'; % compute the term depth
  end
  % }}}

  % compute depth {{{
  switch depth_mode
  case 'ont'
    touched = false(1, numel(ont.term));
    touched(pfp_roottermidx(ont)) = true;

    d = 1;
    while ~all(touched)
      touched(any(ont.DAG(:, touched), 2)) = true;
      d = d + 1;
    end
  case 'term'
    if isstruct(list) % array of structures
      list = {list.id};
    end

    [found, index] = ismember(list, {ont.term.id});
    if ~all(found)
      warning('pfp_depth:InputErr', 'Some terms are not found in the ontology.');
    end

    D = zeros(numel(ont.term), 1);
    D(pfp_roottermidx(ont)) = 1;

    depth = 1;
    while ~all(D(index(found)) > 0)
      depth = depth + 1;
      % only update [term depth] of those unreached terms (D == 0)
      D(D == 0 & any(ont.DAG(:, D>0), 2)) = depth;
    end
    d = nan(1, numel(list));
    d(found) = reshape(D(index(found)), 1, []);
  otherwise
    % nop
  end
  % }}}
return

% -------------
% Yuxiang Jiang (yuxjiang@indiana.edu)
% Department of Computer Science
% Indiana University Bloomington
% Last modified: Mon 23 May 2016 05:59:48 PM E
