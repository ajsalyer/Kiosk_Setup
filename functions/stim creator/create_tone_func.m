function create_tone_func(frequency, duration, wavName, rampDuration)
%create_tone_func  Write a pure tone to <wavName>.wav (and play it).
%
%   create_tone_func(frequency, duration, wavName) -- Hz, seconds, file stem.
%   create_tone_func(..., rampDuration) sets the raised-cosine onset/offset
%   ramp in seconds (default 0.005). Without a ramp the waveform starts and
%   stops abruptly, which is heard as a click at tone onset and offset --
%   a broadband transient the animal could respond to instead of the pitch.
%   Pass 0 for the old unramped behaviour.

  if nargin < 4 || isempty(rampDuration), rampDuration = 0.005; end

  % Generate sine wave samples at desired frequency
  sampling_rate = 44100; % Adjust based on your setup (common value)
  t = 0:1/sampling_rate:duration;
  tone = sin(2*pi*frequency*t);

  % Raised-cosine ramps at both ends (never longer than half the tone).
  nRamp = min(round(rampDuration*sampling_rate), floor(numel(tone)/2));
  if 0 < nRamp
      ramp = 0.5*(1 - cos(pi*(0:nRamp-1)/nRamp));
      tone(1:nRamp) = tone(1:nRamp) .* ramp;
      tone(end-nRamp+1:end) = tone(end-nRamp+1:end) .* fliplr(ramp);
  end

  % Play the generated sound
  sound(tone, sampling_rate);

  audiowrite(append(wavName, '.wav'), tone, sampling_rate);
end
