function varargout = ddpg(varargin)
% DDPG MATLAB code for ddpg.fig
%      DDPG, by itself, creates a new DDPG or raises the existing
%      singleton*.
%
%      H = DDPG returns the handle to a new DDPG or the handle to
%      the existing singleton*.
%
%      DDPG('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in DDPG.M with the given input arguments.
%
%      DDPG('Property','Value',...) creates a new DDPG or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before ddpg_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to ddpg_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help ddpg

% Last Modified by GUIDE v2.5 19-Aug-2020 01:58:50

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @ddpg_OpeningFcn, ...
                   'gui_OutputFcn',  @ddpg_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT

% --- Executes just before ddpg is made visible.
function ddpg_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to ddpg (see VARARGIN)

% Choose default command line output for ddpg
handles.output = hObject;

parameters = load('parameters.mat');
handles.parameters = parameters;
handles.taper = ones(131, 32) * 2.34;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes ddpg wait for user response (see UIRESUME)
% uiwait(handles.figure1);
set(handles.edit1, 'String', num2str(parameters.param_K));
set(handles.edit2, 'String', num2str(parameters.const_K));
set(handles.edit3, 'String', num2str(parameters.starting_step));
set(handles.edit4, 'String', num2str(parameters.MAX_EPISODES));
set(handles.edit5, 'String', num2str(parameters.MAX_EP_STEPS));
set(handles.edit6, 'String', num2str(parameters.LR_A));
set(handles.edit7, 'String', num2str(parameters.LR_C));
set(handles.edit8, 'String', num2str(parameters.GAMMA));
set(handles.edit9, 'String', num2str(parameters.TAU));
set(handles.edit10, 'String', num2str(parameters.MEMORY_CAPACITY));
set(handles.edit11, 'String', num2str(parameters.BATCH_SIZE));
set(handles.edit12, 'String', num2str(parameters.SASE_COUNT));
set(handles.checkbox1,'Value',parameters.SAVE_MODEL);
set(handles.edit13, 'String', parameters.LOAD_MODEL);

set(handles.edit15, 'String', handles.taper(66, 1));
set(handles.edit16, 'String', (handles.taper(end, 1) - handles.taper(1, 1)) / 130);

plot(handles.axes4, reshape(handles.taper, 131 * 32, 1))
axis(handles.axes4, 'auto');
title(handles.axes4, 'Taper profile');
xlabel(handles.axes4, 'N');
ylabel(handles.axes4, 'K');

evalin('base', 'ULT_ScriptToLoadAllFunctions();');

% --- Outputs from this function are returned to the command line.
function varargout = ddpg_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;

function out = checkTaper(taper)
taper = reshape(taper, 131, 32);
HXU = evalin('base', 'UL(1)');
Kbeg = taper(1, :);
Kend = zeros(32,2);
n=HXU.slotlength;
out = 1;
for i=1:n
    if i==5
        continue
    end
    tmpK=Kbeg(i);
    if tmpK > 2.44 || tmpK<0.44
        out = 0;
        break
    end
    try
        tmpUSEG = HXU.slot(i).USEG;
        tmpgap = HXU.slot(i).USEG.f.K_to_gap(tmpUSEG,tmpK);
        gapendup = tmpgap+0.3;
        gapendlow = tmpgap-0.3;
        Kend(i,1)= HXU.slot(i).USEG.f.gap_to_K(tmpUSEG,gapendup);
        Kend(i,2)= HXU.slot(i).USEG.f.gap_to_K(tmpUSEG,gapendlow);
        if min(Kend(i, :)) > taper(end, i) || max(Kend(i, :)) < taper(end, i)
            out = 0;
            break
        end
    catch err
        display('no UND: chicane')
        %out = 0;
    end
end

% --- Executes on button press in btn_auto.
function btn_auto_Callback(hObject, eventdata, handles)
% hObject    handle to btn_auto (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
set(handles.panel_auto,'Visible','on');
set(handles.panel_custom,'Visible','off');

% --- Executes on button press in btn_custom.
function btn_custom_Callback(hObject, eventdata, handles)
% hObject    handle to btn_custom (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
set(handles.panel_auto,'Visible','off');
set(handles.panel_custom,'Visible','on');

function edit1_Callback(hObject, eventdata, handles)
% hObject    handle to edit1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit1 as text
%        str2double(get(hObject,'String')) returns contents of edit1 as a double
if isnan(str2double(get(hObject,'String')))
    set(hObject,'String',num2str(handles.parameters.param_K));
end
handles.parameters.param_K = str2double(get(hObject,'String'));
guidata(hObject, handles);

% --- Executes during object creation, after setting all properties.
function edit1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function edit2_Callback(hObject, eventdata, handles)
% hObject    handle to edit2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit2 as text
%        str2double(get(hObject,'String')) returns contents of edit2 as a double
if isnan(str2double(get(hObject,'String')))
    set(hObject,'String',num2str(handles.parameters.const_K));
end
handles.parameters.const_K = str2double(get(hObject,'String'));
guidata(hObject, handles);

% --- Executes during object creation, after setting all properties.
function edit2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function edit3_Callback(hObject, eventdata, handles)
% hObject    handle to edit3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit3 as text
%        str2double(get(hObject,'String')) returns contents of edit3 as a double
if isnan(str2double(get(hObject,'String')))
    set(hObject,'String',num2str(handles.parameters.starting_step));
end
handles.parameters.starting_step = str2double(get(hObject,'String'));
guidata(hObject, handles);

% --- Executes during object creation, after setting all properties.
function edit3_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function edit4_Callback(hObject, eventdata, handles)
% hObject    handle to edit4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit4 as text
%        str2double(get(hObject,'String')) returns contents of edit4 as a double
if isnan(str2double(get(hObject,'String')))
    set(hObject,'String',num2str(handles.parameters.MAX_EPISODES));
end
handles.parameters.MAX_EPISODES = str2double(get(hObject,'String'));
guidata(hObject, handles);

% --- Executes during object creation, after setting all properties.
function edit4_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes during object creation, after setting all properties.
function axes3_CreateFcn(hObject, eventdata, handles)
% hObject    handle to axes3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: place code in OpeningFcn to populate axes3
title(hObject, 'power change with episodes');
xlabel(hObject, 'N');
ylabel(hObject, 'P[W]');

% --- Executes during object creation, after setting all properties.
function axes2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to axes2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: place code in OpeningFcn to populate axes2
title(hObject, 'Power');
xlabel(hObject, 'Z[N]');
ylabel(hObject, 'P[W]');

% --- Executes during object creation, after setting all properties.
function axes1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to axes1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: place code in OpeningFcn to populate axes1
title(hObject, 'Taper profile');
xlabel(hObject, 'N');
ylabel(hObject, 'K');

function edit5_Callback(hObject, eventdata, handles)
% hObject    handle to edit5 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit5 as text
%        str2double(get(hObject,'String')) returns contents of edit5 as a double
if isnan(str2double(get(hObject,'String')))
    set(hObject,'String',num2str(handles.parameters.MAX_EP_STEPS));
end
handles.parameters.MAX_EP_STEPS = str2double(get(hObject,'String'));
guidata(hObject, handles);

% --- Executes during object creation, after setting all properties.
function edit5_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit5 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function edit6_Callback(hObject, eventdata, handles)
% hObject    handle to edit6 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit6 as text
%        str2double(get(hObject,'String')) returns contents of edit6 as a double
if isnan(str2double(get(hObject,'String')))
    set(hObject,'String',num2str(handles.parameters.LR_A));
end
handles.parameters.LR_A = str2double(get(hObject,'String'));
guidata(hObject, handles);

% --- Executes during object creation, after setting all properties.
function edit6_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit6 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function edit7_Callback(hObject, eventdata, handles)
% hObject    handle to edit7 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit7 as text
%        str2double(get(hObject,'String')) returns contents of edit7 as a double
if isnan(str2double(get(hObject,'String')))
    set(hObject,'String',num2str(handles.parameters.LR_C));
end
handles.parameters.LR_C = str2double(get(hObject,'String'));
guidata(hObject, handles);

% --- Executes during object creation, after setting all properties.
function edit7_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit7 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function edit8_Callback(hObject, eventdata, handles)
% hObject    handle to edit8 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit8 as text
%        str2double(get(hObject,'String')) returns contents of edit8 as a double
if isnan(str2double(get(hObject,'String')))
    set(hObject,'String',num2str(handles.parameters.GAMMA));
end
handles.parameters.GAMMA = str2double(get(hObject,'String'));
guidata(hObject, handles);

% --- Executes during object creation, after setting all properties.
function edit8_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit8 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function edit9_Callback(hObject, eventdata, handles)
% hObject    handle to edit9 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit9 as text
%        str2double(get(hObject,'String')) returns contents of edit9 as a double
if isnan(str2double(get(hObject,'String')))
    set(hObject,'String',num2str(handles.parameters.TAU));
end
handles.parameters.TAU = str2double(get(hObject,'String'));
guidata(hObject, handles);

% --- Executes during object creation, after setting all properties.
function edit9_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit9 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function edit10_Callback(hObject, eventdata, handles)
% hObject    handle to edit10 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit10 as text
%        str2double(get(hObject,'String')) returns contents of edit10 as a double
if isnan(str2double(get(hObject,'String')))
    set(hObject,'String',num2str(handles.parameters.MEMORY_CAPACITY));
end
handles.parameters.MEMORY_CAPACITY = str2double(get(hObject,'String'));
guidata(hObject, handles);

% --- Executes during object creation, after setting all properties.
function edit10_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit10 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function edit11_Callback(hObject, eventdata, handles)
% hObject    handle to edit11 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit11 as text
%        str2double(get(hObject,'String')) returns contents of edit11 as a double
if isnan(str2double(get(hObject,'String')))
    set(hObject,'String',num2str(handles.parameters.BATCH_SIZE));
end
handles.parameters.BATCH_SIZE = str2double(get(hObject,'String'));
guidata(hObject, handles);

% --- Executes during object creation, after setting all properties.
function edit11_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit11 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function edit12_Callback(hObject, eventdata, handles)
% hObject    handle to edit12 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit12 as text
%        str2double(get(hObject,'String')) returns contents of edit12 as a double
if isnan(str2double(get(hObject,'String')))
    set(hObject,'String',num2str(handles.parameters.SASE_COUNT));
end
handles.parameters.SASE_COUNT = str2double(get(hObject,'String'));
guidata(hObject, handles);

% --- Executes during object creation, after setting all properties.
function edit12_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit12 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes on button press in checkbox1.
function checkbox1_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkbox1
handles.parameters.SAVE_MODEL = get(hObject,'Value');
guidata(hObject, handles);

function edit13_Callback(hObject, eventdata, handles)
% hObject    handle to edit13 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit13 as text
%        str2double(get(hObject,'String')) returns contents of edit13 as a double
handles.parameters.LOAD_MODEL = get(hObject,'String');
guidata(hObject, handles);

% --- Executes during object creation, after setting all properties.
function edit13_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit13 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes on button press in btn_open.
function btn_open_Callback(hObject, eventdata, handles)
% hObject    handle to btn_open (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
dir = uigetdir();
if dir ~= 0
    handles.edit13, 'String', dir;
    handles.parameters.LOAD_MODEL = dir;
    guidata(hObject, handles);
end

function pid = runCommandBackground(command)
    fn = '.pid';
    system([command, ' > .log 2>&1 & echo $! > ', fn]);
    pid = load(fn);
    delete(fn);
    
function running = isPIDProgramRunning(pid)
    [~, cmdout] = system(['ps ax | awk ''{ print $1 }'' | grep -e ''^', num2str(pid), '$'' | wc -l']);
    running = (str2double(cmdout) > 0);

function killProgram( pid)
if isPIDProgramRunning(pid)
    system(['kill -9 ', num2str(pid)]);
end

function Des = taper2Destination(taper)
Des = [];
n=evalin('base','UL(1).slotlength');
taper = reshape(taper, 131, 32);
HXU = evalin('base', 'UL(1)');
for i = 1:n
    if i==5
        continue
    end
    Des = [Des struct('Cell', HXU.slotcell(i), 'K', taper(1, i), 'Kend', taper(end, i))];
end

function ddgp_timer_Fcn(tObject, ~, hObject, handles)
    if ~ isPIDProgramRunning(getappdata(hObject, 'ddpg_pid'))
        setappdata(hObject, 'ddpg_pid', -1);
        set(hObject,'String','Start');
        delete(tObject);
        return;
    end
    if exist('power_and_taper.mat','file') == 0
        return;
    end
    % load taper
    result = load('power_and_taper.mat');
    delete('power_and_taper.mat');
    % plot taper
    plot(handles.axes1, result.taper(1:131*23));
    axis(handles.axes1, 'auto');
    title(handles.axes1, 'Taper profile action');
    xlabel(handles.axes1, 'N');
    ylabel(handles.axes1, 'Kact');
    % set taper
    power = [0];
    if checkTaper(result.taper) ~= 0
        assignin('base', 'Des', taper2Destination(result.taper));
        ts=now;
        evalin('base', 'UL(1).f.UndulatorLine_K_set(UL, Des, 0);');
        dt=(now-ts)*24*3600
        und_out = evalin('base','fh.Read_all_K_values(UL(1))');
        plot(handles.axes2,[und_out.K],'bx');
        hold(handles.axes2,'on');
        plot(handles.axes2,[und_out.Kend],'rx');
        axis(handles.axes2, 'auto');
        title(handles.axes2, 'Taper profile destination');
        xlabel(handles.axes2, 'N');
        ylabel(handles.axes2, 'Kdes');
        hold(handles.axes2,'off');
        
        power=[];    
        for i = 1 : handles.parameters.SASE_COUNT
            % run genesis
            % pid = runCommandBackground('./genesis mod.in');
            %setappdata(hObject, 'genesis_pid', pid);
            %while isPIDProgramRunning(pid)
            %    pause(1);
            %end
            %if getappdata(hObject, 'genesis_pid') < 0
            %    return;
            %end
            %setappdata(hObject, 'genesis_pid', -1);
            % load power
            evalin('base', '[~,ats]=lcaGetSmart(''BPMS:LTUH:250:TMIT'');');
            pause(0.1);
            [OUT,ts,PvList] = evalin('base', ...
                strcat('sh.getBPMData_HB_timing(static(1).bpmList_e, ', ...
                '1, ats,{''GDET:FEE1:241:ENRC'',''GDET:FEE1:242:ENRC''});'));
            while sum(sum(isnan(OUT(115:116,:)))) ~= 0
                evalin('base', '[~,ats]=lcaGetSmart(''BPMS:LTUH:250:TMIT'');');
                pause(0.1);
                [OUT,ts,PvList] = evalin('base', ...
                    strcat('sh.getBPMData_HB_timing(static(1).bpmList_e, ', ...
                    '1, ats,{''GDET:FEE1:241:ENRC'',''GDET:FEE1:242:ENRC''});'));
            end
            power = [power; mean(mean(OUT(115:116,:)))];
        end
        if handles.parameters.SASE_COUNT > 1
            power = mean(power);
        end
    end
    % save power for ddpg
    save('power.mat', 'power', '-v4');
    % plot result
%     plot(handles.axes2, power);
%     axis(handles.axes2, 'auto');
%     title(handles.axes2, 'Power');
%     xlabel(handles.axes2, 'Z[N]');
%     ylabel(handles.axes2, 'P[W]');
    progress = getappdata(hObject, 'progress');
    progress = [progress power(end)];
    setappdata(hObject, 'progress', progress);
    plot(handles.axes3, progress);
    axis(handles.axes3, 'auto');
    title(handles.axes3, 'power change with episodes');
    xlabel(handles.axes3, 'N');
    ylabel(handles.axes3, 'P[W]');

function ddgp_timer_error_Fcn(tObject, ~, hObject)
    pid = getappdata(hObject, 'genesis_pid');
    if pid > 0
        killProgram(pid);
    end
    pid = getappdata(hObject, 'ddpg_pid');
    if pid > 0
        killProgram(pid);
    end
    set(hObject,'String','Start');
    delete(tObject);

% --- Executes on button press in btn_start.
function btn_start_Callback(hObject, eventdata, handles)
% hObject    handle to btn_start (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if isequal(get(hObject,'String'), 'Start')
    set(hObject,'String','Stop');
    if exist('power_and_taper.mat', 'file') ~= 0
        delete('power_and_taper.mat');
    end
    if exist('power.mat', 'file') ~= 0
        delete('power.mat');
    end
    parameters = handles.parameters;
    save('parameters.mat', '-struct', 'parameters', '-v4');
    pid = runCommandBackground('python sl_ddpg.py');
    setappdata(hObject, 'ddpg_pid', pid);
    setappdata(hObject, 'progress', []);
    t = timer('StartDelay', 1, 'ExecutionMode', 'fixedDelay');
    t.TimerFcn = {@ddgp_timer_Fcn, hObject, handles};
    t.ErrorFcn = {@ddgp_timer_error_Fcn, hObject};
    start(t);
else
    pid = getappdata(hObject, 'genesis_pid');
    if pid > 0
        killProgram(pid);
    end
    pid = getappdata(hObject, 'ddpg_pid');
    if pid > 0
        killProgram(pid);
    end
end

% --- Executes when user attempts to close figure1.
function figure1_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: delete(hObject) closes the figure
if isstruct(handles)
    if isappdata(handles.btn_start, 'genesis_pid')
        pid = getappdata(handles.btn_start, 'genesis_pid');
        if pid > 0
            killProgram(pid);
        end
    end
    if isappdata(handles.btn_start, 'ddpg_pid')
        pid = getappdata(handles.btn_start, 'ddpg_pid');
        if pid > 0
            killProgram(pid);
        end
    end
    if isappdata(handles.btn_start_custom, 'genesis_pid')
        pid = getappdata(handles.btn_start_custom, 'genesis_pid');
        if pid > 0
            killProgram(pid);
        end
    end
end
delete(hObject);

% --- Executes during object creation, after setting all properties.
function axes4_CreateFcn(hObject, eventdata, handles)
% hObject    handle to axes4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: place code in OpeningFcn to populate axes4

% --- Executes on slider movement.
function slider1_Callback(hObject, eventdata, handles)
% hObject    handle to slider1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
value = get(hObject,'Value');
if rem(value, 1) ~= 0
    value = round(value);
    set(hObject,'Value',value);
end
set(handles.edit14, 'String', num2str(value));
set(handles.edit15, 'String', num2str(handles.taper(66, value)));
set(handles.edit16, 'String', num2str((handles.taper(end, value) - handles.taper(1, value)) / 130));

% --- Executes during object creation, after setting all properties.
function slider1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to slider1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end

function edit15_Callback(hObject, eventdata, handles)
% hObject    handle to edit15 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit15 as text
%        str2double(get(hObject,'String')) returns contents of edit15 as a double
index = get(handles.slider1,'Value');
if isnan(str2double(get(hObject,'String')))
    set(hObject,'String',num2str(handles.taper(66, index)));
else
    value = str2double(get(hObject,'String'));
    slope = str2double(get(handles.edit16,'String'));
    handles.taper(1:131, index) = linspace(value - 65 * slope, value + 65 * slope, 131);
    guidata(hObject, handles);
end
plot(handles.axes4, reshape(handles.taper, 131 * 32, 1))
axis(handles.axes4, 'auto');
title(handles.axes4, 'Taper profile');
xlabel(handles.axes4, 'N');
ylabel(handles.axes4, 'K');

% --- Executes during object creation, after setting all properties.
function edit15_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit15 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function edit16_Callback(hObject, eventdata, handles)
% hObject    handle to edit16 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit16 as text
%        str2double(get(hObject,'String')) returns contents of edit16 as a double
index = get(handles.slider1,'Value');
if isnan(str2double(get(hObject,'String')))
    set(hObject,'String', num2str((handles.taper(end, value) - handles.taper(1, value)) / 130));
else
    value = str2double(get(hObject,'String'));
    center = str2double(get(handles.edit15,'String'));
    handles.taper(1:131, index) = linspace(center - 65 * value, center + 65 * value, 131);
    guidata(hObject, handles);
end
plot(handles.axes4, reshape(handles.taper, 131 * 32, 1))
axis(handles.axes4, 'auto');
title(handles.axes4, 'Taper profile');
xlabel(handles.axes4, 'N');
ylabel(handles.axes4, 'K');

% --- Executes during object creation, after setting all properties.
function edit16_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit16 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit14_Callback(hObject, eventdata, handles)
% hObject    handle to edit14 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit14 as text
%        str2double(get(hObject,'String')) returns contents of edit14 as a double
value = str2double(get(hObject,'String'));
if isnan(value)
    set(hObject,'String',get(handles.slider1,'Value'));
    return;
end
if value > handles.slider1.Max
    value = handles.slider1.Max;
    set(hObject,'String',num2str(value));
elseif value < handles.slider1.Min
    value = handles.slider1.Min;
    set(hObject,'String',num2str(value));
end
if rem(value, 1) ~= 0
    value = round(value);
    set(hObject,'String',num2str(value));
end
set(handles.slider1,'Value',value);
set(handles.edit15, 'String', num2str(handles.taper(66, value)));
set(handles.edit16, 'String', num2str((handles.taper(end, value) - handles.taper(1, value)) / 130));

% --- Executes during object creation, after setting all properties.
function edit14_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit14 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function custom_timer_Fcn(tObject, ~, hObject, handles)
    %if isPIDProgramRunning(getappdata(hObject, 'genesis_pid'))
    %    return;
    %end
    %if getappdata(hObject, 'genesis_pid') < 0
    %    stop(tObject);
    %    return;
    %end
    %setappdata(hObject, 'genesis_pid', -1);
    % load power
    evalin('base', '[~,ats]=lcaGetSmart(''BPMS:LTUH:250:TMIT'');');
    pause(0.1)
    [OUT,ts,PvList] = evalin('base', ...
        strcat('sh.getBPMData_HB_timing(static(1).bpmList_e, ', ...
        '1, ats,{''GDET:FEE1:241:ENRC'',''GDET:FEE1:242:ENRC''});'));
    
    power = mean(mean(OUT(115:116,:)));
    % plot result
    plot(handles.axes5, power);
    axis(handles.axes5, 'auto');
    title(handles.axes5, 'Power');
    xlabel(handles.axes5, 'Z[N]');
    ylabel(handles.axes5, 'P[W]');
    stop(tObject);

function custom_timer_stop_Fcn(tObject, ~, hObject)
    pid = getappdata(hObject, 'genesis_pid');
    if pid > 0
        killProgram(pid);
    end
    delete(tObject);
    set(hObject,'String','Start');

% --- Executes on button press in btn_start_custom.
function btn_start_custom_Callback(hObject, eventdata, handles)
% hObject    handle to btn_start_custom (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if isequal(get(hObject,'String'),'Start')
    if checkTaper(handles.taper) == 0
        msgbox('taper out of range!');
        return;
    end
    set(hObject,'String','Stop');
    % set taper
    assignin('base', 'Des', taper2Destination(handles.taper));
    evalin('base', 'UL(1).f.UndulatorLine_K_set(UL, Des,0);');
    evalin('base', '[~,ats]=lcaGetSmart(''BPMS:LTUH:250:TMIT'');');
    pause(0.1);
    [OUT,ts,PvList] = evalin('base', ...
         strcat('sh.getBPMData_HB_timing(static(1).bpmList_e, ', ...
         '1, ats,{''GDET:FEE1:241:ENRC'',''GDET:FEE1:242:ENRC''});'));
    while sum(sum(isnan(OUT(115:116,:)))) ~= 0
         evalin('base', '[~,ats]=lcaGetSmart(''BPMS:LTUH:250:TMIT'');');
         pause(0.1);
         [OUT,ts,PvList] = evalin('base', ...
             strcat('sh.getBPMData_HB_timing(static(1).bpmList_e, ', ...
             '1, ats,{''GDET:FEE1:241:ENRC'',''GDET:FEE1:242:ENRC''});'));
    end
    power=mean(OUT(115:116,:),1);
    plot(handles.axes5, power);
    axis(handles.axes5, 'auto');
    title(handles.axes5, 'Power');
    xlabel(handles.axes5, 'Z[N]');
    ylabel(handles.axes5, 'P[W]');
    % run genesis
    %pid = runCommandBackground('./genesis mod.in');
    %setappdata(hObject, 'genesis_pid', pid);
    %t = timer('StartDelay', 1, 'ExecutionMode', 'fixedDelay');
    %t.TimerFcn = {@custom_timer_Fcn, hObject, handles};
    %t.StopFcn = {@custom_timer_stop_Fcn, hObject};
    %start(t);
    set(hObject,'String','Start');
end