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
* Sensing signal processing algorithms: clutter removal, doppler processing, target detection, range and velocity estimation.
* Sensing accuracy analysis in terms of Mean Squared Error (MSE) and Normalized Mean Squared Error (NMSE).

## Installation
The software does not require any installation procedure: simply download or clone the repository to your local folders.

## Requirements
The codebase is written in MATLAB. It is currently being tested on MATLAB R2021b.

It requires the [MATLAB WLAN toolbox](https://www.mathworks.com/products/wlan.html).

## How to Run
* Open the `main.m` or `mainIsac.m` script and edit the variable `scenarioNameStr` with the scenario folder name `scenarioFolder` inside the folder `.\example`
* `main.m` is configured to run the `muMimoOfdm_data` scenario by default.
* `mainIsac.m` is configured to run the `pointTarget` scenario by default.
* Run `main.m` or `mainIsac.m`

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
| pointTarget   | 1            | 	1	   | NIST QD 	   | - 		  | MMSE 	  |  0				|   PPDU 	   |
| singleHumanTarget   | 1            | 	1	   | NIST QD 	   | - 		  | MMSE 	  |  0				|   PPDU 	   |

## Published Work

- J. Zhang, S. Blandino, N. Varshney, J. Wang, C. Gentile and N. Golmie, "Multi-User MIMO Enabled Virtual Reality in IEEE 802.11ay WLAN," 2022 IEEE Wireless Communication and Networking Conference.
- S. Blandino, T. Ropitault, A. Sahoo and N. Golmie, "Tools, Models and Dataset for IEEE 802.11ay
 CSI-based Sensing," 2022 IEEE Wireless Communication and Networking Conference.

## Contributing
Feedbacks and additions are more than welcomed! You can directly contact the [authors](#Authors) for any information.


## Authors

[![NIST picture](https://github.com/usnistgov.png?size=100)](https://github.com/usnistgov)

ISAC-PLM has been developed at NIST by Jiayi Zhang(jiayi.zhang@ieee.org), [Steve Blandino](https://www.linkedin.com/in/steve-blandino) (steve.blandino@nist.gov), [Neeraj Varshney](https://www.nist.gov/people/neeraj-varshney) (neeraj.varshney@nist.gov) and [Jian Wang](https://www.nist.gov/people/jian-wang) (jian.wang@nist.gov).



## License
Please refer to the [NIST-License.txt](license/NIST-License.txt) and [MathWorks-Limited-License.txt](license/MathWorks-Limited-License.txt) files in the `license` folder for more information.
