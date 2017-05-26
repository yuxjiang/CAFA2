function [ont] = pfp_loadont(tfile, rfile)
    %PFP_LOADONT Load ontology
    %
    % [ont] = PFP_LOADONT(tfile, rfile);
    %
    %   Loads an ontology from a term file and a relation file.
    %
    % Note
    % ----
    % The "term file" and the "relation file" can be generated from
    % pfp_saveont.m. And both of them are assumed to be tab splitted.
    %
    % Input
    % -----
    % [char]
    % tfile:    A term file name. Format:
    %           <term ID> <term name>
    %
    % [char]
    % rfile:    A relation file name. Format:
    %           <src term ID> <relation> <dst term ID>
    %
    % Output
    % ------
    % [struct]
    % ont:  The ontology structure.
    %
    % See Also
    % --------
    % [>] pfp_saveont.m

    % check inputs {{{
    if nargin ~= 2
        error('pfp_loadont:InputCount', 'Expected 2 inputs.');
    end

    % tfile
    validateattributes(tfile, {'char'}, {'nonempty'}, '', 'tfile', 1);
    term_fid = fopen(tfile, 'r');
    if term_fid == -1
        error('pfp_loadont:FileErr', 'Cannot open the file [%s].', tfile);
    end

    % rfile
    validateattributes(rfile, {'char'}, {'nonempty'}, '', 'rfile', 2);
    rel_fid = fopen(rfile, 'r');
    if rel_fid == -1
        error('pfp_loadont:FileErr', 'Cannot open the file [%s].', rfile);
    end
    % }}}

    % read files {{{
    terms = textscan(term_fid, '%s%s', 'Delimiter', '\t');
    fclose(term_fid);

    rels = textscan(rel_fid, '%s%s%s', 'Delimiter', '\t');
    fclose(rel_fid);
    % }}}

    % construct terms {{{
    ont.term = cell2struct([terms{1}, terms{2}]', {'id', 'term'});
    % }}}

    % construct DAG, rel_code {{{
    [found1, index1] = ismember(rels{1}, terms{1});
    [found2, index2] = ismember(rels{3}, terms{1});

    if ~all(found1) || ~all(found2)
        warning('pfp_loadont:InvalidID', 'Some terms are not found in the term file.')
    end

    found = (found1 & found2);

    index1(~found)  = [];
    rels{2}(~found) = [];
    index2(~found)  = [];

    all_codes = unique(rels{2});
    rel_code = {};
    if ismember('is_a', all_codes)
        rel_code = [rel_code, {'is_a'}];
    end

    if ismember('part_of', all_codes)
        rel_code = [rel_code, {'part_of'}];
    end

    rel_code = [rel_code, setdiff(all_codes, {'is_a', 'part_of'})];
    [~, index_code] = ismember(rels{2}, rel_code);

    n = numel(terms{1});

    ont.DAG      = sparse(index1, index2, index_code, n, n);
    ont.rel_code = rel_code;
    ont.date     = datestr(now, 'mm/dd/yyyy HH:MM');
    % }}}
end

% -------------
% Yuxiang Jiang (yuxjiang@indiana.edu)
% Department of Computer Science
% Indiana University Bloomington
% Last modified: Wed 21 Sep 2016 02:33:51 PM E
