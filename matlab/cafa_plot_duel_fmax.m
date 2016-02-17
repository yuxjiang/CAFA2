function [] = cafa_plot_duel_fmax(pfile, data, bsl_data, yrange)
%CAFA_PLOT_DUEL_FMAX CAFA plot duel Fmax
% {{{
%
% [] = CAFA_PLOT_DUEL_FMAX(pttl, data, bsl_data);
%
%   Plots duel results.
%
% Input
% -----
% [char]
% pfile:    The filename of the plot.
%           Note that the file extension must be either 'eps' or 'png'.
%           default: 'png'
%
% [struct]
% data:     The data structure containing information for plot.
%           [cell]
%           .group1   1-by-n tags (will not be show in the plot for now)
%
%           [cell]
%           .group2   1-by-m tags (will not be show in the plot for now)
%
%           [double]
%           .winner   n-by-m (usually n = m = 5), indicates which model wins.
%                     possible value: 1 or 2
%                     winner(i, j) shows the results of group1(i) v.s. group2(j)
%
%           [double]
%           .pvalue   n-by-m, contains the P-value
%
%           See cafa_duel_seq_fmax.m
%
% [cell]
% bsl_data: A 1 x 4 cell containing the information for baselines, i.e.
%           cell 1 - Naive trained on CAFA1 training (2011 SwissProt)
%           cell 2 - Naive trained on CAFA2 training (2014 SwissProt)
%           cell 3 - BLAST trained on CAFA1 training (2011 SwissProt)
%           cell 4 - BLAST trained on CAFA2 training (2014 SwissProt)
%           
%           Each cell entry contains the evaluation result 'seq_fmax_bst'.
%           See cafa_eval_seq_fmax_bst.m
%
% [double]
% yrange:   [ymin, ymax] of the bar plot of baselines.
%           --------
%           recommended for mfo: [0.2, 0.7]
%           recommended for bpo: [0.0, 0.5]
%
% Output
% ------
% None.
%
% See Also
% --------
%[>]cafa_duel_seq_fmax.m
%[>]cafa_eval_seq_fmax_bst.m
% }}}

  % check inputs {{{
  if nargin ~= 4
    error('cafa_plot_duel_fmax:InputCount', 'Expected 4 inputs.');
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

  % check the 2nd input 'data' {{{
  validateattributes(data, {'struct'}, {'nonempty'}, '', 'data', 2);
  n = numel(data.group1);
  m = numel(data.group2);
  % }}}

  % check the 3rd input 'bsl_data' {{{
  validateattributes(bsl_data, {'cell'}, {'numel', 4}, '', 'bsl_data', 3);
  % }}}

  % check the 4th input 'yrange' {{{
  validateattributes(yrange, {'double'}, {'numel', 2}, '', 'yrange', 4);
  % }}}
  % }}}

  % setting {{{
  % color1 = [196,  48,  43] / 255; % color for group1, red
  % color2 = [ 32, 128,  80] / 255; % color for group2, green
  color1 = [250, 149,   0] / 255; % color for group1, yellow
  color2 = [  0,  83, 159] / 255; % color for group2, blue

  padding    = 0.02;
  margin_max = 0.1;
  bar_xmin   = 0.5;
  bar_xmax   = 2.5;
  bar_ymin   = yrange(1);
  bar_ymax   = yrange(2);

  % --------
  bar_xrange = bar_xmax - bar_xmin;
  bar_yrange = bar_ymax - bar_ymin;
  xyratio  = 2;

  bs_bsl  = 0.3;
  bs_main = 0.2;

  ll_x = linspace(0, 1, m+1); ll_x(end) = [];
  ll_y = linspace(0, 1, n+1); ll_y(end) = [];
  ll_bsl = [mean([bar_xmax; bar_xmin]) - 0.5*bs_bsl, bar_ymax - 0.5*bs_bsl];
  % }}}

  % plotting {{{
  h = figure('Visible', 'off');
  % set(gcf, 'PaperUnits', 'inches');
  % set(gcf, 'PaperSize', [8 5], 'PaperPosition', [0 0 8 5]);
  hold on;

  % default position by MATLAB: [0.1300 0.1100 0.7750 0.8150]

  % plot heatmap {{{
  ax_main = gca;
  ax_main.Position = [0.05, 0.05, 0.4, 0.6];
  ax_main.XLim = [0, 1];
  ax_main.YLim = [0, 1];
  ax_main.XTick = {};
  ax_main.YTick = {};
  ax_main.XAxisLocation = 'top';
  ax_main.YLabel.String = 'CAFA1 top 5 models';
  ax_main.XLabel.String = 'CAFA2 top 5 models';
  ax_main.Visible = 'off';

  text(-0.1, 1.15, 'A.', 'FontSize', 14, 'FontWeight', 'bold');
  text(-0.05, 1-padding, 'CAFA1 top models \rightarrow', ...
  'Rotation', -90, 'FontSize', 12, 'FontWeight', 'bold');
  text(0, 1.05, 'CAFA2 top models \rightarrow', 'FontSize', 12, 'FontWeight', 'bold');

  for i = 1 : n
    for j = 1 : m
      if data.nwins(i, j) == 10000
        value = '100';
      else
        value = sprintf('%.2f', data.nwins(i, j) / 100);
      end
      ratio = min(1.0, data.margin(i, j) / margin_max);
      if data.winner(i, j) == 1
        col = [1, 1, 1] - ratio * ([1, 1, 1] - color1);
      else
        col = [1, 1, 1] - ratio * ([1, 1, 1] - color2);
      end
      draw_rect([ll_y(j), ll_x(n+1-i), bs_main-padding, bs_main-padding], col, value);
    end
  end
  % }}}

  % plot colorbox {{{
  ax_cbox         = axes('Position', [0.15-padding, 0.8, 0.3, 0.1]);
  ax_cbox.XLim    = [0, 1];
  ax_cbox.YLim    = [0, 1];
  ax_cbox.Visible = 'off';

  draw_colorbox([0, 0, 1, .7], color1, color2);
  text(0.0, 1.0, sprintf('%.1f', -margin_max), ...
  'FontSize', 12, 'FontWeight', 'bold', 'HorizontalAlignment', 'center');
  text(0.5, 1.0, sprintf('%.1f', 0), ...
  'FontSize', 12, 'FontWeight', 'bold', 'HorizontalAlignment', 'center');
  text(1.0, 1.0, sprintf('%.1f', +margin_max), ...
  'FontSize', 12, 'FontWeight', 'bold', 'HorizontalAlignment', 'center');
  % }}}

  % plot Naive comparison {{{
  ax_naive = axes('Position', [0.55, 0.55, 0.4, 0.35]);
  res = bsl_info(bsl_data{1}, bsl_data{2}, margin_max, color1, color2);

  draw_bracket([1.5, bar_ymax-0.5*bs_bsl/xyratio], 0.5, 0.05);
  draw_rect([0.75, 0, 0.5, mean(bsl_data{1}.fmax_bst)], color1, '');
  draw_rect([1.75, 0, 0.5, mean(bsl_data{2}.fmax_bst)], color2, '');
  draw_rect([ll_bsl(1), ll_bsl(2), bs_bsl, bs_bsl/2], res.col, res.value);

  text(bar_xmin-.1*bar_xrange, bar_ymax+.2*bar_yrange, 'B.', 'FontSize', 14, 'FontWeight', 'bold');
  text(2, bar_ymax, 'Naive', 'FontSize', 12, 'FontWeight', 'bold');

  ax_naive.XLim         = [bar_xmin, bar_xmax];
  ax_naive.YLim         = [bar_ymin, bar_ymax];
  ax_naive.Box          = 'off';
  ax_naive.XTick        = [1, 2];
  ax_naive.XTickLabel   = {'2011', '2014'};
  % }}}

  % plot BLAST comparison {{{
  ax_blast = axes('Position', [0.55, 0.05, 0.4, 0.35]);
  res = bsl_info(bsl_data{3}, bsl_data{4}, margin_max, color1, color2);

  draw_bracket([1.5, bar_ymax-0.5*bs_bsl/xyratio], 0.5, 0.05);
  draw_rect([0.75, 0, 0.5, mean(bsl_data{3}.fmax_bst)], color1, '');
  draw_rect([1.75, 0, 0.5, mean(bsl_data{4}.fmax_bst)], color2, '');
  draw_rect([ll_bsl(1), ll_bsl(2), bs_bsl, bs_bsl/xyratio], res.col, res.value);

  text(bar_xmin-.1*bar_xrange, bar_ymax+.2*bar_yrange, 'C.', 'FontSize', 14, 'FontWeight', 'bold');
  text(2, bar_ymax, 'BLAST', 'FontSize', 12, 'FontWeight', 'bold');

  ax_blast.XLim         = [bar_xmin, bar_xmax];
  ax_blast.YLim         = [bar_ymin, bar_ymax];
  ax_blast.Box          = 'off';
  ax_blast.XTick        = [1, 2];
  ax_blast.XTickLabel   = {'2011', '2014'};
  % }}}

  embed_canvas(h, 8, 5);
  print(gcf, pfile, device_op, '-r300');
  close;
  % }}}
