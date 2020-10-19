# dem-derivative


This repo includes scripts used to generate the DEM derivative products for Digital Earth Africa.

These products are generated from the Shuttle Radar Topography Mission (SRTM) v3.0 Digital Elevation Model and are provided at 30 m resolution in WGS 84 / NSIDC EASE-Grid 2.0 Global projection (EPSG:6933).

Following data layers are included:
1. Percent Slope
2. Multi-resolution Valley Bottom Flatness (MrVBF)
3. Multi-resolution Ridge Top Flatness (MrRTF)


### Percent Slope
Generated using [gdaldem](https://gdal.org/programs/gdaldem.html).

### MrVBF & MrRTF
Generated using [SAGA GIS tool (Version: 2.3.1)](http://www.saga-gis.org/saga_tool_doc/2.3.0/ta_morphometry_8.html) with default parameters.
A r5a.xlarge (4	vCPU, 32 GB momery) EC2 instance is used.

