function json_line = readMetadata(obj)
%READMETADATA Метод чтения jsonl, выдаёт обратно линию jsonl
    
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
    obj.metadata = jsondecode(json_line);

end