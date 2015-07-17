function [] = cafa_save(pred, ofile, limit)
%CAFA_SAVE CAFA save
% {{{
%
% [] = CAFA_SAVE(pred, ofile);
%
%   Outputs prediction in CAFA format.
%
% [] = CAFA_SAVE(pred, ofile, limit);
%
%   Outputs prediction in CAFA format with specified maximum number of
%   annotations per sequence.
%
% Input
% -----
% [struct]
% pred:   The prediction structure
%         (required)
%         [cell]
%         .object     target id list
%
%         [struct]
%         .ontology   the ontology structure
%
%         [double]
%         .score      predicted score matrix
%
%         (optional)
%         [char]
%         .author     string, author/team name
%
%         [double]
%         .model      double, model ID, e.g. 1, 2, etc.
%
%         [cell]
%         .keywords   cell, an cell array of keywords
%
% [char]
% ofile:  The output file name.
%
%         Format:
%         <target id> <term id> <score>
%
% (optional)
% [double]
% limit:  The number of annotations allowed for each target sequence.
%         default: 1500
%
% Output
% ------
% None.
% }}}

  % check inputs {{{
  if nargin < 2 || nargin > 3
    error('cafa_save:InputCount', 'Expected 2 or 3 inputs.');
  end

  if nargin == 2
    limit = 1500;
  end

  % check the 1st input 'pred' {{{
  validateattributes(pred, {'struct'}, {'nonempty'}, '', 'pred', 1);
  % check the 1st input 'pred' }}}

  % check the 2nd input 'ofile' {{{
  validateattributes(ofile, {'char'}, {'nonempty'}, '', 'ofile', 2);
  fid = fopen(ofile, 'w');
  if fid == -1
    error('cafa_save:InputErr', 'cannot open file [%s].', ofile);
  end
  % check the 2nd input 'ofile' }}}

  % check the 3rd input 'limit' {{{
  validateattributes(limit, {'double'}, {'>', 0}, '', 'limit', 3);
  % check the 3rd input 'limit' }}}
  % check inputs }}}

  % normalize prediction {{{
  max_score = max(max(pred.score));
  pred.score = pred.score ./ max_score;
  % normalize prediction }}}

  % output header {{{
  has_header = false;
  if isfield(pred, 'author')
    fprintf(fid, 'AUTHOR %s\n', pred.author);
    has_header = true;
  end

  if isfield(pred, 'model')
    fprintf(fid, 'MODEL %d\n', pred.model);
    has_header = true;
  end

  if isfield(pred, 'keywords')
    fprintf(fid, 'KEYWORDS ');
    if numel(pred.keywords) > 0
      for i = 1 : numel(pred.keywords) - 1
        fprintf(fid, '%s, ', pred.keywords{i});
      end
      fprintf(fid, '%s.', pred.keywords{end});
    end
    fprintf(fid, '\n');
    has_header = true;
  end
  % output header }}}

  % optional accuracy {{{
  if isfield(pred, 'accuracy')
    for i = 1 : size(pred.accuracy, 1)
      fprintf(fid, 'ACCURACY %d PR=%.2f; RC=%.2f\n', i, pred.accuracy(i, 1), pred.accuracy(i, 2));
    end
  end
  % optional accuracy }}}

  % save prediction scores {{{
  for i = 1 : numel(pred.object)
    fprintf('%d of %d\n', i, numel(pred.object));
    id = pred.object{i};
    index = find(pred.score(i, :) >= 0.01);

    terms = pred.ontology.term(index);
    score = reshape(full([pred.score(i, index)]), [], 1);

    [~, index] = sort(score, 'descend');
    len = min(limit, length(terms));
    terms = terms(index(1:len));
    score = score(index(1:len));

    for j = 1 : len
      fprintf(fid, '%s %s %.2f\n', id, terms(j).id, score(j));
    end
  end

  if has_header
    fprintf(fid, 'END');
  end

  fclose(fid);
  % save prediction scores }}}
return

% -------------
% Yuxiang Jiang (yuxjiang@indiana.edu)
% Department of Computer Science
% Indiana University Bloomington
% Last modified: Fri 17 Jul 2015 11:03:13 AM E
