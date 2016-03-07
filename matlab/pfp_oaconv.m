function [oa] = pfp_oaconv(oa, ont)
%PFP_PREDCONV Prediction conversion
% {{{
%
% [oa] = PFP_PREDCONV(oa, ont);
%
%   Converts ontology annotation structure to another ontology.
%
% Note
% ----
% This function is used when the structure of an ontology has been changed,
% e.g., by removing one type of edges ('part_of'). If the conversion is meant to
% only a subset of the original ontology, use pfp_oaproj.m instead.
%
% 'eia' of the given oa will be removed due to the change of ontology structure.
%
% Input
% -----
% [struct]
% oa:   The ontology annotation structure.
%       See pfp_oabuild.m
%
% [struct]
% ont:  The ontology structure.
%       See pfp_ontbuild.m
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
% }}}

  % check inputs {{{
  if nargin ~= 2
    error('pfp_oaconv:InputCount', 'Expected 2 inputs.');
  end

  % check the 1st input 'oa' {{{
  validateattributes(oa, {'struct'}, {'nonempty'}, '', 'oa', 1);
  % }}}

  % check the 2nd input 'ont' {{{
  validateattributes(ont, {'struct'}, {'nonempty'}, '', 'ont', 2);
  % }}}
  % }}}

  % conversion {{{
  A = pfp_leafannot(oa); % get leaf annotation matrix
  [found, index] = ismember({ont.term.id}, {oa.ontology.term.id});
  A = A(:, index(found)); % re-order columns to match the new ontology
  oa.ontology   = ont;
  oa.annotation = pfp_annotprop(ont.DAG, A);
  % }}}

  % remove 'eia' {{{
  if isfield(oa, 'eia')
    oa = rmfield(oa, 'eia');
  end
  % }}}
return

% -------------
% Yuxiang Jiang (yuxjiang@indiana.edu)
% Department of Computer Science
% Indiana University, Bloomington
% Last modified: Sun 06 Mar 2016 05:28:40 PM E
