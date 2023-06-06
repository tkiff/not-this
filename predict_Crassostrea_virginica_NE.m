function [prdData, info] = predict_Crassostrea_virginica_NE(par, data, auxData)

% unpack par, data, auxData
cPar = parscomp_st(par); vars_pull(par); vars_pull(cPar); vars_pull(data); vars_pull(auxData);

filterChecks = ... % f contrained to not be larger than 1 or negeative
                 f_Kiff2022 > 1 || f_Kiff2022 < 0 || ... ;
                 f_GrizWard2017 > 1 || f_GrizWard2017 < 0 || ... ;
                 f_KraeFord2007 > 1 || f_KraeFord2007 < 0 || ... ;
                 f_LeviDoal2013 > 1 || f_LeviDoal2013 < 0 || ... ;
                 f_tL1_Davi1999 > 1 || f_tL1_Davi1999 < 0 || ... ;
                 f_tL2_Davi1999 > 1 || f_tL2_Davi1999 < 0;
             


if filterChecks
   info    = 0;
   prdData = {};
   return;
end

pars_T    = [T_A T_L T_H T_AL T_AH];

% compute temperature correction factors
TC_ab           = tempcorr(temp.ab, T_ref, T_A);
TC_aj           = tempcorr(temp.aj, T_ref, T_A);
TC_ap           = tempcorr(temp.ap, T_ref, T_A);
TC_am           = tempcorr(temp.am, T_ref, T_A); 
TC_R97          = tempcorr(temp.R97, T_ref, T_A);
% TC_Ri          = tempcorr(temp.Ri, T_ref, T_A);
TC_KraeFord2007 = tempcorr(temp.tL_KraeFord2007, T_ref, T_A);
TC_GrizWard2017 = tempcorr(temp.tL_GrizWard2017, T_ref, T_A);
TC_tL1_Davi1999 = tempcorr(temp.tL1_Davi1999, T_ref, T_A); 
TC_tL2_Davi1999 = tempcorr(temp.tL2_Davi1999, T_ref, T_A);
TC_LF = tempcorr(temp.LF, T_ref, T_A);
% TC_10           = tempcorr(temp.WdJO_10, T_ref, pars_T);
% TC_20           = tempcorr(temp.WdJO_20, T_ref, pars_T);
% TC_30           = tempcorr(temp.WdJO_30, T_ref, pars_T);

%% Zero-variate data
% Life cycle
pars_tj = [g; k; l_T; v_Hb; v_Hj; v_Hp];
[t_j, t_p, t_b, l_j, l_p, l_b, l_i, ~, ~, info] = get_tj(pars_tj, f); % -, scaled times & lengths at f

% Birth
L_b  = L_m * l_b;                 % cm, structural length at birth at f
Lw_b = L_b / del_Mb;              % cm, physical length at birth at f
Wd_b = L_b^3 * d_V * (1 + f * w); % g,  dry weight at birth at f
aT_b = t_b / k_M / TC_ab;         % d,  age at birth at f and T

% Metamorphosis
L_j  = L_m * l_j;                 % cm, structural length at metamorphosis at f
Lw_j = L_j / del_Mb;              % cm, physical length at metamorphosis at f
Wd_j = L_j^3 * d_V * (1 + f * w); % g,  dry weight at metamorphosis at f
aT_j = t_j / k_M / TC_aj;         % d,  age at metamorphosis at f and T
s_M  = l_j / l_b;                 % -,  acceleration factor for v and {p_Am} at f

% Puberty 
L_p  = L_m * l_p;                 % cm, structural length at puberty at f
Lw_p = L_p / del_Mj;              % cm, physical length at puberty at f
Wd_p = L_p^3 * d_V * (1 + f * w); % g,  dry weight at puberty at f
aT_p = t_p / k_M / TC_ap;         % d,  age at puberty at f and T

% Ultimate
L_i  = L_m * l_i;                 % cm, ultimate structural length at f
Lw_i = L_i / del_Mj;              % cm, ultimate physical length at f
Wd_i = L_i^3 * d_V * (1 + f * w); % g,  ultimate dry weight


