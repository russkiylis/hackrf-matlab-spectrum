classdef Configurator
    % Конфигуратор выдаёт объекты классов в соответствии с конфигом

    properties
        data_source_config
        spectrum_processor_config
        draw_output_config
    end

    methods
        function obj = Configurator(config)
            % Конструктор
            
            arguments
                % Конфиг в виде структуры
                config = struct( ...
                    'data_source', struct('type', "file_realtime", 'folder_path', "../iq-files", 'delete_files_flag', true), ...
                    'spectrum_processor', struct('fft_size', 4096, 'db_flag', true, 'window', "blackman-harris"), ...
                    'draw_output', struct('type', "waterfall", 'visualized_fft_size', 128, 'visualized_fft_amount', 4096, 'zero_level', -30, 'min', -10, 'max', 30, 'downsampling_method', "max") ...
                    );
            end
            
            obj.data_source_config = config.data_source;
            obj.spectrum_processor_config = config.spectrum_processor;
            obj.draw_output_config = config.draw_output;

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

        function spectrum_processor = getSpectrumProcessor(obj)
            % Выдача объекта класса математического процессора
            spectrum_processor = SpectrumProcessor(obj.spectrum_processor_config.fft_size, obj.spectrum_processor_config.db_flag, obj.spectrum_processor_config.window);
        end

        function draw_output = getDrawOutput(obj)
            % Выдача объекта класса рисовалки
            draw_output = WaterfallOutput(obj.draw_output_config.visualized_fft_size, obj.draw_output_config.visualized_fft_amount, obj.draw_output_config.zero_level, obj.draw_output_config.min, obj.draw_output_config.max, obj.draw_output_config.downsampling_method);
        end
    end
end