function [A] = pfp_annotprop(DAG, A)
%PFP_ANNOTPROP annotation propagation
% {{{
%
% [oa] = PFP_ANNOTPROP(oa);
%
%   Propagates annotations up to the root term.
%
% Input
% -----
% [double]
% DAG:  m-by-m, the adjacency matrix (for a directed acyclic graph)
%       DAG(i, j) ~= 0 means term[i] has some relation to term[j].
%
% [logical]
% A:    n-by-m, the ontology annotation matrix.
%       A(i, j) = 1 means obj[i] is annotated to have term[j].
%
% Output
% ------
% [logical]
% A:    n-by-m, the propagated ontology annotation matrix.
%       A(i, j) = 1 means obj[i] is annotated to have term[j].
%
% Dependency
% ----------
%[>]Bioinformatics Toolbox:graphtopoorder
% }}}

  % check inputs {{{
  if nargin ~= 2
    error('pfp_annotprop:InputCount', 'Expected 2 inputs.');
  end

  % check the 1st input 'DAG' {{{
  validateattributes(DAG, {'double'}, {'square'}, '', 'DAG', 1);
  m = size(DAG, 1);
  % }}}

  % check the 2nd input 'A' {{{
  validateattributes(A, {'logical'}, {'ncols', m}, '', 'A', 2);
  % }}}
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
% Last modified: Tue 05 May 2015 11:00:13 AM E
