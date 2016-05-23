function [] = cafa_plot_term_avgauc(pfile, pttl, aucs, ont, yaxis)
%CAFA_PLOT_TERM_AVGAUC CAFA plot term-centric averaged AUC
%
% [] = CAFA_PLOT_TERM_AVGAUC(pfile, pttl, aucs, ont, yaxis);
%
%   Plots the sorted averaged-AUC per term.
%   If the number of terms is greater than 20, this function generates 3 plots:
%   (1) averaged AUC for all terms, (2) ... for the top 10 terms and (3) ... for
%   the bottom 10 terms, otherwise, it only generates a boxplot for all terms.
%
%
% Input
% -----
% (required)
% [char]
% pfile:    The filename of the plot.
%           Note that the file extension must be ont of 'eps', or 'png'.
%           default: 'png'
%
% [char]
% pttl:     The plot title.
%
% [cell]
% aucs:     The collected 'term_auc' structures. Each cell has
%           .id   [char]    The model name, used for naming files.
%           .term [cell]    1-by-m, term names. ('m': the number of terms)
%           .auc  [double]  1-by-m, AUC estimates.
%           .mode [double]  The evaluation mode, passed through from input.
%           .npos [double]  The number of positive annotations cutoff, passed
%                           through from input.
%           See cafa_eval_term_auc.m, cafa_collect.m
%
% [struct]
% ont:      The ontology structure. See pfp_ontbuild.m
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
%[>]pfp_gettermidx.m
%[>]pfp_ancestortermidx.m
%[>]pfp_offspringtermidx.m
%[>]embed_canvas.m
%
% See Also
% --------
%[>]cafa_eval_term_auc.m
%[>]cafa_collect.m
%[>]pfp_ontbuild.m

  % check inputs {{{
  if nargin < 4 || nargin > 5
    error('cafa_plot_term_avgauc:InputCount', 'Expected 4 or 5 inputs.');
  end

  if nargin == 4
    yaxis = [];
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

  plot_filename_all = strcat(p, '/', f, '_all', ext);
  plot_filename_top = strcat(p, '/', f, '_top', ext);
  plot_filename_bot = strcat(p, '/', f, '_bot', ext);

  % pttl
  validateattributes(pttl, {'char'}, {}, '', 'pttl', 2);

  % aucs
  validateattributes(aucs, {'cell'}, {'nonempty'}, '', 'aucs', 3);
  n = numel(aucs);
  m = numel(aucs{1}.term);

  % ont
  validateattributes(ont, {'struct'}, {}, '', 'ont', 4);
  tids   = aucs{1}.term;
  tnames = {ont.term(pfp_gettermidx(ont, aucs{1}.term)).name};

  % yaxis
  validateattributes(yaxis, {'double'}, {}, '', 'yaxis', 5);
  if isempty(yaxis)
    is_adaptive = true;
  else
    is_adaptive = false;
  end
  % }}}

  % collect AUCs and compute the average {{{
  auc_mat = zeros(n, m);
  for i = 1 : n
    if numel(aucs{i}.term) ~= m
      error('cafa_plot_term_avgauc:DimErr', 'Inconsistent number of terms of [%s]', aucs{i}.id);
    end
    auc_mat(i, :) = aucs{i}.auc;
  end
  % }}}

  % average and sort {{{
  avg_auc = nanmean(auc_mat, 1);
  [s_auc_avg, order] = sort(avg_auc, 'descend');

  % remove NaN avg_auc's
  drop        = isnan(s_auc_avg);
  order(drop) = [];

  % update 'm'
  m = numel(order);
  % }}}

  % settings {{{
  base_fs = 10;
  % fcolor  = [0.6, 0.6, 0.6];
  % bcolor  = [0.8, 0.3, 0.3];
  fcolor  = [  0,  83, 159]/255;
  bcolor  = [196,  48,  43]/255; % color for the naive baseline
  bar_w   = 0.8;
  % }}}

  % branching {{{
  if m > 20
    % barplot for all {{{
    h = figure('Visible', 'off');
    hold on;

    b = bar(s_auc_avg, bar_w);
    bsl_naive = b.BaseLine;
    set(b, 'FaceColor', fcolor);
    set(b, 'EdgeColor', fcolor);

    ax = gca;
    ax.XTickMode  = 'manual';
    ax.XLim       = [0, m+1];
    if ~is_adaptive
      ax.YLim  = [yaxis(1), yaxis(2)];
      ax.YTick = yaxis(1):yaxis(3):yaxis(2);
    end
    ax.XTickLabel = [];
    ax.FontSize   = base_fs;
    box off;

    % work-around for setting x-axis invisible
    ax.XColor     = 'white';
    ax.XColorMode = 'manual';

    % modify BaseLine (naive)
    bsl_naive.BaseValue = 0.5;
    bsl_naive.Color = bcolor;
    bsl_naive.LineStyle = ':';
    bsl_naive.LineWidth = 3;

    title(pttl);
    ylabel('Averaged AUC');
    xlabel('Terms sorted by AUC (not shown)');

    embed_canvas(h, 5, 4);
    print(h, plot_filename_all, device_op, '-r300');
    close;
    % }}}

    % boxplot for tops {{{

    % select top 10
    % sel = order(1:10);

    % select independent top 10
    index = loc_pick_top_terms(ont, pfp_gettermidx(ont, tids(order)), 10);
    [~, sel] = ismember({ont.term(index).id}, tids);

    h = figure('Visible', 'off');
    b = boxplot(auc_mat(:, sel), 'Colors', fcolor);

    ax = gca;
    ax.XTickLabel = loc_make_label(aucs{1}.term(sel), tnames(sel));
    ax.XTickLabelRotation = 45;
    ax.FontSize = base_fs;
    if ~is_adaptive
      ax.YLim  = [yaxis(1), yaxis(2)];
      ax.YTick = yaxis(1):yaxis(3):yaxis(2);
    end

    ylabel('AUC');

    embed_canvas(h, 5, 4);
    print(h, plot_filename_top, device_op, '-r300');
    close;
    % }}}

    % boxplot for bottoms {{{
    sel = order(end-10:end); % select bottom 10
    h = figure('Visible', 'off');
    b = boxplot(auc_mat(:, sel), 'Colors', fcolor);

    ax = gca;
    ax.XTickLabel = loc_make_label(aucs{1}.term(sel), tnames(sel));
    ax.XTickLabelRotation = 45;
    if ~is_adaptive
      ax.YLim  = [yaxis(1), yaxis(2)];
      ax.YTick = yaxis(1):yaxis(3):yaxis(2);
    end

    ylabel('AUC');

    embed_canvas(h, 5, 4);
    print(h, plot_filename_bot, device_op, '-r300');
    close;
    % }}}
  else
    % boxplot for all {{{
    sel = order; % select all
    h = figure('Visible', 'off');
    b = boxplot(auc_mat(:, sel), 'Colors', fcolor);

    ax = gca;
    ax.XTickLabel = loc_make_label(aucs{1}.term(sel), tnames(sel));
    ax.XTickLabelRotation = 45;
    if ~is_adaptive
      ax.YLim  = [yaxis(1), yaxis(2)];
      ax.YTick = yaxis(1):yaxis(3):yaxis(2);
    end

    ylabel('AUC');

    embed_canvas(h, 5, 4);
    print(h, plot_filename_all, device_op, '-r300');
    close;
    % }}}
  end
  % }}}
