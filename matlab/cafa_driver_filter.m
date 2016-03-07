function [] = cafa_driver_filter(idir, odir, bm)
%CAFA_DRIVER_FILTER CAFA driver filter
% {{{
%
% [] = CAFA_DRIVER_FILTER(idir, odir, bm);
%
%   CAFA driver to filter all consolidated files.
%
% Input
% -----
% [char]
% idir: The input folder having consolidated files.
%
% [char]
% odir: The output folder having filtered plain-text predictions.
%
% [char or cell]
% bm:   A benchmark filename or a list of benchmark target ids.
%
% Output
% ------
% None.
%
% Dependency
% ----------
%[>]pfp_loaditem.m
%[>]cafa_filter.m
% }}}

  % check inputs {{{
  if nargin ~= 3
    error('cafa_driver_filter:InputCount', 'Expected 3 inputs.');
  end

  % check the 1st input 'idir' {{{
  validateattributes(idir, {'char'}, {'nonempty'}, '', 'idir', 1);
  % }}}

  % check the 2nd input 'odir' {{{
  validateattributes(odir, {'char'}, {'nonempty'}, '', 'odir', 2);
  % }}}

  % check the 3rd input 'bm' {{{
  validateattributes(bm, {'char', 'cell'}, {'nonempty'}, '', 'bm', 3);
  if ischar(bm) % load the benchmark if a file name is given
    bm = pfp_loaditem(bm, 'char');
  end
  % }}}
  % }}}

  % make sure <odir> exist {{{
  if ~exist(odir, 'dir')
    mkdir(odir);
  end
  % }}}

  % filter regular models {{{
  files = dir(fullfile(idir, 'M*'));
  for i = 1 : numel(files)
    [~, mid] = fileparts(files(i).name);
    fprintf('filtering model [%s]\n', mid);

    cafa_filter(bm, fullfile(idir, files(i).name), fullfile(odir, mid));
  end
  % }}}
return

% -------------
% Yuxiang Jiang (yuxjiang@indiana.edu)
% Department of Computer Science
% Indiana University, Bloomington
% Last modified: Mon 07 Mar 2016 11:00:42 AM E