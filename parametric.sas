proc lifereg data=dane.dyski outest=weib_params;
model duration_days*event(0)= /dist=weibull;
run;

data hazard_weibull;
    do t = 1 to 100000 by 1000; /* adjust time range based on your data */
        lambda = 18449.93;
        shape = 1.0636;
        hazard = (shape / lambda) * (t / lambda)**(shape - 1);
        output;
    end;
run;

proc sgplot data=hazard_weibull;
    series x=t y=hazard / lineattrs=(thickness=2 color=blue);
    xaxis label="Czas (t)";
    yaxis label="Funkcja hazardu h(t)";
    title "Funkcja hazardu - Dopasowany rozkład Weibulla";
run;

proc rank data = dane.dyski out = binned_data groups=5;
var smart_1_raw smart_3_raw smart_4_raw smart_5_raw smart_7_raw smart_9_raw 
smart_10_raw;
ranks smart_1_raw_bin smart_3_raw_bin smart_4_raw_bin smart_5_raw_bin smart_7_raw_bin smart_9_raw_bin 
smart_10_raw_bin;
run;

proc rank data = dane.dyski out = binned_data_1 groups=5;
var  smart_12_raw smart_187_flag smart_188_flag smart_192_raw smart_193_raw;
ranks smart_12_raw_bin smart_187_flag_bin smart_188_flag_bin smart_192_raw_bin
smart_193_raw_bin;
run;

proc rank data = dane.dyski out = binned_data_2 groups=5;
var  smart_194_avg_temp
smart_197_flag;
ranks smart_194_avg_temp_bin smart_197_flag_bin;
run;

proc rank data = dane.dyski out = binned_data_3 groups=5;
var smart_198_raw smart_199_raw capacity_bytes;
ranks smart_198_raw_bin smart_199_raw_bin capacity_bytes_bin;
run;

data merged_data;
merge binned_data binned_data_1 binned_data_2 binned_data_3;
by A;
run;


proc lifereg data=merged_data;
class smart_1_raw_bin smart_3_raw_bin smart_4_raw_bin smart_5_raw_bin smart_7_raw_bin smart_9_raw_bin 
smart_10_raw_bin smart_12_raw_bin smart_187_flag_bin smart_188_flag_bin smart_192_raw_bin smart_193_raw_bin smart_194_avg_temp_bin
smart_197_flag_bin smart_198_raw_bin smart_199_raw_bin capacity_bytes_bin;
model duration_days*event(0)= smart_1_raw_bin smart_3_raw_bin smart_4_raw_bin smart_5_raw_bin smart_7_raw_bin smart_9_raw_bin 
smart_10_raw_bin smart_12_raw_bin smart_187_flag_bin smart_188_flag_bin smart_192_raw_bin smart_193_raw_bin smart_194_avg_temp_bin
smart_197_flag_bin smart_198_raw_bin smart_199_raw_bin capacity_bytes_bin /dist=weibull;
run;


proc lifereg data=dane.dyski outest=log_params;
model duration_days*event(0)= /dist=llogistic;
run;

proc lifereg data=merged_data;
class smart_1_raw_bin smart_3_raw_bin smart_4_raw_bin smart_5_raw_bin smart_7_raw_bin smart_9_raw_bin 
smart_10_raw_bin smart_12_raw_bin smart_187_flag_bin smart_188_flag_bin smart_192_raw_bin smart_193_raw_bin smart_194_avg_temp_bin
smart_197_flag_bin smart_198_raw_bin smart_199_raw_bin capacity_bytes_bin;
model duration_days*event(0)= smart_1_raw_bin smart_3_raw_bin smart_4_raw_bin smart_5_raw_bin smart_7_raw_bin smart_9_raw_bin 
smart_10_raw_bin smart_12_raw_bin smart_187_flag_bin smart_188_flag_bin smart_192_raw_bin smart_193_raw_bin smart_194_avg_temp_bin
smart_197_flag_bin smart_198_raw_bin smart_199_raw_bin capacity_bytes_bin /dist=llogistic;
run;

proc lifereg data=dane.dyski;
class 
smart_187_flag
smart_188_flag
smart_197_flag;
model duration_days*event(0)= 
smart_4_raw
smart_5_raw
smart_7_raw
smart_9_raw
smart_10_raw
smart_187_flag
smart_188_flag
smart_192_raw
smart_197_flag
smart_198_raw /dist=weibull;
run;

proc lifereg data=dane.dyski;
class 
smart_187_flag
smart_188_flag
smart_197_flag;
model duration_days*event(0)= 
smart_4_raw
smart_5_raw
smart_7_raw
smart_9_raw
smart_10_raw
smart_187_flag
smart_188_flag
smart_192_raw
smart_197_flag
smart_198_raw /dist=gamma;
run;

proc lifereg data=dane.dyski;
class 
smart_187_flag
smart_188_flag
smart_197_flag;
model duration_days*event(0)= 
smart_4_raw
smart_5_raw
smart_7_raw
smart_9_raw
smart_10_raw
smart_187_flag
smart_188_flag
smart_192_raw
smart_197_flag
smart_198_raw /dist=llogistic;
run;

proc lifereg data=dane.dyski;
class 
smart_187_flag
smart_188_flag
smart_197_flag;
model duration_days*event(0)= 
smart_4_raw
smart_5_raw
smart_7_raw
smart_9_raw
smart_10_raw
smart_187_flag
smart_188_flag
smart_192_raw
smart_197_flag
smart_198_raw /dist=lnormal;
run;

%macro predict (zb_wyn=, outest=, out=_last_, xbeta=, time=);
data &zb_wyn;
_p_=1;
set &outest point=_p_;
set &out;
lp=&xbeta;
t=&time;
gamma=1/_scale_;
alpha=exp(-lp*gamma);
prob=0;
_dist_=upcase(_dist_);
if _dist_='WEIBULL' or _dist_='EXPONENTIAL' or _dist_='EXPONENT' then prob=exp(-alpha*t**gamma);
if _dist_='LOGNORMAL' or _dist_='LNORMAL' then prob=1-probnorm((log(t)-lp)/_scale_);
if _dist_='LLOGISTIC' or _dist_='LLOGISTC' then prob=1/(1+alpha*t**gamma);
if _dist_='GAMMA' then do;
d=_shape1_;
k=1/(d*d);
u=(t*exp(-lp))**gamma;
prob=1-probgam(k*u**d,k);
if d lt 0 then prob=1-prob;
end;
drop lp gamma alpha _dist_ _scale_ intercept
_shape1_ _model_ _name_ _type_ _status_ _prob_ _lnlike_ d k u;
run;
/*proc print data=_pred_;*/
/*run;*/
%mend predict;

proc lifereg data=dane.dyski outest=a; 
class 
smart_187_flag
smart_188_flag
smart_197_flag;
model duration_days*event(0)= 
smart_4_raw
smart_5_raw
smart_7_raw
smart_9_raw
smart_10_raw
smart_187_flag
smart_188_flag
smart_192_raw
smart_197_flag
smart_198_raw /dist=gamma;
output OUT=b xbeta=lp;
run;

%predict (zb_wyn=dyski_pred100, outest=a, out=b, xbeta=lp, time=100);
