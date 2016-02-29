function [pred] = pfp_predprop(pred, force, scheme)
%PFP_PREDPROP Prediction Propagation
% {{{
%
% [pred] = PFP_PREDPROP(pred, force, scheme);
%
%   Propagates predicted scores of an predicted oa structure.
%
% Input
% -----
% [struct]
% pred:   The predicted ontology annotation structure.
%
% [logical]
% force:  A binary value, indicates to force consistency or not.
%         'true'   - Update existing scores if inconsistent.
%
%         'false'  - Only fill up missing scores.
%
% (optional)
% [char]
% scheme: The propagation scheme.  {'max', 'ind'}
%
%         'max'   - The score of a parent term is set to the maximum of those of
%                   its children (and itself).
%
%         (TBA)
%         'ind'   - The score of a parent 's' is
%                   s = 1 - \prod_i{1 - s_i}
%                   where s_i is the score of its i-th child.
%                   (It Assumes scores are probabilities and scores of its
%                   children are pairwise independent.)
%
%         default: 'max'
%
% Output
% ------
% [struct]
% pred: The same structure but with score propagated.
%
% Dependency
% ----------
%[>]Bioinformatics Toolbox:graphtopoorder
% }}}

  % check inputs {{{
  if nargin < 2 || nargin > 3
    error('pfp_predprop:InputCount', 'Expected 2 or 3 inputs.');
  end

  if nargin == 2
    scheme = 'max';
  end

  % check the 1st input 'pred' {{{
  validateattributes(pred, {'struct'}, {'nonempty'}, '', 'pred', 1);
  % check the 1st input 'pred' }}}

  % check the 2nd input 'force' {{{
  validateattributes(force, {'logical'}, {'nonempty'}, '', 'force', 2);
  % check the 2nd input 'force' }}}

  % check the 3rd input 'scheme' {{{
  validateattributes(scheme, {'char'}, {'nonempty'}, '', 'scheme', 3);
  scheme = validatestring(scheme, {'max', 'ind'});
  % check the 3rd input 'scheme' }}}
  % check inputs }}}

  % Topologically sort terms from leaf to root. {{{
  order = graphtopoorder(pred.ontology.DAG);

  % Start with the deepest term which has a score.
  deepest = min(find(sum(pred.score(order), 1) > 0));
  order(1 : deepest - 1) = [];
  % Topologically sort terms from leaf to root. }}}

  % propagate scores {{{
  switch scheme
    case 'max'
      if force
        for i = 1 : numel(order)
          % find all child nodes of this term
          C = find(pred.ontology.DAG(:, order(i)) ~= 0);
          if isempty(C)
            continue; % skip for leave terms
          end
          pred.score(:, order(i)) = max(pred.score(:, [C; order(i)]), [], 2);
        end
      else
        for i = 1 : numel(order)
          % find all child nodes of this term
          C = find(pred.ontology.DAG(:, order(i)) ~= 0);

          % find unpredicted proteins for this term
          no_score = find(pred.score(:, order(i)) == 0);
          if isempty(C) || isempty(no_score)
            continue; % skip for leave terms and all predicted terms.
          end
          pred.score(no_score, order(i)) = max(pred.score(no_score, C), [], 2);
        end
      end
    case 'ind'
      %if ~all(all(pred.score <= 1) & all(pred.score >= 0))
      %error('pfp_predprop:NotProb', ...
      %'''score'' is not a probability score within [0, 1]');
      %end
      %pred.score = 1 - pred.score;
      %for i = 1 : numel(order)
      %P = pred.ontology.DAG(order(i), :) ~= 0;
      %pred.score(:, P) = bsxfun(@times, ...
      %pred.score(:, P), pred.score(:, order(i)));
      %end
      %pred.score = 1 - pred.score;
    otherwise
      % nop
  end
  % propagate scores }}}
return

% -------------
% Yuxiang Jiang (yuxjiang@indiana.edu)
% Department of Computer Science
% Indiana University Bloomington
% Last modified: Sat 09 Jan 2016 10:36:19 AM C
