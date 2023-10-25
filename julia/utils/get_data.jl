#
#   Julia Script.
#   Por Gabriel Ferreira.
#
#       Organiza um conjunto de dados para ser usado
#   pela rede neural.

include("create_blocks.jl");

function GetData(channels; blocksize = 25)
    #   Divide os canais em blocos.
    #   - Vetor para registrar os canais.
    blocked_channels = []
    #   - Menor valor de blocos identificado.
    _ch_min = 100000000;

    #println(typeof(channels))
    #println(channels |> size)

    for channel in channels
        #println(type)
        alpha_wave = CreateBlocks(channel[1]; blocksize = blocksize);
        beta_wave = CreateBlocks(channel[2]; blocksize = blocksize);
        gamma_wave = CreateBlocks(channel[3]; blocksize = blocksize);

        _gp_min = size(alpha_wave)[1];
        if (size(beta_wave)[1] < _gp_min)
            _gp_min = size(beta_wave)[1]; 
        elseif (size(gamma_wave)[1] < _gp_min) 
            _gp_min = size(gamma_wave)[1]; 
        end

        block = Array{Float32, 3}(undef, blocksize, 3, _gp_min);

        for i = 1:blocksize
            for j = 1:_gp_min
                block[i, 1, j] = alpha_wave[j, i];
                block[i, 2, j] = beta_wave[j, i];
                block[i, 3, j] = gamma_wave[j, i];
            end
        end

        if (_gp_min < _ch_min)
            _ch_min = _gp_min;
        end

        #   Aloca o canal.
        push!(blocked_channels, block)
    end
    
    #   Cria uma array para salvar o resultante.
    result = Array{Float32, 4}(undef, 8, blocksize, 3, _ch_min);
    for i = 1:8
        for j = 1:blocksize
            for w = 1:3
                for b = 1:_ch_min
                    result[i, j, w, b] = blocked_channels[i][j, w, b];
                end
            end
        end
    end

    #   Retorna o resultado.
    return result;
end