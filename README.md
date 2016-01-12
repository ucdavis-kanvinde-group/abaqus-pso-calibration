# abaqus-pso-calibration
Optimal calibration of continuum cyclic constitutive model using Particle Swarm Optimization.

## For information, please read:
Smith, C.M., Kanvinde, A.M., Deierlein, G.G. (2013) *Optimal calibration of continuum cyclic constitutive model for structural steel using Particle Swarm Optimization*, Journal of Structural Engineering

## About this distro:
Originally developed by Chris Smith (2013). His original code can be found here:

http://purl.stanford.edu/qy227tf3022


His code did not have many comments, and was difficult for me to understand. I went through it, commented extensively, provided some minor optimizations/refactoring, and added some functionalities; this code is the result of my efforts. (Vince Pericoli 2015)

### How to use:
Information about the the physical test results and model information is provided to the routine via a MATLAB binary (.mat) structure file. You must also provide template ABAQUS input files, which represent FE models of the physical tests. Examples of these requirements can be found in the ./example/ directory.

Simply load the .mat structure file, and set the Particle Swarm parameters. Then you could execute the following:

[bestpos bestval] = fpsosearch_simp(@(params)getABQerrorCombined(params, tests, testnums, errortype), lbound, ubound, np, niter, gravity, inertia, errTol, plotflg);

or, a simpler version:
[bestpos bestval] = fpsosearch_simp(@(params)getABQerrorCombined(params, tests), lbound, ubound, np, niter, gravity, inertia, errTol);

Details about the required .mat structure fields and Particle Swarm parameters are provided below. Further information about the Particle Swarm parameters can be found in the above paper by Smith et al.

##### Particle Swarm Parameters:
* lbound  : vector describing the size and lower bound of parameter space
* ubound  : vector describing the size and upper bound of parameter space
* np      : number of particles. Try 3-6 * the param space dimension
* niter   : number of iterations
* gravity : particle attractive force (try 1.5). You can use a vector to specify a different value for global and local (sometimes referred to as "social" and "cognitive" learning rates in the literature).
* inertia : particle inertia (try [0.55, 0.275]). You can use a vector to specify a different value for the initial inertia and final inertia (treated as a linear variation over the steps)
* errTol  : stopping criteria. use -inf unless you know otherwise; this implies that the search will run until without stopping for all niter iterations.
* plotflg : optional flag to specify whether to plot results or print iteration number during the solution search. 0 = no plot or iteration print, 1 = plot, but do not print iteration, 2 = plot and print iteration number (Default).

##### Objective Function (i.e. getABQerrorCombined.m) Parameters
* newparams : vector of material hardening parameters. this is what the PSO algorithm modifies.
* tests     : specifically designed .mat struct file containing test data (see below)
* testnums  : Optional subset of tests on which to run analysis (vector of indices), or string 'all'. Default = 'all'
* errortype : Optional selector for internal error designation (see calcResidualError.m and Smith et al. (2013) for more info). Default = 4

##### Explanation of .mat Structure Fields:
The tests structure must contain a field for every test you want to calibrate, as seen in the example. Each one of those tests has the following structure fields:
* datafile : string name of the excel data file where the test data is located. This is for your information only and is NOT needed by the algorithm.
* mtsdata  : array of the actual test data from the MTS or Tinius Olsen machine. This is for your information only and is NOT needed by the algorithm.
* force    : vector of the filtered force measurement from the test data. See the MATLAB smooth() function for help on data filtering
* displ    : vector of the filtered displacement measurement from the test data. This should be filtered from a RELIABLE measurement (like from an extensometer). The PSO algorithm will try to match the ABAQUS response to this force-displ data.
* history  : vector of the peaks of the displacement loading. The ABAQUS models will be loaded via displacement-control to these peaks.
* template : string name of the ABAQUS input file which represents the test specimen. The input files must be located in the same directory as the PSO algorithm.
* cyclic   : boolean 1/0 or true/false, indicating whether the test is cyclic (true) or monotonic (false)
* symmetric : boolean 1/0 or true/false, indicating whether the ABAQUS input files have symmetry w.r.t. displacement. True indicates that the PSO algorithm should try to match the ABAQUS response to the 0.5*displ data
* rxNodeSet : string name of the ABAQUS node set corresponding to the reaction. The algorithm will obtain the ABAQUS "force" data from this set.
* getIntPtData : boolean 1/0 or true/false, indicating whether you want to also extract integration-point fracture mechanics information from the simulations. This functionality is leftover from Chris' implementation. If you do want to extract this info, please see the code for more details.

##### Requirements of the ABAQUS input template files:
* The node set defined in rxNodeSet must exist. Remember that if you define a geometry set in ABAQUS, it will automatically make the corresponding node and element sets. For the rxNodeSet, you can use kinematic coupling, or you could just use the full reaction surface. The algorithm will sum up all the individual nodal reactions for each time step anyway--so it doesn't matter if it's 1 node or a full set of nodes.
* There must be a defined amplitude (* Amplitude keyword), which is used for the loading boundary condition (the displacement-control loading should be set to 1, which is then scaled by the defined Amplitude)
* The material must be defined such that the plastic response is characterized by combined hardening with 2 backstress parameters, and cyclic hardening parameters

The algorithm will automatically modify the amplitude for each defined test, as well as the plastic material parameters as it searches for an optimum.

##### Other requirements:
The algorithm also requires abaqus-odb-tools in order to extract data from the ABAQUS odb files. You can find that on GitHub as well: https://github.com/ucdavis-kanvinde-group/abaqus-odb-tools

The algorithm has been tested to work with the v1.0.0-beta release, but the most up-to-date code should work fine. Once you have downloaded the abaqus-odb-tools distro, simply edit the odbFetchFieldOutput.py so that it points to the abaqus-odb-tools download location.

The code execution speed could probably be improved significantly if it used the MATLAB Python engine, though the setup/installation becomes much more complicated.
