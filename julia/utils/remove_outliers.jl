#
#   Script Julia
#   Por Gabriel Ferreira.
#
#       Função para remoção dos outliers de um conjunto
#   de dados enquanto divide ele em blocos.
using  Statistics

#   Função responsável pela remoção dos outliers.
#   - data: vetor de dados (Dims = 1)
#   - blocksize: tamanho dos blocos.
#   - fs: frequência de coleta dos dados.
#   - iqr_mult: multiplicador para o intervalo interquartil usado para a definição
#   dos outliers.
function RemoveOutliers(data, time; blocksize = length(data), iqr_mult = 1.5)
    #   Vetor onde os blocos são armazenados após removido os outliers.
    res_data = [];
    res_time = [];

    #   Calcula o número de blocos.
    blocks = trunc(Int, size(data)[1]/blocksize);

    #   Lista os blocos.
    for i = 1:blocks
        #   Pega o conjunto de dados.
        vec_data = data[1 + ((i - 1) * blocksize):(i * blocksize)];
        vec_time = time[1 + ((i - 1) * blocksize):(i * blocksize)];
        
        #   Determina os quartis e o intervalo interquartil.
        Q1 = quantile(vec_data, 0.25);
        Q3 = quantile(vec_data, 0.75);
        IQR = Q3 - Q1;

        #   Verifica se os dados são ou não outliers.
        for j = 1:size(vec_data)[1]
            if ((vec_data[j] < (Q1 - (iqr_mult * IQR)) || (vec_data[j] > (Q3 + (iqr_mult * IQR)))))
                continue
            end

            push!(res_data, Float32(vec_data[j]))
            push!(res_time, vec_time[j])
        end
    end

    #   Pega os elementos que sobraram e cria um bloco com eles.
    if (size(data)[1] > blocksize * blocks)
        rest_data = data[1 + (blocksize * blocks):size(data)[1]]
        rest_time = time[1 + (blocksize * blocks):size(data)[1]]

        #   Determina os quartis e o intervalo interquartil.
        Q1 = quantile(rest_data, 0.25);
        Q3 = quantile(rest_time, 0.75);
        IQR = Q3 - Q1;

        #   Verifica se os dados são ou não outliers.
        for j = 1:size(rest_data)[1]
            if ((rest_data[j] < (Q1 - (iqr_mult * IQR)) || (rest_data[j] > (Q3 + (iqr_mult * IQR)))))
                continue
            end

            push!(res_data, Float32(rest_data[j]))
            push!(res_time, rest_time[j])
        end
    end

    #   Estrutura uma matriz de retorno.
    result = Array{Float32, 2}(undef, size(res_data)[1], 2)
    
    for i = 1:size(res_data)[1]
        result[i, 1] = res_time[i]
        result[i, 2] = res_data[i]
    end

    #   Retorna o resultado.
    return result
end