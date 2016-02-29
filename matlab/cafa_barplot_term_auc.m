function [] = cafa_barplot_term_auc(pfile, pttl, data, bsl_data, yaxis)
%CAFA_BARPLOT_TERM_AUC CAFA barplot term-centric AUC
% {{{
%
% [] = CAFA_BARPLOT_TERM_AUC(pfile, pttl, data, bsl_data, yaxis);
%
%   Plots selected average AUC as barplots.
%
% Input
% -----
% (required)
% [char]
% pfile:    The filename of the plot.
%           Note that the file extension should be either 'eps' or 'png'.
%           default: 'png'
%
% [char]
% pttl:     The plot title.
%
% [cell]
% data:     The data containing AUCs and other information to plot
%           Each cell has the thing needed for plotting a single curve.
%
%           [double]
%           .auc_mean scalar, "bar height".
%
%           [double]
%           .auc_q05  scalar, 5% quantiles.
%
%           [double]
%           .auc_q95  scalar, 95% quantiles.
%
%           [double]
%           .auc_std    scalar, standard deviation
%
%           [double]
%           .auc_ste    scalar, standard error (std / sqrt(N))
%
%           [char]
%           .tag      tag of the model.
%
%           See cafa_sel_top_term_auc.m
%
% [cell]
% bsl_data: A 1 x 2 cell containing the information for baselines, i.e.
%           Naive and BLAST. Each cell has the same structure as 'data'.
%
% (optional)
% [double]
% yaxis:    1 x 3 double, the AUC limits (y-axis), [start, stop, step]
%           if yaxis is empty or not given, it will be decided adaptively.
%           default: []
%
% Output
% ------
% None.
%
% Dependency
% ----------
%[>]cafa_sel_top_term_auc.m
%[>]embed_canvas.m
%[>]adapt_yaxis.m
% }}}

  % check inputs {{{
  if nargin < 4 || nargin > 5
    error('cafa_barplot_term_auc:InputCount', 'Expected 4 or 5 inputs.');
  end

  if nargin == 4
    yaxis = [];
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
  m = numel(bsl_data);
  % }}}

  % check the 5th input 'yaxis' {{{
  validateattributes(yaxis, {'double'}, {}, '', 'yaxis', 5);
  if isempty(yaxis)
    is_adaptive = true;
  else
    is_adaptive = false;
  end
  % }}}
  % }}}

  % preparation, find ylim {{{

  % collect plotting data {{{
  bar_h = zeros(n, 1);
  err_l = zeros(n, 1);
  err_u = zeros(n, 1);

  for i = 1 : n
    bar_h(i) = data{i}.auc_mean;

    % standard error
    err_l(i) = data{i}.auc_mean - data{i}.auc_ste;
    err_u(i) = data{i}.auc_mean + data{i}.auc_ste;

    % standard deviation
    % err_l(i) = data{i}.auc_mean - data{i}.auc_std;
    % err_u(i) = data{i}.auc_mean + data{i}.auc_std;
  end

  bsl_bar_h = zeros(n, 1);
  bsl_err_l = zeros(n, 1);
  bsl_err_u = zeros(n, 1);
  for i = 1 : m
    bsl_bar_h(i) = bsl_data{i}.auc_mean;

    % standard error
    bsl_err_l(i) = bsl_data{i}.auc_mean - bsl_data{i}.auc_ste;
    bsl_err_u(i) = bsl_data{i}.auc_mean + bsl_data{i}.auc_ste;

    % standard deviation
    % bsl_err_l(i) = bsl_data{i}.auc_mean - bsl_data{i}.auc_std;
    % bsl_err_u(i) = bsl_data{i}.auc_mean + bsl_data{i}.auc_std;
  end
  % }}}

  if is_adaptive
    % find range
    auc_min = 1.0;
    auc_max = 0.0;
    for i = 1 : n
      if auc_min > err_l(i)
        auc_min = err_l(i);
      end

      if auc_max < err_u(i)
        auc_max = err_u(i);
      end
    end

    for i = 1 : m
      if auc_min > bsl_err_l(i)
        auc_min = bsl_err_l(i);
      end

      if auc_max < bsl_err_u(i)
        auc_max = bsl_err_u(i);
      end
    end

    [ylim, unit] = adapt_yaxis([auc_min, auc_max], [0.0, 1.0], [0.1, 0.05, 0.02, 0.01]);
    ylim_l = ylim(1);
    ylim_r = ylim(2);
  else
    ylim_l = yaxis(1);
    ylim_u = yaxis(2);
    unit   = yaxis(3);
  end
  % }}}

  % settings {{{
  base_fs = 10; % base font size

  mcolor = [0.6, 0.6, 0.6]; % regular models
  bcolor = {[196,  48,  43]/255, [  0,  83, 159]/255}; % baseline models
  % bcolor = {[0.8, 0.3, 0.3], [0.3, 0.3, 0.8]}; % baseline models

  mtxtcolor = [0.0, 0.0, 0.0]; % for regular models
  btxtcolor = {[1.0, 1.0, 1.0], [1.0, 1.0, 1.0]}; % for baseline models
  % btxtcolor = {[0.0, 0.0, 0.0], [0.8, 0.8, 0.3]}; % for baseline models

  bar_w  = 0.7; % before: 0.5
  xticks = cell(1, n + m);
  % }}}

  % draw top 10 models {{{
  h = figure('Visible', 'off');
  hold on;

  for i = 1 : n
    rpos = [i - bar_w / 2, ylim_l, bar_w, data{i}.auc_mean - ylim_l];
    rectangle('Position', rpos, 'FaceColor', mcolor, 'EdgeColor', mcolor);
    line([i, i], [err_l(i), err_u(i)], 'Color', 'k');
    line([i - bar_w / 4, i + bar_w / 4], [err_l(i), err_l(i)], 'Color', 'k');
    line([i - bar_w / 4, i + bar_w / 4], [err_u(i), err_u(i)], 'Color', 'k');

    % collect team name for display
    xticks{i} = regexprep(data{i}.tag, '_', '\\_');
  end
  % }}}

  % draw baselines {{{
  N = 10; % careful, baseline starts at 11, even if n < 10
  for i = 1 : m
    j = N + i;
    rpos = [j - bar_w / 2, ylim_l, bar_w, bsl_data{i}.auc_mean - ylim_l];
    rectangle('Position', rpos, 'FaceColor', bcolor{i}, 'EdgeColor', bcolor{i});
    line([j, j], [bsl_err_l(i), bsl_err_u(i)], 'Color', 'k');
    line([j - bar_w / 4, j + bar_w / 4], [bsl_err_l(i), bsl_err_l(i)], 'Color', 'k');
    line([j - bar_w / 4, j + bar_w / 4], [bsl_err_u(i), bsl_err_u(i)], 'Color', 'k');

    % collect team name for display
    xticks{j} = regexprep(bsl_data{i}.tag, '_', '\\_');
  end

  % draw dashed baseline level
  for i = 1 : m
    xrange = [0, (N + m + 1)]; % [from, to]
    level  = repmat(bsl_data{i}.auc_mean, 1, 2);
    line(xrange, level, 'LineWidth', 2, 'LineStyle', ':', 'Color', bcolor{i});
  end
  % }}}

  % tuning {{{
  title(pttl, 'FontSize', base_fs + 2);
  ylabel('Averaged AUC');

  ax = gca;
  ax.XLim               = [0, (N + m + 1)];
  ax.YLim               = [ylim_l, ylim_u];
  ax.XTick              = 1 : (N + m);
  ax.YTick              = ylim_l : unit : ylim_u;
  ax.XTickLabel         = xticks;
  ax.FontSize           = base_fs;
  ax.XTickLabelRotation = 45;

  % reset the height of axis (bottom = 0.3), keep others
  bottom = 0.35;
  raised = bottom - ax.Position(2);
  ax.Position(2) = bottom;
  ax.Position(4) = ax.Position(4) - raised;

  embed_canvas(h, 5, 4); % 5 x 4 inches
  print(h, pfile, device_op, '-r300');
  close;
  % }}}
return

% -------------
% Yuxiang Jiang (yuxjiang@indiana.edu)
% Department of Computer Science
% Indiana University Bloomington
% Last modified: Mon 29 Feb 2016 04:19:09 PM E
