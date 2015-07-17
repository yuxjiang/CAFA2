function [sel, bsl] = cafa_sel_top10_seq_prcurve(prcurves, naive, blast, config, rmcurves)
%CAFA_SEL_TOP10_SEQ_FMAX CAFA select top10 sequence-centric Fmax
% {{{
%
% [sel, bsl] = CAFA_SEL_TOP10_SEQ_FMAX(prcurves, naive, blast, config, rmcurves);
%
%   Picks the top10 precision-recall curves in Fmax.
%
% Input
% -----
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
% naive:    the internalID of the naive baseline.
%
% [char]
% blast:    the internalID of the blast baseline.
%
% [char]
% config:   The team info file which should have the following columns:
%
%         * 1. <internalID>
%         * 2. <externalID>
%           3. <teamname>
%         * 4. <type>
%         * 5. <displayname>
%         * 6. <pi>
%
%           Note:
%           1. The starred columns (*) will be used in this function.
%           2. 'type':  'q'  - qualified
%                       'd'  - disqualified
%                       'n'  - Naive method (baseline 1)
%                       'b'  - BLAST method (baseline 2)
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
% [cell]
% bsl:  The baseline curves and related information. Each cell has the same
%       structure as 'sel'.
%
% Dependency
% ----------
%[>]pfp_fmaxc.m
%[>]pfp_sminc.m
%[>]cafa_collect.m
%[>]cafa_read_team_info.m
%[>]cafa_eval_seq_curve.m
% }}}

  % check inputs {{{
  if nargin < 4 || nargin > 5
    error('cafa_sel_top10_seq_prcurve:InputCount', 'Expected 4 or 5 inputs.');
  end

  if nargin == 4
    rmcurves = {};
  end

  % check the 2nd input 'naive' {{{
  validateattributes(naive, {'char'}, {'nonempty'}, '', 'naive', 2);
  % }}}

  % check the 3rd input 'blast' {{{
  validateattributes(blast, {'char'}, {'nonempty'}, '', 'blast', 3);
  % }}}

  % check the 1st input 'prcurves' {{{
  validateattributes(prcurves, {'cell'}, {'nonempty'}, '', 'prcurves', 1);
  % }}}

  % check the 4th input 'config' {{{
  validateattributes(config, {'char'}, {'nonempty'}, '', 'config', 4);
  [team_id, ext_id, ~, team_type, disp_name, pi_name] = cafa_read_team_info(config);
  % }}}

  % check the 5th input 'rmcurves' {{{
  validateattributes(rmcurves, {'cell'}, {}, '', 'rmcurves', 5);
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
  model_num = cell(1, n);
  for i = 1 : n
      splitted_id = strsplit(ext_id{i}, '-');
      model_num{i} = splitted_id{2};
  end
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
      bsl{1}.curve = prcurves{i}.curve;
      [fmax, pt, ~]    = pfp_fmaxc(prcurves{i}.curve, prcurves{i}.tau);
      bsl{1}.opt_point = pt;

      if do_alt
        bsl{1}.alt_point = find_alt_point(prcurves{i}, rmcurves{i});
      end

      bsl{1}.tag = sprintf('%s (F=%.2f,C=%.2f)', disp_name{index}, fmax, prcurves{i}.coverage);
    elseif strcmp(prcurves{i}.id, blast)
      bsl{2}.curve = prcurves{i}.curve;
      [fmax, pt, ~]    = pfp_fmaxc(prcurves{i}.curve, prcurves{i}.tau);
      bsl{2}.opt_point = pt;

      if do_alt
        bsl{2}.alt_point = find_alt_point(prcurves{i}, rmcurves{i});
      end

      bsl{2}.tag = sprintf('%s (F=%.2f,C=%.2f)', disp_name{index}, fmax, prcurves{i}.coverage);
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
      qld{kept}.curve = prcurves{i}.curve;
      fmaxs(kept) = fmax;
      qld{kept}.opt_point = pt;

      if do_alt
        qld{kept}.alt_point = find_alt_point(prcurves{i}, rmcurves{i});
      end

      qld{kept}.disp_name = disp_name{index};
      qld{kept}.tag       = sprintf('%s-%s (F=%.2f,C=%.2f)', disp_name{index}, model_num{index}, fmax, prcurves{i}.coverage);
      qld{kept}.pi_name   = pi_name{index};
      % }}}
    else
      % nop: ignore unmatched baselines and disqualified models
    end
  end
  qld(kept + 1 : end)   = []; % truncate the trailing empty cells
  fmaxs(kept + 1 : end) = [];
  % }}}

  % sort Fmax and pick the top 10 {{{
  % keep find the next team until
  % 1. find K (= 10) teams, or
  % 2. exhaust the list
  % Note that we only allow one model selected per pi.

  K = 10; % target number of seletect teams
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
    warning('cafa_sel_top10_seq_prcurve:LessThenTen', 'Only selected %d models.', nsel);
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
% Last modified: Fri 17 Jul 2015 11:41:46 AM E
