<xsl:stylesheet version="2.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:d="http://github.com/vinniefalco/docca"
  exclude-result-prefixes="xs d">

  <xsl:import href="base-extract-xml-pages.xsl"/>

  <xsl:variable name="doc-ns" select="'boost::beast'"/>
  <xsl:variable name="doc-ref" select="'beast.ref.'"/>

  <xsl:variable name="additional-id-replacements" as="element(replace)*">
    <replace pattern="boost::asio::error" with=""/>
  </xsl:variable>

  <xsl:function name="d:should-ignore-compound">
    <xsl:param name="compound" as="element(compound)"/>
    <xsl:sequence select="contains($compound/name, '::detail')"/>  <!-- TODO: Confirm this should be custom and not built-in behavior -->
  </xsl:function>

</xsl:stylesheet>
