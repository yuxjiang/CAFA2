function [cm, tau] = pfp_confmatw(pred, ref, w, tau)
%PFP_CONFMATW Confusion matrix (weighted)
%
% [cm] = PFP_CONFMAT(pred, ref, w, tau);
%
%   Computes k confusion matrices, where 'k' is the number of thresholds.
%   (weighted version)
%
% Note
% ----
% Predicted scores must be within [0, 1]. (normalized)
%
% Input
% -----
% [double]
% pred: n-by-1 predictions.
%
% [logical]
% ref:  n-by-1 ground truth.
%
% [double]
% w:    n-by-1 weights.
%
% (optional)
% [double]
% tau:  1-by-k increasing thresholds.
%       default: 0.00 : 0.01 : 1.00
%
% Output
% ------
% [struct]
% cm:   1-by-k struct array. Each structure contains:
%       .TN [double]  (weighted) True negative
%       .FP [double]  (weighted) False positive
%       .FN [double]  (weighted) False negative
%       .TP [double]  (weighted) True positive
%
% [double]
% tau:  1-by-k corresponding thresholds.

  % check inputs {{{
  if nargin ~= 3 && nargin ~= 4
    error('pfp_confmat:InputCount', 'Expected 3 or 4 inputs.');
  end

  if nargin == 3
    tau = 0.00 : 0.01 : 1.00;
  end

  % pred
  validateattributes(pred, {'double'}, {'ncols', 1, '>=', 0, '<=', 1}, '', 'pred', 1);
  n = numel(pred);

  % ref
  validateattributes(ref, {'logical'}, {'ncols', 1, 'numel', n}, '', 'ref', 2);

  % w
  validateattributes(w, {'double'}, {'ncols', 1, 'numel', n}, '', 'w', 3);

  % tau
  validateattributes(tau, {'double'}, {'row', '>=', 0, '<=', 1, 'increasing'}, '', 'tau', 4);
  k = numel(tau);
  % }}}

  % compute confusion matrices at each tau {{{
  cm = struct('TN', cell(1, k), 'FP', cell(1, k), 'FN', cell(1, k), 'TP', cell(1, k));

  pos = ref;
  neg = ~ref;

  wpos = w' * pos;
  wneg = w' * neg;
  for i = 1 : k
    P = pred >= tau(i);
    cm(i).FP = w' * (P & neg);
    cm(i).TN = wneg - cm(i).FP;
    cm(i).TP = w' * (P & pos);
    cm(i).FN = wpos - cm(i).TP;
  end
  % }}}
return

% -------------
% Yuxiang Jiang (yuxjiang@indiana.edu)
% Department of Computer Science
% Indiana University Bloomington
% Last modified: Tue 24 May 2016 02:25:37 PM E
