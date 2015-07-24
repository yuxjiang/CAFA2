function [iid, eid, tname, ttype, dname, pname] = cafa_team_read_config(team_file)
%CAFA_TEAM_READ_CONFIG CAFA team read config
% {{{
%
% [iid, eid, tname, ttype, dname, pname] = CAFA_TEAM_READ_CONFIG(team_file);
%
%   Reads and parses team information file.
%
% Input
% -----
% [char]
% team_file:  The team information file.
%
% Output
% ------
% [cell]
% iid:    internal model id
%
% [cell]
% eid:    external model id
%
% [cell]
% tname:  registered team name
%
% [cell]
% ttype:  qualified/disqualified/naive/blast
%
% [cell]
% dname:  model name to display
%
% [cell]
% pname:  PI name
% }}}

  % check inputs {{{
  if nargin ~= 1
    error('cafa_team_read_config:InputCount', 'Expected 1 input.');
  end

  % check the 1st input 'team_file' {{{
  validateattributes(team_file, {'char'}, {'nonempty'}, '', 'team_file', 1);
  fid = fopen(team_file, 'r');
  if fid == -1
    error('cafa_team_read_config:FileErr', 'Cannot open the team file [%s].', team_file);
  end
  % }}}
  % }}}

  % read and parse {{{
  team = textscan(fid, '%s%s%s%s%s%s', 'HeaderLines', 1, 'Delimiter', '\t');
  fclose(fid);

  iid   = team{1};
  eid   = team{2};
  tname = team{3};
  ttype = team{4};
  dname = team{5};
  pname = team{6};
  % }}}
return

% -------------
% Yuxiang Jiang (yuxjiang@indiana.edu)
% Department of Computer Science
% Indiana University, Bloomington
% Last modified: Fri 24 Jul 2015 11:54:42 AM E
