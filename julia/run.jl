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

#   Processa inicialmente os dados por canal.
for ch = 1:size(raw_data)[2]
    #   - Pega o valor do canal.
    raw_channel = raw_data[:, ch];

    #   - Aplica o filtro notch para suavilizar ruídos de ambiente.
    #       Foi suposto ruídos na faixa de 45-65Hz, ou seja, nas
    #   proximidades da frequência da rede elétrica.
    filt_data = filtfilt(filt_notch, raw_channel);

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

    #   - Calcula os espectrogramas dos dados a fim de obter a intensidades.
    #   Configura para processar a transformada de Fourier de 25 em 25 elementos.
    spec_alpha = spectrogram(filt_alpha[:, 2], 25; fs=250.0);
    spec_beta = spectrogram(filt_alpha[:, 2], 25; fs=250.0);
    spec_gamma = spectrogram(filt_alpha[:, 2], 25; fs=250.0);

    #   Organiza o PSD para as ondas alfa:
    #   - Pega as intensidades para 0 Hz, 10 Hz e 20 Hz e soma os vetores.
    #       A ideia é pegar as intensidade da faixa de 8-12Hz filtradas dentro
    #   desse espectro.
    #   1 = 0.0 Hz
    #   2 = 10.0 Hz
    #   3 = 20.0 Hz
    psd_alpha_result = spec_alpha.power[1, :] + spec_alpha.power[2, :] + spec_alpha.power[3, :]
    psd_df_alpha = DataFrame(;t = spec_alpha.time, p = psd_alpha_result);

    #   Organiza o PSD para as ondas beta:
    #   - Pega as intensidades para 10 Hz, 20 Hz e 30 Hz e soma os vetores.
    #       A ideia é pegar as intensidade da faixa de 8-12Hz filtradas dentro
    #   desse espectro.
    #   2 = 10.0 Hz
    #   3 = 20.0 Hz
    #   4 = 30.0 Hz
    psd_beta_result = spec_alpha.power[2, :] + spec_alpha.power[3, :] + spec_alpha.power[4, :]
    psd_df_beta = DataFrame(;t = spec_alpha.time, p = psd_beta_result);

    #   Organiza o PSD para as ondas gamma:
    #   - Pega as intensidades para 30 Hz, 40 Hz, 50 Hz, 60 Hz e 70 Hz e soma os vetores.
    #       A ideia é pegar as intensidade da faixa de 8-12Hz filtradas dentro
    #   desse espectro.
    #   4 = 30.0 Hz
    #   5 = 40.0 Hz
    #   6 = 50.0 Hz
    #   7 = 60.0 Hz
    #   8 = 70.0 Hz
    psd_gamma_result = spec_alpha.power[4, :] + spec_alpha.power[5, :] + spec_alpha.power[6, :] + spec_alpha.power[7, :] + spec_alpha.power[8, :]
    psd_df_gamma = DataFrame(;t = spec_alpha.time, p = psd_gamma_result);

    #   Salva os PSD na pasta indicada.
    CSV.write(ARGS[3] * "/spec_alpha_" * string(ch) * ".csv", psd_df_alpha);
    CSV.write(ARGS[3] * "/spec_beta_" * string(ch) * ".csv", psd_df_beta);
    CSV.write(ARGS[3] * "/spec_gamma_" * string(ch) * ".csv", psd_df_gamma);

    #   Salva a série temporal do canal para cada uma das ondas.
    alpha_df = DataFrame(;t = filt_alpha[1], v = filt_alpha[2])
    beta_df = DataFrame(;t = filt_beta[1], v = filt_beta[2])
    gamma_df = DataFrame(;t = filt_gamma[1], v = filt_gamma[2])

    CSV.write(ARGS[3] * "/time_" * string(ch) * "_alpha.csv", alpha_df);
    CSV.write(ARGS[3] * "/time_" * string(ch) * "_beta.csv", beta_df);
    CSV.write(ARGS[3] * "/time_" * string(ch) * "_gamma.csv", gamma_df);

    #   
end