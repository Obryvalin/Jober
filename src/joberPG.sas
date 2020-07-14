options autosignon=yes sascmd="!sascmd -dmr" noxwait nonotes nosource xmin;
dm "log; clear;";


%let StartTime =   %sysfunc(putn(%sysfunc(time()), time.));
%let syscc = 0;
%let Process = EVDAY;
%let PRG_DIR = \\sasdm1\erxternal\Jober\&Process;
%let stepcnt = 1;
%let shift = 0;
%let scnt=0;


proc format;
picture NiceDate other = '%Y-%0m-%0d' (datatype = date);
run;
%global logdate;
%let logdate = %sysfunc(putn(%sysfunc(date()),NiceDate.));

%let logfile = &PRG_DIR\Logs\&logdate._Jober.log;
%global JCNT;
%let JCNT = 0;
/********************************/
/*
		signoff _all_;
		killtask PBFL;
*/
/********************************/		
/*
		%init;
		%import_timetable;
		%timetable_show;
*/	
/********************************/
/*	
		listtask _all_;
		
		%Jober;  
		

		%signal;
		%StartJob(FSSP,\\sasdm1\erxternal\jober\evday\jobs\1\fssp3.sas);
		%StartJob(INBKI,\\sasdm1\erxternal\jober\evday\jobs\1\INBKI.sas);
		%StartJob(OINBKI,\\sasdm1\erxternal\jober\evday\jobs\1\OBRINBKI.sas);
		%StartJob(PBFL,\\sasdm1\erxternal\jober\evday\jobs\1\PBFL2.SAS);
		%StartJob(PSFINAL,\\sasdm1\erxternal\jober\evday\jobs\1\PSFINAL.sas);
		%StartJob(BFLRB,\\sasdm1\erxternal\Jober\DISTRIB\Storage\BFLRB.sas);
		%StartJob(MASSEGR,\\sasdm1\erxternal\jober\evday\jobs\MASSEGRUL.sas);
		%StartJob(CHIK,\\sasdm1\erxternal\jober\CH\jobs\ik.sas);
		%StartJob(LIQEGR,\\sasdm1\erxternal\jober\evday\jobs\LIQEGRUL.sas);
*/
/********************************/

%put JOBLIB = CHRONO;
libname JobLib    postgres 
		server=sw0641
		port=1988 
		db="CHRONO" 
		user=postgres 
		pw="postgres" 
		schema=public;


%macro init;

	proc sql;
		drop table joblib.timetable;
		drop table joblib.logs;
		drop table joblib.joblog;
	quit;
	data Joblib.timetable;
		format weekday 1. Starttime time. PROCESS JOBNAME $8. FilePath $100.;
	run;

	data joblib.logs;
		format PROCESS JOBNAME $8.  JobDate $10. Jobtype $10. log $500. ;
	run;

	data joblib.joblog;
		format PROCESS $10. JOBNAME $8. Filename $100.  JSTART JEND JSIGNOFF datetime. syscc 10.;
	run;
%mend;


%macro Import_timetable;
%put Import Timetable;
proc sql;
	delete from joblib.timetable where Process = "&Process";
quit;
%put &PRG_DIR\Timetable.csv;
	data Timetable;
		format weekday 1. Starttime time. PROCESS JOBNAME $8. FilePath $100.;
		format stime $8.;
		infile "&PRG_DIR\Timetable.csv" dlm=";";
		input weekday stime $ JOBNAME $ FilePath $;
		Starttime = input(stime,time.);
		Process = "&Process";
		drop stime;
	run;
	%sorting(Timetable,weekday Starttime JobName);
	proc sql;
		insert into joblib.timetable select * from timetable;
	quit;
%mend;
%macro Timetable_show;
	%put ������� %sysfunc(weekday(%sysfunc(today()))):;
	%put;
	data _null_;
		set joblib.Timetable;
		where weekday = weekday(today()) and process = "&Process";
		put Starttime @15 JOBNAME @30 FilePath;
	run;
	%put +--------------------------------+;
	%put ������ %sysfunc(weekday(%sysfunc(today())+1)):;
	%put;
	data _null_;
		set joblib.Timetable;
		where weekday = weekday(today()+1) and process = "&Process";
		put Starttime @15 JOBNAME @30 FilePath;
	run;
	%put +--------------------------------+;
%mend;



%macro cls;
	/*data _null_; x = sleep (2); run;*/
	dm "log; clear;";
	%put +--------------------------------+;
	%put Jober &Process;
	%if &scnt ^= 0 %then %put LOOP STEP : &Scnt;
	%let fstime =   %sysfunc(putn(%sysfunc(time()), time.)); %put ���� &fstime - ������: &Starttime;
	%put +--------------------------------+;
	%put ;
%mend cls;

