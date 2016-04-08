function [] = cafa_plot_pred_cluster(pfile, pttl, ps, reg, mid)
%CAFA_PLOT_PRED_CLUSTER CAFA plot prediction cluster
% {{{
%
% [] = CAFA_PLOT_PRED_CLUSTER(pfile, pttl, ps, reg);
% [] = CAFA_PLOT_PRED_CLUSTER(pfile, pttl, ps, reg, mid);
%
%   Plots prediction clustering as a color-matrix (using PCC).
%
% Note:
% 'Distance' between prediction pi, pj is computed as 1 - PCC(pi, pj).
%
% Input
% -----
% (required)
% [char]
% pfile:  The filename of the plot.
%         Note that the file extension should be either 'eps' or 'png'.
%         default: 'png'
%
% [char]
% pttl:   The plot title.
%
% [struct]
% ps:     The precomputed PCC structure.
%         See cafa_get_pred_pcc.m
%
% [char]
% reg:    The register file.
%
% (optional)
% [cell or char]
% mid:    A list of team names to disclose.
%         default: {} (anonymize all methods, only display internal IDs.)
%         Note: available bundle options:
%         'all'   - all methods
%         'topK' - top 10 methods, 'K' could be any positive integers.
%
% Output
% ------
% None.
%
% Dependency
% ----------
%[>]cafa_team_register.m
%[>]pfp_rgby.m
%[>]embed_canvas.m
%
% See Also
% --------
%[>]cafa_get_pred_pcc.m
%[>]cafa_collect.m
%[>]cafa_sel_top_seq_fmax.
% }}}

  % check inputs {{{
  if nargin ~= 4 && nargin ~= 5
    error('cafa_plot_pred_cluster:InputCount', 'Expected 4 or 5 inputs.');
  end

  if nargin == 4
    mid = {};
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

  % check the 3rd input 'ps' {{{
  validateattributes(ps, {'struct'}, {'nonempty'}, '', 'ps', 3);
  % }}}

  % check the 4th input 'reg' {{{
  validateattributes(reg, {'char'}, {'nonempty'}, '', 'reg', 4);
  [model.id, ~, model.nm] = cafa_team_register(reg);
  % }}}

  % check the 5th input 'mid' {{{
  validateattributes(mid, {'cell', 'char'}, {}, '', 'mid', 5);
  % }}}
  % }}}

  % create labels to display accordingly {{{
  % translate 'mid' [char] -> [cell] if needed
  if ischar(mid)
    if strcmp(mid, 'all') % all
      mid = ps.mid;
    else % top?
      key = regexp(mid, 'top([0-9]+)?$', 'match', 'once');
      if isempty(key)
        error('cafa_plot_pred_cluster:MIDErr', 'Unknown mid token.');
      end
      k = str2double(key(4:end));
      if isnan(k)
        k = 10; % pick top k=10 if k is omitted.
      end
      fmaxs = cafa_collect(config.eval_dir, 'seq_fmax_bst');
      [~, ~, info] = cafa_sel_top_seq_fmax(10, fmaxs, '', '', reg, false);
      mid = info.top_mid;
    end
  end

  labels = ps.mid; % all in anonymous mode

  % make sure all mid (to be revealed) are presented in 'ps'
  [found, reveal_id] = ismember(mid, labels);
  if ~all(found)
    error('cafa_plot_pred_cluster:MIDErr', 'Some models are not found in ''ps'' structure.');
  end

  % extract team "full" name of mid (to be revealed)
  [found, index] = ismember(labels(reveal_id), model.id);
  if ~all(found)
    error('cafa_plot_pred_cluster:MIDErr', 'Some models are not found in register file.');
  end
  labels(reveal_id) = model.id(index);
  % }}}

  % re-order according to clustering {{{
  dist   = 1 - ps.pcc;
  D      = squareform(dist);
  tree   = linkage(D);
  order  = optimalleaforder(tree, D);

  dist   = dist(order, order);
  labels = labels(order);
  % }}}

  % settings {{{
  base_fs = 5;

  [maxcolor, ~, mincolor] = pfp_rgby;
  midcolor = [  1,   1,   1]; % white

  pw = 0.95; % patch width
  % }}}

  % draw heatmap {{{
  % compute colors to display {{{
  n = numel(labels);

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
  % }}}

  h = figure('Visible', 'off');

  ax = gca;
  ax.Visible = 'off';
  ax.Position = [0.1, 0.1, 0.9, 0.9];

  % put title
  text((1+n)/2, 1.05*n, pttl, 'FontSize', base_fs+6, 'HorizontalAlignment', 'center');

  for i = 1 : n
    % mark labels
    text(i, 0, labels{i}, 'Rotation', 90, 'HorizontalAlignment', 'right', 'FontSize', base_fs);
    text(0, i, labels{i}, 'HorizontalAlignment', 'right', 'FontSize', base_fs);
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
% Last modified: Thu 07 Apr 2016 09:42:42 PM E
