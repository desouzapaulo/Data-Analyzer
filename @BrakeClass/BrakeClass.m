classdef BrakeClass < handle
    properties
    data AnalyzeClass = AnalyzeClass.empty
    mu double = double.empty;
    Fz double = double.empty;
    Fx double = double.empty;
    Tp double = double.empty;
    Re double = double.empty;
    Fp double = double.empty;
    Ph double = double.empty;
    Fcm double = double.empty;
    Fpedal double = double.empty;
    end
    %% constructor
    methods
        function obj = BrakeClass(folder, sensor, fs, CG, L, W, Rp, IW, Rext, Hp, mup, Acp, Acm, Hr)
            %% base data
            obj.data = AnalyzeClass(folder, sensor, fs);
            obj.data.normdata()
            obj.data.fft()
            obj.data.filter(5)
            obj.data.scale(1/9.81)
            %% parameters of the center of gravity
            phi = CG(1) / L;
            X = CG(3) / L;
            %% dynamic reaction on Mheels
            Fzr = (phi - X.*obj.data.data(:, 2)).*W;
            Fzf = (1 - phi + X.*obj.data.data(:, 2)).*W;
            obj.Fz = [Fzf Fzr];
            %% locking forces
            Fxr = (phi + X.*obj.data.data(:, 2)).*(obj.data.data(:, 2).*W);
            Fxf = (1 - phi + X.*obj.data.data(:, 2)).*(obj.data.data(:, 2).*W);
            obj.Fx = [Fxf Fxr];
            %% coefficient of friction
            obj.mu = obj.Fx./obj.Fz;
            %% brake torque
            obj.Tp = (obj.Fx.*Rp) + IW.*(obj.data.data(:, 2)./Rp);
            %% friction forces on the caliper
            Ref = Rext - (Hp./2);
            obj.Fp = obj.Tp./Ref;
            %% hidraulic pressure
            obj.Ph = obj.Fp./(Acp*mup);
            %% master cylinder forces
            obj.Fcm = obj.Ph.*Acm;
            %% brake pedral force
            Ft = obj.Fcm(:, 1) + obj.Fcm(:, 2);
            obj.Fpedal = Ft.*Hr;
        end
        function acc(obj, n)
            figure(n)
            plot(obj.data.t, obj.data.data(:, 2))
            xlabel('time [s]')
            ylabel('Acceleration [g]')
            grid on
        end
        function mudata(obj, n)
            figure(n)
            hold all
            plot(obj.data.t, obj.mu)
            xlabel('time [s]')
            ylabel('\mu')
            legend('front', 'rear')
            grid on
        end
        function dynreac(obj, n)
            figure(n)
            hold all
            plot(obj.data.t, obj.Fz)
            xlabel('time [s]')
            ylabel('Dynamic Reaction [N]')
            legend('front', 'rear')
            grid on
        end
        function lockforce(obj, n)
            figure(n)
            hold all
            plot(obj.data.t, obj.Fx(:, 1), 'b-')
            plot(obj.data.t, obj.Fx(:, 2), 'r-')
            xlabel('time [s]')
            ylabel('Loking Force [N]')
            legend('front', 'rear')
            grid on
        end
        function btorque(obj, n)
            figure(n)
            hold all
            plot(obj.data.t, obj.Tp(:, 1), 'b-')
            plot(obj.data.t, obj.Tp(:, 2), 'r-')
            xlabel('time [s]')
            ylabel('Brake Torque [Nm]')
            legend('front', 'rear')
            grid on
        end
        function frictionforce(obj, n)
            figure(n)
            hold all
            plot(obj.data.t, obj.Fp(:, 1), 'b-')
            plot(obj.data.t, obj.Fp(:, 2), 'r-')
            xlabel('time [s]')
            ylabel('Friction Force [N]')
            legend('front', 'rear')
            grid on
        end
        function hydpressure(obj, n)
            figure(n)
            hold all
            plot(obj.data.t, obj.Ph(:, 1), 'b-')
            plot(obj.data.t, obj.Ph(:, 2), 'r-')
            xlabel('time [s]')
            ylabel('Hydraulic pressure [Pa]')
            legend('front', 'rear')
            grid on
        end
        function cylinderforce(obj, n)
            figure(n)
            hold all
            plot(obj.data.t, obj.Fcm(:, 1), 'b-')
            plot(obj.data.t, obj.Fcm(:, 2), 'r-')
            xlabel('time [s]')
            ylabel('Fcm [N]')
            grid on
        end
        function pedalforce(obj, n)
            figure(n)
            hold all
            plot(obj.data.t, obj.Fpedal, 'b-')
            xlabel('time [s]')
            ylabel('Fpedal [N]')
            grid on
        end
        function avgmu(obj, n, a, b)
            % range a:b in seconds
            figure(n)
            hold all
            histogram(obj.mu(a*obj.data.fs:b*obj.data.fs, 1), 'Normalization', 'probability');
            xlabel('\mu front');
            ylabel('Probabilidade');
            figure(n+1)
            histogram(obj.mu(a*obj.data.fs:b*obj.data.fs, 2), 'Normalization', 'probability');
            xlabel('\mu rear');
            ylabel('Probabilidade');
        end
        function avgacc(obj, n, a, b)
            figure(n)
            hold all
            histogram(obj.data.data(a*obj.data.fs:b*obj.data.fs, 2), 'Normalization', 'probability');
            xlabel('Acceleration [g]');
            ylabel('Probabilidade');
        end
    end
end