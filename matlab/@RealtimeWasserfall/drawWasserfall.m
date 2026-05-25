function obj = drawWasserfall(obj, fft_size, visualized_fft_size, isdB, visualized_ffts_amount, window)
% Этот метод рисует сонограмму "водопад" в реальном времени.

    arguments
        obj
    
        % Фильтр - количество IQ, которое берётся в один заход FFT.
        % Из количества равного fft_size получается спектр из fft_size точек.
        fft_size

        visualized_fft_size     % Сколько точек fft визуализируем

        isdB    % Переводим ли в децибелы

        % Количество отображаемых заходов FFT. После достижения этого
        % количества старые IQ удаляются из памяти.
        % Итого в памяти будет visualized_ffts_amount*fft_size IQшек
        visualized_ffts_amount = 10000
    
        % Структура окна. Отвечает за то, что мы делаем с IQшками,
        % попавшими не в центр окна fft_size, а на край.
        % FFT думает, что сигнал повторяется. Поэтому, если ничего не
        % занижать IQшки по краям, то может возникнуть сильный скачок, а
        % сильный скачок - это широкая полоса, мешающая нормальному
        % отображению. Всякие hann, hamming, blackman, blackman-harris
        % уменьшают амплитуду боковых IQшек, но из-за этого занижения мы
        % фактически обрабатываем меньший во времени сигнал, оттого
        % лепестки спектра могут расширяться.
        window = "blackman-harris"
    end
    
    if visualized_fft_size > fft_size
        error("RealtimeWasserfall:VisualizationError", "Количество отображаемого fft size больше реального!");
    end
    if isempty(obj.fft_size_divider)
        obj.fft_size_divider = fft_size/visualized_fft_size;
    end
    if mod(fft_size, visualized_fft_size) ~= 0
        error("RealtimeWasserfall:VisualizationError", "Количество отображаемого fft size меньше реального не в целое число раз!");
    end
    
    % Берём порционно IQшки и проводим над ними FFT

    % Ждём пока наберётся достаточное количество IQшек
    while numel(obj.iq_collected) < fft_size
        return
    end
    
    iq_left = numel(obj.iq_collected);      % Сколько IQшек осталось расфасовать
    index = 1;                              % Индекс для расфасовывания IQ-шек
    ffts_in_chunk = ceil(iq_left/fft_size); % Сколько fft мы сделаем с одного кусочка IQ

    % Расфасовываем IQшки и проводим над ними манипуляции
    while iq_left >= fft_size
        iq_for_fft = obj.iq_collected(index:index+fft_size-1);
        % obj.iq_collected(1:fft_size) = [];
        index = index + fft_size;
        iq_left = iq_left - fft_size;
        
        % Прогоняем IQ через window
        % Для начала создадим в атрибуте fft_size окно. Не будем
        % генерировать его несколько раз
        if isempty(obj.fft_window)
            switch window
                case "hann"
                    obj.fft_window = single(hann(fft_size));
                case "hamming"
                    obj.fft_window = single(hamming(fft_size));
                case "blackman"
                    obj.fft_window = single(blackman(fft_size));
                case "blackman-harris"
                    obj.fft_window = single(blackmanharris(fft_size));
                case "rectangular"
                    obj.fft_window = single(ones(fft_size));
            end
        end
        iq_for_fft = obj.fft_window .* iq_for_fft;      % Прогоняем IQшки через окно

        % Проводим Манипуляции...
        iq_after_fft = fftshift(fft(iq_for_fft));
        iq_power = abs(iq_after_fft).^2;
        
        % Перевод в децибелы
        if isdB
            iq_power = pow2db(iq_power);
        end
        iq_power = single(iq_power)';
        
        % Инициализация массива структурированных fftшек, который мы будем
        % засовывать непосредственно в imagesc. Размер массива фиксирован -
        % visualized_ffts_amount x fft_size. В него мы будем циклически
        % перезаписывать посчитанные fftшки.
        if isempty(obj.structured_data)
            obj.structured_data = zeros(visualized_ffts_amount, visualized_fft_size, "single");
            obj.wasserfall_row = 1;
        end

        % Создание графики
        % imagesc создаём только один раз, потом просто обновляем
        if isempty(obj.wasserfall_image) || ~isgraphics(obj.wasserfall_image)
            obj.wasserfall_figure = figure("Name","Водопад");
            obj.wasserfall_axes = axes(obj.wasserfall_figure); %#ok<LAXES>
            obj.wasserfall_image = imagesc(obj.wasserfall_axes, obj.structured_data);
        end
        
        % Сжатие по частотной оси
        compressed_data = zeros(1,numel(iq_power)/obj.fft_size_divider, "single");
        k = 1;
        for i = 1:obj.fft_size_divider:numel(iq_power)
            compressed_data(k) = max(iq_power(i:i+obj.fft_size_divider-1));
            k = k + 1;
        end

        % Циклическая запись в obj.structured_data посчитанных fftшек
        obj.structured_data(obj.wasserfall_row,:) = compressed_data;
        obj.wasserfall_row = mod(obj.wasserfall_row+1, visualized_ffts_amount+1);
        if obj.wasserfall_row == 0; obj.wasserfall_row = 1; end


    end
    
    % Обновление картинки
    set(obj.wasserfall_image, "CData", obj.structured_data);
    drawnow limitrate nocallbacks;

    % Очистка
    if numel(obj.iq_collected) > 20000000
        obj.iq_collected = [];
    end

end