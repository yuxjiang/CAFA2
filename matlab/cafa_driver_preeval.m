function [] = cafa_driver_preeval(config_info)
%CAFA_DRIVER_PREEVAL CAFA driver pre-evaluation (sequence-centric)
% {{{
%
% [] = CAFA_DRIVER_PREEVAL(config_info);
%
%   Generates pre-evaluated sequence-centric metrics for each model.
%
%   Pre-evaluated metrics are pre-computed ans stored for speeding up downstream
%   evaluations.
%
% Note
% ----
% All CAFA2 related meterials are suggested to be put in a single folder and
% organized as follows:
%
% CAFA2 (which needs to be given as input)
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
% |--   bootstrap/          (bootstrap indicies, for reproducibility)
% |--   consolidated/       (consolidated plain-text prediction files. We assume
% |                          predicted scores from all models have been
% |                          cosolidated and stored in this folder with their
% |                          internal model ID as filenames, w/o file extension.
% |                          Also, this script assumes internal ID starts with
% |                          'M' and followed by 3 decimal digits.
% |                          "Consolidation" is done using preprocessing scripts
% |                          with necessary manual interferences.)
% |--   evaluation/         (evaluation results, not touched here)
% |--   filtered/           (filtered plain-text prediction file)
% |-- ! ontology/           (pre-computed ontologies, see pfp_ontbuild.m.
% |                          However, the original ontology structures here
% |                          are not given directly in the configuration file,
% |                          they are instead given as the ‘ontology' field of
% |                          the groundtruth ontology annotation.)
% |-- ! prediction/         (imported predictions in Matlab structures)
% |     |-- * mfo/
% |     |-- * bpo/
% |     |-- * cco/
% |     `-- * hpo/
% |-- * seq-centric/        (pre-evaluation results will appear here)
% |     |-- * mfo/
% |     |-- * bpo/
% |     |-- * cco/
% |     `-- * hpo/
% `--   register/           (register files, not needed here)
%
% folders marked with * will be updated.
% ................... ! need to be prepared as prerequisites.
%
% folder dependency:
% seq-centric/ -> prediction/ -> filtered/ -> consolidated/
%
% Input
% -----
% [char or struct]
% config_info:  The configuration file (job descriptor) or a parsed config
%               structure.
%
%               See cafa_parse_config.m
%
% Dependency
% ----------
%[>]cafa_parse_config.m
%[>]pfp_loaditem.m
%[>]pfp_seqcm.m
%[>]pfp_convcmstruct.m
%[>]pfp_savevar.m
%
% See Also
% --------
%[>]pfp_ontbuild.m
%[>]pfp_oabuild.m
%[>]cafa_driver_filter.m
%[>]cafa_driver_import.m
% }}}

  % check inputs {{{
  if nargin ~= 1
    error('cafa_driver_preeval:InputCount', 'Expected 1 input.');
  end

  % check the 1st input 'config_info' {{{
  validateattributes(config_info, {'char', 'struct'}, {'nonempty'}, '', 'config_info', 1);

  if ischar(config_info)
    config = cafa_parse_config(config_info);
    % make sure subfolders exist
    if ~exist(config.prev_dir, 'dir')
      mkdir(config.prev_dir);
    end
    % save the configuration file for future reference
    copyfile(config_info, fullfile(config.prev_dir, 'prev_config.job'));
  elseif isstruct(config_info)
    config = config_info;
  else
    error('cafa_driver_preeval:InputErr', 'Unknown data type of ''config_info''');
  end
  % }}}
  % }}}

  % pre-evaluation {{{
  % we assume baseline models has been imported and saved to the prediction
  % subfolders for each ontology.
  for i = 1 : numel(config.model)
    mid = config.model{i};
    fprintf('pre-evaluating model [%s] on [%s]\n', mid, config.ont);
    % load prediction structure
    load(fullfile(config.pred_dir, strcat(mid, '.mat')), 'pred');
    ofile = fullfile(config.prev_dir, strcat(mid, '.mat'));

    % pre-evaluation a single model {{{
    if config.do_seq_fmax
      cm_seq = pfp_seqcm(config.bm, pred, config.oa, 'toi', 'noroot');
      pr = pfp_convcmstruct(cm_seq, 'pr', 'beta', config.beta);
      pfp_savevar(ofile, pr, 'pr');
    end

    if config.do_seq_wfmax || config.do_seq_smin || config.do_seq_nsmin
      cm_seq_ia = pfp_seqcm(config.bm, pred, config.oa, 'toi', 'noroot', 'w', 'eia');

      if config.do_seq_wfmax
        wpr = pfp_convcmstruct(cm_seq_ia, 'wpr', 'beta', config.beta);
        pfp_savevar(ofile, wpr, 'wpr');
      end

      if config.do_seq_smin
        rm = pfp_convcmstruct(cm_seq_ia, 'rm', 'order', config.order);
        pfp_savevar(ofile, rm, 'rm');
      end

      if config.do_seq_nsmin
        nrm = pfp_convcmstruct(cm_seq_ia, 'nrm', 'order', config.order);
        pfp_savevar(ofile, nrm, 'nrm');
      end
    end
    % }}}
  end
  % }}}
return

% -------------
% Yuxiang Jiang (yuxjiang@indiana.edu)
% Department of Computer Science
% Indiana University Bloomington
% Last modified: Thu 17 Mar 2016 01:40:38 PM E