%macro Exist(DSN);
    %GLOBAL exist;
    %LOCAL libname;
    %let dsn=%upcase(&dsn);
    %if %index(&dsn,.) %then %do;
       %let libname=%scan(&dsn,1);
       %let dsn=%scan(&dsn,2);
    %end;
    %else %let libname=WORK;
    proc contents data=&libname.._all_ memtype=data noprint
         out=temp(keep=memname nobs);
    data _null_;
       set temp end=last;
         if upcase(memname)="&dsn" then do;
            if nobs^=0 then call symput ('exist','yes');
            else call symput ('exist','no');
            stop;
         end;
         else if last then call symput ('exist','no');
    run;
	%put &DSN EXIST = &EXIST;
    %DelFile(temp);
%mend;

%macro search_ERR;
	%global chlog_status;
	%let chlog_status = 0;
	options xsync;
	x "del /Q  &logfile";
 	dm "log; file ""&logfile"""; /*���� ����� ���������� "���-����" */
	
	data _null_;
		INFILE "&logfile"  dsd dlm = '';
		FORMAT a $200.;
		INPUT a;
		a = TRANWRD(a,'_ERROR_', '');
		if index(a,'ERROR') then do;
			call symput("chlog_status", 1);
		end;
	run;
	%put &chlog_status;
	%if &chlog_status = 1 %then %do;
		%put "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!";
		%put "!!!!!!� ��������� ���� ������!!!!";
		%put "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!";
		%abort CANCEL;
%end;
%mend search_ERR;

%macro Chronopost(MSG);
x "wscript W:\Script_Dump\StatusChecker\Chronopost.vbs ""Jober &Process"" right ""&MSG""";
%mend;

/*---------------------------------------------------------------------------*/



%macro StartJob(mJOB,mFname);
%put Starting &mJOB....;
	x "wscript W:\Script_Dump\StatusChecker\Chronopost.vbs ""Jober &Process"" right ""START &mJOB.""";
	data joblog;
			format PROCESS $10. JOBNAME $8. Filename $50.  JSTART JEND JSIGNOFF datetime. syscc 10.;
		keep Process filename JOBNAME JSTART JEND JSIGNOFF syscc;
		Process = "&Process";
		Filename = "&mFname";
		JOBNAME = "&mJOB";
	run;
			
	proc sql;
		insert into joblib.joblog select * from joblog;
	quit;
	%let &mJOB.DONE = 0;
	
	%let logdate = %sysfunc(putn(%sysfunc(date()),NiceDate.));
	filename L&MJob "&PRG_DIR\Logs\&mJob._&logdate..log";
	%put L&MJob = &PRG_DIR\Logs\&mJob._&logdate..log;
	%put signon [&mJob.];
	%Put LOG = "&PRG_DIR\Logs\&mJob._&logdate..log";
	signon &mJOB;
	%put Transfering Macros...;
	%syslput PRG_DIR=&PRG_DIR /remote=&mJOB;
	%syslput JOB=&mJOB /remote=&mJOB;
	%syslput Proc=&Process /remote=&mJOB;
	%syslput LOGDATE=&LOGDATE /remote=&mJOB;
	%syslput FPath=&mFName /remote=&mJOB;
	
	%put Rsubmit...;
	rsubmit process=&mJOB. wait=no cwait=no csysrputsync=yes log=L&MJob.;
		options xmin FULLSTIMER source notes compress=yes;
		%macro MSG(MSG);
			%put &MSG;
		%mend;
		proc format;
			picture NiceDate other = '%Y-%0m-%0d' (datatype = date);
		run;
		
		libname JobLib    postgres 
		server=sw0641 
		port=1988 
		db="CHRONO" 
		user=postgres 
		pw="postgres" 
		schema=public;

		%MSG (START &JOB : %sysfunc(putn(%sysfunc(datetime()), datetime.)));
		proc sql;
			update joblib.joblog set JSTART = datetime() where JOBNAME = "&JOB" and JSTART = . and Process = "&Proc";
		quit;
		%MSG (Including &FPath ...);
		%MSG(+--------------------------------+);
		%include "&FPath";
		%MSG(+--------------------------------+);
		proc sql;
			update joblib.joblog set JEND = datetime(),syscc = &SYSCC where JOBNAME = "&JOB" and Process = "&Proc" and JEND = .;
		quit;
		%MSG (END &JOB.: %sysfunc(putn(%sysfunc(datetime()), datetime.)));
		%macro Chronopost;
			%let errmsg=%superq(syserrortext);
			x "wscript W:\Script_Dump\StatusChecker\Chronopost.vbs ""Jober &Proc"" right ""END &JOB. (SYSCC = &syscc - &errmsg)""";
		%mend;
		%Chronopost;
	endrsubmit;
/*rdisplay &mJOB;*/
%mend;