return

% function: loc_make_label {{{
function [labels] = loc_make_label(tacc, tname)
  n = numel(tacc);
  labels = cell(1, n);
  for i = 1 : numel(tname)
    if numel(tname{i}) > 100
      labels{i} = strcat(tname{i}(1:18), '..', tacc{i});
    else
      labels{i} = tname{i};
    end
  end
return
% }}}

% function: loc_pick_top_terms {{{
function [sel] = loc_pick_top_terms(ont, order, n)
  % pick top n independent terms, by "independent", we mean,
  % for each pair of picked terms, their ancestors have only one intersection
  % term: the root term.

  sel = [];
  anc = {}; % ancestor index set corresponding to each selected term index

  remained = order;
  while ~isempty(remained)
    index = remained(1);

    % ancestor's index and offspring's index
    off_set = pfp_offspringtermidx(ont, ont.term(index));
    anc_set = pfp_ancestortermidx(ont, ont.term(index));

    to_keep = true;
    for j = 1 : numel(sel)
      if numel(intersect(anc{j}, anc_set)) > 1
        to_keep = false;
        break;
      end
    end

    if to_keep
      sel = [sel, index];
      anc = [anc, {anc_set}];
    end

    if numel(sel) >= n
      break;
    end

    % speed-up;
    % remove its offspring and ancestor terms' index
    % note that both of these two sets is self-included
    remained(ismember(remained, off_set) | ismember(remained, anc_set)) = [];
  end
  if numel(sel) < n
    warning('Not enough independent terms.');
  end
return
% }}}

% -------------
% Yuxiang Jiang (yuxjiang@indiana.edu)
% Department of Computer Science
% Indiana University Bloomington
% Last modified: Mon 23 May 2016 05:17:24 PM E
