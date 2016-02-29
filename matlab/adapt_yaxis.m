function [ylim, ts] = adapt_yaxis(olim, tlim, cts)
%ADAPT_YAXIS Adapt Y-axis
% {{{
%
% [ylim, ts] = ADAPT_YAXIS(olim, tlim, cts);
%
%   Makes an adaptive Y-axis ticks (YLim, tick step).
%
% Input
% -----
% [double]
% olim: observed [minimal, maximal]
%
% [double]
% tlim: theoretical [minimal, maximal]
%       E.g. [0, 1] if yaxis = AUC.
%
% [double]
% cts:  a vector of candidate tick steps
%
% Output
% ------
% [double]
% ylim: The [lower, upper] bound of y-axis.
%       'ylim' can be used to set 'axes.YLim'
%
% [double]
% ts:   The tick step.
% }}}

  % check inputs {{{
  if nargin ~= 3
    error('adapt_yaxis:InputCount', 'Expected 3 inputs.');
  end

  % check the 1st input 'olim' {{{
  validateattributes(olim, {'double'}, {'numel', 2}, '', 'olim', 1);
  % }}}

  % check the 2nd input 'tlim' {{{
  validateattributes(tlim, {'double'}, {'numel', 2}, '', 'tlim', 2);
  % }}}

  % check the 3th input 'cts' {{{
  validateattributes(cts, {'double'}, {'nonempty'}, '', 'cts', 3);
  % }}}
  % }}}

  % adaptation {{{
  mn = olim(1);
  mx = olim(2);
  MN = tlim(1);
  MX = tlim(2);

  cts = sort(cts, 'descend');
  m = numel(cts);
  % decide tick step
  range = mx - mn;
  for i = 1 : m
    ts = cts(i);
    if range < 2.5 * ts
      continue; % try the next (smaller) step
    end
    if range > 3.5 * ts
      % step cannot be smaller, i.e., found the best step
      if i > 1
        ts = cts(i - 1);
      end
      break;
    end
  end
  % }}}

  % output {{{
  ylim = [max(MN,(floor(mn/ts)-1)*ts), min(MX,(ceil((mx/ts)+0.5))*ts)];
  % }}}
return
% }}}

% -------------
% Yuxiang Jiang (yuxjiang@indiana.edu)
% Department of Computer Science
% Indiana University Bloomington
% Last modified: Fri 26 Feb 2016 02:06:48 AM E
