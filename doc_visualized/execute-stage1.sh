mkdir -p stage1

echo "Executing stage1..."
java -jar "C:/saxon/saxon9he.jar" -threads:128 -s:xml-pages -o:stage1_visualized/results -xsl:stage1.xsl
