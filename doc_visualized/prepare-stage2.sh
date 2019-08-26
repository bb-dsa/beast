rm -rf stage2_visualized/code-trace-enabled
java -jar "C:/saxon/saxon9he.jar" -s:stage2.xsl -o:stage2_visualized/code-trace-enabled/stage2.xsl -xsl:xslt-visualizer/xsl/trace-enable.xsl
