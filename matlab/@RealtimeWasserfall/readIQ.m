function [raw_i, raw_q] = readIQ(obj, delete_files_bool)
% Здесь читаются IQ-файлы. Для этого используется получаенные из jsonl
% метаданные

    arguments
        obj
        delete_files_bool = true
    end

    iq_path = fullfile(obj.iq_dir, obj.metadata.file);  % Путь до файла

    % Небольшой блок с проверками. Сначала проверка на наличие файла
    if isfile(iq_path)
        % Проверка на соответствие размеров. одна IQ занимает 8 байт
        if dir(iq_path).bytes ~= 8 * obj.metadata.samples_count
            error("RealtimeWasserfall:IncorrectIQSize", "IQ-файл " + iq_path + " имеет некорректный размер!")
        end
    else
        error("RealtimeWasserfall:IQFileNotFound", "IQ-файл " + iq_path + " не найден!");
    end
    
    
    % Далее идёт непосредственно чтение файла
    % rb - открытие бинарника
    % ieee-le - открытие в little-endian формате (младший байт сначала)
    iq_fid = fopen(iq_path, "rb", "ieee-le");

    if iq_fid == -1
        error("RealtimeWasserfall:IQOpenFailed", "Ошибка открытия IQ-файла " + iq_path);
    end
    
    % Читаем "сырые" нерасфасованные числа из файла.
    % Поскольку в одном iq 2 числа (re im), то читаем мы в 2 раза больше
    % чисел, чем iqшек в файле.
    % single - это float32.
    raw_iq = fread(iq_fid, 2*obj.metadata.samples_count, "single=>single");
    if numel(raw_iq) ~= 2*obj.metadata.samples_count
        error("RealtimeWasserfall:IQReadFailed", "Ошибка чтения IQ-файла " + iq_path);
    end
    raw_i = raw_iq(1:2:numel(raw_iq));
    raw_q = raw_iq(2:2:numel(raw_iq));
    % obj.iq_collected = [obj.iq_collected complex(raw_i, raw_q)];
    obj.iq_collected = complex(raw_i, raw_q);
    
    % Удаляем файл
    if iq_fid ~= -1
        fclose(iq_fid);
    end
    if delete_files_bool
        delete(iq_path);
    end

end