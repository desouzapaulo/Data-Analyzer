classdef BrakeClass < handle
    properties
    % Data type and folder
    folder = '';
    logger = '';
    Acc AccClass = AccClass.empty
    % Geometric parameters
    W double = double.empty;
    psi double = double.empty;
    chi double = double.empty;
    Fz double = double.empty;
    mu = [0.8 0.8];
    a_fr double = double.empty;
    % Braking system parameters
    Amc double = double.empty;
    Awc double = double.empty;
    Rext double = double.empty;
    Hp double = double.empty;
    l_p double = double.empty;
    Pl double = double.empty;
    r double = double.empty;
    R double = double.empty;
    Po = 7; % [N/cm²]
    Fpedal = 400:10:800; % Pedal Force [N]
    BF = 0.8;
    nu_p = 0.8; 
    nu_c = 0.98; % wheel cylinder efficiency
    % Braking Analysis
    Fx_optm double = double.empty;
    Fx_real double = double.empty;
    phi double = double.empty; % Real braking poportion (with the sistem dimentions)
    % Braking adjustment
    BBB double = double.empty;
    g = 9.81;
    end
    %% constructor
    methods
        function obj = BrakeClass(folder, logger, psi, chi, BBB, parameters)
            obj.folder = folder;
            obj.logger = logger;
            obj.Acc = AccClass(obj.folder, obj.logger);

            obj.psi = psi;
            obj.chi = chi;

            obj.W = parameters(1, 2)*obj.g;            
            obj.l_p = parameters(2, 2);
            obj.Amc = parameters(3, 2:3);
            obj.Awc = parameters(4, 2:3);
            obj.Rext = parameters(5, 2:3);
            obj.Hp = parameters(6, 2:3);            
            obj.R = parameters(7, 2:3);

            obj.r = obj.Rext - (obj.Hp./2);
            Bdif = abs(0.5-BBB);
            
            if BBB > 0.5 
                obj.BBB = [(1-Bdif) (1+Bdif)];
            end
            if BBB < 0.5 
                obj.BBB = [(1+Bdif) (1-Bdif)];
            end
            if BBB == 0.5 
                obj.BBB = [1 1];
            end

        end
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%OPTIMUM BRAKE LINE%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function calcOptBrake(obj)
        %% dynamic reaction on Wheels        
            Fzf = (1 - obj.psi + obj.chi.*(obj.Acc.Read.data(:, 2))).*obj.W;
            Fzr = (obj.psi - obj.chi.*(obj.Acc.Read.data(:, 2))).*obj.W;
            obj.Fz = [Fzf Fzr];
       
        %% Braking forces
            Fxf = (1 - obj.psi + obj.chi.*(obj.Acc.Read.data(:, 2))).*((obj.Acc.Read.data(:, 2)).*obj.W);
            Fxr = (obj.psi - obj.chi.*(obj.Acc.Read.data(:, 2))).*((obj.Acc.Read.data(:, 2)).*obj.W);
            obj.Fx_optm = [Fxf Fxr];

        end
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%REAL BRAKING LINE%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function calcRealBrake(obj)

            %% Hydraulic pressure produced by pedal force
            obj.Pl = zeros(size(obj.Fpedal, 2), 2);
            obj.Pl(:, 1) = obj.BBB(1)*2.*((obj.Fpedal(1, :).*obj.l_p*obj.nu_p)./obj.Amc(1));
            obj.Pl(:, 2) = obj.BBB(2)*2.*((obj.Fpedal(1, :).*obj.l_p*obj.nu_p)./obj.Amc(2));
    
            %% Actual braking force
            obj.Fx_real = zeros(size(obj.Fpedal, 2), 2);
            obj.Fx_real(:, 1) = (obj.Pl(:, 1) - obj.Po).*obj.Awc(1).*(obj.nu_c*obj.BF).*(obj.r(1)/obj.R(2));
            obj.Fx_real(:, 2) = (obj.Pl(:, 2) - obj.Po).*obj.Awc(2).*(obj.nu_c*obj.BF).*(obj.r(1)/obj.R(2));

            %% Braking distribution
            obj.phi = (obj.Fx_real(1, 2)./(obj.Fx_real(1, 2) + obj.Fx_real(1, 1))); % Brake Distribution in 400 [N]

        end

        function calcCntFriction(obj)
            %% Lines of constant friction
            obj.a_fr = [(((1-obj.psi)*obj.mu(1))/(1-obj.chi*obj.mu(1))) ((obj.psi*obj.mu(2))/(1+obj.chi*obj.mu(2)))];
        end

        % %% brake torque
        % function calcTp(obj, RpF, RpR, IWF, IWR)
        %     IW = [IWF IWR];
        %     Rp = [RpF RpR];
        %     obj.Tp = (obj.Fx.*Rp) + IW.*(abs(obj.Acc.Read.data(:, 2).*obj.g)./Rp);
        % end
        % %% friction forces on the caliper
        % function calcFp(obj, RextF, RextR, HpF, HpR)
        %     Rext = [RextF RextR];
        %     Hp = [HpF HpR];
        %     Ref = Rext - (Hp./2);
        %     obj.Fp = (obj.Tp./Ref).*0.5;
        % end
        % %% hidraulic pressure
        % function calcPh(obj, Acp, mup)
        %     obj.Ph = obj.Fp./(Acp*mup);
        % end
        % %% master cylinder forces
        % function calcFcm(obj, Acm)
        %     obj.Fcm = obj.Ph.*Acm;
        % end
        % %% brake pedral force
        % function calcFpedal(obj, Hr)
        %     obj.Fpedal = (obj.Fcm(:, 1)+obj.Fcm(:, 2)).*Hr;
        % end

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%PLOTS%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function pltbrakeline(obj)

            plotlimit = 1;

            for i = 1:length(obj.Fx_optm)
                if (obj.Fx_optm(i,1)/obj.W)+(obj.Fx_optm(i,2)/obj.W) == plotlimit
                    break
                end
            end

            x1 = obj.Fx_optm(1:i,2)./obj.W;
            y1 = obj.Fx_optm(1:i,1)./obj.W;
            x2 = linspace(0, obj.mu(1), length(obj.Fx_optm(1:i,2)));
            y2 = linspace(obj.mu(1), 0, length(obj.Fx_optm(1:i,2)));

            [xi, yi] = polyxpoly(x1, y1, x2, y2, 'unique');

            figure
            hold all
            title('Optimum Braking Line')
            title('Brake Curve')
            axis([0 1 0 1])
            xlabel('Dynamic Rear Axle Brake Force (Normalized)')
            ylabel('Dynamic Front Axle Brake Force (Normalized)')
            grid on

            plot(obj.Fx_optm(1:i,2)./obj.W, obj.Fx_optm(1:i,1)./obj.W, 'DisplayName', 'Optimum Braking Line')
            plot(obj.phi.*obj.Acc.Read.data(:, 2), linspace(0, 1, length(obj.Acc.Read.data(:, 2))), 'DisplayName', 'Real Braking Line')
            plot([0 xi], [obj.a_fr(1) yi], 'r-', 'DisplayName', 'Lines of Constant Friction (front)')
            plot([obj.a_fr(2) xi], [0 yi], 'r-', 'DisplayName', 'Lines of Constant Friction (rear)')
            for j = 0.1:0.1:1
                plot([0 j], [j 0], 'g--')
            end
            
        end
        function pltfft(obj)
            figure
            hold all
            title('FFT')
            plot(obj.Acc.Read.w, obj.Acc.Read.A(:, 2))
            xlabel('Amplitude')
            ylabel('Frequency')
            grid on
        end

        function pltacqrt(obj)
            figure
            hold all
            title('')
            plot(obj.Acc.Read.acqrt)
            xlabel('Acquisition Rate')
            ylabel('Samples')
            grid on
        end
        function pltAcc(obj)
            figure
            hold all
            title('Acc')
            plot(obj.Acc.Read.t, obj.Acc.Read.data(:, 2))
            xlabel('time [s]')
            ylabel('Acceleration [g]')
            grid on
        end
        function pltmu(obj)
            figure
            hold all
            title('Traction coefficient')
            plot(obj.Acc.Read.t, obj.mu(:,1), '-b')
            plot(obj.Acc.Read.t, obj.mu(:,2), '-r')
            xlabel('time [s]')
            ylabel('\mu')
            legend('front', 'rear')
            grid on
        end
        function pltFz(obj)
            figure
            hold all
            title('Dynamic Reaction')
            plot(obj.Acc.Read.t, obj.Fz(:, 1), '-b')
            plot(obj.Acc.Read.t, obj.Fz(:, 2), '-r')
            xlabel('time [s]')
            ylabel('Dynamic Reaction [N]')
            legend('front', 'rear')
            grid on
        end
        function pltFx(obj)
            figure
            hold all
            title('Braking Forces')
            plot(obj.Acc.Read.t, obj.Fx(:, 1), 'b-')
            plot(obj.Acc.Read.t, obj.Fx(:, 2), 'r-')
            xlabel('time [s]')
            ylabel('Loking Force [N]')
            legend('front', 'rear')
            grid on
        end
        function pltTp(obj)
            figure
            hold all
            title('')
            plot(obj.Acc.Read.t, obj.Tp(:, 1), 'b-')
            plot(obj.Acc.Read.t, obj.Tp(:, 2), 'r-')
            xlabel('time [s]')
            ylabel('Brake Torque [Nm]')
            legend('front', 'rear')
            grid on
        end
        function pltFp(obj)
            figure
            hold all
            title('')
            plot(obj.Acc.Read.t, obj.Fp(:, 1), 'b-')
            plot(obj.Acc.Read.t, obj.Fp(:, 2), 'r-')
            xlabel('time [s]')
            ylabel('Friction Force [N]')
            legend('front', 'rear')
            grid on
        end
        function pltPh(obj)
            figure
            hold all
            title('')
            plot(obj.Acc.Read.t, (obj.Ph(:, 1))*1E-5, 'b-')
            plot(obj.Acc.Read.t, (obj.Ph(:, 2))*1E-5, 'r-')
            xlabel('time [s]')
            ylabel('Hydraulic pressure [Bar]')
            legend('front', 'rear')
            grid on
        end
        function pltFcm(obj)
            figure
            hold all
            title('')
            plot(obj.Acc.Read.t, obj.Fcm(:, 1), 'b-')
            plot(obj.Acc.Read.t, obj.Fcm(:, 2), 'r-')
            xlabel('time [s]')
            ylabel('Fcm [N]')
            legend('front', 'rear')
            grid on
        end
        function pltFpedal(obj)
            figure
            hold all
            title('')
            plot(obj.Acc.Read.t, abs((obj.Fpedal)/obj.g), 'b-')
            plot(obj.Acc.Read.t, (445/obj.g).*ones(1,numel(obj.Acc.Read.t)))
            plot(obj.Acc.Read.t, (823/obj.g).*ones(1,numel(obj.Acc.Read.t)))
            legend('Data', '5th percentile female', '95th percentile male')
            xlabel('time [s]')
            ylabel('Fpedal [Kg]')
            grid on
        end

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%STATISTICS%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function pltavgmu(obj, a, b)
            % range a:b in seconds
            figure
            hold all
            histogram(obj.mu(a*obj.Acc.fs:b*obj.Acc.fs, 1), 'Normalization', 'probability');
            xlabel('\mu front');
            ylabel('Probabilidade');
            figure(n+1)
            histogram(obj.mu(a*obj.Acc.fs:b*obj.Acc.fs, 2), 'Normalization', 'probability');
            xlabel('\mu rear');
            ylabel('Probabilidade');
        end
        function pltavgacc(obj, a, b)
            figure
            hold all
            histogram(obj.Acc.R.data(a*obj.Acc.fs:b*obj.Acc.fs, 2), 'Normalization', 'probability');
            
        end
        function pltdistn(obj, a, b, datatype)
            switch datatype
                case 'mu'
                    figure
                    histfit(obj.mu(a*obj.Acc.fs:b*obj.Acc.fs, 1), 50, 'Normal')
                    xlabel('Dados [\mu]');
                    ylabel('Frequencia');
                    legend('Data', 'Normal Distribution', 'Location', 'NorthWest')
                    title('Front \mu')
                    figure
                    histfit(obj.mu(a*obj.Acc.fs:b*obj.Acc.fs, 2),50,'Normal');
                    xlabel('Dados [\mu]');
                    ylabel('Frequencia');
                    legend('Data', 'Normal Distribution', 'Location', 'NorthWest')
                    title('Rear \mu')
                    figure
                    qqplot(obj.mu(a*obj.Acc.fs:b*obj.Acc.fs, 1))
                    title('Front')
                    figure
                    qqplot(obj.mu(a*obj.Acc.fs:b*obj.Acc.fs, 2))
                    title('Rear')
                case 'acc'
                    figure
                    histfit(obj.Acc.Read.data(a*obj.Acc.fs:b*obj.Acc.fs, 2),50,'Normal');
                    xlabel('Data [acc]');
                    ylabel('Frequency');
                    legend('Data', 'Normal Distribution', 'Location', 'NorthWest')
                    figure
                    qqplot(obj.Acc.Read.data(a*obj.Acc.fs:b*obj.Acc.fs, 2));
                    title('Acc.Read.data')
                    
                
            end
        end
    end
end