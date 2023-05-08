%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                           DIABETIC PATIENT                              %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function DIABETIC_PATIENT(weight_, name_, version_, test_data_, randomize_)

    % INIT FIS TREE
    [AP, CCR, ~, BGR_R, BGA_R] = AP_FIST(weight_);

    % SET PATH
    test_id = ...
    strcat('/test_ID', ...
        floor(rand(1) * (0 - 9) + 10) + 48, ...
        floor(rand(1) * (0 - 9) + 10) + 48, ...
        floor(rand(1) * (0 - 9) + 10) + 48, ...
        floor(rand(1) * (65 - 90) + 91), ...
        floor(rand(1) * (65 - 90) + 91), ...
        floor(rand(1) * (65 - 90) + 91));

    v_path = ...
        strcat('results/', 'v', version_);

    path = ...
        strcat(v_path, '/', name_, test_id);

    mkdir(path);

    % INIT DATABASE AND LOG FILE
    fname = fopen(append(path, '/test_log.txt'), 'w');

    if isstring(test_data_)
        test_data_ = readtable(test_data_, "VariableNamingRule", "preserve");
    end

    %
    options = evalfisOptions('NumSamplePoints', 100);

    % CALCULATE TIMESTAMP
    TS = test_data_.Time(2) - test_data_.Time(1);

    % RANDOMIZE test_data(1:3) VALUES
    if randomize_
        test_data_.BGL(1) = rand(1) * (70 - 250) + 250;
        test_data_.BGL(2) = test_data_.BGL(1) + rand(1) * (-8) + 4;
        test_data_.BGL(3) = test_data_.BGL(2) + rand(1) * (-8) + 4;

        test_data_.BGR(2) = (test_data_.BGL(2) - test_data_.BGL(1)) / TS;
        test_data_.BGR(3) = (test_data_.BGL(3) - test_data_.BGL(2)) / TS;

        test_data_.BGA(3) = (test_data_.BGR(3) - test_data_.BGR(2)) / TS;
    end

    % TEST FISTREE
    for i = 3:size(test_data_, 1)

        % evaluate fis tree (insulin dose)
        eval = evalfis(AP, [test_data_.BGL(i) test_data_.BGR(i) test_data_.BGA(i)], options);

        % logging current insulin dose into blood glucose
        test_data_.Insulin(i) = eval;

        % - Insulin absorption time (mins / TS)
        IAT = floor((rand(1) * (55 - 65) + 66) / 5);

        % - total insulin absorbed (mg/dL)
        TIA = test_data_.Insulin(i) * 50;

        % - TIA distributed within IAT (mg/dL/min/TS)
        TIA_T = TIA / IAT;

        for j = i:i + IAT - 1

            if j < size(test_data_, 1)

                if isnan(test_data_.BGL(j + 1))
                    test_data_.BGL(j + 1) = 0;
                end

                test_data_.BGL(j + 1) = ...
                    test_data_.BGL(j + 1) - TIA_T;
            end

        end

        % logging next BGL, BGR, BGA
        if i < size(test_data_, 1)
            test_data_.BGL(i + 1) = test_data_.BGL(i + 1) + test_data_.BGL(i) + (rand(1) * (-2) + 1);

            bgr = (test_data_.BGL(i + 1) - test_data_.BGL(i)) / TS;
            bga = (bgr - test_data_.BGR(i)) / TS;

            if bgr > max(BGR_R)
                mf = [AP.FIS(1).Inputs(2).MembershipFunctions.Name];
                AP.FIS(1) = update_io(AP.FIS(1), "Input", 2, "BG_RATE", [min(BGR_R) bgr], mf);
                BGR_R = [min(BGR_R) bgr];
                fprintf(fname, '\n! ---- ! BG_RATE MAX upd: [%d %d]\n', min(BGR_R), bgr);
            elseif bgr < min(BGR_R)
                mf = [AP.FIS(1).Inputs(2).MembershipFunctions.Name];
                AP.FIS(1) = update_io(AP.FIS(1), "Input", 2, "BG_RATE", [bgr max(BGR_R)], mf);
                BGR_R = [bgr max(BGR_R)];
                fprintf(fname, '\n! ---- ! BG_RATE MIN upd: [%d %d]\n', bgr, max(BGR_R));
            end

            if bga > max(BGA_R)
                mf = [AP.FIS(2).Inputs(2).MembershipFunctions.Name];
                AP.FIS(2) = update_io(AP.FIS(2), "Input", 2, "BG_ACCEL", [min(BGA_R) bga], mf);
                BGA_R = [min(BGA_R) bga];
                fprintf(fname, '\n! ---- ! BG_ACCEL MAX upd: [%d %d]\n', min(BGA_R), bga);
            elseif bga < min(BGA_R)
                mf = [AP.FIS(2).Inputs(2).MembershipFunctions.Name];
                AP.FIS(2) = update_io(AP.FIS(2), "Input", 2, "BG_ACCEL", [bga max(BGA_R)], mf);
                BGA_R = [bga max(BGA_R)];
                fprintf(fname, '\n! ---- ! BG_ACCEL MIN upd: [%d %d]\n', bga, max(BGA_R));
            end

            test_data_.BGR(i + 1) = bgr;
            test_data_.BGA(i + 1) = bga;
        end

        % logging Carbs into BGL
        if test_data_.Carbs(i) > 0

            % - total glucose absorbed (mg/dL)
            TGA = (test_data_.Carbs(i) / CCR) * 50;

            % - TGA normally distributed (mg/dL/min)
            [ds, CAT] = cho_distribution(TGA);

            fprintf(fname, ...
                ['-----| CARBS INTAKE TIME: %02d:%02d' ...
                    '\n-----| Carbs Intake: %d g' ...
                    '\n-----| Carbs absorption time: %d min' ...
                    '\n-----| Total glucose absorbed: %d mg/dL' ...
                '\n-----| TGA/CAT: %d mg/dL/min\n\n'], ...
                floor(test_data_.Time(i) / 60), ...
                mod(test_data_.Time(i), 60), ...
                test_data_.Carbs(i), ...
                CAT * TS, ...
                TGA, ...
                TGA / (CAT * TS));

            for j = i:(i + CAT - 1)

                if j < size(test_data_, 1)

                    if isnan(test_data_.BGL(j + 1))
                        test_data_.BGL(j + 1) = 0;
                    end

                    test_data_.BGL(j + 1) = ...
                        test_data_.BGL(j + 1) + ds(j - i + 1);

                    fprintf(fname, ...
                        'CLF: %02d:%02d | %d\n', ...
                        floor(test_data_.Time(j + 1) / 60), ...
                        mod(test_data_.Time(j + 1), 60), ...
                        ds(j - i + 1));
                end

            end

        end

        % log data to .txt
        fprintf(fname, ...
        ['\n========== Day %d | %02d:%02d ==========' ...
                '\nBlood Glucose Level: %.4f' ...
                '\nBlood Glucose Rate: %.4f' ...
                '\nBlood Glucose Acceleration: %.6f' ...
                '\n==============------------------====\nInsulin Dose: %.4f' ...
            '\n====------------------==============\n\n'], ...
            test_data_.Day(i), ...
            floor(test_data_.Time(i) / 60), ...
            mod(test_data_.Time(i), 60), ...
            test_data_.BGL(i), ...
            test_data_.BGR(i), ...
            test_data_.BGA(i), ...
            eval);

    end

    % WRITE TO LOG FILE
    fclose(fname);

    % SUMMARISING RESULTS
    test_data_.("Patient's weight")(1) = weight_;
    test_data_.CHO_TOTAL(1) = sum(test_data_.Carbs);
    test_data_.INSULIN_TOTAL(1) = sum(test_data_.Insulin);
    test_data_.BGL_GROW_APPROX(1) = test_data_.CHO_TOTAL(1) / CCR * 50;
    test_data_.PREDICTED_INSULIN_TOTAL(1) = test_data_.CHO_TOTAL(1) / 50;

    test_data_.BGL_NORM_100_120(1) = ...
        (sum(test_data_.BGL < 120) ...
        - sum(test_data_.BGL < 100)) ...
        / size(test_data_, 1) * 100;

    test_data_.BGL_NORM_72_180(1) = ...
        (sum(test_data_.BGL < 180) ...
        - sum(test_data_.BGL < 72)) ...
        / size(test_data_, 1) * 100;

    % WRITE TO RESULTS TABLE
    writetable(test_data_, append(path, '/results.xlsx'));

    % SAVE RULES
    if ~exist(append(v_path, '/rules_config.txt'), 'file')
        fconf = fopen(append(v_path, '/rules_config.txt'), 'w');

        for i = 1:size(AP.FIS, 2)

            for j = 1:size(AP.FIS(i).Rules, 2)
                fprintf(fconf, '%s | Rule %02d | %s\n', AP.FIS(i).Name, j, AP.FIS(i).Rules(j).Description);

                if mod(j, 5) == 0
                    fprintf(fconf, '\n');
                end

            end

            fprintf(fconf, ['\n---------------------------------------' ...
                        '------------------------------------------------\n\n\n']);
        end

        fclose(fconf);
    end

    % FIGURES
    t = 0:minutes(TS):hours((size(test_data_, 1) - 1) / 12);

    % - fig
    fig = figure;
    yyaxis right;
    plot(t, test_data_.Insulin, 'DurationTickFormat', 'hh:mm', Color = "#FFA400"),
    ylim([0 2]),
    ylabel('Insulin Dose Level')
    yyaxis left;
    plot(t, test_data_.BGL, 'DurationTickFormat', 'hh:mm', Color = "#220DFF"),
    ylim([0 400]),
    xlabel('Time'), ylabel('Blood Glucose Level')
    title('Blood glucose levels and insulin dosage over 24hrs')

    % - fig1
    fig1 = figure;
    plot(t, test_data_.BGL, 'DurationTickFormat', 'hh:mm', Color = "#220DFF"),
    ylim([0 400])
    xlabel('Time'), ylabel('Blood Glucose Level')
    title('Blood glucose levels over 24hrs')

    % SAVE FIGURES
    saveas(fig, append(path, '/BGL_ID_24hr'), 'png');
    saveas(fig1, append(path, '/BGL_24hr'), 'png');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                             END OF FUNCTION                             %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
