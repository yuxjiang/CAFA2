function [] = cafa_driver_eval(config_info)
%CAFA_DRIVER_EVAL CAFA driver evaluation
% {{{
%
% [] = CAFA_DRIVER_EVAL(config_info);
%
%   Evaluates CAFA models (based on pre-evaluation).
%
% Input
% -----
% [char or struct]
% config_info:  the configuration file (job descriptor) or a parsed config
%               structure.
%
%               See cafa_parse_config.m
%
% Dependency
% ----------
%[>]pfp_loaditem.m
%[>]cafa_parse_config.m
%[>]cafa_eval_seq_curve.m
%[>]cafa_eval_seq_fmax_bst.m
%[>]cafa_eval_seq_smin_bst.m
%[>]cafa_eval_term_auc.m
% }}}

  % parse and save config {{{
  if ischar(config_info)
    config = cafa_parse_config(config_info);
    % save the configuration file for future reference
    copyfile(config_info, strcat(config.eval_dir, 'eval_config.job'));
  elseif isstruct(config_info)
    config = config_info;
  else
    error('cafa_driver_eval:InputErr', 'Unknown data type of ''config_info''');
  end
  % }}}

  % evaluation {{{
  % create parallel worders
  p = gcp('nocreate');
  if isempty(p)
    parpool(8);
  end
  n = numel(config.model);

%  % patch: skip regular models, only eval baseline models {{{
%  isreg = false(1, n);
%  for i = 1 : n
%    if strcmp(config.model{i}(1), 'M')
%      isreg(i) = true;
%    end
%  end
%  config.model(isreg) = [];
%  n = numel(config.model); % update n
%  % }}}

  parfor i = 1 : n
  % for i = 1 : n
    % specify info for the model
    mid       = config.model{i};
    prev_file = strcat(config.prev_dir, mid, '.mat');
    pred_file = strcat(config.pred_dir, mid, '.mat');
    eval_file = strcat(config.eval_dir, mid, '.mat');

    eval_single(config, mid, prev_file, pred_file, eval_file);
  end
  % }}}
return

% function: eval_single {{{
function [] = eval_single(config, mid, prev_file, pred_file, eval_file)
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
% Last modified: Fri 17 Jul 2015 02:40:41 PM E
