mkdir -p stage2

echo "Executing stage2..."
java -jar "C:/saxon/saxon9he.jar" -threads:128 -s:stage1_visualized/results -o:stage2_visualized/results -xsl:stage2.xsl DEBUG=yes

echo "Copying the stage2 results to .txt files (for easier viewing in the browser)..."
java -jar "C:/saxon/saxon9he.jar" -s:xml-pages.xml -xsl:debug-friendly-quickbook.xsl input-dir=stage2_visualized/results >/dev/null
