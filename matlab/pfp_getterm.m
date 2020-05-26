function [terms, idx] = pfp_getterm(ont, list)
    %PFP_GETTERM Get terms
    %
    % [terms, idx] = PFP_GETTERM(ont, list);
    %
    %   Returns an array of terms and their indices.
    %
    % Note
    % ----
    % 1. If 'alt_list' is presented in the ontology structure, 'list' will also
    %    be searched against that list, and if hit, their current IDs will be
    %    returned;
    % 2. For IDs that are not found, empty strings will be placed at both 'id' and
    %    'name' of those terms, and 0 will be returned as an index.
    %
    % Input
    % -----
    % [struct]
    % ont:  The ontology structure. See pfp_ontbuild.m
    %
    % [cell, char or struct]
    % list: [cell]   - A cell of (char) term IDs.
    %       [char]   - A single (char) term ID.
    %       [struct] - An array of term structures.
    %
    % Output
    % ------
    % [struct]
    % terms:    An array of term structures.
    %
    % [double]
    % idx:      An array of indices.
    %
    % See Also
    % --------
    % [>] pfp_ontbuild.m

    % check inputs {{{
    if nargin ~= 2
        error('pfp_getterm:InputCount', 'Expected 2 inputs.');
    end

    % ont
    validateattributes(ont, {'struct'}, {'nonempty'}, '', 'ont', 1);

    % list
    validateattributes(list, {'cell', 'char', 'struct'}, {'nonempty'}, '', 'list', 2);
    switch class(list)
        case 'char'
            list = {list};
        case 'struct'
            list = {list.id};
        otherwise
            % case: cell, nothing to do
    end
    % }}}

    % find ID of requested terms {{{
    idx = zeros(numel(list), 1);

    if isfield(ont, 'alt_list') % has alternate id list structure
        [is_new, indexN] = ismember(list, {ont.term.id});
        [is_old, indexO] = ismember(list, ont.alt_list.old);

        is_conflict = is_new & is_old;

        % checking
        if any(is_conflict)
            warning('pfp_getterm:AbmiguousID', 'Some IDs are ambiguous, mapped to the latest ID.');
            is_old = is_old & ~is_new;
        end

        idx(is_new) = indexN(is_new);
        idx(is_old) = indexO(is_old);
    else
        [found, index] = ismember(list, {ont.term.id});
        idx(found) = index(found);
    end
    idx   = reshape(idx, 1, []);
    ids   = repmat({''}, numel(list), 1);
    names = repmat({''}, numel(list), 1);

    found = idx ~= 0;
    ids(found)   = {ont.term(idx(found)).id};
    names(found) = {ont.term(idx(found)).name};
    terms = cell2struct([ids, names], {'id', 'name'}, 2);
    % }}}
end

% -------------
% Yuxiang Jiang (yuxjiang@indiana.edu)
% Department of Computer Science
% Indiana University Bloomington
% Last modified: Wed 21 Sep 2016 01:12:39 PM E
