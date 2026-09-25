function outPath = mgloSaveFigure(fh, name, opts)
%mgloSaveFigure  Save an mGLO analysis figure to disk as a .jpg.
%
%   mgloSaveFigure(fh, name) writes figure fh to <repo>/analysis/figures as
%   a JPEG. Every figure produced by the mGLO analysis code goes through
%   here, so the output format is set in exactly one place.
%
%   mgloSaveFigure(fh, name, opts) honours:
%     opts.save     true                      set false to plot without saving
%     opts.savedir  <repo>/analysis/figures   destination folder
%     opts.tag      ''                        suffix, e.g. a session date or
%                                             subject, appended to the file
%                                             name so sessions do not
%                                             overwrite each other
%     opts.dpi      150                       resolution passed to print
%
%   Returns the full path written, or '' when saving is off or fails.
%   Saving never interrupts an analysis run: a failure warns and continues.

outPath = '';
if nargin < 3 || isempty(opts) || ~isstruct(opts), opts = struct(); end
if isfield(opts, 'save') && ~opts.save, return; end
if isempty(fh) || ~isgraphics(fh, 'figure'), return; end

if isfield(opts, 'savedir') && ~isempty(opts.savedir)
    savedir = opts.savedir;
else
    % This file lives at <repo>/analysis/all analysis/, so up two = analysis.
    analysisDir = fileparts(fileparts(mfilename('fullpath')));
    savedir = fullfile(analysisDir, 'figures');
end

if isfield(opts, 'tag'), tag = opts.tag; else, tag = ''; end
if isfield(opts, 'dpi') && ~isempty(opts.dpi), dpi = opts.dpi; else, dpi = 150; end

% Build a filesystem-safe stem: letters, digits, underscore and dash only.
stem = regexprep(char(name), '[^A-Za-z0-9_\-]+', '_');
stem = regexprep(stem, '^_+|_+$', '');
if isempty(stem), stem = 'figure'; end
if ~isempty(tag)
    safeTag = regexprep(char(tag), '[^A-Za-z0-9_\-]+', '_');
    safeTag = regexprep(safeTag, '^_+|_+$', '');
    if ~isempty(safeTag), stem = [stem '_' safeTag]; end
end

try
    if ~isfolder(savedir), mkdir(savedir); end
    outPath = fullfile(savedir, [stem '.jpg']);
    print(fh, outPath, '-djpeg', sprintf('-r%d', dpi));
catch ME
    warning('mgloSaveFigure:failed', 'Could not save "%s" as .jpg: %s', ...
            stem, ME.message);
    outPath = '';
end
end
