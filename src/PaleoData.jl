module PaleoData
using DataFrames, XLSX, Downloads, ExcelFiles, CSV, Revise, ZipFile, NCDatasets, DelimitedFiles, GZip
export loadOsman2021, loadThornalley2018, loadOcean2k, loadLMR, loadHadISST


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

println(datadir())
#datadir() = cd("../data")

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
function download(url::String, file::String)
    url = joinpath(url, file)
    !isdir(datadir()) && mkpath(datadir())
    filename = datadir(file)
    !isfile(filename) && Downloads.download(url, filename)
    split = splitext(filename)
    if split[2] == ".gz" && !isfile(split[1])
        println("unzipping a .gz file") 
        return gzip(filename)
    else
        return split[1]
    end
    
end


"""
    function read_data_Osman2021()

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

function loadLMR(varname::String)
    println("big file, slow download (a couple minutes?)")
    url = "https://www.ncei.noaa.gov/pub/data/paleo/reconstructions/tardif2019lmr/v2_0/"
    filename = varname * "_MCruns_ensemble_mean_LMRv2.0.nc"
    filename = download(url, filename) 
    nc = NCDataset(filename)
    return nc 
end

function loadHadISST()
    println("big file, slow download (a couple minutes?)")
    url = "https://www.metoffice.gov.uk/hadobs/hadisst/data"
    filename = "HadISST_sst.nc.gz"
    filename = download(url, filename)
    nc = NCDataset(filename)
    return nc
end



end
    
