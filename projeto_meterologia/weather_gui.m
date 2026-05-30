function weather_gui()
% WEATHER_GUI  Interface gráfica para o classificador ensemble de tempo.
%
%   Previsão manual: selecionar CSV, treinar, introduzir features,
%   obter previsão + métricas completas no conjunto de teste.
%   Métricas: Exatidão, Precisão, Recall/TPR, F1, FPR, FNR,
%             Matriz de Confusão.

    %% -----------------------------------------------------------------------
    %  FIGURA PRINCIPAL
    %% -----------------------------------------------------------------------
    fig = uifigure('Name', 'Ensemble Weather Classifier', ...
                   'Position', [100 60 1100 780], ...
                   'Color',    [0.13 0.15 0.18], ...
                   'Resize',   'on');
    CLR_BG      = [0.13 0.15 0.18];
    CLR_PANEL   = [0.18 0.21 0.25];
    CLR_ACCENT  = [0.22 0.60 0.86];
    CLR_TXT     = [0.92 0.93 0.94];
    CLR_BTN     = [0.22 0.60 0.86];
    CLR_BTN_TXT = [1    1    1   ];
    CLR_OK      = [0.25 0.75 0.45];
    CLR_WARN    = [0.95 0.65 0.20];
    BF_COLS   = [1, 17, 14, 12, 2, 7];
    BF_BREAKS = [2, 4, 10; 3, 6, 12; 35,60,80; 55,70,82; 10,18,25; 25,40,55];
    slH = 22;

    %% -----------------------------------------------------------------------
    %  HELPER — card de métrica (reutilizado no painel de resultado)
    %% -----------------------------------------------------------------------
    function lv = makeCard(par,x,yc,ttl)
        uipanel(par,'Position',[x yc 106 68],'BackgroundColor',[0.10 0.12 0.15],'BorderType','none');
        uilabel(par,'Text',ttl,'Position',[x+4 yc+46 98 18],'FontSize',8,...
            'FontColor',[0.55 0.65 0.75],'BackgroundColor',[0.10 0.12 0.15]);
        lv = uilabel(par,'Text','—','Position',[x+4 yc+8 98 34],...
            'FontSize',18,'FontWeight','bold','FontColor',CLR_TXT,...
            'BackgroundColor',[0.10 0.12 0.15],'HorizontalAlignment','center');
    end

    %% -----------------------------------------------------------------------
    %  STRUCT DO MODELO
    %% -----------------------------------------------------------------------
    mdl.ready=false; mdl.mu=[]; mdl.sigma=[]; mdl.logPrior=[];
    mdl.classes={}; mdl.sigTrain=[]; mdl.hashData=[]; mdl.YTrain=[];
    mdl.bf=[]; mdl.thresholds=[];
    mdl.acc_ens=0; mdl.acc_nb=0; mdl.f1_macro=0;
    mdl.fpr_macro=0; mdl.fnr_macro=0; mdl.tpr_macro=0; mdl.prec_macro=0;

    %% =======================================================================
    %%  PAINEL ESQUERDO — CSV + treino + log
    %% =======================================================================
    pT2L = uipanel(fig,'Position',[10 10 310 740],...
        'BackgroundColor',CLR_PANEL,'BorderType','none');
    uilabel(pT2L,'Text','DADOS DE TREINO','Position',[10 705 290 26],...
        'FontSize',12,'FontWeight','bold','FontColor',CLR_ACCENT,...
        'BackgroundColor',CLR_PANEL,'HorizontalAlignment','left');
    uilabel(pT2L,'Text','Pasta do projecto:','Position',[10 672 290 20],...
        'FontSize',10,'FontColor',CLR_TXT,'BackgroundColor',CLR_PANEL);
    edBaseDirT2 = uieditfield(pT2L,'text','Position',[10 646 258 26],...
        'Value',pwd,'FontSize',9,'BackgroundColor',[0.10 0.12 0.15],'FontColor',CLR_TXT);
    uibutton(pT2L,'push','Text','...','Position',[272 646 38 26],...
        'BackgroundColor',[0.25 0.28 0.33],'FontColor',CLR_TXT,...
        'ButtonPushedFcn',@(~,~)pickBaseDirT2());
    uilabel(pT2L,'Text','Ficheiro CSV (treino):','Position',[10 614 290 20],...
        'FontSize',10,'FontColor',CLR_TXT,'BackgroundColor',CLR_PANEL);
    edCSVT2 = uieditfield(pT2L,'text','Position',[10 588 258 26],...
        'Value','data/aveiro.csv','FontSize',9,...
        'BackgroundColor',[0.10 0.12 0.15],'FontColor',CLR_TXT);
    uibutton(pT2L,'push','Text','...','Position',[272 588 38 26],...
        'BackgroundColor',[0.25 0.28 0.33],'FontColor',CLR_TXT,...
        'ButtonPushedFcn',@(~,~)pickCSVT2());

    uilabel(pT2L,'Text','Rácio de treino (%):','Position',[10 558 200 20],...
        'FontSize',10,'FontColor',CLR_TXT,'BackgroundColor',CLR_PANEL);
    lblRatioT2 = uilabel(pT2L,'Text','80 %','Position',[220 558 80 20],...
        'FontSize',10,'FontWeight','bold','FontColor',CLR_ACCENT,...
        'BackgroundColor',CLR_PANEL,'HorizontalAlignment','right');
    slRatioT2 = uislider(pT2L,'Limits',[50 100],'Value',80,...
        'MajorTicks',[50 60 70 80 90 100],'Position',[10 533 290 slH],'FontColor',CLR_TXT,...
        'ValueChangedFcn',@(s,~)set(lblRatioT2,'Text',sprintf('%d %%',round(s.Value))));

    btnTrain = uibutton(pT2L,'push','Text','⚙  Treinar Modelo',...
        'Position',[10 450 290 42],'BackgroundColor',[0.20 0.45 0.65],...
        'FontColor',CLR_BTN_TXT,'FontSize',12,'FontWeight','bold',...
        'ButtonPushedFcn',@(~,~)trainModelT2());

    pbBgT2 = uipanel(pT2L,'Position',[10 432 290 14],...
        'BackgroundColor',[0.10 0.12 0.15],'BorderType','none','Visible','off');
    pbFgT2 = uipanel(pbBgT2,'Position',[0 0 1 14],...
        'BackgroundColor',CLR_ACCENT,'BorderType','none');

    lblStatusT2 = uilabel(pT2L,'Text','● Modelo não treinado',...
        'Position',[10 404 290 24],'FontSize',10,'FontWeight','bold',...
        'FontColor',CLR_WARN,'BackgroundColor',CLR_PANEL,'HorizontalAlignment','center');

    uilabel(pT2L,'Text','Log de treino:','Position',[10 380 290 20],...
        'FontSize',9,'FontColor',[0.55 0.65 0.75],'BackgroundColor',CLR_PANEL);
    taLogT2 = uitextarea(pT2L,'Position',[10 10 290 365],'Value','',...
        'FontSize',8,'FontName','Courier New',...
        'BackgroundColor',[0.07 0.09 0.11],'FontColor',[0.75 0.90 0.75],'Editable','off');

    %% =======================================================================
    %%  PAINEL CENTRAL — inputs das features
    %% =======================================================================
    pT2M = uipanel(fig,'Position',[330 10 440 740],...
        'BackgroundColor',CLR_PANEL,'BorderType','none');
    uilabel(pT2M,'Text','VALORES DA AMOSTRA','Position',[10 705 420 26],...
        'FontSize',12,'FontWeight','bold','FontColor',CLR_ACCENT,...
        'BackgroundColor',CLR_PANEL,'HorizontalAlignment','left');
    uilabel(pT2M,'Text','(slider ou campo numérico — prima Prever após treinar)',...
        'Position',[10 684 420 18],'FontSize',9,...
        'FontColor',[0.55 0.65 0.75],'BackgroundColor',CLR_PANEL);

    % {nome, unidade, min, max, default}
    % month_sin, month_cos, temp_mean, season_temp e cos_x_tmax
    % são calculados automaticamente em background.
    featureDefs = {
        'precipitation',       'mm',    0,   500,   2.0    % máx diário extremo (~1825mm Réunion 2007)
        'temp_max',            'C',   -50,    55,  18.0    % -50 Sibéria / +54 Death Valley
        'temp_min',            'C',   -55,    45,   8.0    % -55 Yakutsk / +45 extremos secos
        'sunshine_duration',   'h',     0,    24,   5.0    % 0–24 h
        'shortwave_radiation', 'MJ',    0,    45,  10.0    % ~40–42 MJ/m² em dias solsticiais equatoriais
        'wind_speed_max',      'km/h',  0,   250,  20.0    % acima de 220 já é furacão cat-5
        'wind_gusts_max',      'km/h',  0,   400,  35.0    % récord mundial ~407 km/h (Barrow Is. 1996)
        'snowfall',            'cm',    0,   200,   0.0    % >150 cm em tempestades extremas
        'month',               '',      1,    12,   1.0
        'humidity_mean',       '%',     0,   100,  75.0
        'humidity_min',        '%',     0,   100,  55.0
        'cloud_cover_mean',    '%',     0,   100,  40.0
        'pressure_mean',       'hPa', 860,  1090, 1015.0   % récord mín ~870 hPa (tufão); máx ~1084 hPa
        'pressure_min',        'hPa', 850,  1090, 1013.0
        'precipitation_hours', 'h',     0,    24,   2.0
    };
    nFeat       = size(featureDefs,1);
    featEdits   = cell(nFeat,1);
    featSliders = cell(nFeat,1);

    colX=[ 10 230 ]; rowH=62; startY=610;
    for fi = 1:nFeat
        col  = mod(fi-1,2);
        row  = floor((fi-1)/2);
        xPos = colX(col+1);
        yPos = startY - row*rowH;
        fname = featureDefs{fi,1};
        funit = featureDefs{fi,2};
        fmin  = featureDefs{fi,3};
        fmax  = featureDefs{fi,4};
        fdef  = featureDefs{fi,5};
        if isempty(funit), lblTxt=fname;
        else,              lblTxt=[fname ' (' funit ')'];
        end
        uilabel(pT2M,'Text',lblTxt,'Position',[xPos yPos+40 210 16],...
            'FontSize',8,'FontColor',[0.65 0.75 0.85],...
            'BackgroundColor',CLR_PANEL,'Interpreter','none');
        featEdits{fi} = uieditfield(pT2M,'numeric',...
            'Position',[xPos yPos+16 70 22],'Value',fdef,...
            'Limits',[fmin fmax],...
            'LowerLimitInclusive','on','UpperLimitInclusive','on',...
            'FontSize',9,'BackgroundColor',[0.10 0.12 0.15],'FontColor',CLR_TXT);
        featSliders{fi} = uislider(pT2M,'Limits',[fmin fmax],'Value',fdef,...
            'MajorTicks',[],'Position',[xPos+85 yPos+20 130 slH],'FontColor',CLR_TXT);
        sl_i = featSliders{fi};
        ed_i = featEdits{fi};
        sl_i.ValueChangedFcn = @(s,~) set(ed_i,'Value',s.Value);
        ed_i.ValueChangedFcn = @(e,~) set(sl_i,'Value',max(fmin,min(fmax,e.Value)));
    end

    %% =======================================================================
    %%  PAINEL DIREITO — resultado
    %%  Layout (y cresce para cima):
    %%    705  Título
    %%    620  Card "Classe prevista"                     (h=76)
    %%    542  Linha 1 de cards: Acc Ens | Acc NB | F1   (h=68)
    %%    468  Linha 2 de cards: FPR     | FNR    | TPR  (h=68)
    %%    418  Botão Prever                               (h=44)
    %%    392  Label gráfico
    %%    228  Gráfico probabilidades NB                  (h=160)
    %%    204  Label detalhes
    %%     10  Área de texto detalhada                    (h=190)
    %% =======================================================================
    pT2R = uipanel(fig,'Position',[780 10 310 740],...
        'BackgroundColor',CLR_PANEL,'BorderType','none');
    uilabel(pT2R,'Text','RESULTADO DA PREVISÃO','Position',[10 705 290 26],...
        'FontSize',12,'FontWeight','bold','FontColor',CLR_ACCENT,...
        'BackgroundColor',CLR_PANEL,'HorizontalAlignment','left');

    % Card grande — classe prevista
    uipanel(pT2R,'Position',[10 620 290 76],...
        'BackgroundColor',[0.10 0.12 0.15],'BorderType','none');
    uilabel(pT2R,'Text','Classe prevista','Position',[14 678 180 18],'FontSize',9,...
        'FontColor',[0.55 0.65 0.75],'BackgroundColor',[0.10 0.12 0.15]);
    lblPredClass = uilabel(pT2R,'Text','—','Position',[14 628 282 46],...
        'FontSize',26,'FontWeight','bold','FontColor',CLR_TXT,...
        'BackgroundColor',[0.10 0.12 0.15],'HorizontalAlignment','center');

    % Linha 1: Exatidão Ensemble | Exatidão NB | F1 Macro
    lblPredAccEns = makeCard(pT2R, 10,542,'Acc. Ensemble (teste)');
    lblPredAccNB  = makeCard(pT2R,126,542,'Acc. NB (teste)');
    lblPredF1     = makeCard(pT2R,242,542,'F1 Macro (teste)');

    % Linha 2: FPR Macro | FNR Macro | TPR Macro
    lblPredFPR    = makeCard(pT2R, 10,468,'FPR Macro (teste)');
    lblPredFNR    = makeCard(pT2R,126,468,'FNR Macro (teste)');
    lblPredTPR    = makeCard(pT2R,242,468,'TPR Macro (teste)');

    % Botão Prever
    btnPredict = uibutton(pT2R,'push','Text','🔍  Prever',...  %#ok<NASGU>
        'Position',[10 418 290 44],...
        'BackgroundColor',CLR_BTN,'FontColor',CLR_BTN_TXT,...
        'FontSize',14,'FontWeight','bold',...
        'ButtonPushedFcn',@(~,~)predictSingle());

    % Gráfico probabilidades NB
    uilabel(pT2R,'Text','Probabilidades por classe (Naive Bayes):',...
        'Position',[10 392 290 22],'FontSize',10,...
        'FontColor',CLR_ACCENT,'BackgroundColor',CLR_PANEL);
    axProb = uiaxes(pT2R,'Position',[10 228 290 160],...
        'Color',[0.10 0.12 0.15],'XColor',CLR_TXT,'YColor',CLR_TXT);
    axProb.FontSize = 9;

    % Área de texto detalhada
    uilabel(pT2R,'Text','Detalhes:','Position',[10 204 290 22],'FontSize',10,...
        'FontColor',CLR_ACCENT,'BackgroundColor',CLR_PANEL);
    taResult = uitextarea(pT2R,'Position',[10 10 290 190],...
        'Value','Treine o modelo e prima Prever.',...
        'FontSize',9,'FontName','Courier New',...
        'BackgroundColor',[0.07 0.09 0.11],'FontColor',[0.75 0.90 0.75],'Editable','off');

    %% =======================================================================
    %%  CALLBACKS
    %% =======================================================================
    function pickBaseDirT2()
        d=uigetdir(edBaseDirT2.Value,'Seleccionar pasta');
        if d~=0, edBaseDirT2.Value=d; end
    end
    function pickCSVT2()
        [f,p]=uigetfile('*.csv','Seleccionar CSV',edBaseDirT2.Value);
        if f~=0
            fullp=fullfile(p,f); base=edBaseDirT2.Value;
            if startsWith(fullp,base)
                edCSVT2.Value=fullp(length(base)+2:end);
            else
                edCSVT2.Value=fullp;
            end
        end
    end
    function logT2(msg,varargin)
        if nargin>1, msg=sprintf(msg,varargin{:}); end
        cur=taLogT2.Value; if ischar(cur),cur={cur}; end
        taLogT2.Value=[cur;{msg}]; scroll(taLogT2,'bottom'); drawnow limitrate;
    end
    function setProgressT2(val)
        val=max(0,min(1,val)); pbBgT2.Visible='on';
        pbFgT2.Position(3)=max(1,round(val*290)); drawnow;
    end

    %% =======================================================================
    %%  TREINAR MODELO
    %% =======================================================================
    function trainModelT2()
        btnTrain.Enable='off'; mdl.ready=false;
        set(taLogT2,'Value',''); setProgressT2(0);
        lblStatusT2.Text='● A treinar...'; lblStatusT2.FontColor=CLR_WARN; drawnow;
        try
            baseDir2=edBaseDirT2.Value; csvRel2=edCSVT2.Value;
            if isAbsolutePath(csvRel2), csvPath2=csvRel2;
            else,                       csvPath2=fullfile(baseDir2,csvRel2); end
            addpath(fullfile(baseDir2,'naive_bayes'));
            addpath(fullfile(baseDir2,'bloom_filter'));
            addpath(fullfile(baseDir2,'minhash'));
            if ~isfile(csvPath2), error('Ficheiro não encontrado: %s',csvPath2); end
            logT2('A ler %s ...',csvPath2);
            d2=readtable(csvPath2);
            for ci={'date','dew_point_mean','dew_point_max'}
                if ismember(ci{1},d2.Properties.VariableNames), d2.(ci{1})=[]; end
            end
            if ismember('temp_max',d2.Properties.VariableNames) && ...
               ismember('temp_min',d2.Properties.VariableNames)
                d2.temp_mean=(d2.temp_max+d2.temp_min)/2;
                if ismember('month_cos',d2.Properties.VariableNames)
                    d2.season_temp=d2.temp_mean.*d2.month_cos;
                    d2.cos_x_tmax =d2.month_cos.*d2.temp_max;
                end
            end
            Y2=categorical(d2.weather);
            X2=table2array(removevars(d2,'weather'));
            logT2('  %d amostras, %d features',size(X2,1),size(X2,2));
            logT2('  Classes: %s',strjoin(categories(Y2),', '));
            setProgressT2(0.10);
            trainRatio2=slRatioT2.Value/100;
            rng('shuffle');
            idxP2=randperm(size(X2,1)); nTr2=round(trainRatio2*numel(idxP2));

            % Tratamento especial se rácio for 100%
            if nTr2 == size(X2,1)
                XTr2=X2(idxP2,:); YTr2=Y2(idxP2);
                XTe2=XTr2;        YTe2=YTr2;
                logT2('  Treino: %d  Teste: %d (Aviso: 100%% - testado no treino)',size(XTr2,1),size(XTe2,1));
            else
                XTr2=X2(idxP2(1:nTr2),:);     YTr2=Y2(idxP2(1:nTr2));
                XTe2=X2(idxP2(nTr2+1:end),:); YTe2=Y2(idxP2(nTr2+1:end));
                logT2('  Treino: %d  Teste: %d',size(XTr2,1),size(XTe2,1));
            end

            setProgressT2(0.20);
            logT2('Thresholds...'); thr2=compute_thresholds(XTr2,YTr2);
            setProgressT2(0.30);
            logT2('Bloom Filter...');
            bf2=bloom_init(50000,7);
            for ii=1:size(XTr2,1)
                key=build_bf_key(XTr2(ii,:),BF_COLS,BF_BREAKS);
                bf2=bloom_insert(bf2,key);
            end
            setProgressT2(0.45);
            logT2('MinHash (200 hashes)...');
            tTok2=cell(size(XTr2,1),1);
            for ii=1:size(XTr2,1), tTok2{ii}=extract_features(XTr2(ii,:),thr2); end
            [sig2,hd2]=minhash_signature(tTok2,200);
            setProgressT2(0.65);
            logT2('Naive Bayes...');
            [mu2,sigma2,logPr2,cls2]=nb_train(XTr2,YTr2);
            setProgressT2(0.80);
            logT2('A avaliar...');
            prev2=ensemble_predict(XTe2,YTr2,sig2,bf2,...
                mu2,sigma2,logPr2,cls2,hd2,0.55,0.40,0.05,BF_COLS,BF_BREAKS,thr2);
            acc_ens2=mean(prev2==YTe2);
            [~,pNB2]=nb_predict(XTe2,mu2,sigma2,logPr2,cls2);
            [~,iNB2]=max(pNB2,[],2);
            acc_nb2=mean(categorical(cls2(iNB2))==YTe2);

            %% --- Métricas por classe: Precision, Recall/TPR, F1, FPR, FNR ---
            nC2=numel(cls2); nTe2=numel(YTe2);
            f1s2=zeros(nC2,1); fprs2=zeros(nC2,1); fnrs2=zeros(nC2,1);
            tprs2=zeros(nC2,1); precs2=zeros(nC2,1);
            for c=1:nC2
                tp2=sum(prev2==cls2{c}&YTe2==cls2{c});
                fp2=sum(prev2==cls2{c}&YTe2~=cls2{c});
                fn2=sum(prev2~=cls2{c}&YTe2==cls2{c});
                tn2=nTe2-tp2-fp2-fn2;
                p2 =tp2/max(tp2+fp2,1);
                r2 =tp2/max(tp2+fn2,1);           % Recall = TPR
                f1s2(c) =2*p2*r2/max(p2+r2,1e-9);
                fprs2(c)=fp2/max(fp2+tn2,1);       % FPR = FP/(FP+TN)
                fnrs2(c)=fn2/max(fn2+tp2,1);        % FNR = FN/(FN+TP)
                tprs2(c)=r2;                         % TPR = Recall
                precs2(c)=p2;
            end
            f1mac2   =mean(f1s2);
            fpr_mac2 =mean(fprs2);
            fnr_mac2 =mean(fnrs2);
            tpr_mac2 =mean(tprs2);
            prec_mac2=mean(precs2);

            %% --- Log: tabela de avaliação completa ---
            logT2(''); logT2('=== AVALIAÇÃO NO CONJUNTO DE TESTE ===');
            logT2('  Exatidão (Ensemble) : %.2f%%', acc_ens2*100);
            logT2('  Exatidão (NB)       : %.2f%%', acc_nb2*100);
            logT2('');
            logT2('%-10s %8s %8s %6s %8s %8s', ...
                'Classe','Prec','TPR/Rec','F1','FPR','FNR');
            logT2('%s', repmat('-',1,55));
            for c=1:nC2
                logT2('%-10s %7.2f%% %7.2f%% %5.2f%% %7.2f%% %7.2f%%', ...
                    cls2{c}, precs2(c)*100, tprs2(c)*100, f1s2(c)*100, ...
                    fprs2(c)*100, fnrs2(c)*100);
            end
            logT2('%s', repmat('-',1,55));
            logT2('%-10s %7.2f%% %7.2f%% %5.2f%% %7.2f%% %7.2f%%', ...
                'Macro', prec_mac2*100, tpr_mac2*100, f1mac2*100, ...
                fpr_mac2*100, fnr_mac2*100);
            logT2('');
            logT2('  TPR=Recall | FPR=FP/(FP+TN) | FNR=FN/(FN+TP)');

            %% --- Log: Matriz de Confusão (texto) ---
            logT2('');
            logT2('--- Matriz de Confusão ---');
            confMat2=confusionmat(YTe2,prev2,'Order',cls2);
            hdr=sprintf('%12s','');
            for c=1:nC2, hdr=[hdr sprintf('%10s',cls2{c})]; end %#ok<AGROW>
            logT2('%s  <- Previsto', hdr);
            logT2('%s', repmat('-',1,12+nC2*10+14));
            for c=1:nC2
                rowStr=sprintf('%-12s',cls2{c});
                for k=1:nC2, rowStr=[rowStr sprintf('%10d',confMat2(c,k))]; end %#ok<AGROW>
                logT2('%s', rowStr);
            end
            logT2('^ Real');
            logT2(''); logT2('Modelo pronto. Prima Prever.');

            %% --- Mostrar matriz de confusão visual numa nova figura ---
            try
                figure('Name','Matriz de Confusão — Ensemble');
                cm2=confusionchart(YTe2,prev2,...
                    'RowSummary','row-normalized',...
                    'ColumnSummary','column-normalized',...
                    'Title','Ensemble — Matriz de Confusão');
                cm2.ClassLabels=cls2;
            catch
            end

            %% --- Guardar modelo e actualizar cards ---
            mdl.mu=mu2; mdl.sigma=sigma2; mdl.logPrior=logPr2;
            mdl.classes=cls2; mdl.sigTrain=sig2; mdl.hashData=hd2;
            mdl.YTrain=YTr2; mdl.bf=bf2; mdl.thresholds=thr2;
            mdl.acc_ens=acc_ens2;   mdl.acc_nb=acc_nb2;   mdl.f1_macro=f1mac2;
            mdl.fpr_macro=fpr_mac2; mdl.fnr_macro=fnr_mac2;
            mdl.tpr_macro=tpr_mac2; mdl.prec_macro=prec_mac2;
            mdl.ready=true;

            set(lblPredAccEns,'Text',sprintf('%.2f%%',acc_ens2*100),'FontColor',CLR_OK);
            set(lblPredAccNB, 'Text',sprintf('%.2f%%',acc_nb2*100), 'FontColor',CLR_TXT);
            set(lblPredF1,    'Text',sprintf('%.2f%%',f1mac2*100),  'FontColor',CLR_ACCENT);
            set(lblPredFPR,   'Text',sprintf('%.2f%%',fpr_mac2*100),'FontColor',CLR_WARN);
            set(lblPredFNR,   'Text',sprintf('%.2f%%',fnr_mac2*100),'FontColor',CLR_WARN);
            set(lblPredTPR,   'Text',sprintf('%.2f%%',tpr_mac2*100),'FontColor',CLR_OK);
            setProgressT2(1.0);
            lblStatusT2.Text='● Modelo pronto'; lblStatusT2.FontColor=CLR_OK;
        catch ME
            logT2('ERRO: %s',ME.message);
            for si=1:numel(ME.stack)
                logT2('  em %s (linha %d)',ME.stack(si).name,ME.stack(si).line);
            end
            lblStatusT2.Text='● Erro no treino'; lblStatusT2.FontColor=[0.90 0.25 0.25];
        end
        pbBgT2.Visible='off'; btnTrain.Enable='on';
    end

    %% =======================================================================
    %%  PREVER AMOSTRA ÚNICA
    %% =======================================================================
    function predictSingle()
        if ~mdl.ready
            taResult.Value={'Modelo não treinado.','Prima "Treinar Modelo" primeiro.'};
            return;
        end

        % 1. Ler os valores introduzidos na UI (15 features visíveis)
        raw = zeros(1, nFeat);
        for fi=1:nFeat, raw(fi)=featEdits{fi}.Value; end

        % 2. Extrair variáveis-chave
        tmax = raw(2);
        tmin = raw(3);
        m    = raw(9);

        % 3. Calcular features derivadas em background
        trange    = tmax - tmin;
        m_sin     = sin(2 * pi * m / 12);
        m_cos     = cos(2 * pi * m / 12);
        tmean     = (tmax + tmin) / 2;
        seas_temp = tmean * m_cos;
        c_x_tmax  = m_cos * tmax;

        % 4. Reconstruir o array de 20 posições para o modelo
        row = zeros(1, 20);
        row(1:8)   = raw(1:8);       % precipitation → snowfall
        row(9)     = trange;         % temp_range
        row(10)    = m_sin;          % month_sin
        row(11)    = m_cos;          % month_cos
        row(12:17) = raw(10:15);     % humidity_mean → precipitation_hours
        row(18)    = tmean;          % temp_mean
        row(19)    = seas_temp;      % season_temp
        row(20)    = c_x_tmax;       % cos_x_tmax

        try
            prev=ensemble_predict(row,mdl.YTrain,mdl.sigTrain,mdl.bf,...
                mdl.mu,mdl.sigma,mdl.logPrior,mdl.classes,mdl.hashData,...
                0.55,0.40,0.05,BF_COLS,BF_BREAKS,mdl.thresholds);
            predStr=char(prev);

            [~,logNB]=nb_predict(row,mdl.mu,mdl.sigma,mdl.logPrior,mdl.classes);
            logNB=logNB(:)'-max(logNB(:));
            pNB=exp(logNB)/sum(exp(logNB));

            lblPredClass.Text=upper(predStr);
            switch predStr
                case 'sun',     lblPredClass.FontColor=[1.00 0.85 0.20];
                case 'rain',    lblPredClass.FontColor=[0.30 0.65 1.00];
                case 'drizzle', lblPredClass.FontColor=[0.55 0.80 1.00];
                case 'fog',     lblPredClass.FontColor=[0.75 0.75 0.75];
                case 'thunder', lblPredClass.FontColor=[1.00 0.55 0.20];
                otherwise,      lblPredClass.FontColor=CLR_TXT;
            end

            % Barras de probabilidade
            cla(axProb);
            nC=numel(mdl.classes);
            bClr=repmat([0.22 0.60 0.86],nC,1);
            pIdx=find(strcmp(mdl.classes,predStr),1);
            if ~isempty(pIdx), bClr(pIdx,:)=[0.25 0.75 0.45]; end
            bh=bar(axProb,1:nC,pNB*100,'FaceColor','flat'); bh.CData=bClr;
            axProb.XTick=1:nC; axProb.XTickLabel=mdl.classes;
            axProb.FontSize=8; axProb.Color=[0.10 0.12 0.15];
            axProb.XColor=CLR_TXT; axProb.YColor=CLR_TXT;
            ylabel(axProb,'%');
            title(axProb,'Probabilidades NB','FontSize',9,'Color',CLR_TXT);
            ylim(axProb,[0 100]);

            % Texto detalhado
            lines={'=== PREVISÃO DETALHADA ===',''};
            lines{end+1}=sprintf('Classe prevista : %s',predStr);
            lines{end+1}='';
            lines{end+1}='Probabilidades Naive Bayes:';
            for ci=1:nC
                mk=''; if ci==pIdx, mk=' <--'; end
                lines{end+1}=sprintf('  %-12s %6.2f%%%s',mdl.classes{ci},pNB(ci)*100,mk);
            end
            lines{end+1}='';
            lines{end+1}='--- Métricas do modelo (conjunto de teste) ---';
            lines{end+1}=sprintf('  Exatidão Ensemble : %.2f%%',mdl.acc_ens*100);
            lines{end+1}=sprintf('  Exatidão NB       : %.2f%%',mdl.acc_nb*100);
            lines{end+1}=sprintf('  Precisão Macro    : %.2f%%',mdl.prec_macro*100);
            lines{end+1}=sprintf('  TPR Macro         : %.2f%%',mdl.tpr_macro*100);
            lines{end+1}=sprintf('  F1 Macro          : %.2f%%',mdl.f1_macro*100);
            lines{end+1}=sprintf('  FPR Macro         : %.2f%%',mdl.fpr_macro*100);
            lines{end+1}=sprintf('  FNR Macro         : %.2f%%',mdl.fnr_macro*100);
            lines{end+1}='  (ver log de treino para tabela por classe)';
            lines{end+1}='';
            lines{end+1}='--- Valores introduzidos ---';
            for fi2=1:nFeat
                lines{end+1}=sprintf('  %-24s %g',featureDefs{fi2,1},raw(fi2));
            end
            lines{end+1}='';
            lines{end+1}='--- Valores calculados em fundo ---';
            lines{end+1}=sprintf('  %-24s %.2f', 'temp_range',  trange);
            lines{end+1}=sprintf('  %-24s %.4f', 'month_sin',   m_sin);
            lines{end+1}=sprintf('  %-24s %.4f', 'month_cos',   m_cos);
            lines{end+1}=sprintf('  %-24s %.2f', 'temp_mean',   tmean);
            lines{end+1}=sprintf('  %-24s %.2f', 'season_temp', seas_temp);
            lines{end+1}=sprintf('  %-24s %.2f', 'cos_x_tmax',  c_x_tmax);

            taResult.Value=lines;
        catch ME
            taResult.Value={sprintf('ERRO: %s',ME.message)};
        end
    end

    %% -----------------------------------------------------------------------
    %  UTILITÁRIO
    %% -----------------------------------------------------------------------
    function res = isAbsolutePath(p)
        res = startsWith(p, '/') || (length(p) >= 3 && p(2) == ':' && p(3) == '\');
    end
end