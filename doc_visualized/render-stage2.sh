mkdir -p stage2_visualized/visualized/assets
cp -ru xslt-visualizer/assets/* stage2_visualized/visualized/assets

echo "Rendering the stage2 visualization results"
java -jar "C:/saxon/saxon9he.jar" -threads:128 -s:stage2_visualized/results/traced -o:stage2_visualized/visualized -xsl:xslt-visualizer/xsl/render.xsl

#echo "Copying the stage2 visualization files to .html versions"
#java -jar "C:/saxon/saxon9he.jar" -s:xslt-visualizer/util/copy-to-html.xsl -o:stage2_visualized/visualized/dummy.xml -xsl:xslt-visualizer/util/copy-to-html.xsl

echo "Renaming the stage2 visualization files to .html"
cd stage2_visualized/visualized
for file in *.xml
do
  mv "$file" "${file%.xml}.html"
done
