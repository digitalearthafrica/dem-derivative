
# Process DEM into tiled derivative products
# All calculations are done in EPSG:6933 and 30x30 m pixels

# Runs on a VM with gdal and saga 


export AWS_NO_SIGN_REQUEST=YES

# input dem
dem="/vsis3/deafrica-data/ancillary/dem/srtm_africa.tif";

# define output size and tiles in 6933
# size is chosen to cover DEM extent with a regular grid
xfs=301320;
yfs=357210;
# tiling; tile size is chosen to match multi-resolution calculations
xs=21870;
ys=21870;
# buffer; size is chosen to avoid tile edge effect in multi-resolution calculations 
buffer=2430; #$((xs/9));
# number of tiles
nx=$((xfs/xs));
if (($((nx*xs))<$xfs)); then nx=$((nx+1)); fi
ny=$((yfs/ys));
if (($((ny*ys))<$yfs)); then ny=$((ny+1)); fi
# output coordinate in m
xf0=-3134700;
yf0=5394600;
xres=30;
yres=-30;

echo "tile size" $xs $ys;
echo "number of tiles" $nx $ny;


startx=1;
starty=1;

#
# ==============================================

# loop through tiles
for xi in $(seq $startx $nx); do
    for yi in $(seq $starty $ny); do

	# output name
        outname_mrvbf="mrvbf_${xi}_${yi}.tif"
	outname_mrrtf="mrrtf_${xi}_${yi}.tif"
	outname_slope="slope_${xi}_${yi}.tif"
        # break if done
        if [ -f $outname_mrvbf ]; then 
            continue;
        fi
	echo $outname_mrvbf;

	# buffered boundary
	x0=$(((xi-1)*xs-buffer));
	y0=$(((yi-1)*ys-buffer));
	x1=$((x0+xs+buffer*2));
	y1=$((y0+ys+buffer*2));
	#echo "buffered window:" $x0 $y0 $x1 $y1;
	
	xoff=$x0;
	trim_xoff=$buffer;
        yoff=$y0;
        trim_yoff=$buffer;
        xsize=$((x1-xoff));
        trim_xsize=$((xsize-trim_xoff-buffer));
        ysize=$((y1-yoff));
        trim_ysize=$((ysize-trim_yoff-buffer));

	
	#echo $xoff $yoff $xsize $ysize;
	extent="$((xf0+xoff*xres)) $((yf0+(yoff+ysize)*yres)) $((xf0+(xoff+xsize)*xres)) $((yf0+yoff*yres))";
	# extract buffered dem
	cmd="gdalwarp -r bilinear -t_srs EPSG:6933 -tr $xres $yres -te $extent -te_srs EPSG:6933 $dem subdem.tif";
	$cmd;

	# processing derivatives

        # slope
        cmd="gdaldem slope subdem.tif subdem_slope.tif -p -compute_edges";
	$cmd;

        # MrVBF and MrRTF
        # convert to saga format        
        saga_cmd io_gdal 0 -GRIDS "DEM.sgrd" -FILES "subdem.tif" -TRANSFORM 1 -RESAMPLING 0;
        # mvvbf
        saga_cmd ta_morphometry 8 -DEM "DEM.sgrd" -MRVBF "MrVBF.sgrd" -MRRTF "MrRTF.sgrd" -T_SLOPE 16 -T_PCTL_V 0.400000 -T_PCTL_R 0.350000 -P_SLOPE 4.000000 -P_PCTL 3.000000 -UPDATE 1 -CLASSIFY 0 -MAX_RES 0.5;
        # convert to geotiff
        saga_cmd io_gdal 1 -GRIDS "MrVBF.sgrd" -FILE "subdem_mrvbf.tif" -FORMAT 1 -TYPE 3 -SET_NODATA 0 -NODATA 3.000000;
        saga_cmd io_gdal 1 -GRIDS "MrRTF.sgrd" -FILE "subdem_mrrtf.tif" -FORMAT 1 -TYPE 3 -SET_NODATA 0 -NODATA 3.000000;
	# clean up intermediate results
        rm -f DEM.* MrVBF.* MrRTF.*;

        # add projection
        gdal_edit.py -a_srs EPSG:6933 subdem_mrvbf.tif;
	gdal_edit.py -a_srs EPSG:6933 subdem_mrrtf.tif;
		
	# trim to remove buffer
	#co="-co COMPRESS=LZW -co TILED=YES -co BLOCKXSIZE=512 -co BLOCKYSIZE=512"
	co="-co TILED=YES -co BLOCKXSIZE=512 -co BLOCKYSIZE=512";
	outname="output_${xi}_${yi}.tif";
	cmd="gdal_translate -a_nodata -32768 $co -srcwin $trim_xoff $trim_yoff $trim_xsize $trim_ysize subdem_mrvbf.tif $outname_mrvbf";
	#echo $cmd;
	$cmd;
	cmd="gdal_translate -a_nodata -32768 $co -srcwin $trim_xoff $trim_yoff $trim_xsize $trim_ysize subdem_mrrtf.tif $outname_mrrtf";
	$cmd;
	cmd="gdal_translate $co -srcwin $trim_xoff $trim_yoff $trim_xsize $trim_ysize subdem_slope.tif $outname_slope";
        $cmd;

	# clean up intermediate files
        rm -f subdem*.tif;

	# move off VM to save storage space
	cmd="scp $outname_mrvbf fxy120@gadi.nci.org.au:/g/data/u46/users/fxy120/DEAfrica/MrVBF/tiled_21870/";
        $cmd;
	cmd="scp $outname_mrrtf fxy120@gadi.nci.org.au:/g/data/u46/users/fxy120/DEAfrica/MrVBF/tiled_21870/";
        $cmd;
	cmd="scp $outname_slope fxy120@gadi.nci.org.au:/g/data/u46/users/fxy120/DEAfrica/MrVBF/tiled_21870/";
        $cmd;
	rm -f mrvbf_*_*.tif;
	rm -f mrrtf_*_*.tif;
	rm -f slope_*_*.tif;
	
    done;
    
done;

