function [ev] = cafa_eval_term_auc(id, bm, pred, oa, ev_mode, varargin)
%CAFA_EVAL_TERM_AUC CAFA evaluation term-centric AUC
% {{{ 
%
% [ev] = CAFA_EVAL_TERM_AUC(id, bm, pred, oa, ev_mode, varargin);
%
%   Computes the AUCs over each term from the confusion matrices.
%
% Input
% -----
% [char]
% id:       A string for model ID.
%
% [char or cell]
% bm:       A benchmark filename or a list of benchmark target IDs.
%
% [struct]
% pred:     The prediction structure.
%
% [struct]
% oa:       The reference structure.
%           See pfp_oabuild.m
%
% [char]
% ev_mode:  The mode of evaluation.
%           '1', 'full'     - averaged over the entire benchmark sets.
%                             missing prediction are treated as 0.
%           '2', 'partial'  - averaged over the predicted subset (partial).
%
% (optional) Name-Value pairs
% [double]
% 'tau'     An array of thresholds.
%           default: 0.00 : 0.01 : 1.00 (i.e. 0.00, 0.01, ..., 0.99, 1.00)
%
% [double]
% 'npos'    The number of positive annotations for a term to be evaluated
%           Note: we suggest 'npos' >= 10 so as to have a meaningful AUC.
%           default: 10
%
% Output
% ------
% [struct]
% ev: The AUC results per term:
%
%     [char]
%     .id     The model name, used for naming files.
%
%     [cell of char]
%     .term   1-by-m, term names. ('m': the number of terms)
%
%     [double]
%     .auc    1-by-m, AUC estimates.
%
%     [double]
%     .mode   The evaluation mode, passed through from input.
%
%     [double]
%     .npos   The number of positive annotations cutoff, passed through from input.
%
% Dependency
% ----------
%[>]pfp_loaditem.m
%[>]pfp_predproj.m
%[>]pfp_oaproj.m
%[>]get_auc.m
%[>]pfp_oabuild.m
% }}}

  % check inputs {{{
  if nargin < 5
    error('cafa_eval_term_auc:InputCount', 'Expected >= 5 inputs.');
  end

  % check the 1st input 'id' {{{
  validateattributes(id, {'char'}, {'nonempty'}, '', 'id', 1);
  % }}}

  % check the 2nd input 'bm' {{{
  validateattributes(bm, {'cell', 'char'}, {'nonempty'}, '', 'bm', 2);
  if ischar(bm) % load the benchmark if a file name is given
    bm = pfp_loaditem(bm, 'char');
  end
  % }}}

  % check the 3rd input 'pred' {{{
  validateattributes(pred, {'struct'}, {'nonempty'}, '', 'pred', 3);
  % }}}

  % check the 4th input 'oa' {{{
  validateattributes(oa, {'struct'}, {'nonempty'}, '', 'oa', 4);
  if numel(pred.ontology.term) ~= numel(oa.ontology.term) || ~all(strcmp({pred.ontology.term.id}, {oa.ontology.term.id}))
    error('cafa_eval_term_auc:InputErr', 'Ontology mismatch.');
  end
  % }}}

  % check the 5th input 'ev_mode' {{{
  ev_mode = validatestring(ev_mode, {'1', 'full', '2', 'partial'}, '', 'ev_mode', 5);
  % }}}
  % }}}

  % parse and check extra inputs {{{
  p = inputParser;

  defaultTAU  = 0.00 : 0.01 : 1.00;
  defaultNPOS = 10;

  addOptional(p, 'tau', defaultTAU, @(x) validateattributes(x, {'double'}, {'vector', '>=', 0, '<=', 1}));
  addOptional(p, 'npos', defaultNPOS, @(x) validateattributes(x, {'double'}, {'numel', 1, '>', 0}));

  parse(p, varargin{:});
  % }}}

  % align 'pred' and 'oa' onto the given target list {{{
  pred = pfp_predproj(pred, bm, 'object');
  oa   = pfp_oaproj(oa, bm, 'object');
  % }}}

  % find the valid terms that have enough positive annotations {{{
  valid = sum(oa.annotation, 1) >= p.Results.npos;
  % }}}

  % prepare P and T {{{
  switch ev_mode
  case {'1', 'full'}
    P = pred.score(:, valid);
    T = oa.annotation(:, valid);
  case {'2', 'partial'}
    covered = full(any(pred.score > 0, 2));
    P = pred.score(covered, valid);
    T = oa.annotation(covered, valid);
  otherwise
    % nop
  end
  % }}}

  % get auc {{{
  ev.id   = id;
  ev.term = reshape({oa.ontology.term(valid).id}, 1, []);

  k = numel(p.Results.tau);
  m = numel(ev.term);

  % non-empty check {{{
  if isempty(P) || isempty(T)
    ev.auc = nan(1, m);
    return;
  end
  % }}}

  ev.auc  = zeros(1, m);
  for i = 1 : m
    ev.auc(i) = get_auc([P(:, i), T(:, i)]);
  end
  ev.mode = ev_mode;
  ev.npos = p.Results.npos;
  % }}}
return

% -------------
% Yuxiang Jiang (yuxjiang@indiana.edu)
% Department of Computer Science
% Indiana University Bloomington
% Last modified: Tue 15 Sep 2015 02:06:00 PM E
