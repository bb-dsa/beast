<!DOCTYPE xsl:stylesheet [
<!-- TODO: complete this list -->
<!ENTITY BLOCK_LEVEL_ELEMENT "programlisting
                            | itemizedlist
                            | orderedlist
                            | parameterlist
                            | simplesect
                            | para
                            | table
                            | linebreak">
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
    <page id="{@d:page-id}" type="{@d:page-type}">
      <xsl:apply-templates mode="index-term-atts" select="."/>
      <title>
        <xsl:apply-templates mode="page-title" select="."/>
      </title>
      <xsl:next-match/>
    </page>
  </xsl:template>

          <!-- Put an index term on every page except class (compound) and overloaded-member pages -->
          <xsl:template mode="index-term-atts" match="doxygen[@d:page-type eq 'compound' or @d:overload-position]"/>
          <xsl:template mode="index-term-atts" match="doxygen">
            <xsl:attribute name="primary-index-term">
              <xsl:apply-templates mode="primary-index-term" select="."/>
            </xsl:attribute>
            <xsl:apply-templates mode="secondary-index-term-att" select="."/>
          </xsl:template>

                  <!-- By default, use the member name as the primary term... -->
                  <xsl:template mode="primary-index-term" match="doxygen">
                    <xsl:apply-templates mode="member-name" select="."/>
                  </xsl:template>
                  <!-- ...and the compound name as the secondary term. -->
                  <xsl:template mode="secondary-index-term-att" match="doxygen">
                    <xsl:attribute name="secondary-index-term">
                      <xsl:apply-templates mode="compound-name" select="."/>
                    </xsl:attribute>
                  </xsl:template>

                  <!-- But with namespace members, use the fully-qualified name as the primary term... -->
                  <xsl:template mode="primary-index-term" match="doxygen[compounddef/@kind eq 'namespace']">
                    <xsl:apply-templates mode="compound-and-member-name" select="."/>
                  </xsl:template>
                  <!-- ...and no secondary term. -->
                  <xsl:template mode="secondary-index-term-att" match="doxygen[compounddef/@kind eq 'namespace']"/>

                          <xsl:template mode="compound-name" match="doxygen"
                            >{d:strip-doc-ns(compounddef/compoundname)}</xsl:template>

                          <xsl:template mode="member-name" match="doxygen"
                            >{(compounddef/sectiondef/memberdef/name)[1]}</xsl:template>

                          <xsl:template mode="compound-and-member-name" match="doxygen">
                            <xsl:apply-templates mode="compound-name" select="."/>
                            <xsl:text>::</xsl:text>
                            <xsl:apply-templates mode="member-name" select="."/>
                          </xsl:template>

          <xsl:template mode="page-title" match="doxygen[@d:page-type eq 'compound']">
            <xsl:apply-templates mode="compound-name" select="."/>
          </xsl:template>
          <xsl:template mode="page-title" match="doxygen">
            <xsl:apply-templates mode="compound-and-member-name" select="."/>
            <xsl:apply-templates mode="overload-qualifier" select="."/>
          </xsl:template>

                  <xsl:template mode="overload-qualifier" match="doxygen"/>
                  <xsl:template mode="overload-qualifier" match="doxygen[@d:overload-position]">
                    <xsl:text> (</xsl:text>
                    <xsl:value-of select="@d:overload-position"/>
                    <xsl:text> of </xsl:text>
                    <xsl:value-of select="@d:overload-size"/>
                    <xsl:text> overloads)</xsl:text>
                  </xsl:template>


  <xsl:template match="/doxygen[@d:page-type eq 'compound']">
    <xsl:apply-templates select="compounddef"/>
  </xsl:template>

  <xsl:template match="/doxygen[@d:page-type eq 'member']">
    <xsl:apply-templates select="compounddef/sectiondef/memberdef"/> <!-- should just be one -->
  </xsl:template>

  <xsl:template match="/doxygen[@d:page-type eq 'overload-list']">
    <xsl:apply-templates select="(compounddef/sectiondef/memberdef)[1]"/>
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
    <xsl:apply-templates mode="includes-footer" select="."/>
  </xsl:template>

  <xsl:template match="memberdef">
    <xsl:apply-templates mode="memberdef-page-content" select="."/>
  </xsl:template>

          <xsl:template mode="memberdef-page-content" match="memberdef">
            <xsl:apply-templates select="briefdescription"/>
            <xsl:apply-templates mode="section" select="., detaileddescription"/>
          </xsl:template>

          <xsl:template mode="memberdef-page-content" match="memberdef[@kind eq 'enum']">
            <xsl:apply-templates select="briefdescription"/>
            <xsl:apply-templates mode="section" select="., parent::sectiondef, detaileddescription"/>
          </xsl:template>

          <xsl:template mode="memberdef-page-content" match="memberdef[/doxygen/@d:page-type eq 'overload-list']">
            <xsl:apply-templates mode="overload-list" select="../../sectiondef/memberdef"/>
          </xsl:template>

                  <xsl:template mode="overload-list" match="memberdef">
                    <xsl:apply-templates select="briefdescription[not(. = ../preceding-sibling::*/briefdescription)]"/>
                    <overloaded-member>
                      <xsl:apply-templates mode="normalize-params" select="templateparamlist"/>
                      <xsl:apply-templates mode="modifier" select="(@explicit, @friend, @static)[. eq 'yes'],
                                                                   @virt[. eq 'virtual']"/>
                      <xsl:apply-templates select="type"/>
                      <link to="{@d:page-refid}">{name}</link>
                      <params>
                        <xsl:apply-templates select="param"/>
                      </params>
                      <xsl:apply-templates mode="modifier" select="@const[. eq 'yes']"/>
                    </overloaded-member>
                  </xsl:template>

                          <xsl:template mode="modifier" match="@*">
                            <modifier>{local-name(.)}</modifier>
                          </xsl:template>
                          <xsl:template mode="modifier" match="@virt">
                            <modifier>virtual</modifier>
                          </xsl:template>


  <xsl:template match="type">
    <type>
      <xsl:value-of select="d:cleanup-type(normalize-space(.))"/>
    </type>
  </xsl:template>

  <!-- d:cleanup-param() may not be needed, and the above may suffice. (TODO: confirm this and remove d:cleanup-param() if so)
  <xsl:template match="param/type">
    <type>
      <xsl:value-of select="d:cleanup-param(.)"/>
    </type>
  </xsl:template>
  -->

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

  <xsl:template mode="section-heading" match="sectiondef[@kind eq 'enum']">Values</xsl:template>

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

          <xsl:template mode="member-nodes" match="sectiondef[@kind eq 'enum']">
            <xsl:sequence select="memberdef/enumvalue"/>
          </xsl:template>

          <xsl:template mode="member-nodes" match="sectiondef">
            <xsl:sequence select="memberdef"/>
          </xsl:template>


          <xsl:function name="d:member-name">
            <xsl:param name="element"/>
            <xsl:apply-templates mode="member-name" select="$element"/>
          </xsl:function>

                  <xsl:template mode="member-name" match="memberdef | enumvalue">
                    <xsl:sequence select="name"/>
                  </xsl:template>
                  <xsl:template mode="member-name" match="innerclass">
                    <xsl:sequence select="d:referenced-class/doxygen/compounddef/compoundname ! d:strip-ns(.)"/>
                  </xsl:template>


          <xsl:template mode="member-row" match="enumvalue">
            <tr>
              <td>
                <code>{d:member-name(.)}</code>
              </td>
              <td>
                <xsl:apply-templates mode="member-description" select="."/>
              </td>
            </tr>
          </xsl:template>

          <!-- Only output a table row for the first instance of each name (ignore overloads) -->
          <xsl:template mode="member-row" match="memberdef[name = preceding-sibling::memberdef/name]"/>
          <xsl:template mode="member-row" match="*">
            <tr>
              <td>
                <bold>
                  <link to="{@d:page-refid}">{d:member-name(.)}</link>
                </bold>
              </td>
              <td>
                <xsl:apply-templates mode="member-description" select="."/>
              </td>
            </tr>
          </xsl:template>

                  <xsl:template mode="member-description" match="enumvalue">
                    <xsl:apply-templates select="briefdescription, detaileddescription"/>
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

  <xsl:template mode="section-body" match="memberdef[@kind eq 'typedef']">
    <typedef>
      <xsl:apply-templates mode="normalize-params" select="templateparamlist"/>
      <xsl:apply-templates select="name, type"/>
    </typedef>
    <!-- TODO: output typedef table here (when applicable) -->
  </xsl:template>

  <xsl:template mode="section-body" match="memberdef[@kind eq 'enum']">
    <enum>
      <xsl:apply-templates select="name"/>
    </enum>
  </xsl:template>

  <!-- TODO: finish implementing this; consider different elements for <enum>, <function>, etc. -->
  <xsl:template mode="section-body" match="memberdef[@kind = ('function','friend')]">
    <xsl:apply-templates mode="includes-header" select="."/>
    <function>
      <xsl:apply-templates mode="normalize-params" select="templateparamlist"/>
      <xsl:apply-templates mode="modifier" select="@static[. eq 'yes'],
                                                   @virt  [. eq 'virtual']"/>
      <xsl:apply-templates select="type, name"/>
      <params>
        <xsl:apply-templates select="param"/> <!-- TODO: implement param[array] rendering (elsewhere) -->
      </params>
      <xsl:apply-templates mode="modifier" select="@const[. eq 'yes']"/>
    </function>
  </xsl:template>

          <!-- TODO: make sure this is robust and handles all the possible cases well -->
          <xsl:template mode="normalize-params" match="templateparamlist/param/type[not(../declname)]
                                                                                   [starts-with(.,'class ')]"
                                                priority="1">
            <type>class</type>
            <declname>{substring-after(.,'class ')}</declname>
          </xsl:template>

          <xsl:template mode="normalize-params" match="templateparamlist/param/type[not(../declname)]">
            <ERROR message="param neither has a declname nor a 'class ' prefix in the type"/>
          </xsl:template>

          <xsl:template mode="normalize-params" match="templateparamlist/param/defname"/>


  <!-- We only need to keep the @file attribute -->
  <xsl:template match="location/@*[. except ../@file]"/>


  <xsl:template match="briefdescription">
    <div>
      <xsl:apply-templates/>
    </div>
  </xsl:template>

  <xsl:template match="simplesect/title"/>

  <!-- TODO: verify we don't need this; it was causing duplicate headings in simplesect sections
  <xsl:template match="title">
    <heading>
      <xsl:apply-templates/>
    </heading>
  </xsl:template>
  -->

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

  <!-- By default, don't output an includes header or footer -->
  <xsl:template mode="includes-header" match="*"/>
  <xsl:template mode="includes-footer" match="*"/>


  <!-- When a <para> directly contains a mix of inline nodes and block-level elements, normalize its content -->
  <xsl:template match="para[&BLOCK_LEVEL_ELEMENT;]">
    <para>
      <xsl:for-each-group select="* | text()" group-adjacent="d:is-inline(.)">
        <xsl:apply-templates mode="capture-ranges" select="."/>
      </xsl:for-each-group>
    </para>
  </xsl:template>

          <xsl:function name="d:is-inline">
            <xsl:param name="node"/>
            <xsl:sequence select="not($node/../(&BLOCK_LEVEL_ELEMENT;)[. is $node])"/>
          </xsl:function>

          <!-- Process the block-level elements as usual -->
          <xsl:template mode="capture-ranges" match="node()">
            <xsl:apply-templates select="current-group()"/>
          </xsl:template>

          <!-- Wrap contiguous ranges of inline children in a nested <para> -->
          <xsl:template mode="capture-ranges" match="node()[d:is-inline(.)]">
            <xsl:choose>
              <!-- But only if it has text or if the group has more than one node -->
              <xsl:when test="normalize-space(.) or current-group()[2]">
                <para>
                  <xsl:apply-templates mode="strip-leading-space" select="."/>
                </para>
              </xsl:when>
              <xsl:otherwise>
                <xsl:next-match/>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:template>


  <!-- Strip leading whitespace from the nested paragraphs to prevent eventual interpretation as a code block -->
  <xsl:template mode="strip-leading-space" match="*">
    <xsl:copy>
      <xsl:apply-templates mode="#current" select="@* | node()[1]"/>
    </xsl:copy>
    <xsl:apply-templates mode="#current" select="following-sibling::node()[1]
                                                 [ancestor-or-self::node() intersect current-group()]"/>
  </xsl:template>

  <xsl:template mode="strip-leading-space" match="@*">
    <xsl:copy/>
  </xsl:template>

  <xsl:template mode="strip-leading-space" match="text()">
    <xsl:param name="done-stripping" tunnel="yes" select="false()"/>
    <xsl:choose>
      <xsl:when test="$done-stripping">
        <xsl:sequence select="."/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:sequence select="replace(.,'^\s+','')"/>
      </xsl:otherwise>
    </xsl:choose>
    <xsl:apply-templates mode="#current" select="following-sibling::node()[1]
                                                 [ancestor-or-self::node() intersect current-group()]">
      <xsl:with-param name="done-stripping" select="$done-stripping or normalize-space(.)" tunnel="yes"/>
    </xsl:apply-templates>
  </xsl:template>


  <xsl:template mode="#default normalize-params" match="@* | node()">
    <xsl:copy copy-namespaces="no">
      <xsl:apply-templates mode="#current" select="@* | node()"/>
    </xsl:copy>
  </xsl:template>

</xsl:stylesheet>
