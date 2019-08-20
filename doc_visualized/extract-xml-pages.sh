echo "Copying a custom (manually-slimmed-down) index.xml if present..."
cp ../index.xml .

echo "Removing the previously-extracted XML pages (xml-pages directory)..."
rm -rf xml-pages

echo "Extracting the xml-pages from index.xml and accompanying files..."
java -jar "C:/saxon/saxon9he.jar" -s:index.xml -xsl:extract-xml-pages.xsl -o:xml-pages.xml
