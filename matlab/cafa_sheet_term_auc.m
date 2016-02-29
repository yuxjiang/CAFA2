function [] = cafa_sheet_term_auc(sfile, aucs, config, isdump, anonymous, sort_mid)
%CAFA_SHEET_TERM_AUC CAFA sheet term-centric AUC
% {{{
%
% [] = CAFA_SHEET_TERM_AUC(sfile, aucs, config, anonymous, sort_mid);
%
%   Builds AUC evaluation report (*.csv).
%
% Note
% ----
% Terms (columns) will be sorted according to BLAST performance.
%
% Input
% -----
% (required)
% [char]
% sfile:      The filename of the report sheet.
%
% [cell]
% aucs:       n-by-1 AUC results.
%             [char]      [1-by-k]    .id
%             [cell]      [1-by-m]    .term
%             [double]    [1-by-m]    .auc
%
%             See cafa_eval_term_auc.m
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
%           * 6. <dumpname>
%             7. <pi>
%             8. <keyword list>
%             9. <assigned color>
%
%             Note:
%             1. The starred columns (*) will be used in this function.
%             2. 'type':  'q'  - qualified
%                         'd'  - disqualified
%                         'n'  - Naive method (baseline 1)
%                         'b'  - BLAST method (baseline 2)
%
% [logical]
% isdump:     A switch for using dump name instead of display name.
%             default: false.
%
% [logical]
% anonymous:  If anonymous.
%
% (optional)
% [char]
% sort_mid:   Model name, Sort terms according the performance of it.
%             default: 'BB4S'
%
% Output
% ------
% None.
%
% Dependency
% ----------
%[>]cafa_team_read_config.m
%[>]cafa_eval_term_auc.m
% }}}

  % check inputs {{{
  if nargin < 5 || nargin > 6
    error('cafa_sheet_term_auc:InputCount', 'Expected 5 or 6 inputs.');
  end

  if nargin == 5
    sort_mid = 'BB4S'; % BLAST trained on SwissProt 2014
  end

  % check the 1st input 'sfile' {{{
  validateattributes(sfile, {'char'}, {'nonempty'}, '', 'sfile', 1);
  fout = fopen(sfile, 'w');
  if fout == -1
    error('cafa_sheet_term_auc:FileErr', 'Cannot open file.');
  end
  % }}}

  % check the 2nd input 'aucs' {{{
  validateattributes(aucs, {'cell'}, {'nonempty'}, '', 'aucs', 2);
  % }}}

  % check the 3rd input 'config' {{{
  validateattributes(config, {'char'}, {'nonempty'}, '', 'config', 3);
  [team_id, ext_id, ~, team_type, disp_name, dump_name] = cafa_team_read_config(config);
  % }}}

  % check the 4th input 'isdump' {{{
  validateattributes(isdump, {'logical'}, {'nonempty'}, '', 'isdump', 4);
  if isdump
    disp_name = dump_name;
  end
  % }}}

  % check the 5th input 'anonymous' {{{
  validateattributes(anonymous, {'logical'}, {'nonempty'}, '', 'anonymous', 5);
  % }}}

  % check the 6th input 'sort_mid' {{{
  validateattributes(sort_mid, {'char'}, {'nonempty'}, '', 'sort_mid', 6);
  % }}}
  % }}}

  % prepare output {{{
  n = numel(aucs);
  for i = 1 : n
    [found, index] = ismember(aucs{i}.id, team_id);
    if ~found
      error('cafa_sheet_term_auc:IDErr', 'Invalid model ID.');
    end
    aucs{i}.eid  = ext_id{index};
    aucs{i}.team = disp_name{index};

    % record the index of blast method for sorting {{{
    if strcmp(aucs{i}.id, sort_mid) % before: if strcmpi('blast', aucs{i}.team)
      blast_index = i;
    end
    % }}}
  end
  % }}}

  % sort terms according to BLAST result: good --> bad {{{
  m = numel(aucs{blast_index}.term);
  [~, index] = sort(aucs{blast_index}.auc, 'descend');
  % }}}

  % printing {{{
  if anonymous
    % print header line {{{
    fprintf(fout, 'ID-model');

    % re-order terms
    reordered_term = aucs{blast_index}.term(index);

    for j = 1 : m
      fprintf(fout, ',%s', reordered_term{j});
    end
    fprintf(fout, '\n');
    % }}}

    for i = 1 : n
      if numel(aucs{i}.term) ~= m
        error('cafa_sheet_term_auc:TermCount', 'Terms don''t match.');
      end
      fprintf(fout, '%s', aucs{i}.eid);
      auc_row = aucs{i}.auc(index);

      for j = 1 : m
        fprintf(fout, ',%.2f', auc_row(j));
      end
      fprintf(fout, '\n');
    end
  else
    % print header line {{{
    fprintf(fout, 'ID-model,Team');

    % re-order terms
    reordered_term = aucs{blast_index}.term(index);

    for j = 1 : m
      fprintf(fout, ',%s', reordered_term{j});
    end
    fprintf(fout, '\n');
    % }}}

    for i = 1 : n
      if numel(aucs{i}.term) ~= m
        error('cafa_sheet_term_auc:TermCount', 'Terms don''t match.');
      end

      fprintf(fout, '%s,%s', aucs{i}.eid, aucs{i}.team);
      auc_row = aucs{i}.auc(index);
      for j = 1 : m
        fprintf(fout, ',%.2f', auc_row(j));
      end
      fprintf(fout, '\n');
    end
  end
  fclose(fout);
  % }}}
return

% -------------
% Yuxiang Jiang (yuxjiang@indiana.edu)
% Department of Computer Science
% Indiana University Bloomington
% Last modified: Tue 20 Oct 2015 11:21:11 AM E
