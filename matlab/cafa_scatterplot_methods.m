function [] = cafa_scatterplot_methods(pfile, task)
% CAFA_SCATTERPLOT_METHODS CAFA scatterplot for methods
%
% [] = CAFA_SCATTERPLOT_METHODS(pfile, task);
%
%   Makes a scatterplot of two categories of performances over methods.
%
% Input
% -----
% [char]
% pfile:  The filename of the plot.
%         Note that the file extension must be either 'eps' or 'png'.
%         default: 'png'
%
% [char]
% task:   The comparison task, possible tasks:
%         'EH'  - easy vs. hard
%         'EP'  - eukarya vs. prokarya
%         'FNS' - Fmax vs normalized Smin
%         'FS'  - Fmax vs Smin
%         'FP'  - Full mode vs. partial mode
%
% Output
% ------
% None.
%
% Dependency
% ----------
%[>]embed_canvas.m

  % check inputs {{{
  if nargin ~= 2
    error('cafa_scatterplot_methods:InputCount', 'Expected 2 inputs.');
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

  % task
  valid_tasks = {'EH', 'EP', 'FNS', 'FS', 'FP'};
  task = validatestring(task, valid_tasks, '', 'task', 2);
  if strcmp(task, 'EH')
    pttl = 'Easy vs. Difficult';
    xlab = 'Fmax on Easy benchmarks';
    ylab = 'Fmax on Difficult benchmarks';
  elseif strcmp(task, 'EP')
    pttl = 'Eukarya vs. Prokarya (Fmax)';
    xlab = 'Fmax on Eukarya benchmarks';
    ylab = 'Fmax on Prokarya benchmarks';
  elseif strcmp(task, 'FNS')
    pttl = 'Fmax vs. normalized Smin';
    xlab = 'Fmax (all benchmarks)';
    ylab = 'normalized Smin (all benchmarks)';
  elseif strcmp(task, 'FS')
    pttl = 'Fmax vs. Smin';
    xlab = 'Fmax (all benchmarks)';
    ylab = 'Smin (all benchmarks)';
  elseif strcmp(task, 'FP')
    pttl = 'Full mode vs. Partial mode (Fmax)';
    xlab = 'Fmax in full mode (all benchmarks)';
    ylab = 'Fmax in partial mode (all benchmarks)';
  else
    % do nothing
  end
  % }}}

  % collect data {{{
  evdir = '~/cafa/evaluation/';
  if strcmp(task, 'EH')
    mfo_data_x = loc_extract_field_from_collection(cafa_collect([evdir, 'mfo_easy_type1_mode1'], 'seq_fmax'), 'fmax', 'BN4S', 'BB4S');
    mfo_data_y = loc_extract_field_from_collection(cafa_collect([evdir, 'mfo_hard_type1_mode1'], 'seq_fmax'), 'fmax', 'BN4S', 'BB4S');
    bpo_data_x = loc_extract_field_from_collection(cafa_collect([evdir, 'bpo_easy_type1_mode1'], 'seq_fmax'), 'fmax', 'BN4S', 'BB4S');
    bpo_data_y = loc_extract_field_from_collection(cafa_collect([evdir, 'bpo_hard_type1_mode1'], 'seq_fmax'), 'fmax', 'BN4S', 'BB4S');
    cco_data_x = loc_extract_field_from_collection(cafa_collect([evdir, 'cco_easy_type1_mode1'], 'seq_fmax'), 'fmax', 'BN4S', 'BB4S');
    cco_data_y = loc_extract_field_from_collection(cafa_collect([evdir, 'cco_hard_type1_mode1'], 'seq_fmax'), 'fmax', 'BN4S', 'BB4S');
    % hpo_data_x = loc_extract_field_from_collection(cafa_collect([evdir, 'hpo_HUMAN_type1_mode1'], 'seq_fmax'), 'fmax', 'BN4H', 'BB4H');
    % hpo_data_y = hpo_data_x;
  elseif strcmp(task, 'EP')
    mfo_data_x = loc_extract_field_from_collection(cafa_collect([evdir, 'mfo_eukarya_type1_mode1'], 'seq_fmax'), 'fmax', 'BN4S', 'BB4S');
    mfo_data_y = loc_extract_field_from_collection(cafa_collect([evdir, 'mfo_prokarya_type1_mode1'], 'seq_fmax'), 'fmax', 'BN4S', 'BB4S');
    bpo_data_x = loc_extract_field_from_collection(cafa_collect([evdir, 'bpo_eukarya_type1_mode1'], 'seq_fmax'), 'fmax', 'BN4S', 'BB4S');
    bpo_data_y = loc_extract_field_from_collection(cafa_collect([evdir, 'bpo_prokarya_type1_mode1'], 'seq_fmax'), 'fmax', 'BN4S', 'BB4S');
    cco_data_x = loc_extract_field_from_collection(cafa_collect([evdir, 'cco_eukarya_type1_mode1'], 'seq_fmax'), 'fmax', 'BN4S', 'BB4S');
    cco_data_y = loc_extract_field_from_collection(cafa_collect([evdir, 'cco_prokarya_type1_mode1'], 'seq_fmax'), 'fmax', 'BN4S', 'BB4S');
    % hpo_data_x = loc_extract_field_from_collection(cafa_collect([evdir, 'hpo_HUMAN_type1_mode1'], 'seq_fmax'), 'fmax', 'BN4H', 'BB4H');
  elseif strcmp(task, 'FNS')
    mfo_data_x = loc_extract_field_from_collection(cafa_collect([evdir, 'mfo_all_type1_mode1'], 'seq_fmax'), 'fmax', 'BN4S', 'BB4S');
    mfo_data_y = loc_extract_field_from_collection(cafa_collect([evdir, 'mfo_all_type1_mode1'], 'seq_nsmin'), 'smin', 'BN4S', 'BB4S');
    bpo_data_x = loc_extract_field_from_collection(cafa_collect([evdir, 'bpo_all_type1_mode1'], 'seq_fmax'), 'fmax', 'BN4S', 'BB4S');
    bpo_data_y = loc_extract_field_from_collection(cafa_collect([evdir, 'bpo_all_type1_mode1'], 'seq_nsmin'), 'smin', 'BN4S', 'BB4S');
    cco_data_x = loc_extract_field_from_collection(cafa_collect([evdir, 'cco_all_type1_mode1'], 'seq_fmax'), 'fmax', 'BN4S', 'BB4S');
    cco_data_y = loc_extract_field_from_collection(cafa_collect([evdir, 'cco_all_type1_mode1'], 'seq_nsmin'), 'smin', 'BN4S', 'BB4S');
    hpo_data_x = loc_extract_field_from_collection(cafa_collect([evdir, 'hpo_HUMAN_type1_mode1'], 'seq_fmax'), 'fmax', 'BN4H', 'BB4H');
    hpo_data_y = loc_extract_field_from_collection(cafa_collect([evdir, 'hpo_HUMAN_type1_mode1'], 'seq_nsmin'), 'smin', 'BN4H', 'BB4H');
  elseif strcmp(task, 'FS')
    mfo_data_x = loc_extract_field_from_collection(cafa_collect([evdir, 'mfo_all_type1_mode1'], 'seq_fmax'), 'fmax', 'BN4S', 'BB4S');
    mfo_data_y = loc_extract_field_from_collection(cafa_collect([evdir, 'mfo_all_type1_mode1'], 'seq_smin'), 'smin', 'BN4S', 'BB4S');
    % bpo_data_x = loc_extract_field_from_collection(cafa_collect([evdir, 'bpo_all_type1_mode1'], 'seq_fmax'), 'fmax', 'BN4S', 'BB4S');
    % bpo_data_y = loc_extract_field_from_collection(cafa_collect([evdir, 'bpo_all_type1_mode1'], 'seq_nsmin'), 'smin', 'BN4S', 'BB4S');
    % cco_data_x = loc_extract_field_from_collection(cafa_collect([evdir, 'cco_all_type1_mode1'], 'seq_fmax'), 'fmax', 'BN4S', 'BB4S');
    % cco_data_y = loc_extract_field_from_collection(cafa_collect([evdir, 'cco_all_type1_mode1'], 'seq_nsmin'), 'smin', 'BN4S', 'BB4S');
    % hpo_data_x = loc_extract_field_from_collection(cafa_collect([evdir, 'hpo_HUMAN_type1_mode1'], 'seq_fmax'), 'fmax', 'BN4H', 'BB4H');
    % hpo_data_y = loc_extract_field_from_collection(cafa_collect([evdir, 'hpo_HUMAN_type1_mode1'], 'seq_nsmin'), 'smin', 'BN4H', 'BB4H');
  elseif strcmp(task, 'FP')
    mfo_data_x = loc_extract_field_from_collection(cafa_collect([evdir, 'mfo_all_type1_mode1'], 'seq_fmax'), 'fmax', 'BN4S', 'BB4S');
    mfo_data_y = loc_extract_field_from_collection(cafa_collect([evdir, 'mfo_all_type1_mode2'], 'seq_fmax'), 'fmax', 'BN4S', 'BB4S');
    bpo_data_x = loc_extract_field_from_collection(cafa_collect([evdir, 'bpo_all_type1_mode1'], 'seq_fmax'), 'fmax', 'BN4S', 'BB4S');
    bpo_data_y = loc_extract_field_from_collection(cafa_collect([evdir, 'bpo_all_type1_mode2'], 'seq_fmax'), 'fmax', 'BN4S', 'BB4S');
    cco_data_x = loc_extract_field_from_collection(cafa_collect([evdir, 'cco_all_type1_mode1'], 'seq_fmax'), 'fmax', 'BN4S', 'BB4S');
    cco_data_y = loc_extract_field_from_collection(cafa_collect([evdir, 'cco_all_type1_mode2'], 'seq_fmax'), 'fmax', 'BN4S', 'BB4S');
    hpo_data_x = loc_extract_field_from_collection(cafa_collect([evdir, 'hpo_HUMAN_type1_mode1'], 'seq_fmax'), 'fmax', 'BN4H', 'BB4H');
    hpo_data_y = loc_extract_field_from_collection(cafa_collect([evdir, 'hpo_HUMAN_type1_mode2'], 'seq_fmax'), 'fmax', 'BN4H', 'BB4H');
  else
    % do nothing
  end

  mfo_data = loc_pair_data_xy(mfo_data_x, mfo_data_y);
  % bpo_data = loc_pair_data_xy(bpo_data_x, bpo_data_y);
  % cco_data = loc_pair_data_xy(cco_data_x, cco_data_y);
  % if ismember(task, {'FNS', 'FS', 'FP'})
  %   hpo_data = loc_pair_data_xy(hpo_data_x, hpo_data_y);
  % end
  % }}}

  % setup {{{
  cmfo = [  0,  83, 159] / 255;
  cbpo = [196,  48,  43] / 255;
  ccco = [250, 149,   0] / 255;
  chpo = [ 32, 128,  80] / 255;
  cnaive = [1, 0, 0];
  cblast = [0, 0, 1];
  % }}}

  % plotting {{{
  h = figure('Visible', 'off'); hold on; axis square; grid on;

  % draw a diagonal dash line
  if ~strcmp(task, 'FS')
    x = 0.0 : 0.05 : 1.0;
    if ismember(task, {'FNS', 'FS'})
      plot(x, 1-x, 'k--');
    else
      plot(x, x, 'k--');
    end
  end

  % plot methods
  scatter(mfo_data.points(:,1), mfo_data.points(:,2), 'MarkerEdgeColor', cmfo);
  % scatter(bpo_data.points(:,1), bpo_data.points(:,2), 'MarkerEdgeColor', cbpo);
  % scatter(cco_data.points(:,1), cco_data.points(:,2), 'MarkerEdgeColor', ccco);
  % if ismember(task, {'FNS', 'FS', 'FP'})
  %   scatter(hpo_data.points(:,1), hpo_data.points(:,2), 'MarkerEdgeColor', chpo);
  % end

  % mark baseline methods
  plot(mfo_data.points(mfo_data.naive,1), mfo_data.points(mfo_data.naive,2), '.', 'Color', cnaive, 'MarkerSize', 15);
  plot(mfo_data.points(mfo_data.blast,1), mfo_data.points(mfo_data.blast,2), '.', 'Color', cblast, 'MarkerSize', 15);
  % plot(bpo_data.points(bpo_data.naive,1), bpo_data.points(bpo_data.naive,2), '.', 'Color', cnaive, 'MarkerSize', 15);
  % plot(bpo_data.points(bpo_data.blast,1), bpo_data.points(bpo_data.blast,2), '.', 'Color', cblast, 'MarkerSize', 15);
  % plot(cco_data.points(cco_data.naive,1), cco_data.points(cco_data.naive,2), '.', 'Color', cnaive, 'MarkerSize', 15);
  % plot(cco_data.points(cco_data.blast,1), cco_data.points(cco_data.blast,2), '.', 'Color', cblast, 'MarkerSize', 15);
  % if ismember(task, {'FNS', 'FS', 'FP'})
  %   plot(hpo_data.points(hpo_data.naive,1), hpo_data.points(hpo_data.naive,2), '.', 'Color', cnaive, 'MarkerSize', 15);
  %   plot(hpo_data.points(hpo_data.blast,1), hpo_data.points(hpo_data.blast,2), '.', 'Color', cblast, 'MarkerSize', 15);
  % end

  title(pttl);
  xlabel(xlab);
  ylabel(ylab);

  ax = gca;
  ax.XTick = 0:0.2:1.0;
  xlim([0, 1]);

  if ~strcmp(task, 'FS')
    ax.YTick = 0:0.2:1.0;
    ylim([0, 1]);
  else
    ylim([0, 15]);
  end

  embed_canvas(h, 5, 5);
  print(h, pfile, device_op, '-r300');
  close;
  % }}}
