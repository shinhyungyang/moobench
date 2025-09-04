# Analysis Scripts

These scripts aim for quick analysis of MooBench result values, both for understanding the behaviour and generating tables and graphs for publications.

The following files are contained:
- getExponential.sh: Creates `evolution_$FRAMEWORK.sh` for every framework; used for scalability analysis
- getFilesAverages.sh: Prints the averages of scalability analysis of $1 (files need to be unpacked)
- getStatistics.sh: Creates a table of the overview of all result folders in $1 (files are automatically unpacked)
