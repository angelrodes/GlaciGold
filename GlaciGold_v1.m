% init
clear
close all hidden

%% Input parameters
whater_depth=[0 100]; % cm (river depth range)
last_deglaciation=[11000 11500]; % years (range for last deglaciation)
ice_depth=1000; % m (deph under ice during glaciations)
nuclide=3; % the mass of the cosmonuclide
% Measured Apparent Surface Exposure Ages (ASEA)
ASEA=[20e3 100e3 1e6 2e6 4e6]; % years


%% load constants
if exist('consts.mat', 'file') ~= 2 % create if needed
    constants
end
load('consts.mat')
density=1; % water density
densityice=consts.rhoice; % ice density
    
%% load climatecurves
make_climatecurves % NGRIP+ data (see NUNAIT paper)
close all hidden % close plot generated by make_climatecurves.m
load climatecurves.mat
% get last deglaciation 
climatecurves.lastdeg=0.*climatecurves.age;
for step=1:numel(climatecurves.age)
    climatecurves.lastdeg(step)=min(climatecurves.age(climatecurves.d18O>=climatecurves.d18O(step)));
end


%% Calculate d18O thresholds
selection= climatecurves.lastdeg<max(last_deglaciation) &...
    climatecurves.lastdeg>min(last_deglaciation);
if sum(selection)>0
    d18O_thresholds=[min(climatecurves.d18O(selection)) max(climatecurves.d18O(selection))];
else % if no results, get the closest d18O value
    distance=abs(climatecurves.lastdeg-mean(last_deglaciation));
    selection=find(distance==min(distance),1,'first');
    d18O_thresholds=[1 1]*climatecurves.d18O(selection);
end
plot_d18O=climatecurves.d18O(selection);

%% Get prodution rate parameters
mucont= muon_contribution(NaN,NaN,nuclide); % use global average for muon contributions
P=[consts.Psp(consts.nuclides==nuclide)*(1-mucont.value),consts.Pmu(consts.nuclides==nuclide,:)*mucont.value];
L=[consts.Lsp,consts.Lmu];
l=consts.l(consts.nuclides==nuclide);
l=l+log(2)/(1000*4543e6); % add a small decay (1000 times earth age) to simplify math with stable isotopes
apparent_age=@(concentration) log(1-min(max(concentration,0)*l,1))/(-l); % a

%% Define models to run
d18O_model=[min(d18O_thresholds) max(d18O_thresholds) min(d18O_thresholds) max(d18O_thresholds)];
zwater_model=[min(whater_depth) max(whater_depth)  max(whater_depth)  min(whater_depth)];
nmodels=numel(d18O_model);

%% Make input matrices 
Production_rates=repmat(P,nmodels,1);
Attenuation_lengths=repmat(L,nmodels,1);
decay_constant=repmat(l,nmodels,1);

[sample_index,p_index,climate_index]=ndgrid(1:numel(d18O_model),1:size(Production_rates,2),1:numel(climatecurves.age));

% Dimensions:
% 1 samples: d18O_model zwater_model
% 2 production rates
% 3 climate curves

T=climatecurves.age(climate_index); 
ZW=zwater_model(sample_index);
D=d18O_model(sample_index); % thresholds
MC=D.*0+mucont.value;
dMC=D.*0+mucont.uncert;
lmatrix=D.*0+l;
E=0; % glacial erosion
W=0; % interglacial weathering
P=repmat(Production_rates,[1,1,numel(climatecurves.age)]);
L=repmat(Attenuation_lengths,[1,1,numel(climatecurves.age)]);

% Define step lengths (years)
climatecurves.dage=diff([climatecurves.age,4543e6]);
dT=climatecurves.dage(climate_index);

% glaciated times
G=(climatecurves.d18O(climate_index)>D);

% erosion during each step (from NUNAIT)
Zi=E.*dT.*G+W.*dT.*~G;

% depths (under water)
Z=cumsum(Zi,numel(size(Zi)))-Zi+ZW;

% depths under ice
ZICE=G.*ice_depth*100; % cm

%% Accumulation model
Cii=...
    P./(lmatrix+W.*density./L).*...
    exp(-(Z.*density+ZICE.*densityice)./L).*...
    (1-exp(-(lmatrix+W.*density./L).*dT)).*...
    exp(-lmatrix.*T);

