function [model] = cafa_train_ensemble(bm, k, scheme, learner)
%CAFA_TRAIN_ENSEMBLE CAFA train ensemble
%
% [model] = CAFA_TRAIN_ENSEMBLE(bm, k, scheme, learner);
%
%   Returns a combined linear model of a benchmark category.
%
% Input
% -----
% [char]
% bm:       The benchmark, which is encoded as: <ontology>_<category>_<type>_<mode>
%           For example: mfo_HUMAN_type1_mode1
%           Also, the specified benchmark should have been evaluated, i.e. there
%           must be an existing subfolder (having the same name) under
%           [CAFA_DIR]/evaluation/
%
% [double]
% k:        The number of selected models.
%
% [char]
% scheme:   How to select models. Available schemes are:
%           'lasso' - use LASSO to fit a linear model
%           'sfs'   - sequential forward (feature) selection
%
% [char]
% learner:  Learning model. Available models are:
%           'ols' - ordinary least square
%           'lr'  - logistic regression
%           'nn'  - neural network
%
% Output
% ------
% [struct]
% model:  The learned ensemble model, which contains the following:
%         .scheme     one of {'lasso', 'sfs'}
%         .learner    one of {'ols', 'lr', 'nn'}
%         .iid        1-by-p cell array of model internal IDs.
%         .dname      1-by-p cell array of model display names.
%         .selected   1-by-k index
%         .theta      model parameter
%                     if learner = ['ols'] or ['lr']
%                     1-by-p double array, at most k of which are non-zero.
%                     if learner = ['nn']
%                     the trained neural network model.
%         .perf       1-by-p double array of performance (fmax).
%         .perf_comb  double, performance of the combined model.
%
% Dependency
% ----------
%[>]pfp_loaditem.m
%[>]pfp_oaproj.m
%[>]pfp_roottermidx.m
%[>]pfp_predproj.m
%[>]pfp_predprop.m
%[>]pfp_minmaxnrm.m
%[>]pfp_seqmetric.m
%[>]cafa_pick_models.m
%[>]cafa_team_iid2dname.m

  % basic setting {{{
  param.CAFA_DIR = '~/cafa';
  % }}}

  % check inputs {{{
  if nargin ~= 4
    error('cafa_train_ensemble:InputCount', 'Expected 4 inputs.');
  end

  % bm
  validateattributes(bm, {'char'}, {'nonempty'}, '', 'bm', 1);
  tokens = strsplit(bm, '_');
  if ~exist(fullfile(param.CAFA_DIR, 'prediction', tokens{1}), 'dir')
    error('cafa_pick_models:InputErr', 'Prediction folder does not exist.');
  end

  % k
  validateattributes(k, {'double'}, {'>', 0}, '', 'k', 2);
  param.k = k;

  % scheme
  param.scheme = validatestring(scheme, {'lasso', 'sfs'}, '', 'scheme', 3);

  % learner
  param.learner = validatestring(learner, {'ols', 'lr', 'nn'}, '', 'learner', 4);
  % }}}

  % load model iids {{{
  param.mids = cafa_pick_models(Inf, bm, 1); % pick all models.
  % }}}

  % load target values {{{
  % load benchmarks
  list_file = strcat(tokens{1}, '_', tokens{2}, '_', tokens{3}, '.txt');
  benchmark = pfp_loaditem(fullfile(param.CAFA_DIR, 'benchmark', 'lists', list_file), 'char');

  data           = load(fullfile(param.CAFA_DIR, 'benchmark', 'groundtruth', [tokens{1}, 'a']), 'oa');
  param.oa       = pfp_oaproj(data.oa, benchmark, 'object'); % Y will be oa.annotation
  param.small_oa = pfp_annotsuboa(param.oa);
  % }}}

  % load predictions {{{
  fprintf('loading predictions ...\n');
  param.p = numel(param.mids); % number of candidate models
  n = numel(benchmark);  % number of proteins
  param.preds = cell(1, param.p);
  x     = cell(1, param.p);
  for j = 1 : param.p
    data = load(fullfile(param.CAFA_DIR, 'prediction', tokens{1}, param.mids{j}), 'pred');
    param.preds{j} = pfp_predproj(data.pred, benchmark, 'object'); % for evaluation
    x{j} = param.preds{j}.score;
  end
  % }}}

  % split (training + validation, test) {{{
  tv = randsample(n, floor(0.90*n)); % training + validation set
  ts = setdiff(1:n, tv); % test set

  [tv_x, tv_y, ts_x, ts_y] = loc_split_ds(x, param.oa.annotation, tv, ts);
  param.tv_benchmark = benchmark(tv);
  % }}}

  % learn an ensemble with k models {{{
  fprintf('learning an ensemble ...\n');
  param.nfolds = 5; % do 5-fold cross-validation when needed
  model = loc_learn_model(tv_x, tv_y, param);
  % }}}

  % test performance {{{
  fprintf('evaluating performance ...\n');
  pred_ts = loc_apply_model(model, benchmark(ts), param.preds, param.oa);

  model.perf_comb = pfp_seqmetric(benchmark(ts), pred_ts, param.oa, 'fmax');
  model.perf      = zeros(1, param.p);
  for j = 1 : param.p
    model.perf(j) = pfp_seqmetric(benchmark(ts), param.preds{j}, param.oa, 'fmax');
  end
  % }}}
