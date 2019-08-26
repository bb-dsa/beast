#rm -rf stage2_visualized/results

echo "Removing previous stage2 result traces..."
rm -rf stage2_visualized/results/traced
mkdir -p stage2_visualized/results

echo "Tracing stage2..."
java -jar "C:/saxon/saxon9he.jar" -threads:128 -s:stage1_visualized/results -o:stage2_visualized/results -xsl:stage2_visualized/code-trace-enabled/stage2.xsl DEBUG=yes
