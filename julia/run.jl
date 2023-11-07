#
#   Script Julia
#   Por Gabriel Ferreira
#
#   Execução:
#
#       julia `run.jl` <1> <2> <3>
#
#       `run.jl` indica o caminho até o arquivo, no caso: sinap-lab/julia/run.jl
#
#       1 - arquivo .BSON que contém o modelo treinado da rede neural utilizada durante
#   o programa.
#
#       2 - arquivo .CSV contendo os dados de uma tarefa.
#
#       3 - pasta onde todos os resultados serão salvos.
#
#       Executa a estrutura a partir de uma pasta, carregando os arquivos presentes nela,
#   filtrando e extraindo dados. Esses dados são exportados para arquivos .CSV
#   em uma pasta determinada previamente.

#   Referências utilizadas.
using DSP;
using Statistics;
using Flux;
using DataFrames;
using CSV;
using BSON: @load;

#   Importa o modelo a ser usado para a rede neural.
@load ARGS[1] model;

#   Incluí os scripts auxiliares.
include("utils/remove_outliers.jl");
include("utils/get_data.jl");

#   Filtros aplicados.
#   - Filtro notch para remover ruídos da rede/de ambiente.
filt_notch = Filters.iirnotch(65, 45; fs = 250.0);

#   - Método de aplicação do filtro.
filt_method = Butterworth(4);

#   - Filtros passa-alta e passa-baixa para onda alfa.
filt_lowpass_alpha = Lowpass(12; fs = 250.0);
filt_highpass_alpha = Highpass(8; fs = 250.0);

#   - Filtros passa-alta e passa-baixa para onda beta.
filt_lowpass_beta = Lowpass(30; fs = 250.0);
filt_highpass_beta = Highpass(12; fs = 250.0);

#   - Filtros passa-alta e passa-baixa para onda gamma.
filt_lowpass_gamma = Lowpass(70; fs = 250.0);
filt_highpass_gamma = Highpass(30; fs = 250.0);

#   Lê o arquivo de dados.
raw_data = CSV.read(ARGS[2], DataFrame);

#   Vetor para registro dos canais.
channels = []

#   Processa inicialmente os dados por canal.
for ch = 1:size(raw_data)[2]
    #   - Pega o valor do canal.
    raw_channel = raw_data[:, ch];

    #   - Aplica o filtro notch para suavilizar ruídos de ambiente.
    #       Foi suposto ruídos na faixa de 45-65Hz, ou seja, nas
    #   proximidades da frequência da rede elétrica.
    filt_data = filtfilt(filt_notch, raw_channel);

    #   - Faz um espectrograma do canal.
    spec = spectrogram(filt_data, 15; nfft=nextfastfft(600), fs=250.0);

    #   - Médias do espectrograma.
    freq_mean = []
    alpha_power_mean = []
    beta_power_mean = []
    gamma_power_mean = []

    #   - Abre o espectrograma.
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

    #   - Gera um heatmap do espectrograma.
    #   Linhas fixas de frequência.
    top_line = []
    gamma_line = []
    beta_line = []
    alpha_line = []
    for _ in spec.time
        push!(top_line, 70)
        push!(gamma_line, 30)
        push!(beta_line, 12)
        push!(alpha_line, 8)
    end

    graph_spec = heatmap(spec.time, spec.freq[1:170], spec.power[1:170, :] ./1000000, c = :curl)

    #   - Separa os espectros da onda.
    filt_alpha = filt(digitalfilter(filt_lowpass_alpha, filt_method), filt_data);
    filt_alpha = filt(digitalfilter(filt_highpass_alpha, filt_method), filt_alpha);

    filt_beta = filt(digitalfilter(filt_lowpass_beta, filt_method), filt_data);
    filt_beta = filt(digitalfilter(filt_highpass_beta, filt_method), filt_beta);

    filt_gamma = filt(digitalfilter(filt_lowpass_gamma, filt_method), filt_data);
    filt_gamma = filt(digitalfilter(filt_highpass_gamma, filt_method), filt_gamma);

    #   - Gera um conjunto de valores temporais, já que eles não são informados
    #   pelo programa de coleta de dados.
    time = range(0, (size(filt_data)[1]/250.0), size(filt_data)[1]);

    #   - Remove os outliers.
    filt_alpha = RemoveOutliers(filt_alpha, time; blocksize = 250)
    filt_beta = RemoveOutliers(filt_beta, time; blocksize = 250)
    filt_gamma = RemoveOutliers(filt_gamma, time; blocksize = 250)

    #   Salva a série temporal do canal para cada uma das ondas.
    alpha_df = DataFrame(;t = filt_alpha[:, 1], v = filt_alpha[:, 2]);
    beta_df = DataFrame(;t = filt_beta[:, 1], v = filt_beta[:, 2]);
    gamma_df = DataFrame(;t = filt_gamma[:, 1], v = filt_gamma[:, 2]);

    CSV.write(ARGS[3] * "/time_" * string(ch) * "_alpha.csv", alpha_df);
    CSV.write(ARGS[3] * "/time_" * string(ch) * "_beta.csv", beta_df);
    CSV.write(ARGS[3] * "/time_" * string(ch) * "_gamma.csv", gamma_df);

    #   Aloca os dados no vetor de canais.
    push!(channels, (filt_alpha[:, 2], filt_beta[:, 2], filt_gamma[:, 2]))
end

#   Carrega os dados a partir dos canais.
data = GetData(channels; blocksize = 200);

#   Joga os dados no modelo.
model_result = model(data);

#   Aloca o resultado do modelo em um DataFrame.
model_df = DataFrame(;Repulsivo=model_result[1,:], Neutro=model_result[2,:], Fofo=model_result[3,:]);

#   Salva o DataFrame.
CSV.write(ARGS[3] * "/result.csv", model_df);
