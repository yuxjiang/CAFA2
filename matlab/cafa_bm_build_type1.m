function [bm] = cafa_bm_build_type1(ont, raw_oa0, raw_oa1)
%CAFA_BM_BUILD_TYPE1 CAFA benchmark build type1
%
% [bm] = CAFA_BM_BUILD_TYPE1(ont, raw_oa0, raw_oa1);
%
%   Makes a benchmark by comparing ontology annotations of T0 and T1.
%
% Note
% ----
% Type1: no-knowledge benchmarks.
% This scripts is typically used by constructing HPO benchmarks.
%
% Input
% -----
% [struct]
% ont:      The ontology structure. See pfp_ontbuild.m
%
% [char]
% raw_oa0:  Raw annotation file for T0 annotations. Format:
%           <UniProtKB Accession> <term ID>
%
% [char]
% raw_oa1:  Raw annotation file for T1 annotations. Same format as raw_oa0.
%
% Output
% ------
% [cell]
% bm:       Benchmark protein list (in UniProtKB accession number).
%
% Dependency
% ----------
%[>]pfp_oabuild.m
%
% See Also
% --------
%[>]pfp_ontbuild.m

  % check inputs {{{
  if nargin ~= 3
    error('cafa_bm_build_type1:InputCount', 'Expected 3 inputs.');
  end

  % ont
  validateattributes(ont, {'struct'}, {'nonempty'}, '', 'ont', 1);

  % raw_oa0
  validateattributes(raw_oa0, {'char'}, {'nonempty'}, '', 'raw_oa0', 2);

  % raw_oa1
  validateattributes(raw_oa1, {'char'}, {'nonempty'}, '', 'raw_oa1', 3);
  % }}}

  % build benchmark {{{
  % Build ontology annotation structures (map to the given ontology)
  % See pfp_oabuild.m for structure details.
  T0 = pfp_oabuild(ont, raw_oa0);
  T1 = pfp_oabuild(ont, raw_oa1);

  bm = setdiff(T1.object, T0.object);
  % }}}
return

% -------------
% Yuxiang Jiang (yuxjiang@indiana.edu)
% Department of Computer Science
% Indiana University Bloomington
% Last modified: Mon 23 May 2016 06:43:03 PM E
