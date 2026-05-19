function obj = drawWasserfall(obj, fft_size, isdB, visualized_ffts_amount, window)
% Этот метод рисует сонограмму "водопад" в реальном времени.

    arguments
        obj
    
        % Фильтр - количество IQ, которое берётся в один заход FFT.
        % Из количества равного fft_size получается спектр из fft_size точек.
        fft_size
        
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

    
    % Берём порционно IQшки и проводим над ними FFT

    % Ждём пока наберётся достаточное количество IQшек
    while numel(obj.iq_collected) < fft_size
        return
    end
    
    % Расфасовываем IQшки и проводим над ними манипуляции
    while numel(obj.iq_collected) >= fft_size
        iq_for_fft = obj.iq_collected(1:fft_size);
        obj.iq_collected(1:fft_size) = [];
        
        % Прогоняем IQ через window
        switch window
            case "hann"
                iq_for_fft = single(hann(fft_size)).*iq_for_fft;
            case "hamming"
                iq_for_fft = single(hamming(fft_size)).*iq_for_fft;
            case "blackman"
                iq_for_fft = single(blackman(fft_size)).*iq_for_fft;
            case "blackman-harris"
                iq_for_fft = single(blackmanharris(fft_size)).*iq_for_fft;
        end

        % Проводим Манипуляции...
        iq_after_fft = fftshift(fft(iq_for_fft));
        iq_power = abs(iq_after_fft).^2;
        
        % Перевод в децибелы
        if isdB
            iq_power = pow2db(iq_power);
        end
        iq_power = single(iq_power);
        
        % Инициализация матрицы спектров, если её раньше не было
        if isempty(obj.wasserfall_data)
            obj.wasserfall_data = zeros(visualized_ffts_amount, fft_size, "single");
        end

        % Засовывание в матрицу спектров посчитанное fft вниз и удаление
        % fft сверху
        obj.wasserfall_data = [obj.wasserfall_data; iq_power'];
        obj.wasserfall_data(1,:) = [];
        
        % Создание графики
        % imagesc создаём только один раз, потом просто обновляем
        if isempty(obj.wasserfall_image) || ~isgraphics(obj.wasserfall_image)
            obj.wasserfall_figure = figure("Name","Водопад");
            obj.wasserfall_axes = axes(obj.wasserfall_figure);
            obj.wasserfall_image = imagesc(obj.wasserfall_axes, obj.wasserfall_data);
        else
            set(obj.wasserfall_image, "CData", obj.wasserfall_data);
            drawnow limitrate;
        end

    end

end