% reproduction
pars_R = [kap; kap_R; g; k_J; k_M; L_T; v; U_Hb;U_Hj;  U_Hp];  % compose parameter vector at T
R97 = TC_R97 * reprod_rate_j(9.7 * del_Mj, f, pars_R);       % #/d, ultimate reproduction rate at T

% % original ultimate reproduction
% pars_R = [kap; kap_R; g; k_J; k_M; L_T; v; U_Hb; U_Hj; U_Hp];
% RT_i   = TC_Ri * reprod_rate_j(L_i, f, pars_R); % #/d, ultimate reproduction rate at T

% Life span
pars_tm = [g; l_T; h_a / k_M^2; s_G];
t_m     = get_tm_s(pars_tm, f, l_b); % -, scaled mean life span at T_ref
aT_m    = t_m / k_M / TC_am;         % d, mean life span at T

% Pack to output
prdData.ab  = aT_b;
prdData.aj  = aT_j;
prdData.ap  = aT_p;
prdData.am  = aT_m;
prdData.Lb  = Lw_b;
prdData.Lj  = Lw_j;
prdData.Lp  = Lw_p;
prdData.Li  = Lw_i;
prdData.Wdb = Wd_b;
prdData.Wdj = Wd_j;
prdData.Wdp = Wd_p;
prdData.Wdi = Wd_i;
prdData.R97 = R97;
%prdData.Ri  = RT_i;

%% Uni-variate data
% tL data from tL_KraeFord2007
f = f_KraeFord2007; TC = TC_KraeFord2007; tL = tL_KraeFord2007;
[t_j, ~, t_b, l_j, ~, l_b, l_i, rho_j, rho_B] = get_tj(pars_tj, f);
rT_j = TC * rho_j * k_M; rT_B = TC * rho_B * k_M;
L_b  = l_b * L_m; L_j = l_j * L_m; L_i = l_i * L_m;
tT_j = (t_j - t_b) / k_M / TC;                                    % d,  time since birth at metamorphosis
t_bj = tL(tL(:,1) < tT_j,1);                                      % d,  select times before metamorphosis
L_bj = (L_b * exp(t_bj * rT_j / 3)) / del_Mb;                     % cm, physical length at exponential growth as V1-morph
t_ji = tL(tL(:,1) >= tT_j,1);                                     % d,  select times after metamorphosis
L_ji = (L_i - (L_i - L_j) * exp(-rT_B * (t_ji - tT_j))) / del_Mj; % cm, physical length at isomorphic growth
EL_KraeFord2007 = [L_bj; L_ji];                                   % cm,  expected physical length at time

% tL data from GrizWard2017
f = f_GrizWard2017; TC = TC_GrizWard2017; tL = tL_GrizWard2017;
[t_j, ~, t_b, l_j, ~, l_b, l_i, rho_j, rho_B] = get_tj(pars_tj, f);
rT_j = TC * rho_j * k_M; rT_B = TC * rho_B * k_M;
L_b  = l_b * L_m; L_j = l_j * L_m; L_i = l_i * L_m;
tT_j = (t_j - t_b) / k_M / TC;                                    % d,  time since birth at metamorphosis
t_bj = tL(tL(:,1) < tT_j,1);                                      % d,  select times before metamorphosis
L_bj = (L_b * exp(t_bj * rT_j / 3)) / del_Mb;                     % cm, physical length at exponential growth as V1-morph
t_ji = tL(tL(:,1) >= tT_j,1);                                     % d,  select times after metamorphosis
L_ji = (L_i - (L_i - L_j) * exp(-rT_B * (t_ji - tT_j))) / del_Mj; % cm, physical length at isomorphic growth
EL_GrizWard2017 = [L_bj; L_ji]; % cm,  expected physical length at time
% Weight data adapted from ...
L = L_i - (L_i - L_j) * exp( - rT_B * (tWd_GrizWard2017(:,1) - tT_j)); % cm, total length
EWd_GrizWard2017 = (L.^3 * (1 + f_GrizWard2017 * ome)) * d_V; % g, wet weight 

