module PaleoData
using DataFrames, XLSX, Downloads, CSV, Revise, ZipFile, NCDatasets, DelimitedFiles, GZip
#load data functions 
export loadOsman2021, loadThornalley2018, loadOcean2k, loadLMR, loadHadISST,
    loadOcean2kBinned, loadSteinhilber2009, loadGao2008, loadEPICA800kCO2, loadLund2015
#some helper functions 
export makeNaN, splitfixedwidth, ptobserve

projectdir() = dirname(dirname(pathof(PaleoData)))
projectdir(s::String) = joinpath(projectdir(), s)

function datadir(s=nothing)
    path = joinpath(projectdir(), "data")
    ! isdir(path) && mkdir(path)
    if isnothing(s)
        return path
    else
        return joinpath(path, s)
    end
    
end

"""
function unzip(file,exdir="")

credit to: https://discourse.julialang.org/t/how-to-extract-a-file-in-a-zip-archive-without-using-os-specific-tools/34585/5
"""
function unzip(file,exdir="")
    fileFullPath = isabspath(file) ?  file : joinpath(pwd(),file)
    basePath = dirname(fileFullPath)
    outPath = (exdir == "" ? basePath : (isabspath(exdir) ? exdir : joinpath(pwd(),exdir)))
    isdir(outPath) ? "" : mkdir(outPath)
    zarchive = ZipFile.Reader(fileFullPath)
    for f in zarchive.files
        fullFilePath = joinpath(outPath,f.name)
        if (endswith(f.name,"/") || endswith(f.name,"\\"))
            mkdir(fullFilePath)
        else
            write(fullFilePath, read(f))
        end
    end
    close(zarchive)
end
function gzip(file)
    unzipped_name = splitext(file)[1]
    GZip.open(file, "r") do io
        open(unzipped_name, "w") do out
            write(out, read(io))
        end
    end
    return unzipped_name
end


"""
function download(url::String, filename::String)
"""
function download(url::String, file::String; join = true)
    url = join ? joinpath(url, file) : url 
    !isdir(datadir()) && mkpath(datadir())
    filename = datadir(file)
    !isfile(filename) && Downloads.download(url, filename)
    split = splitext(filename)
    if split[2] == ".gz" && !isfile(split[1])
        println("unzipping a .gz file") 
        return gzip(filename)
        rm(filename) 
    elseif split[2] == ".zip" && !isdir(split[1])
        println("unzipping")
        unzip(filename)
        rm(filename)
        return split[1]
    elseif split[2] ∈ [".gz", ".zip"]
        return split[1]
    else
        return filename
    end
    
end


"""
    function loadOsman2021()

    Read proxy data archive from NCEI and Osman et al. 2021

# Arguments
- file: file in tree at baseurl, good files are 
        LGMR_SST_climo.nc
        LGMR_SAT_climo.nc
        full ensembles (e.g. LGMR_SAT_ens.nc) will take a long time (3GB download)
# Output
- `df::DataFrame`: tabular data from Excel spreadsheet
# BRYNN STOLE THIS FROM JAKE in DEGLACIAL_POWERLAW #
(and slightly modded it) 
"""
function loadOsman2021(filename::String)
    baseurl = "https://www.ncei.noaa.gov/pub/data/paleo/reconstructions/osman2021"
    filename = download(baseurl, filename) 
    ds = Dataset(filename)
    return ds 
end

"""
function loadThornalley2018()

Loads in sortable silt records from KNR-178-48JPC, KNR-178-56JPC
"""
function loadThornalley2018()
    filename = "41586_2018_7_MOESM2_ESM.xlsx"
    url = "https://static-content.springer.com/esm/art%3A10.1038%2Fs41586-018-0007-4/MediaObjects"
    filename = download(url, filename)

    # get the sheet names
    xf = XLSX.readxlsx(filename)
    sheetname = XLSX.sheetnames(xf)[end]
    xf1 = xf[sheetname * "!C3:E95"]
    xf1[typeof.(xf1) .!= Float64] .= NaN
    xf1 = convert(Matrix{Float64}, xf1) 
    df1 = DataFrame(xf1, ["age [CE]", "mean SS (mm)", "smooth"])

    xf2 = xf[sheetname * "!I3:K71"]
    xf2[typeof.(xf2) .!= Float64] .= NaN
    xf2 = convert(Matrix{Float64}, xf2) 
    df2 = DataFrame(xf2, ["age [CE]", "mean SS (mm)", "smooth"])

    names = ["KNR-178-56JPC", "KNR-178-48JPC"] 
    return Dict(zip(names, [df1,df2])) 
end

"""
function loadOcean2k()

Loads in names and locations of Ocean2k cores 
"""
function loadOcean2k()
    url = "https://www.ncei.noaa.gov/pub/data/paleo/pages2k"
    filename = "Ocean2kLR2015sst.xlsx"
    filename = download(url, filename)
    xl = XLSX.readxlsx(filename)
    sheetnames = XLSX.sheetnames(xl) 
    locsheet = xl[sheetnames[1]]
    names = locsheet["A4:A60"]
    lats = locsheet["B4:B60"]
    lons = locsheet["C4:C60"]
    depths = locsheet["D4:D60"]
    data = xl[sheetnames[4]]["A1:DJ566"]
    return DataFrame(hcat(names, lats, lons, depths), ["name", "lat", "lon", "depth"]), DataFrame(data[2:end, :], data[1, :])
