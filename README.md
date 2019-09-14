# A simple and incomplete Matlab implementation of ITU-T P.1203

Runs with R2016a or later (because of movmean). 
Partly implements a p1203 recommendation with a few 
slight violations (for the moment), with all its helper functions - like random forest handling. 
Also provides a script to provide input to the QoE model by simulating a video transmission with 
normally distributed video chunk sizes and bandwidth samples, and a "player" that implements
RBA and BBA-0 quality adaptation.

It will also allow you to input your own bandwidth traces and videos (in a form of chunk size series) once I manage to spend half an hour implementing that :)



## How to use and what does it do?

**First**, it's important to read and at least slightly understand the recommendation in question. This code is made for personal use, so it's not trying to be an all-purpose ready-to-go solution :) Some features - like the entire audio component and most of video component modes - are not implemented for now, so you might want to get your hands dirty writing them on your own.



**Second**, the model needs a pre-calculated table to convert R values to MOS. A sample table is already included here, and the following function generates a new one with a resolution of your choice:

```
make_lookup_table(pitch) 
	where:
		pitch:	defines the table resolution. Take care, as
				MOS values in the tables MUST be unique, and having
				too much resolution might violate this (seems to be
				an issue of the recommendation itself)
```

**Finally**, ```run_batch.m``` runs a series of evaluations for a fake video  with different "connectivity" bandwidth values (that are constant during the session), and saves the results in a .mat file:

```
run_batch(algo, max_bw, step)
	where:
		algo:	1 - RBA (EWMA), 2 - BBA
		max_bw:	max bitrate to estimate QoE for, in Mbps
		step:	sampling step (in Mbps) 
```
		
The result file includes, most importantly, the tested bandwidths and their corresponding resulting QoE values, in a form of vectors. It also provides a piecewise-linear fit object that can be used to quickly plot the curve or obtain QoE values for any  continuous bandwidth within the tested range. ```batch-qoe_2_0.1_6.mat``` is included as an example.

_Note for linear programming dudes and dudettes: I couldn't manage to obtain correct polynomial coefficients for the linear pieces of the fit using the method which is dedicated for that in the fit object (either I do something wrong, or matlab is broken). My workaround was to script it manually (see an example in run_batch.m)._


