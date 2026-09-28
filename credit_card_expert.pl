% =============================================================================
% EXPERT SYSTEM: Credit Card Eligibility Advisor (CCE-ES)
% =============================================================================

:- dynamic fact/1.
:- dynamic explanation/1.

% -----------------------------------------------------------------------------
% 1. KNOWLEDGE BASE: 20 Base Facts
% -----------------------------------------------------------------------------
card_product(classic_card).
card_product(silver_card).
card_product(gold_card).
card_product(platinum_card).

min_applicant_age(18).
max_applicant_age(65).

min_tenure_salaried(6).
min_tenure_self_employed(24).

min_income_classic(30000).
min_income_silver(60000).
min_income_gold(120000).
min_income_platinum(250000).

credit_score_range(poor, 300, 579).
credit_score_range(fair, 580, 669).
credit_score_range(good, 670, 739).
credit_score_range(very_good, 740, 799).
credit_score_range(exceptional, 800, 850).

dti_threshold_healthy(0.35).
dti_threshold_acceptable(0.50).
dti_threshold_critical(0.50).

% -----------------------------------------------------------------------------
% Explanation Tracker Utilities
% -----------------------------------------------------------------------------
clear_memory :-
    retractall(fact(_)),
    retractall(explanation(_)).

log_reason(RuleID, Reason) :-
    assertz(explanation(rule(RuleID, Reason))).

% -----------------------------------------------------------------------------
% 2. KNOWLEDGE BASE: 20 Inference Rules
% -----------------------------------------------------------------------------

% --- Category A: Demographic & Stability ---
% Rule 1: Age Eligible
eval_rule(1) :-
    fact(age(A)), A >= 18, A =< 65,
    assertz(fact(status(age_eligible))),
    log_reason('Rule 1', 'Applicant age is within the eligible range (18 to 65).').

% Rule 2: Age Disqualified
eval_rule(2) :-
    fact(age(A)), (A < 18 ; A > 65),
    assertz(fact(disqualified('Applicant falls outside the statutory age boundaries (18-65).'))),
    log_reason('Rule 2', 'Applicant fails statutory age criteria.').

% Rule 3: Salaried Stability
eval_rule(3) :-
    fact(employment(salaried)), fact(tenure(M)), M >= 6,
    assertz(fact(status(employment_stable))),
    log_reason('Rule 3', 'Salaried tenure is >= 6 months; employment is stable.').

% Rule 4: Self-Employed Stability
eval_rule(4) :-
    fact(employment(self_employed)), fact(tenure(M)), M >= 24,
    assertz(fact(status(employment_stable))),
    log_reason('Rule 4', 'Self-employed business operations exceed 24 months.').

% Rule 5: Employment Disqualification
eval_rule(5) :-
    \+ fact(status(employment_stable)),
    assertz(fact(disqualified('Insufficient employment tenure for unsecured credit.'))),
    log_reason('Rule 5', 'Employment history lacks required stability duration.').

% --- Category B: Credit Score Evaluation ---
% Rule 6: Exceptional Score
eval_rule(6) :-
    fact(credit_score(S)), S >= 800, S =< 850,
    assertz(fact(credit_rating(exceptional))),
    log_reason('Rule 6', 'Credit score >= 800 is classified as EXCEPTIONAL.').

% Rule 7: Very Good Score
eval_rule(7) :-
    fact(credit_score(S)), S >= 740, S < 800,
    assertz(fact(credit_rating(very_good))),
    log_reason('Rule 7', 'Credit score between 740 and 799 is classified as VERY GOOD.').

% Rule 8: Good Score
eval_rule(8) :-
    fact(credit_score(S)), S >= 670, S < 740,
    assertz(fact(credit_rating(good))),
    log_reason('Rule 8', 'Credit score between 670 and 739 is classified as GOOD.').

% Rule 9: Fair Score
eval_rule(9) :-
    fact(credit_score(S)), S >= 580, S < 670,
    assertz(fact(credit_rating(fair))),
    log_reason('Rule 9', 'Credit score between 580 and 669 is classified as FAIR.').

% Rule 10: Poor Score
eval_rule(10) :-
    fact(credit_score(S)), S >= 300, S < 580,
    assertz(fact(credit_rating(poor))),
    log_reason('Rule 10', 'Credit score < 580 indicates POOR credit risk.').

