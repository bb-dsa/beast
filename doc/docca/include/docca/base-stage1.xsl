<!DOCTYPE xsl:stylesheet [
<!-- TODO: complete this list -->
<!ENTITY BLOCK_LEVEL_ELEMENT "itemizedlist
                            | orderedlist
                            | programlisting
                            | para
                            | table">
]>
<xsl:stylesheet version="3.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:d="http://github.com/vinniefalco/docca"
  exclude-result-prefixes="xs d"
  expand-text="yes">

  <xsl:include href="common.xsl"/>

  <xsl:output indent="yes"/>

  <xsl:template match="/doxygen" priority="1">
    <xsl:variable name="section-name">
      <xsl:apply-templates mode="section-name" select="."/>
    </xsl:variable>
    <page id="{@d:page-id}" type="{@d:page-type}" section-name="{$section-name}">
      <xsl:apply-templates mode="index-parent-att" select="."/>
      <xsl:next-match/>
    </page>
  </xsl:template>

          <xsl:template mode="section-name" match="doxygen[@d:page-type eq 'compound']">{@d:page-id}</xsl:template>
          <xsl:template mode="section-name" match="doxygen[@d:overload-position]"      >overload{@d:overload-position}</xsl:template>
          <xsl:template mode="section-name" match="doxygen"                            >{(compounddef/sectiondef/memberdef/name)[1]}</xsl:template>

          <xsl:template mode="index-parent-att" match="doxygen[@d:page-type eq 'compound' or @d:overload-position]"/>
          <xsl:template mode="index-parent-att" match="doxygen">
            <xsl:attribute name="index-parent" select="d:strip-doc-ns(compounddef/compoundname)"/>
          </xsl:template>

  <xsl:template match="/doxygen[@d:page-type eq 'member']">
    <xsl:apply-templates select="compounddef/sectiondef/memberdef"/> <!-- should just be one -->
  </xsl:template>

  <xsl:template match="/doxygen[@d:page-type eq 'compound']">
    <xsl:apply-templates select="compounddef"/>
  </xsl:template>

  <xsl:template match="/doxygen[@d:page-type eq 'overload-list']">
    <xsl:apply-templates select="(compounddef/sectiondef/memberdef)[1]"/>
  </xsl:template>

  <xsl:template mode="page-title" match="compounddef">{d:strip-doc-ns(compoundname)}</xsl:template>
  <xsl:template mode="page-title" match="memberdef">
    <xsl:value-of select="d:strip-doc-ns(/doxygen/compounddef/compoundname)"/>
    <xsl:text>::</xsl:text>
    <xsl:value-of select="name"/>
    <xsl:apply-templates mode="overload-qualifier" select="/doxygen"/>
  </xsl:template>

          <xsl:template mode="overload-qualifier" match="*"/>
          <xsl:template mode="overload-qualifier" match="/doxygen[@d:overload-position]">
            <xsl:text> (</xsl:text>
            <xsl:value-of select="@d:overload-position"/>
            <xsl:text> of </xsl:text>
            <xsl:value-of select="@d:overload-size"/>
            <xsl:text> overloads)</xsl:text>
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
    <title>
      <xsl:apply-templates mode="page-title" select="."/>
    </title>

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

                                 detaileddescription
                                 (:,

                                 (: ASSUMPTION: simplesect and parameterlist only appear in a contiguous block at the end of detaileddescription :)
                                 (: TODO: verify this is true, and, if not, change the implementation so it does whatever the right thing is :)
                                 detaileddescription//(simplesect | parameterlist)
                                 :)
                                 "/>
    <xsl:apply-templates mode="includes-footer"/>
  </xsl:template>

  <xsl:template match="memberdef">
    <title>
      <xsl:apply-templates mode="page-title" select="."/>
    </title>
    <xsl:apply-templates mode="memberdef-page-content" select="."/>
  </xsl:template>

          <xsl:template mode="memberdef-page-content" match="memberdef">
            <xsl:apply-templates select="briefdescription"/>
            <xsl:apply-templates mode="section" select="., detaileddescription"/>
          </xsl:template>

          <xsl:template mode="memberdef-page-content" match="memberdef[/doxygen/@d:page-type eq 'overload-list']">
            <xsl:apply-templates mode="overload-list" select="../../sectiondef/memberdef"/>
          </xsl:template>

                  <xsl:template mode="overload-list" match="memberdef">
                    <xsl:apply-templates select="briefdescription[not(. = preceding-sibling::*/briefdescription)]"/>
                    <overloaded-member>
                      <xsl:apply-templates mode="normalize-params" select="templateparamlist"/>
                      <xsl:apply-templates mode="modifier" select="(@explicit, @friend, @static)[. eq 'yes'],
                                                                   @virt[. eq 'virtual']"/>
                      <xsl:apply-templates select="type"/>
                      <member-link to="{@d:page-id}" display="{name}"/>
                      <xsl:apply-templates select="param"/>
                      <member-link to="{@d:page-id}" display="more..."/>
                    </overloaded-member>
                  </xsl:template>

                          <xsl:template mode="modifier" match="@*">
                            <modifier>{local-name(.)}</modifier>
                          </xsl:template>
                          <xsl:template mode="modifier" match="@virt">
                            <modifier>virtual</modifier>
                          </xsl:template>


  <!-- TODO: implement "cleanup-type" from the original doxygen.xsl -->
  <xsl:template match="type[normalize-space(.)]">
    <xsl:next-match/>
  </xsl:template>

  <!-- TODO: implement param normalization; see "cleanup-param", etc. -->
  <xsl:template match="param">
    <xsl:next-match/>
  </xsl:template>

  <!-- TODO: Should this be a custom rule or built-in? -->
  <xsl:template mode="section" match="simplesect[matches(title,'Concepts:?')]"/>

  <xsl:template mode="section" match="*">
    <section>
      <heading>
        <xsl:apply-templates mode="section-heading" select="."/>
      </heading>
      <xsl:apply-templates mode="section-body" select="."/>
    </section>
  </xsl:template>

  <xsl:template match="simplesect | parameterlist">
    <xsl:apply-templates mode="section" select="."/>
  </xsl:template>

  <xsl:template mode="section-heading" match="memberdef |
                                              compounddef        ">Synopsis</xsl:template>
  <xsl:template mode="section-heading" match="detaileddescription">Description</xsl:template>

  <xsl:template mode="section-heading" match="simplesect[@kind eq 'note'  ]">Remarks</xsl:template>
  <xsl:template mode="section-heading" match="simplesect[@kind eq 'see'   ]">See Also</xsl:template>
  <xsl:template mode="section-heading" match="simplesect[@kind eq 'return']">Return Value</xsl:template>
  <xsl:template mode="section-heading" match="simplesect"                   >{title}</xsl:template>

  <xsl:template mode="section-heading" match="parameterlist[@kind eq 'exception'    ]">Exceptions</xsl:template>
  <xsl:template mode="section-heading" match="parameterlist[@kind eq 'templateparam']">Template Parameters</xsl:template>
  <xsl:template mode="section-heading" match="parameterlist                          ">Parameters</xsl:template>

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

  <xsl:template mode="section-body" match="sectiondef | innerclass | parameterlist">
    <table>
      <tr>
        <th>
          <xsl:apply-templates mode="column-1-name" select="."/>
        </th>
        <th>
          <xsl:apply-templates mode="column-2-name" select="."/>
        </th>
      </tr>
      <xsl:apply-templates mode="table-body" select="."/>
    </table>
  </xsl:template>

          <xsl:template mode="column-1-name" match="*">Name</xsl:template>
          <xsl:template mode="column-2-name" match="*">Description</xsl:template>

          <xsl:template mode="column-1-name"
                        match="parameterlist[@kind = ('exception','templateparam')]">Type</xsl:template>

          <xsl:template mode="column-2-name" match="parameterlist[@kind eq 'exception']">Thrown On</xsl:template>


  <xsl:template mode="table-body" match="parameterlist">
    <xsl:apply-templates mode="parameter-row" select="parameteritem"/>
  </xsl:template>

          <xsl:template mode="parameter-row" match="parameteritem">
            <tr>
              <td>
                <code>
                  <!-- ASSUMPTION: <parameternamelist> only ever has one <parametername> child -->
                  <xsl:apply-templates select="parameternamelist/parametername/node()"/>
                </code>
              </td>
              <td>
                <xsl:apply-templates select="parameterdescription/node()"/>
              </td>
            </tr>
          </xsl:template>

  <xsl:template mode="table-body" match="sectiondef | innerclass">
    <xsl:variable name="member-nodes" as="element()*">
      <xsl:apply-templates mode="member-nodes" select="."/>
    </xsl:variable>
    <xsl:apply-templates mode="member-row" select="$member-nodes">
      <xsl:sort select="d:member-name(.)"/>
    </xsl:apply-templates>
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
                    <xsl:sequence select="d:referenced-class/doxygen/compounddef/compoundname ! d:strip-ns(.)"/>
                  </xsl:template>


          <!-- Only output a table row for the first instance of each name (ignore overloads) -->
          <xsl:template mode="member-row" match="memberdef[name = preceding-sibling::memberdef/name]"/>
          <xsl:template mode="member-row" match="*">
            <tr>
              <td>
                <member-link to="{d:member-name(.)}"/>
              </td>
              <td>
                <xsl:apply-templates mode="member-description" select="."/>
              </td>
            </tr>
          </xsl:template>

                  <xsl:template mode="member-description" match="innerclass">
                    <xsl:apply-templates select="d:referenced-class/doxygen/compounddef/briefdescription"/>
                  </xsl:template>
                  <xsl:template mode="member-description" match="memberdef">
                    <xsl:apply-templates select="briefdescription"/>
                    <!-- Pull in any overload descriptions but only if they vary -->
                    <xsl:apply-templates select="following-sibling::memberdef[name eq current()/name]
                                                /briefdescription[not(. eq current()/briefdescription)]"/>
                  </xsl:template>


  <xsl:template mode="section-body" match="detaileddescription | simplesect">
    <xsl:apply-templates/>
  </xsl:template>

          <!-- We are already processing these at the top level; don't duplicate their content -->
          <!--
          <xsl:template match="detaileddescription//simplesect
                             | detaileddescription//parameterlist"/>
                             -->

  <xsl:template mode="section-body" match="compounddef">
    <xsl:apply-templates mode="includes-header" select="."/>
    <compound>
      <xsl:apply-templates mode="normalize-params" select="templateparamlist"/>
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

  <!-- TODO: finish implementing this; consider different elements for <enum>, <function>, etc. -->
  <xsl:template mode="section-body" match="memberdef">
    <xsl:apply-templates mode="includes-header" select="."/>
    <member>
      <xsl:apply-templates mode="normalize-params" select="templateparamlist"/>
      <kind>{@kind}</kind>
      <name>{name}</name>
    </member>
  </xsl:template>

          <!-- TODO: make sure this is robust and handles all the possible cases well -->
          <xsl:template mode="normalize-params" match="templateparamlist/param/type[not(../declname)]
                                                                                   [starts-with(.,'class ')]"
                                                priority="1">
            <type>{    substring-before(.,' ')}</type>
            <declname>{substring-after (.,' ')}</declname>
          </xsl:template>

          <xsl:template mode="normalize-params" match="templateparamlist/param/type[not(../declname)]">
            <ERROR message="param neither has declname nor 'class ' prefix in the type"/>
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

  <!-- TODO: check both of these rules; I don't think they're correct yet, e.g. w.r.t. namespace memberdefs -->
  <xsl:template mode="includes-header" match="compounddef | memberdef[@kind eq 'friend']
                                                          | memberdef[/doxygen/@d:overload-position]">
    <para>
      <xsl:apply-templates select="location"/>
    </para>
  </xsl:template>

  <xsl:template mode="includes-footer" match="compounddef | memberdef[@kind eq 'friend']
                                                          | memberdef[/doxygen/@d:overload-position]">
    <para>
      <footer>
        <xsl:apply-templates select="location"/>
      </footer>
    </para>
  </xsl:template>

  <!-- If a non-whitespace-only text node appears as a sibling of a block-level element, wrap it in a <para> -->
  <xsl:template match="*[&BLOCK_LEVEL_ELEMENT;]/text()[normalize-space(.)]">
    <para>
      <xsl:copy-of select="."/>
    </para>
  </xsl:template>

  <xsl:template mode="#default normalize-params" match="@* | node()">
    <xsl:copy copy-namespaces="no">
      <xsl:apply-templates mode="#current" select="@* | node()"/>
    </xsl:copy>
  </xsl:template>

</xsl:stylesheet>
