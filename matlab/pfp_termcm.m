function [cm] = pfp_termcm(target, pred, oa, evmode, varargin)
%PFP_TERMEVAL Term-centric confusion matrices
%
% [cm] = PFP_TERMCM(target, pred, oa, evmode, varargin);
%
%   Calculate term-centric confusion matrices. It computes k matrices for each
%   'target' sequence, where 'k' is the number of thresholds.
%
% Note
% ----
% This function assumes the predicted scores have been normalized to be within
% the range [0, 1].
%
% Input
% -----
% [cell]
% target: A list of target objects.
%         For those target sequences that are not in pred.object, their
%         predicted associtated scores for each term will be 0.00, as if they
%         are not predicted.
%
% [struct]
% pred:   The prediction structure.
%
% [struct]
% oa:     The reference structure.
%
% [char]
% evmode: The mode of evaluation.
%         '1', 'full'     - averaged over the entire benchmark sets.
%                             missing prediction are treated as 0.
%         '2', 'partial'  - averaged over the predicted subset (partial).
%
% (optional) Name-Value pairs
% [double]
% 'tau'   An array of thresholds.
%         default: 0.00 : 0.01 : 1.00 (i.e. 0.00, 0.01, ..., 0.99, 1.00)
%
% Output
% ------
% [struct]
% cm: The structure of results.
%     .centric  [char]    'term'
%     .object   [cell]    A n-by-1 array of (char) object ID.
%     .term     [struct]  A 1-by-m array of (char) term ID.
%     .tau      [double]  A 1-by-k array of thresholds.
%     .cm       [struct]  An m-by-k struct array of confusion matrices.
%     .npp      [double]  An 1-by-m array of number of positive predictions for
%                         each term.
%     .date     [char]    The date whtn this evaluation is performed.
%
% Dependency
% ----------
%[>]pfp_predproj.m
%[>]pfp_oaproj.m
%[>]pfp_confmat.m
%
% See Also
% --------
%[>]pfp_oabuild.m

  % check basic inputs {{{
  if nargin < 4
    error('pfp_termcm:InputCount', 'Expected >= 4 inputs.');
  end

  % target
  validateattributes(target, {'cell'}, {'nonempty'}, '', 'target', 1);

  % pred
  validateattributes(pred, {'struct'}, {'nonempty'}, '', 'pred', 2);

  % oa
  validateattributes(oa, {'struct'}, {'nonempty'}, '', 'oa', 3);
  if numel(pred.ontology.term) ~= numel(oa.ontology.term) || ~all(strcmp({pred.ontology.term.id}, {oa.ontology.term.id}))
    error('pfp_termeval:InputErr', 'Ontology mismatch.');
  end

  % evmode
  evmode = validatestring(evmode, {'1', 'full', '2', 'partial'}, '', 'evmode', 4);
  % }}}

  % parse and check extra inputs {{{
  p = inputParser;
  defaultTAU   = 0.00 : 0.01 : 1.00;
  addParameter(p, 'tau', defaultTAU, @(x) validateattributes(x, {'double'}, {'vector', '>=', 0, '<=', 1}));
  parse(p, varargin{:})
  % }}}

  % align 'pred' and 'oa' onto the given target list {{{
  if ismember(evmode, {'2', 'partial'})
    npp_seq = sum(pred.score > 0.0, 2);
    pred.object(npp_seq > 0);
    target = intersect(pred.object(npp_seq > 0), target);
  end
  pred = pfp_predproj(pred, target, 'object');
  oa   = pfp_oaproj(oa, target, 'object');
  % }}}

  % prepare for output {{{
  % positive annotation
  pos_anno = any(oa.annotation, 1);

  % construct prediction matrix and reference (ground truth) matrix.
  P = pred.score(:, pos_anno);
  T = oa.annotation(:, pos_anno);

  cm.centric = 'term';
  cm.object  = pred.object;
  cm.term    = reshape({pred.ontology.term(pos_anno).id}, 1, []);
  cm.tau     = p.Results.tau;

  m = size(P, 2);

  cm.npp = reshape(full(sum(P > 0.0, 1)), [], 1);
  cm.cm  = cell(m, 1);

  for i = 1 : m
    cm.cm{i} = pfp_confmat(P(:, i), T(:, i), p.Results.tau);
  end
  cm.cm   = cell2mat(cm.cm);
  cm.date = datestr(now, 'mm/dd/yyyy HH:MM');
  % }}}
return

% -------------
% Yuxiang Jiang (yuxjiang@indiana.edu)
% Department of Computer Science
% Indiana University Bloomington
% Last modified: Tue 24 May 2016 02:22:00 PM E
