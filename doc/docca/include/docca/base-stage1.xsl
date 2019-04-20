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

  <!-- For convenience, pre-calculate some member sequences and tunnel them through -->
  <xsl:template match="compounddef" priority="1">
    <xsl:next-match>
      <xsl:with-param name="public-types"
                      select="sectiondef[@kind eq 'public-type']/memberdef
                            | innerclass[@prot eq 'public'][not(d:should-ignore-inner-class(.))]"
                      tunnel="yes"/>
      <xsl:with-param name="friends"
                      select="sectiondef[@kind eq 'friend']/memberdef[not(type eq 'friend class')]
                                                                     [not(d:should-ignore-friend(.))]"
                      tunnel="yes"/>
    </xsl:next-match>
  </xsl:template>

  <xsl:template match="compounddef">
    <xsl:param name="public-types" tunnel="yes"/>
    <xsl:param name="friends" tunnel="yes"/>
    <title>{d:strip-doc-ns(compoundname)}</title>

    <xsl:apply-templates select="briefdescription"/>

    <xsl:apply-templates mode="section"
                         select=".,

                                 ( $public-types/self::memberdef/..
                                 | $public-types/self::innerclass
                                 )[1],

                                 sectiondef[@kind = (   'public-func',   'public-static-func')],
                                 sectiondef[@kind = ('protected-func','protected-static-func')],
                                 sectiondef[@kind = (  'private-func',  'private-static-func')][$include-private-members],

                                 sectiondef[@kind = (   'public-attrib',   'public-static-attrib')],
                                 sectiondef[@kind = ('protected-attrib','protected-static-attrib')],
                                 sectiondef[@kind = (  'private-attrib',  'private-static-attrib')][$include-private-members],

                                 $friends/..,

                                 sectiondef[@kind eq 'related'],

                                 detaileddescription"/>

    <!-- TODO: port "class-members" and "includes-foot" (from doxygen.xsl) here -->
  </xsl:template>

  <xsl:template mode="section" match="*">
    <section>
      <heading>
        <xsl:apply-templates mode="section-heading" select="."/>
      </heading>
      <xsl:apply-templates mode="section-body" select="."/>
    </section>
  </xsl:template>

  <xsl:template mode="section-heading" match="compounddef        ">Synopsis</xsl:template>
  <xsl:template mode="section-heading" match="detaileddescription">Description</xsl:template>
  <xsl:template mode="section-heading" match="innerclass
                                            | sectiondef[@kind eq 'public-type']">Types</xsl:template>
  <xsl:template mode="section-heading" match="sectiondef[@kind eq 'friend'     ]">Friends</xsl:template>
  <xsl:template mode="section-heading" match="sectiondef[@kind eq 'related'    ]">Related Functions</xsl:template>

  <xsl:template mode="section-heading" match="sectiondef">
    <xsl:apply-templates mode="access-level" select="@kind"/>
    <xsl:apply-templates mode="member-kind" select="@kind"/>
  </xsl:template>

          <xsl:template mode="access-level" match="@kind[starts-with(.,'public'   )]"/>
          <xsl:template mode="access-level" match="@kind[starts-with(.,'protected')]">Protected </xsl:template>
          <xsl:template mode="access-level" match="@kind[starts-with(.,'private'  )]">Private </xsl:template>

          <xsl:template mode="member-kind" match="@kind[ends-with(.,'func'  )]">Member Functions</xsl:template>
          <xsl:template mode="member-kind" match="@kind[ends-with(.,'attrib')]">Data Members</xsl:template>


  <xsl:template mode="section-body" match="sectiondef | innerclass">
    <xsl:variable name="member-nodes" as="element()*">
      <xsl:apply-templates mode="member-nodes" select="."/>
    </xsl:variable>
    <table>
      <tr>
        <th>Name</th>
        <th>Description</th>
      </tr>
      <xsl:apply-templates mode="table-row" select="$member-nodes">
        <xsl:sort select="d:member-name(.)"/>
      </xsl:apply-templates>
    </table>
  </xsl:template>

          <xsl:template mode="member-nodes" match="innerclass | sectiondef[@kind eq 'public-type']">
            <xsl:param name="public-types" tunnel="yes"/>
            <xsl:sequence select="$public-types"/>
          </xsl:template>

          <xsl:template mode="member-nodes" match="sectiondef[@kind eq 'friend']">
            <xsl:param name="friends" tunnel="yes"/>
            <xsl:sequence select="$friends"/>
          </xsl:template>

          <xsl:template mode="member-nodes" match="sectiondef">
            <xsl:sequence select="memberdef"/>
          </xsl:template>


          <xsl:function name="d:member-name">
            <xsl:param name="element"/>
            <xsl:apply-templates mode="member-name" select="$element"/>
          </xsl:function>

                  <xsl:template mode="member-name" match="memberdef">
                    <xsl:sequence select="name"/>
                  </xsl:template>
                  <xsl:template mode="member-name" match="innerclass">
                    <xsl:sequence select="."/>
                  </xsl:template>


          <xsl:template mode="table-row" match="*">
            <tr>
              <td>
                <!-- TODO: make this a link (after attending to overloads) -->
                <xsl:value-of select="d:member-name(.) ! d:strip-ns(.)"/>
              </td>
              <td>
                <!-- TODO: populate this -->
              </td>
            </tr>
          </xsl:template>


  <xsl:template mode="section-body" match="compounddef">
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
