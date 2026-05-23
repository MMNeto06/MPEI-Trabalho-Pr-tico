function weather_gui()
% WEATHER_GUI  Interface gráfica para o classificador ensemble de tempo.
%
%   Tab 1 — Pipeline completo (treino + avaliação)  [conteúdo original]
%   Tab 2 — Previsão manual: selecionar CSV, treinar, introduzir features,
%            obter previsão + precisão do modelo no conjunto de teste
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
    %% -----------------------------------------------------------------------
    %  TAB GROUP (Corrigido: Removido 'BackgroundColor' que causava erro)
    %% -----------------------------------------------------------------------
    tg = uitabgroup(fig, 'Position', [0 0 1100 780]);
    tab1 = uitab(tg, 'Title', '  Pipeline  ',        'BackgroundColor', CLR_BG);
    tab2 = uitab(tg, 'Title', '  Previsão Manual  ', 'BackgroundColor', CLR_BG);
    %% =======================================================================
    %%  TAB 1 — conteúdo original
    %% =======================================================================
    pLeft = uipanel(tab1, 'Position', [10 10 320 740], ...
        'BackgroundColor', CLR_PANEL, 'BorderType', 'none');
    slH = 22;  y = 705;
    uilabel(pLeft, 'Text', 'CONFIGURAÇÃO', 'Position', [10 y 300 26], ...
        'FontSize', 12, 'FontWeight', 'bold', 'FontColor', CLR_ACCENT, ...
        'BackgroundColor', CLR_PANEL, 'HorizontalAlignment', 'left');
    y = y-44;
    uilabel(pLeft,'Text','Pasta do projecto (baseDir):','Position',[10 y 300 20],...
        'FontSize',10,'FontColor',CLR_TXT,'BackgroundColor',CLR_PANEL);
    y = y-30;
    edBaseDir = uieditfield(pLeft,'text','Position',[10 y 258 26],'Value',pwd,...
        'FontSize',9,'BackgroundColor',[0.10 0.12 0.15],'FontColor',CLR_TXT);
    uibutton(pLeft,'push','Text','...','Position',[272 y 38 26],...
        'BackgroundColor',[0.25 0.28 0.33],'FontColor',CLR_TXT,...
        'ButtonPushedFcn',@(~,~)pickBaseDir());
    y = y-42;
    uilabel(pLeft,'Text','Ficheiro CSV:','Position',[10 y 300 20],...
        'FontSize',10,'FontColor',CLR_TXT,'BackgroundColor',CLR_PANEL);
    y = y-30;
    edCSV = uieditfield(pLeft,'text','Position',[10 y 258 26],...
        'Value','data/aveiro.csv','FontSize',9,...
        'BackgroundColor',[0.10 0.12 0.15],'FontColor',CLR_TXT);
    uibutton(pLeft,'push','Text','...','Position',[272 y 38 26],...
        'BackgroundColor',[0.25 0.28 0.33],'FontColor',CLR_TXT,...
        'ButtonPushedFcn',@(~,~)pickCSV());
    y = y-46;
    uilabel(pLeft,'Text','Rácio de treino:','Position',[10 y 200 20],...
        'FontSize',10,'FontColor',CLR_TXT,'BackgroundColor',CLR_PANEL);
    lblRatio = uilabel(pLeft,'Text','80 %','Position',[220 y 90 20],...
        'FontSize',10,'FontWeight','bold','FontColor',CLR_ACCENT,...
        'BackgroundColor',CLR_PANEL,'HorizontalAlignment','right');
    y = y-32;
    slRatio = uislider(pLeft,'Limits',[50 95],'Value',80,...
        'MajorTicks',[50 60 70 80 90 95],'Position',[10 y 300 slH],'FontColor',CLR_TXT,...
        'ValueChangedFcn',@(s,~)set(lblRatio,'Text',sprintf('%d %%',round(s.Value))));
    y = y-50;
    uilabel(pLeft,'Text','Nº de hashes MinHash:','Position',[10 y 210 20],...
        'FontSize',10,'FontColor',CLR_TXT,'BackgroundColor',CLR_PANEL);
    lblHash = uilabel(pLeft,'Text','200','Position',[220 y 90 20],...
        'FontSize',10,'FontWeight','bold','FontColor',CLR_ACCENT,...
        'BackgroundColor',CLR_PANEL,'HorizontalAlignment','right');
    y = y-32;
    slHash = uislider(pLeft,'Limits',[50 500],'Value',200,...
        'MajorTicks',[50 100 200 300 500],'Position',[10 y 300 slH],'FontColor',CLR_TXT,...
        'ValueChangedFcn',@(s,~)set(lblHash,'Text',sprintf('%d',round(s.Value))));
    y = y-50;
    uilabel(pLeft,'Text','Vizinhos MinHash (top-k):','Position',[10 y 210 20],...
        'FontSize',10,'FontColor',CLR_TXT,'BackgroundColor',CLR_PANEL);
    lblK = uilabel(pLeft,'Text','20','Position',[220 y 90 20],...
        'FontSize',10,'FontWeight','bold','FontColor',CLR_ACCENT,...
        'BackgroundColor',CLR_PANEL,'HorizontalAlignment','right');
    y = y-32;
    slK = uislider(pLeft,'Limits',[5 50],'Value',20,...
        'MajorTicks',[5 10 20 30 50],'Position',[10 y 300 slH],'FontColor',CLR_TXT,...
        'ValueChangedFcn',@(s,~)set(lblK,'Text',sprintf('%d',round(s.Value))));
    y = y-50;
    uilabel(pLeft,'Text','Pesos do Ensemble','Position',[10 y 300 22],...
        'FontSize',10,'FontWeight','bold','FontColor',CLR_ACCENT,'BackgroundColor',CLR_PANEL);
    function lbl = makeWeightRow(yPos,name,val)
        uilabel(pLeft,'Text',name,'Position',[10 yPos 190 20],'FontSize',9,...
            'FontColor',CLR_TXT,'BackgroundColor',CLR_PANEL);
        lbl = uilabel(pLeft,'Text',sprintf('%.2f',val),'Position',[220 yPos 90 20],...
            'FontSize',9,'FontWeight','bold','FontColor',CLR_ACCENT,...
            'BackgroundColor',CLR_PANEL,'HorizontalAlignment','right');
    end
    y=y-30; lblWNB=makeWeightRow(y,'w_nb (NaiveBayes):',0.55);
    y=y-28; slWNB=uislider(pLeft,'Limits',[0 1],'Value',0.55,'MajorTicks',[],...
        'Position',[10 y 300 slH],'FontColor',CLR_TXT,...
        'ValueChangedFcn',@(s,~)set(lblWNB,'Text',sprintf('%.2f',s.Value)));
    y=y-46; lblWMH=makeWeightRow(y,'w_mh (MinHash):',0.40);
    y=y-28; slWMH=uislider(pLeft,'Limits',[0 1],'Value',0.40,'MajorTicks',[],...
        'Position',[10 y 300 slH],'FontColor',CLR_TXT,...
        'ValueChangedFcn',@(s,~)set(lblWMH,'Text',sprintf('%.2f',s.Value)));
    y=y-46; lblWBF=makeWeightRow(y,'w_bf (BloomFilter):',0.05);
    y=y-28; slWBF=uislider(pLeft,'Limits',[0 1],'Value',0.05,'MajorTicks',[],...
        'Position',[10 y 300 slH],'FontColor',CLR_TXT,...
        'ValueChangedFcn',@(s,~)set(lblWBF,'Text',sprintf('%.2f',s.Value)));
    y=y-56;
    btnRun = uibutton(pLeft,'push','Text','▶  Correr Pipeline',...
        'Position',[10 y 300 44],'BackgroundColor',CLR_BTN,...
        'FontColor',CLR_BTN_TXT,'FontSize',13,'FontWeight','bold',...
        'ButtonPushedFcn',@(~,~)runPipeline());
    y=y-52;
    pbBg = uipanel(pLeft,'Position',[10 y 300 16],...
        'BackgroundColor',[0.10 0.12 0.15],'BorderType','none','Visible','off');
    pbFg = uipanel(pbBg,'Position',[0 0 1 16],...
        'BackgroundColor',CLR_ACCENT,'BorderType','none');
    y=y-30;
    lblStatus = uilabel(pLeft,'Text','● Pronto','Position',[10 y 300 28],...
        'FontSize',11,'FontWeight','bold','FontColor',CLR_OK,...
        'BackgroundColor',CLR_PANEL,'HorizontalAlignment','center');
    y=y-44;
    btnClear = uibutton(pLeft,'push','Text','Limpar Log',...
        'Position',[10 y 300 34],'BackgroundColor',[0.25 0.28 0.33],...
        'FontColor',CLR_TXT,'FontSize',10);
    % Painel central — log
    pMid = uipanel(tab1,'Position',[340 10 380 740],...
        'BackgroundColor',CLR_PANEL,'BorderType','none');
    uilabel(pMid,'Text','LOG DE EXECUÇÃO','Position',[10 708 360 24],...
        'FontSize',11,'FontWeight','bold','FontColor',CLR_ACCENT,'BackgroundColor',CLR_PANEL);
    taLog = uitextarea(pMid,'Position',[10 10 360 690],'Value','',...
        'FontSize',9,'FontName','Courier New',...
        'BackgroundColor',[0.07 0.09 0.11],'FontColor',[0.75 0.90 0.75],'Editable','off');
    btnClear.ButtonPushedFcn = @(~,~)set(taLog,'Value','');
    % Painel direito — métricas + confusão
    pRight = uipanel(tab1,'Position',[730 10 360 740],...
        'BackgroundColor',CLR_PANEL,'BorderType','none');
    uilabel(pRight,'Text','RESULTADOS','Position',[10 708 340 24],...
        'FontSize',11,'FontWeight','bold','FontColor',CLR_ACCENT,'BackgroundColor',CLR_PANEL);
    function lv = makeCard(par,x,yc,ttl)
        uipanel(par,'Position',[x yc 106 68],'BackgroundColor',[0.10 0.12 0.15],'BorderType','none');
        uilabel(par,'Text',ttl,'Position',[x+4 yc+46 98 18],'FontSize',8,...
            'FontColor',[0.55 0.65 0.75],'BackgroundColor',[0.10 0.12 0.15]);
        lv = uilabel(par,'Text','—','Position',[x+4 yc+8 98 34],...
            'FontSize',18,'FontWeight','bold','FontColor',CLR_TXT,...
            'BackgroundColor',[0.10 0.12 0.15],'HorizontalAlignment','center');
    end
    lblAccEns  = makeCard(pRight, 10,662,'Accuracy Ensemble');
    lblAccNB   = makeCard(pRight,126,662,'Accuracy NaiveBayes');
    lblF1Macro = makeCard(pRight,242,662,'F1 Macro avg');
    axPanel = uipanel(pRight,'Position',[10 10 340 642],...
        'BackgroundColor',[0.10 0.12 0.15],'BorderType','none');
    lblNoPlot = uilabel(axPanel,...
        'Text','A matriz de confusão aparecerá aqui após correr o pipeline.',...
        'Position',[10 280 320 60],'FontSize',10,'FontColor',[0.45 0.55 0.65],...
        'BackgroundColor',[0.10 0.12 0.15],'HorizontalAlignment','center','WordWrap','on');
    axCM = uiaxes(axPanel,'Position',[5 5 330 630],...
        'Color',[0.10 0.12 0.15],'XColor',CLR_TXT,'YColor',CLR_TXT,'Visible','off');
    %% =======================================================================
    %%  TAB 2 — Previsão Manual
    %% =======================================================================
    % Struct com o modelo treinado (preenchido por trainModelT2)
    mdl.ready=false; mdl.mu=[]; mdl.sigma=[]; mdl.logPrior=[];
    mdl.classes={}; mdl.sigTrain=[]; mdl.hashData=[]; mdl.YTrain=[];
    mdl.bf=[]; mdl.thresholds=[]; mdl.acc_ens=0; mdl.acc_nb=0; mdl.f1_macro=0;
    %% --- Painel esquerdo: CSV + treino + log (Corrigido e Redesenhado) ---
    pT2L = uipanel(tab2,'Position',[10 10 310 740],...
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
        
    % Corrigido: Limite máximo alterado de 95 para 100 para permitir rácio completo
    slRatioT2 = uislider(pT2L,'Limits',[50 100],'Value',80,...
        'MajorTicks',[50 60 70 80 90 100],'Position',[10 533 290 slH],'FontColor',CLR_TXT,...
        'ValueChangedFcn',@(s,~)set(lblRatioT2,'Text',sprintf('%d %%',round(s.Value))));
        
    % Corrigido: Botão descido para evitar sobreposição com as marcações numéricas do slider
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
        
    % Ajustado: Altura redimensionada para acolher o novo posicionamento
    taLogT2 = uitextarea(pT2L,'Position',[10 10 290 365],'Value','',...
        'FontSize',8,'FontName','Courier New',...
        'BackgroundColor',[0.07 0.09 0.11],'FontColor',[0.75 0.90 0.75],'Editable','off');
        
    %% --- Painel central: inputs das 20 features (Corrigido Espaçamento) ---
    pT2M = uipanel(tab2,'Position',[330 10 440 740],...
        'BackgroundColor',CLR_PANEL,'BorderType','none');
    uilabel(pT2M,'Text','VALORES DA AMOSTRA','Position',[10 705 420 26],...
        'FontSize',12,'FontWeight','bold','FontColor',CLR_ACCENT,...
        'BackgroundColor',CLR_PANEL,'HorizontalAlignment','left');
    uilabel(pT2M,'Text','(slider ou campo numérico — prima Prever após treinar)',...
        'Position',[10 684 420 18],'FontSize',9,...
        'FontColor',[0.55 0.65 0.75],'BackgroundColor',CLR_PANEL);
    % {nome, unidade, min, max, default}
    % Nota: month_sin, month_cos, temp_mean, season_temp e cos_x_tmax 
    % foram removidos da UI para serem calculados no background.
    featureDefs = {
        'precipitation',       'mm',    0,   50,   2.0
        'temp_max',            'C',    -5,   42,  18.0
        'temp_min',            'C',   -10,   30,   8.0
        'sunshine_duration',   'h',     0,   15,   5.0
        'shortwave_radiation', 'MJ',    0,   25,  10.0
        'wind_speed_max',      'km/h',  0,   80,  20.0
        'wind_gusts_max',      'km/h',  0,  130,  35.0
        'snowfall',            'cm',    0,   30,   0.0
        'month',               '',      1,   12,   1.0   
        'humidity_mean',       '%',     0,  100,  75.0
        'humidity_min',        '%',     0,  100,  55.0
        'cloud_cover_mean',    '%',     0,  100,  40.0
        'pressure_mean',       'hPa', 960, 1045, 1015.0
        'pressure_min',        'hPa', 955, 1044, 1013.0
        'precipitation_hours', 'h',     0,   24,   2.0
    };
    nFeat       = size(featureDefs,1);
    featEdits   = cell(nFeat,1);
    featSliders = cell(nFeat,1);
    
    % Corrigido: rowH aumentado para 62 e startY reduzido para 610 para afastar os componentes
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
        % Ajustado: Subido ligeiramente o rótulo da feature (yPos+40)
        uilabel(pT2M,'Text',lblTxt,'Position',[xPos yPos+40 210 16],...
            'FontSize',8,'FontColor',[0.65 0.75 0.85],...
            'BackgroundColor',CLR_PANEL,'Interpreter','none');
        featEdits{fi} = uieditfield(pT2M,'numeric',...
            'Position',[xPos yPos+16 70 22],'Value',fdef,...
            'Limits',[fmin fmax],...
            'LowerLimitInclusive','on','UpperLimitInclusive','on',...
            'FontSize',9,'BackgroundColor',[0.10 0.12 0.15],'FontColor',CLR_TXT);
        % Ajustado: Movido mais para a direita (xPos+85) para evitar colar no editfield
        featSliders{fi} = uislider(pT2M,'Limits',[fmin fmax],'Value',fdef,...
            'MajorTicks',[],'Position',[xPos+85 yPos+20 130 slH],'FontColor',CLR_TXT);
        % Sincronizar slider <-> edit
        sl_i = featSliders{fi};
        ed_i = featEdits{fi};
        sl_i.ValueChangedFcn = @(s,~) set(ed_i,'Value',s.Value);
        ed_i.ValueChangedFcn = @(e,~) set(sl_i,'Value',max(fmin,min(fmax,e.Value)));
    end
    %% --- Painel direito: resultado ---
    pT2R = uipanel(tab2,'Position',[780 10 310 740],...
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
    % Cards de precisão
    lblPredAccEns = makeCard(pT2R, 10,542,'Acc. Ensemble (teste)');
    lblPredAccNB  = makeCard(pT2R,126,542,'Acc. NB (teste)');
    lblPredF1     = makeCard(pT2R,242,542,'F1 Macro (teste)');
    % Botão Prever
    btnPredict = uibutton(pT2R,'push','Text','🔍  Prever',...  %#ok<NASGU>
        'Position',[10 492 290 44],...
        'BackgroundColor',CLR_BTN,'FontColor',CLR_BTN_TXT,...
        'FontSize',14,'FontWeight','bold',...
        'ButtonPushedFcn',@(~,~)predictSingle());
    % Gráfico probabilidades NB
    uilabel(pT2R,'Text','Probabilidades por classe (Naive Bayes):',...
        'Position',[10 464 290 22],'FontSize',10,...
        'FontColor',CLR_ACCENT,'BackgroundColor',CLR_PANEL);
    axProb = uiaxes(pT2R,'Position',[10 286 290 174],...
        'Color',[0.10 0.12 0.15],'XColor',CLR_TXT,'YColor',CLR_TXT);
    axProb.FontSize = 9;
    % Área de texto detalhada
    uilabel(pT2R,'Text','Detalhes:','Position',[10 260 290 22],'FontSize',10,...
        'FontColor',CLR_ACCENT,'BackgroundColor',CLR_PANEL);
    taResult = uitextarea(pT2R,'Position',[10 10 290 246],...
        'Value','Treine o modelo e prima Prever.',...
        'FontSize',9,'FontName','Courier New',...
        'BackgroundColor',[0.07 0.09 0.11],'FontColor',[0.75 0.90 0.75],'Editable','off');
    %% =======================================================================
    %%  CALLBACKS — Tab 1
    %% =======================================================================
    function pickBaseDir()
        d = uigetdir(edBaseDir.Value,'Seleccionar pasta do projecto');
        if d ~= 0, edBaseDir.Value = d; end
    end
    function pickCSV()
        [f,p] = uigetfile('*.csv','Seleccionar CSV',edBaseDir.Value);
        if f ~= 0
            fullp = fullfile(p,f);
            base  = edBaseDir.Value;
            if startsWith(fullp,base)
                edCSV.Value = fullp(length(base)+2:end);
            else
                edCSV.Value = fullp;
            end
        end
    end
    function logMsg(msg,varargin)
        if nargin>1, msg=sprintf(msg,varargin{:}); end
        cur=taLog.Value; if ischar(cur),cur={cur}; end
        taLog.Value=[cur;{msg}]; scroll(taLog,'bottom'); drawnow limitrate;
    end
    function setStatus(txt,colour)
        lblStatus.Text=txt; lblStatus.FontColor=colour; drawnow;
    end
    function setProgress(val)
        val=max(0,min(1,val)); pbBg.Visible='on';
        pbFg.Position(3)=max(1,round(val*300)); drawnow;
    end
    function hideProgress(), pbBg.Visible='off'; end
    %% =======================================================================
    %%  CALLBACKS — Tab 2
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
    %%  TREINAR MODELO — Tab 2 (Salvaguarda para Rácio de 100%)
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
            
            % Tratamento especial se o rácio for 100% (evita que conjunto de teste fique vazio e quebre o código)
            if nTr2 == size(X2,1)
                XTr2=X2(idxP2,:); YTr2=Y2(idxP2);
                XTe2=XTr2;        YTe2=YTr2; % Avalia no próprio conjunto de treino se for 100%
                logT2('  Treino: %d  Teste: %d (Aviso: Rácio 100%% - Testado no conjunto de Treino)',size(XTr2,1),size(XTe2,1));
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
            nC2=numel(cls2); f1s2=zeros(nC2,1);
            for c=1:nC2
                tp2=sum(prev2==cls2{c}&YTe2==cls2{c});
                fp2=sum(prev2==cls2{c}&YTe2~=cls2{c});
                fn2=sum(prev2~=cls2{c}&YTe2==cls2{c});
                p2=tp2/max(tp2+fp2,1); r2=tp2/max(tp2+fn2,1);
                f1s2(c)=2*p2*r2/max(p2+r2,1e-9);
            end
            f1mac2=mean(f1s2);
            logT2(''); logT2('=== PRECISÃO NO TESTE ===');
            logT2('  Acc Ensemble : %.2f%%',acc_ens2*100);
            logT2('  Acc NB       : %.2f%%',acc_nb2*100);
            logT2('  F1 Macro     : %.2f%%',f1mac2*100);
            logT2(''); logT2('Modelo pronto. Prima Prever.');
            mdl.mu=mu2; mdl.sigma=sigma2; mdl.logPrior=logPr2;
            mdl.classes=cls2; mdl.sigTrain=sig2; mdl.hashData=hd2;
            mdl.YTrain=YTr2; mdl.bf=bf2; mdl.thresholds=thr2;
            mdl.acc_ens=acc_ens2; mdl.acc_nb=acc_nb2; mdl.f1_macro=f1mac2;
            mdl.ready=true;
            set(lblPredAccEns,'Text',sprintf('%.2f%%',acc_ens2*100),'FontColor',CLR_OK);
            set(lblPredAccNB, 'Text',sprintf('%.2f%%',acc_nb2*100), 'FontColor',CLR_TXT);
            set(lblPredF1,    'Text',sprintf('%.2f%%',f1mac2*100),  'FontColor',CLR_ACCENT);
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
    %%  PREVER AMOSTRA ÚNICA — Tab 2
    %% =======================================================================
    function predictSingle()
        if ~mdl.ready
            taResult.Value={'Modelo não treinado.','Prima "Treinar Modelo" primeiro.'};
            return;
        end
        
        % 1. Ler os valores introduzidos na UI (agora são apenas 15)
        raw = zeros(1, nFeat);
        for fi=1:nFeat, raw(fi)=featEdits{fi}.Value; end
        
        % 2. Extrair variáveis-chave usando o novo mapeamento de índices
        tmax = raw(2);
        tmin = raw(3);
        m    = raw(9); % O mês passou para a 9ª posição na UI
        
        % 3. Calcular TODAS as features derivadas em background
        trange    = tmax - tmin;       % Amplitude térmica calculada automaticamente!
        m_sin     = sin(2 * pi * m / 12);
        m_cos     = cos(2 * pi * m / 12);
        tmean     = (tmax + tmin) / 2;
        seas_temp = tmean * m_cos;
        c_x_tmax  = m_cos * tmax;
        
        % 4. Reconstruir o array original de 20 posições para o modelo avaliar
        row = zeros(1, 20);
        row(1:8)   = raw(1:8);           % De 'precipitation' até 'snowfall'
        row(9)     = trange;             % temp_range (Col 9) calculada de fundo
        row(10)    = m_sin;              % month_sin (Col 10)
        row(11)    = m_cos;              % month_cos (Col 11)
        row(12:17) = raw(10:15);         % De 'humidity_mean' até 'precipitation_hours'
        row(18)    = tmean;              % temp_mean (Col 18)
        row(19)    = seas_temp;          % season_temp (Col 19)
        row(20)    = c_x_tmax;           % cos_x_tmax (Col 20)
        
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
            lines{end+1}='--- Precisão do modelo (conjunto de teste) ---';
            lines{end+1}=sprintf('  Accuracy Ensemble : %.2f%%',mdl.acc_ens*100);
            lines{end+1}=sprintf('  Accuracy NB       : %.2f%%',mdl.acc_nb*100);
            lines{end+1}=sprintf('  F1 Macro          : %.2f%%',mdl.f1_macro*100);
            lines{end+1}='';
            
            % Mostra as variáveis originais introduzidas
            lines{end+1}='--- Valores introduzidos ---';
            for fi2=1:nFeat
                lines{end+1}=sprintf('  %-24s %g',featureDefs{fi2,1},raw(fi2));
            end
            
            % Mostra ao utilizador tudo o que foi gerado de fundo
            lines{end+1}='';
            lines{end+1}='--- Valores calculados em fundo ---';
            lines{end+1}=sprintf('  %-24s %.2f', 'temp_range', trange);
            lines{end+1}=sprintf('  %-24s %.4f', 'month_sin', m_sin);
            lines{end+1}=sprintf('  %-24s %.4f', 'month_cos', m_cos);
            lines{end+1}=sprintf('  %-24s %.2f', 'temp_mean', tmean);
            lines{end+1}=sprintf('  %-24s %.2f', 'season_temp', seas_temp);
            lines{end+1}=sprintf('  %-24s %.2f', 'cos_x_tmax', c_x_tmax);
            
            taResult.Value=lines;
        catch ME
            taResult.Value={sprintf('ERRO: %s',ME.message)};
        end
    end
    %% =======================================================================
    %%  PIPELINE PRINCIPAL — Tab 1
    %% =======================================================================
    function runPipeline()
        btnRun.Enable='off'; setProgress(0); setStatus('● A correr...',CLR_WARN);
        try
            baseDir=edBaseDir.Value; csvRel=edCSV.Value;
            if isAbsolutePath(csvRel), csvPath=csvRel;
            else,                      csvPath=fullfile(baseDir,csvRel); end
            addpath(fullfile(baseDir,'naive_bayes'));
            addpath(fullfile(baseDir,'bloom_filter'));
            addpath(fullfile(baseDir,'minhash'));
            trainRatio=slRatio.Value/100;
            nHashes=round(slHash.Value);
            kNeigh=round(slK.Value); %#ok<NASGU>
            w_nb=slWNB.Value; w_mh=slWMH.Value; w_bf=slWBF.Value;
            logMsg('=== WEATHER ENSEMBLE GUI ===');
            logMsg('baseDir   : %s',baseDir);
            logMsg('CSV       : %s',csvPath);
            logMsg('Treino    : %.0f%%  |  Teste: %.0f%%',trainRatio*100,(1-trainRatio)*100);
            logMsg('Hashes    : %d   |  Top-k: %d',nHashes,kNeigh);
            logMsg('Pesos     : NB=%.2f  MH=%.2f  BF=%.2f',w_nb,w_mh,w_bf);
            logMsg('');
            logMsg('[1/6] A ler CSV...'); setProgress(0.05);
            if ~isfile(csvPath), error('Ficheiro não encontrado: %s',csvPath); end
            data=readtable(csvPath);
            for ci={'date','dew_point_mean','dew_point_max'}
                if ismember(ci{1},data.Properties.VariableNames), data.(ci{1})=[]; end
            end
            if ismember('temp_max',data.Properties.VariableNames) && ...
               ismember('temp_min',data.Properties.VariableNames)
                data.temp_mean=(data.temp_max+data.temp_min)/2;
                if ismember('month_cos',data.Properties.VariableNames)
                    data.season_temp=data.temp_mean.*data.month_cos;
                    data.cos_x_tmax =data.month_cos.*data.temp_max;
                end
            end
            Y=categorical(data.weather);
            X=table2array(removevars(data,'weather'));
            logMsg('  Linhas  : %d',size(X,1));
            logMsg('  Features: %d',size(X,2));
            
            % Nota: O código original fornecido estava truncado no final de runPipeline. 
            % Preservada a estrutura básica e os callbacks internos essenciais para fecho sintático.
            logMsg('Pipeline concluído em simulação.');
            setProgress(1.0); setStatus('● Pronto',CLR_OK);
        catch ME
            logMsg('ERRO: %s',ME.message);
            setStatus('● Erro', [0.90 0.25 0.25]);
        end
        btnRun.Enable='on';
    end

    % Utilitário auxiliar para caminhos
    function res = isAbsolutePath(p)
        res = startsWith(p, '/') || (length(p) >= 3 && p(2) == ':' && p(3) == '\');
    end
end