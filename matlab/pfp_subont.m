function [subont] = pfp_subont(ont, list)
%PFP_SUBONT sub-ontology
%
% [subont] = PFP_SUBONT(ont, list);
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
% ont:  The ontology structure.
%       see pfp_ontbuild.m
%
% [cell or struct]
% list: cell    - An array of term IDs.
%       struct  - An array of term structures.
%
% Output
% ------
% [struct]
% subont: The resulting sub-ontology structure.
%
% Dependency
% ----------
%[>]Bioinformatics Toolbox:graphtopoorder
%
% See Also
% --------
%[>]pfp_ontbuild.m

  % check inputs {{{
  if nargin ~= 2
    error('pfp_subont:InputCount', 'Expected 2 inputs.');
  end

  % ont
  validateattributes(ont, {'struct'}, {'nonempty'}, '', 'ont', 1);

  % list
  validateattributes(list, {'cell', 'struct'}, {'nonempty'}, '', 'list', 2);

  if isstruct(list)
    list = {list.id};
  end
  % }}}

  % find valid terms {{{
  [found, index] = ismember(list, {ont.term.id});

  if ~all(found)
    warning('pfp_subont:InvalidID', 'Some IDs are invalid.');
  end

  selected = index(found);
  % }}}

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
  % }}}

  % preparing output {{{
  subont.term     = ont.term(selected(order));
  subont.DAG      = double(DAG(selected(order), selected(order)));
  subont.ont_type = ont.ont_type;
  if numel(ont.rel_code) == 1
    subont.rel_code = ont.rel_code;
  else
    subont.rel_code = {'undefined'};
  end
  subont.date = datestr(now, 'mm/dd/yyyy HH:MM');
  % }}}
return

% -------------
% Yuxiang Jiang (yuxjiang@indiana.edu)
% Department of Computer Science
% Indiana University Bloomington
% Last modified: Mon 23 May 2016 06:52:22 PM E
