function [pred, msg] = cafa_import(ifile, ont, header)
%CAFA_IMPORT CAFA Import
% {{{
%
% [pred, msg] = CAFA_IMPORT(ifile, ont);
%
%   Imports prediction in CAFA format.
%
% [pred, msg] = CAFA_IMPORT(ifile, ont, false);
%
%   Imports prediction in CAFA format, but without header.
%
% Input
% -----
% [char]
% ifile:  Input file name. The file should be in CAFA submission format:
%         Header
%         ------
%         AUTHOR team_name
%         MODEL  model_id
%         KEYWORDS kw1[, kw2, ...].
%         (optional)
%         ACCURACY 1 PR=X.XX; RC=X.XX
%         ACCURACY 2 PR=X.XX; RC=X.XX
%
%         Prediction
%         ----------
%         <target id> <term id> <score: x.xx>
%
%         The file must end with: END
%
% [struct]
% ont:    The ontology structure.
%         See pfp_ontbuild.m
%
% (optional)
% [logical]
% header: A boolean value, indicates the existance of header.
%         default: true.
%
% Output
% ------
% [struct]
% pred:   The prediction structure.
%         [cell]
%         .object     The target ID list.
%
%         [structure]
%         .ontology   The ontology structure.
%
%         [double]
%         .score      Predicted score matrix
%
%         [char]
%         .author     Author/team name
%
%         [double]
%         .model      Model ID, e.g. 1, 2, etc.
%
%         [cell]
%         .keywords   An cell array of keywords
%
%         [char]
%         .tag        set to the filename
%
%         (optional)
%         [double]
%         .accuracy   k-by-2 precision-recall pairs
%
% [cell]
% msg:    Message for detected errors.
%
% Dependency
% ----------
%[>]pfp_gettermidx.m
%[>]pfp_predprop.m
%
% See Also
% --------
%[>]pfp_ontbuild.m
% }}}

  % check inputs {{{
  if nargin < 2 || nargin > 3
    error('cafa_import:InputCount', 'Expected 2 or 3 inputs.');
  end

  if nargin == 2
    header = true;
  end

  % check the 1st input 'ifile' {{{
  validateattributes(ifile, {'char'}, {'nonempty'}, '', 'ifile', 1);

  fid = fopen(ifile, 'r');
  if fid == -1
    error('cafa_import:InputErr', 'Cannot open file [%s].', ifile);
  end
  % }}}

  % check the 2nd input 'ont' {{{
  validateattributes(ont, {'struct'}, {'nonempty'}, '', 'ont', 2);
  % }}}

  % check the 3rd input 'header' {{{
  validateattributes(header, {'logical'}, {'nonempty'}, '', 'header', 3);
  % }}}
  % }}}

  % Parse header {{{
  pred.object = {};
  pred.ontology = ont;
  pred.score = [];

  if header
    tline = fgetl(fid);
    if isempty(regexp(tline, '^AUTHOR', 'match', 'once'))
      error('cafa_import:FormatErr', 'AUTHOR line error.');
    else
      pred.author = regexprep(tline, 'AUTHOR\s*', '');
    end

    tline = fgetl(fid);
    if isempty(regexp(tline, '^MODEL', 'match', 'once'))
      error('cafa_import:FormatErr', 'MODEL line error.');
    else
      pred.model = str2double(regexprep(tline, 'MODEL\s*', ''));
      if isempty(pred.model)
        error('cafa_import:FormatErr', 'MODEL line error.');
      end
    end

    tline = fgetl(fid);
    if isempty(regexp(tline, '^KEYWORDS', 'match', 'once'))
      error('cafa_import:FormatErr', 'KEYWORDS line error.');
    else
      pred.keywords = regexp(regexprep(tline, '^KEYWORDS\s*', ''), '[^\s,.][^,.]*[^\s,.]', 'match');
    end

    % optional ACCURACY
    acc_line = 0;
    tline = fgetl(fid);
    while ischar(tline) && ~isempty(regexp(tline, '^ACCURACY', 'match', 'once'))
      acc_line = acc_line + 1;
      pr = cellfun(@str2num, regexp(tline, '\d\.\d{2}', 'match'));
      if numel(pr) ~= 2
        error('cafa_import:FormatErr', 'ACCURACY line error.');
      end

      if ~isfield(pred, 'accuracy')
        pred.accuracy = pr;
      else
        pred.accuracy = [pred.accuracy; pr];
      end
      tline = fgetl(fid);
    end

    % accuracy line + 3 lines for (author, model, keywords)
    header_line = acc_line + 3;

    % goes back to the begining of file
    fseek(fid, 0, 'bof');
  else
    header_line = 0;
  end
  % }}}

  % Read prediction data {{{
  bs = 1e6; % block size

  oindex = [];
  tindex = [];
  score  = [];

  data = textscan(fid, '%s%s%f', bs, 'Delimiter', '\t ', 'HeaderLines', header_line, 'CommentStyle', 'END');
  while ~isempty(data{1})
    % update the object list, without affecting the index of existing object
    uobj = unique(data{1});
    pred.object = [pred.object; setdiff(uobj, pred.object)];

    % find indices
    [~, oid] = ismember(data{1}, pred.object);
    tid = reshape(pfp_gettermidx(ont, data{2}), [], 1); % column vector

    found = tid ~= 0;

    oindex = [oindex; oid(found)];
    tindex = [tindex; tid(found)];
    score  = [score; data{3}(found)];

    data = textscan(fid, '%s%s%f', bs, 'Delimiter', '\t ', 'CommentStyle', 'END');
  end
  fclose(fid);
  % }}}

  % remove duplications {{{
  [oindex, tindex, score, dup_o, dup_t] = remove_duplication(oindex, tindex, score);
  if ~isempty(dup_o)
    msg = cell(1, numel(dup_o));
    for i = 1 : numel(dup_o)
      msg{i} = sprintf('duplicate annotation: %s_%s', pred.object{dup_o(i)}, pred.ontology.term(dup_t(i)).id);
    end
  else
    msg = {};
  end
  % }}}

  % prepare output {{{
  pred.score = sparse(oindex, tindex, score, numel(pred.object), numel(pred.ontology.term));

  if ~isempty(pred.object)
    % propagate raw annotations using 'max' scheme
    pred = pfp_predprop(pred, true, 'max');
  end

  pred.date = date;
  pred.tag = ifile;
  % }}}
