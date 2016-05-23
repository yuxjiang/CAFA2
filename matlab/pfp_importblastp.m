function [blast] = pfp_importblastp(ifile, ksh)
%PFP_IMPORTBLASTP Read BLAST
%
% [blast] = PFP_IMPORTBLASTP(ifile);
% [blast] = PFP_IMPORTBLASTP(ifile, ksh);
%
%   Reads "blastp" result in tab-splited format which was reported using the
%   following format: (version: v2.2.28+)
%
%   -outfmt "6 qseqid sseqid evalue length pident nident"
%
% Note
% ----
% 1. By default, self-matched hits will be removed.
% 2. If 'ksh' is set to false, sequences that have only self-hits are removed.
%
% Input
% -----
% (required)
% [char]
% ifile:  BLAST result filename.
%
% (optional)
% [logical]
% ksh:    A toggle indicates to "keep-self-hits".
%         default: false.
%
% Output
% ------
% [struct]
% blast:  The resulting structure, containing the blast results of n
%         sequences.
%
%         .qseqid   [cell]    An n-by-1 cell array of query IDs.
%         .info     [cell]    The information of hits, with fields:
%           .sseqid [cell]    A k-by-1 array of subject ID list (hits).
%           .evalue [double]  A k-by-1 array of E-value.
%           .length [double]  A k-by-1 array of matched length.
%           .pident [double]  A k-by-1 array of percentages of identical
%                             matches.
%           .nident [double]  A k-by-1 array of numbers of identical matches.

  % check inputs {{{
  if nargin < 1 && nargin > 2
    error('pfp_importblast:InputCount', 'Expected 1 or 2 inputs.');
  end

  if nargin == 1
    ksh = false;
  end

  % ifile
  validateattributes(ifile, {'char'}, {'nonempty'}, '', 'ifile', 1);
  fid = fopen(ifile, 'r');
  if fid == -1
    error('pfp_importblast:FileErr', 'Cannot open the file [%s].', ifile);
  end

  % ksh
  validateattributes(ksh, {'logical'}, {'nonempty'}, '', 'ksh', 2);
  % }}}

  % read blast results {{{
  block_size = 1e5;
  format = '%s%s%f%f%f%f';

  qseqid    = {}; % holding results (query sequencd id)
  info      = {}; % holding results (information)
  collected = 0;

  running_qseqid = {};
  remained       = cell(1, 6);
  while ~feof(fid)
    % read in a new block
    block = textscan(fid, format, block_size);

    % process the block {{{
    % appending to the remained block
    for i = 1 : 6
      remained{i} = [remained{i}; block{i}];
    end

    R = numel(remained{1});

    start = 1;
    pos   = loc_first_chunk_last_pos(remained{1}, 1, R);

    % Records in 'remained' could contain multiple chunks, this loop parsed each
    % of them. The last chunk is, of course, "remained" for the next block.
    while pos ~= R % all records of the current chunk has been read
      index  = start : pos;
      if ksh
        keep = true(numel(index), 1);
      else
        % remove self-hits
        keep = ~strcmp(remained{2}(index), remained{1}{start});
      end

      % collect
      if any(keep)
        % append one entry to the result
        collected              = collected + 1;
        qseqid{collected}      = remained{1}{start};
        info{collected}.sseqid = remained{2}(index(keep));
        info{collected}.evalue = remained{3}(index(keep));
        info{collected}.length = remained{4}(index(keep));
        info{collected}.pident = remained{5}(index(keep));
        info{collected}.nident = remained{6}(index(keep));
      end

      % update
      start = pos + 1;
      pos   = loc_first_chunk_last_pos(remained{1}, start, R);
    end

    % clear processed entries {{{
    if start > 1 % has been updated
      for i = 1 : 6
        remained{i}(1 : start - 1) = [];
      end
    end
    % }}}
    % }}}
  end
  fclose(fid);

  % collect the last "remained" entry {{{
  if ~isempty(remained{1})
    collected = collected + 1;
    qseqid{collected} = remained{1}{1};
    info{collected}.sseqid = remained{2};
    info{collected}.evalue = remained{3};
    info{collected}.length = remained{4};
    info{collected}.pident = remained{5};
    info{collected}.nident = remained{6};
  end
  % }}}

  blast.qseqid = qseqid;
  blast.info   = info;
  % }}}
return

% function: loc_first_chunk_last_pos {{{
% This function assumes same labels have been put together in L, that is, labels
% are organized as "chunks", and it returns the end position of the first chunk.
function [pos] = loc_first_chunk_last_pos(L, pos_a, pos_b)
  if strcmp(L(pos_a), L(pos_b))
    pos = pos_b; return;
  end

  % find the smallest N such that N = 2^n >= (pos_b - pos_a) {{{
  n = 0;
  range = pos_b - pos_a;
  while 2 ^ n < range
    n = n + 1;
  end
  N = 2 ^ n;
  % }}}

  % binary search {{{
  pos  = pos_a + N;
  step = N / 2;

  while step >= 1
    if pos > pos_b || ~strcmp(L(pos_a), L(pos))
      pos = pos - step;
    else
      pos = pos + step;
    end
    step = step / 2;
  end
  % }}}

  if ~strcmp(L(pos_a), L(pos))
    pos = pos - 1;
  end
return
% }}}

% -------------
% Yuxiang Jiang (yuxjiang@indiana.edu)
% Department of Computer Science
% Indiana University Bloomington
% Last modified: Sun 22 May 2016 03:13:17 PM E
