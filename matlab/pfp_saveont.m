function [] = pfp_saveont(ofile, ont)
    %PFP_SAVEONT Save ontology
    %
    % [] = PFP_SAVEONT(ofile, ont);
    %
    %   Saves the ontology terms and structure.
    %
    % Input
    % -----
    % [char]
    % ofile:    The output file name which will be splitted into two files.
    %           E.g. let ofile = '/path/to/output_file.txt', then "terms" will
    %           be saved to: /path/to/output_file_term.txt
    %
    %           <GO ID> <Term name>
    %
    %           and structures will be saved to: /path/to/output_file_rel.txt
    %
    %           <GO ID] <rel> <GO ID>
    %
    % [struct]
    % ont:      The ontology structure. See pfp_ontbuild.m
    %
    % Output
    % ------
    % None.
    %
    % See Also
    % --------
    % [>] pfp_ontbuild.m
    % [>] pfp_loadont.m

    % check inputs {{{
    if nargin ~= 2
        error('pfp_saveont:InputCount', 'Expected 2 inputs.');
    end

    % ofile
    validateattributes(ofile, {'char'}, {'nonempty'}, '', 'ofile', 1);

    % ont
    validateattributes(ont, {'struct'}, {'nonempty'}, '', 'ont', 2);
    % }}}

    % generate and check the output file names {{{
    [p, f, e] = fileparts(ofile);
    if isempty(p)
        % set path to the current folder if omitted
        p = '.';
    end
    term_file = [p, '/', f, '_term', e];
    rel_file  = [p, '/', f, '_rel', e];

    term_fid = fopen(term_file, 'w');
    if term_fid == -1
        error('pfp_saveont:FileErr', 'Cannot open the file [%s].', term_file);
    end

    rel_fid = fopen(rel_file, 'w');
    if rel_fid == -1
        error('pfp_saveont:FileErr', 'Cannot open the file [%s].', rel_file);
    end
    % }}}

    % output terms {{{
    for i = 1 : numel(ont.term)
        fprintf(term_fid, '%s\t%s\n', ont.term(i).id, ont.term(i).name);
    end
    fclose(term_fid);
    % }}}

    % output relation/structures {{{
    for k = 1 : numel(ont.rel_code)
        for i = 1 : numel(ont.term)
            index = find(ont.DAG(i, :) == k);
            for j = 1 : numel(index)
                fprintf(rel_fid, '%s\t%s\t%s\n', ont.term(i).id, ont.rel_code{k}, ont.term(index(j)).id);
            end
        end
    end
    fclose(rel_fid);
    % }}}
end

% -------------
% Yuxiang Jiang (yuxjiang@indiana.edu)
% Department of Computer Science
% Indiana University Bloomington
% Last modified: Wed 21 Sep 2016 02:37:41 PM E
