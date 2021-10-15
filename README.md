# IEEE 802.11ay EDMG Physical Layer Model
> Physical layer (PHY) model of IEEE 802.11ay enhanced directional multi-gigabit (EDMG) Wireless local access network (WLAN).

<img src="docs/img/results.jpg" alt="drawing">


## Table of Contents
* [Features](#features)
* [Installation](#installation)
* [Requirements](#requirements)
* [How to Run](#how-to-run)
* [Folder Structure](#folder-structure)
* [Code Structure](#code-structure)
* [Scenario definition](#scenario-definition)
* [Contributing](#contributing)
* [Authors](#authors)
* [License](#license)

## Features
* IEEE 802.11ay Single Carrier/OFDM waveform generation.
* IEEE 802.11ay spatial multiplexing schemes: SU-SISO, SU-MIMO, MU-MIMO.
* Perform link-level bit error rate (BER), packet error rate (PER), data rate tests and analytical link-level spectral efficiency (SE) bound.
* Receiver algorithms: synchronization, channel estimation, carrier frequency offset (CFO) correction.

## Installation
The software does not require any installation procedure: simply download or clone the repository to your local folders.

### Requirements
The codebase is written in MATLAB. It is currently being tested on MATLAB R2021b.

It requires the [MATLAB WLAN toolbox](https://www.mathworks.com/products/wlan.html).

## Folder Structure
The MATLAB code is collected in the following folders:
* Root folder
	- `edmg-phy-model`: repository folder.
        - `example`: example folder.
        - `license`: license folder.
        - `src`: source code folder.
            - `channel`: tapped delay line (TDL) channel functions.
                - `+nist`: MathWorks authored codes revised by NIST.
            - `config`: configuration functions.
            - `ext`: external code files.
            - `phy`: link-level simulations functions.
                - `+nist`: MathWorks authored codes revised by NIST.
            - `tools`: supporting functions.
        - `results`: results folder (auto-generated).
            - `LLS_results`: BER, PER and data rate results of link-level simulation.
            - `LLA_results`: SE results of link-level analysis.


## Code Structure
The IEEE 802.11ay EDMG PHY Model uses the following major files:
* The script `main.m` to launch the simulation.
* The function `runPHYErrorRateDataRate.m` runs the link-level simulation to obtain BER, PER and data rate in the individual-user and average-user cases, respectively;
* The function `runPHYSpectralEfficiency.m` runs the link-level analysis to obtain ergodic SE in the individual-user, average-user and sum-user cases, respectively.
* The function `edmgTx.m` generates the IEEE 802.11ay transmit waveform.
* The function `edmgRxIdeal.m` implements the idea receiver processing with perfect channel estimation and synchronization.
* The function `edmgRxFull.m` implements the idea receiver processing with imperfect channel estimation and synchronization with CFO.

## How to Run
* Open the `main.m` script and edit the variable `scenarioNameStr` with the scenario folder name `scenarioFolder` inside the folder `.\example`
* The software is configured to run the `muMimoOfdm_data` scenario by default.
* Run the `main.m` script
* To create and run a custom simulation, please refer to [scenario definition](#scenario-definition).

## Scenario Definition
To execute the IEEE 802.11ay EDMG PHY Model, the input must be properly defined in the folder `.\example\scenarioFolder\Input`. The configuration is broken down into three main components: simulation, PHY and channel.

* [Simulation configuration](#simulation-configuration): The simulation configuration aims at selecting the properties of the simulation that the users want to analyze and chose the operation mode of the simulator.
* [PHY configuration](#phy-configuration): The PHY configuration defines the properties of the PHY and the algorithms the PHY uses in simulation.
* [Channel configuration](#channel-configuration): The channel configuration specifies the property of the channel over which the packets are transmitted.

Each of this object is defined in an input configuration file.
The configuration is loaded making sure that the loaded parameters are meaningful by comparing them with a predefined expected range. In case some parameter is missing, default values are assumed.

### Simulation Configuration
The file `configSimulation.txt` may contain the following fields:
1. `debugFlag`: define the software operating mode.  
0 for simulation,1 for `debugging`, 2 for testing. If the field is not defined `debugFlag` is set to 0.

1. `pktFormatFlag`: select the packet format.  
0 for PPDU format (header + data),1 for PSDU format (data-field only). Using the PPDU format the receiver does not use any channel knowledge to operate but it retrieves the information needed from the header processing. If the field is not defined `pktFormatFlag` is set to 1 and the channel is perfectly known at both transmitter and receiver.

1. `chanModel`: select the channel model over which the packets are transmitted.  
If this field is not defined `chanModel` is set to `Rayleigh`.
	1. `AWGN` for AWGN channel
	1. `Rayleigh` for Random multi-path Rayleigh fading channel
	1. `MatlabTGay` for MATLAB TGay channel	(SU-MIMO is supported up to total 4 spatial streams. MU-MIMO is not supported. Function is to be checked due to the version issue.)
	1. `NIST` for NIST Quasi-Deterministic (Q-D) 60GHz channel (Additional dataset required from NIST.)

1. `dopplerFlag`: doppler flag.  
0: Doppler off (block fading). 1: Doppler ON. (Default = 0)

1. `snrMode`: SNR definition.  
Ratio of symbol energy to noise power spectral density `EsNo`, Ratio of bit energy to noise power spectral density `EbNo`, Signal-to-noise ratio (SNR) per sample `SNR`. (Default value: `EsNo`)

1. `snrAntNormFlag`: SNR Rx antenna normalization flag.   
0: AllAnt. 1: PerAnt (Default 0)

1. `snrRange`: Simulation SNR range in dB.  
Define the SNR range in dB specified as a 1-by-2  vector of scalar. (Default [0 20])

1. `snrStep`: Define the SNR step in dB specified as a positive scalar.  
The simulation SNR points are generated in the range `snrRange` with a step of `snrStep`, i.e. `snrRange(1):snrStep:snrRange(2)`. (Default 1)

1. `maxNumErrors`: Maximum number of error specified as a positive integer. (Default = 100)

1. `maxNumPackets`: Maximum number of packets specified as positive integer. (Default = 1000)

### PHY Configuration
The file `phyConfig.txt` may contain the following fields:
1. `phyMode` PHY mode.  
`phyMode` is specified as `OFDM` or `SC`. (Default `OFDM`)

1. `lenPsduByt`: Length of PSDU.  
`lenPsduByt` is in byte specifies as positive scalar. (Default = 4096)

1. `giType` : Guard interval length.  
`giType` is specified as `Short`, `Normal` or `Long`.

1. `numSTSVec`: Number of spatial-time streams.  
`numSTSVec` specified as 1-by-STAs vector of positive integers in the range 1-8 such that `sum(numSTSVec)<=8`. (Default = 1)

1. `smTypeNDP`: Spatial mapping type for non-data packet (preamble only, non data-field of PPSU).  
`smTypeNDP` specified as `Hadamard`, `Fourier`, `Custom` or `Direct`. (Default is `Direct`)

1. `smTypeDP`: Spatial mapping type for data packet (PSDU, data-field of PPSU).  
`smTypeDP` specified as `Hadamard`, `Fourier`, `Custom` or `Direct`. (Default is `Direct`)

1. `mcs`: Modulation and coding scheme (MCS) Index.  
`mcs` is specified as index in the range 1-20 (21 for SC). (Default = 6).

1. `analogBeamforming`: Analog beamforming scheme.  
`analogBeamforming` specified as `maxAllUserCapacity`, `maxMinAllUserSV`, `maxMinPerUserCapacity`, `maxMinMinPerUserSV`, respectively. (Default is `maxAllUserCapacity`)
This value is used if `chanModel` in `simulationConfig.txt` is specified as NIST. Application of analog beamforming is performed with an external MATLAB application, not included in this release.

1. `dynamicBeamNumber`: Dynamic stream allocation.  
`dynamicBeamNumber` selects only the streams among `numSTSVec` with high SINR. `dynamicBeamNumber` is specified as a scalar between 0-20 indicating the condition number of a SU-MIMO matrix. This value is used if chanModel in `simulationConfig.txt` is specified as NIST. (0: OFF) (Default 0).Dynamic stream allocation is based on the analog channel state information and it is performed with an external MATLAB application, not included in this release.

1. `processFlag`: transceiver digital processing flag.
`processFlag` selects specific MIMO signal processing for OFDM/SC mode transmitter and receiver. `processFlag` is specified as a scalar between 0-5 (Default 0).
	- For the transmitter processing,
		- `processFlag = 0`, supports both OFDM and SC SISO and SU-MIMO without transmitter precoding.
		- `processFlag = 1`, OFDM supports SU- and MU-MIMO with frequency-domain precoding based on regularized zero-forcing (RZF) criteria; SC supports SU-MIMO with time-domain one-tap precoding based on RZF criteria.
		- `processFlag = 2`, OFDM supports SU-MIMO with frequency-domain precoding based on based on SVD and RZF filtering; SC supports SU-MIMO with time-domain one-tap precoding based on SVD and RZF filtering.
		- `processFlag = 3`, OFDM supports MU-MIMO with frequency-domain precoding based on based on SVD and RZF filtering; SC supports SU-MIMO with time-domain one-tap precoding based on SVD and RZF filtering.
		- `processFlag = 4`, OFDM supports SU- and MU-MIMO with frequency-domain precoding based on based on block diagonalization and ZF filtering (BD=ZF); SC supports SU-MIMO with time-domain one-tap precoding based on BD-ZF.
		- `processFlag = 5`, SC supports MU-MIMO with time-domain multi-tap precoding with ZF.
	- For the receiver processing, all `processFlag = 0~5` support OFDM/SC joint frequency-domain equalization and MIMO detection based on linear minimum mean squared error (MMSE) criteria.


1. `symbOffset`: Symbol sampling offset.  
`symbOffset` is specified as values from 0 to 1. When `symbOffset` is 0, no offset is applied. When `symbOffset` is 1 an offset equal to the GI length is applied. (Default 0.75)

1. `softCsiFlag`: Demodulation with soft channel state information flag.
`softCsiFlag` is specified as 0 for inactivated or 1 for activated. (Default 1 for OFDM and 0 for SC)  

1. `ldpcDecMethod`: LDPC decoding method.
`ldpcDecMethod` is specified as `norm-min-sum` or `bp`, respectively.  (Default `norm-min-sum`)

### Channel Configuration
The IEEE 802.11ay EDMG PHY Model supports several channel models over which the user can evaluate the PHY performance.
The channel model is configured with a dedicated configuration file, which is different for each of the channel model supported, since each model has its own features and set of parameters.

#### Multi-Tap Rayleigh Channel
The file `channelRayleighConfig.txt` may contain the following fields:
1. `numTaps`: Number of taps.  
Number of taps specified as a positive integer. If the field is not defined `numTaps` is set to 10.

1. `maxMimoArrivalDelay`: Sample of maximum offset in the multiple-input multiple-output (MIMO) channel impulse response (CIR).  
`maxMimoArrivalDelay` defines the maximum sample offset of each single-input single-output (SISO) component.
The actual delay is randomly selected between 0 and `maxMimoArrivalDelay`.
If the field is not defined `maxMimoArrivalDelay` is set to 0.

1. `pdpMethodStr`: Power delay profile for tapped-delay line (TDL) channel model.  
`pdpMethodStr` is specified as `PS`, `Equ` or `Exp`, using phase shift, equal power or exponential power, respectively.

1. `tdlTypeChannel` Interpolation Method of CIR.  
`tdlTypeChannel` is specified as `Impulse` or `Sinc`.(Default `Impulse`)

#### NIST QD Channel
The IEEE 802.11ay EDMG PHY Model provides a set of system level channels in `FOLDERNAME`.
They represent several environments for different PAA models and analog beamforming schemes.
The file `channelNistConfig.txt` loading one of the predefined channel, may contain the following fields:

1. `environmentFileNamechannel` Environment.   
`environmentFileNamechannel` is specified as `LR` for lecture room, `OAH` for open area hotspot or `SC` for street canyon.
If the field is not defined `environmentFileName` is set to `LR`.

1. `totalNumberOfReflections`: Reflection order.  
`totalNumberOfReflections` is specified as a positive integer. If the field is not defined `totalNumberOfReflections` is set to 2.

1. `tdlTypeChannel` Interpolation Method OF TDL CIR filtering.  
`tdlTypeChannel` is specified as `Impulse` or `Sinc`.

Moreover, the antenna model can be configured for each node in the system thanks to the file `paaConfigNodeX.txt` where `X`
 represents the node index from 0.
`paaConfigNodeX.txt` may contain the following fields:

1. `numAntenna`: Total number of antenna element in the node.  
`numAntenna` is specified as a positive integer. If the field is not defined `numAntenna` is set to 16.

1. `Geometry`: Geometry of the antenna array.   
`Geometry` is specified as `UniformLinear` or `UniformRectangular`.

1. `numAntennaVert`: Total number of antenna element in the vertical direction.  
`numAntennaVert` is specified as a positive integer. If the field is not defined `numAntennaVert` is set to 4.

## Example Provided

The following Table describes the predefined examples scenarios and the main configuration parameters. 
These predefined scenarios are given as examples in `/src/examples/`. Each scenario contains a configuration input folder.


| Example      | Number of Rx | Streams/rx | Channel Model | Precoder | Equalizer | Processing Flag | Packet 	   |
| :---         |     :---:    |   :---:    | :---: 		   |:---:     | :---:     | :---:           | :---: 	   |
| sisoOfdmAwgn_data  | 1			  | 	1	   | AWGN 	   | - 		  | MMSE 	  | 0				|	PSDU  	   |
| sisoSc_data  | 1			  | 	1	   | Rayleigh 	   | - 		  | MMSE 	  | 0				|	PSDU  	   |
| sisoOfdm_data| 1            | 	1	   | Rayleigh 	   | - 		  | MMSE 	  | 0				|   PSDU 	   |
| sisoSc	   | 1			  | 	1	   | Rayleigh 	   | - 		  | MMSE 	  | 0				|	PPDU  	   |
| sisoOfdm     | 1            | 	1	   | Rayleigh 	   | - 		  | MMSE 	  | 0				|   PPDU 	   |
| mimoSc_data  | 1			  | 	2	   | Rayleigh 	   | RZF (Freq flat)	  | MMSE 	  | 1				|	PSDU  	   |
| mimoOfdm_data| 1            | 	2	   | Rayleigh 	   | RZF (Freq sel) 		  | MMSE 	  | 1				|   PSDU 	   |
| mimoSc	   | 1			  | 	2	   | Rayleigh 	   | RZF (Freq flat) 		  | MMSE 	  | 1				|	PPDU  	   |
| mimoOfdm     | 1            | 	2	   | Rayleigh 	   | RZF (Freq sel) 		  | MMSE 	  | 1			|   PPDU 	   |
| muMimoSc_data   | 2            | 	2	   | Rayleigh 	   | ZF (Time domain) 		  | MMSE 	  | 5				|   PSDU 	   |
| muMimoOfdm_data   | 2            | 	2	   | Rayleigh 	   | RZF (Freq sel) 		  | MMSE 	  | 1				|   PSDU 	   |
| muMimoOfdm   | 2            | 	2	   | Rayleigh 	   | RZF (Freq sel) 		  | MMSE 	  | 1				|   PPDU 	   |





## Results Generation

### Folder and Saving Path
The software automatically creates an `results` folder under the project folder (`edmg-phy-model`) in order to store all result-related files.
1. The sub-folder `LLS_results` contains one nested result folder per link-level simulation including the BER, PER and data rate results generated from `runPHYErrorRateDataRate.m`.
1. The sub-folder `LLA_results` contains one nested result folder per link-level analysis including the SE results generated from `runPHYSpectralEfficiency.m`.
The results are stored into unique time-stamped folders.

Moreover, the results  obtained in the last execution of a scenario defined in `/src/examples/` are also stored in the `output` folder of the scenario.

### Files and Parameters
When simulation completed, the software saves the parameters into the above-mentioned nested result folder, whose file name is based on simulation parameters.
The key configuration parameters and result data  are saved in file with `ws_*.mat` formats, while the plotted figures are saved in `*.fig` formats.
The parameters and results  are hosted in the struct variables as below:

1. `simuParams`: Simulation configuration
1. `phyParams`: PHY configuration
1. `channelParams`: Channel configuration
1. `results`: results struct includes members:
	- `berAvgUser`, `perAvgUser`, `gbitRateAvgUser`: average BER, PER, Gigabit data rate of all users (STAs)
	- `berIndiUser`, `perIndiUser`, `gbitRateIndiUser`: individual BER, PER, Gigabit data rate of each user (STA)
	- `gbitRateSumUser`: sum Gigabit data rate of all users
	- `ergoSEAvgUser`: average ergodic SE of all users
	- `ergoSEIndiUser`: individual ergodic SE of each user
	- `ergoSESumUser`: sum ergodic SE of all users


## Contributing
Feedbacks and additions are more than welcomed! You can directly contact the [authors](#Authors) for any information.


## Authors

[![NIST picture](https://github.com/usnistgov.png?size=100)](https://github.com/usnistgov)

The EDMG-PHY-Model software has been developed at NIST by Jiayi Zhang(jiayi.zhang@ieee.org), [Steve Blandino](https://www.linkedin.com/in/steve-blandino) (steve.blandino@nist.gov), [Neeraj Varshney](https://www.nist.gov/people/neeraj-varshney) (neeraj.varshney@nist.gov) and [Jian Wang](https://www.nist.gov/people/jian-wang) (jian.wang@nist.gov).



## License
Please refer to the [NIST-License.txt](license/NIST-License.txt) and [MathWorks-Limited-License.txt](license/MathWorks-Limited-License.txt) files in the `license` folder for more information.
