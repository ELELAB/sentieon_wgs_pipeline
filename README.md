# Germline WGS Variant Calling pipeline
Germline Whole Genome Sequencing (WGS) variant calling workflow with [Sentieon®](https://www.sentieon.com) (DNAseq 202010.02) for paired-end sequencing data in Danish HPC Computerome2. Wrapper and submission script-generator are included to facilitate the process.
   
See Sentieon's [DNAseq manual](https://support.sentieon.com/versions/202010.02/manual/DNAseq_usage/dnaseq/) and [Argument Correspondence application note](https://support.sentieon.com/appnotes/arguments/) for information on how parameters in the Sentieon tools correspond to parameters in the GATK.

Sentieon DNAseq:
<img width="1127" alt="Screenshot 2022-09-13 at 13 47 26" src="https://user-images.githubusercontent.com/53432540/189893139-44809ab0-be04-4548-a9ed-9dc5c4c7970d.png">


  
## Wrapper    
To submitt a sample for analysis in Computerome2, `sentieon_wrapper_v2.sh` is used. This script combines all the neccesary to submit the WGS variant calling analysis of a sample/set of samples to the queuing system of Computerome2 HPC. It uses `submit.py` to generate and submit a PBS submission script (qsub) that runs the WGS pipeline script `sentieon_WGS_froz38.sh`  on the sample/s of interest.  
  
Usage: `sentieon_wrapper_v2 -[options] [absolute path to R1.fq file]`  
Options:  
&emsp;&emsp;&emsp;	-c | --commit		- committed run (default is dry)  
&emsp;&emsp;&emsp;	-g | --germline		- germline (WGS) sample  
&emsp;&emsp;&emsp;	-h | --help		- prints this message  
&emsp;&emsp;&emsp;	-v | --version		- prints version and date  
&emsp;&emsp;&emsp;	file | list		- a FASTQ file or a list of such files  

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

Positional arguments: script &emsp;&emsp;A string indicating the code to run (sentieon_WGS_froz38.sh).

Optional arguments:  
&emsp;&emsp;&emsp;  - h | --help            show this help message and exit  
&emsp;&emsp;&emsp;  - n NAME | --name NAME&emsp;&emsp;Name of the submission job. Default is a unique number after 'icope'.  
&emsp;&emsp;&emsp;  - no-nr | --no-numbering&emsp;&emsp;Disable addinga number after the name in filenames to avoid overwriting files.  
&emsp;&emsp;&emsp;  - minutes MINUTES&emsp;&emsp;Wall-time minutes. Default is 0. If no walltime is provided, then is 30.  
&emsp;&emsp;&emsp;  - hours HOURS | --hours HOURS&emsp;&emsp;Wall-time hours. Default is 10.  
&emsp;&emsp;&emsp;  - mem MEMORY | --memory MEMORY&emsp;&emsp;Memory in gb. Default is 150.  
&emsp;&emsp;&emsp;  - dir WORKDIR | --workdir WORKDIR&emsp;&emsp;The submission files are saved here. Relative filenames in command is relative to this. &emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;Default is current directory.  
&emsp;&emsp;&emsp;  - py2 | --python2&emsp;&emsp;A flag set if we want to run the code with python2.  
&emsp;&emsp;&emsp;  - w WAIT_FOR | --wait WAIT_FOR&emsp;&emsp;Used to wait for a given job to finish successfully. Insert the job number.  
&emsp;&emsp;&emsp;  - T | --tunnel&emsp;&emsp;Flag set to include opening and closing tunnel for contacting Sentieon license. Default name are &emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;sentieon[start/stop]2.sh located in your $HOME  
&emsp;&emsp;&emsp;  - R | --reserve &emsp;&emsp;Use this flag to submit job to our own reserves nodes  
&emsp;&emsp;&emsp;  - a ARRAY | --array ARRAY&emsp;&emsp; Used to create job array, the job number will be $PBS_ARRAYID. Insert numbers to run eg. 608-631.  
&emsp;&emsp;&emsp;  - max_jobs MAX_JOBS | --max_jobs MAX_JOBS&emsp;&emsp;Choose maximum number of jobs to run at a time from this call. This setting is &emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;only relevant for array jobs. If more array jobs are started than this number, &emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;some of them will wait to run.  
&emsp;&emsp;&emsp;  -- verbose&emsp;&emsp;Add to execute set -xv and more information.  
&emsp;&emsp;&emsp;  - np NPROC | --nproc NPROC &emsp;&emsp;Number of processors to use. Default is 38  
&emsp;&emsp;&emsp;  - test| --test&emsp;&emsp;For testing writing the qsub-script only. Will not submit to Computerome.  
&emsp;&emsp;&emsp;  - move| --move-outfiles&emsp;&emsp;When running the pipeline, enable moving the output files to the sample folder generated by the scirpt. &emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;The name of the generated folder is inferred from the pipeline version and input sample name.  
                        
                        
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
