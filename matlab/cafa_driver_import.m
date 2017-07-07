function [] = cafa_driver_import(idir, odir, ont)
%CAFA_DRIVER_IMPORT CAFA driver import
%
% [] = CAFA_DRIVER_IMPORT(idir, odir, ont);
%
%   CAFA driver to import all prediction files and save as prediction structures.
%
% Input
% -----
% [char]
% idir: The input folder having plain-text prediction files.
%       Note: it is STRONGLY suggested to use a filtered folder.
%       See cafa_driver_filter.m
%
% [char]
% odir: The output folder having loaded prediction structures.
%
% [struct]
% ont:  The ontology structure.
%       See pfp_ontbuild.m
%
% Output
% ------
% None.
%
% Dependency
% ----------
%[>]cafa_import.m
%[>]pfp_savevar.m
%
% See Also
% --------
%[>]cafa_driver_filter.m
%[>]pfp_ontbuild.m

  % check inputs {{{
  if nargin ~= 3
    error('cafa_driver_import:InputCount', 'Expected 3 inputs.');
  end

  % idir
  validateattributes(idir, {'char'}, {'nonempty'}, '', 'idir', 1);

  % odir
  validateattributes(odir, {'char'}, {'nonempty'}, '', 'odir', 2);

  % ont
  validateattributes(ont, {'struct'}, {'nonempty'}, '', 'ont', 3);
  % }}}

  % make sure <odir> exist {{{
  if ~exist(odir, 'dir')
    mkdir(odir);
  end
  % }}}

  % import (filtered) models and save to <odir> {{{
  files = dir(fullfile(idir, 'M*'));
  for i = 1 : numel(files)
    [~, mid] = fileparts(files(i).name);
    fprintf('importing model [%s]\n', mid);

    % Assumes the <CAFA header> of prediction files have been removed
    pred = cafa_import(fullfile(idir, mid), ont, false);
    pfp_savevar(fullfile(odir, mid), pred, 'pred');
  end
  % }}}
return

% -------------
% Yuxiang Jiang (yuxjiang@indiana.edu)
% Department of Computer Science
% Indiana University, Bloomington
% Last modified: Fri 07 Jul 2017 09:14:58 AM E
