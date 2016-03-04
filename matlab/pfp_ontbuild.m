function [onts] = pfp_ontbuild(obofile, rel)
%PFP_ONTBUILD Ontology build
% {{{
%
% [onts] = PFP_ONTBUILD(obofile);
% [onts] = PFP_ONTBUILD(obofile, rel);
%
%   Builds ontology structure(s) from a plain-text OBO file.
%
% Note
% ----
% This "parser" is NOT meant to fully support OBO format 1.2. It considers the
% OBO file format to be the following, which is suffice to build a DAG.
%
% OBO syntax (without "trailing modifiers"): {{{
% <obo file>        -> <header>\n<stanzas>
% <header>          -> <tag-value pairs>
% <stanzas>         -> <stanza>|<stanzas>\n<stanza>
% <stanza>          -> <stanza name>\n<tag-value pairs>
% <tag-value pairs> -> <tag-value pair>|<tag-value pairs>\n<tag-value pair>
% <tag-value pair>  -> <tag>: <value>
% <stanza name>     -> [STRING]
% <tag>             -> STRING
% <value>           -> STRING
%
% Comments start with !
%
% 1. <header> is generally ignored by this parser, expect for these two optional
%    tag "date", which will be saved as a field of output structure; and
%    "default-namespace" which indicates the default namespace for all
%    <stanza>s.
% 2. Required <tag> for each <stanza>: "id", "name"
% }}}
%
% This "parser" also makes the following STRONG assumptions:
% 1. [Term] is the only stanza to extract.
% 2. "is_a" is presented as the basic relationship between [Term]s, and will
%    always be extracted.
% 3. <tag> namespace indicates the ontology to which a [Term] belongs to, and it
%    will be passed to the output as its field: ont_type. If "namespace" is not
%    given for a [Term], it will take the default-namespace. Further, if
%    "default-namespace" is not given in the <header>, those terms with empty
%    namespace will be grouped in a single ontology with ont_type: 'unknown'.
% 4. Only these <tag>s will be extracted:
%    <tag> -> id|name|namespace|is_a|alt_id|is_obsoleted|relationship
% 5. Only obsoleted terms have this <tag-value pair>
%    is_obsoleted: true
%    and its value should always be true.
%
% Input
% -----
% (required)
% [char]
% obofile:  The ontology file in OBO format.
%
% (optional)
% [cell]
% rel:      A cell array of relationship other than "is_a" to extract. Other
%           relationship codes in the given OBO file are ignored. It is passed
%           to the output as one of its field: 'rel_code'.
%           default: {'part_of'} (as mostly used for Gene Ontology)
%
% Output
% ------
% [cell or struct]
% onts:     The built ontology structure.
%           If the given OBO file only has one ontology structure, 'onts' is a
%           single variable of type 'struct'; while multiple ontologies result
%           in a cell array of ontology structures. In either cases, the
%           structure has the following fields:
%
%           [struct]
%           .term       A term structure array, each has two fields:
%             .id       [char] The term ID.
%             .name     [char] The name tag attached to each term.
%
%           [struct]
%           .alt_list   The alternative ID list.
%             .old      [char] The old ID.
%             .new      [char] The corresponding new ID.
%
%           [double and sparse]
%           .DAG        The adjacency matrix corresponding to a directed
%                       acyclic graph, where DAG(i, j) = t indicates term i has
%                       relationship type 'rel_code{t}' with term j.
%
%           [cell]
%           .rel_code   A relationship code array, typically, for example, it
%                       could be {'is_a', 'part_of'} for gene ontology.
%
%           [char]
%           .ont_type   The ontology name tag. E.g. 'molecular_function',
%                       'human_phenotype', etc.
%
%           [char]
%           .date       The date tag of this OBO file if "date" is presented in
%                       <header>; Otherwise, it stores the current date.
% }}}

  % check inputs {{{
  if nargin ~= 1 && nargin ~= 2
    error('pfp_ontbuild:InputCount', 'Expected 1 or 2 inputs.');
  end

  if nargin == 1
    rel = {'part_of'};
  end

  % check the 1st input 'obofile' {{{
  validateattributes(obofile, {'char'}, {'nonempty'}, '', 'obofile', 1);
  fid = fopen(obofile, 'r');
  if fid == -1
    error('pfp_ontbuild:FileErr', 'Cannot open OBO file.');
  end
  % }}}

  % check the 2nd input 'rel' {{{
  validateattributes(rel, {'cell'}, {'nonempty'}, '', 'rel', 2);
  % }}}
  % }}}

  % read the OBO file as a whole {{{
  obo = textscan(fid, '%s', 'WhiteSpace', '\n');
  obo = obo{1};
  fclose(fid);
  % }}}

  % parse obo file {{{
  % locate the [b]eginning and [e]nding line number of each [Term] stanza {{{
  stanza_b = find(cellfun(@length, regexp(obo, '^\[.+\]')));
  is_term  = strcmpi(obo(stanza_b), '[Term]');
  term_b   = stanza_b(is_term);
  stanza_e = [stanza_b(2:end)-1; numel(obo)];
  term_e   = stanza_e(is_term);

  tid         = zeros(numel(obo), 1);
  tid(term_b) = 1:numel(term_b);    % tid = [0 0 1 0 0  0 2 0  0 0 0 3 0  0]
  tid(term_e) = -(1:numel(term_b)); % tid = [0 0 1 0 0 -1 2 0 -2 0 0 3 0 -3]
  tid         = cumsum(tid);        % tid = [0 0 1 1 1  0 2 2  0 0 0 3 3  0]
  tid         = max([0; tid(1:end-1)], tid);

  % tid(i) = 0 indicates the i-th line can be ignored
  % tid(i) = k (k > 0) indicates the i-th line belongs to the k-th [Term]
  % stanza, ie., tid(i) is either <stanza name> or one of its <tag-value pair>s.
  loi = tid > 0; % line-of-interest
  % }}}

  % parse header for date {{{
  % locate the line number of the first [Term] <stanza>
  dt         = datestr(now, 'mm/dd/yyyy HH:MM'); % default date
  default_ns = 'unknown'; % default namespace
  begin_of_stanzas = min(stanza_b);
  for i = 1 : begin_of_stanzas-1
    pair = regexp(obo{i}, '(?<tag>\S+):\s*(?<value>.*$)', 'names');
    if isempty(pair)
      continue;
    elseif strcmpi(pair.tag, 'date')
      % parse date string
      d = regexp(pair.value, '(?<dd>\d{2}):(?<mm>\d{2}):(?<yyyy>\d{4}) (?<HH>\d{2}):(?<MM>\d{2})', 'names');
      dt = sprintf('%s/%s/%s %s:%s', d.mm, d.dd, d.yyyy, d.HH, d.MM);
    elseif strcmpi(pair.tag, 'default-namespace')
      default_ns = pair.value;
    end
  end
  % }}}

  % hash the first 6 character of each line to make a list of tags {{{
  % Note: these hash keys must match with those in hashkeywords
  hk = hashkeywords;

  HK_ID     = 1;
  HK_NAME   = 2;
  HK_NAMESP = 3;
  HK_IS_A   = 4;
  HK_ALT_ID = 5;
  HK_IS_OBS = 6; % is_obsoleted
  HK_RELATI = 7; % relationship

  % key-length: 6
  % extract the first up to 6 character of each line to be the hash key for that
  % line. (Note that ^\w{1,6} matches the first up to 6 [A-Za-z_]). Since this
  % script only sensitive to a few <tag>s which are all consist of lower case
  % letters and '_', so we extract '`' (0x60, the last character before 'a' in
  % the ASCII table) from these keys. (Note that '_': 0x5F becomes 0 after the
  % max(0, x-'`') operation.)
  key = max(0, char(regexp(obo, '^\w{1,6}', 'match', 'once'))-'`');
  if size(key, 2) < 6
    % in case no line has at least 6 characters, although rare..
    key = [key, zeros(size(key,1), 6-size(key,2))];
  end
  % 'key' is then a n-by-6 non-negative double matrix.
  % must be the same powers as in function: hashkeywords
  powers = [27^5;27^4;27^3;27^2;27;1];
  tags   = full(hk(key*powers+1));

  % clear "tags", ie., <tag>: <value> --> <value>
  obo = regexprep(obo, '^\w+:\s*', '');
  % }}}

  % extract id and name {{{
  % we assume each [Term] has only exactly one "id" and "name"
  id   = obo(loi & (tags == HK_ID));
  name = obo(loi & (tags == HK_NAME));
  % }}}

  % extract namespace {{{
  ns = repmat({default_ns}, numel(id), 1);
  is_ns = loi & (tags == HK_NAMESP);
  ns_index = tid(is_ns);
  if ~isempty(ns_index)
    ns(ns_index) = obo(is_ns);
  end
  % }}}

  % extract is_a relationship {{{
  is_a_index = loi & (tags == HK_IS_A);
  % note: [is_a_list.src] is a [is_a_list.dst]
  is_a_list.src = id(tid(is_a_index));
  is_a_list.dst = regexprep(obo(is_a_index), '\s*([^\s!]+).*', '$1');
  % }}}

  % extract other relationships {{{
  for i = 1 : numel(rel)
    % '^rel{i}' matches any line starts with i-th relationship, say '^part_of'
    is_this_rel = ~cellfun(@isempty, regexp(obo, sprintf('^%s', rel{i}), 'match', 'once'));
    % in most cases (is_this_rel == true) implies (loi == true) & (tags == %
    % HK_RELATI) however, sometimes a [Typedef] <stanza> could contain a
    % <tag-value pair> as id: part_of
    is_this_rel     = is_this_rel & loi & (tags == HK_RELATI);
    rel_list.src{i} = id(tid(is_this_rel));
    rel_list.dst{i} = regexprep(obo(is_this_rel), sprintf('^%s\\s*([^\\s!]+).*', rel{i}), '$1');
  end
  % }}}

  % extract alt_id {{{
  alt_id_index = loi & (tags == HK_ALT_ID);
  % note: [alt_list.src] is an alternative id of [alt_list.dst]
  alt_list.src = obo(alt_id_index);
  alt_list.dst = id(tid(alt_id_index));
  % }}}

  % remove obsoleted terms {{{
  is_obs = tid(loi & (tags == HK_IS_OBS));
  id(is_obs)   = [];
  name(is_obs) = [];
  ns(is_obs)   = [];
  % }}}

  % split ontologies according to namespaces {{{
  ont_types = unique(ns);
  if numel(ont_types) == 1
    term = cell2struct([id, name], {'id', 'name'}, 2);
    onts = make_ont(term, alt_list, is_a_list, rel, rel_list);

    onts.ont_type = ont_types{1};
    onts.date     = dt;
  else
    onts = cell(1, numel(ont_types));
    for i = 1 : numel(ont_types)
      this_ont = strcmpi(ns, ont_types{i});
      term = cell2struct([id(this_ont), name(this_ont)], {'id', 'name'}, 2);
      onts{i} = make_ont(term, alt_list, is_a_list, rel, rel_list);

      onts{i}.ont_type = ont_types{i};
      onts{i}.date = dt;
    end
  end
  % }}}
  % parse obo file }}}
