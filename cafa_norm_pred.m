function [score] = cafa_norm_pred(score)
%CAFA_NORM_PRED CAFA normalize prediction
% {{{
%
% [score] = CAFA_NORM_PRED(score);
%
%   Normalizes (and rounds) the prediction according to the CAFA rules.
%
% Note
% ----
% 1. This function assumes non-negative predictions.
%
% 2. CAFA2 requires the prediction to be within the range [0, 1]. Also, scores
%    keep only 2 significant figures.
%
% Input
% -----
% [double]
% score:  An n-by-m prediction score matrix.
%
% Output
% ------
% [double]
% score:  The resulting matrix.
%
% Dependency
% ----------
%[>]pfp_minmaxnrm.m
% }}}

  % check inputs {{{
  if nargin ~= 1
    error('cafa_norm_pred:InputCount', 'Expected 1 input.');
  end

  % check the 1st input 'score' {{{
  validateattributes(score, {'double'}, {'>=', 0}, '', 'score', 1);
  [n, m] = size(score);
  % }}}
  % }}}

  % normalization {{{
  score = pfp_minmaxnrm(score', zeros(1, n), max(score', [], 1))';
  % }}}

  % rounding {{{
  score = sparse(round(score .* 100)) ./ 100;
  % }}}
return

% -------------
% Yuxiang Jiang (yuxjiang@indiana.edu)
% Department of Computer Science
% Indiana University Bloomington
% Last modified: Fri 17 Jul 2015 11:05:12 AM E
