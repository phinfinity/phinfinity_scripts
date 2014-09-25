#!/bin/bash 
# Script by Phinfinity <rndanish@gmail.com>
# This script is a useful wrapper around imagemagick to
# make neat pdf's out of a set of given images
# This script requires ImageMagick to be installed

SCALE=10
BORDER_SIZE=30
COMPRESS="JPEG" # or Lossless
DOUBLEPERPAGE=false
usage()
{
cat << EOF
usage: $0 [-s scale] [-b border_percentage] [-l] [-2] IMAGES... OUTPUT_PDF
This script uses imagemagick to neatly generate a pdf out of a given set of images as arguments.
OPTIONS:
    -s density in pixels per millimeter. Defaults to 10
    -b border size as a percentage. Defaults to 30%
    -l Use Lossless compression. (Default is jpeg)
    -2 Use two images per page (Default is 1 image per page)
    -h This help message
EOF
}
while getopts "hs:b:l2" OPTION
do
  case $OPTION in
    h)
      usage
      exit 1
      ;;
    s)
      SCALE=$OPTARG
      ;;
    b)
      BORDER_SIZE=$OPTARG
      ;;
    l)
      COMPRESS="Lossless"
      ;;
    2)
      DOUBLEPERPAGE=true
      ;;
    ?)
      usage
      exit
      ;;
  esac
done
shift $((OPTIND - 1))
if [[ $# -lt 2 ]]
then
  echo "error: Must specify at least one image and an output name"
  usage
  exit 1
fi
IMGFILES=()
for i; do IMGFILES+=($i); done
OUTPUT_FILE=$i
unset IMGFILES[${#IMGFILES[@]}-1] # Pop Last output argument
if [[ $OUTPUT_FILE != *.pdf ]]
then
  OUTPUT_FILE=${OUTPUT_FILE}.pdf
fi
echo "Writing Images to $OUTPUT_FILE" 1>&2
IM_WD=$((210*SCALE))
IM_HT=$((297*SCALE))
DENSITY=$((SCALE*10))

COMMAND=""
if [ "$DOUBLEPERPAGE" = true ]
then
  # TODO , The double image mechanism is not very nice at the moment.
  # look into montage command for future.
  HALFHT=$((IM_HT/2))
  COMMAND="convert "
  for i in $(seq 0 2 $((${#IMGFILES[@]}-1)))
  do
    COMMAND=$COMMAND" \( ${IMGFILES[$i]} ${IMGFILES[$((i+1))]} -gravity center -bordercolor none -border ${BORDER_SIZE}%x${BORDER_SIZE}% -resize ${IM_WD}x${HALFHT} -extent ${IM_WD}x${HALFHT} -append \) "
  done
  COMMAND=$COMMAND" -extent ${IM_WD}x${IM_HT} -units PixelsPerCentimeter -density ${DENSITY}x${DENSITY} -compress $COMPRESS $OUTPUT_FILE"
else
  COMMAND="convert ${IMGFILES[@]} -bordercolor none -border ${BORDER_SIZE}%x${BORDER_SIZE}% -compress $COMPRESS -resize ${IM_WD}x${IM_HT} -gravity center -extent ${IM_WD}x${IM_HT} -units PixelsPerCentimeter -density ${DENSITY}x${DENSITY} $OUTPUT_FILE"
fi

echo "$COMMAND"
eval "$COMMAND"
echo "converted to pdf of size $(du -sh $OUTPUT_FILE)"
