function [] = cafa_driver_preeval(cafa_dir, do_filter, do_import, is_duel)
%CAFA_DRIVER_PREEVAL CAFA driver pre-evaluation (sequence-centric)
% {{{ 
%
% [] = CAFA_DRIVER_PREEVAL(cafa_dir, do_filter, do_import);
% [] = CAFA_DRIVER_PREEVAL(cafa_dir, do_filter, do_import, is_duel);
%
%   Generates pre-evaluated sequence-centric metrics for each model.
%
%   Pre-evaluated metrics are pre-computed ans stored for speeding up downstream
%   evaluations.
%
% Note
% ----
% All CAFA2 related meterials are assumed to be put in a single folder and
% organized as follows:
%
% CAFA2 (which needs to be given as input)
% |--   config/             (configuration files, not needed here)
% |-- ! consolidated/       (consolidated plain-text prediction files. We assume
% |                         predicted scores from all models have been
% |                         cosolidated and stored in this folder with their
% |                         internal model ID as filenames, w/o file extension.
% |                         Also, this script assumes internal ID starts with
% |                         'M' and followed by 3 decimal digits.
% |                         "Consolidation" is done using preprocessing scripts
% |                         with necessary manual interferences.)
% |-- * seq-centric/        (pre-evaluation results will appear here)
% |     |-- * mfo/
% |     |-- * bpo/
% |     |-- * cco/
% |     `-- * hpo/
% |-- + prediction/         (imported predictions in Matlab structures)
% |     |-- * mfo/
% |     |-- * bpo/
% |     |-- * cco/
% |     `-- * hpo/
% |-- + filtered/           (filtered plain-text prediction file)
% |-- ! benchmark/
% |     |-- ! lists/        (lists of benchmarks)
% |     |   |-- all.txt             The union list of all benchmarks
% |     |   |-- mfo_all_typex.txt   ..................... mfo benchmarks
% |     |   |-- bpo_all_typex.txt   ..................... bpo benchmarks
% |     |   |-- cco_all_typex.txt   ..................... cco benchmarks
% |     |   `-- hpo_HUMAN_typex.txt ..................... hpo benchmarks
% |     `-- ! groundtruth/  (pre-computed annotations, see pfp_oabuild.m)
% |           |-- mfoa.mat (containing 'oa' struct. See pfp_oabuild.m)
% |           |-- bpoa.mat 
% |           |-- ccoa.mat 
% |           `-- hpoa.mat 
% |--   evaluation/         (evaluation results, not touched here)
% `-- ! ontology/           (pre-computed ontologies, see pfp_ontbuild.m.
%                            However, the original ontology structures here 
%                            will not be used directly by this function. They
%                            are used to construct groundtruth annotations,
%                            while the one embeded in those 'oa' are in turn
%                            used here to enforce consistency between imported
%                            prediction and annotation structures.)
%
% folders marked with * will be updated.
% ................... + might be updated according to the input toggles.
% ................... ! need to be prepared as prerequisites.
%
% folder dependency:
% seq-centric/ -> prediction/ -> filtered/ -> consolidated/
%
% Input
% -----
% (required)
% [char]
% cafa_dir:   The CAFA2 folder.
%
% [logical]
% do_filter:  Does text prediction filtering according to benchmarks.
%           * Note: this step is slow but only needs to do once.
%
% [logical]
% do_import:  Does import text predictions and save as 'pred' prediction structures.
%           * Note: this step is slow but only needs to do once.
%
% (optional)
% [logical]
% is_duel:    Does pre-evaluation on duel setting?
%             default: false.
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

  % check inputs {{{
  if nargin ~= 3 && nargin ~= 4
    error('cafa_driver_preeval:InputCount', 'Expected 3 or 4 inputs.');
  end

  if nargin == 3
    is_duel = false;
  end

  % check the 1st input {{{
  validateattributes(cafa_dir, {'char'}, {'nonemtpy'}, '', 'cafa_dir', 1);
  if ~exist(cafa_dir, 'dir')
    error('cafa_driver_preeval:InputErr', 'CAFA dir is not found.');
  end
  % }}}
  % }}}

  % set up paths and variables {{{
  config.cons_dir = fullfile(cafa_dir, 'consolidated'); % (input) where are the raw plain-text predictions
  config.prev_dir = fullfile(cafa_dir, 'seq-centric');  % where the sequence-centric pre-evaluation results go
  config.pred_dir = fullfile(cafa_dir, 'prediction');   % where the prediction structures go
  config.filt_dir = fullfile(cafa_dir, 'filtered');     % where the filtered plain-text predictions go
  config.bm_all   = pfp_loaditem(fullfile(cafa_dir, 'benchmark', 'lists', 'all.txt'), 'char');
  config.bm_mfo   = pfp_loaditem(fullfile(cafa_dir, 'benchmark', 'lists', 'mfo_all_typex.txt'), 'char');
  config.bm_bpo   = pfp_loaditem(fullfile(cafa_dir, 'benchmark', 'lists', 'bpo_all_typex.txt'), 'char');
  config.mfoa     = load(fullfile(cafa_dir, 'benchmark', 'groundtruth', 'mfoa.mat'), 'oa');
  config.bpoa     = load(fullfile(cafa_dir, 'benchmark', 'groundtruth', 'bpoa.mat'), 'oa');
  if is_duel
    config.ont = {'mfo', 'bpo'};
  else
    config.bm_cco = pfp_loaditem(fullfile(cafa_dir, 'benchmark', 'lists', 'cco_all_typex.txt'), 'char');
    config.bm_hpo = pfp_loaditem(fullfile(cafa_dir, 'benchmark', 'lists', 'hpo_HUMAN_type1.txt'), 'char');
    config.ccoa   = load(fullfile(cafa_dir, 'benchmark', 'groundtruth', 'ccoa.mat'), 'oa');
    config.hpoa   = load(fullfile(cafa_dir, 'benchmark', 'groundtruth', 'hpoa.mat'), 'oa');
    config.ont    = {'mfo', 'bpo', 'cco', 'hpo'};
  end
  % }}}

  % filter regular models and save to config.filt_dir {{{
  if do_filter
    files = dir(fullfile(config.cons_dir, 'M*'));
    for i = 1 : numel(files)
      mid = regexprep(files(i).name, '\..*$', '');
      fprintf('filtering model [%s]\n', mid);
      ifile = fullfile(config.cons_dir, mid);
      ofile = fullfile(config.filt_dir, mid);
      cafa_filter(config.bm_all, ifile, ofile);
    end
  end
  % }}}

  % import filtered models and save to config.pred_dir {{{
  if do_import
    files = dir(fullfile(config.filt_dir, 'M*'));

    % make sure subfolders exist
    for i = 1 : numel(config.ont)
      if ~exist(fullfile(config.pred_dir, config.ont{i}), 'dir')
        mkdir(fullfile(config.pred_dir, config.ont{i}));
      end
    end

    for i = 1 : numel(files)
      mid = regexprep(files(i).name, '\..*$', '');
      fprintf('importing model [%s]\n', mid);
      ifile = fullfile(config.filt_dir, mid);

      % for each ontology, no header/footer information
      if ismember('mfo', config.ont)
        pred = cafa_import(ifile, config.mfoa.oa.ontology, false);
        pfp_savevar(fullfile(config.pred_dir, 'mfo', mid), pred, 'pred');
      end

      if ismember('bpo', config.ont)
        pred = cafa_import(ifile, config.bpoa.oa.ontology, false);
        pfp_savevar(fullfile(config.pred_dir, 'bpo', mid), pred, 'pred');
      end

      if ismember('cco', config.ont)
        pred = cafa_import(ifile, config.ccoa.oa.ontology, false);
        pfp_savevar(fullfile(config.pred_dir, 'cco', mid), pred, 'pred');
      end

      if ismember('hpo', config.ont)
        pred = cafa_import(ifile, config.hpoa.oa.ontology, false);
        pfp_savevar(fullfile(config.pred_dir, 'hpo', mid), pred, 'pred');
      end
    end
  end
  % }}}

  % pre-evaluation {{{
  % we assume baseline models has been imported and saved to the prediction
  % subfolders for each ontology.
  for i = 1 : numel(config.ont)
    ont = config.ont{i};
    pred_dir_ont = fullfile(config.pred_dir, ont);
    prev_dir_ont = fullfile(config.prev_dir, ont);

    % make sure subfolders exist
    if ~exist(prev_dir_ont, 'dir')
      mkdir(prev_dir_ont);
    end

    files = dir(fullfile(pred_dir_ont, '*.mat'));
    for i = 1 : numel(files)
      mid = regexprep(files(i).name, '\..*$', '');
      fprintf('pre-evaluating model [%s] on [%s]\n', mid, ont);
      % load prediction structure
      load(fullfile(pred_dir_ont, files(i).name), 'pred');

      % setup
      bmfield = sprintf('bm_%s', ont);
      oafield = sprintf('%sa', ont);

      config.pred  = pred;
      config.bm    = config.(bmfield);
      config.oa    = config.(oafield).oa;
      config.ofile = fullfile(prev_dir_ont, files(i).name);

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
% Last modified: Wed 17 Feb 2016 05:37:28 PM E
