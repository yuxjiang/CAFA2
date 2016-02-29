function [subont] = pfp_subont(ont, term_lst)
%PFP_SUBONT sub-ontology
% {{{
%
% [subont] = PFP_SUBONT(ont, term_lst);
%
%   Makes a sub-ontology using given terms from the given ontology.
%
% Algorithm
% ---------
% topologically sort terms from leaves to root
% for each term [t] in this order:
%   if [t] is not selected:
%     let [t]'s parents adopt all its children
%   else
% end
%
% Caveat
% ------
% All types of "relation" on the edges of the original DAG will be lost in the
% resulting sub ontology. And the 'rel_code' becomes 'undefined', unless there
% is only one type of relation in the original ontology structure.
%
% Input
% -----
% [struct]
% ont:      The ontology structure.
%           see pfp_ontbuild.m
%
% [cell or struct]
% term_lst: [cell]    - An array of term IDs.
%           [struct]  - An array of term structures.
%
% Output
% ------
% [struct]
% subont:   The resulting sub-ontology structure.
%
% Dependency
% ----------
%[>]Bioinformatics Toolbox:graphtopoorder
%
% See Also
% --------
%[>]pfp_ontbuild.m
% }}}

  % check inputs {{{
  if nargin ~= 2
    error('pfp_subont:InputCount', 'Expected 2 inputs.');
  end

  % check the 1st argument 'ont' {{{
  validateattributes(ont, {'struct'}, {'nonempty'}, '', 'ont', 1);
  % check the 1st argument 'ont' }}}

  % check the 2nd argument 'term_lst' {{{
  validateattributes(term_lst, {'cell', 'struct'}, {'nonempty'}, '', 'term_lst', 2);

  if isstruct(term_lst)
    term_lst = {term_lst.id};
  end
  % check the 2nd argument 'term_lst' }}}
  % check inputs }}}

  % find valid terms {{{
  [found, index] = ismember(term_lst, {ont.term.id});

  if ~all(found)
    warning('pfp_subont:InvalidID', 'Some IDs are invalid.');
  end

  selected = index(found);
  % find valid terms }}}

  % run algorithm to find selected terms {{{
  DAG        = ont.DAG ~= 0;
  topoorder  = graphtopoorder(DAG); % Bioinformatics Toolbox
  isselected = ismember(topoorder, selected);

  for t = 1:length(topoorder)
    if ~isselected(t)
      c = DAG(:, topoorder(t));
      if any(c)
        DAG(c, :) = DAG(c, :) | repmat(DAG(topoorder(t), :), sum(c), 1);
      end
    end
  end

  % sort selected terms
  [~, order] = sort(selected);
  % run algorithm to find selected terms }}}

  % preparing output {{{
  subont.term     = ont.term(selected(order));
  subont.DAG      = double(DAG(selected(order), selected(order)));
  subont.ont_type = ont.ont_type;
  if numel(ont.rel_code) == 1
    subont.rel_code = ont.rel_code;
  else
    subont.rel_code = {'undefined'};
  end
  subont.date = date;
  % preparing output }}}
return

% -------------
% Yuxiang Jiang (yuxjiang@indiana.edu)
% Department of Computer Science
% Indiana University Bloomington
% Last modified: Sat 09 Jan 2016 10:04:09 AM C
