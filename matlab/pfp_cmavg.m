function [m] = pfp_cmavg(cmstruct, metric, varargin)
%PFP_CMAVG Confusion matrix average
%
% [m] = PFP_CMAVG(cmstruct, metric, varargin);
%
%   Computes the averaged metric from confusion matrices.
%
% Input
% -----
% [struct]
% cmstruct: The confusion matrix structure.
%           (It can be obtained from pfp_seqcm.m, or pfp_termcm.m)
%
% [char]
% metric:   The metric need to be averaged. Must be one of the following:
%           'pr'  - precision, recall
%           'wpr' - weighted precision, recall
%         * 'rm'  - RU, MI
%         * 'nrm' - normalized RU, MI
%           'f'   - F-measure
%           'wf'  - weighted F-measure
%         * 'sd'  - semantic distance
%         * 'nsd' - normalized semantic distance
%           'ss'  - sensitivity, 1 - specificity (points on ROC)
%           'acc' - accuracy
%
%         * Note: starred (*) metrics are only available in "sequence-centered"
%           evaluation. Since information accretion makes no sense in
%           "term-centered" evaluation model.
%
%           Also, weighted metrics (e.g. wpr) is not available for now in
%           "term-centered" evaluation mode, see pfp_termcm.m.
%
% (optional) Name-Value pairs
% [double]
% 'beta'    Used in F_{beta}-measure.
%           default: 1
%
% [double]
% 'order'   The order of semantic distance. (sequence-centered only)
%           default: 2
%
% [logical]
% 'Q'       An n-by-1 indicator of qualified predictions. It won't affect
%           the result in 'full' evaluation mode, however, in the 'partial'
%           mode, only rows corresponding to TRUE bits are averaged.
%           default: cmstruct.npp > 1 (at least one positive predictions, see
%           pfp_seqcm.m or pfp_termcm.m for details)
%
% [char]
% evmode:   The mode of evaluation. Only effective in "sequence-centered"
%           evaluation, i.e., returned by pfp_seqcm.m rather than pfp_termcm.m.
%           (indeed, 'evmode' has to be decided when calling pfp_termcm.m)
%           '1', 'full'     - averaged over the entire benchmark sets.
%                             missing prediction are treated as 0.
%           '2', 'partial'  - averaged over the predicted subset (partial).
%
%           default: 'full'
%
% [char]
% avgmode:  The mode of averaging.
%           'macro' - macro-average, compute the metric over each confusion
%                     matrix and then average the metric.
%           'micro' - micro-average, average the confusion matrix, and then
%                     compute the metric.
%
%           default: 'macro'
%
% Output
% ------
% [cell]
% m:        The 1-by-k averaged metric.
%
% Dependency
% ----------
%[>]pfp_cmmetric.m
%
% See Also
% --------
%[>]pfp_seqcm.m
%[>]pfp_termcm.m

  % check inputs {{{
  if nargin < 2
    error('pfp_cmavg:InputCount', 'Expected >= 2 inputs.');
  end

  % cmstruct
  validateattributes(cmstruct, {'struct'}, {'nonempty'}, '', 'cmstruct', 1);
  cms = cmstruct.cm;
  [n, k] = size(cms);

  % metric
  metric = validatestring(metric, {'pr', 'wpr', 'rm', 'nrm', 'f', 'wf', 'sd', 'nsd', 'ss', 'acc'}, '', 'metric', 2);
  % }}}

  % parse additional inputs {{{
  p = inputParser;

  defaultBETA     = 1;
  defaultORDER    = 2;
  defaultQ        = reshape(cmstruct.npp > 0, [], 1);
  defaultEV_MODE  = 'full';
  defaultAVG_MODE = 'macro';

  valid_evmodes   = {'1', '2', 'full', 'partial'};
  valid_avgmodes = {'macro', 'micro'};

  addParameter(p, 'beta', defaultBETA, @(x) validateattributes(x, {'double'}, {'real', 'positive'}));
  addParameter(p, 'order', defaultORDER, @(x) validateattributes(x, {'double'}, {'real', 'positive'}));
  addParameter(p, 'Q', defaultQ, @(x) validateattributes(x, {'logical'}, {'ncols', 1, 'numel', n}));
  addParameter(p, 'evmode', defaultEV_MODE, @(x) any(strcmpi(x, valid_evmodes)));
  addParameter(p, 'avgmode', defaultAVG_MODE, @(x) any(strcmpi(x, valid_avgmodes)));

  parse(p, varargin{:});
  % }}}

  % sanity check for sequence-centered {{{
  if strcmp(cmstruct.centric, 'term') && ismember(metric, {'rm', 'nrm', 'sd', 'nsd'})
    error('pfp_cmavg:IncompatibleInput', 'metric is not available in term-centered evaluation.');
  end
  % }}}

  % select rows to average according to 'evmode' and 'Q' {{{
  switch p.Results.evmode
  case {'1', 'full'}
    % use the full matrix, nop
  case {'2', 'partial'}
    cms = cms(p.Results.Q, :);
  otherwise
    % nop
  end
  % }}}

  % averaging {{{
  m = cell(1, k);
  switch p.Results.avgmode
  case 'macro'
    for i = 1 : k
      cm = [reshape(full([cms(:, i).TN]), [], 1), ...
            reshape(full([cms(:, i).FP]), [], 1), ...
            reshape(full([cms(:, i).FN]), [], 1), ...
            reshape(full([cms(:, i).TP]), [], 1) ...
      ];
      raw_m = pfp_cmmetric(cm, metric, 'beta', p.Results.beta, 'order', p.Results.order);
      m{i}  = nanmean(raw_m, 1);
    end
  case 'micro'
    for i = 1 : k
      cm = [full(mean([cms(:, i).TN])), ...
            full(mean([cms(:, i).FP])), ...
            full(mean([cms(:, i).FN])), ...
            full(mean([cms(:, i).TP])) ...
      ];
      m{i} = pfp_cmmetric(cm, metric, 'beta', p.Results.beta, 'order', p.Results.order);
    end
  otherwise
    % nop
  end
  % }}}
return

% -------------
% Yuxiang Jiang (yuxjiang@indiana.edu)
% Department of Computer Science
% Indiana University Bloomington
% Last modified: Tue 24 May 2016 02:18:54 PM E