return

% function: hashkeywords {{{
function [hk] = hashkeywords
  powers = [27^5;27^4;27^3;27^2;27;1];
  hk = sparse(27^6, 1);
  hk(max(0,'id    '-'`')*powers+1) = 1;
  hk(max(0,'name  '-'`')*powers+1) = 2;
  hk(max(0,'namesp'-'`')*powers+1) = 3; % namespace
  hk(max(0,'is_a  '-'`')*powers+1) = 4;
  hk(max(0,'alt_id'-'`')*powers+1) = 5;
  hk(max(0,'is_obs'-'`')*powers+1) = 6; % is_obsoleted
  hk(max(0,'relati'-'`')*powers+1) = 7; % relationship
return
% }}}

% function: construct ont {{{
function ont = make_ont(term, alt_list, is_a_list, rel, rel_list)
  [~, order] = sort({term.id}); % sort by id
  ont.term = term(order);
  n = numel(term);

  % construct 'alt' list
  found = ismember(alt_list.dst, {ont.term.id});
  ont.alt_list.old = alt_list.src(found);
  ont.alt_list.new = alt_list.dst(found);

  % construct 'DAG'
  % make a list of (source, destination, relationship index)
  ont.rel_code = {'is_a'};
  [found_src, index_src] = ismember(is_a_list.src, {ont.term.id});
  [found_dst, index_dst] = ismember(is_a_list.dst, {ont.term.id});
  valid = found_src & found_dst;
  src = index_src(valid);
  dst = index_dst(valid);
  ind = ones(sum(valid), 1); % index of "is_a": 1

  % append (src, dst, ind) for each 'rel'
  rel_count = 1;
  if exist('rel', 'var')
    for i = 1 : numel(rel)
      if isempty(rel_list.src{i}) || isempty(rel_list.dst{i})
        continue;
      end

      rel_count = rel_count + 1;
      ont.rel_code = [ont.rel_code, rel(i)];
      [found_src, index_src] = ismember(rel_list.src{i}, {ont.term.id});
      [found_dst, index_dst] = ismember(rel_list.dst{i}, {ont.term.id});
      valid = found_src & found_dst;

      % appending
      src = [src; index_src(valid)];
      dst = [dst; index_dst(valid)];
      ind = [ind; rel_count * ones(sum(valid), 1)];
    end
  end
  ont.DAG = sparse(src, dst, ind, n, n);
return
% }}}

% -------------
% Yuxiang Jiang (yuxjiang@indiana.edu)
% Department of Computer Science
% Indiana University, Bloomington
% Last modified: Fri 04 Mar 2016 12:32:08 PM E
