% Title: Baseline VAR
% Objective: Quarterly and Annual VAR analysis to establish whether including
% inequality/distribution matters for aggregates.
% Author: Nisha Chikhale
% Date Created: 03/03/2020
% Date Modified: 03/10/2020
%% 
clc;
clear all;

%% Download data from FRED %%

url = "https://fred.stlouisfed.org/";
c = fred(url);

series1 = "GDPC1"; % real GDP quarterly data
startdate1 = '06/01/1960'; 
enddate1 = '06/01/2019'; 

d1 = fetch(c,series1,startdate1,enddate1);
d2 = getFredData('INDPRO','1960-06-01','2019-06-01', [],'q'); %industrial production quarterly data is used as an indication of fluctuations
%fetch doesn't work when you need to change the frequency of data

gdpc1 = d1.Data(1:236,2);
IP = d2.Data(1:236,2);
N = size(gdpc1,1);

close(c)
%% Compute annualized GDP growth %%
gdpt = gdpc1(2:N,1);
gdpt1 = gdpc1(1:N-1,1);
xt = 400*log(gdpt./gdpt1); %annualized gdp growth
% compute log(industrial production)
ip=log(IP);
%% Download JLN uncertainty data %%
% Import data from spreadsheet
% Script for importing data from the following spreadsheet:
%
%    Workbook: /Users/nishachikhale/Documents/Stata/Ludvigsondownload/MacroFinanceUncertainty_201908_update/MacroUncertaintyToCirculate.xlsx
%    Worksheet: Macro Uncertainty
%
% Auto-generated by MATLAB on 02-Mar-2020 13:04:15

% Setup the Import Options and import the data
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

% Clear temporary variables
clear opts

%% Import data from spreadsheet
% Script for importing data from the following spreadsheet:
%
%    Workbook: /Users/nishachikhale/Documents/Stata/Ludvigsondownload/MacroFinanceUncertainty_201908_update/FinancialUncertaintyToCirculate.xlsx
%    Worksheet: Financial Uncertainty
%
% Auto-generated by MATLAB on 05-Mar-2020 09:56:05

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
um_quarterly = table2array(MacroUncertaintyToCirculate(1:3:708,3));%grab every 3rd element in 3rd column to get quarterly macro uncertainty at h=3
uf_quarterly = table2array(FinancialUncertaintyToCirculate(1:3:708,3));
%% Baseline VAR 1.0%%
%% Choose optimal lag length %%

for k=1:4
        Mdl = varm(3,k);
        Input = [um_quarterly(k:N,1) ip(k:N,1) uf_quarterly(k:N,1)];
        EstMdl = estimate(Mdl,Input);
        Results = summarize(EstMdl);
        BICtable(k) = Results.BIC;
        AICtable(k) = Results.AIC;
end
  
disp("AIC & BIC tables are minimized at p=2 lags")
AICtable
BICtable

% parameters 
p = 2;  %number of lags
n = 3;  %number of vars 

% Report coefficients of the model %
Mdl = varm(n,p);
Input = [um_quarterly(p:N,1) ip(p:N,1) uf_quarterly(p:N,1)];
EstMdl = estimate(Mdl,Input);  %note that there is no time trend in this model
Results = summarize(EstMdl)
disp("VAR coefficients")
ARcoeffs = cell2mat(EstMdl.AR) %estimates of phi_1 and phi_2 are in here 
const = EstMdl.Constant; 
disp("VAR innovations")
sigma = EstMdl.Covariance %estimates of the innovations to the VAR, e_t 
% Note: the uncertainty data is stationary but not mean zero while the ip
% data is neither stationary nor mean zero.
% t = linspace(0,N-1,N-1);
% cla
% plot(t, Input)
%% IRFs via Cholesky Decomposition %% 
%% VARir code from Ambrogio Cesa-Bianchi's site (https://sites.google.com/site/ambropo/matlab-examples) %%
Fcomp = [ARcoeffs; eye((p-1)*n), zeros((p-1)*n,n)]
 %E = eig(Fcomp) : if eigen values of companion form have modulus less than
 %one VAR(p) is stable.
