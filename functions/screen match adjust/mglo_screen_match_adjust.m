function S = mglo_screen_match_adjust(DEG_PER_REL, Screen, overrides, MLConfig)
%mglo_screen_match_adjust  Screen geometry + relative-axes layout for mGLO.
%
%   S = mglo_screen_match_adjust(DEG_PER_REL, Screen, [], MLConfig) fits
%   the task to whatever display it is running on -- a rig monitor, a
%   training kiosk, a laptop in simulation mode. Inside a timing file both
%   objects are simply in scope (trialholder_v2.m receives MLConfig and sets
%   Screen = MLConfig.Screen), and mGLO.m passes them every trial. Nothing
%   in this file is specific to one machine.
%
%   What is taken from MonkeyLogic, per machine:
%     resolution    Screen.Xsize / Screen.Ysize -- the subject screen as
%                   MonkeyLogic created it (mglgetscreeninfo, native pixels)
%     PX_PER_DEG    Screen.PixelsPerDegree -- MonkeyLogic's own conversion,
%                   built from the adapter's native display mode and the
%                   "Diagonal size" and "Viewing distance" entered in that
%                   machine's MonkeyLogic main menu (mlconfig.m). It is the
%                   SAME number MonkeyLogic uses to place every TaskObject
%                   and fixation window, so stimuli sized with it agree with
%                   the rest of the task by construction. It does not go
%                   through MATLAB's DPI-scaled screen size, so Windows
%                   display scaling does not affect it.
%     physical size SCREEN_WIDTH / SCREEN_HEIGHT (cm) of the subject area and
%                   DISTANCE_TO_SCREEN, from MLConfig.DiagonalSize and
%                   ViewingDistance, for the barcode.
%   Per-machine accuracy therefore comes from entering the right diagonal
%   and viewing distance in MonkeyLogic on that machine, nowhere else.
%
%   Layout auto-fit: the token row and choice ports are laid out in
%   relative units over a half-range of 1.0 rel = DEG_PER_REL degrees. When
%   the screen spans fewer degrees than that (a small or close-up kiosk
%   screen), the layout is compressed to fit (S.REL2DEG < DEG_PER_REL,
%   S.LayoutFitted = true) instead of running off the edges. The central
%   STIMULUS keeps its size in degrees (STIM_REL_DIAM * DEG_PER_REL) so
%   stimulus visual angle stays comparable across setups.
%
%   S = mglo_screen_match_adjust(DEG_PER_REL) with no screen falls back to
%   a declared preview panel (below). That path is for offline use only --
%   previewing geometry from the command window, tests.
%
%   overrides (struct, optional) replaces named fields before anything is
%   derived; an override of the physical geometry wins over the measured
%   value, e.g. to force a known panel:
%       S = mglo_screen_match_adjust(15, [], struct('SCREEN_HEIGHT', 30, ...
%               'DISTANCE_TO_SCREEN', 57));
%
%   S.Measured reports whether MonkeyLogic's live screen was used.
%
%   Returned fields
%     Layout (rel units)  TOKEN_REL_Y, TOKEN_REL_HALFSPAN, PORT_REL_X,
%                         STIM_REL_DIAM, TOKEN_IMG_FILL, TOKEN_IMG_MAXH_REL
%     Panel               SCREEN_HEIGHT, SCREEN_WIDTH (cm),
%                         SCREEN_RES_WIDTH, SCREEN_RES_HEIGHT (px),
%                         DISTANCE_TO_SCREEN (cm), SCREEN_HALF_DEG ([x y])
%     Grating             CONTRAST, DONUT_SIZE, A_DEGREE, B_DEGREE,
%                         SPATIAL_FREQUENCY, TEMPORAL_FREQUENCY
%     Derived             REL2DEG (layout), DEG_PER_REL, PX_PER_DEG,
%                         STIM_SLOT_PX, SIZE, STIM_FALLBACK_PX
%     Status              Measured, MeasuredPPD, LayoutFitted
%
%   See also mGLO.

persistent lastWarning   % warn once per distinct problem, not every trial

if nargin < 1 || isempty(DEG_PER_REL), DEG_PER_REL = 15; end
if nargin < 2, Screen = []; end
if nargin < 3 || isempty(overrides), overrides = struct(); end
if nargin < 4, MLConfig = []; end

