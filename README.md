# sentieon_wgs_pipeline
WGS variant calling pipeline with Sentieon® (DNAseq from sentieon-genomics-202010.02) for paired-end sequencing data and wrapper+submission script for submitting the analysis in Computerome2 job system.  
Sentieon DNAseq manual: https://support.sentieon.com/versions/202010.02/manual/DNAseq_usage/dnaseq/  
  
<img width="1127" alt="Screenshot 2022-09-13 at 13 47 26" src="https://user-images.githubusercontent.com/53432540/189893139-44809ab0-be04-4548-a9ed-9dc5c4c7970d.png">


  
## sentieon_wrapper_v2    
To submitt a sample for analysis in Computerome2, Sentieon_wrapper_v2.sh is used. This script uses submit.py and sentieon_WGS_froz38.sh along with the sample of interest to submit a job to the queueing system.  
  
Usage: sentieon_wrapper_v2 -[options] [absolute path to R1 file]  
&emsp;&emsp;&emsp;	-c | --commit		- committed run (default is dry)  
&emsp;&emsp;&emsp;	-g | --germline		- germline (WGS) sample  
&emsp;&emsp;&emsp;	-h | --help		- prints this message  
&emsp;&emsp;&emsp;	-t | --tumor		- tumor (RNAseq) sample  
&emsp;&emsp;&emsp;	-v | --version		- prints version and date  
&emsp;&emsp;&emsp;	file | list		- a FASTQ file or a list of such files  

Notes:
	- the sample type must be specified with either '-g', or '-t'
	- at least one input file or list must be given
	- a file has to have a name in the form [<full_path>]<name>.R1.fq.gz (iCOPE nomenclature convention)
	- a list has to contain FQ files with names as above

Example for a Germline WGS: sentieon_wrapper_v2 -g -c [Absolute Path to file]R1.fq.gz  
  
This will use submit.py script to submit the specified sample to the queueing system for analysis with Sentieon DNAseq  
  
## submit.py  
General job submission script (PBS based) for Computerome2.  

Usage: submit.py [-h] [-n NAME] [-no-nr] [-minutes MINUTES] [-hours HOURS]  
 &emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;                [-mem MEMORY] [-dir WORKDIR] [-py2] [-w WAIT_FOR] [-T] [-R]  
 &emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;                [-a ARRAY] [-max_jobs MAX_JOBS] [--verbose] [-np NPROC][-test] [-move] script

Positional arguments: script &emsp;&emsp;A string indicating the code to run (sentieon_WGS_froz38.sh).

Optional arguments:  
&emsp;&emsp;&emsp;  -h | --help            show this help message and exit  
&emsp;&emsp;&emsp;  -n NAME | --name NAME&emsp;&emsp;Name of the submission job. Default is a unique number after 'icope' that doesn't create conflict.  
&emsp;&emsp;&emsp;  -no-nr | --no-numbering&emsp;&emsp;Disable addinga number after the name in filenames to avoid overwriting files.  
&emsp;&emsp;&emsp;  -minutes MINUTES&emsp;&emsp;Wall-time minutes. Default is 0 unless no kind of wall-time is provided, then it is 30.  
&emsp;&emsp;&emsp;  -hours HOURS | --hours HOURS&emsp;&emsp;Wall-time hours. Default is 10.  
&emsp;&emsp;&emsp;  -mem MEMORY | --memory MEMORY&emsp;&emsp;Memory in gb. Default is 150.  
&emsp;&emsp;&emsp;  -dir WORKDIR | --workdir WORKDIR&emsp;&emsp;The submission files are saved here. Relativefilenames in command is relative to this. &emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;Default is current directory.  
&emsp;&emsp;&emsp;  -py2 | --python2&emsp;&emsp;A flag set if we want to run the code with python2.  
&emsp;&emsp;&emsp;  -w WAIT_FOR | --wait WAIT_FOR&emsp;&emsp;Used to wait of a given job to finish successfully. Insert the job number.  
&emsp;&emsp;&emsp;  -T | --tunnel&emsp;&emsp;Flag set to include opening and closing tunnel for Sentieon pipeline. Default name are sentieonstart2.sh  
&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;and sentieonstop2.sh located in your $HOME  
&emsp;&emsp;&emsp;  -R | --reserve         Use this flag to submit job to our own reserves nodes  
&emsp;&emsp;&emsp;  -a ARRAY | --array ARRAY&emsp;&emsp; Used to create job array, the job number will be $PBS_ARRAYID. Insert numbers to run eg. 608-631.  
&emsp;&emsp;&emsp;  -max_jobs MAX_JOBS | --max_jobs MAX_JOBS&emsp;&emsp;Choose maximum number of jobs to run at a time from this call. This setting is &emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;only relevant for array jobs. If more array jobs are started than this number, &emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;some of them will wait to run.  
&emsp;&emsp;&emsp;  --verbose&emsp;&emsp;Add to execute set -xv and more information.  
&emsp;&emsp;&emsp;  -np NPROC | --nproc NPROC &emsp;&emsp;Number of processors to use. Default is 38  
&emsp;&emsp;&emsp;  -test| --test&emsp;&emsp;For testing writing the qsub-script only. Will not submit to Computerome.  
&emsp;&emsp;&emsp;  -move| --move-outfiles&emsp;&emsp;When running the pipeline, enable moving the output files to the sample folder generated by the scirpt. &emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;The name of the generated folder is inferred from the pipeline version and input sample name.  
                        
                        
 Default behaviour when using sentieon_wrapper_v2 for a Germline WGS sample: submit.py "sentieon_WGS_froz38.sh 11021_154854.G.T01.S1.R1.fq.gz 38" -n 11021_154854.G.T01.S1 -np 38 -move --tunnel | tee -a sentieon_wrapper.11021_154854.G.T01.S1.log  
   
 Finally, the sample is queued in the system (you can double check with qstat command) and should be analysed in 4-8 hours.
 
 
 
