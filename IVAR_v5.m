% Title: Interacted VAR
% Objective: Quarterly I-VAR
% Author: Nisha Chikhale
% Date Created: 05/01/2020
% Date Modified: 05/20/2020

%% 
clc;
clear;


addpath '/Users/nishachikhale/Documents/MATLAB/ECON718/StateDependenceofAggUncertainty/code/caggianoetal2017_data_and_replication_codes'
addpath '/Users/nishachikhale/Documents/MATLAB/ECON718/StateDependenceofAggUncertainty/code/caggianoetal2017_data_and_replication_codes/I-VAR tbx_/utils by A. Cesa Bianchi'
addpath '/Users/nishachikhale/Documents/MATLAB/ECON718/StateDependenceofAggUncertainty/code/caggianoetal2017_data_and_replication_codes/I-VAR tbx_'
addpath '/Users/nishachikhale/Documents/MATLAB/ECON718/StateDependenceofAggUncertainty/code/caggianoetal2017_data_and_replication_codes/I-VAR tbx_/utils for figures'

%% Download data from FRED %%
% The sample in JKO is 1985-2018 quarterly, I do 1985-present quarterly
url = "https://fred.stlouisfed.org/";
c = fred(url);

d1 = getFredData('GDPC1','1984-09-01','2019-06-01', [],'q'); 
d2 = getFredData('PCE','1984-09-01','2019-06-01', [],'q'); 
d3 = getFredData('PAYEMS','1984-09-01','2019-06-01', [],'q'); 
d4 = getFredData('FEDFUNDS','1984-09-01','2019-06-01', [],'q'); 
d5 = getFredData('DGS10','1984-09-01','2019-06-01', [],'q');
d6 = getFredData('PCEND','1984-09-01','2019-06-01', [],'q');
d7 = getFredData('HOHWMN02USM065S','1984-09-01','2019-06-01', [],'q');
d8 = getFredData('UNRATE','1984-09-01','2019-06-01', [],'q');
d9 = getFredData('LNS12300060','1984-09-01','2019-06-01', [],'q');
d10 = getFredData('CE16OV','1984-09-01','2019-06-01', [],'q');
d11 = getFredData('GDPDEF','1984-09-01','2019-06-01', [],'q');

gdpc1 = d1.Data(1:139,2);
N = size(gdpc1,1);
gdpt = gdpc1(2:N,1);
gdpt1 = gdpc1(1:N-1,1);
el = d10.Data(2:139,2);
elt1 = d10.Data(1:138,2);
ffr = d4.Data(2:139,2);
nd = d6.Data(1:139,2);
ndt = nd(2:N,1);
ndt1 = nd(1:N-1,1);
def = d11.Data(2:139,2);
deft1 = d11.Data(1:138,2);

close(c)

%% Download Shadow rate data %%
%% Import data from spreadsheet
% Script for importing data from the following spreadsheet:
%
%    Workbook: /Users/nishachikhale/Documents/MATLAB/ECON718/StateDependenceofAggUncertainty/RawData/shadowrate_US.xls
%    Worksheet: Sheet1
%
% Auto-generated by MATLAB on 20-Apr-2020 07:41:10

%% Setup the Import Options and import the data
opts = spreadsheetImportOptions("NumVariables", 3);

% Specify sheet and range
opts.Sheet = "Sheet1";
opts.DataRange = "A1:C363";

% Specify column names and types
opts.VariableNames = ["VarName1", "VarName2", "VarName3"];
opts.VariableTypes = ["double", "double", "double"];

% Import the data
shadowrateUS = readtable("/Users/nishachikhale/Documents/MATLAB/ECON718/StateDependenceofAggUncertainty/RawData/shadowrate_US.xls", opts, "UseExcel", false);


%% Clear temporary variables
clear opts
%1990q1:2020q1
srate = table2array(shadowrateUS(1:3:363,3));

