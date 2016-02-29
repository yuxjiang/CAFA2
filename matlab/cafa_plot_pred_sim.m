function [team, sim, dist] = cafa_plot_pred_sim(pfile, pttl, config_info, method, mid, team_cfg)
%CAFA_PLOT_PRED_SIM CAFA plot prediction similarity
% {{{
%
% [team, sim, dist] = CAFA_PLOT_PRED_SIM(pfile, pttl, pred_dir, method, mid, team_cfg);
%
%   Plots prediction similarity.
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
% [char or struct]
% config_info:  the configuration file (job descriptor) or a parsed config
%               structure.
%
%               See cafa_parse_config.m
%
% [char]
% method:       one of the following:
%               1. 'pcorr':   Pearson's correlation over all proteins and terms
%               2. 'hamming': Hamming distance between binarized leaf terms'
%               score.
%
% (optional)
% [cell or char]
% mid:          a list of team names to disclose.
%               default: {}
%
%               Note: 'mid' could be set to 'all' for disclose all methods.
%
% [char]
% team_cfg:     the team information. It's not used if 'mid' is empty.
%               default: ''
%
% Output
% ------
% [cell]
% team:         Ordered team names on plot.
%
% [double]
% sim:          Similarity matrix. Could be one of the following depending on
%               the specified 'method'.
%               1. r, Pearson's correlation ('pcorr')
%               2. 1/d_H ('hamming')
%
% dist:         Distance matrix. Could be one of the following depending on the
%               specified 'method'.
%               1. 1-r ('pcorr')
%               2. d_H, Hamming distance ('hamming')
%
% Dependency
% ----------
%[>]cafa_parse_config.m
%[>]cafa_team_read_config.m
%[>]pfp_predproj.m
%[>]pfp_oaproj.m
%[>]pfp_annotsuboa.m
% }}}

  % check inputs {{{
  if nargin ~= 4 && nargin ~= 6
    error('cafa_plot_pred_sim:InputCount', 'Expected 4 or 6 inputs.');
  end

  if nargin == 4
    mid      = {};
    team_cfg = '';
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
  else
    config = config_info;
  end
  % }}}

  % check the 4th input 'method' {{{
  method = validatestring(method, {'pcorr', 'hamming'}, '', 'method', 4);
  % }}}

  % check the 5th input 'mid' {{{
  validateattributes(mid, {'cell', 'char'}, {}, '', 'mid', 5);
  if ischar(mid) && ~strcmp(mid, 'all')
    error('cafa_plot_pred_sim:MIDErr', 'Unknown mid token.');
  end
  % }}}

  % check the 6th input 'team_cfg' {{{
  if ~isempty(mid)
    validateattributes(team_cfg, {'char'}, {'nonempty'}, '', 'team_cfg', 6);
    [team_id, ~, team_name] = cafa_team_read_config(team_cfg);
  else
    % nop, 'team_cfg' is ignored.
  end
  % }}}
  % }}}

  % get team names to display {{{
  model_index = config.model;

  % remove unused baseline models: B[BN]1S
  index = cell2mat(cellfun(@(x) isempty(regexp(x, 'B[BN]1S')), config.model, 'UniformOutput', false));
  model_index = config.model(index);
  model_names = model_index;

  n = numel(model_index);

  % replace 'BN4S' with 'Naive', 'BB4S' with 'BLAST'
  model_names = regexprep(model_names, 'BN4[SH]', 'Naive');
  model_names = regexprep(model_names, 'BB4[SH]', 'BLAST');

  if ~isempty(mid)
    if ischar(mid) && strcmp(mid, 'all')
      mid = model_index;
    end
    [found, index] = ismember(mid, team_id);
    if ~all(found)
      error('cafa_plot_pred_sim:MIDErr', 'Some models are not found in team config.');
    end
    new_name = team_name(index);

    [found, index] = ismember(mid, model_index);
    if ~all(found)
      error('cafa_plot_pred_sim:MIDErr', 'Some models are not found in predictions.');
    end

    % replace names
    model_names(index) = new_name;

    model_names = regexprep(model_names, '_', '\\_'); % for "underscore"
  end
  % }}}

  % load and project predictions and ground-truth {{{
  fprintf('loading and projecting ... ');
  pred = cell(1, n);
  for i = 1 : n
    data = load(strcat(config.pred_dir, model_index{i}, '.mat'), 'pred');
    pred{i} = pfp_predproj(data.pred, config.bm, 'object');
  end

  oa = pfp_annotsuboa(pfp_oaproj(config.oa, config.bm, 'object'));
  fprintf('done.\n');
  % }}}

  % find lists of predicted proteins and terms {{{
  plist = cell(1, n);
  tlist = cell(1, n);
  for i = 1 : n
    has_score = pred{i}.score > 0;
    tlist{i} = full(find(any(has_score, 1))); % terms
    plist{i} = full(find(any(has_score, 2))); % proteins
  end
  % }}}

  % compute 'sim' and 'dist' {{{
  sim  = -ones(n);
  dist = zeros(n);

  fprintf('Computing pairwise similarity ... ');
  if strcmp(method, 'pcorr')
    % sim:  Pearson's correlation
    % dist: 1 - sim
    for i = 1 : n
      sim(i, i)  = 1;
      for j = i+1 : n
        % find indices of common proteins on which both i and j predicted
        pi = intersect(plist{i}, plist{j});

        % find indices of common terms on which both i and j have scores
        ti = intersect(tlist{i}, tlist{j});

        x = full(reshape(pred{i}.score(pi, ti), [], 1));
        y = full(reshape(pred{j}.score(pi, ti), [], 1));

        if ~isempty(x) && ~isempty(y)
          rho = corr(x, y);
          if ~isnan(rho)
            sim(i, j) = rho;
            sim(j, i) = sim(i, j);
          end
        end
      end
    end
    dist = 1 - sim; % compute 'dist' from 'sim'.
  elseif strcmp(method, 'hamming')
    % dist: Hamming distance
    % sim:  1 / (1 + dist)
    for i = 1 : n
      dist(i, i) = 0;
      for j = i+1 : n
        % find indices of common proteins on which both i and j predicted
        pi = intersect(plist{i}, plist{j});

        % find indices of common terms on which both i and j have scores
        ti = intersect(tlist{i}, tlist{j});
      end
    end
    % TBA
  else
    % nop
  end
  fprintf('done.\n');
  % }}}

  % re-order according to clustering {{{
  D = squareform(dist);
  tree  = linkage(D);
  order = optimalleaforder(tree, D);

  sim         = sim(order, order);
  dist        = dist(order, order);
  model_names = model_names(order);
  % }}}

  % settings {{{
  base_fs = 5;

  maxcolor = [196,  48,  43] / 255;
  midcolor = [  1,   1,   1]; % white
  mincolor = [  0,  83, 159] / 255;

  pw = 0.95; % patch width
  % }}}

  % draw heatmap {{{
  % compute colors to display {{{
  data = reshape(dist, 1, []);
  data(isinf(data)) = [];
  maxval = max(data);
  midval = median(data);
  value = cell(n, n);
  for i = 1 : n;
    value{i, i} = mincolor;
    for j = i+1 : n
      if isinf(dist(i, j))
        value{i, j} = maxcolor;
        value{j, i} = maxcolor;
      elseif dist(i, j) <= midval
        prop = dist(i, j) / midval;
        rc = mincolor + prop * (midcolor - mincolor);
        value{i, j} = max([[0, 0, 0]; rc]);
        % [0.99, 0.99, 0.99] is used to prevent a "bug"?
        value{i, j} = min([[0.99, 0.99, 0.99]; value{i, j}]);
        value{j, i} = value{i, j};
      else
        prop = (dist(i, j) - midval) / (maxval - midval);
        rc = midcolor + prop * (maxcolor - midcolor);
        value{i, j} = max([[0, 0, 0]; rc]);
        value{i, j} = min([[0.99, 0.99, 0.99]; value{i, j}]);
        value{j, i} = value{i, j};
      end
    end
  end
  team = model_names;
  % }}}

  h = figure('Visible', 'off');

  ax = gca;
  ax.Visible = 'off';
  ax.Position = [0.1, 0.1, 0.9, 0.9];

  % put title
  text((1+n)/2, 1.05*n, pttl, 'FontSize', base_fs+6, 'HorizontalAlignment', 'center');

  for i = 1 : n
    % mark labels
    text(i, 0, model_names{i}, 'Rotation', 90, 'HorizontalAlignment', 'right', 'FontSize', base_fs);
    text(0, i, model_names{i}, 'HorizontalAlignment', 'right', 'FontSize', base_fs);
    for j = 1 : n
      rpos = [i-1/2*pw, j-1/2*pw, pw, pw];
      rectangle('Position', rpos, 'FaceColor', value{i, j}, 'EdgeColor', value{i, j});
    end
  end
  embed_canvas(h, 12, 12);
  print(h, pfile, device_op, '-r300');
  % }}}
return

% -------------
% Yuxiang Jiang (yuxjiang@indiana.edu)
% Department of Computer Science
% Indiana University, Bloomington
% Last modified: Tue 28 Jul 2015 02:18:58 PM E
