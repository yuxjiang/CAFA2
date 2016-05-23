function [pred] = pfp_naive(qseqid, oa)
%PFP_NAIVE Naive function prediction
%
% [pred] = PFP_NAIVE(qseqid, oa);
%
%   Returns the naive function prediction.
%
%   The naive function prediction simply predicts a term (for all query
%   sequences) with the frequency in an annotation database.
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
% pred: The naive prediction structure.
%       .object   [cell]    query ID list
%       .ontology [struct]  the ontology structure
%       .score    [double]  predicted association scores
%       .date     [char]
%
% See Also
% --------
%[>]pfp_oabuild.m

  % check inputs {{{
  if nargin ~= 2
    error('pfp_naive:InputCount', 'Expected 2 inputs.');
  end

  % qseqid
  validateattributes(qseqid, {'cell'}, {'nonempty'}, '', 'qseqid', 1);

  % oa
  validateattributes(oa, {'struct'}, {'nonempty'}, '', 'oa', 2);
  % }}}

  % prepare for the output {{{
  pred.object   = reshape(qseqid, [], 1); % make it vertical
  pred.ontology = oa.ontology;

  score = sparse(sum(oa.annotation, 1));
  score = score ./ max(score);

  pred.score = repmat(score, numel(qseqid), 1);
  pred.date  = datestr(now, 'mm/dd/yyyy HH:MM');
  % }}}
return

% -------------
% Yuxiang Jiang (yuxjiang@indiana.edu)
% Department of Computer Science
% Indiana University Bloomington
% Last modified: Sun 22 May 2016 04:15:16 PM E