%% Download JLN uncertainty data %%

%% Import data from spreadsheet
% Script for importing data from the following spreadsheet:
%
%    Workbook: /Users/nishachikhale/Documents/Stata/Ludvigsondownload/MacroFinanceUncertainty_201908_update/MacroUncertaintyToCirculate.xlsx
%    Worksheet: Macro Uncertainty
%
% Auto-generated by MATLAB on 13-Mar-2020 12:57:22

%% Setup the Import Options and import the data
opts = spreadsheetImportOptions("NumVariables", 4);

% Specify sheet and range
opts.Sheet = "Macro Uncertainty";
opts.DataRange = "A2:D709";

% Specify column names and types
opts.VariableNames = ["Date", "h1", "h3", "h12"];
opts.VariableTypes = ["datetime", "double", "double", "double"];

% Specify variable properties
opts = setvaropts(opts, "Date", "InputFormat", "");

% Import the data
MacroUncertaintyToCirculate = readtable("/Users/nishachikhale/Documents/Stata/Ludvigsondownload/MacroFinanceUncertainty_201908_update/MacroUncertaintyToCirculate.xlsx", opts, "UseExcel", false);


%% Clear temporary variables
clear opts
%% Import data from spreadsheet
% Script for importing data from the following spreadsheet:
%
%    Workbook: /Users/nishachikhale/Documents/Stata/Ludvigsondownload/MacroFinanceUncertainty_201908_update/FinancialUncertaintyToCirculate.xlsx
%    Worksheet: Financial Uncertainty
%
% Auto-generated by MATLAB on 13-Mar-2020 12:57:46

%% Setup the Import Options and import the data
opts = spreadsheetImportOptions("NumVariables", 4);

% Specify sheet and range
opts.Sheet = "Financial Uncertainty";
opts.DataRange = "A2:D709";

% Specify column names and types
opts.VariableNames = ["Date", "h1", "h3", "h12"];
opts.VariableTypes = ["datetime", "double", "double", "double"];

% Specify variable properties
opts = setvaropts(opts, "Date", "InputFormat", "");

% Import the data
FinancialUncertaintyToCirculate = readtable("/Users/nishachikhale/Documents/Stata/Ludvigsondownload/MacroFinanceUncertainty_201908_update/FinancialUncertaintyToCirculate.xlsx", opts, "UseExcel", false);


%% Clear temporary variables
clear opts
%% Create uncertainty variables %%
um_q = table2array(MacroUncertaintyToCirculate(295:3:708,3));%grab every 3rd element in 3rd column to get quarterly macro uncertainty at h=3
um1_q = table2array(MacroUncertaintyToCirculate(295:3:708,2)); %h=1
uf_q = table2array(FinancialUncertaintyToCirculate(295:3:708,3));
%% compute log of first differences of variables and annualize GDP, P and Emp
 x1 = (log(def) - log(deft1))*400; 
 x2 = (log(gdpt) - log(gdpt1))*400;
 x3 = (log(ndt) - log(ndt1))*400;
 x4 = (log(el) - log(elt1))*400;
 x5 = ffr;
 %% Import data from spreadsheet
% Script for importing data from the following spreadsheet:
%
%    Workbook: /Users/nishachikhale/Documents/MATLAB/ECON718/StateDependenceofAggUncertainty/RawData/DFA_FRB/dfa-9050ratio-clean.xlsx
%    Worksheet: Sheet1
%
% Auto-generated by MATLAB on 21-Mar-2020 11:22:35

%% Setup the Import Options and import the data
opts = spreadsheetImportOptions("NumVariables", 16);

% Specify sheet and range
opts.Sheet = "Sheet1";
opts.DataRange = "A2:P123";

