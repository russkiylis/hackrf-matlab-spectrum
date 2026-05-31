classdef Configurator
    % Конфигуратор выдаёт объекты классов в соответствии с конфигом

    properties
        data_source_config
    end

    methods
        function obj = Configurator(config)
            % Конструктор
            
            arguments
                % Конфиг в виде структуры
                config = struct( ...
                    'data_source', struct('type', "file_realtime", 'folder_path', "../iq-files", 'delete_files_flag', true) ...
                    );
            end
            
            obj.data_source_config = config.data_source;

        end

        function data_source = getDataSource(obj)
            % Выдача объекта класса источника IQ-компонентов
            switch obj.data_source_config.type
                case "file_realtime"
                    data_source = RealtimeFileDataSource(obj.data_source_config.folder_path, obj.data_source_config.delete_files_flag);
                case "file_recorded"
                    data_source = RecordedFileDataSource(obj.data_source_config.folder_path);
                otherwise
                    error("Configurator:InvalidDataSourceType", "Сомнительный тип источника IQ-компонентов!");
            end
        end
    end
end