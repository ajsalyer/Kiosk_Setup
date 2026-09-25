function S = mglo_screen_match_adjust(DEG_PER_REL, Screen, overrides)
%mglo_screen_match_adjust  Screen geometry + relative-axes layout for mGLO.
%
%   S = mglo_screen_match_adjust(DEG_PER_REL, Screen) fits the task to
%   whatever display it is actually running on. Pass MonkeyLogic's live
%   screen object -- inside a timing file it is simply in scope:
%       trialholder_v2.m:9   Screen = MLConfig.Screen;
%   and PX_PER_DEG plus the resolution are then taken from what MonkeyLogic
%   measured, not from numbers typed in here. Move the task to a different
%   panel and every stimulus size, token slot and choice-port position
%   follows automatically, with nothing to edit.
%
%   S = mglo_screen_match_adjust(DEG_PER_REL) with no screen falls back to
%   the declared panel constants below and derives PX_PER_DEG from them.
%   That path is for offline use -- previewing geometry from the command
%   window, tests -- not for a running task.
%
%   S = mglo_screen_match_adjust(DEG_PER_REL, Screen, overrides) replaces
%   named fields before anything is derived, and an override always wins
%   over the measured value, e.g. to force a known panel:
%       S = mglo_screen_match_adjust(15, [], struct('SCREEN_HEIGHT', 30, ...
%               'SCREEN_WIDTH', 53, 'DISTANCE_TO_SCREEN', 57));
%
%   S.Measured reports whether the live screen was used, so the task can
%   barcode which geometry a session actually ran with.
%
%   Relative axes: 1.0 rel = DEG_PER_REL visual degrees (so with the
%   default 15, 0.1 rel = 1.5 deg). Layout is defined in rel units (usable
%   half-range 1.0) and converted with REL2DEG for MonkeyLogic, which works
%   in visual degrees. Keeping the layout in rel units is what lets the same
%   numbers describe the display on any panel.
%
%   Returned fields
%     Layout (rel units)  TOKEN_REL_Y, TOKEN_REL_HALFSPAN, PORT_REL_X,
%                         STIM_REL_DIAM, TOKEN_IMG_FILL, TOKEN_IMG_MAXH_REL
%     Panel               SCREEN_HEIGHT, SCREEN_WIDTH (cm),
%                         SCREEN_RES_WIDTH, SCREEN_RES_HEIGHT (px),
%                         DISTANCE_TO_SCREEN (cm)
%     Grating             CONTRAST, DONUT_SIZE, A_DEGREE, B_DEGREE,
%                         SPATIAL_FREQUENCY, TEMPORAL_FREQUENCY
%     Derived             REL2DEG, PX_PER_DEG, STIM_SLOT_PX, SIZE,
%                         STIM_FALLBACK_PX
%
%   See also mGLO, mGLO-rig.

if nargin < 1 || isempty(DEG_PER_REL), DEG_PER_REL = 15; end
if nargin < 2, Screen = []; end
if nargin < 3, overrides = struct(); end

%--- Layout in relative units ---------------------------------------------
S.TOKEN_REL_Y        = 0.9;   % token row at the top
S.TOKEN_REL_HALFSPAN = 0.9;   % all token centers fit within [-1, 1]
S.PORT_REL_X         = 0.7;   % choice ports left/right of center
S.STIM_REL_DIAM      = 0.5;   % central stimulus diameter

% Token image slot: fit within 90% of the token spacing, max height 1.5 deg.
S.TOKEN_IMG_FILL     = 0.9;
S.TOKEN_IMG_MAXH_REL = 0.15;

%--- Declared panel, used only when no live screen is supplied ------------
% These are a fallback, not the source of truth. A running task passes
% Screen and the measured values below replace the resolution and PPD.
S.CONTRAST           = 0.8;
S.DONUT_SIZE         = 0;     % visual degrees
S.SCREEN_HEIGHT      = 15;    % centimeters
S.SCREEN_WIDTH       = 22;    % centimeters
S.SCREEN_RES_WIDTH   = 1920;
S.SCREEN_RES_HEIGHT  = 1080;
S.DISTANCE_TO_SCREEN = 20;    % centimeters
S.A_DEGREE           = 45;
S.B_DEGREE           = 135;
S.SPATIAL_FREQUENCY  = 1;
S.TEMPORAL_FREQUENCY = 2;

