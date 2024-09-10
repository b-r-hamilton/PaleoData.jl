# PaleoData.jl
[![Build Status](https://github.com/b-r-hamilton/PaleoData.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/b-r-hamilton/PaleoData.jl/actions/workflows/CI.yml?query=branch%3Amain)

Repository to access common paleoclimate/paleoceanography datasets in a Julia readable format 

```
julia> thornalley = loadThornalley2018()
Dict{String, DataFrames.DataFrame} with 2 entries:
  "KNR-178-48JPC" => 69×3 DataFrame…
  "KNR-178-56JPC" => 93×3 DataFrame…
```


