function [] = cafa_team_output_as_node(filename, team_cfg, top_mid)
%CAFA_TEAM_OUTPUT_AS_NODE CAFA team output as (network) node
% {{{
%
% [] = CAFA_TEAM_OUTPUT_AS_NODE(filename, team_cfg, top_mid);
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
% top_mid:  A cell array of top methods' ID. (Fmax)
%
%           See cafa_sel_top_seq_fmax.m
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

  % check the 3rd input 'top_mid' {{{
  validateattributes(top_mid, {'cell'}, {'nonempty'}, '', 'top_mid', 3);
  % }}}
  % }}}

  % output {{{
  header = 'Name\tType\tPI\tColor\tIS_TOP10\n';
  format = '%s\t%s\t%s\t#%s\t%s\n'; % team.name, team.type (q/d/b/n), team.pi, team.hex, is_top10?
  
  n = numel(team.iid);

  fprintf(fid, header);
  for i = 1 : n
    if ismember(team.iid{i}, top_mid)
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
% Last modified: Tue 28 Jul 2015 03:21:21 PM E