%--- Layout in relative units ---------------------------------------------
S.TOKEN_REL_Y        = 0.9;   % token row at the top
S.TOKEN_REL_HALFSPAN = 0.9;   % all token centers fit within [-1, 1]
S.PORT_REL_X         = 0.7;   % choice ports left/right of center
S.STIM_REL_DIAM      = 0.5;   % central stimulus diameter

% Token image slot: fit within 90% of the token spacing, max height 0.15 rel.
S.TOKEN_IMG_FILL     = 0.9;
S.TOKEN_IMG_MAXH_REL = 0.15;

% Fraction of the screen's half-extent the 1.0-rel layout may use when it
% has to be compressed (leaves a sliver so edge tokens are not clipped).
LAYOUT_MARGIN        = 0.95;

%--- Grating description (barcode only; the movies are pre-rendered) ------
S.CONTRAST           = 0.8;
S.DONUT_SIZE         = 0;     % visual degrees
S.A_DEGREE           = 45;
S.B_DEGREE           = 135;
S.SPATIAL_FREQUENCY  = 1;
S.TEMPORAL_FREQUENCY = 2;

S.STIM_FALLBACK_PX   = 800;   % used only if TaskObject introspection fails

%--- Preview panel, used ONLY when MonkeyLogic's screen is unavailable -----
% A generic 1080p panel for offline previews and tests. A running task never
% uses these: it measures the real screen below. Width is derived from the
% pixel aspect ratio, so the preview panel is always self-consistent.
S.SCREEN_RES_WIDTH   = 1920;
S.SCREEN_RES_HEIGHT  = 1080;
S.SCREEN_HEIGHT      = 15;    % centimeters
S.SCREEN_WIDTH       = NaN;   % derived below unless overridden
S.DISTANCE_TO_SCREEN = 20;    % centimeters

%--- Take the real screen from MonkeyLogic ---------------------------------
S.Measured = false;
S.MeasuredPPD = NaN;
if ~isempty(Screen)
    try
        ppd = Screen.PixelsPerDegree;
        xs = getOr(Screen, 'Xsize', NaN);
        ys = getOr(Screen, 'Ysize', NaN);
        if isscalar(ppd) && isfinite(ppd) && 0 < ppd && ...
                isfinite(xs) && 0 < xs && isfinite(ys) && 0 < ys
            S.MeasuredPPD = ppd;
            S.Measured = true;
            S.SCREEN_RES_WIDTH  = xs;
            S.SCREEN_RES_HEIGHT = ys;
            % Physical size of the subject area and viewing distance, from
            % the same MonkeyLogic settings PixelsPerDegree was built from.
            [cmPerPx, dist] = physicalScale(MLConfig, ppd);
            if isfinite(cmPerPx)
                S.SCREEN_WIDTH       = xs * cmPerPx;
                S.SCREEN_HEIGHT      = ys * cmPerPx;
                S.DISTANCE_TO_SCREEN = dist;
            end
        else
            warnOnce(sprintf(['MonkeyLogic screen not usable (PixelsPerDegree %s, ' ...
                'size %s x %s) -- using the %dx%d preview panel. Stimulus sizes ' ...
                'will be wrong on a real display.'], mat2str(ppd), mat2str(xs), ...
                mat2str(ys), S.SCREEN_RES_WIDTH, S.SCREEN_RES_HEIGHT), 'noPPD');
        end
    catch ME
        warnOnce(sprintf('Could not read the MonkeyLogic screen (%s); using the preview panel.', ...
            ME.message), 'badScreen');
    end
end

%--- Apply caller overrides before deriving anything ----------------------
fn = fieldnames(overrides);
for i = 1:numel(fn)
    if ~isfield(S, fn{i})
        error('mglo_screen_match_adjust:badOverride', ...
              'Unknown geometry field "%s".', fn{i});
    end
    S.(fn{i}) = overrides.(fn{i});
end
if ~isfinite(S.SCREEN_WIDTH)
    S.SCREEN_WIDTH = S.SCREEN_HEIGHT * S.SCREEN_RES_WIDTH / S.SCREEN_RES_HEIGHT;
end

