function [] = cafa_driver_eval(cfg)
%CAFA_DRIVER_EVAL CAFA driver evaluation
%
% [] = CAFA_DRIVER_EVAL(cfg);
%
%   Evaluates CAFA models (based on pre-evaluation).
%
% Note
% ----
% All CAFA2 related meterials are assumed to be put in a single folder:
% (See cafa_driver_preeval.m for full file structures.)
%
% CAFA2
% |--   ...               (other sub-folders not listed)
% |-- ! seq-centric/      (pre-evaluation results will appear here)
% |     |-- ! mfo/
% |     |-- ! bpo/
% |     |-- ! cco/
% |     `-- ! hpo/
% |-- ! prediction/       (imported predictions in Matlab structures)
% |     |-- ! mfo/
% |     |-- ! bpo/
% |     |-- ! cco/
% |     `-- ! hpo/
% |-- ! benchmark/
% |     |-- lists/        (lists of benchmarks)
% |     `-- groundtruth/  (pre-computed annotations, see pfp_oabuild.m)
% `-- * evaluation/       (evaluation results appear in sub-folders here)
%       |-- ...
%       `-- <eval_dir>    (The evalution results, one file for each model. And
%                          the configuration guides this evaluation will also be
%                          saved in this folder as 'eval_config.job')
%
% folders marked with * will be updated.
% ................... ! need to be prepared as prerequisites.
%
% Input
% -----
% [char or struct]
% cfg:  The configuration file (job descriptor) or a parsed config structure.
%       See cafa_parse_config.m
%
% Dependency
% ----------
%[>]pfp_loaditem.m
%[>]cafa_parse_config.m
%[>]cafa_eval_seq_curve.m
%[>]cafa_eval_seq_fmax_bst.m
%[>]cafa_eval_seq_smin_bst.m
%[>]cafa_eval_term_auc.m
%
% See Also
% --------
%[>]cafa_driver_preeval.m

  % check inputs {{{
  if nargin ~= 1
    error('cafa_driver_eval:InputCount', 'Expected 1 input.');
  end

  % cfg
  config = cafa_parse_config(cfg);
  copyfile(cfg, fullfile(config.eval_dir, 'eval_config.job'));
  % }}}

  % evaluation {{{
  n = numel(config.model);
  if n > 8
    % parallel evaluation for batch running
    p = gcp('nocreate');
    if isempty(p)
      parpool(8);
    end

    parfor i = 1 : n
      % specify info for the model
      local_cfg = config;
      mid       = local_cfg.model{i};
      prev_file = fullfile(local_cfg.prev_dir, strcat(mid, '.mat'));
      pred_file = fullfile(local_cfg.pred_dir, strcat(mid, '.mat'));
      eval_file = fullfile(local_cfg.eval_dir, strcat(mid, '.mat'));

      loc_eval_single(local_cfg, mid, prev_file, pred_file, eval_file);
    end
  else
    % serial evaluation for small jobs
    for i = 1 : n
      % specify info for the model
      mid       = config.model{i};
      prev_file = fullfile(config.prev_dir, strcat(mid, '.mat'));
      pred_file = fullfile(config.pred_dir, strcat(mid, '.mat'));
      eval_file = fullfile(config.eval_dir, strcat(mid, '.mat'));

      loc_eval_single(config, mid, prev_file, pred_file, eval_file);
    end
  end
  % }}}
return

% function: loc_eval_single {{{
function [] = loc_eval_single(config, mid, prev_file, pred_file, eval_file)
  fprintf('Evaluating [%s]\n', mid);

  % NOTE: pre-evaluated structure: {{{
  % For pre-computation, we must fix a benchmark list, thus, only
  % sequence-centric metrics can be pre-computed.
  %
  % 'pr':  pre-computed precision-recall curves for macro-averaging prcurve,
  %        fmax, fmax_bst.
  %
  % 'wpr': pre-computed weighted (precision-recall) curves for macro-averaging
  %        wprcurve, wfmax, wfmax_bst.
  %
  % 'rm':  pre-computed RU-MI curves for macro-averaging rmcurve, smin,
  %        smin_bst.
  %
  % 'nrm': pre-computed normalized RU-MI curves for macro-averaging nrmcurve,
  %        nsmin, nsmin_bst.
  % }}}

  % sequence-centric Fmax {{{
  if config.do_seq_fmax
    load(prev_file, 'pr');

    % precision-recall curve
    prcurve = cafa_eval_seq_curve(mid, config.bm, pr, config.md);
    pfp_savevar(eval_file, prcurve, 'seq_prcurve');

    % Fmax
    fmax.id = prcurve.id;
    [fmax.fmax, fmax.point, fmax.tau] = pfp_fmaxc(prcurve.curve, prcurve.tau, config.beta);
    fmax.coverage = prcurve.coverage;
    fmax.mode = prcurve.mode;
    pfp_savevar(eval_file, fmax, 'seq_fmax');

    % bootstrapped Fmax
    fmax = cafa_eval_seq_fmax_bst(mid, config.bm, pr, config.md, config.bi, config.beta);
    pfp_savevar(eval_file, fmax, 'seq_fmax_bst');
  end
  % }}}

  % sequence-centric weighted Fmax {{{
  if config.do_seq_wfmax
    load(prev_file, 'wpr');

    % weighted precision-recall curve
    prcurve = cafa_eval_seq_curve(mid, config.bm, wpr, config.md);
    pfp_savevar(eval_file, prcurve, 'seq_wprcurve');

    % weighted Fmax
    fmax.id = prcurve.id;
    [fmax.fmax, fmax.point, fmax.tau] = pfp_fmaxc(prcurve.curve, prcurve.tau, config.beta);
    fmax.coverage = prcurve.coverage;
    fmax.mode = prcurve.mode;
    pfp_savevar(eval_file, fmax, 'seq_wfmax');

    % weighted bootstrapped Fmax
    fmax = cafa_eval_seq_fmax_bst(mid, config.bm, wpr, config.md, config.bi, config.beta);
    pfp_savevar(eval_file, fmax, 'seq_wfmax_bst');
  end
  % }}}

  % sequence-centric Smin {{{
  if config.do_seq_smin
    load(prev_file, 'rm');

    % RU-MI curve
    rmcurve = cafa_eval_seq_curve(mid, config.bm, rm, config.md);
    pfp_savevar(eval_file, rmcurve, 'seq_rmcurve');

    % Smin
    smin.id = rmcurve.id;
    [smin.smin, smin.point, smin.tau] = pfp_sminc(rmcurve.curve, rmcurve.tau);
    smin.coverage = rmcurve.coverage;
    smin.mode = rmcurve.mode;
    pfp_savevar(eval_file, smin, 'seq_smin');

    % bootstrapped Smin
    smin = cafa_eval_seq_smin_bst(mid, config.bm, rm, config.md, config.bi);
    pfp_savevar(eval_file, smin, 'seq_smin_bst');
  end
  % }}}

  % sequence-centric normalized Smin {{{
  if config.do_seq_nsmin
    load(prev_file, 'nrm');

    % RU-MI curve
    rmcurve = cafa_eval_seq_curve(mid, config.bm, nrm, config.md);
    pfp_savevar(eval_file, rmcurve, 'seq_nrmcurve');

    % Smin
    smin.id = rmcurve.id;
    [smin.smin, smin.point, smin.tau] = pfp_sminc(rmcurve.curve, rmcurve.tau);
    smin.coverage = rmcurve.coverage;
    smin.mode = rmcurve.mode;
    pfp_savevar(eval_file, smin, 'seq_nsmin');

    % bootstrapped Smin
    smin = cafa_eval_seq_smin_bst(mid, config.bm, nrm, config.md, config.bi);
    pfp_savevar(eval_file, smin, 'seq_nsmin_bst');
  end
  % }}}

  % term-centric AUC {{{
  if config.do_term_auc
    load(pred_file, 'pred');

    auc = cafa_eval_term_auc(mid, config.bm, pred, config.oa, config.md);
    pfp_savevar(eval_file, auc, 'term_auc');
  end
  % }}}
return
% }}}

% -------------
% Yuxiang Jiang (yuxjiang@indiana.edu)
% Department of Computer Science
% Indiana University Bloomington
% Last modified: Mon 08 May 2017 07:43:52 PM E
