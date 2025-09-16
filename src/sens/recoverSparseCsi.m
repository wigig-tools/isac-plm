function csi = recoverSparseCsi(csi, sensParams)
% RECOVERSPARSECSI Recover uniformly sampled CSI from sparse/jittery bursts
%   CSI = RECOVERSPARSECSI(CSI, SENSPARAMS) reconstructs a uniformly sampled
%   cell array of channel measurements when the acquisition is irregular in
%   time and potentially lossy. The function uses the burst layout encoded in
%   SENSPARAMS.networkTiming and interpolates each delay bin (fast time) across
%   slow time for every angle column to a per-burst uniform grid defined by
%   SENSPARAMS.pri and SENSPARAMS.pulsesCpi. When SENSPARAMS.sparseCsi == 0,
%   the input CSI is returned unchanged.
%
%   Inputs
%   ------
%   CSI            1xT cell array. Each cell CSI{t} is an Ndelay-by-Nangle
%                  complex matrix (delay/fast-time by angle/beam) measured at
%                  time index t.
%
%   SENSPARAMS     Struct with required fields:
%     .sparseCsi             Logical flag. If true, perform recovery; if false,
%                            return CSI as provided.
%     .networkTiming         N x 5 numeric array describing measurements.
%                            Column 1: timestamps in nanoseconds.
%                            Column 5: burst identifier in {1,...,B}.
%                            (Other columns are ignored here.)
%     .pulsesCpi             Positive integer. Number of pulses (slow-time
%                            samples) per burst/CPI.
%     .pri                   Pulse Repetition Interval in seconds.
%     .clutterRemovalMethod  String or char. Method name passed to
%                            CLOUTTERREMOVAL for per-angle slow-time
%                            detrending/clutter suppression.
%
%   Output
%   ------
%   CSI            1x(B*P) cell array, where B = max(networkTiming(:,5)) and
%                  P = SENSPARAMS.pulsesCpi. Each cell is an Ndelay-by-Nangle
%                  complex matrix resampled on a uniform per-burst slow-time grid.
%
%   * Time unit expectations: networkTiming(:,1) in nanoseconds; PRI in seconds.
%
%   2025 NIST/CTL Steve Blandino
%   This file is available under the terms of the NIST License.

if ~sensParams.sparseCsi

else
    lenCsi = length(csi);
    fastTimeLen = size(csi{1},1);
    angleLen = size(csi{1},2);
    Hmat = reshape(squeeze(cell2mat(csi.')),fastTimeLen, lenCsi,angleLen);
    numBurst = max(sensParams.networkTiming(:,5));
    expectedCsiSize = numBurst*sensParams.pulsesCpi;
    expectedTimingBurst = 0:sensParams.pri:sensParams.pri*(sensParams.pulsesCpi-1);
    networkTiming = sensParams.networkTiming(:,1)*1e-9;
    for bID = 1:numBurst
        interBi(bID,1) = min(sensParams.networkTiming(sensParams.networkTiming(:,5) == bID,1))*1e-9;
    end

    expectedTiming = reshape((repmat(expectedTimingBurst, numBurst,1)+ interBi)', [],1);

    [~,keep] = unique(networkTiming);
    sensParams.networkTiming = sensParams.networkTiming(keep,:);
    HmatInterp = zeros(fastTimeLen, expectedCsiSize, angleLen);
    HmatInterpSmooth = zeros(fastTimeLen, expectedCsiSize, angleLen);

    Hmat = Hmat(:,keep,:);
    % Interpolate each delay bin across time
    t_sinc = -5*sensParams.pri:sensParams.pri/10:5*sensParams.pri; % Windowed sinc support
    sinc_kernel = sinc(t_sinc / sensParams.pri); % Nor
    for a = 1:angleLen
                csiNoClutter = clutterRemoval(Hmat(:,:,a), sensParams.clutterRemovalMethod);

        for d = 1:fastTimeLen
            HmatInterpBID = zeros(sensParams.pulsesCpi,numBurst);
            for bID = 1:numBurst
                cirID = sensParams.networkTiming(:,5) == bID;
                networkTimingBID = sensParams.networkTiming(cirID,1)*1e-9;
                hBID = squeeze(csiNoClutter(d, cirID));
                expectedTimingBID = expectedTiming((bID-1)*sensParams.pulsesCpi+1 :bID*sensParams.pulsesCpi);
                HmatInterpBID(:,bID) = interp1(networkTimingBID, hBID, expectedTimingBID , 'linear', 'extrap');
            end


            HmatInterp(d, :,a) = HmatInterpBID(:);
            HmatInterpSmooth(d, :,a) = conv(HmatInterp(d, :,a), sinc_kernel, 'same');
        end
    end


   
    for i = 1:expectedCsiSize
        csi{i} = squeeze(HmatInterp(:,i,:));
    end

end
