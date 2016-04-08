function [] = cafa_plot_eia(pfile, pttl, config_info, eia, t1oa, ptype)
%CAFA_PLOT_EIA CAFA plot estimated information accretion
% {{{
%
% [] = CAFA_PLOT_EIA(pfile, pttl, config_info, eia, t1oa);
% [] = cafa_plot_eia(pfile, pttl, config_info, eia, t1oa, ptype);
%
%   Plots a comparison barplot of information accretion between benchmark and T1
%   annotations.
%
% Input
% -----
% (required)
% [char]
% pfile:        The filename of the plot.
%               Note that the file extension must be either 'eps' or 'png'.
%               default: 'png'
%
% [char]
% pttl:         The plot title.
%
% [char or struct]
% config_info:  The configuration file (job descriptor) or a parsed config
%               structure.
%
%               See cafa_parse_config.m
%
% [double]
% eia:          The 1-by-m vector of estimated information accretion.
%
% [struct]
% t1oa:         The ontology annotation at T1.
%               See pfp_oabuild.m
%
% (optional)
% [char]
% ptype:        Plot type, available options:
%               'hist'    Histogram (along with embeded boxplot)
%               'kde'     Kernel density estimation
%               'qqplot'  QQplot
%               default: 'hist'.
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
  if nargin ~= 5 && nargin ~= 6
    error('cafa_plot_eia_density:InputCount', 'Expected 5 or 6 inputs.');
  end

  if nargin == 5
    ptype = 'hist';
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

  % check the 3rd input 'config_info' {{{
  validateattributes(config_info, {'char', 'struct'}, {'nonempty'}, '', 'config_info', 3);

  if ischar(config_info)
    config = cafa_parse_config(config_info);
  elseif isstruct(config_info)
    config = config_info;
  else
    error('cafa_plot_eia_density:InputErr', 'Unknown data type of ''config_info''');
  end
  % }}}

  % check the 4th input 'eia' {{{
  validateattributes(eia, {'double'}, {'nonempty', '>=', 0}, '', 'eia', 4);
  m = numel(eia);
  % }}}

  % check the 5th input 't1oa' {{{
  validateattributes(t1oa, {'struct'}, {}, '', 't1oa', 5);
  % }}}

  % check the 6th input 't1oa' {{{
  ptype = validatestring(ptype, {'hist', 'kde', 'qqplot'}, '', 'ptype', 6);
  % }}}
  % }}}

  % calculating {{{
  bmoa = pfp_oaproj(config.oa, config.bm, 'object');
  bmoa_annot = bmoa.annotation;

  % remove empty annotations in t1oa
  t1oa_annot = t1oa.annotation(any(t1oa.annotation, 2), :);

  % settings
  [r, ~, b, y] = pfp_rgby;

  label1 = 'Benchmark';
  label2 = 'All T1';
  label3 = 'Naive';

  eia   = reshape(eia, [], 1); % enforce a column vector
  bm_ia = full(bmoa_annot * eia);
  t1_ia = full(t1oa_annot * eia);
  n1    = numel(bm_ia); % the size of benchmark
  n2    = numel(t1_ia); % the size of T1
  G     = [repmat({label1}, n1, 1); repmat({label2}, n2, 1)];
  cG    = [repmat(y, n1, 1); repmat(b, n2, 1)];
  % }}}

  % get naive prediction {{{
  if strcmp(config.ont, 'hpo')
    naive_file = 'BN4H.mat';
  else
    naive_file = 'BN4S.mat';
  end
  naive = load(fullfile(config.eval_dir, naive_file), 'seq_fmax');
  opt_tau = naive.seq_fmax.tau;

  naive = load(fullfile(config.pred_dir, naive_file), 'pred');
  naive_eia = full(naive.pred.score(1,:) >= opt_tau) * eia;
  % }}}

  % plotting {{{
  h = figure('Visible', 'off');
  title(pttl);
  switch ptype
    case 'hist' % {{{
      pfile = fullfile(p, strcat(f, '_hist_box', e));
      hold on;
      bw = max([bm_ia; t1_ia]) / 50;

      h1               = histogram(bm_ia);
      h1.Normalization = 'probability';
      h1.BinWidth      = bw;
      h1.FaceColor     = y;

      h2               = histogram(t1_ia);
      h2.Normalization = 'probability';
      h2.BinWidth      = bw;
      h2.FaceColor     = b;

      % mark the Naive eia
      plot(naive_eia, 0, 'o', 'MarkerEdgeColor', r, 'MarkerFaceColor', r);

      legend({label1, label2, label3});
      xlabel('Total information accretion per protein');
      ylabel('Frequency');

      % make the embeded boxplot {{{
      axes('Position', [0.35, 0.35, 0.4, 0.4]);

      boxplot([bm_ia; t1_ia], G, 'colors', [y; b], 'symbol', '.');

      min_ia = min([bm_ia; t1_ia]);
      max_ia = max([bm_ia; t1_ia]);
      q95_ia = quantile(t1_ia, .95);

      ax = gca;
      ax.YLim = adapt_yaxis([min_ia, q95_ia], [0, max_ia], [1, 2, 5, 10, 20, 50]);

      ylabel('Information accretion');
      % }}}
      % }}}
    case 'qqplot' % {{{
      pfile = fullfile(p, strcat(f, '_qqplot', e));
      % n = 200; % number of points to plot
      % qqplot(bm_ia, t1_ia, linspace(0, 100, n));
      qqplot(bm_ia, t1_ia);
      axis square;
      ax = gca;
      ax.XLim(1) = 0;
      ax.YLim(1) = 0;
      xlabel(label1);
      ylabel(label2);
      % }}}
    case 'kde' % {{{
      % preparation {{{
      % We set up a range of support for KDE
      % and remove extremes (right tails especially)
      minia = 0;
      tail  = 0.99; % ignore "tail" beyond this quantile
      maxia = max(quantile(bm_ia, tail), quantile(t1_ia, tail));

      % for visual purpose
      maxia_v = max(quantile(bm_ia, tail), quantile(t1_ia, tail));

      bm_ia(bm_ia <= minia | bm_ia >= maxia) = [];
      t1_ia(t1_ia <= minia | t1_ia >= maxia) = [];

      [fbm, xibm] = ksdensity(bm_ia, 'Support', [minia, maxia]);
      [ft1, xit1] = ksdensity(t1_ia, 'Support', [minia, maxia]);
      % }}}

      pfile = fullfile(p, strcat(f, '_kde', e));
      hold on;
      plot(xibm, fbm, 'Color', y);
      plot(xit1, ft1, 'Color', b);

      % mark the Naive eia
      plot(naive_eia, 0, 'o', 'MarkerEdgeColor', r, 'MarkerFaceColor', r);
      legend({label1, label2, label3});
      ax = gca;
      ax.XLabel.String = 'Total information accretion per protein';
      ax.YLabel.String = 'Probability';
      ax.XLim          = [minia, maxia_v];
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
% Last modified: Fri 08 Apr 2016 01:08:24 PM E