% LWw data from Kiff2022
f   = f_Kiff2022;
EWd = ((LWd(:,1) * del_Mj).^3 * (1 + w * f)) * d_V; % g, expected dry weight

% tL 1 - Upper DRE w/varying temp from AmP entry Aequipecten_opercalaris
[~, ~, ~, ~, ~, ~, l_i, ~, rho_B] = get_tj(pars_tj, f_tL1_Davi1999);
r_B = rho_B * k_M; L_i = l_i * L_m;
[t L] = ode45(@get_L1, tL1_Davi1999(:,1), Lw_0_davi1999*del_Mj, [], r_B, L_i, T_ref, pars_T); 
EL_tL1_Davi1999 = L/ del_Mj;

% tL2 - DMC w/varying temp from AmP entry Aequipecten_opercalaris
[~, ~, ~, ~, ~, ~, l_i, ~, rho_B] = get_tj(pars_tj, f_tL2_Davi1999);
r_B = rho_B * k_M; L_i = l_i * L_m;
[t L] = ode45(@get_L2, tL2_Davi1999(:,1), Lw_0_davi1999*del_Mj, [], r_B, L_i, T_ref, pars_T); 
EL_tL2_Davi1999 = L/ del_Mj;

% length - filtering rate
EF = TC_LF * F_m * (LF(:,1)*del_Mj).^2; % l/d, filtering rate (on natural seston)

% from littorina littorina
%f = f_LeviDoal2013; 
L_0T = (Wd_0_LeviDoal2013/ (1 + f_LeviDoal2013 * w)/ d_V)^(1/3);
% from Assiminea japonica
[~, ~, ~, ~, ~, ~, l_i, ~, rho_B] = get_tj(pars_tj, f_LeviDoal2013);
r_B = rho_B * k_M; L_i = l_i * L_m;
[t, L] = ode45(@get_L3, tWd_LeviDoal2013(:,1), L_0T, [], L_i, r_B, T_ref, pars_T);
EWd_LeviDoal2013 = L.^3 * (1 + f_LeviDoal2013 * w) * d_V; % mg, AFDW

