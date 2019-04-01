<xsl:stylesheet version="3.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:d="http://github.com/vinniefalco/docca"
  exclude-result-prefixes="xs d"
  expand-text="yes">

  <!-- TODO: make sure this doesn't screw up any formatting -->
  <!--
  <xsl:output indent="yes"/>
  -->

  <xsl:key name="memberdefs-by-id" match="memberdef" use="@id"/>

  <xsl:key name="elements-by-refid" match="compound | member" use="@refid"/>

  <xsl:variable name="index-xml" select="/"/>

  <xsl:template match="/">
    <index>
      <xsl:apply-templates select="/doxygenindex/compound"/>
    </index>
    <!-- Testing the ID-related functions
    <xsl:value-of select="replace(d:extract-ns('put'), '::$', '')"/>
    <xsl:text>&#xA;</xsl:text>
    <xsl:value-of select="replace(d:extract-ns('foobar::parser::put'), '::$', '')"/>
    <xsl:text>&#xA;</xsl:text>
    <xsl:value-of select="d:extract-ns('foobar::parser::put&lt;foo::bar, bat::bang>')"/>
    <xsl:text>&#xA;</xsl:text>
    <xsl:value-of select="d:strip-ns('boost::beast::http::parser::basic_parser&lt; foo::isRequest, bar::parser &gt;')"/>
    <xsl:text>&#xA;</xsl:text>
    <xsl:value-of select="d:strip-doc-ns('boost::beast::http::parser::basic_parser&lt; foo::isRequest, bar::parser &gt;')"/>
    <xsl:text>&#xA;</xsl:text>
    <xsl:text>&#xA;</xsl:text>
    <xsl:value-of select="d:make-id('boost::beast::http::parser::basic_parser&lt; foo::isRequest, bar::parser &gt;')"/>
    -->
  </xsl:template>

  <!-- Default implementation; can be customized/overridden -->
  <xsl:function name="d:should-ignore-compound">
    <xsl:param name="compound" as="element(compound)"/>
    <xsl:sequence select="false()"/>
  </xsl:function>

  <xsl:template match="compound[d:should-ignore-compound(.)]"/>
  <xsl:template match="compound">
    <!-- Load each input file only once -->
    <xsl:apply-templates mode="create-page" select=".">
      <xsl:with-param name="source-doc" select="document(@refid||'.xml', /)" tunnel="yes"/>
    </xsl:apply-templates>
  </xsl:template>

  <!-- Potentially create a page for the compound and/or for its member children -->
  <xsl:template mode="create-page" match="compound" priority="1">
    <xsl:next-match/>
    <xsl:apply-templates mode="#current" select="member"/>
  </xsl:template>

  <!-- Split up the content into class, struct, and member pages -->
  <xsl:template mode="create-page" match="*"/>
  <xsl:template mode="create-page" match="compound[@kind = ('class','struct')]
                                        | compound[@kind = ('class','struct','namespace')]/member
                                                                                           [not(@kind eq 'enumvalue')]">
    <xsl:variable name="page-id" as="xs:string">
      <xsl:apply-templates mode="page-id" select="."/>
    </xsl:variable>
    <!-- FIXME: Enable after we add support for overloads (to prevent attempting to write to the same output location more than once) -->
    <!-- Just for now: add position() to disambiguate the IDs; still need to add support for the overload page -->
    <xsl:result-document href="xml-pages/{$page-id}_{position()}.xml">
    <!--
    <xsl:result-document href="xml-pages/{$page-id}.xml">
    -->
      <xsl:apply-templates mode="page-content" select=".">
        <xsl:with-param name="page-id" select="$page-id" tunnel="yes"/>
      </xsl:apply-templates>
    </xsl:result-document>
                                            <!-- FIXME: see above FIXME note -->
    <page id="{$page-id}" href="{$page-id}_{position()}.xml"/>
    <!--
    <d:result-document href="xml-pages/{$page-id}.xml">
      <xsl:apply-templates mode="page-content" select="."/>
    </d:result-document>
    -->
  </xsl:template>

          <xsl:template mode="page-id" priority="1"
                                       match="compound[@kind eq 'namespace']
                                                      /member">{d:make-id(../name||'::'||name)}</xsl:template>
          <xsl:template mode="page-id" match="compound/member">{d:make-id(../name||'.' ||name)}</xsl:template>
          <xsl:template mode="page-id" match="compound"       >{d:make-id(name)               }</xsl:template>


          <!-- The content for a class or struct is the original source document, pared down some -->
          <xsl:template mode="page-content" match="compound">
            <xsl:param name="source-doc" tunnel="yes"/>
            <xsl:apply-templates mode="build-compound-page" select="$source-doc"/>
          </xsl:template>

                  <!-- By default, copy everything -->
                  <xsl:template mode="build-compound-page" match="@* | node()" name="copy-in-compound-page">
                    <xsl:copy>
                      <xsl:apply-templates mode="#current" select="@*"/>
                      <xsl:apply-templates mode="compound-content-insert" select="."/>
                      <xsl:apply-templates mode="#current"/>
                    </xsl:copy>
                  </xsl:template>

                          <!-- By default, don't insert anything -->
                          <xsl:template mode="compound-content-insert" match="*"/>

                  <xsl:template mode="build-compound-page" match="listofallmembers"/>

                  <xsl:template mode="build-compound-page" match="memberdef/@*"/>

                  <!-- But directly inside <memberdef>, don't copy anything... -->
                  <xsl:template mode="build-compound-page" match="memberdef/node()"/>

                  <!-- ...except for <name> and <briefdescription> -->
                  <xsl:template mode="build-compound-page" match="memberdef/name
                                                                | memberdef/briefdescription" priority="1">
                    <xsl:call-template name="copy-in-compound-page"/>
                  </xsl:template>

                  <!-- Alternative implementation in case we need to start controlling whitespace more
                  <xsl:template mode="build-compound-page" match="memberdef">
                    <memberdef>
                      <xsl:text>&#xA;</xsl:text>
                      <xsl:copy-of select="name"/>
                      <xsl:text>&#xA;</xsl:text>
                      <xsl:copy-of select="briefdescription"/>
                    </memberdef>
                  </xsl:template>
                  -->

          <!-- The content for a member page is a subset of the source document -->
          <xsl:template mode="page-content" match="compound/member">
            <xsl:param name="source-doc" tunnel="yes"/>
            <xsl:apply-templates mode="build-member-page" select="$source-doc">
              <xsl:with-param name="target-member"
                              select="key('memberdefs-by-id', @refid, $source-doc)"
                              tunnel="yes"/>
            </xsl:apply-templates>
          </xsl:template>

                  <!-- Always copy the name of the parent compound -->
                  <xsl:template mode="build-member-page" match="compoundname" priority="2">
                    <xsl:copy-of select="."/>
                  </xsl:template>

                  <!-- Otherwise, only copy an element if it's the target member or one of its ancestors -->
                  <xsl:template mode="build-member-page" match="*" priority="1">
                    <xsl:param name="target-member" tunnel="yes"/>
                    <xsl:if test=". intersect $target-member/ancestor-or-self::*">
                      <xsl:next-match/>
                    </xsl:if>
                  </xsl:template>

                  <!-- By default, copy everything -->
                  <xsl:template mode="build-member-page
                                      copy-member-content" match="@* | node()">
                    <xsl:copy>
                      <xsl:apply-templates mode="#current" select="@*"/>
                      <xsl:apply-templates mode="member-content-insert" select="."/>
                      <xsl:apply-templates mode="#current"/>
                    </xsl:copy>
                  </xsl:template>

                          <!-- By default, don't insert anything -->
                          <xsl:template mode="member-content-insert" match="*"/>

                  <!-- Strip out extraneous whitespace -->
                  <xsl:template mode="build-member-page" match="compounddef/text() | sectiondef/text()"/>

                  <!-- Switch to an unfiltered copy once we're done filtering out the undesired elements -->
                  <xsl:template mode="build-member-page" match="memberdef/node()" priority="2">
                    <xsl:apply-templates mode="copy-member-content" select="."/>
                  </xsl:template>

                  <!-- Add the page ID to the top of both compound and member pages -->
                  <xsl:template mode="member-content-insert
                                      compound-content-insert" match="/doxygen">
                    <xsl:param name="page-id" tunnel="yes"/>
                    <xsl:attribute name="d:page-id" select="$page-id"/>
                  </xsl:template>

                  <!-- TODO: refactor this rule -->
                  <!-- Resolve the referenced page IDs for later link generation -->
                  <xsl:template mode="member-content-insert" match="ref">
                    <xsl:variable name="page-id" as="xs:string">
                      <xsl:variable name="target-element" as="element()">
                        <xsl:variable name="referenced-elements"
                                      select="key('elements-by-refid', @refid, $index-xml)"/>
                        <xsl:choose>
                          <!-- Handle the case where the referenced element appears two or more times in index.xml -->
                          <!-- If there's no ambiguity, we're done! -->
                          <xsl:when test="count($referenced-elements) eq 1">
                            <xsl:apply-templates mode="find-target-element" select="$referenced-elements"/>
                          </xsl:when>
                          <xsl:otherwise>
                            <!-- Otherwise, see if a namespace in the link text successfully disambiguates -->
                            <xsl:variable name="qualified-reference" as="element()*">
                              <xsl:variable name="parent-in-link-text"
                                            select="if (contains(.,'::'))
                                                    then d:extract-ns-without-suffix(.)
                                                    else ''"/>
                              <xsl:sequence select="$referenced-elements[ends-with(parent::compound/name, '::'||$parent-in-link-text)]"/>
                            </xsl:variable>
                            <xsl:choose>
                              <xsl:when test="count($qualified-reference) eq 1">
                                <xsl:apply-templates mode="find-target-element" select="$qualified-reference"/>
                              </xsl:when>
                              <xsl:otherwise>
                                <!-- Otherwise, favor the member that's in the same class or namespace as the current page -->
                                <xsl:variable name="sibling-reference" as="element()*">
                                  <xsl:variable name="compound-for-current-page" select="/doxygen/compounddef/compoundname/string()"/>
                                  <xsl:sequence select="$referenced-elements[parent::compound/name eq $compound-for-current-page]"/>
                                </xsl:variable>
                                <xsl:choose>
                                  <xsl:when test="count($sibling-reference) eq 1">
                                    <xsl:apply-templates mode="find-target-element" select="$sibling-reference"/>
                                  </xsl:when>
                                  <!-- If all else fails, give up and just use the first one -->
                                  <xsl:otherwise>
                                    <xsl:apply-templates mode="find-target-element" select="$referenced-elements[1]"/>
                                  </xsl:otherwise>
                                </xsl:choose>
                              </xsl:otherwise>
                            </xsl:choose>
                          </xsl:otherwise>
                        </xsl:choose>
                      </xsl:variable>
                      <xsl:apply-templates mode="page-id" select="$target-element"/>
                    </xsl:variable>
                    <xsl:attribute name="d:refid" select="$page-id"/>
                  </xsl:template>

                          <xsl:template mode="find-target-element" match="compound | member">
                            <xsl:sequence select="."/>
                          </xsl:template>

                          <!-- In the index XML, enumvalue "members" immediately follow the corresponding enum member -->
                          <xsl:template mode="find-target-element" match="member[@kind eq 'enumvalue']">
                            <xsl:sequence select="preceding-sibling::member[@kind eq 'enum'][1]"/>
                          </xsl:template>


  <xsl:variable name="leading-ns-regex" select="'^([^:&lt;]+::)+'"/>

  <xsl:function name="d:extract-ns-without-suffix">
    <xsl:param name="name"/>
    <xsl:sequence select="replace(d:extract-ns($name), '::$', '')"/>
  </xsl:function>

  <xsl:function name="d:extract-ns">
    <xsl:param name="name"/>
    <xsl:sequence select="replace($name, '('||$leading-ns-regex||').*', '$1')"/>
  </xsl:function>

  <!-- Strip all C++ namespace prefixes that come at the beginning -->
  <xsl:function name="d:strip-ns">
    <xsl:param name="name"/>
    <xsl:sequence select="replace($name, $leading-ns-regex, '')"/>
  </xsl:function>

  <!-- Strip the common C++ namespace prefix for the docs as a whole -->
  <!-- ASSUMPTION: $doc-ns is defined in the customizing stylesheet -->
  <xsl:function name="d:strip-doc-ns">
    <xsl:param name="name"/>
    <xsl:sequence select="replace($name, '^'||$doc-ns||'::', '')"/>
  </xsl:function>

  <xsl:function name="d:make-id">
    <xsl:param name="name"/>
    <xsl:sequence select="d:make-id($name, $id-replacements)"/>
  </xsl:function>

  <xsl:function name="d:make-id">
    <xsl:param name="name"/>
    <xsl:param name="replacements"/>
    <xsl:variable name="next" select="head($replacements)"/>
    <xsl:variable name="rest" select="tail($replacements)"/>
    <xsl:sequence select="if (exists($next))
                          then d:make-id(replace($name, $next/@pattern, $next/@with), $rest)
                          else $name"/>
  </xsl:function>

  <xsl:variable name="id-replacements" select="$additional-id-replacements, $base-id-replacements"/>

  <!-- Can be overridden by a customizing stylesheet -->
  <xsl:variable name="additional-id-replacements" as="element(replace)*" select="()"/>
  <xsl:variable name="base-id-replacements" as="element(replace)+">
    <replace pattern="^boost::system::" with=""/>  <!-- TODO: verify this is generic enough not to be in a custom stylesheet -->
    <replace pattern="boost__posix_time__ptime" with="ptime"/>  <!-- TODO: verify this is correct; it smells... (the input looks already partially processed) -->
    <replace pattern="::" with="__"/>
    <replace pattern="="  with="_eq_"/>
    <replace pattern="!"  with="_not_"/>
    <replace pattern="->" with="_arrow_"/>
    <replace pattern="&lt;" with="_lt_"/>
    <replace pattern=">"    with="_gt_"/>
    <replace pattern="^~" with="_dtor_"/>  <!-- destructor -->
    <replace pattern="~" with="_"/>
    <replace pattern="\[" with="_lb_"/>
    <replace pattern="\]" with="_rb_"/>
    <replace pattern="\(" with="_lp_"/>
    <replace pattern="\)" with="_rp_"/>
    <replace pattern="\+" with="_plus_"/>
    <replace pattern="-" with="_minus_"/>
    <replace pattern="\*" with="_star_"/>
    <replace pattern="/" with="_slash_"/>
    <replace pattern=" " with="_"/>
  </xsl:variable>

</xsl:stylesheet>
