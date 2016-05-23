function [cm] = pfp_seqcm(target, pred, oa, varargin)
%PFP_SEQCM Sequence-centric confusion matrices
%
% [cm] = PFP_SEQCM(target, pred, oa, varargin);
%
%   Calculate sequence-centric confusion matrices. It computes k matrices for
%   each 'target' sequence, where 'k' is the number of thresholds.
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
% (optional) Name-Value pairs
% [double]
% 'tau'   An array of thresholds.
%         default: 0.00:0.01:1.00 (i.e. 0.00, 0.01, ..., 0.99, 1.00)
%
% [logical or char]
% 'toi'   A binary vector indicating "terms of interest".
%         Note that the following special short-hand tokens are also allowed.
%         'all'     - all terms
%         'noroot'  - exclude root term
%         default: 'noroot'
%
% [double]
% 'w'     A weight vector over terms. Note that an empty vector implies equal
%         weights.
%         default: []
%
% Output
% ------
% [struct]
% cm: The structure of results.
%     .centric  [char]    Will be set to 'sequence'.
%     .object   [cell]    An n-by-1 array of (char) object ID.
%     .ontology [struct]  The ontology structure. (m terms).
%     .toi      [logical] A 1-by-m vector indicating "term of interest".
%     .w        [double]  A 1-by-m vector of term weights. (empty if not
%                         specified.)
%     .tau      [double]  A 1-by-k array of thresholds.
%     .cm       [struct]  An n-by-k struct array of confusion matrices.
%     .npp      [double]  An n-by-1 array of "# of positive predictions" for
%                         each sequence.
%                         Note that it was calculated according to 'toi'.
%     .date     [char]    The date when this evaluation is performed.
%
% Dependency
% ----------
%[>]pfp_predproj.m
%[>]pfp_oaproj.m
%[>]pfp_roottermidx.m
%[>]pfp_confmat.m
%[>]pfp_confmatw.m

  % check inputs {{{
  if nargin < 3
    error('pfp_seqcm:InputCount', 'Expected at least 3 inputs.');
  end

  % target
  validateattributes(target, {'cell'}, {'nonempty'}, '', 'target', 1);

  % pred
  validateattributes(pred, {'struct'}, {'nonempty'}, '', 'pred', 2);

  % oa
  validateattributes(oa, {'struct'}, {'nonempty'}, '', 'oa', 3);
  if numel(pred.ontology.term) ~= numel(oa.ontology.term) || ~all(strcmp({pred.ontology.term.id}, {oa.ontology.term.id}))
    error('pfp_seqcm:InputErr', 'Ontology mismatch.');
  end
  % }}}

  % parse and check extra inputs {{{
  p = inputParser;

  defaultTOI   = 'noroot';
  defaultTAU   = 0.00 : 0.01 : 1.00;
  defaultW     = [];

  addParameter(p, 'tau', defaultTAU, @(x) validateattributes(x, {'double'}, {'vector', '>=', 0, '<=', 1}));
  addParameter(p, 'toi', defaultTOI, @(x) validateattributes(x, {'logical', 'char'}, {'nonempty'}));
  addParameter(p, 'w', defaultW, @(x) validateattributes(x, {'double'}, {}));

  parse(p, varargin{:});

  % parse the parameter 'toi' {{{
  switch p.Results.toi
  case 'all'
    toi = true(1, numel(oa.ontology.term));
  case 'noroot'
    toi = true(1, numel(oa.ontology.term));
    toi(pfp_roottermidx(oa.ontology)) = false;
  otherwise
    if ischar(r.Results.toi)
      error('pfp_seqcm:BadToken', 'Unknown ''toi'' token.');
    end
    toi = p.Results.toi;
  end
  % }}}

  % parse the parameter 'w' {{{
  if isempty(p.Results.w)
    method = 'regular';
  else
    validateattributes(p.Results.w, {'double'}, {'vector', 'numel', numel(oa.ontology.term)});
    w = reshape(p.Results.w(toi), [], 1);
    method = 'weighted';
  end
  % }}}
  % }}}

  % align 'pred' and 'oa' onto the given target list {{{
  pred = pfp_predproj(pred, target, 'object');
  oa   = pfp_oaproj(oa, target, 'object');
  % }}}

  % prepare for output {{{
  cm.centric  = 'sequence';
  cm.object   = pred.object;
  cm.ontology = pred.ontology;
  cm.toi      = toi;
  cm.w        = p.Results.w;
  cm.tau      = p.Results.tau;

  % construct prediction matrix and reference (ground truth) matrix.
  P = pred.score(:, toi)';
  T = oa.annotation(:, toi)';

  n = size(P, 2);

  cm.npp = reshape(full(sum(P > 0.0, 1)), [], 1);
  cm.cm  = cell(n, 1);
  switch method
  case 'regular'
    for i = 1 : n
      cm.cm{i} = pfp_confmat(P(:, i), T(:, i), p.Results.tau);
    end
  case 'weighted'
    for i = 1 : n
      cm.cm{i} = pfp_confmatw(P(:, i), T(:, i), w, p.Results.tau);
    end
  otherwise
    % nop
  end
  cm.cm   = cell2mat(cm.cm);
  cm.date = datestr(now, 'mm/dd/yyyy HH:MM');
  % }}}
return

% -------------
% Yuxiang Jiang (yuxjiang@indiana.edu)
% Department of Computer Science
% Indiana University Bloomington
% Last modified: Mon 23 May 2016 04:11:06 PM E
