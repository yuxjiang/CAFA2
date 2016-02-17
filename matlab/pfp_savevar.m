function [] = pfp_savevar(filename, var, varname)
%PFP_SAVEVAR Save variable
% {{{
%
% [] = pfp_savevar(filename, var, varname);
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
% filename: The file name to which the variable will be saved.
%
% [(any)]
% var:      A matlab variable (data)
%
% (optional)
% [char]
% varname:  Assign a new name to the saved variable if needed.
%           It resort to inputname(var) if not given or given as empty.
%           default: ''
%
% Output
% ------
% None.
% }}}

  % check inputs {{{
  if nargin < 2 || nargin > 3
    error('pfp_savevar:InputCount', 'Expected 2 or 3 inputs.');
  end

  if nargin == 2
    varname = '';
  end

  % check the 1st input 'filename' {{{
  validateattributes(filename, {'char'}, {'nonempty'}, '', 'filename', 1);
  % }}}

  % check the 2nd input 'var' {{{
  % the 2nd input 'var' is left without checking, any data is allowed.
  % }}}

  % check the 3rd input 'varname' {{{
  validateattributes(varname, {'char'}, {}, '', 'varname', 3);
  % }}}
  % }}}

  % prepare varname {{{
  if isempty(varname)
    varname = inputname(2);
  end
  eval(sprintf('%s = var;', varname));
  % }}}

  % save / append {{{
  if exist(filename, 'file')
    % if the file already exists, append the variable.
    save(filename, varname, '-append');
  else
    save(filename, varname, '-v7.3');
  end
  % }}}
return

% -------------
% Yuxiang Jiang (yuxjiang@indiana.edu)
% Department of Computer Science
% Indiana University, Bloomington
% Last modified: Tue 08 Sep 2015 01:33:30 PM E
