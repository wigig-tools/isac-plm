# Integrated Sensing and Communication Physical Layer Model (ISAC-PLM)
> Integrated Sensing and Communication Physical layer (PHY) model of IEEE 802.11ay enhanced directional multi-gigabit (EDMG) Wireless local access network (WLAN).
<p align="center">
<img src="docs/gif/isac.gif" alt="drawing">
</p>
<p align="center">
<img src="docs/img/results.jpg" alt="drawing">
</p>


## Table of Contents
* [Features](#features)
* [Installation](#installation)
* [Requirements](#requirements)
* [How to Run](#how-to-run)
    * [Documentation](#documentation)
* [Examples Provided](#examples-provided)
* [Published Work](#published-work)
* [Contributing](#contributing)
* [Authors](#authors)
* [License](#license)

## Features
* IEEE 802.11ay Single Carrier/OFDM waveform generation.
* IEEE 802.11ay spatial multiplexing schemes: SU-SISO, SU-MIMO, MU-MIMO.
* Perform link-level bit error rate (BER), packet error rate (PER), data rate tests and analytical link-level spectral efficiency (SE) bound.
* Receiver algorithms: synchronization, channel estimation, carrier frequency offset (CFO) correction.
* Passive sensing using IEEE 802.11ay preamble.
* Active sensing using IEEE 802.11bf multi-static PPDU.
* Sensing signal processing algorithms: clutter removal, doppler processing, target detection, range and velocity estimation.
* Sensing accuracy analysis in terms of Mean Squared Error (MSE) and Normalized Mean Squared Error (NMSE).

## Installation
The software does not require any installation procedure: simply download or clone the repository to your local folders.

## Requirements
The codebase is written in MATLAB. It is currently being tested on MATLAB R2021b.

It requires the [MATLAB WLAN toolbox](https://www.mathworks.com/products/wlan.html).

## How to Run
* Open `main.m` script and edit the variable `scenarioNameStr` with the scenario folder name `scenarioFolder` inside the folder `.\example`
* Run `main.m` 

### Documentation
More details about ISAC-PLM can be found in the documentation ([docs/isac-plm.pdf](docs/isac-plm.pdf)).

## Examples Provided

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
| pointTargetPassiveSensing   | 1            | 	1	   | NIST QD 	   | - 		  | MMSE 	  |  0				|   PPDU 	   |
| singleHumanTarget   | 1            | 	1	   | NIST QD 	   | - 		  | MMSE 	  |  0				|   PPDU 	   |
| pointTargetActiveSensing   | 1            | 	1	   | NIST QD 	   | - 		  | -	  |  -				|   TRN-R	   |
| bistaticLivingRoomTRN-R| 1            | 	1	   | NIST QD 	   | - 		  | -	  |  -				|   TRN-R	   |
| bistaticLivingRoomTRN-T| 1            | 	1	   | NIST QD 	   | - 		  | -	  |  -				|   TRN-T	   |
| thresholdSensing	| 1            | 	1	   | NIST QD 	   | - 		  | MMSE 	  |  0				|   PPDU 	   |

## Published Work

- J. Zhang, S. Blandino, N. Varshney, J. Wang, C. Gentile and N. Golmie, [Multi-User MIMO Enabled Virtual Reality in IEEE 802.11ay WLAN](https://ieeexplore.ieee.org/document/9771778), 2022 IEEE Wireless Communication and Networking Conference.
- S. Blandino, T.Ropitault, A. Sahoo and N. Golmie, [Tools, Models and Dataset for IEEE 802.11ay
 CSI-based Sensing](https://ieeexplore.ieee.org/document/9771569), 2022 IEEE Wireless Communication and Networking Conference.

## IEEE 802.11bf contributions

- [DMG/EDMG Link Level Simulation Platform](https://mentor.ieee.org/802.11/dcn/22/11-22-0803-00-00bf-dmg-edmg-link-level-simulation-platform.pptx)
- [Implementation of 60 GHz WLAN-SENS Physical Layer Model](https://mentor.ieee.org/802.11/dcn/22/11-22-1217-01-00bf-implementation-of-60-ghz-wlan-sens-physical-layer-model.docx)
- [Channel Models for WLAN Sensing Systems](https://mentor.ieee.org/802.11/dcn/21/11-21-0782-05-00bf-channel-models-for-wlan-sensing-systems.docx)
- [11bf Evaluation Methodology and Simulation Scenarios](https://mentor.ieee.org/802.11/dcn/21/11-21-0876-05-00bf-11bf-evaluation-methodology-and-simulation-scenarios.doc)

## Contributing
Feedbacks and additions are more than welcomed! You can directly contact the [authors](#Authors) for any information.


## Authors

[![NIST picture](https://github.com/usnistgov.png?size=100)](https://github.com/usnistgov)

ISAC-PLM has been developed at NIST by [Steve Blandino](https://www.nist.gov/people/steve-blandino) (steve.blandino@nist.gov), [Neeraj Varshney](https://www.nist.gov/people/neeraj-varshney) (neeraj.varshney@nist.gov) and [Jian Wang](https://www.nist.gov/people/jian-wang) (jian.wang@nist.gov), Jiayi Zhang(jiayi.zhang@ieee.org).



## License
Please refer to the [NIST-License.txt](license/NIST-License.txt) and [MathWorks-Limited-License.txt](license/MathWorks-Limited-License.txt) files in the `license` folder for more information.
