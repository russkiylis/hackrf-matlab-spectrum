classdef RealtimeFileDataSource < FileDataSource
    % Источник информации из файлов (в реальном времени)

    properties
        delete_files_flag   % Флаг удаления прочитанных файлов
    end

    methods
        function obj = RealtimeFileDataSource(folder_path, delete_files_flag)
            % Конструктор
            waitForFile(fullfile(folder_path, "metadata.jsonl"), 30);
            obj@FileDataSource(folder_path);
            obj.delete_files_flag = delete_files_flag;
        end

        function delete(obj)
            % Что происходит при удалении объекта класса
            delete@FileDataSource(obj);
            if obj.delete_files_flag && isfile(obj.metadata_path)
                delete(obj.metadata_path);  % Удаляем файл jsonl
            end
        end

        function [iq_complex, metadata] = nextData(obj)
            % Взаимодействие FileIQSource с внешним миром ограничивается
            % только выдачей новой информации
            metadata = obj.readMetadata();
            iq_complex = obj.readIQ(metadata);

            % Удаляем файлы, если есть соответствующий флажок.
            % Файл, который в данный момент пишется, не затронется, так как
            % он имеет пометку .tmp
            if obj.delete_files_flag
                delete(fullfile(obj.folder_path, "*.cf32"));
            end
        end
    end

    methods(Access=private)
        function metadata = readMetadata(obj)
            % Приватный метод чтения файла с метаданными

            % Читаем файл metadata
            fseek(obj.metadata_fid, 0, "eof");          % Начинаем читать файл с конца
            json_line = -1;
            while json_line == -1
                cr_pos = ftell(obj.metadata_fid);           % Запоминаем позицию каретки
                json_line = fgets(obj.metadata_fid);        % Пытаемся читать строчку
                if json_line == -1
                    fseek(obj.metadata_fid, cr_pos, "bof"); % Если строка не готова, возвращаемся взад
                else
                    if ~endsWith(json_line, newline)
                        fseek(obj.metadata_fid, cr_pos, "bof"); % Если строка не готова, возвращаемся взад
                        json_line = -1;
                    end
                end
                pause(0.001);
            end
        
            % Тут у нас есть строчка из metadata.jsonl. Декодируем её.
            metadata = jsondecode(json_line);
        end
    end
end