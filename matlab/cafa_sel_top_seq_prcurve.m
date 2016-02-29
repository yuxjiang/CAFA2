function [sel, bsl] = cafa_sel_top_seq_prcurve(K, prcurves, naive, blast, config, isdump, rmcurves)
%CAFA_SEL_TOP_SEQ_FMAX CAFA select top sequence-centric Fmax
% {{{
%
% [sel, bsl] = CAFA_SEL_TOP0_SEQ_FMAX(K, prcurves, naive, blast, config, isdump);
%
%   Picks the top precision-recall curves in Fmax.
%
% [sel, bsl] = CAFA_SEL_TOP0_SEQ_FMAX(K, prcurves, naive, blast, config, isdump, rmcurves);
%
%   Picks the top precision-recall curves in Fmax (output corresponding optimal
%   Smin ru-mi pairs).
%
% Input
% -----
% (required)
% [double]
% K:        The number of teams/methods to pick.
%
% [cell]
% prcurves: The pre-calculated precision-recall curve structures.
%           [char]      [1-by-n]    .id
%           [double]    [k-by-2]    .curve
%           [double]    [1-by-k]    .tau
%           [double]    [1-by-1]    .ncovered
%           [double]    [1-by-1]    .coverage
%
%           See cafa_eval_seq_prcurve.m
%
% [char]
% naive:    The model id of the naive baseline. E.g. BN4S
%           Could be empty: '' if not interested.
%
% [char]
% blast:    The model id of the blast baseline. E.g. BB4S
%           Could be empty: '' if not interested.
%
% [char]
% config:   The team info file which should have the following columns:
%
%         * 1. <internalID>
%         * 2. <externalID>
%           3. <teamname>
%         * 4. <type>
%         * 5. <displayname>
%         * 6. <dumpname>
%         * 6. <pi>
%           7. <keyword list>
%         * 8. <assigned color>
%
%           Note:
%           1. The starred columns (*) will be used in this function.
%           2. 'type':  'q'  - qualified
%                       'd'  - disqualified
%                       'n'  - Naive method (baseline 1)
%                       'b'  - BLAST method (baseline 2)
%
% [logical]
% isdump:   A switch for using dump name instead of display name.
%           default: false.
%
% (optional)
% [cell]
% rmcurves: The pre-calculated RU-MI curve structures.
%           [char]      [1-by-n]    .id
%           [double]    [k-by-2]    .curve
%           [double]    [1-by-k]    .tau
%           [double]    [1-by-1]    .ncovered
%           [double]    [1-by-1]    .coverage
%
%           See cafa_eval_seq_rmcurve.m
%
% Output
% ------
% [cell]
% sel:  The curves and related information ready for plotting:
%
%       [double]
%       .curve      n x 2, points on the curve.
%
%       [double]
%       .opt_point  1 x 2, the optimal point (corresp. to Fmax).
%
%       [double] (optional: if 'rmcurves' is present)
%       .alt_point  1 x 2, the alternative point (corresp. to Smin).
%
%       [char]
%       .tag        for the legend of the plot.
%
%       [char]
%       .pi_name    name of the PI.
%
%       [double]
%       .color      assigned color (1-by-3 RGB tuple).
%
%
% [cell]
% bsl:  The baseline curves and related information. Each cell has the same
%       structure as 'sel'.
%
% Dependency
% ----------
%[>]pfp_fmaxc.m
%[>]pfp_sminc.m
%[>]cafa_collect.m
%[>]cafa_team_read_config.m
%[>]cafa_eval_seq_curve.m
% }}}

  % check inputs {{{
  if nargin < 6 || nargin > 7
    error('cafa_sel_top_seq_prcurve:InputCount', 'Expected 6 or 7 inputs.');
  end

  if nargin == 6
    rmcurves = {};
  end

  % check the 1st input 'K' {{{
  validateattributes(K, {'double'}, {'nonnegative', 'integer'}, '', 'K', 1);
  % }}}

  % check the 2nd input 'prcurves' {{{
  validateattributes(prcurves, {'cell'}, {'nonempty'}, '', 'prcurves', 2);
  % }}}

  % check the 3rd input 'naive' {{{
  validateattributes(naive, {'char'}, {}, '', 'naive', 3);
  % }}}

  % check the 4rd input 'blast' {{{
  validateattributes(blast, {'char'}, {}, '', 'blast', 4);
  % }}}

  % check the 5th input 'config' {{{
  validateattributes(config, {'char'}, {'nonempty'}, '', 'config', 5);
  [team_id, ext_id, ~, team_type, disp_name, dump_name, pi_name, ~, clr] = cafa_team_read_config(config);
  % }}}

  % check the 6th input 'isdump' {{{
  validateattributes(isdump, {'logical'}, {'nonempty'}, '', 'isdump', 6);
  if isdump
    disp_name = dump_name;
  end
  % }}}

  % check the 7th input 'rmcurves' {{{
  validateattributes(rmcurves, {'cell'}, {}, '', 'rmcurves', 7);
  if isempty(rmcurves)
    do_alt = false;
  else
    do_alt = true;
  end
  % }}}
  % }}}

  % clean up, and calculate Fmax {{{
  % 1. remove 'disqualified' teams;
  % 2. set aside baseline methods;
  % 3. match team names for display.
  % 4. calculate Fmax.

  n = numel(prcurves);
  qld = cell(1, n); % all qualified teams
  bsl = cell(1, 2); % two baseline methods
  fmaxs = zeros(1, n);
  kept = 0;

  % parse model number 1, 2 or 3 from external ID {{{
  % model_num = cell(1, n);
  % for i = 1 : n
  %     splitted_id = strsplit(ext_id{i}, '-');
  %     model_num{i} = splitted_id{2};
  % end
  % }}}

  for i = 1 : n
    index = find(strcmp(team_id, prcurves{i}.id));

    % remove points that are strickly less that another one {{{
    % (pr(i), rc(i)) is strickly less than (pr(j), rc(j)), if
    % pr(i) < pr(j) and rc(i) < rc(j).
    prcurves{i} = remove_points(prcurves{i});
    % }}}

    % remove the point on the curve that corresp. to tau = 0.00
    prcurves{i} = remove_tau0_point(prcurves{i});

    if strcmp(prcurves{i}.id, naive)
      bsl{1}.curve     = prcurves{i}.curve;
      [fmax, pt, ~]    = pfp_fmaxc(prcurves{i}.curve, prcurves{i}.tau);
      bsl{1}.opt_point = pt;

      if do_alt
        bsl{1}.alt_point = find_alt_point(prcurves{i}, rmcurves{i});
      end

      bsl{1}.tag     = sprintf('%s (F=%.2f,C=%.2f)', disp_name{index}, fmax, prcurves{i}.coverage);
      bsl{1}.pi_name = pi_name{index};
      bsl{1}.color   = (hex2dec(reshape(clr{index}, 3, 2))/255)';
    elseif strcmp(prcurves{i}.id, blast)
      bsl{2}.curve     = prcurves{i}.curve;
      [fmax, pt, ~]    = pfp_fmaxc(prcurves{i}.curve, prcurves{i}.tau);
      bsl{2}.opt_point = pt;

      if do_alt
        bsl{2}.alt_point = find_alt_point(prcurves{i}, rmcurves{i});
      end

      bsl{2}.tag     = sprintf('%s (F=%.2f,C=%.2f)', disp_name{index}, fmax, prcurves{i}.coverage);
      bsl{2}.pi_name = pi_name{index};
      bsl{2}.color   = (hex2dec(reshape(clr{index}, 3, 2))/255)';
    elseif strcmp(team_type(index), 'q') % qualified teams
      % filtering {{{
      % skip models with 0 coverage
      if prcurves{i}.coverage == 0
        continue;
      end

      % skip models covering less than 10 proteins
      if prcurves{i}.ncovered < 10
        continue;
      end

      [fmax, pt, ~] = pfp_fmaxc(prcurves{i}.curve, prcurves{i}.tau);

      % skip models with 'NaN' Fmax values
      if isnan(fmax)
        continue;
      end
      % }}}

      % collecting {{{
      kept = kept + 1;
      qld{kept}.curve     = prcurves{i}.curve;
      fmaxs(kept)         = fmax;
      qld{kept}.opt_point = pt;

      if do_alt
        qld{kept}.alt_point = find_alt_point(prcurves{i}, rmcurves{i});
      end

      qld{kept}.disp_name = disp_name{index};
      % qld{kept}.tag       = sprintf('%s-%s (F=%.2f,C=%.2f)', disp_name{index}, model_num{index}, fmax, prcurves{i}.coverage);
      qld{kept}.tag       = sprintf('%s (F=%.2f,C=%.2f)', disp_name{index}, fmax, prcurves{i}.coverage);
      qld{kept}.pi_name   = pi_name{index};
      qld{kept}.color     = (hex2dec(reshape(clr{index}, 3, 2))/255)';
      % }}}
    else
      % nop: ignore unmatched baselines and disqualified models
    end
  end
  qld(kept + 1 : end)   = []; % truncate the trailing empty cells
  fmaxs(kept + 1 : end) = [];
  % }}}

  % sort Fmax and pick the top K {{{
  % keep find the next team until
  % 1. find K (= 10) teams, or
  % 2. exhaust the list
  % Note that we only allow one model selected per pi.

  sel = cell(1, K);
  sel_pi = {};
  [~, index] = sort(fmaxs, 'descend');
  nsel = 0;
  for i = 1 : numel(qld)
    if ~ismember(qld{index(i)}.pi_name, sel_pi)
      nsel = nsel + 1;
      sel_pi{end + 1} = qld{index(i)}.pi_name;
      sel{nsel} = qld{index(i)};
    end
    if nsel == K
      break;
    end
  end
  if nsel < K
    warning('cafa_sel_top_seq_prcurve:LessThanK', 'Only selected %d models.', nsel);
    sel(nsel + 1 : end) = [];
  end
  % }}}
