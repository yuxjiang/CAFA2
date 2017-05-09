function [] = cafa_setup(idir, odir)
    %CAFA_SETUP
    %
    %   [] = CAFA_SETUP(idir, odir);
    %
    %       This script sets up a basic CAFA2 evaluation runtime folder
    %       structure.
    %
    % Input
    % -----
    % [char]
    % idir: The folder where CAFA2 github repo is.
    %
    % [char]
    % odir: The output directory that has write permission. It's suggested to
    %       use an empty folder.
    %
    % Output
    % ------
    % None.

    % check inputs {{{
    if nargin ~= 2
        error('cafa_setup:InputCount', 'Expected 2 inputs.');
    end

    % idir
    validateattributes(idir, {'char'}, {'nonempty'}, '', 'idir', 1);

    % odir
    validateattributes(odir, {'char'}, {'nonempty'}, '', 'odir', 2);
    % }}}

    if ~exist(odir, 'dir');
        mkdir(odir);
    end

    mkdir(fullfile(odir, 'bootstrap'));
    mkdir(fullfile(odir, 'consolidated'));
    mkdir(fullfile(odir, 'evaluation'));
    mkdir(fullfile(odir, 'filtered'));
    mkdir(fullfile(odir, 'prediction'));
    mkdir(fullfile(odir, 'prediction/mfo'));
    mkdir(fullfile(odir, 'prediction/bpo'));
    mkdir(fullfile(odir, 'prediction/cco'));
    mkdir(fullfile(odir, 'prediction/hpo'));
    mkdir(fullfile(odir, 'seq-centric'));
    mkdir(fullfile(odir, 'seq-centric/mfo'));
    mkdir(fullfile(odir, 'seq-centric/bpo'));
    mkdir(fullfile(odir, 'seq-centric/cco'));
    mkdir(fullfile(odir, 'seq-centric/hpo'));

    % create symbolic links to pre-structured baseline methods
    system(sprintf('ln -sf %s %s', ...
        fullfile(idir, 'baselines/mfo/BB4S.mat'), ...
        fullfile(odir, 'prediction/mfo/BB4S.mat')));
    system(sprintf('ln -sf %s %s', ...
        fullfile(idir, 'baselines/bpo/BB4S.mat'), ...
        fullfile(odir, 'prediction/bpo/BB4S.mat')));
    system(sprintf('ln -sf %s %s', ...
        fullfile(idir, 'baselines/cco/BB4S.mat'), ...
        fullfile(odir, 'prediction/cco/BB4S.mat')));
    system(sprintf('ln -sf %s %s', ...
        fullfile(idir, 'baselines/hpo/BB4H.mat'), ...
        fullfile(odir, 'prediction/hpo/BB4H.mat')));

    system(sprintf('ln -sf %s %s', ...
        fullfile(idir, 'baselines/mfo/BN4S.mat'), ...
        fullfile(odir, 'prediction/mfo/BN4S.mat')));
    system(sprintf('ln -sf %s %s', ...
        fullfile(idir, 'baselines/bpo/BN4S.mat'), ...
        fullfile(odir, 'prediction/bpo/BN4S.mat')));
    system(sprintf('ln -sf %s %s', ...
        fullfile(idir, 'baselines/cco/BN4S.mat'), ...
        fullfile(odir, 'prediction/cco/BN4S.mat')));
    system(sprintf('ln -sf %s %s', ...
        fullfile(idir, 'baselines/hpo/BN4H.mat'), ...
        fullfile(odir, 'prediction/hpo/BN4H.mat')));
end

% -------------
% Yuxiang Jiang (yuxjiang@indiana.edu)
% Department of Computer Science
% Indiana University, Bloomington
% Last modified: Mon 08 May 2017 05:55:35 PM E
