function [oa] = pfp_rmprotbd(oa)
%PFP_RMPROTBD Remove protein binding
%
% [oa] = PFP_RMPROTBD(oa);
%
%   Removes objects with "protein binding (GO:0005515)" as their exclusive
%   annotation.
%
% Input
% -----
% [struct]
% oa: The ontology annotation structure. See pfp_oabuild.m
%
% Output
% ------
% [struct]
% oa: The updated ontology annotation structure.
%
% Dependency
% ----------
%[>]pfp_ancestortermidx.m
%
% See Also
% --------
%[>]pfp_oabuild.m

  % check inputs {{{
  if nargin ~= 1
    error('pfp_rmprotbd:InputCount', 'Expected 1 input.');
  end

  % oa
  validateattributes(oa, {'struct'}, {'nonempty'}, '', 'oa', 1);
  % }}}

  % find and remove objects {{{
  % mask out annotations to the terms that are ancestors of GO:0005515
  % (protein binding). Any sequence has no annotation left should be removed.
  masked_oa = oa.annotation;
  masked_oa(:, pfp_ancestortermidx(oa.ontology, 'GO:0005515')) = false;
  keep = find(any(masked_oa, 2));

  oa.object     = oa.object(keep);
  oa.annotation = oa.annotation(keep, :);
  oa.date       = datestr(now, 'mm/dd/yyyy HH:MM');
  % }}}
return

% -------------
% Yuxiang Jiang (yuxjiang@indiana.edu)
% Department of Computer Science
% Indiana University Bloomington
% Last modified: Thu 12 May 2016 03:48:55 PM E
