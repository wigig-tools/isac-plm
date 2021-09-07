function H = PolyMatConv(F,G)
%H = PolyMatConv(F,G);
%
%   Returns the convolution of two MIMO system matrices F and G. This 
%   convolution operator is not commutative, and if representing 
%   polynomial matrices, F is left-multiplied onto G.
%
%   For all matrices F, G and H, the first two dimensions are spatial, 
%   and the third dimension is lag or time. If e.g. F is a polynomial 
%   matrix of the format
%      F(z) = F0 + F1 z^{-1} + F2 z^{-2} + ...
%   then
%      F(:,:,1) = F0;
%      F(:,:,2) = F1;
%      F(:,:,3) = F2;
%      ...
%   is the required representation for the input. The output is
%      H(z) = F(z)G(z)
%   with a format representation analogously to F(z) above.
%
%   Input parameters
%      F      K x M x L1 MIMO system matrix 
%             K   output dimension
%             M   input dimension
%             L1  length of FIR filters
%      G      M x N x L2 MIMO system matrix 
%             M   output dimension
%             N   input dimension
%             L2  length of FIR filters
%
%   Output parameters
%      H      K x N x (L1+L2-1) MIMO system matrix
   
% S Weiss, Univ of Southampton, 15/7/2004
  
[M1,N1,L1] = size(F);
[M2,N2,L2] = size(G);
if N1 ~= M2
  error('input matrix dimensions to function PolyMatConv() do not agree');
end
% Pre-allocate MIMO system matrix
H = zeros(M1,N2,L1+L2-1);

for m = 1:M1
  for n = 1:N2
    for k = 1:N1
      a = shiftdim(F(m,k,:),1);
      b = shiftdim(G(k,n,:),1);
      c(1,:,1) = conv(a,b);
      H(m,n,:) = H(m,n,:) + shiftdim(c,-1);
    end
  end
end