return

% function: remove_duplication {{{
function [oindex, tindex, score, dup_o, dup_t] = remove_duplication(oindex, tindex, score)
%REMOVE_DUPLICATION Remove duplication (takes average) {{{
% Input
% -----
%   oindex:     Object index
%
%   tindex:     Term index
%
%   score:      Corresdponding score
%
% Output
% ------
%   oindex:     Object index (with dup removed)
%
%   tindex:     Term index (with dup removed)
%
%   score:      Corresdponding score (with dup removed)
%
%   dup_o:      duplicated object index (for output messages)
%
%   dup_t:      duplicated term index (for output messages)
% }}}

  dup_o = [];
  dup_t = [];

  if isempty(oindex)
    return;
  end

  [oindex, index] = sort(oindex);
  tindex = tindex(index);
  score  = score(index);

  % boundary start
  b_bg = find(oindex - [0; oindex(1 : end - 1)] ~= 0);

  % boundary end
  b_ed = find(oindex - [oindex(2 : end); oindex(end) + 1] ~= 0);

  to_be_rm = false(numel(oindex), 1);

  for i = 1 : numel(b_bg)
    a = b_bg(i); b = b_ed(i);
    block_index = (a:b)';
    if a < b && numel(unique(tindex(block_index))) < numel(block_index) 
      % duplication detected!
      [tindex(a:b), index] = sort(tindex(a:b));

      % rearrange score accordingly
      score(a:b) = score(block_index(index));

      dup_count = 1;
      record_id = a;
      t = tindex(a);
      for walking = a + 1 : b
        if tindex(walking) ~= t % scanning a new term
          % update the recorded score if needed
          if (dup_count > 1)
            dup_o = [dup_o; oindex(record_id)];
            dup_t = [dup_t; tindex(record_id)];
            score(record_id) = round(score(record_id) ./ dup_count .* 100) ./ 100;
          end

          % recording for a new one
          t = tindex(walking);
          dup_count = 1;
          record_id = walking;
        else % found duplicated annotations
          score(record_id) = score(record_id) + score(walking);
          to_be_rm(walking) = true;
          dup_count = dup_count + 1;
        end
      end
      % update the last recorded score if needed
      if (dup_count > 1)
        score(record_id) = round(score(record_id) ./ dup_count .* 100) ./ 100;
      end
    end
  end
  oindex(to_be_rm) = [];
  tindex(to_be_rm) = [];
  score(to_be_rm) = [];
return % }}}

% -------------
% Yuxiang Jiang (yuxjiang@indiana.edu)
% Department of Computer Science
% Indiana University Bloomington
% Last modified: Fri 23 Oct 2015 02:12:56 PM E
