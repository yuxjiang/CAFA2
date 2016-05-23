function [] = cafa_hist_oa_depth(pfile, pttl, bm, oa)
%CAFA_HIST_OA_DEPTH CAFA histogram ontology annotation depth
%
% [] = CAFA_HIST_OA_DEPTH(pfile, pttl, bm, oa);
%
%   Plots histogram of annotation depth.
%
% Input
% -----
% [char]
% pfile:      The filename of the plot.
%             Note that the file extension must be either '.eps' or '.png'
%
% [char]
% pttl:       The plot title.
%
% [char or cell]
% bm:         A benchmark filename or a list of benchmark target IDs.
%
% [struct]
% oa:         The ontology annotation structure. See pfp_oabuild.m.
%
% Output
% ------
% None.
%
% Dependency
% ----------
%[>]pfp_loaditem.m
%[>]pfp_oaproj.m
%[>]pfp_leafannot.m
%[>]pfp_depth.m
%[>]embed_canvas.m
%[>]adapt_yaxis.m
%
% See Also
% --------
%[>]pfp_oabuild.m

  % check inputs {{{
  if nargin ~= 4
    error('cafa_hist_oa_depth:InputCount', 'Expected 4 inputs.');
  end

  % pfile
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

  % pttl
  validateattributes(pttl, {'char'}, {}, '', 'pttl', 2);

  % bm
  validateattributes(bm, {'char', 'cell'}, {'nonempty'}, '', 'bm', 3);
  if ischar(bm) % load the benchmark if a file name is given
    bm = pfp_loaditem(bm, 'char');
  end

  % oa
  validateattributes(oa, {'struct'}, {'nonempty'}, '', 'oa', 4);
  % }}}

  % get plot data {{{
  oa = pfp_oaproj(oa, bm, 'object');
  annotation = pfp_leafannot(oa);

  depth = pfp_depth(oa.ontology, oa.ontology.term);

  all_depth = [];
  for i = 1 : numel(oa.object)
    all_depth = [all_depth, depth(full(annotation(i, :)))];
  end
  max_depth = 12; % 12 is the maximum depth among all 3 GO and HPO
  % max_depth = max(all_depth);

  [N, edges] = histcounts(all_depth, [1:max_depth,Inf]);
  N = N / sum(N); % normalize to percentages
  % }}}

  % setting {{{
  bw      = 0.7; % bar width
  mcolor  = [  0,  83, 159]/255; % main color (for bars)
  base_fs = 10; % base font size
  % }}}

  % plotting {{{
  h = figure('Visible', 'off');
  box on;

  for i = 1 : numel(N)
    rpos = [i - bw / 2, 0, bw, N(i)];
    rectangle('Position', rpos, 'FaceColor', mcolor, 'EdgeColor', mcolor);
  end

  [ylim, ts] = adapt_yaxis([min(N), max(N)], [0, 1], [0.1, 0.05]);
  l = ylim(1);
  u = ylim(2);
  ax = gca;
  ax.XLim  = [0, max_depth+1];
  ax.YLim  = ylim;
  ax.XTick = 1 : max_depth;
  ax.YTick = l : ts : u;

  ax.XLabel.String = 'Annotation depth in ontology';
  ax.YLabel.String = 'Fraction of data set';
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
% Last modified: Mon 23 May 2016 05:51:08 PM E
