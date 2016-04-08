function [] = cafa_save_pred_pcc(ofile, ps, cutoff, reg, eval_dir)
%CAFA_SAVE_PRED_PCC CAFA save prediction's pairwise PCC (as a network)
% {{{
%
% [] = CAFA_SAVE_PRED_PCC(ofile, ps, cutoff, reg, eval_dir);
%
%   Outputs two files (node, edge) to form a network using PCC as edges.
%
% Note
% ----
% This function is used to generate node descriptions for drawing networks of
% prediction correlations.
%
% Input
% -----
% [char]
% ofile:    The output file name. The actual pairs of outputs becomes:
%           <ofile>; /path/to/file.ext -->
%           node: /path/to/file_node.ext
%           edge: /path/to/file_edge.ext
%
% [struct]
% ps:       The precomputed PCC structure.
%           See cafa_get_pred_pcc.m
%
% [double]
% cutoff:   The cutoff of PCC, below which the edge will be ignored.
%           Often: 0.75;
%
% [char]
% reg:      The register file.
%           See cafa_team_register.m
%
% [cell]
% eval_dir: The evaluation directory containing evaluation results.
%
% Output
% ------
% None.
%
% Dependency
% ----------
%[>]cafa_team_register.m
%[>]cafa_sel_top_seq_fmax.m
%
% See Also
% --------
%[>]cafa_get_pred_pcc.m
% }}}

  % check inputs {{{
  if nargin ~= 5
    error('cafa_save_pred_pcc:InputCount', 'Expected 5 inputs.');
  end

  % check the 1st input 'ofile' {{{
  validateattributes(ofile, {'char'}, {'nonempty'}, '', 'ofile', 1);

  [p, f, e] = fileparts(ofile);
  ofile_node = fullfile(p, strcat(f, '_node', e));
  ofile_edge = fullfile(p, strcat(f, '_edge', e));
  fid_node = fopen(ofile_node, 'w');
  if fid_node == -1
    error('cafa_save_pred_pcc:FileErr', 'Cannot open the node file [%s].', ofile_node);
  end
  % }}}

  % check the 2nd input 'ps' {{{
  validateattributes(ps, {'struct'}, {'nonempty'}, '', 'ps', 2);
  % }}}

  % check the 3rd input 'cutoff' {{{
  validateattributes(cutoff, {'double'}, {'>', -1, '<', 1}, '', 'cutoff', 3);
  % }}}

  % check the 4th input 'reg' {{{
  validateattributes(reg, {'char'}, {'nonempty'}, '', 'reg', 4);
  [model.id, ~, model.nm, model.tp, ~, ~, model.pi, ~, model.cl] = cafa_team_register(reg);
  % }}}

  % check the 5th input 'eval_dir' {{{
  validateattributes(eval_dir, {'char'}, {'nonempty'}, '', 'eval_dir', 5);
  % }}}
  % }}}

  % find participated and top methods {{{
  fmaxs = cafa_collect(eval_dir, 'seq_fmax_bst');

  % get mid of top 10 methods
  % use dummy tag '.' for baseline methods
  [~, ~, info] = cafa_sel_top_seq_fmax(10, fmaxs, '', '', reg, false);

  n = numel(fmaxs);
  mid = cell(1, n);
  covered = false(1, n);
  for i = 1 : n
    mid{i}     = fmaxs{i}.id;
    covered(i) = nanmean(fmaxs{i}.ncovered_bst) > 0;
  end
  % removed un-participated methods
  mid(~covered) = [];
  participated = ismember(model.id, mid);
  model.id(~participated) = []; % ID
  model.nm(~participated) = []; % name
  model.tp(~participated) = []; % type (status)
  model.pi(~participated) = []; % PI
  model.cl(~participated) = []; % color (in HEX)
  % }}}

  % remove testing models and unused baseline models: B[BN]1S (if presented) {{{
  ub = cell2mat(cellfun(@(x) ~isempty(regexp(x, 'B[BN]1S')), model.id, 'UniformOutput', false));
  ts = strcmp(model.tp, 'x');
  remove = ub | ts;
  model.id(remove) = []; % ID
  model.nm(remove) = []; % name
  model.tp(remove) = []; % type (status)
  model.pi(remove) = []; % PI
  model.cl(remove) = []; % color (in HEX)
  % }}}

  % output nodes {{{
  header = 'Name\tType\tPI\tColor\tIS_TOP10\n';
  % format: model.nm, model.tp (q/d/x/b/n), model.pi, model.cl, is_top10?
  format = '%s\t%s\t%s\t#%s\t%s\n';

  n = numel(model.id);
  fprintf(fid_node, header);
  for i = 1 : n
    if strcmp(model.tp{i}, 'x')
      % skip testing methods.
      continue;
    end
    if ismember(model.id{i}, info.top_mid)
      is_top10 = 'YES';
    else
      is_top10 = 'NO';
    end
    fprintf(fid_node, format, model.nm{i}, model.tp{i}, model.pi{i}, model.cl{i}, is_top10);
  end
  fclose(fid_node);
  % }}}

  % output ("node-induced") sub network {{{
  [found, index] = ismember(model.id, ps.mid);
  pcc_net.object = model.nm(found);
  pcc_net.ADJ    = ps.pcc(index(found), index(found));
  pfp_savenet(ofile_edge, pcc_net, cutoff);
  % }}}
return

% -------------
% Yuxiang Jiang (yuxjiang@indiana.edu)
% Department of Computer Science
% Indiana University, Bloomington
% Last modified: Thu 07 Apr 2016 11:39:19 PM E