% % Respiration data from ShumKoen1982
% p_ref  = p_Am * L_m^2; % J/d, max assimilation power at max size and T_ref
% pars_p = [kap; kap_R; g; k_J; k_M; L_T; v; U_Hb; U_Hj; U_Hp];
% % at T = 10 C
% f      = 1;
% e      = 1;                                                         % -,     scaled reserve density e = f at f = 1
% TC     = TC_10;                                                     % -,     temperature correction factor
% L      = (WdJO_10(:,1) / (1 + f * w) / d_V).^(1/3);                 % cm,    structural length
% l      = L / L_m;                                                   % -,     scaled length
% p_ref  = TC * (p_Am * s_M) * L_m^2;                                 % J/d,   reference power after metamorphosis
% p_A    = f * l.^2;                                                  % -,     scaled assimilation power (page 78 DEB book)
% p_D    = kap * l.^3  + (1 - kap) * e .* l.^2 .* (g + l) ./ (g + e); % -,     scaled dissapating power (page 77 DEB book)
% p_G    = kap * l.^2 .* (e - l - l_T) / (1 + e / g);                 % -,     scaled growth power (page 78 DEB book)
% p_ADG  = p_ref * [p_A, p_D, p_G];                                   % J/d,   basic powers
% J_M    = -(n_M \ n_O) * eta_O * p_ADG';                             % mol/d, mineral fluxes
% J_O    = -24.4e9 / 24 * J_M(3,:)';                                  % nL/h,  O2-consumption (from predict_Crassostrea_gigas)
% EJO_10 = J_O / 1000000;                                             % mL/h,  O2-consumption
% % at T = 20 C
% TC     = TC_20;                                                     % -,     temperature correction factor
% L      = (WdJO_20(:,1) / (1 + f * w) / d_V).^(1/3);                 % cm,    structural length
% l      = L / L_m;                                                   % -,     scaled length
% p_ref  = TC * (p_Am * s_M) * L_m^2;                                 % J/d,   reference power after metamorphosis
% p_A    = f * l.^2;                                                  % -,     scaled assimilation power (page 78 DEB book)
% p_D    = kap * l.^3  + (1 - kap) * e .* l.^2 .* (g + l) ./ (g + e); % -,     scaled dissapating power (page 77 DEB book)
% p_G    = kap * l.^2 .* (e - l - l_T) / (1 + e / g);                 % -,     scaled growth power (page 78 DEB book)
% p_ADG  = p_ref * [p_A, p_D, p_G];                                   % J/d,   basic powers
% J_M    = -(n_M \ n_O) * eta_O * p_ADG';                             % mol/d, mineral fluxes
% J_O    = -24.4e9 / 24 * J_M(3,:)';                                  % nL/h,  O2-consumption (from predict_Crassostrea_gigas)
% EJO_20 = J_O / 1000000;                                             % mL/h,  O2-consumption
% % at T = 30 C
% TC     = TC_30;                                                     % -,     temperature correction factor
% L      = (WdJO_30(:,1) / (1 + f * w) / d_V).^(1/3);                 % cm,    structural length
% l      = L / L_m;                                                   % -,     scaled length
% p_ref  = TC * (p_Am * s_M) * L_m^2;                                 % J/d,   reference power after metamorphosis
% p_A    = f * l.^2;                                                  % -,     scaled assimilation power (page 78 DEB book)
% p_D    = kap * l.^3  + (1 - kap) * e .* l.^2 .* (g + l) ./ (g + e); % -,     scaled dissapating power (page 77 DEB book)
% p_G    = kap * l.^2 .* (e - l - l_T) / (1 + e / g);                 % -,     scaled growth power (page 78 DEB book)
% p_ADG  = p_ref * [p_A, p_D, p_G];                                   % J/d,   basic powers
% J_M    = -(n_M \ n_O) * eta_O * p_ADG';                             % mol/d, mineral fluxes
% J_O    = -24.4e9 / 24 * J_M(3,:)';                                  % nL/h,  O2-consumption (from predict_Crassostrea_gigas)
% EJO_30 = J_O / 1000000;                                             % mL/h,  O2-consumption

% Pack to output
prdData.tL_KraeFord2007 = EL_KraeFord2007;
prdData.tL_GrizWard2017 = EL_GrizWard2017;
prdData.tWd_GrizWard2017 = EWd_GrizWard2017;
prdData.LWd              = EWd;
prdData.tL1_Davi1999    = EL_tL1_Davi1999;
prdData.tL2_Davi1999    = EL_tL2_Davi1999;
prdData.LF              = EF;
% prdData.WdJO_10  = EJO_10;
% prdData.WdJO_20  = EJO_20;
% prdData.WdJO_30  = EJO_30;
prdData.tWd_LeviDoal2013 = EWd_LeviDoal2013;

end

%% sin function varying temperature 

function dL = get_L1(t, L, r_B, L_i, T_ref, pars_T)
  TC = tempcorr(C2K(12.5+10*sin(2*pi*((t+148)+245)/365)), T_ref, pars_T);
  dL = TC * r_B * (L_i -L); 
end

function dL = get_L2(t, L, r_B, L_i, T_ref, pars_T)
  TC = tempcorr(C2K(10+8.4*sin(2*pi*((t+148)+233)/365)), T_ref, pars_T);
  dL = TC * r_B * (L_i -L);
end

function dL = get_L3(t, L, L_i, r_B, T_ref, pars_T)
  TC = tempcorr(C2K(14.4+12.9*sin(2*pi*((t+160)+252)/365)), T_ref, pars_T);
  dL = TC * r_B * (L_i - L);
end


