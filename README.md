# metapopulation_sources
Analysis of MPA population models to compare different patch value statistics


This code performs all of the analyses and creates all of the figures in the manuscript "Defining sources, sinks, and patch value for conservation planning in marine metapopulations" by J. Wilson White and colleagues.

The code is written in Matlab and was originally executed in R2026a.

The main file is run_source_models.m, which calls all of the necessary files to perform the analysis and generate figures. The arguments to run_source_models.m specify the scenarios to be run.

The directories NCSR and SCSR contain the input files needed for the North and South study regions, respectively.

At this time, the SCSR is missing the connectivity matrix files because of file storage issues on Git.
