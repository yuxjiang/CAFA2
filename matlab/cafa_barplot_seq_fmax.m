function [] = cafa_barplot_seq_fmax(pfile, pttl, data, bsl_data, yaxis)
%CAFA_BARPLOT_SEQ_FMAX CAFA barplot sequence-centric Fmax
% {{{
%
% [] = CAFA_BARPLOT_SEQ_FMAX(pfile, pttl, data, bsl_data, yaxis);
%
%   Plots selected bootstrapped Fmax as barplots.
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
% data:     The data containing Fmaxs and other information to plot
%           Each cell has the thing needed for plotting a single curve.
%
%           [double]
%           .fmax_mean      scalar, "bar height".
%
%           [double]
%           .fmax_q05       scalar, 5% quantiles.
%
%           [double]
%           .fmax_q95       scalar, 95% quantiles.
%
%           [double]
%           .coverage       scalar, averaged coverage.
%
%           [char]
%           .tag            tag of the model.
%
%           See cafa_sel_top_seq_fmax.m
%
% [cell]
% bsl_data: A 1 x 2 cell containing the information for baselines, i.e.
%           Naive and BLAST. Each cell has the same structure as 'data'.
%
% (optional)
% [double]
% yaxis:    1 x 3 double, the Fmax limits (y-axis), [start, stop, step]
%           if yaxis is empty or not given, it will be decided adaptively.
%           default: []
%
% Output
% ------
% None.
%
% Dependency
% ----------
%[>]cafa_sel_top_seq_fmax.m
%[>]embed_canvas.m
% }}}

  % check inputs {{{
  if nargin < 4 || nargin > 5
    error('cafa_barplot_seq_fmax:InputCount', 'Expected 4 or 5 inputs.');
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
  if is_adaptive
    % find range
    fmax_min = 1.0;
    fmax_max = 0.0;
    for i = 1 : n
      if fmax_min > data{i}.fmax_q05
        fmax_min = data{i}.fmax_q05;
      end

      if fmax_max < data{i}.fmax_q95
        fmax_max = data{i}.fmax_q95;
      end
    end

    for i = 1 : m
      if fmax_min > bsl_data{i}.fmax_q05
        fmax_min = bsl_data{i}.fmax_q05;
      end

      if fmax_max < bsl_data{i}.fmax_q95
        fmax_max = bsl_data{i}.fmax_q95;
      end
    end

    [ylim_l, ylim_u, unit] = adapt_yaxis(fmax_min, fmax_max, 0.0, 1.0, [0.1, 0.05, 0.02, 0.01]);
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
    rpos = [i - bar_w / 2, ylim_l, bar_w, data{i}.fmax_mean - ylim_l];
    rectangle('Position', rpos, 'FaceColor', mcolor, 'EdgeColor', mcolor);
    line([i, i], [data{i}.fmax_q05, data{i}.fmax_q95], 'Color', 'k');
    line([i - bar_w / 4, i + bar_w / 4], [data{i}.fmax_q05, data{i}.fmax_q05], 'Color', 'k');
    line([i - bar_w / 4, i + bar_w / 4], [data{i}.fmax_q95, data{i}.fmax_q95], 'Color', 'k');

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
    rpos = [j - bar_w / 2, ylim_l, bar_w, bsl_data{i}.fmax_mean - ylim_l];
    rectangle('Position', rpos, 'FaceColor', bcolor{i}, 'EdgeColor', bcolor{i});
    line([j, j], [bsl_data{i}.fmax_q05, bsl_data{i}.fmax_q95], 'Color', 'k');
    line([j - bar_w / 4, j + bar_w / 4], [bsl_data{i}.fmax_q05, bsl_data{i}.fmax_q05], 'Color', 'k');
    line([j - bar_w / 4, j + bar_w / 4], [bsl_data{i}.fmax_q95, bsl_data{i}.fmax_q95], 'Color', 'k');

    % plot coverage as text
    cpos  = ylim_l + 0.05 * (ylim_u - ylim_l);
    ctext = sprintf('C=%.2f', nanmean(bsl_data{i}.coverage));
    text(j, cpos, ctext, 'Rotation', 90, 'FontSize', base_fs, 'Color', btxtcolor{i});

    % collect team name for display
    xticks{j} = regexprep(bsl_data{i}.tag, '_', '\\_');
  end

  % draw dashed baseline level
  for i = 1 : m
    xrange = [0, (N + m + 1)]; % [from, to]
    level  = repmat(bsl_data{i}.fmax_mean, 1, 2);
    line(xrange, level, 'LineWidth', 2, 'LineStyle', ':', 'Color', bcolor{i});
  end
  % }}}

  % tuning {{{
  title(pttl, 'FontSize', base_fs + 2);
  ylabel('{\itF}_{max}');

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
% Last modified: Sun 19 Jul 2015 04:30:50 PM E
