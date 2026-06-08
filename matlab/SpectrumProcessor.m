classdef SpectrumProcessor
    % Блок обработки IQ. Тут вектор IQ-компонентов разбивается по кусочкам
    % размером fft_size, а затем над ними проводится FFT.

    properties
        fft_size    % Количество точек под FFT
        db_flag     % Проводить ли преобразование в децибелы

        % Структура окна. Отвечает за то, что мы делаем с IQшками,
        % попавшими не в центр окна fft_size, а на край.
        % FFT думает, что сигнал повторяется. Поэтому, если ничего не
        % занижать IQшки по краям, то может возникнуть сильный скачок, а
        % сильный скачок - это широкая полоса, мешающая нормальному
        % отображению. Всякие hann, hamming, blackman, blackman-harris
        % уменьшают амплитуду боковых IQшек, но из-за этого занижения мы
        % фактически обрабатываем меньший во времени сигнал, оттого
        % лепестки спектра могут расширяться.
        window
    end

    methods
        function obj = SpectrumProcessor(fft_size, db_flag, window)
            % Конструктор
            obj.fft_size = fft_size;
            obj.db_flag = db_flag;
            switch window
                case "rectangular"
                    obj.window = single(ones(fft_size,1));
                case "hann"
                    obj.window = single(hann(fft_size));
                case "hamming"
                    obj.window = single(hamming(fft_size));
                case "blackman"
                    obj.window = single(blackman(fft_size));
                case "blackman-harris"
                    obj.window = single(blackmanharris(fft_size));
                otherwise
                    error("SpectrumProcessor:UnknownWindowType", "Неизвестный тип окна!");
            end
        end

        function output = process(obj, iq_complex, metadata)
            % Основной метод вывода. Возвращает обработанные IQшки в виде
            % матрицы FFT
            
            % Проверка на кратность поданного вектора размеру fft. Если не
            % кратно, пока что просто дополняем нулями, в дальнейшем будет
            % отдельный блок
            remainder = mod(numel(iq_complex), obj.fft_size);
            padding_count = 0;
            if remainder ~= 0
                padding_count = obj.fft_size - remainder;   % Сколько нулей пришлось вставить
                iq_complex = [iq_complex; zeros(padding_count, 1, "like", iq_complex)];
            end
            
            ffts_in_chunk = numel(iq_complex) / obj.fft_size;   % Сколько fft мы сделаем с одного кусочка IQ

            % Расфасовываем IQшки по столбцам: один столбец - один FFT-кадр
            iq_frames = reshape(iq_complex, obj.fft_size, ffts_in_chunk);
            iq_frames = obj.window .* iq_frames;                % Прогоняем IQшки через окно

            % Проводим Манипуляции...
            iq_after_fft = fftshift(fft(iq_frames, [], 1), 1);
            iq_power = abs(iq_after_fft).^2;

            % На выходе одна строка - один FFT-кадр
            fft_output = single(iq_power.');

            % Перевод в децибелы
            if obj.db_flag
                fft_output = pow2db(fft_output);
            end

            output = struct('fft_output', fft_output, 'metadata', metadata, 'db_flag', obj.db_flag, 'padding_count', padding_count);
        end
    end
end
