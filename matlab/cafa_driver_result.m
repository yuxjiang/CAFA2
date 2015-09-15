function [] = cafa_driver_result(eval_dir, cfg, naive, blast, mode)
%CAFA_DRIVER_RESULT CAFA driver result
% {{{
%
% [] = CAFA_DRIVER_RESULT(eval_dir, cfg, naive, blast);
%
%   Generates results for evaluation (plots, and sheets), according to the
%   evaluation configuration file '<eval_dir>/eval_config.job'.
%
% Input
% -----
% [char]
% eval_dir:   The directory that contains evaluation results.
%
% [char]
% cfg:        The team information.
%
% [char]
% naive:      The model name of naive baseline. E.g. BN1S
%
% [char]
% blast:      The model name of blast baseline. E.g. BB1S
%
% [char]
% mode:       The running mode, must be one of the following:
%             'paper' only generates figures in the main paper of the CAFA manuscript
%                     yaxis_fmax is set to [0.0, 0.8, 0.1]
%
%             'suppl' only generates figures in the supplementary of the CAFA manuscript
%                     yaxis_fmax is set to [] (adaptive)
%
%             'all'   generates all figures and sheets/tables
%                     yaxis_fmax is set to [] (adaptive)
%
% Output
% ------
% None.
%
% Dependency
% ----------
%[>]cafa_parse_config.m
%[>]cafa_collect.m
%[>]cafa_sel_top_seq_prcurve.m
%[>]cafa_sel_top_seq_rmcurve.m
%[>]cafa_sel_top_seq_fmax.m
%[>]cafa_sel_top_seq_smin.m
%[>]cafa_plot_seq_prcurve.m
%[>]cafa_plot_seq_rmcurve.m
%[>]cafa_barplot_seq_fmax.m
%[>]cafa_barplot_seq_smin.m
%[>]cafa_sheet_seq_fmax.m
%[>]cafa_sheet_seq_smin.m
%[>]cafa_sel_valid_term_auc.m
%[>]cafa_get_term_auc.m
%[>]cafa_team_read_config.m
% }}}

  % set-up {{{
  eval_dir = regexprep(strcat(eval_dir, '/'), '//', '/');
  config_file = strcat(eval_dir, 'eval_config.job');
  config = cafa_parse_config(config_file);
  saveto_prefix = strcat(regexprep(config.eval_dir, '.*/(.*)/$', '$1'), '_');

  if strcmp(mode, 'paper')
    yaxis_fmax = [0.0, 0.8, 0.1];
    yaxis_auc  = [];
  elseif strcmp(mode, 'suppl')
    yaxis_fmax = [];
    yaxis_auc  = [];
  elseif strcmp(mode, 'all')
    yaxis_fmax = [];
    yaxis_auc  = [];
  elseif strcmp(mode, 'test')
    yaxis_fmax = [];
    yaxis_auc  = [];
  else
    error('unknown running mode [%s].', mode);
  end

  plot_ext  = '.png';
  sheet_ext = '.csv';

  if strcmp(config.ont, 'mfo')
    ont_str = 'Molecular Function';
  elseif strcmp(config.ont, 'bpo')
    ont_str = 'Biological Process';
  elseif strcmp(config.ont, 'cco')
    ont_str = 'Cellular Component';
  elseif strcmp(config.ont, 'hpo')
    ont_str = 'Human Phenotype';
  else
    error('cafa_driver_result:BadOnt', 'Unknown ontology in the config.');
  end
  % }}}

  % top10 precision-recall curve {{{
  if strcmp(mode, 'suppl') || strcmp(mode, 'all')
    saveto = strcat(config.eval_dir, saveto_prefix, 'top10_fmax_curve', plot_ext);
    prcurves = cafa_collect(config.eval_dir, 'seq_prcurve');
    [top10, baseline] = cafa_sel_top_seq_prcurve(10, prcurves, naive, blast, cfg);
    cafa_plot_seq_prcurve(saveto, ont_str, top10, baseline);

    % mark alternative points {{{
    % rmcurves = cafa_collect(config.eval_dir, 'seq_rmcurve');
    % [top10, baseline] = cafa_sel_top_seq_prcurve(10, prcurves, naive, blast, cfg, rmcurves);
    % cafa_plot_seq_prcurve(saveto, ont_str, top10, baseline, true);
    % }}}
  end
  % }}}

  % all Fmax sheet {{{
  if strcmp(mode, 'all')
    saveto_A = strcat(config.eval_dir, saveto_prefix, 'all_fmax_sheet', sheet_ext);
    saveto_N = strcat(config.eval_dir, saveto_prefix, 'all_fmax_sheet_disclosed', sheet_ext);
    fmaxs = cafa_collect(config.eval_dir, 'seq_fmax');
    fmaxs_bst = cafa_collect(config.eval_dir, 'seq_fmax_bst');
    cafa_sheet_seq_fmax(saveto_A, fmaxs, fmaxs_bst, cfg, true);
    cafa_sheet_seq_fmax(saveto_N, fmaxs, fmaxs_bst, cfg, false);
  end
  % }}}

  % top10 weighted precision-recall curve {{{
  if (strcmp(mode, 'suppl') && (strcmp(config.cat, 'all') || strcmp(config.ont, 'hpo'))) ...
    || strcmp(mode, 'all')
    saveto = strcat(config.eval_dir, saveto_prefix, 'top10_wfmax_curve', plot_ext);
    prcurves = cafa_collect(config.eval_dir, 'seq_wprcurve');
    [top10, baseline] = cafa_sel_top_seq_prcurve(10, prcurves, naive, blast, cfg);
    cafa_plot_seq_prcurve(saveto, ont_str, top10, baseline);
  end
  % }}}

  % all weighted Fmax sheet {{{
  if strcmp(mode, 'all')
    saveto_A = strcat(config.eval_dir, saveto_prefix, 'all_wfmax_sheet', sheet_ext);
    saveto_N = strcat(config.eval_dir, saveto_prefix, 'all_wfmax_sheet_disclosed', sheet_ext);
    fmaxs = cafa_collect(config.eval_dir, 'seq_wfmax');
    fmaxs_bst = cafa_collect(config.eval_dir, 'seq_wfmax_bst');
    cafa_sheet_seq_fmax(saveto_A, fmaxs, fmaxs_bst, cfg, true);
    cafa_sheet_seq_fmax(saveto_N, fmaxs, fmaxs_bst, cfg, false);
  end
  % }}}

  % top10 RU-MI curve {{{
  if strcmp(mode, 'all')
    saveto = strcat(config.eval_dir, saveto_prefix, 'top10_smin_curve', plot_ext);
    rmcurves = cafa_collect(config.eval_dir, 'seq_rmcurve');
    [top10, baseline] = cafa_sel_top_seq_rmcurve(10, rmcurves, naive, blast, cfg);
    cafa_plot_seq_rmcurve(saveto, ont_str, top10, baseline);
  end
  % }}}

  % all Smin sheet {{{
  if strcmp(mode, 'all')
    saveto_A = strcat(config.eval_dir, saveto_prefix, 'all_smin_sheet', sheet_ext);
    saveto_N = strcat(config.eval_dir, saveto_prefix, 'all_smin_sheet_disclosed', sheet_ext);
    smins = cafa_collect(config.eval_dir, 'seq_smin');
    smins_bst = cafa_collect(config.eval_dir, 'seq_smin_bst');
    cafa_sheet_seq_smin(saveto_A, smins, smins_bst, cfg, true);
    cafa_sheet_seq_smin(saveto_N, smins, smins_bst, cfg, false);
  end
  % }}}

  % top10 normalized RU-MI curve {{{
  if (strcmp(mode, 'suppl') && (strcmp(config.cat, 'all') || strcmp(config.ont, 'hpo'))) ...
    || strcmp(mode, 'all')
    saveto = strcat(config.eval_dir, saveto_prefix, 'top10_nsmin_curve', plot_ext);
    rmcurves = cafa_collect(config.eval_dir, 'seq_nrmcurve');
    [top10, baseline] = cafa_sel_top_seq_rmcurve(10, rmcurves, naive, blast, cfg);
    cafa_plot_seq_rmcurve(saveto, ont_str, top10, baseline);
  end
  % }}}

  % all normalized Smin sheet {{{
  if strcmp(mode, 'all')
    saveto_A = strcat(config.eval_dir, saveto_prefix, 'all_nsmin_sheet', sheet_ext);
    saveto_N = strcat(config.eval_dir, saveto_prefix, 'all_nsmin_sheet_disclosed', sheet_ext);
    smins = cafa_collect(config.eval_dir, 'seq_nsmin');
    smins_bst = cafa_collect(config.eval_dir, 'seq_nsmin_bst');
    cafa_sheet_seq_smin(saveto_A, smins, smins_bst, cfg, true);
    cafa_sheet_seq_smin(saveto_N, smins, smins_bst, cfg, false);
  end
  % }}}

  % top10 Fmax bar {{{
  if strcmp(mode, 'paper') || strcmp(mode, 'suppl') || strcmp(mode, 'all')
    saveto = strcat(config.eval_dir, saveto_prefix, 'top10_fmax_bar', plot_ext);
    saveto_team = strcat(config.eval_dir, saveto_prefix, 'fmax_team.txt');
    fmaxs = cafa_collect(config.eval_dir, 'seq_fmax_bst');
    [top10, baseline, info] = cafa_sel_top_seq_fmax(10, fmaxs, naive, blast, cfg);
    cafa_barplot_seq_fmax(saveto, ont_str, top10, baseline, yaxis_fmax);
    save_team_info(saveto_team, info, cfg);
  end
  % }}}

  % top10 weighted Fmax bar {{{
  if strcmp(mode, 'all')
    saveto = strcat(config.eval_dir, saveto_prefix, 'top10_wfmax_bar', plot_ext);
    saveto_team = strcat(config.eval_dir, saveto_prefix, 'wfmax_team.txt');
    fmaxs = cafa_collect(config.eval_dir, 'seq_wfmax_bst');
    [top10, baseline, info] = cafa_sel_top_seq_fmax(10, fmaxs, naive, blast, cfg);
    cafa_barplot_seq_fmax(saveto, ont_str, top10, baseline, yaxis_fmax);
    save_team_info(saveto_team, info, cfg);
  end
  % }}}

  % top10 Smin bar {{{
  if (strcmp(mode, 'paper') && (strcmp(config.cat, 'all') || strcmp(config.ont, 'hpo'))) ...
    || strcmp(mode, 'all')
    saveto = strcat(config.eval_dir, saveto_prefix, 'top10_smin_bar', plot_ext);
    saveto_team = strcat(config.eval_dir, saveto_prefix, 'smin_team.txt');
    smins = cafa_collect(config.eval_dir, 'seq_smin_bst');
    [top10, baseline, info] = cafa_sel_top_seq_smin(10, smins, naive, blast, cfg);
    cafa_barplot_seq_smin(saveto, ont_str, top10, baseline);
    save_team_info(saveto_team, info, cfg);
  end
  % }}}

  % top10 normalized Smin bar {{{
  if strcmp(mode, 'all')
    saveto = strcat(config.eval_dir, saveto_prefix, 'top10_nsmin_bar', plot_ext);
    saveto_team = strcat(config.eval_dir, saveto_prefix, 'nsmin_team.txt');
    smins = cafa_collect(config.eval_dir, 'seq_nsmin_bst');
    [top10, baseline, info] = cafa_sel_top_seq_smin(10, smins, naive, blast, cfg);
    cafa_barplot_seq_smin(saveto, ont_str, top10, baseline);
    save_team_info(saveto_team, info, cfg);
  end
  % }}}

  % averaged AUC (over all teams) {{{
  if (strcmp(mode, 'paper') && strcmp(config.ont, 'hpo')) ...
    || strcmp(mode, 'all')
    saveto = strcat(config.eval_dir, saveto_prefix, 'avg_auc_bar', plot_ext);
    aucs = cafa_collect(config.eval_dir, 'term_auc');

    % load term acc <--> term name table
    fid = fopen(config.ont_term, 'r');
    terms = textscan(fid, '%s%s', 'Delimiter', '\t');
    fclose(fid);

    % note that filtered aucs could be empty, for all terms are fully annotated
    % like root, which results in NaN AUC.
    aucs = cafa_sel_valid_term_auc(aucs); % keep only participating models
    if ~isempty(aucs)
      % [~, index] = ismember(aucs{1}.term, terms{1});
      cafa_plot_term_avgauc(saveto, ont_str, aucs, config.oa.ontology, yaxis_auc);
    else
      warning('No model is selected.');
    end
  end
  % }}}

  % [FOR TEST] averaged AUC (over top 5 teams) {{{
  if strcmp(mode, 'test')
    saveto = strcat(config.eval_dir, saveto_prefix, 'top5avg_auc_bar', plot_ext);
    fmaxs  = cafa_collect(config.eval_dir, 'seq_fmax_bst');
    [~, ~, info] = cafa_sel_top_seq_fmax(5, fmaxs, naive, blast, cfg);
    aucs = cafa_collect(config.eval_dir, 'term_auc');

    % load term acc <--> term name table
    fid = fopen(config.ont_term, 'r');
    terms = textscan(fid, '%s%s', 'Delimiter', '\t');
    fclose(fid);

    % select top 5 methods
    aucs = cafa_get_term_auc(aucs, info.top_mid);

    % note that filtered aucs could be empty, for all terms are fully annotated
    % like root, which results in NaN AUC.
    aucs = cafa_sel_valid_term_auc(aucs); % keep only participating models
    if ~isempty(aucs)
      % [~, index] = ismember(aucs{1}.term, terms{1});
      cafa_plot_term_avgauc(saveto, ont_str, aucs, config.oa.ontology, yaxis_auc);
    else
      warning('No model is selected.');
    end
  end
  % }}}

  % all AUC sheet {{{
  if strcmp(mode, 'all')
    saveto_A = strcat(config.eval_dir, saveto_prefix, 'all_auc_sheet', sheet_ext);
    saveto_N = strcat(config.eval_dir, saveto_prefix, 'all_auc_sheet_disclosed', sheet_ext);
    aucs = cafa_collect(config.eval_dir, 'term_auc');
    if strcmp(config.ont, 'hpo')
      cafa_sheet_term_auc(saveto_A, aucs, cfg, true, 'BB4H');
      cafa_sheet_term_auc(saveto_N, aucs, cfg, false, 'BB4H');
    else % MFO, BPO, CCO
      cafa_sheet_term_auc(saveto_A, aucs, cfg, true, 'BB4S');
      cafa_sheet_term_auc(saveto_N, aucs, cfg, false, 'BB4S');
    end
  end
  % }}}

  % top10 methods in averaged AUC (over all terms) bar {{{
  if (strcmp(mode, 'paper') && (strcmp(config.cat, 'all') || strcmp(config.ont, 'hpo'))) ...
    || strcmp(mode, 'all')
    if strcmp(mode, 'paper')
      yaxis_auc = [0.2, 1.0, 0.1];
    end
    saveto = strcat(config.eval_dir, saveto_prefix, 'top10_auc_bar', plot_ext);
    aucs = cafa_collect(config.eval_dir, 'term_auc');
    [top10, baseline, info] = cafa_sel_top_term_auc(10, aucs, naive, blast, cfg);
    if isempty(top10)
      warning('cafa_driver_result:FewTerm', 'All terms are positive, No plots are generated.');
    else
      cafa_barplot_term_auc(saveto, ont_str, top10, baseline, yaxis_auc);
    end
  end
  % }}}
