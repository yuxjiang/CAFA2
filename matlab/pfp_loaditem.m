function [items] = pfp_loaditem(filename, data_type)
%PFP_LOADITEM Load item
% {{{
%
% [items] = PFP_LOADITEM(filename, data_type);
%
%   Loads data from a file (one data item per line).
%
% Input
% -----
% [char]
% filename:   The data file name.
%
% [char]
% data_type:  The type of the data, could be 'char' or 'numeric'.
%
% Output
% ------
% [cell or double]
% items:      The resuling data holder, types depends on 'data_type'.
% }}}

  % check inputs {{{
  if nargin ~= 2
    error('pfp_loaditem:InputCount', 'Expected 2 inputs.');
  end

  % check the 1st input 'filename' {{{
  validateattributes(filename, {'char'}, {'nonempty'}, '', 'filename', 1);
  fid = fopen(filename, 'r');
  if fid == -1
    error('pfp_loaditem:FileErr', 'Cannot open [%s].', filename);
  end
  % }}}

  % check the 2nd input 'data_type' {{{
  validateattributes(data_type, {'char'}, {'nonempty'}, '', 'data_type', 2);
  dtype = validatestring(data_type, {'char', 'numeric'});
  % }}}
  % }}}

  % load data {{{
  switch dtype
  case 'char'
    data = textscan(fid, '%s');
    items = data{1};
  case 'numeric'
    data = textscan(fid, '%f');
    items = data{1};
  otherwise
    % do noting
    items = [];
  end
  fclose(fid);
  % }}}
return

% -------------
% Yuxiang Jiang (yuxjiang@indiana.edu)
% Department of Computer Science
% Indiana University Bloomington
% Last modified: Fri 26 Feb 2016 02:42:03 AM E
