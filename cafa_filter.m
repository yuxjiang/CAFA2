function [] = cafa_filter(seq_list, ifile, ofile)
%CAFA_FILTER CAFA filter
% {{{
%
% [] = CAFA_FILTER(seq_list, ifile, ofile);
%
%   Filters raw predictions: keeps only targets in the given list. This function
%   is used to make the raw prediction file smaller.
%
% Input
% -----
% [cell]
% seq_list: sequence (benchmark) list, expected to be a target list.
%
% [char]
% ifile:    Input file name. The file should be in CAFA submission format:
%           Header
%           ------
%           AUTHOR team_name
%           MODEL  model_id
%           KEYWORDS kw1[, kw2, ...].
%           (optional)
%           ACCURACY 1 PR=X.XX; RC=X.XX
%           ACCURACY 2 PR=X.XX; RC=X.XX
%
%           Prediction
%           ----------
%           <target id> <term id> <score: x.xx>
%
%           The file must end with: END
%
% [char]
% ofile:    Output file name. The output file shall follow the same format
%           as the input file.
%
% Output
% ------
% None.
% }}}

  % check inputs {{{
  if nargin ~= 3
    error('cafa_filter:InputCount', 'Expected 3 inputs.');
  end

  % check the 1st input 'seq_list' {{{
  validateattributes(seq_list, {'cell'}, {'nonempty'}, '', 'seq_list', 1);
  % }}}

  % check the 2nd input 'ifile' {{{
  validateattributes(ifile, {'char'}, {'nonempty'}, '', 'ifile', 2);
  fin = fopen(ifile, 'r');
  if fin == -1
    error('cafa_filter:InputErr', 'Cannot open input file [%s].', ifile);
  end
  % }}}

  % check the 3rd input 'ofile' {{{
  validateattributes(ofile, {'char'}, {'nonempty'}, '', 'ofile', 3);
  fout = fopen(ofile, 'w');
  if fout == -1
    error('cafa_filter:InputErr', 'Cannot open output file [%s].', ofile);
  end
  % }}}
  % }}}

  % parse header if presented {{{
  has_header = false;
  header_lines = 0;

  tline = fgetl(fin);
  if isempty(tline) || (isnumeric(tline) && tline == -1) % empty input file
    fclose(fin);
    fclose(fout);
    return;
  end

  while isempty(regexp(tline, '^T[0-9]+', 'match', 'once'))
    has_header = true;
    header_lines = header_lines + 1;
    fprintf(fout, '%s\n', tline); % copy the header to output file
    tline = fgetl(fin);
  end

  fseek(fin, 0, 'bof'); % roll back
  % }}}

  % filter the body of the file {{{
  n = 0;
  bs = 1e5; % block size
  data = textscan(fin, '%s%s%f', bs, 'HeaderLines', header_lines, 'CommentStyle', 'END');
  while ~isempty(data{1})
    found = ismember(data{1}, seq_list);
    if any(found)
      index = find(found);
      for i = 1 : numel(index)
        fprintf(fout, '%s\t%s\t%.2f\n', data{1}{index(i)}, data{2}{index(i)}, data{3}(index(i)));
      end
    end
    n = n + numel(data{1});
    %fprintf('filtered [%d] lines.\n', n);
    data = textscan(fin, '%s%s%f', bs, 'CommentStyle', 'END');
  end

  if has_header
    fprintf(fout, 'END');
  end
  fclose(fin);
  fclose(fout);
  % }}}
return

% -------------
% Yuxiang Jiang (yuxjiang@indiana.edu)
% Department of Computer Science
% Indiana University Bloomington
% Last modified: Fri 17 Jul 2015 11:06:07 AM E
