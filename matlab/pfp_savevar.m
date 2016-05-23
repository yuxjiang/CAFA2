function [] = pfp_savevar(ofile, vardata, varname)
%PFP_SAVEVAR Save variable
%
% [] = pfp_savevar(ofile, vardata, varname);
%
%   Save (or append if file exists) a variable to a file.
%
% Note
% ----
% Variable with the same name in the file will be replaced.
%
% Input
% -----
% [char]
% ofile:    The file name to which the variable will be saved.
%
% [(any)]
% vardata:  A matlab variable (data)
%
% (optional)
% [char]
% varname:  Assign a new name to the saved variable if needed.
%           It resort to inputname(vardata) if not given or given as empty.
%           default: ''
%
% Output
% ------
% None.

  % check inputs {{{
  if nargin < 2 || nargin > 3
    error('pfp_savevar:InputCount', 'Expected 2 or 3 inputs.');
  end

  if nargin == 2
    varname = '';
  end

  % ofile
  validateattributes(ofile, {'char'}, {'nonempty'}, '', 'ofile', 1);

  % vardata
  % the 2nd input 'vardata' is left without checking, any data is allowed.

  % varname
  validateattributes(varname, {'char'}, {}, '', 'varname', 3);
  % }}}

  % prepare varname {{{
  if isempty(varname)
    varname = inputname(2);
  end
  eval(sprintf('%s = vardata;', varname));
  % }}}

  % save / append {{{
  if exist(ofile, 'file')
    % if the file already exists, append the variable.
    save(ofile, varname, '-append');
  else
    save(ofile, varname, '-v7.3');
  end
  % }}}
return

% -------------
% Yuxiang Jiang (yuxjiang@indiana.edu)
% Department of Computer Science
% Indiana University, Bloomington
% Last modified: Thu 12 May 2016 05:29:45 PM E
