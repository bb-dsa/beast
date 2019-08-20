<xsl:stylesheet version="3.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:d="http://github.com/vinniefalco/docca"
  xmlns:my="http://localhost"
  expand-text="yes">

  <xsl:output method="text"/>

  <xsl:import href="common.xsl"/>

  <xsl:include href="config.xsl"/>
  <xsl:include href="emphasized-types.xsl"/>

  <xsl:param name="DEBUG" select="false()"/>

  <xsl:variable name="list-indent-width" select="4"/>

  <xsl:variable name="nl" select="'&#xA;'"/>

  <xsl:template match="/page">
    <xsl:text>{$nl}</xsl:text>
    <xsl:text>[section:{@id} {d:qb-escape(title)}]</xsl:text>
    <xsl:apply-templates/>
  </xsl:template>

  <!-- Title is already included in section header -->
  <xsl:template match="/page/title"/>

  <xsl:template match="heading">{$nl}[heading {.}]</xsl:template>

  <xsl:template match="location">
    <xsl:apply-templates mode="includes-template" select="."/>
  </xsl:template>

  <!-- TODO: make this work for more complex examples (e.g. with template parameters) -->
  <xsl:template match="compound">
    <!-- Working around apparent Saxon bug?? It complains when I merge the consecutive <xsl:text> instructions into one -->
    <xsl:text>{$nl}</xsl:text>
    <xsl:text>```</xsl:text>
    <xsl:text>{$nl}</xsl:text>
    <xsl:apply-templates mode="syntax" select="*"/>
    <xsl:text>{$nl}</xsl:text>
    <xsl:text>```</xsl:text>
    <xsl:text>{$nl}</xsl:text>
  </xsl:template>

          <!-- TODO: Should we consider not using a separate "syntax" mode, so we get other things "for free"
                     like stripping of whitespace-only text nodes and link generation for inline <ref> elements? -->
          <xsl:template mode="syntax" match="kind">{my:content(.)} </xsl:template>

          <xsl:template mode="syntax" match="templateparamlist">
            <xsl:text>template&lt;</xsl:text>
            <xsl:text>{$nl}</xsl:text>
            <xsl:apply-templates mode="syntax" select="param"/>
            <xsl:text>></xsl:text>
            <xsl:text>{$nl}</xsl:text>
          </xsl:template>

          <xsl:template mode="syntax" match="param">
            <xsl:text>    </xsl:text>
            <xsl:apply-templates mode="syntax" select="*"/>
            <xsl:if test="following-sibling::param">,{$nl}</xsl:if>
          </xsl:template>

          <xsl:template mode="syntax" match="type">{my:content(.)}{' '}</xsl:template>
          <xsl:template mode="syntax" match="declname[. = $emphasized-types]">__{translate(.,'_','')}__</xsl:template>
          <xsl:template mode="syntax" match="declname">{my:content(.)}</xsl:template>
          <xsl:template mode="syntax" match="defval"> = {my:content(.)}</xsl:template>


  <xsl:template mode="#all" match="ERROR">[role red error.{@message}]</xsl:template>

  <xsl:template match="table">
    <xsl:text>{$nl}</xsl:text>
    <xsl:text>[table </xsl:text>
    <xsl:apply-templates select="tr"/>
    <xsl:text>{$nl}</xsl:text>
    <xsl:text>]</xsl:text>
  </xsl:template>

          <!-- ASSUMPTION: table rows have either <th> or <td>, not both -->
          <xsl:template match="tr[th]">
            <xsl:text>[</xsl:text>
            <xsl:apply-templates select="th"/>
            <xsl:text>]</xsl:text>
          </xsl:template>

                  <!-- ASSUMPTION: <th> doesn't contain any nested markup (well, we ignore it anyway) -->
                  <xsl:template match="th">[{.}]</xsl:template>

          <xsl:template match="tr">
            <xsl:text>{$nl}  [</xsl:text>
            <xsl:apply-templates select="td"/>
            <xsl:text>{$nl}  ]</xsl:text>
          </xsl:template>

                  <!-- ASSUMPTION: <td> doesn't directly contain text, only elements -->
                  <xsl:template match="td">
                    <xsl:text>{$nl}    [</xsl:text>
                    <xsl:apply-templates select="*"/>
                    <xsl:text>{$nl}    ]</xsl:text>
                  </xsl:template>

  <xsl:template match="member-link">[link {$doc-ref}.{/page/@id}.{d:make-id(@to)} [*{d:qb-escape(@to)}]]</xsl:template>

  <xsl:template match="emphasis">
    <xsl:text>['</xsl:text>
    <xsl:apply-templates/>
    <xsl:text>]</xsl:text>
  </xsl:template>

  <xsl:template match="bold">
    <xsl:text>[*</xsl:text>
    <xsl:apply-templates/>
    <xsl:text>]</xsl:text>
  </xsl:template>

  <xsl:template match="computeroutput">
    <xsl:text>`</xsl:text>
    <xsl:apply-templates/>
    <xsl:text>`</xsl:text>
  </xsl:template>

  <xsl:template match="listitem">
    <xsl:text>{$nl}</xsl:text>
    <xsl:apply-templates mode="list-item-indent" select="."/>
    <xsl:apply-templates mode="list-item-label" select=".."/>
    <xsl:text> </xsl:text>
    <!-- ASSUMPTION: <para> always appears as a child of list items -->
    <xsl:apply-templates select="para/node()"/>
  </xsl:template>

          <!-- TODO: verify this works as expected (find an example of a nested list) -->
          <xsl:template mode="list-item-indent"
                        match="listitem">{ancestor::listitem ! (1 to $list-indent-width) ! ' '}</xsl:template>

          <xsl:template mode="list-item-label" match="itemizedlist">*</xsl:template>
          <xsl:template mode="list-item-label" match="orderedlist" >#</xsl:template>

  <xsl:template match="para" priority="1">
    <xsl:next-match/>
    <xsl:if test=". is /page/div[1]/para[1] and $DEBUG">
      <xsl:text>[@../../doc/html/beast/ref/{/page/@id}.html original_results] </xsl:text>
      <xsl:text>[@../build/stage1_visualized/visualized/{/page/@id}.html stage1_visualized] </xsl:text>
      <xsl:text>[@../build/stage2_visualized/visualized/{/page/@id}.html stage2_visualized] </xsl:text>
    </xsl:if>
  </xsl:template>

  <xsl:template match="para | div">
    <xsl:text>{$nl}</xsl:text>
    <xsl:apply-templates/>
  </xsl:template>

  <xsl:template match="sp">
    <xsl:text> </xsl:text>
  </xsl:template>

  <xsl:template match="programlisting">
    <xsl:text>{$nl}</xsl:text>
    <xsl:text>```</xsl:text>
    <xsl:text>{$nl}</xsl:text>
    <xsl:apply-templates/>
    <xsl:text>```</xsl:text>
    <xsl:text>{$nl}</xsl:text>
  </xsl:template>

  <xsl:template match="codeline">
    <xsl:apply-templates/>
    <xsl:text>{$nl}</xsl:text>
  </xsl:template>

  <!-- Ignore whitespace-only text nodes -->
  <xsl:template match="text()[not(normalize-space())]"/>

  <xsl:function name="d:qb-escape">
    <xsl:param name="string"/>
    <xsl:sequence select="replace(
                            replace($string, '\[', '\\['),
                            '\]',
                            '\\]'
                          )"/>
  </xsl:function>

  <!-- Convenience function for processing child nodes in the default mode -->
  <xsl:function name="my:content">
    <xsl:param name="sequence"/>
    <xsl:apply-templates select="$sequence/node()"/>
  </xsl:function>

</xsl:stylesheet>
