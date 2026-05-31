classdef (Abstract) FileDataSource < handle
    % Источник информации из файлов (сохранённых)

    properties
        folder_path     % Путь к папке с информацией
        metadata_path   % Путь к файлу с метаданными

        metadata_fid    % file id метаданных
    end

    methods
        function obj = FileDataSource(folder_path)
            % Конструктор
            obj.folder_path = folder_path;
            obj.metadata_path = fullfile(obj.folder_path, "metadata.jsonl");

            % Открываем файл metadata
            obj.metadata_fid = fopen(obj.metadata_path, "r");   % Открытие файла metadata
            if obj.metadata_fid == -1
                error("FileDataSource:MetadataOpenFailed", "Файл metadata.jsonl не открылся!");
            end
        end

        function delete(obj)
            % Что происходит при удалении объекта класса
            if obj.metadata_fid ~= -1
                fclose(obj.metadata_fid);   % Закрываем файл jsonl
                obj.metadata_fid = -1;
            end
        end
    end

    methods(Abstract)
        % Заставляем всех наследников отдавать информацию. В каждом
        % наследнике обязан быть метод nextData, выдающий IQ и метаданные
        [iq_complex, metadata] = nextData(obj);
    end

    methods(Access=protected)

        function iq_complex = readIQ(obj, metadata)
            % Защищённый метод чтения IQ-файлов (с последующим удалением или
            % без него)
            file_path = fullfile(obj.folder_path, metadata.file);  % Путь до файла
        
            % Небольшой блок с проверками. Сначала проверка на наличие файла
            if isfile(file_path)
                % Проверка на соответствие размеров. одна IQ занимает 8 байт
                if dir(file_path).bytes ~= 8 * metadata.samples_count
                    error("FileDataSource:IncorrectIQSize", "IQ-файл " + file_path + " имеет некорректный размер!")
                end
            else
                error("FileDataSource:IQFileNotFound", "IQ-файл " + file_path + " не найден!");
            end
            
            
            % Далее идёт непосредственно чтение файла
            % rb - открытие бинарника
            % ieee-le - открытие в little-endian формате (младший байт сначала)
            fid = fopen(file_path, "rb", "ieee-le");
        
            if fid == -1
                error("FileDataSource:IQOpenFailed", "Ошибка открытия IQ-файла " + file_path);
            end
            
            % Читаем "сырые" нерасфасованные числа из файла.
            % Поскольку в одном iq 2 числа (re im), то читаем мы в 2 раза больше
            % чисел, чем iqшек в файле.
            % single - это float32.
            raw_iq = fread(fid, 2*metadata.samples_count, "single=>single");
            if numel(raw_iq) ~= 2*metadata.samples_count
                error("FileDataSource:IQReadFailed", "Ошибка чтения IQ-файла " + file_path);
            end
            raw_i = raw_iq(1:2:numel(raw_iq));
            raw_q = raw_iq(2:2:numel(raw_iq));
            iq_complex = complex(raw_i, raw_q);
            
            % Закрываем файл, если он ещё не закрыт
            if fid ~= -1
                fclose(fid);
            end
        end
    end
end