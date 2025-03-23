# ThermoPlates
This repository hosts a series of UNIX shell scripts from Boone et al. (2025) that utilises the Generic Mapping Tool version 6 command library (Wessel et al., 2019) to enable the integration of thermochronology data with plate tectonic, mantle dynamics, and paleoclimate model outputs for interpreting long-term exhumation histories in a holistic Earth systems context.

The workflow requires an input .csv file with the longitude and latitude of thermochronology samples and their per-million-year cooling rates recorded by thermal history modelling. Depending on the purposes of the study, additional information, such as paleotemperatures, or the regions and sub-regions of samples can also be included in the input file. 

The workflow consists of the following scripts:

- 00_Thermochronology_Data_Characteristics.sh - Determines the longitude-latitude ranges of samples in the dataset, the age range constrained by the thermal history model data, the range in paleotemperatures, and the range of cooling rates. It also generates a histogram of cooling rates across the dataset (Fig. ED1 in Boone et al., 2025).

- 01_Thermochronology_Assessment.sh - Makes a series of 2D and 3D scatter plots to examine potential relationships between cooling rates through time versus defined region or sub-region, and versus longitude or latitude (ED2). The code also makes 3D lon-lat-cooling rate figures for each million-year time step (Vid. S1) and static 4D lon-lat-time-cooling rate plots (Figs. 1d & 1e in Boone et al., 2025). 

- 02_data_play.sh - Makes a series of maps in present-day coordinates that plot the distribution of fast, very fast and extra fast cooling samples (defined by Boone et al., 2025 for the Central Asian dataset as >0.5, >1.0, and >1.5 °C/Ma) relative to faults from an input fault database in a present-day static geography for each million-year time step. It then extracts and makes scatter plots of mean and standard deviation cooling rates for each region at each million-year timestep (Fig. ED3 in Boone et al., 2025). 

- 03_Thermochron_GPlates.sh - This comprises the core of the ThermoPlates workflow, combining thermal (or exhumation) history datasets with the plate tectonic, mantle dynamic, paleoclimate, and paleotopography simulations and fault databases. Using an input fault database, the script also identifies faults in proximity to fast cooling/denuding samples and performs structural analysis of their geometries. It also performs calculations to produce the kinematics_master.xyz and thermochron_master_${age}.xyz files that are used in the subsequent 04_Kinematics.sh and 05_Loop_Plot.sh scripts. The 03_Thermochron_GPlates.sh script runs a loop through the modelling time range and creates the following figures for each time step:
    - Regional map of cooling rates through time
    - Global map of an evolving plate tectonic reconstruction with thermochronology-derived cooling rates through time and seafloor ages
    - Global map of an evolving plate tectonic reconstruction with thermochronology-derived cooling rates through time atop predicted dynamic topography
    - Global and regional maps of an evolving plate tectonic reconstruction with convergence rates along subduction zones and thermochronology-derived cooling rates through time
    - Global and regional maps of an evolving plate tectonic reconstruction with trench migration rates and thermochronology-derived cooling rates through time
    - Regional maps of samples cooling above a certain, user-defined cut-off rate and faults within some user-defined proximity range of the fast cooling samples
    - Rose diagrams of plate velocity and azimuth near thermochronology samples, arc azimuths, suubduction rate azimuths, arc migration azimuths, faults in proximity to quickly cooling/exhuming samples
    - Global and regional maps of an evolving plate tectonic reconstruction with paleoprecipitation rates and thermochronology-derived cooling rates through time
    - Global and regional maps of an evolving plate tectonic reconstruction with a paleotopography model and thermochronology-derived cooling rates through time
    - Three different scatter plots of cooling rate versus dynamic topography, change in dynamic topography, and paleoprecipitation rate for each time step

- 04_Kinematics.sh - Uses the kinematics_master.xyz file generated with the 02_Thermochron_GPlates.sh and generates a series of scatter plots to compare trends in cooling histories through time with the results from the plate tectonic and subduction kinematics (Figs. 6b-6d, ED4 & ED5b-ED5d in Boone et al., 2025) and fault analysis (Figs. 5b-5c in Boone et al., 2025) (see below).

- 05_Loop_Plot.sh - Uses the series of thermochron_master_${age}.xyz files created in 03_Thermochron_GPlates.sh for every modelling time step and creates three different scatter plots of cooling rate versus time coloured by (i) dynamic topography, (ii) change in dynamic topography, and (iii) paleoprecipitaton rate across the entire input thermochronology dataset. 

- 99_Animator.sh - Can be placed in a directory of figures from multiple time slices (like those made in some of the above script) to make a combined animation (e.g., Vids. S1-S4 in Boone et al., 2025).

Note: Data for the Central Asian example published in Boone et al. (2025) can be found in the Supplementary Data of that paper.
