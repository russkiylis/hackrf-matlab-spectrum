classdef WaterfallOutput < handle
    % Класс для отображения водопада
    
    properties
        visualized_fft_size     % Размер отображаемого fft (ширина)
        fft_size                % Размер реального fft
        visualized_fft_amount   % Количество отображаемых fft (длина)

        waterfall_data              % Матрица для отображения
        writing_row_index = 1       % Индекс строки, куда писать следующие fft
        fft_size_divider            % Делитель размера fft (пример: 1024/8=128)
        downsampling_method         % Метод выбора точек при уменьшении размера fft
        zero_level                  % Уровень нуля (полезно в случае с дБ)
        minimum
        maximum

        waterfall_figure
        waterfall_axes
        waterfall_image

        freq_axis
        time_axis
        repeats = 0;                % Сколько раз циклическая запись пошла по кругу
    end

    methods
        function obj = WaterfallOutput(visualized_fft_size, visualized_fft_amount, zero_level, min, max, downsampling_method)
            % Конструктор
            obj.visualized_fft_size = visualized_fft_size;
            obj.visualized_fft_amount = visualized_fft_amount;
            obj.zero_level = zero_level;
            obj.downsampling_method = downsampling_method;
            obj.minimum = min;
            obj.maximum = max;

        end

        function output = update(obj, processed_data)
            % Метод для обновления картинки
            
            % При первом вызове update проверяется наличие сгенерированной
            % матрицы waterfall_data
            if isempty(obj.waterfall_data)
                obj.fft_size = numel(processed_data.fft_output(1,:));
                if obj.visualized_fft_size > obj.fft_size
                    error("WaterfallOutput:VisualizationError", "Количество отображаемого fft size больше реального!");
                end

                obj.fft_size_divider = obj.fft_size/obj.visualized_fft_size;
                if mod(obj.fft_size, obj.visualized_fft_size) ~= 0
                    error("WaterfallOutput:VisualizationError", "Количество отображаемого fft size меньше реального не в целое число раз!");
                end

                obj.waterfall_data = single(ones(obj.visualized_fft_amount, obj.visualized_fft_size).*obj.zero_level);
            end

            
            % Создание графики
            % imagesc создаём только один раз, потом просто обновляем
            if isempty(obj.waterfall_image) || ~isgraphics(obj.waterfall_image)
                obj.waterfall_figure = figure("Name","Водопад");
                obj.waterfall_axes = axes(obj.waterfall_figure); %#ok<LAXES>
                obj.waterfall_image = imagesc(obj.waterfall_axes, obj.waterfall_data);

                clim(obj.waterfall_axes, [obj.minimum obj.maximum]);
            end
            
            % Сжатие fft по ширине
            compressed_rows = obj.downsampler(processed_data.fft_output);

            waterfall_data = obj.waterfall_data;
            writing_row_index = obj.writing_row_index;
            repeats = obj.repeats;

            % Далее работаем с каждой строчкой по отдельности
            for i = 1:size(compressed_rows, 1)
                compressed_row = compressed_rows(i,:);
                
                % Засовывание строки в матрицу вывода
                waterfall_data(writing_row_index, :) = compressed_row;
                writing_row_index = mod(writing_row_index+1, obj.visualized_fft_amount+1);
                if writing_row_index == 0
                    writing_row_index = 1;
                    repeats = repeats + 1;
                end
            end

            obj.waterfall_data = waterfall_data;
            obj.writing_row_index = writing_row_index;
            obj.repeats = repeats;
           
            % Оси
            freq_ax = linspace(processed_data.metadata.center_freq - processed_data.metadata.sampling_rate/2, processed_data.metadata.center_freq + processed_data.metadata.sampling_rate/2, obj.visualized_fft_size);
            freq_axis_mhz = freq_ax / 1e6;
            obj.freq_axis = freq_axis_mhz;

            seconds_per_row = obj.fft_size / processed_data.metadata.sampling_rate;
            total_time = obj.visualized_fft_amount * seconds_per_row;



            % Обновление картинки
            set(obj.waterfall_image, "CData", obj.waterfall_data);
            set(obj.waterfall_image, "XData", obj.freq_axis);
            xlim(obj.waterfall_axes, [obj.freq_axis(1), obj.freq_axis(end)]);
            set(obj.waterfall_image, "YData", [obj.repeats*total_time, (obj.repeats+1)*total_time]);
            ylim(obj.waterfall_axes, [obj.repeats*total_time, (obj.repeats+1)*total_time]);
            drawnow limitrate nocallbacks;

            output = struct('figure', obj.waterfall_figure, 'axes', obj.waterfall_axes, 'image', obj.waterfall_image);
        end
    end

    methods (Access=protected)
        function compressed_data = downsampler(obj, fft_output)
            rows_count = size(fft_output, 1);
            grouped_data = reshape(fft_output, rows_count, obj.fft_size_divider, obj.visualized_fft_size);

            switch obj.downsampling_method
                case "max"
                    compressed_data = max(grouped_data, [], 2);
                case "avg"
                    compressed_data = mean(grouped_data, 2);
                otherwise
                    error("WaterfallOutput:UnknownDownsamplingMethod", "Неизвестный метод даунсемплинга!");
            end

            compressed_data = reshape(compressed_data, rows_count, obj.visualized_fft_size);
        end
    end
end
