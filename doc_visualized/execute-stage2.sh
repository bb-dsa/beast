mkdir -p stage2

echo "Executing stage2..."
java -jar "C:/saxon/saxon9he.jar" -threads:128 -s:stage1_visualized/results -o:stage2_visualized/results -xsl:stage2.xsl DEBUG=yes
