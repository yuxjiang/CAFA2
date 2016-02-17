function [X, mn, mx] = pfp_minmaxnrm(X, mn, mx)
%PFP_MINMAXNRM Min-Max normalization
% {{{
%
% [X, mn, mx] = PFP_MINMAXNRM(X);
%
%   Normalizes columns of the data matrix using min-max method.
%
% [X, mn, mx] = PFP_MINMAXNRM(X, mn, mx);
%
%   Normalizes columns of the data matrix using the specified minimum and
%   maximum.
%
% Note
% ----
% 1. X out of range of [mn, mx] will be set to 0 or 1 respectively.
%
% 2. This function squash the value to 0 for any columns that have a tiny range:
% i.e. mx - mn < 1e-8.
%
% Input
% -----
% [double]
% X:  An n-by-m data matrix.
%
% (optional)
% [double]
% mn: A 1-by-m desired minimum.
%     default: min(X, [], 1);
%
% [double]
% mx: A 1-by-m desired maximum
%     default: max(X, [], 1);
%
% Output
% ------
% [double]
% X:  An n-by-m resulting data matrix.
%
% [double]
% mn: A 1-by-m minimum for each column.
%
% [double]
% mx: A 1-by-m maximum for each column.
% }}}

  % check inputs {{{
  if nargin ~= 1 && nargin ~= 3
    error('pfp_minmaxnrm:InputCount', 'Expected 1 or 3 inputs.');
  end

  % check the 1st input 'X' {{{
  validateattributes(X, {'double'}, {'nonempty'}, '', 'X', 1);
  [n, m] = size(X);
  % }}}

  if nargin == 1
    mn = min(X, [], 1);
    mx = max(X, [], 1);
  end

  % check the 2nd input 'mn' {{{
  validateattributes(mn, {'double'}, {'row', 'numel', m}, '', 'mn', 2);
  % }}}

  % check the 3rd input 'mx' {{{
  validateattributes(mx, {'double'}, {'row', 'numel', m}, '', 'mx', 3);
  % }}}

  if ~all(mx >= mn)
    error('pfp_minmaxnrm:InputErr', 'All specified MAX must not be smaller than MIN.');
  end
  % }}}

  % force each column of the data to the corresponding range {{{
  X = bsxfun(@max, X, mn);
  X = bsxfun(@min, X, mx);
  % }}}

  % normalization {{{
  range = mx - mn;
  tiny_range = range < 1e-8;

  % squash data with a tiny range.
  X(:, tiny_range) = 0.0;
  range(tiny_range) = 1.0; % avoid divide-by-zero

  X = bsxfun(@minus, X, mn);
  X = bsxfun(@rdivide, X, range);
  % }}}
return

% -------------
% Yuxiang Jiang (yuxjiang@indiana.edu)
% Department of Computer Science
% Indiana University Bloomington
% Last modified: Sat 19 Sep 2015 08:16:05 PM E
