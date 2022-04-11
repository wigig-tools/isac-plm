function [pktErrNdp,  estCIRNdp, estCFRNdp, estNoiseVarNdp] = ...
    getCsit(channel, channelParams, simParams, phyParams)
%%GETCSIT Channel state information at the tranmsitter.
%
% [Err, CIR, CFR, noiseVar] = GETCSIT(H, C, S, P) returns the channel state
% information used at the transmitter given the channel H and C, S , P, 
% i.e.,the channel, simulation and PHY structures. If the packet is lost,
% Err = 1. CFR and CIR indicate the channel frequency resmponse and the
% time channel response respectively. GETCSIT returns also the estimated
% noise

awgnChannel =[];

switch simParams.csit
    
    case 'estimated'
        % Sounding at Transmitter
        txNdpSigSeq = edmgTxMimo(phyParams.cfgNDP,simParams,phyParams.precNormFlag);
        
        % Sounding over multi-path fading channel
        rxNdpSigSeq = getReceivedPilots(txNdpSigSeq,channel.tdMimoChan,...
            phyParams,simParams, channelParams,simParams.noise.varLinActSubc,awgnChannel);
        
        % Estimate CSIT
        spatialMapMat = [];
        svdChan = [];
        
        if simParams.chanFlag > 0
            [pktErrNdp,  estCIRNdp, estCFRNdp, estNoiseVarNdp] = estimateCsit(rxNdpSigSeq, phyParams);
            
%             if any(cell2mat(pktErrNdp))
%                 numPacketErrors = numPacketErrors+1;
%                 numPkt(iSNR) = numPkt(iSNR)+1;
%                                 continue; % Go to next loop iteration
%             end
            
            % Get Precoding Matrix
%             [spatialMapMat,svdChan,powAlloMat,precScaleFactor] = edmgTxMIMOPrecoder(estCIRNdp,estCFRNdp,estNoiseVarNdp,phyParams.cfgEDMG,cfgSim);
        end
        
        % Update Spatial matrix
%         phyParams = updateSpatialMatrix(phyParams,spatialMapMat,svdChan,powAlloMat,precScaleFactor);
        
    otherwise
        % Perfect noise estimation
        estNoiseVarNdp = cell(phyParams.numUsers,1);
        for iUser = 1:phyParams.numUsers
            estNoiseVarNdp{iUser} = simParams.noise.varLinTotSubc*ones(1,phyParams.numSTSVec(iUser));
        end
        pktErrNdp{1} = 0;
        estCIRNdp = channel.tdMimoChan;
        estCFRNdp = channel.fdMimoChan;

%         % Get Precoding Matrix
%         [spatialMapMat,svdChan,powAlloMat,precScaleFactor] = edmgTxMIMOPrecoder(tdMimoChan,fdMimoChan,estNoiseVarNdp,phyParams.cfgEDMG,cfgSim);
%         
%         % Update Spatial matrix
%         phyParams = updateSpatialMatrix(phyParams,spatialMapMat,svdChan,powAlloMat,precScaleFactor);
        
%     otherwise
%         % Reset Precoding Matrix
%         pktErrNdp{1} = 0;
%         spatialMapMat = eye(phyParams.numSTSTot,phyParams.numTxAnt);
%         svdChan = [];
%         powAlloMat = [];
%         precScaleFactor = 1;
%         phyParams = updateSpatialMatrix(phyParams,spatialMapMat,svdChan,powAlloMat,precScaleFactor);
end

end