function [cm, tau] = pfp_confmat(pred, ref, tau)
%PFP_CONFMAT Confusion matrix
% {{{
%
% [cm] = PFP_CONFMAT(pred, ref, tau);
%
%   Computes k confusion matrices, where 'k' is the number of thresholds.
%
% Note
% ----
% Predicted scores must be within [0, 1]. (normalized).
%
% Input
% -----
% [double]
% pred: n-by-1 predictions.
%
% [logical]
% ref:  n-by-1 ground truth.
%
% (optional)
% [double]
% tau:  1-by-k thresholds.
%       default: 0.00 : 0.01 : 1.00
%
% Output
% ------
% [struct]
% cm:   1-by-k struct array. Each structure contains:
%
%       [double]
%       .TN, .FP, .FN, .TP  - The four entries in a confusion matrix.
%
% [double]
% tau:  1-by-k corresponding thresholds.
% }}}

  % check inputs {{{
  if nargin < 2 || nargin > 3
    error('pfp_confmat:InputCount', 'Expected 2 or 3 inputs.');
  end

  if nargin == 2
    tau = 0.00 : 0.01 : 1.00;
  end

  % check the 1st input 'pred' {{{
  validateattributes(pred, {'double'}, {'ncols', 1, '>=', 0, '<=', 1}, '', 'pred', 1);
  n = numel(pred);
  % }}}

  % check the 2nd input 'ref' {{{
  validateattributes(ref, {'logical'}, {'ncols', 1, 'numel', n}, '', 'ref', 2);
  % }}}

  % check the 3rd input 'tau' {{{
  validateattributes(tau, {'double'}, {'row', '>=', 0, '<=', 1}, '', 'tau', 3);
  k = numel(tau);
  % }}}
  % }}}

  % compute confusion matrices at each tau {{{
  cm = struct('TN', cell(1, k), 'FP', cell(1, k), 'FN', cell(1, k), 'TP', cell(1, k));

  pos = ref;
  neg = ~ref;

  npos = sum(pos);
  nneg = sum(neg);
  for i = 1 : k
    P = pred >= tau(i);
    cm(i).FP = sum(P & neg);
    cm(i).TN = nneg - cm(i).FP;
    cm(i).TP = sum(P & pos);
    cm(i).FN = npos - cm(i).TP;
  end
  % }}}
return

% -------------
% Yuxiang Jiang (yuxjiang@indiana.edu)
% Department of Computer Science
% Indiana University Bloomington
% Last modified: Tue 15 Sep 2015 11:41:29 AM E
