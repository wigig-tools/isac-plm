function normCSIVarValue = csiVariation(h, g, tau, scheme, phyParams)
%%CSIVARIATION calculates channel variation and normalizes between [0,1].
%
%   [NORMCSIVARVALUE] = CSIVARIATION(H, G, T, SCHEME, PHY) calculates channel 
%   variation using the CSI H and G at two time-instants. Return the 
%   normalized CSI variation value based on the SCHEME defined as 'EucDistance',
%   'TRRS', 'FRRS'.
%
%
%   2021-2022 NIST/CTL Neeraj Varshney (neeraj.varshney@nist.gov)

%   This file is available under the terms of the NIST License.

h = h(~isnan(h));
tau1 = tau(~isnan(h));
g = g(~isnan(g));
tau2 = tau(~isnan(g));
switch scheme
    
    case 'EucDistance'
        normCSIVarValue = sqrt(0.5 * var(h-g)/(var(h) + var(g)));
        
    case 'TRRS'
        g2 = conj(g(end:-1:1));
        normCSIVarValue = 1 - max(abs(conv(h,g2)))/(norm(h)*norm(g2));

    case 'FRRS'
        phyMode = phyParams.phyMode;
        centerFrequencyHz = phyParams.fc;
        if strcmp(phyMode,'SC')
            Nd = phyParams.scInfo.NTONES;               % Number of subcarriers
            numBands = Nd;
            bandBandwidth = 2.16e+9;
            CenterFrequencySubBand = centerFrequencyHz + ( (-round(numBands/2) +1 : floor(numBands/2)) * bandBandwidth/numBands) - bandBandwidth/(2*numBands); % Nd even
        elseif strcmp(phyMode,'OFDM')
            N = phyParams.ofdmInfo.NSD + phyParams.ofdmInfo.NSP;           % Total data and pilot subcarriers
            Ndc = phyParams.ofdmInfo.NDC;                % Number of DC subcarriers
            Nd = N + Ndc;
            numBands = Nd;
            subfreqSpacingHz = 5.15625 * 10^6;
            bandBandwidth = numBands * subfreqSpacingHz;
            CenterFrequencySubBand = centerFrequencyHz + ( (-round(numBands/2) +1 : floor(numBands/2)) * bandBandwidth/numBands);
        end
        for iSubband = 1:length(CenterFrequencySubBand)
            fc = CenterFrequencySubBand(iSubband);
            H(iSubband) = sum(h.*exp(-1i*2*pi*fc.*tau1));
            G(iSubband) = sum(g.*exp(-1i*2*pi*fc.*tau2));
        end
        cf = max((xcorr(H,G))/(norm(H)*norm(G)));
        normCSIVarValue = 1 - abs(cf);
        
end

end