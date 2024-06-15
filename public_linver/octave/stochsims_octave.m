% ******************************************************************
% Program to run stochastic simulations of LINVER in Octave under
% various assumptions for agents' expectations, monetary policy, and
% the manner in which random shocks are drawn. Prior to setting
% parameters and running the program, users should review the
% stochsims user manual in the Matlab folder.
%
% Notes:
%
% (1) Dynare is used to process the model file and generate the
%     decision-rule matrices, so the user must set the path to the
%     Dynare directory in or before running the program.
% (2) This program can also be run in Matlab.
%
%*******************************************************************

clear all;

% Provide the path to Dynare (eg, addpath c:/dynare/5.0/matlab)


% Supply model settings (mandatory unless otherwise indicated)
%   expvers -- expectational version of the model
%   mprule -- the federal funds rate rule
%   elb_imposed -- "yes" or "no"
%   elb -- lower limit of RFF (mandatory if ELB imposed)
%
%   tax_gamma -- optional setting for the cyclicality of the trend
%     personal tax rate TRPTS (default is .00125 for full model
%     consistent expectations, .00075 for other expectational
%     cases)
%   ctp_option -- optional switch indicating standard model
%     cyclical term premium effects if 0 (default), suppression of
%     all cyclical TP effects if 1, and alternative more stable
%     estimated cyclical TP effects if 2
%   ecfs_option -- optional switch indicating application of
%     extreme case fiscal stabilization to prevent the expected
%     output gap from falling too low (default is "yes" if
%     elb_imposed = "yes, otherwise default is "no")
%   ecfs_floor -- optional ECFS-induced lower bound on the
%     expected output gap (default is -15)

% mandatory
expvers = "mcap";
mprule = "intay";
elb_imposed = "yes";
elb = -2;  % required only if elb_imposed = "yes"

% optional
%tax_gamma = .00075;
%ctp_option = 2;
%ecfs_option = "no";
%ecfs_floor = -25;



% Supply optional monetary policy settings
%   elbqtrs -- number of quarters the ELB imposed on the expected
%     RFF path (default is 1 under VAR expectations and 61
%     otherwise)
%   asymqtrs -- number of quarters the expected RFF path is forced
%     to conform to the prescriptions of a nonlinear rule, if
%     selected (default is elbqtrs if defined, 61 otherwise except
%     under VAR expectations)
%   uthresh_imposed -- "yes" or "no" to imposing an unemployment
%     gap threshold that must be satisfied for liftoff from the ELB
%     (default is "no")
%   pithresh_imposed -- "yes" or "no" to imposing an inflation
%     threshold that must be satisfied for liftoff from the ELB
%     (default is "no")
%   uthresh -- value of unemployment gap threshold, if imposed
%   pithresh -- value of inflation threshold, if imposed
%   pithresh_var -- measure used to define threshold, if imposed
%   maxfgq -- the number of quarters the unemployment and inflation
%     threshold condition are imposed on the expected RFF path
%     (optional, default is elbqtrs)

%elbqtrs = 101;
%asymqtrs = 21;
%uthresh_imposed = "yes";
%uthresh = 0;
%pithresh_imposed = "yes";
%pithresh = 0;
%pithresh_var = "picx4";
%maxfgq = 21;




% Supply optional simulation parameters
%   add_track_names -- variables for which simulation results are
%     retained in addition to the default set
%   nreplic -- number of simulated outcomes (default is 5000)
%   nsimqtrs -- length in quarters of each outcome (default is 200)
%   residuals_file -- name of text file of historical equation
%     shocks (default is "hist_residuals.txt")
%   draw_method -- sampling procedure (default is "state")
%   res_drop -- names of shocks to be excluded
%   alt_range -- alternative historical range for sample (default
%     is ["1970Q1","2019Q4"])
%   rescale_wpshocks -- rescaling of pre-1983 wage and price
%     residuals to match post-1982 variances (default is "yes")
%   save_option -- "full" or "limited" results saved to disk
%     (default is "none")
%   save_name -- name of file in current directory where results are
%     saved if save_option is invoked (default is stochsims_results)

%add_track_names = {"fiscal"};
%nreplic = 500;
%nsimqtrs = 300;
%residuals_file = 'hist_residuals.txt';
%draw_method = "mvnorm";
%res_drop = {"pbfir_l_aerr","pegfr_l_aerr","pegsr_l_aerr","phr_l_aerr","pxr_l_aerr"};
%alt_range = {"1983Q1","2019Q4"};
%rescale_wpshocks = "no";
%save_option = "limited";
%save_name = "savefile";


% ****************************************************************
% miscellaneous checks
% ****************************************************************

% if using Octave, load the econometrics (for prettyprint)
% and io (for xlsread) packages
if exist('OCTAVE_VERSION')
    warning('off', 'Octave:possible-matlab-short-circuit-operator');
    pkg load io;
    pkg load econometrics;
end


% If using Matlab, change some cell arrays to strings
if ~exist('OCTAVE_VERSION')
    if exist('alt_range')
        alt_range = string(alt_range);
    end
    if exist('res_drop')
        res_drop = string(res_drop);
    end
    if exist('add_track_names')
        add_track_names = string(add_track_names);
    end
end



tic

% Verify the validity of user-selected settings and define various
% parameters used in stochastic simulations

make_parameters_octave;
if strcmp(fail_flag,"yes")
    return
end

if ~exist('OCTAVE_VERSION')
    track_names = string(track_names);
end


% Construct the version of the model to be stochastically simulated
% based on the user-supplied and default parameter settings and
% process it using DYNARE

make_runmod_octave;
if strcmp(fail_flag,"yes")
    return
end


% Retrieve DYNARE results and construct various matrices and
% namelists to be used to run stochastic simulations

make_matrices_octave;
if strcmp(fail_flag,"yes")
    return
end

% Construct a matrix of shocks randomly sampled from the set of
% historical shocks to be applied in the stochastic simulations

make_shocks_octave;
if strcmp(fail_flag,"yes")
    return
end

runtime_setup = toc;

% ****************************************************************
% stochastic simulations
% ****************************************************************

tic

% Run the stochastic simulations and then compute summary
% statistics

stochloop_octave;

runtime_sim = toc;

disp("    ");
disp(['Setup run time = ',num2str(runtime_setup,'%.2f')])
disp(['Simulation run time = ',num2str(runtime_sim,'%.2f')])
disp("    ");


% Compute summary statistics and if selected, save results

summarize_results_octave;
