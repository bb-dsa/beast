mkdir -p stage1

echo "Executing stage1..."
 java -jar "C:/saxon/saxon9he.jar" -threads:128 -s:xml-pages -o:stage1_visualized/results -xsl:stage1.xsl

mkdir -p stage2

echo "Executing stage2..."
java -jar "C:/saxon/saxon9he.jar" -threads:128 -s:stage1_visualized/results -o:stage2_visualized/results -xsl:stage2.xsl DEBUG=yes
