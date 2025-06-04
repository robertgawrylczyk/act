

proc import datafile="/home/u64248777/_backblaze_data_2024_agg_filtered.xlsx"
    out=backblaze_data
    dbms=xlsx
    replace;
    sheet="Sheet1";
    getnames=yes;
    
    
run;

data dane_pre;
    set backblaze_data;
    label
        smart_1_raw  = "Rate of hardware read errors during disk operations"
        smart_3_raw  = "Average time of spindle spin up from zero RPM to fully operational"
        smart_4_raw  = "Number of spindle start/stop cycles"
        smart_5_raw  = "Count of reallocated sectors (bad sectors remapped)"
        smart_7_raw  = "Rate of positioning errors of the read/write head"
        smart_9_raw  = "Count of hours the drive has been powered on"
        smart_10_raw = "Number of retry attempts for spin-up"
        smart_12_raw = "Number of full power on/off cycles"
        smart_187_flag = "FLAG Uncorrectable errors reported to host"
        smart_188_flag = "FLAG Command timeouts (not completed in time)"
        smart_192_raw = "Number of times the heads retracted due to power off"
        smart_193_raw = "Times the heads have been loaded/unloaded"
        smart_194_avg_temp = "AVERAGE Drive temperature (usually Celsius)"
        smart_197_flag = "FLAG Number of sectors pending remap"
        smart_198_raw = "Uncorrectable errors found offline"
        smart_199_raw = "Errors during data transfer via the interface cable"
        event = "failure";
run;


data dane;
  set dane_pre(drop=A);
run;

proc contents data=dane;
run;

proc print data=dane (obs=10);
run;

proc freq data=dane;
table event;
run;



data dane;
    set dane;
    start_date = '01JAN1900'd + start_date - 2;
    end_date   = '01JAN1900'd + end_date - 2;
    format start_date end_date ddmmyy10.;
run;

data dane;
set dane;
if event="0" then duration_days ="";
else duration_days =duration_days ;
run;

data dane;
set dane;
if event="0" then end_date ="";
else end_date =end_date ;
run;

data dane_surv;
    set dane;

    ostatni_dzien = '31DEC2024'd;

    if event = 1 then do;
        t = end_date - start_date;
        c = 1;
    end;

    else if event = 0 then do;
        t = ostatni_dzien - start_date;
        c = 0;
    end;

    format ostatni_dzien start_date end_date ddmmyy10.;
run;


proc print data=dane_surv (obs=50);
run;

proc means data=dane_surv;
var t;
run;
proc freq data=dane_surv;
table
c;
run;


proc lifetest data=dane_surv method=lt plots=(s,h,p);
time t*c(0);
run;

proc lifetest data=dane_surv method=lt plots=(s,h);
time t*c(0);
strata datacenter;
run;

proc lifetest data=dane_surv method=lt plots=(s,h);
time t*c(0);
strata smart_188_flag;
run;



proc lifetest data=dane_surv method=pl plots=(s, ls, lls);
time t*c(0);
run;


proc lifetest data=dane_surv method=pl plots=(s);
time t*c(0);
strata smart_197_flag;
run;