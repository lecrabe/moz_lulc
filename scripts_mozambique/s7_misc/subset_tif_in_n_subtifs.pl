use List::Util qw(min max);
$file = `basename @ARGV[0]`;
chomp($file);
$filepath = `readlink -f @ARGV[0]`;
chomp($filepath);
$path=substr($filepath,0,length($filepath)-length($file)-1);

$nx = `basename @ARGV[1]`;
$ny = `basename @ARGV[2]`;

chomp($nx);
chomp($ny);

if(@ARGV[2] eq ''){die("Usage : <input.tif> <nb tiles in x> <nb tiles in y> \n");}


$base=substr($file,0,length($file)-4);
$ext =substr($file,length($file)-3,length($file));

$outdir = "$path/$base\_subset_tiles";
system "mkdir $outdir";

print "base is $base and path is $path, file will be cut into $nx x $ny tiles put into $outdir\n";

@info=`gdalinfo $filepath`;
@sizeline= grep /Size is/,@info;
$sizeline=@sizeline[0];
chomp($sizeline);
$sizeline =~ s/Size is //;
($size_x,$size_y)=split(",",$sizeline);
chomp($size_x);
chomp($size_y);

$subsize_x=int($size_x/$nx);
$subsize_y=int($size_y/$ny);

print "$size_x $size_y $subsize_x $subsize_y\n";

#die;
for($i=1;$i<=$nx;$i++){
for($j=1;$j<=$ny;$j++){

$x_off=$subsize_x*($i-1);
$y_off=$subsize_y*($j-1);
$x_size=$subsize_x;
$y_size=$subsize_y;

if($i eq $nx){$x_size=$size_x-$subsize_x*($nx-1)}
if($j eq $ny){$y_size=$size_y-$subsize_y*($ny-1)}

print "$i $j\n";
print "gdal_translate -srcwin $x_off $y_off $x_size $y_size $path/$base.$ext $outdir/$base\_$i\_$j.tif";
print "\n";
system "gdal_translate -co \"COMPRESS=LZW\" -srcwin $x_off $y_off $x_size $y_size $path/$base.$ext $outdir/$base\_$i\_$j.tif";

}
}