return

% function: draw_rect {{{
function [r] = draw_rect(pos, col, label)
  r = rectangle('Position', pos);
  r.EdgeColor = 'black';
  r.FaceColor = col;
  if ~isempty(label)
    t = text(pos(1)+0.5*pos(3), pos(2)+0.5*pos(4), label);
    t.HorizontalAlignment = 'center';
  end
return
% }}}

% function: draw_bracket {{{
function [] = draw_bracket(center, width, height)
  line(center(1) + [-width, width], repmat(center(2), 1, 2), 'Color', 'black');
  line(repmat(center(1)-width, 1, 2), center(2) + [-height, 0], 'Color', 'black');
  line(repmat(center(1)+width, 1, 2), center(2) + [-height, 0], 'Color', 'black');
return
% }}}

% function: bsl_info {{{
function [res] = bsl_info(bsl1, bsl2, margin_max, color1, color2)
  b1 = mean(bsl1.fmax_bst);
  b2 = mean(bsl2.fmax_bst);
  m  = abs(b1 - b2);

  ratio = min(1.0, m / margin_max);
  if b1 > b2
    res.winner = 1;
    res.value = sprintf('%.1f', sum(bsl1.fmax_bst > bsl2.fmax_bst) / 100);
    res.col = [1, 1, 1] - ratio * ([1, 1, 1] - color1);
  else
    res.winner = 2;
    res.value = sprintf('%.1f', sum(bsl2.fmax_bst > bsl1.fmax_bst) / 100);
    res.col = [1, 1, 1] - ratio * ([1, 1, 1] - color2);
  end
return
% }}}

% function: draw_colorbox {{{
function [] = draw_colorbox(pos, color1, color2)
  ns = 40; % number of scales
  scale1 = [linspace(color1(1), 1, ns); linspace(color1(2), 1, ns); linspace(color1(3), 1, ns)]';
  scale2 = [linspace(color2(1), 1, ns); linspace(color2(2), 1, ns); linspace(color2(3), 1, ns)]';
  scale = [scale1(1:end-1,:); flipud(scale2)];

  n = size(scale, 1);

  xpos = linspace(pos(1), pos(1)+pos(3), n+1); xpos(end) = [];
  ypos = pos(2);
  width = xpos(2) - xpos(1);
  height = pos(4);
  for i = 1 : n
    rectangle('Position', [xpos(i), ypos, width, height], ...
    'FaceColor', scale(i,:), 'EdgeColor', scale(i,:));
  end
return
% }}}

% -------------
% Yuxiang Jiang (yuxjiang@indiana.edu)
% Department of Computer Science
% Indiana University Bloomington
% Last modified: Wed 17 Feb 2016 04:45:29 PM E