% --- Category C: Debt-to-Income (DTI) Evaluation ---
% Rule 11: Healthy DTI
eval_rule(11) :-
    fact(monthly_income(Inc)), fact(existing_debt(Debt)), Inc > 0,
    DTI is Debt / Inc, DTI =< 0.35,
    assertz(fact(dti_ratio(DTI))),
    assertz(fact(dti_rating(healthy))),
    log_reason('Rule 11', 'Debt-to-Income ratio <= 35% is rated HEALTHY.').

% Rule 12: Moderate DTI
eval_rule(12) :-
    fact(monthly_income(Inc)), fact(existing_debt(Debt)), Inc > 0,
    DTI is Debt / Inc, DTI > 0.35, DTI =< 0.50,
    assertz(fact(dti_ratio(DTI))),
    assertz(fact(dti_rating(moderate))),
    log_reason('Rule 12', 'Debt-to-Income ratio is between 36% and 50% (MODERATE).').

% Rule 13: Critical DTI
eval_rule(13) :-
    fact(monthly_income(Inc)), fact(existing_debt(Debt)), Inc > 0,
    DTI is Debt / Inc, DTI > 0.50,
    assertz(fact(dti_ratio(DTI))),
    assertz(fact(dti_rating(critical))),
    log_reason('Rule 13', 'Debt-to-Income ratio exceeds 50% (CRITICAL over-indebtedness).').

% --- Category D: Composite Risk Derivation ---
% Rule 14: Ultra Low Risk
eval_rule(14) :-
    fact(credit_rating(exceptional)), fact(dti_rating(healthy)),
    assertz(fact(risk_profile(ultra_low))),
    log_reason('Rule 14', 'Exceptional credit combined with healthy DTI confirms ULTRA LOW risk.').

% Rule 15: Low Risk
eval_rule(15) :-
    fact(credit_rating(very_good)), (fact(dti_rating(healthy)) ; fact(dti_rating(moderate))),
    assertz(fact(risk_profile(low))),
    log_reason('Rule 15', 'Very good credit rating with manageable DTI establishes LOW risk.').

% Rule 16: Moderate Risk
eval_rule(16) :-
    fact(credit_rating(good)), fact(dti_rating(healthy)),
    assertz(fact(risk_profile(moderate))),
    log_reason('Rule 16', 'Good credit profile and healthy DTI creates MODERATE risk.').

% Rule 17: Severe Risk Disqualification
eval_rule(17) :-
    (fact(credit_rating(poor)) ; fact(dti_rating(critical))),
    assertz(fact(risk_profile(severe_risk))),
    assertz(fact(disqualified('High default probability due to poor credit or excessive debt.'))),
    log_reason('Rule 17', 'Poor credit rating or critical DTI triggers SEVERE RISK alert.').

% --- Category E: Card Product Eligibility Sanctions ---
% Rule 18: Platinum Card Sanction
eval_rule(18) :-
    fact(status(age_eligible)), fact(status(employment_stable)),
    fact(risk_profile(ultra_low)),
    fact(monthly_income(Inc)), Inc >= 250000,
    assertz(fact(eligible_card(platinum_card))),
    log_reason('Rule 18', 'Qualified for PLATINUM CARD: Ultra-low risk and income >= 250,000.').

% Rule 19: Gold Card Sanction
eval_rule(19) :-
    fact(status(age_eligible)), fact(status(employment_stable)),
    (fact(risk_profile(ultra_low)) ; fact(risk_profile(low))),
    fact(monthly_income(Inc)), Inc >= 120000,
    assertz(fact(eligible_card(gold_card))),
    log_reason('Rule 19', 'Qualified for GOLD CARD: Low/Ultra-low risk and income >= 120,000.').

% Rule 20: Silver & Classic Card Sanction
eval_rule(20) :-
    fact(status(age_eligible)), fact(status(employment_stable)),
    (fact(risk_profile(ultra_low)) ; fact(risk_profile(low)) ; fact(risk_profile(moderate))),
    fact(monthly_income(Inc)), Inc >= 60000,
    assertz(fact(eligible_card(silver_card))),
    assertz(fact(eligible_card(classic_card))),
    log_reason('Rule 20', 'Qualified for SILVER / CLASSIC CARD: Acceptable risk profile and income >= 60,000.').

