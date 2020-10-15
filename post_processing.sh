

# build vrt
gdalbuildvrt slope.vrt slope_*_*.tif
gdalbuildvrt mrvbf.vrt mrvbf_*_*.tif
gdalbuildvrt mrrtf.vrt mrrtf_*_*.tif

# trim to match DEM extent
gdal_translate -projwin -32.0001389 47.0001389 61.0001389 -46.0001389 -projwin_srs EPSG:4326 slope.vrt slope_africa.tif
gdal_translate -projwin -32.0001389 47.0001389 61.0001389 -46.0001389 -projwin_srs EPSG:4326 mrvbf.vrt mrvbf_africa.tif
gdal_translate -projwin -32.0001389 47.0001389 61.0001389 -46.0001389 -projwin_srs EPSG:4326 mrrtf.vrt mrrtf_africa.tif

# COG
rio cogeo create slope_africa.tif cog_slope_africa.tif
rio cogeo create mrvbf_africa.tif cog_mrvbf_africa.tif
rio cogeo create mrrtf_africa.tif cog_mrrtf_africa.tif
