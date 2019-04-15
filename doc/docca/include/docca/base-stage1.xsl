<xsl:stylesheet version="3.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:d="http://github.com/vinniefalco/docca"
  exclude-result-prefixes="xs d"
  expand-text="yes">

  <xsl:include href="common.xsl"/>

  <xsl:output indent="yes"/>

  <xsl:template match="/doxygen" priority="1">
    <page id="{@d:page-id}">
      <xsl:next-match/>
    </page>
  </xsl:template>

  <xsl:template match="/doxygen[@d:page-type eq 'member']">
    <xsl:apply-templates select="compounddef/sectiondef/memberdef"/> <!-- should just be one -->
  </xsl:template>

  <xsl:template match="/doxygen[@d:page-type eq 'compound']">
    <xsl:apply-templates select="compounddef"/>
  </xsl:template>

  <xsl:template match="compounddef">
    <title>{d:strip-doc-ns(compoundname)}</title>

    <xsl:apply-templates select="briefdescription"/>

    <section>
      <title>Synopsis</title>
      <para>
        <xsl:apply-templates select="location"/>
      </para>
      <!-- Do in final stage instead
      <para>
        <xsl:apply-templates mode="includes-template" select="location"/>
      </para>
      -->
      <xsl:apply-templates mode="normalize-params" select="templateparamlist"/>
      <compound>
        <kind>{@kind}</kind>
        <name>{d:strip-ns(compoundname)}</name>
        <xsl:for-each select="basecompoundref[not(d:should-ignore-base(.))]">
          <base>
            <prot>{@prot}</prot>
            <name>{d:strip-doc-ns(.)}</name>
          </base>
        </xsl:for-each>
      </compound>
    </section>
  </xsl:template>

          <!-- TODO: make sure this is robust and handles all the possible cases well -->
          <xsl:template mode="normalize-params" match="templateparamlist/param[not(declname)]">
            <param>
              <type>{    substring-before(type,' ')}</type>
              <declname>{substring-after (type,' ')}</declname>
            </param>
          </xsl:template>
          <xsl:template mode="normalize-params" match="templateparamlist/param/defname"/>

  <!-- We only need to keep the @file attribute -->
  <xsl:template match="location/@*[. except ../@file]"/>

  <xsl:template match="briefdescription">
    <div>
      <xsl:apply-templates/>
    </div>
  </xsl:template>

  <xsl:template match="title">
    <heading>
      <xsl:apply-templates/>
    </heading>
  </xsl:template>

  <xsl:template mode="#default normalize-params" match="@* | node()">
    <xsl:copy copy-namespaces="no">
      <xsl:apply-templates mode="#current" select="@* | node()"/>
    </xsl:copy>
  </xsl:template>

</xsl:stylesheet>
