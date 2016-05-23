function [res] = cafa_eval_one_term_auc(cfg, term)
%CAFA_EVAL_ONE_TERM_AUC Evaluate one term using AUC
%
% [res] = CAFA_EVAL_ONE_TERM_AUC(cfg, term);
%
%   Computes term-centric AUC of predictions on one given term.
%
% Input
% -----
% [char or struct]
% cfg:  The configuration file (job descriptor) or a parsed config structure.
%       See cafa_parse_config.m
%
% [char]
% term: GO term ID.
%
% Output
% ------
% [cell]
% res:  An n-by-2 cell array of AUC evaluation results.
%       Column 1: methods ID
%       Column 2: AUC
%
% Dependency
% ----------
%[>]cafa_parse_config.m

  % check inputs {{{
  if nargin ~= 2
    error('cafa_eval_one_term_auc:InputCount', 'Expected 2 input.');
  end

  % cfg
  config = cafa_parse_config(cfg);

  % term
  validateattributes(term, {'char'}, {'nonempty'}, '', 'term', 2);
  [found, index] = ismember(term, {config.oa.ontology.term.id});
  if ~found
    error('cafa_eval_one_term_auc:InputErr', 'This term cannot be found in the evaluation.');
  end
  % }}}

  % prepare ground truth vector {{{
  oa = pfp_oaproj(config.oa, config.bm, 'object');
  T  = oa.annotation(:, index); % ground truth vector
  if ~any(T)
    error('cafa_eval_one_term_auc:NoPos', 'No positive annotations on this term.');
  end

  if sum(T) < 10
    warning('cafa_eval_one_term_auc:FewPos', 'Positive annotations are less than 10');
  end
  % }}}

  % evaluation {{{
  n = numel(config.model);
  res = cell(n, 2);
  for i = 1 : n
    fprintf('model: [%s], %d/%d\n', config.model{i}, i, n);
    load(fullfile(config.pred_dir, config.model{i}));
    pred = pfp_predproj(pred, config.bm, 'object');
    P = pred.score(:, index); % prediction vector
    res{i, 1} = config.model{i};
    res{i, 2} = get_auc([P, T]);
  end
  % }}}
return

% -------------
% Yuxiang Jiang (yuxjiang@indiana.edu)
% Department of Computer Science
% Indiana University, Bloomington
% Last modified: Mon 23 May 2016 02:35:16 PM E
