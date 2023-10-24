#
#   Script Julia
#   Por Gabriel Ferreira
#
#   Execução:
#
#       julia `run.jl` <1> <2>
#
#       1 - arquivo .BSON que contém o modelo treinado da rede neural utilizada durante
#   o programa.
#
#       2 - arquivo .CSV contendo os dados de uma tarefa.
#
#   - 23/10/2023
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

#   Filtros aplicados.
#   - Filtro notch para remover ruídos da rede/de ambiente.
filt_notch = Filters.iirnotch(65, 45; fs = 250.0)

#   - Método de aplicação do filtro.
filt_method = Butterworth(4)

#   - Filtros passa-alta e passa-baixa para onda alfa.
filt_lowpass_alpha = Lowpass(12; fs = 250.0)
filt_highpass_alpha = Highpass(8; fs = 250.0)

#   - Filtros passa-alta e passa-baixa para onda beta.
filt_lowpass_beta = Lowpass(30; fs = 250.0)
filt_highpass_beta = Highpass(12; fs = 250.0)

#   - Filtros passa-alta e passa-baixa para onda gamma.
filt_lowpass_gamma = Lowpass(70; fs = 250.0)
filt_highpass_gamma = Highpass(30; fs = 250.0)

#   Lê o arquivo de dados.
raw_data = CSV.read(ARGS[2], DataFrame);

#   Processa inicialmente os dados por canal.
for ch = 1:size(raw_data)[2]
    #   Pega o valor do canal.
    raw_channel = raw_data[:, ch]

    
end