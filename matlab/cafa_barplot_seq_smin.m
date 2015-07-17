function [] = cafa_barplot_seq_smin(pfile, pttl, data, bsl_data)
%CAFA_BARPLOT_SEQ_SMIN CAFA barplot sequence-centric S-min
% {{{
%
% [] = CAFA_BARPLOT_SEQ_SMIN(pfile, pttl, data, bsl_data);
%
%   Plots selected bootstrapped S-min as barplots.
%
% Input
% -----
% (required)
% [char]
% pfile:    The filename of the plot.
%           Note that the file extension must be one of 'eps' or 'png'
%           default: 'png'
%
% [char]
% pttl:     The plot title.
%
% [cell]
% data:     The data containing Smins and other information to plot
%           Each cell has the thing needed for plotting a single curve.
%
%           [double]
%           .smin_mean      scalar, "bar height".
%
%           [double]
%           .smin_q05       scalar, 5% quantiles.
%
%           [double]
%           .smin_q95       scalar, 95% quantiles.
%
%           [double]
%           .coverage       scalar, averaged coverage.
%
%           [char]
%           .tag            tag of the model.
%
%           See cafa_sel_top10_seq_smin.m
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
%[>]cafa_sel_top10_seq_smin.m
%[>]embed_canvas.m
% }}}

  % check inputs {{{
  if nargin ~= 4
    error('cafa_barplot_seq_smin:InputCount', 'Expected 4 inputs.');
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
  % }}}

  % preparation, find ylim {{{
  % find range
  smin_min = Inf;
  smin_max = 0.0;
  for i = 1 : n
    if smin_min > data{i}.smin_q05
      smin_min = data{i}.smin_q05;
    end

    if smin_max < data{i}.smin_q95
      smin_max = data{i}.smin_q95;
    end
  end

  for i = 1 : m
    if smin_min > bsl_data{i}.smin_q05
      smin_min = bsl_data{i}.smin_q05;
    end

    if smin_max < bsl_data{i}.smin_q95
      smin_max = bsl_data{i}.smin_q95;
    end
  end

  [ylim_l, ylim_u, unit] = adapt_yaxis(smin_min, smin_max, 0.0, 100.0, [10.0, 5.0, 2.0, 1.0, 0.5, 0.2, 0.1]);
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
  h = figure('Visible', 'off'); hold on;

  for i = 1 : n
    rpos = [i - bar_w / 2, ylim_l, bar_w, data{i}.smin_mean - ylim_l];
    rectangle('Position', rpos, 'FaceColor', mcolor, 'EdgeColor', mcolor);
    line([i, i], [data{i}.smin_q05, data{i}.smin_q95], 'Color', 'k');
    line([i - bar_w / 4, i + bar_w / 4], [data{i}.smin_q05, data{i}.smin_q05], 'Color', 'k');
    line([i - bar_w / 4, i + bar_w / 4], [data{i}.smin_q95, data{i}.smin_q95], 'Color', 'k');

    % plot coverage as text
    cpos  = ylim_l + 0.05 * (ylim_u - ylim_l);
    ctext = sprintf('C=%.2f', nanmean(data{i}.coverage));
    text(i, cpos, ctext, 'FontSize', base_fs, 'Rotation', 90);

    % collect team name for display
    xticks{i} = regexprep(data{i}.tag, '_', '\\_');
  end
  % }}}

  % draw baselines {{{
  N = 10; % careful, baseline starts at 11, even if n < 10
  for i = 1 : m
    j = N + i;
    rpos = [j - bar_w / 2, ylim_l, bar_w, bsl_data{i}.smin_mean - ylim_l];
    rectangle('Position', rpos, 'FaceColor', bcolor{i}, 'EdgeColor', bcolor{i});
    line([j, j], [bsl_data{i}.smin_q05, bsl_data{i}.smin_q95], 'Color', 'k');
    line([j - bar_w / 4, j + bar_w / 4], [bsl_data{i}.smin_q05, bsl_data{i}.smin_q05], 'Color', 'k');
    line([j - bar_w / 4, j + bar_w / 4], [bsl_data{i}.smin_q95, bsl_data{i}.smin_q95], 'Color', 'k');

    % plot coverage as text
    cpos  = ylim_l + 0.05 * (ylim_u - ylim_l);
    ctext = sprintf('C=%.2f', nanmean(bsl_data{i}.coverage));
    text(j, cpos, ctext, 'FontSize', base_fs, 'Rotation', 90, 'Color', btxtcolor{i});

    % collect team name for display
    xticks{j} = regexprep(bsl_data{i}.tag, '_', '\\_');
  end

  for i = 1 : m
    xrange = [0, (N + m + 1)];
    level  = repmat(bsl_data{i}.smin_mean, 1, 2);
    line(xrange, level, 'LineWidth', 2, 'LineStyle', ':', 'Color', bcolor{i});
  end
  % }}}

  % tuning {{{
  title(pttl, 'FontSize', base_fs + 2); % set it bigger than the base font size
  ylabel('{\itS}_{min}');

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
  print(h, pfile, device_op);
  close;
  % }}}
return

% -------------
% Yuxiang Jiang (yuxjiang@indiana.edu)
% Department of Computer Science
% Indiana University Bloomington
% Last modified: Fri 10 Jul 2015 03:11:29 PM E