% -----------------------------------------------------------------------------
% 3. INFERENCE ENGINES
% -----------------------------------------------------------------------------

% Forward Chaining: Evaluate all rules across layers sequentially
run_forward_chaining :-
    % Layer 1: Age
    (eval_rule(1) ; eval_rule(2)),
    % Layer 2: Employment
    (eval_rule(3) ; eval_rule(4) ; eval_rule(5)),
    % Layer 3: Credit Rating
    (eval_rule(6) ; eval_rule(7) ; eval_rule(8) ; eval_rule(9) ; eval_rule(10)),
    % Layer 4: DTI Ratio
    (eval_rule(11) ; eval_rule(12) ; eval_rule(13)),
    % Layer 5: Composite Risk
    (eval_rule(14) ; eval_rule(15) ; eval_rule(16) ; eval_rule(17)),
    % Layer 6: Product Sanctions
    ignore(eval_rule(18)),
    ignore(eval_rule(19)),
    ignore(eval_rule(20)).

% Backward Chaining: Verify if a specific card product can be awarded
verify_target_goal(TargetCard) :-
    write('>> Backward Chaining Query: Testing eligibility for '), write(TargetCard), nl,
    run_forward_chaining,
    ( fact(eligible_card(TargetCard)) ->
        format('>> Hypothesis TRUE: Applicant is ELIGIBLE for ~w.~n', [TargetCard])
    ;
        format('>> Hypothesis FALSE: Applicant DOES NOT qualify for ~w.~n', [TargetCard])
    ).

% -----------------------------------------------------------------------------
% 4. EXPLANATION FACILITY
% -----------------------------------------------------------------------------
display_reasoning :-
    nl, write('========================= REASONING AUDIT TRACE ========================='), nl,
    forall(explanation(rule(ID, Text)),
           format('[+] ~w Triggered: ~w~n', [ID, Text])),
    write('========================================================================='), nl.

display_final_decision :-
    nl, write('========================= UNDERWRITING DECISION ========================='), nl,
    ( fact(disqualified(Reason)) ->
        format('DECISION : REJECTED / DECLINED~nREASON   : ~w~n', [Reason])
    ;
        setof(C, fact(eligible_card(C)), Cards) ->
        format('DECISION : APPROVED~nOFFERS   : Eligible Products: ~w~n', [Cards])
    ;
        format('DECISION : REJECTED~nREASON   : Applicant does not meet minimum income/risk requirements for any tier.~n')
    ),
    display_reasoning.

% -----------------------------------------------------------------------------
% 5. INTERACTIVE USER INTERFACE (CLI)
% -----------------------------------------------------------------------------
start :-
    clear_memory,
    write('==================================================================='), nl,
    write('       CREDIT CARD ELIGIBILITY EXPERT SYSTEM (CCE-ES)              '), nl,
    write('==================================================================='), nl,
    
    write('Enter Applicant Age: '), read(Age),
    assertz(fact(age(Age))),
    
    write('Employment Type (salaried / self_employed): '), read(EmpType),
    assertz(fact(employment(EmpType))),
    
    write('Tenure in Months (at current job or active business): '), read(Tenure),
    assertz(fact(tenure(Tenure))),
    
    write('Monthly Gross Income: '), read(Income),
    assertz(fact(monthly_income(Income))),
    
    write('Existing Total Monthly Debt Commitments: '), read(Debt),
    assertz(fact(existing_debt(Debt))),
    
    write('Credit Bureau Score (300 - 850): '), read(Score),
    assertz(fact(credit_score(Score))),
    
    nl, write('Select Reasoning Engine Mode:'), nl,
    write('1. Forward Chaining (Comprehensive Product Discovery)'), nl,
    write('2. Backward Chaining (Hypothesis Check for Specific Tier)'), nl,
    write('Choice (1 or 2): '), read(Choice),
    
    ( Choice == 1 ->
        run_forward_chaining,
        display_final_decision
    ; Choice == 2 ->
        write('Enter Targeted Product (platinum_card / gold_card / silver_card / classic_card): '),
        read(TargetCard),
        verify_target_goal(TargetCard),
        display_final_decision
    ;
        write('Invalid choice entered. Terminating session.'), nl
    ).