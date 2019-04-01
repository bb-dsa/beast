<!-- This is just an initial placeholder/mockup for gettting a barebones build running -->
<xsl:stylesheet version="3.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:d="http://github.com/vinniefalco/docca"
  expand-text="yes">

  <xsl:output method="text"/>

  <xsl:template match="/">
    [section:{/*/@d:page-id} {/*/@d:page-id}]

    {(.//briefdescription)[1]}

    [heading Synopsis]

    Synopsis text goes here.

    [heading Description]

    {(.//detaileddescription)[1]}

    [endsect]
  </xsl:template>

</xsl:stylesheet>
