function [oa] = pfp_oabuild(ont, afile, varargin)
%PFP_OABUILD Ontology annotation build
% {{{
%
% [oa] = PFP_OABUILD(ont, afile[, afile_2, ...]);
%
%   Builds an ontology annotation structure from data file(s).
%
%   Note:
%   Annotations with unmatched term IDs will be ignored.
%
% Input
% -----
% [struct]
% ont:      The ontology structure.
%
% [char]
% afile:    An annotation data file. This function assumes that the data
%           file contains two columns:
%
%           <object id> <term id>
%
% (optional)
% [cell]
% varargin: Additional data files.
%
% Output
% ------
% [struct]
% oa:       The ontology annotation structure, which has
%           [cell]
%           .object     (char) object ID array, of char type, ID here could 
%                       be string that identifies an object e.g., HGNC ID
%                       for genes, UniProt accession for proteins.
%
%           [struct]
%           .ontology   The ontology structure.
%
%           [logical and sparse]
%           .annotation Annotation(i, j) = true means object i and term j
%                       are associated.
%
%           [double]
%           .eia        The estimated information accretion for each term.
%
%           [char]
%           .date       When it's been built.
%
% Dependency
% ----------
%[>]pfp_ontbuild.m
%[>]pfp_getterm.m
%[>]pfp_annotprop.m
% }}}

  % check inputs {{{
  % check the 1st argument 'ont' {{{
  validateattributes(ont, {'struct'}, {'nonempty'}, '', 'ont', 1);
  % check the 1st argument 'ont' }}}

  % check the 2nd argument 'afile' {{{
  validateattributes(afile, {'char'}, {'nonempty'}, '', 'afile', 2);
  if ~exist(afile, 'file')
      error('pfp_oabuild:FileErr', 'File [%s] doesn''t exist.', afile);
  end
  afiles = cell(1, 1 + numel(varargin));
  afiles{1} = afile;
  % check the 2nd argument 'afile' }}}

  % check additional arguments 'varargin' {{{
  for i = 1 : numel(varargin)
      validateattributes(varargin{i}, {'char'}, {'nonempty'}, '', 'varargin', 3);
      if ~exist(varargin{i}, 'file')
          error('pfp_oabuild:FileErr', 'File [%s] doesn''t exist.', varargin{i});
      end
      afiles{i + 1} = varargin{i};
  end
  % check additional arguments 'varargin' }}}
  % check inputs }}}

  % read ontology annotation data file(s) {{{
  plain_oa = oaread(afiles); % See below for definination

  matched_term = pfp_getterm(ont, plain_oa.term_id);
  [found, index] = ismember({matched_term.id}, {ont.term.id});
  if ~all(found)
    warning('pfp_oabuild:InvalidID', 'Found [%d] invalid term ID(s).', sum(~found));
  end

  plain_oa.annot(:, ~found) = [];
  % read ontology annotation data file(s) }}}

  % build oa structure {{{
  oa.object     = plain_oa.obj_id;
  oa.ontology   = ont;
  oa.annotation = logical(sparse(numel(oa.object), numel(ont.term)));
  oa.annotation(:, index(found)) = plain_oa.annot ~= 0;

  % remove objects with no annotations
  zero_annot = sum(oa.annotation, 2) == 0;
  oa.annotation(zero_annot, :) = [];
  oa.object(zero_annot) = [];

  oa.annotation = pfp_annotprop(oa.ontology.DAG, oa.annotation);
  oa.eia        = pfp_eia(oa.ontology.DAG, oa.annotation);
  oa.date       = date;
  % build oa structure }}}
return

% function: oaread {{{
function [plain_oa] = oaread(afiles)
%OAREAD Ontology annotation read {{{
%
% [plain_oa] = OAREAD(afiles);
%
%   Reads plain ontology annotation file(s) into a plain oa structure
%
% Input
% -----
% [char]
% afiles:   plain ontology annotation file, in the following format
%
%           <object ID> <ontology term ID>
%
% Output 
% ------
% [struct]
% plain_oa: ontology annotation, which has
%           .obj_id     - gene product ID, having length n.
%           .term_id    - GO term ID, having length m.
%           .annot      - a sparse binary matrix, with size n-by-m.
% }}}

  gp = {};
  tm = {};
  for i = 1 : numel(afiles)
    fid  = fopen(afiles{i}, 'r');
    data = textscan(fid, '%s%s', 'delimiter', '\t');
    fclose(fid);

    gp = [gp; data{1}];
    tm = [tm; data{2}];
  end

  plain_oa.obj_id  = unique(gp);
  plain_oa.term_id = unique(tm);
  [~, indexO]      = ismember(gp, plain_oa.obj_id);
  [~, indexT]      = ismember(tm, plain_oa.term_id);
  plain_oa.annot   = sparse(indexO, indexT, 1, numel(plain_oa.obj_id), numel(plain_oa.term_id));
  plain_oa.annot   = logical(plain_oa.annot);
return
% function: oaread }}}

% -------------
% Yuxiang Jiang (yuxjiang@indiana.edu)
% Department of Computer Science
% Indiana University Bloomington
% Last modified: Sat 16 May 2015 06:02:28 PM E
