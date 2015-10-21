function [res] = pfp_convcmstruct(cmstruct, metric, varargin)
%PFP_CONVCMSTRUCT Convert confusion matrix struct
% {{{
%
% [res] = PFP_CONVCMSTRUCT(cmstruct, metric);
%
%   Converts a confusion matrix struct (returned from pfp_seqcm.m) to a specific
%   confusion matrix derived metric (e.g. precision-recall curve).
%
% Input
% -----
% (required)
% [struct]
% cmstruct: A confusion matrix struct.
%           See pfp_seqcm.m
%
% [char]
% metric:   One of the metrics that can be derived from a confusion matrix
%
% (optional) Name-Value pairs
% (varargin will be passed through pfp_cmmetric.m directly, see that file for
% details.)
%
% Output
% ------
% [struct]
% res: The structure of results.
%
%      [char]
%      .centric  'sequence'
%
%      [cell]
%      .object   An n-by-1 array of (char) object ID.
%
%      [cell]
%      .metric   A 1-by-k cell of converted metrics.
%
%      [double]
%      .tau      A 1-by-k array of thresholds.
%
%      [logical]
%      .covered  A n-by-1 logical array indicating if the corresponding object is
%                predicted ("covered") by the model.
%
%      [char]
%      .date     The date when this struct is built.
%
% Dependency
% ----------
%[>]pfp_cmmetric.m
%
% See Also
% --------
%[>]pfp_seqcm.m
% }}}

  % check inputs {{{
  if nargin < 2
    error('pfp_convcmstruct:InputCount', 'Expected >= 2 inputs.');
  end

  % check the 1st input 'cmstruct' {{{
  validateattributes(cmstruct, {'struct'}, {'nonempty'}, '', 'cmstruct', 1);
  % }}}

  % check the 2nd input 'metric' {{{
  validateattributes(metric, {'char'}, {'nonempty'}, '', 'metric', 2);
  % }}}
  % }}}

  % converting {{{
  k           = size(cmstruct.cm, 2);
  res.centric = 'sequence';
  res.object  = cmstruct.object;
  res.metric  = cell(1, k);
  for i = 1 : k
    cm = [reshape(full([cmstruct.cm(:, i).TN]), [], 1), ...
          reshape(full([cmstruct.cm(:, i).FP]), [], 1), ...
          reshape(full([cmstruct.cm(:, i).FN]), [], 1), ...
          reshape(full([cmstruct.cm(:, i).TP]), [], 1)];
    res.metric{i} = pfp_cmmetric(cm, metric, varargin{:});
  end
  res.tau     = cmstruct.tau;
  res.covered = (cmstruct.npp > 0);
  res.date    = date;
  % }}}
return

% -------------
% Yuxiang Jiang (yuxjiang@indiana.edu)
% Department of Computer Science
% Indiana University, Bloomington
% Last modified: Wed 21 Oct 2015 06:34:46 PM E
