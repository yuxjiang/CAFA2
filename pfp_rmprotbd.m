function [oa] = pfp_rmprotbd(oa)
%PFP_RMPROTBD Remove protein binding
% {{{
%
% [oa] = PFP_RMPROTBD(oa);
%
%   Removes objects with "protein binding (GO:0005515)" as its unique
%   annotation.
%
% Input
% -----
% [struct]
% oa: The ontology annotation structure.
%
% Output
% ------
% [struct]
% oa: The updated ontology annotation structure.
%
% Dependency
% ----------
%[>]pfp_oabuild.m
%[>]pfp_ancestortermidx.m
% }}}

  % check inputs {{{
  % check the 1st argument 'oa' {{{
  validateattributes(oa, {'struct'}, {'nonempty'}, '', 'oa', 1);
  % check the 1st argument 'oa' }}}
  % check inputs }}}

  % find and remove objects {{{

  % mask out annotations to the terms that are ancestors of GO:0005515 
  % (protein binding). Any sequence has no annotation left should be removed.
  masked_oa = oa.annotation;
  masked_oa(:, pfp_ancestortermidx(oa.ontology, 'GO:0005515')) = false;

  keep = find(any(masked_oa, 2));

  oa.object     = oa.object(keep);
  oa.annotation = oa.annotation(keep, :);

  % update eia, re-estimate information accretion
  oa.eia  = pfp_eia(oa.ontology.DAG, oa.annotation);
  oa.date = date;
  % find and remove objects }}}
return

% -------------
% Yuxiang Jiang (yuxjiang@indiana.edu)
% Department of Computer Science
% Indiana University Bloomington
% Last modified: Tue 05 May 2015 11:13:57 AM E
