function [m] = pfp_cmmetric(cm, metric, varargin)
%PFP_CMMETRIC Confusion matrix metric
% {{{
%
% [m] = PFP_CMMETRIC(TN, FP, FN, TP, metric, p);
%
%   Gets metric from confusion matrixs.
%
% Input
% -----
% [double]
% cm:     n-by-4, The four cells of the confusion matrix.
%         cm(:, 1)    - TN, true negative.
%         cm(:, 2)    - FP, false positive.
%         cm(:, 3)    - FN, false negative.
%         cm(:, 4)    - TP, true positive.
%
%         Note that each row of cm construct a confusion matrix, and they are
%         evaluated independently.
%
% [char]
% metric: Desired metric, should be one of the following:
%         'pr'    - precision, recall
%         'wpr'   - weighted precision, recall
%         'rm'    - RU, MI
%         'nrm'   - normalized RU, MI
%         'f'     - F-measure
%         'wf'    - weighted F-measure
%         'sd'    - semantic distance
%         'nsd'   - normalized semantic distance
%         'ss'    - sensitivity, 1 - specificity (points on ROC)
%         'acc'   - accuracy
%
% (optional) Name, Value pairs
% [double]
% 'beta':   used as beta in F_{beta}-measure.
%           default: 1
%
% [double]
% 'order':  used as the order of semantic distance.
%           default: 2
%
% Output
% ------
% [double]
% m:  The resulting metric with the size n-by-1 or n-by-2 depending on 'metric'.
%
% See Also
% --------
%[>]pfp_seqcm.m
% }}}

  % check inputs {{{
  if nargin < 2
    error('pfp_cmmetric:InputCount', 'Expected >= 2 inputs.');
  end

  % check the 1st input 'cm' {{{
  validateattributes(cm, {'double'}, {'ncols', 4}, '', 'cm', 1);
  TN = cm(:, 1);
  FP = cm(:, 2);
  FN = cm(:, 3);
  TP = cm(:, 4);
  % }}}

  % check the 2nd input 'metric' {{{
  metric_opt = {'pr', 'wpr', 'rm', 'nrm', 'f', 'wf', 'sd', 'nsd', 'ss', 'acc'};
  validatestring(metric, metric_opt, '', 'metric', 2);
  % }}}
  % }}}

  % parse additional inputs {{{
  p = inputParser;

  defaultBETA  = 1;
  defaultORDER = 2;

  addParameter(p, 'beta', defaultBETA, @(x) validateattributes(x, {'double'}, {'real', 'positive'}));
  addParameter(p, 'order', defaultORDER, @(x) validateattributes(x, {'double'}, {'real', 'positive'}));

  parse(p, varargin{:});
  % }}}

  % compute metric {{{
  if strcmpi(metric, 'pr') || strcmpi(metric, 'wpr') 
    % m = [(weighted) precision, (weighted) recall]
    % Precision can be NaN for (TP + FP) = 0, no (positive) prediction
    % recall can be NaN for (FP + FN) = 0, no (positive) annotation
    m = [TP ./ (TP + FP), TP ./ (TP + FN)];
  elseif strcmpi(metric, 'rm')
    % m = [RU, MI]
    % Both RU and MI should never be NaN.
    m = [FN, FP]; % ru: weighted FN; mi: weighted FP.
  elseif strcmpi(metric, 'nrm')
    % m = [normalized RU, normalized MI]
    % Both normalized RU and normalized MI could be NaN in the case that no
    % (positive) prediction and no (positive) annotation.
    m = [FN, FP] ./ repmat(FN + TP + FP, 1, 2);
  elseif strcmpi(metric, 'f') || strcmpi(metric, 'wf')
    % m = [(weighted) F]
    % (Weighted) F can be NaN in any of these 3 cases:
    % 1. No predictions: TP = FP = 0
    % 2. No annotations: TP = FN = 0
    % 3. No true positives: TP = 0 (i.e. pr = rc = 0)
    [pr, rc] = [TP ./ (TP + FP), TP ./ (TP + FN)];
    m = (1 + p.Results.beta .^ 2) .* pr .* rc ./ (p.Results.beta .^ 2 .* pr + rc);
  elseif strcmpi(metric, 'sd')
    % m = [semantic distance]
    % SD can never be NaN
    [ru, mi] = [FN, FP];
    m = (ru .^ p.Results.order + mi .^ p.Results.order) .^ (1 ./ p.Results.order);
  elseif strcmpi(metric, 'nsd')
    % m = [normalized semantic distance]
    % normalized SD can be NaN when neither (positive) prediction nor (positive)
    % annotation.
    [nru, nmi] = [FN, FP] ./ repmat(FN + TP + FP, 1, 2);
    m = (nru .^ p.Results.order + nmi .^ p.Results.order) .^ (1 ./ p.Results.order);
  elseif strcmpi(metric, 'ss')
    % TPR (sensitivity, recall) can be NaN for no (positive) annotations
    % FPR (1 - specificity) can be NaN for no (negative) annotations
    m = [TP ./ (TP + FN), FP ./ (TN + FP)];
  elseif strcmpi(metric, 'acc')
    % Accuracy should never be NaN
    m = (TN + TP) ./ (TN + TP + FP + FN);
  else
    error('pfp_cmmetric:UnknownMetric', 'Unknown metric.');
  end
  % }}}
return

% -------------
% Yuxiang Jiang (yuxjiang@indiana.edu)
% Department of Computer Science
% Indiana University Bloomington
% Last modified: Wed 21 Oct 2015 06:20:37 PM E
