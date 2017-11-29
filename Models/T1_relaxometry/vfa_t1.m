classdef vfa_t1
% vfa_t1: Compute a T1 map using Variable Flip Angle
%
% Assumptions:
% 
% Inputs:
%   VFAData         spoiled Gradient echo data, 4D volume with different flip angles in time dimension
%   (B1map)           excitation (B1+) fieldmap. Used to correct flip angles. [optional]
%
% Outputs:
%   T1              Longitudinal relaxation time [s]
%   M0              Equilibrium magnetization
%
% Protocol:
%   Array [nbFA x 2]:
%       [FA1 TR1; FA2 TR2;...]      flip angle [degrees] TR [s]
%
% Options:
%   None
%
% Example of command line usage (see also <a href="matlab: showdemo vfa_t1_batch">showdemo vfa_t1_batch</a>):
%   Model = vfa_t1;  % Create class from model 
%   Model.Prot.SPGR.Mat=[3 0.015; 20 0.015]; %Protocol: 2 different FAs
%   data = struct;  % Create data structure 
%   data.VFAData = load_nii_data('VFAData.nii.gz');
%   data.B1map = load_nii_data('B1map.nii.gz');
%   FitResults = FitData(data,Model); %fit data
%   FitResultsSave_mat(FitResults);
%
%   For more examples: <a href="matlab: qMRusage(vfa_t1);">qMRusage(vfa_t1)</a>
%
% 
% Author: Ian Gagnon, 2017
%
% References:
%   Please cite the following if you use this module:
%     Fram, E.K., Herfkens, R.J., Johnson, G.A., Glover, G.H., Karis, J.P.,
%     Shimakawa, A., Perkins, T.G., Pelc, N.J., 1987. Rapid calculation of
%     T1 using variable flip angle gradient refocused imaging. Magn. Reson.
%     Imaging 5, 201?208
%   In addition to citing the package:
%     Cabana J-F, Gu Y, Boudreau M, Levesque IR, Atchia Y, Sled JG,
%     Narayanan S, Arnold DL, Pike GB, Cohen-Adad J, Duval T, Vuong M-T and
%     Stikov N. (2016), Quantitative magnetization transfer imaging made
%     easy with qMTLab: Software for data simulation, analysis, and
%     visualization. Concepts Magn. Reson.. doi: 10.1002/cmr.a.21357

properties (Hidden=true)
% Hidden proprties goes here.    
end

    properties
        MRIinputs = {'VFAData','B1map','Mask'};
        xnames = {'M0','T1'};
        voxelwise = 1;
        
        % Protocol
        Prot  = struct('SPGR',struct('Format',{{'FlipAngle' 'TR'}},...
                                         'Mat', [3 0.015; 20 0.015])); % You can define a default protocol here.
        
        % fitting options
        st           = [2000 0.7]; % starting point
        lb           = [0   0.00001]; % lower bound
        ub           = [6000   5]; % upper bound
        fx           = [0     0]; % fix parameters
                                     
        % Model options
        buttons = {};
        options= struct(); % structure filled by the buttons. Leave empty in the code
        
    end
    
methods (Hidden=true)
% Hidden methods goes here.    
end
    
    methods
        
        function obj = vfa_t1()
            obj.options = button2opts(obj.buttons);
        end
        
        function Smodel = equation(obj,x)
            % Generates a VFA signal based on input parameters
            x = mat2struct(x,obj.xnames); % if x is a structure, convert to vector

            % Equation: S=M0sin(a)*(1-E)/(1-E)cos(a); E=exp(-TR/T1)
            flipAngles = (obj.Prot.SPGR.Mat(:,1))';
            TR = obj.Prot.SPGR.Mat(1,2);
            E = exp(-TR/x.T1);
            Smodel = x.M0*sin(flipAngles/180*pi)*(1-E)./(1-E*cos(flipAngles/180*pi));
            
        end
        
       function FitResult = fit(obj,data)           
            % T1 and M0
            flipAngles = (obj.Prot.SPGR.Mat(:,1))';
            TR = obj.Prot.SPGR.Mat(:,2);
            if ~isfield(data,'B1map'), data.B1map=1; end
            [FitResult.M0, FitResult.T1] = mtv_compute_m0_t1(double(data.VFAData), flipAngles, TR(1), data.B1map);
       
        end
        
        function plotModel(obj,x,data)
            if nargin<2 || isempty(x), x = obj.st; end
            
            x = mat2struct(x,obj.xnames);
            if isempty(data.B1map), data.B1map=1; end
            disp(x)
            flipAngles = obj.Prot.SPGR.Mat(:,1)';
            TR = obj.Prot.SPGR.Mat(1,2)';
            
            % Plot data and fitted signal
            subplot(2,1,1)
            plot(flipAngles,data.VFAData,'.','MarkerSize',16)
            E = exp(-TR/x.T1);
            Smodel = x.M0*sin(flipAngles/180*pi*data.B1map)*(1-E)./(1-E*cos(flipAngles/180*pi*data.B1map));
            hold on
            plot(flipAngles,Smodel,'x','MarkerSize',16)
            hold off
            title('Data points','FontSize',14);
            xlabel('Flip Angle [deg]','FontSize',12);
            ylabel('Signal','FontSize',12);
            legend('data', 'fitted','Location','best')
            set(gca,'FontSize',12)
            
            % Plot linear fit
            subplot(2,1,2)
            ydata = data.VFAData./sin(flipAngles/180*pi*data.B1map)';
            xdata = data.VFAData./tan(flipAngles/180*pi*data.B1map)';
            plot(xdata,ydata,'xb','MarkerSize',16)
            hold on
            slope = exp(-TR/x.T1);
            intercept = x.M0*(1-slope);
            mval = min(xdata);
            Mval = max(xdata);
            plot([mval Mval],intercept+slope*[mval Mval],'-r');
            hold off
            title('Linear Fit','FontSize',14);
            xlabel('[au]','FontSize',12);
            ylabel('[au]','FontSize',12);
            legend('linearized data', 'linear fit','Location','best')
            %txt=strcat('T1=',num2str(x.T1),'s M0=',num2str(x.M0));
            %text(mval*1.1,max(ydata)*0.8,txt)
            set(gca,'FontSize',12)

%             h = plot( fitresult, xData, yData,'+');
%             set(h,'MarkerSize',30)
%             legend( h, 'y vs. x', 'untitled fit 1', 'Location', 'NorthEast' );
%             p11 = predint(fitresult,x,0.95,'observation','off');
%             hold on
%             plot(x,p11,'m--'); drawnow;
%             hold off
%             % Label axes
%             xlabel( 'x' );
%             ylabel( 'y' );
%             grid on
%             saveas(gcf,['temp.jpg']);
        end

    end
end
