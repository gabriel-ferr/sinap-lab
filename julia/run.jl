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
#       2 - diretório dos arquivos de dados .CSV nomeados como: <ID_IND>_<TASK>.csv,
#   onde <ID_IND> é o número de identificação do indivíduo que particiou do teste e
#   <TASK> o número de identificação da tarefa realizada.
#
#   - 23/10/2023
#       Executa a estrutura a partir de uma pasta, carregando os arquivos presentes nela,
#   filtrando e extraindo dados. Esses dados por exportados para arquivos .CSV
#   em uma pasta determinada previamente.

#   Referências utilizadas.
using DSP;
using Statistics;
using Flux;
using DataFrames;
using CSV;
using BSON: @load;

#   Pega os arquivos que devem ser tratados.
