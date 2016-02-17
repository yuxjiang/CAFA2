function [pred] = pfp_naive(qseqid, oa)
%PFP_NAIVE Naive function prediction
% {{{
%
% [pred] = PFP_NAIVE(qseqid, oa);
%
%   Returns the naive function prediction.
%
%   The naive function prediction simply predicts a term (for all query
%   sequences) as the frequency in the annotation database.
%
% Note
% ----
% 'Pred' is similar to 'oa' except that it changes the binary 'annotation'
% matrix to real-valued within [0, 1] matrix 'score'.
%
% Input
% -----
% [cell]
% qseqid: An array of (char) query sequence IDs.
%
% [struct]
% oa:     The reference ontology annotation structure.
%         See pfp_oabuild.m.
%
% Output
% ------
% [struct]
% pred: The naive prediction structure, having the following fields:
%       [cell]
%       .object     A cell of (char) query ID list.
%
%       [struct]
%       .ontology   the ontology structure
%
%       [double and sparse]
%       .score      The scoring matrix.
%
%       [char]
%       .date
%
% See Also
% --------
%[>]pfp_oabuild.m
% }}}

  % check inputs {{{
  if nargin ~= 2
    error('pfp_naive:InputCount', 'Expected 2 inputs.');
  end

  % check the 1st input 'qseqid' {{{
  validateattributes(qseqid, {'cell'}, {'nonempty'}, '', 'qseqid', 1);
  % check the 1st input 'qseqid' }}}

  % check the 2nd input 'oa' {{{
  validateattributes(oa, {'struct'}, {'nonempty'}, '', 'oa', 2);
  % check the 2nd input 'oa' }}}
  % check inputs }}}

  % prepare for the output {{{
  pred.object = reshape(qseqid, [], 1); % make it vertical
  pred.ontology = oa.ontology;

  score = sparse(sum(oa.annotation, 1));
  score = score ./ max(score);

  pred.score = repmat(score, numel(qseqid), 1);
  pred.date  = date;
  % prepare for the output }}}
return

% -------------
% Yuxiang Jiang (yuxjiang@indiana.edu)
% Department of Computer Science
% Indiana University Bloomington
% Last modified: Sat 09 Jan 2016 10:35:16 AM C
