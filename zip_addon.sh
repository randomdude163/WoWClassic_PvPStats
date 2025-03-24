rm PvPStatsClassic.zip
mkdir _zip
cp -r PvPStatsClassic _zip
cd _zip
rm -r PvPStatsClassic/img/Screenshots
find . -name "*.DS_Store" -type f -delete
zip -r PvPStatsClassic.zip PvPStatsClassic
mv PvPStatsClassic.zip ..
cd ..
rm -r _zip
