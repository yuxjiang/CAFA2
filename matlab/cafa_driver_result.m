function [] = cafa_driver_result(eval_dir, cfg, naive, blast)
%CAFA_DRIVER_RESULT CAFA driver result
% {{{
%
% [] = CAFA_DRIVER_RESULT(eval_dir, cfg, naive, blast);
%
%   Generates results for evaluation (plots, and sheets).
%
% Given [ontology] [benchmark category] [benchmark type] [evaluation mode],
% what does this function generate?
% 1. top10 (weighted) Fmax and (normalized) Smin curves
% 2. top10 (weighted) Fmax and (normalized) Smin bars (bootstrapped)
% 3. histogram of averaged AUC per term.
% 4. top10(bottom10) best(worst) predicted terms boxplots
% 5. all methods (weighted) Fmax report csv
% 6. all methods (normalized) Smin report csv
% 7. all methods AUC per term csv
%
% Input
% -----
% [char]
% eval_dir: the directory that contains evaluation results.
%
% [char]
% cfg:      the team information.
%
% [char]
% naive:    the internalID of naive baseline. E.g. BN1S
%
% [char]
% blast:    the internalID of blast baseline. E.g. BB1S
%
% Output
% ------
% None.
%
% Dependency
% ----------
%[>]cafa_parse_config.m
%[>]cafa_collect.m
%[>]cafa_sel_top10_seq_prcurve.m
%[>]cafa_sel_top10_seq_rmcurve.m
%[>]cafa_sel_top10_seq_fmax.m
%[>]cafa_sel_top10_seq_smin.m
%[>]cafa_plot_seq_prcurve.m
%[>]cafa_plot_seq_rmcurve.m
%[>]cafa_barplot_seq_fmax.m
%[>]cafa_barplot_seq_smin.m
%[>]cafa_sheet_seq_fmax.m
%[>]cafa_sheet_seq_smin.m
%[>]cafa_sel_valid_term_auc.m
%[>]cafa_get_term_auc.m
%[>]cafa_read_team_info.m
% }}}

  % set-up {{{
  eval_dir = regexprep(strcat(eval_dir, '/'), '//', '/');
  config_file = strcat(eval_dir, 'eval_config.job');
  config = cafa_parse_config(config_file);
  saveto_prefix = strcat(regexprep(config.eval_dir, '.*/(.*)/$', '$1'), '_');

  plot_ext  = '.png';
  sheet_ext = '.csv';

  % Y-axis {{{
  % fixed y-axis (in Fmax barplots), for the manuscript.
  % yaxis_fmax = [0.0, 0.8, 0.1]; % start, stop, step, for Fmax barplots

  % adaptive y-axis, for the supplementary.
  yaxis_fmax = [];

  % fixed y-axis (in AUC bar/box plots)
  yaxis_auc = [0.2, 1.0, 0.1];

  % adaptive y-axis
  % yaxis_auc = [];
  % }}}

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
  saveto = strcat(config.eval_dir, saveto_prefix, 'top10_fmax_curve', plot_ext);
  prcurves = cafa_collect(config.eval_dir, 'seq_prcurve');
  [top10, baseline] = cafa_sel_top10_seq_prcurve(prcurves, naive, blast, cfg);
  cafa_plot_seq_prcurve(saveto, ont_str, top10, baseline);

  % mark alternative points {{{
  % rmcurves = cafa_collect(config.eval_dir, 'seq_rmcurve');
  % [top10, baseline] = cafa_sel_top10_seq_prcurve(prcurves, naive, blast, cfg, rmcurves);
  % cafa_plot_seq_prcurve(saveto, ont_str, top10, baseline, true);
  % }}}
  % }}}

  % all Fmax sheet {{{
  saveto_A = strcat(config.eval_dir, saveto_prefix, 'all_fmax_sheet', sheet_ext);
  saveto_N = strcat(config.eval_dir, saveto_prefix, 'all_fmax_sheet_disclosed', sheet_ext);
  fmaxs = cafa_collect(config.eval_dir, 'seq_fmax');
  fmaxs_bst = cafa_collect(config.eval_dir, 'seq_fmax_bst');
  cafa_sheet_seq_fmax(saveto_A, fmaxs, fmaxs_bst, cfg, true);
  cafa_sheet_seq_fmax(saveto_N, fmaxs, fmaxs_bst, cfg, false);
  % }}}

  % top10 weighted precision-recall curve {{{
  saveto = strcat(config.eval_dir, saveto_prefix, 'top10_wfmax_curve', plot_ext);
  prcurves = cafa_collect(config.eval_dir, 'seq_wprcurve');
  [top10, baseline] = cafa_sel_top10_seq_prcurve(prcurves, naive, blast, cfg);
  cafa_plot_seq_prcurve(saveto, ont_str, top10, baseline);
  % }}}

  % all weighted Fmax sheet {{{
  saveto_A = strcat(config.eval_dir, saveto_prefix, 'all_wfmax_sheet', sheet_ext);
  saveto_N = strcat(config.eval_dir, saveto_prefix, 'all_wfmax_sheet_disclosed', sheet_ext);
  fmaxs = cafa_collect(config.eval_dir, 'seq_wfmax');
  fmaxs_bst = cafa_collect(config.eval_dir, 'seq_wfmax_bst');
  cafa_sheet_seq_fmax(saveto_A, fmaxs, fmaxs_bst, cfg, true);
  cafa_sheet_seq_fmax(saveto_N, fmaxs, fmaxs_bst, cfg, false);
  % }}}

  % top10 RU-MI curve {{{
  saveto = strcat(config.eval_dir, saveto_prefix, 'top10_smin_curve', plot_ext);
  rmcurves = cafa_collect(config.eval_dir, 'seq_rmcurve');
  [top10, baseline] = cafa_sel_top10_seq_rmcurve(rmcurves, naive, blast, cfg);
  cafa_plot_seq_rmcurve(saveto, ont_str, top10, baseline);
  % }}}

  % all Smin sheet {{{
  saveto_A = strcat(config.eval_dir, saveto_prefix, 'all_smin_sheet', sheet_ext);
  saveto_N = strcat(config.eval_dir, saveto_prefix, 'all_smin_sheet_disclosed', sheet_ext);
  smins = cafa_collect(config.eval_dir, 'seq_smin');
  smins_bst = cafa_collect(config.eval_dir, 'seq_smin_bst');
  cafa_sheet_seq_smin(saveto_A, smins, smins_bst, cfg, true);
  cafa_sheet_seq_smin(saveto_N, smins, smins_bst, cfg, false);
  % }}}

  % top10 normalized RU-MI curve {{{
  saveto = strcat(config.eval_dir, saveto_prefix, 'top10_nsmin_curve', plot_ext);
  rmcurves = cafa_collect(config.eval_dir, 'seq_nrmcurve');
  [top10, baseline] = cafa_sel_top10_seq_rmcurve(rmcurves, naive, blast, cfg);
  cafa_plot_seq_rmcurve(saveto, ont_str, top10, baseline);
  % }}}

  % all normalized Smin sheet {{{
  saveto_A = strcat(config.eval_dir, saveto_prefix, 'all_nsmin_sheet', sheet_ext);
  saveto_N = strcat(config.eval_dir, saveto_prefix, 'all_nsmin_sheet_disclosed', sheet_ext);
  smins = cafa_collect(config.eval_dir, 'seq_nsmin');
  smins_bst = cafa_collect(config.eval_dir, 'seq_nsmin_bst');
  cafa_sheet_seq_smin(saveto_A, smins, smins_bst, cfg, true);
  cafa_sheet_seq_smin(saveto_N, smins, smins_bst, cfg, false);
  % }}}

  % top10 Fmax bar {{{
  saveto = strcat(config.eval_dir, saveto_prefix, 'top10_fmax_bar', plot_ext);
  saveto_team = strcat(config.eval_dir, saveto_prefix, 'team.txt');
  fmaxs = cafa_collect(config.eval_dir, 'seq_fmax_bst');
  [top10, baseline, info] = cafa_sel_top10_seq_fmax(fmaxs, naive, blast, cfg);
  cafa_barplot_seq_fmax(saveto, ont_str, top10, baseline, yaxis_fmax);
  save_team_info(saveto_team, info, cfg);
  % cafa_barplot_seq_fmax(saveto, strcat(ont_str, ' F0.5'), top10, baseline, yaxis_fmax);
  % }}}

  % top10 weighted Fmax bar {{{
  saveto = strcat(config.eval_dir, saveto_prefix, 'top10_wfmax_bar', plot_ext);
  saveto_team = strcat(config.eval_dir, saveto_prefix, 'team.txt');
  fmaxs = cafa_collect(config.eval_dir, 'seq_wfmax_bst');
  [top10, baseline, info] = cafa_sel_top10_seq_fmax(fmaxs, naive, blast, cfg);
  cafa_barplot_seq_fmax(saveto, ont_str, top10, baseline, yaxis_fmax);
  save_team_info(saveto_team, info, cfg);
  % }}}

  % top10 Smin bar {{{
  saveto = strcat(config.eval_dir, saveto_prefix, 'top10_smin_bar', plot_ext);
  saveto_team = strcat(config.eval_dir, saveto_prefix, 'team.txt');
  smins = cafa_collect(config.eval_dir, 'seq_smin_bst');
  [top10, baseline, info] = cafa_sel_top10_seq_smin(smins, naive, blast, cfg);
  cafa_barplot_seq_smin(saveto, ont_str, top10, baseline);
  save_team_info(saveto_team, info, cfg);
  % }}}

  % top10 normalized Smin bar {{{
  saveto = strcat(config.eval_dir, saveto_prefix, 'top10_nsmin_bar', plot_ext);
  saveto_team = strcat(config.eval_dir, saveto_prefix, 'team.txt');
  smins = cafa_collect(config.eval_dir, 'seq_nsmin_bst');
  [top10, baseline, info] = cafa_sel_top10_seq_smin(smins, naive, blast, cfg);
  cafa_barplot_seq_smin(saveto, ont_str, top10, baseline);
  save_team_info(saveto_team, info, cfg);
  % }}}

  % all averaged AUC per term {{{
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
  % }}}

  % top5 averaged AUC per term {{{
  saveto = strcat(config.eval_dir, saveto_prefix, 'top5avg_auc_bar', plot_ext);
  fmaxs  = cafa_collect(config.eval_dir, 'seq_fmax_bst');
  [~, ~, info] = cafa_sel_top10_seq_fmax(fmaxs, naive, blast, cfg, 5);
  aucs   = cafa_collect(config.eval_dir, 'term_auc');

  % load term acc <--> term name table
  fid = fopen(config.ont_term, 'r');
  terms = textscan(fid, '%s%s', 'Delimiter', '\t');
  fclose(fid);

  % select top 5 methods
  aucs = cafa_get_term_auc(aucs, info.top10_mid);

  % note that filtered aucs could be empty, for all terms are fully annotated
  % like root, which results in NaN AUC.
  aucs = cafa_sel_valid_term_auc(aucs); % keep only participating models
  if ~isempty(aucs)
    % [~, index] = ismember(aucs{1}.term, terms{1});
    cafa_plot_term_avgauc(saveto, ont_str, aucs, config.oa.ontology, yaxis_auc);
  else
    warning('No model is selected.');
  end
  % }}}

  % all AUC per term sheet {{{
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
  % }}}
return

% function: save_team_info {{{
function [] = save_team_info(saveto, info, cfg)
  [iid, eid, tname, ~, dname, pi] = cafa_read_team_info(cfg);
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
  for i = 1 : numel(info.top10_mid)
    [~, j] = ismember(info.top10_mid{i}, iid);
    fprintf(fid, '%s,%s,%s,%s,%s\n', iid{j}, eid{j}, tname{j}, dname{j}, pi{j});
  end
  fclose(fid);
return
% }}}

% -------------
% Yuxiang Jiang (yuxjiang@indiana.edu)
% Department of Computer Science
% Indiana University, Bloomington
% Last modified: Sun 19 Jul 2015 03:27:19 PM E
