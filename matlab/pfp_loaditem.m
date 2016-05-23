function [items] = pfp_loaditem(ifile, dtype)
%PFP_LOADITEM Load item
%
% [items] = PFP_LOADITEM(ifile, dtype);
%
%   Loads data from a file (one data item per line).
%
% Input
% -----
% [char]
% ifile:  The data file name.
%
% [char]
% dtype:  The type of the data, could be 'char' or 'numeric'.
%
% Output
% ------
% [cell or double]
% items:  The resuling data holder, types depends on 'dtype'.

  % check inputs {{{
  if nargin ~= 2
    error('pfp_loaditem:InputCount', 'Expected 2 inputs.');
  end

  % ifile
  validateattributes(ifile, {'char'}, {'nonempty'}, '', 'ifile', 1);
  fid = fopen(ifile, 'r');
  if fid == -1
    error('pfp_loaditem:FileErr', 'Cannot open [%s].', ifile);
  end

  % dtype
  validateattributes(dtype, {'char'}, {'nonempty'}, '', 'dtype', 2);
  dtype = validatestring(dtype, {'char', 'numeric'});
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
% Last modified: Thu 12 May 2016 05:32:46 PM E
