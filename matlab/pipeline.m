% Основная входная точка в программу
% Рекомендую запускать сначала её, а затем GNU-Radio
% Так файлы не будут создаваться в холостую

% Программа будет ждать открытия GNU-Radio 30 секунд, а затем закроется

% КРАТКИЙ ГАЙД ПО СОСТАВЛЕНИЮ cfg
%
% cfg - структура с настройками программы. Сейчас конфигуратор использует
% секцию cfg.data_source, в которой задаётся источник данных.
%
% Доступные типы источников:
%
% 1. Файлы, поступающие в реальном времени:
%    cfg = struct( ...
%        'data_source', struct( ...
%            'type', "file_realtime", ...
%            'folder_path', "../iq-files", ...
%            'delete_files_flag', false ...
%        ) ...
%    );
%
%    Поля:
%    - type              - тип источника: "file_realtime";
%    - folder_path       - папка с metadata.jsonl и IQ-файлами;
%    - delete_files_flag - удалять ли IQ-файлы после чтения.
%
% 2. Ранее сохранённые файлы:
%    cfg = struct( ...
%        'data_source', struct( ...
%            'type', "file_recorded", ...
%            'folder_path', "../iq-files" ...
%        ) ...
%    );
%
%    Обязательные поля:
%    - type        - тип источника: "file_recorded";
%    - folder_path - папка с metadata.jsonl и IQ-файлами.

% Сначала создадим конфиг
% cfg = struct( ...
%     'data_source', struct('type', "file_realtime", 'folder_path', "../iq-files", 'delete_files_flag', false) ...
% );
cfg = struct( ...
    'data_source', struct('type', "file_recorded", 'folder_path', "../iq-files"), ...
    'spectrum_processor', struct('fft_size', 16384, 'db_flag', true, 'window', "blackman-harris"), ...
    'draw_output', struct('type', "waterfall", 'visualized_fft_size', 1024, 'visualized_fft_amount', 10000, 'zero_level', -5, 'min', -10, 'max', 30, 'downsampling_method', "max") ...
    );

% Затем создадим объект конфигуратора
configurator = Configurator(cfg);

% Создадим нужные нам объекты классов с помощью конфигуратора
data_source = configurator.getDataSource();
spectrum_processor = configurator.getSpectrumProcessor();
draw_output = configurator.getDrawOutput();

% Выводить ли что-либо в консоль или нет
logging = true;

while true
    % Запросим у источника новые данные
    [iq_complex, metadata] = data_source.nextData();

    % СОСТАВ metadata
    %
    % metadata - структура, описывающая один IQ-чанк. Она создаётся
    % GNU Radio и читается из соответствующей строки metadata.jsonl.
    %
    % Поля структуры:
    % - chunk_id        - порядковый номер чанка;
    % - file            - имя IQ-файла, например "chunk_000000000001.cf32";
    % - format          - формат IQ-файла: "cf32_le";
    % - sampling_rate   - частота дискретизации, Гц;
    % - center_freq     - центральная частота приёмника, Гц;
    % - bandwidth       - ширина полосы обзора, Гц;
    % - timestamp_utc   - время создания чанка в UTC в формате ISO 8601;
    % - first_sample_id - номер первого IQ-отсчёта чанка с начала записи;
    % - samples_count   - количество IQ-отсчётов в чанке;
    % - chunk_time      - заданная длительность полного чанка, с;
    % - duration        - фактическая длительность чанка, с.
    
    % Если находим EOF то выходим из программы
    % (Работает для recorded data source)
    if iq_complex == -1
        if logging
            disp("EOF");
        end
        break
    end

    % Прокомментируем полученный кусочек
    if logging
        disp("Кусочек файла - " + metadata.chunk_id + ". Количество IQ - " + metadata.samples_count);
    end

    processed_data = spectrum_processor.process(iq_complex, metadata);
    % disp(processed_data);

    draw_props = draw_output.update(processed_data);
    xlabel(draw_props.axes, "Частота, МГц");
    ylabel(draw_props.axes, "Время, с");
    
end
