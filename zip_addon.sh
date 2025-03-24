mkdir _zip
cp -r PvPStatsClassic _zip
cd _zip
rm -r PvPStatsClassic/img
zip -r PvPStatsClassic.zip PvPStatsClassic
mv PvPStatsClassic.zip ..
cd ..
rm -r _zip
