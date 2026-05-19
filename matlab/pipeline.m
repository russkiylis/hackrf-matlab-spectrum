% Основная входная точка в программу
% Рекомендую запускать сначала её, а затем GNU-Radio
% Так файлы не будут создаваться в холостую

% Программа будет ждать открытия GNU-Radio 30 секунд, а затем закроется

clear; clc;

wasserfall = RealtimeWasserfall();

while true
    
    % Для начала прочитаем метаданные
    line = wasserfall.readMetadata();
    disp(line);
    
    % Затем прочитаем и откроем соответствующий IQ-файл
    wasserfall.readIQ();
    
    % Далее выводим сонограмму
    wasserfall.drawWasserfall(1024, false, 100, "blackman-harris");

end