%macro signoffFinished;
	%let jscnt = 0;
	proc sql;
		create table joblog as select * from joblib.joblog where JEND ^= . and JSIGNOFF = . and Process = "&Process";
	quit;
	%let JobSoffCNT = 0;
	data _null_;
		set joblog;
		call symput("JobSoff"||compress(_n_),compress(JOBNAME));
		call symput("JobSoffCNT",compress(_n_));
		call symput("JobSoffD"||compress(_n_),compress(put(datepart(JSTART),Nicedate.)));
	run;
	%do jscnt = 1 %to &JobSoffCNT;
		signoff &&JobSoff&jscnt;
		data log;
			format Process $10. JobName $8. JobDate $10. Jobtype $10. log $500. ;
			JobName = "&&JobSoff&jscnt";
			Process = "&Process";
			JobDate = "&&JobSoffD&jscnt";
			infile "&PRG_Dir\Logs\&&JobSoff&jscnt.._&&JobSoffD&jscnt...log" dlm="@#";
			input log $;
			Jobtype = "SOURCE";
			if index(log,"NOTE:")> 0 then Jobtype = "NOTE";
			if index(log,"WARNING:")> 0 then Jobtype = "WARNING";
			if index(log,"ERROR:")> 0 then Jobtype = "ERROR";			
		run;
		proc sql;
			insert into joblib.logs select * from log;
		quit;
		proc sql;
			update joblib.joblog set JSIGNOFF = datetime() where JOBNAME = "&&JobSoff&jscnt" and Process = "&Process" and JEND ^= . and JSIGNOFF = . ;
		quit;
	%end;
	
	%delfile(joblog);
%mend;

/*---------------------------------------------------------------------------*/
%macro signal;
	options xsync;
	x "dir &PRG_DIR\Signal /b > &PRG_DIR\Signal.txt";
	data dir;
		format file $50.;
		infile "&PRG_DIR\Signal.txt" dlm=";";
		input file $;
	run;
	x "delfile &PRG_DIR\Signal.txt";
	%let signalCNT = 0;
	data _null_;
		set dir;
		call symput (compress("signalfile"||(_n_)),compress(file));
		call symput ("signalCNT",compress(_n_));
	run;
	%do sigi = 1 %to &signalCNT;
		data signal;
			format job $10. path $50.;
			infile "&PRG_DIR\Signal\&&signalfile&sigi.." dlm=";";
			input job $ path $;	
		run;
	
		%let signalfCNT = 0;
		data _null_;
			set signal;
			call symput (compress("signaljob"||(_n_)),compress(job));
			call symput (compress("signalpath"||(_n_)),compress(path));
			call symput ("signalfCNT",compress(_n_));
		run;
		%do sigj = 1 %to &signalfcnt;
			%Startjob(&&SignalJob&sigj..,&&Signalpath&sigj..);
		%end;
		x "del ""&PRG_DIR\Signal\&&signalfile&sigi..""";
		
	%end;
			
	%delfile(dir signal);
%Mend;
%macro Jober;

	%do %while (1 < 2);
		%let logdate = %sysfunc(putn(%sysfunc(date()),NiceDate.));
		%let CTIME = %sysfunc(time());
		libname JobLib    postgres 
				server=sw0641 
				port=1988 
				db="CHRONO" 
				user=postgres 
				pw="postgres" 
				schema=public;
		%cls;
		%timetable_show;
		%put CTIME = %sysfunc(putn(&CTIME,time.));
		%put �������:;
		data timetable;
			set joblib.timetable;
			if Process = "&Process" and weekday = weekday(date()) and Starttime >= &CTIME;
			put Starttime @15 JOBNAME @30 FilePath;
		run;

			data TimetableNow;
				set joblib.timetable;
				if Process = "&Process" and hour(Starttime) = hour(&CTIME) and minute(Starttime) = minute(&CTIME) and weekday=weekday(date());
			run;
			%exist(TimeTableNow);
			%if &exist = yes %then %do;
				%let JCNT = 0;
				data _null_;
					set timetableNow;
					call symput(compress("Job"||(_n_)),compress(JOBNAME));
					call symput(compress("FPath"||(_n_)),compress(FilePath));
					call symput("JCNT",compress(_n_));
				run;
				%do i = 1 %to &JCNT;
					
					%delfile(JobLog);
					%put Start JOB &i / &JCNT : &&JOB&i.. / &&FPath&i..;
					%StartJob(&&JOB&i..,&&FPath&i..);
					data _null_; x=sleep(1);run;
				%end;
			%end;
			%delfile (Timetable Joblog);

	
		
		%signoffFinished;
		%signal;
/*		%PG_SYNC;*/
		%put +--------------------------------+;
		listtask _all_;
		%put +--------------------------------+;
		data joblog;
				set Joblib.joblog;
				if Process = "&Process" and datepart(JSTART)=today();
				put JOBNAME @15 JSTART @45 JEND;
		run;

				data _null_; x = wakeup(max(Hour(&CTIME)*60*60+(Minute(&CTIME)+1)*60+&shift,time()+1)); run;
	
	%end;
%mend;

%cls;
%put Ready;

