function [model] = cafa_train_ensemble(bm, k, v)
%CAFA_TRAIN_ENSEMBLE CAFA train ensemble
% {{{
%
% [model] = CAFA_TRAIN_ENSEMBLE(bm);
%
%   Returns a combined linear model of a benchmark category.
%
% Input
% -----
% [char]
% bm:     The benchmark, which is encoded as: <ontology>_<category>_<type>_<mode>
%
%         For example: mfo_HUMAN_type1_mode1
%
%         Also, the specified benchmark should have been evaluated, i.e. there
%         must be an existing subfolder (having the same name) under
%         [CAFA_DIR]/evaluation/
%
% [double]
% k:      The number of models to keep (having non-zero coefficient).
%
% [double]
% v:      The number of folds for "cross-validation"
%
% Output
% ------
% [struct]
% model:  A k-by-1 vector of beta hat in the case of a linear model.
%         .iid          1-by-n cell array of model internal IDs.
%         .dname        1-by-n cell array of model display names.
%         .beta         1-by-n double array, at most k of which are non-zero.
%         .perf         1-by-n double array of performance (fmax).
%         .perf_comb    double, performance of the combined model.
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
% }}}

  % basic setting {{{
  param.CAFA_DIR = '~/cafa';
  param.learner  = 'ols';
  % }}}

  % check inputs {{{
  if nargin ~= 3
    error('cafa_train_ensemble:InputCount', 'Expected 3 inputs.');
  end

  % check the 1st input 'bm'
  validateattributes(bm, {'char'}, {'nonempty'}, '', 'bm', 1);
  tokens = strsplit(bm, '_');
  if ~exist(fullfile(param.CAFA_DIR, 'prediction', tokens{1}), 'dir')
    error('cafa_pick_models:InputErr', 'Prediction folder does not exist.');
  end

  % check the 2nd input 'k'
  validateattributes(k, {'double'}, {'>', 0}, '', 'k', 2);

  % check the 3rd input 'v'
  validateattributes(v, {'double'}, {'>', 0}, '', 'v', 3);
  % }}}

  % load model iids {{{
  mids = cafa_pick_models(Inf, bm, 1); % pick all models.
  % }}}

  % load target values {{{
  % load benchmarks
  list_file = strcat(tokens{1}, '_', tokens{2}, '_', tokens{3}, '.txt');
  benchmark = pfp_loaditem(fullfile(param.CAFA_DIR, 'benchmark', 'lists', list_file), 'char');

  gt = load(fullfile(param.CAFA_DIR, 'benchmark', 'groundtruth', [tokens{1}, 'a']), 'oa');
  oa = pfp_oaproj(gt.oa, benchmark, 'object');
  Y  = oa.annotation;
  % }}}

  % load predictions {{{
  fprintf('loading predictions ...\n');
  m = numel(mids);
  for i = 1 : m
    data = load(fullfile(param.CAFA_DIR, 'prediction', tokens{1}, mids{i}), 'pred');
    data = pfp_predproj(data.pred, benchmark, 'object');
    X{i} = data.score;
  end
  % }}}

  % split (training, test) {{{
  n  = size(Y, 1);
  tv = randsample(n, floor(0.75*n)); % training + val
  ts = setdiff(1:n, tv); % test
  
  tv_X = cell(1, m);
  ts_X = cell(1, m);
  for i = 1 : m
    tv_X{i} = X{i}(tv, :);
    ts_X{i} = X{i}(ts, :);
  end
  tv_Y = Y(tv, :);
  ts_Y = Y(ts, :);
  % }}}

  % pick k models and learn an ensemble {{{
  fprintf('learning an ensemble ...\n');
  param.k        = k;
  param.nfolds   = v;
  param.mids     = mids;
  model          = learn_model(tv_X, tv_Y, param);
  % }}}

  % test performance {{{
  fprintf('evaluating performance ...\n');
  pred_ts = apply_model(model, benchmark, X, ts, oa.ontology);

  model.perf_comb = pfp_seqmetric(benchmark(ts), pred_ts, oa, 'fmax');
  model.perf      = zeros(1, m);
  for i = 1 : m
    pred.object    = benchmark(ts);
    pred.ontology  = oa.ontology;
    pred.score     = X{i}(ts, :);
    model.perf(i)  = pfp_seqmetric(benchmark(ts), pred, oa, 'fmax');
  end
  % }}}
