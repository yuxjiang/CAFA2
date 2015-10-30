function [] = cafa_driver_preeval()
%CAFA_DRIVER_PREEVAL CAFA driver pre-evaluation (sequence-centric)
% {{{ 
%
% [] = CAFA_DRIVER_PREEVAL();
%
%   Generates pre-evaluated sequence-centric metrics for each model.
%
% Note
% ----
% Update the corresponding paths below as needed.
%
% Suggestion
% ----------
% It will be more organsized to keep everything under a single folder,
% therefore, an example CAFA2 project folder looks like the following:
%
% CAFA2 (replacing "cv3" below)
% |--   config/           (configuration files)
% |--   consolidated/     (consolidated plain-text prediction files)
% |-- * seq-centric/      (pre-evaluation results will appear here)
% |-- * prediction/       (imported predictions in Matlab structures)
% |     |-- * mfo/
% |     |-- * bpo/
% |     |-- * cco/
% |     `-- * hpo/
% |-- * filtered/         (filtered plain-text prediction file)
% |--   benchmark/
% |     |-- lists/        (lists of benchmarks)
% |     `-- groundtruth/  (pre-computed annotations, see pfp_oabuild.m)
% |--   evaluation/       (evaluation results will appear here)
% `--   ontology/         (pre-computed ontologies, see pfp_ontbuild.m)
%
% folders with * will be modified by this script.
%   
% Dependency
% ----------
%[>]cafa_filter.m
%[>]cafa_import.m
%[>]pfp_loaditem.m
%[>]pfp_seqcm.m
%[>]pfp_convcmstruct.m
%[>]pfp_savevar.m
%
% See Also
% --------
%[>]pfp_ontbuild.m
%[>]pfp_oabuild.m
% }}}

  % set up paths and variables {{{
  % Note: each folder must end with '/'

  % % cafa 1 ----
  % config.cons_dir = '~/cv3/duel/cafa1/consolidated/';
  % config.prev_dir = '~/cv3/duel/cafa1/seq-centric/';
  % config.pred_dir = '~/cv3/duel/cafa1/prediction/';
  % config.filt_dir = '~/cv3/duel/cafa1/filtered/';
  % config.bm_all   = pfp_loaditem('~/cv3/duel/cafa1/benchmark/all_duel_cafa1.txt', 'char');
  % config.bm_mfo   = pfp_loaditem('~/cv3/duel/cafa1/benchmark/mfo_duel_type1.txt', 'char');
  % config.bm_cco   = pfp_loaditem('~/cv3/duel/cafa1/benchmark/cco_duel_type1.txt', 'char');
  % config.bm_bpo   = pfp_loaditem('~/cv3/duel/cafa1/benchmark/bpo_duel_type1.txt', 'char');
  % config.mfoa     = load('~/cv3/duel/cafa1/benchmark/groundtruth/mfoa.mat', 'oa');
  % config.bpoa     = load('~/cv3/duel/cafa1/benchmark/groundtruth/bpoa.mat', 'oa');
  % config.ccoa     = load('~/cv3/duel/cafa1/benchmark/groundtruth/ccoa.mat', 'oa');
  % config.ont      = {'mfo', 'bpo'};

  % cafa 2 ----
  config.cons_dir = '~/cv3/consolidated/'; % (input) where are the raw plain-text predictions
  config.prev_dir = '~/cv3/seq-centric_test/';  % where the sequence-centric pre-evaluation results go
  config.pred_dir = '~/cv3/prediction/';   % where the prediction structures go
  config.filt_dir = '~/cv3/filtered/';     % where the filtered plain-text predictions go
  config.bm_all   = pfp_loaditem('~/cv3/benchmark/lists/all.txt', 'char');
  config.bm_mfo   = pfp_loaditem('~/cv3/benchmark/lists/mfo_all_typex.txt', 'char');
  config.bm_cco   = pfp_loaditem('~/cv3/benchmark/lists/cco_all_typex.txt', 'char');
  config.bm_bpo   = pfp_loaditem('~/cv3/benchmark/lists/bpo_all_typex.txt', 'char');
  config.bm_hpo   = pfp_loaditem('~/cv3/benchmark/lists/hpo_HUMAN_type1.txt', 'char');
  config.mfoa     = load('~/cv3/benchmark/groundtruth/mfoa.mat', 'oa');
  config.bpoa     = load('~/cv3/benchmark/groundtruth/bpoa.mat', 'oa');
  config.ccoa     = load('~/cv3/benchmark/groundtruth/ccoa.mat', 'oa');
  config.hpoa     = load('~/cv3/benchmark/groundtruth/hpoa.mat', 'oa');
  config.ont      = {'mfo', 'bpo', 'cco', 'hpo'};
  % }}}

  % set up toggles {{{
  config.do_filter = false; % to keep only benchmark sequences
  config.do_import = false; % make 'pred' from text files for each ontology.
  % }}}

  % filter regular models {{{
  if config.do_filter
    files = dir(strcat(config.cons_dir, 'M*'));
    for i = 1 : numel(files)
      mid = regexprep(files(i).name, '\..*$', '');
      fprintf('filtering model [%s]\n', mid);
      ifile = strcat(config.cons_dir, mid);
      ofile = strcat(config.filt_dir, mid);
      cafa_filter(config.bm_all, ifile, ofile);
    end
  end
  % }}}

  % import filtered models and save to config.pred_dir {{{
  if config.do_import
    files = dir(strcat(config.filt_dir, 'M*'));

    % make sure subfolders exist
    for i = 1 : numel(config.ont)
      if ~exist(strcat(config.pred_dir, config.ont{i}), 'dir')
        mkdir(strcat(config.pred_dir, config.ont{i}));
      end
    end

    for i = 1 : numel(files)
      mid = regexprep(files(i).name, '\..*$', '');
      fprintf('importing model [%s]\n', mid);
      ifile = strcat(config.filt_dir, mid);

      % for each ontology, no header/footer information
      if ismember('mfo', config.ont)
        pred = cafa_import(ifile, config.mfoa.oa.ontology, false);
        pfp_savevar(strcat(config.pred_dir, 'mfo/', mid), pred, 'pred');
      end

      if ismember('bpo', config.ont)
        pred = cafa_import(ifile, config.bpoa.oa.ontology, false);
        pfp_savevar(strcat(config.pred_dir, 'bpo/', mid), pred, 'pred');
      end

      if ismember('cco', config.ont)
        pred = cafa_import(ifile, config.ccoa.oa.ontology, false);
        pfp_savevar(strcat(config.pred_dir, 'cco/', mid), pred, 'pred');
      end

      if ismember('hpo', config.ont)
        pred = cafa_import(ifile, config.hpoa.oa.ontology, false);
        pfp_savevar(strcat(config.pred_dir, 'hpo/', mid), pred, 'pred');
      end
    end
  end
  % }}}

  % pre-evaluation {{{
  % we assume baseline models has been imported and saved to the prediction
  % subfolders for each ontology.
  for i = 1 : numel(config.ont)
    ont = config.ont{i};
    pred_dir_ont = strcat(config.pred_dir, ont, '/');
    prev_dir_ont = strcat(config.prev_dir, ont, '/');

    % make sure subfolders exist
    if ~exist(prev_dir_ont, 'dir')
      mkdir(prev_dir_ont);
    end

    files = dir(strcat(pred_dir_ont, '*.mat'));
    for i = 1 : numel(files)
      mid = regexprep(files(i).name, '\..*$', '');
      fprintf('pre-evaluating model [%s] on [%s]\n', mid, ont);
      % load prediction structure
      load(strcat(pred_dir_ont, files(i).name), 'pred');

      % setup
      bmfield = sprintf('bm_%s', ont);
      oafield = sprintf('%sa', ont);

      config.pred  = pred;
      config.bm    = config.(bmfield);
      config.oa    = config.(oafield).oa;
      config.ofile = strcat(prev_dir_ont, files(i).name);

      preeval_single(config);
    end
  end
  % }}}
return

% function: preeval_single {{{
function [] = preeval_single(config)
  % compute confusion matrices {{{
  cm_seq = pfp_seqcm(config.bm, config.pred, config.oa, 'toi', 'noroot');
  cm_seq_ia = pfp_seqcm(config.bm, config.pred, config.oa, 'toi', 'noroot', 'w', 'eia');
  % }}}

  % compute and save metrics of interest {{{
  pr = pfp_convcmstruct(cm_seq, 'pr', 'beta', 1);
  pfp_savevar(config.ofile, pr, 'pr');

  wpr = pfp_convcmstruct(cm_seq_ia, 'wpr', 'beta', 1);
  pfp_savevar(config.ofile, wpr, 'wpr');

  rm = pfp_convcmstruct(cm_seq_ia, 'rm', 'order', 2);
  pfp_savevar(config.ofile, rm, 'rm');

  nrm = pfp_convcmstruct(cm_seq_ia, 'nrm', 'order', 2);
  pfp_savevar(config.ofile, nrm, 'nrm');
  % }}}
return
%}}}

% -------------
% Yuxiang Jiang (yuxjiang@indiana.edu)
% Department of Computer Science
% Indiana University Bloomington
% Last modified: Thu 29 Oct 2015 09:24:17 PM E