S.STIM_FALLBACK_PX   = 800;   % used only if TaskObject introspection fails

%--- Take the real panel from MonkeyLogic when we have it -----------------
% Screen.PixelsPerDegree is what MonkeyLogic derived from the actual
% subject display and the configured viewing distance, so it is the number
% that makes a stimulus the size it is meant to be. Guarded because the
% object may be absent offline, and PixelsPerDegree is NaN until the screen
% has been created.
S.Measured = false;
S.MeasuredPPD = NaN;
if ~isempty(Screen)
    try
        ppd = Screen.PixelsPerDegree;
        if isscalar(ppd) && isfinite(ppd) && 0 < ppd
            S.MeasuredPPD = ppd;
            S.Measured = true;
            % has() covers both the real mlscreen object and a plain struct
            % stand-in; isprop alone silently misses struct fields.
            if has(Screen,'Xsize') && 0 < Screen.Xsize, S.SCREEN_RES_WIDTH  = Screen.Xsize; end
            if has(Screen,'Ysize') && 0 < Screen.Ysize, S.SCREEN_RES_HEIGHT = Screen.Ysize; end
        else
            warning('mglo_screen_match_adjust:noPPD', ...
                ['Screen.PixelsPerDegree is %s -- falling back to the declared ' ...
                 'panel (%gx%g). Stimulus sizes will be wrong if the real ' ...
                 'display differs.'], mat2str(ppd), S.SCREEN_RES_WIDTH, S.SCREEN_RES_HEIGHT);
        end
    catch ME
        warning('mglo_screen_match_adjust:badScreen', ...
                'Could not read the live screen (%s); using declared panel.', ME.message);
    end
end

%--- Apply caller overrides before deriving anything ----------------------
if ~isempty(overrides) && isstruct(overrides)
    fn = fieldnames(overrides);
    for i = 1:numel(fn)
        if ~isfield(S, fn{i})
            error('mglo_screen_match_adjust:badOverride', ...
                  'Unknown geometry field "%s".', fn{i});
        end
        S.(fn{i}) = overrides.(fn{i});
    end
end

%--- Derived quantities ---------------------------------------------------
S.DEG_PER_REL = DEG_PER_REL;
S.REL2DEG     = DEG_PER_REL;

% Pixels per degree: the measured value when MonkeyLogic gave us one,
% otherwise derived from the declared panel. An explicit override of the
% physical dimensions wins over the measurement, since that is the caller
% stating they know better.
geomOverridden = ~isempty(overrides) && isstruct(overrides) && ...
    any(isfield(overrides, {'SCREEN_HEIGHT','DISTANCE_TO_SCREEN','SCREEN_RES_HEIGHT'}));
if S.Measured && ~geomOverridden
    S.PX_PER_DEG = S.MeasuredPPD;
else
    S.PX_PER_DEG = S.SCREEN_RES_HEIGHT / ...
                   (2*atand((S.SCREEN_HEIGHT/2)/S.DISTANCE_TO_SCREEN));
    if S.Measured
        S.Measured = false;   % an override was used instead
    end
end

% Native asset sizes are read at run time (TaskObject.Size for movies,
% imfinfo/VideoReader at trial 1 for token art and g000.avi), so assets of
% ANY size fit the same slots. Scales downstream are computed from
% STIM_SLOT_PX.
S.STIM_SLOT_PX = S.STIM_REL_DIAM*DEG_PER_REL*S.PX_PER_DEG; % diameter, px
S.SIZE         = S.STIM_REL_DIAM*DEG_PER_REL; % diameter, visual deg (barcode)
end


function tf = has(obj, name)
%has  True if obj carries this field/property, for objects and structs alike.
tf = false;
try
    tf = (isobject(obj) && isprop(obj, name)) || (isstruct(obj) && isfield(obj, name));
catch
end
end
