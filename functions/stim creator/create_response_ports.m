%Specify how large you want the image to be in pixels first, then the 3
%code RGB value of the lightest color, (higher numbers), and then the RGB
%value of the darkest color (lower numbers), then the spatial frequency,
%then the rotation, and finally, what you want to call the file
function create_response_ports(SIZE,CIRCLE_COLOR,BACKGROUND_COLOR,FILENAME)
    %Create a color image
    image_output = ones(SIZE,SIZE,3);
    for background_colors = 1:3
        image_output(:,:,background_colors) = BACKGROUND_COLOR(background_colors);
    end

    %Turn it into a circle
    centerY = round(SIZE/2);
    centerX = round(SIZE/2);
    % Next create the circle in the image.
    [columnsInImage, rowsInImage] = meshgrid(1:SIZE, 1:SIZE);
    circlePixels = ((rowsInImage - centerY).^2 + (columnsInImage - centerX).^2) <= (SIZE/2).^2;
    
    for circle_colors = 1:3
        one_layer = image_output(:,:,circle_colors);
        one_layer(circlePixels) = CIRCLE_COLOR(circle_colors);
        image_output(:,:,circle_colors) = one_layer;
    end

    %Save it as whatever the input filename is
    imwrite(image_output,FILENAME);
end
