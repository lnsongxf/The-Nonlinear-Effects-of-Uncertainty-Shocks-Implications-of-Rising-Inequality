% Title: VAR w/Inequality 
% Objective: Annual VAR analysis to establish whether including
% inequality/distribution matters for aggregates.
% Author: Nisha Chikhale
% Date Created: 03/05/2020
% Date Modified: 03/10/2020
%% 
clc;
clear all;
%% Download data from FRED %%

url = "https://fred.stlouisfed.org/";
c = fred(url);

d1 = getFredData('INDPRO','1966-01-01','2017-12-01', [],'a'); %industrial production annual data 
d2 =  getFredData('INDPRO','1960-06-01','2019-06-01', [],'q');
d3 = getFredData('PRS85006173','1960-06-01','2019-06-01', [],'q');
IP_ann = d1.Data(1:52,2);
IP_q = d2.Data(1:236,2);
LS_q = d3.Data(1:236,2);
N_ann = size(IP_ann,1)-1;
N_q = size(IP_q,1);

close(c)
%% Import data from spreadsheet
% Script for importing data from the following spreadsheet:
%
%    Workbook: /Users/nishachikhale/Documents/Stata/Ludvigsondownload/MacroFinanceUncertainty_201908_update/MacroUncertaintyToCirculate.xlsx
%    Worksheet: Macro Uncertainty
%
% Auto-generated by MATLAB on 05-Mar-2020 11:48:41

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
MacroUncertaintyToCirculate1 = readtable("/Users/nishachikhale/Documents/Stata/Ludvigsondownload/MacroFinanceUncertainty_201908_update/MacroUncertaintyToCirculate.xlsx", opts, "UseExcel", false);


%% Clear temporary variables
clear opts
%% Import data from spreadsheet
% Script for importing data from the following spreadsheet:
%
%    Workbook: /Users/nishachikhale/Documents/Stata/Ludvigsondownload/MacroFinanceUncertainty_201908_update/FinancialUncertaintyToCirculate.xlsx
%    Worksheet: Financial Uncertainty
%
% Auto-generated by MATLAB on 05-Mar-2020 11:49:28

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
FinancialUncertaintyToCirculate1 = readtable("/Users/nishachikhale/Documents/Stata/Ludvigsondownload/MacroFinanceUncertainty_201908_update/FinancialUncertaintyToCirculate.xlsx", opts, "UseExcel", false);


%% Clear temporary variables
clear opts
%% Import data from text file
% Script for importing data from the following text file:
%
%    filename: /Users/nishachikhale/Documents/Stata/718proposal/output/dinavar62-16.csv
%
% Auto-generated by MATLAB on 05-Mar-2020 13:18:04

%% Setup the Import Options and import the data
opts = delimitedTextImportOptions("NumVariables", 2);

% Specify range and delimiter
opts.DataLines = [2, Inf];
opts.Delimiter = ",";

% Specify column names and types
opts.VariableNames = ["year", "m2post"];
opts.VariableTypes = ["double", "double"];

% Specify file level properties
opts.ExtraColumnsRule = "ignore";
opts.EmptyLineRule = "read";

% Import the data
dinavar6216 = readtable("/Users/nishachikhale/Documents/Stata/718proposal/output/dinavar62-16.csv", opts);

%Note this data goes from 2016:1962 (backwards) so we need to flip the
%vector
%% Clear temporary variables
clear opts

%% Create quarterly vars %%
ip_q = log(IP_q);
um_q = table2array(MacroUncertaintyToCirculate1(1:3:708,3));%grab every 3rd element in 3th column to get quarterly macro uncertainty at h=3
uf_q = table2array(FinancialUncertaintyToCirculate1(1:3:708,3));
ls_q = log(LS_q);
%% Create annual vars %%
ip_ann = log(IP_ann);
%ip=log(IP_ann(2:52,1)); ip one year ahead
um_ann = table2array(MacroUncertaintyToCirculate1(78:12:678,4));%grab every 12th element in 4th column to get annual macro uncertainty at h=12
uf_ann = table2array(FinancialUncertaintyToCirculate1(78:12:678,4));
var_ann = flipud(table2array(dinavar6216(1:51,2)));
lnvar_ann = log(var_ann);
%% Baseline VAR 2.0%%
%% Choose optimal lag length %%
%keep p=2 the optimal lag length from VAR 1.0 w/o inequality

% parameters 
p = 2;  %number of lags
n = 4;  %number of vars

