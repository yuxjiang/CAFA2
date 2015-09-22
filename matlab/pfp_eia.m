function [eia] = pfp_eia(DAG, A)
%PFP_EIA Estimated information accretion
% {{{
%
% [eia] = PFP_EIA(oa);
%
%   Estimates the information accretion for each term in the ontology.
%
%   Note:
%   To avoid infinite 'eia', a pseudocount of one is added to each term.
%
% Definition
% ----------
% Information accretion:
% See the [Reference] below for details.
%
% Input
% -----
% [double]
% DAG:  m x m, the adjacency matrix (for a directed acyclic graph)
%       DAG(i, j) ~= 0 means term[i] has some relation to term[j].
%
% [logical]
% A:    n x m, the ontology annotation matrix.
%       A(i, j) = 1 means obj[i] is annotated to have term[j].
%
% Output
% ------
% [double]
% eia:  1 x m, an array of estimated information accretion.
%
% Reference
% ---------
% W. Clark and P. Radivojac, Information theoretic evaluation of predicted
% ontology annotations. Bioinformatics, 2013.
% }}}

  % check inputs {{{
  if nargin ~= 2
    error('pfp_eia:InputCount', 'Expected 2 inputs.');
  end

  % check the 1st input 'DAG' {{{
  validateattributes(DAG, {'double'}, {'square'}, '', 'DAG', 1);
  m = size(DAG, 1);
  % check the 1st input 'DAG' }}}

  % check the 2nd input 'A' {{{
  validateattributes(A, {'logical'}, {'ncols', m}, '', 'A', 2);
  % check the 2nd input 'A' }}}
  % check inputs }}}

  % find annotated "sub-ontology" {{{
  has_seq = any(A, 1);
  subDAG  = DAG(has_seq, has_seq) ~= 0; % make it logical
  subA    = A(:, has_seq);
  % find annotated "sub-ontology" }}}

  % calculate eia for annotated sub-ontology {{{
  k      = size(subDAG, 1);
  subeia = zeros(1, k);

  % add one pseudocount to each term, i.e., a virtual protein that has
  % annotations with all terms.
  subA = [subA; ones(1, k)];

  for i = 1 : k
    p        = subDAG(i, :); % parent term(s)
    support  = all(subA(:, p), 2);
    S        = sum(support);
    subia(i) = sum(support & subA(:, i)) / S;
  end
  % calculate eia for annotated sub-ontology }}}

  % prepare output {{{
  eia          = zeros(1, m);
  eia(has_seq) = -log(subia);
  % prepare output }}}}
return

% -------------
% Yuxiang Jiang (yuxjiang@indiana.edu)
% Department of Computer Science
% Indiana University Bloomington
% Last modified: Tue 05 May 2015 11:23:44 AM E
