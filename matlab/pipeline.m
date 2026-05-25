% Основная входная точка в программу
% Рекомендую запускать сначала её, а затем GNU-Radio
% Так файлы не будут создаваться в холостую

% Программа будет ждать открытия GNU-Radio 30 секунд, а затем закроется

wasserfall = RealtimeWasserfall();

while true
    
    % Для начала прочитаем метаданные
    line = wasserfall.readMetadata();
    disp(line);
    
    % Затем прочитаем и откроем соответствующий IQ-файл
    wasserfall.readIQ();
    
    % Далее выводим сонограмму
    wasserfall.drawWasserfall(131072, 1024, true, 1024, "blackman-harris");

end