return

% function: loc_extract_field_from_collection {{{
function [res] = loc_extract_field_from_collection(data, field, naive, blast)
  n = numel(data);
  res.id  = cell(1, n);
  res.val = zeros(1, n);
  for i = 1 : n
    res.id{i}  = data{i}.id;
    res.val(i) = data{i}.(field);
  end
  % remove other baseline methods
  other_baseline = (~ismember(res.id, {naive, blast})) & cellfun(@(x) x(1) == 'B', res.id);
  res.id(other_baseline)  = [];
  res.val(other_baseline) = [];
return
% }}}

% function: loc_pair_data_xy {{{
function [res] = loc_pair_data_xy(data_x, data_y)
  id = union(data_x.id, data_y.id);
  [~, index_x] = ismember(data_x.id, id);
  [~, index_y] = ismember(data_y.id, id);

  res.points = zeros(numel(id), 2);
  res.points(index_x, 1) = reshape(data_x.val, [], 1);
  res.points(index_y, 2) = reshape(data_y.val, [], 1);
  res.naive = find(cellfun(@(x) x(2) == 'N', id));
  res.blast = find(cellfun(@(x) x(2) == 'B', id));
return
% }}}

% -------------
% Yuxiang Jiang (yuxjiang@indiana.edu)
% Department of Computer Science
% Indiana University, Bloomington
% Last modified: Mon 23 May 2016 04:48:50 PM E
