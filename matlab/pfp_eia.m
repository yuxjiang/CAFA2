function [eia] = pfp_eia(DAG, A)
%PFP_EIA Estimated information accretion
%
% [eia] = PFP_EIA(DAG, A);
%
%   Estimates the information accretion for each term in the ontology.
%
% Note
% ----
% To avoid infinite 'eia', a pseudocount of one is added to each term.
%
% Definition
% ----------
% Information accretion:
% The negative logarithm of the conditional probability of a term being
% annotated given that all of its parents are annotated:
% ia(t) = -log P(t=1 | Pa(t)=1),
% where Pa(t) is the parents of term t.
%
% See the [Reference] below for details.
%
% Reference
% ---------
% W. Clark and P. Radivojac, Information theoretic evaluation of predicted
% ontology annotations. Bioinformatics, 2013.
%
% Input
% -----
% [double]
% DAG:  The m-by-m adjacency matrix.
%       DAG(i, j) ~= 0 means term i has a relationship to term j.
%
% [logical]
% A:    An n-by-m, the ontology annotation matrix.
%       A(i, j) = true indicates object i is annotated to have term j.
%
% Output
% ------
% [double]
% eia:  An 1-by-m array of estimated information accretion.

  % check inputs {{{
  if nargin ~= 2
    error('pfp_eia:InputCount', 'Expected 2 inputs.');
  end

  % DAG
  validateattributes(DAG, {'double'}, {'square'}, '', 'DAG', 1);
  m = size(DAG, 1);

  % A
  validateattributes(A, {'logical'}, {'ncols', m}, '', 'A', 2);
  % }}}

  % find annotated "sub-ontology" {{{
  has_seq = any(A, 1);
  subDAG  = DAG(has_seq, has_seq) ~= 0; % make it logical
  subA    = A(:, has_seq);
  % }}}

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
  % }}}

  % prepare output {{{
  eia          = zeros(1, m);
  eia(has_seq) = -log(subia);
  % }}}
return

% -------------
% Yuxiang Jiang (yuxjiang@indiana.edu)
% Department of Computer Science
% Indiana University Bloomington
% Last modified: Thu 12 May 2016 04:29:43 PM E
