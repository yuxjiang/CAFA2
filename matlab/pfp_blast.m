function [pred] = pfp_blast(qseqid, B, oa, feature)
%PFP_BLAST BLAST (predictor)
% {{{
%
% [pred] = PFP_BLAST(qseqid, B, oa, feature);
%
%   Returns the BLAST predcition.
%
% Note
% ----
% The resulting structure 'pred' is similar to 'oa' except that it substitutes
% the field 'annotation' for a double matrix 'score'.
%
% Input
% -----
% [cell]
% qseqid:   n-by-1, a list of query sequence ID.
%           The sequence ID can of any type, as long as they are the same as
%           those used in 'B.qseqid'. One can simply feed the function with
%           'B.qseqid' as the 1st input so as to get the BLAST prediction of all
%           sequences in 'B'.
%
% [char]
% B:        The imported blastp results. Typically, blast test set against
%           training set sequences.
%           See pfp_importblastp.m for instructions of running blastp.
%
%           Note: one needs to make sure that the query sequence ID of 'B'
%           "match" the 'qseqid' as the first argument.
%
% [struct]
% oa:       The reference ontology annotation structure. Typically, it's the
%           annotation structure of the training set.
%           See pfp_oabuild.m
%
% (optional)
% [char]
% feature:  The feature used to generate blast predictions. It has to be one
%           of {'sid', 'rscore'}.
%           'sid'     - sequence identity, uses 'pident' from blastp.
%                       It's the widely used BLAST baseline for protein function
%                       prediction methods.
%           'rscore'  - R-score, -log(E-value) + 2
%           default: 'sid'
%
% Output
% ------
% [struct]
% pred:     The BLAST prediction structure.
%           [cell]
%           .object     query ID list
%
%           [struct]
%           .ontology   the ontology structure
%
%           [double]
%           .score      predicted association scores
%
%           [char]
%           .date
%
% See Also
% --------
%[>]pfp_importblastp.m
%[>]pfp_oabuild.m
% }}}

  % check inputs {{{
  if nargin < 3 || nargin > 4
    error('pfp_blast:InputCount', 'Expected 3 or 4 inputs.');
  end

  if nargin == 3
    feature = 'sid';
  else
    % maximum R-score allowed
    MAX_RSCORE = 500;
  end

  % check the 1st input 'qseqid' {{{
  validateattributes(qseqid, {'cell'}, {'nonempty'}, '', 'qseqid', 1);
  % check the 1st input 'qseqid' }}}

  % check the 2nd input 'B' {{{
  validateattributes(B, {'struct'}, {'nonempty'}, '', 'B', 2);
  % check the 2nd input 'B' }}}

  % check the 3rd input 'oa' {{{
  validateattributes(oa, {'struct'}, {'nonempty'}, '', 'oa', 3);
  % check the 3rd input 'oa' }}}

  % check the 4th input 'feature' {{{
  feature = validatestring(feature, {'sid', 'rscore'}, '', 'feature', 4);
  % check the 4th input 'feature' }}}
  % check inputs }}}

  % preparing output {{{
  pred.object   = reshape(qseqid, [], 1);
  pred.ontology = oa.ontology;

  n = numel(pred.object);
  m = numel(pred.ontology.term);

  pred.score    = sparse(n, m);
  pred.date     = date;
  % preparing output }}}

  % compute the blast prediction {{{
  [found, index] = ismember(pred.object, B.qseqid);
  for i = 1 : n
    if found(i)
      l = index(i);
      k = numel(B.info{l}.sseqid);
      anno_mat = sparse(k, m);
      [sfound, sindex] = ismember(B.info{l}.sseqid, oa.object);

      if all(~sfound)
        % all hit sequence is not annotated in this 'oa'
        continue;
      end

      switch feature
      case 'sid'
        f = B.info{l}.pident(sfound) ./ 100;
      case 'rscore'
        % crop the value to be within [0, MAX_RSCORE]
        f = -log(B.info{l}.evalue(sfound)) + 2;
        f(f > MAX_RSCORE) = MAX_RSCORE;
        f(f < 0) = 0;
      otherwise
        % nop
      end
      anno_mat(sfound, :) = bsxfun(@times, oa.annotation(sindex(sfound), :), f);

      pred.score(i, :) = max(anno_mat, [], 1);
    end
  end
  % compute the blast prediction }}}
return

% -------------
% Yuxiang Jiang (yuxjiang@indiana.edu)
% Department of Computer Science
% Indiana University Bloomington
% Last modified: Sat 09 Jan 2016 10:33:18 AM C
