
# Process DEM into tiled derivative products
# All calculations are done in EPSG:6933 and 30x30 m pixels

# Uses gdaldem and tile grid designed for producing MrVBF


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


startx=8;
starty=8;

#
# ==============================================

# loop through tiles
for xi in $(seq $startx $nx); do
    for yi in $(seq $starty $ny); do

	# output name
        outname_aspect="aspect_${xi}_${yi}.tif"
	
        # break if done
        if [ -f $outname_aspect ]; then 
            continue;
        fi
	echo $outname_aspect;

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

        #cmd="gdaldem hillshade subdem.tif subdem_hillshade.tif -p -compute_edges";
	#$cmd;
        cmd="gdaldem aspect subdem.tif subdem_aspect.tif -p -compute_edges";
	$cmd;
        cmd="gdaldem TRI subdem.tif subdem_TRI.tif -p -compute_edges";
	$cmd;
        cmd="gdaldem TPI subdem.tif subdem_TPI.tif -p -compute_edges";
	$cmd;
        cmd="gdaldem roughness subdem.tif subdem_roughness.tif -p -compute_edges";
	$cmd;


	# trim to remove buffer
	#co="-co COMPRESS=LZW -co TILED=YES -co BLOCKXSIZE=512 -co BLOCKYSIZE=512"
	co="-co TILED=YES -co BLOCKXSIZE=512 -co BLOCKYSIZE=512";
	cmd="gdal_translate $co -srcwin $trim_xoff $trim_yoff $trim_xsize $trim_ysize subdem_aspect.tif /g/data/dem/$outname_aspect";
        $cmd;
        cmd="gdal_translate $co -srcwin $trim_xoff $trim_yoff $trim_xsize $trim_ysize subdem_TRI.tif /g/data/dem/tri_${xi}_${yi}.tif";
        $cmd;
        cmd="gdal_translate $co -srcwin $trim_xoff $trim_yoff $trim_xsize $trim_ysize subdem_TPI.tif /g/data/dem/tpi_${xi}_${yi}.tif";
        $cmd;
        cmd="gdal_translate $co -srcwin $trim_xoff $trim_yoff $trim_xsize $trim_ysize subdem_roughness.tif /g/data/dem/roughness_${xi}_${yi}.tif";
        $cmd;

	# clean up intermediate files
        rm -f subdem*.tif;
	exit;
    done;
    exit;
done;

