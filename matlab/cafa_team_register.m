function [iid, eid, tname, ttype, dname, dname2, pname, kw, chex] = cafa_team_register(reg)
%CAFA_TEAM_REGISTER CAFA team register
%
% [iid, eid, tname, ttype, dname, pname, kw, chex, dname2] = CAFA_TEAM_REGISTER(reg);
%
%   Reads and parses team information file.
%
% Input
% -----
% [char]
% reg:  The team register information file, which has 8 columns:
%       1. Method ID
%          Internal ID, starts with 'M' for participating methods and 'B' for
%          baseline methods.
%       2. Method ID
%          External ID, each method should be aware of its own external ID.
%       3. Team name
%          The "full" name, format: <team>[-<method>][(<model>)].
%       4. Type of the method
%          Indicates its status, qualified/disqualified/test/baseline
%       5. Display name of the method
%       6. Dump name of the method
%          The name for its appearance in the data dump.
%       7. PI's name of the method/team
%       8. Keyword list of the method
%       9. Assigned color of the method/PI
%
% Output
% ------
% [cell]
% iid:    The internal model id.
%
% [cell]
% eid:    The external model id.
%
% [cell]
% tname:  The registered team name.
%
% [cell]
% ttype:  One of qualified, disqualified, naive, or blast.  possible values:
%         'q' qualified
%         'd' disqualified
%         'x' for testing
%         'n' Naive baseline
%         'b' BLAST baseline
%
% [cell]
% dname:  The model name to display.
%
% [cell]
% dname2: The dump name for Data dump.
%
% [cell]
% pname:  The PI name.
%
% [cell]
% kw:     The keywords list. Separated by comma.
%
% [cell]
% chex:   Assigned color for the method. (a distinct color for each PI) RGB
%         value in HEX.

  % check inputs {{{
  if nargin ~= 1
    error('cafa_team_register:InputCount', 'Expected 1 input.');
  end

  % reg
  validateattributes(reg, {'char'}, {'nonempty'}, '', 'reg', 1);
  fid = fopen(reg, 'r');
  if fid == -1
    error('cafa_team_register:FileErr', 'Cannot open the team file [%s].', reg);
  end
  % }}}

  % read and parse {{{
  fmt = repmat('%s', 1, 9);
  team = textscan(fid, fmt, 'HeaderLines', 1, 'Delimiter', '\t');
  fclose(fid);

  iid    = team{1};
  eid    = team{2};
  tname  = team{3};
  ttype  = team{4};
  dname  = team{5};
  dname2 = team{6};
  pname  = team{7};
  kw     = team{8};
  chex   = team{9};
  % }}}
return

% -------------
% Yuxiang Jiang (yuxjiang@indiana.edu)
% Department of Computer Science
% Indiana University, Bloomington
% Last modified: Mon 23 May 2016 03:46:44 PM E
