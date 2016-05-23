function [] = cafa_hist_oa_count(pfile, pttl, bm, oa, propagated)
%CAFA_HIST_OA_COUNT CAFA histogram ontology annotation count
%
% [] = CAFA_HIST_OA_COUNT(pfile, pttl, bm, oa);
% [] = CAFA_HIST_OA_COUNT(pfile, pttl, bm, oa, propagated);
%
%   Plots histogram of (propagated, or leaf) annotation counts.
%
% Input
% -----
% [char]
% pfile:      The filename of the plot.
%             Note that the file extension must be either '.eps' or '.png'
%
% [char]
% pttl:       The plot title.
%
% [char or cell]
% bm:         A benchmark filename or a list of benchmark target IDs.
%
% [struct]
% oa:         The ontology annotation structure. See pfp_oabuild.m.
%
% (optional)
% [logical]
% propagated: Plot propagated annotation of just leaf annotations.
%             default: true
%
% Output
% ------
% None.
%
% Dependency
% ----------
%[>]pfp_loaditem.m
%[>]pfp_oaproj.m
%[>]pfp_leafannot.m
%[>]embed_canvas.m
%
% See Also
% --------
%[>]pfp_oabuild.m

  % check inputs {{{
  if nargin ~= 4 && nargin ~= 5
    error('cafa_hist_oa_count:InputCount', 'Expected 4 or 5 inputs.');
  end

  if nargin == 4
    propagated = true;
  end

  % pfile
  validateattributes(pfile, {'char'}, {'nonempty'}, '', 'pfile', 1);
  [p, f, e] = fileparts(pfile);
  if isempty(e)
    e = '.png';
  end
  ext = validatestring(e, {'.eps', '.png'}, '', 'pfile', 1);
  if strcmp(ext, '.eps')
    device_op = '-depsc';
  elseif strcmp(ext, '.png')
    device_op = '-dpng';
  end

  % pttl
  validateattributes(pttl, {'char'}, {}, '', 'pttl', 2);

  % bm
  validateattributes(bm, {'char', 'cell'}, {'nonempty'}, '', 'bm', 3);
  if ischar(bm) % load the benchmark if a file name is given
    bm = pfp_loaditem(bm, 'char');
  end

  % oa
  validateattributes(oa, {'struct'}, {'nonempty'}, '', 'oa', 4);

  % propagated
  validateattributes(propagated, {'logical'}, {}, '', 'propagated', 5);
  % }}}

  % get statistics {{{
  oa = pfp_oaproj(oa, bm, 'object');

  if propagated
    counts = sum(oa.annotation, 2);
  else
    counts = sum(pfp_leafannot(oa), 2);
  end
  % }}}

  % plotting {{{
  h = figure('Visible', 'off');
  histogram(counts);
  if propagated
    xlabel('Number of (propagated) annotations');
  else
    xlabel('Number of (leaf) annotations');
  end

  ylabel('Number of proteins');
  title(pttl);

  embed_canvas(h, 5, 4);
  print(h, pfile, device_op, '-r300');
  close(h);
  % }}}
return

% -------------
% Yuxiang Jiang (yuxjiang@indiana.edu)
% Department of Computer Science
% Indiana University Bloomington
% Last modified: Mon 23 May 2016 05:50:54 PM E
