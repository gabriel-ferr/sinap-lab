# Usando: https://docs.juliahub.com/DSP/OtML7/0.6.6/periodograms/
using DSP;
using DataFrames;
using CSV;
using Plots;
using Statistics;

include("julia/utils/remove_outliers.jl")

raw_data = CSV.read("raw/tarefa_1_4.csv", DataFrame);

fil_notch = Filters.iirnotch(65, 45; fs = 250.0)
#fil_lowpass_alpha = Lowpass(12; fs = 250.0)
#fil_highpass_alpha = Highpass(8; fs = 250.0)
#fil_method = Butterworth(4)

fil_data = filtfilt(fil_notch, raw_data[:, 1])
#fil_data = filt(digitalfilter(fil_lowpass_alpha, fil_method), fil_data)
#fil_data = filt(digitalfilter(fil_highpass_alpha, fil_method), fil_data)

spec = spectrogram(fil_data, 15;nfft=nextfastfft(600), fs=250.0)

freq_mean = []
alpha_power_mean = []
beta_power_mean = []
gamma_power_mean = []
for t = 1:size(spec.time)[1]
    power_freqs = spec.power[:, t] ./1000000
    freqs = spec.freq

    #   Calcula a frequência média.
    #   É uma média ponderada!
    f_mean_sum = []
    for f = 1:size(power_freqs)[1]
        push!(f_mean_sum, power_freqs[f] * freqs[f]);
    end

    f_mean = sum(f_mean_sum) / sum(power_freqs)

    push!(freq_mean, f_mean);

    alpha = []
    beta = []
    gamma = []

    for i = 1:size(power_freqs)[1]
        if (freqs[i] < 12.0)
            push!(alpha, power_freqs[i])
        elseif (freqs[i] < 30.0)
            push!(beta, power_freqs[i])
        elseif (freqs[i] < 70.0)
            push!(gamma, power_freqs[i])
        end
    end

    push!(alpha_power_mean, sum(alpha)/size(alpha)[1])
    push!(beta_power_mean, sum(beta)/size(beta)[1])
    push!(gamma_power_mean, sum(gamma)/size(gamma)[1])
end

println(spec.power |> size)

graph_1 = heatmap(spec.time, spec.freq[1:180], spec.power[1:180, :] ./1000000, c = :curl)
plot!(spec.time, freq_mean)
plot!(spec.time, alpha_power_mean)
plot!(spec.time, beta_power_mean)
plot!(spec.time, gamma_power_mean)

#   Normaliza as intensidades.
alpha_power_mean = alpha_power_mean ./ std(alpha_power_mean)
beta_power_mean = beta_power_mean ./ std(beta_power_mean)
gamma_power_mean = gamma_power_mean ./ std(gamma_power_mean)

#spec.power
#graph_1 = heatmap(spec.time, spec.freq[1:120], spec.power[1:120, :] ./1000000, c = :curl)
#plot!(spec.time, freq_mean)

graph_2 = plot(spec.time, alpha_power_mean)
plot!(spec.time, beta_power_mean)
plot!(spec.time, gamma_power_mean)


graph_3 = plot(spec.time, freq_mean)

plot(graph_1, graph_2, graph_3, layout=(3,1), size=(1024,1024))