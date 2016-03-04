function [] = cafa_plot_eia(pfile, pttl, eia, bmoa, bm, bgoa)
%CAFA_PLOT_EIA CAFA plot estimated annotation
% {{{
%
% [] = CAFA_PLOT_EIA(pfile, pttl, eia, bmoa, bm, bgoa);
%
%   Plots a comparison barplot of information accretion between benchmark and
%   background annotations.
%
% Input
% -----
% [char]
% pfile:    The filename of the plot.
%           Note that the file extension must be either 'eps' or 'png'.
%           default: 'png'
%
% [char]
% pttl:     The plot title.
%
% [double]
% eia:      The 1-by-m vector of estimated information accretion.
%
% [struct]
% bmoa: The ontology annotation structure of benchmarks.
%       See pfp_oabuild.m
%
%       Note: bmoa.object is supposed to cover the entire benchmark.
%
% [char or cell]
% bm:   A benchmark filename or a list of benchmark target ids.
%
%
% [struct]
% bgoa: The ontology annotation of background usually the entire annotation
%       data set.
%
% Dependency
% ----------
%[>]embed_canvas.m
%[>]pfp_loaditem.m
%[>]pfp_oaproj.m
%
% See Also
% --------
%[>]pfp_oabuild.m
% }}}

  % check inputs {{{
  if nargin ~= 6
    error('cafa_plot_eia:InputCount', 'Expected 6 inputs.');
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

  % check the 3rd input 'eia' {{{
  validateattributes(eia, {'double'}, {'nonempty', '>=', 0}, '', 'eia', 3);
  m = numel(eia);
  % }}}

  % check the 4th input 'bmoa' {{{
  validateattributes(bmoa, {'struct'}, {}, '', 'bmoa', 4);
  % }}}

  % check the 5th input 'bm' {{{
  validateattributes(bm, {'char', 'cell'}, {'nonempty'}, '', 'bm', 5);
  if ischar(bm) % load the benchmark if a file name is given
    bm = pfp_loaditem(bm, 'char');
  end
  % }}}

  % check the 6th input 'bgoa' {{{
  validateattributes(bgoa, {'struct'}, {}, '', 'bgoa', 6);
  % }}}
  % }}}

  % calculating {{{
  bmoa = pfp_oaproj(bmoa, bm, 'object');
  bmoa_annot = bmoa.annotation;

  % remove empty annotations in bgoa
  bgoa_annot = bgoa.annotation(any(bgoa.annotation, 2), :);

  % settings
  color1 = [250, 149,   0] / 255; % color for group1, yellow
  color2 = [  0,  83, 159] / 255; % color for group2, blue

  label1 = 'Benchmark';
  label2 = 'All T1';

  eia   = reshape(eia, [], 1); % enforce a column vector
  bm_ia = full(bmoa_annot * eia);
  bg_ia = full(bgoa_annot * eia);
  n1    = numel(bm_ia); % the size of benchmark
  n2    = numel(bg_ia); % the size of background
  G     = [repmat({label1}, n1, 1); repmat({label2}, n2, 1)];
  cG    = [repmat(color1, n1, 1); repmat(color2, n2, 1)];

  bm_mu = mean(bm_ia);
  bg_mu = mean(bg_ia);
  % }}}

  % plotting {{{
  h = figure('Visible', 'off');
  plot_type = 'hist';

  title(pttl);
  % available plot type: {'hist', 'qqplot'}
  switch plot_type
    case 'hist' % {{{
      pfile = fullfile(p, strcat(f, '_hist', e));
      hold on;
      bw = max([bm_ia; bg_ia]) / 50;

      h1               = histogram(bm_ia);
      h1.Normalization = 'probability';
      h1.BinWidth      = bw;
      h1.FaceColor     = color1;

      h2               = histogram(bg_ia);
      h2.Normalization = 'probability';
      h2.BinWidth      = bw;
      h2.FaceColor     = color2;

      legend({label1, label2});
      xlabel('Information accretion');
      ylabel('Frequency');

      % make another boxplot {{{
      axes('Position', [0.35, 0.35, 0.4, 0.4]);

      boxplot([bm_ia; bg_ia], G, 'colors', [color1; color2], 'symbol', '.');

      min_ia = min([bm_ia; bg_ia]);
      max_ia = max([bm_ia; bg_ia]);
      q95_ia = quantile(bg_ia, .95);

      ax = gca;
      ax.YLim = adapt_yaxis([min_ia, q95_ia], [0, max_ia], [1, 2, 5, 10, 20, 50]);

      ylabel('Normalized IC');
      % }}}
      % }}}
    case 'qqplot' % {{{
      pfile = fullfile(p, strcat(f, '_qqplot', e));
      % n = 200; % number of points to plot
      % qqplot(bm_ia, bg_ia, linspace(0, 100, n));
      qqplot(bm_ia, bg_ia);
      axis square;
      ax = gca;
      ax.XLim(1) = 0;
      ax.YLim(1) = 0;
      xlabel(label1);
      ylabel(label2);
      % }}}
    otherwise
      % do nothing
  end
  embed_canvas(h, 8, 5);
  print(h, pfile, device_op, '-r300');
  close;
  % }}}
return

% -------------
% Yuxiang Jiang (yuxjiang@indiana.edu)
% Department of Computer Science
% Indiana University, Bloomington
% Last modified: Tue 01 Mar 2016 09:24:29 PM E