% Report coefficients of the model %
%This model doesn't have a good measure if inequality (labor share of
%income). I don't think we should use this for comparison.
Mdl = varm(n,p);
Input = [ls_q(p:N_q,1) um_q(p:N_q,1) ip_q(p:N_q,1) uf_q(p:N_q,1)];  
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
        D  = chol(Finf*sigma*Finf')'; % identification: u2 has no effect on y in the long run (innovation on uncertainty on GDP growth)
        invA = Finf\D;
        
%% call function below to compute the IRFs %%
IRF = IRFVAR(Fcomp, invA, p, 20); %calls the function below 


%% plot 1-20 quarter horizon IRFs %%
% parameters for IRFs
time = linspace(0,20,20);
quarters = time;

%plot the IRF of a labor share shock (var 1)
figure(1)
cla
plot(quarters, IRF(1,1:20), ':') %labor share of income
hold on
plot(quarters, IRF(2,1:20), '-') %macro uncertainty
hold on
plot(quarters, IRF(3,1:20), '-.') %ip
hold on
plot(quarters, IRF(4,1:20), '--') %financial uncertainty
title('IRF: Response to a Labor Share Shock')
legend('log(Labor Share of Income)','Macro Uncertainty h=3','log(Industrial Production)','Financial Uncertainty h=3')
saveas(figure(1),[pwd '/plots/2Q_1.png']);

%plot the IRF of a macro uncertainty shock (var 2)
figure(2)
cla
plot(quarters, IRF(5,1:20), ':') %labor share of income
hold on
plot(quarters, IRF(6,1:20), '-') %macro uncertainty
hold on
plot(quarters, IRF(7,1:20), '-.') %ip
hold on
plot(quarters, IRF(8,1:20), '--') %financial uncertainty
title('IRF: Response to a Macro Uncertainty Shock')
legend('log(Labor Share of Income)','Macro Uncertainty h=3','log(Industrial Production)','Financial Uncertainty h=3')
saveas(figure(2),[pwd '/plots/2Q_2.png']);


%plot the IRF of a output uncertainty shock (var 3)
figure(3)
cla
plot(quarters, IRF(9,1:20), ':') %labor share of income
hold on
plot(quarters, IRF(10,1:20), '-') %macro uncertainty
hold on
plot(quarters, IRF(11,1:20), '-.') %ip
hold on
plot(quarters, IRF(12,1:20), '--') %financial uncertainty
title('IRF: Response to an Output Shock')
legend('log(Labor Share of Income)','Macro Uncertainty h=3','log(Industrial Production)','Financial Uncertainty h=3')
saveas(figure(3),[pwd '/plots/2Q_3.png']);

%plot the IRF of a financial uncertainty shock (var 4)
figure(4)
cla
plot(quarters, IRF(13,1:20), ':') %labor share of income
hold on
plot(quarters, IRF(14,1:20), '-') %macro uncertainty
hold on
plot(quarters, IRF(15,1:20), '-.') %ip
hold on
plot(quarters, IRF(16,1:20), '--') %financial uncertainty
title('IRF: Response to a Financial Uncertainty shock')
legend('log(Labor Share of Income)','Macro Uncertainty h=3','log(Industrial Production)','Financial Uncertainty h=3')
saveas(figure(4),[pwd '/plots/2Q_4.png']);

%% Baseline VAR 2.1%%
%% Choose optimal lag length %%
%keep p=1 the optimal lag length from VAR 1.1 w/o inequality

% parameters 
p = 1;  %number of lags
n = 4;  %number of vars 

% Report coefficients of the model %
Mdl = varm(n,p);
Input = [lnvar_ann(p:N_ann,1) um_ann(p:N_ann,1) ip_ann(p:N_ann,1) uf_ann(p:N_ann,1)]; 
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
        D  = chol(Finf*sigma*Finf')'; % identification: u2 has no effect on y in the long run (innovation on uncertainty on GDP growth)
        invA = Finf\D;
        
%% call function below to compute the IRFs %%
IRF = IRFVAR(Fcomp, invA, p, 10); %calls the function below 

%% VAR Decomposition %%
%% variance decomposition for macro uncertainty shock on log(ip) %%       
y1=1;
y2=2;
vdip_1 = sum(IRF(7,1:y1).^2)./(sum(IRF(3,1:y1).^2) + sum(IRF(7,1:y1).^2) + sum(IRF(11,1:y1).^2) + sum(IRF(15,1:y1).^2)) 
vdip_2 = sum(IRF(7,1:y2).^2)./(sum(IRF(3,1:y2).^2) + sum(IRF(7,1:y2).^2) + sum(IRF(11,1:y2).^2) + sum(IRF(15,1:y2).^2))

%% variance decomposition for macro uncertainty shock on financial uncertainty %%
vduf_1 = sum(IRF(8,1:y1).^2)./(sum(IRF(4,1:y1).^2) + sum(IRF(8,1:y1).^2) + sum(IRF(12,1:y1).^2) + sum(IRF(16,1:y1).^2)) 
vduf_2 = sum(IRF(8,1:y2).^2)./(sum(IRF(4,1:y2).^2) + sum(IRF(8,1:y2).^2) + sum(IRF(12,1:y2).^2) + sum(IRF(16,1:y2).^2))
%% variance decomposition for macro uncertainty shock on inequality %%
vdin_1 = sum(IRF(5,1:y1).^2)./(sum(IRF(1,1:y1).^2) + sum(IRF(5,1:y1).^2) + sum(IRF(9,1:y1).^2) + sum(IRF(13,1:y1).^2)) 
vdin_2 = sum(IRF(5,1:y2).^2)./(sum(IRF(1,1:y2).^2) + sum(IRF(5,1:y2).^2) + sum(IRF(9,1:y2).^2) + sum(IRF(13,1:y2).^2))

%% plot 1-5 year horizon IRFs %%
% parameters for IRFs
time = linspace(0,5,5);
years = time;

%plot the IRF of an Inequality shock (var 1)
figure(5)
cla
plot(years, IRF(1,1:5), ':') %variance of income distribution
hold on
plot(years, IRF(2,1:5), '-') %macro uncertainty
hold on
plot(years, IRF(3,1:5), '-.') %ip
hold on
plot(years, IRF(4,1:5), '--') %financial uncertainty
title('IRF: Response to an Inequality Shock')
legend('log(Variance of Income Distribution)','Macro Uncertainty h=12','log(Industrial Production)','Financial Uncertainty h=12')
saveas(figure(5),[pwd '/plots/21A_5.png']);


%plot the IRF of a macro uncertainty shock (var 2)
figure(6)
cla
plot(years, IRF(5,1:5), ':') %variance of income distribution
hold on
plot(years, IRF(6,1:5), '-') %macro uncertainty
hold on
plot(years, IRF(7,1:5), '-.') %ip
hold on
plot(years, IRF(8,1:5), '--') %financial uncertainty
title('IRF: Response to a Macro Uncertainty Shock')
legend('log(Variance of Income Distribution)','Macro Uncertainty h=12','log(Industrial Production)','Financial Uncertainty h=12')
saveas(figure(6),[pwd '/plots/21A_6.png']);


%plot the IRF of an output shock (var 3)
figure(7)
cla
plot(years, IRF(9,1:5), ':') %variance of income distribution
hold on
plot(years, IRF(10,1:5), '-') %macro uncertainty
hold on
plot(years, IRF(11,1:5), '-.') %ip
hold on
plot(years, IRF(12,1:5), '--') %financial uncertainty
title('IRF: Response to an Output Shock')
legend('log(Variance of Income Distribution)','Macro Uncertainty h=12','log(Industrial Production)','Financial Uncertainty h=12')
saveas(figure(7),[pwd '/plots/21A_7.png']);

%plot the IRF of a financial uncertainty shock (var 4)
figure(8)
cla
plot(years, IRF(13,1:5), ':') %variance of income distribution
hold on
plot(years, IRF(14,1:5), '-') %macro uncertainty
hold on
plot(years, IRF(15,1:5), '-.') %ip
hold on
plot(years, IRF(16,1:5), '--') %financial uncertainty
title('IRF: Response to a Financial Uncertianty Shock')
legend('log(Variance of Income Distribution)','Macro Uncertainty h=12','log(Industrial Production)','Financial Uncertainty h=12')
saveas(figure(8),[pwd '/plots/21A_8.png']);


%% IRFVAR function %%
function [IRF]=IRFVAR(A,A0inv,p,h)

q=size(A0inv,1);
J=[eye(q,q) zeros(q,q*(p-1))];
IRF=reshape(J*A^0*J'*A0inv,q^2,1);

for i =1:h
    IRF=([IRF reshape(J*A^i*J'*A0inv,q^2,1)]); %added a . before *A0inv
   
end
end 
