function weather_gui()
% WEATHER_GUI  Interface gráfica para o classificador ensemble de tempo.
%
%   Corre o mesmo pipeline que main_demo.m mas com controlos visuais:
%     - Selecionar ficheiro CSV
%     - Ajustar rácio treino/teste
%     - Ajustar número de hash functions do MinHash
%     - Botão "Correr Pipeline"
%     - Log de texto em tempo real
%     - Painel de métricas (Accuracy, F1 macro, F1 ponderado)
%     - Matriz de confusão gráfica
%
%   Pré-requisitos: pasta naive_bayes/, bloom_filter/ e minhash/ acessíveis
%   via addpath (o GUI pergunta o baseDir ao utilizador).

    %% ---------- figura principal ----------
    fig = uifigure('Name', 'Ensemble Weather Classifier', ...
                   'Position', [100 80 1060 680], ...
                   'Color', [0.13 0.15 0.18], ...
                   'Resize', 'on');

    % Paleta
    CLR_BG      = [0.13 0.15 0.18];
    CLR_PANEL   = [0.18 0.21 0.25];
    CLR_ACCENT  = [0.22 0.60 0.86];
    CLR_TXT     = [0.92 0.93 0.94];
    CLR_BTN     = [0.22 0.60 0.86];
    CLR_BTN_TXT = [1    1    1   ];
    CLR_OK      = [0.25 0.75 0.45];
    CLR_WARN    = [0.95 0.65 0.20];

    %% =====================================================================
    %  PAINEL ESQUERDO — configurações
    %% =====================================================================
    pLeft = uipanel(fig, ...
        'Position',         [10 10 300 660], ...
        'BackgroundColor',  CLR_PANEL, ...
        'BorderType',       'none');

    % Título
    uilabel(pLeft, 'Text', 'CONFIGURAÇÃO', ...
        'Position',         [10 625 280 24], ...
        'FontSize',         11, 'FontWeight', 'bold', ...
        'FontColor',        CLR_ACCENT, ...
        'BackgroundColor',  CLR_PANEL, ...
        'HorizontalAlignment', 'left');

    % --- Base directory ---
    uilabel(pLeft, 'Text', 'Pasta do projecto (baseDir):', ...
        'Position', [10 595 280 18], 'FontSize', 10, ...
        'FontColor', CLR_TXT, 'BackgroundColor', CLR_PANEL);

    edBaseDir = uieditfield(pLeft, 'text', ...
        'Position',        [10 572 240 24], ...
        'Value',           pwd, ...
        'FontSize',        9, ...
        'BackgroundColor', [0.10 0.12 0.15], ...
        'FontColor',       CLR_TXT);

    uibutton(pLeft, 'push', ...
        'Text',            '...', ...
        'Position',        [254 572 36 24], ...
        'BackgroundColor', [0.25 0.28 0.33], ...
        'FontColor',       CLR_TXT, ...
        'ButtonPushedFcn', @(~,~) pickBaseDir());

    % --- CSV file ---
    uilabel(pLeft, 'Text', 'Ficheiro CSV:', ...
        'Position', [10 543 280 18], 'FontSize', 10, ...
        'FontColor', CLR_TXT, 'BackgroundColor', CLR_PANEL);

    edCSV = uieditfield(pLeft, 'text', ...
        'Position',        [10 520 240 24], ...
        'Value',           'data/seattle-weather.csv', ...
        'FontSize',        9, ...
        'BackgroundColor', [0.10 0.12 0.15], ...
        'FontColor',       CLR_TXT);

    uibutton(pLeft, 'push', ...
        'Text',            '...', ...
        'Position',        [254 520 36 24], ...
        'BackgroundColor', [0.25 0.28 0.33], ...
        'FontColor',       CLR_TXT, ...
        'ButtonPushedFcn', @(~,~) pickCSV());

    % --- Rácio treino ---
    uilabel(pLeft, 'Text', 'Rácio de treino:', ...
        'Position', [10 490 180 18], 'FontSize', 10, ...
        'FontColor', CLR_TXT, 'BackgroundColor', CLR_PANEL);

    lblRatio = uilabel(pLeft, 'Text', '80 %', ...
        'Position', [220 490 70 18], 'FontSize', 10, ...
        'FontWeight', 'bold', 'FontColor', CLR_ACCENT, ...
        'BackgroundColor', CLR_PANEL, 'HorizontalAlignment', 'right');

    slRatio = uislider(pLeft, ...
        'Limits',          [50 95], ...
        'Value',           80, ...
        'MajorTicks',      [50 60 70 80 90 95], ...
        'Position',        [10 468 280 22], ...
        'FontColor',       CLR_TXT, ...
        'ValueChangedFcn', @(src,~) set(lblRatio,'Text', sprintf('%d %%', round(src.Value))));

    % --- Nº hashes MinHash ---
    uilabel(pLeft, 'Text', 'Nº de hashes MinHash:', ...
        'Position', [10 440 200 18], 'FontSize', 10, ...
        'FontColor', CLR_TXT, 'BackgroundColor', CLR_PANEL);

    lblHash = uilabel(pLeft, 'Text', '200', ...
        'Position', [220 440 70 18], 'FontSize', 10, ...
        'FontWeight', 'bold', 'FontColor', CLR_ACCENT, ...
        'BackgroundColor', CLR_PANEL, 'HorizontalAlignment', 'right');

    slHash = uislider(pLeft, ...
        'Limits',          [50 500], ...
        'Value',           200, ...
        'MajorTicks',      [50 100 200 300 500], ...
        'Position',        [10 418 280 22], ...
        'FontColor',       CLR_TXT, ...
        'ValueChangedFcn', @(src,~) set(lblHash,'Text', sprintf('%d', round(src.Value))));

    % --- Nº vizinhos MinHash ---
    uilabel(pLeft, 'Text', 'Vizinhos MinHash (top-k):', ...
        'Position', [10 390 200 18], 'FontSize', 10, ...
        'FontColor', CLR_TXT, 'BackgroundColor', CLR_PANEL);

    lblK = uilabel(pLeft, 'Text', '20', ...
        'Position', [220 390 70 18], 'FontSize', 10, ...
        'FontWeight', 'bold', 'FontColor', CLR_ACCENT, ...
        'BackgroundColor', CLR_PANEL, 'HorizontalAlignment', 'right');

    slK = uislider(pLeft, ...
        'Limits',          [5 50], ...
        'Value',           20, ...
        'MajorTicks',      [5 10 20 30 50], ...
        'Position',        [10 368 280 22], ...
        'FontColor',       CLR_TXT, ...
        'ValueChangedFcn', @(src,~) set(lblK,'Text', sprintf('%d', round(src.Value))));

    % --- Pesos do ensemble ---
    uilabel(pLeft, 'Text', 'Pesos do Ensemble', ...
        'Position', [10 338 280 18], 'FontSize', 10, ...
        'FontWeight', 'bold', 'FontColor', CLR_ACCENT, ...
        'BackgroundColor', CLR_PANEL);

    function lbl = makeWeightRow(y, name, val)
        uilabel(pLeft, 'Text', name, ...
            'Position', [10 y 110 18], 'FontSize', 9, ...
            'FontColor', CLR_TXT, 'BackgroundColor', CLR_PANEL);
        lbl = uilabel(pLeft, 'Text', sprintf('%.2f', val), ...
            'Position', [248 y 44 18], 'FontSize', 9, ...
            'FontWeight','bold','FontColor', CLR_ACCENT, ...
            'BackgroundColor', CLR_PANEL, 'HorizontalAlignment','right');
    end

    lblWNB = makeWeightRow(318, 'w_nb (NaiveBayes):', 0.55);
    slWNB  = uislider(pLeft,'Limits',[0 1],'Value',0.55, ...
        'MajorTicks',[], 'Position',[10 298 280 18],'FontColor',CLR_TXT, ...
        'ValueChangedFcn',@(src,~) set(lblWNB,'Text',sprintf('%.2f',src.Value)));

    lblWMH = makeWeightRow(275, 'w_mh (MinHash):', 0.40);
    slWMH  = uislider(pLeft,'Limits',[0 1],'Value',0.40, ...
        'MajorTicks',[], 'Position',[10 255 280 18],'FontColor',CLR_TXT, ...
        'ValueChangedFcn',@(src,~) set(lblWMH,'Text',sprintf('%.2f',src.Value)));

    lblWBF = makeWeightRow(232, 'w_bf (BloomFilter):', 0.05);
    slWBF  = uislider(pLeft,'Limits',[0 1],'Value',0.05, ...
        'MajorTicks',[], 'Position',[10 212 280 18],'FontColor',CLR_TXT, ...
        'ValueChangedFcn',@(src,~) set(lblWBF,'Text',sprintf('%.2f',src.Value)));

    % --- Botão correr ---
    btnRun = uibutton(pLeft, 'push', ...
        'Text',            '▶  Correr Pipeline', ...
        'Position',        [10 160 280 40], ...
        'BackgroundColor', CLR_BTN, ...
        'FontColor',       CLR_BTN_TXT, ...
        'FontSize',        13, 'FontWeight', 'bold', ...
        'ButtonPushedFcn', @(~,~) runPipeline());

    % --- Botão limpar log ---
    uibutton(pLeft, 'push', ...
        'Text',            'Limpar Log', ...
        'Position',        [10 110 280 30], ...
        'BackgroundColor', [0.25 0.28 0.33], ...
        'FontColor',       CLR_TXT, ...
        'FontSize',        10, ...
        'ButtonPushedFcn', @(~,~) set(taLog,'Value',''));

    % --- Indicador de estado ---
    lblStatus = uilabel(pLeft, ...
        'Text',            '● Pronto', ...
        'Position',        [10 72 280 28], ...
        'FontSize',        11, 'FontWeight', 'bold', ...
        'FontColor',       CLR_OK, ...
        'BackgroundColor', CLR_PANEL, ...
        'HorizontalAlignment', 'center');

    % Barra de progresso
    pbProgress = uiprogressbar(pLeft, ...
        'Position',    [10 42 280 16], ...
        'Value',       0, ...
        'Visible',     'off');

    %% =====================================================================
    %  PAINEL CENTRAL — log
    %% =====================================================================
    pMid = uipanel(fig, ...
        'Position',        [320 10 360 660], ...
        'BackgroundColor', CLR_PANEL, ...
        'BorderType',      'none');

    uilabel(pMid, 'Text', 'LOG DE EXECUÇÃO', ...
        'Position',        [10 630 340 22], ...
        'FontSize',        11, 'FontWeight', 'bold', ...
        'FontColor',       CLR_ACCENT, ...
        'BackgroundColor', CLR_PANEL);

    taLog = uitextarea(pMid, ...
        'Position',        [10 10 340 615], ...
        'Value',           '', ...
        'FontSize',        9, ...
        'FontName',        'Courier New', ...
        'BackgroundColor', [0.07 0.09 0.11], ...
        'FontColor',       [0.75 0.90 0.75], ...
        'Editable',        'off');

    %% =====================================================================
    %  PAINEL DIREITO — métricas + matriz de confusão
    %% =====================================================================
    pRight = uipanel(fig, ...
        'Position',        [690 10 360 660], ...
        'BackgroundColor', CLR_PANEL, ...
        'BorderType',      'none');

    uilabel(pRight, 'Text', 'RESULTADOS', ...
        'Position',        [10 630 340 22], ...
        'FontSize',        11, 'FontWeight', 'bold', ...
        'FontColor',       CLR_ACCENT, ...
        'BackgroundColor', CLR_PANEL);

    % Cards de métricas
    function [lv] = makeCard(x, y, title)
        uipanel(pRight, 'Position', [x y 100 64], ...
            'BackgroundColor', [0.10 0.12 0.15], 'BorderType','none');
        uilabel(pRight, 'Text', title, ...
            'Position', [x+4 y+42 92 18], 'FontSize', 8, ...
            'FontColor', [0.55 0.65 0.75], 'BackgroundColor', [0.10 0.12 0.15]);
        lv = uilabel(pRight, 'Text', '—', ...
            'Position', [x+4 y+10 92 30], 'FontSize', 18, 'FontWeight','bold', ...
            'FontColor', CLR_TXT, 'BackgroundColor', [0.10 0.12 0.15], ...
            'HorizontalAlignment', 'center');
    end

    lblAccEns  = makeCard( 10, 560, 'Accuracy Ensemble');
    lblAccNB   = makeCard(120, 560, 'Accuracy NaiveBayes');
    lblF1Macro = makeCard(230, 560, 'F1 Macro avg');

    % Área para a matriz de confusão (axes dentro de uipanel)
    axPanel = uipanel(pRight, ...
        'Position',        [10 10 340 540], ...
        'BackgroundColor', [0.10 0.12 0.15], ...
        'BorderType',      'none');

    lblNoPlot = uilabel(axPanel, ...
        'Text',            'A matriz de confusão aparecerá aqui após correr o pipeline.', ...
        'Position',        [10 230 320 60], ...
        'FontSize',        10, 'FontColor', [0.45 0.55 0.65], ...
        'BackgroundColor', [0.10 0.12 0.15], ...
        'HorizontalAlignment', 'center', 'WordWrap', 'on');

    axCM = uiaxes(axPanel, ...
        'Position',        [5 5 330 530], ...
        'Color',           [0.10 0.12 0.15], ...
        'XColor',          CLR_TXT, 'YColor', CLR_TXT, ...
        'Visible',         'off');

    %% =====================================================================
    %  CALLBACKS AUXILIARES
    %% =====================================================================
    function pickBaseDir()
        d = uigetdir(edBaseDir.Value, 'Seleccionar pasta do projecto');
        if d ~= 0
            edBaseDir.Value = d;
        end
    end

    function pickCSV()
        startDir = edBaseDir.Value;
        [f, p] = uigetfile('*.csv', 'Seleccionar CSV', startDir);
        if f ~= 0
            % Guardar caminho relativo a baseDir se possível
            fullp = fullfile(p, f);
            base  = edBaseDir.Value;
            if startsWith(fullp, base)
                edCSV.Value = fullp(length(base)+2:end); % relativo
            else
                edCSV.Value = fullp;
            end
        end
    end

    function log(msg, varargin)
        if nargin > 1
            msg = sprintf(msg, varargin{:});
        end
        cur = taLog.Value;
        if ischar(cur), cur = {cur}; end
        taLog.Value = [cur; {msg}];
        scroll(taLog, 'bottom');
        drawnow limitrate;
    end

    function setStatus(txt, colour)
        lblStatus.Text       = txt;
        lblStatus.FontColor  = colour;
        drawnow;
    end

    %% =====================================================================
    %  PIPELINE PRINCIPAL
    %% =====================================================================
    function runPipeline()

        btnRun.Enable = 'off';
        set(pbProgress, 'Value', 0, 'Visible', 'on');
        setStatus('● A correr...', CLR_WARN);

        try
            %% 0. Paths
            baseDir = edBaseDir.Value;
            csvRel  = edCSV.Value;
            if isAbsolutePath(csvRel)
                csvPath = csvRel;
            else
                csvPath = fullfile(baseDir, csvRel);
            end

            addpath(fullfile(baseDir, 'naive_bayes'));
            addpath(fullfile(baseDir, 'bloom_filter'));
            addpath(fullfile(baseDir, 'minhash'));

            trainRatio = slRatio.Value / 100;
            nHashes    = round(slHash.Value);
            kNeigh     = round(slK.Value);
            w_nb       = slWNB.Value;
            w_mh       = slWMH.Value;
            w_bf       = slWBF.Value;

            log('=== WEATHER ENSEMBLE GUI ===');
            log('baseDir   : %s', baseDir);
            log('CSV       : %s', csvPath);
            log('Treino    : %.0f%%  |  Teste: %.0f%%', trainRatio*100, (1-trainRatio)*100);
            log('Hashes    : %d   |  Top-k: %d', nHashes, kNeigh);
            log('Pesos     : NB=%.2f  MH=%.2f  BF=%.2f', w_nb, w_mh, w_bf);
            log('');

            %% 1. Ler dados
            log('[1/6] A ler CSV...');
            pbProgress.Value = 0.05; drawnow;

            if ~isfile(csvPath)
                error('Ficheiro não encontrado: %s', csvPath);
            end
            data = readtable(csvPath);

            % Remover colunas não-feature (igual ao main_demo)
            colsRemove = {'date','dew_point_mean','dew_point_max'};
            for ci = 1:numel(colsRemove)
                if ismember(colsRemove{ci}, data.Properties.VariableNames)
                    data.(colsRemove{ci}) = [];
                end
            end

            % Features compostas
            if ismember('temp_max',data.Properties.VariableNames) && ...
               ismember('temp_min',data.Properties.VariableNames)
                data.temp_mean   = (data.temp_max + data.temp_min) / 2;
                if ismember('month_cos', data.Properties.VariableNames)
                    data.season_temp = data.temp_mean .* data.month_cos;
                    data.cos_x_tmax  = data.month_cos .* data.temp_max;
                end
            end

            Y = categorical(data.weather);
            X = table2array(removevars(data, 'weather'));

            log('  Linhas  : %d', size(X,1));
            log('  Features: %d', size(X,2));
            log('  Classes : %s', strjoin(categories(Y), ', '));
            pbProgress.Value = 0.12; drawnow;

            %% 2. Split
            log('[2/6] Split treino/teste...');
            rng('shuffle');
            idx    = randperm(size(X,1));
            nTrain = round(trainRatio * numel(idx));
            trainIdx = idx(1:nTrain);
            testIdx  = idx(nTrain+1:end);
            XTrain = X(trainIdx,:);  YTrain = Y(trainIdx);
            XTest  = X(testIdx,:);   YTest  = Y(testIdx);
            log('  Treino: %d  |  Teste: %d', size(XTrain,1), size(XTest,1));
            pbProgress.Value = 0.18; drawnow;

            %% 3. Bloom Filter
            log('[3/6] Bloom Filter...');
            bf = bloom_init(50000, 7);
            for ii = 1:size(XTrain,1)
                tokens = extract_features(XTrain(ii,:));
                key    = lower(strjoin(sort(string(tokens)), '|'));
                bf     = bloom_insert(bf, key);
            end
            log('  FPR estimada: %.4f%%', bloom_fp_rate(bf)*100);
            pbProgress.Value = 0.32; drawnow;

            %% 4. MinHash
            log('[4/6] MinHash (%d hashes)...', nHashes);
            trainTokens = cell(size(XTrain,1),1);
            for ii = 1:size(XTrain,1)
                trainTokens{ii} = extract_features(XTrain(ii,:));
            end
            [sigTrain, hashData] = minhash_signature(trainTokens, nHashes);
            log('  Assinaturas: %dx%d', size(sigTrain,1), size(sigTrain,2));
            pbProgress.Value = 0.50; drawnow;

            %% 5. Naive Bayes
            log('[5/6] Naive Bayes (treino)...');
            [mu, sigma, logPrior, classes] = nb_train(XTrain, YTrain);
            log('  Classes: %s', strjoin(classes,', '));

            % NB isolado para comparação
            [~, p_nb_all] = nb_predict(XTest, mu, sigma, logPrior, classes);
            [~, idxNB]    = max(p_nb_all, [], 2);
            pred_nb       = classes(idxNB);
            acc_nb        = mean(categorical(pred_nb) == YTest);
            log('  Accuracy NB (isolado): %.4f (%.2f%%)', acc_nb, acc_nb*100);
            pbProgress.Value = 0.65; drawnow;

            %% 6. Ensemble
            log('[6/6] Ensemble predict...');
            previsoes = ensemble_predict(XTest, YTrain, sigTrain, bf, ...
                                         mu, sigma, logPrior, classes, hashData, ...
                                         w_nb, w_mh, w_bf);
            acc_ens = mean(previsoes == YTest);
            log('  Accuracy Ensemble: %.4f (%.2f%%)', acc_ens, acc_ens*100);
            pbProgress.Value = 0.80; drawnow;

            %% 7. Métricas detalhadas
            log('');
            log('=== MÉTRICAS POR CLASSE ===');
            log('%-12s  %9s  %9s  %9s  %6s', 'Classe','Precision','Recall','F1','Suporte');
            log('%s', repmat('-',1,55));

            nClasses  = numel(classes);
            precs = zeros(nClasses,1); recs = zeros(nClasses,1);
            f1s   = zeros(nClasses,1); sups = zeros(nClasses,1);

            for c = 1:nClasses
                tp = sum(previsoes == classes{c} & YTest == classes{c});
                fp = sum(previsoes == classes{c} & YTest ~= classes{c});
                fn = sum(previsoes ~= classes{c} & YTest == classes{c});
                p  = tp / max(tp+fp, 1);
                r  = tp / max(tp+fn, 1);
                f1 = 2*p*r / max(p+r, 1e-9);
                precs(c)=p; recs(c)=r; f1s(c)=f1;
                sups(c) = sum(YTest == classes{c});
                log('%-12s  %9.4f  %9.4f  %9.4f  %6d', classes{c}, p, r, f1, sups(c));
            end
            log('%s', repmat('-',1,55));

            nTeste   = numel(YTest);
            f1_macro = mean(f1s);
            f1_w     = sum(f1s .* sups) / nTeste;
            log('%-12s  %9.4f  %9.4f  %9.4f  %6d', ...
                'Macro avg', mean(precs), mean(recs), f1_macro, nTeste);
            log('%-12s  %9.4f  %9.4f  %9.4f  %6d', ...
                'Weighted', ...
                sum(precs.*sups)/nTeste, sum(recs.*sups)/nTeste, f1_w, nTeste);
            pbProgress.Value = 0.90; drawnow;

            %% 8. Bloom — dias novos vs vistos
            log('');
            log('=== BLOOM FILTER (teste) ===');
            nNaoVisto = 0;
            for ii = 1:size(XTest,1)
                tokens = extract_features(XTest(ii,:));
                chave  = lower(strjoin(sort(string(tokens)),'|'));
                if ~bloom_check(bf, chave), nNaoVisto = nNaoVisto+1; end
            end
            log('  Vistos  : %d / %d', nTeste-nNaoVisto, nTeste);
            log('  Novos   : %d / %d', nNaoVisto, nTeste);

            %% 9. Atualizar cards de métricas
            set(lblAccEns,  'Text', sprintf('%.2f%%', acc_ens*100), 'FontColor', CLR_OK);
            set(lblAccNB,   'Text', sprintf('%.2f%%', acc_nb*100),  'FontColor', CLR_TXT);
            set(lblF1Macro, 'Text', sprintf('%.2f%%', f1_macro*100),'FontColor', CLR_ACCENT);

            %% 10. Matriz de confusão
            confMatrix = confusionmat(YTest, previsoes, 'Order', classes);
            lblNoPlot.Visible = 'off';
            axCM.Visible      = 'on';
            cla(axCM);

            % Normalizar por linha para mostrar % recall
            rowSums = sum(confMatrix, 2);
            rowSums(rowSums == 0) = 1;
            confNorm = confMatrix ./ rowSums;

            imagesc(axCM, confNorm);
            colormap(axCM, parula);
            clim(axCM, [0 1]);

            axCM.XTick = 1:nClasses;
            axCM.YTick = 1:nClasses;
            axCM.XTickLabel = classes;
            axCM.YTickLabel = classes;
            axCM.XAxisLocation = 'top';
            axCM.FontSize = 8;
            xlabel(axCM, 'Previsto');
            ylabel(axCM, 'Real');
            title(axCM,  'Matriz de Confusão (normalizada por linha)', ...
                  'FontSize', 9, 'Color', CLR_TXT);

            for r = 1:nClasses
                for c2 = 1:nClasses
                    val = confNorm(r,c2);
                    clr = ternary(val > 0.5, [0 0 0], [1 1 1]);
                    text(axCM, c2, r, sprintf('%.2f\n(%d)', val, confMatrix(r,c2)), ...
                        'HorizontalAlignment','center', ...
                        'VerticalAlignment','middle', ...
                        'FontSize', 7, 'Color', clr);
                end
            end

            pbProgress.Value = 1.0; drawnow;
            log('');
            log('=== CONCLUÍDO ===');
            setStatus('● Concluído', CLR_OK);

        catch ME
            log('');
            log('ERRO: %s', ME.message);
            for si = 1:numel(ME.stack)
                log('  em %s (linha %d)', ME.stack(si).name, ME.stack(si).line);
            end
            setStatus('● Erro', [0.90 0.25 0.25]);
        end

        pbProgress.Visible = 'off';
        btnRun.Enable = 'on';
    end

    %% =====================================================================
    %  UTILITÁRIOS
    %% =====================================================================
    function r = isAbsolutePath(p)
        r = ~isempty(p) && (p(1) == '/' || p(1) == '\' || (numel(p)>1 && p(2)==':'));
    end

    function v = ternary(cond, a, b)
        if cond, v = a; else, v = b; end
    end

end