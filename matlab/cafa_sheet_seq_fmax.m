function [] = cafa_sheet_seq_fmax(sfile, fmax, fmax_bst, config, anonymous)
%CAFA_SHEET_SEQ_FMAX CAFA sheet sequence-centric Fmax
% {{{
%
% [] = CAFA_SHEET_SEQ_FMAX(sfile, fmax, fmax_bst, config, anonymous);
%
%   Builds evaluation reports (*.csv).
%
% Input
% -----
% [char]
% sfile:    The filename of the report sheet.
%
% [cell]
% fmax:     1-by-n fmax results.
%           [char]      [1-by-k]    .id
%           [double]    [1-by-1]    .fmax
%           [double]    [1-by-1]    .point
%           [double]    [1-by-1]    .tau
%           [double]    [1-by-1]    .coverage
%
%           See cafa_eval_seq_fmax.m
%
% [cell]
% fmax_bst: 1-by-n bootstrapped fmax results.
%           [char]      [1-by-k]    .id
%           [double]    [B-by-1]    .fmax_bst
%           [double]    [B-by-1]    .point_bst
%           [double]    [B-by-1]    .tau_bst
%           [double]    [B-by-1]    .coverage_bst
%
%           See cafa_eval_seq_fmax_bst.m
%
% [char]
% config:   The file having team information. The file should have the
%           folloing columns:
%
%         * 1. <internalID>
%         * 2. <externalID>
%           3. <teamname>
%         * 4. <type>
%         * 5. <displayname>
%           6. <pi>
%           7. <keyword list>
%           8. <assigned color>
%
%           Note:
%           1. The starred columns (*) will be used in this function.
%           2. 'type':  'q'  - qualified
%                       'd'  - disqualified
%                       'n'  - Naive method (baseline 1)
%                       'b'  - BLAST method (baseline 2)
%
% [logical]
% anonymous:  Toggle for anonymous. (i.e. remove the team name column)
%
% Output
% ------
% None.
%
% Dependency
% ----------
%[>]cafa_team_read_config.m
%[>]cafa_eval_seq_fmax.m
%[>]cafa_eval_seq_fmax_bst.m
% }}}

  % check inputs {{{
  if nargin ~= 5
    error('cafa_sheet_seq_fmax:InputCount', 'Expected 5 inputs.');
  end

  % check the 1st input 'sfile' {{{
  validateattributes(sfile, {'char'}, {'nonempty'}, '', 'sfile', 1);
  fout = fopen(sfile, 'w');
  if fout == -1
    error('cafa_sheet_seq_fmax:FileErr', 'Cannot open file.');
  end
  % }}}

  % check the 2nd input 'fmax' {{{
  validateattributes(fmax, {'cell'}, {'nonempty'}, '', 'fmax', 2);
  % }}}

  % check the 3rd input 'fmax_bst' {{{
  validateattributes(fmax_bst, {'cell'}, {'nonempty'}, '', 'fmax_bst', 3);
  % }}}

  % check the 4th input 'config' {{{
  validateattributes(config, {'char'}, {'nonempty'}, '', 'config', 4);
  [team_id, ext_id, ~, team_type, disp_name] = cafa_team_read_config(config);
  % }}}

  % check the 5th input 'anonymous' {{{
  validateattributes(anonymous, {'logical'}, {'nonempty'}, '', 'anonymous', 5);
  % }}}
  % }}}

  % prepare output {{{
  n = numel(fmax);
  for i = 1 : n
    if ~strcmp(fmax{i}.id, fmax_bst{i}.id)
      error('cafa_sheet_seq_fmax:IDErr', 'Bootstrapped ID mismatch.');
    end

    [found, index] = ismember(fmax{i}.id, team_id);
    if ~found 
      error('cafa_sheet_seq_fmax:IDErr', 'Invalid model ID.');
    end
    fmax{i}.eid  = ext_id{index};
    fmax{i}.team = disp_name{index};
  end
  % }}}

  % printing {{{
  if anonymous
    header = strcat('ID-model', ',Coverage,F1-max,Threshold', ',Coverage Avg(B),F1-max Avg(B),F1-max Std(B),Threshold Avg(B)', '\n');
    format = '%s,%.2f,%.3f,%.2f,%.2f,%.3f,%.3f,%.2f\n';
    fprintf(fout, header);
    for i = 1 : n
      fprintf(fout, format, ...
        fmax{i}.eid, ...
        fmax{i}.coverage, ...
        fmax{i}.fmax, ...
        fmax{i}.tau, ...
        nanmean(fmax_bst{i}.coverage_bst), ...
        nanmean(fmax_bst{i}.fmax_bst), ...
        nanstd(fmax_bst{i}.fmax_bst), ...
        nanmean(fmax_bst{i}.tau_bst) ...
        );
    end
  else
    header = strcat('ID-model,Team', ',Coverage,F1-max,Threshold', ',Coverage Avg(B),F1-max Avg(B),F1-max Std(B),Threshold Avg(B)', '\n');
    format = '%s,%s,%.2f,%.3f,%.2f,%.2f,%.3f,%.3f,%.2f\n';
    fprintf(fout, header);
    for i = 1 : n
      fprintf(fout, format, ...
        fmax{i}.eid, ...
        fmax{i}.team, ...
        fmax{i}.coverage, ...
        fmax{i}.fmax, ...
        fmax{i}.tau, ...
        nanmean(fmax_bst{i}.coverage_bst), ...
        nanmean(fmax_bst{i}.fmax_bst), ...
        nanstd(fmax_bst{i}.fmax_bst), ...
        nanmean(fmax_bst{i}.tau_bst) ...
        );
    end
  end
  fclose(fout);
  % }}}
return
% }}}

% -------------
% Yuxiang Jiang (yuxjiang@indiana.edu)
% Department of Computer Science
% Indiana University Bloomington
% Last modified: Wed 05 Aug 2015 04:26:47 PM E
