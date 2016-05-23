function [idx] = pfp_roottermidx(ont)
%PFP_ROOTTERMIDX Root term index
%
% [idx] = PFP_ROOTTERMIDX(ont);
%
%   Returns the index of root term(s) of an ontology.
%
% Input
% -----
% [struct]
% ont:  The ontology structure. See pfp_ontbuild.m
%
% Output
% ------
% [double]
% idx:  The index of the root(s).
%
% See Also
% --------
%[>]pfp_ontbuild.m

  % check inputs {{{
  if nargin ~= 1
    error('pfp_roottermidx:InputCount', 'Expected 1 input.');
  end

  % ont
  validateattributes(ont, {'struct'}, {'nonempty'}, '', 'ont', 1);
  % }}}

  % root term index {{{
  idx = reshape(find(~any(ont.DAG ~= 0, 2)), 1, []);
  % }}}
return

% -------------
% Yuxiang Jiang (yuxjiang@indiana.edu)
% Department of Computer Science
% Indiana University Bloomington
% Last modified: Mon 23 May 2016 06:50:42 PM E