% Sum for all production rates
Ci=sum(Cii,numel(size(Cii))-1);

% Cumulative sum for each exhumation age
C=cumsum(Ci,numel(size(Ci)));

% Apparent Surface Exposure Age of the models
ASEA_models=apparent_age(permute(C,[1,3,2])); % a
ASEA_models_min=min(ASEA_models);
ASEA_models_max=max(ASEA_models);

% Exhumation ages
EX_models=[climatecurves.age(2:end),4543e6];

%% Calcualte exhumation ages for the ASEAs

max_ref=ASEA_models_max+[1:numel(ASEA_models_max)]/numel(ASEA_models_max);
min_ref=ASEA_models_min-[1:numel(ASEA_models_min)]/numel(ASEA_models_min);
for sample=1:numel(ASEA)
    ASEAi=ASEA(sample);
    max_ex_age(sample)=interp1(max_ref,EX_models,ASEAi);
    min_ex_age(sample)=interp1(min_ref,EX_models,ASEAi);
end

%% Text output
disp(' ')
disp('------------------')
disp('GLACIGOLD')
disp('Angel Rodes, 2022')
disp('------------------')
disp(['ASEA' char(9)...
    'Exhumation age range'])
disp(['(' consts.nuclidesstring{consts.nuclides==nuclide} ' a)' char(9)...
    '(a)'])
for sample=1:numel(ASEA)
    disp([num2str(round(ASEA(sample))) char(9)...
        num2str(round(min_ex_age(sample))) '-' num2str(round(max_ex_age(sample)))])
end
disp(' ')

%% Plots

% Plot model
figure
hold on
plot([1 2],[1 1]*d18O_thresholds(1),'-b','LineWidth',2) % for legend
plot([1 2],[1 1]*d18O_thresholds(1),'-g','LineWidth',2) % for legend
plot(climatecurves.age,climatecurves.d18O,'-','Color','k','LineWidth',2) % plot d18O curve
legend(['Glaciated (' num2str(ice_depth) ' m of ice)'],...
    ['Exposed (' num2str(min(whater_depth)/100) '-' num2str(max(whater_depth)/100) ' m of water)'],...
    climatecurves.ver,...
    'Location','southwest')
legend('AutoUpdate','off')
for h=plot_d18O
    glaciated=climatecurves.age(climatecurves.d18O>=h);
    plot(glaciated,glaciated.*0+h,'.b')
    deglaciated=climatecurves.age(climatecurves.d18O<=h);
    plot(deglaciated,deglaciated.*0+h,'.g')
    last_exp=[1 climatecurves.age(find(climatecurves.d18O>h,1,'first')-1)];
    plot(last_exp,last_exp.*0+h,'-g','LineWidth',2)
end
plot(climatecurves.age,climatecurves.d18O,'-','Color','k','LineWidth',2) % plot d18O curve again
ylabel('\delta^{18}O')
set(gca, 'Xdir', 'reverse')
xlabel('Age (a)')
set(gca, 'XScale', 'log')
xlim([1e3 1e7])
box on 
grid on
title('GlaciGold model')


% plot apparent age vs. exhumation age (model)
figure
hold on
plot(EX_models,EX_models,'--g') % 1:1 line
for sample=1:numel(ASEA) 
    plot([1 1]*ASEA(sample),[min_ex_age(sample) max_ex_age(sample)],'-r') % sample range
end
plot(ASEA_models_min,EX_models,'-k','LineWidth',2) % min model
plot(ASEA_models_max,EX_models,'-k','LineWidth',2) % max model
% plot(ASEA_models,EX_models,'--m') % 4 models (testing)
set(gca, 'XScale', 'log')
xlim([1e2 1e8])
set(gca, 'YScale', 'log')
ylim([1e2 1e8])
grid on
box on
ylabel('Exhumation age (years)')
% xlabel([consts.nuclidesstring{consts.nuclides==nuclide} ' ASEA'])
xlabel([consts.nuclidesstring{consts.nuclides==nuclide} ' Apparent Surface Exposure Age'])
title('GlaciGold ages')