return

% function: preprocess_xy {{{
function [px, py] = preprocess_xy(x, y, index)
  p = length(x);
  px = cell(1, p);
  if nargin == 3
    for i = 1 : p
      px{i} = reshape(x{i}(index,:), [], 1);
    end
    px = cell2mat(px);
    py = reshape(y(index,:), [], 1);
  else
    for i = 1 : p
      px{i} = reshape(x{i}, [], 1);
    end
    px = cell2mat(px);
    py = reshape(y, [], 1);
  end
return
% }}}

% function: learn_model {{{
% assumes x to be a p-by-1 row cell array (p = 10 for most cases)
%         each of which is a (double) n-by-m matrix
%         y to be a (binary) n-by-m matrix
%         where n: # of proteins, m: # of terms
function [model] = learn_model(x, y, param)
  p = numel(x);
  [n, m] = size(y);
  votes = zeros(1, p);
  % v-fold cross-validation {{{
  index = crossvalind('Kfold', n, param.nfolds);
  for i = 1 : param.nfolds
    val = (index == i);
    tr  = (index ~= i);

    % get votes
    [tr_X, tr_Y] = preprocess_xy(x, y, tr);

    % remove all zero rows (for speeding up LASSO)
    allzero = all(tr_X==0, 2);
    tr_X(allzero, :) = [];
    tr_Y(allzero)    = [];
    [B, FitInfo] = lasso(tr_X, tr_Y, 'DFMax', param.k);
    weight = 1 / FitInfo.MSE(1);
    picked = find(B(:, 1) ~= 0);
    votes(picked) = votes(picked) + weight;
  end
  % }}}

  [~, index] = sort(votes, 'descend');
  idk = index(1:param.k); % index to keep
  x = x(idk); % keep only the selected k models
  [x, y] = preprocess_xy(x, y);

  if strcmp(param.learner, 'ols')
    beta = (x'*x)\(x'*y); % linear regression
  elseif strcmp(param.learner, 'logistic_regression')
    beta = mnrfit(x, y+1);
  else
    error('cafa_train_ensemble:Learner', 'Unknown learner.');
  end

  cfile = fullfile(param.CAFA_DIR, 'config', 'config.tab');

  model.learner   = param.learner;
  model.iid       = param.mids;
  model.dname     = cafa_team_iid2dname(cfile, param.mids);
  model.beta      = zeros(1, p);
  model.beta(idk) = beta;
return
% }}}

% function: apply_model {{{
function [pred] = apply_model(model, bm, X, pid, ont)
% model:  learned model
% bm:     a list of benchmark
% X:      test set X
% pid:    benchmark (protein) index of test set
% ont:    ontology structure
  pred.object   = bm(pid);
  pred.ontology = ont;
  
  pred.score = sparse(numel(pid), numel(ont.term));
  % weighted sum
  if numel(model.beta) ~= numel(X)
    error('cafa_train_ensemble:ModelCount', 'Incorrect number of models.');
  end
  n = numel(model.beta);

  for i = 1 : n
    if model.beta(i) == 0
      continue;
    end
    pred.score = pred.score + model.beta(i) * X{i}(pid, :);
  end

  if strcmp(model.learner, 'ols')
    % do nothing
  elseif strcmp(model.learner, 'logistic_regression')
    % apply the linker function
    pred.score = 1 ./ (1 + exp(-pred.score));
  else
    % do nothing
  end

  % normalize each row (protein) separately
  max_scores = pred.score(:, pfp_roottermidx(ont));
  min_scores = min(pred.score, [], 2);
  pred.score = pfp_minmaxnrm(pred.score', min_scores', max_scores')';
  pred = pfp_predprop(pred, true, 'max');
return
% }}}

% -------------
% Yuxiang Jiang (yuxjiang@indiana.edu)
% Department of Computer Science
% Indiana University, Bloomington
% Last modified: Mon 01 Feb 2016 04:38:07 PM E
