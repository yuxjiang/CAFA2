function [] = cafa_team_output_as_node(filename, team_cfg, eval_dir)
%CAFA_TEAM_OUTPUT_AS_NODE CAFA team output as (network) node
% {{{
%
% [] = CAFA_TEAM_OUTPUT_AS_NODE(filename, team_cfg, eval_dir);
%
%   Outputs a tab-split-value file describes teams as network nodes.
%
% Input
% -----
% [char]
% filename: The output file name.
%
% [char]
% team_cfg: The team configuration file.
%
%           See cafa_team_read_config.m
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
%[>]cafa_team_read_config.m
%[>]cafa_sel_top_seq_fmax.m
% }}}

  % check inputs {{{
  if nargin ~= 3
    error('cafa_team_output_as_node:InputCount', 'Expected 3 inputs.');
  end

  % check the 1st input 'filename' {{{
  validateattributes(filename, {'char'}, {'nonempty'}, '', 'filename', 1);
  fid = fopen(filename, 'w');
  if fid == -1
    error('cafa_team_output_as_node:FileErr', 'Cannot open the output file [%s].', filename);
  end
  % }}}

  % check the 2nd input 'team_cfg' {{{
  validateattributes(team_cfg, {'char'}, {'nonempty'}, '', 'team_cfg', 2);
  [team.iid, team.eid, team.name, team.type, team.display, team.pi, team.kw, team.hex] = cafa_team_read_config(team_cfg);
  % }}}

  % check the 3rd input 'eval_dir' {{{
  validateattributes(eval_dir, {'char'}, {'nonempty'}, '', 'eval_dir', 3);
  % }}}
  % }}}

  % find participated and top methods {{{
  fmaxs = cafa_collect(eval_dir, 'seq_fmax_bst');

  % get mid of top 10 methods
  % use dummy tag '.' for baseline methods
  [~, ~, info] = cafa_sel_top_seq_fmax(10, fmaxs, '.', '.', team_cfg);

  n = numel(fmaxs);
  mid     = cell(1, n);
  covered = false(1, n);
  for i = 1 : n
    mid{i}     = fmaxs{i}.id;
    covered(i) = nanmean(fmaxs{i}.ncovered_bst) > 0;
  end
  % removed un-participated methods
  mid(~covered) = [];
  participated = ismember(team.iid, mid);
  team.iid(~participated)     = [];
  team.eid(~participated)     = [];
  team.name(~participated)    = [];
  team.type(~participated)    = [];
  team.display(~participated) = [];
  team.pi(~participated)      = [];
  team.kw(~participated)      = [];
  team.hex(~participated)     = [];
  % }}}

  % output {{{
  header = 'Name\tType\tPI\tColor\tIS_TOP10\n';
  % format: team.name, team.type (q/d/b/n), team.pi, team.hex, is_top10?
  format = '%s\t%s\t%s\t#%s\t%s\n';
  
  n = numel(team.iid);

  fprintf(fid, header);
  for i = 1 : n
    if ismember(team.iid{i}, info.top_mid)
      is_top10 = 'YES';
    else
      is_top10 = 'NO';
    end
    fprintf(fid, format, team.name{i}, team.type{i}, team.pi{i}, team.hex{i}, is_top10);
  end
  fclose(fid);
  % }}}
return

% -------------
% Yuxiang Jiang (yuxjiang@indiana.edu)
% Department of Computer Science
% Indiana University, Bloomington
% Last modified: Tue 28 Jul 2015 04:45:33 PM E
