import Pkg; Pkg.activate("../")
using PaleoData, Test, Revise

@testset "PaleoData.jl" begin
    osman = loadOsman2021("LGMR_SST_climo.nc")
    thornalley = loadThornalley2018()
    oc2k = loadOcean2k()
    lmr = loadLMR("sst")
    hadisst = loadHadISST()
end

