classdef RealtimeWasserfall < handle
    % Класс для отрисовки сонограммы в реальном времени
    % Для работы ему нужны файлы из GNU Radio

    properties
        iq_dir      % Папка с IQ-файлами
    end

    methods
        % Конструктор
        function obj = RealtimeWasserfall(iq_dir_)
            arguments
                iq_dir_ = "../iq-files";
            end
            
            obj.iq_dir = iq_dir_;
        end

    end

end