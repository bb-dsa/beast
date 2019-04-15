<xsl:stylesheet version="3.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:d="http://github.com/vinniefalco/docca"
  exclude-result-prefixes="xs d"
  expand-text="yes">

  <xsl:variable name="doc-ns" select="'boost::beast'"/>
  <xsl:variable name="doc-ref" select="'beast.ref.'"/>

  <xsl:variable name="additional-id-replacements" as="element(replace)*">
    <replace pattern="boost::asio::error" with=""/>
  </xsl:variable>

  <xsl:template mode="includes-template" match="location"
    >Defined in header [include_file {substring-after(@file, 'include/')}]
  </xsl:template>

  <xsl:function name="d:should-ignore-compound">
    <xsl:param name="compound" as="element(compound)"/>
    <xsl:sequence select="contains($compound/name, '::detail')"/>  <!-- TODO: Confirm this should be custom and not built-in behavior -->
  </xsl:function>

  <xsl:function name="d:should-ignore-base">
    <xsl:param name="basecompoundref" as="element(basecompoundref)"/>
    <xsl:sequence select="contains($basecompoundref, '::detail')"/>  <!-- TODO: Confirm this should be custom and not built-in behavior -->
  </xsl:function>

</xsl:stylesheet>
