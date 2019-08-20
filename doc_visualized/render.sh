mkdir -p stage1_visualized/visualized/assets
cp -ru xslt-visualizer/assets/* stage1_visualized/visualized/assets


echo "Rendering the stage1 visualization results"
# Create the rendered results (Saxon forces .xml prefix in the output files)
java -jar "C:/saxon/saxon9he.jar" -threads:128 -s:stage1_visualized/results/traced -o:stage1_visualized/visualized -xsl:xslt-visualizer/xsl/render.xsl


#echo "Copying the stage1 visualization files to .html versions"
# Copy the files to .html versions (just using Saxon - as a proof of concept for use in difficult build tools)
#java -jar "C:/saxon/saxon9he.jar" -s:xslt-visualizer/util/copy-to-html.xsl -o:stage1_visualized/visualized/dummy.xml -xsl:xslt-visualizer/util/copy-to-html.xsl

echo "Renaming the stage1 visualization files to .html"
cd stage1_visualized/visualized
for file in *.xml
do
  mv "$file" "${file%.xml}.html"
done

cd ../..

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
