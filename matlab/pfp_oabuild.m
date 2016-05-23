function [oa] = pfp_oabuild(ont, afile, varargin)
%PFP_OABUILD Ontology annotation build
%
% [oa] = PFP_OABUILD(ont, afile[, afile_2, ...]);
%
%   Builds an ontology annotation structure from data file(s).
%
% Note
% ----
% Annotations with invalid terms will be ignored.
%
% Input
% -----
% (required)
% [struct]
% ont:      The ontology structure. See pfp_ontbuild.m
%
% [char]
% afile:    An annotation file, which has two columns splitted by TAB.
%           <object ID> <term ID>
%
% (optional)
% [cell]
% varargin: Additional annotation files.
%
% Output
% ------
% [struct]
% oa: The ontology annotation structure, which has the following fields:
%     .object     [cell]    Object ID array, of type "char". ID here could
%                           typically be strings that identify objects in a
%                           database: e.g., UniProt protein accessions.
%     .ontology   [struct]  The ontology structure passed through from the
%                           inputs.
%     .annotation [logical] A (sparse) binary matrix where annotation(i, j) =
%                           true indicates the association between object i
%                           and term j.
%     .date       [char]    The date when it's been built.
%
% Dependency
% ----------
%[>]pfp_getterm.m
%[>]pfp_annotprop.m
%
% See Also
% --------
%[>]pfp_ontbuild.m

  % check inputs {{{
  % ont
  validateattributes(ont, {'struct'}, {'nonempty'}, '', 'ont', 1);

  % afile
  validateattributes(afile, {'char'}, {'nonempty'}, '', 'afile', 2);
  if ~exist(afile, 'file')
    error('pfp_oabuild:FileErr', 'File [%s] doesn''t exist.', afile);
  end
  afiles = cell(1, 1 + numel(varargin));
  afiles{1} = afile;

  % varargin
  for i = 1 : numel(varargin)
    validateattributes(varargin{i}, {'char'}, {'nonempty'}, '', 'varargin', 3);
    if ~exist(varargin{i}, 'file')
      error('pfp_oabuild:FileErr', 'File [%s] doesn''t exist.', varargin{i});
    end
    afiles{i+1} = varargin{i};
  end
  % }}}

  % read ontology annotation data file(s) {{{
  plain_oa   = loc_oaread(afiles); % See below for local function definination
  valid_term = pfp_getterm(ont, plain_oa.term_id);

  % invalid terms will have an empty string, '', as its ID (place-holder),
  dummy = find(cellfun(@length, {valid_term.id}) == 0);
  if numel(dummy) > 0
    warning('pfp_oabuild:InvalidID', 'Found [%d] invalid term ID(s).', numel(dummy));

    % remove those dummy terms.
    valid_term(dummy) = [];

    % update 'plain_oa' accordingly
    plain_oa.term_id(dummy)  = [];
    plain_oa.annot(:, dummy) = [];
  end
  % }}}

  % build oa structure {{{
  oa.object     = plain_oa.obj_id;
  oa.ontology   = ont;
  oa.annotation = logical(sparse(numel(oa.object), numel(ont.term)));

  % map valid_term.id to the ontology term list those terms have been mapped
  % already above, so all should be found
  [~, index] = ismember({valid_term.id}, {ont.term.id});

  % alternative term IDs will share the same index, in which case, we have to
  % take the union of annotations on those terms. Thus, the union will be saved
  % as two exact copy (columns) corresponding to each of the alternative IDs.
  uindex = unique(index);
  for i = 1 : numel(uindex)
    alt_cols = find(index == uindex(i));
    if numel(alt_cols) > 1
      % take the union and overwrite
      col = any(plain_oa.annot(:, alt_cols), 2);
      plain_oa.annot(:, alt_cols) = repmat(col, 1, numel(alt_cols));
    end
  end

  oa.annotation(:, index) = plain_oa.annot ~= 0;

  % remove objects with no annotations
  zero_annot = sum(oa.annotation, 2) == 0;
  oa.annotation(zero_annot, :) = [];
  oa.object(zero_annot) = [];

  oa.annotation = pfp_annotprop(oa.ontology.DAG, oa.annotation);
  oa.date       = datestr(now, 'mm/dd/yyyy HH:MM');
  % }}}
return

% function: loc_oaread {{{
function [plain_oa] = loc_oaread(afiles)
% [plain_oa] = LOC_OAREAD(afiles);
%
%   Reads plain ontology annotation file(s) into a plain oa structure
%
% Input
% -----
% [char]
% afiles:   plain ontology annotation file, in the following format
%           <object ID> <term ID>
%
% Output
% ------
% [struct]
% plain_oa: ontology annotation, which has
%           .obj_id   [cell]    gene product ID, having length n.
%           .term_id  [cell]    GO term ID, having length m.
%           .annot    [logical] a sparse binary matrix, with size n-by-m.

  gp = {};
  tm = {};
  for i = 1 : numel(afiles)
    fid  = fopen(afiles{i}, 'r');
    data = textscan(fid, '%s%s', 'Delimiter', '\t');
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
% }}}

% -------------
% Yuxiang Jiang (yuxjiang@indiana.edu)
% Department of Computer Science
% Indiana University Bloomington
% Last modified: Thu 12 May 2016 03:26:35 PM E
