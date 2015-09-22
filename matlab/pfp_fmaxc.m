function [fmax, point, t] = pfp_fmaxc(curve, tau, beta)
%PFP_FMAXC F-measure maximum (from) curve
% {{{
%
% [fmax, point, t] = PFP_FMAXC(curve, tau);
%
%   Returns the maximum F_{1}-measure of a precision-recall curve.
%
% [fmax, point, t] = PFP_FMAXC(curve, tau, beta);
%
%   Returns the maximum F_{beta}-measure of a precision-recall curve.
%
% Input
% -----
% [double]
% curve:  A k-by-2 precision-recall matrix (i.e. a curve).
%
% [double]
% tau:    A 1-by-k vector of thresholds.
%
% (optional)
% [double]
% beta:   The beta of F_{beta}-measure.
%         default: 1
%
% Output
% ------
% [double]
% fmax:   The F_{beta}-max.
%
% [double]
% point:  The corresponding (pr, rc) that produces the F-max.
%
% [double]
% t:      The best corresponding threshold.
% }}}

  % check inputs {{{
  if nargin < 2
    error('pfp_fmaxc:InputCount', 'Expected >= 2 inputs.');
  end

  if nargin == 2
    beta = 1;
  end

  % check the 1st input 'curve' {{{
  validateattributes(curve, {'double'}, {'ncols', 2}, '', 'curve', 1);
  k = size(curve, 1);
  % }}}

  % check the 2nd input 'tau' {{{
  validateattributes(tau, {'double'}, {'numel', k}, '', 'tau', 2);
  % }}}

  % check the 3rd input 'beta' {{{
  validateattributes(beta, {'double'}, {'real', 'positive'}, '', 'beta', 3);
  % }}}
  % }}}

  % sanity check {{{
  if any(all(isnan(curve), 1))
    fmax  = NaN;
    point = nan(1, 2);
    t     = NaN;
    return;
  end
  % }}}

  % calculation {{{
  pr = curve(:, 1);
  rc = curve(:, 2);

  f = (1 + beta .^ 2) .* pr .* rc ./ (beta .^ 2 .* pr + rc);
  fmax = max(f);

  % threshold is set to the highest possible one that yields this fmax
  index = max(find(f == fmax));
  point = curve(index, :);
  t     = tau(index);
  % }}}
return

% -----------
% Yuxiang Jiang (yuxjiang@indiana.edu)
% Department of Computer Science
% Indiana University Bloomington
% Last modified: Mon 14 Sep 2015 05:25:50 PM E