%--- Pixels per degree ----------------------------------------------------
% MonkeyLogic's value when we have it. An explicit override of the physical
% geometry wins, since that is the caller stating they know better.
geomOverridden = any(isfield(overrides, {'SCREEN_HEIGHT','DISTANCE_TO_SCREEN','SCREEN_RES_HEIGHT'}));
if S.Measured && ~geomOverridden
    S.PX_PER_DEG = S.MeasuredPPD;
else
    S.PX_PER_DEG = S.SCREEN_RES_HEIGHT / ...
                   (2*atand((S.SCREEN_HEIGHT/2)/S.DISTANCE_TO_SCREEN));
    S.Measured = false;
end

%--- Fit the layout to the screen ------------------------------------------
% Visible half-extent in degrees, then the largest rel scale for which the
% whole 1.0-rel layout stays on screen in both directions.
S.SCREEN_HALF_DEG = [S.SCREEN_RES_WIDTH S.SCREEN_RES_HEIGHT] / 2 / S.PX_PER_DEG;
S.DEG_PER_REL = DEG_PER_REL;
fitDeg = LAYOUT_MARGIN * min(S.SCREEN_HALF_DEG);
S.REL2DEG = min(DEG_PER_REL, fitDeg);
S.LayoutFitted = S.REL2DEG < DEG_PER_REL;
if S.LayoutFitted
    warnOnce(sprintf(['Screen spans +/-%.1f x +/-%.1f deg, less than the layout''s ' ...
        '+/-%g deg (DEG_PER_REL): token row and choice ports compressed to +/-%.1f deg. ' ...
        'Stimulus size unchanged.'], S.SCREEN_HALF_DEG(1), S.SCREEN_HALF_DEG(2), ...
        DEG_PER_REL, S.REL2DEG), 'layoutFitted');
end

% The stimulus keeps its size in DEGREES regardless of the layout fit, so
% visual angle is comparable across setups. Native asset sizes are read at
% run time (TaskObject.Size for movies, imfinfo/VideoReader at trial 1 for
% token art and g000.avi), so assets of ANY size fit the same slot.
S.SIZE         = S.STIM_REL_DIAM*DEG_PER_REL;   % diameter, visual deg (barcode)
S.STIM_SLOT_PX = S.SIZE*S.PX_PER_DEG;           % diameter, px
if S.SIZE > 2*min(S.SCREEN_HALF_DEG)
    warnOnce(sprintf(['Stimulus (%.1f deg) is larger than the screen''s shorter side ' ...
        '(%.1f deg). Lower DEG_PER_REL or check the diagonal / viewing distance ' ...
        'in the MonkeyLogic menu.'], S.SIZE, 2*min(S.SCREEN_HALF_DEG)), 'stimTooBig');
end


    function warnOnce(msg, id)
        % Runs every trial: repeat a warning only when the problem changes.
        if ~isequal(lastWarning, msg)
            lastWarning = msg;
            warning(['mglo_screen_match_adjust:' id], '%s', msg);
        end
    end
end


function [cmPerPx, dist] = physicalScale(MLConfig, ppd)
%physicalScale  cm per pixel and viewing distance from MonkeyLogic's config.
%   Inverts mlconfig.m's get.PixelsPerDegree: ppd = diagPx / viewingDeg with
%   viewingDeg from DiagonalSize and ViewingDistance, so the physical
%   diagonal (DiagonalSize cm) spans ppd*viewingDeg pixels.
try
    diagCm = MLConfig.DiagonalSize;
    dist   = MLConfig.ViewingDistance;
    adjusted = false;
    try, adjusted = logical(MLConfig.AdjustedPPD); catch, end
    if adjusted
        viewingDeg = diagCm / (dist * tand(1));
    else
        viewingDeg = 2 * atand((diagCm/2) / dist);
    end
    if isfinite(diagCm) && 0 < diagCm && isfinite(dist) && 0 < dist
        cmPerPx = diagCm / (ppd * viewingDeg);
    else
        dist = NaN;
    end
catch
    cmPerPx = NaN;
    dist = NaN;
end
end


function v = getOr(obj, name, dflt)
%getOr  obj.(name) for mlscreen objects and plain struct stand-ins alike.
v = dflt;
try
    if (isobject(obj) && isprop(obj, name)) || (isstruct(obj) && isfield(obj, name))
        v = double(obj.(name));
    end
catch
end
end
