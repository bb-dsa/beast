echo "Removing previous stage1 results..."
rm -rf stage1_visualized/results
mkdir -p stage1_visualized/results

echo "Tracing stage1..."
#java -jar "C:/saxon/saxon9he.jar" -threads:32 -s:xml-pages2 -o:stage1_visualized/results -xsl:stage1_visualized/code-trace-enabled/stage1.xsl
 java -jar "C:/saxon/saxon9he.jar" -threads:128 -s:xml-pages -o:stage1_visualized/results -xsl:stage1_visualized/code-trace-enabled/stage1.xsl