end

"""
function loadOcean2kBinned()

load in the binned stdev, binned SST values, and binned ages 
"""
function loadOcean2kBinned()
    url = "https://www.ncei.noaa.gov/pub/data/paleo/pages2k/"
    filename = "Ocean2kLR2015.zip"
    filename = download(url, filename) #should automatically unzip
    path1 = joinpath(filename, "composites_shipped/binnm_nm.csv")
    path2 = joinpath(filename, "composites_shipped/binnNm.csv")
    path3 = joinpath(filename, "composites_shipped/stimem.csv") 
    return readdlm(path1), readdlm(path2), readdlm(path3) 
end


"""
function loadLMR(varname::String)

load in LMR ensemble mean 
"""
function loadLMR(varname::String)
    println("big file, slow download (a couple minutes?)")
    url = "https://www.ncei.noaa.gov/pub/data/paleo/reconstructions/tardif2019lmr/v2_0/"
    filename = varname * "_MCruns_ensemble_mean_LMRv2.0.nc"
    filename = download(url, filename) 
    nc = NCDataset(filename)
    return nc 
end

"""
function loadHadISST()

load in HadISST dataset 
"""
function loadHadISST()
    url = "https://www.metoffice.gov.uk/hadobs/hadsst4/data/netcdf/"
    filename = "HadSST.4.0.1.0_median.nc"
    filename = download(url, filename)
    nc = NCDataset(filename)
    return nc
end

"""
function loadSteinhilber2009()

load Steinhilber total solar insolation CE dataset 
"""
function loadSteinhilber2009()
    url = "https://www.ncei.noaa.gov/pub/data/paleo/climate_forcing/solar_variability"
    filename = "steinhilber2009tsi.txt"
    filename = download(url, filename)
    #df = CSV.read(filename, DataFrame, header = 109)
    dlm = readdlm(filename)
    mat = convert(Matrix{Float64}, dlm[85:end, begin:3])
    names = dlm[84, begin:3]
    return DataFrame(mat, names)
end

"""
function loadGao2008()

load Gao total stratospheric sulfate injection CE dataset
"""
function loadGao2008()
    url = "https://climate.envsci.rutgers.edu/IVI2/"
    filename = "IVI2TotalInjection_501-2000Version2.txt"
    filename = download(url, filename)
    dlm = readdlm(filename)
    mat = convert(Matrix{Float64}, dlm[10:end, begin:4])
    names = dlm[9, begin:4]
    return DataFrame(mat, names) 
end

"""
function loadEPICA800kCO2()

load EPICA CO2 record 
"""
function loadEPICA800kCO2()
    url = "https://www.ncei.noaa.gov/pub/data/paleo/icecore/antarctica/epica_domec/"
    filename = "edc-monnin-co2-2008-noaa.txt"
    filename = download(url, filename)
    dlm = readdlm(filename)
    mat = convert(Matrix{Float64}, dlm[279:end, 1:4])
    names = dlm[278, 1:4]
    return DataFrame(mat, names) 
end

function loadLund2015()
    url = "https://www.ncei.noaa.gov/pub/data/paleo/contributions_by_author/lund2015/"
    ggccores = "ggc" .* string.([14,22,30,33,36,63,78,90,125])
    jpccores = "jpc" .* string.([17,20,42])
    cores = Symbol.(vcat(ggccores, jpccores))
    filenames = NamedTuple{Tuple(cores)}("lund2015" .* string.(cores) .* ".txt")

    #each .txt file gives "northernmost lat, southernmost lat", but they are the same
    locs = Vector{Tuple}(undef, length(cores))
    
    for (i, c) in enumerate(cores)
        filename = PaleoData.download(url, filenames[c])
        dlm = readdlm(filename, skipstart = 59)
        lat = dlm[1, 4]
        lon = dlm[3,4]
        depth = -dlm[5,3]
        locs[i] = (lat, lon, depth)
    end
    return NamedTuple{Tuple(cores)}(locs) 
    
end


function makeNaN(x::Array{Union{Missing, T}}) where T 
    x[ismissing.(x)] .= NaN
    return convert(Array{T}, x) 
end

"""
I wrote this, and its lovely, but try readdlm first... 
"""
function splitfixedwidth(str::String)
    notspace = findall(x->x != ' ', str)
    continuous = diff(notspace)
    breakpoints = vcat(0, findall(x->x!=1, continuous))
    indices = [notspace[breakpoints[i]+1:breakpoints[i+1]] for i in 1:length(breakpoints)-1]
    return [parse(Float64, str[i]) for i in indices]
end

function ptobserve(fld::Array{T, N}, lon, lat, lonpt, latpt) where {T, N}
    lon_ind = findmin(abs.(lon .- lonpt))[2]
    lat_ind = findmin(abs.(lat .- latpt))[2]
    return fld[lon_ind, lat_ind, :]
end

end
    
