function evaluate(YTeste, previsoes, classes, XTeste, bf, bf_cols, bf_breaks)
    nClasses = numel(classes);
    nTeste = numel(YTeste);

    %% 1) Bloom Filter
    fprintf('=== Bloom Filter: Dias de Teste vs Histórico ===\n');
    nNaoVisto = 0;
    for i = 1:nTeste
        key = build_bf_key(XTeste(i,:), bf_cols, bf_breaks);
        if ~bloom_check(bf, key)
            nNaoVisto = nNaoVisto + 1;
        end
    end
    nVisto = nTeste - nNaoVisto;
    fprintf('  Dias provavelmente vistos no treino : %d / %d\n', nVisto,    nTeste);
    fprintf('  Dias definitivamente novos          : %d / %d\n', nNaoVisto, nTeste);
    fprintf('  FPR estimada do filtro              : %.4f%%\n\n', bloom_fp_rate(bf) * 100);

    %% 2) Exatidão global (Accuracy)
    exatidao = mean(previsoes == YTeste);
    fprintf('Exatidão global: %.4f  (%.2f%%)\n', exatidao, exatidao * 100);

    %% 3) Precision, Recall/TPR, F1, FPR, FNR por classe
    %   TPR = Taxa de Verdadeiros Positivos = Recall = TP / (TP + FN)
    %   FPR = Taxa de Falsos Positivos      = FP / (FP + TN)
    %   FNR = Taxa de Falsos Negativos      = FN / (FN + TP)  [= 1 - TPR]
    fprintf('\n%-12s  %9s  %10s  %9s  %9s  %9s  %6s\n', ...
        'Classe', 'Precision', 'Recall/TPR', 'F1-Score', 'FPR', 'FNR', 'Suporte');
    fprintf('%s\n', repmat('-', 1, 76));

    precisoes = zeros(nClasses, 1);
    recalls   = zeros(nClasses, 1);
    f1scores  = zeros(nClasses, 1);
    fprs      = zeros(nClasses, 1);
    fnrs      = zeros(nClasses, 1);
    suportes  = zeros(nClasses, 1);

    for c = 1:nClasses
        tp = sum(previsoes == classes{c} & YTeste == classes{c});
        fp = sum(previsoes == classes{c} & YTeste ~= classes{c});
        fn = sum(previsoes ~= classes{c} & YTeste == classes{c});
        tn = nTeste - tp - fp - fn;

        p   = tp / max(tp + fp, 1);           % Precisão (Precision)
        r   = tp / max(tp + fn, 1);           % Recall = TPR
        f1  = 2 * p * r / max(p + r, 1e-9);  % F1-Score
        fpr = fp / max(fp + tn, 1);           % Taxa de Falsos Positivos
        fnr = fn / max(fn + tp, 1);           % Taxa de Falsos Negativos

        precisoes(c) = p;
        recalls(c)   = r;
        f1scores(c)  = f1;
        fprs(c)      = fpr;
        fnrs(c)      = fnr;
        suportes(c)  = sum(YTeste == classes{c});

        fprintf('%-12s  %9.4f  %10.4f  %9.4f  %9.4f  %9.4f  %6d\n', ...
            classes{c}, p, r, f1, fpr, fnr, suportes(c));
    end

    fprintf('%s\n', repmat('-', 1, 76));

    % Macro-average (não ponderada)
    fprintf('%-12s  %9.4f  %10.4f  %9.4f  %9.4f  %9.4f  %6d\n', ...
        'Macro avg', ...
        mean(precisoes), mean(recalls), mean(f1scores), mean(fprs), mean(fnrs), ...
        nTeste);

    % Weighted average (ponderada pelo suporte)
    fprintf('%-12s  %9.4f  %10.4f  %9.4f  %9.4f  %9.4f  %6d\n', ...
        'Weighted avg', ...
        sum(precisoes .* suportes) / nTeste, ...
        sum(recalls   .* suportes) / nTeste, ...
        sum(f1scores  .* suportes) / nTeste, ...
        sum(fprs      .* suportes) / nTeste, ...
        sum(fnrs      .* suportes) / nTeste, ...
        nTeste);

    fprintf('\n  Recall = TPR (Taxa de Verdadeiros Positivos) = TP / (TP + FN)\n');
    fprintf('  FPR    = Taxa de Falsos Positivos            = FP / (FP + TN)\n');
    fprintf('  FNR    = Taxa de Falsos Negativos            = FN / (FN + TP)\n');

    %% 4) Matriz de confusão (texto)
    fprintf('\n--- Matriz de Confusão ---\n');
    confMatrix = confusionmat(YTeste, previsoes, 'Order', classes);

    fprintf('%12s', '');
    for c = 1:nClasses
        fprintf('%10s', classes{c});
    end
    fprintf('  <- Previsto\n');
    fprintf('%s\n', repmat('-', 1, 12 + nClasses * 10 + 12));

    for c = 1:nClasses
        fprintf('%-12s', classes{c});
        for k = 1:nClasses
            fprintf('%10d', confMatrix(c, k));
        end
        fprintf('\n');
    end
    fprintf('^ Real\n');

    %% 5) Matriz de confusão visual
    try
        figure('Name', 'Matriz de Confusão');
        cm = confusionchart(YTeste, previsoes, ...
            'RowSummary',    'row-normalized', ...
            'ColumnSummary', 'column-normalized', ...
            'Title',         'Ensemble — Matriz de Confusão');
        cm.ClassLabels = classes;
    catch
    end
end