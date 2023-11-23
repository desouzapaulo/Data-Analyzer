classdef LocationClass < handle
    properties
        data AnalyzeClass = AnalyzeClass.empty
    end
    methods
        function obj = LocationClass(folder, sensor, fs)
            obj.data = AnalyzeClass(folder, sensor, fs);
        end
        function speed(obj, n)
            figure(n)
            plot(obj.data.data(:, 2), obj.data.data(:, 7).*3.6)
            xlabel('time [s]')
            ylabel('Speed [km/h]')
            grid on
        end
    end
end