return

% function: remove_points {{{
function [pr] = remove_points(pr)
  precision = pr.curve(:, 1);
  recall    = pr.curve(:, 2);

  n = length(pr.tau);
  useless = false(n, 1);

  for i = 1 : n
    lt_both = (precision > precision(i)) & (recall > recall(i));
    eq_both = (precision == precision(i)) & (recall == recall(i));
    if any(lt_both & ~eq_both)
      useless(i) = true;
    end
  end
  if ~isempty(useless)
    pr.curve(useless, :) = [];
    pr.tau(useless)      = [];
  end
return
% }}}

% function: remove_tau0_point {{{
function [pr] = remove_tau0_point(pr)
  index = find(pr.tau == 0.00);
  if ~isempty(index)
    pr.curve(index, :) = [];
    pr.tau(index)      = [];
  end
return
% }}}

% function: find_alt_point {{{
function [point] = find_alt_point(prcurve, rmcurve)
  [~, ~, tau] = pfp_sminc(rmcurve.curve, rmcurve.tau);
  [~, index]  = min(abs(prcurve.tau - tau));
  point = prcurve.curve(index, :);
return
% }}}

% -------------
% Yuxiang Jiang (yuxjiang@indiana.edu)
% Department of Computer Science
% Indiana University Bloomington
% Last modified: Tue 16 Feb 2016 03:18:21 PM E