return

% function: save_team_info {{{
function [] = save_team_info(saveto, info, cfg)
  [iid, eid, tname, ~, dname, pi] = cafa_team_read_config(cfg);
  fid = fopen(saveto, 'w');
  fprintf(fid, 'qualified model counts [%3d]\n', numel(info.all_mid));
  fprintf(fid, '----------------------------\n');
  fprintf(fid, 'internal,external,teamname,display,pi\n');
  for i = 1 : numel(info.all_mid)
    [~, j] = ismember(info.all_mid{i}, iid);
    fprintf(fid, '%s,%s,%s,%s,%s\n', iid{j}, eid{j}, tname{j}, dname{j}, pi{j});
  end
  fprintf(fid, '\n');
  fprintf(fid, 'top 10 models (at most one per PI)\n');
  fprintf(fid, '----------------------------------\n');
  fprintf(fid, 'internal,external,teamname,display,pi\n');
  for i = 1 : numel(info.top_mid)
    [~, j] = ismember(info.top_mid{i}, iid);
    fprintf(fid, '%s,%s,%s,%s,%s\n', iid{j}, eid{j}, tname{j}, dname{j}, pi{j});
  end
  fclose(fid);
return
% }}}

% -------------
% Yuxiang Jiang (yuxjiang@indiana.edu)
% Department of Computer Science
% Indiana University, Bloomington
% Last modified: Tue 15 Sep 2015 01:29:31 PM E
