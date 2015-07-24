function [sel, bsl] = cafa_sel_top_seq_rmcurve(K, rmcurves, naive, blast, config)
%CAFA_SEL_TOP_SEQ_SMIN CAFA curve top sequence-centric Smin
% {{{
%
% [sel, bsl] = CAFA_SEL_TOP_SEQ_SMIN(K, rmcurves, naive, blast, config);
%
%   Picks the top RU-MI curves in Smin.
%
% Input
% -----
% [double]
% K:        The number of teams/methods to pick.
%
% [cell]
% rmcurves: The pre-calculated RU-MI curve structures.
%           [char]      [1-by-n]    .id
%           [double]    [k-by-2]    .curve
%           [double]    [1-by-k]    .tau
%           [double]    [1-by-1]    .coverage
%
%           See cafa_eval_seq_rmcurve.m
%
% [char]
% naive:    the internalID of the naive baseline.
%
% [char]
% blast:    the internalID of the blast baseline.
%
% [char]
% config:   The file having team information. The file should have the
%           folloing columns:
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
% Output
% ------
% [cell]
% sel:  The curves and related information ready for plotting:
%
%       [double]
%       .curve      n x 2, points on the curve.
%
%       [double]
%       .opt_point  1 x 2, the optimal point (corresp. to Smin).
%
%       [char]
%       .tag        for the legend of the plot.
%
% [cell]
% bsl:  The baseline curves and related information. Each cell has the
%       same structure as 'sel'.
%   
%
% Dependency
% ----------
%[>]pfp_sminc.m
%[>]cafa_collect.m
%[>]cafa_team_read_config.m
%[>]cafa_eval_seq_curve.m
% }}}

  % check inputs {{{
  if nargin ~= 5
    error('cafa_sel_top_seq_rmcurve:InputCount', 'Expected 5 inputs.');
  end

  % check the 1st input 'K' {{{
  validateattributes(K, {'double'}, {'positive', 'integer'}, '', 'K', 1);
  % }}}
  
  % check the 2nd input 'rmcurves' {{{
  validateattributes(rmcurves, {'cell'}, {'nonempty'}, '', 'rmcurves', 2);
  % }}}

  % check the 3rd input 'naive' {{{
  validateattributes(naive, {'char'}, {'nonempty'}, '', 'naive', 3);
  % }}}

  % check the 4rd input 'blast' {{{
  validateattributes(blast, {'char'}, {'nonempty'}, '', 'blast', 4);
  % }}}

  % check the 5th input 'config' {{{
  validateattributes(config, {'char'}, {'nonempty'}, '', 'config', 5);
  [team_id, ext_id, ~, team_type, disp_name, pi_name] = cafa_team_read_config(config);
  % }}}
  % }}}

  % clean up, and calculate Smin {{{
  % 1. remove 'disqualified' teams;
  % 2. set aside baseline methods;
  % 3. match team names for display.
  % 4. calculate Smin.

  n = numel(rmcurves);
  qld = cell(1, n); % all qualified teams
  bsl = cell(1, 2); % two baseline methods (naive + blast)
  smins = zeros(1, n);
  kept = 0;

  % parse model number 1, 2 or 3 from external ID {{{
  model_num = cell(1, n);
  for i = 1 : n
      splitted_id = strsplit(ext_id{i}, '-');
      model_num{i} = splitted_id{2};
  end
  % }}}

  for i = 1 : n
    index = find(strcmp(team_id, rmcurves{i}.id));

    % remove the point on the curve that corresp. to tau = 0.00
    rmcurves{i} = remove_tau0_point(rmcurves{i});

    if strcmp(rmcurves{i}.id, naive)
      bsl{1}.curve = rmcurves{i}.curve;
      [smin, pt, ~] = pfp_sminc(rmcurves{i}.curve, rmcurves{i}.tau);
      bsl{1}.opt_point = pt;
      bsl{1}.tag = sprintf('%s (S=%.2f,C=%.2f)', disp_name{index}, smin, rmcurves{i}.coverage);
    elseif strcmp(rmcurves{i}.id, blast)
      bsl{2}.curve = rmcurves{i}.curve;
      [smin, pt, ~] = pfp_sminc(rmcurves{i}.curve, rmcurves{i}.tau);
      bsl{2}.opt_point = pt;
      bsl{2}.tag = sprintf('%s (S=%.2f,C=%.2f)', disp_name{index}, smin, rmcurves{i}.coverage);
    elseif strcmp(team_type(index), 'q') % qualified teams
      % filtering {{{
      % skip models with 0 coverage
      if rmcurves{i}.coverage == 0
        continue;
      end

      % skip models covering less than 10 proteins
      if rmcurves{i}.ncovered < 10
        continue;
      end

      [smin, pt, ~] = pfp_sminc(rmcurves{i}.curve, rmcurves{i}.tau);

      % skip teams with 'NaN' Smin values, though this shouldn't happen.
      if isnan(smin)
        continue;
      end
      % }}}

      % collecting {{{
      kept = kept + 1;
      qld{kept}.curve     = rmcurves{i}.curve;
      smins(kept)         = smin;
      qld{kept}.opt_point = pt;
      qld{kept}.disp_name = disp_name{index};
      qld{kept}.tag       = sprintf('%s-%s (S=%.2f,C=%.2f)', disp_name{index}, model_num{index}, smin, rmcurves{i}.coverage);
      qld{kept}.pi_name   = pi_name{index};
      % }}}
    else
      % nop: ignore unmatched baselines and disqualified models
    end
  end
  qld(kept + 1 : end) = []; % truncate the trailing empty cells
  smins(kept + 1 : end) = [];
  % }}}

  % sort Smin and pick the top K {{{
  % keep find the next team until
  % 1. find K (= 10) teams, or
  % 2. exhaust the list
  % Note that we only allow one model selected per team.

  sel = cell(1, K);
  sel_pi = {};
  [~, index] = sort(smins, 'ascend');
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
    warning('cafa_sel_top_seq_rmcurve:LessThenTen', 'Only selected %d models.', nsel);
    sel(nsel + 1 : end) = [];
  end
  % }}}
return

% function: remove_points {{{
function [new_curve] = remove_points(curve)
  RU = curve(:, 1);
  MI = curve(:, 2);

  n = size(curve, 1);
  useless = false(n, 1);

  for i = 1 : n
    gt_both = (RU < RU(i)) & (MI < MI(i));
    eq_both = (RU == RU(i)) & (MI == MI(i));
    if any(gt_both & ~eq_both)
      useless(i) = true;
    end
  end
  RU(useless) = [];
  MI(useless) = [];
  new_curve = [RU, MI];
return
% }}}

% function: remove_tau0_point {{{
function [rm] = remove_tau0_point(rm)
  index = find(rm.tau == 0.00);
  if ~isempty(index)
    rm.curve(index, :) = [];
    rm.tau(index) = [];
  end
return
% }}}

% -------------
% Yuxiang Jiang (yuxjiang@indiana.edu)
% Department of Computer Science
% Indiana University Bloomington
% Last modified: Fri 24 Jul 2015 11:55:48 AM E