return

% function: loc_split_ds(x, y, id1, id2) {{{
function [x1, y1, x2, y2] = loc_split_ds(x, y, id1, id2)
  p = numel(x);
  x1 = cell(1, p);
  x2 = cell(1, p);
  for j = 1 : p
    x1{j} = x{j}(id1, :);
    x2{j} = x{j}(id2, :);
  end
  y1 = y(id1, :);
  y2 = y(id2, :);
return
% }}}

% function: loc_preprocess_xy(x, y) {{{
function [px, py] = loc_preprocess_xy(x, y)
% {{{
% Input
% -----
% [cell]
% x: 1-by-p cell array of score matrices, each of which having size n-by-m.
%
% [double]
% y: n-by-m binary annotation matrix.
%
% Output
% ------
% [double]
% px: N-by-p preprocessed score matrix.
%
% [double]
% px: N-by-1 preprocessed annotation matrix.
% }}}
%
% 1. Removes terms with same annotation (i.e., all 0 or 1, for all proteins).
% 2. Concatenates terms to be a long vector for each model.

  p = numel(x);
  keep = find(~all(bsxfun(@eq, y, y(1,:)), 1)); % find columns to keep
  for j = 1 : p
    x{j} = reshape(x{j}(:, keep), [], 1);
  end
  px = cell2mat(x);
  py = reshape(y(:, keep), [], 1);
return
% }}}

% function: loc_learn_model(x, y, param) {{{
function [model] = loc_learn_model(x, y, param)
% {{{
% Input
% -----
% [cell]
% x: 1-by-p cell array of score matrices, each of which having size n-by-m.
%
% [double]
% y: n-by-m binary annotation matrix.
%
% Output
% ------
% model
% }}}

  % record configurations {{{
  model.scheme  = param.scheme;
  cfile         = fullfile(param.CAFA_DIR, 'config', 'config.tab');
  model.learner = param.learner;
  model.iid     = param.mids;
  model.dname   = cafa_team_iid2dname(cfile, param.mids);
  % }}}

  n = size(y, 1);
  model.votes = zeros(1, param.p);

  % set up a template of ols model to be a criterion for feature selection {{{
  criterion.learner  = 'ols';
  criterion.selected = [];                % place-holder
  criterion.theta    = zeros(param.p, 1); % place-holder
  % }}}

  for v = 1 : param.nfolds
    fprintf('fold [%d] of %d ...\n', v, param.nfolds);

    % split (training, validation) set, and preprocess {{{
    index = crossvalind('Kfold', n, param.nfolds);
    tr = (index ~= v);
    va = (index == v);
    [tr_x, tr_y, va_x, va_y] = loc_split_ds(x, y, tr, va);
    [tr_x, tr_y] = loc_preprocess_xy(tr_x, tr_y);
    % }}}

    % make predictions on the small annotated sub-ontology
    small_preds = cell(1, param.p);
    for j = 1 : param.p
      small_preds{j} = pfp_predproj(param.preds{j}, {param.small_oa.ontology.term.id}, 'term');
    end

    % compute weighted votes of this fold
    selected = [];
    weight   = 0;
    switch param.scheme
    case 'lasso'
      % use LASSO to vote {{{
      B = lasso(tr_x, tr_y, 'DFMax', param.k);
      selected = find(B(:, 1) ~= 0);

      % update criterion
      criterion.selected = selected;
      criterion.theta    = B;

      % evaluate on the validation set
      pred_va = loc_apply_model(criterion, param.tv_benchmark, param.preds, param.oa);
      weight  = pfp_seqmetric(param.tv_benchmark, pred_va, param.oa, 'fmax');
      % }}}
    case 'sfs'
      % sequential (forward) selection {{{
      selected     = [];
      best_overall = 0; % use fmax as performance
      while numel(selected) < param.k
        best_id    = 0;
        best_round = 0;
        for j = 1 : param.p
          if ismember(j, selected)
            continue;
          end
          candidates = [selected, j];
          candid_x   = tr_x(:, candidates);
          candid_param = loc_learn_ols(candid_x, tr_y);

          % update criterion
          criterion.selected          = candidates;
          criterion.theta             = zeros(param.p, 1);
          criterion.theta(candidates) = candid_param;

          % evaluate on the validation set
          % pred_va = loc_apply_model(criterion, param.tv_benchmark, param.preds, param.oa);
          % perf    = pfp_seqmetric(param.tv_benchmark, pred_va, param.oa, 'fmax');
          pred_va = loc_apply_model(criterion, param.tv_benchmark, small_preds, param.small_oa);
          perf    = pfp_seqmetric(param.tv_benchmark, pred_va, param.small_oa, 'fmax');

          if perf > best_round % found a better candidate
            best_round = perf;
            best_id = j;
          end
        end

        if best_round > best_overall
          best_overall = best_round;
          selected = [selected, best_id];
        else
          fprintf('adding methods doesn''t improve performance, early stop.\n');
          break; % early-stopping
        end
      end
      weight = best_overall;
      % }}}
    otherwise
      % do nothing
    end
    % collect weighted votes
    model.votes(selected) = model.votes(selected) + weight;
  end
  [~, index]     = sort(model.votes, 'descend');
  model.selected = index(1:param.k); % index to keep

  x = x(model.selected); % keep only the selected k models

  [x, y] = loc_preprocess_xy(x, y);
  if strcmp(param.learner, 'ols')
    model.theta = zeros(1, param.p);
    model.theta(model.selected) = loc_learn_ols(x, y); % linear regression
  elseif strcmp(param.learner, 'lr') % TODO
    model.theta = zeros(1, param.p);
    model.theta(model.selected) = loc_learn_lr(x, y); % logistic regression
  elseif strcmp(param.learner, 'nn')
    model.theta = loc_learn_nn(x, y); % neural network
  end
return
% }}}

