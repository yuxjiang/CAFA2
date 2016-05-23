function [A] = pfp_annotprop(DAG, A)
%PFP_ANNOTPROP annotation propagation
%
% [oa] = PFP_ANNOTPROP(oa);
%
%   Propagates annotations up to the root term.
%
% Input
% -----
% [double]
% DAG:  An m-by-m adjacency matrix, (as a [D]irected [A]cyclic [G]raph)
%       DAG(i, j) ~= 0 means term i has relationship to term j.
%
% [logical]
% A:    An n-by-m binary annotation matrix, A(i, j) = true means object i is
%       annotated to have term j.
%
% Output
% ------
% [logical]
% A:  The propagated ontology annotation matrix.
%
% Dependency
% ----------
%[>]Bioinformatics Toolbox:graphtopoorder

  % check inputs {{{
  if nargin ~= 2
    error('pfp_annotprop:InputCount', 'Expected 2 inputs.');
  end

  % DAG
  validateattributes(DAG, {'double'}, {'square'}, '', 'DAG', 1);
  m = size(DAG, 1);

  % A
  validateattributes(A, {'logical'}, {'ncols', m}, '', 'A', 2);
  % }}}

  % propagation {{{
  DAG = DAG ~= 0; % make it logical

  % topologically sort terms from leaf to root
  order = graphtopoorder(DAG);
  for i = 1 : numel(order)
    p = DAG(order(i), :); % parent term(s)
    A(:, p) = bsxfun(@or, A(:, p), A(:, order(i)));
  end
  % }}}
return

% -------------
% Yuxiang Jiang (yuxjiang@indiana.edu)
% Department of Computer Science
% Indiana University Bloomington
% Last modified: Thu 12 May 2016 04:13:41 PM E
