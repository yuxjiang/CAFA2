function [fmax, point, t]  = pfp_fmax(pred, ref, tau, beta)
%PFP_FMAX F-measure maximum
% {{{
%
% [fmax, point, t] = PFP_FMAX(pred, ref, tau);
%
%   Returns the maximum F_{1}-measure.
%
% [fmax, point, t] = PFP_FMAX(pred, ref, tau, beta);
%
%   Returns the maximum F_{beta}-measure.
%
% Input
% -----
% pred:   An n-by-m predictions from m predictors, predicted scores must be
%         within [0, 1].
%
% ref:    An n-by-1 binary reference label corresponding to each term.
%
% tau:    A 1-by-k vector of thresholds.
%
% (optional)
% beta:   The beta of F_{beta}-measure.
%         default: 1
%
% Output
% ------
% fmax:   An 1-by-m cell of the minimum semantic distance.
%
% point:  Corresponding (pr, rc) that produces 'fmax'.
%
% t:      The best corresponding threshold.
%
%         Note:
%         For m = 1, this function simply returns a tuple of plain data,
%         instead of a tuple of 1-by-1 cells.
%
% Dependency
% ----------
%[>]pfp_prcurve.m
%[>]pfp_fmaxc.m
% }}}

  % calculate the precision-recall curve
  curve = pfp_prcurve(pred, ref, tau);

  % check result
  if isempty(curve)
    fmax = NaN; point = []; t = NaN;
    return;
  end

  % decide beta
  if ~exist('beta', 'var')
    beta = 1;
  end

  % calculate the fmax
  if ~iscell(curve)
    [fmax, point, t] = pfp_fmaxc(curve, tau, beta);
  else
    m = numel(curve);
    fmax = cell(1, m);
    point = cell(1, m);
    t = cell(1, m);
    for i = 1 : m
      [fmax{i}, point{i}, t{i}] = pfp_fmaxc(curve{i}, tau, beta);
    end
  end
return

% -------------
% Yuxiang Jiang (yuxjiang@indiana.edu)
% Department of Computer Science
% Indiana University Bloomington
% Last modified: Mon 14 Sep 2015 05:26:06 PM E
