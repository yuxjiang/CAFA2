function [] = cafa_sheet_seq_smin(sfile, smin, smin_bst, config, anonymous)
%CAFA_SHEET_SEQ_SMIN CAFA sheet sequence-centric Smin
% {{{
%
% [] = CAFA_SHEET_SEQ_SMIN(sfile, smin, smin_bst, config, anonymous);
%
%   Builds evaluation reports (*.csv).
%
% Input
% -----
% [char]
% sfile:      The filename of the report sheet.
%
% [cell]
% smin:       A 1-by-n smin results.
%             [char]      [1-by-k]    .id
%             [double]    [1-by-1]    .smin
%             [double]    [1-by-1]    .point
%             [double]    [1-by-1]    .tau
%             [double]    [1-by-1]    .coverage
%
%             See cafa_eval_seq_smin.m
%
% [cell]
% smin_bst:   A 1-by-n bootstrapped smin results.
%             [char]      [1-by-k]    .id
%             [double]    [B-by-1]    .smin_bst
%             [double]    [B-by-1]    .point_bst
%             [double]    [B-by-1]    .tau_bst
%             [double]    [B-by-1]    .coverage_bst
%
%             See cafa_eval_seq_smin_bst.m
%
% [char]
% config:     The file having team information. The file should have the
%             folloing columns:
%
%           * 1. <internalID>
%           * 2. <externalID>
%             3. <teamname>
%           * 4. <type>
%           * 5. <displayname>
%             6. <pi>
%             7. <keyword list>
%             8. <assigned color>
%
%             Note:
%             1. The starred columns (*) will be used in this function.
%             2. 'type':  'q'  - qualified
%                         'd'  - disqualified
%                         'n'  - Naive method (baseline 1)
%                         'b'  - BLAST method (baseline 2)
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
%[>]cafa_eval_seq_smin.m
%[>]cafa_eval_seq_smin_bst.m
%[>]cafa_team_read_config.m
% }}}

  % check inputs {{{
  if nargin ~= 5
    error('cafa_sheet_seq_smin:InputCount', 'Expected 5 inputs.');
  end

  % check the 1st input 'sfile' {{{
  validateattributes(sfile, {'char'}, {'nonempty'}, '', 'sfile', 1);
  fout = fopen(sfile, 'w');
  if fout == -1
    error('cafa_sheet_seq_smin:FileErr', 'Cannot open file.');
  end
  % }}}

  % check the 2nd input 'smin' {{{
  validateattributes(smin, {'cell'}, {'nonempty'}, '', 'smin', 2);
  % }}}

  % check the 3rd input 'smin_bst' {{{
  validateattributes(smin_bst, {'cell'}, {'nonempty'}, '', 'smin_bst', 3);
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
  n = numel(smin);
  for i = 1 : n
    if ~strcmp(smin{i}.id, smin_bst{i}.id)
      error('cafa_sheet_seq_smin:IDErr', 'Bootstrapped ID mismatch.');
    end

    [found, index] = ismember(smin{i}.id, team_id);
    if ~found 
      error('cafa_sheet_seq_smin:IDErr', 'Invalid model ID.');
    end
    smin{i}.eid  = ext_id{index};
    smin{i}.team = disp_name{index};
  end
  % }}}

  % printing {{{
  if anonymous
    header = strcat('ID-model', ',Coverage,S2-min,Threshold', ',Coverage Avg(B),S2-min Avg(B),S2-min Std(B),Threshold Avg(B)', '\n');
    format = '%s,%.2f,%.3f,%.2f,%.2f,%.3f,%.3f,%.2f\n';
    fprintf(fout, header);
    for i = 1 : n
      fprintf(fout, format, ...
        smin{i}.eid, ...
        smin{i}.coverage, ...
        smin{i}.smin, ...
        smin{i}.tau, ...
        nanmean(smin_bst{i}.coverage_bst), ...
        nanmean(smin_bst{i}.smin_bst), ...
        nanstd(smin_bst{i}.smin_bst), ...
        nanmean(smin_bst{i}.tau_bst) ...
        );
    end
  else
    header = strcat('ID-model,Team', ',Coverage,S2-min,Threshold', ',Coverage Avg(B),S2-min Avg(B),S2-min Std(B),Threshold Avg(B)', '\n');
    format = '%s,%s,%.2f,%.3f,%.2f,%.2f,%.3f,%.3f,%.2f\n';
    fprintf(fout, header);
    for i = 1 : n
      fprintf(fout, format, ...
        smin{i}.eid, ...
        smin{i}.team, ...
        smin{i}.coverage, ...
        smin{i}.smin, ...
        smin{i}.tau, ...
        nanmean(smin_bst{i}.coverage_bst), ...
        nanmean(smin_bst{i}.smin_bst), ...
        nanstd(smin_bst{i}.smin_bst), ...
        nanmean(smin_bst{i}.tau_bst) ...
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
% Last modified: Wed 05 Aug 2015 04:25:31 PM E
