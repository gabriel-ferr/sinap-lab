#
#   Script Julia
#   Por Gabriel Ferreira.
#
#       Separa os dados em blocos de tamanho igual.

#   - Função responsável por criar os blocos.
#   
using  Statistics;

function CreateBlocks(data; blocksize = 25, normalize = false)
    #   Calcula o número de blocos que devem ser gerados.
    blocks = trunc(Int, size(data)[1]/blocksize);

    #   Cria um vetor para armazenar o conjutno de dados.
    result = Array{Float32, 2}(undef, blocks, blocksize);

    #   Lista os dados preenchendo a Array de resultados.
    point = 1;
    for i = 1:blocks
        for j = 1:blocksize
            result[i, j] = data[point];
            point = point + 1;
        end
    end

    #   Normaliza se configurado para isso.
    if (normalize)
        #   Normaliza por bloco.
        for i = 1:blocks
            _bs = result[i, :];
            normalized = (_bs .- mean(_bs)) ./ std(_bs);
            #   Substituí os valores.
            for j = 1:blocksize
                result[i, j] = normalized[j];
            end
        end
    end

    #   Retorna o resultado.
    return result;
end