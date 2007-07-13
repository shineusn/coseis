% Print file to EPS and convert to PDF
function printpdf( varargin )
crop = 1;
file = 'fig';
if nargin > 0, file = varargin{1}; end
if nargin > 1, crop = 0; end
set( gcf, 'InvertHardCopy', 'off' )
print( '-depsc', file )
movefile( [ file '.eps' ], 'tmp.eps' )
if crop
  !sed 's|/DA { \[6|/DA { \[1|' tmp.eps | ps2pdf14 -dPDFSETTINGS=/prepress -dEPSCrop - tmp.pdf
else
  !sed 's|/DA { \[6|/DA { \[1|' tmp.eps | ps2pdf14 -dPDFSETTINGS=/prepress - tmp.pdf
end
movefile( 'tmp.pdf', [ file '.pdf' ] )
delete( 'tmp.eps' )
