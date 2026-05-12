function evaluate(YTeste, previsoes, classes)
%EVALUATE  Calcula e imprime métricas de classificação + matriz de confusão.
%
%   evaluate(YTeste, previsoes, classes)
%
%   Entradas:
%     YTeste    — vetor categorical com os rótulos reais
%     previsoes — vetor categorical com os rótulos previstos (saída de nb_predict)
%     classes   — cell array com os nomes das classes (saída de nb_train)

    nClasses = numel(classes);
    nTeste   = numel(YTeste);

    %% 1) Acurácia global
    acuracia = mean(previsoes == YTeste);
    fprintf('Acurácia global: %.4f  (%.2f%%)\n', acuracia, acuracia * 100);

    %% 2) Precision, Recall e F1 por classe
    fprintf('\n%-12s  %9s  %9s  %9s  %6s\n', 'Classe', 'Precision', 'Recall', 'F1-Score', 'Suporte');
    fprintf('%s\n', repmat('-', 1, 55));

    precisoes = zeros(nClasses, 1);
    recalls   = zeros(nClasses, 1);
    f1scores  = zeros(nClasses, 1);
    suportes  = zeros(nClasses, 1);

    for c = 1:nClasses
        tp = sum(previsoes == classes{c} & YTeste == classes{c});
        fp = sum(previsoes == classes{c} & YTeste ~= classes{c});
        fn = sum(previsoes ~= classes{c} & YTeste == classes{c});

        p  = tp / max(tp + fp, 1);
        r  = tp / max(tp + fn, 1);
        f1 = 2 * p * r / max(p + r, 1e-9);

        precisoes(c) = p;
        recalls(c)   = r;
        f1scores(c)  = f1;
        suportes(c)  = sum(YTeste == classes{c});

        fprintf('%-12s  %9.4f  %9.4f  %9.4f  %6d\n', classes{c}, p, r, f1, suportes(c));
    end

    fprintf('%s\n', repmat('-', 1, 55));

    % Macro-average (não ponderada)
    fprintf('%-12s  %9.4f  %9.4f  %9.4f  %6d\n', ...
        'Macro avg', mean(precisoes), mean(recalls), mean(f1scores), nTeste);

    % Weighted average (ponderada pelo suporte)
    fprintf('%-12s  %9.4f  %9.4f  %9.4f  %6d\n', ...
        'Weighted avg', ...
        sum(precisoes .* suportes) / nTeste, ...
        sum(recalls   .* suportes) / nTeste, ...
        sum(f1scores  .* suportes) / nTeste, ...
        nTeste);

    %% 3) Matriz de confusão (texto)
    fprintf('\n--- Matriz de Confusão ---\n');
    confMatrix = confusionmat(YTeste, previsoes, 'Order', classes);

    % Cabeçalho
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

    %% 4) Figura: matriz de confusão visual (se houver display disponível)
    try
        figure('Name', 'Matriz de Confusão');
        cm = confusionchart(YTeste, previsoes, ...
            'RowSummary',    'row-normalized', ...
            'ColumnSummary', 'column-normalized', ...
            'Title',         'Naive Bayes Gaussiano — Seattle Weather');
        cm.ClassLabels = classes;
    catch
        % Sem display gráfico disponível (ex: servidor) — ignorar silenciosamente
    end
end