% function: loc_apply_model(model, bm, preds, oa) {{{
function [pred] = loc_apply_model(model, bm, preds, oa)
% {{{
% Input
% -----
% [struct]
% model: The learned model.
%
% [cell]
% bm:    A list of benchmark.
%
% [cell]
% preds: A cell of pred structures.
%
% [struct]
% oa:    The ontology annotation structure.
%
% Output
% ------
% [struct]
% pred: the prediction structure.
% }}}

  pred.object   = bm;
  pred.ontology = oa.ontology;
  pred.score    = sparse(numel(bm), numel(oa.ontology.term));

  index = model.selected;
  % apply model
  if strcmp(model.learner, 'ols')
    % weighted sum
    for j = 1 : numel(index)
      P = pfp_predproj(preds{index(j)}, bm, 'object');
      pred.score = pred.score + model.theta(index(j)) * P.score;
    end
  elseif strcmp(model.learner, 'lr')
    % weighted sum
    for j = 1 : numel(index)
      P = pfp_predproj(preds{index(j)}, bm, 'object');
      pred.score = pred.score + model.theta(index(j)) * P.score;
    end
    % apply the linker function
    pred.score = 1 ./ (1 + exp(-pred.score));
  elseif strcmp(model.learner, 'nn')
    x = cell(1, numel(index));
    for j = 1 : numel(index)
      P = pfp_predproj(preds{index(j)}, bm, 'object');
      x{j} = reshape(P.score, [], 1);
    end
    x = cell2mat(x);
    pred.score = reshape(sim(model.theta, x')', numel(bm), []);
  end

  % normalize each row (protein) separately
  % max_scores = pred.score(:, pfp_roottermidx(oa.ontology));
  % min_scores = min(pred.score, [], 2);
  % pred.score = pfp_minmaxnrm(pred.score', min_scores', max_scores')';
  min_score  = min(min(pred.score));
  pred.score = cafa_norm_pred(pred.score - min_score);
  %
  pred = pfp_predprop(pred, true, 'max');
return
% }}}

% function: loc_learn_ols(x, y) {{{
function [beta] = loc_learn_ols(x, y)
  beta = (x' * x) \ (x' * y);
return
% }}}

% function: loc_learn_lr(x, y) {{{
function [beta] = loc_learn_lr(x, y)
  beta = mnrfit(x, y+1);
return
% }}}

% function: loc_learn_nn(x, y) {{{
function [net, perf] = loc_learn_nn(x, y)
  % sub-sampling {{{
  if size(x, 1) > 100000
    index = randsample(size(x, 1), 100000);
    x = x(index, :);
    y = y(index);
  end
  % }}}

  net = feedforwardnet(5);

  % setup
  net.layers{1}.transferFcn            = 'tansig';
  net.layers{2}.transferFcn            = 'logsig';
  net.inputs{1}.processFcns            = {'mapminmax'};
  net.outputs{2}.processFcns           = {'mapminmax'};
  net.outputs{2}.processParams{1}.ymin = 0;
  net.outputs{2}.processParams{1}.ymax = 1;
  net.divideParam.trainRatio           = 0.7;
  net.divideParam.valratio             = 0.3;
  net.divideParam.testRatio            = 0;
  net.trainParam.epochs                = 100;
  net.trainParam.max_fail              = 10;

  net.trainParam.showWindow      = false;
  net.trainParam.showCommandLine = false;

  net         = init(net);
  [net, info] = train(net, x', y');
  perf        = info.best_vperf; % best performance on the validation set
return
% }}}

% -------------
% Yuxiang Jiang (yuxjiang@indiana.edu)
% Department of Computer Science
% Indiana University, Bloomington
% Last modified: Mon 23 May 2016 03:45:33 PM E
