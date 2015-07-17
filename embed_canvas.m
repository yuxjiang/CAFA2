function [h] = embed_canvas(h, width, height)
%EMBED_CANVAS Embed canvas
% {{{
%
% [h] = EMBED_CANVAS(h, width, height);
%
%   Embed a figure (thru handle) into the center of a canvas.
%
% Input
% -----
% [handle]
% h:      Figure handle, returned from calling 'figure' or 'gcf'.
%
% [double]
% width:  Width of the canvas (in inches)
%
% [double]
% height: Height of the canvas (in inches)
%
% Output
% ------
% [handle]
% h:      The modified handle of the figure.
% }}}

  % check inputs {{{
  if nargin ~= 3
    error('embed_canvas:InputCount', 'Expected 3 inputs.');
  end

  % check the 1st input 'h' {{{
  validateattributes(h, {'handle'}, {'nonempty'}, '', 'h', 1);
  % }}}

  % check the 2nd input 'width' {{{
  validateattributes(width, {'double'}, {'positive'}, '', 'width', 2);
  % }}}

  % check the 3rd input 'height' {{{
  validateattributes(height, {'double'}, {'positive'}, '', 'height', 3);
  % }}}
  % }}}

  % change settings {{{
  h.PaperUnits = 'inches';
  left   = (h.PaperSize(1) - width) / 2;
  bottom = (h.PaperSize(2) - height) / 2;

  h.PaperPosition = [left, bottom, width, height];
  % }}}
return

% -------------
% Yuxiang Jiang (yuxjiang@indiana.edu)
% Department of Computer Science
% Indiana University, Bloomington
% Last modified: Tue 07 Jul 2015 02:59:22 PM E
