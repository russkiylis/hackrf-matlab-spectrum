classdef RealtimeWasserfall < handle
    % Класс для отрисовки сонограммы в реальном времени
    % Для работы ему нужны файлы из GNU Radio

    properties

        iq_dir              % Папка с IQ-файлами

        metadata_path       % Путь к jsonl-metadata
        metadata_fid = -1   % FID jsonl-metadata
        
        metadata            % Структура с метаданными
        
        iq_collected        % Прочитанные комплексные значения
        wasserfall_data     % Матрица спектра для водопада
        wasserfall_row      % Текущая строчка wasserfall_data, куда записываются свежие IQ
        
        % Для отображения
        wasserfall_figure
        wasserfall_axes
        wasserfall_image
        structured_data
        fft_size_divider    % То, во сколько раз отображаемое значение fft size меньше реального

        % Окно FFT
        fft_window

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
        
        % Деструктор
        function delete(obj)
            if obj.metadata_fid ~= -1
                fclose(obj.metadata_fid);   % Закрываем файл jsonl
                obj.metadata_fid = -1;
                delete(obj.metadata_path);
            end
        end

        obj = purge(obj);
        json_line = readMetadata(obj);
        [raw_i, raw_q] = readIQ(obj, delete_files_bool);
        obj = drawWasserfall(obj, fft_size, isdB, visualized_ffts_amount, window)

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