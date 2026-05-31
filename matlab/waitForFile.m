function waitForFile(file_path, timeout)
    % Функция ожидания появления файла
    t_start = tic;
    while ~isfile(file_path)
        if toc(t_start) > timeout
            error("WaitForFile:FileWaitTimeout", "Превышено время ожидания файла" + string(file_path));
        end
        pause(0.5);
    end