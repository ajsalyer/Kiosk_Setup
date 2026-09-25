function create_tone_func(frequency, duration, wavName)
  % Generate sine wave samples at desired frequency
  sampling_rate = 44100; % Adjust based on your setup (common value)
  t = 0:1/sampling_rate:duration;
  tone = sin(2*pi*frequency*t);
  
  % Play the generated sound
  sound(tone, sampling_rate);

  audiowrite(append(wavName, '.wav'), tone, sampling_rate);
end