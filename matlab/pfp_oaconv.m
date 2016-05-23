function [oa] = pfp_oaconv(oa, ont)
%PFP_PREDCONV Prediction conversion
%
% [oa] = PFP_PREDCONV(oa, ont);
%
%   Converts ontology annotation structure to another ontology.
%
% Note
% ----
% This function is used when the structure of an ontology has been changed,
% e.g., by removing one type of edges ("part_of") and consider the "is_a" DAG.
%
% If the resulting ontology is simply a subset terms, use pfp_oaproj.m
% instead.
%
% Input
% -----
% [struct]
% oa:   The ontology annotation structure. See pfp_oabuild.m
%
% [struct]
% ont:  The ontology structure. See pfp_ontbuild.m
%
% Output
% ------
% [struct]
% oa:   The converted structure.
%
% Dependency
% ----------
%[>]pfp_leafannot.m
%[>]pfp_annotprop.m
%
% See Also
% --------
%[>]pfp_oabuild.m
%[>]pfp_ontbuild.m
%[>]pfp_oaproj.m

  % check inputs {{{
  if nargin ~= 2
    error('pfp_oaconv:InputCount', 'Expected 2 inputs.');
  end

  % oa
  validateattributes(oa, {'struct'}, {'nonempty'}, '', 'oa', 1);

  % ont
  validateattributes(ont, {'struct'}, {'nonempty'}, '', 'ont', 2);
  % }}}

  % conversion {{{
  A = pfp_leafannot(oa); % get leaf annotation matrix
  [found, index] = ismember({ont.term.id}, {oa.ontology.term.id});
  A = A(:, index(found)); % re-order columns to match the new ontology
  oa.ontology   = ont;
  oa.annotation = pfp_annotprop(ont.DAG, A); % replenish
  % }}}
return

% -------------
% Yuxiang Jiang (yuxjiang@indiana.edu)
% Department of Computer Science
% Indiana University, Bloomington
% Last modified: Thu 12 May 2016 03:37:35 PM E