Finf_big = inv(eye(length(Fcomp))-Fcomp); % from the companion
        Finf = Finf_big(1:n,1:n);
        D  = chol(Finf*sigma*Finf')'; % identification: u2 has no effect on y in the long run (innovation on uncertainty on GDP growth)
        invA = Finf\D;
        
%% call function below to compute the IRFs %%
IRF = IRFVAR(Fcomp, invA, p, 40); %calls the function below  
%IRF_level= cumsum(IRF,2); %sums the rows of the IRF matrix
%% VAR Decomposition %%
q1=1;
q4=4;
q8=8;
%% variance decomposition for macro uncertainty shock on log(ip) %%       
vdipm_1 = sum(IRF(2,1:q1).^2)./(sum(IRF(2,1:q1).^2) + sum(IRF(5,1:q1).^2) + sum(IRF(8,1:q1).^2)) 
vdipm_4 = sum(IRF(2,1:q4).^2)./(sum(IRF(2,1:q4).^2) + sum(IRF(5,1:q4).^2) + sum(IRF(8,1:q4).^2))
vdipm_8 = sum(IRF(2,1:q8).^2)./(sum(IRF(2,1:q8).^2) + sum(IRF(5,1:q8).^2) + sum(IRF(8,1:q8).^2))
%% variance decomposition for macro uncertainty shock on financial uncertainty %%
vdufm_1 = sum(IRF(3,1:q1).^2)./(sum(IRF(3,1:q1).^2) + sum(IRF(6,1:q1).^2) + sum(IRF(9,1:q1).^2)) 
vdufm_4 = sum(IRF(3,1:q4).^2)./(sum(IRF(3,1:q4).^2) + sum(IRF(6,1:q4).^2) + sum(IRF(9,1:q4).^2))
vdufm_8 = sum(IRF(3,1:q8).^2)./(sum(IRF(3,1:q8).^2) + sum(IRF(6,1:q8).^2) + sum(IRF(9,1:q8).^2))
%% variance decomposition for macro uncertainty shock on macro uncertianty %%
vdmm_1 = 1- vdipm_1 - vdufm_1
vdmm_4 = 1- vdipm_4 - vdufm_4
vdmm_8 = 1- vdipm_8 - vdufm_8
%% variance decomposition for output shock on macro uncertainty %%
vdmip_1 = sum(IRF(4,1:q1).^2)./(sum(IRF(1,1:q1).^2) + sum(IRF(4,1:q1).^2) + sum(IRF(7,1:q1).^2)) 
vdmip_4 = sum(IRF(4,1:q4).^2)./(sum(IRF(1,1:q4).^2) + sum(IRF(4,1:q4).^2) + sum(IRF(7,1:q4).^2))
vdmip_8 = sum(IRF(4,1:q8).^2)./(sum(IRF(1,1:q8).^2) + sum(IRF(4,1:q8).^2) + sum(IRF(7,1:q8).^2))
%% variance decomposition for output shock on financial uncertainty %%
vdfip_1 = sum(IRF(6,1:q1).^2)./(sum(IRF(3,1:q1).^2) + sum(IRF(6,1:q1).^2) + sum(IRF(9,1:q1).^2)) 
vdfip_4 = sum(IRF(6,1:q4).^2)./(sum(IRF(3,1:q4).^2) + sum(IRF(6,1:q4).^2) + sum(IRF(9,1:q4).^2))
vdfip_8 = sum(IRF(6,1:q8).^2)./(sum(IRF(3,1:q8).^2) + sum(IRF(6,1:q8).^2) + sum(IRF(9,1:q8).^2))
%% variance decomposition for output shock on output %%
vdipi_1 = 1- vdmip_1 - vdfip_1
vdipi_4 = 1- vdmip_4 - vdfip_4
vdipi_8 = 1- vdmip_8 - vdfip_8
%% variance decomposition for financial uncertainty shock on macro uncertainty %%
vdmf_1 = sum(IRF(7,1:q1).^2)./(sum(IRF(1,1:q1).^2) + sum(IRF(4,1:q1).^2) + sum(IRF(7,1:q1).^2)) 
vdmf_4 = sum(IRF(7,1:q4).^2)./(sum(IRF(1,1:q4).^2) + sum(IRF(4,1:q4).^2) + sum(IRF(7,1:q4).^2))
vdmf_8 = sum(IRF(7,1:q8).^2)./(sum(IRF(1,1:q8).^2) + sum(IRF(4,1:q8).^2) + sum(IRF(7,1:q8).^2))
%% variance decomposition for financial uncertainty shock on output %%
vdipf_1 = sum(IRF(8,1:q1).^2)./(sum(IRF(2,1:q1).^2) + sum(IRF(5,1:q1).^2) + sum(IRF(8,1:q1).^2)) 
vdipf_4 = sum(IRF(8,1:q4).^2)./(sum(IRF(2,1:q4).^2) + sum(IRF(5,1:q4).^2) + sum(IRF(8,1:q4).^2))
vdipf_8 = sum(IRF(8,1:q8).^2)./(sum(IRF(2,1:q8).^2) + sum(IRF(5,1:q8).^2) + sum(IRF(8,1:q8).^2))
%% variance decomposition for financial uncertainty shock on financial uncertainty %%
vdff_1 = 1- vdmf_1 - vdipf_1
vdff_4 = 1- vdmf_4 - vdipf_4
vdff_8 = 1- vdmf_8 - vdipf_8
%% plot 1-20 quarter horizon IRFs %%
% parameters for IRFs
time = linspace(0,20,20);
quarters = time;

%plot the IRF of macro uncertainty shock (shock to var 1)
figure(1)
cla
plot(quarters, IRF(1,1:20),'-') %macro uncertainty
hold on
plot(quarters, IRF(2,1:20),'-.') %ip
hold on
plot(quarters, IRF(3,1:20),'--') %financial uncertainty
title('IRF: Response to a Macro Uncertainty Shock')
legend('Macro Uncertainty h=3','log(Industrial Production)','Financial Uncertainty h=3')
saveas(figure(1),[pwd '/plots/1Q_1.png']);

%plot the IRF of an output shock (var 2)
figure(2)
cla
plot(quarters, IRF(4,1:20),'-') %macro uncertainty
hold on
plot(quarters, IRF(5,1:20),'-.') %ip
hold on
plot(quarters, IRF(6,1:20),'--') %financial uncertainty
title('IRF: Response to an Output Shock')
legend('Macro Uncertainty h=3','log(Industrial Production)','Financial Uncertainty h=3')
saveas(figure(2),[pwd '/plots/1Q_2.png']);

%plot the IRF of a financial uncertainty shock (var 3)
figure(3)
cla
plot(quarters, IRF(7,1:20),'-') %macro uncertainty
hold on
plot(quarters, IRF(8,1:20),'-.') %ip
hold on
plot(quarters, IRF(9,1:20),'--') %financial uncertainty
title('IRF: Response to a Financial Uncertainty Shock')
legend('Macro Uncertainty h=3','log(Industrial Production)','Financial Uncertainty h=3')
saveas(figure(3),[pwd '/plots/1Q_3.png']);

%% Download data from FRED %%

url = "https://fred.stlouisfed.org/";
c = fred(url);

d3 = getFredData('INDPRO','1960-06-01','2019-06-01', [],'a'); %industrial production annual data 
IP_ann = d3.Data(1:60,2);
N = size(IP_ann,1);

close(c)

%% Create annual vars %%
ip=log(IP_ann);
um_ann = table2array(MacroUncertaintyToCirculate(6:12:702,4));%grab every 12th element in 4th column to get annual macro uncertainty at h=12
uf_ann = table2array(FinancialUncertaintyToCirculate(6:12:702,4));

%% Baseline VAR 1.1%%
%% Choose optimal lag length %%

for k=1:4
        Mdl = varm(3,k);
        Input = [um_ann(k:N-1,1) ip(k:N-1,1) uf_ann(k:N-1,1)];
        EstMdl = estimate(Mdl,Input);
        Results = summarize(EstMdl);
        BICtable(k) = Results.BIC;
        AICtable(k) = Results.AIC;
end
  
disp("AIC & BIC tables are minimized at p=1 lag")
AICtable
BICtable

% parameters 
p = 1;  %number of lags
n = 3;  %number of vars 

% Report coefficients of the model %
Mdl = varm(n,p);
Input = [um_ann(p:N-1,1) ip(p:N-1,1) uf_ann(p:N-1,1)];
EstMdl = estimate(Mdl,Input);  %note that there is no time trend in this model
Results = summarize(EstMdl)
disp("VAR coefficients")
ARcoeffs = cell2mat(EstMdl.AR) %estimates of phi_1 and phi_2 are in here 
const = EstMdl.Constant; 
disp("VAR innovations")
sigma = EstMdl.Covariance %estimates of the innovations to the VAR, e_t 

%% IRFs %% 
%% VARir code from Ambrogio Cesa-Bianchi's site (https://sites.google.com/site/ambropo/matlab-examples) %%
Fcomp = [ARcoeffs; eye((p-1)*n), zeros((p-1)*n,n)]
    
Finf_big = inv(eye(length(Fcomp))-Fcomp); % from the companion
        Finf = Finf_big(1:n,1:n);
        D  = chol(Finf*sigma*Finf')'; % identification: u2 has no effect on y in the long run (innovation on uncertainty on real activity)
        invA = Finf\D;
        
%% call function below to compute the IRFs %%
IRF = IRFVAR(Fcomp, invA, p, 10); %calls the function below 

%% VAR Decomposition %%
%% variance decomposition for macro uncertainty shock on log(ip) %%       
y1=1;
y2=2;
vdip_1 = sum(IRF(2,1:y1).^2)./(sum(IRF(2,1:y1).^2) + sum(IRF(5,1:y1).^2) + sum(IRF(8,1:y1).^2)) 
vdip_2 = sum(IRF(2,1:y2).^2)./(sum(IRF(2,1:y2).^2) + sum(IRF(5,1:y2).^2) + sum(IRF(8,1:y2).^2))

%% variance decomposition for macro uncertainty shock on financial uncertainty %%
vduf_1 = sum(IRF(3,1:y1).^2)./(sum(IRF(3,1:y1).^2) + sum(IRF(6,1:y1).^2) + sum(IRF(9,1:y1).^2)) 
vduf_2 = sum(IRF(3,1:y2).^2)./(sum(IRF(3,1:y2).^2) + sum(IRF(6,1:y2).^2) + sum(IRF(9,1:y2).^2))
%% plot 1-5 year horizon IRFs %%
% parameters for IRFs
time = linspace(0,5,5);
years = time;

%plot the IRF of macro uncertainty shock (var 1)
figure(4)
cla
plot(years, IRF(1,1:5),'-') %macro uncertainty
hold on
plot(years, IRF(2,1:5),'-.') %ip
hold on
plot(years, IRF(3,1:5),'--') %financial uncertainty
title('IRF: Response to a Macro Uncertainty Shock')
legend('Macro Uncertainty h=12','log(Industrial Production)','Financial Uncertainty h=12')
saveas(figure(4),[pwd '/plots/11A_4.png']);

%plot the IRF of an output shock (var 2)
figure(5)
cla
plot(years, IRF(4,1:5),'-') %macro uncertainty
hold on
plot(years, IRF(5,1:5),'-.') %ip
hold on
plot(years, IRF(6,1:5),'--') %financial uncertainty
title('IRF: Response to an Output Shock')
legend('Macro Uncertainty h=12','log(Industrial Production)','Financial Uncertainty h=12')
saveas(figure(5),[pwd '/plots/11A_5.png']);

%plot the IRF of a financial uncertianty shock (var 3)
figure(6)
cla
plot(years, IRF(7,1:5),'-') %macro uncertainty
hold on
plot(years, IRF(8,1:5),'-.') %ip
hold on
plot(years, IRF(9,1:5),'--') %financial uncertainty
title('IRF: Response to a Financial Uncertainty Shock')
legend('Macro Uncertainty h=12','log(Industrial Production)','Financial Uncertainty h=12')
saveas(figure(6),[pwd '/plots/11A_6.png']);


%% IRFVAR function %%
function [IRF]=IRFVAR(A,A0inv,p,h)

q=size(A0inv,1);
J=[eye(q,q) zeros(q,q*(p-1))];
IRF=reshape(J*A^0*J'*A0inv,q^2,1);

for i =1:h
    IRF=([IRF reshape(J*A^i*J'*A0inv,q^2,1)]); %added a . before *A0inv
   
end
end 
