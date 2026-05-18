classdef RealtimeWasserfall < handle
    % Класс для отрисовки сонограммы в реальном времени
    % Для работы ему нужны файлы из GNU Radio

    properties

        iq_dir              % Папка с IQ-файлами

        metadata_path       % Путь к jsonl-metadata
        metadata_fid        % FID jsonl-metadata

    end




    
    methods

        % Конструктор
        function obj = RealtimeWasserfall(iq_dir_)
            arguments
                iq_dir_ = "../iq-files";    % Папка с IQ-файлами
            end
            
            % Получаем нужные директории
            obj.iq_dir = iq_dir_;
            obj.metadata_path = obj.iq_dir + "/metadata.jsonl";


            % Открываем файл metadata
            obj.waitForFile(obj.metadata_path, 30);     % Ожидание файла metadata (т.е. запуска GNU Radio)
            obj.metadata_fid = fopen(obj.metadata_path, "r");   % Открытие файла metadata
            if obj.metadata_fid == -1
                error("RealtimeWasserfall:MetadataOpenFailed", "Файл metadata.jsonl не открылся!");
            end

        end

        obj = purge(obj);
        json_line = readMetadata(obj);

    end





    methods(Access=private, Static)

        function waitForFile(file_path, timeout)
            % Функция ожидания появления файла
            t_start = tic;
            while ~isfile(file_path)
                if toc(t_start) > timeout
                    error("RealtimeWasserfall:FileWaitTimeout", "Превышено время ожидания файла" + file_path);
                end
                pause(0.5);
            end
        end

    end




end