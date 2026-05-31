classdef RecordedFileDataSource < FileDataSource
    % Источник информации из файлов (сохранённых)

    methods
        function obj = RecordedFileDataSource(folder_path)
            % Конструктор
            obj@FileDataSource(folder_path);
        end
        
        function [iq_complex, metadata] = nextData(obj)
            % Взаимодействие FileIQSource с внешним миром ограничивается
            % только выдачей новой информации
            [metadata, eof_flag] = obj.readMetadata();
            if eof_flag == true
                iq_complex = -1;    % Если конец файла, то iq_complex будет -1. Это можно обработать.
            else
                iq_complex = obj.readIQ(metadata);
            end
        end

    end

    methods(Access=private)
        function [metadata, eof_flag] = readMetadata(obj)
            % Приватный метод чтения файла с метаданными

            % Читаем файл metadata
            json_line = fgets(obj.metadata_fid);        % Пытаемся читать строчку
            if json_line == -1
                if feof(obj.metadata_fid)
                    eof_flag = true;
                    metadata = [];
                    return
                else
                    error("FileDataSource:MetadataCorrupted", "Файлы повреждены!");
                end
            end
            eof_flag = false;
        
            % Тут у нас есть строчка из metadata.jsonl. Декодируем её.
            metadata = jsondecode(json_line);
        end
    end
end