% Specify column names and types
opts.VariableNames = ["date", "a", "b", "c", "bottom", "year", "Q", "top1", "top10", "top50", "ratio", "ratio2", "ratio3", "ratio4", "ratio5", "quarter"];
opts.VariableTypes = ["string", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double"];

% Specify variable properties
opts = setvaropts(opts, "date", "WhitespaceRule", "preserve");
opts = setvaropts(opts, "date", "EmptyFieldRule", "auto");

% Import the data
dfa9050ratioclean = readtable("/Users/nishachikhale/Documents/MATLAB/ECON718/StateDependenceofAggUncertainty/RawData/DFA_FRB/dfa-9050ratio-clean.xlsx", opts, "UseExcel", false);


%% Clear temporary variables
clear opts
%% Create in sample 1989Q3:2019Q2 %%
um_q = table2array(MacroUncertaintyToCirculate(349:3:708,3)); 
um1_q = table2array(MacroUncertaintyToCirculate(349:3:708,2)); 
uf_q = table2array(FinancialUncertaintyToCirculate(349:3:708,3));
ratio = table2array(dfa9050ratioclean(1:120,11)); %90/50
ratio2 = table2array(dfa9050ratioclean(1:120,12)); %1/bottom 50
ratio3 = table2array(dfa9050ratioclean(1:120,13)); %50/50
ratio4 = table2array(dfa9050ratioclean(1:120,14)); %1/90
ratio5 = table2array(dfa9050ratioclean(1:120,15)); %1/top 50
% test different measure of inequality
%ratio = ratio5;  warning: the matrix is close to singular when using ratio4 and ratio5!!!! >> results may be inaccurate

x1 = x1(19:138,1); 
x2 = x2(19:138,1);
x3 = x3(19:138,1);
x4 = x4(19:138,1);
x5 = [x5(1:2,1) ; srate(1:118,1)]; %appends effective funds rate to shadow rate for first 2 quarters in sample
interact = um1_q.*ratio;
Int_lag = [lagmatrix(interact,1) lagmatrix(interact,2) lagmatrix(interact,3)];
data = [um1_q ratio x1 x2 x3 x4 x5 Int_lag];


%% Estimate VAR w/ interaction term %%
% specification  
numend = 7;  %number of endogenous vars 
%lag selection can be done later for now make it deterministic
nlags = 2; %lag length
c_case = 1; %1 for constant, 2 for constant and trend in our VAR 
data_end = data(:,1:numend);% endogenous data
data_ex = data(:,numend+1:numend+nlags); % exogenous data + lagged interaction terms
nsteps = 12;
pick = 1; %order of variable to shock 
ordend=pick ; % ordering (as in the Chol-decomp) of the I endogenous variable with which to do the interactions (the shocked variable)
ordend2=2; % ordering (as in the Chol-decomp) of the II endogenous variable with which to do the interactions (usually the variable along with some states are then defined)
[nobs] = size(data_end,1);
% OLS estimation Interacted-VAR
VAR= VARmodel(data_end,nlags,c_case,data_ex);

%% selection of the initial histories defining low and high inequality %%
thres = median(ratio);
il = 1;
ih = 1;
for t = 1:nobs-nlags
    if (VAR.X(t,3) < thres)
        historiesL(il,:) = VAR.X(t,:);
        il = il+1;
    elseif (VAR.X(t,3) >= thres)
        historiesH(ih,:) = VAR.X(t,:);
        ih = ih+1;
    end
end

%% obtain point estimates for state-dependent GIRFs %%
draws=500;
typeImpulse=0; % 0 if 1st.dev shock, 1 if 1unit increase shock. Whatever else gives exactly the size of the shock in st.dev. terms
mode=0;  % 0 to draw from the empirical distribution of residuals for future shocks/ 1 from a Gaussian distribution respecting the VCV matrix for the future shocks
% for sample state-conditional GIRFs
[OIRFavg,OIRF_optavg]=VARirtrue_sim1shock_histories_futureN(VAR,nsteps+5,pick,historiesL,ordend,ordend2,draws,mode,typeImpulse,0);
[OIRF2avg,OIRF_opt2avg]=VARirtrue_sim1shock_histories_futureN(VAR,nsteps+5,pick,historiesH,ordend,ordend2,draws,mode,typeImpulse,0);
% ---------- keep just the nsteps ahead needed
OIRFavg=OIRFavg(1:nsteps,:,:);
OIRF2avg=OIRF2avg(1:nsteps,:,:);
% ----------

% diagnostic explosiveness/instability:
disp('DIAGNOSTIC FOR GIRFS POINT ESTIMATES:')
disp(['- The number of explosive initial histories discarded is: ' num2str(OIRF_optavg.nexplos) ' for the low inequality state and ', num2str(OIRF_opt2avg.nexplos) ' for the high inequality state'])
if max(OIRF_optavg.countRep)>0
disp('- It was needed to repeat some particularly extreme residual extractions for at least one initial history. For details see OIRF_optavg.countRep and OIRF_opt2avg.countRep')
end
disp('------------------------------------------------------')

%% Obtain bootstrapped confidence intervals %%
fast = 0; fast=0; %1 to be fast (avoid estraction future shocks in obtaining the GIRF - is a fairly good approximation/ 0 to consider them
perc=50; % percentile used to separe the two states (on ratio) inside the bootstrap procedure 

[INFavgL2, SUPavgL2, MEDavgL2, INFavgH2, SUPavgH2, MEDavgH2, IRFdrawsL, IRFdrawsH] = VARirbandtrue_endint1shock_historiesEnd2_futureN(VAR,OIRF_optavg,pick,perc,1000,68,typeImpulse,fast);

% ---------- keep just the nsteps ahead needed
INFavgL2=INFavgL2(1:nsteps,:,:);
SUPavgL2=SUPavgL2(1:nsteps,:,:);
MEDavgL2=MEDavgL2(1:nsteps,:,:);
INFavgH2=INFavgH2(1:nsteps,:,:);
SUPavgH2=SUPavgH2(1:nsteps,:,:);
MEDavgH2=MEDavgH2(1:nsteps,:,:);
IRFdrawsL=IRFdrawsL(1:nsteps,:,:,:);
IRFdrawsH=IRFdrawsH(1:nsteps,:,:,:);
% ----------

%formatting figures
set(groot,'defaultLineLineWidth',1.5);
FontSize=16;
labels = {'Uncertainty';'90/50 ratio';'Inflation';'GDP growth';'N.D. Consumption growth';'Employment growth';'sFFR'};

%% plot sample/point estimated responses at the center Confidence Intervals %%
figure(1)
cla;
VARirplot_2New_CCP(OIRF2avg,OIRFavg,pick, labels,'irf',ordend2,INFavgH2,SUPavgH2,INFavgL2,SUPavgL2,FontSize)
saveas(figure(1),[pwd '/plots/ivar/v5_fig1.png']);
%% test statistic for the difference between the two state-conditional GIRFs %%

pctg=68;
select=pick;
[dIRFinf,dIRFsup,dIRFmed]=VAR_intstat(IRFdrawsH,IRFdrawsL,select,pctg);
pctg=68;
[dIRFinf2,dIRFsup2,dIRFmed2]=VAR_intstat(IRFdrawsH,IRFdrawsL,select,pctg);

% at the center bands there is the sample difference among responses:
%dOIRFavg=OIRFavg(:,:,pick)-OIRF2avg(:,:,pick);
dOIRFavg=OIRF2avg(:,:,pick)-OIRFavg(:,:,pick);
figure(2)
cla;
VARtestplot_2New_CCP(dOIRFavg,dOIRFavg,pick,labels,'test',ordend2,dIRFinf2,dIRFsup2,dIRFinf2,dIRFsup2,FontSize)
saveas(figure(2),[pwd '/plots/ivar/v5_fig2.png']);

save('ivar_v5.mat');
