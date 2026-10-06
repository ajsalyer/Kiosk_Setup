%SIZE in pixels
%MAX_COLOR, 0.0 - 1, with 1 being pure white, and 0 being pure black, and 0.5 being gray
%MIN_COLOR, 0.0 - 1, with 1 being pure white, and 0 being pure black, and 0.5 being gray
%SPATIAL_FREQUENCY, from 0 to infinity (but more reasonable values are
    %under 0.5), with 0 having the spacing between gratings be 0 (whole image
    %changes color at the same time), and larger values having larger spacings
%ROTATION 0-360, how much the grating should be rotated, in degrees
%HERTZ, 0-infinity, how many times per second the phase shifts from peak to peak.
%DURATION,0-infinity , how long the video should be, in seconds. (0.5 being half a second)
%FRAMERATE, how many frames the video will display per second
%FILENAME, what to name your video file, example: 'A.avi'. Make sure to use
%quotation marks for the string, also make sure to include the .avi

%CONTRAST_REDUCTION, 0.0 - 0.3: how far the grating's peaks are pulled in
%from the default 0.2 - 0.8 range towards mid-grey. It REDUCES contrast:
%0 is full contrast (0.2 - 0.8), 0.15 is half (0.35 - 0.65), 0.3 is a flat
%grey field. Values above 0.3 would invert the grating, so they are refused.

function create_drifting_sine_grating_simple(ROTATION,FILENAME, CONTRAST_REDUCTION, SIZE)
    %create_drifting_sine_grating(800,1,0,0.1,135,3,1.0,60,"A.avi")
    if ~exist("SIZE", "var")
        SIZE = 400;
    end
    if ~exist("CONTRAST_REDUCTION", "var")
        CONTRAST_REDUCTION = 0.0;
    end
    if CONTRAST_REDUCTION < 0 || CONTRAST_REDUCTION > 0.3
        error('CONTRAST_REDUCTION must be between 0 (full contrast) and 0.3 (flat grey); got %g.', CONTRAST_REDUCTION);
    end
    MAX_COLOR = .80 - CONTRAST_REDUCTION;
    MIN_COLOR = .20 + CONTRAST_REDUCTION;
    SPATIAL_FREQUENCY = 0.2;
    HERTZ = 3;
    DURATION = 0.6;
    FRAMERATE = 60;
    %Create the video file we are going to make
    v = VideoWriter(FILENAME);
    v.FrameRate = FRAMERATE;
    open(v);
    for f = 1:round(FRAMERATE*DURATION)
        %Create sine wave with the phase_shift defined by HERTZ
        phase_shift = 2*pi*HERTZ/FRAMERATE*f;
        sine_wave = (MAX_COLOR+MIN_COLOR)/2 + (MAX_COLOR - MIN_COLOR)/2 .*(sin(phase_shift + SPATIAL_FREQUENCY*(1:SIZE*2)));
        %Turn it into a grayscale image of SIZE*SIZE in pixels
        frame_output = ones(SIZE*2) .* sine_wave;
        %Perform the desired rotation
        frame_output = imrotate(frame_output,ROTATION,'crop');
        %Crop out the black edges
        frame_output = frame_output(floor(SIZE/2):ceil(SIZE*1.5),floor(SIZE/2):ceil(SIZE*1.5));
        %Make sure it is the desired size (might be off by one pixel but that
        %should be fine)
        frame_output = frame_output(1:SIZE,1:SIZE);
        
        %Turn it into a circle
        centerY = round(SIZE/2);
        centerX = round(SIZE/2);
        % Next create the circle in the image.
        [columnsInImage, rowsInImage] = meshgrid(1:SIZE, 1:SIZE);
        circlePixels = ((rowsInImage - centerY).^2 + (columnsInImage - centerX).^2) <= (SIZE/2).^2;
        frame_output(~circlePixels) = 0.5;
        writeVideo(v,frame_output);
    end
    close(v)
end
