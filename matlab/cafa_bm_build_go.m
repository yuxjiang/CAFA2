function [bm] = cafa_bm_build_go(gont, raw_goa0, raw_goa1)
%CAFA_BM_BUILD_GO CAFA benchmark build go
% {{{
%
% [bm] = CAFA_BM_BUILD_GO(gont, raw_goa0, raw_goa1);
%
%   Makes a GO benchmark by comparing ontology annotations of T0 and T1.
%
% Input
% -----
% [struct]
% gont:       The Gene ontology structure.
%             It must contain the three ontologies as its fields.
%             i.e., .MFO, .BPO, .CCO
%
%             See pfp_ontbuild.m.
%
% [char]
% raw_goa0:   Raw annotation file for T0 annotations. Format:
%             <UniProtKB Accession> <GO term ID> <Ontology tag: F/P/C>
%
% [char]
% raw_goa1:   Raw annotation file for T1 annotations.
%
% Output
% ------
% [struct]
% bm:         Benchmark protein list (in UniProtKB accession number).
%
%             [cell]
%             .type1_mfo  - type1 benchmark for molecular function
%             .type1_bpo  - type1 benchmark for biological process
%             .type1_cco  - type1 benchmark for cellular component
%             .type2_mfo  - type2 benchmark for molecular function
%             .type2_bpo  - type2 benchmark for biological process
%             .type2_cco  - type2 benchmark for cellular component
%
%             Note
%             ----
%             type 1: For a protein to be qualified as type 1, it must have no
%             annotation at all by T0 (among any of the three GO ontologies).
%
%             type 2: For a protein to be qualified as type 2, it must have no
%             annotation on the one of interest, but have some annotations on
%             the other two ontologies. For example, if protein A is in type 2
%             benchmark for MFO, is must have no annotation on MFO by T0, but
%             not restrictions on its annotation on BPO or CCO. however, it must
%             have some annotations on either one of the other two, otherwise,
%             it should be in type 1 benchmark.
%
% Dependency
% ----------
%[>]pfp_ontbuild.m
%[>]pfp_oabuild.m
%[>]pfp_rmprotbd.m
% }}}

  % split the raw annotation files. {{{
  fprintf('Splitting raw annotation files ... ');
  awk_cmd_mfo ='awk -F''\t'' ''{if ($3 == "F") print $1"\t"$2}'' '; 
  awk_cmd_bpo ='awk -F''\t'' ''{if ($3 == "P") print $1"\t"$2}'' '; 
  awk_cmd_cco ='awk -F''\t'' ''{if ($3 == "C") print $1"\t"$2}'' '; 

  system([awk_cmd_mfo, raw_goa0, ' > /tmp/cafa_bm_mfo_t0']);
  system([awk_cmd_bpo, raw_goa0, ' > /tmp/cafa_bm_bpo_t0']);
  system([awk_cmd_cco, raw_goa0, ' > /tmp/cafa_bm_cco_t0']);

  system([awk_cmd_mfo, raw_goa1, ' > /tmp/cafa_bm_mfo_t1']);
  system([awk_cmd_bpo, raw_goa1, ' > /tmp/cafa_bm_bpo_t1']);
  system([awk_cmd_cco, raw_goa1, ' > /tmp/cafa_bm_cco_t1']);
  fprintf('done.\n');
  % }}}

  % Build ontology annotation structures (map to the given ontology) {{{
  % See pfp_oabuild.m for structure details.
  fprintf('Building ontology annotation structures ... ');
  T0.mfoa = pfp_oabuild(gont.MFO, '/tmp/cafa_bm_mfo_t0');
  T0.bpoa = pfp_oabuild(gont.BPO, '/tmp/cafa_bm_bpo_t0');
  T0.ccoa = pfp_oabuild(gont.CCO, '/tmp/cafa_bm_cco_t0');

  T1.mfoa = pfp_oabuild(gont.MFO, '/tmp/cafa_bm_mfo_t1');
  T1.bpoa = pfp_oabuild(gont.BPO, '/tmp/cafa_bm_bpo_t1');
  T1.ccoa = pfp_oabuild(gont.CCO, '/tmp/cafa_bm_cco_t1');
  fprintf('done.\n');
  % }}}

  % Remove proteins whose deepest annotation is 'protein binding' {{{
  fprintf('Removing ''protein binding'' annotation (MFO only) ... ');
  T0.mfoa =  pfp_rmprotbd(T0.mfoa);
  T1.mfoa =  pfp_rmprotbd(T1.mfoa);
  fprintf('done.\n');
  % }}}

  fprintf('Constructing benchmarks ... '); % {{{
  % type 1 benchmark proteins
  T0_all = unique(vertcat(T0.mfoa.object, T0.bpoa.object, T0.ccoa.object));
  bm.type1_mfo = setdiff(T1.mfoa.object, T0_all);
  bm.type1_bpo = setdiff(T1.bpoa.object, T0_all);
  bm.type1_cco = setdiff(T1.ccoa.object, T0_all);

  % type 2 benchmark proteins
  bm.type2_mfo = setdiff(setdiff(T1.mfoa.object, T0.mfoa.object), bm.type1_mfo);
  bm.type2_bpo = setdiff(setdiff(T1.bpoa.object, T0.bpoa.object), bm.type1_bpo);
  bm.type2_cco = setdiff(setdiff(T1.ccoa.object, T0.ccoa.object), bm.type1_cco);
  fprintf('done.\n');
  % }}}
return

% -------------
% Yuxiang Jiang (yuxjiang@indiana.edu)
% Department of Computer Science
% Indiana University Bloomington
% Last modified: Fri 17 Jul 2015 11:00:53 AM E
