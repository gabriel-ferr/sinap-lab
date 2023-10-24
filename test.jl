# Usando: https://docs.juliahub.com/DSP/OtML7/0.6.6/periodograms/
using DSP;
using DataFrames;
using CSV;
using Plots;

raw_data = CSV.read("raw/tarefa_1_1.csv", DataFrame);

fil_notch = Filters.iirnotch(65, 45; fs = 250.0)
fil_lowpass_alpha = Lowpass(12; fs = 250.0)
fil_highpass_alpha = Highpass(8; fs = 250.0)
fil_method = Butterworth(4)

fil_data = filtfilt(fil_notch, raw_data[:, 1])
fil_data = filt(digitalfilter(fil_lowpass_alpha, fil_method), fil_data)
fil_data = filt(digitalfilter(fil_highpass_alpha, fil_method), fil_data)

spec = spectrogram(fil_data, 25; fs=250.0)

plot(spec.freq[:], spec.power[:, 1], nfft)

spec.freq