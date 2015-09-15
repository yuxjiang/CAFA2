function [] = cafa_plot_seq_rmcurve(pfile, pttl, data, bsl_data)
%CAFA_PLOT_SEQ_RMCURVE CAFA plot sequence-centric RU-MI curves
% {{{
%
% [] = CAFA_PLOT_SEQ_RMCURVE(pttl, data, bsl_data);
%
%   Plots RU-MI curves from given data (including baseline data).
%
% Note
% ----
% absolute size: 8 x 5 (inches)
% dpi:           150
% resolution:    1200 x 750
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
% [cell]
% data:     The data containing curves and other information to plot.
%           Each cell has the thing needed for plotting a single curve.
%
%           [double]
%           .curve      n x 2, points on the curve
%
%           [double]
%           .opt_point  1 x 2, the optimal point (corresp. to Smin)
%
%           [char]
%           .tag        for the legend of the plot
%
%           See cafa_sel_top_seq_rmcurve.m
%
% [cell]
% bsl_data: A 1 x 2 cell containing the information for baselines, i.e.
%           Naive and BLAST. Each cell has the same structure as 'data'.
%
% Output
% ------
% None.
%
% Dependency
% ----------
%[>]cafa_sel_top_seq_rmcurve.m
%[>]embed_canvas.m
% }}}

  % check inputs {{{
  if nargin ~= 4
    error('cafa_plot_seq_rmcurve:InputCount', 'Expected 4 inputs.');
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

  % check the 3rd input 'data' {{{
  validateattributes(data, {'cell'}, {'nonempty'}, '', 'data', 3);
  n = numel(data);
  % }}}

  % check the 4th input 'bsl_data' {{{
  validateattributes(bsl_data, {'cell'}, {'numel', 2}, '', 'bsl_data', 4);
  % }}}
  % }}}

  % collect data {{{
  N = n + 2; % number of curves: n curves + 2 baseline curves

  RU  = cell(N, 1);
  MI  = cell(N, 1);
  opt = cell(N, 1);
  tag = cell(N, 1);
  for i = 1 : n
    RU{i}  = data{i}.curve(:, 1);
    MI{i}  = data{i}.curve(:, 2);
    opt{i} = data{i}.opt_point;
    tag{i} = data{i}.tag;
  end

  for i = 1 : 2
    RU{n + i}  = bsl_data{i}.curve(:, 1);
    MI{n + i}  = bsl_data{i}.curve(:, 2);
    opt{n + i} = bsl_data{i}.opt_point;
    tag{n + i} = bsl_data{i}.tag;
  end
  % }}}

  % determine line styles for each curve {{{
  % !! This block of choosing colors can be customized

  % color {{{
  % find 12 distinguishable colors for plotting
  cmap = colormap('colorcube'); % Matlab 2014b
  clr = zeros(12, 3);
  for i = 1 : 12
    clr(i, :) = cmap((i - 1) * 3 + 1, :);
  end

  if n > 12
    clr = [clr; clr(1 : n - 12, :)];
  else
    clr(n + 1 : end, :) = [];
  end

  clr(n + 1, :) = [1.00, 0.00, 0.00]; % red for Naive
  clr(n + 2, :) = [0.00, 0.00, 1.00]; % blue for BLAST
  % }}}

  % line style and width {{{
  style_ext = {'', '.'};  % supports at most 2 x 12 = 24 curves
  ls = cell(N, 1);        % line style
  lw = zeros(N, 1);       % line width
  for i = 1 : n % model curves
    ls{i} = ['-', style_ext{floor((i - 1) / 12) + 1}];  % line style
    lw(i) = 1.5;                                        % line width
  end
  for i = n + 1 : N
    ls{i} = ':';    % baseline curves
    lw(i) = 3;      % line width
  end
  % }}}
  % }}}

  % plotting {{{
  h = figure('Visible', 'off');
  % set(gcf, 'PaperUnits', 'inches');
  % set(gcf, 'PaperSize', [8 5], 'PaperPosition', [0 0 8 5]);
  hold on;

  % default position by MATLAB: [0.1300 0.1100 0.7750 0.8150]
  set(gca, 'Position', [0.10 0.10 0.50 0.80]);

  xlabel('Remaining uncertainty');
  ylabel('Misinformation');
  title(pttl);

  % plot rmcurves of selected models {{{
  for i = 1 : N
    plot(RU{i}, MI{i}, ls{i}, 'Color', clr(i, :), 'LineWidth', lw(i, :));
  end
  % }}}

  % plot optimal Smin on the curves
  for i = 1 : N
    plot(opt{i}(1), opt{i}(2), '.', 'Color', clr(i, :), 'MarkerSize', 20);
    plot(opt{i}(1), opt{i}(2), 'o', 'Color', clr(i, :), 'MarkerSize', 10);
  end

  % calculate a proper xylim {{{
  poi = cell2mat(opt);

  mm_xy = minmax(poi');
  range_x = mm_xy(1, 2) - mm_xy(1, 1);
  range_y = mm_xy(2, 2) - mm_xy(2, 1);

  min_x = max(0, mm_xy(1, 1) - 0.5 * range_x);
  min_y = 0;
  max_x = mm_xy(1, 2) + 0.8 * range_x;
  max_y = mm_xy(2, 2) + 0.8 * range_y;

  % little patch for the normalized case {{{
  if all(all(poi <= 1.0))
    min_x = 0; max_x = 1; range_x = 1;
    min_y = 0; max_y = 1; range_y = 1;
  end
  % }}}

  xlim([min_x, max_x]);
  ylim([min_y, max_y]);
  % }}}

  % plot F-max mesh curves {{{
  x = min_x : range_x ./ 20 : max_x;
  y = min_y : range_y ./ 20 : max_y;
  [X, Y] = meshgrid(x, y);
  Z = sqrt(X .^ 2 + Y .^ 2);

  legend(tag, 'Fontsize', 10, 'Interpreter', 'none', 'Position', [0.65, 0.25, 0.30, 0.50]);
  contour(X, Y, Z, 'ShowText', 'on', 'LineColor', [1, 1, 1] * 0.5, 'LineStyle', ':', 'LabelSpacing', 288);
  % }}}

  embed_canvas(h, 8, 5);
  print(h, pfile, device_op, '-r300');
  close;
  % }}}
return

% -------------
% Yuxiang Jiang (yuxjiang@indiana.edu)
% Department of Computer Science
% Indiana University Bloomington
% Last modified: Tue 01 Sep 2015 04:05:58 PM E
