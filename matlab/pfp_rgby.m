function [r, g, b, y] = pfp_rgby
%PFP_RGBY (R)ed, (G)reen, (B)lue, (Y)ellow
%
% [r, g, b, y] = PFP_RGBY;
%
%   Returns the preferable 4 major colors.
%
% Input
% -----
% None.
%
% Output
% ------
% [double]
% r:  Red
%
% [double]
% g:  Green
%
% [double]
% b:  Blue
%
% [double]
% y:  Yellow

  % color definition {{{
  r = [.7686, .1882, .1686]; % [196,  48,  43] / 255;
  g = [.1255, .5020, .3137]; % [ 32, 128,  80] / 255;
  b = [.0000, .3255, .6235]; % [  0,  83, 159] / 255;
  y = [.9804, .5843, .0000]; % [250, 149,   0] / 255;
  % }}}
return

% -------------
% Yuxiang Jiang (yuxjiang@indiana.edu)
% Department of Computer Science
% Indiana University, Bloomington
% Last modified: Sun 22 May 2016 03:40:42 PM E
