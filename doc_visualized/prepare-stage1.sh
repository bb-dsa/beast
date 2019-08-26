rm -rf stage1_visualized/code-trace-enabled
java -jar "C:/saxon/saxon9he.jar" -s:stage1.xsl -o:stage1_visualized/code-trace-enabled/stage1.xsl -xsl:xslt-visualizer/xsl/trace-enable.xsl
