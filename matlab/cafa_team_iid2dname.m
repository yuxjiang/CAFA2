function [dname] = cafa_team_iid2dname(reg, iid)
%CAFA_TEAM_IID2DNAME CAFA team internal ID to display name
%
% [dname] = CAFA_TEAM_IID2DNAME(reg, iid);
%
%   Returns the display name of a (list of) models.
%
% Input
% -----
% [char]
% reg:  The team information file.
%
%       Note: team register file which consists of 8 columns:
%       1. Method ID (internal ID, starts with 'M' for participating
%          methods and 'B' for baseline methods)
%       2. Method ID (external ID, each method should be aware of its own
%          external ID)
%       3. Team name
%       4. Type of the method
%       5. Display name of the method
%       6. Dump name of the method (possibly another name for its
%          appearance in the data dump.)
%       7. PI's name of the method/team
%       8. Keyword list of the method
%       9. Assigned color of the method/PI
%
% [cell or char]
% iid:  An internal ID or a list of internal IDs.
%
% Output
% ------
% [cell or char]
% dname:  The corresponding display name(s).
%
% Dependency
% ----------
%[>]cafa_team_register.m

  % check inputs {{{
  if nargin ~= 2
    error('cafa_team_iid2dname:InputCount', 'Expected 2 inputs.');
  end

  % reg
  validateattributes(reg, {'char'}, {'nonempty'}, '', 'reg', 1);
  fid = fopen(reg, 'r');
  if fid == -1
    error('cafa_team_register:FileErr', 'Cannot open the team file [%s].', reg);
  end

  % iid 
  validateattributes(iid, {'cell', 'char'}, {'nonempty'}, '', 'iid', 2);
  % }}}

  % convert id {{{
  [iids, ~, ~, ~, dnames] = cafa_team_register(reg);
  [found, index] = ismember(iid, iids);
  if ~all(found)
    error('cafa_team_iid2dname:IDErr', 'Invalid internal ID.');
  end

  if iscell(iid)
    dname = reshape(dnames(index), 1, []);
  else
    dname = dnames{index};
  end
  % }}}
return

% -------------
% Yuxiang Jiang (yuxjiang@indiana.edu)
% Department of Computer Science
% Indiana University, Bloomington
% Last modified: Mon 23 May 2016 03:46:07 PM E
