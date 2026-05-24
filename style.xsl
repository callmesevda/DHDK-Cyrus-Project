<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:tei="http://www.tei-c.org/ns/1.0"
    exclude-result-prefixes="tei">

    <xsl:output method="html" encoding="UTF-8" indent="yes"/>

    <xsl:template name="clean-name">
        <xsl:param name="raw-text"/>
        
        <xsl:variable name="clean-id" select="substring-after($raw-text, '#')"/>

        <xsl:choose>
            <xsl:when test="starts-with($raw-text, '#') and //tei:person[@xml:id=$clean-id]/tei:persName">
                <xsl:value-of select="//tei:person[@xml:id=$clean-id]/tei:persName"/>
            </xsl:when>
            
            <xsl:when test="starts-with($raw-text, '#') and //tei:place[@xml:id=$clean-id]/tei:placeName">
                <xsl:value-of select="//tei:place[@xml:id=$clean-id]/tei:placeName"/>
            </xsl:when>
            
            <xsl:when test="starts-with($raw-text, '#') and //tei:org[@xml:id=$clean-id]/tei:orgName">
                <xsl:value-of select="//tei:org[@xml:id=$clean-id]/tei:orgName"/>
            </xsl:when>

            <xsl:when test="starts-with($raw-text, '#') and //*[@xml:id=$clean-id]/tei:label">
                <xsl:value-of select="//*[@xml:id=$clean-id]/tei:label"/>
            </xsl:when>

            <xsl:when test="starts-with($raw-text, '#')">
                <xsl:value-of select="translate(substring-after($raw-text, '#'), '_', ' ')"/>
            </xsl:when>

            <xsl:when test="contains($raw-text, 'ext:')">
                <xsl:value-of select="translate(substring-after($raw-text, 'ext:'), '_', ' ')"/>
            </xsl:when>

            <xsl:when test="contains($raw-text, 'crm:')">
                <xsl:value-of select="translate(substring-after($raw-text, 'crm:'), '_', ' ')"/>
            </xsl:when>
            <xsl:when test="contains($raw-text, 'schema:')">
                <xsl:value-of select="translate(substring-after($raw-text, 'schema:'), '_', ' ')"/>
            </xsl:when>

            <xsl:otherwise><xsl:value-of select="$raw-text"/></xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template match="/">
        <html>
            <head>
                <title>Knowledge Graph Data - Cyrus Cylinder</title>     
                <style>
                    table { 
                        border-collapse: collapse; 
                        width: 100%; 
                        table-layout: fixed;
                    }
                    
                    th, td { 
                        border-bottom: 1px solid #eeeeee; 
                        padding: 10px 10px; 
                        text-align: left; 
                        word-wrap: break-word;
                    }
                </style>
            </head>
            <body>
                <div class="container">                    
                    <table>
                        <tr>
                            <th>Subject (Active Entity)</th>
                            <th>Predicate (Relation Type)</th>
                            <th>Object (Passive Entity)</th>
                        </tr>

                        <xsl:if test="//tei:relation[@active = //tei:persName/@ref or substring-after(@active, '#') = //tei:person/@xml:id]">
                            <xsl:for-each select="//tei:relation[@active = //tei:persName/@ref or substring-after(@active, '#') = //tei:person/@xml:id]">
                                <xsl:call-template name="print-row"/>
                            </xsl:for-each>
                        </xsl:if>

                        <xsl:if test="//tei:relation[@active = //tei:placeName/@ref or substring-after(@active, '#') = //tei:place/@xml:id]">
                            <xsl:for-each select="//tei:relation[@active = //tei:placeName/@ref or substring-after(@active, '#') = //tei:place/@xml:id]">
                                <xsl:call-template name="print-row"/>
                            </xsl:for-each>
                        </xsl:if>

                        <xsl:if test="//tei:relation[@active = //tei:orgName/@ref or substring-after(@active, '#') = //tei:org/@xml:id]">
                            <xsl:for-each select="//tei:relation[@active = //tei:orgName/@ref or substring-after(@active, '#') = //tei:org/@xml:id]">
                                <xsl:call-template name="print-row"/>
                            </xsl:for-each>
                        </xsl:if>

                        <xsl:if test="//tei:relation[starts-with(@active, '#') and 
                            not(@active = //tei:persName/@ref or substring-after(@active, '#') = //tei:person/@xml:id) and 
                            not(@active = //tei:placeName/@ref or substring-after(@active, '#') = //tei:place/@xml:id) and 
                            not(@active = //tei:orgName/@ref or substring-after(@active, '#') = //tei:org/@xml:id)]">
                            <xsl:for-each select="//tei:relation[starts-with(@active, '#') and 
                                not(@active = //tei:persName/@ref or substring-after(@active, '#') = //tei:person/@xml:id) and 
                                not(@active = //tei:placeName/@ref or substring-after(@active, '#') = //tei:place/@xml:id) and 
                                not(@active = //tei:orgName/@ref or substring-after(@active, '#') = //tei:org/@xml:id)]">
                                <xsl:call-template name="print-row"/>
                            </xsl:for-each>
                        </xsl:if>

                        <xsl:if test="//tei:relation[starts-with(@active, 'ext:')]">
                            <xsl:for-each select="//tei:relation[starts-with(@active, 'ext:')]">
                                <xsl:call-template name="print-row"/>
                            </xsl:for-each>
                        </xsl:if>

                    </table>
                </div>
            </body>
        </html>
    </xsl:template>

    <xsl:template name="print-row">
        <tr>
            <td>
                <xsl:call-template name="clean-name">
                    <xsl:with-param name="raw-text" select="@active"/>
                </xsl:call-template>
            </td>
            <td>
                <xsl:call-template name="clean-name">
                    <xsl:with-param name="raw-text" select="@name"/>
                </xsl:call-template>
            </td>
            <td>
                <xsl:call-template name="clean-name">
                    <xsl:with-param name="raw-text" select="@passive"/>
                </xsl:call-template>
            </td>
        </tr>
    </xsl:template>

</xsl:stylesheet>