Cancer Systems Biology, Health and Technology Department, Section for Bioinformatics, 2800, Lyngby, Denmark

# Germline WGS Variant Calling pipeline
Germline Whole Genome Sequencing (WGS) variant calling workflow with [Sentieon®](https://www.sentieon.com) (DNAseq 202010.02) for paired-end sequencing data in Danish HPC Computerome2. Wrapper and submission script-generator are included to facilitate the process.
   
See Sentieon's [DNAseq manual](https://support.sentieon.com/versions/202010.02/manual/DNAseq_usage/dnaseq/) and [Argument Correspondence application note](https://support.sentieon.com/appnotes/arguments/) for information on how parameters in the Sentieon tools correspond to parameters in the GATK.

Sentieon DNAseq (https://support.sentieon.com/versions/202112.07/manual/DNAseq_usage/dnaseq/):
<img width="1127" alt="Screenshot 2022-09-13 at 13 47 26" src="https://user-images.githubusercontent.com/53432540/189893139-44809ab0-be04-4548-a9ed-9dc5c4c7970d.png">


  
## Wrapper    
To submitt a sample for analysis in Computerome2, `sentieon_wrapper_v2.sh` is used. This script combines all the neccesary to submit the WGS variant calling analysis of a sample/set of samples to the queuing system of Computerome2 HPC. It uses `submit.py` to generate and submit a PBS submission script (qsub) that runs the WGS pipeline script `sentieon_WGS_froz38.sh`  on the sample/s of interest.  
  
Usage: `sentieon_wrapper_v2 -[options] [absolute path to R1.fq file/list]`   
Arguments:
| Argument | Description |
| ------------- | ------------- |
| file/list  | a FASTQ file or a list of such files  |  

Options:

| Option  | Abreviation | Description |
| ------------- | ------------- | ------------- |
| --commit | -c  | committed run (default is dry)  |  
| --germline | -g  | germline (WGS) sample   |  
| --help | -h  | prints this message  |  
| --version | -v  | prints version and date   |  


Notes:  
	- the sample type (germline) must be specified with  '-g' 
	- at least one input file or list must be given  
	- a file has to have a name in the form `/<absolut_path>/<name>.R1.fq.gz` [(iCOPE nomenclature convention)](https://docs.google.com/document/d/1V22gvaMExWaHE1wM-0cihxBygQk6KlK9hZWnRoFvh8Y/edit#heading=h.rq7vebkfu0au)  
	- a list has to contain FQ files with names as above  

Example:  
`sentieon_wrapper_v2 -g -c [absolute path]R1.fq.gz`  
The sample is now queued in the job system (double check with qstat command) and should be analysed in 4-8 hours.
    
### submit.py  
General job-submission-script generator for Computerome2. It takes as argument the script to be run on HPC cluster and generates and submits the corresponding `.qsub` file to the queuing system. `sentieon_wrapper_v2` internally uses `submit.py` to generate submission scripts to run the samples of interest with `sentieon_WGS_froz38.sh`.   

Usage: `submit.py  script [-h] [-n NAME] [-no-nr] [-minutes MINUTES] [-hours HOURS]`  
 &emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;`[-mem MEMORY] [-dir WORKDIR] [-py2] [-w WAIT_FOR] [-T] [-R]`  
 &emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;`[-a ARRAY] [-max_jobs MAX_JOBS] [--verbose] [-np NPROC][-test] [-move]`

Positional arguments:   
| Argument | Description |
| ------------- | ------------- |
| script | A string indicating the code to run (sentieon_WGS_froz38.sh).   |  

Optional arguments:  

| Option  | Abreviation | Description |
| ------------- | ------------- | ------------- |
| --help | -h  | Show this help message and exit  |
| --name | -n  | Name of the submission job. Default is a unique number after 'icope'.  |
| --no-numbering  | -no-nr  | Disable addinga number after the name in filenames to avoid overwriting files.  |
| --minutes  | -minutes  | Wall-time minutes. Default is 0. If no walltime is provided, then is 30.  |
| --hours  | -hours  | Wall-time hours. Default is 10. |
| --memory  | -mem  | Memory in gb. Default is 150.  |
| --workdir | -dir  | The submission files are saved here. Relative filenames in command is relative to this. Default is current directory. |
| --python2  | -py2  | A flag set if we want to run the code with python2.  |
| --wait  | -w  | Used to wait for a given job to finish successfully. Insert the job number.  |
| --tunnel  | -T  | Flag set to include opening and closing tunnel for contacting Sentieon license. Default name are sentieon[start/stop]2.sh located in your $HOME |
| --reserve  | -R  | Use this flag to submit job to our own reserves nodes  |
| --array  | -a  | Used to create job array, the job number will be $PBS_ARRAYID. Insert numbers to run eg. 608-631.  |
| --max_jobs  | -max_jobs  | Choose maximum number of jobs to run at a time from this call. This setting is  only relevant for array jobs. If more array jobs are started than this number,some of them will wait to run.  |
| --verbose  | -verbose  | Add to execute set -xv and more information.  |
| --nproc  | -np  | Number of processors to use. Default is 38  |
| --move-outfile  | --move  | When running the pipeline, enable moving the output files to the sample folder generated by the scirpt.   |


Default behaviour when using `sentieon_wrapper_v2 -g -c [absolute path]R1.fq.gz`:  
`submit.py "sentieon_WGS_froz38.sh SAMPLE_NAME.R1.fq.gz 38" -n SAMPLE_NAME -np 38 -move --tunnel | tee -a sentieon_wrapper.SAMPLE_NAME.log`  

### sentieon_WGS_froz38.sh  
Script to run Sentieons DNAseq pipeline on a germline paired-end WGS sample with reference Human Genome build 38. Takes as input the R1.fq file and the number of available computing cores to output its corresponding BAM+RecalibrationTable as well as the VCF containing the genetic variants of the sample. Quality metrics and figures are also outputed in the results folder.       
Usage: `sentieon_WGS.froz38.sh SAMPLE_NAME.R1.fq.gz [n of cores]`  
 
# LICENSE
The content of this repository is licensed under the terms of the GNU General 
Public License (see LICENSE file). 

You can redistribute it and/or modify it under the terms of the GNU General
Public License as published by the Free Software Foundation, either version 3
of the License, or (at your option) any later version.
    
This set of files is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU General Public License for more details.
You should have received a copy of the GNU General Public License
along with this program.  If not, see <https://www.gnu.org/licenses/>.


## Citation 

RosettaDDGPrediction for high-throughput mutational scans: from stability to binding

Valentina Sora, Adrian Otamendi Laspiur, Kristine Degn, Matteo Arnaudi, Mattia Utichi, Ludovica Beltrame, Dayana De Menezes, Matteo Orlandi, Olga Rigina, Peter Wad Sackett, Karin Wadt, Kjeld Schmiegelow, Matteo Tiberti, Elena Papaleo*
under revision for Protein Science and on biorxiv:  https://doi.org/10.1101/2022.09.02.506350 
