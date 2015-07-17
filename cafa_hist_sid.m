function [] = cafa_hist_sid(pfile, pttl, bm, sfile)
%CAFA_HIST_SID Histogram of sid (sequence identity)
% {{{
%
% [] = CAFA_PLOT_SID_HIST(pfile, pttl, bm, sfile);
%
%   Plots the histogram of sequence identity.
%
% Input
% -----
% [char]
% pfile:  The filename of the plot.
%         Note that the file extension must be either '.eps' or '.png'
%
% [char]
% pttl:   The plot title.
%
% [char or cell]
% bm:     A benchmark filename or a list of benchmark target IDs.
%
% [char]
% sfile:  The sequence identity data file, format:
%         <tid> <sid> <identity>
%
% Output
% ------
% None.
%
% Dependency
% ----------
%[>]pfp_loaditem.m
%[>]embed_canvas.m
% }}}

  % check inputs {{{
  if nargin ~= 4
    error('cafa_hist_sid:InputCount', 'Expected 4 inputs.');
  end

  % check the 1st input 'pfile' {{{
  validateattributes(pfile, {'char'}, {'nonempty'}, '', 'pfile', 1);
  [p, f, e] = fileparts(pfile);
  if isempty(e)
    e = '.png';
  end
  ext = validatestring(e, {'.eps', '.png'}, '', 'pfile', 1);
  if strcmp(ext, '.eps')
    device_op = '-depsc';
  elseif strcmp(ext, '.png')
    device_op = '-dpng';
  end
  % }}}

  % check the 2nd input 'pttl' {{{
  validateattributes(pttl, {'char'}, {}, '', 'pttl', 2);
  % }}}

  % check the 3rd input 'bm' {{{
  validateattributes(bm, {'char', 'cell'}, {'nonempty'}, '', 'bm', 3);
  if ischar(bm) % load the benchmark if a file name is given
    bm = pfp_loaditem(bm, 'char');
  end
  % }}}

  % check the 4th input 'sfile' {{{
  validateattributes(sfile, {'char'}, {'nonempty'}, '', 'sfile', 4);
  fin = fopen(sfile, 'r');
  if fin == -1
    error('cafa_hist_sid:FileErr', 'Cannot open the data file.');
    return;
  end
  % }}}
  % }}}

  % read the select sequence identities {{{
  data = textscan(fin, '%s%s%f', 'delimiter', '\t');
  fclose(fin);
  [found, index] = ismember(bm, data{1});
  sid = data{3}(index(found));
  % }}}

  % setting {{{
  bw      = 0.8; % bar width
  mcolor  = [  0,  83, 159]/255; % main color (for bars)
  base_fs = 10; % base font size
  nbins   = 30;
  % }}}

  % plot data {{{
  h = figure('Visible', 'off');
  box on;

  % make a histogram of 20 bins
  % edges = 0.00 : 0.05 : 1.00;
  % edges(end) = edges(end) + 0.01; % include sid = 1.00 into the last bin
  % histogram(sid, edges);
  [N, edges] = histcounts(sid, nbins, 'BinLimits', [0, 1]);

  for i = 1 : numel(N)
    x = (edges(i) + edges(i+1)) / 2;
    width = (edges(i+1) - edges(i)) * bw;
    rpos = [x - width / 2, 0, width, N(i)];
    rectangle('Position', rpos, 'FaceColor', mcolor, 'EdgeColor', mcolor);
  end

  ax = gca;
  ax.XLim  = [0, 1];
  ax.XTick = 0.0:0.1:1.0;

  ax.XLabel.String = 'Percent identity';
  ax.YLabel.String = 'Count';
  ax.Title.String  = pttl;

  embed_canvas(h, 5, 4);
  print(h, pfile, device_op, '-r300');
  close(h);
  % }}}
return

% -------------
% Yuxiang Jiang (yuxjiang@indiana.edu)
% Department of Computer Science
% Indiana University Bloomington
% Last modified: Wed 08 Jul 2015 02:29:29 PM E
