using PaleoData, Test

@testset "PaleoData.jl" begin
    osman = loadOsman2021("LGMR_SST_climo.nc")
    thornalley = loadThornalley2018()
    oc2k = loadOcean2k()
    lmr = loadLMR("sst")
    hadisst = loadHadISST()
    steinhilber = loadSteinhilber2009()
    gao = loadGao2008()
    epica = loadEPICA800kCO2()
    lund2015 = loadLund2015() 
end

