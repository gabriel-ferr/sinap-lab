#
#   Script Julia
#   Por Gabriel Ferreira.
#
#       Prepara o ambiente para ser utilizado pelos demais scripts
#   do Julia.

#   Importa o Pkg para download das referências.
import Pkg;

#   Usa o Pkg para importar as referências.
Pkg.add("DSP");
Pkg.add("Statistics");

Pkg.add("Flux");

Pkg.add("DataFrames");
Pkg.add("BSON");
Pkg.add("CSV");