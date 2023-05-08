%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                COMMENTS                                 %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%{
The carbohydate coverage ratio: 500 / (0.55 * weight_) = 1 unit insulin /
11.086474 g CHO
1 unit of Insulin drop BGL by 50 ml/dL, 1 unit of insulin cover CCR

Very Low BG : <54 mg/dL
Low BG :  54-72 mg/dL
Mid BG :  72-180 mg/dL
High BG :  180-250 mg/dL
Very High BG : >250 mg/dL

Based on info from healthline.com for each CCR
1 unit of insulin should be taken, hence 1 unit of insulin would decrease
the GBL by approx 50 mg/dL.

Insulin starts acting on BGL within one hour, which makes it absorption
rate : 50mg/dL/h -> 0.8(3)mg/dL/min

CHO get digested anywhere from 30min to 6hrs. To make this system easier, i
will assume the digestion rate to be anywhere wrom 90-180 mins (18(5min) - 36(5min))

CCR = 1(u ins) = 50(mg/dL/digestion time (bgl));

TOTAL BGL INCREASE FROM MEAL = (CHO / CCR) * 50;
TOTAL BGL INCREASE FROM MEAL DISTR WITH DIGESTION RATE =
(CHO / CCR) * (50 / (floor(rand(1) * (18 - 36) + 37) * 5));

BGL(n+1) = BGL(n) + ;

::idea{ maybe should add MAX DAILY DOSE input that would compare values of
MDD and how much of insulin has already been given to the body, hence
adjusting how FIS distributes insulind

::idea{ change code so that insulin dose is calculated up to the last
value in table?

BGL : mg/dL
BGR : mg/dL/min
BGA : mg/dL/min^2

based on data from the real life scenario of type 1 diabetes patient
we assume that max diff between BGL can be within 2u/min (10u/5mins)
for BGR [-2 2]
for BGA [-0.8 0.8]

% set custom carbs intake (optional) if unset test_data defaults to the og values
%test_data = cho_intake(dbname, [50 50 50 50 50], [40 240 440 640 840], "overwrite");

iteration 1 : adjusted rulebase to lower insulin dose when BGL is v_low/low
iteration 2 : adjusted rulebase to lower insulin dose when BGR/BGA are negative
iteration 3 : edited CHO and insulin absorption formulas
iteration 4: self-adjusting fis tree that adjusts value ranges based on
real-life data, adjusted BGA from [-0.8 0.8] to [-0.7 0.7]
iteration 5: after last iteration big jumps in BGL started to occur. it was
decided to rework cho blood distribution and make it normal instead of
constant (check cho_distr.m), corrected normal distributiob algorithm as
well as BGR/BGA optimization function
iteration 6: cahnge rules in AP_FIST: FIS(2).PD:Low & BGA:Mid => ID:Low
Iteration 7: after tweeking with rules i realized that the range of the
'Mid' BGL is too broad and i want to narrow it.
Iteration 8: changed produced charts, working on BGL ranges and rules
Iteration 9: try lowering the max for mid mf of BGL
Iteration 10: Changed TGA/CAT settings
Iteration 11: compare how different are the outcomes in v6.3.2 and v6.4.2!
The difference is three rules

Iteration 12: all tests were run with patient's weight being 82,
configurations with less and more weight had been run as well.
%}

set(0, 'DefaultFigureVisible', 'off')
[~, fname, ext] = fileparts(string({dir('db/*.xlsx').name}));
path = append('db/', fname, ext);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            MAIN FILE START                              %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

weight = 82;
version = '_gauss.10.5';
randomize = false;

% RUN ALL DATABASES
%    for i = 1:size(fname,2)
%        DIABETIC_PATIENT(weight, fname(i), version, path(i), randomize)
%    end

% RUN SPECIFIC DATABASE
DIABETIC_PATIENT(weight, "norm", version, "db/norm.xlsx", randomize)
DIABETIC_PATIENT(weight, "norm", version, "db/norm.xlsx", randomize)
DIABETIC_PATIENT(weight, "norm", version, "db/norm.xlsx", randomize)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                              MAIN FILE END                              %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
