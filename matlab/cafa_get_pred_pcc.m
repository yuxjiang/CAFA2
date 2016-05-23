function [res] = cafa_get_pred_pcc(cfg)
%CAFA_GET_PRED_PCORR CAFA get prediction Pearson's correlation
%
% [res] = CAFA_GET_PRED_PCORR(cfg);
%
%   Computes Pearson's correlation coefficient between predictions over a set of
%   benchmark proteins.
%
% Input
% -----
% cfg:  The configuration file (job descriptor) or a parsed config structure.
%       See cafa_parse_config.m
%
% Output
% ------
% [struct]
% res:  The result structure, which has the following fields:
%       .mid  [cell]    An n-by-1 cell array of internal ID.
%       .pcc  [double]  An n-by-n matrix of Pearson's correlation coefficient.
%
% Dependency
% ----------
%[>]cafa_parse_config.m
%[>]cafa_team_register.m
%[>]pfp_predproj.m

  % check inputs {{{
  if nargin ~= 1
    error('cafa_get_pred_pcc:InputCount', 'Expected 1 input.');
  end

  % cfg
  config = cafa_parse_config(cfg);
  % }}}

  % get team names to display {{{
  % remove unused baseline models: B[BN]1S (if presented)
  index = cell2mat(cellfun(@(x) isempty(regexp(x, 'B[BN]1S')), config.model, 'UniformOutput', false));
  res.mid = config.model(index);
  n = numel(res.mid);
  % }}}

  % load and project predictions and ground-truth {{{
  fprintf('loading and projecting ... ');
  pred = cell(1, n);
  for i = 1 : n
    data = load(strcat(config.pred_dir, res.mid{i}, '.mat'), 'pred');
    pred{i} = pfp_predproj(data.pred, config.bm, 'object');
  end
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

  % compute 'pcc' {{{
  res.pcc  = -ones(n, n);
  fprintf('Computing pairwise PCC ... ');
  for i = 1 : n
    res.pcc(i, i) = 1; % self similarity
    for j = i+1 : n
      % find indices of common proteins on which both i and j predicted
      pi = intersect(plist{i}, plist{j});

      % find indices of common terms on which both i and j have scores
      ti = intersect(tlist{i}, tlist{j});

      x = full(reshape(pred{i}.score(pi, ti), [], 1));
      y = full(reshape(pred{j}.score(pi, ti), [], 1));

      if ~isempty(x) && ~isempty(y)
        rho = corr(x, y); % Pearson's cc
        if ~isnan(rho)
          res.pcc(i, j) = rho;
          res.pcc(j, i) = res.pcc(i, j);
        end
      end
    end
  end
  fprintf('done.\n');
  % }}}
return

% -------------
% Yuxiang Jiang (yuxjiang@indiana.edu)
% Department of Computer Science
% Indiana University, Bloomington
% Last modified: Mon 23 May 2016 02:35:36 PM E
